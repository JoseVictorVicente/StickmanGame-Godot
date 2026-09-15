class_name LayoutPaineis
extends RefCounted
## Posiciona o inventário ao centro e os painéis laterais (armazém / ferraria / mundos).


static func alinhar(
	painel: Control,
	area_menus: Control,
	armazem: Control,
	ferraria: Control,
	mundos: Control,
	menus_abaixo: bool
) -> void:
	if painel == null or area_menus == null:
		return
	var tam_painel := painel.get_combined_minimum_size()
	tam_painel.x = maxf(tam_painel.x, painel.custom_minimum_size.x)
	if painel.size != tam_painel:
		painel.size = tam_painel
	var y := 0.0
	if menus_abaixo:
		y = maxf(0.0, area_menus.size.y - painel.size.y)
	var pos_painel := Vector2((area_menus.size.x - painel.size.x) * 0.5, y)
	if painel.position != pos_painel:
		painel.position = pos_painel
	_posicionar_lado(armazem, painel, true, y, painel.size.y)
	_posicionar_lado(ferraria, painel, false, y, painel.size.y)
	_posicionar_lado(mundos, painel, false, y, painel.size.y)


static func largura_janela(painel: Control, armazem: Control, ferraria: Control, mundos: Control) -> int:
	var extra_esq := 0
	var extra_dir := 0
	if armazem and armazem.visible:
		extra_esq = 8 + int(armazem.custom_minimum_size.x)
	if ferraria and ferraria.visible:
		extra_dir = maxi(extra_dir, 8 + int(ferraria.custom_minimum_size.x))
	if mundos and mundos.visible:
		extra_dir = maxi(extra_dir, 8 + int(mundos.custom_minimum_size.x))
	var base := 0
	if painel:
		base = int(painel.custom_minimum_size.x)
	return 40 + base + 2 * maxi(extra_esq, extra_dir)


static func _posicionar_lado(lado: Control, painel: Control, na_esquerda: bool, y: float, altura: float) -> void:
	if lado == null or not lado.visible:
		return
	var largura := maxf(lado.custom_minimum_size.x, lado.get_combined_minimum_size().x)
	var tam := Vector2(largura, maxf(altura, lado.get_combined_minimum_size().y))
	if lado.size != tam:
		lado.size = tam
	var pos: Vector2
	if na_esquerda:
		pos = Vector2(painel.position.x - 8.0 - lado.size.x, y)
	else:
		pos = Vector2(painel.position.x + painel.size.x + 8.0, y)
	if lado.position != pos:
		lado.position = pos
