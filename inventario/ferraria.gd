class_name Ferraria
extends PanelContainer
## Painel lateral de forja e desmonte.
## Fica acoplado à direita do inventário e só existe enquanto o menu está aberto.

signal visibilidade_alterada(aberta: bool)
signal ouro_obtido(quantidade: int)

enum Aba { SINTESE, DESMONTAR }

const SLOTS_SINTSE := 9
const SLOT_CENTRAL := 4
const COLUNAS := 3
const TAMANHO_SLOT := Vector2(44, 44)
const TAMANHO_ICONE_INFO := 28
const FILTRO_TODOS := -1
const CAMADA_LEGENDA_INFO := 127
const Z_INDEX_LEGENDA_INFO := 100
const OFFSET_LEGENDA_INFO := Vector2(10, 0)
const TEXTO_RODAPE := "Forje 9 itens da mesma raridade e tipo"
const TEXTO_DESMONTE := "Desmonte itens para receber ouro"

@onready var grade_sintese: GridContainer = %GradeSintese
@onready var grade_desmontar: GridContainer = %GradeDesmontar
@onready var botao_fechar: Button = %BotaoFecharFerraria
@onready var botao_preenchimento: Button = %BotaoPreenchimento
@onready var botao_info_nivel: PanelContainer = %BotaoInfoNivel
@onready var botao_sintetizar: Button = %BotaoSintetizar
@onready var botao_desmontar: Button = %BotaoDesmontar
@onready var botao_aba_sintese: Button = %BotaoAbaSintese
@onready var botao_aba_desmontar: Button = %BotaoAbaDesmontar
@onready var botao_filtro_forja: Button = %BotaoFiltroForja
@onready var botao_armazem_forja: Button = %BotaoArmazemForja
@onready var botao_preenchimento_desmonte: Button = %BotaoPreenchimentoDesmonte
@onready var botao_filtro_desmonte: Button = %BotaoFiltroDesmonte
@onready var botao_armazem_desmonte: Button = %BotaoArmazemDesmonte
@onready var painel_sintese: VBoxContainer = %PainelSintese
@onready var painel_desmontar: VBoxContainer = %PainelDesmontar
@onready var label_explicacao: Label = %LabelExplicacaoFerraria
@onready var label_explicacao_desmontar: Label = %LabelExplicacaoDesmontar
@onready var label_valor_desmonte: Label = %LabelValorDesmonte
@onready var cabecalho: HBoxContainer = %CabecalhoFerraria

var _menu: MenuInventario
var _slots: Array[SlotItem] = []
var _slots_desmontar: Array[SlotItem] = []
var _vinculos: Dictionary = {}
var _aba: Aba = Aba.SINTESE
var _filtro_raridade: int = FILTRO_TODOS
var _usar_armazem: bool = false
var _popup_filtro: PopupMenu
var _camada_legenda_info: CanvasLayer
var _caixa_legenda_info: PanelContainer


func _ready() -> void:
	hide()
	_criar_slots(grade_sintese, _slots, true)
	_criar_slots(grade_desmontar, _slots_desmontar, false)
	_criar_popup_filtro()
	botao_fechar.pressed.connect(fechar)
	botao_preenchimento.pressed.connect(preencher_automatico)
	botao_preenchimento_desmonte.pressed.connect(preencher_desmonte)
	botao_sintetizar.pressed.connect(sintetizar)
	botao_desmontar.pressed.connect(desmontar)
	botao_aba_sintese.pressed.connect(mostrar_aba.bind(Aba.SINTESE))
	botao_aba_desmontar.pressed.connect(mostrar_aba.bind(Aba.DESMONTAR))
	botao_filtro_forja.pressed.connect(_abrir_filtro.bind(botao_filtro_forja))
	botao_filtro_desmonte.pressed.connect(_abrir_filtro.bind(botao_filtro_desmonte))
	botao_armazem_forja.toggled.connect(_on_armazem_toggled)
	botao_armazem_desmonte.toggled.connect(_on_armazem_toggled)
	cabecalho.gui_input.connect(_on_cabecalho_gui_input)
	gui_input.connect(_on_cabecalho_gui_input)
	visibility_changed.connect(_on_visibilidade_legenda_info)
	label_explicacao.text = TEXTO_RODAPE
	label_explicacao_desmontar.text = TEXTO_DESMONTE
	_configurar_botao_info_nivel()
	mostrar_aba(Aba.SINTESE)
	_atualizar_botoes_filtro()
	_atualizar_botoes_armazem()
	_atualizar_estado()
	_atualizar_desmonte()


