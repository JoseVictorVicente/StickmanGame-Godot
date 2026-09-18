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
	item.raridade = _roll_rarity(nivel_inimigo)
	item.nivel_item = ItemData.sortear_nivel_item(nivel_inimigo)
	var variacao := randf_range(0.9, 1.1)
	var bonus_raridade := ItemData.multiplicador_stats(item.raridade)
	var bonus_nivel := ItemData.multiplicador_nivel_item(item.nivel_item)
	item.dano_bonus = maxi(1, int(round(float(modelo.dano_bonus) * variacao * bonus_raridade * bonus_nivel)))
	item.vida_bonus = maxi(0, int(round(float(modelo.vida_bonus) * variacao * bonus_raridade * bonus_nivel)))
	item.id = "%s_%d" % [modelo.id, Time.get_ticks_msec()]
	item.icone = item.generate_icon()
	return item


func generate_random_gem(nivel_inimigo: int) -> ItemData:
	var atributos: Array[ItemData.AtributoGema] = [
		ItemData.AtributoGema.ATAQUE,
		ItemData.AtributoGema.ATAQUE_PCT,
		ItemData.AtributoGema.VIDA,
		ItemData.AtributoGema.VIDA_PCT,
		ItemData.AtributoGema.VEL_ATAQUE,
		ItemData.AtributoGema.CRIT_CHANCE,
		ItemData.AtributoGema.CRIT_DANO,
		ItemData.AtributoGema.EVASAO,
		ItemData.AtributoGema.RES_FISICA,
		ItemData.AtributoGema.RES_ARCANA,
		ItemData.AtributoGema.RES_ELEMENTAL,
	]
	var atributo := atributos[randi() % atributos.size()]
	var raridade := _roll_rarity(nivel_inimigo)
	var item := ItemData.criar_gema(atributo, raridade)
	item.id = "%s_%d" % [item.id, Time.get_ticks_msec()]
	item.valor_gema *= randf_range(0.9, 1.1)
	item.icone = item.generate_icon()
	return item


func get_by_id(id_item: String) -> ItemData:
	for item in itens:
		if item.id == id_item:
			return item
	return null


func _roll_rarity(nivel_inimigo: int) -> ItemData.Raridade:
	var nivel := maxi(1, nivel_inimigo)
	var tier_max := clampi(int(floor(float(nivel) / 5.0)), int(ItemData.Raridade.COMUM), int(ItemData.Raridade.TRANSCENDENTAL))
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
			return tier as ItemData.Raridade
	return tier_max as ItemData.Raridade


