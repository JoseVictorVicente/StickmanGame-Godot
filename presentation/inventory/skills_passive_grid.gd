class_name SkillsPassiveGrid
extends GridContainer
## Grade de skills passivas disponíveis (pool bakeado).

const SLOT_SCENE := preload("res://presentation/inventory/skill_slot_passive.tscn")
const MAX_SLOTS := 10
const COLUMNS := 5
const DEFAULT_SLOT_SIZE := Vector2(64, 64)


func passive_slots() -> Array[Button]:
	return _collect_slots()


func setup(connect_slot: Callable) -> Array[Button]:
	var lista := passive_slots()
	if lista.is_empty():
		lista = ensure_slots()
	for slot in lista:
		_connect_slot_once(slot, connect_slot)
	return lista


func ensure_slots(slot_size: Vector2 = DEFAULT_SLOT_SIZE) -> Array[Button]:
	if get_child_count() == MAX_SLOTS and _children_are_slots():
		_apply_layout(slot_size)
		return _collect_slots()

	_clear_children()
	_apply_layout(slot_size)

	var criados: Array[Button] = []
	for indice in MAX_SLOTS:
		var slot := SLOT_SCENE.instantiate() as Button
		slot.name = "PassiveSkillSlot_%02d" % (indice + 1)
		add_child(slot)
		criados.append(slot)
	return criados


func _connect_slot_once(slot: Button, connect_slot: Callable) -> void:
	if slot.get_meta(&"passive_skill_wired", false):
		return
	if connect_slot.is_valid():
		connect_slot.call(slot)
	slot.set_meta(&"passive_skill_wired", true)


func _apply_layout(slot_size: Vector2) -> void:
	columns = COLUMNS
	for filho in get_children():
		if filho is Button:
			(filho as Button).custom_minimum_size = slot_size
			(filho as Button).focus_mode = Control.FOCUS_NONE
			(filho as Button).add_theme_font_size_override("font_size", 9)
			(filho as Button).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _children_are_slots() -> bool:
	for filho in get_children():
		if not filho is Button:
			return false
	return get_child_count() > 0


func _collect_slots() -> Array[Button]:
	var lista: Array[Button] = []
	for filho in get_children():
		if filho is Button:
			lista.append(filho as Button)
	return lista


func _clear_children() -> void:
	for filho in get_children():
		filho.queue_free()
