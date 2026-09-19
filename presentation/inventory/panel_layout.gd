class_name PanelLayout
extends RefCounted
## Posiciona o inventário ao centro e os painéis laterais (armazém / ferraria / mundos).


static func align_panel(
	painel: Control,
	menu_area: Control,
	armazem: Control,
	ferraria: Control,
	mundos: Control,
	_menus_abaixo: bool,
	formacao: Control = null,
	atributos: Control = null,
	skills: Control = null,
	arvore: Control = null
) -> void:
	if painel == null or menu_area == null:
		return
	var area_size := menu_area.size
	var tam_painel := painel.get_combined_minimum_size() if painel.visible else painel.size
	tam_painel.x = maxf(tam_painel.x, painel.custom_minimum_size.x)
	if painel.visible and painel.size != tam_painel:
		painel.size = tam_painel
	var pos_painel := Vector2((area_size.x - painel.size.x) * 0.5, 0.0)
	if painel.position != pos_painel:
		painel.position = pos_painel
	_position_side(armazem, painel, true)
	_position_side(ferraria, painel, false)
	_position_side(mundos, painel, false)
	_overlay_panel(formacao, painel)
	_overlay_panel(atributos, painel)
	_overlay_panel(skills, painel)
	_overlay_panel(arvore, painel)


static func window_width(painel: Control, armazem: Control, ferraria: Control, mundos: Control, formacao: Control = null) -> int:
	var extra_esq := 0
	var extra_dir := 0
	if armazem and armazem.visible:
		extra_esq = 8 + _largura_de(armazem)
	if ferraria and ferraria.visible:
		extra_dir = maxi(extra_dir, 8 + _largura_de(ferraria))
	if mundos and mundos.visible:
		extra_dir = maxi(extra_dir, 8 + _largura_de(mundos))
	var base := 0
	if painel:
		base = int(painel.custom_minimum_size.x)
	return 40 + base + 2 * maxi(extra_esq, extra_dir)


static func _overlay_panel(lado: Control, painel: Control) -> void:
	if lado == null or not lado.visible or painel == null:
		return
	var tam := painel.size
	if tam.x < 1.0 or tam.y < 1.0:
		tam = painel.get_combined_minimum_size()
		tam.x = maxf(tam.x, painel.custom_minimum_size.x)
	if lado.size != tam:
		lado.size = tam
	if lado.position != painel.position:
		lado.position = painel.position


static func _largura_de(lado: Control) -> int:
	return int(maxf(lado.custom_minimum_size.x, lado.get_combined_minimum_size().x))


static func _position_side(lado: Control, painel: Control, na_esquerda: bool) -> void:
	if lado == null or not lado.visible:
		return
	var largura := maxf(lado.custom_minimum_size.x, lado.get_combined_minimum_size().x)
	var altura := maxf(painel.size.y, 1.0)
	var tam := Vector2(largura, altura)
	var pos := Vector2(
		painel.position.x - 8.0 - tam.x if na_esquerda else painel.position.x + painel.size.x + 8.0,
		painel.position.y
	)
	# Control lateral segue o retângulo do inventário; não use o mínimo do conteúdo.
	lado.custom_minimum_size = Vector2(largura, 0.0)
	if lado.size != tam:
		lado.size = tam
	if lado.position != pos:
		lado.position = pos
