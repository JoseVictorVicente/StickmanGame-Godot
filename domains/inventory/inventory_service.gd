class_name InventoryService
extends RefCounted
## Grid inventory storage (10×5). Pure data — no UI nodes.

const COLUMNS := 10
const ROWS := 5
const SLOT_COUNT := COLUMNS * ROWS

var _slots: Array = []


func _init() -> void:
	_slots.resize(SLOT_COUNT)
	for i in SLOT_COUNT:
		_slots[i] = null


func slot_count() -> int:
	return SLOT_COUNT


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
	return {"slots": lista, "columns": COLUMNS, "rows": ROWS}


func from_dict(data: Variant) -> void:
	_slots.resize(SLOT_COUNT)
	for i in SLOT_COUNT:
		_slots[i] = null
	var lista: Array = []
	if data is Dictionary:
		var raw: Variant = data.get("slots", data.get("items", []))
		if raw is Array:
			lista = raw
	elif data is Array:
		lista = data
	for i in mini(lista.size(), SLOT_COUNT):
		if lista[i] is Dictionary and not (lista[i] as Dictionary).is_empty():
			_slots[i] = ItemData.from_dictionary(lista[i])
		else:
			_slots[i] = null