func _populate_catalog() -> void:
	itens.clear()
	var G := ItemData.RequiredClass.WARRIOR
	var M := ItemData.RequiredClass.MAGE
	var A := ItemData.RequiredClass.ARCHER
	var S := ItemData.RequiredClass.ASSASSIN
	var T := ItemData.RequiredClass.TANK
	var C := ItemData.RequiredClass.PRIEST
	# Guerreiro
	itens.append(_create("espada_ferro", "Espada de Ferro", ItemData.Tipo.ARMA, 8, 0, G))
	itens.append(_create("espada_treino", "Espada de Treino", ItemData.Tipo.ARMA, 9, 0, G))
	itens.append(_create("escudo_madeira", "Escudo de Madeira", ItemData.Tipo.SECUNDARIA, 2, 8, G))
	itens.append(_create("elmo_guerreiro", "Elmo do Guerreiro", ItemData.Tipo.CAPACETE, 3, 6, G))
	itens.append(_create("peitoral_guerreiro", "Peitoral do Guerreiro", ItemData.Tipo.PEITORAL, 2, 10, G))
	itens.append(_create("luvas_guerreiro", "Luvas do Guerreiro", ItemData.Tipo.LUVA, 2, 4, G))
	itens.append(_create("calca_guerreiro", "Calça do Guerreiro", ItemData.Tipo.CALCA, 2, 6, G))
	itens.append(_create("botas_guerreiro", "Botas do Guerreiro", ItemData.Tipo.BOTA, 1, 5, G))
	itens.append(_create("mascote_leao", "Mascote Leão", ItemData.Tipo.PET, 3, 4, G))
	itens.append(_create("anel_honra", "Anel de Honra", ItemData.Tipo.ANEL, 2, 2, G))
	itens.append(_create("bracelete_guerreiro", "Bracelete do Guerreiro", ItemData.Tipo.BRACELETE, 2, 3, G))
	# Mago
	itens.append(_create("cajado_arcano", "Cajado Arcano", ItemData.Tipo.ARMA, 7, 0, M))
	itens.append(_create("grimorio", "Grimório", ItemData.Tipo.SECUNDARIA, 4, 0, M))
	itens.append(_create("familiar", "Familiar Arcano", ItemData.Tipo.PET, 3, 0, M))
	itens.append(_create("manto_mistico", "Manto Místico", ItemData.Tipo.PEITORAL, 2, 8, M))
	itens.append(_create("tiara_arcano", "Tiara Arcana", ItemData.Tipo.CAPACETE, 2, 4, M))
	itens.append(_create("luvas_mago", "Luvas do Mago", ItemData.Tipo.LUVA, 3, 2, M))
	itens.append(_create("calca_mago", "Calça do Mago", ItemData.Tipo.CALCA, 2, 5, M))
	itens.append(_create("botas_mago", "Botas do Mago", ItemData.Tipo.BOTA, 1, 4, M))
	itens.append(_create("cinto_arcano", "Cinto Arcano", ItemData.Tipo.CINTO, 2, 3, M))
	itens.append(_create("pingente_mana", "Pingente de Mana", ItemData.Tipo.PINGENTE, 2, 4, M))
	# Arqueiro
	itens.append(_create("arco_curto", "Arco Curto", ItemData.Tipo.ARMA, 7, 0, A))
	itens.append(_create("aljava", "Aljava", ItemData.Tipo.SECUNDARIA, 3, 0, A))
	itens.append(_create("capuz_couro", "Capuz de Couro", ItemData.Tipo.CAPACETE, 2, 4, A))
	itens.append(_create("peitoral_arqueiro", "Peitoral do Arqueiro", ItemData.Tipo.PEITORAL, 2, 6, A))
	itens.append(_create("luvas_arqueiro", "Luvas do Arqueiro", ItemData.Tipo.LUVA, 2, 3, A))
	itens.append(_create("calca_arqueiro", "Calça do Arqueiro", ItemData.Tipo.CALCA, 2, 5, A))
	itens.append(_create("botas_arqueiro", "Botas do Arqueiro", ItemData.Tipo.BOTA, 1, 4, A))
	itens.append(_create("falcao_companheiro", "Falcão Companheiro", ItemData.Tipo.PET, 3, 2, A))
	itens.append(_create("anel_precisao", "Anel de Precisão", ItemData.Tipo.ANEL, 3, 0, A))
	# Assassino
	itens.append(_create("adaga_sombria", "Adaga Sombria", ItemData.Tipo.ARMA, 6, 0, S))
	itens.append(_create("adaga_secundaria", "Adaga Gêmea", ItemData.Tipo.SECUNDARIA, 5, 0, S))
	itens.append(_create("capuz_assassino", "Capuz do Assassino", ItemData.Tipo.CAPACETE, 3, 2, S))
	itens.append(_create("peitoral_sombrio", "Peitoral Sombrio", ItemData.Tipo.PEITORAL, 2, 5, S))
	itens.append(_create("luvas_assassino", "Luvas do Assassino", ItemData.Tipo.LUVA, 3, 2, S))
	itens.append(_create("calca_assassino", "Calça do Assassino", ItemData.Tipo.CALCA, 2, 4, S))
	itens.append(_create("botas_assassino", "Botas do Assassino", ItemData.Tipo.BOTA, 1, 3, S))
	itens.append(_create("cinto_sombrio", "Cinto Sombrio", ItemData.Tipo.CINTO, 2, 2, S))
	itens.append(_create("bracelete_sombrio", "Bracelete Sombrio", ItemData.Tipo.BRACELETE, 3, 1, S))
	# Tanque
	itens.append(_create("maca_pesada", "Maça Pesada", ItemData.Tipo.ARMA, 8, 4, T))
	itens.append(_create("escudo_torre", "Escudo Torre", ItemData.Tipo.SECUNDARIA, 1, 14, T))
	itens.append(_create("peitoral_ferro", "Peitoral de Ferro", ItemData.Tipo.PEITORAL, 2, 16, T))
	itens.append(_create("elmo_torre", "Elmo Torre", ItemData.Tipo.CAPACETE, 2, 10, T))
	itens.append(_create("luvas_tanque", "Luvas do Tanque", ItemData.Tipo.LUVA, 2, 6, T))
	itens.append(_create("calca_tanque", "Calça do Tanque", ItemData.Tipo.CALCA, 2, 12, T))
	itens.append(_create("botas_tanque", "Botas do Tanque", ItemData.Tipo.BOTA, 1, 8, T))
	itens.append(_create("mascote_tartaruga", "Mascote Tartaruga", ItemData.Tipo.PET, 1, 8, T))
	itens.append(_create("pingente_guardiao", "Pingente do Guardião", ItemData.Tipo.PINGENTE, 1, 6, T))
	# Sacerdote
	itens.append(_create("cajado_sagrado", "Cajado Sagrado", ItemData.Tipo.ARMA, 5, 6, C))
	itens.append(_create("tomo_luz", "Tomo de Luz", ItemData.Tipo.SECUNDARIA, 2, 8, C))
	itens.append(_create("manto_clerical", "Manto Clerical", ItemData.Tipo.PEITORAL, 1, 12, C))
	itens.append(_create("pingente_fe", "Pingente de Fé", ItemData.Tipo.PINGENTE, 1, 5, C))
	itens.append(_create("tiara_sagrada", "Tiara Sagrada", ItemData.Tipo.CAPACETE, 2, 6, C))
	itens.append(_create("luvas_sacerdote", "Luvas do Sacerdote", ItemData.Tipo.LUVA, 1, 5, C))
	itens.append(_create("calca_sacerdote", "Calça do Sacerdote", ItemData.Tipo.CALCA, 1, 8, C))
	itens.append(_create("botas_sacerdote", "Botas do Sacerdote", ItemData.Tipo.BOTA, 1, 6, C))
	itens.append(_create("anel_devocao", "Anel de Devotos", ItemData.Tipo.ANEL, 2, 4, C))
	# Comuns (qualquer classe)
	itens.append(_create("luvas_tecido", "Luvas de Tecido", ItemData.Tipo.LUVA, 2, 2))
	itens.append(_create("calca_couro", "Calça de Couro", ItemData.Tipo.CALCA, 2, 5))
	itens.append(_create("botas_viagem", "Botas de Viagem", ItemData.Tipo.BOTA, 1, 3))
	itens.append(_create("cinto_simples", "Cinto Simples", ItemData.Tipo.CINTO, 1, 2))
	itens.append(_create("anel_bruto", "Anel Bruto", ItemData.Tipo.ANEL, 2, 0))
	itens.append(_create("bracelete_ferro", "Bracelete de Ferro", ItemData.Tipo.BRACELETE, 2, 1))
	itens.append(_create("capuz_viagem", "Capuz de Viagem", ItemData.Tipo.CAPACETE, 1, 3))
	itens.append(_create("peitoral_couro", "Peitoral de Couro", ItemData.Tipo.PEITORAL, 2, 4))
	itens.append(_create("pingente_simples", "Pingente Simples", ItemData.Tipo.PINGENTE, 1, 2))
	itens.append(_create("mascote_rato", "Mascote Rato", ItemData.Tipo.PET, 1, 2))
	for item in itens:
		item.icone = item.generate_icon()


func _create(
	p_id: String,
	p_nome: String,
	p_tipo: ItemData.Tipo,
	p_dano: int,
	p_vida: int,
	p_classe: ItemData.RequiredClass = ItemData.RequiredClass.ALL
) -> ItemData:
	var item := ItemData.new()
	item.id = p_id
	item.nome = p_nome
	item.tipo = p_tipo
	item.dano_bonus = p_dano
	item.vida_bonus = p_vida
	item.required_class = p_classe
	item.raridade = ItemData.Raridade.COMUM
	item.nivel_item = ItemData.NIVEIS_ITEM[0]
	return item
