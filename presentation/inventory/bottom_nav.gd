@tool
class_name BottomNav
extends HBoxContainer
## Bottom navigation bar for the inventory menu.

signal nav_requested(action: String)

const DEFAULT_LAYOUT := preload("res://presentation/inventory/inventory_layout_default.tres")

@export var layout_resource: InventoryLayout = DEFAULT_LAYOUT

@onready var storage_button: Button = %StorageButton
@onready var skills_button: Button = %SkillsButton
@onready var tree_button: Button = %TreeButton
@onready var formation_button: Button = %FormationButton
@onready var forge_button: Button = %ForgePanelButton
@onready var world_button: Button = %WorldButton

var _menu: InventoryMenu


func _ready() -> void:
	if Engine.is_editor_hint():
		call_deferred("_apply_editor_preview")


func configure(menu: InventoryMenu, layout: InventoryLayout = null) -> void:
	_menu = menu
	apply_layout(layout)
	_wire_buttons(menu)


func apply_layout(layout: InventoryLayout = null) -> void:
	var tokens := _resolve_layout(layout)
	if tokens == null:
		return
	var grid_w := tokens.inventory_grid_pixel_size().x
	var bar_h := float(tokens.bottom_bar_height)
	custom_minimum_size = Vector2(grid_w, bar_h)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_END
	alignment = BoxContainer.ALIGNMENT_END
	for botao in _nav_buttons():
		_style_nav_button(botao, tokens)


func apply_bar_icons(menu: InventoryMenu) -> void:
	if menu == null:
		return
	if skills_button:
		menu.setup_bar_button(skills_button, "skills")
	menu.setup_bar_button(tree_button, "inventory")
	menu.setup_bar_button(forge_button, "forge")
	menu.setup_bar_button(world_button, "world")


func _wire_buttons(menu: InventoryMenu) -> void:
	if storage_button and not storage_button.pressed.is_connected(_on_storage_pressed):
		storage_button.pressed.connect(_on_storage_pressed)
	if skills_button and not skills_button.pressed.is_connected(_on_skills_pressed):
		skills_button.pressed.connect(_on_skills_pressed)
	if tree_button and not tree_button.pressed.is_connected(_on_tree_pressed):
		tree_button.pressed.connect(_on_tree_pressed)
	if formation_button and not formation_button.pressed.is_connected(_on_formation_pressed):
		formation_button.pressed.connect(_on_formation_pressed)
	if forge_button and not forge_button.pressed.is_connected(_on_forge_pressed):
		forge_button.pressed.connect(_on_forge_pressed)
	if world_button and not world_button.pressed.is_connected(_on_world_pressed):
		world_button.pressed.connect(_on_world_pressed)
	apply_bar_icons(menu)


func _on_storage_pressed() -> void:
	nav_requested.emit("storage")


func _on_skills_pressed() -> void:
	nav_requested.emit("skills")


func _on_tree_pressed() -> void:
	nav_requested.emit("tree")


func _on_formation_pressed() -> void:
	nav_requested.emit("formation")


func _on_forge_pressed() -> void:
	nav_requested.emit("forge")


func _on_world_pressed() -> void:
	nav_requested.emit("world")


func _resolve_layout(layout: InventoryLayout) -> InventoryLayout:
	var tokens := layout if layout else layout_resource
	if tokens == null:
		tokens = DEFAULT_LAYOUT
	return InventoryLayout.duplicate_synced(tokens)


func _apply_editor_preview() -> void:
	apply_layout()


func _nav_buttons() -> Array[Button]:
	return [
		storage_button,
		skills_button,
		tree_button,
		formation_button,
		forge_button,
		world_button,
	]


func _style_nav_button(botao: Button, tokens: InventoryLayout) -> void:
	if botao == null:
		return
	var bar_h := float(tokens.bottom_bar_height)
	botao.text = ""
	botao.custom_minimum_size = Vector2(0, bar_h)
	botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	botao.size_flags_vertical = Control.SIZE_EXPAND_FILL
	botao.expand_icon = false
	botao.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	botao.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	botao.add_theme_constant_override("icon_max_width", tokens.nav_icon_max_width)
