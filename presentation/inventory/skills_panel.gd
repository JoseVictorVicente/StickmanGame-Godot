class_name SkillsPanel
extends PanelContainer
## Painel dedicado ao equipamento de skills dos heróis.

signal panel_open_changed(is_open: bool)
signal slot_selected(stage_index: int)

const TAMANHO_SLOT_EQUIPADO := Vector2(120, 64)
const TAMANHO_SLOT_HABILIDADE := Vector2(64, 64)

@onready var botao_fechar: Button = %CloseSkillsButton
@onready var cabecalho: HBoxContainer = %SkillsHeader
@onready var hero_slots: HBoxContainer = %HeroSkillSlots
@onready var hero_skills_label: Label = %HeroSkillsLabel
@onready var equipped_section: VBoxContainer = %EquippedSection
@onready var active_section: VBoxContainer = %ActiveSkillsSection
@onready var passive_section: VBoxContainer = %PassiveSkillsSection
@onready var equipped_active_grid: GridContainer = %EquippedActiveGrid
@onready var equipped_passive_grid: GridContainer = %EquippedPassiveGrid
@onready var _equipped_active_nodes: Array[Button] = [%EquippedActiveSlot0, %EquippedActiveSlot1]
@onready var _equipped_passive_nodes: Array[Button] = [%EquippedPassiveSlot0, %EquippedPassiveSlot1]
@onready var active_grid: SkillsActiveGrid = %ActiveGrid
@onready var passive_grid: SkillsPassiveGrid = %PassiveGrid
@onready var _hero_slot_nodes: Array[Button] = [%HeroSkillSlot0, %HeroSkillSlot1, %HeroSkillSlot2]
@onready var title_label: Label = $Conteudo/SkillsHeader/BannerTitulo/Titulo
@onready var hero_title_label: Label = $Conteudo/TituloHeroi
@onready var equipped_active_title: Label = $Conteudo/SkillsPanelCorpo/RolagemSkills/ConteudoSkills/EquippedSection/LinhaEquipadas/ColunaEquipAtivas/TituloEquipAtivas
@onready var equipped_passive_title: Label = $Conteudo/SkillsPanelCorpo/RolagemSkills/ConteudoSkills/EquippedSection/LinhaEquipadas/ColunaEquipPassivas/TituloEquipPassivas
@onready var available_title: Label = $Conteudo/SkillsPanelCorpo/RolagemSkills/ConteudoSkills/TituloDisponiveis
@onready var available_active_title: Label = $Conteudo/SkillsPanelCorpo/RolagemSkills/ConteudoSkills/ActiveSkillsSection/TituloAtivas
@onready var available_passive_title: Label = $Conteudo/SkillsPanelCorpo/RolagemSkills/ConteudoSkills/PassiveSkillsSection/TituloPassivas

var _menu: InventoryMenu
var _party: PartyService
var _slot_alvo: int = 0
var _hero_buttons: Array[Button] = []
var _slots_equipados_ativos: Array[Button] = []
var _slots_equipados_passivos: Array[Button] = []
var _slots_ativos: Array[TextureButton] = []
var _slots_passivos: Array[Button] = []
var _slot_ativo_selecionado: int = 0
var _slot_passivo_selecionado: int = 0
var _equipped_grids_built: bool = false


func _ready() -> void:
	hide()
	botao_fechar.pressed.connect(close)
	cabecalho.gui_input.connect(_on_header_gui_input)
	gui_input.connect(_on_header_gui_input)
	_wire_equipped_slot_buttons()
	_wire_skill_grids()
	_wire_hero_selector()
	_build_equipped_grids()
	if not HeroEquipment.equipment_changed.is_connected(_on_equipment_changed):
		HeroEquipment.equipment_changed.connect(_on_equipment_changed)
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


func open(
	slot_heroi: int = -1,
	tipo_slot: SkillResource.Type = SkillResource.Type.ACTIVE,
	indice_slot: int = 0
) -> void:
	if _menu == null or not _menu.visible:
		return
	if slot_heroi >= 0:
		_slot_alvo = slot_heroi
	elif _party != null and not (_party.active_party[_slot_alvo] is ClassData):
		_slot_alvo = _party.first_occupied_slot()
	set_equipment_slot(tipo_slot, indice_slot)
	show()
	update()
	panel_open_changed.emit(true)
	call_deferred("_enforce_layout")


func set_equipment_slot(tipo: SkillResource.Type, stage_index: int) -> void:
	if tipo == SkillResource.Type.ACTIVE:
		_slot_ativo_selecionado = clampi(stage_index, 0, HeroEquipment.MAX_ACTIVE - 1)
	else:
		_slot_passivo_selecionado = clampi(stage_index, 0, HeroEquipment.MAX_PASSIVE - 1)


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
	_refresh_hero_selector()
	_update_header()
	_update_skills_ui()