func configurar(menu: MenuInventario) -> void:
	_menu = menu
	for slot in _todos_slots():
		_menu.conectar_slot_ferraria(slot)
	if not _menu.equipamentos_alterados.is_connected(_on_itens_alterados):
		_menu.equipamentos_alterados.connect(_on_itens_alterados)


func slots_sintese() -> Array[SlotItem]:
	var todos: Array[SlotItem] = []
	todos.append_array(_slots)
	todos.append_array(_slots_desmontar)
	return todos


func slots_apenas_sintese() -> Array[SlotItem]:
	return _slots


func eh_slot_ferraria(slot: SlotItem) -> bool:
	return slot in _slots or slot in _slots_desmontar


func origem_ja_reservada(origem: SlotItem) -> bool:
	return _vinculos.values().has(origem)


func reservar_item(origem: SlotItem, slot_ferraria: SlotItem) -> bool:
	if _menu == null or origem == null or slot_ferraria == null:
		return false
	if _tem_resultado_pendente():
		return false
	if origem.item == null or slot_ferraria.item != null:
		return false
	if origem.reservado_ferraria or origem_ja_reservada(origem):
		return false
	if eh_slot_sintese(slot_ferraria) and not pode_receber_na_sintese(origem.item):
		aviso_categoria_bloqueada(origem.item)
		return false
	slot_ferraria.definir_item(origem.item)
	origem.definir_reserva_ferraria(true)
	_vinculos[slot_ferraria] = origem
	return true


func liberar_slot_ferraria(slot_ferraria: SlotItem) -> void:
	if eh_resultado_pendente(slot_ferraria):
		return
	if not _vinculos.has(slot_ferraria):
		slot_ferraria.definir_item(null)
		return
	var origem: SlotItem = _vinculos[slot_ferraria]
	_vinculos.erase(slot_ferraria)
	slot_ferraria.definir_item(null)
	if origem and is_instance_valid(origem):
		origem.definir_reserva_ferraria(false)


func liberar_todos() -> void:
	for slot in _todos_slots():
		liberar_slot_ferraria(slot)


func trocar_reservas(a: SlotItem, b: SlotItem) -> void:
	var origem_a: SlotItem = _vinculos.get(a)
	var origem_b: SlotItem = _vinculos.get(b)
	var item_a := a.item
	var item_b := b.item
	a.definir_item(item_b)
	b.definir_item(item_a)
	if origem_a:
		_vinculos[b] = origem_a
	else:
		_vinculos.erase(b)
	if origem_b:
		_vinculos[a] = origem_b
	else:
		_vinculos.erase(a)


func consumir_reservas(lista: Array[SlotItem]) -> void:
	for slot_ferraria in lista:
		if eh_resultado_pendente(slot_ferraria):
			continue
		var origem: SlotItem = _vinculos.get(slot_ferraria)
		if origem and is_instance_valid(origem):
			origem.definir_item(null)
			origem.definir_reserva_ferraria(false)
		_vinculos.erase(slot_ferraria)
		slot_ferraria.definir_item(null)


func eh_resultado_pendente(slot: SlotItem) -> bool:
	return slot == _slots[SLOT_CENTRAL] and slot.item != null and not _vinculos.has(slot)


func _tem_resultado_pendente() -> bool:
	return eh_resultado_pendente(_slots[SLOT_CENTRAL])


func coletar_resultado_para(destino: SlotItem = null) -> bool:
	if _menu == null or not _tem_resultado_pendente():
		return false
	var central := _slots[SLOT_CENTRAL]
	var item := central.item
	if destino != null:
		if destino.item != null or destino.reservado_ferraria:
			return false
		destino.definir_item(item)
		central.definir_item(null)
		return true
	if _menu.adicionar_item(item):
		central.definir_item(null)
		return true
	return false


func interagir_slot(slot: SlotItem) -> void:
	if eh_resultado_pendente(slot):
		if not coletar_resultado_para():
			_definir_status("Inventário cheio. Libere espaço para retirar o item.", Color(1, 0.55, 0.4, 1))
		return
	liberar_slot_ferraria(slot)


func eh_slot_sintese(slot: SlotItem) -> bool:
	return slot in _slots


func categoria_sintese_travada() -> Variant:
	for slot in _slots:
		if slot.item != null:
			return slot.item.categoria()
	return null


func pode_receber_na_sintese(item: ItemData) -> bool:
	if item == null:
		return true
	var travada: Variant = categoria_sintese_travada()
	if travada == null:
		return true
	return item.categoria() == travada


