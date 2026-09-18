class_name ItemData
extends Resource
## Resource de item (equipamento) usado pelo inventário e pelo banco de dados.

enum Tipo {
	CAPACETE,
	PEITORAL,
	ARMA,
	SECUNDARIA,
	LUVA,
	CALCA,
	BOTA,
	CINTO,
	PINGENTE,
	ANEL,
	BRACELETE,
	PET,
	GEMA,
}

enum AtributoGema {
	ATAQUE,
	ATAQUE_PCT,
	VIDA,
	VIDA_PCT,
	VEL_ATAQUE,
	CRIT_CHANCE,
	CRIT_DANO,
	EVASAO,
	RES_FISICA,
	RES_ARCANA,
	RES_ELEMENTAL,
}

enum Raridade {
	COMUM,
	INCOMUM,
	RARO,
	EPICO,
	LENDARIO,
	MITICO,
	PRIMORDIAL,
	ASTRAL,
	DIVINO,
	TRANSCENDENTAL,
}

enum RequiredClass {
	ALL,
	WARRIOR,
	MAGE,
	ARCHER,
	ASSASSIN,
	TANK,
	PRIEST,
}

enum Categoria {
	EQUIPAMENTO,
	ACESSORIO,
	GEMA,
}

const NIVEIS_ITEM: Array[int] = [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 70, 80]

@export var id: String = ""
@export var nome: String = ""
@export var icone: Texture2D
@export var tipo: Tipo = Tipo.ARMA
@export var raridade: Raridade = Raridade.COMUM
@export var nivel_item: int = 5
@export var dano_bonus: int = 0
@export var vida_bonus: int = 0
@export var required_class: RequiredClass = RequiredClass.ALL
@export var atributo_gema: AtributoGema = AtributoGema.ATAQUE
@export var valor_gema: float = 0.0
var gema_imbuida: Dictionary = {}


func description() -> String:
	return tooltip_text()


func tooltip_text() -> String:
	var linhas: PackedStringArray = [nome, rarity_name()]
	if is_gem():
		linhas.append("%s: +%s" % [nome_atributo_gema(atributo_gema), gem_value_text()])
		linhas.append("Valor: %d ouro" % dismantle_value())
		return "\n".join(linhas)
	linhas.append("Dano Bônus: +%d" % dano_bonus)
	if vida_bonus != 0:
		linhas.append("Vida Bônus: +%d" % vida_bonus)
	if has_embedded_gem():
		var linha_gema := gem_slot_line()
		if linha_gema != "":
			linhas.append(linha_gema)
	elif has_gem_slot():
		linhas.append(gem_slot_line())
	if required_class != RequiredClass.ALL:
		linhas.append("Classe: %s" % required_class_name())
	linhas.append("Nível: %d" % nivel_item)
	linhas.append("Valor: %d ouro" % dismantle_value())
	return "\n".join(linhas)


func type_name() -> String:
	match tipo:
		Tipo.CAPACETE:
			return "Capacete"
		Tipo.PEITORAL:
			return "Peitoral"
		Tipo.ARMA:
			return "Arma"
		Tipo.SECUNDARIA:
			return "Secundaria"
		Tipo.LUVA:
			return "Luva"
		Tipo.CALCA:
			return "Calca"
		Tipo.BOTA:
			return "Bota"
		Tipo.CINTO:
			return "Cinto"
		Tipo.PINGENTE:
			return "Pingente"
		Tipo.ANEL:
			return "Anel"
		Tipo.BRACELETE:
			return "Bracelete"
		Tipo.PET:
			return "Pet"
		Tipo.GEMA:
			return "Gema"
		_:
			return "Item"


func is_gem() -> bool:
	return tipo == Tipo.GEMA


func has_gem_slot() -> bool:
	return not is_gem() and int(raridade) >= int(Raridade.LENDARIO)


func has_embedded_gem() -> bool:
	return not gema_imbuida.is_empty()


func gem_slot_line() -> String:
	if is_gem() or not has_gem_slot():
		return ""
	if has_embedded_gem():
		var gema := get_embedded_gem()
		if gema == null:
			return ""
		return "Gema: %s +%s" % [nome_atributo_gema(gema.atributo_gema), gema.gem_value_text()]
	return "Slot de gema: disponível"


