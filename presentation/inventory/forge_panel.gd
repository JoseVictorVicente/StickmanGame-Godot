class_name ForgePanel
extends Control
## Painel lateral de forja e desmonte.
## Fica acoplado à direita do inventário e só existe enquanto o menu está aberto.

signal panel_open_changed(is_open: bool)
signal gold_gained(quantidade: int)

enum Aba { SINTESE, DESMONTAR, JOIAS }

const SLOTS_SINTSE := 9
const SLOT_CENTRAL := 4
const COLUNAS := 3
const TAMANHO_SLOT := Vector2(44, 44)
const TAMANHO_ICONE_INFO := 28
const TAMANHO_TOGGLE_ARMAZEM := Vector2(48, 26)
const GRADE_MARGEM := 0.08
const FILTRO_TODOS := -1
const CAMADA_LEGENDA_INFO := 127
const Z_INDEX_LEGENDA_INFO := 100
const OFFSET_LEGENDA_INFO := Vector2(10, 0)
const TEXTO_RODAPE := "Forje 9 itens da mesma raridade e família"
const TEXTO_DESMONTE := "Desmonte itens para receber ouro"
const TEXTO_JOIAS := "Imbua uma gema em equipamento lendário ou superior"
const JOIAS_LARGURA_SETA := 32.0

@onready var grade_sintese: GridContainer = %GradeSintese
@onready var grade_desmontar: GridContainer = %GradeDesmontar
@onready var botao_fechar: Button = %BotaoFecharForgePanel
@onready var botao_preenchimento: Button = %BotaoPreenchimento
@onready var botao_info_nivel: PanelContainer = %BotaoInfoNivel
@onready var toggle_armazem: Control = %ToggleArmazem
@onready var toggle_trilho: Panel = %ToggleTrilho
@onready var toggle_knob: Panel = %ToggleKnob
@onready var botao_sintetizar: Button = %BotaoSintetizar
@onready var botao_desmontar: Button = %BotaoDesmontar
@onready var botao_aba_sintese: Button = %BotaoAbaSintese
@onready var botao_aba_desmontar: Button = %BotaoAbaDesmontar
@onready var botao_aba_joias: Button = %BotaoAbaJoias
@onready var botao_filtro_forja: Button = %BotaoFiltroForja
@onready var botao_preenchimento_desmonte: Button = %BotaoPreenchimentoDesmonte
@onready var botao_filtro_desmonte: Button = %BotaoFiltroDesmonte
@onready var painel_sintese: VBoxContainer = %PainelSintese
@onready var painel_desmontar: VBoxContainer = %PainelDesmontar
@onready var painel_joias: VBoxContainer = %PainelJoias
@onready var area_joias: HBoxContainer = %AreaJoias
@onready var botao_imbuir: Button = %BotaoImbuir
@onready var label_explicacao: Label = %LabelExplicacaoForgePanel
@onready var label_explicacao_desmontar: Label = %LabelExplicacaoDesmontar
@onready var label_explicacao_joias: Label = %LabelExplicacaoJoias
@onready var label_valor_desmonte: Label = %LabelValorDesmonte
@onready var cabecalho: HBoxContainer = %CabecalhoForgePanel
@onready var corpo_ferraria: Control = %CorpoForgePanel
var _menu: InventoryMenu
var _slots: Array[ItemSlot] = []
var _slots_desmontar: Array[ItemSlot] = []
var _vinculos: Dictionary = {}
var _aba: Aba = Aba.SINTESE
var _filtro_raridade: int = FILTRO_TODOS
var _usar_armazem: bool = false
var _popup_filtro: PopupMenu
var _camada_legenda_info: CanvasLayer
var _caixa_legenda_info: PanelContainer
var slot_joia_alvo: ItemSlot
var slot_joia_gema: ItemSlot


func _ready() -> void:
	hide()
	_create_slots(grade_sintese, _slots, true)
	_create_slots(grade_desmontar, _slots_desmontar, false)
	_create_filter_popup()
	botao_fechar.pressed.connect(close)
	botao_preenchimento.pressed.connect(auto_fill)
	botao_preenchimento_desmonte.pressed.connect(auto_fill_dismantle)
	botao_sintetizar.pressed.connect(synthesize)
	botao_desmontar.pressed.connect(dismantle)
	botao_aba_sintese.pressed.connect(show_tab.bind(Aba.SINTESE))
	botao_aba_desmontar.pressed.connect(show_tab.bind(Aba.DESMONTAR))
	botao_aba_joias.pressed.connect(show_tab.bind(Aba.JOIAS))
	botao_imbuir.pressed.connect(_on_imbue_pressed)
	botao_filtro_forja.pressed.connect(_open_filter.bind(botao_filtro_forja))
	botao_filtro_desmonte.pressed.connect(_open_filter.bind(botao_filtro_desmonte))
	cabecalho.gui_input.connect(_on_header_gui_input)
	gui_input.connect(_on_header_gui_input)
	visibility_changed.connect(_on_info_tooltip_visibility)
	label_explicacao.text = TEXTO_RODAPE
	label_explicacao_desmontar.text = TEXTO_DESMONTE
	label_explicacao_joias.text = TEXTO_JOIAS
	_build_jewelry_area()
	_setup_warehouse_toggle()
	_setup_level_info_button()
	show_tab(Aba.SINTESE)
	_update_filter_buttons()
	_update_state()
	_update_dismantle()
	visibility_changed.connect(_on_visibility_changed)
	resized.connect(_align_forge_background)
	if corpo_ferraria:
		corpo_ferraria.resized.connect(_align_forge_background)
	if painel_sintese:
		painel_sintese.resized.connect(_align_forge_background)
	if painel_desmontar:
		painel_desmontar.resized.connect(_align_forge_background)
	if painel_joias:
		painel_joias.resized.connect(_align_forge_background)


