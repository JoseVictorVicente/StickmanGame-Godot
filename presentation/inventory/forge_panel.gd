class_name ForgePanel
extends Control
## Painel lateral de forja e desmonte.
## Fica acoplado à direita do inventário e só existe enquanto o menu está aberto.

signal panel_open_changed(is_open: bool)
signal gold_gained(amount: int)

enum Aba { SINTESE, DESMONTAR, JOIAS }

const SYNTHESIS_SLOTS := 9
const SLOT_CENTRAL := 4
const COLUNAS := 3
const SLOT_SIZE := Vector2(44, 44)
const TAMANHO_ICONE_INFO := 28
const WAREHOUSE_TOGGLE_SIZE := Vector2(48, 26)
const GRADE_MARGEM := 0.08
const FILTRO_TODOS := -1
const CAMADA_LEGENDA_INFO := 127
const Z_INDEX_LEGENDA_INFO := 100
const OFFSET_LEGENDA_INFO := Vector2(10, 0)
const GEMS_ARROW_WIDTH := 32.0

@onready var synthesis_grid: GridContainer = %SynthesisGrid
@onready var dismantle_grid: GridContainer = %DismantleGrid
@onready var botao_fechar: Button = %CloseForgeButton
@onready var autofill_button: Button = %AutofillButton
@onready var level_info_button: PanelContainer = %LevelInfoButton
@onready var warehouse_toggle: Control = %WarehouseToggle
@onready var toggle_track: Panel = %ToggleTrack
@onready var toggle_knob: Panel = %ToggleKnob
@onready var synthesize_button: Button = %SynthesizeButton
@onready var dismantle_button: Button = %DismantleButton
@onready var synthesis_tab_button: Button = %SynthesisTabButton
@onready var dismantle_tab_button: Button = %DismantleTabButton
@onready var gems_tab_button: Button = %GemsTabButton
@onready var forge_filter_button: Button = %ForgeFilterButton
@onready var dismantle_autofill_button: Button = %DismantleAutofillButton
@onready var dismantle_filter_button: Button = %DismantleFilterButton
@onready var synthesis_panel: VBoxContainer = %SynthesisPanel
@onready var dismantle_panel: VBoxContainer = %DismantlePanel
@onready var gems_panel: VBoxContainer = %GemsPanel
@onready var gems_area: HBoxContainer = %GemsArea
@onready var imbue_button: Button = %ImbueButton
@onready var explanation_label: Label = %ForgeExplanationLabel
@onready var dismantle_explanation_label: Label = %DismantleExplanationLabel
@onready var gems_explanation_label: Label = %GemsExplanationLabel
@onready var dismantle_value_label: Label = %DismantleValueLabel
@onready var cabecalho: HBoxContainer = %ForgeHeader
@onready var forge_body: Control = %ForgeBody
@onready var title_label: Label = $Conteudo/ForgeHeader/BannerTitulo/Titulo
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
var _forge_service := ForgeService.new()


