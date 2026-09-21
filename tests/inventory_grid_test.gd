extends SceneTree
## Fixed 5 rows × 10 cols inventory grid (49 usable + expand), layout tokens, and overflow.


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var layout := preload("res://presentation/inventory/inventory_layout_default.tres") as InventoryLayout
	assert(layout.expected_slot_count() == 50, "layout should define 50 display slots")
	assert(layout.usable_inventory_slot_count() == 49, "layout should define 49 usable slots")
	assert(layout.inventory_grid_columns == 10, "layout should use 10 columns")
	assert(layout.inventory_grid_rows == 5, "layout should use 5 rows")
	var grid_size := layout.inventory_grid_pixel_size()
	assert(grid_size.x >= 420.0 and grid_size.y >= 210.0, "grid should reserve pixel size")

	var inv_grid_scene := preload("res://presentation/inventory/inventory_slots_grid.tscn")
	var inv_grid: InventorySlotsGrid = inv_grid_scene.instantiate()
	assert(inv_grid.slots().size() == 50, "baked grid should expose 50 slots")
	assert(inv_grid.usable_slots().size() == 49, "baked grid should expose 49 usable slots")
	var expand := inv_grid.expand_slot()
	assert(expand != null, "slot 50 should be baked as expand placeholder")
	expand.set_expand_placeholder(true)
	assert(expand.is_expand_placeholder, "expand slot should be marked as placeholder")
	assert(not expand.aceita(ItemData.new()), "expand slot must reject items")

	var menu_packed := load("res://presentation/inventory/inventory_menu.tscn") as PackedScene
	assert(menu_packed != null, "inventory menu scene should load")
	var menu: Node = menu_packed.instantiate()
	assert(menu != null, "inventory menu should instantiate")
	root.add_child(menu)
	await process_frame
	assert(menu.has_method("inventory_slots"), "menu should expose inventory_slots")
	var menu_slots: Array = menu.call("inventory_slots")
	assert(menu_slots.size() == 50, "runtime menu should wire 50 display slots")

	var drop_slot: ItemSlot = menu.call("first_empty_inventory_slot")
	assert(drop_slot != null, "menu should expose an empty inventory slot")
	assert(drop_slot.accepts_any, "combat drops must target inventory slots, not equipment")

	var usable := 0
	for slot in menu.inventory_slots_grid.usable_slots():
		var item := ItemData.new()
		item.id = "fill_%d" % usable
		(slot as ItemSlot).set_item(item)
		usable += 1
	assert(usable == 49, "usable slots should accept 49 items")
	assert(not menu.call("try_add_inventory_item", ItemData.new()), "full inventory should reject item")

	var grid: InventorySlotsGrid = menu.inventory_slots_grid
	assert(grid != null, "inventory grid node should exist")
	assert(grid.get_child_count() == 50, "menu grid should keep 50 slot nodes")

	print("[TEST PASS] inventory grid 5r x 10c")
	quit(0)