func aviso_categoria_bloqueada(item: ItemData) -> void:
	var travada: Variant = categoria_sintese_travada()
	if travada == null or item == null:
		return
	_definir_status(
		"Grade travada em %s. Não é possível misturar %s." % [
			ItemData.nome_categoria(travada as ItemData.Categoria),
			ItemData.nome_categoria(item.categoria()),
		],
		Color(1, 0.55, 0.4, 1)
	)


func primeiro_slot_vazio() -> SlotItem:
	for slot in _slots_da_aba_atual():
		if slot.item == null:
			return slot
	return null


func esta_aberta() -> bool:
	return visible


func mostrar_aba(aba: Aba) -> void:
	if aba != _aba:
		_limpar_aba(_aba)
	_aba = aba
	painel_sintese.visible = aba == Aba.SINTESE
	painel_desmontar.visible = aba == Aba.DESMONTAR
	_pintar_aba(botao_aba_sintese, aba == Aba.SINTESE)
	_pintar_aba(botao_aba_desmontar, aba == Aba.DESMONTAR)
	_on_itens_alterados()


## Alterna a janela. Só abre se o inventário estiver visível.
func alternar() -> void:
	if visible:
		fechar()
	else:
		abrir()


func abrir() -> void:
	if _menu == null or not _menu.visible:
		return
	show()
	_atualizar_estado()
	_atualizar_desmonte()
	visibilidade_alterada.emit(true)


func fechar() -> void:
	_ocultar_legenda_info()
	_devolver_itens()
	hide()
	visibilidade_alterada.emit(false)


func preencher_automatico() -> void:
	if _menu == null:
		return
	if _tem_resultado_pendente():
		_definir_status("Retire o item do slot central antes de preencher.", Color(1, 0.55, 0.4, 1))
		return
	_devolver_lista(_slots)
	var grupo := _encontrar_grupo_elegivel()
	if grupo.is_empty():
		_atualizar_estado()
		_definir_status(_mensagem_sem_grupo(), Color(1, 0.55, 0.4, 1))
		return
	for i in SLOTS_SINTSE:
		reservar_item(grupo[i], _slots[i])
	_atualizar_estado()


func preencher_desmonte() -> void:
	if _menu == null:
		return
	_devolver_lista(_slots_desmontar)
	var candidatos := _itens_origem_filtrados(false)
	if candidatos.is_empty():
		_atualizar_desmonte()
		label_explicacao_desmontar.text = _mensagem_sem_itens_desmonte()
		label_explicacao_desmontar.add_theme_color_override("font_color", Color(1, 0.55, 0.4, 1))
		return
	var limite := mini(SLOTS_SINTSE, candidatos.size())
	for i in limite:
		reservar_item(candidatos[i], _slots_desmontar[i])
	_atualizar_desmonte()
	label_explicacao_desmontar.text = "Grade preenchida. Clique em DESMONTAR."
	label_explicacao_desmontar.add_theme_color_override("font_color", Color(0.72, 0.9, 0.7, 1))


func sintetizar() -> void:
	if not _receita_valida():
		_atualizar_estado()
		_definir_status("Coloque 9 itens da mesma raridade e família (equipamento ou acessório).", Color(1, 0.55, 0.4, 1))
		return
	var ingredientes: Array[ItemData] = []
	for slot in _slots:
		ingredientes.append(slot.item)
	var raridade_base := ingredientes[0].raridade
	var chance := ItemData.chance_forja_sucesso(raridade_base)
	var sucesso := randf() <= chance
	var raridade_resultado := ItemData.proxima_raridade(raridade_base) if sucesso else raridade_base
	var resultado := _criar_item_sintetizado(ingredientes, raridade_resultado)
	consumir_reservas(_slots)
	_slots[SLOT_CENTRAL].definir_item(resultado)
	_menu.notificar_itens_alterados()
	_atualizar_estado()
	if sucesso:
		_definir_status(
			"Sucesso! %s (%s, Nv.%d)." % [resultado.nome, resultado.nome_raridade(), resultado.nivel_item],
			Color(0.85, 0.78, 0.32, 1)
		)
	else:
		_definir_status(
			"Forja falhou (%d%%). Recebeu: %s (%s, Nv.%d). Retire do slot central." % [
				ItemData.chance_forja_sucesso_pct(raridade_base),
				resultado.nome,
				resultado.nome_raridade(),
				resultado.nivel_item,
			],
			Color(1, 0.55, 0.4, 1)
		)


