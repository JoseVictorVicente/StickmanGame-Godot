class_name SkillsPanel
extends PanelContainer
## Painel dedicado ao equipamento de skills dos heróis.

signal panel_open_changed(is_open: bool)
signal slot_selected(stage_index: int)

const TAMANHO_SLOT_EQUIPADO := Vector2(52, 52)
const TAMANHO_SLOT_INVENTARIO := Vector2(48, 48)
const TAMANHO_HERO_LATERAL := Vector2(56, 56)
const TAMANHO_HERO_CENTRO := Vector2(88, 88)
const MODULO_SELECIONADO := Color(1.12, 1.04, 0.82, 1)
const MODULO_EQUIPADO := Color(0.9, 1.0, 0.9, 1)
const CATEGORIAS_LINHA_ATIVA := [
	LocaleKeys.SKILLS_ROW_ATTACK,
	LocaleKeys.SKILLS_ROW_DEFENSE,
	LocaleKeys.SKILLS_ROW_SUPPORT,
]

@onready var botao_fechar: Button = %CloseSkillsButton
@onready var cabecalho: HBoxContainer = %SkillsHeader
@onready var carrossel: HBoxContainer = %HeroCarousel
@onready var botao_hero_anterior: Button = %PrevHeroButton
@onready var botao_hero_proximo: Button = %NextHeroButton
@onready var retrato_hero_anterior: TextureButton = %PrevHeroPortrait
@onready var retrato_hero_centro: TextureButton = %CenterHeroPortrait
@onready var retrato_hero_proximo: TextureButton = %NextHeroPortrait
@onready var active_section: VBoxContainer = %ActiveSkillsSection
@onready var passive_section: VBoxContainer = %PassiveSkillsSection
@onready var _equipped_active_nodes: Array[TextureButton] = [%EquippedActiveSlot0, %EquippedActiveSlot1]
@onready var _equipped_passive_nodes: Array[TextureButton] = [%EquippedPassiveSlot0, %EquippedPassiveSlot1]
@onready var slot_ultimate: TextureButton = %EquippedUltimateSlot
@onready var active_grid: SkillsActiveGrid = %ActiveGrid
@onready var passive_grid: SkillsPassiveGrid = %PassiveGrid
@onready var title_label: Label = $Conteudo/SkillsHeader/BannerTitulo/Titulo
@onready var active_title: Label = %TituloAtivas
@onready var passive_title: Label = %TituloPassivas
@onready var ultimate_label: Label = %UltimateLabel

var _menu: InventoryMenu
var _party: PartyService
var _selected_class_id: String = ""
var _slots_equipados_ativos: Array[TextureButton] = []
var _slots_equipados_passivos: Array[TextureButton] = []
var _slots_ativos: Array[TextureButton] = []
var _slots_passivos: Array[TextureButton] = []
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
	_wire_hero_carousel()
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
	_sync_selected_class_from_slot(slot_heroi)
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
	_ensure_selected_class()
	_refresh_hero_carousel()
	_update_skills_ui()


func _wire_skill_grids() -> void:
	if active_grid:
		_slots_ativos = active_grid.setup(Callable(self, "_connect_active_slot"))
	if passive_grid:
		_slots_passivos = passive_grid.setup(Callable(self, "_connect_passive_slot"))


func _wire_hero_carousel() -> void:
	if botao_hero_anterior.get_meta(&"carousel_wired", false):
		return
	botao_hero_anterior.pressed.connect(_shift_hero.bind(-1))
	botao_hero_proximo.pressed.connect(_shift_hero.bind(1))
	botao_hero_anterior.set_meta(&"carousel_wired", true)


func _connect_active_slot(slot: TextureButton) -> void:
	slot.pressed.connect(_on_available_active_pressed.bind(slot))
	SkillTooltip.vincular(slot, func() -> SkillResource:
		var skill: Variant = slot.get_meta("skill", null)
		return skill if skill is SkillResource else null
	)


func _connect_passive_slot(slot: TextureButton) -> void:
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
		_configure_equipped_slot_button(botao, stage_index, true, TAMANHO_SLOT_EQUIPADO)
		_slots_equipados_ativos.append(botao)
	for stage_index in HeroEquipment.MAX_PASSIVE:
		var botao := _equipped_passive_nodes[stage_index]
		_configure_equipped_slot_button(botao, stage_index, false, TAMANHO_SLOT_EQUIPADO)
		_slots_equipados_passivos.append(botao)
	SkillIcons.apply_framed_texture_button(slot_ultimate, null, TAMANHO_SLOT_EQUIPADO, true)