func gem_slot_label_color() -> Color:
	if has_embedded_gem():
		return Color(0.95, 0.78, 0.32, 1)
	return Color(0.55, 0.82, 0.95, 1)


func get_embedded_gem() -> ItemData:
	if gema_imbuida.is_empty():
		return null
	return de_dicionario(gema_imbuida)


func imbue_gem(gema: ItemData) -> bool:
	if gema == null or not gema.is_gem() or not has_gem_slot() or has_embedded_gem():
		return false
	gema_imbuida = gema.to_dictionary()
	return true


func embedded_gem_bonus() -> Dictionary:
	var bonus := SkillTreeDefinition.bonus_vazio()
	if not has_embedded_gem():
		return bonus
	var gema := get_embedded_gem()
	if gema:
		gema.apply_bonus_to(bonus)
	return bonus


func apply_bonus_to(destino: Dictionary) -> void:
	if not is_gem():
		return
	match atributo_gema:
		AtributoGema.ATAQUE:
			destino["ataque"] = int(destino.get("ataque", 0)) + int(round(valor_gema))
		AtributoGema.ATAQUE_PCT:
			destino["ataque_pct"] = float(destino.get("ataque_pct", 0.0)) + valor_gema
		AtributoGema.VIDA:
			destino["vida"] = int(destino.get("vida", 0)) + int(round(valor_gema))
		AtributoGema.VIDA_PCT:
			destino["vida_pct"] = float(destino.get("vida_pct", 0.0)) + valor_gema
		AtributoGema.VEL_ATAQUE:
			destino["vel_ataque"] = float(destino.get("vel_ataque", 0.0)) + valor_gema
		AtributoGema.CRIT_CHANCE:
			destino["crit_chance"] = float(destino.get("crit_chance", 0.0)) + valor_gema
		AtributoGema.CRIT_DANO:
			destino["crit_dano"] = float(destino.get("crit_dano", 0.0)) + valor_gema
		AtributoGema.EVASAO:
			destino["evasao"] = float(destino.get("evasao", 0.0)) + valor_gema
		AtributoGema.RES_FISICA:
			destino["res_fisica"] = float(destino.get("res_fisica", 0.0)) + valor_gema
		AtributoGema.RES_ARCANA:
			destino["res_arcana"] = float(destino.get("res_arcana", 0.0)) + valor_gema
		AtributoGema.RES_ELEMENTAL:
			destino["res_elemental"] = float(destino.get("res_elemental", 0.0)) + valor_gema


static func nome_atributo_gema(atributo: AtributoGema) -> String:
	match atributo:
		AtributoGema.ATAQUE:
			return "Ataque"
		AtributoGema.ATAQUE_PCT:
			return "Ataque %"
		AtributoGema.VIDA:
			return "Vida"
		AtributoGema.VIDA_PCT:
			return "Vida %"
		AtributoGema.VEL_ATAQUE:
			return "Vel. Ataque %"
		AtributoGema.CRIT_CHANCE:
			return "Crítico %"
		AtributoGema.CRIT_DANO:
			return "Dano Crítico %"
		AtributoGema.EVASAO:
			return "Evasão %"
		AtributoGema.RES_FISICA:
			return "Res. Física %"
		AtributoGema.RES_ARCANA:
			return "Res. Arcana %"
		AtributoGema.RES_ELEMENTAL:
			return "Res. Elemental %"
		_:
			return "Atributo"


static func valor_base_gema(atributo: AtributoGema) -> float:
	match atributo:
		AtributoGema.ATAQUE:
			return 5.0
		AtributoGema.ATAQUE_PCT:
			return 2.0
		AtributoGema.VIDA:
			return 10.0
		AtributoGema.VIDA_PCT:
			return 2.0
		AtributoGema.VEL_ATAQUE:
			return 1.5
		AtributoGema.CRIT_CHANCE:
			return 1.0
		AtributoGema.CRIT_DANO:
			return 3.0
		AtributoGema.EVASAO:
			return 1.0
		AtributoGema.RES_FISICA, AtributoGema.RES_ARCANA, AtributoGema.RES_ELEMENTAL:
			return 2.0
		_:
			return 1.0


static func calcular_valor_gema(atributo: AtributoGema, raridade_item: Raridade) -> float:
	var base := valor_base_gema(atributo)
	return base * multiplicador_stats(raridade_item)


