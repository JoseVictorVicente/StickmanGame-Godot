extends SceneTree
## Inventory hub vertical band: menu sits above/below combat reserve via OverlayVBox spacers.


const MENU_SCENE := preload("res://presentation/inventory/inventory_menu.tscn")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var host := Control.new()
	host.custom_minimum_size = Vector2(UiConstants.WINDOW_WIDTH, UiConstants.WINDOW_HEIGHT)
	host.size = host.custom_minimum_size
	root.add_child(host)

	var menu := MENU_SCENE.instantiate() as InventoryMenu
	assert(menu != null, "inventory menu should instantiate")
	host.add_child(menu)
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.size = host.size

	await process_frame
	await process_frame

	menu.set_below_combat(false)
	await process_frame
	await process_frame

	var painel := menu.get_node("%Panel") as Control
	var panel_rect := painel.get_global_rect()
	var combat_top := UiConstants.WINDOW_HEIGHT - UiConstants.COMBAT_RESERVED_SPACE

	assert(panel_rect.position.y > 50.0, "panel should not stick to top when combat is at bottom")
	assert(
		panel_rect.end.y <= combat_top + 8.0,
		"panel bottom should sit above combat reserve (got %.1f, limit %.1f)" % [panel_rect.end.y, combat_top]
	)

	menu.set_below_combat(true)
	await process_frame
	await process_frame

	panel_rect = painel.get_global_rect()
	assert(
		panel_rect.position.y >= UiConstants.COMBAT_RESERVED_SPACE - 8.0,
		"panel should open below top combat band when menu opens downward"
	)

	print("[TEST PASS] Inventory menu layout")
	quit()
