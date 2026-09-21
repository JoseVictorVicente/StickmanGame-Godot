class_name InventoryPanelRouter
extends RefCounted
## Opens/closes inventory side panels and full-bleed overlays.


var _menu: InventoryMenu


func setup(menu: InventoryMenu) -> void:
	_menu = menu


func close_overlay_panels(except: Control = null) -> void:
	if _menu.formation_panel_node and _menu.formation_panel_node != except and _menu.formation_panel_node.is_open():
		_menu.formation_panel_node.close()
	if _menu.attributes_panel_node and _menu.attributes_panel_node != except and _menu.attributes_panel_node.is_open():
		_menu.attributes_panel_node.close()
	if _menu.skills_panel_node and _menu.skills_panel_node != except and _menu.skills_panel_node.is_open():
		_menu.skills_panel_node.close()
	if _menu.skill_tree_panel_node and _menu.skill_tree_panel_node != except and _menu.skill_tree_panel_node.is_open():
		_menu.skill_tree_panel_node.close()


func close_right_panels(except: Control = null) -> void:
	if _menu.forge_panel_node and _menu.forge_panel_node != except and _menu.forge_panel_node.is_open():
		_menu.forge_panel_node.close()
	if _menu.worlds_panel_node and _menu.worlds_panel_node != except and _menu.worlds_panel_node.is_open():
		_menu.worlds_panel_node.close()


func set_inventory_visible(visible_hub: bool) -> void:
	if _menu.hub_content == null or _menu.hub_body == null:
		return
	_menu.restore_base_panel()
	_menu.hub_content.visible = visible_hub


func open_forge() -> void:
	if _menu.forge_panel_node.is_open():
		_menu.forge_panel_node.close()
	else:
		close_right_panels(_menu.forge_panel_node)
		_menu.forge_panel_node.open()
	_menu.forge_button.release_focus()


func open_warehouse() -> void:
	_menu.warehouse_panel_node.toggle()
	_menu.storage_button.release_focus()


func open_worlds() -> void:
	if _menu.worlds_panel_node.is_open():
		_menu.worlds_panel_node.close()
	else:
		close_right_panels(_menu.worlds_panel_node)
		_menu.worlds_panel_node.open()
	_menu.world_button.release_focus()


func open_formation() -> void:
	if _menu.formation_panel_node.is_open():
		_menu.formation_panel_node.close()
		return
	close_overlay_panels(_menu.formation_panel_node)
	close_right_panels()
	_menu.formation_panel_node.open()


func open_skills(slot_hero: int = -1, slot_type: SkillResource.Type = SkillResource.Type.ACTIVE, slot_index: int = 0) -> void:
	close_overlay_panels(_menu.skills_panel_node)
	close_right_panels()
	if _menu.skills_panel_node:
		var hero := slot_hero if slot_hero >= 0 else _menu.current_character_index()
		_menu.skills_panel_node.open(hero, slot_type, slot_index)


func open_attributes() -> void:
	close_overlay_panels(_menu.attributes_panel_node)
	if _menu.attributes_panel_node:
		_menu.attributes_panel_node.open()


func open_skill_tree() -> void:
	close_overlay_panels(_menu.skill_tree_panel_node)
	close_right_panels()
	if _menu.skill_tree_panel_node:
		_menu.skill_tree_panel_node.open()


func on_overlay_visibility_changed(open: bool) -> void:
	set_inventory_visible(not open)
	_menu.align_side_panels()
	_menu.call_deferred("align_side_panels")


func on_forge_visibility_changed(open: bool) -> void:
	if not open:
		_menu.clear_slot_selection()
		_menu.restore_forge_button_style()
		_menu.align_side_panels()
		return
	var style := _menu.create_active_side_button_style()
	if _menu.forge_button:
		_menu.forge_button.add_theme_stylebox_override("normal", style)
		_menu.forge_button.add_theme_stylebox_override("hover", style)
		_menu.forge_button.add_theme_stylebox_override("pressed", style)
	_menu.align_side_panels()


func on_warehouse_visibility_changed(open: bool) -> void:
	if open:
		var style := _menu.create_active_side_button_style()
		if _menu.storage_button:
			_menu.storage_button.add_theme_stylebox_override("normal", style)
			_menu.storage_button.add_theme_stylebox_override("hover", style)
			_menu.storage_button.add_theme_stylebox_override("pressed", style)
		_menu.align_side_panels()
		return
	_menu.restore_warehouse_button_style()
	_menu.align_side_panels()


func on_worlds_visibility_changed(open: bool) -> void:
	if open:
		var style := _menu.create_active_side_button_style()
		if _menu.world_button:
			_menu.world_button.add_theme_stylebox_override("normal", style)
			_menu.world_button.add_theme_stylebox_override("hover", style)
			_menu.world_button.add_theme_stylebox_override("pressed", style)
		_menu.align_side_panels()
		return
	_menu.restore_world_button_style()
	_menu.align_side_panels()
