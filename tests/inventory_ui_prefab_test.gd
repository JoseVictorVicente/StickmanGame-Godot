extends SceneTree
## Smoke test for inventory UI prefabs (item_slot + hub panels).


const ITEM_SLOT_SCENE := preload("res://presentation/inventory/item_slot.tscn")
const HERO_EQUIP_LEFT_SCENE := preload("res://presentation/inventory/hero_equip_left_panel.tscn")
const HERO_EQUIP_RIGHT_SCENE := preload("res://presentation/inventory/hero_equip_right_panel.tscn")
const HERO_CHARACTER_SCENE := preload("res://presentation/inventory/hero_character_panel.tscn")
const INVENTORY_PANEL_SCENE := preload("res://presentation/inventory/inventory_panel.tscn")
const INVENTORY_SLOTS_GRID_SCENE := preload("res://presentation/inventory/inventory_slots_grid.tscn")
const WAREHOUSE_SLOTS_GRID_SCENE := preload("res://presentation/inventory/warehouse_slots_grid.tscn")
const LAYOUT := preload("res://presentation/inventory/inventory_layout_default.tres")
const FORMATION_PARTY_SLOT_SCENE := preload("res://presentation/inventory/formation_party_slot.tscn")
const SKILLS_ACTIVE_GRID_SCENE := preload("res://presentation/inventory/skills_active_grid.tscn")
const SKILLS_PASSIVE_GRID_SCENE := preload("res://presentation/inventory/skills_passive_grid.tscn")
const FORMATION_PANEL_SCENE := preload("res://presentation/inventory/formation_panel.tscn")
const WAREHOUSE_PANEL_SCENE := preload("res://presentation/inventory/warehouse_panel.tscn")
const ATTRIBUTES_PANEL_SCENE := preload("res://presentation/inventory/attributes_panel.tscn")
const FORGE_PANEL_SCENE := preload("res://presentation/inventory/forge_panel.tscn")
const SETTINGS_PANEL_SCENE := preload("res://presentation/inventory/settings_panel.tscn")