func configure(menu: InventoryMenu) -> void:
	_menu = menu
	for slot in _todos_slots():
		_menu.connect_forge_slot(slot)
	for slot in _jewelry_slots():
		_menu.connect_forge_slot(slot)
	if not _menu.equipment_changed.is_connected(_on_items_changed):
		_menu.equipment_changed.connect(_on_items_changed)


func synthesis_slots() -> Array[ItemSlot]:
	var todos: Array[ItemSlot] = []
	todos.append_array(_slots)
	todos.append_array(_slots_desmontar)
	return todos


func synthesis_only_slots() -> Array[ItemSlot]:
	return _slots


func is_forge_slot(slot: ItemSlot) -> bool:
	return slot in _slots or slot in _slots_desmontar or is_jewelry_slot(slot)


func is_jewelry_slot(slot: ItemSlot) -> bool:
	return slot == slot_joia_alvo or slot == slot_joia_gema


func is_jewelry_target_slot(slot: ItemSlot) -> bool:
	return slot == slot_joia_alvo


func is_jewelry_gem_slot(slot: ItemSlot) -> bool:
	return slot == slot_joia_gema


func can_accept_target_jewelry(item: ItemData) -> bool:
	if item == null or item.is_gem():
		return false
	return item.has_gem_slot() and not item.has_embedded_gem()


func can_accept_gem_jewelry(item: ItemData) -> bool:
	return item != null and item.is_gem()


func is_origin_reserved(origem: ItemSlot) -> bool:
	return _vinculos.values().has(origem)


func reserve_item(origem: ItemSlot, slot_ferraria: ItemSlot) -> bool:
	if _menu == null or origem == null or slot_ferraria == null:
		return false
	if _has_pending_result():
		return false
	if origem.item == null or slot_ferraria.item != null:
		return false
	if origem.reservado_ferraria or is_origin_reserved(origem):
		return false
	if is_jewelry_target_slot(slot_ferraria) and not can_accept_target_jewelry(origem.item):
		_set_jewelry_status("Equipamento lendário+ sem gema imbuída necessário.", Color(1, 0.55, 0.4, 1))
		return false
	if is_jewelry_gem_slot(slot_ferraria) and not can_accept_gem_jewelry(origem.item):
		_set_jewelry_status("Selecione uma gema.", Color(1, 0.55, 0.4, 1))
		return false
	if is_synthesis_slot(slot_ferraria) and not can_accept_in_synthesis(origem.item):
		notify_blocked_category(origem.item)
		return false
	slot_ferraria.set_item(origem.item)
	origem.set_forge_reserved(true)
	_vinculos[slot_ferraria] = origem
	return true


func release_forge_slot(slot_ferraria: ItemSlot) -> void:
	if is_pending_result(slot_ferraria):
		return
	if not _vinculos.has(slot_ferraria):
		slot_ferraria.set_item(null)
		return
	var origem: ItemSlot = _vinculos[slot_ferraria]
	_vinculos.erase(slot_ferraria)
	slot_ferraria.set_item(null)
	if origem and is_instance_valid(origem):
		origem.set_forge_reserved(false)


func release_all() -> void:
	for slot in _todos_slots():
		release_forge_slot(slot)


func swap_reservations(a: ItemSlot, b: ItemSlot) -> void:
	var origem_a: ItemSlot = _vinculos.get(a)
	var origem_b: ItemSlot = _vinculos.get(b)
	var item_a := a.item
	var item_b := b.item
	a.set_item(item_b)
	b.set_item(item_a)
	if origem_a:
		_vinculos[b] = origem_a
	else:
		_vinculos.erase(b)
	if origem_b:
		_vinculos[a] = origem_b
	else:
		_vinculos.erase(a)


func consume_reservations(lista: Array[ItemSlot]) -> void:
	for slot_ferraria in lista:
		if is_pending_result(slot_ferraria):
			continue
		var origem: ItemSlot = _vinculos.get(slot_ferraria)
		if origem and is_instance_valid(origem):
			origem.set_item(null)
			origem.set_forge_reserved(false)
		_vinculos.erase(slot_ferraria)
		slot_ferraria.set_item(null)


func is_pending_result(slot: ItemSlot) -> bool:
	return slot == _slots[SLOT_CENTRAL] and slot.item != null and not _vinculos.has(slot)


func _has_pending_result() -> bool:
	return is_pending_result(_slots[SLOT_CENTRAL])


func collect_result_to(destino: ItemSlot = null) -> bool:
	if _menu == null or not _has_pending_result():
		return false
	var central := _slots[SLOT_CENTRAL]
	var item := central.item
	if destino != null:
		if destino.item != null or destino.reservado_ferraria:
			return false
		destino.set_item(item)
		central.set_item(null)
		return true
	if _menu.add_item(item):
		central.set_item(null)
		return true
	return false


func interact_slot(slot: ItemSlot) -> void:
	if is_pending_result(slot):
		if not collect_result_to():
			_set_status("Inventário cheio. Libere espaço para retirar o item.", Color(1, 0.55, 0.4, 1))
		return
	release_forge_slot(slot)


func is_synthesis_slot(slot: ItemSlot) -> bool:
	return slot in _slots


func locked_synthesis_category() -> Variant:
	for slot in _slots:
		if slot.item != null:
			return slot.item.category()
	return null