func desmontar() -> void:
	var valor := _valor_desmonte_atual()
	if valor <= 0:
		_atualizar_desmonte()
		label_explicacao_desmontar.text = "Coloque itens na grade para desmontar."
		label_explicacao_desmontar.add_theme_color_override("font_color", Color(1, 0.55, 0.4, 1))
		return
	consumir_reservas(_slots_desmontar)
	ouro_obtido.emit(valor)
	_menu.notificar_itens_alterados()
	_atualizar_desmonte()
	label_explicacao_desmontar.text = "Desmonte concluído: +%d ouro." % valor
	label_explicacao_desmontar.add_theme_color_override("font_color", Color(0.85, 0.78, 0.32, 1))


func _criar_slots(grade: GridContainer, destino: Array[SlotItem], sintese: bool) -> void:
	grade.columns = COLUNAS
	for indice in SLOTS_SINTSE:
		var slot := SlotItem.new()
		slot.name = "%s_%d" % [grade.name, indice + 1]
		slot.custom_minimum_size = TAMANHO_SLOT
		var icone := TextureRect.new()
		icone.name = "Icone"
		icone.set_anchors_preset(Control.PRESET_FULL_RECT)
		icone.offset_left = 4.0
		icone.offset_top = 4.0
		icone.offset_right = -4.0
		icone.offset_bottom = -4.0
		icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(icone)
		slot.configurar(icone, ItemData.Tipo.ARMA, true)
		if sintese:
			slot.validar_drop_extra = _validar_drop_sintese
		else:
			slot.validar_drop_extra = _validar_drop_desmonte
		slot.item_duplo_clique.connect(_on_slot_duplo_clique)
		grade.add_child(slot)
		destino.append(slot)


func _validar_drop_sintese(item: ItemData, origem: SlotItem = null) -> bool:
	if origem and (origem.reservado_ferraria or origem_ja_reservada(origem)):
		return false
	return pode_receber_na_sintese(item)


func _validar_drop_desmonte(item: ItemData, origem: SlotItem = null) -> bool:
	if origem and (origem.reservado_ferraria or origem_ja_reservada(origem)):
		return false
	return item != null


func _on_slot_duplo_clique(slot: SlotItem) -> void:
	if _menu == null or slot.item == null:
		return
	if eh_resultado_pendente(slot):
		if coletar_resultado_para():
			_on_itens_alterados()
		else:
			_definir_status("Inventário cheio. Libere espaço para retirar o item.", Color(1, 0.55, 0.4, 1))
		return
	liberar_slot_ferraria(slot)
	_on_itens_alterados()


func _devolver_itens() -> void:
	_guardar_resultado_central()
	liberar_todos()


func _guardar_resultado_central() -> void:
	if _menu == null or not _tem_resultado_pendente():
		return
	if not coletar_resultado_para():
		_definir_status("Inventário cheio. O item forjado permanece na grade.", Color(1, 0.55, 0.4, 1))


func _devolver_lista(lista: Array[SlotItem]) -> void:
	for slot in lista:
		liberar_slot_ferraria(slot)


func _limpar_aba(aba: Aba) -> void:
	match aba:
		Aba.SINTESE:
			_guardar_resultado_central()
			_devolver_lista(_slots)
		Aba.DESMONTAR:
			_devolver_lista(_slots_desmontar)


func _encontrar_grupo_elegivel() -> Array[SlotItem]:
	var grupos: Dictionary = {}
	for slot in _slots_origem():
		if slot.item == null or slot.reservado_ferraria:
			continue
		if ItemData.eh_raridade_maxima(slot.item.raridade):
			continue
		if not _passa_filtro(slot.item):
			continue
		var chave := "%d_%d" % [int(slot.item.categoria()), int(slot.item.raridade)]
		if not grupos.has(chave):
			var nova: Array = []
			grupos[chave] = nova
		var grupo_atual: Array = grupos[chave] as Array
		grupo_atual.append(slot)
		grupos[chave] = grupo_atual
	var melhor: Array = []
	for chave in grupos.keys():
		var grupo: Array = grupos[chave] as Array
		if grupo.size() >= SLOTS_SINTSE and grupo.size() > melhor.size():
			melhor = grupo
	var escolhido: Array[SlotItem] = []
	for i in mini(SLOTS_SINTSE, melhor.size()):
		escolhido.append(melhor[i] as SlotItem)
	return escolhido


func _receita_valida() -> bool:
	if _tem_resultado_pendente():
		return false
	if _slots.size() != SLOTS_SINTSE:
		return false
	var primeiro: ItemData = _slots[0].item
	if primeiro == null or ItemData.eh_raridade_maxima(primeiro.raridade):
		return false
	for slot in _slots:
		if slot.item == null:
			return false
		if slot.item.categoria() != primeiro.categoria():
			return false
		if slot.item.raridade != primeiro.raridade:
			return false
	return true


