class_name Ferraria
extends PanelContainer
## Painel lateral de síntese e desmonte (estilo CUBE).
## Fica acoplado à direita do inventário e só existe enquanto o menu está aberto.

signal visibilidade_alterada(aberta: bool)
signal ouro_obtido(quantidade: int)

enum Aba { SINTESE, DESMONTAR }

const SLOTS_SINTSE := 9
const COLUNAS := 3
const TAMANHO_SLOT := Vector2(44, 44)
const TEXTO_RODAPE := "Sintetize 9 itens da mesma raridade e categoria para obter 1 de grau superior."
const TEXTO_DESMONTE := "Desmonte itens para convertê-los em ouro. Itens melhores valem mais."

@onready var grade_sintese: GridContainer = %GradeSintese
@onready var grade_desmontar: GridContainer = %GradeDesmontar
@onready var botao_fechar: Button = %BotaoFecharFerraria
@onready var botao_preenchimento: Button = %BotaoPreenchimento
@onready var botao_sintetizar: Button = %BotaoSintetizar
@onready var botao_desmontar: Button = %BotaoDesmontar
@onready var botao_aba_sintese: Button = %BotaoAbaSintese
@onready var botao_aba_desmontar: Button = %BotaoAbaDesmontar
@onready var painel_sintese: VBoxContainer = %PainelSintese
@onready var painel_desmontar: VBoxContainer = %PainelDesmontar
@onready var label_explicacao: Label = %LabelExplicacaoFerraria
@onready var label_explicacao_desmontar: Label = %LabelExplicacaoDesmontar
@onready var label_valor_desmonte: Label = %LabelValorDesmonte
@onready var cabecalho: HBoxContainer = %CabecalhoFerraria

var _menu: MenuInventario
var _slots: Array[SlotItem] = []
var _slots_desmontar: Array[SlotItem] = []
var _aba: Aba = Aba.SINTESE


func _ready() -> void:
	hide()
	_criar_slots(grade_sintese, _slots)
	_criar_slots(grade_desmontar, _slots_desmontar)
	botao_fechar.pressed.connect(fechar)
	botao_preenchimento.pressed.connect(preencher_automatico)
	botao_sintetizar.pressed.connect(sintetizar)
	botao_desmontar.pressed.connect(desmontar)
	botao_aba_sintese.pressed.connect(mostrar_aba.bind(Aba.SINTESE))
	botao_aba_desmontar.pressed.connect(mostrar_aba.bind(Aba.DESMONTAR))
	cabecalho.gui_input.connect(_on_cabecalho_gui_input)
	gui_input.connect(_on_cabecalho_gui_input)
	label_explicacao.text = TEXTO_RODAPE
	label_explicacao_desmontar.text = TEXTO_DESMONTE
	mostrar_aba(Aba.SINTESE)
	_atualizar_estado()
	_atualizar_desmonte()


func configurar(menu: MenuInventario) -> void:
	_menu = menu
	for slot in _todos_slots():
		_menu.conectar_slot_ferraria(slot)
	if not _menu.equipamentos_alterados.is_connected(_on_itens_alterados):
		_menu.equipamentos_alterados.connect(_on_itens_alterados)


func slots_sintese() -> Array[SlotItem]:
	return _todos_slots()


func primeiro_slot_vazio() -> SlotItem:
	for slot in _slots_da_aba_atual():
		if slot.item == null:
			return slot
	return null


func esta_aberta() -> bool:
	return visible


func mostrar_aba(aba: Aba) -> void:
	_aba = aba
	painel_sintese.visible = aba == Aba.SINTESE
	painel_desmontar.visible = aba == Aba.DESMONTAR
	_pintar_aba(botao_aba_sintese, aba == Aba.SINTESE)
	_pintar_aba(botao_aba_desmontar, aba == Aba.DESMONTAR)
	if aba == Aba.SINTESE:
		_atualizar_estado()
	else:
		_atualizar_desmonte()


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
	_devolver_itens()
	hide()
	visibilidade_alterada.emit(false)


func preencher_automatico() -> void:
	if _menu == null:
		return
	_devolver_lista(_slots)
	var grupo := _encontrar_grupo_elegivel()
	if grupo.is_empty():
		_atualizar_estado()
		_definir_status("Não há 9 itens da mesma raridade e categoria.", Color(1, 0.55, 0.4, 1))
		return
	for i in SLOTS_SINTSE:
		_menu.mover_item_entre_slots(grupo[i], _slots[i])
	_atualizar_estado()
	_definir_status("Grade preenchida. Clique em SINTETIZAR.", Color(0.72, 0.9, 0.7, 1))


func sintetizar() -> void:
	if not _receita_valida():
		_atualizar_estado()
		_definir_status("Coloque 9 itens da mesma raridade e categoria.", Color(1, 0.55, 0.4, 1))
		return
	var ingredientes: Array[ItemData] = []
	for slot in _slots:
		ingredientes.append(slot.item)
	var resultado := _criar_item_sintetizado(ingredientes)
	for slot in _slots:
		slot.definir_item(null)
	if not _menu.adicionar_item(resultado):
		_slots[0].definir_item(resultado)
		_menu.notificar_itens_alterados()
		_atualizar_estado()
		_definir_status("Inventário cheio. O item ficou na grade.", Color(1, 0.55, 0.4, 1))
		return
	_menu.notificar_itens_alterados()
	_atualizar_estado()
	_definir_status("Síntese concluída: %s (%s)." % [resultado.nome, resultado.nome_raridade()], Color(0.85, 0.78, 0.32, 1))


