extends SceneTree
## Fixed 10x5 inventory grid, layout tokens, and try_add_inventory_item overflow.


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var layout := preload("res://presentation/inventory/inventory_layout_default.tres") as InventoryLayout
	layout.sync_from_base_unit()
	assert(layout.expected_slot_count() == 50, "layout should define 50 slots")
	var grid_size := layout.inventory_grid_pixel_size()
	assert(grid_size.x > 300.0 and grid_size.y > 150.0, "grid should reserve pixel size")

	var inv_grid_scene := preload("res://presentation/inventory/inventory_slots_grid.tscn")
	var inv_grid: InventorySlotsGrid = inv_grid_scene.instantiate()
	assert(inv_grid.get_child_count() == 50, "baked grid scene should have 50 slot children")

	var slots := inv_grid.slots()
	assert(slots.size() == 50, "slots() should return 50 baked slots")
	assert(inv_grid.custom_minimum_size == grid_size or inv_grid.custom_minimum_size.x > 0.0,
		"grid should reserve pixel size after layout apply")

	var child_count_before := inv_grid.get_child_count()
	var ensured := inv_grid.ensure_slots(layout)
	assert(ensured.size() == 50, "ensure_slots should keep 50 slots")
	assert(inv_grid.get_child_count() == child_count_before, "ensure_slots should not recreate baked nodes")

	var menu_packed := load("res://presentation/inventory/inventory_menu.tscn") as PackedScene
	assert(menu_packed != null, "inventory menu scene should load")
	var menu: Node = menu_packed.instantiate()
	assert(menu != null, "inventory menu should instantiate")
	root.add_child(menu)
	await process_frame
	assert(menu.has_method("inventory_slots"), "menu should expose inventory_slots")
	var menu_slots: Array = menu.call("inventory_slots")
	assert(menu_slots.size() == 50, "runtime menu should wire 50 slots")

	for slot in menu_slots:
		var item := ItemData.new()
		item.id = "fill_%d" % (slot as ItemSlot).get_index()
		(slot as ItemSlot).set_item(item)
	assert(not menu.call("try_add_inventory_item", ItemData.new()), "full inventory should reject item")

	var grid: InventorySlotsGrid = menu.inventory_slots_grid
	assert(grid != null, "inventory grid node should exist")
	assert(grid.get_child_count() == 50, "menu grid should keep 50 slot nodes")

	print("[TEST PASS] Inventory grid layout")
	quit()