func _criar_item_sintetizado(ingredientes: Array[ItemData], raridade_alvo: ItemData.Raridade) -> ItemData:
	var base := ingredientes[0]
	var categoria := base.categoria()
	var tipo_resultado := _tipo_resultado_sintese(ingredientes, categoria)
	var soma_dano := 0
	var soma_vida := 0
	var soma_nivel := 0
	var classe := base.classe_requerida
	for item in ingredientes:
		soma_dano += item.dano_bonus
		soma_vida += item.vida_bonus
		soma_nivel += item.nivel_item
		if item.classe_requerida != classe:
			classe = ItemData.ClasseRequerida.TODAS
	var nivel_resultado := _sortear_nivel_forja(ingredientes)
	var nivel_medio := float(soma_nivel) / float(SLOTS_SINTSE)
	var ajuste_nivel := ItemData.multiplicador_nivel_item(nivel_resultado)
	ajuste_nivel /= maxf(0.01, ItemData.multiplicador_nivel_item(int(round(nivel_medio))))
	var resultado := ItemData.new()
	resultado.id = "%s_sint_%d" % [base.id, Time.get_ticks_msec()]
	resultado.nome = _nome_resultado_sintese(ingredientes, tipo_resultado)
	resultado.tipo = tipo_resultado
	resultado.raridade = raridade_alvo
	resultado.nivel_item = nivel_resultado
	resultado.classe_requerida = classe
	resultado.dano_bonus = maxi(1, int(round(float(soma_dano) / float(SLOTS_SINTSE) * 1.25 * ajuste_nivel)))
	resultado.vida_bonus = maxi(0, int(round(float(soma_vida) / float(SLOTS_SINTSE) * 1.25 * ajuste_nivel)))
	resultado.icone = resultado.gerar_icone()
	return resultado


func _sortear_nivel_forja(ingredientes: Array[ItemData]) -> int:
	if ingredientes.is_empty():
		return ItemData.NIVEIS_ITEM[0]
	var indice := randi() % ingredientes.size()
	return ItemData.normalizar_nivel_item(ingredientes[indice].nivel_item)


func _chances_nivel_na_grade() -> Dictionary:
	var contagem: Dictionary = {}
	var total := 0
	for slot in _slots:
		if slot.item == null:
			continue
		var nivel := slot.item.nivel_item
		contagem[nivel] = int(contagem.get(nivel, 0)) + 1
		total += 1
	if total == 0:
		return {}
	var chances: Dictionary = {}
	for nivel in contagem.keys():
		chances[nivel] = 100.0 * float(contagem[nivel]) / float(total)
	return chances


func _texto_tooltip_chances_nivel() -> String:
	var chances := _chances_nivel_na_grade()
	if chances.is_empty():
		return "Coloque itens na grade para ver as chances por nível."
	var niveis: Array = chances.keys()
	niveis.sort()
	var linhas: PackedStringArray = ["Chances de nível no resultado:"]
	for nivel in niveis:
		linhas.append("Nv.%d: %.1f%%" % [int(nivel), float(chances[nivel])])
	if _contar_ocupados(_slots) < SLOTS_SINTSE:
		linhas.append("")
		linhas.append("Valores com base nos %d itens atuais." % _contar_ocupados(_slots))
	return "\n".join(linhas)


func _configurar_botao_info_nivel() -> void:
	if botao_info_nivel == null:
		return
	botao_info_nivel.custom_minimum_size = Vector2(TAMANHO_ICONE_INFO, TAMANHO_ICONE_INFO)
	botao_info_nivel.mouse_filter = Control.MOUSE_FILTER_STOP
	botao_info_nivel.tooltip_text = ""
	for margem in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		botao_info_nivel.add_theme_constant_override(margem, 0)
	for filho in botao_info_nivel.get_children():
		filho.queue_free()
	var centro := CenterContainer.new()
	centro.name = "CentroInfo"
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	botao_info_nivel.add_child(centro)
	var rotulo := Label.new()
	rotulo.name = "RotuloInfo"
	rotulo.text = "i"
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rotulo.add_theme_font_size_override("font_size", 14)
	rotulo.add_theme_color_override("font_color", Color(0.92, 0.86, 0.72, 1))
	rotulo.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.45))
	rotulo.add_theme_constant_override("outline_size", 1)
	var ajuste := MarginContainer.new()
	ajuste.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ajuste.add_theme_constant_override("margin_left", 1)
	ajuste.add_theme_constant_override("margin_top", 1)
	ajuste.add_child(rotulo)
	centro.add_child(ajuste)
	_aplicar_estilo_icone_info(false)
	if not botao_info_nivel.mouse_entered.is_connected(_on_icone_info_mouse_entered):
		botao_info_nivel.mouse_entered.connect(_on_icone_info_mouse_entered)
	if not botao_info_nivel.mouse_exited.is_connected(_on_icone_info_mouse_exited):
		botao_info_nivel.mouse_exited.connect(_on_icone_info_mouse_exited)


