extends SceneTree
## Fixed 5×10 inventory grid (49 usable + expand placeholder), layout tokens, and overflow.


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var layout := preload("res://presentation/inventory/inventory_layout_default.tres") as InventoryLayout
	layout.sync_from_base_unit()
	assert(layout.expected_slot_count() == 50, "layout should define 50 display slots")
	assert(layout.usable_inventory_slot_count() == 49, "layout should define 49 usable slots")
	assert(layout.inventory_grid_columns == 10, "layout should use 10 columns")
	assert(layout.inventory_grid_rows == 5, "layout should use 5 rows")
	var grid_size := layout.inventory_grid_pixel_size()
	assert(grid_size.x > 200.0 and grid_size.y > 100.0, "grid should reserve pixel size")
	assert(
		layout.hero_row_pixel_size().x == layout.hub_content_pixel_width(),
		"hero row width should match inventory hub content width"
	)
	assert(
		layout.hub_column_pixel_height() <= layout.max_hub_panel_pixel_height() + 0.5,
		"hub column height must fit overlay viewport after sync"
	)

	var inv_grid_scene := preload("res://presentation/inventory/inventory_slots_grid.tscn")
	var inv_grid: InventorySlotsGrid = inv_grid_scene.instantiate()
	var ensured := inv_grid.ensure_slots(layout)
	assert(ensured.size() == 50, "ensure_slots should build 50 slots")
	assert(inv_grid.expand_slot() != null, "grid should expose expand placeholder slot")
	assert(inv_grid.columns == 10, "grid should lay out 10 columns")

	var menu_packed := load("res://presentation/inventory/inventory_menu.tscn") as PackedScene
	assert(menu_packed != null, "inventory menu scene should load")
	var menu: Node = menu_packed.instantiate()
	assert(menu != null, "inventory menu should instantiate")
	root.add_child(menu)
	await process_frame
	assert(menu.has_method("inventory_slots"), "menu should expose inventory_slots")
	var menu_slots: Array = menu.call("inventory_slots")
	assert(menu_slots.size() == 50, "runtime menu should wire 50 slots")

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

	print("[TEST PASS] Inventory grid layout")
	quit()