func _ready() -> void:
	hide()
	_create_slots(synthesis_grid, _slots, true)
	_create_slots(dismantle_grid, _slots_desmontar, false)
	_create_filter_popup()
	botao_fechar.pressed.connect(close)
	autofill_button.pressed.connect(auto_fill)
	dismantle_autofill_button.pressed.connect(auto_fill_dismantle)
	synthesize_button.pressed.connect(synthesize)
	dismantle_button.pressed.connect(dismantle)
	synthesis_tab_button.pressed.connect(show_tab.bind(Aba.SINTESE))
	dismantle_tab_button.pressed.connect(show_tab.bind(Aba.DESMONTAR))
	gems_tab_button.pressed.connect(show_tab.bind(Aba.JOIAS))
	imbue_button.pressed.connect(_on_imbue_pressed)
	forge_filter_button.pressed.connect(_open_filter.bind(forge_filter_button))
	dismantle_filter_button.pressed.connect(_open_filter.bind(dismantle_filter_button))
	cabecalho.gui_input.connect(_on_header_gui_input)
	gui_input.connect(_on_header_gui_input)
	visibility_changed.connect(_on_info_tooltip_visibility)
	LocaleService.locale_changed.connect(_on_locale_changed)
	_update_localized_texts()
	_build_jewelry_area()
	_setup_warehouse_toggle()
	_setup_level_info_button()
	show_tab(Aba.SINTESE)
	_update_filter_buttons()
	_update_state()
	_update_dismantle()
	visibility_changed.connect(_on_visibility_changed)
	resized.connect(_align_forge_background)
	if forge_body:
		forge_body.resized.connect(_align_forge_background)
	if synthesis_panel:
		synthesis_panel.resized.connect(_align_forge_background)
	if dismantle_panel:
		dismantle_panel.resized.connect(_align_forge_background)
	if gems_panel:
		gems_panel.resized.connect(_align_forge_background)


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
	if origem.forge_reserved or is_origin_reserved(origem):
		return false
	if is_jewelry_target_slot(slot_ferraria) and not can_accept_target_jewelry(origem.item):
		_set_jewelry_status(tr(LocaleKeys.FORGE_JEWELRY_NEED_GEAR), Color(1, 0.55, 0.4, 1))
		return false
	if is_jewelry_gem_slot(slot_ferraria) and not can_accept_gem_jewelry(origem.item):
		_set_jewelry_status(tr(LocaleKeys.FORGE_JEWELRY_SELECT_GEM), Color(1, 0.55, 0.4, 1))
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
		if destino.item != null or destino.forge_reserved:
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
			_set_status(tr(LocaleKeys.FORGE_INVENTORY_FULL), Color(1, 0.55, 0.4, 1))
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
	_set_status(tr(LocaleKeys.FORGE_MIXED_CATEGORY) % [
		ItemData.display_name_categoria(travada as ItemData.Category),
		ItemData.display_name_categoria(item.category()),
	], Color(1, 0.55, 0.4, 1))


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
	synthesis_panel.visible = aba == Aba.SINTESE
	dismantle_panel.visible = aba == Aba.DESMONTAR
	gems_panel.visible = aba == Aba.JOIAS
	_style_tab(synthesis_tab_button, aba == Aba.SINTESE)
	_style_tab(dismantle_tab_button, aba == Aba.DESMONTAR)
	_style_tab(gems_tab_button, aba == Aba.JOIAS)
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
		_set_status(tr(LocaleKeys.FORGE_CLEAR_CENTRAL), Color(1, 0.55, 0.4, 1))
		return
	_return_item_list(_slots)
	var grupo := _find_eligible_group()
	if grupo.is_empty():
		_update_state()
		_set_status(_no_group_message(), Color(1, 0.55, 0.4, 1))
		return
	for i in SYNTHESIS_SLOTS:
		reserve_item(grupo[i], _slots[i])
	_update_state()


func auto_fill_dismantle() -> void:
	if _menu == null:
		return
	_return_item_list(_slots_desmontar)
	var candidatos := _filtered_source_items(false)
	if candidatos.is_empty():
		_update_dismantle()
		dismantle_explanation_label.text = _no_dismantle_items_message()
		dismantle_explanation_label.add_theme_color_override("font_color", Color(1, 0.55, 0.4, 1))
		return
	var limite := mini(SYNTHESIS_SLOTS, candidatos.size())
	for i in limite:
		reserve_item(candidatos[i], _slots_desmontar[i])
	_update_dismantle()
	dismantle_explanation_label.text = tr(LocaleKeys.FORGE_DISMANTLE_FILLED)
	dismantle_explanation_label.add_theme_color_override("font_color", Color(0.72, 0.9, 0.7, 1))


func synthesize() -> void:
	if not _receita_valida():
		_update_state()
		_set_status(tr(LocaleKeys.FORGE_RECIPE_INVALID), Color(1, 0.55, 0.4, 1))
		return
	var ingredientes: Array[ItemData] = []
	for slot in _slots:
		ingredientes.append(slot.item)
	var custo := _forge_service.get_cost(ingredientes[0], "synthesis")
	if _menu == null or not _menu.try_spend_gold(custo):
		_set_status(tr(LocaleKeys.FORGE_NOT_ENOUGH_GOLD) % custo, Color(1, 0.55, 0.4, 1))
		return
	var raridade_base := ingredientes[0].rarity
	var chance := ItemData.forge_success_chance(raridade_base)
	var sucesso := randf() <= chance
	var raridade_resultado := ItemData.next_rarity(raridade_base) if sucesso else raridade_base
	var resultado := _create_synthesized_item(ingredientes, raridade_resultado)
	consume_reservations(_slots)
	_slots[SLOT_CENTRAL].set_item(resultado)
	_menu.notify_items_changed()
	_update_state()
	if sucesso:
		_set_status(tr(LocaleKeys.FORGE_SUCCESS) % [resultado.get_display_name(), resultado.rarity_name(), resultado.item_level], Color(0.85, 0.78, 0.32, 1))
	else:
		_set_status(tr(LocaleKeys.FORGE_FAILED) % [
				ItemData.forge_success_chance_pct(raridade_base),
				resultado.get_display_name(),
				resultado.rarity_name(),
				resultado.item_level,
			], Color(1, 0.55, 0.4, 1))


