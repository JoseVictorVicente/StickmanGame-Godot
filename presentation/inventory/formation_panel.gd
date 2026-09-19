class_name FormationPanel
extends PanelContainer
## Substitui o inventário para montar a equipe em campo.

signal panel_open_changed(is_open: bool)
signal slot_selected(stage_index: int)

@onready var botao_fechar: Button = %CloseFormationButton
@onready var cabecalho: HBoxContainer = %FormationHeader
@onready var party_slots: HBoxContainer = %FormationSlots
@onready var _formation_slot_widgets: Array[FormationPartySlot] = [%FormationSlot0, %FormationSlot1, %FormationSlot2]
@onready var hero_scroll: ScrollContainer = %HeroScroll
@onready var hero_grid: FormationHeroGrid = %FormationHeroGrid
@onready var hint_label: Label = %FormationHintLabel
@onready var title_label: Label = $Conteudo/FormationHeader/BannerTitulo/Titulo
@onready var party_title: Label = %PartyTitle
@onready var heroes_title: Label = %HeroesTitle

var _menu: InventoryMenu
var _party: PartyService
var _slot_alvo: int = 0
var _botoes_slot: Array[Button] = []
var _botoes_retirar: Array[Button] = []
var _hero_buttons: Array[Button] = []


func _ready() -> void:
	hide()
	_wire_formation_slots()
	_wire_hero_buttons()
	botao_fechar.pressed.connect(close)
	cabecalho.gui_input.connect(_on_header_gui_input)
	gui_input.connect(_on_header_gui_input)
	if hero_scroll:
		hero_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		hero_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
		hero_scroll.custom_minimum_size.y = 160
	LocaleService.locale_changed.connect(_on_locale_changed)
	_update_localized_texts()


func configure(menu: InventoryMenu, party: PartyService) -> void:
	_menu = menu
	_party = party
	if _party and not _party.party_changed.is_connected(update):
		_party.party_changed.connect(update)
	update()


func is_open() -> bool:
	return visible


func open() -> void:
	if _menu == null or not _menu.visible:
		return
	show()
	update()
	panel_open_changed.emit(true)
	call_deferred("_enforce_layout")


func _enforce_layout() -> void:
	if visible:
		panel_open_changed.emit(true)


func close() -> void:
	custom_minimum_size = Vector2(580, 0)
	hide()
	panel_open_changed.emit(false)


func update() -> void:
	if _party == null:
		return
	if not (_party.active_party[_slot_alvo] is ClassData):
		_slot_alvo = _party.first_occupied_slot()
	_build_slots()
	_refresh_hero_grid()
	if hint_label:
		if _party.can_remove():
			hint_label.text = tr(LocaleKeys.FORMATION_HINT_CAN_REMOVE)
		else:
			hint_label.text = tr(LocaleKeys.FORMATION_HINT_MIN_ONE)


func _wire_formation_slots() -> void:
	if has_meta("_formation_slots_wired"):
		return
	for i in PartyService.SLOTS:
		var widget := _formation_slot_widgets[i]
		if widget == null:
			continue
		widget.hero_button.pressed.connect(_on_slot_pressed.bind(i))
		widget.remove_button.pressed.connect(_on_retirar.bind(i))
	set_meta("_formation_slots_wired", true)


func _wire_hero_buttons() -> void:
	if hero_grid == null:
		return
	_hero_buttons = hero_grid.setup(Callable(self, "_on_hero_button_ready"))


func _on_hero_button_ready(botao: Button) -> void:
	if botao.get_meta(&"formation_pressed_wired", false):
		return
	var class_id := str(botao.get_meta("class_id", ""))
	if class_id.is_empty():
		return
	botao.pressed.connect(_on_hero_button_pressed.bind(class_id))
	botao.set_meta(&"formation_pressed_wired", true)


func _build_slots() -> void:
	_botoes_slot.clear()
	_botoes_retirar.clear()
	for i in PartyService.SLOTS:
		var widget := _formation_slot_widgets[i]
		if widget == null:
			continue
		var botao := widget.hero_button
		var retirar := widget.remove_button
		var classe: Variant = _party.active_party[i]
		if classe is ClassData:
			var dados := classe as ClassData
			botao.icon = dados.character_sprite
			botao.text = dados.get_localized_name()
			botao.disabled = false
		else:
			botao.icon = null
			botao.text = tr(LocaleKeys.UI_EMPTY_SLOT)
			botao.disabled = true
		retirar.text = tr(LocaleKeys.FORMATION_REMOVE)
		var ocupado := classe is ClassData
		retirar.disabled = not ocupado or not _party.can_remove()
		retirar.tooltip_text = tr(LocaleKeys.FORMATION_REMOVE_BLOCKED) if retirar.disabled and ocupado else tr(LocaleKeys.FORMATION_REMOVE_TOOLTIP)
		_botoes_slot.append(botao)
		_botoes_retirar.append(retirar)
		_paint_slot(botao, i == _slot_alvo and ocupado)


