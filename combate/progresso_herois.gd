class_name ProgressoHerois
extends RefCounted
## Nível e XP dos 3 heróis da equipe.

const XP_BASE_NIVEL := 20
const SLOTS := 3

var slots: Array[Dictionary] = []


func _init() -> void:
	slots = [
		_slot_vazio(),
		_slot_vazio(),
		_slot_vazio(),
	]


func obter_nivel(indice: int) -> int:
	if indice < 0 or indice >= slots.size():
		return 1
	return maxi(1, int(slots[indice]["nivel"]))


func do_indice(indice: int) -> Dictionary:
	if indice < 0 or indice >= slots.size():
		return _slot_vazio()
	return slots[indice]


func aplicar_xp(quantidade: int, equipe_ativa: Array) -> PackedInt32Array:
	var niveis := PackedInt32Array()
	niveis.resize(SLOTS)
	for indice in SLOTS:
		niveis[indice] = obter_nivel(indice)
		if indice >= equipe_ativa.size() or equipe_ativa[indice] == null:
			continue
		var progresso: Dictionary = slots[indice]
		progresso["xp"] = int(progresso["xp"]) + quantidade
		while int(progresso["xp"]) >= int(progresso["xp_proximo"]) and int(progresso["xp_proximo"]) > 0:
			progresso["xp"] = int(progresso["xp"]) - int(progresso["xp_proximo"])
			progresso["nivel"] = int(progresso["nivel"]) + 1
			var proximo: int = int(XP_BASE_NIVEL * pow(1.35, int(progresso["nivel"]) - 1))
			progresso["xp_proximo"] = max(1, proximo)
		niveis[indice] = int(progresso["nivel"])
	return niveis


func serializar() -> Array:
	return slots.duplicate(true)


func aplicar(dados: Variant) -> void:
	if not (dados is Array):
		return
	for i in mini(dados.size(), slots.size()):
		if dados[i] is Dictionary:
			slots[i] = {
				"nivel": int(dados[i].get("nivel", 1)),
				"xp": int(dados[i].get("xp", 0)),
				"xp_proximo": int(dados[i].get("xp_proximo", XP_BASE_NIVEL)),
			}


func _slot_vazio() -> Dictionary:
	return {"nivel": 1, "xp": 0, "xp_proximo": XP_BASE_NIVEL}
