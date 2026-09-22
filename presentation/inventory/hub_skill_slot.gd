class_name HubSkillSlot
extends Button
## Hub equip skill slot — same black fill and slot_border chrome as ItemSlot.

const SCENE := preload("res://presentation/inventory/hub_skill_slot.tscn")
const SLOT_FRAME_TEXTURE := preload("res://sprites/ui/slot_border.png")
const SLOT_FRAME_BLEED_BASE_SIZE := 42.0
const SLOT_FRAME_BLEED_BASE_PX := 2.0
const SLOT_ICON_INSET_BASE_SIZE := 42.0
const SLOT_ICON_INSET_BASE_PX := 5.0
const EMPTY_TEXT := "+"

@onready var slot_frame: TextureRect = %SlotFrame
@onready var skill_icon: TextureRect = %SkillIcon
@onready var placeholder_label: Label = %PlaceholderLabel


func _ready() -> void:
	_apply_button_chrome()
	if slot_frame and slot_frame.texture == null:
		slot_frame.texture = SLOT_FRAME_TEXTURE
	text = ""
	flat = true
	expand_icon = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	resized.connect(_sync_chrome_layout)
	call_deferred("_sync_chrome_layout")


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_sync_chrome_layout()


func set_skill(skill: SkillResource) -> void:
	if skill == null:
		set_empty()
		return
	if placeholder_label:
		placeholder_label.visible = false
	if skill_icon:
		skill_icon.visible = true
		skill_icon.texture = SkillIcons.get_icon(skill)
		skill_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func set_empty() -> void:
	if skill_icon:
		skill_icon.texture = null
		skill_icon.visible = false
	if placeholder_label:
		placeholder_label.visible = true
		placeholder_label.text = EMPTY_TEXT


func _apply_button_chrome() -> void:
	var empty := StyleBoxEmpty.new()
	add_theme_stylebox_override("normal", empty)
	add_theme_stylebox_override("hover", empty)
	add_theme_stylebox_override("pressed", empty)
	add_theme_stylebox_override("focus", empty)
	add_theme_stylebox_override("disabled", empty)


func _sync_chrome_layout() -> void:
	var side := minf(size.x, size.y)
	if side <= 0.0:
		return
	var scale := side / SLOT_FRAME_BLEED_BASE_SIZE
	if slot_frame:
		var bleed := maxf(SLOT_FRAME_BLEED_BASE_PX, SLOT_FRAME_BLEED_BASE_PX * scale)
		slot_frame.offset_left = -bleed
		slot_frame.offset_top = -bleed
		slot_frame.offset_right = bleed
		slot_frame.offset_bottom = bleed
	if skill_icon:
		var inset := maxf(SLOT_ICON_INSET_BASE_PX, SLOT_ICON_INSET_BASE_PX * scale)
		skill_icon.offset_left = inset
		skill_icon.offset_top = inset
		skill_icon.offset_right = -inset
		skill_icon.offset_bottom = -inset
