extends Node
## Gerencia as habilidades equipadas de cada classe de herói (autoload: HeroEquipment).

const _SkillResourceScript := preload("res://dados/skill_resource.gd")

signal equipamento_alterado(classe_id: String)

const MAX_ACTIVE := 2
const MAX_PASSIVE := 2
const PASTA_HABILIDADES := "res://dados/habilidades/"

var _equipamentos: Dictionary = {}
var _catalogos: Dictionary = {}


func equip_skill(classe_id: String, skill_resource: SkillResource, slot_index: int = -1) -> bool:
	if classe_id == "" or skill_resource == null:
		return false
	_ensure_equipamento(classe_id)
	_remover_se_existir(classe_id, skill_resource)
	var equipamento: Dictionary = _equipamentos[classe_id]
	if skill_resource.type == SkillResource.Type.ACTIVE:
		if slot_index < 0:
			slot_index = primeiro_slot_livre(classe_id, SkillResource.Type.ACTIVE)
			if slot_index < 0:
				slot_index = 0
		if slot_index < 0 or slot_index >= MAX_ACTIVE:
			return false
		equipamento["actives"][slot_index] = skill_resource
	else:
		if slot_index < 0:
			slot_index = primeiro_slot_livre(classe_id, SkillResource.Type.PASSIVE)
			if slot_index < 0:
				slot_index = 0
		if slot_index < 0 or slot_index >= MAX_PASSIVE:
			return false
		equipamento["passives"][slot_index] = skill_resource
	equipamento_alterado.emit(classe_id)
	return true


func unequip_skill(classe_id: String, tipo: SkillResource.Type, slot_index: int) -> void:
	if classe_id == "" or not _equipamentos.has(classe_id):
		return
	var equipamento: Dictionary = _equipamentos[classe_id]
	if tipo == SkillResource.Type.ACTIVE:
		if slot_index < 0 or slot_index >= MAX_ACTIVE:
			return
		equipamento["actives"][slot_index] = null
	else:
		if slot_index < 0 or slot_index >= MAX_PASSIVE:
			return
		equipamento["passives"][slot_index] = null
	equipamento_alterado.emit(classe_id)


func is_equipped(classe_id: String, skill_resource: SkillResource) -> bool:
	if classe_id == "" or skill_resource == null or not _equipamentos.has(classe_id):
		return false
	var equipamento: Dictionary = _equipamentos[classe_id]
	for skill in equipamento["actives"]:
		if skill == skill_resource:
			return true
	for skill in equipamento["passives"]:
		if skill == skill_resource:
			return true
	return false


func primeiro_slot_livre(classe_id: String, tipo: SkillResource.Type) -> int:
	_ensure_equipamento(classe_id)
	var equipamento: Dictionary = _equipamentos[classe_id]
	if tipo == SkillResource.Type.ACTIVE:
		for i in MAX_ACTIVE:
			if equipamento["actives"][i] == null:
				return i
	else:
		for i in MAX_PASSIVE:
			if equipamento["passives"][i] == null:
				return i
	return -1


func obter_equipada(classe_id: String, tipo: SkillResource.Type, slot_index: int) -> SkillResource:
	if classe_id == "":
		return null
	_ensure_equipamento(classe_id)
	var equipamento: Dictionary = _equipamentos[classe_id]
	if tipo == SkillResource.Type.ACTIVE:
		if slot_index < 0 or slot_index >= MAX_ACTIVE:
			return null
		return equipamento["actives"][slot_index]
	if slot_index < 0 or slot_index >= MAX_PASSIVE:
		return null
	return equipamento["passives"][slot_index]


func catalogo_de(classe_id: String) -> Array:
	if classe_id == "":
		return []
	if not _catalogos.has(classe_id):
		_catalogos[classe_id] = _carregar_catalogo(classe_id)
	return _catalogos[classe_id]


func _ensure_equipamento(classe_id: String) -> void:
	if _equipamentos.has(classe_id):
		return
	_equipamentos[classe_id] = {
		"actives": _criar_slots(MAX_ACTIVE),
		"passives": _criar_slots(MAX_PASSIVE),
	}


func _criar_slots(quantidade: int) -> Array:
	var slots: Array = []
	slots.resize(quantidade)
	return slots


func _remover_se_existir(classe_id: String, skill_resource: SkillResource) -> void:
	if not _equipamentos.has(classe_id):
		return
	var equipamento: Dictionary = _equipamentos[classe_id]
	for i in MAX_ACTIVE:
		if equipamento["actives"][i] == skill_resource:
			equipamento["actives"][i] = null
	for i in MAX_PASSIVE:
		if equipamento["passives"][i] == skill_resource:
			equipamento["passives"][i] = null


func _carregar_catalogo(classe_id: String) -> Array:
	var lista: Array = []
	var pasta := "%s%s/" % [PASTA_HABILIDADES, classe_id]
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
	lista.sort_custom(_comparar_skills)
	return lista


func _comparar_skills(a: SkillResource, b: SkillResource) -> bool:
	if a.type != b.type:
		return a.type == SkillResource.Type.ACTIVE
	if a.sort_order != b.sort_order:
		return a.sort_order < b.sort_order
	return a.skill_id < b.skill_id