func dismantle() -> void:
	var valor := _current_dismantle_value()
	if valor <= 0:
		_update_dismantle()
		dismantle_explanation_label.text = tr(LocaleKeys.FORGE_DISMANTLE_PLACE)
		dismantle_explanation_label.add_theme_color_override("font_color", Color(1, 0.55, 0.4, 1))
		return
	consume_reservations(_slots_desmontar)
	gold_gained.emit(valor)
	_menu.notify_items_changed()
	_update_dismantle()
	dismantle_explanation_label.text = tr(LocaleKeys.FORGE_DISMANTLE_DONE) % valor
	dismantle_explanation_label.add_theme_color_override("font_color", Color(0.85, 0.78, 0.32, 1))


func _on_visibility_changed() -> void:
	if visible:
		_update_forge_background()


func _update_forge_background() -> void:
	synthesis_grid.visible = _aba == Aba.SINTESE
	dismantle_grid.visible = _aba == Aba.DESMONTAR
	if gems_area:
		gems_area.visible = _aba == Aba.JOIAS
	call_deferred("_align_forge_background")


func _current_tab_grid() -> GridContainer:
	if _aba == Aba.SINTESE:
		return synthesis_grid
	return dismantle_grid


func _current_tab_slots() -> Array[ItemSlot]:
	return _slots if _aba == Aba.SINTESE else _slots_desmontar


func _current_tab_panel() -> VBoxContainer:
	match _aba:
		Aba.SINTESE:
			return synthesis_panel
		Aba.DESMONTAR:
			return dismantle_panel
		Aba.JOIAS:
			return gems_panel
	return synthesis_panel


func _align_forge_background() -> void:
	if forge_body == null:
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
	var tam := forge_body.size
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
	if gems_area == null or slot_joia_alvo == null or slot_joia_gema == null:
		return
	var separacao := float(gems_area.get_theme_constant("separation"))
	var largura_seta := GEMS_ARROW_WIDTH
	var lado := minf((alvo.size.x - largura_seta - separacao * 2.0) * 0.5, alvo.size.y)
	lado = maxf(1.0, lado)
	var tamanho_slot := Vector2.ONE * lado
	slot_joia_alvo.custom_minimum_size = tamanho_slot
	slot_joia_gema.custom_minimum_size = tamanho_slot
	gems_area.reset_size()
	var tam_area := gems_area.get_combined_minimum_size()
	if tam_area.x < 1.0 or tam_area.y < 1.0:
		return
	gems_area.position = alvo.position + (alvo.size - tam_area) * 0.5
	gems_area.size = tam_area
	var seta := gems_area.get_node_or_null("SetaImbuir")
	if seta:
		seta.custom_minimum_size = Vector2(GEMS_ARROW_WIDTH, lado)
		seta.queue_redraw()


func _build_jewelry_area() -> void:
	if gems_area == null:
		return
	for filho in gems_area.get_children():
		filho.queue_free()
	slot_joia_alvo = _create_jewelry_visual_slot("SlotJoiaAlvo", _validate_jewelry_target_drop)
	gems_area.add_child(slot_joia_alvo)
	var seta := Control.new()
	seta.set_script(load("res://presentation/inventory/imbue_arrow.gd"))
	seta.name = "SetaImbuir"
	seta.custom_minimum_size = Vector2(GEMS_ARROW_WIDTH, 44)
	gems_area.add_child(seta)
	slot_joia_gema = _create_jewelry_visual_slot("SlotJoiaGema", _validate_jewelry_gem_drop)
	gems_area.add_child(slot_joia_gema)


func _validate_jewelry_target_drop(item: ItemData, origem: ItemSlot = null) -> bool:
	if origem and (origem.forge_reserved or is_origin_reserved(origem)):
		return false
	return can_accept_target_jewelry(item)


func _validate_jewelry_gem_drop(item: ItemData, origem: ItemSlot = null) -> bool:
	if origem and (origem.forge_reserved or is_origin_reserved(origem)):
		return false
	return can_accept_gem_jewelry(item)


