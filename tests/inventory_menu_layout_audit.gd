extends SceneTree
## Geometric audit for inventory_menu hub: bands, widths, stack order, overlays.


const LAYOUT := preload("res://presentation/inventory/inventory_layout_default.tres")
const MENU_SCENE_PATH := "res://presentation/inventory/inventory_menu.tscn"
const LayoutStates := preload("res://tests/inventory_menu_layout_states.gd")

const TEST_HOST_GROUP := "inventory_layout_test_host"
const TOL := 12.0
const WORLDS_TOL := 2.0
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
	var painel := menu.get_node_or_null("%HubBody") as Control
	var menu_area := menu.get_node_or_null("%MenuArea") as Control
	var layout := LAYOUT.duplicate() as InventoryLayout
	layout.sync_from_base_unit()
	if painel == null or menu_area == null:
		_record_failure(state_id, "Panel/MenuArea", Rect2(), "hub nodes should exist")
		return
	if painel.visible:
		_check_combat_band(state_id, painel, menu)
		_check_hub_width(state_id, painel, menu_area, layout, menu)
		_check_panel_viewport_fit(state_id, layout)
		_check_hero_inventory_width(state_id, menu, layout)
	var conteudo := menu.get_node_or_null("%HubContent") as Control
	if conteudo != null and conteudo.visible:
		_check_vertical_stack(menu, state_id)
		_check_slot_sizes(menu, state_id, layout)
		_check_nav_sizes(menu, state_id, layout)
	_check_overlay_coverage(menu, state_id, painel)
	_check_screen_visible(menu, state_id)
	_check_side_panel_visible(menu, state_id, painel)
	_check_worlds_panel_invariants(menu, state_id)


func _rect_in_menu(control: Control, menu: Control) -> Rect2:
	var global_rect := control.get_global_rect()
	var origin := menu.get_global_rect().position
	return Rect2(global_rect.position - origin, global_rect.size)


func _check_hero_inventory_width(state_id: String, menu: Control, layout: InventoryLayout) -> void:
	var upper_row := menu.get_node_or_null("%HubUpperRow") as Control
	var inv_panel := menu.get_node_or_null("%InventoryPanel") as Control
	if upper_row == null or inv_panel == null or not upper_row.visible or not inv_panel.visible:
		return
	var hero_rect := _rect_in_menu(upper_row, menu)
	var row_rect := _rect_in_menu(inv_panel, menu)
	var target_w := layout.hub_content_pixel_width()
	if absf(hero_rect.size.x - target_w) > TOL:
		_record_failure(
			state_id,
			"HubUpperRow",
			hero_rect,
			"hero row width ~= inventory hub width (%.0f)" % target_w
		)
	if absf(row_rect.size.x - target_w) > TOL:
		_record_failure(
			state_id,
			"InventoryPanel",
			row_rect,
			"inventory panel width ~= hub content width (%.0f)" % target_w
		)
	if absf(hero_rect.size.x - row_rect.size.x) > TOL:
		_record_failure(
			state_id,
			"HubUpperRow/InventoryPanel",
			Rect2(hero_rect.position, hero_rect.size + row_rect.size),
			"hero and inventory panel share width"
		)
	if absf(hero_rect.position.x - row_rect.position.x) > TOL:
		_record_failure(
			state_id,
			"HubUpperRow/InventoryPanel",
			Rect2(hero_rect.position, hero_rect.size + row_rect.size),
			"hero and inventory panel left edges align"
		)


func _check_panel_viewport_fit(state_id: String, layout: InventoryLayout) -> void:
	var max_h := layout.max_hub_panel_pixel_height()
	var column_h := layout.hub_column_pixel_height()
	if column_h > max_h + TOL:
		_record_failure(
			state_id,
			"InventoryLayout",
			Rect2(),
			"hub column height %.1f <= viewport max %.1f (run sync_from_base_unit / fit_panel_to_viewport)"
			% [column_h, max_h]
		)


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
	var names: PackedStringArray = ["HubUpperRow", "InventoryPanel", "BottomNav"]
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
	var nav := menu.get_node_or_null("%BottomNav") as Control
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
	var grid := menu.get_node_or_null("%InventoryPanel") as Control
	if grid != null and grid.is_visible_in_tree():
		var grid_rect := _rect_in_menu(grid, menu)
		var overlap := _intersection_area(grid_rect, overlay_rect)
		if overlap / maxf(_area(grid_rect), 1.0) > GRID_OVERLAP_MAX:
			_record_failure(
				state_id,
				"InventoryPanel",
				grid_rect,
				"grid overlap with overlay <= %.0f%%" % (GRID_OVERLAP_MAX * 100.0)
			)


func _check_screen_visible(menu: Control, state_id: String) -> void:
	var panel_name := ""
	match state_id:
		"skill_tree_open":
			panel_name = "SkillTreePanel"
		"worlds_open", "worlds_briefing_open", "worlds_trail_open":
			panel_name = "WorldsPanel"
		"settings_open":
			panel_name = "SettingsPanel"
		_:
			return
	var panel := menu.get_node_or_null("%" + panel_name) as Control
	if panel == null or not panel.is_visible_in_tree():
		_record_failure(state_id, panel_name, Rect2(), "%s should be visible in tree" % panel_name)
		return
	if state_id == "skill_tree_open" and _area(_rect_in_menu(panel, menu)) <= 1.0:
		_record_failure(state_id, panel_name, _rect_in_menu(panel, menu), "skill tree panel should have area > 0")


