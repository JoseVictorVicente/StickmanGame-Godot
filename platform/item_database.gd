extends Node
## Catálogo de ItemData e geração de drops aleatórios.

var itens: Array[ItemData] = []


func _ready() -> void:
	_populate_catalog()


func generate_random_item(nivel_inimigo: int) -> ItemData:
	if randf() < 0.22:
		return generate_random_gem(nivel_inimigo)
	return generate_random_equipment(nivel_inimigo)


func generate_random_equipment(nivel_inimigo: int) -> ItemData:
	if itens.is_empty():
		_populate_catalog()
	var modelo: ItemData = itens[randi() % itens.size()]
	var item: ItemData = modelo.duplicate() as ItemData
	item.rarity = _roll_rarity(nivel_inimigo)
	item.item_level = ItemData.roll_item_level(nivel_inimigo)
	var variacao := randf_range(0.9, 1.1)
	var bonus_raridade := ItemData.multiplicador_stats(item.rarity)
	var bonus_nivel := ItemData.item_level_multiplier(item.item_level)
	item.damage_bonus = maxi(1, int(round(float(modelo.damage_bonus) * variacao * bonus_raridade * bonus_nivel)))
	item.hp_bonus = maxi(0, int(round(float(modelo.hp_bonus) * variacao * bonus_raridade * bonus_nivel)))
	item.id = "%s_%d" % [modelo.id, Time.get_ticks_msec()]
	item.icone = item.generate_icon()
	return item


func generate_random_gem(nivel_inimigo: int) -> ItemData:
	var atributos: Array[ItemData.GemAttribute] = [
		ItemData.GemAttribute.ATTACK,
		ItemData.GemAttribute.ATTACK_PCT,
		ItemData.GemAttribute.HP,
		ItemData.GemAttribute.HP_PCT,
		ItemData.GemAttribute.ATTACK_SPEED,
		ItemData.GemAttribute.CRIT_CHANCE,
		ItemData.GemAttribute.CRIT_DAMAGE,
		ItemData.GemAttribute.EVASION,
		ItemData.GemAttribute.PHYS_RES,
		ItemData.GemAttribute.ARCANE_RES,
		ItemData.GemAttribute.ELEMENTAL_RES,
	]
	var atributo := atributos[randi() % atributos.size()]
	var raridade := _roll_rarity(nivel_inimigo)
	var item := ItemData.create_gem(atributo, raridade)
	item.id = "%s_%d" % [item.id, Time.get_ticks_msec()]
	item.gem_value *= randf_range(0.9, 1.1)
	item.icone = item.generate_icon()
	return item


func get_by_id(id_item: String) -> ItemData:
	for item in itens:
		if item.id == id_item:
			return item
	return null


func _roll_rarity(nivel_inimigo: int) -> ItemData.Rarity:
	var nivel := maxi(1, nivel_inimigo)
	var tier_max := clampi(int(floor(float(nivel) / 5.0)), int(ItemData.Rarity.COMMON), int(ItemData.Rarity.TRANSCENDENTAL))
	var pesos: Array[float] = []
	pesos.resize(tier_max + 1)
	for tier in tier_max + 1:
		var distancia := tier_max - tier
		pesos[tier] = pow(0.58, float(distancia)) * (1.0 + float(tier) * 0.06)
	var total := 0.0
	for peso in pesos:
		total += peso
	var rolagem := randf() * total
	var acumulado := 0.0
	for tier in tier_max + 1:
		acumulado += pesos[tier]
		if rolagem <= acumulado:
			return tier as ItemData.Rarity
	return tier_max as ItemData.Rarity