func can_accept_in_synthesis(item: ItemData) -> bool:
	if item == null:
		return true
	var travada: Variant = locked_synthesis_category()
	if travada == null:
		return true
	return item.category() == travada


func notify_blocked_category(item: ItemData) -> void:
	var travada: Variant = locked_synthesis_category()
	if travada == null or item == null:
		return
	_set_status(
		"Grade travada em %s. Não é possível misturar %s." % [
			ItemData.nome_categoria(travada as ItemData.Categoria),
			ItemData.nome_categoria(item.category()),
		],
		Color(1, 0.55, 0.4, 1)
	)


func first_empty_slot() -> ItemSlot:
	if _aba == Aba.JOIAS:
		return _first_empty_jewelry_slot(null)
	for slot in _slots_for_current_tab():
		if slot.item == null:
			return slot
	return null


func _first_empty_jewelry_slot(item: ItemData) -> ItemSlot:
	if item != null and item.is_gem():
		if slot_joia_gema != null and slot_joia_gema.item == null:
			return slot_joia_gema
	elif item != null and can_accept_target_jewelry(item):
		if slot_joia_alvo != null and slot_joia_alvo.item == null:
			return slot_joia_alvo
	if slot_joia_alvo != null and slot_joia_alvo.item == null:
		return slot_joia_alvo
	if slot_joia_gema != null and slot_joia_gema.item == null:
		return slot_joia_gema
	return null


func _jewelry_slots() -> Array[ItemSlot]:
	var lista: Array[ItemSlot] = []
	if slot_joia_alvo:
		lista.append(slot_joia_alvo)
	if slot_joia_gema:
		lista.append(slot_joia_gema)
	return lista


func is_open() -> bool:
	return visible


func show_tab(aba: Aba) -> void:
	if aba != _aba:
		_clear_tab(_aba)
	_aba = aba
	painel_sintese.visible = aba == Aba.SINTESE
	painel_desmontar.visible = aba == Aba.DESMONTAR
	painel_joias.visible = aba == Aba.JOIAS
	_paint_tab(botao_aba_sintese, aba == Aba.SINTESE)
	_paint_tab(botao_aba_desmontar, aba == Aba.DESMONTAR)
	_paint_tab(botao_aba_joias, aba == Aba.JOIAS)
	_on_items_changed()
	_update_forge_background()


## Alterna a janela. Só abre se o inventário estiver visível.
func toggle() -> void:
	if visible:
		close()
	else:
		open()


func open() -> void:
	if _menu == null or not _menu.visible:
		return
	show()
	_update_state()
	_update_dismantle()
	_update_forge_background()
	panel_open_changed.emit(true)


func close() -> void:
	_hide_info_tooltip()
	_return_items()
	hide()
	panel_open_changed.emit(false)


func auto_fill() -> void:
	if _menu == null:
		return
	if _has_pending_result():
		_set_status("Retire o item do slot central antes de preencher.", Color(1, 0.55, 0.4, 1))
		return
	_return_item_list(_slots)
	var grupo := _find_eligible_group()
	if grupo.is_empty():
		_update_state()
		_set_status(_no_group_message(), Color(1, 0.55, 0.4, 1))
		return
	for i in SLOTS_SINTSE:
		reserve_item(grupo[i], _slots[i])
	_update_state()


func auto_fill_dismantle() -> void:
	if _menu == null:
		return
	_return_item_list(_slots_desmontar)
	var candidatos := _filtered_source_items(false)
	if candidatos.is_empty():
		_update_dismantle()
		label_explicacao_desmontar.text = _no_dismantle_items_message()
		label_explicacao_desmontar.add_theme_color_override("font_color", Color(1, 0.55, 0.4, 1))
		return
	var limite := mini(SLOTS_SINTSE, candidatos.size())
	for i in limite:
		reserve_item(candidatos[i], _slots_desmontar[i])
	_update_dismantle()
	label_explicacao_desmontar.text = "Grade preenchida. Clique em DESMONTAR."
	label_explicacao_desmontar.add_theme_color_override("font_color", Color(0.72, 0.9, 0.7, 1))


func synthesize() -> void:
	if not _receita_valida():
		_update_state()
		_set_status("Coloque 9 itens da mesma raridade e família (equipamento, acessório ou gema).", Color(1, 0.55, 0.4, 1))
		return
	var ingredientes: Array[ItemData] = []
	for slot in _slots:
		ingredientes.append(slot.item)
	var raridade_base := ingredientes[0].raridade
	var chance := ItemData.chance_forja_sucesso(raridade_base)
	var sucesso := randf() <= chance
	var raridade_resultado := ItemData.proxima_raridade(raridade_base) if sucesso else raridade_base
	var resultado := _create_synthesized_item(ingredientes, raridade_resultado)
	consume_reservations(_slots)
	_slots[SLOT_CENTRAL].set_item(resultado)
	_menu.notify_items_changed()
	_update_state()
	if sucesso:
		_set_status(
			"Sucesso! %s (%s, Nv.%d)." % [resultado.nome, resultado.rarity_name(), resultado.nivel_item],
			Color(0.85, 0.78, 0.32, 1)
		)
	else:
		_set_status(
			"Forja falhou (%d%%). Recebeu: %s (%s, Nv.%d). Retire do slot central." % [
				ItemData.chance_forja_sucesso_pct(raridade_base),
				resultado.nome,
				resultado.rarity_name(),
				resultado.nivel_item,
			],
			Color(1, 0.55, 0.4, 1)
		)


