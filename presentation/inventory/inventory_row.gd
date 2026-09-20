class_name InventoryRow
extends VBoxContainer
## Linha do inventário: formação + ordenar + grade 10×5 + armazém.

@onready var formation_button: Button = %FormationButton
@onready var sort_button: Button = %SortInventoryButton
@onready var inventory_grid: InventorySlotsGrid = %InventoryGrid
@onready var warehouse_button: Button = %WarehouseButton