func _on_icone_info_mouse_entered() -> void:
	_aplicar_estilo_icone_info(true)
	_mostrar_legenda_info()


func _on_icone_info_mouse_exited() -> void:
	_aplicar_estilo_icone_info(false)
	_ocultar_legenda_info()


func _aplicar_estilo_icone_info(hover: bool) -> void:
	if botao_info_nivel == null:
		return
	var raio := TAMANHO_ICONE_INFO / 2
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.18, 0.15, 0.13, 1) if hover else Color(0.14, 0.12, 0.1, 1)
	estilo.border_color = Color(0.9, 0.76, 0.38, 1) if hover else Color(0.72, 0.58, 0.28, 1)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(raio)
	estilo.set_content_margin_all(0)
	botao_info_nivel.add_theme_stylebox_override("panel", estilo)


func _on_visibilidade_legenda_info() -> void:
	if not visible:
		_ocultar_legenda_info()


func _garantir_caixa_legenda_info() -> PanelContainer:
	if _camada_legenda_info == null or not is_instance_valid(_camada_legenda_info):
		_camada_legenda_info = CanvasLayer.new()
		_camada_legenda_info.layer = CAMADA_LEGENDA_INFO
		_camada_legenda_info.name = "CamadaLegendaInfoFerraria"
		get_tree().root.add_child(_camada_legenda_info)
	if _caixa_legenda_info == null or not is_instance_valid(_caixa_legenda_info):
		_caixa_legenda_info = PanelContainer.new()
		_caixa_legenda_info.z_index = Z_INDEX_LEGENDA_INFO
		_caixa_legenda_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_camada_legenda_info.add_child(_caixa_legenda_info)
	return _caixa_legenda_info


func _preencher_legenda_info(caixa: PanelContainer) -> void:
	while caixa.get_child_count() > 0:
		caixa.get_child(0).free()
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color(0.08, 0.07, 0.06, 0.96)
	fundo.border_color = Color(0.72, 0.58, 0.28, 1)
	fundo.set_border_width_all(2)
	fundo.set_corner_radius_all(4)
	fundo.content_margin_left = 10
	fundo.content_margin_top = 8
	fundo.content_margin_right = 10
	fundo.content_margin_bottom = 8
	caixa.add_theme_stylebox_override("panel", fundo)
	var coluna := VBoxContainer.new()
	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_theme_constant_override("separation", 3)
	var linhas := _texto_tooltip_chances_nivel().split("\n")
	for i in linhas.size():
		var linha := str(linhas[i])
		if linha == "":
			continue
		var rotulo := Label.new()
		rotulo.text = linha
		rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rotulo.add_theme_font_size_override("font_size", 11 if i > 0 else 12)
		if i == 0:
			rotulo.add_theme_color_override("font_color", Color(0.95, 0.86, 0.45, 1))
		else:
			rotulo.add_theme_color_override("font_color", Color(0.88, 0.84, 0.75, 1))
		coluna.add_child(rotulo)
	caixa.add_child(coluna)


func _posicionar_legenda_info() -> void:
	if _caixa_legenda_info == null or botao_info_nivel == null:
		return
	_caixa_legenda_info.reset_size()
	var tam := _caixa_legenda_info.get_combined_minimum_size()
	if _caixa_legenda_info.size.x > tam.x or _caixa_legenda_info.size.y > tam.y:
		tam = _caixa_legenda_info.size
	_caixa_legenda_info.size = tam
	var icone := botao_info_nivel.get_global_rect()
	var pos := Vector2(
		icone.position.x - tam.x - OFFSET_LEGENDA_INFO.x,
		icone.position.y + (icone.size.y - tam.y) * 0.5
	)
	var viewport := get_viewport().get_visible_rect()
	pos.x = clampf(pos.x, viewport.position.x + 4.0, maxf(viewport.position.x + 4.0, viewport.end.x - tam.x - 4.0))
	pos.y = clampf(pos.y, viewport.position.y + 4.0, maxf(viewport.position.y + 4.0, viewport.end.y - tam.y - 4.0))
	_caixa_legenda_info.global_position = pos


func _mostrar_legenda_info() -> void:
	if botao_info_nivel == null or not is_visible_in_tree():
		return
	var caixa := _garantir_caixa_legenda_info()
	_preencher_legenda_info(caixa)
	_posicionar_legenda_info()
	caixa.show()
	caixa.move_to_front()