func _configure_equipped_slot_button(
	botao: TextureButton,
	stage_index: int,
	ativo: bool,
	slot_size: Vector2
) -> void:
	botao.set_meta("slot_equipado_ativo", ativo)
	botao.set_meta("slot_equipado_indice", stage_index)
	SkillTooltip.vincular(botao, func() -> SkillResource:
		var classe_id := _get_class_id()
		var tipo := SkillResource.Type.ACTIVE if ativo else SkillResource.Type.PASSIVE
		return HeroEquipment.get_equipped(classe_id, tipo, stage_index)
	)


func _hero_catalog() -> Array[ClassData]:
	return ClassData.catalog()


func _catalog_index_for_id(class_id: String) -> int:
	var normalized := ClassData.normalize_id(class_id)
	var catalog := _hero_catalog()
	for i in catalog.size():
		if catalog[i].id == normalized:
			return i
	return 0


func _class_exists_in_catalog(class_id: String) -> bool:
	var normalized := ClassData.normalize_id(class_id)
	for classe in _hero_catalog():
		if classe.id == normalized:
			return true
	return false


func _ensure_selected_class() -> void:
	if _class_exists_in_catalog(_selected_class_id):
		return
	_sync_selected_class_from_slot(-1)


func _sync_selected_class_from_slot(slot_heroi: int) -> void:
	if _party != null and slot_heroi >= 0 and slot_heroi < PartyService.SLOTS:
		var classe_slot: Variant = _party.active_party[slot_heroi]
		if classe_slot is ClassData:
			_selected_class_id = (classe_slot as ClassData).id
			return
	if _menu != null:
		var atual := _menu.get_current_class()
		if atual != null:
			_selected_class_id = atual.id
			return
	var catalog := _hero_catalog()
	if not catalog.is_empty():
		_selected_class_id = catalog[0].id


func _party_slot_for_class(class_id: String) -> int:
	if _party == null:
		return -1
	var normalized := ClassData.normalize_id(class_id)
	for i in PartyService.SLOTS:
		var classe: Variant = _party.active_party[i]
		if classe is ClassData and (classe as ClassData).id == normalized:
			return i
	return -1


func _shift_hero(delta: int) -> void:
	var catalog := _hero_catalog()
	if catalog.is_empty():
		return
	var current_index := _catalog_index_for_id(_selected_class_id)
	var next_index := (current_index + delta) % catalog.size()
	_select_hero_class(catalog[next_index].id)


func _select_hero_class(class_id: String) -> void:
	var normalized := ClassData.normalize_id(class_id)
	if normalized == "":
		return
	if _selected_class_id == normalized:
		_refresh_hero_carousel()
		_update_skills_ui()
		return
	_selected_class_id = normalized
	update()
	var party_slot := _party_slot_for_class(normalized)
	if party_slot >= 0:
		slot_selected.emit(party_slot)


func _refresh_hero_carousel() -> void:
	if carrossel == null:
		return
	var catalog := _hero_catalog()
	var has_heroes := not catalog.is_empty()
	carrossel.visible = has_heroes
	if not has_heroes:
		return

	_ensure_selected_class()
	var current_index := _catalog_index_for_id(_selected_class_id)
	var prev_index := (current_index - 1 + catalog.size()) % catalog.size()
	var next_index := (current_index + 1) % catalog.size()
	var show_neighbors := catalog.size() > 1

	if botao_hero_anterior:
		botao_hero_anterior.visible = show_neighbors
	if botao_hero_proximo:
		botao_hero_proximo.visible = show_neighbors
	if retrato_hero_anterior:
		retrato_hero_anterior.visible = show_neighbors
	if retrato_hero_proximo:
		retrato_hero_proximo.visible = show_neighbors

	_paint_hero_portrait(retrato_hero_centro, catalog[current_index], true)
	if show_neighbors:
		_paint_hero_portrait(retrato_hero_anterior, catalog[prev_index], false)
		_paint_hero_portrait(retrato_hero_proximo, catalog[next_index], false)
		_bind_side_portrait_action(retrato_hero_anterior, catalog[prev_index].id)
		_bind_side_portrait_action(retrato_hero_proximo, catalog[next_index].id)


func _bind_side_portrait_action(botao: TextureButton, class_id: String) -> void:
	if botao == null:
		return
	botao.set_meta(&"class_id", class_id)
	if botao.get_meta(&"side_portrait_wired", false):
		return
	botao.pressed.connect(func() -> void:
		var alvo: String = str(botao.get_meta(&"class_id", ""))
		if alvo != "":
			_select_hero_class(alvo)
	)
	botao.set_meta(&"side_portrait_wired", true)


func _paint_hero_portrait(botao: TextureButton, classe: ClassData, central: bool) -> void:
	if botao == null:
		return
	if classe == null:
		botao.visible = false
		return
	botao.visible = true
	var slot_size := TAMANHO_HERO_CENTRO if central else TAMANHO_HERO_LATERAL
	if botao.has_method("apply_hero"):
		botao.call("apply_hero", classe.character_sprite, slot_size, not central)
	botao.set_meta(&"class_id", classe.id)


