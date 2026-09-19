class_name WarehouseService
extends RefCounted
## Paginated warehouse storage. Mirrors WarehousePanel save layout.

const TAB_COUNT := 8
const COLUMNS := 5
const ROWS := 8
const SLOTS_PER_TAB := COLUMNS * ROWS
const TREE_UNLOCKED_TAB_START := 1
const TREE_UNLOCKED_TAB_END := 3
const EXTRA_TAB_UNLOCK_START := 4

var _tabs: Array = []
var _unlocked: Array[bool] = []


func _init() -> void:
	_reset()


func _reset() -> void:
	_tabs.clear()
	_unlocked.clear()
	for _i in TAB_COUNT:
		var tab: Array = []
		tab.resize(SLOTS_PER_TAB)
		for j in SLOTS_PER_TAB:
			tab[j] = null
		_tabs.append(tab)
		_unlocked.append(_i == 0)


func tab_count() -> int:
	return TAB_COUNT


func is_tab_unlocked(tab_index: int) -> bool:
	if tab_index < 0 or tab_index >= _unlocked.size():
		return false
	return _unlocked[tab_index]


func set_tab_unlocked(tab_index: int, unlocked: bool) -> void:
	if tab_index < 0 or tab_index >= _unlocked.size():
		return
	if tab_index >= TREE_UNLOCKED_TAB_START and tab_index <= TREE_UNLOCKED_TAB_END:
		return
	_unlocked[tab_index] = unlocked


func apply_tree_unlocks(indices: Array[int]) -> void:
	for tab_index in range(TREE_UNLOCKED_TAB_START, TREE_UNLOCKED_TAB_END + 1):
		_unlocked[tab_index] = tab_index in indices


func get_item(tab_index: int, slot_index: int) -> ItemData:
	if not _valid_slot(tab_index, slot_index):
		return null
	return _tabs[tab_index][slot_index] as ItemData


func set_item(tab_index: int, slot_index: int, item: ItemData) -> void:
	if not _valid_slot(tab_index, slot_index):
		return
	_tabs[tab_index][slot_index] = item


func first_empty_slot(tab_index: int = 0) -> int:
	if tab_index < 0 or tab_index >= TAB_COUNT or not _unlocked[tab_index]:
		return -1
	var tab: Array = _tabs[tab_index]
	for i in tab.size():
		if tab[i] == null:
			return i
	return -1


func first_empty_slot_any_tab() -> Vector2i:
	for tab_index in TAB_COUNT:
		if not _unlocked[tab_index]:
			continue
		var slot := first_empty_slot(tab_index)
		if slot >= 0:
			return Vector2i(tab_index, slot)
	return Vector2i(-1, -1)


func add_item(item: ItemData) -> bool:
	if item == null:
		return false
	var coords := first_empty_slot_any_tab()
	if coords.x < 0:
		return false
	_tabs[coords.x][coords.y] = item
	return true


func sort_tab(tab_index: int) -> void:
	if tab_index < 0 or tab_index >= TAB_COUNT:
		return
	var items: Array[ItemData] = []
	var tab: Array = _tabs[tab_index]
	for slot in tab:
		if slot is ItemData:
			items.append(slot)
	items.sort_custom(ItemData.compare_sort)
	for i in tab.size():
		tab[i] = items[i] if i < items.size() else null


func to_dict() -> Dictionary:
	var tabs: Array = []
	for tab in _tabs:
		var items: Array = []
		for slot in tab:
			if slot is ItemData:
				items.append((slot as ItemData).to_dictionary())
			else:
				items.append({})
		tabs.append(items)
	return {
		"unlocked": _unlocked.duplicate(),
		"tabs": tabs,
	}


func from_dict(data: Variant) -> void:
	_reset()
	if data is Array:
		_apply_tab_items(0, data)
		return
	if not (data is Dictionary):
		return
	var flags: Variant = data.get("unlocked", [])
	if flags is Array:
		for i in range(EXTRA_TAB_UNLOCK_START, mini(flags.size(), TAB_COUNT)):
			_unlocked[i] = bool(flags[i])
	var tabs: Variant = data.get("tabs", data.get("abas", []))
	if tabs is Array:
		for i in mini(tabs.size(), TAB_COUNT):
			if tabs[i] is Array:
				_apply_tab_items(i, tabs[i])


func _apply_tab_items(tab_index: int, lista: Array) -> void:
	if tab_index < 0 or tab_index >= TAB_COUNT:
		return
	var tab: Array = _tabs[tab_index]
	for i in tab.size():
		tab[i] = null
	for i in mini(lista.size(), tab.size()):
		if lista[i] is Dictionary and not (lista[i] as Dictionary).is_empty():
			tab[i] = ItemData.from_dictionary(lista[i])
		else:
			tab[i] = null


func _valid_slot(tab_index: int, slot_index: int) -> bool:
	if tab_index < 0 or tab_index >= TAB_COUNT:
		return false
	if slot_index < 0 or slot_index >= SLOTS_PER_TAB:
		return false
	return true