func dismantle() -> void:
	var valor := _current_dismantle_value()
	if valor <= 0:
		_update_dismantle()
		label_explicacao_desmontar.text = "Coloque itens na grade para dismantle."
		label_explicacao_desmontar.add_theme_color_override("font_color", Color(1, 0.55, 0.4, 1))
		return
	consume_reservations(_slots_desmontar)
	gold_gained.emit(valor)
	_menu.notify_items_changed()
	_update_dismantle()
	label_explicacao_desmontar.text = "Desmonte concluído: +%d ouro." % valor
	label_explicacao_desmontar.add_theme_color_override("font_color", Color(0.85, 0.78, 0.32, 1))


func _on_visibility_changed() -> void:
	if visible:
		_update_forge_background()


func _update_forge_background() -> void:
	grade_sintese.visible = _aba == Aba.SINTESE
	grade_desmontar.visible = _aba == Aba.DESMONTAR
	if area_joias:
		area_joias.visible = _aba == Aba.JOIAS
	call_deferred("_align_forge_background")


func _current_tab_grid() -> GridContainer:
	if _aba == Aba.SINTESE:
		return grade_sintese
	return grade_desmontar


func _current_tab_slots() -> Array[ItemSlot]:
	return _slots if _aba == Aba.SINTESE else _slots_desmontar


func _current_tab_panel() -> VBoxContainer:
	match _aba:
		Aba.SINTESE:
			return painel_sintese
		Aba.DESMONTAR:
			return painel_desmontar
		Aba.JOIAS:
			return painel_joias
	return painel_sintese


func _align_forge_background() -> void:
	if corpo_ferraria == null:
		return
	var painel := _current_tab_panel()
	if painel and painel.visible:
		var altura_controles := painel.get_combined_minimum_size().y
		if altura_controles > 0.0:
			painel.offset_top = -altura_controles
	var alvo := _grid_area_rect()
	if alvo.size.x < 1.0 or alvo.size.y < 1.0:
		return
	if _aba == Aba.JOIAS:
		_align_jewelry_area(alvo)
		return
	var grade := _current_tab_grid()
	if grade == null:
		return
	var sep_h := float(grade.get_theme_constant("h_separation"))
	var sep_v := float(grade.get_theme_constant("v_separation"))
	var lado_slot := minf(
		(alvo.size.x - sep_h * 2.0) / 3.0,
		(alvo.size.y - sep_v * 2.0) / 3.0
	)
	var slot_size := Vector2.ONE * maxf(1.0, lado_slot)
	for slot in _current_tab_slots():
		slot.custom_minimum_size = slot_size
	grade.reset_size()
	var tam_grade := grade.get_combined_minimum_size()
	if tam_grade.x < 1.0 or tam_grade.y < 1.0:
		return
	grade.position = alvo.position + (alvo.size - tam_grade) * 0.5
	grade.size = tam_grade


func _grid_area_rect() -> Rect2:
	var tam := corpo_ferraria.size
	if tam.x < 1.0 or tam.y < 1.0:
		return Rect2()
	var painel := _current_tab_panel()
	var altura_baixo := 0.0
	if painel and painel.visible:
		altura_baixo = painel.get_combined_minimum_size().y
	var area := Rect2(Vector2.ZERO, Vector2(tam.x, maxf(1.0, tam.y - altura_baixo)))
	var inset := area.size * GRADE_MARGEM
	area.position += inset
	area.size -= inset * 2.0
	return area


func _align_jewelry_area(alvo: Rect2) -> void:
	if area_joias == null or slot_joia_alvo == null or slot_joia_gema == null:
		return
	var separacao := float(area_joias.get_theme_constant("separation"))
	var largura_seta := JOIAS_LARGURA_SETA
	var lado := minf((alvo.size.x - largura_seta - separacao * 2.0) * 0.5, alvo.size.y)
	lado = maxf(1.0, lado)
	var tamanho_slot := Vector2.ONE * lado
	slot_joia_alvo.custom_minimum_size = tamanho_slot
	slot_joia_gema.custom_minimum_size = tamanho_slot
	area_joias.reset_size()
	var tam_area := area_joias.get_combined_minimum_size()
	if tam_area.x < 1.0 or tam_area.y < 1.0:
		return
	area_joias.position = alvo.position + (alvo.size - tam_area) * 0.5
	area_joias.size = tam_area
	var seta := area_joias.get_node_or_null("SetaImbuir")
	if seta:
		seta.custom_minimum_size = Vector2(JOIAS_LARGURA_SETA, lado)
		seta.queue_redraw()


func _build_jewelry_area() -> void:
	if area_joias == null:
		return
	for filho in area_joias.get_children():
		filho.queue_free()
	slot_joia_alvo = _create_jewelry_visual_slot("SlotJoiaAlvo", _validate_jewelry_target_drop)
	area_joias.add_child(slot_joia_alvo)
	var seta := Control.new()
	seta.set_script(load("res://presentation/inventory/imbue_arrow.gd"))
	seta.name = "SetaImbuir"
	seta.custom_minimum_size = Vector2(JOIAS_LARGURA_SETA, 44)
	area_joias.add_child(seta)
	slot_joia_gema = _create_jewelry_visual_slot("SlotJoiaGema", _validate_jewelry_gem_drop)
	area_joias.add_child(slot_joia_gema)


func _validate_jewelry_target_drop(item: ItemData, origem: ItemSlot = null) -> bool:
	if origem and (origem.reservado_ferraria or is_origin_reserved(origem)):
		return false
	return can_accept_target_jewelry(item)


func _validate_jewelry_gem_drop(item: ItemData, origem: ItemSlot = null) -> bool:
	if origem and (origem.reservado_ferraria or is_origin_reserved(origem)):
		return false
	return can_accept_gem_jewelry(item)


