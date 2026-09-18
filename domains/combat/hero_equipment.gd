extends Node
## Gerencia as habilidades equipadas de cada classe de herói (autoload: HeroEquipment).

const _SkillResourceScript := preload("res://data/skill_resource.gd")

signal equipment_changed(classe_id: String)

const MAX_ACTIVE := 2
const MAX_PASSIVE := 2
const SKILLS_FOLDER := "res://data/skills/"

var _equipment: Dictionary = {}
var _catalogos: Dictionary = {}


func equip_skill(classe_id: String, skill_resource: SkillResource, slot_index: int = -1) -> bool:
	if classe_id == "" or skill_resource == null:
		return false
	_ensure_equipamento(classe_id)
	_remove_if_present(classe_id, skill_resource)
	var equipamento: Dictionary = _equipment[classe_id]
	if skill_resource.type == SkillResource.Type.ACTIVE:
		if slot_index < 0:
			slot_index = first_free_slot(classe_id, SkillResource.Type.ACTIVE)
			if slot_index < 0:
				slot_index = 0
		if slot_index < 0 or slot_index >= MAX_ACTIVE:
			return false
		equipamento["actives"][slot_index] = skill_resource
	else:
		if slot_index < 0:
			slot_index = first_free_slot(classe_id, SkillResource.Type.PASSIVE)
			if slot_index < 0:
				slot_index = 0
		if slot_index < 0 or slot_index >= MAX_PASSIVE:
			return false
		equipamento["passives"][slot_index] = skill_resource
	equipment_changed.emit(classe_id)
	return true


func unequip_skill(classe_id: String, tipo: SkillResource.Type, slot_index: int) -> void:
	if classe_id == "" or not _equipment.has(classe_id):
		return
	var equipamento: Dictionary = _equipment[classe_id]
	if tipo == SkillResource.Type.ACTIVE:
		if slot_index < 0 or slot_index >= MAX_ACTIVE:
			return
		equipamento["actives"][slot_index] = null
	else:
		if slot_index < 0 or slot_index >= MAX_PASSIVE:
			return
		equipamento["passives"][slot_index] = null
	equipment_changed.emit(classe_id)


func is_equipped(classe_id: String, skill_resource: SkillResource) -> bool:
	if classe_id == "" or skill_resource == null or not _equipment.has(classe_id):
		return false
	var equipamento: Dictionary = _equipment[classe_id]
	for skill in equipamento["actives"]:
		if skill == skill_resource:
			return true
	for skill in equipamento["passives"]:
		if skill == skill_resource:
			return true
	return false


func first_free_slot(classe_id: String, tipo: SkillResource.Type) -> int:
	_ensure_equipamento(classe_id)
	var equipamento: Dictionary = _equipment[classe_id]
	if tipo == SkillResource.Type.ACTIVE:
		for i in MAX_ACTIVE:
			if equipamento["actives"][i] == null:
				return i
	else:
		for i in MAX_PASSIVE:
			if equipamento["passives"][i] == null:
				return i
	return -1


func get_equipped(classe_id: String, tipo: SkillResource.Type, slot_index: int) -> SkillResource:
	if classe_id == "":
		return null
	_ensure_equipamento(classe_id)
	var equipamento: Dictionary = _equipment[classe_id]
	if tipo == SkillResource.Type.ACTIVE:
		if slot_index < 0 or slot_index >= MAX_ACTIVE:
			return null
		return equipamento["actives"][slot_index]
	if slot_index < 0 or slot_index >= MAX_PASSIVE:
		return null
	return equipamento["passives"][slot_index]


func catalog_for(class_id: String) -> Array:
	class_id = ClassData.normalize_id(class_id)
	if class_id == "":
		return []
	if not _catalogos.has(class_id):
		_catalogos[class_id] = _load_catalog(class_id)
	return _catalogos[class_id]


