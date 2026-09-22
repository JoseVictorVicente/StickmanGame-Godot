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
	assert(left_panel.all_equipment_slots().size() == 7, "left equip panel should expose 7 baked slots")
	assert(left_panel.get_node("%SlotSkillAtiva0") != null, "left panel should bake active skill slots")
	assert(left_panel.get_node("%UltimateSlotButton") != null, "left panel should bake ultimate placeholder")
	left_panel.queue_free()

	var right_panel := HERO_EQUIP_RIGHT_SCENE.instantiate() as HeroEquipRightPanel
	assert(right_panel != null, "hero_equip_right_panel scene should instantiate")
	root.add_child(right_panel)
	assert(right_panel.slots().size() == 5, "right equip panel should expose 4 jewelry + pet slots")
	assert(right_panel.get_node("%SortInventoryButton") != null, "sort button should be baked in scene")
	assert(right_panel.get_node("%SlotSkillMenuPassiva0") != null, "right panel should bake passive skill slots")
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
	assert(inventory_panel.get_node("%InventoryGrid") != null, "inventory panel should bake grid")
	inventory_panel.queue_free()

	var inv_grid := INVENTORY_SLOTS_GRID_SCENE.instantiate() as InventorySlotsGrid
	assert(inv_grid != null, "inventory_slots_grid scene should instantiate")
	assert(inv_grid.slots().size() == 50, "inventory grid should bake 5 rows x 10 cols")
	assert(inv_grid.usable_slots().size() == 49, "inventory grid should expose 49 usable slots")
	assert(inv_grid.expand_slot() != null, "slot 50 should be expand placeholder")

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
	assert(active_skills_grid.get_child_count() == 3, "active skills grid should bake 3 rows")
	assert(active_skills_grid.type_slots().size() == 3, "active skills grid should expose 3 type slots")
	assert(active_skills_grid.active_slots().size() == 15, "active skills grid should expose 15 skill slots")

	var passive_grid := SKILLS_PASSIVE_GRID_SCENE.instantiate()
	assert(passive_grid != null, "skills_passive_grid scene should instantiate")
	root.add_child(passive_grid)
	await process_frame
	passive_grid.queue_free()

	var formation := FORMATION_PANEL_SCENE.instantiate()
	assert(formation != null, "formation_panel scene should instantiate")
	formation.queue_free()

	var warehouse := WAREHOUSE_PANEL_SCENE.instantiate()
	assert(warehouse != null, "warehouse_panel scene should instantiate")
	warehouse.queue_free()

	var attributes := ATTRIBUTES_PANEL_SCENE.instantiate()
	assert(attributes != null, "attributes_panel scene should instantiate")
	attributes.queue_free()

	var forge := FORGE_PANEL_SCENE.instantiate()
	assert(forge != null, "forge_panel scene should instantiate")
	forge.queue_free()

	var settings := SETTINGS_PANEL_SCENE.instantiate()
	assert(settings != null, "settings_panel scene should instantiate")
	settings.queue_free()

	assert(LAYOUT.inventory_grid_columns == 10, "default layout resource should use 10 columns")
	assert(LAYOUT.inventory_grid_rows == 5, "default layout resource should use 5 rows")

	print("[TEST PASS] inventory UI prefabs")
	quit(0)