static func criar_gema(atributo: AtributoGema, raridade_item: Raridade) -> ItemData:
	var item := ItemData.new()
	item.tipo = Tipo.GEMA
	item.atributo_gema = atributo
	item.raridade = raridade_item
	item.nivel_item = NIVEIS_ITEM[0]
	item.valor_gema = calcular_valor_gema(atributo, raridade_item)
	item.nome = "Gema de %s" % nome_atributo_gema(atributo)
	item.id = "gema_%s" % int(atributo)
	item.required_class = RequiredClass.ALL
	item.icone = item.generate_icon()
	return item


func gem_value_text() -> String:
	if atributo_gema in [AtributoGema.ATAQUE, AtributoGema.VIDA]:
		return str(int(round(valor_gema)))
	return "%.1f%%" % valor_gema


func category() -> Categoria:
	return categoria_do_tipo(tipo)


static func categoria_do_tipo(p_tipo: Tipo) -> Categoria:
	if p_tipo == Tipo.GEMA:
		return Categoria.GEMA
	match p_tipo:
		Tipo.CINTO, Tipo.PINGENTE, Tipo.ANEL, Tipo.BRACELETE:
			return Categoria.ACESSORIO
		_:
			return Categoria.EQUIPAMENTO


static func nome_categoria(p_categoria: Categoria) -> String:
	match p_categoria:
		Categoria.ACESSORIO:
			return "Acessório"
		Categoria.GEMA:
			return "Gema"
		_:
			return "Equipamento"


static func tipos_da_categoria(p_categoria: Categoria) -> Array[Tipo]:
	var lista: Array[Tipo] = []
	for tipo_valor in Tipo.values():
		if categoria_do_tipo(tipo_valor as Tipo) == p_categoria:
			lista.append(tipo_valor as Tipo)
	return lista


func rarity_name() -> String:
	return nome_de_raridade(raridade)


static func nome_de_raridade(p_raridade: Raridade) -> String:
	match p_raridade:
		Raridade.INCOMUM:
			return "Incomum"
		Raridade.RARO:
			return "Raro"
		Raridade.EPICO:
			return "Épico"
		Raridade.LENDARIO:
			return "Lendário"
		Raridade.MITICO:
			return "Mítico"
		Raridade.PRIMORDIAL:
			return "Primordial"
		Raridade.ASTRAL:
			return "Astral"
		Raridade.DIVINO:
			return "Divino"
		Raridade.TRANSCENDENTAL:
			return "Transcendental"
		_:
			return "Comum"


static func nomes_filtro_ferraria() -> PackedStringArray:
	var nomes := PackedStringArray(["Todos"])
	for i in Raridade.size():
		nomes.append(nome_de_raridade(i as Raridade))
	return nomes


static func raridade_maxima() -> Raridade:
	return Raridade.TRANSCENDENTAL


static func eh_raridade_maxima(p_raridade: Raridade) -> bool:
	return p_raridade >= Raridade.TRANSCENDENTAL


static func proxima_raridade(p_raridade: Raridade) -> Raridade:
	if eh_raridade_maxima(p_raridade):
		return p_raridade
	return (int(p_raridade) + 1) as Raridade


static func chance_forja_sucesso(p_raridade: Raridade) -> float:
	match p_raridade:
		Raridade.COMUM, Raridade.INCOMUM, Raridade.RARO:
			return 1.0
		Raridade.EPICO:
			return 0.9
		Raridade.LENDARIO:
			return 0.5
		Raridade.MITICO:
			return 0.45
		Raridade.PRIMORDIAL:
			return 0.4
		Raridade.ASTRAL:
			return 0.35
		Raridade.DIVINO:
			return 0.3
		Raridade.TRANSCENDENTAL:
			return 0.25
		_:
			return 1.0


static func chance_forja_sucesso_pct(p_raridade: Raridade) -> int:
	return int(round(chance_forja_sucesso(p_raridade) * 100.0))


static func migrar_raridade_salva(valor: int) -> Raridade:
	if valor >= 0 and valor <= 3:
		var legado: Array[Raridade] = [
			Raridade.COMUM,
			Raridade.RARO,
			Raridade.EPICO,
			Raridade.LENDARIO,
		]
		return legado[valor]
	return clampi(valor, 0, int(Raridade.TRANSCENDENTAL)) as Raridade