func _wire_skill_grids() -> void:
	if active_grid:
		_slots_ativos = active_grid.setup(Callable(self, "_connect_active_slot"))
	if passive_grid:
		_slots_passivos = passive_grid.setup(Callable(self, "_connect_passive_slot"))


func _wire_hero_selector() -> void:
	_hero_buttons = _hero_slot_nodes.duplicate()
	for i in PartyService.SLOTS:
		if i >= _hero_buttons.size():
			continue
		var botao := _hero_buttons[i]
		if botao.get_meta(&"hero_selector_wired", false):
			continue
		botao.pressed.connect(_on_hero_slot_pressed.bind(i))
		botao.set_meta(&"hero_selector_wired", true)


func _connect_active_slot(slot: TextureButton) -> void:
	slot.pressed.connect(_on_available_active_pressed.bind(slot))
	SkillTooltip.vincular(slot, func() -> SkillResource:
		var skill: Variant = slot.get_meta("skill", null)
		return skill if skill is SkillResource else null
	)


func _connect_passive_slot(slot: Button) -> void:
	slot.pressed.connect(_on_available_skill_pressed.bind(slot))
	SkillTooltip.vincular(slot, func() -> SkillResource:
		var skill: Variant = slot.get_meta("skill", null)
		return skill if skill is SkillResource else null
	)


func _build_equipped_grids() -> void:
	if _equipped_grids_built:
		return
	_bind_equipped_slots()
	_equipped_grids_built = true


func _wire_equipped_slot_buttons() -> void:
	if has_meta("_equipped_slots_wired"):
		return
	for stage_index in HeroEquipment.MAX_ACTIVE:
		_equipped_active_nodes[stage_index].pressed.connect(_on_active_slot_pressed.bind(stage_index))
	for stage_index in HeroEquipment.MAX_PASSIVE:
		_equipped_passive_nodes[stage_index].pressed.connect(_on_passive_slot_pressed.bind(stage_index))
	set_meta("_equipped_slots_wired", true)


func _bind_equipped_slots() -> void:
	_slots_equipados_ativos.clear()
	_slots_equipados_passivos.clear()
	for stage_index in HeroEquipment.MAX_ACTIVE:
		var botao := _equipped_active_nodes[stage_index]
		_configure_equipped_slot_button(botao, stage_index, true)
		_slots_equipados_ativos.append(botao)
	for stage_index in HeroEquipment.MAX_PASSIVE:
		var botao := _equipped_passive_nodes[stage_index]
		_configure_equipped_slot_button(botao, stage_index, false)
		_slots_equipados_passivos.append(botao)


func _configure_equipped_slot_button(botao: Button, stage_index: int, ativo: bool) -> void:
	botao.custom_minimum_size = TAMANHO_SLOT_EQUIPADO
	botao.text = _empty_slot_text()
	botao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	botao.add_theme_font_size_override("font_size", 10)
	botao.set_meta("slot_equipado_ativo", ativo)
	botao.set_meta("slot_equipado_indice", stage_index)
	SkillTooltip.vincular(botao, func() -> SkillResource:
		var classe_id := _get_class_id()
		var tipo := SkillResource.Type.ACTIVE if ativo else SkillResource.Type.PASSIVE
		return HeroEquipment.get_equipped(classe_id, tipo, stage_index)
	)


func _refresh_hero_selector() -> void:
	for i in PartyService.SLOTS:
		if i >= _hero_buttons.size():
			continue
		var botao := _hero_buttons[i]
		var classe: Variant = _party.active_party[i]
		if not (classe is ClassData):
			botao.visible = false
			continue
		var dados := classe as ClassData
		botao.visible = true
		botao.custom_minimum_size = Vector2(72, 82)
		botao.text = dados.get_localized_name()
		botao.icon = dados.character_sprite
		botao.expand_icon = true
		botao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		botao.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		botao.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		botao.alignment = HORIZONTAL_ALIGNMENT_CENTER
		botao.add_theme_constant_override("icon_max_width", 48)
		botao.add_theme_font_size_override("font_size", 9)
		_paint_hero(botao, i == _slot_alvo)


func _update_header() -> void:
	if hero_skills_label == null or _party == null:
		return
	var classe: Variant = _party.active_party[_slot_alvo]
	if classe is ClassData:
		hero_skills_label.text = (classe as ClassData).get_localized_name()
	else:
		hero_skills_label.text = tr(LocaleKeys.SKILLS_NO_HERO)


func _get_class_id() -> String:
	if _party == null:
		return ""
	var classe: Variant = _party.active_party[_slot_alvo]
	if classe is ClassData:
		return (classe as ClassData).id
	return ""


func _on_equipment_changed(_classe_id: String) -> void:
	_update_skills_ui()


