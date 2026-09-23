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
var _warehouse_icon_anim: RefCounted = NAV_WORLD_ICON.new()
var _skills_icon_anim: RefCounted = NAV_WORLD_ICON.new()
var _tree_icon_anim: RefCounted = NAV_WORLD_ICON.new()
var _forge_icon_anim: RefCounted = NAV_WORLD_ICON.new()
var _formation_icon_anim: RefCounted = NAV_WORLD_ICON.new()
var _world_icon_anim: RefCounted = NAV_WORLD_ICON.new()


func _ready() -> void:
	set_process(true)
	resized.connect(_sync_nav_button_pivots)
	call_deferred("_sync_nav_button_pivots")


func configure(menu: InventoryMenu, _layout: InventoryLayout = null) -> void:
	_menu = menu
	_wire_buttons(menu)
	_setup_warehouse_animated_icon()
	_setup_skills_animated_icon()
	_setup_tree_animated_icon()
	_setup_forge_animated_icon()
	_setup_formation_animated_icon()
	_setup_world_animated_icon()
	call_deferred("_sync_nav_button_pivots")


func apply_bar_icons(menu: InventoryMenu) -> void:
	if menu == null:
		return
	_setup_warehouse_animated_icon()
	_setup_skills_animated_icon()
	_setup_tree_animated_icon()
	_setup_forge_animated_icon()
	_setup_formation_animated_icon()
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


func _setup_animated_nav_icon(
	botao: Button,
	anim: RefCounted,
	frames: SpriteFrames,
	fallback_bar_key: String
) -> void:
	if botao == null:
		return
	botao.icon = null
	botao.expand_icon = true
	botao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	botao.remove_theme_constant_override("icon_max_width")
	anim.reset(frames)
	var first: Texture2D = anim.advance(0.0)
	if first == null:
		first = InterfaceIcons.bar_icon(fallback_bar_key)
	if first:
		botao.icon = first


func _setup_warehouse_animated_icon() -> void:
	_setup_animated_nav_icon(
		storage_button,
		_warehouse_icon_anim,
		InterfaceIcons.nav_warehouse_frames(),
		"warehouse"
	)


func _setup_skills_animated_icon() -> void:
	_setup_animated_nav_icon(
		skills_button,
		_skills_icon_anim,
		InterfaceIcons.nav_skills_frames(),
		"skills"
	)


func _setup_tree_animated_icon() -> void:
	_setup_animated_nav_icon(
		tree_button,
		_tree_icon_anim,
		InterfaceIcons.nav_inventory_frames(),
		"inventory"
	)


func _setup_forge_animated_icon() -> void:
	_setup_animated_nav_icon(
		forge_button,
		_forge_icon_anim,
		InterfaceIcons.nav_forge_frames(),
		"forge"
	)


func _setup_formation_animated_icon() -> void:
	_setup_animated_nav_icon(
		formation_button,
		_formation_icon_anim,
		InterfaceIcons.nav_formation_frames(),
		"formation"
	)


func _setup_world_animated_icon() -> void:
	_setup_animated_nav_icon(
		world_button,
		_world_icon_anim,
		InterfaceIcons.nav_world_frames(),
		"world"
	)


func _process(delta: float) -> void:
	if storage_button:
		var warehouse_frame: Texture2D = _warehouse_icon_anim.advance(delta)
		if warehouse_frame:
			storage_button.icon = warehouse_frame
	if skills_button:
		var skills_frame: Texture2D = _skills_icon_anim.advance(delta)
		if skills_frame:
			skills_button.icon = skills_frame
	if tree_button:
		var tree_frame: Texture2D = _tree_icon_anim.advance(delta)
		if tree_frame:
			tree_button.icon = tree_frame
	if forge_button:
		var forge_frame: Texture2D = _forge_icon_anim.advance(delta)
		if forge_frame:
			forge_button.icon = forge_frame
	if formation_button:
		var formation_frame: Texture2D = _formation_icon_anim.advance(delta)
		if formation_frame:
			formation_button.icon = formation_frame
	if world_button:
		var world_frame: Texture2D = _world_icon_anim.advance(delta)
		if world_frame:
			world_button.icon = world_frame


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