func _create_jewelry_visual_slot(nome: String, validar: Callable) -> ItemSlot:
	var slot := ItemSlot.new()
	slot.name = nome
	slot.custom_minimum_size = SLOT_SIZE
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
	slot.configure(icone, ItemData.Type.WEAPON, true)
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
		_set_jewelry_status(tr(LocaleKeys.FORGE_JEWELRY_SELECT_BOTH), Color(1, 0.55, 0.4, 1))
		return
	if not can_accept_target_jewelry(equipamento) or not can_accept_gem_jewelry(gema):
		_set_jewelry_status(tr(LocaleKeys.FORGE_JEWELRY_INVALID), Color(1, 0.55, 0.4, 1))
		return
	var custo := _forge_service.get_cost(equipamento, "imbue")
	if not _menu.try_spend_gold(custo):
		_set_jewelry_status(tr(LocaleKeys.FORGE_NOT_ENOUGH_GOLD) % custo, Color(1, 0.55, 0.4, 1))
		return
	var origem_gema: ItemSlot = _vinculos.get(slot_joia_gema)
	if origem_gema == null:
		_set_jewelry_status(tr(LocaleKeys.FORGE_JEWELRY_DRAG_GEM), Color(1, 0.55, 0.4, 1))
		return
	if not equipamento.imbue_gem(gema):
		_set_jewelry_status(tr(LocaleKeys.FORGE_JEWELRY_FAILED), Color(1, 0.55, 0.4, 1))
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
	_set_jewelry_status(tr(LocaleKeys.FORGE_JEWELRY_SUCCESS), Color(0.85, 0.78, 0.32, 1))


func _set_jewelry_status(texto: String, cor: Color) -> void:
	if gems_explanation_label:
		gems_explanation_label.text = texto
		gems_explanation_label.add_theme_color_override("font_color", cor)


func _update_jewelry_state() -> void:
	if imbue_button == null:
		return
	var valido := slot_joia_alvo != null and slot_joia_gema != null
	valido = valido and slot_joia_alvo.item != null and slot_joia_gema.item != null
	if valido:
		valido = can_accept_target_jewelry(slot_joia_alvo.item) and can_accept_gem_jewelry(slot_joia_gema.item)
	imbue_button.disabled = not valido
	if slot_joia_alvo != null and slot_joia_alvo.item != null and slot_joia_alvo.item.has_embedded_gem():
		var imbuido: ItemData = slot_joia_alvo.item
		_set_jewelry_status(
			"%s — %s" % [imbuido.get_display_name(), imbuido.gem_slot_line()],
			Color(0.85, 0.78, 0.32, 1)
		)
	elif valido:
		var equipamento: ItemData = slot_joia_alvo.item
		var gema: ItemData = slot_joia_gema.item
		var custo := _forge_service.get_cost(equipamento, "imbue")
		_set_jewelry_status(
			"%s %s" % [
				tr(LocaleKeys.FORGE_JEWELRY_IMBUE) % [gema.get_display_name(), equipamento.get_display_name()],
				tr(LocaleKeys.FORGE_COST) % custo,
			],
			Color(0.85, 0.78, 0.32, 1)
		)
	elif slot_joia_alvo == null or slot_joia_gema == null or (slot_joia_alvo.item == null and slot_joia_gema.item == null):
		_set_jewelry_status(tr(LocaleKeys.FORGE_GEMS_HINT), Color(0.72, 0.66, 0.52, 1))


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
	for stage_index in SYNTHESIS_SLOTS:
		var slot := ItemSlot.new()
		slot.name = "%s_%d" % [grade.name, stage_index + 1]
		slot.custom_minimum_size = SLOT_SIZE
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
		slot.configure(icone, ItemData.Type.WEAPON, true)
		if sintese:
			slot.validar_drop_extra = _validate_synthesis_drop
		else:
			slot.validar_drop_extra = _validate_dismantle_drop
		slot.item_double_clicked.connect(_on_slot_double_clicked)
		grade.add_child(slot)
		destino.append(slot)


func _validate_synthesis_drop(item: ItemData, origem: ItemSlot = null) -> bool:
	if origem and (origem.forge_reserved or is_origin_reserved(origem)):
		return false
	return can_accept_in_synthesis(item)


func _validate_dismantle_drop(item: ItemData, origem: ItemSlot = null) -> bool:
	if origem and (origem.forge_reserved or is_origin_reserved(origem)):
		return false
	return item != null