func _populate_catalog() -> void:
	itens.clear()
	var G := ItemData.RequiredClass.WARRIOR
	var M := ItemData.RequiredClass.MAGE
	var A := ItemData.RequiredClass.ARCHER
	var S := ItemData.RequiredClass.ASSASSIN
	var T := ItemData.RequiredClass.TANK
	var C := ItemData.RequiredClass.PRIEST
	# Guerreiro
	itens.append(_create("espada_ferro", "Espada de Ferro", ItemData.Type.WEAPON, 8, 0, G))
	itens.append(_create("espada_treino", "Espada de Treino", ItemData.Type.WEAPON, 9, 0, G))
	itens.append(_create("escudo_madeira", "Escudo de Madeira", ItemData.Type.OFFHAND, 2, 8, G))
	itens.append(_create("elmo_guerreiro", "Elmo do Guerreiro", ItemData.Type.HELMET, 3, 6, G))
	itens.append(_create("peitoral_guerreiro", "Peitoral do Guerreiro", ItemData.Type.CHEST, 2, 10, G))
	itens.append(_create("luvas_guerreiro", "Luvas do Guerreiro", ItemData.Type.GLOVES, 2, 4, G))
	itens.append(_create("calca_guerreiro", "Calça do Guerreiro", ItemData.Type.PANTS, 2, 6, G))
	itens.append(_create("botas_guerreiro", "Botas do Guerreiro", ItemData.Type.BOOTS, 1, 5, G))
	itens.append(_create("mascote_leao", "Mascote Leão", ItemData.Type.PET, 3, 4, G))
	itens.append(_create("anel_honra", "Anel de Honra", ItemData.Type.RING, 2, 2, G))
	itens.append(_create("bracelete_guerreiro", "Bracelete do Guerreiro", ItemData.Type.BRACELET, 2, 3, G))
	# Mago
	itens.append(_create("cajado_arcano", "Cajado Arcano", ItemData.Type.WEAPON, 7, 0, M))
	itens.append(_create("grimorio", "Grimório", ItemData.Type.OFFHAND, 4, 0, M))
	itens.append(_create("familiar", "Familiar Arcano", ItemData.Type.PET, 3, 0, M))
	itens.append(_create("manto_mistico", "Manto Místico", ItemData.Type.CHEST, 2, 8, M))
	itens.append(_create("tiara_arcano", "Tiara Arcana", ItemData.Type.HELMET, 2, 4, M))
	itens.append(_create("luvas_mago", "Luvas do Mago", ItemData.Type.GLOVES, 3, 2, M))
	itens.append(_create("calca_mago", "Calça do Mago", ItemData.Type.PANTS, 2, 5, M))
	itens.append(_create("botas_mago", "Botas do Mago", ItemData.Type.BOOTS, 1, 4, M))
	itens.append(_create("cinto_arcano", "Cinto Arcano", ItemData.Type.BELT, 2, 3, M))
	itens.append(_create("pingente_mana", "Pingente de Mana", ItemData.Type.PENDANT, 2, 4, M))
	# Arqueiro
	itens.append(_create("arco_curto", "Arco Curto", ItemData.Type.WEAPON, 7, 0, A))
	itens.append(_create("aljava", "Aljava", ItemData.Type.OFFHAND, 3, 0, A))
	itens.append(_create("capuz_couro", "Capuz de Couro", ItemData.Type.HELMET, 2, 4, A))
	itens.append(_create("peitoral_arqueiro", "Peitoral do Arqueiro", ItemData.Type.CHEST, 2, 6, A))
	itens.append(_create("luvas_arqueiro", "Luvas do Arqueiro", ItemData.Type.GLOVES, 2, 3, A))
	itens.append(_create("calca_arqueiro", "Calça do Arqueiro", ItemData.Type.PANTS, 2, 5, A))
	itens.append(_create("botas_arqueiro", "Botas do Arqueiro", ItemData.Type.BOOTS, 1, 4, A))
	itens.append(_create("falcao_companheiro", "Falcão Companheiro", ItemData.Type.PET, 3, 2, A))
	itens.append(_create("anel_precisao", "Anel de Precisão", ItemData.Type.RING, 3, 0, A))
	# Assassino
	itens.append(_create("adaga_sombria", "Adaga Sombria", ItemData.Type.WEAPON, 6, 0, S))
	itens.append(_create("adaga_secundaria", "Adaga Gêmea", ItemData.Type.OFFHAND, 5, 0, S))
	itens.append(_create("capuz_assassino", "Capuz do Assassino", ItemData.Type.HELMET, 3, 2, S))
	itens.append(_create("peitoral_sombrio", "Peitoral Sombrio", ItemData.Type.CHEST, 2, 5, S))
	itens.append(_create("luvas_assassino", "Luvas do Assassino", ItemData.Type.GLOVES, 3, 2, S))
	itens.append(_create("calca_assassino", "Calça do Assassino", ItemData.Type.PANTS, 2, 4, S))
	itens.append(_create("botas_assassino", "Botas do Assassino", ItemData.Type.BOOTS, 1, 3, S))
	itens.append(_create("cinto_sombrio", "Cinto Sombrio", ItemData.Type.BELT, 2, 2, S))
	itens.append(_create("bracelete_sombrio", "Bracelete Sombrio", ItemData.Type.BRACELET, 3, 1, S))
	# Tanque
	itens.append(_create("maca_pesada", "Maça Pesada", ItemData.Type.WEAPON, 8, 4, T))
	itens.append(_create("escudo_torre", "Escudo Torre", ItemData.Type.OFFHAND, 1, 14, T))
	itens.append(_create("peitoral_ferro", "Peitoral de Ferro", ItemData.Type.CHEST, 2, 16, T))
	itens.append(_create("elmo_torre", "Elmo Torre", ItemData.Type.HELMET, 2, 10, T))
	itens.append(_create("luvas_tanque", "Luvas do Tanque", ItemData.Type.GLOVES, 2, 6, T))
	itens.append(_create("calca_tanque", "Calça do Tanque", ItemData.Type.PANTS, 2, 12, T))
	itens.append(_create("botas_tanque", "Botas do Tanque", ItemData.Type.BOOTS, 1, 8, T))
	itens.append(_create("mascote_tartaruga", "Mascote Tartaruga", ItemData.Type.PET, 1, 8, T))
	itens.append(_create("pingente_guardiao", "Pingente do Guardião", ItemData.Type.PENDANT, 1, 6, T))
	# Sacerdote
	itens.append(_create("cajado_sagrado", "Cajado Sagrado", ItemData.Type.WEAPON, 5, 6, C))
	itens.append(_create("tomo_luz", "Tomo de Luz", ItemData.Type.OFFHAND, 2, 8, C))
	itens.append(_create("manto_clerical", "Manto Clerical", ItemData.Type.CHEST, 1, 12, C))
	itens.append(_create("pingente_fe", "Pingente de Fé", ItemData.Type.PENDANT, 1, 5, C))
	itens.append(_create("tiara_sagrada", "Tiara Sagrada", ItemData.Type.HELMET, 2, 6, C))
	itens.append(_create("luvas_sacerdote", "Luvas do Sacerdote", ItemData.Type.GLOVES, 1, 5, C))
	itens.append(_create("calca_sacerdote", "Calça do Sacerdote", ItemData.Type.PANTS, 1, 8, C))
	itens.append(_create("botas_sacerdote", "Botas do Sacerdote", ItemData.Type.BOOTS, 1, 6, C))
	itens.append(_create("anel_devocao", "Anel de Devotos", ItemData.Type.RING, 2, 4, C))
	# Comuns (qualquer classe)
	itens.append(_create("luvas_tecido", "Luvas de Tecido", ItemData.Type.GLOVES, 2, 2))
	itens.append(_create("calca_couro", "Calça de Couro", ItemData.Type.PANTS, 2, 5))
	itens.append(_create("botas_viagem", "Botas de Viagem", ItemData.Type.BOOTS, 1, 3))
	itens.append(_create("cinto_simples", "Cinto Simples", ItemData.Type.BELT, 1, 2))
	itens.append(_create("anel_bruto", "Anel Bruto", ItemData.Type.RING, 2, 0))
	itens.append(_create("bracelete_ferro", "Bracelete de Ferro", ItemData.Type.BRACELET, 2, 1))
	itens.append(_create("capuz_viagem", "Capuz de Viagem", ItemData.Type.HELMET, 1, 3))
	itens.append(_create("peitoral_couro", "Peitoral de Couro", ItemData.Type.CHEST, 2, 4))
	itens.append(_create("pingente_simples", "Pingente Simples", ItemData.Type.PENDANT, 1, 2))
	itens.append(_create("mascote_rato", "Mascote Rato", ItemData.Type.PET, 1, 2))
	for item in itens:
		item.icone = item.generate_icon()


func _create(
	p_id: String,
	p_nome: String,
	p_tipo: ItemData.Type,
	p_dano: int,
	p_hp: int,
	p_classe: ItemData.RequiredClass = ItemData.RequiredClass.ALL
) -> ItemData:
	var item := ItemData.new()
	item.id = p_id
	item.display_name = p_nome
	item.name_key = "ITEM_%s" % p_id
	item.item_type = p_tipo
	item.damage_bonus = p_dano
	item.hp_bonus = p_hp
	item.required_class = p_classe
	item.rarity = ItemData.Rarity.COMMON
	item.item_level = ItemData.ITEM_LEVELS[0]
	return item
