class_name ArvoreHabilidades
extends RefCounted
## Árvore radial: nó central de ataque + 11 ramos com 15 nós cada.

enum TipoBonus {
	ATAQUE,
	ATAQUE_PCT,
	VIDA,
	BONUS_XP,
	BONUS_OURO,
	VEL_ATAQUE,
	CRIT_CHANCE,
	CRIT_DANO,
	EVASAO,
	RES_FISICA,
	RES_ARCANA,
	RES_ELEMENTAL,
}

const NUM_RAMOS := 11
const NOS_POR_RAMO := 15
const TOTAL_NOS := 1 + NUM_RAMOS * NOS_POR_RAMO
const NOS_ATAQUE_PCT := 5
const NOS_ATAQUE_FLAT := NOS_POR_RAMO - NOS_ATAQUE_PCT

const CENTRO_CANVAS := Vector2(950, 950)
const TAMANHO_CANVAS := Vector2(1900, 1900)
const RAIO_INICIAL := 72.0
const RAIO_PASSO := 48.0

const CUSTO_CENTRO := 50
const CUSTO_BASE_RAMO := 80
const CUSTO_CRESCIMENTO := 18
const MULT_CUSTO_PREMIUM := 3.0

const _DEF_RAMOS: Array[Dictionary] = [
	{"tipo": TipoBonus.ATAQUE, "sigla": "ATK", "rotulo": "Ataque", "valor": 2, "pct": false},
	{"tipo": TipoBonus.VIDA, "sigla": "VID", "rotulo": "Vida", "valor": 6, "pct": false},
	{"tipo": TipoBonus.BONUS_XP, "sigla": "XP", "rotulo": "XP", "valor": 2, "pct": true},
	{"tipo": TipoBonus.BONUS_OURO, "sigla": "OURO", "rotulo": "Ouro", "valor": 2, "pct": true},
	{"tipo": TipoBonus.VEL_ATAQUE, "sigla": "VEL", "rotulo": "Vel.", "valor": 3, "pct": true},
	{"tipo": TipoBonus.CRIT_CHANCE, "sigla": "CRIT", "rotulo": "Crít.", "valor": 1, "pct": true},
	{"tipo": TipoBonus.CRIT_DANO, "sigla": "DCR", "rotulo": "D.Crít", "valor": 4, "pct": true},
	{"tipo": TipoBonus.EVASAO, "sigla": "EVA", "rotulo": "Evasão", "valor": 2, "pct": true},
	{"tipo": TipoBonus.RES_FISICA, "sigla": "FIS", "rotulo": "Res. Fís.", "valor": 2, "pct": true},
	{"tipo": TipoBonus.RES_ARCANA, "sigla": "ARC", "rotulo": "Res. Arc.", "valor": 2, "pct": true},
	{"tipo": TipoBonus.RES_ELEMENTAL, "sigla": "ELE", "rotulo": "Res. Elem.", "valor": 2, "pct": true},
]


static func catalogo() -> Array[Dictionary]:
	var nos: Array[Dictionary] = []
	nos.append(_no_centro())
	for regiao in NUM_RAMOS:
		var pai := 0
		for profundidade in NOS_POR_RAMO:
			var no := _no_ramo(regiao, profundidade, pai)
			nos.append(no)
			pai = int(no["id"])
	return nos


static func id_do_no(regiao: int, profundidade: int) -> int:
	return 1 + regiao * NOS_POR_RAMO + profundidade


static func angulo_regiao(regiao: int) -> float:
	return -PI * 0.5 + float(regiao) * TAU / float(NUM_RAMOS)


static func custo_do_no(no: Dictionary) -> int:
	var id := int(no.get("id", -1))
	if id == 0:
		return CUSTO_CENTRO
	var profundidade := int(no.get("profundidade", 0))
	var base := CUSTO_BASE_RAMO + profundidade * profundidade * CUSTO_CRESCIMENTO
	if bool(no.get("premium", false)):
		return int(round(float(base) * MULT_CUSTO_PREMIUM))
	return base


