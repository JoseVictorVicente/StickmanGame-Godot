class_name SkillTreeDefinition
extends RefCounted
## Três colunas com padrão diamante 2-1-2… em 15 fileiras verticais.

enum BonusType {
	ATTACK,
	ATTACK_PCT,
	HP,
	BONUS_XP,
	GOLD_BONUS,
	ATTACK_SPEED,
	CRIT_CHANCE,
	CRIT_DAMAGE,
	EVASION,
	PHYS_RES,
	ARCANE_RES,
	ELEMENTAL_RES,
	WAREHOUSE,
}

enum Section {
	ATTACK = 0,
	DEFENSE = 1,
	UTILITY = 2,
}

const NUM_SECTIONS := 3
const NUM_BRANCHES := NUM_SECTIONS
const NUM_ROWS := 15
const NODES_PER_SECTION := 23
const NODES_PER_BRANCH := NODES_PER_SECTION
const TOTAL_NODES := NUM_SECTIONS * NODES_PER_SECTION

const COLUMN_WIDTH := 180.0
const COLUMN_GAP := 14.0
const ROW_HEIGHT := 66.0
const HEADER_HEIGHT := 44.0
const SIDE_OFFSET := 52.0
const SIDE_MARGIN := 16.0
const TOP_MARGIN := 12.0
const BOTTOM_MARGIN := 20.0

const BASE_COST := 60
const COST_GROWTH := 20
const COST_PER_LEVEL := 28
const PREMIUM_COST_MULT := 2.5
const MAX_LEVEL := 5
const MAX_WAREHOUSE_LEVEL := 1

