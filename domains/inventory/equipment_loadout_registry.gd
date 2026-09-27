class_name EquipmentLoadoutRegistry
extends RefCounted
## Item equipment keyed by class id. Pure data — InventoryMenu syncs UI slots.

const EQUIP_TYPES: Array[ItemData.Type] = [
	ItemData.Type.WEAPON,
	ItemData.Type.OFFHAND,
	ItemData.Type.HELMET,
	ItemData.Type.CHEST,
	ItemData.Type.GLOVES,
	ItemData.Type.PANTS,
	ItemData.Type.BOOTS,
	ItemData.Type.RING2,
	ItemData.Type.PENDANT,
	ItemData.Type.RING,
	ItemData.Type.BRACELET,
	ItemData.Type.PET,
]

var _by_class: Dictionary = {}


func ensure_classes(class_ids: Array) -> void:
	for raw_id in class_ids:
		var class_id := str(raw_id)
		if not _by_class.has(class_id):
			_by_class[class_id] = _empty_loadout()


func get_item(class_id: String, item_type: ItemData.Type) -> ItemData:
	if class_id == "" or not _by_class.has(class_id):
		return null
	var loadout: Dictionary = _by_class[class_id]
	return loadout.get(int(item_type)) as ItemData


func set_item(class_id: String, item_type: ItemData.Type, item: ItemData) -> void:
	if class_id == "":
		return
	ensure_classes([class_id])
	_by_class[class_id][int(item_type)] = item


func items_for_class(class_id: String) -> Array[ItemData]:
	var lista: Array[ItemData] = []
	if class_id == "" or not _by_class.has(class_id):
		return lista
	var loadout: Dictionary = _by_class[class_id]
	for tipo in EQUIP_TYPES:
		var item: ItemData = loadout.get(int(tipo)) as ItemData
		if item != null:
			lista.append(item)
	return lista


func serialize() -> Dictionary:
	var todos: Dictionary = {}
	for class_id in _by_class.keys():
		var lista: Array = []
		var loadout: Dictionary = _by_class[class_id]
		for tipo in EQUIP_TYPES:
			var item: Variant = loadout.get(int(tipo))
			lista.append({
				"type": int(tipo),
				"item": (item as ItemData).to_dictionary() if item is ItemData else {},
			})
		todos[str(class_id)] = lista
	return todos


func deserialize(data: Variant) -> void:
	_by_class.clear()
	if data is Dictionary:
		for class_id in data.keys():
			_apply_slot_list(str(class_id), data[class_id])
		return
	if data is Array:
		var legacy_ids: Array[String] = ["warrior", "mage", "archer"]
		for i in mini(data.size(), legacy_ids.size()):
			if data[i] is Array:
				_apply_slot_list(legacy_ids[i], data[i])


func _apply_slot_list(class_id: String, lista: Variant) -> void:
	ensure_classes([class_id])
	var loadout := _empty_loadout()
	if lista is Array:
		for entrada in lista:
			if entrada is Dictionary:
				var tipo := int(entrada.get("type", -1))
				var dados: Variant = entrada.get("item", {})
				if tipo >= 0 and dados is Dictionary and not (dados as Dictionary).is_empty():
					loadout[tipo] = ItemData.from_dictionary(dados)
	_by_class[class_id] = loadout


func _empty_loadout() -> Dictionary:
	var loadout: Dictionary = {}
	for tipo in EQUIP_TYPES:
		loadout[int(tipo)] = null
	return loadout
