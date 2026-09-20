class_name SkillsPassiveGrid
extends GridContainer
## Passive skill inventory: 2 rows x 5 columns (10 slots), baked in .tscn.

const SLOT_SCENE := preload("res://presentation/inventory/skill_slot_passive.tscn")
const MAX_SLOTS := 10
const COLUMNS := 5
const DEFAULT_SLOT_SIZE := Vector2(48, 48)


func passive_slots() -> Array[TextureButton]:
	return _collect_slots()


func setup(connect_slot: Callable) -> Array[TextureButton]:
	var lista := passive_slots()
	if lista.is_empty():
		lista = ensure_slots()
	for slot in lista:
		_connect_slot_once(slot, connect_slot)
	return lista


func ensure_slots(slot_size: Vector2 = DEFAULT_SLOT_SIZE) -> Array[TextureButton]:
	if get_child_count() == MAX_SLOTS and _children_are_slots():
		_apply_layout(slot_size)
		return _collect_slots()

	_clear_children()
	_apply_layout(slot_size)

	var criados: Array[TextureButton] = []
	for indice in MAX_SLOTS:
		var slot := SLOT_SCENE.instantiate() as TextureButton
		slot.name = "PassiveSkillSlot_%02d" % (indice + 1)
		add_child(slot)
		criados.append(slot)
	return criados


func _connect_slot_once(slot: TextureButton, connect_slot: Callable) -> void:
	if slot.get_meta(&"passive_skill_wired", false):
		return
	if connect_slot.is_valid():
		connect_slot.call(slot)
	slot.set_meta(&"passive_skill_wired", true)


func _apply_layout(slot_size: Vector2) -> void:
	columns = COLUMNS
	for filho in get_children():
		if filho is TextureButton:
			(filho as TextureButton).custom_minimum_size = slot_size
			(filho as TextureButton).focus_mode = Control.FOCUS_NONE


func _children_are_slots() -> bool:
	for filho in get_children():
		if not filho is TextureButton:
			return false
	return get_child_count() == MAX_SLOTS


func _collect_slots() -> Array[TextureButton]:
	var lista: Array[TextureButton] = []
	for filho in get_children():
		if filho is TextureButton:
			lista.append(filho as TextureButton)
	return lista


func _clear_children() -> void:
	for filho in get_children():
		filho.queue_free()
