class_name EquipmentGrid
extends GridContainer
## Grade de slots de equipamento. Slots bakeados no .tscn quando possível.

const ITEM_SLOT_SCENE := preload("res://presentation/inventory/item_slot.tscn")

const LEFT_TYPES: Array[ItemData.Type] = [
	ItemData.Type.WEAPON,
	ItemData.Type.OFFHAND,
	ItemData.Type.HELMET,
	ItemData.Type.CHEST,
	ItemData.Type.GLOVES,
	ItemData.Type.PANTS,
	ItemData.Type.BOOTS,
]
const RIGHT_TYPES: Array[ItemData.Type] = [
	ItemData.Type.BELT,
	ItemData.Type.PENDANT,
	ItemData.Type.RING,
	ItemData.Type.BRACELET,
	ItemData.Type.PET,
]


func slots() -> Array[ItemSlot]:
	return _collect_slots()


func build_slots(tipos: Array[ItemData.Type], layout: InventoryLayout) -> Array[ItemSlot]:
	if get_child_count() == tipos.size() and _children_are_item_slots():
		_apply_layout(layout, tipos)
		return _collect_slots()

	for filho in get_children():
		filho.queue_free()

	columns = layout.equip_grid_columns
	add_theme_constant_override("h_separation", layout.equip_grid_h_separation)
	add_theme_constant_override("v_separation", layout.equip_grid_v_separation)

	var criados: Array[ItemSlot] = []
	for tipo in tipos:
		var slot := _create_slot(tipo, layout)
		add_child(slot)
		slot.configure(null, tipo, false)
		criados.append(slot)
	return criados


func _apply_layout(layout: InventoryLayout, tipos: Array[ItemData.Type]) -> void:
	columns = layout.equip_grid_columns
	add_theme_constant_override("h_separation", layout.equip_grid_h_separation)
	add_theme_constant_override("v_separation", layout.equip_grid_v_separation)
	var filhos := _collect_slots()
	for i in mini(filhos.size(), tipos.size()):
		var slot := filhos[i]
		slot.custom_minimum_size = layout.equip_slot_size
		slot.slot_label = tr(ItemData.equip_slot_label_key(tipos[i]))
		if slot.item == null:
			slot.configure(null, tipos[i], false)


func _create_slot(tipo: ItemData.Type, layout: InventoryLayout) -> ItemSlot:
	var slot := ITEM_SLOT_SCENE.instantiate() as ItemSlot
	slot.name = "Slot%s" % ItemData.type_display_name(tipo).replace(" ", "")
	slot.custom_minimum_size = layout.equip_slot_size
	slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	slot.slot_label = tr(ItemData.equip_slot_label_key(tipo))
	return slot


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