func _ocultar_legenda_info() -> void:
	if _caixa_legenda_info and is_instance_valid(_caixa_legenda_info):
		_caixa_legenda_info.hide()


func _atualizar_tooltip_info_nivel() -> void:
	if _caixa_legenda_info == null or not _caixa_legenda_info.visible:
		return
	_preencher_legenda_info(_caixa_legenda_info)
	_posicionar_legenda_info()


func _tipo_resultado_sintese(ingredientes: Array[ItemData], categoria: ItemData.Categoria) -> ItemData.Tipo:
	var contagem: Dictionary = {}
	for item in ingredientes:
		if item.categoria() != categoria:
			continue
		var chave := int(item.tipo)
		contagem[chave] = int(contagem.get(chave, 0)) + 1
	var melhor_tipo := ingredientes[0].tipo
	var melhor_total := 0
	for chave in contagem.keys():
		var total := int(contagem[chave])
		if total > melhor_total:
			melhor_total = total
			melhor_tipo = chave as ItemData.Tipo
	return melhor_tipo


func _nome_resultado_sintese(ingredientes: Array[ItemData], tipo: ItemData.Tipo) -> String:
	for item in ingredientes:
		if item.tipo == tipo and item.nome != "":
			return item.nome
	return _nome_padrao_tipo(tipo)


func _nome_padrao_tipo(tipo: ItemData.Tipo) -> String:
	var amostra := ItemData.new()
	amostra.tipo = tipo
	return amostra.nome_tipo()


func _on_itens_alterados() -> void:
	_atualizar_estado()
	_atualizar_desmonte()


func _atualizar_estado() -> void:
	if botao_sintetizar == null:
		return
	_atualizar_tooltip_info_nivel()
	if _tem_resultado_pendente():
		botao_sintetizar.disabled = true
		var item := _slots[SLOT_CENTRAL].item
		_definir_status(
			"Item pronto: %s (%s, Nv.%d). Retire do slot central." % [item.nome, item.nome_raridade(), item.nivel_item],
			Color(0.72, 0.9, 0.7, 1)
		)
		return
	var valida := _receita_valida()
	botao_sintetizar.disabled = not valida
	if valida:
		var amostra: ItemData = _slots[0].item
		var pct := ItemData.chance_forja_sucesso_pct(amostra.raridade)
		_definir_status("Chance de sucesso: %d%%" % pct, Color(0.85, 0.78, 0.32, 1))
	elif _contar_ocupados(_slots) == 0:
		_definir_status(TEXTO_RODAPE, Color(0.72, 0.66, 0.52, 1))
	else:
		var travada: Variant = categoria_sintese_travada()
		var extra := ""
		if travada != null:
			extra = " Família: %s." % ItemData.nome_categoria(travada as ItemData.Categoria)
		_definir_status(
			"%d/9 — mesma raridade e família. Níveis podem ser misturados.%s" % [_contar_ocupados(_slots), extra],
			Color(0.82, 0.74, 0.55, 1)
		)


func _atualizar_desmonte() -> void:
	if botao_desmontar == null:
		return
	var valor := _valor_desmonte_atual()
	var ocupados := _contar_ocupados(_slots_desmontar)
	botao_desmontar.disabled = valor <= 0
	label_valor_desmonte.text = "Valor: %d ouro" % valor
	if ocupados == 0:
		label_explicacao_desmontar.text = TEXTO_DESMONTE
		label_explicacao_desmontar.add_theme_color_override("font_color", Color(0.72, 0.66, 0.52, 1))


func _valor_desmonte_atual() -> int:
	var total := 0
	for slot in _slots_desmontar:
		if slot.item:
			total += slot.item.valor_desmonte()
	return total


func _contar_ocupados(lista: Array[SlotItem]) -> int:
	var total := 0
	for slot in lista:
		if slot.item:
			total += 1
	return total


func _slots_da_aba_atual() -> Array[SlotItem]:
	if _aba == Aba.DESMONTAR:
		return _slots_desmontar
	return _slots


func _todos_slots() -> Array[SlotItem]:
	var todos: Array[SlotItem] = []
	todos.append_array(_slots)
	todos.append_array(_slots_desmontar)
	return todos


func _pintar_aba(botao: Button, ativa: bool) -> void:
	var estilo := StyleBoxFlat.new()
	estilo.content_margin_left = 8
	estilo.content_margin_top = 7
	estilo.content_margin_right = 8
	estilo.content_margin_bottom = 7
	estilo.set_corner_radius_all(4)
	estilo.set_border_width_all(1)
	if ativa:
		estilo.bg_color = Color(0.32, 0.24, 0.16, 1)
		estilo.border_color = Color(0.95, 0.78, 0.32, 1)
	else:
		estilo.bg_color = Color(0.18, 0.14, 0.11, 1)
		estilo.border_color = Color(0.62, 0.5, 0.28, 1)
	botao.add_theme_stylebox_override("normal", estilo)
	botao.add_theme_stylebox_override("hover", estilo)


