class_name HeroCharacterPanel
extends VBoxContainer
## Center hub panel: portrait, ultimate placeholder, attributes, party row.

signal attributes_requested

@onready var character_portrait: TextureRect = %CharacterPortrait
@onready var character_xp_bar: ProgressBar = %CharacterXpBar
@onready var character_xp_label: Label = %CharacterXpLabel
@onready var character_attributes_button: TextureButton = %CharacterAttributesButton
@onready var ultimate_slot_button: Button = %UltimateSlotButton
@onready var party_slots: HBoxContainer = %PartySlots
@onready var character_name_label: Label = %CharacterNameLabel
@onready var character_level_label: Label = %CharacterLevelLabel
@onready var team_ui: TeamSelectionUI = %TeamArea

var _menu: Node


func configure(menu: Node) -> void:
	_menu = menu
	if character_attributes_button and not character_attributes_button.pressed.is_connected(_on_attributes_pressed):
		character_attributes_button.pressed.connect(_on_attributes_pressed)


func wire_character_selector(
	_hero_slots: Array,
	_slot_size: Vector2,
	_style_factory: Callable,
	_on_selected: Callable
) -> Array[Button]:
	return []


func set_character_button_style(_buttons: Array[Button], _selected_index: int, _style_factory: Callable) -> void:
	pass


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
