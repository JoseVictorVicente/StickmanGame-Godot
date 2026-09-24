class_name ForgeSlotsGrid
extends GridContainer
## Grade de forja 3×3. Slots bakeados no .tscn; atualize via ItemSlot.set_item().

const SLOT_COUNT := 9
const COLUMNS := 3
const DEFAULT_SLOT_SIZE := Vector2(42, 42)


func slots() -> Array[ItemSlot]:
	return _collect_slots()


func fit_to_inner_rect(area: Rect2) -> void:
	if area.size.x < 1.0 or area.size.y < 1.0:
		return
	var sep_h := float(get_theme_constant("h_separation"))
	var sep_v := float(get_theme_constant("v_separation"))
	var lado_slot := minf(
		(area.size.x - sep_h * 2.0) / float(COLUMNS),
		(area.size.y - sep_v * 2.0) / float(COLUMNS)
	)
	var slot_size := Vector2.ONE * maxf(1.0, lado_slot)
	for slot in slots():
		slot.custom_minimum_size = slot_size
	reset_size()


func _collect_slots() -> Array[ItemSlot]:
	var lista: Array[ItemSlot] = []
	for filho in get_children():
		if filho is ItemSlot:
			lista.append(filho as ItemSlot)
	return lista