static func multiplicador_stats(p_raridade: Raridade) -> float:
	return pow(1.22, float(int(p_raridade)))


static func normalizar_nivel_item(valor: int) -> int:
	if NIVEIS_ITEM.has(valor):
		return valor
	var melhor := NIVEIS_ITEM[0]
	var menor_dist := absi(valor - melhor)
	for nivel in NIVEIS_ITEM:
		var dist := absi(valor - nivel)
		if dist < menor_dist:
			menor_dist = dist
			melhor = nivel
	return melhor


static func indice_nivel_item(nivel: int) -> int:
	var normalizado := normalizar_nivel_item(nivel)
	var stage_index := NIVEIS_ITEM.find(normalizado)
	return stage_index if stage_index >= 0 else 0


static func comparar_ordenacao(a: ItemData, b: ItemData) -> bool:
	if a == null and b == null:
		return false
	if a == null:
		return false
	if b == null:
		return true
	if int(a.raridade) != int(b.raridade):
		return int(a.raridade) > int(b.raridade)
	var indice_a := indice_nivel_item(a.nivel_item)
	var indice_b := indice_nivel_item(b.nivel_item)
	if indice_a != indice_b:
		return indice_a > indice_b
	return a.nome.nocasecmp_to(b.nome) < 0


static func multiplicador_nivel_item(nivel: int) -> float:
	return pow(1.088, float(indice_nivel_item(nivel)))


static func nivel_item_maximo(hero_progress: int) -> int:
	var maximo := NIVEIS_ITEM[0]
	for nivel in NIVEIS_ITEM:
		if nivel <= hero_progress + 4:
			maximo = nivel
	return maximo


static func sortear_nivel_item(hero_progress: int) -> int:
	var maximo := nivel_item_maximo(maxi(1, hero_progress))
	var opcoes: Array[int] = []
	for nivel in NIVEIS_ITEM:
		if nivel <= maximo:
			opcoes.append(nivel)
	if opcoes.is_empty():
		return NIVEIS_ITEM[0]
	var pesos: Array[float] = []
	var total := 0.0
	for i in opcoes.size():
		var peso := pow(0.62, float(opcoes.size() - 1 - i))
		pesos.append(peso)
		total += peso
	var rolagem := randf() * total
	var acumulado := 0.0
	for i in opcoes.size():
		acumulado += pesos[i]
		if rolagem <= acumulado:
			return opcoes[i]
	return opcoes[0]


func can_equip(nivel_heroi: int) -> bool:
	return nivel_heroi >= normalizar_nivel_item(nivel_item)


func required_class_name() -> String:
	match required_class:
		RequiredClass.WARRIOR:
			return "warrior"
		RequiredClass.MAGE:
			return "mage"
		RequiredClass.ARCHER:
			return "archer"
		RequiredClass.ASSASSIN:
			return "assassin"
		RequiredClass.TANK:
			return "tank"
		RequiredClass.PRIEST:
			return "priest"
		_:
			return "Todas"


func rarity_color() -> Color:
	return cor_de_raridade(raridade)


static func cor_de_raridade(p_raridade: Raridade) -> Color:
	match p_raridade:
		Raridade.INCOMUM:
			return Color(0.35, 0.85, 0.42, 1)
		Raridade.RARO:
			return Color(0.28, 0.52, 0.98, 1)
		Raridade.EPICO:
			return Color(0.68, 0.28, 0.92, 1)
		Raridade.LENDARIO:
			return Color(0.95, 0.78, 0.22, 1)
		Raridade.MITICO:
			return Color(0.95, 0.52, 0.18, 1)
		Raridade.PRIMORDIAL:
			return Color(0.92, 0.22, 0.22, 1)
		Raridade.ASTRAL:
			return Color(0.28, 0.88, 0.92, 1)
		Raridade.DIVINO:
			return Color(0.92, 0.22, 0.78, 1)
		Raridade.TRANSCENDENTAL:
			return Color(1.0, 0.45, 0.82, 1)
		_:
			return Color(0.92, 0.92, 0.95, 1)


