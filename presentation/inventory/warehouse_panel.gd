class_name WarehousePanel
extends Control
## Sidecar warehouse to the left of the inventory hub.
## Eight tabs; only the first starts unlocked.

signal panel_open_changed(is_open: bool)

const TAB_COUNT := 8
const SKILL_TREE_PAGES := 3
const FIRST_EXTRA_PAGE_INDEX := 4

@export var style_tab_normal: StyleBoxFlat
@export var style_tab_active: StyleBoxFlat
@export var style_tab_locked: StyleBoxFlat

@onready var header: HBoxContainer = %WarehouseHeader
@onready var close_button: Button = %CloseWarehouseButton
@onready var tab_row: GridContainer = %TabRow
@onready var warehouse_grid: GridContainer = %WarehouseGrid
@onready var sort_button: Button = %SortWarehouseButton
@onready var title_label: Label = %WarehouseTitle

var _menu: InventoryMenu
var _slots_by_tab: Array = []
var _tab_buttons: Array[Button] = []
var _current_tab: int = 0
var _unlocked_tabs: Array[bool] = []


func _ready() -> void:
	hide()
	_initialize_unlocks()
	_wire_tabs()
	_wire_grids()
	close_button.pressed.connect(close)
	header.gui_input.connect(_on_header_gui_input)
	gui_input.connect(_on_header_gui_input)
	sort_button.pressed.connect(_on_sort_button_pressed)
	LocaleService.locale_changed.connect(_on_locale_changed)
	_update_localized_texts()
	show_tab(0)


func configure(menu: InventoryMenu) -> void:
	_menu = menu
	for slot_list in _slots_by_tab:
		for slot in slot_list:
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
	if not _unlocked_tabs[_current_tab]:
		return null
	for slot in _slots_for_tab(_current_tab):
		if slot.item == null:
			return slot
	return null


func all_slots() -> Array[ItemSlot]:
	var every_slot: Array[ItemSlot] = []
	for slot_list in _slots_by_tab:
		for slot in slot_list:
			every_slot.append(slot)
	return every_slot


func show_tab(stage_index: int) -> void:
	if stage_index < 0 or stage_index >= TAB_COUNT:
		return
	if not _unlocked_tabs[stage_index]:
		_set_title_for_tab(stage_index, true)
		sort_button.disabled = true
		return
	_current_tab = stage_index
	for i in TAB_COUNT:
		var grade: GridContainer = warehouse_grid.get_node("GradeAba_%d" % i)
		grade.visible = i == stage_index
		_style_tab(_tab_buttons[i], i == stage_index, _unlocked_tabs[i])
	_set_title_for_tab(stage_index, false)
	sort_button.disabled = false


func unlock_tab(stage_index: int) -> void:
	if stage_index < 0 or stage_index >= TAB_COUNT:
		return
	if stage_index >= 1 and stage_index <= SKILL_TREE_PAGES:
		return
	_set_tab_state(stage_index, true)


func apply_skill_tree_unlocks(indices: Array[int]) -> void:
	for stage_index in range(1, SKILL_TREE_PAGES + 1):
		_set_tab_state(stage_index, stage_index in indices)
	if not _unlocked_tabs[_current_tab]:
		show_tab(0)


func serialize() -> Dictionary:
	var tabs: Array = []
	for slot_list in _slots_by_tab:
		var items: Array = []
		for slot in slot_list:
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
		for i in range(FIRST_EXTRA_PAGE_INDEX, mini(flags.size(), TAB_COUNT)):
			_unlocked_tabs[i] = bool(flags[i])
			_set_tab_state(i, _unlocked_tabs[i])
	var tabs: Variant = dados.get("tabs", dados.get("abas", []))
	if tabs is Array:
		for i in mini(tabs.size(), TAB_COUNT):
			if tabs[i] is Array:
				_apply_item_list(_slots_for_tab(i), tabs[i])
	show_tab(_current_tab)


func refresh_locale() -> void:
	_update_localized_texts()
	show_tab(_current_tab)


func _initialize_unlocks() -> void:
	_unlocked_tabs.clear()
	for i in TAB_COUNT:
		_unlocked_tabs.append(i == 0)