func _update_skills_ui() -> void:
	_update_equipped_slots()
	for i in _slots_equipados_ativos.size():
		_paint_equipped_slot(_slots_equipados_ativos[i], _slot_ativo_selecionado == i)
	for i in _slots_equipados_passivos.size():
		_paint_equipped_slot(_slots_equipados_passivos[i], _slot_passivo_selecionado == i)
	_update_available_skills()


func _update_equipped_slots() -> void:
	var classe_id := _get_class_id()
	for i in _slots_equipados_ativos.size():
		_update_slot_text(
			_slots_equipados_ativos[i],
			HeroEquipment.get_equipped(classe_id, SkillResource.Type.ACTIVE, i)
		)
	for i in _slots_equipados_passivos.size():
		_update_slot_text(
			_slots_equipados_passivos[i],
			HeroEquipment.get_equipped(classe_id, SkillResource.Type.PASSIVE, i)
		)


func _update_available_skills() -> void:
	var classe_id := _get_class_id()
	var ativas := HeroEquipment.catalog_skills(classe_id, SkillResource.Type.ACTIVE)
	var passivas := HeroEquipment.catalog_skills(classe_id, SkillResource.Type.PASSIVE)
	for i in _slots_ativos.size():
		var slot := _slots_ativos[i]
		if i >= ativas.size():
			slot.visible = false
			slot.set_meta("skill", null)
			_setup_framed_active_slot(slot, null, classe_id)
			continue
		slot.visible = true
		_setup_framed_active_slot(slot, ativas[i], classe_id)
	for i in _slots_passivos.size():
		var slot := _slots_passivos[i]
		if i >= passivas.size():
			slot.visible = false
			slot.set_meta("skill", null)
			_setup_available_slot(slot, null, classe_id)
			continue
		slot.visible = true
		_setup_available_slot(slot, passivas[i], classe_id)


func _setup_framed_active_slot(slot: TextureButton, skill: SkillResource, classe_id: String) -> void:
	slot.set_meta("skill", skill)
	SkillIcons.apply_to_texture_button(slot, skill, TAMANHO_SLOT_HABILIDADE)
	if skill == null:
		_clear_framed_equipped_highlight(slot)
	elif HeroEquipment.is_equipped(classe_id, skill):
		_paint_framed_equipped_highlight(slot)
	else:
		_clear_framed_equipped_highlight(slot)


func _setup_available_slot(slot: Button, skill: SkillResource, classe_id: String) -> void:
	slot.set_meta("skill", skill)
	if skill == null:
		slot.text = ""
		SkillIcons.apply_to_button(slot, null, TAMANHO_SLOT_HABILIDADE)
		slot.disabled = true
		_paint_available_slot(slot, false)
	else:
		slot.text = ""
		SkillIcons.apply_to_button(slot, skill, TAMANHO_SLOT_HABILIDADE)
		slot.disabled = false
		_paint_available_slot(slot, HeroEquipment.is_equipped(classe_id, skill))


func _update_slot_text(botao: Button, skill: SkillResource) -> void:
	if skill == null:
		botao.text = _empty_slot_text()
		SkillIcons.apply_to_button(botao, null, TAMANHO_SLOT_EQUIPADO)
	else:
		botao.text = ""
		SkillIcons.apply_to_button(botao, skill, TAMANHO_SLOT_EQUIPADO)


func _on_hero_slot_pressed(stage_index: int) -> void:
	_slot_alvo = stage_index
	update()
	slot_selected.emit(stage_index)


func _on_active_slot_pressed(stage_index: int) -> void:
	var classe_id := _get_class_id()
	if HeroEquipment.get_equipped(classe_id, SkillResource.Type.ACTIVE, stage_index) != null:
		HeroEquipment.unequip_skill(classe_id, SkillResource.Type.ACTIVE, stage_index)
		if _menu and _menu.has_method("_update_main_skill_slots"):
			_menu._update_main_skill_slots()
	else:
		_slot_ativo_selecionado = stage_index
	_update_skills_ui()


func _on_passive_slot_pressed(stage_index: int) -> void:
	var classe_id := _get_class_id()
	if HeroEquipment.get_equipped(classe_id, SkillResource.Type.PASSIVE, stage_index) != null:
		HeroEquipment.unequip_skill(classe_id, SkillResource.Type.PASSIVE, stage_index)
		if _menu and _menu.has_method("_update_main_skill_slots"):
			_menu._update_main_skill_slots()
	else:
		_slot_passivo_selecionado = stage_index
	_update_skills_ui()


func _on_available_active_pressed(slot: TextureButton) -> void:
	_on_available_skill_pressed(slot)


