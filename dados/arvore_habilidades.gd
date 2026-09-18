class_name ArvoreHabilidades
extends RefCounted
## Três colunas com padrão diamante 2-1-2… em 15 fileiras verticais.

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
	ARMAZEM,
}

enum Secao {
	ATAQUE = 0,
	DEFESA = 1,
	UTILIDADE = 2,
}

const NUM_SECOES := 3
const NUM_RAMOS := NUM_SECOES
const NUM_LINHAS := 15
const NOS_POR_SECAO := 23
const NOS_POR_RAMO := NOS_POR_SECAO
const TOTAL_NOS := NUM_SECOES * NOS_POR_SECAO

const LARGURA_COLUNA := 180.0
const ESPACO_COLUNAS := 14.0
const ALTURA_LINHA := 58.0
const ALTURA_CABECALHO := 44.0
const OFFSET_LATERAL := 52.0
const MARGEM_LATERAL := 16.0
const MARGEM_SUPERIOR := 12.0
const MARGEM_INFERIOR := 20.0

const CUSTO_BASE := 60
const CUSTO_CRESCIMENTO := 20
const CUSTO_POR_NIVEL := 28
const MULT_CUSTO_PREMIUM := 2.5
const NIVEL_MAX := 5
const NIVEL_MAX_ARMAZEM := 1

const _PADRAO_LINHAS: Array = [
	[0, 1],
	[2],
	[3, 4],
	[5],
	[6, 7],
	[8],
	[9, 10],
	[11],
	[12, 13],
	[14],
	[15, 16],
	[17],
	[18, 19],
	[20],
	[21, 22],
]


static func _padrao_linhas() -> Array:
	return _PADRAO_LINHAS


static func _idiv(a: int, b: int) -> int:
	return int(a / b)


static func catalogo() -> Array[Dictionary]:
	var nos: Array[Dictionary] = []
	for secao in NUM_SECOES:
		for slot in NOS_POR_SECAO:
			var linha := linha_do_slot(slot)
			var def := _criar_def_no(secao, slot, linha)
			nos.append({
				"id": id_do_no(secao, slot),
				"pais": pais_do_slot(secao, slot),
				"secao": secao,
				"regiao": secao,
				"slot": slot,
				"linha": linha,
				"tipo": int(def["tipo"]),
				"valor_base": int(def["valor_base"]),
				"valor": int(def["valor_base"]),
				"rotulo": str(def.get("rotulo", def.get("nome", ""))),
				"eh_pct": bool(def.get("eh_pct", false)),
				"nome": str(def["nome"]),
				"sigla": str(def["sigla"]),
				"premium": bool(def.get("premium", false)),
			})
	return nos


static func id_do_no(secao: int, slot: int) -> int:
	return secao * NOS_POR_SECAO + slot + 1


static func quantidade_nos_regiao(_secao: int) -> int:
	return NOS_POR_SECAO


static func pais_do_slot(secao: int, slot: int) -> Array[int]:
	var linha_atual := linha_do_slot(slot)
	if linha_atual == 0:
		return []
	var pais: Array[int] = []
	for s in NOS_POR_SECAO:
		if linha_do_slot(s) < linha_atual:
			pais.append(id_do_no(secao, s))
	return pais


static func slots_da_linha(linha: int) -> Array[int]:
	var arr: Array = _padrao_linhas()[linha]
	var saida: Array[int] = []
	for s in arr:
		saida.append(int(s))
	return saida


static func ligacoes_visuais() -> Array[Dictionary]:
	var ligacoes: Array[Dictionary] = []
	var padrao := _padrao_linhas()
	for row_idx in range(1, padrao.size()):
		var anterior: Array = padrao[row_idx - 1]
		var atual: Array = padrao[row_idx]
		if atual.size() == 1 and anterior.size() == 2:
			for slot_de in anterior:
				ligacoes.append({"de": int(slot_de), "para": int(atual[0]), "tipo": "merge"})
		elif atual.size() == 2 and anterior.size() == 1:
			for slot_para in atual:
				ligacoes.append({"de": int(anterior[0]), "para": int(slot_para), "tipo": "split"})
	return ligacoes


static func linha_do_slot(slot: int) -> int:
	var acum := 0
	for i in _padrao_linhas().size():
		var linha: Array = _padrao_linhas()[i]
		if slot < acum + linha.size():
			return i
		acum += linha.size()
	return 0


static func coluna_do_slot(slot: int) -> int:
	var acum := 0
	for linha in _padrao_linhas():
		if slot < acum + linha.size():
			if linha.size() == 1:
				return -1
			return slot - acum
		acum += linha.size()
	return -1


static func nome_regiao(secao: int) -> String:
	match secao:
		Secao.ATAQUE:
			return "Ataque"
		Secao.DEFESA:
			return "Defesa"
		Secao.UTILIDADE:
			return "Utilidade"
	return ""