func _check_side_panel_visible(menu: Control, state_id: String, painel: Control) -> void:
	var panel_name := ""
	match state_id:
		"warehouse_open":
			panel_name = "WarehousePanel"
		"forge_open":
			panel_name = "PanelForgePanel"
		"worlds_open", "worlds_briefing_open", "worlds_trail_open":
			panel_name = "WorldsPanel"
		_:
			return
	var panel := menu.get_node_or_null("%" + panel_name) as Control
	if panel == null or not panel.is_visible_in_tree():
		_record_failure(state_id, panel_name, Rect2(), "%s should be visible in tree" % panel_name)
		return
	var panel_rect := _rect_in_menu(panel, menu)
	if panel_rect.size.x < 200.0:
		_record_failure(state_id, panel_name, panel_rect, "side panel width >= 200")
	if painel != null:
		var hub_rect := _rect_in_menu(painel, menu)
		if hub_rect.size.y > 1.0 and panel_rect.size.y < hub_rect.size.y * 0.8:
			_record_failure(
				state_id,
				panel_name,
				panel_rect,
				"side panel height >= 80%% of hub (%.0f)" % hub_rect.size.y
			)
	var menu_rect := _rect_in_menu(menu.get_node_or_null("%MenuArea") as Control, menu)
	if menu_rect.size.x > 1.0:
		var panel_end := panel_rect.position.x + panel_rect.size.x
		var menu_end := menu_rect.position.x + menu_rect.size.x
		if panel_rect.position.x < menu_rect.position.x - TOL or panel_end > menu_end + TOL:
			_record_failure(state_id, panel_name, panel_rect, "side panel should stay inside MenuArea")


func _check_worlds_panel_invariants(menu: Control, state_id: String) -> void:
	if state_id not in ["worlds_open", "worlds_briefing_open", "worlds_trail_open"]:
		return
	var worlds := menu.get_node_or_null("%WorldsPanel") as Control
	if worlds == null or not worlds.is_visible_in_tree():
		return
	var panel_rect := _rect_in_menu(worlds, menu)
	if panel_rect.size.x < 200.0:
		return
	match state_id:
		"worlds_open":
			_check_worlds_hall_invariants(state_id, worlds, panel_rect, menu)
		"worlds_briefing_open":
			_check_worlds_briefing_invariants(state_id, worlds, panel_rect, menu)
		"worlds_trail_open":
			_check_worlds_trail_invariants(state_id, worlds, panel_rect, menu)


func _check_worlds_hall_invariants(state_id: String, worlds: Control, panel_rect: Rect2, menu: Control) -> void:
	var list_panel := worlds.get_node_or_null("%WorldListPanel") as Control
	var footer := worlds.get_node_or_null("Margem/Conteudo/RodapeDificuldade") as Control
	var difficulty := worlds.get_node_or_null("%DifficultyButton") as Control
	if list_panel == null or not list_panel.is_visible_in_tree():
		_record_failure(state_id, "WorldListPanel", panel_rect, "hall list should be visible")
		return
	var cards: Array[Control] = []
	for i in WorldProgress.TOTAL_WORLDS:
		var card := list_panel.get_node_or_null("WorldList/PortalCard_%d" % (i + 1)) as Control
		if card and card.is_visible_in_tree():
			cards.append(card)
	if cards.size() < WorldProgress.TOTAL_WORLDS:
		_record_failure(state_id, "PortalCards", panel_rect, "hall should show 5 portal cards")
	for j in range(cards.size()):
		for k in range(j + 1, cards.size()):
			var overlap := _intersection_area(_rect_in_menu(cards[j], menu), _rect_in_menu(cards[k], menu))
			if overlap > WORLDS_TOL:
				_record_failure(state_id, "PortalCard overlap", _rect_in_menu(cards[j], menu), "portal cards should not overlap")
	if footer == null or not footer.is_visible_in_tree():
		_record_failure(state_id, "RodapeDificuldade", panel_rect, "hall footer should be visible")
	elif difficulty != null:
		var diff_rect := _rect_in_menu(difficulty, menu)
		if diff_rect.end.y > panel_rect.end.y + WORLDS_TOL:
			_record_failure(state_id, "DifficultyButton", diff_rect, "difficulty button should stay inside WorldsPanel")