func _on_slot_double_clicked(slot: ItemSlot) -> void:
	if _menu == null or slot.item == null:
		return
	if is_pending_result(slot):
		if collect_result_to():
			_on_items_changed()
		else:
			_set_status(tr(LocaleKeys.FORGE_INVENTORY_FULL), Color(1, 0.55, 0.4, 1))
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
		_set_status(tr(LocaleKeys.FORGE_INVENTORY_FULL_FORGE), Color(1, 0.55, 0.4, 1))


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
		if slot.item == null or slot.forge_reserved:
			continue
		if ItemData.is_max_rarity(slot.item.rarity):
			continue
		if not _passes_filter(slot.item):
			continue
		var chave := "%d_%d" % [int(slot.item.category()), int(slot.item.rarity)]
		if not grupos.has(chave):
			var nova: Array = []
			grupos[chave] = nova
		var grupo_atual: Array = grupos[chave] as Array
		grupo_atual.append(slot)
		grupos[chave] = grupo_atual
	var melhor: Array = []
	for chave in grupos.keys():
		var grupo: Array = grupos[chave] as Array
		if grupo.size() >= SYNTHESIS_SLOTS and grupo.size() > melhor.size():
			melhor = grupo
	var escolhido: Array[ItemSlot] = []
	for i in mini(SYNTHESIS_SLOTS, melhor.size()):
		escolhido.append(melhor[i] as ItemSlot)
	return escolhido


func _receita_valida() -> bool:
	if _has_pending_result():
		return false
	if _slots.size() != SYNTHESIS_SLOTS:
		return false
	var primeiro: ItemData = _slots[0].item
	if primeiro == null or ItemData.is_max_rarity(primeiro.rarity):
		return false
	for slot in _slots:
		if slot.item == null:
			return false
		if slot.item.category() != primeiro.category():
			return false
		if slot.item.rarity != primeiro.rarity:
			return false
	return true


func _create_synthesized_item(ingredientes: Array[ItemData], raridade_alvo: ItemData.Rarity) -> ItemData:
	var base := ingredientes[0]
	if base.category() == ItemData.Category.GEM:
		return _create_synthesized_gem(ingredientes, raridade_alvo)
	var category := base.category()
	var tipo_resultado := _synthesis_result_type(ingredientes, category)
	var soma_dano := 0
	var soma_vida := 0
	var soma_nivel := 0
	var classe := base.required_class
	for item in ingredientes:
		soma_dano += item.damage_bonus
		soma_vida += item.hp_bonus
		soma_nivel += item.item_level
		if item.required_class != classe:
			classe = ItemData.RequiredClass.ALL
	var nivel_resultado := _roll_forge_level(ingredientes)
	var nivel_medio := float(soma_nivel) / float(SYNTHESIS_SLOTS)
	var ajuste_nivel := ItemData.item_level_multiplier(nivel_resultado)
	ajuste_nivel /= maxf(0.01, ItemData.item_level_multiplier(int(round(nivel_medio))))
	var resultado := ItemData.new()
	resultado.id = "%s_sint_%d" % [base.id, Time.get_ticks_msec()]
	resultado.display_name = _synthesis_result_name(ingredientes, tipo_resultado)
	resultado.item_type = tipo_resultado
	resultado.rarity = raridade_alvo
	resultado.item_level = nivel_resultado
	resultado.required_class = classe
	resultado.damage_bonus = maxi(1, int(round(float(soma_dano) / float(SYNTHESIS_SLOTS) * 1.25 * ajuste_nivel)))
	resultado.hp_bonus = maxi(0, int(round(float(soma_vida) / float(SYNTHESIS_SLOTS) * 1.25 * ajuste_nivel)))
	resultado.icone = resultado.generate_icon()
	return resultado


func _create_synthesized_gem(ingredientes: Array[ItemData], raridade_alvo: ItemData.Rarity) -> ItemData:
	var atributo := _synthesis_gem_result_attribute(ingredientes)
	var soma_valor := 0.0
	for item in ingredientes:
		soma_valor += item.gem_value
	var resultado := ItemData.create_gem(atributo, raridade_alvo)
	resultado.id = "%s_sint_%d" % [resultado.id, Time.get_ticks_msec()]
	resultado.gem_value = maxf(0.1, soma_valor / float(SYNTHESIS_SLOTS) * 1.25)
	resultado.icone = resultado.generate_icon()
	return resultado


func _synthesis_gem_result_attribute(ingredientes: Array[ItemData]) -> ItemData.GemAttribute:
	var contagem: Dictionary = {}
	for item in ingredientes:
		var chave := int(item.gem_attribute)
		contagem[chave] = int(contagem.get(chave, 0)) + 1
	var melhor := ingredientes[0].gem_attribute
	var melhor_total := 0
	for chave in contagem.keys():
		var total := int(contagem[chave])
		if total > melhor_total:
			melhor_total = total
			melhor = chave as ItemData.GemAttribute
	return melhor


