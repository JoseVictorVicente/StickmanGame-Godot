class_name InventorySlotsGrid
extends GridContainer
## Grade de inventário 10×5. Slots bakeados no .tscn; atualize via ItemSlot.set_item().

const ITEM_SLOT_SCENE := preload("res://presentation/inventory/item_slot.tscn")
const DEFAULT_LAYOUT := preload("res://presentation/inventory/inventory_layout_default.tres")


func slots() -> Array[ItemSlot]:
	return _collect_inventory_slots()


func setup(connect_slot: Callable) -> Array[ItemSlot]:
	var lista := slots()
	if lista.is_empty():
		lista = ensure_slots(DEFAULT_LAYOUT)
	for slot in lista:
		if connect_slot.is_valid():
			_connect_slot_once(slot, connect_slot)
	return lista


func ensure_slots(layout: InventoryLayout) -> Array[ItemSlot]:
	var esperado := layout.expected_slot_count()
	if get_child_count() == esperado and _children_are_inventory_slots():
		_apply_grid_layout(layout)
		return _collect_inventory_slots()

	_clear_slot_children()
	columns = layout.inventory_grid_columns
	add_theme_constant_override("h_separation", layout.inventory_grid_h_separation)
	add_theme_constant_override("v_separation", layout.inventory_grid_v_separation)

	var criados: Array[ItemSlot] = []
	for indice in esperado:
		var slot := ITEM_SLOT_SCENE.instantiate() as ItemSlot
		slot.name = "SlotInventario_%02d" % (indice + 1)
		slot.custom_minimum_size = layout.inventory_slot_size
		add_child(slot)
		slot.configure(null, ItemData.Type.WEAPON, true)
		criados.append(slot)
	_apply_grid_layout(layout)
	return criados


func build_slots(layout: InventoryLayout) -> Array[ItemSlot]:
	return ensure_slots(layout)


func _connect_slot_once(slot: ItemSlot, connect_slot: Callable) -> void:
	if slot.get_meta(&"inventory_slot_wired", false):
		return
	connect_slot.call(slot)
	slot.set_meta(&"inventory_slot_wired", true)


func _clear_slot_children() -> void:
	for filho in get_children():
		filho.queue_free()


func _children_are_inventory_slots() -> bool:
	for filho in get_children():
		if not filho is ItemSlot:
			return false
	return get_child_count() > 0


func _collect_inventory_slots() -> Array[ItemSlot]:
	var lista: Array[ItemSlot] = []
	for filho in get_children():
		if filho is ItemSlot:
			lista.append(filho as ItemSlot)
	return lista


func _apply_grid_layout(layout: InventoryLayout) -> void:
	columns = layout.inventory_grid_columns
	add_theme_constant_override("h_separation", layout.inventory_grid_h_separation)
	add_theme_constant_override("v_separation", layout.inventory_grid_v_separation)
	for filho in get_children():
		if filho is ItemSlot:
			(filho as ItemSlot).custom_minimum_size = layout.inventory_slot_size
	custom_minimum_size = layout.inventory_grid_pixel_size()
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
