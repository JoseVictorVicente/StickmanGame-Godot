class_name InventoryService
extends RefCounted
## Grid inventory storage (5 rows × 10 cols display; 49 usable + expand placeholder). Pure data — no UI nodes.

const COLUMNS := 10
const ROWS := 5
const EXPAND_DISPLAY_SLOTS := 1
const DISPLAY_SLOT_COUNT := COLUMNS * ROWS
const DEFAULT_UNLOCKED_SLOTS := DISPLAY_SLOT_COUNT - EXPAND_DISPLAY_SLOTS

## Back-compat aliases used by save migration and tests.
const USABLE_SLOT_COUNT := DEFAULT_UNLOCKED_SLOTS
const SLOT_COUNT := DEFAULT_UNLOCKED_SLOTS

var unlocked_slots: int = DEFAULT_UNLOCKED_SLOTS
var _slots: Array = []


func _init() -> void:
	reset_slots()


func reset_slots(unlocked: int = DEFAULT_UNLOCKED_SLOTS) -> void:
	unlocked_slots = clampi(unlocked, 0, max_unlockable_slots())
	_slots.resize(unlocked_slots)
	for i in unlocked_slots:
		_slots[i] = null


func max_unlockable_slots() -> int:
	return DEFAULT_UNLOCKED_SLOTS


func display_slot_count() -> int:
	return DISPLAY_SLOT_COUNT


func slot_count() -> int:
	return unlocked_slots


func get_item(index: int) -> ItemData:
	if index < 0 or index >= _slots.size():
		return null
	return _slots[index] as ItemData


func set_item(index: int, item: ItemData) -> void:
	if index < 0 or index >= _slots.size():
		return
	_slots[index] = item


func get_slots() -> Array:
	return _slots.duplicate()


func first_empty_index() -> int:
	for i in _slots.size():
		if _slots[i] == null:
			return i
	return -1


func is_full() -> bool:
	return first_empty_index() < 0


func add_item(item: ItemData) -> bool:
	if item == null:
		return false
	var index := first_empty_index()
	if index < 0:
		return false
	_slots[index] = item
	return true


func remove_item(index: int) -> ItemData:
	if index < 0 or index >= _slots.size():
		return null
	var item: ItemData = _slots[index]
	_slots[index] = null
	return item


func sort_items() -> void:
	var items: Array[ItemData] = []
	for slot in _slots:
		if slot is ItemData:
			items.append(slot)
	items.sort_custom(ItemData.compare_sort)
	for i in _slots.size():
		_slots[i] = items[i] if i < items.size() else null


func to_dict() -> Dictionary:
	var lista: Array = []
	for slot in _slots:
		if slot is ItemData:
			lista.append((slot as ItemData).to_dictionary())
		else:
			lista.append({})
	return {
		"slots": lista,
		"unlocked_slots": unlocked_slots,
		"columns": COLUMNS,
		"rows": ROWS,
	}


func from_dict(data: Variant) -> void:
	var lista: Array = []
	var unlocked := DEFAULT_UNLOCKED_SLOTS
	if data is Dictionary:
		var raw: Variant = data.get("slots", data.get("items", []))
		if raw is Array:
			lista = raw
		unlocked = int(data.get("unlocked_slots", DEFAULT_UNLOCKED_SLOTS))
	elif data is Array:
		lista = data
	reset_slots(unlocked)
	for i in mini(lista.size(), unlocked_slots):
		if lista[i] is Dictionary and not (lista[i] as Dictionary).is_empty():
			_slots[i] = ItemData.from_dictionary(lista[i])
		else:
			_slots[i] = null
