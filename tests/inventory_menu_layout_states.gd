class_name InventoryMenuLayoutStates
extends RefCounted
## Shared inventory_menu hub states for geometry audit and visual capture.


const STATE_IDS: PackedStringArray = [
	"hub_combat_bottom",
	"hub_combat_top",
	"formation_open",
	"skills_open",
	"warehouse_open",
	"forge_open",
]


static func reset_menu(menu: Control) -> void:
	menu.call("set_below_combat", false)
	if menu.has_method("_set_inventory_visible"):
		menu.call("_set_inventory_visible", true)
	var conteudo := menu.get_node_or_null("%Conteudo") as Control
	if conteudo:
		conteudo.visible = true
	for overlay_name in ["FormationPanel", "AttributesPanel", "SkillsPanel", "SkillTreePanel"]:
		var overlay := menu.get_node_or_null("%" + overlay_name) as Control
		if overlay:
			overlay.hide()
	var warehouse := menu.get_node_or_null("%WarehousePanel") as Control
	if warehouse:
		warehouse.hide()
	var forge := menu.get_node_or_null("%PanelForgePanel") as Control
	if forge:
		forge.hide()


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
		"warehouse_open":
			menu.call("set_below_combat", false)
			var warehouse := menu.get_node_or_null("%WarehousePanel") as Control
			if warehouse:
				warehouse.show()
		"forge_open":
			menu.call("set_below_combat", false)
			var forge := menu.get_node_or_null("%PanelForgePanel") as Control
			if forge:
				forge.show()
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