func _initialize() -> void:
	var slot := ITEM_SLOT_SCENE.instantiate() as ItemSlot
	assert(slot != null, "item_slot scene should instantiate")
	assert(slot.get_icon_rect() != null, "item_slot should expose Icone node")
	slot.configure()
	assert(slot.icone_rect != null, "configure should bind Icone")

	var left_panel := HERO_EQUIP_LEFT_SCENE.instantiate() as HeroEquipLeftPanel
	assert(left_panel != null, "hero_equip_left_panel scene should instantiate")
	root.add_child(left_panel)
	left_panel.apply_layout(LAYOUT)
	assert(left_panel.all_equipment_slots().size() == 7, "left equip panel should expose 7 baked slots")
	assert(left_panel.get_node("%ActiveColumn") != null, "left panel should bake active skill column")
	left_panel.queue_free()

	var right_panel := HERO_EQUIP_RIGHT_SCENE.instantiate() as HeroEquipRightPanel
	assert(right_panel != null, "hero_equip_right_panel scene should instantiate")
	root.add_child(right_panel)
	right_panel.apply_layout(LAYOUT)
	assert(right_panel.slots().size() == 5, "right equip panel should expose 4 jewelry + pet slots")
	assert(right_panel.get_node("%SortInventoryButton") != null, "sort button should be baked in scene")
	assert(right_panel.get_node("%PassiveColumn") != null, "right panel should bake passive skill column")
	right_panel.queue_free()

	var character_panel := HERO_CHARACTER_SCENE.instantiate() as HeroCharacterPanel
	assert(character_panel != null, "hero_character_panel scene should instantiate")
	root.add_child(character_panel)
	assert(character_panel.get_node("%PortraitArea") != null, "character panel should bake portrait area")
	assert(character_panel.get_node("%PartySlots") != null, "character panel should bake party slots")
	character_panel.queue_free()

	var inventory_panel := INVENTORY_PANEL_SCENE.instantiate() as InventoryPanel
	assert(inventory_panel != null, "inventory_panel scene should instantiate")
	root.add_child(inventory_panel)
	inventory_panel.apply_layout(LAYOUT)
	assert(inventory_panel.get_node("%InventoryGrid") != null, "inventory panel should bake grid")
	inventory_panel.queue_free()

	var inv_grid := INVENTORY_SLOTS_GRID_SCENE.instantiate() as InventorySlotsGrid
	assert(inv_grid != null, "inventory_slots_grid scene should instantiate")
	var inv_built := inv_grid.ensure_slots(LAYOUT)
	assert(inv_built.size() == 50, "inventory grid should build 5x10 display slots")
	var inv_slots := inv_grid.slots()
	assert(inv_slots.size() == 50, "inventory grid should expose 5x10 slots")
	assert(inv_grid.usable_slots().size() == 49, "inventory grid should expose 49 usable slots")

	var wh_grid := WAREHOUSE_SLOTS_GRID_SCENE.instantiate() as WarehouseSlotsGrid
	assert(wh_grid != null, "warehouse_slots_grid scene should instantiate")
	assert(wh_grid.get_child_count() == 40, "warehouse grid scene should bake 40 slots")
	var wh_slots := wh_grid.slots()
	assert(wh_slots.size() == 40, "warehouse grid should expose 5x8 slots")

	var form_slot := FORMATION_PARTY_SLOT_SCENE.instantiate()
	assert(form_slot != null, "formation_party_slot scene should instantiate")
	root.add_child(form_slot)
	assert(form_slot.get_node("%HeroButton") != null, "formation slot should expose hero button")
	assert(form_slot.get_node("%RemoveButton") != null, "formation slot should expose remove button")
	form_slot.queue_free()

	var active_skills_grid := SKILLS_ACTIVE_GRID_SCENE.instantiate() as SkillsActiveGrid
	assert(active_skills_grid != null, "skills_active_grid scene should instantiate")
	assert(active_skills_grid.get_child_count() == 6, "active skills grid should bake 6 slots")
	assert(active_skills_grid.active_slots().size() == 6, "active skills grid should expose 6 slots")

	var passive_skills_grid := SKILLS_PASSIVE_GRID_SCENE.instantiate() as SkillsPassiveGrid
	assert(passive_skills_grid != null, "skills_passive_grid scene should instantiate")
	assert(passive_skills_grid.get_child_count() == 10, "passive skills grid should bake 10 slots")
	assert(passive_skills_grid.passive_slots().size() == 10, "passive skills grid should expose 10 slots")

	var formation_panel := FORMATION_PANEL_SCENE.instantiate()
	assert(formation_panel != null, "formation_panel scene should instantiate")
	root.add_child(formation_panel)
	var hero_grid := formation_panel.get_node("%FormationHeroGrid") as FormationHeroGrid
	assert(hero_grid != null, "formation panel should expose hero grid")
	assert(hero_grid.get_child_count() == 6, "formation hero grid should bake 6 heroes")
	formation_panel.queue_free()

	var warehouse_panel := WAREHOUSE_PANEL_SCENE.instantiate()
	assert(warehouse_panel != null, "warehouse_panel scene should instantiate")
	root.add_child(warehouse_panel)
	var tab_row := warehouse_panel.get_node("%TabRow") as GridContainer
	var wh_parent_grid := warehouse_panel.get_node("%WarehouseGrid") as GridContainer
	assert(tab_row.get_child_count() == 8, "warehouse panel should bake 8 tabs")
	assert(wh_parent_grid.get_child_count() == 8, "warehouse panel should bake 8 tab grids")
	for i in 8:
		var grade := wh_parent_grid.get_node("GradeAba_%d" % i) as WarehouseSlotsGrid
		assert(grade != null, "warehouse should bake GradeAba_%d" % i)
		assert(grade.get_child_count() == 40, "warehouse tab grid should bake 40 slots")
	warehouse_panel.queue_free()

	var attributes_panel := ATTRIBUTES_PANEL_SCENE.instantiate()
	assert(attributes_panel != null, "attributes_panel scene should instantiate")
	root.add_child(attributes_panel)
	var attr_list := attributes_panel.get_node("%AttributesList") as VBoxContainer
	assert(attr_list.get_child_count() == 12, "attributes panel should bake 12 rows")
	attributes_panel.queue_free()

	var forge_panel := FORGE_PANEL_SCENE.instantiate()
	assert(forge_panel != null, "forge_panel scene should instantiate")
	root.add_child(forge_panel)
	var gems_area := forge_panel.get_node("%GemsArea") as HBoxContainer
	assert(gems_area.get_child_count() == 3, "forge gems area should bake 3 children")
	forge_panel.queue_free()

	var settings_panel := SETTINGS_PANEL_SCENE.instantiate() as SettingsPanel
	assert(settings_panel != null, "settings_panel scene should instantiate")
	assert(settings_panel.close_settings_button != null, "settings panel should expose close button")
	assert(settings_panel.option_locale != null, "settings panel should expose locale selector")
	settings_panel.queue_free()

	print("[TEST PASS] Inventory UI prefabs")
	quit()
