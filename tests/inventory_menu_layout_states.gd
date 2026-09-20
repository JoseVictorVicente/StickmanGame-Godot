class_name InventoryMenuLayoutStates
extends RefCounted
## Shared inventory_menu screen states for geometry audit and visual capture.


const STATE_IDS: PackedStringArray = [
	"hub_combat_bottom",
	"hub_combat_top",
	"formation_open",
	"skills_open",
	"attributes_open",
	"skill_tree_open",
	"warehouse_open",
	"forge_open",
	"worlds_open",
	"settings_open",
]

const OVERLAY_PANELS: PackedStringArray = [
	"FormationPanel",
	"AttributesPanel",
	"SkillsPanel",
	"SkillTreePanel",
]

const SIDE_PANELS: PackedStringArray = [
	"WarehousePanel",
	"PanelForgePanel",
	"WorldsPanel",
]


static func reset_menu(menu: Control) -> void:
	menu.call("set_below_combat", false)
	if menu.has_method("_set_inventory_visible"):
		menu.call("_set_inventory_visible", true)
	var conteudo := menu.get_node_or_null("%Conteudo") as Control
	if conteudo:
		conteudo.visible = true
	if menu.has_method("_close_settings"):
		menu.call("_close_settings")
	for panel_name in OVERLAY_PANELS:
		_close_panel(menu, panel_name)
	for panel_name in SIDE_PANELS:
		_close_panel(menu, panel_name)
	if menu.has_method("_align_side_panels"):
		menu.call("_align_side_panels")


static func apply_state(menu: Control, state_id: String) -> void:
	match state_id:
		"hub_combat_bottom":
			menu.call("set_below_combat", false)
		"hub_combat_top":
			menu.call("set_below_combat", true)
		"formation_open":
			menu.call("set_below_combat", false)
			_show_overlay(menu, "FormationPanel")
		"skills_open":
			menu.call("set_below_combat", false)
			_show_overlay(menu, "SkillsPanel")
		"attributes_open":
			menu.call("set_below_combat", false)
			_show_overlay(menu, "AttributesPanel")
		"skill_tree_open":
			menu.call("set_below_combat", false)
			if menu.has_method("_open_skill_tree"):
				menu.call("_open_skill_tree")
			else:
				_show_overlay(menu, "SkillTreePanel")
		"warehouse_open":
			menu.call("set_below_combat", false)
			_open_side_panel(menu, "WarehousePanel")
		"forge_open":
			menu.call("set_below_combat", false)
			_open_side_panel(menu, "PanelForgePanel")
		"worlds_open":
			menu.call("set_below_combat", false)
			_open_side_panel(menu, "WorldsPanel")
		"settings_open":
			menu.call("set_below_combat", false)
			if menu.has_method("_open_settings"):
				menu.call("_open_settings")
			else:
				var settings := menu.get_node_or_null("%SettingsPanel") as Control
				if settings:
					settings.show()
		_:
			push_error("Unknown inventory menu layout state: %s" % state_id)


static func instantiate_menu(host: Control, menu_scene: PackedScene) -> Control:
	var menu := menu_scene.instantiate() as Control
	if menu == null:
		return null
	host.add_child(menu)
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.size = host.size
	menu.show()
	return menu


static func settle(tree: SceneTree, menu: Control) -> void:
	if menu.has_method("_apply_panel_layout"):
		menu.call("_apply_panel_layout")
	if menu.has_method("_align_side_panels"):
		menu.call("_align_side_panels")
	for _i in 5:
		await tree.process_frame


static func _close_panel(menu: Control, panel_name: String) -> void:
	var panel := menu.get_node_or_null("%" + panel_name)
	if panel == null:
		return
	if panel.has_method("is_open") and panel.has_method("close") and panel.is_open():
		panel.close()
	elif panel is CanvasItem:
		(panel as CanvasItem).hide()


static func _open_side_panel(menu: Control, panel_name: String) -> void:
	var panel := menu.get_node_or_null("%" + panel_name)
	if menu.has_method("_close_right_panels"):
		menu.call("_close_right_panels", panel)
	if panel and panel.has_method("open"):
		panel.open()


static func _show_overlay(menu: Control, overlay_name: String) -> void:
	if menu.has_method("_set_inventory_visible"):
		menu.call("_set_inventory_visible", false)
	var conteudo := menu.get_node_or_null("%Conteudo") as Control
	if conteudo:
		conteudo.visible = false
	var overlay := menu.get_node_or_null("%" + overlay_name) as Control
	if overlay:
		overlay.show()
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var painel := menu.get_node_or_null("%Panel") as PanelContainer
	if painel:
		PanelLayout.align_overlays(
			painel,
			menu.get_node_or_null("%FormationPanel") as Control,
			menu.get_node_or_null("%AttributesPanel") as Control,
			menu.get_node_or_null("%SkillsPanel") as Control,
			menu.get_node_or_null("%SkillTreePanel") as Control
		)