func _roll_forge_level(ingredientes: Array[ItemData]) -> int:
	if ingredientes.is_empty():
		return ItemData.ITEM_LEVELS[0]
	var stage_index := randi() % ingredientes.size()
	return ItemData.normalize_item_level(ingredientes[stage_index].item_level)


func _level_chances_in_grid() -> Dictionary:
	var contagem: Dictionary = {}
	var total := 0
	for slot in _slots:
		if slot.item == null:
			continue
		var nivel := slot.item.item_level
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
		return tr(LocaleKeys.FORGE_LEVEL_HINT_EMPTY)
	var linhas: PackedStringArray = [tr(LocaleKeys.FORGE_LEVEL_HINT_TITLE)]
	var niveis: Array = chances.keys()
	niveis.sort()
	for nivel in niveis:
		linhas.append(tr(LocaleKeys.FORGE_LEVEL_HINT_ROW) % [int(nivel), float(chances[nivel])])
	if _count_occupied(_slots) < SYNTHESIS_SLOTS:
		linhas.append("")
		linhas.append(tr(LocaleKeys.FORGE_LEVEL_HINT_PARTIAL) % _count_occupied(_slots))
	return "\n".join(linhas)


func _setup_warehouse_toggle() -> void:
	if warehouse_toggle == null:
		return
	warehouse_toggle.tooltip_text = tr(LocaleKeys.FORGE_WAREHOUSE_TOGGLE)
	if not warehouse_toggle.gui_input.is_connected(_on_warehouse_toggle_clicked):
		warehouse_toggle.gui_input.connect(_on_warehouse_toggle_clicked)
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
	if toggle_track == null or toggle_knob == null:
		return
	var raio := int(WAREHOUSE_TOGGLE_SIZE.y * 0.5)
	var trilho := StyleBoxFlat.new()
	trilho.set_corner_radius_all(raio)
	trilho.set_border_width_all(1)
	if ligado:
		trilho.bg_color = Color(0.26, 0.42, 0.2, 1)
		trilho.border_color = Color(0.62, 0.88, 0.38, 1)
	else:
		trilho.bg_color = Color(0.14, 0.12, 0.1, 1)
		trilho.border_color = Color(0.52, 0.42, 0.24, 1)
	toggle_track.add_theme_stylebox_override("panel", trilho)
	var knob := StyleBoxFlat.new()
	knob.set_corner_radius_all(10)
	knob.bg_color = Color(0.92, 0.86, 0.72, 1)
	knob.border_color = Color(0.72, 0.58, 0.28, 1)
	knob.set_border_width_all(1)
	toggle_knob.add_theme_stylebox_override("panel", knob)
	toggle_knob.position = Vector2(25, 3) if ligado else Vector2(3, 3)


func _setup_level_info_button() -> void:
	if level_info_button == null:
		return
	level_info_button.custom_minimum_size = Vector2(TAMANHO_ICONE_INFO, TAMANHO_ICONE_INFO)
	level_info_button.mouse_filter = Control.MOUSE_FILTER_STOP
	level_info_button.tooltip_text = ""
	for margem in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		level_info_button.add_theme_constant_override(margem, 0)
	for filho in level_info_button.get_children():
		filho.queue_free()
	var centro := CenterContainer.new()
	centro.name = "CentroInfo"
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_info_button.add_child(centro)
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
	if not level_info_button.mouse_entered.is_connected(_on_icone_info_mouse_entered):
		level_info_button.mouse_entered.connect(_on_icone_info_mouse_entered)
	if not level_info_button.mouse_exited.is_connected(_on_icone_info_mouse_exited):
		level_info_button.mouse_exited.connect(_on_icone_info_mouse_exited)


func _on_icone_info_mouse_entered() -> void:
	_apply_info_icon_style(true)
	_show_info_tooltip()


func _on_icone_info_mouse_exited() -> void:
	_apply_info_icon_style(false)
	_hide_info_tooltip()