func _set_tab_state(stage_index: int, unlocked: bool) -> void:
	if stage_index < 0 or stage_index >= TAB_COUNT:
		return
	_unlocked_tabs[stage_index] = unlocked
	if stage_index >= _tab_buttons.size():
		return
	var button := _tab_buttons[stage_index]
	button.disabled = not unlocked
	button.text = str(stage_index + 1) if unlocked else "🔒"
	_style_tab(button, stage_index == _current_tab, unlocked)


func _wire_tabs() -> void:
	_collect_tab_buttons()
	assert(_tab_buttons.size() == TAB_COUNT, "warehouse TabRow should bake %d tab buttons" % TAB_COUNT)
	for i in _tab_buttons.size():
		_tab_buttons[i].pressed.connect(show_tab.bind(i))
		_style_tab(_tab_buttons[i], i == _current_tab, _unlocked_tabs[i])


func _wire_grids() -> void:
	_collect_grid_slots()
	assert(_slots_by_tab.size() == TAB_COUNT, "warehouse grid should bake %d tab grids" % TAB_COUNT)


func _collect_tab_buttons() -> void:
	_tab_buttons.clear()
	for child in tab_row.get_children():
		if child is Button:
			_tab_buttons.append(child as Button)


func _collect_grid_slots() -> void:
	_slots_by_tab.clear()
	for i in TAB_COUNT:
		var grade := warehouse_grid.get_node_or_null("GradeAba_%d" % i) as WarehouseSlotsGrid
		assert(grade != null, "warehouse grid should bake GradeAba_%d" % i)
		var slot_list := grade.slots()
		var expected := WarehouseSlotsGrid.COLUMNS * WarehouseSlotsGrid.ROWS
		if slot_list.size() != expected:
			slot_list = grade.ensure_slots(WarehouseSlotsGrid.DEFAULT_SLOT_SIZE)
		assert(
			slot_list.size() == expected,
			"GradeAba_%d should bake %d slots" % [i, expected]
		)
		_slots_by_tab.append(slot_list)


func _slots_for_tab(stage_index: int) -> Array[ItemSlot]:
	var slots: Array[ItemSlot] = []
	if stage_index < 0 or stage_index >= _slots_by_tab.size():
		return slots
	for slot in _slots_by_tab[stage_index]:
		slots.append(slot)
	return slots


func _apply_item_list(slots: Array[ItemSlot], lista: Array) -> void:
	for i in slots.size():
		var item: ItemData = null
		if i < lista.size() and lista[i] is Dictionary:
			item = ItemData.from_dictionary(lista[i])
		slots[i].set_item(item)


func _style_tab(button: Button, active: bool, unlocked: bool) -> void:
	var base: StyleBoxFlat = style_tab_normal
	if not unlocked:
		base = style_tab_locked
		button.add_theme_color_override("font_color", Color(0.5, 0.46, 0.4, 1))
	elif active:
		base = style_tab_active
		button.add_theme_color_override("font_color", Color(1, 0.92, 0.72, 1))
	else:
		button.add_theme_color_override("font_color", Color(0.95, 0.88, 0.7, 1))
	if base == null:
		return
	var style := base.duplicate() as StyleBoxFlat
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("disabled", style)


func _update_localized_texts() -> void:
	close_button.text = tr(LocaleKeys.BTN_CLOSE)
	close_button.tooltip_text = tr(LocaleKeys.BTN_BACK_INVENTORY)
	sort_button.tooltip_text = tr(LocaleKeys.BTN_SORT)
	_set_title_for_tab(_current_tab, not _unlocked_tabs[_current_tab])


func _set_title_for_tab(stage_index: int, locked: bool) -> void:
	if title_label == null:
		return
	var texto: String
	if locked:
		texto = tr(LocaleKeys.UI_WAREHOUSE_TAB_LOCKED) % (stage_index + 1)
	else:
		texto = tr(LocaleKeys.UI_WAREHOUSE_N) % (stage_index + 1)
	title_label.text = texto.to_upper()


func _on_sort_button_pressed() -> void:
	if not _unlocked_tabs[_current_tab]:
		return
	InventoryMenu.sort_slots(_slots_for_tab(_current_tab))
	if _menu:
		_menu.notify_items_changed()
	sort_button.release_focus()


func _on_locale_changed(_locale_code: String) -> void:
	_update_localized_texts()
	if is_open():
		show_tab(_current_tab)


func _on_header_gui_input(event: InputEvent) -> void:
	if _menu == null:
		return
	_menu.drag_window_from_event(event)