static func posicao_do_no(no: Dictionary) -> Vector2:
	var id := int(no.get("id", 0))
	if id == 0:
		return CENTRO_CANVAS
	var regiao := int(no.get("regiao", 0))
	var profundidade := int(no.get("profundidade", 0))
	var ang := angulo_regiao(regiao)
	var raio := RAIO_INICIAL + float(profundidade) * RAIO_PASSO
	return CENTRO_CANVAS + Vector2(cos(ang), sin(ang)) * raio


static func chave_bonus(tipo: TipoBonus) -> String:
	match tipo:
		TipoBonus.ATAQUE:
			return "ataque"
		TipoBonus.ATAQUE_PCT:
			return "ataque_pct"
		TipoBonus.VIDA:
			return "vida"
		TipoBonus.BONUS_XP:
			return "bonus_xp"
		TipoBonus.BONUS_OURO:
			return "bonus_ouro"
		TipoBonus.VEL_ATAQUE:
			return "vel_ataque"
		TipoBonus.CRIT_CHANCE:
			return "crit_chance"
		TipoBonus.CRIT_DANO:
			return "crit_dano"
		TipoBonus.EVASAO:
			return "evasao"
		TipoBonus.RES_FISICA:
			return "res_fisica"
		TipoBonus.RES_ARCANA:
			return "res_arcana"
		TipoBonus.RES_ELEMENTAL:
			return "res_elemental"
	return ""


static func bonus_vazio() -> Dictionary:
	return {
		"ataque": 0,
		"ataque_pct": 0.0,
		"vida": 0,
		"bonus_xp": 0.0,
		"bonus_ouro": 0.0,
		"vel_ataque": 0.0,
		"crit_chance": 0.0,
		"crit_dano": 0.0,
		"evasao": 0.0,
		"res_fisica": 0.0,
		"res_arcana": 0.0,
		"res_elemental": 0.0,
	}


static func cor_regiao(regiao: int) -> Color:
	var cores: Array[Color] = [
		Color(0.82, 0.28, 0.22, 1),
		Color(0.22, 0.62, 0.32, 1),
		Color(0.32, 0.48, 0.92, 1),
		Color(0.92, 0.78, 0.22, 1),
		Color(0.58, 0.32, 0.82, 1),
		Color(0.92, 0.42, 0.18, 1),
		Color(0.18, 0.72, 0.72, 1),
		Color(0.72, 0.72, 0.28, 1),
		Color(0.55, 0.42, 0.28, 1),
		Color(0.42, 0.28, 0.72, 1),
		Color(0.28, 0.62, 0.62, 1),
	]
	return cores[regiao % cores.size()]


static func _no_centro() -> Dictionary:
	return {
		"id": 0,
		"pai": -1,
		"regiao": -1,
		"profundidade": -1,
		"angulo": 0.0,
		"tipo": int(TipoBonus.ATAQUE),
		"valor": 3,
		"nome": "Ataque +3",
		"sigla": "ATK",
		"premium": false,
	}


static func _no_ramo(regiao: int, profundidade: int, pai: int) -> Dictionary:
	var def: Dictionary = _DEF_RAMOS[regiao]
	var id := id_do_no(regiao, profundidade)
	var tipo: TipoBonus = def["tipo"]
	var valor: int = int(def["valor"])
	var premium := false
	var nome := ""
	var sigla: String = def["sigla"]

	if regiao == 0:
		if profundidade >= NOS_ATAQUE_FLAT:
			tipo = TipoBonus.ATAQUE_PCT
			valor = 3
			premium = true
			nome = "Ataque +3%"
		else:
			nome = "Ataque +%d" % valor
	elif bool(def.get("pct", false)):
		nome = "%s +%d%%" % [def["rotulo"], valor]
	else:
		nome = "%s +%d" % [def["rotulo"], valor]

	return {
		"id": id,
		"pai": pai,
		"regiao": regiao,
		"profundidade": profundidade,
		"angulo": angulo_regiao(regiao),
		"tipo": int(tipo),
		"valor": valor,
		"nome": nome,
		"sigla": sigla,
		"premium": premium,
	}
