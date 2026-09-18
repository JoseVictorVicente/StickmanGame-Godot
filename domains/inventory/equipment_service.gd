class_name EquipmentService
extends RefCounted
## Equipment slots per party character index (12 types × 3 heroes).

const CHARACTER_SLOTS := 3
const EQUIP_SLOT_COUNT := 12

const EQUIP_TYPES: Array[ItemData.Tipo] = [
	ItemData.Tipo.ARMA,
	ItemData.Tipo.SECUNDARIA,
	ItemData.Tipo.CAPACETE,
	ItemData.Tipo.PEITORAL,
	ItemData.Tipo.LUVA,
	ItemData.Tipo.CALCA,
	ItemData.Tipo.BOTA,
	ItemData.Tipo.CINTO,
	ItemData.Tipo.PINGENTE,
	ItemData.Tipo.ANEL,
	ItemData.Tipo.BRACELETE,
	ItemData.Tipo.PET,
]

var _by_character: Array = []


func _init() -> void:
	_reset_storage()


func _reset_storage() -> void:
	_by_character.clear()
	for _i in CHARACTER_SLOTS:
		var loadout: Dictionary = {}
		for tipo in EQUIP_TYPES:
			loadout[int(tipo)] = null
		_by_character.append(loadout)


func get_equipped(character_index: int, item_type: ItemData.Tipo) -> ItemData:
	if not _valid_character(character_index):
		return null
	var loadout: Dictionary = _by_character[character_index]
	return loadout.get(int(item_type)) as ItemData


func get_all_equipped(character_index: int) -> Array[ItemData]:
	var items: Array[ItemData] = []
	if not _valid_character(character_index):
		return items
	var loadout: Dictionary = _by_character[character_index]
	for tipo in EQUIP_TYPES:
		var item: ItemData = loadout.get(int(tipo)) as ItemData
		if item != null:
			items.append(item)
	return items


func can_equip(
	item: ItemData,
	character_index: int,
	hero_level: int,
	hero_class: ItemData.RequiredClass = ItemData.RequiredClass.ALL
) -> bool:
	if item == null or not _valid_character(character_index):
		return false
	if item.is_gem():
		return false
	if not EQUIP_TYPES.has(item.tipo):
		return false
	if not _class_can_use(item, hero_class):
		return false
	return item.can_equip(hero_level)


func equip(
	item: ItemData,
	character_index: int,
	hero_level: int,
	hero_class: ItemData.RequiredClass = ItemData.RequiredClass.ALL
) -> bool:
	if not can_equip(item, character_index, hero_level, hero_class):
		return false
	var loadout: Dictionary = _by_character[character_index]
	loadout[int(item.tipo)] = item
	return true


func unequip(character_index: int, item_type: ItemData.Tipo) -> ItemData:
	if not _valid_character(character_index):
		return null
	var loadout: Dictionary = _by_character[character_index]
	var key := int(item_type)
	var previous: ItemData = loadout.get(key) as ItemData
	loadout[key] = null
	return previous


func total_damage_bonus(character_index: int) -> int:
	var total := 0
	for item in get_all_equipped(character_index):
		total += item.dano_bonus
	return total


func total_hp_bonus(character_index: int) -> int:
	var total := 0
	for item in get_all_equipped(character_index):
		total += item.vida_bonus
	return total


func to_dict() -> Dictionary:
	var all: Dictionary = {}
	for i in CHARACTER_SLOTS:
		var entries: Array = []
		for tipo in EQUIP_TYPES:
			var item: ItemData = _by_character[i].get(int(tipo)) as ItemData
			entries.append({
				"tipo": int(tipo),
				"item": item.to_dictionary() if item else {},
			})
		all[str(i)] = entries
	return all


func from_dict(data: Variant) -> void:
	_reset_storage()
	if data is Dictionary:
		for i in CHARACTER_SLOTS:
			var key := str(i)
			if data.has(key) and data[key] is Array:
				_apply_slot_list(i, data[key])
		return
	if data is Array:
		for i in mini(data.size(), CHARACTER_SLOTS):
			if data[i] is Array:
				_apply_slot_list(i, data[i])


func from_class_dict(data: Variant) -> void:
	_reset_storage()
	if not (data is Dictionary):
		return
	for class_id in data.keys():
		var index := _character_index_for_class(str(class_id))
		if index < 0:
			continue
		var lista: Variant = data[class_id]
		if lista is Array:
			_apply_slot_list(index, lista)


static func character_index_for_class_id(class_id: String) -> int:
	match class_id:
		"warrior":
			return 0
		"mage":
			return 1
		"archer":
			return 2
		_:
			return -1


func _apply_slot_list(character_index: int, lista: Array) -> void:
	if not _valid_character(character_index):
		return
	var loadout: Dictionary = _by_character[character_index]
	for tipo in EQUIP_TYPES:
		loadout[int(tipo)] = null
	var by_type: Dictionary = {}
	for entrada in lista:
		if entrada is Dictionary:
			by_type[int(entrada.get("tipo", -1))] = entrada.get("item", {})
	for tipo in EQUIP_TYPES:
		var key := int(tipo)
		var raw: Variant = by_type.get(key, {})
		if raw is Dictionary and not (raw as Dictionary).is_empty():
			loadout[key] = ItemData.de_dicionario(raw)
		else:
			loadout[key] = null


func _valid_character(character_index: int) -> bool:
	return character_index >= 0 and character_index < _by_character.size()


func _character_index_for_class(class_id: String) -> int:
	return character_index_for_class_id(class_id)


static func _class_can_use(item: ItemData, hero_class: ItemData.RequiredClass) -> bool:
	if item.required_class == ItemData.RequiredClass.ALL:
		return true
	return item.required_class == hero_class