func _ensure_equipamento(classe_id: String) -> void:
	if _equipment.has(classe_id):
		return
	_equipment[classe_id] = {
		"actives": _create_slots(MAX_ACTIVE),
		"passives": _create_slots(MAX_PASSIVE),
	}


func _create_slots(quantidade: int) -> Array:
	var slots: Array = []
	slots.resize(quantidade)
	return slots


func _remove_if_present(classe_id: String, skill_resource: SkillResource) -> void:
	if not _equipment.has(classe_id):
		return
	var equipamento: Dictionary = _equipment[classe_id]
	for i in MAX_ACTIVE:
		if equipamento["actives"][i] == skill_resource:
			equipamento["actives"][i] = null
	for i in MAX_PASSIVE:
		if equipamento["passives"][i] == skill_resource:
			equipamento["passives"][i] = null


func _load_catalog(class_id: String) -> Array:
	var lista: Array = []
	var pasta := "%s%s/" % [SKILLS_FOLDER, class_id]
	var dir := DirAccess.open(pasta)
	if dir == null:
		return lista
	dir.list_dir_begin()
	var nome_arquivo := dir.get_next()
	while nome_arquivo != "":
		if not dir.current_is_dir() and nome_arquivo.ends_with(".tres"):
			var caminho := pasta + nome_arquivo
			if not ResourceLoader.exists(caminho):
				push_warning("Habilidade não encontrada: %s" % caminho)
			else:
				var recurso: Resource = load(caminho)
				if recurso != null and recurso.get_script() == _SkillResourceScript:
					lista.append(recurso)
		nome_arquivo = dir.get_next()
	dir.list_dir_end()
	lista.sort_custom(_compare_skills)
	return lista


func _compare_skills(a: SkillResource, b: SkillResource) -> bool:
	if a.type != b.type:
		return a.type == SkillResource.Type.ACTIVE
	if a.sort_order != b.sort_order:
		return a.sort_order < b.sort_order
	return a.skill_id < b.skill_id


func serialize() -> Dictionary:
	var data: Dictionary = {}
	for class_id in _equipment.keys():
		var loadout: Dictionary = _equipment[class_id]
		data[class_id] = {
			"actives": _serialize_slots(loadout.get("actives", [])),
			"passives": _serialize_slots(loadout.get("passives", [])),
		}
	return data


func deserialize(data: Variant) -> void:
	_equipment.clear()
	if not (data is Dictionary):
		return
	for raw_class_id in data.keys():
		var class_id := ClassData.normalize_id(str(raw_class_id))
		var loadout: Variant = data[raw_class_id]
		if not (loadout is Dictionary):
			continue
		_ensure_equipamento(class_id)
		var equipamento: Dictionary = _equipment[class_id]
		equipamento["actives"] = _deserialize_slots(loadout.get("actives", []), MAX_ACTIVE)
		equipamento["passives"] = _deserialize_slots(loadout.get("passives", []), MAX_PASSIVE)


func _serialize_slots(slots: Array) -> Array:
	var result: Array = []
	for skill in slots:
		if skill is SkillResource:
			result.append(skill.skill_id)
		else:
			result.append("")
	return result


func _deserialize_slots(ids: Variant, max_slots: int) -> Array:
	var slots := _create_slots(max_slots)
	if not (ids is Array):
		return slots
	for i in mini(ids.size(), max_slots):
		var skill_id := str(ids[i])
		if skill_id == "":
			continue
		var skill := _find_skill_by_id(skill_id)
		if skill != null:
			slots[i] = skill
	return slots


func _find_skill_by_id(skill_id: String) -> SkillResource:
	for class_id in _catalogos.keys():
		for skill in catalog_for(str(class_id)):
			if skill is SkillResource and skill.skill_id == skill_id:
				return skill
	for classe in ClassData.catalog():
		for skill in catalog_for(classe.id):
			if skill is SkillResource and skill.skill_id == skill_id:
				return skill
	return null
