class_name BottomNav
extends HBoxContainer
## Bottom navigation bar for the inventory menu.

signal nav_requested(action: String)

const NAV_WORLD_ICON := preload("res://presentation/inventory/nav_world_icon.gd")
const HOVER_SCALE := 1.12
const HOVER_TWEEN_DURATION := 0.08

@onready var storage_button: Button = %StorageButton
@onready var skills_button: Button = %SkillsButton
@onready var tree_button: Button = %TreeButton
@onready var formation_button: Button = %FormationButton
@onready var forge_button: Button = %ForgePanelButton
@onready var world_button: Button = %WorldButton

var _menu: InventoryMenu
var _nav_tweens: Dictionary = {}
var _world_icon_anim: RefCounted = NAV_WORLD_ICON.new()


func _ready() -> void:
	set_process(true)
	resized.connect(_sync_nav_button_pivots)
	call_deferred("_sync_nav_button_pivots")


func configure(menu: InventoryMenu, _layout: InventoryLayout = null) -> void:
	_menu = menu
	_wire_buttons(menu)
	_setup_world_animated_icon()
	call_deferred("_sync_nav_button_pivots")


func apply_bar_icons(menu: InventoryMenu) -> void:
	if menu == null:
		return
	if skills_button:
		menu.setup_bar_button(skills_button, "skills")
	menu.setup_bar_button(tree_button, "inventory")
	menu.setup_bar_button(forge_button, "forge")
	_setup_world_animated_icon()


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
	for botao in _nav_buttons():
		_wire_nav_hover(botao)
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


func _nav_buttons() -> Array[Button]:
	return [
		storage_button,
		skills_button,
		tree_button,
		formation_button,
		forge_button,
		world_button,
	]


func _setup_world_animated_icon() -> void:
	if world_button == null:
		return
	world_button.icon = null
	world_button.expand_icon = true
	world_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	world_button.remove_theme_constant_override("icon_max_width")
	_world_icon_anim.reset(InterfaceIcons.nav_world_frames())
	var first: Texture2D = _world_icon_anim.advance(0.0)
	if first == null:
		first = InterfaceIcons.bar_icon("world")
	if first:
		world_button.icon = first


func _process(delta: float) -> void:
	if world_button == null:
		return
	var frame: Texture2D = _world_icon_anim.advance(delta)
	if frame:
		world_button.icon = frame


func _wire_nav_hover(botao: Button) -> void:
	if botao == null:
		return
	if not botao.mouse_entered.is_connected(_on_nav_mouse_entered):
		botao.mouse_entered.connect(_on_nav_mouse_entered.bind(botao))
	if not botao.mouse_exited.is_connected(_on_nav_mouse_exited):
		botao.mouse_exited.connect(_on_nav_mouse_exited.bind(botao))


func _on_nav_mouse_entered(botao: Button) -> void:
	_tween_nav_scale(botao, HOVER_SCALE)


func _on_nav_mouse_exited(botao: Button) -> void:
	_tween_nav_scale(botao, 1.0)


func _sync_nav_button_pivots() -> void:
	for botao in _nav_buttons():
		if botao:
			botao.pivot_offset = _nav_button_pivot(botao)


func _nav_button_pivot(botao: Control) -> Vector2:
	var size := botao.size
	if size.x < 1.0 or size.y < 1.0:
		size = botao.custom_minimum_size
	return size * 0.5


func _tween_nav_scale(botao: Button, target_scale: float) -> void:
	if botao == null:
		return
	botao.pivot_offset = _nav_button_pivot(botao)
	var target := Vector2.ONE * target_scale
	if Engine.is_editor_hint():
		botao.scale = target
		return
	var key := botao.get_instance_id()
	if _nav_tweens.has(key):
		var old_tween: Variant = _nav_tweens[key]
		if old_tween is Tween and (old_tween as Tween).is_valid():
			(old_tween as Tween).kill()
	var tween := botao.create_tween()
	_nav_tweens[key] = tween
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(botao, "scale", target, HOVER_TWEEN_DURATION)
