class_name InventorySlotsGrid
extends GridContainer
## Inventory grid 5 rows × 10 cols (49 usable + expand placeholder). Baked slots in .tscn.

const EXPAND_SLOT_NAME := "SlotInventario_50"

var _unlocked_slot_count: int = InventoryService.DEFAULT_UNLOCKED_SLOTS


func slots() -> Array[ItemSlot]:
	return _collect_inventory_slots()


func usable_slots() -> Array[ItemSlot]:
	var lista: Array[ItemSlot] = []
	var expand := expand_slot()
	var cap := mini(_unlocked_slot_count, slots().size())
	if expand != null:
		cap = mini(cap, slots().size() - 1)
	for slot in slots():
		if slot == expand:
			continue
		if lista.size() >= cap:
			break
		lista.append(slot)
	return lista


func expand_slot() -> ItemSlot:
	return get_node_or_null(EXPAND_SLOT_NAME) as ItemSlot


func display_slot_count() -> int:
	return slots().size()


func unlocked_slot_count() -> int:
	return _unlocked_slot_count


func set_unlocked_slot_count(count: int) -> void:
	var expand := expand_slot()
	var max_usable := slots().size()
	if expand != null:
		max_usable -= 1
	_unlocked_slot_count = clampi(count, 0, max_usable)


func setup(connect_slot: Callable) -> Array[ItemSlot]:
	var expand := expand_slot()
	if expand:
		expand.set_expand_placeholder(true)
	var lista := usable_slots()
	for slot in lista:
		if connect_slot.is_valid():
			_connect_slot_once(slot, connect_slot)
	return lista


func _connect_slot_once(slot: ItemSlot, connect_slot: Callable) -> void:
	if slot.get_meta(&"inventory_slot_wired", false):
		return
	connect_slot.call(slot)
	slot.set_meta(&"inventory_slot_wired", true)


func _collect_inventory_slots() -> Array[ItemSlot]:
	var lista: Array[ItemSlot] = []
	for filho in get_children():
		if filho is ItemSlot:
			lista.append(filho as ItemSlot)
	return lista
