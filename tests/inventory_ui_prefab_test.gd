extends SceneTree
## Smoke test for inventory UI prefabs (item_slot + equipment_grid).


const ITEM_SLOT_SCENE := preload("res://presentation/inventory/item_slot.tscn")
const EQUIPMENT_GRID_SCENE := preload("res://presentation/inventory/equipment_grid.tscn")
const EQUIPMENT_GRID_LEFT_SCENE := preload("res://presentation/inventory/equipment_grid_left.tscn")
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
const HERO_SECTION_SCENE := preload("res://presentation/inventory/hero_section.tscn")


func _initialize() -> void:
	var slot := ITEM_SLOT_SCENE.instantiate() as ItemSlot
	assert(slot != null, "item_slot scene should instantiate")
	assert(slot.get_icon_rect() != null, "item_slot should expose Icone node")
	slot.configure()
	assert(slot.icone_rect != null, "configure should bind Icone")

	var grid := EQUIPMENT_GRID_SCENE.instantiate() as EquipmentGrid
	assert(grid != null, "equipment_grid scene should instantiate")
	var tipos: Array[ItemData.Type] = [ItemData.Type.WEAPON, ItemData.Type.CHEST]
	var slots := grid.build_slots(tipos, LAYOUT)
	assert(slots.size() == 2, "equipment grid should build one slot per type")
	assert(slots[1].accepted_type == ItemData.Type.CHEST, "chest slot should keep type")

	var baked_left := EQUIPMENT_GRID_LEFT_SCENE.instantiate() as EquipmentGrid
	assert(baked_left != null, "equipment_grid_left scene should instantiate")
	assert(baked_left.get_child_count() == 7, "left equip grid should bake 7 slots")
	var left_slots := baked_left.build_slots(EquipmentGrid.LEFT_TYPES, LAYOUT)
	assert(left_slots.size() == 7, "build_slots should reuse baked left slots")

	var inv_grid := INVENTORY_SLOTS_GRID_SCENE.instantiate() as InventorySlotsGrid
	assert(inv_grid != null, "inventory_slots_grid scene should instantiate")
	assert(inv_grid.get_child_count() == 50, "inventory grid scene should bake 50 slots")
	var inv_slots := inv_grid.slots()
	assert(inv_slots.size() == 50, "inventory grid should expose 10x5 slots")

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

	var hero_section := HERO_SECTION_SCENE.instantiate() as HeroSection
	assert(hero_section != null, "hero_section scene should instantiate")
	root.add_child(hero_section)
	var equip_left := hero_section.get_node("%EquipLeft") as VBoxContainer
	var equip_count := 0
	for filho in equip_left.get_children():
		if str(filho.name).begins_with("EquipLeft_"):
			equip_count += 1
	assert(equip_count == 6, "hero section should bake 6 left equip grids")
	hero_section.queue_free()

	print("[TEST PASS] Inventory UI prefabs")
	quit()
