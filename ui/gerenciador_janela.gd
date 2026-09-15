class_name GerenciadorJanela
extends Node
## Janela transparente, arraste, âncoras do palco e click-through.

const LARGURA := 960
const ALTURA := 860
const PALCO_MARGEM_TOPO := 8
const PALCO_ALTURA := 124
const PALCO_BASE_JANELA := 108
const PAINEL_ALTURA := 100
const BOTAO_TAMANHO := 80
const BOTAO_OFFSET_ESQ := 384
const BOTAO_OFFSET_DIR := 464

var palco: Control
var painel_batalha: PanelContainer
var area_botao_menu: ColorRect
var combate: Node2D
var chao: ColorRect
var botao_abrir_inventario: Button
var obter_rects_menu: Callable
var menu_esta_visivel: Callable
var ao_soltar_arraste: Callable

var _arrastando: bool = false
var _offset_arraste: Vector2i = Vector2i.ZERO
var combate_no_topo: bool = false


func configurar_flags() -> void:
	get_viewport().transparent_bg = true
	get_tree().get_root().transparent_bg = true
	DisplayServer.window_set_size(Vector2i(LARGURA, ALTURA))
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_MOUSE_PASSTHROUGH, false)


func _process(_delta: float) -> void:
	alinhar_combate()
	atualizar_click_through()


func alinhar_combate() -> void:
	if chao == null or combate == null:
		return
	var rect := chao.get_global_rect()
	combate.position = Vector2(rect.get_center().x, rect.position.y + 2)


