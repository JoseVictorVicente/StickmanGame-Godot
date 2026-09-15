extends Node
## Catálogo de ItemData e geração de drops aleatórios.

var itens: Array[ItemData] = []


func _ready() -> void:
	_popular_catalogo()


func gerar_item_aleatorio(nivel_inimigo: int) -> ItemData:
	if itens.is_empty():
		_popular_catalogo()
	var modelo: ItemData = itens[randi() % itens.size()]
	var item: ItemData = modelo.duplicate() as ItemData
	item.raridade = _sortear_raridade(nivel_inimigo)
	var variacao := randf_range(0.9, 1.1)
	var bonus_raridade := 1.0 + float(item.raridade) * 0.22
	item.dano_bonus = maxi(1, int(round(float(modelo.dano_bonus) * variacao * bonus_raridade)))
	item.vida_bonus = maxi(0, int(round(float(modelo.vida_bonus) * variacao * bonus_raridade)))
	item.id = "%s_%d" % [modelo.id, Time.get_ticks_msec()]
	item.icone = item.gerar_icone()
	return item


func obter_por_id(id_item: String) -> ItemData:
	for item in itens:
		if item.id == id_item:
			return item
	return null


func _sortear_raridade(nivel_inimigo: int) -> ItemData.Raridade:
	var nivel := maxi(1, nivel_inimigo)
	var lendario := clampf(0.01 + float(nivel) * 0.004, 0.01, 0.08)
	var epico := clampf(0.05 + float(nivel) * 0.01, 0.05, 0.22)
	var raro := clampf(0.18 + float(nivel) * 0.02, 0.18, 0.45)
	var rolagem := randf()
	if rolagem < lendario:
		return ItemData.Raridade.LENDARIO
	if rolagem < lendario + epico:
		return ItemData.Raridade.EPICO
	if rolagem < lendario + epico + raro:
		return ItemData.Raridade.RARO
	return ItemData.Raridade.COMUM


func _popular_catalogo() -> void:
	itens.clear()
	var G := ItemData.ClasseRequerida.GUERREIRO
	var M := ItemData.ClasseRequerida.MAGO
	var A := ItemData.ClasseRequerida.ARQUEIRO
	var S := ItemData.ClasseRequerida.ASSASSINO
	var T := ItemData.ClasseRequerida.TANQUE
	var C := ItemData.ClasseRequerida.SACERDOTE
	# Guerreiro
	itens.append(_criar("espada_ferro", "Espada de Ferro", ItemData.Tipo.ARMA, 8, 0, G))
	itens.append(_criar("espada_treino", "Espada de Treino", ItemData.Tipo.ARMA, 9, 0, G))
	itens.append(_criar("escudo_madeira", "Escudo de Madeira", ItemData.Tipo.SECUNDARIA, 2, 8, G))
	# Mago
	itens.append(_criar("cajado_arcano", "Cajado Arcano", ItemData.Tipo.ARMA, 7, 0, M))
	itens.append(_criar("grimorio", "Grimório", ItemData.Tipo.SECUNDARIA, 4, 0, M))
	itens.append(_criar("familiar", "Familiar Arcano", ItemData.Tipo.PET, 3, 0, M))
	itens.append(_criar("manto_mistico", "Manto Místico", ItemData.Tipo.PEITORAL, 2, 8, M))
	# Arqueiro
	itens.append(_criar("arco_curto", "Arco Curto", ItemData.Tipo.ARMA, 7, 0, A))
	itens.append(_criar("aljava", "Aljava", ItemData.Tipo.SECUNDARIA, 3, 0, A))
	itens.append(_criar("capuz_couro", "Capuz de Couro", ItemData.Tipo.CAPACETE, 2, 4, A))
	# Assassino
	itens.append(_criar("adaga_sombria", "Adaga Sombria", ItemData.Tipo.ARMA, 6, 0, S))
	itens.append(_criar("adaga_secundaria", "Adaga Gêmea", ItemData.Tipo.SECUNDARIA, 5, 0, S))
	itens.append(_criar("capuz_assassino", "Capuz do Assassino", ItemData.Tipo.CAPACETE, 3, 2, S))
	# Tanque
	itens.append(_criar("maca_pesada", "Maça Pesada", ItemData.Tipo.ARMA, 8, 4, T))
	itens.append(_criar("escudo_torre", "Escudo Torre", ItemData.Tipo.SECUNDARIA, 1, 14, T))
	itens.append(_criar("peitoral_ferro", "Peitoral de Ferro", ItemData.Tipo.PEITORAL, 2, 16, T))
	# Sacerdote
	itens.append(_criar("cajado_sagrado", "Cajado Sagrado", ItemData.Tipo.ARMA, 5, 6, C))
	itens.append(_criar("tomo_luz", "Tomo de Luz", ItemData.Tipo.SECUNDARIA, 2, 8, C))
	itens.append(_criar("manto_clerical", "Manto Clerical", ItemData.Tipo.PEITORAL, 1, 12, C))
	itens.append(_criar("pingente_fe", "Pingente de Fé", ItemData.Tipo.PINGENTE, 1, 5, C))
	# Comuns (qualquer classe)
	itens.append(_criar("luvas_tecido", "Luvas de Tecido", ItemData.Tipo.LUVA, 2, 2))
	itens.append(_criar("calca_couro", "Calça de Couro", ItemData.Tipo.CALCA, 2, 5))
	itens.append(_criar("botas_viagem", "Botas de Viagem", ItemData.Tipo.BOTA, 1, 3))
	itens.append(_criar("cinto_simples", "Cinto Simples", ItemData.Tipo.CINTO, 1, 2))
	itens.append(_criar("anel_bruto", "Anel Bruto", ItemData.Tipo.ANEL, 2, 0))
	itens.append(_criar("bracelete_ferro", "Bracelete de Ferro", ItemData.Tipo.BRACELETE, 2, 1))
	for item in itens:
		item.icone = item.gerar_icone()


func _criar(
	p_id: String,
	p_nome: String,
	p_tipo: ItemData.Tipo,
	p_dano: int,
	p_vida: int,
	p_classe: ItemData.ClasseRequerida = ItemData.ClasseRequerida.TODAS
) -> ItemData:
	var item := ItemData.new()
	item.id = p_id
	item.nome = p_nome
	item.tipo = p_tipo
	item.dano_bonus = p_dano
	item.vida_bonus = p_vida
	item.classe_requerida = p_classe
	item.raridade = ItemData.Raridade.COMUM
	return item
