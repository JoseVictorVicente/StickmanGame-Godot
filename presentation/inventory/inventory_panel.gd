class_name InventoryPanel
extends VBoxContainer
## Inventory hub band: scrollable 5 rows × 10 cols (49 usable + expand).

@onready var inventory_scroll: ScrollContainer = %InventoryScroll
@onready var inventory_grid: InventorySlotsGrid = %InventoryGrid

var _menu: Node


func configure(menu: Node, _layout: InventoryLayout = null) -> void:
	_menu = menu
	if inventory_grid and menu:
		menu.inventory_slot_list = inventory_grid.setup(Callable(menu, "connect_item_slot"))