const _ROW_PATTERN: Array = [
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
	return _ROW_PATTERN


static func _idiv(a: int, b: int) -> int:
	return int(a / b)


static func catalog() -> Array[Dictionary]:
	var nos: Array[Dictionary] = []
	for secao in NUM_SECTIONS:
		for slot in NODES_PER_SECTION:
			var linha := slot_row(slot)
			var def := _create_node_def(secao, slot, linha)
			nos.append({
				"id": node_id(secao, slot),
				"pais": parent_slots(secao, slot),
				"secao": secao,
				"regiao": secao,
				"slot": slot,
				"linha": linha,
				"type": int(def["tipo"]),
				"valor_base": int(def["valor_base"]),
				"valor": int(def["valor_base"]),
				"label": str(def.get("rotulo", def.get("name", ""))),
				"eh_pct": bool(def.get("eh_pct", false)),
				"name": str(def["name"]),
				"sigla": str(def["sigla"]),
				"premium": bool(def.get("premium", false)),
			})
	return nos


static func node_id(secao: int, slot: int) -> int:
	return secao * NODES_PER_SECTION + slot + 1


static func quantidade_nos_regiao(_secao: int) -> int:
	return NODES_PER_SECTION


static func parent_slots(secao: int, slot: int) -> Array[int]:
	var linha_atual := slot_row(slot)
	if linha_atual == 0:
		return []
	var pais: Array[int] = []
	for s in NODES_PER_SECTION:
		if slot_row(s) < linha_atual:
			pais.append(node_id(secao, s))
	return pais


static func slots_in_row(linha: int) -> Array[int]:
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


static func slot_row(slot: int) -> int:
	var acum := 0
	for i in _padrao_linhas().size():
		var linha: Array = _padrao_linhas()[i]
		if slot < acum + linha.size():
			return i
		acum += linha.size()
	return 0


static func slot_column(slot: int) -> int:
	var acum := 0
	for linha in _padrao_linhas():
		if slot < acum + linha.size():
			if linha.size() == 1:
				return -1
			return slot - acum
		acum += linha.size()
	return -1


static func region_name_key(secao: int) -> String:
	match secao:
		Section.ATTACK:
			return LocaleKeys.TREE_REGION_ATTACK
		Section.DEFENSE:
			return LocaleKeys.TREE_REGION_DEFENSE
		Section.UTILITY:
			return LocaleKeys.TREE_REGION_UTILITY
	return ""


static func region_name(secao: int) -> String:
	return region_name_key(secao)


static func centro_x_coluna(secao: int) -> float:
	return SIDE_MARGIN + float(secao) * (COLUMN_WIDTH + COLUMN_GAP) + COLUMN_WIDTH * 0.5


static func tamanho_canvas() -> Vector2:
	var altura := TOP_MARGIN + HEADER_HEIGHT + float(NUM_ROWS) * ROW_HEIGHT + BOTTOM_MARGIN
	var largura := SIDE_MARGIN * 2.0 + float(NUM_SECTIONS) * COLUMN_WIDTH + float(NUM_SECTIONS - 1) * COLUMN_GAP
	return Vector2(largura, altura)


static func custo_do_no(no: Dictionary, nivel_atual: int = 0) -> int:
	return next_level_cost(no, nivel_atual)


static func next_level_cost(no: Dictionary, nivel_atual: int) -> int:
	var next_stage := nivel_atual + 1
	var linha := int(no.get("linha", 0))
	var base := BASE_COST + linha * linha * COST_GROWTH
	if bool(no.get("premium", false)):
		base = int(round(float(base) * PREMIUM_COST_MULT))
	return base + next_stage * next_stage * COST_PER_LEVEL


static func max_level(no: Dictionary) -> int:
	if int(no.get("type", -1)) == BonusType.WAREHOUSE:
		return MAX_WAREHOUSE_LEVEL
	return MAX_LEVEL


static func bonus_value(no: Dictionary, nivel: int) -> float:
	if nivel <= 0:
		return 0.0
	return float(int(no.get("valor_base", no.get("valor", 1))) * nivel)


static func bonus_description(no: Dictionary, nivel: int) -> String:
	if nivel <= 0:
		return str(no.get("name", ""))
	if int(no.get("type", -1)) == BonusType.WAREHOUSE:
		return str(no.get("name", ""))
	var rotulo := str(no.get("rotulo", no.get("sigla", "")))
	var total := int(bonus_value(no, nivel))
	if bool(no.get("eh_pct", false)) or int(no.get("type", -1)) == BonusType.ATTACK_PCT:
		return "%s +%d%%" % [rotulo, total]
	return "%s +%d" % [rotulo, total]


static func next_level_name(no: Dictionary, nivel_atual: int) -> String:
	return bonus_description(no, nivel_atual + 1)


static func posicao_do_no(no: Dictionary) -> Vector2:
	var secao := int(no.get("secao", no.get("regiao", 0)))
	var slot := int(no.get("slot", 0))
	var linha := int(no.get("linha", slot_row(slot)))
	var col := slot_column(slot)
	var cx := centro_x_coluna(secao)
	var x := cx
	if col == 0:
		x = cx - SIDE_OFFSET
	elif col == 1:
		x = cx + SIDE_OFFSET
	var y := TOP_MARGIN + HEADER_HEIGHT + float(linha) * ROW_HEIGHT + ROW_HEIGHT * 0.5
	return Vector2(x, y)


static func bonus_key(tipo: BonusType) -> String:
	match tipo:
		BonusType.ATTACK:
			return "attack"
		BonusType.ATTACK_PCT:
			return "attack_pct"
		BonusType.HP:
			return "hp"
		BonusType.BONUS_XP:
			return "xp_bonus"
		BonusType.GOLD_BONUS:
			return "gold_bonus"
		BonusType.ATTACK_SPEED:
			return "attack_speed"
		BonusType.CRIT_CHANCE:
			return "crit_chance"
		BonusType.CRIT_DAMAGE:
			return "crit_damage"
		BonusType.EVASION:
			return "evasion"
		BonusType.PHYS_RES:
			return "phys_res"
		BonusType.ARCANE_RES:
			return "arcane_res"
		BonusType.ELEMENTAL_RES:
			return "elemental_res"
		BonusType.WAREHOUSE:
			return ""
	return ""


static func empty_bonus() -> Dictionary:
	return {
		"attack": 0,
		"attack_pct": 0.0,
		"hp": 0,
		"hp_pct": 0.0,
		"xp_bonus": 0.0,
		"gold_bonus": 0.0,
		"attack_speed": 0.0,
		"crit_chance": 0.0,
		"crit_damage": 0.0,
		"evasion": 0.0,
		"phys_res": 0.0,
		"arcane_res": 0.0,
		"elemental_res": 0.0,
	}


static func region_color(secao: int) -> Color:
	match secao:
		Section.ATTACK:
			return Color(0.85, 0.32, 0.28, 1)
		Section.DEFENSE:
			return Color(0.28, 0.65, 0.38, 1)
		Section.UTILITY:
			return Color(0.35, 0.52, 0.88, 1)
	return Color(0.6, 0.6, 0.6, 1)


static func _create_node_def(secao: int, slot: int, linha: int) -> Dictionary:
	match secao:
		Section.ATTACK:
			return _create_attack_node(slot, linha)
		Section.DEFENSE:
			return _create_defense_node(slot, linha)
		Section.UTILITY:
			return _create_utility_node(slot, linha)
	return _create_attack_node(slot, linha)


static func _create_attack_node(slot: int, linha: int) -> Dictionary:
	var merge := linha % 2 == 1
	if merge and linha in [5, 9, 13]:
		var pct := 2 + _idiv(linha, 5)
		return {
			"tipo": BonusType.ATTACK_PCT,
			"valor_base": pct,
			"sigla": "%",
			"label": "Ataque",
			"eh_pct": true,
			"name": "Ataque +%d%%" % pct,
			"premium": true,
		}
	var tipos: Array = [
		BonusType.ATTACK,
		BonusType.ATTACK_SPEED,
		BonusType.CRIT_CHANCE,
		BonusType.CRIT_DAMAGE,
	]
	var siglas: Array = ["ATK", "VEL", "CRIT", "DCR"]
	var rotulos: Array = ["Ataque", "Vel.", "Crít.", "D.Crít"]
	var pct_flags: Array = [false, true, true, true]
	var idx := 0 if merge else (slot + linha) % tipos.size()
	return _build_stat_def(tipos[idx] as BonusType, str(siglas[idx]), str(rotulos[idx]), bool(pct_flags[idx]), linha, false)


static func _create_defense_node(slot: int, linha: int) -> Dictionary:
	var merge := linha % 2 == 1
	if merge and linha in [5, 9, 13]:
		var valor := 8 + linha
		return {
			"tipo": BonusType.HP,
			"valor_base": valor,
			"sigla": "VID",
			"label": "Vida",
			"eh_pct": false,
			"name": "Vida +%d" % valor,
			"premium": true,
		}
	var tipos: Array = [
		BonusType.HP,
		BonusType.EVASION,
		BonusType.PHYS_RES,
		BonusType.ARCANE_RES,
		BonusType.ELEMENTAL_RES,
	]
	var siglas: Array = ["VID", "EVA", "FIS", "ARC", "ELE"]
	var rotulos: Array = ["Vida", "Evasão", "Res. Fís.", "Res. Arc.", "Res. Elem."]
	var pct_flags: Array = [false, true, true, true, true]
	var idx := 0 if merge else (slot + linha) % tipos.size()
	return _build_stat_def(tipos[idx] as BonusType, str(siglas[idx]), str(rotulos[idx]), bool(pct_flags[idx]), linha, false)


static func _create_utility_node(slot: int, linha: int) -> Dictionary:
	var merge := linha % 2 == 1
	if merge and linha in [7, 11, 13]:
		var indice_arm := [7, 11, 13].find(linha)
		var valor := indice_arm + 1
		return {
			"tipo": BonusType.WAREHOUSE,
			"valor_base": valor,
			"sigla": "ARM",
			"label": "Armazém",
			"eh_pct": false,
			"name": "Armazém %d" % (valor + 1),
			"premium": false,
		}
	if merge and linha in [5, 9, 13]:
		var pct := 2 + _idiv(linha, 4)
		return {
			"tipo": BonusType.BONUS_XP,
			"valor_base": pct,
			"sigla": "XP",
			"label": "XP",
			"eh_pct": true,
			"name": "XP +%d%%" % pct,
			"premium": true,
		}
	var usa_xp := (slot + linha) % 2 == 0
	if usa_xp:
		var valor_xp := 1 + _idiv(linha, 3)
		return {
			"tipo": BonusType.BONUS_XP,
			"valor_base": valor_xp,
			"sigla": "XP",
			"label": "XP",
			"eh_pct": true,
			"name": "XP +%d%%" % valor_xp,
			"premium": false,
		}
	var valor_ouro := 1 + _idiv(linha, 3)
	return {
		"tipo": BonusType.GOLD_BONUS,
		"valor_base": valor_ouro,
		"sigla": "OURO",
		"label": "Ouro",
		"eh_pct": true,
		"name": "Ouro +%d%%" % valor_ouro,
		"premium": false,
	}


static func _build_stat_def(
	tipo: BonusType,
	sigla: String,
	rotulo: String,
	eh_pct: bool,
	linha: int,
	premium: bool
) -> Dictionary:
	var valor := _value_for_type(tipo, linha)
	var nome := "%s +%d%%" % [rotulo, valor] if eh_pct else "%s +%d" % [rotulo, valor]
	return {
		"tipo": tipo,
		"valor_base": valor,
		"sigla": sigla,
		"label": rotulo,
		"eh_pct": eh_pct,
		"name": nome,
		"premium": premium,
	}


static func _value_for_type(tipo: BonusType, linha: int) -> int:
	match tipo:
		BonusType.ATTACK:
			return 2 + _idiv(linha, 3)
		BonusType.HP:
			return 4 + _idiv(linha, 2)
		BonusType.ATTACK_SPEED, BonusType.CRIT_CHANCE, BonusType.EVASION:
			return 1 + _idiv(linha, 4)
		BonusType.CRIT_DAMAGE:
			return 3 + _idiv(linha, 3)
		BonusType.PHYS_RES, BonusType.ARCANE_RES, BonusType.ELEMENTAL_RES:
			return 1 + _idiv(linha, 4)
		BonusType.BONUS_XP, BonusType.GOLD_BONUS:
			return 1 + _idiv(linha, 3)
	return 1
