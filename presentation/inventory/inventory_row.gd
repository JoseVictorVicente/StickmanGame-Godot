class_name InventoryRow
extends HBoxContainer
## Linha do inventário: ordenar + grade 10×5 + armazém.

@onready var sort_button: Button = %SortInventoryButton
@onready var inventory_grid: InventorySlotsGrid = %InventoryGrid
@onready var warehouse_button: Button = %WarehouseButton
