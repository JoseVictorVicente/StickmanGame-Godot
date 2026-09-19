class_name ForgeSlotsGrid
extends GridContainer
## Grade de forja 3×3. Slots bakeados no .tscn; atualize via ItemSlot.set_item().

const ITEM_SLOT_SCENE := preload("res://presentation/inventory/item_slot.tscn")
const SLOT_COUNT := 9
const COLUMNS := 3
const DEFAULT_SLOT_SIZE := Vector2(42, 42)


func slots() -> Array[ItemSlot]:
	return _collect_slots()


func ensure_slots(slot_size: Vector2 = DEFAULT_SLOT_SIZE, slot_style: StyleBoxFlat = null) -> Array[ItemSlot]:
	if get_child_count() == SLOT_COUNT and _children_are_item_slots():
		_apply_layout(slot_size, slot_style)
		return _collect_slots()

	_clear_slot_children()
	_apply_layout(slot_size, slot_style)

	var criados: Array[ItemSlot] = []
	for indice in SLOT_COUNT:
		var slot := ITEM_SLOT_SCENE.instantiate() as ItemSlot
		slot.name = "ForgeSlot_%02d" % (indice + 1)
		slot.custom_minimum_size = slot_size
		if slot_style:
			slot.add_theme_stylebox_override("panel", slot_style)
		add_child(slot)
		slot.configure(null, ItemData.Type.WEAPON, true)
		criados.append(slot)
	return criados


func build_slots(slot_size: Vector2, slot_style: StyleBoxFlat = null) -> Array[ItemSlot]:
	return ensure_slots(slot_size, slot_style)


func _apply_layout(slot_size: Vector2, slot_style: StyleBoxFlat) -> void:
	columns = COLUMNS
	add_theme_constant_override("h_separation", 4)
	add_theme_constant_override("v_separation", 4)
	for filho in get_children():
		if filho is ItemSlot:
			var slot := filho as ItemSlot
			slot.custom_minimum_size = slot_size
			if slot_style:
				slot.add_theme_stylebox_override("panel", slot_style)


func _clear_slot_children() -> void:
	for filho in get_children():
		filho.queue_free()


func _children_are_item_slots() -> bool:
	for filho in get_children():
		if not filho is ItemSlot:
			return false
	return get_child_count() > 0


func _collect_slots() -> Array[ItemSlot]:
	var lista: Array[ItemSlot] = []
	for filho in get_children():
		if filho is ItemSlot:
			lista.append(filho as ItemSlot)
	return lista
