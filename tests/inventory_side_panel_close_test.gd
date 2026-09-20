extends SceneTree
## Smoke test: open/close warehouse and worlds without runtime errors.

const MENU_SCENE := preload("res://presentation/inventory/inventory_menu.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.custom_minimum_size = Vector2(960, 860)
	root.add_child(host)

	var menu := MENU_SCENE.instantiate() as Control
	host.add_child(menu)
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.size = host.custom_minimum_size
	menu.show()

	for _i in 3:
		await process_frame

	var warehouse := menu.get_node_or_null("%WarehousePanel")
	var worlds := menu.get_node_or_null("%WorldsPanel")
	assert(warehouse != null, "warehouse panel should exist")
	assert(worlds != null, "worlds panel should exist")

	warehouse.open()
	await process_frame
	warehouse.close()
	await process_frame

	worlds.open()
	await process_frame
	worlds.close()
	await process_frame

	print("[PASS] inventory side panel close smoke test")
	quit()
