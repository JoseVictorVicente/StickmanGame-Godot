class_name FormationPanel
extends PanelContainer
## Substitui o inventário para montar a equipe em campo.

signal panel_open_changed(is_open: bool)
signal slot_selected(stage_index: int)

@onready var botao_fechar: Button = %CloseFormationButton
@onready var cabecalho: HBoxContainer = %FormationHeader
@onready var party_slots: HBoxContainer = %FormationSlots
@onready var hero_scroll: ScrollContainer = %HeroScroll
@onready var hero_grid: GridContainer = %FormationHeroGrid
@onready var hint_label: Label = %FormationHintLabel
@onready var title_label: Label = $Conteudo/FormationHeader/BannerTitulo/Titulo

var _menu: InventoryMenu
var _party: PartyService
var _slot_alvo: int = 0
var _botoes_slot: Array[Button] = []
var _botoes_retirar: Array[Button] = []
var _hero_buttons: Array[Button] = []


func _ready() -> void:
	hide()
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
	_build_heroes()
	if hint_label:
		if _party.can_remove():
			hint_label.text = tr(LocaleKeys.FORMATION_HINT_CAN_REMOVE)
		else:
			hint_label.text = tr(LocaleKeys.FORMATION_HINT_MIN_ONE)


func _build_slots() -> void:
	for filho in party_slots.get_children():
		filho.queue_free()
	_botoes_slot.clear()
	_botoes_retirar.clear()
	for i in PartyService.SLOTS:
		var caixa := VBoxContainer.new()
		caixa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		caixa.add_theme_constant_override("separation", 4)
		var botao := Button.new()
		botao.custom_minimum_size = Vector2(88, 102)
		botao.clip_text = true
		botao.expand_icon = true
		botao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		botao.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		botao.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		botao.alignment = HORIZONTAL_ALIGNMENT_CENTER
		botao.add_theme_constant_override("icon_max_width", 64)
		botao.add_theme_font_size_override("font_size", 10)
		botao.pressed.connect(_on_slot_pressed.bind(i))
		var classe: Variant = _party.active_party[i]
		if classe is ClassData:
			var dados := classe as ClassData
			botao.icon = dados.character_sprite
			botao.text = dados.get_localized_name()
		else:
			botao.text = tr(LocaleKeys.UI_EMPTY_SLOT)
			botao.disabled = true
		caixa.add_child(botao)
		var retirar := Button.new()
		retirar.text = tr(LocaleKeys.FORMATION_REMOVE)
		retirar.add_theme_font_size_override("font_size", 10)
		retirar.pressed.connect(_on_retirar.bind(i))
		var ocupado := classe is ClassData
		retirar.disabled = not ocupado or not _party.can_remove()
		retirar.tooltip_text = tr(LocaleKeys.FORMATION_REMOVE_BLOCKED) if retirar.disabled and ocupado else tr(LocaleKeys.FORMATION_REMOVE_TOOLTIP)
		caixa.add_child(retirar)
		party_slots.add_child(caixa)
		_botoes_slot.append(botao)
		_botoes_retirar.append(retirar)
		_paint_slot(botao, i == _slot_alvo and ocupado)


func _build_heroes() -> void:
	for filho in hero_grid.get_children():
		filho.queue_free()
	_hero_buttons.clear()
	hero_grid.columns = 3
	for classe in _party.unlocked_classes:
		var botao := Button.new()
		botao.custom_minimum_size = Vector2(86, 98)
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
		botao.pressed.connect(_on_hero_pressed.bind(classe))
		hero_grid.add_child(botao)
		_hero_buttons.append(botao)
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