func dismantle_value() -> int:
	var bases: Array[int] = [8, 14, 28, 90, 240, 600, 1500, 3800, 9500, 24000]
	var stage_index := clampi(int(raridade), 0, bases.size() - 1)
	var extra := dano_bonus + vida_bonus
	if is_gem():
		extra = int(round(valor_gema * 2.0))
	return maxi(1, bases[stage_index] + extra)


func type_abbreviation() -> String:
	return sigla_do_tipo(tipo)


static func sigla_do_tipo(p_tipo: Tipo) -> String:
	match p_tipo:
		Tipo.ARMA:
			return "ESP"
		Tipo.SECUNDARIA:
			return "ADG"
		Tipo.CAPACETE:
			return "CAP"
		Tipo.PEITORAL:
			return "PEI"
		Tipo.LUVA:
			return "LUV"
		Tipo.CALCA:
			return "CAL"
		Tipo.BOTA:
			return "BOT"
		Tipo.CINTO:
			return "CIN"
		Tipo.PINGENTE:
			return "PIN"
		Tipo.ANEL:
			return "ANL"
		Tipo.BRACELETE:
			return "BRA"
		Tipo.PET:
			return "PET"
		Tipo.GEMA:
			return "GEM"
		_:
			return "ITM"


func to_dictionary() -> Dictionary:
	var dados := {
		"id": id,
		"nome": nome,
		"tipo": int(tipo),
		"raridade": int(raridade),
		"nivel_item": nivel_item,
		"dano_bonus": dano_bonus,
		"vida_bonus": vida_bonus,
		"classe_requerida": int(required_class),
		"required_class": int(required_class),
		"atributo_gema": int(atributo_gema),
		"valor_gema": valor_gema,
	}
	if not gema_imbuida.is_empty():
		dados["gema_imbuida"] = gema_imbuida.duplicate(true)
	return dados


static func de_dicionario(dados: Dictionary) -> ItemData:
	if dados.is_empty():
		return null
	var item := ItemData.new()
	item.id = str(dados.get("id", ""))
	item.nome = str(dados.get("nome", ""))
	item.tipo = int(dados.get("tipo", Tipo.ARMA)) as Tipo
	item.raridade = migrar_raridade_salva(int(dados.get("raridade", Raridade.COMUM)))
	item.nivel_item = normalizar_nivel_item(int(dados.get("nivel_item", NIVEIS_ITEM[0])))
	item.dano_bonus = int(dados.get("dano_bonus", 0))
	item.vida_bonus = int(dados.get("vida_bonus", 0))
	var raw_class: Variant = dados.get("required_class", dados.get("classe_requerida", RequiredClass.ALL))
	item.required_class = int(raw_class) as RequiredClass
	item.atributo_gema = int(dados.get("atributo_gema", AtributoGema.ATAQUE)) as AtributoGema
	item.valor_gema = float(dados.get("valor_gema", 0.0))
	var gema_salva: Variant = dados.get("gema_imbuida", {})
	item.gema_imbuida = gema_salva.duplicate(true) if gema_salva is Dictionary else {}
	item.icone = item.generate_icon()
	return item


func generate_icon() -> Texture2D:
	if is_gem():
		return _generate_gem_icon()
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(6, 26):
		for x in range(6, 26):
			var cor := _icon_pixel_color(x, y)
			img.set_pixel(x, y, cor)
	return ImageTexture.create_from_image(img)


func _generate_gem_icon() -> Texture2D:
	return InterfaceIcons.gem_icon(raridade)


func _icon_pixel_color(x: int, y: int) -> Color:
	if raridade == Raridade.TRANSCENDENTAL:
		var matiz := fmod(float(x + y) * 0.08 + float(x - y) * 0.05, 1.0)
		return Color.from_hsv(matiz, 0.85, 1.0, 1.0).lerp(_type_color(), 0.25)
	var cor := rarity_color().lerp(_type_color(), 0.4)
	return cor


func _type_color() -> Color:
	match tipo:
		Tipo.ARMA:
			return Color(0.55, 0.58, 0.65)
		Tipo.SECUNDARIA:
			return Color(0.45, 0.38, 0.28)
		Tipo.CAPACETE:
			return Color(0.5, 0.32, 0.18)
		Tipo.PEITORAL:
			return Color(0.35, 0.4, 0.5)
		Tipo.ANEL:
			return Color(0.75, 0.62, 0.2)
		_:
			return Color(0.6, 0.55, 0.45)