func _definir_status(texto: String, cor: Color) -> void:
	if label_explicacao == null:
		return
	label_explicacao.text = texto
	label_explicacao.add_theme_color_override("font_color", cor)


func _slots_origem() -> Array[SlotItem]:
	if _menu == null:
		var vazio: Array[SlotItem] = []
		return vazio
	if _usar_armazem:
		return _menu.slots_armazem()
	return _menu.slots_inventario()


func _passa_filtro(item: ItemData) -> bool:
	if item == null:
		return false
	if _filtro_raridade == FILTRO_TODOS:
		return true
	return int(item.raridade) == _filtro_raridade


func _itens_origem_filtrados(ignorar_lendario: bool) -> Array[SlotItem]:
	var lista: Array[SlotItem] = []
	for slot in _slots_origem():
		if slot.item == null or slot.reservado_ferraria:
			continue
		if ignorar_lendario and ItemData.eh_raridade_maxima(slot.item.raridade):
			continue
		if _passa_filtro(slot.item):
			lista.append(slot)
	return lista


func _criar_popup_filtro() -> void:
	_popup_filtro = PopupMenu.new()
	_popup_filtro.name = "MenuFiltroRaridade"
	add_child(_popup_filtro)
	var nomes := ItemData.nomes_filtro_ferraria()
	for i in nomes.size():
		_popup_filtro.add_item(nomes[i], i)
	_popup_filtro.id_pressed.connect(_on_filtro_escolhido)


func _abrir_filtro(botao: Button) -> void:
	if _popup_filtro == null or botao == null:
		return
	var pos := botao.get_screen_position()
	_popup_filtro.position = Vector2i(int(pos.x), int(pos.y + botao.size.y))
	_popup_filtro.popup()


func _on_filtro_escolhido(id: int) -> void:
	if id <= 0:
		_filtro_raridade = FILTRO_TODOS
	else:
		_filtro_raridade = id - 1
	_atualizar_botoes_filtro()


func _on_armazem_toggled(ligado: bool) -> void:
	_usar_armazem = ligado
	if botao_armazem_forja.button_pressed != ligado:
		botao_armazem_forja.set_pressed_no_signal(ligado)
	if botao_armazem_desmonte.button_pressed != ligado:
		botao_armazem_desmonte.set_pressed_no_signal(ligado)
	_atualizar_botoes_armazem()
	if ligado and _menu and _menu.painel_armazem and not _menu.painel_armazem.esta_aberta():
		_menu.painel_armazem.abrir()


func _atualizar_botoes_filtro() -> void:
	var texto := "Filtro: %s" % _nome_filtro_atual()
	if botao_filtro_forja:
		botao_filtro_forja.text = texto
	if botao_filtro_desmonte:
		botao_filtro_desmonte.text = texto


func _atualizar_botoes_armazem() -> void:
	var texto := "Só armazém" if _usar_armazem else "Incluir armazém"
	_pintar_toggle(botao_armazem_forja, _usar_armazem, texto)
	_pintar_toggle(botao_armazem_desmonte, _usar_armazem, texto)


func _pintar_toggle(botao: Button, ativo: bool, texto: String) -> void:
	if botao == null:
		return
	botao.text = texto
	_pintar_aba(botao, ativo)


func _nome_filtro_atual() -> String:
	if _filtro_raridade == FILTRO_TODOS:
		return "Todos"
	return ItemData.nome_de_raridade(_filtro_raridade as ItemData.Raridade)


func _mensagem_sem_grupo() -> String:
	var origem := "do armazém" if _usar_armazem else "do inventário"
	if _filtro_raridade == FILTRO_TODOS:
		return "Não há 9 itens da mesma família %s." % origem
	return "Não há 9 itens %s %s." % [_nome_filtro_atual().to_lower(), origem]


func _mensagem_sem_itens_desmonte() -> String:
	var origem := "no armazém" if _usar_armazem else "no inventário"
	if _filtro_raridade == FILTRO_TODOS:
		return "Não há itens %s." % origem
	return "Não há itens %s %s." % [_nome_filtro_atual().to_lower(), origem]


func _on_cabecalho_gui_input(event: InputEvent) -> void:
	if _menu == null:
		return
	_menu.arrastar_janela_pelo_evento(event)
