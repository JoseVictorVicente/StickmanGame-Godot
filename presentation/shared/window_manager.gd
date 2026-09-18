class_name WindowManager
extends Node
## Janela transparente, arraste, âncoras do stage_panel e click-through.

const LARGURA := 960
const ALTURA := 860
const STAGE_TOP_MARGIN := 8
const STAGE_HEIGHT := 124
const PALCO_BASE_JANELA := 108
const PANEL_HEIGHT := 100
const BUTTON_SIZE := 80
const INVENTORY_PANEL_WIDTH := 580

var stage_panel: Control
var battle_panel: PanelContainer
var menu_button_area: ColorRect
var combat_root: Node2D
var floor: Control
var open_inventory_button: Button
var get_menu_rects: Callable
var is_menu_visible: Callable
var on_drag_released: Callable

var _dragging: bool = false
var _drag_offset: Vector2i = Vector2i.ZERO
var combat_at_top: bool = false


func configure_flags() -> void:
	get_viewport().transparent_bg = true
	get_tree().get_root().transparent_bg = true
	DisplayServer.window_set_size(Vector2i(LARGURA, ALTURA))
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_MOUSE_PASSTHROUGH, false)


func _process(_delta: float) -> void:
	align_combat()
	update_click_through()


func align_combat() -> void:
	if floor == null or combat_root == null:
		return
	var rect := floor.get_global_rect()
	combat_root.position = Vector2(rect.get_center().x, rect.position.y + 2)


func on_drag_area(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if _dragging:
			_drag_offset = DisplayServer.mouse_get_position() - DisplayServer.window_get_position()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		var estava := _dragging
		_dragging = false
		if estava and is_menu_visible.is_valid() and bool(is_menu_visible.call()):
			if on_drag_released.is_valid():
				on_drag_released.call()
	elif event is InputEventMouseMotion and _dragging:
		DisplayServer.window_set_position(DisplayServer.mouse_get_position() - _drag_offset)


func apply_menu_direction() -> bool:
	var abrir_para_baixo := _should_open_downward()
	anchor_combat_to_top(abrir_para_baixo)
	_keep_combat_on_screen()
	return abrir_para_baixo


func anchor_combat_to_top(no_topo: bool) -> void:
	combat_at_top = no_topo
	if no_topo:
		_set_anchors(stage_panel, 0.5, 0.0, 0.5, 0.0, -240, STAGE_TOP_MARGIN, 240, STAGE_TOP_MARGIN + STAGE_HEIGHT)
		var painel_topo := STAGE_TOP_MARGIN + STAGE_HEIGHT
		_set_anchors(battle_panel, 0.5, 0.0, 0.5, 0.0, -160, painel_topo, 160, painel_topo + PANEL_HEIGHT)
		var botao_topo := painel_topo + 10
		_position_inventory_button(0.0, 0.0, botao_topo, botao_topo + BUTTON_SIZE)
	else:
		_set_anchors(stage_panel, 0.5, 1.0, 0.5, 1.0, -240, -232, 240, -PALCO_BASE_JANELA)
		_set_anchors(battle_panel, 0.5, 1.0, 0.5, 1.0, -160, -108, 160, -8)
		_position_inventory_button(1.0, 1.0, -96, -16)


func _horizontal_button_offsets() -> Vector2i:
	var largura := get_window().size.x
	var direita_painel := int((largura + INVENTORY_PANEL_WIDTH) * 0.5)
	var centro := int(largura * 0.5)
	var offset_dir := direita_painel - centro
	return Vector2i(offset_dir - BUTTON_SIZE, offset_dir)


func _position_inventory_button(a_topo: float, a_base: float, offset_topo: int, offset_base: int) -> void:
	if menu_button_area == null:
		return
	var offsets := _horizontal_button_offsets()
	_set_anchors(
		menu_button_area,
		0.5,
		a_topo,
		0.5,
		a_base,
		offsets.x,
		offset_topo,
		offsets.y,
		offset_base
	)


func _align_inventory_button() -> void:
	if menu_button_area == null:
		return
	_position_inventory_button(
		menu_button_area.anchor_top,
		menu_button_area.anchor_bottom,
		int(menu_button_area.offset_top),
		int(menu_button_area.offset_bottom)
	)


func adjust_width(abrir_inventario: bool = false, largura_menu: int = LARGURA) -> void:
	var desejada := LARGURA
	if abrir_inventario or (is_menu_visible.is_valid() and bool(is_menu_visible.call())):
		desejada = maxi(LARGURA, largura_menu)
	var tela := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	desejada = mini(desejada, tela.size.x)
	var atual := DisplayServer.window_get_size()
	if atual.x == desejada:
		_align_inventory_button()
		return
	var pos := DisplayServer.window_get_position()
	var centro := pos.x + int(atual.x / 2.0)
	var nova_x := centro - int(desejada / 2.0)
	nova_x = clampi(nova_x, tela.position.x, tela.position.x + tela.size.x - desejada)
	var janela := get_window()
	janela.position = Vector2i(nova_x, pos.y)
	janela.size = Vector2i(desejada, ALTURA)
	_align_inventory_button()


func update_click_through() -> void:
	var retangulos: Array[Rect2] = []
	if open_inventory_button and open_inventory_button.visible and open_inventory_button.is_visible_in_tree():
		retangulos.append(open_inventory_button.get_global_rect().grow(6.0))
	if battle_panel and battle_panel.visible:
		retangulos.append(battle_panel.get_global_rect().grow(4.0))
	if stage_panel and stage_panel.visible:
		retangulos.append(stage_panel.get_global_rect().grow(4.0))
	if get_menu_rects.is_valid() and is_menu_visible.is_valid() and bool(is_menu_visible.call()):
		var extras: Variant = get_menu_rects.call()
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


func _should_open_downward() -> bool:
	var tela := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	var palco_tela := _rect_on_screen(stage_panel)
	var win := DisplayServer.window_get_position()
	var limite_alto := float(tela.position.y) + float(tela.size.y) * 0.45
	if win.y <= tela.position.y + 80:
		return true
	if palco_tela.position.y <= limite_alto:
		return true
	if palco_tela.position.y - float(tela.position.y) < 500.0:
		return true
	return false


func _keep_combat_on_screen() -> void:
	var tela := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	var palco_tela := _rect_on_screen(stage_panel)
	var win := DisplayServer.window_get_position()
	var dy := 0
	if palco_tela.position.y < float(tela.position.y) + 4.0:
		dy = int(float(tela.position.y) + 4.0 - palco_tela.position.y)
	elif palco_tela.end.y > float(tela.end.y) - 4.0:
		dy = int(float(tela.end.y) - 4.0 - palco_tela.end.y)
	if dy != 0:
		DisplayServer.window_set_position(Vector2i(win.x, win.y + dy))


func _rect_on_screen(controle: Control) -> Rect2:
	var local := controle.get_global_rect()
	var win := Vector2(DisplayServer.window_get_position())
	var xform := get_window().get_final_transform()
	var pos := win + xform * local.position
	var canto := win + xform * local.end
	return Rect2(pos, canto - pos)


func _set_anchors(
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