func _apply_info_icon_style(hover: bool) -> void:
	if level_info_button == null:
		return
	var raio := TAMANHO_ICONE_INFO / 2
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.18, 0.15, 0.13, 1) if hover else Color(0.14, 0.12, 0.1, 1)
	estilo.border_color = Color(0.9, 0.76, 0.38, 1) if hover else Color(0.72, 0.58, 0.28, 1)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(raio)
	estilo.set_content_margin_all(0)
	level_info_button.add_theme_stylebox_override("panel", estilo)


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
	if _caixa_legenda_info == null or level_info_button == null:
		return
	_caixa_legenda_info.reset_size()
	var tam := _caixa_legenda_info.get_combined_minimum_size()
	if _caixa_legenda_info.size.x > tam.x or _caixa_legenda_info.size.y > tam.y:
		tam = _caixa_legenda_info.size
	_caixa_legenda_info.size = tam
	var icone := level_info_button.get_global_rect()
	var pos := Vector2(
		icone.position.x - tam.x - OFFSET_LEGENDA_INFO.x,
		icone.position.y + (icone.size.y - tam.y) * 0.5
	)
	var viewport := get_viewport().get_visible_rect()
	pos.x = clampf(pos.x, viewport.position.x + 4.0, maxf(viewport.position.x + 4.0, viewport.end.x - tam.x - 4.0))
	pos.y = clampf(pos.y, viewport.position.y + 4.0, maxf(viewport.position.y + 4.0, viewport.end.y - tam.y - 4.0))
	_caixa_legenda_info.global_position = pos


func _show_info_tooltip() -> void:
	if level_info_button == null or not is_visible_in_tree():
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


func _synthesis_result_type(ingredientes: Array[ItemData], category: ItemData.Category) -> ItemData.Type:
	var contagem: Dictionary = {}
	for item in ingredientes:
		if item.category() != category:
			continue
		var chave := int(item.item_type)
		contagem[chave] = int(contagem.get(chave, 0)) + 1
	var melhor_tipo := ingredientes[0].item_type
	var melhor_total := 0
	for chave in contagem.keys():
		var total := int(contagem[chave])
		if total > melhor_total:
			melhor_total = total
			melhor_tipo = chave as ItemData.Type
	return melhor_tipo


func _synthesis_result_name(ingredientes: Array[ItemData], tipo: ItemData.Type) -> String:
	for item in ingredientes:
		if item.item_type == tipo and item.display_name != "":
			return item.display_name
	return _default_name_for_type(tipo)


func _default_name_for_type(tipo: ItemData.Type) -> String:
	var amostra := ItemData.new()
	amostra.item_type = tipo
	return amostra.type_name()


func _on_items_changed() -> void:
	_update_state()
	_update_dismantle()
	_update_jewelry_state()


func _update_state() -> void:
	if synthesize_button == null:
		return
	_update_level_info_tooltip()
	if _has_pending_result():
		synthesize_button.disabled = true
		var item := _slots[SLOT_CENTRAL].item
		_set_status(
			tr(LocaleKeys.FORGE_ITEM_READY) % [item.get_display_name(), item.rarity_name(), item.item_level],
			Color(0.72, 0.9, 0.7, 1)
		)
		return
	var valida := _receita_valida()
	synthesize_button.disabled = not valida
	if valida:
		var amostra: ItemData = _slots[0].item
		var pct := ItemData.forge_success_chance_pct(amostra.rarity)
		var custo := _forge_service.get_cost(amostra, "synthesis")
		_set_status(
			"%s %s" % [tr(LocaleKeys.FORGE_SUCCESS_CHANCE) % pct, tr(LocaleKeys.FORGE_COST) % custo],
			Color(0.85, 0.78, 0.32, 1)
		)
	elif _count_occupied(_slots) == 0:
		_set_status(tr(LocaleKeys.FORGE_SYNTHESIS_HINT), Color(0.72, 0.66, 0.52, 1))
	else:
		var travada: Variant = locked_synthesis_category()
		var extra := ""
		if travada != null:
			extra = " " + tr(LocaleKeys.FORGE_FAMILY_LOCKED) % ItemData.display_name_categoria(travada as ItemData.Category)
		_set_status(tr(LocaleKeys.FORGE_PROGRESS) % [_count_occupied(_slots), extra], Color(0.82, 0.74, 0.55, 1))


func _update_dismantle() -> void:
	if dismantle_button == null:
		return
	var valor := _current_dismantle_value()
	var ocupados := _count_occupied(_slots_desmontar)
	dismantle_button.disabled = valor <= 0
	dismantle_value_label.text = tr(LocaleKeys.FORGE_DISMANTLE_VALUE) % valor
	if ocupados == 0:
		dismantle_explanation_label.text = tr(LocaleKeys.FORGE_DISMANTLE_HINT)
		dismantle_explanation_label.add_theme_color_override("font_color", Color(0.72, 0.66, 0.52, 1))


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


func _style_tab(botao: Button, ativa: bool) -> void:
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
	if explanation_label == null:
		return
	explanation_label.text = texto
	explanation_label.add_theme_color_override("font_color", cor)


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
	return int(item.rarity) == _filtro_raridade


