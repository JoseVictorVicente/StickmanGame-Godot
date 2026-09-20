@tool
class_name HeroCharacterPanel
extends VBoxContainer
## Center hub panel: portrait, XP, attributes, party row.

signal attributes_requested

const DEFAULT_LAYOUT := preload("res://presentation/inventory/inventory_layout_default.tres")

@export var layout_resource: InventoryLayout = DEFAULT_LAYOUT

@onready var portrait_area: Control = %PortraitArea
@onready var character_portrait: TextureRect = %CharacterPortrait
@onready var character_xp_bar: ProgressBar = %CharacterXpBar
@onready var character_xp_label: Label = %CharacterXpLabel
@onready var character_attributes_button: Button = %CharacterAttributesButton
@onready var party_slots: HBoxContainer = %PartySlots
@onready var character_row: HBoxContainer = %CharacterRow
@onready var character_name_label: Label = %CharacterNameLabel
@onready var character_level_label: Label = %CharacterLevelLabel
@onready var team_ui: TeamSelectionUI = %TeamArea

var _menu: Node


func _ready() -> void:
	if Engine.is_editor_hint():
		call_deferred("_apply_editor_preview")
	elif character_row:
		character_row.visible = false


func configure(menu: Node) -> void:
	_menu = menu
	if character_attributes_button and not character_attributes_button.pressed.is_connected(_on_attributes_pressed):
		character_attributes_button.pressed.connect(_on_attributes_pressed)


func apply_layout(layout: InventoryLayout = null) -> void:
	var tokens := _resolve_layout(layout)
	if tokens == null:
		return
	custom_minimum_size = tokens.hero_character_panel_size()
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	add_theme_constant_override("separation", tokens.spacing_tight)
	if portrait_area:
		portrait_area.custom_minimum_size = tokens.portrait_pixel_size()
	if party_slots:
		party_slots.custom_minimum_size = Vector2(
			tokens.equip_block_pixel_size(3, 1).x,
			tokens.party_hero_slot_size.y
		)
		party_slots.add_theme_constant_override("separation", tokens.spacing_tight)
	if character_attributes_button:
		character_attributes_button.custom_minimum_size = Vector2(28, 28)
		character_attributes_button.text = ""
	if team_ui:
		team_ui.layout_resource = tokens
		for i in PartyService.SLOTS:
			var party_slot := team_ui.get_node_or_null("%%PartySlot%d" % i) as Button
			if party_slot:
				party_slot.custom_minimum_size = tokens.party_hero_slot_size


func wire_character_selector(
	hero_slots: Array,
	slot_size: Vector2,
	style_factory: Callable,
	on_selected: Callable
) -> Array[Button]:
	var buttons: Array[Button] = []
	if character_row == null:
		return buttons
	for stage_index in hero_slots.size():
		var botao := character_row.get_node_or_null("Character_%d" % (stage_index + 1)) as Button
		if botao == null:
			continue
		botao.custom_minimum_size = slot_size
		botao.add_theme_font_size_override("font_size", 11)
		botao.add_theme_color_override("font_color", Color(0.95, 0.88, 0.7, 1))
		if style_factory.is_valid():
			botao.add_theme_stylebox_override("pressed", style_factory.call(true))
		if on_selected.is_valid():
			botao.pressed.connect(on_selected.bind(stage_index))
		buttons.append(botao)
	return buttons


func set_character_button_style(buttons: Array[Button], selected_index: int, style_factory: Callable) -> void:
	if not style_factory.is_valid():
		return
	for i in buttons.size():
		var selected := i == selected_index
		var style: StyleBoxFlat = style_factory.call(selected)
		buttons[i].add_theme_stylebox_override("normal", style)
		buttons[i].add_theme_stylebox_override("hover", style)


func set_character_header(name_text: String, level_text: String) -> void:
	if character_name_label:
		character_name_label.text = name_text
	if character_level_label:
		character_level_label.text = level_text


func update_portrait(classe: ClassData) -> void:
	if character_portrait == null:
		return
	character_portrait.texture = classe.character_sprite if classe else null
	character_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func update_xp_bar(level: int, xp: int, xp_next: int) -> void:
	if character_xp_bar == null:
		return
	var next_val := maxi(1, xp_next)
	character_xp_bar.max_value = float(next_val)
	character_xp_bar.value = clampf(float(xp), 0.0, float(next_val))
	if character_xp_label:
		character_xp_label.text = tr(LocaleKeys.UI_LEVEL_FORMAT) % [level, xp, next_val]


func _on_attributes_pressed() -> void:
	attributes_requested.emit()


func _resolve_layout(layout: InventoryLayout) -> InventoryLayout:
	var tokens := layout if layout else layout_resource
	if tokens == null:
		tokens = DEFAULT_LAYOUT
	return InventoryLayout.duplicate_synced(tokens)


func _apply_editor_preview() -> void:
	apply_layout()