func _get_class_id() -> String:
	return ClassData.normalize_id(_selected_class_id)


func _on_equipment_changed(_classe_id: String) -> void:
	_update_skills_ui()


func _update_skills_ui() -> void:
	_refresh_active_row_categories()
	_update_equipped_slots()
	for i in _slots_equipados_ativos.size():
		_paint_equipped_slot(_slots_equipados_ativos[i], _slot_ativo_selecionado == i)
	for i in _slots_equipados_passivos.size():
		_paint_equipped_slot(_slots_equipados_passivos[i], _slot_passivo_selecionado == i)
	_update_available_skills()


func _update_equipped_slots() -> void:
	var classe_id := _get_class_id()
	for i in _slots_equipados_ativos.size():
		_apply_framed_slot(
			_slots_equipados_ativos[i],
			HeroEquipment.get_equipped(classe_id, SkillResource.Type.ACTIVE, i),
			TAMANHO_SLOT_EQUIPADO
		)
	for i in _slots_equipados_passivos.size():
		_apply_framed_slot(
			_slots_equipados_passivos[i],
			HeroEquipment.get_equipped(classe_id, SkillResource.Type.PASSIVE, i),
			TAMANHO_SLOT_EQUIPADO
		)
	SkillIcons.apply_framed_texture_button(slot_ultimate, null, TAMANHO_SLOT_EQUIPADO, true)


func _refresh_active_row_categories() -> void:
	if active_grid == null:
		return
	var type_slots := active_grid.type_slots()
	for i in type_slots.size():
		var chave: String = CATEGORIAS_LINHA_ATIVA[i] if i < CATEGORIAS_LINHA_ATIVA.size() else LocaleKeys.SKILLS_ROW_ATTACK
		var type_slot: Control = type_slots[i]
		if type_slot.has_method("apply_category"):
			type_slot.call("apply_category", tr(chave), SkillsActiveGrid.TYPE_SLOT_SIZE)


func _update_available_skills() -> void:
	var classe_id := _get_class_id()
	var ativas := HeroEquipment.catalog_skills(classe_id, SkillResource.Type.ACTIVE)
	var passivas := HeroEquipment.catalog_skills(classe_id, SkillResource.Type.PASSIVE)
	for i in _slots_ativos.size():
		var slot := _slots_ativos[i]
		slot.visible = true
		var skill: SkillResource = ativas[i] if i < ativas.size() else null
		_setup_inventory_slot(slot, skill, classe_id)
	for i in _slots_passivos.size():
		var slot := _slots_passivos[i]
		if i >= passivas.size():
			slot.visible = false
			slot.set_meta("skill", null)
			continue
		slot.visible = true
		_setup_inventory_slot(slot, passivas[i], classe_id)


func _setup_inventory_slot(slot: TextureButton, skill: SkillResource, classe_id: String) -> void:
	slot.set_meta("skill", skill)
	_apply_framed_slot(slot, skill, TAMANHO_SLOT_INVENTARIO)
	slot.disabled = skill == null
	if skill == null:
		slot.modulate = Color.WHITE
		return
	var equipada := HeroEquipment.is_equipped(classe_id, skill)
	slot.modulate = MODULO_EQUIPADO if equipada else Color.WHITE


func _apply_framed_slot(slot: TextureButton, skill: SkillResource, slot_size: Vector2) -> void:
	SkillIcons.apply_framed_texture_button(slot, skill, slot_size)


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


func _paint_equipped_slot(botao: TextureButton, selecionado: bool) -> void:
	botao.modulate = MODULO_SELECIONADO if selecionado else Color.WHITE


func refresh_locale() -> void:
	_update_localized_texts()
	update()


func _update_localized_texts() -> void:
	if title_label:
		title_label.text = tr(LocaleKeys.SKILLS_TITLE).to_upper()
	if botao_fechar:
		botao_fechar.text = tr(LocaleKeys.BTN_CLOSE)
	if active_title:
		active_title.text = tr(LocaleKeys.SKILLS_ACTIVE).to_upper()
	if passive_title:
		passive_title.text = tr(LocaleKeys.SKILLS_PASSIVE).to_upper()
	if ultimate_label:
		ultimate_label.text = tr(LocaleKeys.SKILLS_ULTIMATE).to_upper()


func _on_locale_changed(_locale_code: String) -> void:
	_update_localized_texts()
	if is_open():
		update()


func _on_header_gui_input(evento: InputEvent) -> void:
	if _menu and _menu.has_method("_on_header_gui_input"):
		_menu._on_header_gui_input(evento)