static func centro_x_coluna(secao: int) -> float:
	return MARGEM_LATERAL + float(secao) * (LARGURA_COLUNA + ESPACO_COLUNAS) + LARGURA_COLUNA * 0.5


static func tamanho_canvas() -> Vector2:
	var altura := MARGEM_SUPERIOR + ALTURA_CABECALHO + float(NUM_LINHAS) * ALTURA_LINHA + MARGEM_INFERIOR
	var largura := MARGEM_LATERAL * 2.0 + float(NUM_SECOES) * LARGURA_COLUNA + float(NUM_SECOES - 1) * ESPACO_COLUNAS
	return Vector2(largura, altura)


static func custo_do_no(no: Dictionary, nivel_atual: int = 0) -> int:
	return custo_proximo_nivel(no, nivel_atual)


static func custo_proximo_nivel(no: Dictionary, nivel_atual: int) -> int:
	var proximo := nivel_atual + 1
	var linha := int(no.get("linha", 0))
	var base := CUSTO_BASE + linha * linha * CUSTO_CRESCIMENTO
	if bool(no.get("premium", false)):
		base = int(round(float(base) * MULT_CUSTO_PREMIUM))
	return base + proximo * proximo * CUSTO_POR_NIVEL


static func nivel_maximo(no: Dictionary) -> int:
	if int(no.get("tipo", -1)) == TipoBonus.ARMAZEM:
		return NIVEL_MAX_ARMAZEM
	return NIVEL_MAX


static func valor_bonus(no: Dictionary, nivel: int) -> float:
	if nivel <= 0:
		return 0.0
	return float(int(no.get("valor_base", no.get("valor", 1))) * nivel)


static func descricao_bonus(no: Dictionary, nivel: int) -> String:
	if nivel <= 0:
		return str(no.get("nome", ""))
	if int(no.get("tipo", -1)) == TipoBonus.ARMAZEM:
		return str(no.get("nome", ""))
	var rotulo := str(no.get("rotulo", no.get("sigla", "")))
	var total := int(valor_bonus(no, nivel))
	if bool(no.get("eh_pct", false)) or int(no.get("tipo", -1)) == TipoBonus.ATAQUE_PCT:
		return "%s +%d%%" % [rotulo, total]
	return "%s +%d" % [rotulo, total]


static func nome_proximo_nivel(no: Dictionary, nivel_atual: int) -> String:
	return descricao_bonus(no, nivel_atual + 1)


static func posicao_do_no(no: Dictionary) -> Vector2:
	var secao := int(no.get("secao", no.get("regiao", 0)))
	var slot := int(no.get("slot", 0))
	var linha := int(no.get("linha", linha_do_slot(slot)))
	var col := coluna_do_slot(slot)
	var cx := centro_x_coluna(secao)
	var x := cx
	if col == 0:
		x = cx - OFFSET_LATERAL
	elif col == 1:
		x = cx + OFFSET_LATERAL
	var y := MARGEM_SUPERIOR + ALTURA_CABECALHO + float(linha) * ALTURA_LINHA + ALTURA_LINHA * 0.5
	return Vector2(x, y)


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
		TipoBonus.ARMAZEM:
			return ""
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


static func cor_regiao(secao: int) -> Color:
	match secao:
		Secao.ATAQUE:
			return Color(0.85, 0.32, 0.28, 1)
		Secao.DEFESA:
			return Color(0.28, 0.65, 0.38, 1)
		Secao.UTILIDADE:
			return Color(0.35, 0.52, 0.88, 1)
	return Color(0.6, 0.6, 0.6, 1)


static func _criar_def_no(secao: int, slot: int, linha: int) -> Dictionary:
	match secao:
		Secao.ATAQUE:
			return _criar_no_ataque(slot, linha)
		Secao.DEFESA:
			return _criar_no_defesa(slot, linha)
		Secao.UTILIDADE:
			return _criar_no_utilidade(slot, linha)
	return _criar_no_ataque(slot, linha)


static func _criar_no_ataque(slot: int, linha: int) -> Dictionary:
	var merge := linha % 2 == 1
	if merge and linha in [5, 9, 13]:
		var pct := 2 + _idiv(linha, 5)
		return {
			"tipo": TipoBonus.ATAQUE_PCT,
			"valor_base": pct,
			"sigla": "%",
			"rotulo": "Ataque",
			"eh_pct": true,
			"nome": "Ataque +%d%%" % pct,
			"premium": true,
		}
	var tipos: Array = [
		TipoBonus.ATAQUE,
		TipoBonus.VEL_ATAQUE,
		TipoBonus.CRIT_CHANCE,
		TipoBonus.CRIT_DANO,
	]
	var siglas: Array = ["ATK", "VEL", "CRIT", "DCR"]
	var rotulos: Array = ["Ataque", "Vel.", "Crít.", "D.Crít"]
	var pct_flags: Array = [false, true, true, true]
	var idx := 0 if merge else (slot + linha) % tipos.size()
	return _montar_def_stat(tipos[idx] as TipoBonus, str(siglas[idx]), str(rotulos[idx]), bool(pct_flags[idx]), linha, false)