func _create_jewelry_visual_slot(nome: String, validar: Callable) -> ItemSlot:
	var slot := ItemSlot.new()
	slot.name = nome
	slot.custom_minimum_size = TAMANHO_SLOT
	slot.mouse_filter = Control.MOUSE_FILTER_STOP
	slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
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
	slot.configure(icone, ItemData.Tipo.ARMA, true)
	slot.validar_drop_extra = validar
	slot.item_double_clicked.connect(_on_slot_double_clicked)
	if _menu:
		_menu.connect_forge_slot(slot)
	return slot


func _on_imbue_pressed() -> void:
	if _menu == null or slot_joia_alvo == null or slot_joia_gema == null:
		return
	var equipamento := slot_joia_alvo.item
	var gema := slot_joia_gema.item
	if equipamento == null or gema == null:
		_set_jewelry_status("Selecione um equipamento e uma gema.", Color(1, 0.55, 0.4, 1))
		return
	if not can_accept_target_jewelry(equipamento) or not can_accept_gem_jewelry(gema):
		_set_jewelry_status("Equipamento ou gema inválidos para imbuir.", Color(1, 0.55, 0.4, 1))
		return
	var origem_gema: ItemSlot = _vinculos.get(slot_joia_gema)
	if origem_gema == null:
		_set_jewelry_status("Arraste a gema do inventário para o slot.", Color(1, 0.55, 0.4, 1))
		return
	if not equipamento.imbue_gem(gema):
		_set_jewelry_status("Não foi possível imbuir a gema.", Color(1, 0.55, 0.4, 1))
		return
	var origem_equip: ItemSlot = _vinculos.get(slot_joia_alvo)
	origem_gema.set_item(null)
	origem_gema.set_forge_reserved(false)
	_vinculos.erase(slot_joia_gema)
	slot_joia_gema.set_item(null)
	if origem_equip:
		origem_equip.set_forge_reserved(false)
	_vinculos.erase(slot_joia_alvo)
	slot_joia_alvo.set_item(equipamento)
	_menu.notify_items_changed()
	_update_jewelry_state()
	_set_jewelry_status("Gema imbuída com sucesso!", Color(0.85, 0.78, 0.32, 1))


func _set_jewelry_status(texto: String, cor: Color) -> void:
	if label_explicacao_joias:
		label_explicacao_joias.text = texto
		label_explicacao_joias.add_theme_color_override("font_color", cor)


func _update_jewelry_state() -> void:
	if botao_imbuir == null:
		return
	var valido := slot_joia_alvo != null and slot_joia_gema != null
	valido = valido and slot_joia_alvo.item != null and slot_joia_gema.item != null
	if valido:
		valido = can_accept_target_jewelry(slot_joia_alvo.item) and can_accept_gem_jewelry(slot_joia_gema.item)
	botao_imbuir.disabled = not valido
	if slot_joia_alvo != null and slot_joia_alvo.item != null and slot_joia_alvo.item.has_embedded_gem():
		var imbuido: ItemData = slot_joia_alvo.item
		_set_jewelry_status(
			"%s — %s" % [imbuido.nome, imbuido.gem_slot_line()],
			Color(0.85, 0.78, 0.32, 1)
		)
	elif valido:
		var equipamento: ItemData = slot_joia_alvo.item
		var gema: ItemData = slot_joia_gema.item
		_set_jewelry_status(
			"Imbuir %s em %s" % [gema.nome, equipamento.nome],
			Color(0.85, 0.78, 0.32, 1)
		)
	elif slot_joia_alvo == null or slot_joia_gema == null or (slot_joia_alvo.item == null and slot_joia_gema.item == null):
		_set_jewelry_status(TEXTO_JOIAS, Color(0.72, 0.66, 0.52, 1))


func _forge_slot_style() -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.02, 0.02, 0.03, 0.12)
	estilo.border_color = Color(0.72, 0.58, 0.28, 0.35)
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(2)
	return estilo


func _create_slots(grade: GridContainer, destino: Array[ItemSlot], sintese: bool) -> void:
	grade.columns = COLUNAS
	var estilo_slot := _forge_slot_style()
	for stage_index in SLOTS_SINTSE:
		var slot := ItemSlot.new()
		slot.name = "%s_%d" % [grade.name, stage_index + 1]
		slot.custom_minimum_size = TAMANHO_SLOT
		if estilo_slot:
			slot.add_theme_stylebox_override("panel", estilo_slot)
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
		slot.configure(icone, ItemData.Tipo.ARMA, true)
		if sintese:
			slot.validar_drop_extra = _validate_synthesis_drop
		else:
			slot.validar_drop_extra = _validate_dismantle_drop
		slot.item_double_clicked.connect(_on_slot_double_clicked)
		grade.add_child(slot)
		destino.append(slot)


func _validate_synthesis_drop(item: ItemData, origem: ItemSlot = null) -> bool:
	if origem and (origem.reservado_ferraria or is_origin_reserved(origem)):
		return false
	return can_accept_in_synthesis(item)


func _validate_dismantle_drop(item: ItemData, origem: ItemSlot = null) -> bool:
	if origem and (origem.reservado_ferraria or is_origin_reserved(origem)):
		return false
	return item != null


func _on_slot_double_clicked(slot: ItemSlot) -> void:
	if _menu == null or slot.item == null:
		return
	if is_pending_result(slot):
		if collect_result_to():
			_on_items_changed()
		else:
			_set_status("Inventário cheio. Libere espaço para retirar o item.", Color(1, 0.55, 0.4, 1))
		return
	release_forge_slot(slot)
	_on_items_changed()


