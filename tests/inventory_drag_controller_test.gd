extends SceneTree
## Smoke test for InventoryDragController wiring.


func _initialize() -> void:
	var drag := InventoryDragController.new()
	var menu := InventoryMenu.new()
	drag.setup(menu)
	drag.clear_selection()
	drag.set_selection(null)
	print("[TEST PASS] InventoryDragController")
	quit()