func _filtered_source_items(ignorar_lendario: bool) -> Array[ItemSlot]:
	var lista: Array[ItemSlot] = []
	for slot in _source_slots():
		if slot.item == null or slot.forge_reserved:
			continue
		if ignorar_lendario and ItemData.is_max_rarity(slot.item.rarity):
			continue
		if _passes_filter(slot.item):
			lista.append(slot)
	return lista


func _create_filter_popup() -> void:
	_popup_filtro = PopupMenu.new()
	_popup_filtro.name = "MenuFiltroRaridade"
	add_child(_popup_filtro)
	var nomes := ItemData.forge_filter_names()
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
	var texto := tr(LocaleKeys.FORGE_FILTER) % _current_filter_name()
	if forge_filter_button:
		forge_filter_button.text = texto
	if dismantle_filter_button:
		dismantle_filter_button.text = texto


func _source_items_name() -> String:
	if _usar_armazem:
		return tr(LocaleKeys.FORGE_SOURCE_BOTH)
	return tr(LocaleKeys.FORGE_SOURCE_INVENTORY)


func _current_filter_name() -> String:
	if _filtro_raridade == FILTRO_TODOS:
		return tr(LocaleKeys.RARITY_ALL)
	return ItemData.rarity_display_name(_filtro_raridade as ItemData.Rarity)


func _no_group_message() -> String:
	var origem := _source_items_name()
	if _filtro_raridade == FILTRO_TODOS:
		return tr(LocaleKeys.FORGE_NO_GROUP) % origem
	return tr(LocaleKeys.FORGE_NO_GROUP_FILTER) % [_current_filter_name().to_lower(), origem]


func _no_dismantle_items_message() -> String:
	var origem := _source_items_name()
	if _filtro_raridade == FILTRO_TODOS:
		return tr(LocaleKeys.FORGE_NO_DISMANTLE) % origem
	return tr(LocaleKeys.FORGE_NO_DISMANTLE_FILTER) % [_current_filter_name().to_lower(), origem]


func refresh_locale() -> void:
	_update_localized_texts()
	_rebuild_filter_popup()
	_update_filter_buttons()
	_update_state()
	_update_dismantle()
	_update_jewelry_state()


func _update_localized_texts() -> void:
	if title_label:
		title_label.text = tr(LocaleKeys.FORGE_TITLE).to_upper()
	if botao_fechar:
		botao_fechar.text = tr(LocaleKeys.BTN_CLOSE)
	if synthesis_tab_button:
		synthesis_tab_button.text = tr(LocaleKeys.FORGE_TAB_SYNTHESIS)
	if dismantle_tab_button:
		dismantle_tab_button.text = tr(LocaleKeys.FORGE_TAB_DISMANTLE)
	if gems_tab_button:
		gems_tab_button.text = tr(LocaleKeys.FORGE_TAB_GEMS)
	if autofill_button:
		autofill_button.text = tr(LocaleKeys.FORGE_AUTOFILL)
	if dismantle_autofill_button:
		dismantle_autofill_button.text = tr(LocaleKeys.FORGE_AUTOFILL)
	if synthesize_button:
		synthesize_button.text = tr(LocaleKeys.FORGE_SYNTHESIZE)
	if dismantle_button:
		dismantle_button.text = tr(LocaleKeys.FORGE_DISMANTLE)
	if imbue_button:
		imbue_button.text = tr(LocaleKeys.FORGE_IMBUE)
	if explanation_label and _count_occupied(_slots) == 0 and not _has_pending_result():
		explanation_label.text = tr(LocaleKeys.FORGE_SYNTHESIS_HINT)
	if dismantle_explanation_label and _count_occupied(_slots_desmontar) == 0:
		dismantle_explanation_label.text = tr(LocaleKeys.FORGE_DISMANTLE_HINT)
	if gems_explanation_label and (slot_joia_alvo == null or slot_joia_gema == null or (slot_joia_alvo.item == null and slot_joia_gema.item == null)):
		gems_explanation_label.text = tr(LocaleKeys.FORGE_GEMS_HINT)


func _rebuild_filter_popup() -> void:
	if _popup_filtro == null:
		return
	_popup_filtro.clear()
	var nomes := ItemData.forge_filter_names()
	for i in nomes.size():
		_popup_filtro.add_item(nomes[i], i)


func _on_locale_changed(_locale_code: String) -> void:
	if is_open():
		refresh_locale()


func _on_header_gui_input(event: InputEvent) -> void:
	if _menu == null:
		return
	_menu.drag_window_from_event(event)
