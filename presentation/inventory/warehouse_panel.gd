class_name WarehousePanel
extends Control
## Painel lateral de armazém, à esquerda do inventário.
## Várias abas; só a primeira começa desbloqueada.

signal panel_open_changed(is_open: bool)

const ABAS := 8
const COLUNAS_ABAS := 4
const PAGINAS_ARVORE := 3
const INDICE_PRIMEIRA_PAGINA_EXTRA := 4
const COLUNAS := 5
const LINHAS := 8
const SLOT_SIZE := Vector2(42, 42)
const WAREHOUSE_GRID_SCENE := preload("res://presentation/inventory/warehouse_slots_grid.tscn")

@onready var cabecalho: HBoxContainer = %WarehouseHeader
@onready var botao_fechar: Button = %CloseWarehouseButton
@onready var tab_row: GridContainer = %TabRow
@onready var warehouse_grid: GridContainer = %WarehouseGrid
@onready var status_label: Label = %WarehouseStatusLabel
@onready var sort_button: Button = %SortWarehouseButton
@onready var title_label: Label = $Margem/Conteudo/WarehouseHeader/BannerTitulo/Titulo

var _menu: InventoryMenu
var _slots_por_aba: Array = []
var _botoes_aba: Array[Button] = []
var _aba_atual: int = 0
var _unlocked_tabs: Array[bool] = []


func _ready() -> void:
	hide()
	_initialize_unlocks()
	_wire_tabs()
	_wire_grids()
	botao_fechar.pressed.connect(close)
	cabecalho.gui_input.connect(_on_header_gui_input)
	gui_input.connect(_on_header_gui_input)
	_setup_sort_button()
	LocaleService.locale_changed.connect(_on_locale_changed)
	show_tab(0)


func configure(menu: InventoryMenu) -> void:
	_menu = menu
	for lista in _slots_por_aba:
		for slot in lista:
			_menu.connect_forge_slot(slot)


func is_open() -> bool:
	return visible


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func open() -> void:
	if _menu == null or not _menu.visible:
		return
	show()
	panel_open_changed.emit(true)


func close() -> void:
	hide()
	panel_open_changed.emit(false)


func first_empty_slot() -> ItemSlot:
	if not _unlocked_tabs[_aba_atual]:
		return null
	for slot in _slots_for_tab(_aba_atual):
		if slot.item == null:
			return slot
	return null


func all_slots() -> Array[ItemSlot]:
	var todos: Array[ItemSlot] = []
	for lista in _slots_por_aba:
		for slot in lista:
			todos.append(slot)
	return todos


func show_tab(stage_index: int) -> void:
	if stage_index < 0 or stage_index >= ABAS:
		return
	if not _unlocked_tabs[stage_index]:
		status_label.text = tr(LocaleKeys.UI_WAREHOUSE_TAB_LOCKED) % (stage_index + 1)
		if sort_button:
			sort_button.disabled = true
		return
	_aba_atual = stage_index
	for i in ABAS:
		var grade: GridContainer = warehouse_grid.get_node("GradeAba_%d" % i)
		grade.visible = i == stage_index
		_style_tab(_botoes_aba[i], i == stage_index, _unlocked_tabs[i])
	status_label.text = tr(LocaleKeys.UI_WAREHOUSE_N) % (stage_index + 1)
	if sort_button:
		sort_button.disabled = false


func _setup_sort_button() -> void:
	if sort_button == null:
		return
	InterfaceIcons.setup_icon_button(sort_button, "res://sprites/ui/sort_inventory.png")
	sort_button.pressed.connect(_on_sort_button_pressed)


func _on_sort_button_pressed() -> void:
	if not _unlocked_tabs[_aba_atual]:
		return
	InventoryMenu.sort_slots(_slots_for_tab(_aba_atual))
	if _menu:
		_menu.notify_items_changed()
	sort_button.release_focus()


func unlock_tab(stage_index: int) -> void:
	if stage_index < 0 or stage_index >= ABAS:
		return
	if stage_index >= 1 and stage_index <= PAGINAS_ARVORE:
		return
	_set_tab_state(stage_index, true)


func apply_skill_tree_unlocks(indices: Array[int]) -> void:
	for stage_index in range(1, PAGINAS_ARVORE + 1):
		_set_tab_state(stage_index, stage_index in indices)
	if not _unlocked_tabs[_aba_atual]:
		show_tab(0)


func _set_tab_state(stage_index: int, desbloqueada: bool) -> void:
	if stage_index < 0 or stage_index >= ABAS:
		return
	_unlocked_tabs[stage_index] = desbloqueada
	if stage_index >= _botoes_aba.size():
		return
	var botao := _botoes_aba[stage_index]
	botao.disabled = not desbloqueada
	botao.text = str(stage_index + 1) if desbloqueada else "🔒"
	_style_tab(botao, stage_index == _aba_atual, desbloqueada)


func _initialize_unlocks() -> void:
	_unlocked_tabs.clear()
	for i in ABAS:
		_unlocked_tabs.append(i == 0)


