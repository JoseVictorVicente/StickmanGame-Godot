class_name ProgressoArvore
extends RefCounted
## Habilidades desbloqueadas compartilhadas por toda a equipe.

var _desbloqueados: Array[int] = []
var _catalogo: Array[Dictionary] = []


func _init() -> void:
	_catalogo = ArvoreHabilidades.catalogo()


func no_por_id(id_no: int) -> Dictionary:
	for no in _catalogo:
		if int(no.get("id", -1)) == id_no:
			return no
	return {}


func esta_desbloqueado(id_no: int) -> bool:
	return id_no in _desbloqueados


func pode_comprar(id_no: int) -> bool:
	if esta_desbloqueado(id_no):
		return false
	var no := no_por_id(id_no)
	if no.is_empty():
		return false
	var pai := int(no.get("pai", -1))
	if pai >= 0 and not esta_desbloqueado(pai):
		return false
	return true


func desbloquear(id_no: int) -> bool:
	if not pode_comprar(id_no):
		return false
	_desbloqueados.append(id_no)
	return true


func bonus_global() -> Dictionary:
	var total := ArvoreHabilidades.bonus_vazio()
	for id_no in _desbloqueados:
		var no := no_por_id(int(id_no))
		if no.is_empty():
			continue
		var chave := ArvoreHabilidades.chave_bonus(int(no.get("tipo", 0)))
		if chave == "":
			continue
		var valor := float(no.get("valor", 0))
		if chave in ["ataque", "vida"]:
			total[chave] = int(total[chave]) + int(valor)
		elif chave == "ataque_pct":
			total["ataque_pct"] = float(total["ataque_pct"]) + valor
		else:
			total[chave] = float(total[chave]) + valor
	return _aplicar_caps_bonus(total)


static func _aplicar_caps_bonus(total: Dictionary) -> Dictionary:
	var caps := {
		"ataque_pct": 20.0,
		"bonus_ouro": 30.0,
		"bonus_xp": 40.0,
		"vel_ataque": 45.0,
		"crit_chance": 25.0,
		"crit_dano": 60.0,
		"evasao": 25.0,
		"res_fisica": 35.0,
		"res_arcana": 35.0,
		"res_elemental": 35.0,
	}
	for chave in caps.keys():
		if chave in total:
			total[chave] = minf(float(total[chave]), float(caps[chave]))
	return total


func serializar() -> Array:
	return _desbloqueados.duplicate()


func aplicar(dados: Variant) -> void:
	_desbloqueados.clear()
	if not (dados is Array):
		return
	if dados.is_empty():
		return
	if dados[0] is Array:
		var uniao: Dictionary = {}
		for slot_lista in dados:
			if slot_lista is Array:
				for id_no in slot_lista:
					uniao[int(id_no)] = true
		for id_no in uniao.keys():
			var id := int(id_no)
			if not no_por_id(id).is_empty():
				_desbloqueados.append(id)
		return
	for id_no in dados:
		var id := int(id_no)
		if not no_por_id(id).is_empty():
			_desbloqueados.append(id)