func _return_items() -> void:
	_store_central_result()
	release_all()


func _store_central_result() -> void:
	if _menu == null or not _has_pending_result():
		return
	if not collect_result_to():
		_set_status("Inventário cheio. O item forjado permanece na grade.", Color(1, 0.55, 0.4, 1))


func _return_item_list(lista: Array[ItemSlot]) -> void:
	for slot in lista:
		release_forge_slot(slot)


func _clear_tab(aba: Aba) -> void:
	match aba:
		Aba.SINTESE:
			_store_central_result()
			_return_item_list(_slots)
		Aba.DESMONTAR:
			_return_item_list(_slots_desmontar)
		Aba.JOIAS:
			_return_item_list(_jewelry_slots())


func _find_eligible_group() -> Array[ItemSlot]:
	var grupos: Dictionary = {}
	for slot in _source_slots():
		if slot.item == null or slot.reservado_ferraria:
			continue
		if ItemData.eh_raridade_maxima(slot.item.raridade):
			continue
		if not _passes_filter(slot.item):
			continue
		var chave := "%d_%d" % [int(slot.item.category()), int(slot.item.raridade)]
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
	var escolhido: Array[ItemSlot] = []
	for i in mini(SLOTS_SINTSE, melhor.size()):
		escolhido.append(melhor[i] as ItemSlot)
	return escolhido


func _receita_valida() -> bool:
	if _has_pending_result():
		return false
	if _slots.size() != SLOTS_SINTSE:
		return false
	var primeiro: ItemData = _slots[0].item
	if primeiro == null or ItemData.eh_raridade_maxima(primeiro.raridade):
		return false
	for slot in _slots:
		if slot.item == null:
			return false
		if slot.item.category() != primeiro.category():
			return false
		if slot.item.raridade != primeiro.raridade:
			return false
	return true


func _create_synthesized_item(ingredientes: Array[ItemData], raridade_alvo: ItemData.Raridade) -> ItemData:
	var base := ingredientes[0]
	if base.category() == ItemData.Categoria.GEMA:
		return _create_synthesized_gem(ingredientes, raridade_alvo)
	var category := base.category()
	var tipo_resultado := _synthesis_result_type(ingredientes, category)
	var soma_dano := 0
	var soma_vida := 0
	var soma_nivel := 0
	var classe := base.required_class
	for item in ingredientes:
		soma_dano += item.dano_bonus
		soma_vida += item.vida_bonus
		soma_nivel += item.nivel_item
		if item.required_class != classe:
			classe = ItemData.RequiredClass.ALL
	var nivel_resultado := _roll_forge_level(ingredientes)
	var nivel_medio := float(soma_nivel) / float(SLOTS_SINTSE)
	var ajuste_nivel := ItemData.multiplicador_nivel_item(nivel_resultado)
	ajuste_nivel /= maxf(0.01, ItemData.multiplicador_nivel_item(int(round(nivel_medio))))
	var resultado := ItemData.new()
	resultado.id = "%s_sint_%d" % [base.id, Time.get_ticks_msec()]
	resultado.nome = _synthesis_result_name(ingredientes, tipo_resultado)
	resultado.tipo = tipo_resultado
	resultado.raridade = raridade_alvo
	resultado.nivel_item = nivel_resultado
	resultado.required_class = classe
	resultado.dano_bonus = maxi(1, int(round(float(soma_dano) / float(SLOTS_SINTSE) * 1.25 * ajuste_nivel)))
	resultado.vida_bonus = maxi(0, int(round(float(soma_vida) / float(SLOTS_SINTSE) * 1.25 * ajuste_nivel)))
	resultado.icone = resultado.generate_icon()
	return resultado


func _create_synthesized_gem(ingredientes: Array[ItemData], raridade_alvo: ItemData.Raridade) -> ItemData:
	var atributo := _synthesis_gem_result_attribute(ingredientes)
	var soma_valor := 0.0
	for item in ingredientes:
		soma_valor += item.valor_gema
	var resultado := ItemData.criar_gema(atributo, raridade_alvo)
	resultado.id = "%s_sint_%d" % [resultado.id, Time.get_ticks_msec()]
	resultado.valor_gema = maxf(0.1, soma_valor / float(SLOTS_SINTSE) * 1.25)
	resultado.icone = resultado.generate_icon()
	return resultado


func _synthesis_gem_result_attribute(ingredientes: Array[ItemData]) -> ItemData.AtributoGema:
	var contagem: Dictionary = {}
	for item in ingredientes:
		var chave := int(item.atributo_gema)
		contagem[chave] = int(contagem.get(chave, 0)) + 1
	var melhor := ingredientes[0].atributo_gema
	var melhor_total := 0
	for chave in contagem.keys():
		var total := int(contagem[chave])
		if total > melhor_total:
			melhor_total = total
			melhor = chave as ItemData.AtributoGema
	return melhor


func _roll_forge_level(ingredientes: Array[ItemData]) -> int:
	if ingredientes.is_empty():
		return ItemData.NIVEIS_ITEM[0]
	var stage_index := randi() % ingredientes.size()
	return ItemData.normalizar_nivel_item(ingredientes[stage_index].nivel_item)


func _level_chances_in_grid() -> Dictionary:
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


func _level_chance_tooltip_text() -> String:
	var chances := _level_chances_in_grid()
	if chances.is_empty():
		return "Coloque itens na grade para ver as chances por nível."
	var niveis: Array = chances.keys()
	niveis.sort()
	var linhas: PackedStringArray = ["Chances de nível no resultado:"]
	for nivel in niveis:
		linhas.append("Nv.%d: %.1f%%" % [int(nivel), float(chances[nivel])])
	if _count_occupied(_slots) < SLOTS_SINTSE:
		linhas.append("")
		linhas.append("Valores com base nos %d itens atuais." % _count_occupied(_slots))
	return "\n".join(linhas)