func serialize() -> Dictionary:
	var tabs: Array = []
	for lista in _slots_por_aba:
		var items: Array = []
		for slot in lista:
			items.append(slot.item.to_dictionary() if slot.item else {})
		tabs.append(items)
	return {
		"unlocked": _unlocked_tabs.duplicate(),
		"tabs": tabs,
	}


func apply(dados: Variant) -> void:
	if dados is Array:
		_apply_item_list(_slots_for_tab(0), dados)
		return
	if not (dados is Dictionary):
		return
	var flags: Variant = dados.get("unlocked", [])
	if flags is Array:
		for i in range(INDICE_PRIMEIRA_PAGINA_EXTRA, mini(flags.size(), ABAS)):
			_unlocked_tabs[i] = bool(flags[i])
			_set_tab_state(i, _unlocked_tabs[i])
	var tabs: Variant = dados.get("tabs", dados.get("abas", []))
	if tabs is Array:
		for i in mini(tabs.size(), ABAS):
			if tabs[i] is Array:
				_apply_item_list(_slots_for_tab(i), tabs[i])
	show_tab(_aba_atual)


func _wire_tabs() -> void:
	tab_row.columns = COLUNAS_ABAS
	_collect_tab_buttons()
	assert(_botoes_aba.size() == ABAS, "warehouse TabRow should bake %d tab buttons" % ABAS)
	if not tab_row.has_meta("_tabs_wired"):
		for i in _botoes_aba.size():
			_botoes_aba[i].pressed.connect(show_tab.bind(i))
		tab_row.set_meta("_tabs_wired", true)
	for i in _botoes_aba.size():
		_style_tab(_botoes_aba[i], i == _aba_atual, _unlocked_tabs[i])


func _wire_grids() -> void:
	warehouse_grid.columns = 1
	_collect_grid_slots()
	assert(_slots_por_aba.size() == ABAS, "warehouse grid should bake %d tab grids" % ABAS)


func _collect_tab_buttons() -> void:
	_botoes_aba.clear()
	for filho in tab_row.get_children():
		if filho is Button:
			_botoes_aba.append(filho as Button)


func _collect_grid_slots() -> void:
	_slots_por_aba.clear()
	for i in ABAS:
		var grade := warehouse_grid.get_node_or_null("GradeAba_%d" % i) as WarehouseSlotsGrid
		if grade == null:
			continue
		var lista := grade.slots()
		if lista.is_empty():
			lista = grade.ensure_slots(SLOT_SIZE)
		_slots_por_aba.append(lista)


func _slots_for_tab(stage_index: int) -> Array[ItemSlot]:
	var saida: Array[ItemSlot] = []
	if stage_index < 0 or stage_index >= _slots_por_aba.size():
		return saida
	for slot in _slots_por_aba[stage_index]:
		saida.append(slot)
	return saida


func _apply_item_list(slots: Array[ItemSlot], lista: Array) -> void:
	for i in slots.size():
		var item: ItemData = null
		if i < lista.size() and lista[i] is Dictionary:
			item = ItemData.from_dictionary(lista[i])
		slots[i].set_item(item)


func _style_tab(botao: Button, ativa: bool, desbloqueada: bool) -> void:
	var estilo := StyleBoxFlat.new()
	estilo.content_margin_left = 6
	estilo.content_margin_top = 6
	estilo.content_margin_right = 6
	estilo.content_margin_bottom = 6
	estilo.set_corner_radius_all(4)
	estilo.set_border_width_all(1)
	if not desbloqueada:
		estilo.bg_color = Color(0.1, 0.09, 0.08, 1)
		estilo.border_color = Color(0.32, 0.28, 0.22, 1)
		botao.add_theme_color_override("font_color", Color(0.5, 0.46, 0.4, 1))
	elif ativa:
		estilo.bg_color = Color(0.32, 0.24, 0.16, 1)
		estilo.border_color = Color(0.95, 0.78, 0.32, 1)
		botao.add_theme_color_override("font_color", Color(1, 0.92, 0.72, 1))
	else:
		estilo.bg_color = Color(0.18, 0.14, 0.11, 1)
		estilo.border_color = Color(0.62, 0.5, 0.28, 1)
		botao.add_theme_color_override("font_color", Color(0.95, 0.88, 0.7, 1))
	botao.add_theme_stylebox_override("normal", estilo)
	botao.add_theme_stylebox_override("hover", estilo)
	botao.add_theme_stylebox_override("disabled", estilo)


func refresh_locale() -> void:
	_update_localized_texts()
	show_tab(_aba_atual)


func _update_localized_texts() -> void:
	if title_label:
		title_label.text = tr(LocaleKeys.UI_WAREHOUSE).to_upper()
	if botao_fechar:
		botao_fechar.text = tr(LocaleKeys.BTN_CLOSE)
		botao_fechar.tooltip_text = tr(LocaleKeys.BTN_BACK_INVENTORY)
	if sort_button:
		sort_button.tooltip_text = tr(LocaleKeys.BTN_SORT)


func _on_locale_changed(_locale_code: String) -> void:
	_update_localized_texts()
	if is_open():
		show_tab(_aba_atual)


func _on_header_gui_input(event: InputEvent) -> void:
	if _menu == null:
		return
	_menu.drag_window_from_event(event)