func desmontar() -> void:
	var valor := _valor_desmonte_atual()
	if valor <= 0:
		_atualizar_desmonte()
		label_explicacao_desmontar.text = "Coloque itens na grade para desmontar."
		label_explicacao_desmontar.add_theme_color_override("font_color", Color(1, 0.55, 0.4, 1))
		return
	for slot in _slots_desmontar:
		slot.definir_item(null)
	ouro_obtido.emit(valor)
	_menu.notificar_itens_alterados()
	_atualizar_desmonte()
	label_explicacao_desmontar.text = "Desmonte concluído: +%d ouro." % valor
	label_explicacao_desmontar.add_theme_color_override("font_color", Color(0.85, 0.78, 0.32, 1))


func _criar_slots(grade: GridContainer, destino: Array[SlotItem]) -> void:
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
		slot.item_duplo_clique.connect(_on_slot_duplo_clique)
		grade.add_child(slot)
		destino.append(slot)


func _on_slot_duplo_clique(slot: SlotItem) -> void:
	if _menu == null or slot.item == null:
		return
	var vazio := _menu.primeiro_slot_inventario_vazio()
	if vazio:
		_menu.mover_item_entre_slots(slot, vazio)
		_on_itens_alterados()


func _devolver_itens() -> void:
	_devolver_lista(_slots)
	_devolver_lista(_slots_desmontar)


func _devolver_lista(lista: Array[SlotItem]) -> void:
	if _menu == null:
		return
	for slot in lista:
		if slot.item == null:
			continue
		var vazio := _menu.primeiro_slot_inventario_vazio()
		if vazio:
			_menu.mover_item_entre_slots(slot, vazio)
		else:
			break


func _encontrar_grupo_elegivel() -> Array[SlotItem]:
	var grupos: Dictionary = {}
	for slot in _menu.slots_inventario():
		if slot.item == null:
			continue
		if slot.item.raridade == ItemData.Raridade.LENDARIO:
			continue
		var chave := "%d_%d" % [int(slot.item.tipo), int(slot.item.raridade)]
		if not grupos.has(chave):
			grupos[chave] = []
		grupos[chave].append(slot)
	var melhor: Array = []
	for chave in grupos.keys():
		var grupo: Array = grupos[chave]
		if grupo.size() >= SLOTS_SINTSE and grupo.size() > melhor.size():
			melhor = grupo
	var escolhido: Array[SlotItem] = []
	for i in mini(SLOTS_SINTSE, melhor.size()):
		escolhido.append(melhor[i] as SlotItem)
	return escolhido


func _receita_valida() -> bool:
	if _slots.size() != SLOTS_SINTSE:
		return false
	var primeiro: ItemData = _slots[0].item
	if primeiro == null or primeiro.raridade == ItemData.Raridade.LENDARIO:
		return false
	for slot in _slots:
		if slot.item == null:
			return false
		if slot.item.tipo != primeiro.tipo:
			return false
		if slot.item.raridade != primeiro.raridade:
			return false
	return true


func _criar_item_sintetizado(ingredientes: Array[ItemData]) -> ItemData:
	var base := ingredientes[0]
	var soma_dano := 0
	var soma_vida := 0
	var classe := base.classe_requerida
	for item in ingredientes:
		soma_dano += item.dano_bonus
		soma_vida += item.vida_bonus
		if item.classe_requerida != classe:
			classe = ItemData.ClasseRequerida.TODAS
	var resultado := ItemData.new()
	resultado.id = "%s_sint_%d" % [base.id, Time.get_ticks_msec()]
	resultado.nome = base.nome
	resultado.tipo = base.tipo
	resultado.raridade = (int(base.raridade) + 1) as ItemData.Raridade
	resultado.classe_requerida = classe
	resultado.dano_bonus = maxi(1, int(round(float(soma_dano) / float(SLOTS_SINTSE) * 1.25)))
	resultado.vida_bonus = maxi(0, int(round(float(soma_vida) / float(SLOTS_SINTSE) * 1.25)))
	resultado.icone = resultado.gerar_icone()
	return resultado


func _on_itens_alterados() -> void:
	_atualizar_estado()
	_atualizar_desmonte()


func _atualizar_estado() -> void:
	if botao_sintetizar == null:
		return
	var valida := _receita_valida()
	botao_sintetizar.disabled = not valida
	if valida:
		var amostra: ItemData = _slots[0].item
		_definir_status(
			"Pronto: 9x %s %s → 1 %s." % [
				amostra.nome_tipo(),
				amostra.nome_raridade(),
				_nome_proxima_raridade(amostra.raridade),
			],
			Color(0.85, 0.78, 0.32, 1)
		)
	elif _contar_ocupados(_slots) == 0:
		_definir_status(TEXTO_RODAPE, Color(0.72, 0.66, 0.52, 1))
	else:
		_definir_status("%d/9 — use a mesma raridade e categoria." % _contar_ocupados(_slots), Color(0.82, 0.74, 0.55, 1))


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


func _nome_proxima_raridade(atual: ItemData.Raridade) -> String:
	match atual:
		ItemData.Raridade.COMUM:
			return "Raro"
		ItemData.Raridade.RARO:
			return "Épico"
		ItemData.Raridade.EPICO:
			return "Lendário"
		_:
			return "—"


func _definir_status(texto: String, cor: Color) -> void:
	if label_explicacao == null:
		return
	label_explicacao.text = texto
	label_explicacao.add_theme_color_override("font_color", cor)


func _on_cabecalho_gui_input(event: InputEvent) -> void:
	if _menu == null:
		return
	_menu.arrastar_janela_pelo_evento(event)
