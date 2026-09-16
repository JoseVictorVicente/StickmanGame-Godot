class_name LayoutPaineis
extends RefCounted
## Posiciona o inventário ao centro e os painéis laterais (armazém / ferraria / mundos).


static func alinhar(
	painel: Control,
	area_menus: Control,
	armazem: Control,
	ferraria: Control,
	mundos: Control,
	menus_abaixo: bool,
	formacao: Control = null,
	atributos: Control = null
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
	_posicionar_lado(armazem, painel, true, y, painel.size.y, area_menus.size)
	_posicionar_lado(ferraria, painel, false, y, painel.size.y, area_menus.size)
	_posicionar_lado(mundos, painel, false, y, painel.size.y, area_menus.size)
	_sobrepor_painel(formacao, painel)
	_sobrepor_painel(atributos, painel)


static func largura_janela(painel: Control, armazem: Control, ferraria: Control, mundos: Control, formacao: Control = null) -> int:
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


static func _sobrepor_painel(lado: Control, painel: Control) -> void:
	if lado == null or not lado.visible or painel == null:
		return
	var tam := painel.size
	if tam.x < 1.0 or tam.y < 1.0:
		tam = painel.get_combined_minimum_size()
		tam.x = maxf(tam.x, painel.custom_minimum_size.x)
		tam.y = maxf(tam.y, painel.custom_minimum_size.y)
	if lado.size != tam:
		lado.size = tam
	if lado.position != painel.position:
		lado.position = painel.position


static func _largura_de(lado: Control) -> int:
	return int(maxf(lado.custom_minimum_size.x, lado.get_combined_minimum_size().x))


static func _posicionar_lado(lado: Control, painel: Control, na_esquerda: bool, y: float, altura: float, area: Vector2 = Vector2.ZERO) -> void:
	if lado == null or not lado.visible:
		return
	var largura := maxf(lado.custom_minimum_size.x, lado.get_combined_minimum_size().x)
	# Mesma altura do inventário: o conteúdo extra rola por dentro do painel.
	var altura_lado := maxf(altura, 1.0)
	if area.y > 0.0:
		altura_lado = minf(altura_lado, area.y)
	var tam := Vector2(largura, altura_lado)
	if lado.size != tam:
		lado.size = tam
	var pos: Vector2
	if na_esquerda:
		pos = Vector2(painel.position.x - 8.0 - lado.size.x, y)
	else:
		pos = Vector2(painel.position.x + painel.size.x + 8.0, y)
	if area.y > 0.0:
		pos.y = clampf(pos.y, 0.0, maxf(0.0, area.y - lado.size.y))
	if lado.position != pos:
		lado.position = pos