static func _criar_no_defesa(slot: int, linha: int) -> Dictionary:
	var merge := linha % 2 == 1
	if merge and linha in [5, 9, 13]:
		var valor := 8 + linha
		return {
			"tipo": TipoBonus.VIDA,
			"valor_base": valor,
			"sigla": "VID",
			"rotulo": "Vida",
			"eh_pct": false,
			"nome": "Vida +%d" % valor,
			"premium": true,
		}
	var tipos: Array = [
		TipoBonus.VIDA,
		TipoBonus.EVASAO,
		TipoBonus.RES_FISICA,
		TipoBonus.RES_ARCANA,
		TipoBonus.RES_ELEMENTAL,
	]
	var siglas: Array = ["VID", "EVA", "FIS", "ARC", "ELE"]
	var rotulos: Array = ["Vida", "Evasão", "Res. Fís.", "Res. Arc.", "Res. Elem."]
	var pct_flags: Array = [false, true, true, true, true]
	var idx := 0 if merge else (slot + linha) % tipos.size()
	return _montar_def_stat(tipos[idx] as TipoBonus, str(siglas[idx]), str(rotulos[idx]), bool(pct_flags[idx]), linha, false)


static func _criar_no_utilidade(slot: int, linha: int) -> Dictionary:
	var merge := linha % 2 == 1
	if merge and linha in [7, 11, 13]:
		var indice_arm := [7, 11, 13].find(linha)
		var valor := indice_arm + 1
		return {
			"tipo": TipoBonus.ARMAZEM,
			"valor_base": valor,
			"sigla": "ARM",
			"rotulo": "Armazém",
			"eh_pct": false,
			"nome": "Armazém %d" % (valor + 1),
			"premium": false,
		}
	if merge and linha in [5, 9, 13]:
		var pct := 2 + _idiv(linha, 4)
		return {
			"tipo": TipoBonus.BONUS_XP,
			"valor_base": pct,
			"sigla": "XP",
			"rotulo": "XP",
			"eh_pct": true,
			"nome": "XP +%d%%" % pct,
			"premium": true,
		}
	var usa_xp := (slot + linha) % 2 == 0
	if usa_xp:
		var valor_xp := 1 + _idiv(linha, 3)
		return {
			"tipo": TipoBonus.BONUS_XP,
			"valor_base": valor_xp,
			"sigla": "XP",
			"rotulo": "XP",
			"eh_pct": true,
			"nome": "XP +%d%%" % valor_xp,
			"premium": false,
		}
	var valor_ouro := 1 + _idiv(linha, 3)
	return {
		"tipo": TipoBonus.BONUS_OURO,
		"valor_base": valor_ouro,
		"sigla": "OURO",
		"rotulo": "Ouro",
		"eh_pct": true,
		"nome": "Ouro +%d%%" % valor_ouro,
		"premium": false,
	}


static func _montar_def_stat(
	tipo: TipoBonus,
	sigla: String,
	rotulo: String,
	eh_pct: bool,
	linha: int,
	premium: bool
) -> Dictionary:
	var valor := _valor_por_tipo(tipo, linha)
	var nome := "%s +%d%%" % [rotulo, valor] if eh_pct else "%s +%d" % [rotulo, valor]
	return {
		"tipo": tipo,
		"valor_base": valor,
		"sigla": sigla,
		"rotulo": rotulo,
		"eh_pct": eh_pct,
		"nome": nome,
		"premium": premium,
	}


static func _valor_por_tipo(tipo: TipoBonus, linha: int) -> int:
	match tipo:
		TipoBonus.ATAQUE:
			return 2 + _idiv(linha, 3)
		TipoBonus.VIDA:
			return 4 + _idiv(linha, 2)
		TipoBonus.VEL_ATAQUE, TipoBonus.CRIT_CHANCE, TipoBonus.EVASAO:
			return 1 + _idiv(linha, 4)
		TipoBonus.CRIT_DANO:
			return 3 + _idiv(linha, 3)
		TipoBonus.RES_FISICA, TipoBonus.RES_ARCANA, TipoBonus.RES_ELEMENTAL:
			return 1 + _idiv(linha, 4)
		TipoBonus.BONUS_XP, TipoBonus.BONUS_OURO:
			return 1 + _idiv(linha, 3)
	return 1
