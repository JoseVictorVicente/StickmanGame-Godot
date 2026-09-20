class_name SkillTypeSlot
extends Control
## Indicador visual de categoria por linha na grade de ativas (ataque / defesa / suporte).

@onready var frame_slot: TextureButton = %FrameSlot
@onready var category_label: Label = %CategoryLabel


func apply_category(text: String, slot_size: Vector2 = Vector2(56, 56)) -> void:
	if category_label:
		category_label.text = text
	if frame_slot:
		SkillIcons.apply_framed_texture_button(frame_slot, null, slot_size, true)
