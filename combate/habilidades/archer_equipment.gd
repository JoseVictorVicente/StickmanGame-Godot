extends Node
## Gerencia as habilidades equipadas do Arqueiro (autoload: ArcherEquipment).

const _SkillResourceScript := preload("res://dados/skill_resource.gd")

signal equipamento_alterado

const MAX_ACTIVE := 2
const MAX_PASSIVE := 2

const CAMINHOS_CATALOGO: Array[String] = [
	"res://dados/habilidades/arqueiro/verdant_rain.tres",
	"res://dados/habilidades/arqueiro/soulseeker_shot.tres",
	"res://dados/habilidades/arqueiro/phantom_quiver.tres",
	"res://dados/habilidades/arqueiro/gale_precision.tres",
]

var equipped_actives: Array = []
var equipped_passives: Array = []
var catalogo: Array = []


func _ready() -> void:
	equipped_actives.resize(MAX_ACTIVE)
	equipped_passives.resize(MAX_PASSIVE)
	_carregar_catalogo()


func equip_skill(skill_resource: SkillResource, slot_index: int = -1) -> bool:
	if skill_resource == null:
		return false
	_remover_se_existir(skill_resource)
	if skill_resource.type == SkillResource.Type.ACTIVE:
		if slot_index < 0:
			slot_index = primeiro_slot_livre(SkillResource.Type.ACTIVE)
			if slot_index < 0:
				slot_index = 0
		if slot_index < 0 or slot_index >= MAX_ACTIVE:
			return false
		equipped_actives[slot_index] = skill_resource
	else:
		if slot_index < 0:
			slot_index = primeiro_slot_livre(SkillResource.Type.PASSIVE)
			if slot_index < 0:
				slot_index = 0
		if slot_index < 0 or slot_index >= MAX_PASSIVE:
			return false
		equipped_passives[slot_index] = skill_resource
	equipamento_alterado.emit()
	return true


func unequip_skill(tipo: SkillResource.Type, slot_index: int) -> void:
	if tipo == SkillResource.Type.ACTIVE:
		if slot_index < 0 or slot_index >= MAX_ACTIVE:
			return
		equipped_actives[slot_index] = null
	else:
		if slot_index < 0 or slot_index >= MAX_PASSIVE:
			return
		equipped_passives[slot_index] = null
	equipamento_alterado.emit()


func is_equipped(skill_resource: SkillResource) -> bool:
	if skill_resource == null:
		return false
	for skill in equipped_actives:
		if skill == skill_resource:
			return true
	for skill in equipped_passives:
		if skill == skill_resource:
			return true
	return false


func primeiro_slot_livre(tipo: SkillResource.Type) -> int:
	if tipo == SkillResource.Type.ACTIVE:
		for i in MAX_ACTIVE:
			if equipped_actives[i] == null:
				return i
	else:
		for i in MAX_PASSIVE:
			if equipped_passives[i] == null:
				return i
	return -1


func obter_equipada(tipo: SkillResource.Type, slot_index: int) -> SkillResource:
	if tipo == SkillResource.Type.ACTIVE:
		if slot_index < 0 or slot_index >= MAX_ACTIVE:
			return null
		return equipped_actives[slot_index]
	if slot_index < 0 or slot_index >= MAX_PASSIVE:
		return null
	return equipped_passives[slot_index]


func _remover_se_existir(skill_resource: SkillResource) -> void:
	for i in MAX_ACTIVE:
		if equipped_actives[i] == skill_resource:
			equipped_actives[i] = null
	for i in MAX_PASSIVE:
		if equipped_passives[i] == skill_resource:
			equipped_passives[i] = null


func _carregar_catalogo() -> void:
	catalogo.clear()
	for caminho in CAMINHOS_CATALOGO:
		if not ResourceLoader.exists(caminho):
			push_warning("Habilidade não encontrada: %s" % caminho)
			continue
		var recurso: Resource = load(caminho)
		if recurso != null and recurso.get_script() == _SkillResourceScript:
			catalogo.append(recurso)