func on_area_arraste(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_arrastando = event.pressed
		if _arrastando:
			_offset_arraste = DisplayServer.mouse_get_position() - DisplayServer.window_get_position()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		var estava := _arrastando
		_arrastando = false
		if estava and menu_esta_visivel.is_valid() and bool(menu_esta_visivel.call()):
			if ao_soltar_arraste.is_valid():
				ao_soltar_arraste.call()
	elif event is InputEventMouseMotion and _arrastando:
		DisplayServer.window_set_position(DisplayServer.mouse_get_position() - _offset_arraste)


func aplicar_direcao_do_menu() -> bool:
	var abrir_para_baixo := _deve_abrir_para_baixo()
	ancorar_combate_no_topo(abrir_para_baixo)
	_manter_combate_na_tela()
	return abrir_para_baixo


func ancorar_combate_no_topo(no_topo: bool) -> void:
	combate_no_topo = no_topo
	if no_topo:
		_definir_ancoras(palco, 0.5, 0.0, 0.5, 0.0, -240, PALCO_MARGEM_TOPO, 240, PALCO_MARGEM_TOPO + PALCO_ALTURA)
		var painel_topo := PALCO_MARGEM_TOPO + PALCO_ALTURA
		_definir_ancoras(painel_batalha, 0.5, 0.0, 0.5, 0.0, -160, painel_topo, 160, painel_topo + PAINEL_ALTURA)
		var botao_topo := painel_topo + 10
		_definir_ancoras(area_botao_menu, 0.5, 0.0, 0.5, 0.0, BOTAO_OFFSET_ESQ, botao_topo, BOTAO_OFFSET_DIR, botao_topo + BOTAO_TAMANHO)
	else:
		_definir_ancoras(palco, 0.5, 1.0, 0.5, 1.0, -240, -232, 240, -PALCO_BASE_JANELA)
		_definir_ancoras(painel_batalha, 0.5, 1.0, 0.5, 1.0, -160, -108, 160, -8)
		_definir_ancoras(area_botao_menu, 0.5, 1.0, 0.5, 1.0, BOTAO_OFFSET_ESQ, -96, BOTAO_OFFSET_DIR, -16)


func ajustar_largura(abrir_inventario: bool = false, largura_menu: int = LARGURA) -> void:
	var desejada := LARGURA
	if abrir_inventario or (menu_esta_visivel.is_valid() and bool(menu_esta_visivel.call())):
		desejada = maxi(LARGURA, largura_menu)
	var tela := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	desejada = mini(desejada, tela.size.x)
	var atual := DisplayServer.window_get_size()
	if atual.x == desejada:
		return
	var pos := DisplayServer.window_get_position()
	var centro := pos.x + int(atual.x / 2.0)
	var nova_x := centro - int(desejada / 2.0)
	nova_x = clampi(nova_x, tela.position.x, tela.position.x + tela.size.x - desejada)
	var janela := get_window()
	janela.position = Vector2i(nova_x, pos.y)
	janela.size = Vector2i(desejada, ALTURA)


func atualizar_click_through() -> void:
	var retangulos: Array[Rect2] = []
	if botao_abrir_inventario and botao_abrir_inventario.visible and botao_abrir_inventario.is_visible_in_tree():
		retangulos.append(botao_abrir_inventario.get_global_rect().grow(6.0))
	if painel_batalha and painel_batalha.visible:
		retangulos.append(painel_batalha.get_global_rect().grow(4.0))
	if palco and palco.visible:
		retangulos.append(palco.get_global_rect().grow(4.0))
	if obter_rects_menu.is_valid() and menu_esta_visivel.is_valid() and bool(menu_esta_visivel.call()):
		var extras: Variant = obter_rects_menu.call()
		if extras is Array:
			for ret in extras:
				if ret is Rect2:
					retangulos.append(ret)

	var cantos := PackedVector2Array()
	var xform := get_window().get_final_transform()
	for retangulo in retangulos:
		cantos.append(xform * retangulo.position)
		cantos.append(xform * Vector2(retangulo.end.x, retangulo.position.y))
		cantos.append(xform * retangulo.end)
		cantos.append(xform * Vector2(retangulo.position.x, retangulo.end.y))

	var pontos := cantos
	if cantos.size() > 4:
		pontos = Geometry2D.convex_hull(cantos)
	DisplayServer.window_set_mouse_passthrough(pontos)


func _deve_abrir_para_baixo() -> bool:
	var tela := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	var palco_tela := _rect_na_tela(palco)
	var win := DisplayServer.window_get_position()
	var limite_alto := float(tela.position.y) + float(tela.size.y) * 0.45
	if win.y <= tela.position.y + 80:
		return true
	if palco_tela.position.y <= limite_alto:
		return true
	if palco_tela.position.y - float(tela.position.y) < 500.0:
		return true
	return false


func _manter_combate_na_tela() -> void:
	var tela := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	var palco_tela := _rect_na_tela(palco)
	var win := DisplayServer.window_get_position()
	var dy := 0
	if palco_tela.position.y < float(tela.position.y) + 4.0:
		dy = int(float(tela.position.y) + 4.0 - palco_tela.position.y)
	elif palco_tela.end.y > float(tela.end.y) - 4.0:
		dy = int(float(tela.end.y) - 4.0 - palco_tela.end.y)
	if dy != 0:
		DisplayServer.window_set_position(Vector2i(win.x, win.y + dy))


func _rect_na_tela(controle: Control) -> Rect2:
	var local := controle.get_global_rect()
	var win := Vector2(DisplayServer.window_get_position())
	var xform := get_window().get_final_transform()
	var pos := win + xform * local.position
	var canto := win + xform * local.end
	return Rect2(pos, canto - pos)


func _definir_ancoras(
	controle: Control,
	a_esq: float,
	a_topo: float,
	a_dir: float,
	a_base: float,
	o_esq: int,
	o_topo: int,
	o_dir: int,
	o_base: int
) -> void:
	if controle == null:
		return
	controle.anchor_left = a_esq
	controle.anchor_top = a_topo
	controle.anchor_right = a_dir
	controle.anchor_bottom = a_base
	controle.offset_left = o_esq
	controle.offset_top = o_topo
	controle.offset_right = o_dir
	controle.offset_bottom = o_base