func _on_available_skill_pressed(slot: Control) -> void:
	var classe_id := _get_class_id()
	if classe_id == "":
		return
	var skill: Variant = slot.get_meta("skill", null)
	if not (skill is SkillResource):
		return
	var slot_alvo := _slot_ativo_selecionado if skill.type == SkillResource.Type.ACTIVE else _slot_passivo_selecionado
	if HeroEquipment.equip_skill(classe_id, skill, slot_alvo) and _menu and _menu.has_method("_update_main_skill_slots"):
		_menu._update_main_skill_slots()


func _paint_hero(botao: Button, selecionado: bool) -> void:
	var estilo := StyleBoxFlat.new()
	estilo.set_corner_radius_all(4)
	estilo.set_border_width_all(2)
	if selecionado:
		estilo.bg_color = Color(0.22, 0.16, 0.08, 1)
		estilo.border_color = Color(0.95, 0.78, 0.32, 1)
	else:
		estilo.bg_color = Color(0.08, 0.07, 0.06, 1)
		estilo.border_color = Color(0.42, 0.35, 0.24, 1)
	botao.add_theme_stylebox_override("normal", estilo)
	botao.add_theme_stylebox_override("hover", estilo)


func _paint_available_slot(botao: Button, equipada: bool) -> void:
	var estilo := StyleBoxFlat.new()
	estilo.set_corner_radius_all(4)
	estilo.set_border_width_all(2)
	if equipada:
		estilo.bg_color = Color(0.18, 0.24, 0.14, 1)
		estilo.border_color = Color(0.55, 0.82, 0.38, 1)
	else:
		estilo.bg_color = Color(0.1, 0.16, 0.1, 1)
		estilo.border_color = Color(0.35, 0.58, 0.32, 0.85)
	botao.add_theme_stylebox_override("normal", estilo)
	botao.add_theme_stylebox_override("hover", estilo)
	botao.add_theme_stylebox_override("pressed", estilo)
	botao.add_theme_stylebox_override("disabled", estilo)


func _paint_framed_equipped_highlight(botao: Control) -> void:
	var overlay := botao.get_node_or_null("EquippedHighlight") as Panel
	if overlay == null:
		overlay = Panel.new()
		overlay.name = "EquippedHighlight"
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		botao.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0, 0, 0, 0)
	estilo.set_border_width_all(2)
	estilo.border_color = Color(0.95, 0.78, 0.32, 0.95)
	estilo.set_corner_radius_all(4)
	overlay.add_theme_stylebox_override("panel", estilo)
	overlay.show()


func _clear_framed_equipped_highlight(botao: Control) -> void:
	var overlay := botao.get_node_or_null("EquippedHighlight") as Panel
	if overlay != null:
		overlay.hide()


func _paint_equipped_slot(botao: Button, selecionado: bool) -> void:
	var estilo := StyleBoxFlat.new()
	estilo.set_corner_radius_all(4)
	estilo.set_border_width_all(2)
	if selecionado:
		estilo.bg_color = Color(0.22, 0.16, 0.08, 1)
		estilo.border_color = Color(0.95, 0.78, 0.32, 1)
	else:
		estilo.bg_color = Color(0.06, 0.05, 0.04, 1)
		estilo.border_color = Color(0.55, 0.44, 0.26, 1)
	botao.add_theme_stylebox_override("normal", estilo)
	botao.add_theme_stylebox_override("hover", estilo)
	botao.add_theme_stylebox_override("pressed", estilo)


func refresh_locale() -> void:
	_update_localized_texts()
	update()


func _empty_slot_text() -> String:
	return tr(LocaleKeys.SKILLS_EMPTY_SLOT)


func _update_localized_texts() -> void:
	if title_label:
		title_label.text = tr(LocaleKeys.SKILLS_TITLE).to_upper()
	if botao_fechar:
		botao_fechar.text = tr(LocaleKeys.BTN_CLOSE)
	if hero_title_label:
		hero_title_label.text = tr(LocaleKeys.SKILLS_SELECTED_HERO)
	if equipped_active_title:
		equipped_active_title.text = tr(LocaleKeys.SKILLS_ACTIVE)
	if equipped_passive_title:
		equipped_passive_title.text = tr(LocaleKeys.SKILLS_PASSIVE)
	if available_title:
		available_title.text = tr(LocaleKeys.SKILLS_AVAILABLE)
	if available_active_title:
		available_active_title.text = tr(LocaleKeys.SKILLS_ACTIVE)
	if available_passive_title:
		available_passive_title.text = tr(LocaleKeys.SKILLS_PASSIVE)


func _on_locale_changed(_locale_code: String) -> void:
	_update_localized_texts()
	if is_open():
		update()


func _on_header_gui_input(evento: InputEvent) -> void:
	if _menu and _menu.has_method("_on_header_gui_input"):
		_menu._on_header_gui_input(evento)
