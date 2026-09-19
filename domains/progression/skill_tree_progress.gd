class_name SkillTreeProgress
extends RefCounted
## Shared skill tree levels for the whole party.

var _niveis: Dictionary = {}
var _catalogo: Array[Dictionary] = []


func _init() -> void:
	_catalogo = SkillTreeDefinition.catalog()


func node_by_id(id_no: int) -> Dictionary:
	for no in _catalogo:
		if int(no.get("id", -1)) == id_no:
			return no
	return {}


func node_level(id_no: int) -> int:
	return int(_niveis.get(id_no, 0))


func is_unlocked(id_no: int) -> bool:
	return node_level(id_no) >= 1


func max_level(id_no: int) -> int:
	var no := node_by_id(id_no)
	if no.is_empty():
		return 0
	return SkillTreeDefinition.max_level(no)


func is_at_max_level(id_no: int) -> bool:
	return node_level(id_no) >= max_level(id_no)


func points_in_section(secao: int) -> int:
	var total := 0
	for id_no in _niveis.keys():
		var no := node_by_id(int(id_no))
		if no.is_empty():
			continue
		if int(no.get("secao", no.get("regiao", -1))) == secao:
			total += node_level(int(id_no))
	return total


func can_purchase(id_no: int) -> bool:
	if is_at_max_level(id_no):
		return false
	var no := node_by_id(id_no)
	if no.is_empty():
		return false
	var nivel := node_level(id_no)
	if nivel <= 0:
		var pais: Array = no.get("pais", [])
		for id_pai in pais:
			if node_level(int(id_pai)) < 1:
				return false
	return true


func level_up(id_no: int) -> bool:
	if not can_purchase(id_no):
		return false
	_niveis[id_no] = node_level(id_no) + 1
	return true


func unlock(id_no: int) -> bool:
	return level_up(id_no)


func global_bonus() -> Dictionary:
	var total := SkillTreeDefinition.empty_bonus()
	for id_no in _niveis.keys():
		var nivel := node_level(int(id_no))
		if nivel <= 0:
			continue
		var no := node_by_id(int(id_no))
		if no.is_empty():
			continue
		var chave := SkillTreeDefinition.bonus_key(int(no.get("type", 0)))
		if chave == "":
			continue
		var valor := SkillTreeDefinition.bonus_value(no, nivel)
		if chave in ["attack", "hp"]:
			total[chave] = int(total[chave]) + int(valor)
		elif chave == "attack_pct":
			total["attack_pct"] = float(total["attack_pct"]) + valor
		else:
			total[chave] = float(total[chave]) + valor
	return _aplicar_caps_bonus(total)


func unlocked_warehouse_indices() -> Array[int]:
	var saida: Array[int] = []
	for id_no in _niveis.keys():
		if node_level(int(id_no)) < 1:
			continue
		var no := node_by_id(int(id_no))
		if no.is_empty():
			continue
		if int(no.get("type", -1)) != SkillTreeDefinition.BonusType.WAREHOUSE:
			continue
		saida.append(int(no.get("valor_base", no.get("valor", 0))))
	return saida


static func _aplicar_caps_bonus(total: Dictionary) -> Dictionary:
	var caps := {
		"attack_pct": 20.0,
		"gold_bonus": 30.0,
		"xp_bonus": 40.0,
		"attack_speed": 45.0,
		"crit_chance": 25.0,
		"crit_damage": 60.0,
		"evasion": 25.0,
		"phys_res": 35.0,
		"arcane_res": 35.0,
		"elemental_res": 35.0,
		"cooldown_reduction": 40.0,
	}
	for chave in caps.keys():
		if chave in total:
			total[chave] = minf(float(total[chave]), float(caps[chave]))
	return total


func serialize() -> Dictionary:
	return _niveis.duplicate()


func apply(data: Variant) -> void:
	_niveis.clear()
	if data is Dictionary:
		for id_no in data.keys():
			var id := int(id_no)
			var no := node_by_id(id)
			if no.is_empty():
				continue
			var nivel := clampi(int(data[id_no]), 0, max_level(id))
			if nivel > 0:
				_niveis[id] = nivel
		_migrate_saves()
		return
	if not (data is Array):
		return
	if data.is_empty():
		return
	if data[0] is Array:
		var uniao: Dictionary = {}
		for slot_lista in data:
			if slot_lista is Array:
				for id_no in slot_lista:
					uniao[int(id_no)] = true
		for id_no in uniao.keys():
			var id := int(id_no)
			if not node_by_id(id).is_empty():
				_niveis[id] = 1
		_migrate_saves()
		return
	for id_no in data:
		var id := int(id_no)
		if not node_by_id(id).is_empty():
			_niveis[id] = 1
	_migrate_saves()


func _migrate_saves() -> void:
	var validos: Dictionary = {}
	for id_no in _niveis.keys():
		var id := int(id_no)
		var no := node_by_id(id)
		if no.is_empty():
			continue
		validos[id] = clampi(node_level(id), 0, max_level(id))
	_niveis = validos
	for secao in SkillTreeDefinition.NUM_SECTIONS:
		_repair_section_chain(secao)


func _repair_section_chain(secao: int) -> void:
	for slot in SkillTreeDefinition.NODES_PER_SECTION:
		var id := SkillTreeDefinition.node_id(secao, slot)
		if node_level(id) <= 0:
			continue
		for id_pai in SkillTreeDefinition.parent_slots(secao, slot):
			if node_level(id_pai) < 1:
				_niveis[id_pai] = 1
