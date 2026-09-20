extends SceneTree
## Geometric audit for inventory_menu hub: bands, widths, stack order, overlays.


const LAYOUT := preload("res://presentation/inventory/inventory_layout_default.tres")
const MENU_SCENE_PATH := "res://presentation/inventory/inventory_menu.tscn"
const LayoutStates := preload("res://tests/inventory_menu_layout_states.gd")

const TEST_HOST_GROUP := "inventory_layout_test_host"
const TOL := 12.0
const OVERLAY_COVERAGE := 0.85
const GRID_OVERLAP_MAX := 0.05


var _failures: Array[Dictionary] = []
var _menu_scene: PackedScene


func _initialize() -> void:
	call_deferred("_run_audit")


func _run_audit() -> void:
	await process_frame
	DisplayServer.window_set_size(
		Vector2i(UiConstants.WINDOW_WIDTH, UiConstants.WINDOW_HEIGHT)
	)
	_menu_scene = load(MENU_SCENE_PATH) as PackedScene
	if _menu_scene == null:
		print("INVENTORY_MENU_LAYOUT_AUDIT_FAILED")
		print(JSON.stringify({"state": "boot", "node": "InventoryMenu", "expected": "scene should load"}))
		quit(1)
		return
	LAYOUT.sync_from_base_unit()
	await _clear_test_hosts()
	var menu: Control = await _spawn_menu()
	if menu == null:
		print("INVENTORY_MENU_LAYOUT_AUDIT_FAILED")
		print(JSON.stringify({"state": "boot", "node": "InventoryMenu", "expected": "menu scene should instantiate"}))
		quit(1)
		return
	for state_id in LayoutStates.STATE_IDS:
		LayoutStates.reset_menu(menu)
		LayoutStates.apply_state(menu, state_id)
		await LayoutStates.settle(self, menu)
		await process_frame
		await process_frame
		_run_invariants(menu, state_id)
	if _failures.is_empty():
		print("[TEST PASS] Inventory menu layout audit (%d states)" % LayoutStates.STATE_IDS.size())
		quit(0)
		return
	print("INVENTORY_MENU_LAYOUT_AUDIT_FAILED")
	for failure in _failures:
		print(JSON.stringify(failure))
	quit(1)


func _clear_test_hosts() -> void:
	for child in root.get_children():
		if child.is_in_group(TEST_HOST_GROUP):
			child.queue_free()
	for _i in 5:
		await process_frame


func _spawn_menu() -> Control:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(UiConstants.WINDOW_WIDTH, UiConstants.WINDOW_HEIGHT)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.add_to_group(TEST_HOST_GROUP)
	root.add_child(viewport)
	var host := Control.new()
	host.custom_minimum_size = Vector2(UiConstants.WINDOW_WIDTH, UiConstants.WINDOW_HEIGHT)
	host.size = host.custom_minimum_size
	viewport.add_child(host)
	await process_frame
	var menu := LayoutStates.instantiate_menu(host, _menu_scene)
	if menu != null and not menu.is_node_ready():
		await menu.ready
	return menu


func _run_invariants(menu: Control, state_id: String) -> void:
	var painel := menu.get_node_or_null("%Panel") as Control
	var menu_area := menu.get_node_or_null("%MenuArea") as Control
	var layout := LAYOUT.duplicate() as InventoryLayout
	layout.sync_from_base_unit()
	if painel == null or menu_area == null:
		_record_failure(state_id, "Panel/MenuArea", Rect2(), "hub nodes should exist")
		return
	if painel.visible:
		_check_combat_band(state_id, painel, menu)
		_check_hub_width(state_id, painel, menu_area, layout, menu)
	var conteudo := menu.get_node_or_null("%Conteudo") as Control
	if conteudo != null and conteudo.visible:
		_check_vertical_stack(menu, state_id)
		_check_slot_sizes(menu, state_id, layout)
		_check_nav_sizes(menu, state_id, layout)
	_check_overlay_coverage(menu, state_id, painel)
	_check_screen_visible(menu, state_id)


func _rect_in_menu(control: Control, menu: Control) -> Rect2:
	var global_rect := control.get_global_rect()
	var origin := menu.get_global_rect().position
	return Rect2(global_rect.position - origin, global_rect.size)


func _check_combat_band(state_id: String, painel: Control, menu: Control) -> void:
	var rect := _rect_in_menu(painel, menu)
	var combat_top := UiConstants.WINDOW_HEIGHT - UiConstants.COMBAT_RESERVED_SPACE
	if state_id == "hub_combat_top":
		if rect.position.y < UiConstants.COMBAT_RESERVED_SPACE - TOL:
			_record_failure(
				state_id,
				"Panel",
				rect,
				"panel top >= COMBAT_RESERVED_SPACE (%.1f)" % UiConstants.COMBAT_RESERVED_SPACE
			)
	elif state_id in ["hub_combat_bottom", "formation_open", "skills_open", "warehouse_open", "forge_open"]:
		if rect.end.y > combat_top + TOL:
			_record_failure(
				state_id,
				"Panel",
				rect,
				"panel bottom <= combat band (%.1f)" % combat_top
			)


func _check_hub_width(
	state_id: String,
	painel: Control,
	menu_area: Control,
	layout: InventoryLayout,
	menu: Control
) -> void:
	var panel_rect := _rect_in_menu(painel, menu)
	var row_rect := _rect_in_menu(menu_area, menu)
	if row_rect.size.x > UiConstants.WINDOW_WIDTH + TOL:
		_record_failure(
			state_id,
			"MenuArea",
			row_rect,
			"menu row width <= WINDOW_WIDTH (%d)" % UiConstants.WINDOW_WIDTH
		)
	var min_w := maxf(layout.panel_min_width * 0.9, layout.inventory_row_pixel_size().x)
	var max_w := float(UiConstants.WINDOW_WIDTH) - 80.0
	if panel_rect.size.x < min_w - TOL or panel_rect.size.x > max_w + TOL:
		_record_failure(
			state_id,
			"Panel",
			panel_rect,
			"panel width in [%.0f, %.0f]" % [min_w, max_w]
		)