func _refresh_hero_grid() -> void:
	if hero_grid == null or _party == null:
		return
	if _hero_buttons.is_empty():
		_hero_buttons = hero_grid.hero_buttons()
	var unlocked_ids: Dictionary = {}
	for classe in _party.unlocked_classes:
		if classe is ClassData:
			unlocked_ids[(classe as ClassData).id] = classe
	for botao in _hero_buttons:
		var class_id := str(botao.get_meta("class_id", ""))
		var classe: ClassData = unlocked_ids.get(class_id) as ClassData
		if classe == null:
			botao.visible = false
			continue
		botao.visible = true
		botao.text = classe.get_localized_name()
		botao.tooltip_text = classe.get_localized_name()
		botao.icon = classe.character_sprite
		botao.expand_icon = true
		botao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		botao.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		botao.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		botao.alignment = HORIZONTAL_ALIGNMENT_CENTER
		botao.add_theme_constant_override("icon_max_width", 56)
		botao.add_theme_font_size_override("font_size", 10)
		var na_equipe := _party._index_of_class(classe.id) >= 0
		_paint_hero(botao, na_equipe)


func _on_slot_pressed(stage_index: int) -> void:
	if not (_party.active_party[stage_index] is ClassData):
		return
	_slot_alvo = stage_index
	update()
	slot_selected.emit(stage_index)


func _on_retirar(stage_index: int) -> void:
	if _party.remove_from_slot(stage_index):
		_slot_alvo = _party.first_occupied_slot()
		slot_selected.emit(_slot_alvo)


func _on_hero_button_pressed(class_id: String) -> void:
	var classe := _find_unlocked_class(class_id)
	if classe == null:
		return
	_on_hero_pressed(classe)


func _find_unlocked_class(class_id: String) -> ClassData:
	for classe in _party.unlocked_classes:
		if classe is ClassData and (classe as ClassData).id == class_id:
			return classe
	return null


func _on_hero_pressed(classe: ClassData) -> void:
	var ja := _party._index_of_class(classe.id)
	if ja >= 0:
		_slot_alvo = ja
		update()
		slot_selected.emit(ja)
		return
	var colocado := _party.add_class(classe)
	if colocado >= 0:
		_slot_alvo = colocado
		slot_selected.emit(colocado)
		return
	_party.scale_character(_slot_alvo, classe)
	slot_selected.emit(_slot_alvo)


func _paint_slot(botao: Button, ativo: bool) -> void:
	var estilo := StyleBoxFlat.new()
	estilo.set_corner_radius_all(4)
	estilo.set_border_width_all(2)
	if ativo:
		estilo.bg_color = Color(0.22, 0.16, 0.08, 1)
		estilo.border_color = Color(0.95, 0.78, 0.32, 1)
	else:
		estilo.bg_color = Color(0.08, 0.07, 0.06, 1)
		estilo.border_color = Color(0.42, 0.35, 0.24, 1)
	botao.add_theme_stylebox_override("normal", estilo)
	botao.add_theme_stylebox_override("hover", estilo)
	botao.add_theme_stylebox_override("disabled", estilo)


func _paint_hero(botao: Button, na_equipe: bool) -> void:
	var estilo := StyleBoxFlat.new()
	estilo.set_corner_radius_all(4)
	if na_equipe:
		estilo.bg_color = Color(0.22, 0.16, 0.08, 0.7)
		estilo.border_color = Color(0.95, 0.78, 0.32, 1)
		estilo.set_border_width_all(2)
	else:
		estilo.bg_color = Color(0.1, 0.09, 0.08, 1)
		estilo.border_color = Color(0.42, 0.35, 0.24, 1)
		estilo.set_border_width_all(1)
	botao.add_theme_stylebox_override("normal", estilo)
	botao.add_theme_stylebox_override("hover", estilo)


func refresh_locale() -> void:
	_update_localized_texts()
	update()


func _update_localized_texts() -> void:
	if title_label:
		title_label.text = tr(LocaleKeys.FORMATION_TITLE).to_upper()
	if party_title:
		party_title.text = tr(LocaleKeys.FORMATION_PARTY_TITLE)
	if heroes_title:
		heroes_title.text = tr(LocaleKeys.FORMATION_HEROES_TITLE)
	if botao_fechar:
		botao_fechar.text = tr(LocaleKeys.BTN_CLOSE)
	if botao_fechar:
		botao_fechar.tooltip_text = tr(LocaleKeys.BTN_BACK_INVENTORY)


func _on_locale_changed(_locale_code: String) -> void:
	_update_localized_texts()
	if is_open():
		update()


func _on_header_gui_input(evento: InputEvent) -> void:
	if _menu and _menu.has_method("_on_header_gui_input"):
		_menu._on_header_gui_input(evento)
