@tool
class_name InventorySlotsGrid
extends GridContainer
## Inventory grid 5×10 (49 usable slots + expand "+" placeholder). Baked slots in .tscn; update via ItemSlot.set_item().

const ITEM_SLOT_SCENE := preload("res://presentation/inventory/item_slot.tscn")
const DEFAULT_LAYOUT := preload("res://presentation/inventory/inventory_layout_default.tres")
const EXPAND_SLOT_ICON := preload("res://sprites/ui/nav_shop.png")


func _ready() -> void:
	if Engine.is_editor_hint():
		call_deferred("_apply_editor_preview")


func _apply_editor_preview() -> void:
	var layout := InventoryLayout.duplicate_synced(DEFAULT_LAYOUT)
	if layout == null or layout.get_script() == null:
		return
	ensure_slots(layout)


func slots() -> Array[ItemSlot]:
	return _collect_inventory_slots()


func usable_slots() -> Array[ItemSlot]:
	var lista := slots()
	var limite := DEFAULT_LAYOUT.usable_inventory_slot_count()
	if lista.size() <= limite:
		return lista
	return lista.slice(0, limite)


func expand_slot() -> ItemSlot:
	var lista := slots()
	if lista.is_empty():
		return null
	return lista[lista.size() - 1]


func setup(connect_slot: Callable) -> Array[ItemSlot]:
	var layout := InventoryLayout.duplicate_synced(DEFAULT_LAYOUT)
	var lista := ensure_slots(layout)
	for i in lista.size():
		var slot := lista[i]
		if _is_expand_slot(i, layout):
			_configure_expand_slot(slot)
			continue
		if connect_slot.is_valid():
			_connect_slot_once(slot, connect_slot)
	return lista


func ensure_slots(layout: InventoryLayout) -> Array[ItemSlot]:
	var esperado := layout.expected_slot_count()
	if get_child_count() == esperado and _children_are_inventory_slots():
		_apply_grid_layout(layout)
		_refresh_expand_slot(layout)
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
		if _is_expand_slot(indice, layout):
			_configure_expand_slot(slot)
		else:
			slot.configure(null, ItemData.Type.WEAPON, true)
		criados.append(slot)
	_apply_grid_layout(layout)
	return criados


func build_slots(layout: InventoryLayout) -> Array[ItemSlot]:
	return ensure_slots(layout)


func _is_expand_slot(indice: int, layout: InventoryLayout) -> bool:
	return indice == layout.usable_inventory_slot_count()


func _configure_expand_slot(slot: ItemSlot) -> void:
	slot.configure(null, ItemData.Type.WEAPON, false)
	slot.set_item(null)
	slot.mouse_filter = Control.MOUSE_FILTER_STOP
	slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	slot.slot_label = "+"
	if slot.get_icon_rect():
		slot.get_icon_rect().texture = EXPAND_SLOT_ICON
		slot.get_icon_rect().modulate = Color(0.85, 0.75, 0.45, 0.9)


func _refresh_expand_slot(layout: InventoryLayout) -> void:
	var lista := _collect_inventory_slots()
	for i in lista.size():
		if _is_expand_slot(i, layout):
			_configure_expand_slot(lista[i])


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