func _check_vertical_stack(menu: Control, state_id: String) -> void:
	var names: PackedStringArray = ["Header", "AreaHeroi", "LinhaInventario", "MenuInferior"]
	var nodes: Array[Control] = []
	for node_name in names:
		var node := menu.get_node_or_null("%" + node_name) as Control
		if node != null:
			nodes.append(node)
	for i in range(nodes.size() - 1):
		var upper := nodes[i]
		var lower := nodes[i + 1]
		if not upper.visible or not lower.visible:
			continue
		var upper_rect := _rect_in_menu(upper, menu)
		var lower_rect := _rect_in_menu(lower, menu)
		if upper_rect.end.y > lower_rect.position.y + TOL:
			_record_failure(
				state_id,
				"%s -> %s" % [upper.name, lower.name],
				Rect2(upper_rect.position, upper_rect.size + lower_rect.size),
				"upper end.y <= lower start.y"
			)


func _check_slot_sizes(menu: Control, state_id: String, layout: InventoryLayout) -> void:
	if not menu.has_method("inventory_slots_grid"):
		return
	var grid: InventorySlotsGrid = menu.get("inventory_slots_grid")
	if grid == null:
		_record_failure(state_id, "InventoryGrid", Rect2(), "inventory grid should exist")
		return
	var slots: Array = grid.slots()
	if slots.is_empty():
		_record_failure(state_id, "InventoryGrid", Rect2(), "inventory grid should have slots")
		return
	var slot_rect := _rect_in_menu(slots[0] as Control, menu)
	var expected := layout.inventory_slot_size.x
	if absf(slot_rect.size.x - expected) > 2.0 or absf(slot_rect.size.y - expected) > 2.0:
		_record_failure(
			state_id,
			"InventorySlot",
			slot_rect,
			"slot size ~= %.0f" % expected
		)


func _check_nav_sizes(menu: Control, state_id: String, layout: InventoryLayout) -> void:
	var nav := menu.get_node_or_null("%MenuInferior") as Control
	if nav == null:
		return
	var btn := nav.get_node_or_null("%SkillsButton") as Control
	if btn == null:
		return
	var rect := _rect_in_menu(btn, menu)
	var min_h := float(layout.bottom_bar_height) * 0.8
	if rect.size.y < min_h - TOL:
		_record_failure(
			state_id,
			"SkillsButton",
			rect,
			"nav button height >= %.0f" % min_h
		)


func _check_overlay_coverage(menu: Control, state_id: String, painel: Control) -> void:
	var overlay_name := ""
	match state_id:
		"formation_open":
			overlay_name = "FormationPanel"
		"skills_open":
			overlay_name = "SkillsPanel"
		"attributes_open":
			overlay_name = "AttributesPanel"
		_:
			return
	var overlay := menu.get_node_or_null("%" + overlay_name) as Control
	if overlay == null or not overlay.visible:
		_record_failure(state_id, overlay_name, Rect2(), "overlay should be visible")
		return
	var panel_rect := _rect_in_menu(painel, menu)
	var overlay_rect := _rect_in_menu(overlay, menu)
	var panel_area := _area(panel_rect)
	if panel_area <= 0.0:
		return
	var coverage := _area(overlay_rect) / panel_area
	if coverage < OVERLAY_COVERAGE:
		_record_failure(
			state_id,
			overlay_name,
			overlay_rect,
			"overlay covers >= %.0f%% of panel" % (OVERLAY_COVERAGE * 100.0)
		)
	var grid := menu.get_node_or_null("%LinhaInventario") as Control
	if grid != null and grid.is_visible_in_tree():
		var grid_rect := _rect_in_menu(grid, menu)
		var overlap := _intersection_area(grid_rect, overlay_rect)
		if overlap / maxf(_area(grid_rect), 1.0) > GRID_OVERLAP_MAX:
			_record_failure(
				state_id,
				"LinhaInventario",
				grid_rect,
				"grid overlap with overlay <= %.0f%%" % (GRID_OVERLAP_MAX * 100.0)
			)


func _check_screen_visible(menu: Control, state_id: String) -> void:
	var panel_name := ""
	match state_id:
		"skill_tree_open":
			panel_name = "SkillTreePanel"
		"worlds_open":
			panel_name = "WorldsPanel"
		"settings_open":
			panel_name = "SettingsPanel"
		_:
			return
	var panel := menu.get_node_or_null("%" + panel_name) as Control
	if panel == null or not panel.visible:
		_record_failure(state_id, panel_name, Rect2(), "%s should be visible" % panel_name)


func _record_failure(state_id: String, node_name: String, rect: Rect2, expected: String) -> void:
	_failures.append({
		"state": state_id,
		"node": node_name,
		"rect": {
			"x": rect.position.x,
			"y": rect.position.y,
			"w": rect.size.x,
			"h": rect.size.y,
		},
		"expected": expected,
	})


func _area(rect: Rect2) -> float:
	return maxf(0.0, rect.size.x) * maxf(0.0, rect.size.y)


func _intersection_area(a: Rect2, b: Rect2) -> float:
	var left := maxf(a.position.x, b.position.x)
	var top := maxf(a.position.y, b.position.y)
	var right := minf(a.end.x, b.end.x)
	var bottom := minf(a.end.y, b.end.y)
	if right <= left or bottom <= top:
		return 0.0
	return (right - left) * (bottom - top)