func _setup_warehouse_toggle() -> void:
	if toggle_armazem == null:
		return
	toggle_armazem.tooltip_text = "Incluir armazém no preenchimento automático"
	if not toggle_armazem.gui_input.is_connected(_on_warehouse_toggle_clicked):
		toggle_armazem.gui_input.connect(_on_warehouse_toggle_clicked)
	_style_warehouse_toggle(_usar_armazem)


func _on_warehouse_toggle_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed:
			_apply_warehouse_toggle(not _usar_armazem)


func _apply_warehouse_toggle(ligado: bool) -> void:
	_usar_armazem = ligado
	_style_warehouse_toggle(ligado)


func _style_warehouse_toggle(ligado: bool) -> void:
	if toggle_trilho == null or toggle_knob == null:
		return
	var raio := int(TAMANHO_TOGGLE_ARMAZEM.y * 0.5)
	var trilho := StyleBoxFlat.new()
	trilho.set_corner_radius_all(raio)
	trilho.set_border_width_all(1)
	if ligado:
		trilho.bg_color = Color(0.26, 0.42, 0.2, 1)
		trilho.border_color = Color(0.62, 0.88, 0.38, 1)
	else:
		trilho.bg_color = Color(0.14, 0.12, 0.1, 1)
		trilho.border_color = Color(0.52, 0.42, 0.24, 1)
	toggle_trilho.add_theme_stylebox_override("panel", trilho)
	var knob := StyleBoxFlat.new()
	knob.set_corner_radius_all(10)
	knob.bg_color = Color(0.92, 0.86, 0.72, 1)
	knob.border_color = Color(0.72, 0.58, 0.28, 1)
	knob.set_border_width_all(1)
	toggle_knob.add_theme_stylebox_override("panel", knob)
	toggle_knob.position = Vector2(25, 3) if ligado else Vector2(3, 3)


func _setup_level_info_button() -> void:
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
	_apply_info_icon_style(false)
	if not botao_info_nivel.mouse_entered.is_connected(_on_icone_info_mouse_entered):
		botao_info_nivel.mouse_entered.connect(_on_icone_info_mouse_entered)
	if not botao_info_nivel.mouse_exited.is_connected(_on_icone_info_mouse_exited):
		botao_info_nivel.mouse_exited.connect(_on_icone_info_mouse_exited)


func _on_icone_info_mouse_entered() -> void:
	_apply_info_icon_style(true)
	_show_info_tooltip()


func _on_icone_info_mouse_exited() -> void:
	_apply_info_icon_style(false)
	_hide_info_tooltip()


func _apply_info_icon_style(hover: bool) -> void:
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


func _on_info_tooltip_visibility() -> void:
	if not visible:
		_hide_info_tooltip()


func _ensure_info_tooltip_box() -> PanelContainer:
	if _camada_legenda_info == null or not is_instance_valid(_camada_legenda_info):
		_camada_legenda_info = CanvasLayer.new()
		_camada_legenda_info.layer = CAMADA_LEGENDA_INFO
		_camada_legenda_info.name = "CamadaLegendaInfoForgePanel"
		get_tree().root.add_child(_camada_legenda_info)
	if _caixa_legenda_info == null or not is_instance_valid(_caixa_legenda_info):
		_caixa_legenda_info = PanelContainer.new()
		_caixa_legenda_info.z_index = Z_INDEX_LEGENDA_INFO
		_caixa_legenda_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_camada_legenda_info.add_child(_caixa_legenda_info)
	return _caixa_legenda_info


func _fill_info_tooltip(caixa: PanelContainer) -> void:
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
	var linhas := _level_chance_tooltip_text().split("\n")
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


func _position_info_tooltip() -> void:
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


func _show_info_tooltip() -> void:
	if botao_info_nivel == null or not is_visible_in_tree():
		return
	var caixa := _ensure_info_tooltip_box()
	_fill_info_tooltip(caixa)
	_position_info_tooltip()
	caixa.show()
	caixa.move_to_front()


func _hide_info_tooltip() -> void:
	if _caixa_legenda_info and is_instance_valid(_caixa_legenda_info):
		_caixa_legenda_info.hide()


func _update_level_info_tooltip() -> void:
	if _caixa_legenda_info == null or not _caixa_legenda_info.visible:
		return
	_fill_info_tooltip(_caixa_legenda_info)
	_position_info_tooltip()


func _synthesis_result_type(ingredientes: Array[ItemData], category: ItemData.Categoria) -> ItemData.Tipo:
	var contagem: Dictionary = {}
	for item in ingredientes:
		if item.category() != category:
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


func _synthesis_result_name(ingredientes: Array[ItemData], tipo: ItemData.Tipo) -> String:
	for item in ingredientes:
		if item.tipo == tipo and item.nome != "":
			return item.nome
	return _default_name_for_type(tipo)


func _default_name_for_type(tipo: ItemData.Tipo) -> String:
	var amostra := ItemData.new()
	amostra.tipo = tipo
	return amostra.type_name()


func _on_items_changed() -> void:
	_update_state()
	_update_dismantle()
	_update_jewelry_state()


