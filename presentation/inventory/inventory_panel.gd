@tool
class_name InventoryPanel
extends VBoxContainer
## Inventory hub band: scrollable 5×10 grid (sort lives in hero_equip_right_panel).

const DEFAULT_LAYOUT := preload("res://presentation/inventory/inventory_layout_default.tres")

@export var layout_resource: InventoryLayout = DEFAULT_LAYOUT

@onready var inventory_scroll: ScrollContainer = %InventoryScroll
@onready var inventory_grid: InventorySlotsGrid = %InventoryGrid

var _menu: Node


func _ready() -> void:
	if Engine.is_editor_hint():
		call_deferred("_apply_editor_preview")


func configure(menu: Node, layout: InventoryLayout = null) -> void:
	_menu = menu
	apply_layout(layout)
	if inventory_grid and menu:
		menu.inventory_slot_list = inventory_grid.setup(Callable(menu, "connect_item_slot"))


func apply_layout(layout: InventoryLayout = null) -> void:
	var tokens := _resolve_layout(layout)
	if tokens == null:
		return
	var grid_size := tokens.inventory_grid_pixel_size()
	var visible_h := tokens.inventory_scroll_viewport_height()
	custom_minimum_size = tokens.inventory_panel_size()
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	if inventory_scroll:
		inventory_scroll.custom_minimum_size = Vector2(grid_size.x, visible_h)
		inventory_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN


func _resolve_layout(layout: InventoryLayout) -> InventoryLayout:
	var tokens := layout if layout else layout_resource
	if tokens == null:
		tokens = DEFAULT_LAYOUT
	return InventoryLayout.duplicate_synced(tokens)


func _apply_editor_preview() -> void:
	apply_layout()
