class_name ArvoreHabilidades
extends RefCounted
## Catálogo da árvore radial de habilidades (15 nós).

enum TipoBonus {
	ATAQUE,
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

const TOTAL_NOS := 15
const RAIO_INTERNO := 118.0
const RAIO_EXTERNO := 210.0
const CENTRO_CANVAS := Vector2(450, 450)
const CUSTOS_ANEL: Array[int] = [50, 300, 1500]


static func catalogo() -> Array[Dictionary]:
	var nos: Array[Dictionary] = []
	nos.append(_no(0, -1, 0, 0.0, TipoBonus.ATAQUE, 3, "Ataque +3"))
	var inner := [
		{"tipo": TipoBonus.VIDA, "valor": 8, "nome": "Vida +8"},
		{"tipo": TipoBonus.BONUS_XP, "valor": 2, "nome": "XP +2%"},
		{"tipo": TipoBonus.BONUS_OURO, "valor": 2, "nome": "Ouro +2%"},
		{"tipo": TipoBonus.VEL_ATAQUE, "valor": 3, "nome": "Vel. +3%"},
		{"tipo": TipoBonus.CRIT_CHANCE, "valor": 1, "nome": "Crít. +1%"},
		{"tipo": TipoBonus.RES_ARCANA, "valor": 2, "nome": "Res. Arc. +2%"},
	]
	for i in inner.size():
		var ang := -PI * 0.5 + float(i) * TAU / float(inner.size())
		nos.append(_no(i + 1, 0, 1, ang, inner[i]["tipo"], inner[i]["valor"], inner[i]["nome"]))
	var outer := [
		{"pai": 1, "tipo": TipoBonus.ATAQUE, "valor": 2, "nome": "Ataque +2"},
		{"pai": 2, "tipo": TipoBonus.VIDA, "valor": 12, "nome": "Vida +12"},
		{"pai": 3, "tipo": TipoBonus.BONUS_XP, "valor": 3, "nome": "XP +3%"},
		{"pai": 4, "tipo": TipoBonus.BONUS_OURO, "valor": 3, "nome": "Ouro +3%"},
		{"pai": 5, "tipo": TipoBonus.EVASAO, "valor": 2, "nome": "Evasão +2%"},
		{"pai": 6, "tipo": TipoBonus.CRIT_DANO, "valor": 5, "nome": "D.Crít +5%"},
		{"pai": 1, "tipo": TipoBonus.RES_FISICA, "valor": 3, "nome": "Res. Fís. +3%"},
		{"pai": 6, "tipo": TipoBonus.RES_ELEMENTAL, "valor": 3, "nome": "Res. Elem. +3%"},
	]
	for i in outer.size():
		var pai := int(outer[i]["pai"])
		var ang_pai: float = nos[pai]["angulo"]
		var desvio := -0.28 if i % 2 == 0 else 0.28
		nos.append(_no(7 + i, pai, 2, ang_pai + desvio, outer[i]["tipo"], outer[i]["valor"], outer[i]["nome"]))
	return nos


static func custo_do_no(no: Dictionary) -> int:
	var anel := clampi(int(no.get("anel", 0)), 0, CUSTOS_ANEL.size() - 1)
	return CUSTOS_ANEL[anel]


static func posicao_do_no(no: Dictionary) -> Vector2:
	var raio := RAIO_INTERNO if int(no.get("anel", 0)) == 1 else RAIO_EXTERNO if int(no.get("anel", 0)) == 2 else 0.0
	var ang: float = no.get("angulo", 0.0)
	return CENTRO_CANVAS + Vector2(cos(ang), sin(ang)) * raio


static func chave_bonus(tipo: TipoBonus) -> String:
	match tipo:
		TipoBonus.ATAQUE:
			return "ataque"
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


static func _no(id: int, pai: int, anel: int, angulo: float, tipo: TipoBonus, valor: int, nome: String) -> Dictionary:
	return {
		"id": id,
		"pai": pai,
		"anel": anel,
		"angulo": angulo,
		"tipo": int(tipo),
		"valor": valor,
		"nome": nome,
	}