func _update_state() -> void:
	if botao_sintetizar == null:
		return
	_update_level_info_tooltip()
	if _has_pending_result():
		botao_sintetizar.disabled = true
		var item := _slots[SLOT_CENTRAL].item
		_set_status(
			"Item pronto: %s (%s, Nv.%d). Retire do slot central." % [item.nome, item.rarity_name(), item.nivel_item],
			Color(0.72, 0.9, 0.7, 1)
		)
		return
	var valida := _receita_valida()
	botao_sintetizar.disabled = not valida
	if valida:
		var amostra: ItemData = _slots[0].item
		var pct := ItemData.chance_forja_sucesso_pct(amostra.raridade)
		_set_status("Chance de sucesso: %d%%" % pct, Color(0.85, 0.78, 0.32, 1))
	elif _count_occupied(_slots) == 0:
		_set_status(TEXTO_RODAPE, Color(0.72, 0.66, 0.52, 1))
	else:
		var travada: Variant = locked_synthesis_category()
		var extra := ""
		if travada != null:
			extra = " Família: %s." % ItemData.nome_categoria(travada as ItemData.Categoria)
		_set_status(
			"%d/9 — mesma raridade e família. Níveis podem ser misturados.%s" % [_count_occupied(_slots), extra],
			Color(0.82, 0.74, 0.55, 1)
		)


func _update_dismantle() -> void:
	if botao_desmontar == null:
		return
	var valor := _current_dismantle_value()
	var ocupados := _count_occupied(_slots_desmontar)
	botao_desmontar.disabled = valor <= 0
	label_valor_desmonte.text = "Valor: %d ouro" % valor
	if ocupados == 0:
		label_explicacao_desmontar.text = TEXTO_DESMONTE
		label_explicacao_desmontar.add_theme_color_override("font_color", Color(0.72, 0.66, 0.52, 1))


func _current_dismantle_value() -> int:
	var total := 0
	for slot in _slots_desmontar:
		if slot.item:
			total += slot.item.dismantle_value()
	return total


func _count_occupied(lista: Array[ItemSlot]) -> int:
	var total := 0
	for slot in lista:
		if slot.item:
			total += 1
	return total


func _slots_for_current_tab() -> Array[ItemSlot]:
	if _aba == Aba.DESMONTAR:
		return _slots_desmontar
	if _aba == Aba.JOIAS:
		return _jewelry_slots()
	return _slots


func _todos_slots() -> Array[ItemSlot]:
	var todos: Array[ItemSlot] = []
	todos.append_array(_slots)
	todos.append_array(_slots_desmontar)
	return todos


func _paint_tab(botao: Button, ativa: bool) -> void:
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


func _set_status(texto: String, cor: Color) -> void:
	if label_explicacao == null:
		return
	label_explicacao.text = texto
	label_explicacao.add_theme_color_override("font_color", cor)


func _source_slots() -> Array[ItemSlot]:
	if _menu == null:
		var vazio: Array[ItemSlot] = []
		return vazio
	var lista: Array[ItemSlot] = []
	lista.append_array(_menu.inventory_slots())
	if _usar_armazem:
		lista.append_array(_menu.warehouse_slots())
	return lista


func _passes_filter(item: ItemData) -> bool:
	if item == null:
		return false
	if _filtro_raridade == FILTRO_TODOS:
		return true
	return int(item.raridade) == _filtro_raridade


func _filtered_source_items(ignorar_lendario: bool) -> Array[ItemSlot]:
	var lista: Array[ItemSlot] = []
	for slot in _source_slots():
		if slot.item == null or slot.reservado_ferraria:
			continue
		if ignorar_lendario and ItemData.eh_raridade_maxima(slot.item.raridade):
			continue
		if _passes_filter(slot.item):
			lista.append(slot)
	return lista


func _create_filter_popup() -> void:
	_popup_filtro = PopupMenu.new()
	_popup_filtro.name = "MenuFiltroRaridade"
	add_child(_popup_filtro)
	var nomes := ItemData.nomes_filtro_ferraria()
	for i in nomes.size():
		_popup_filtro.add_item(nomes[i], i)
	_popup_filtro.id_pressed.connect(_on_filter_selected)


func _open_filter(botao: Button) -> void:
	if _popup_filtro == null or botao == null:
		return
	var pos := botao.get_screen_position()
	_popup_filtro.position = Vector2i(int(pos.x), int(pos.y + botao.size.y))
	_popup_filtro.popup()


func _on_filter_selected(id: int) -> void:
	if id <= 0:
		_filtro_raridade = FILTRO_TODOS
	else:
		_filtro_raridade = id - 1
	_update_filter_buttons()


func _update_filter_buttons() -> void:
	var texto := "Filtro: %s" % _current_filter_name()
	if botao_filtro_forja:
		botao_filtro_forja.text = texto
	if botao_filtro_desmonte:
		botao_filtro_desmonte.text = texto


func _source_items_name() -> String:
	if _usar_armazem:
		return "do inventário e armazém"
	return "do inventário"


func _current_filter_name() -> String:
	if _filtro_raridade == FILTRO_TODOS:
		return "Todos"
	return ItemData.nome_de_raridade(_filtro_raridade as ItemData.Raridade)


func _no_group_message() -> String:
	var origem := _source_items_name()
	if _filtro_raridade == FILTRO_TODOS:
		return "Não há 9 itens da mesma família %s." % origem
	return "Não há 9 itens %s %s." % [_current_filter_name().to_lower(), origem]


func _no_dismantle_items_message() -> String:
	var origem := _source_items_name()
	if _filtro_raridade == FILTRO_TODOS:
		return "Não há itens %s." % origem
	return "Não há itens %s %s." % [_current_filter_name().to_lower(), origem]


func _on_header_gui_input(event: InputEvent) -> void:
	if _menu == null:
		return
	_menu.drag_window_from_event(event)