func _check_worlds_briefing_invariants(state_id: String, worlds: Control, panel_rect: Rect2, menu: Control) -> void:
	var briefing := worlds.get_node_or_null("%RealmBriefingPanel") as Control
	if briefing == null or not briefing.is_visible_in_tree():
		_record_failure(state_id, "RealmBriefingPanel", panel_rect, "briefing panel should be visible")
		return
	var banner := briefing.get_node_or_null("%BriefingBanner") as Control
	var art_frame := briefing.get_node_or_null("%BriefingArtFrame") as Control
	var enter_btn := briefing.get_node_or_null("%EnterPortalButton") as Control
	var demon := briefing.get_node_or_null("%BriefingDemonKing") as Control
	var frame_rect := _rect_in_menu(art_frame, menu) if art_frame else Rect2()
	if frame_rect.size.y < 80.0:
		_record_failure(state_id, "BriefingArtFrame", frame_rect, "briefing banner height >= 80")
	if banner != null:
		var banner_rect := _rect_in_menu(banner, menu)
		if _area(banner_rect) <= 1.0:
			_record_failure(state_id, "BriefingBanner", banner_rect, "briefing banner area > 0")
	var layout_nodes: Array[Control] = []
	for node_name in ["BriefingArtFrame", "BriefingBody", "BriefingFooterSpacer", "BriefingDemonKing", "EnterPortalButton"]:
		var node := briefing.get_node_or_null(node_name) as Control
		if node != null and node.is_visible_in_tree() and node.name != "BriefingFooterSpacer":
			if node.size.y >= 1.0 or node.name == "BriefingArtFrame":
				layout_nodes.append(node)
	_check_worlds_no_overlap(state_id, layout_nodes, menu, panel_rect)
	if enter_btn != null:
		var enter_rect := _rect_in_menu(enter_btn, menu)
		if enter_rect.end.y > panel_rect.end.y + WORLDS_TOL:
			_record_failure(state_id, "EnterPortalButton", enter_rect, "enter portal button should stay inside WorldsPanel")
	if demon != null and enter_btn != null:
		var overlap := _intersection_area(_rect_in_menu(demon, menu), _rect_in_menu(enter_btn, menu))
		if overlap > WORLDS_TOL:
			_record_failure(state_id, "BriefingDemonKing", _rect_in_menu(demon, menu), "boss label should not overlap CTA")


func _check_worlds_trail_invariants(state_id: String, worlds: Control, panel_rect: Rect2, menu: Control) -> void:
	var map_panel := worlds.get_node_or_null("%PanelStageMap") as Control
	var trail_difficulty_row := worlds.get_node_or_null("%TrailDifficultyRow") as Control
	var trail_difficulty := worlds.get_node_or_null("%TrailDifficultyButton") as Control
	var progress := worlds.get_node_or_null("%TrailProgressLabel") as Control
	if map_panel == null or not map_panel.is_visible_in_tree():
		_record_failure(state_id, "PanelStageMap", panel_rect, "trail map should be visible")
		return
	if progress == null or not progress.is_visible_in_tree():
		_record_failure(state_id, "TrailProgressLabel", panel_rect, "trail progress label should be visible")
	if trail_difficulty_row == null or not trail_difficulty_row.is_visible_in_tree():
		_record_failure(state_id, "TrailDifficultyRow", panel_rect, "trail difficulty row should be visible in header")
	var stage_map := map_panel.get_node_or_null("%StageMap") as Control if map_panel else null
	if stage_map != null:
		for i in WorldProgress.STAGES_PER_WORLD:
			var ancora := stage_map.get_node_or_null("StageAnchor_%d" % (i + 1)) as Control
			if ancora == null or not ancora.is_visible_in_tree():
				continue
			var stage_rect := _rect_in_menu(ancora, menu)
			if stage_rect.size.y < 1.0:
				continue
			if stage_rect.position.x < panel_rect.position.x - WORLDS_TOL:
				_record_failure(state_id, "StageAnchor_%d" % (i + 1), stage_rect, "stage node should stay inside WorldsPanel")
			if stage_rect.end.x > panel_rect.end.x + WORLDS_TOL:
				_record_failure(state_id, "StageAnchor_%d" % (i + 1), stage_rect, "stage node should stay inside WorldsPanel")
			if stage_rect.position.y < panel_rect.position.y - WORLDS_TOL:
				_record_failure(state_id, "StageAnchor_%d" % (i + 1), stage_rect, "stage node should stay inside WorldsPanel")
			if stage_rect.end.y > panel_rect.end.y + WORLDS_TOL:
				_record_failure(state_id, "StageAnchor_%d" % (i + 1), stage_rect, "stage node should stay inside WorldsPanel")
	if trail_difficulty != null:
		var diff_rect := _rect_in_menu(trail_difficulty, menu)
		if diff_rect.end.y > panel_rect.end.y + WORLDS_TOL:
			_record_failure(state_id, "TrailDifficultyButton", diff_rect, "difficulty button should stay inside WorldsPanel")


func _check_worlds_no_overlap(state_id: String, nodes: Array[Control], menu: Control, panel_rect: Rect2) -> void:
	for j in range(nodes.size()):
		for k in range(j + 1, nodes.size()):
			var a := _rect_in_menu(nodes[j], menu)
			var b := _rect_in_menu(nodes[k], menu)
			var overlap := _intersection_area(a, b)
			if overlap > WORLDS_TOL:
				_record_failure(
					state_id,
					"%s -> %s" % [nodes[j].name, nodes[k].name],
					a,
					"worlds panel children should not overlap"
				)


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
