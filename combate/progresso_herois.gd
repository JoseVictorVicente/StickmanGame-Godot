class_name ProgressoHerois
extends RefCounted
## Nível e XP individuais por classe de herói.

const XP_BASE_NIVEL := 300
const XP_CRESCIMENTO := 1.43
const SLOTS := 3

var _por_classe: Dictionary = {}


func _init() -> void:
	for classe in ClasseData.catalogo():
		_por_classe[classe.id] = _slot_vazio()


static func xp_para_proximo(nivel: int) -> int:
	return maxi(1, int(XP_BASE_NIVEL * pow(XP_CRESCIMENTO, float(maxi(1, nivel) - 1))))


func id_classe_no_slot(indice: int, equipe_ativa: Array) -> String:
	if indice < 0 or indice >= equipe_ativa.size():
		return ""
	var classe: Variant = equipe_ativa[indice]
	if classe is ClasseData:
		return (classe as ClasseData).id
	return ""


func obter_por_classe(id_classe: String) -> Dictionary:
	if id_classe == "":
		return _slot_vazio()
	if not _por_classe.has(id_classe):
		_por_classe[id_classe] = _slot_vazio()
	return _por_classe[id_classe]


func obter_nivel_do_slot(indice: int, equipe_ativa: Array) -> int:
	var id := id_classe_no_slot(indice, equipe_ativa)
	if id == "":
		return 1
	return maxi(1, int(obter_por_classe(id)["nivel"]))


func do_indice(indice: int, equipe_ativa: Array) -> Dictionary:
	var id := id_classe_no_slot(indice, equipe_ativa)
	if id == "":
		return _slot_vazio()
	return obter_por_classe(id).duplicate()


func aplicar_xp(quantidade: int, equipe_ativa: Array) -> PackedInt32Array:
	var niveis := PackedInt32Array()
	niveis.resize(SLOTS)
	for indice in SLOTS:
		niveis[indice] = obter_nivel_do_slot(indice, equipe_ativa)
		var id := id_classe_no_slot(indice, equipe_ativa)
		if id == "":
			continue
		var progresso: Dictionary = obter_por_classe(id)
		progresso["xp"] = int(progresso["xp"]) + quantidade
		while int(progresso["xp"]) >= int(progresso["xp_proximo"]) and int(progresso["xp_proximo"]) > 0:
			progresso["xp"] = int(progresso["xp"]) - int(progresso["xp_proximo"])
			progresso["nivel"] = int(progresso["nivel"]) + 1
			progresso["xp_proximo"] = xp_para_proximo(int(progresso["nivel"]))
		_por_classe[id] = progresso
		niveis[indice] = int(progresso["nivel"])
	return niveis


func serializar() -> Dictionary:
	var dados: Dictionary = {}
	for id_classe in _por_classe.keys():
		var progresso: Dictionary = _por_classe[id_classe]
		dados[id_classe] = {
			"nivel": int(progresso["nivel"]),
			"xp": int(progresso["xp"]),
		}
	return dados


func aplicar(dados: Variant, ids_equipe: Array = []) -> void:
	if dados is Dictionary:
		for id_classe in dados.keys():
			if not (dados[id_classe] is Dictionary):
				continue
			var entrada: Dictionary = dados[id_classe]
			var nivel := maxi(1, int(entrada.get("nivel", 1)))
			_por_classe[str(id_classe)] = {
				"nivel": nivel,
				"xp": maxi(0, int(entrada.get("xp", 0))),
				"xp_proximo": xp_para_proximo(nivel),
			}
		return
	if not (dados is Array):
		return
	for i in mini(dados.size(), ids_equipe.size()):
		var id := str(ids_equipe[i])
		if id == "" or not (dados[i] is Dictionary):
			continue
		var nivel := maxi(1, int(dados[i].get("nivel", 1)))
		_por_classe[id] = {
			"nivel": nivel,
			"xp": maxi(0, int(dados[i].get("xp", 0))),
			"xp_proximo": xp_para_proximo(nivel),
		}


func _slot_vazio() -> Dictionary:
	return {"nivel": 1, "xp": 0, "xp_proximo": XP_BASE_NIVEL}
