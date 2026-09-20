class_name InventoryMenu
extends Control
## Painel flutuante de personagem / inventário.
## Abre acima do idle, sem cobrir o botão de 4 quadrados.

signal closed
signal character_changed(stage_index: int)
signal equipment_changed
signal hero_class_changed(stage_index: int, classe: ClassData)
signal window_released
signal gold_gained(amount: int)
signal gold_spent(amount: int)
signal skill_tree_changed
signal menu_width_changed
signal stage_started(world: int, stage: int, difficulty: int)

const EQUIPMENT_GRID_SCENE := preload("res://presentation/inventory/equipment_grid.tscn")
const EQUIP_LEFT_TYPES: Array[ItemData.Type] = [
	ItemData.Type.WEAPON,
	ItemData.Type.OFFHAND,
	ItemData.Type.HELMET,
	ItemData.Type.CHEST,
	ItemData.Type.GLOVES,
	ItemData.Type.PANTS,
	ItemData.Type.BOOTS,
]
const EQUIP_RIGHT_TYPES: Array[ItemData.Type] = [
	ItemData.Type.BELT,
	ItemData.Type.PENDANT,
	ItemData.Type.RING,
	ItemData.Type.BRACELET,
	ItemData.Type.PET,
]
const MARGEM_TOPO_UI := UiConstants.UI_TOP_MARGIN
const COMBAT_RESERVED_SPACE := UiConstants.COMBAT_RESERVED_SPACE
var HERO_SLOTS: Array[Dictionary] = [
	{"name": "Warrior", "hero_class": ItemData.RequiredClass.WARRIOR},
	{"name": "Mage", "hero_class": ItemData.RequiredClass.MAGE},
	{"name": "Archer", "hero_class": ItemData.RequiredClass.ARCHER},
]
var CLASSES: Array[ClassData] = []

@onready var exit_button: Button = %ExitButton
@onready var quit_game_button: Button = %QuitGameButton
@onready var settings_button: Button = %SettingsButton
@onready var settings_panel: PanelContainer = %SettingsPanel
@onready var close_settings_button: Button = %CloseSettingsButton
@onready var slider_volume: HSlider = %VolumeSlider
@onready var label_volume_valor: Label = %VolumeValueLabel
@onready var titulo_config: Label = %SettingsTitle
@onready var label_volume_titulo: Label = %VolumeTitleLabel
@onready var label_language_title: Label = %LabelLanguageTitle
@onready var option_locale: OptionButton = %OptionLocale
@onready var cabecalho: HBoxContainer = %Header
@onready var painel: PanelContainer = %Panel
@onready var conteudo: VBoxContainer = %Conteudo
@onready var hub_upper: VBoxContainer = %HubUpper
@onready var hub_lower: VBoxContainer = %HubLower
@onready var menu_area: HBoxContainer = %MenuArea
@onready var overlay_vbox: VBoxContainer = %OverlayVBox
@onready var top_spacer: Control = %TopSpacer
@onready var bottom_spacer: Control = %BottomSpacer
@onready var forge_panel_node: ForgePanel = %PanelForgePanel
@onready var warehouse_panel_node: WarehousePanel = %WarehousePanel
@onready var worlds_panel_node: WorldsPanel = %WorldsPanel
@onready var formation_panel_node: FormationPanel = %FormationPanel
@onready var skills_panel_node: SkillsPanel = %SkillsPanel
@onready var attributes_panel_node: AttributesPanel = %AttributesPanel
@onready var skill_tree_panel_node: SkillTreePanel = %SkillTreePanel
@onready var area_heroi: HeroSection = %AreaHeroi
@onready var linha_inventario: InventoryRow = %LinhaInventario
@onready var menu_inferior: BottomNav = %MenuInferior

const EMPTY_SKILL_SLOT_TEXT := "+"

var inventory_slots_grid: InventorySlotsGrid
var sort_inventory_button: Button
var equip_left: VBoxContainer
var equip_right: VBoxContainer
var character_row: HBoxContainer
var character_name_label: Label
var character_level_label: Label
var character_portrait: TextureRect
var hero_card_row: HBoxContainer
var active_column: VBoxContainer
var passive_column: VBoxContainer
var slot_ativa_0: Button
var slot_ativa_1: Button
var slot_passiva_0: Button
var slot_passiva_1: Button
var character_xp_bar: ProgressBar
var character_xp_label: Label
var character_attributes_button: Button
var team_ui: TeamSelectionUI
var formation_button: Button
var botao_skills: Button
var botao_inventario: Button
var forge_button: Button
var warehouse_button: Button
var world_button: Button
var gold_label: Label
var gold_panel: Control
var gold_spacer: Control

var _dragging: bool = false
var _offset_mouse: Vector2i = Vector2i.ZERO
var _character_index: int = 0
var _character_buttons: Array[Button] = []
var _left_equipment_by_class: Dictionary = {}
var _right_equipment_by_class: Dictionary = {}
var _inventory_slot_list: Array[ItemSlot] = []
var _slot_selecionado: ItemSlot = null
var _forge_button_styles: Dictionary = {}
var _warehouse_button_styles: Dictionary = {}
var _world_button_styles: Dictionary = {}
var _menus_abaixo: bool = false
var _skill_tree_progress := SkillTreeProgress.new()
var query_gold: Callable
var query_slot_progress: Callable

@export var layout_inventario: InventoryLayout = preload("res://presentation/inventory/inventory_layout_default.tres")


func _ready() -> void:
	CLASSES = ClassData.catalog()
	_bind_hub_references()
	_apply_panel_layout()
	_create_character_equipment()
	_setup_inventory_slots()
	_setup_inventory_sort_button()
	_wire_character_selector()
	exit_button.pressed.connect(_on_exit_button_pressed)
	quit_game_button.pressed.connect(_on_quit_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	close_settings_button.pressed.connect(_close_settings)
	slider_volume.value_changed.connect(_on_volume_changed)
	_setup_locale_selector()
	LocaleService.locale_changed.connect(_on_locale_changed)
	_update_localized_texts()
	settings_button.icon = _gear_icon()
	settings_button.add_theme_constant_override("icon_max_width", 20)
	cabecalho.gui_input.connect(_on_header_gui_input)
	painel.gui_input.connect(_on_header_gui_input)
	forge_panel_node.configure(self)
	warehouse_panel_node.configure(self)
	_sync_warehouse_skill_tree()
	worlds_panel_node.configure(self)
	menu_area.resized.connect(_align_side_panels)
	painel.resized.connect(_align_side_panels)
	forge_button.pressed.connect(_on_forge_button_pressed)
	forge_panel_node.panel_open_changed.connect(_on_forge_visibility_changed)
	warehouse_panel_node.panel_open_changed.connect(_on_warehouse_visibility_changed)
	worlds_panel_node.panel_open_changed.connect(_on_worlds_visibility_changed)
	worlds_panel_node.stage_started.connect(_on_stage_started)
	forge_panel_node.gold_gained.connect(_on_forge_gold_spent)
	visibility_changed.connect(_on_menu_visibility_changed)
	if character_row:
		character_row.visible = false
	_store_forge_button_styles()
	_warehouse_button_styles["normal"] = warehouse_button.get_theme_stylebox("normal").duplicate()
	_warehouse_button_styles["hover"] = warehouse_button.get_theme_stylebox("hover").duplicate()
	_warehouse_button_styles["pressed"] = warehouse_button.get_theme_stylebox("pressed").duplicate()
	_world_button_styles["normal"] = world_button.get_theme_stylebox("normal").duplicate()
	_world_button_styles["hover"] = world_button.get_theme_stylebox("hover").duplicate()
	_world_button_styles["pressed"] = world_button.get_theme_stylebox("pressed").duplicate()
	warehouse_button.pressed.connect(_on_warehouse_button_pressed)
	world_button.pressed.connect(_on_world_button_pressed)
	warehouse_button.icon = load("res://sprites/ui/chest.png")
	warehouse_button.text = ""
	warehouse_button.expand_icon = true
	warehouse_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warehouse_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	warehouse_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	warehouse_button.add_theme_constant_override("icon_max_width", 52)
	warehouse_button.tooltip_text = tr(LocaleKeys.UI_WAREHOUSE)
	_apply_bottom_bar_icons()
	_connect_main_skill_slots()
	if not HeroEquipment.equipment_changed.is_connected(_on_equipment_skills_changed):
		HeroEquipment.equipment_changed.connect(_on_equipment_skills_changed)
	if botao_skills:
		botao_skills.pressed.connect(_on_skills_button_pressed)
	if character_attributes_button:
		character_attributes_button.pressed.connect(_on_attributes_button_pressed)
	if formation_button and not formation_button.pressed.is_connected(_on_formation_requested):
		formation_button.pressed.connect(_on_formation_requested)
	if attributes_panel_node:
		attributes_panel_node.configure(self)
		if not attributes_panel_node.panel_open_changed.is_connected(_on_attributes_visibility_changed):
			attributes_panel_node.panel_open_changed.connect(_on_attributes_visibility_changed)
	if skill_tree_panel_node:
		skill_tree_panel_node.configure(self)
		if not skill_tree_panel_node.panel_open_changed.is_connected(_on_skill_tree_visibility_changed):
			skill_tree_panel_node.panel_open_changed.connect(_on_skill_tree_visibility_changed)
	botao_inventario.pressed.connect(_on_skill_tree_button_pressed)
	if gold_panel:
		gold_panel.resized.connect(_align_gold_spacer)
		_align_gold_spacer()
	call_deferred("_align_gold_spacer")
	_restore_base_panel()
	call_deferred("_align_side_panels")


func _layout() -> InventoryLayout:
	var layout := layout_inventario if layout_inventario else InventoryLayout.new()
	layout.sync_from_base_unit()
	return layout


func _bind_hub_references() -> void:
	inventory_slots_grid = linha_inventario.inventory_grid
	sort_inventory_button = linha_inventario.sort_button
	warehouse_button = linha_inventario.warehouse_button
	formation_button = linha_inventario.formation_button
	botao_skills = menu_inferior.skills_button
	botao_inventario = menu_inferior.inventory_button
	forge_button = menu_inferior.forge_button
	world_button = menu_inferior.world_button
	equip_left = area_heroi.equip_left
	equip_right = area_heroi.equip_right
	character_row = area_heroi.character_row
	character_name_label = area_heroi.character_name_label
	character_level_label = area_heroi.character_level_label
	character_portrait = area_heroi.character_portrait
	hero_card_row = area_heroi.hero_card_row
	active_column = area_heroi.active_column
	passive_column = area_heroi.passive_column
	slot_ativa_0 = area_heroi.slot_ativa_0
	slot_ativa_1 = area_heroi.slot_ativa_1
	slot_passiva_0 = area_heroi.slot_passiva_0
	slot_passiva_1 = area_heroi.slot_passiva_1
	character_xp_bar = area_heroi.character_xp_bar
	character_xp_label = area_heroi.character_xp_label
	character_attributes_button = area_heroi.character_attributes_button
	team_ui = area_heroi.team_ui
	gold_label = area_heroi.gold_label
	gold_panel = area_heroi.gold_panel
	gold_spacer = area_heroi.gold_spacer


func _create_character_equipment() -> void:
	for classe in CLASSES:
		var nome_esq := "EquipLeft_%s" % classe.id
		var nome_dir := "EquipRight_%s" % classe.id
		var esquerda := equip_left.get_node_or_null(nome_esq) as EquipmentGrid
		if esquerda == null:
			esquerda = _create_equipment_grid(nome_esq, EQUIP_LEFT_TYPES)
			equip_left.add_child(esquerda)
		else:
			_bind_equipment_grid(esquerda, EQUIP_LEFT_TYPES)
		esquerda.visible = false
		_left_equipment_by_class[classe.id] = esquerda

		var direita := equip_right.get_node_or_null(nome_dir) as EquipmentGrid
		if direita == null:
			direita = _create_equipment_grid(nome_dir, EQUIP_RIGHT_TYPES)
			equip_right.add_child(direita)
		else:
			_bind_equipment_grid(direita, EQUIP_RIGHT_TYPES)
		direita.visible = false
		_right_equipment_by_class[classe.id] = direita


func _create_equipment_grid(nome_no: String, tipos_slots: Array[ItemData.Type]) -> EquipmentGrid:
	var grade := EQUIPMENT_GRID_SCENE.instantiate() as EquipmentGrid
	grade.name = nome_no
	_bind_equipment_grid(grade, tipos_slots)
	return grade


func _bind_equipment_grid(grade: EquipmentGrid, tipos_slots: Array[ItemData.Type]) -> void:
	var slots := grade.build_slots(tipos_slots, _layout())
	for slot in slots:
		_connect_item_slot(slot)


func _setup_inventory_slots() -> void:
	_inventory_slot_list = inventory_slots_grid.setup(Callable(self, "_connect_item_slot"))


func _apply_panel_layout() -> void:
	var layout := _layout()
	if painel:
		var hub_w := maxf(layout.panel_min_size.x, layout.inventory_row_pixel_size().x + 24.0)
		painel.custom_minimum_size = Vector2(hub_w, layout.panel_min_size.y)
	if conteudo:
		conteudo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_apply_hub_zones(layout)
	if linha_inventario:
		linha_inventario.custom_minimum_size = layout.inventory_row_pixel_size()
	if menu_inferior:
		menu_inferior.custom_minimum_size.y = layout.bottom_bar_height
	if not Engine.is_editor_hint():
		if linha_inventario:
			linha_inventario.visible = true
			linha_inventario.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if menu_inferior:
			menu_inferior.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			menu_inferior.size_flags_vertical = Control.SIZE_SHRINK_END
	if menu_inferior:
		for botao_nav in [botao_skills, botao_inventario, forge_button, world_button]:
			if botao_nav:
				botao_nav.add_theme_font_size_override("font_size", layout.font_nav)
				botao_nav.add_theme_constant_override("icon_max_width", layout.nav_icon_max_width)
	var area_foto := hero_card_row.get_node_or_null("AreaFoto") as Control
	if area_foto:
		area_foto.custom_minimum_size = layout.portrait_min_size
	for botao_skill in [slot_ativa_0, slot_ativa_1, slot_passiva_0, slot_passiva_1]:
		if botao_skill:
			botao_skill.custom_minimum_size = layout.skill_menu_slot_size
	if character_attributes_button:
		character_attributes_button.custom_minimum_size = Vector2(layout.portrait_min_size.x, 26)
	if gold_label:
		gold_label.add_theme_font_size_override("font_size", layout.font_gold)
	if team_ui:
		for i in PartyService.SLOTS:
			var party_slot := team_ui.get_node_or_null("%%PartySlot%d" % i) as Button
			if party_slot:
				party_slot.custom_minimum_size = layout.party_hero_slot_size
	if team_ui:
		team_ui.layout_resource = layout
	if formation_button:
		var grid_w := layout.inventory_grid_pixel_size().x
		formation_button.custom_minimum_size = Vector2(grid_w, float(layout.formation_bar_height))
	if area_heroi:
		area_heroi.apply_layout_offsets(layout)
		area_heroi.size_flags_vertical = Control.SIZE_SHRINK_BEGIN


func _apply_hub_zones(layout: InventoryLayout) -> void:
	if hub_upper == null or hub_lower == null:
		return
	hub_upper.custom_minimum_size.y = layout.hub_upper_band_height()
	hub_upper.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	hub_lower.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hub_lower.clip_contents = true
	if menu_inferior:
		menu_inferior.size_flags_vertical = Control.SIZE_SHRINK_END


func _connect_item_slot(slot: ItemSlot) -> void:
	slot.item_clicked.connect(_on_slot_clicked)
	slot.item_double_clicked.connect(_on_slot_double_clicked)
	slot.item_right_clicked.connect(_on_slot_right_clicked)
	slot.item_dropped.connect(_on_slot_dropped)


func _wire_character_selector() -> void:
	_character_buttons.clear()
	for stage_index in HERO_SLOTS.size():
		var botao := character_row.get_node_or_null("Character_%d" % (stage_index + 1)) as Button
		if botao == null:
			continue
		botao.custom_minimum_size = _layout().character_slot_size
		botao.add_theme_font_size_override("font_size", 11)
		botao.add_theme_color_override("font_color", Color(0.95, 0.88, 0.7, 1))
		botao.add_theme_stylebox_override("pressed", _create_character_style(true))
		botao.pressed.connect(select_character.bind(stage_index))
		_character_buttons.append(botao)
	if _character_buttons.size() > 0:
		select_character(0)


func select_character(stage_index: int) -> void:
	if team_ui and team_ui._party:
		var party: PartyService = team_ui._party
		if stage_index < 0 or stage_index >= PartyService.SLOTS or not (party.active_party[stage_index] is ClassData):
			stage_index = party.first_occupied_slot()
	_character_index = stage_index
	var dados: Dictionary = HERO_SLOTS[stage_index]
	var hero_progress := _progress_for_index(stage_index)
	character_name_label.text = str(dados["name"])
	character_level_label.text = tr(LocaleKeys.UI_LEVEL_SHORT) % int(hero_progress["level"])
	_update_xp_bar()
	if attributes_panel_node and attributes_panel_node.is_open():
		attributes_panel_node.update()
	if skill_tree_panel_node and skill_tree_panel_node.is_open():
		skill_tree_panel_node.update()
	if team_ui:
		team_ui.select_slot(stage_index, false)
	_update_portrait()
	_update_main_skill_slots()

	for i in _character_buttons.size():
		var selecionado := i == stage_index
		var estilo := _create_character_style(selecionado)
		_character_buttons[i].add_theme_stylebox_override("normal", estilo)
		_character_buttons[i].add_theme_stylebox_override("hover", estilo)

	_show_character_equipment(stage_index)
	character_changed.emit(stage_index)
	equipment_changed.emit()


func _show_character_equipment(_indice: int) -> void:
	var id_ativo := _class_id_for_slot(_character_index)
	for id_classe in _left_equipment_by_class.keys():
		var ativo := str(id_classe) == id_ativo
		(_left_equipment_by_class[id_classe] as GridContainer).visible = ativo
		(_right_equipment_by_class[id_classe] as GridContainer).visible = ativo


func current_character_index() -> int:
	return _character_index


func get_equipped_items(stage_index: int = -1) -> Array[ItemData]:
	var items: Array[ItemData] = []
	if stage_index < 0:
		stage_index = _character_index
	var grades := _grids_for_slot(stage_index)
	for grade in grades:
		for filho in grade.get_children():
			var slot := filho as ItemSlot
			if slot == null:
				slot = filho.get_node_or_null("FundoSlot") as ItemSlot
			if slot and slot.item:
				items.append(slot.item)
	return items


func update_displayed_level(nivel: int, xp: int = -1, xp_next: int = -1) -> void:
	character_level_label.text = tr(LocaleKeys.UI_LEVEL_SHORT) % nivel
	_update_xp_bar(xp, xp_next)
	_sync_party_names()
	if attributes_panel_node and attributes_panel_node.is_open():
		attributes_panel_node.update()


func _progress_for_index(stage_index: int) -> Dictionary:
	if query_slot_progress.is_valid():
		var dados: Variant = query_slot_progress.call(stage_index)
		if dados is Dictionary:
			return dados
	return {"level": 1, "xp": 0, "xp_next": HeroProgress.BASE_XP_PER_LEVEL}


func set_below_combat(abaixo: bool) -> void:
	_menus_abaixo = abaixo
	_apply_combat_spacers()
	_align_side_panels()


func _apply_combat_spacers() -> void:
	if top_spacer == null or bottom_spacer == null:
		return
	if _menus_abaixo:
		top_spacer.custom_minimum_size = Vector2(0, COMBAT_RESERVED_SPACE)
		top_spacer.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		bottom_spacer.custom_minimum_size = Vector2.ZERO
		bottom_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	else:
		top_spacer.custom_minimum_size = Vector2.ZERO
		top_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		bottom_spacer.custom_minimum_size = Vector2(0, COMBAT_RESERVED_SPACE)
		bottom_spacer.size_flags_vertical = Control.SIZE_SHRINK_END


func get_clickable_rects() -> Array[Rect2]:
	if not visible:
		return []
	var rects: Array[Rect2] = []
	if formation_panel_node and formation_panel_node.visible:
		rects.append(formation_panel_node.get_global_rect().grow(4.0))
	elif skills_panel_node and skills_panel_node.visible:
		rects.append(skills_panel_node.get_global_rect().grow(4.0))
	elif attributes_panel_node and attributes_panel_node.visible:
		rects.append(attributes_panel_node.get_global_rect().grow(4.0))
	elif skill_tree_panel_node and skill_tree_panel_node.visible:
		rects.append(skill_tree_panel_node.get_global_rect().grow(4.0))
	elif painel:
		rects.append(painel.get_global_rect().grow(4.0))
	if warehouse_panel_node and warehouse_panel_node.visible:
		rects.append(warehouse_panel_node.get_global_rect().grow(4.0))
	if forge_panel_node and forge_panel_node.visible:
		rects.append(forge_panel_node.get_global_rect().grow(4.0))
	if worlds_panel_node and worlds_panel_node.visible:
		rects.append(worlds_panel_node.get_global_rect().grow(4.0))
	if settings_panel and settings_panel.visible:
		rects.append(settings_panel.get_global_rect().grow(4.0))
	return rects


func width_for_window() -> int:
	return PanelLayout.window_width(menu_area)


func _align_side_panels() -> void:
	_restore_base_panel()
	PanelLayout.align_overlays(
		painel,
		formation_panel_node,
		attributes_panel_node,
		skills_panel_node,
		skill_tree_panel_node
	)
	_apply_panel_layout()
	_sync_side_panel_heights()
	_align_settings()
	menu_width_changed.emit()


func _sync_side_panel_heights() -> void:
	if painel == null:
		return
	var hub_h := painel.get_combined_minimum_size().y
	for lateral in [warehouse_panel_node, forge_panel_node, worlds_panel_node]:
		if lateral:
			lateral.custom_minimum_size.y = hub_h


func _restore_base_panel() -> void:
	if painel == null:
		return
	painel.modulate = Color.WHITE
	painel.mouse_filter = Control.MOUSE_FILTER_STOP
	if painel.custom_minimum_size.x < _layout().panel_min_size.x:
		painel.custom_minimum_size.x = _layout().panel_min_size.x


func _set_inventory_visible(visivel: bool) -> void:
	if conteudo == null or painel == null:
		return
	_restore_base_panel()
	if not visivel:
		var tam := painel.get_combined_minimum_size()
		tam.x = maxf(tam.x, _layout().panel_min_size.x)
		tam.y = maxf(tam.y, painel.custom_minimum_size.y)
		painel.custom_minimum_size = tam
	conteudo.visible = visivel


func inventory_slots() -> Array[ItemSlot]:
	return _inventory_slot_list


static func sort_slots(slots: Array[ItemSlot]) -> void:
	var items: Array[ItemData] = []
	for slot in slots:
		if slot.item != null:
			items.append(slot.item)
	items.sort_custom(ItemData.compare_sort)
	for i in slots.size():
		slots[i].set_item(items[i] if i < items.size() else null)


static func setup_icon_button(botao: Button, caminho_icone: String, lado: int = 42) -> void:
	if botao == null:
		return
	var sem_fundo := StyleBoxEmpty.new()
	botao.add_theme_stylebox_override("normal", sem_fundo)
	botao.add_theme_stylebox_override("hover", sem_fundo)
	botao.add_theme_stylebox_override("pressed", sem_fundo)
	botao.add_theme_stylebox_override("focus", sem_fundo)
	botao.text = ""
	if ResourceLoader.exists(caminho_icone):
		botao.icon = load(caminho_icone)
	botao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	botao.expand_icon = true
	botao.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	botao.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	botao.add_theme_constant_override("icon_max_width", lado)
	botao.custom_minimum_size = Vector2(lado, lado)


func _setup_inventory_sort_button() -> void:
	if sort_inventory_button == null:
		return
	setup_icon_button(sort_inventory_button, "res://sprites/ui/sort_inventory.png")
	if not sort_inventory_button.pressed.is_connected(_on_inventory_sort_pressed):
		sort_inventory_button.pressed.connect(_on_inventory_sort_pressed)


func _on_inventory_sort_pressed() -> void:
	sort_slots(_inventory_slot_list)
	_set_selection(null)
	equipment_changed.emit()
	sort_inventory_button.release_focus()


func warehouse_slots() -> Array[ItemSlot]:
	if warehouse_panel_node:
		return warehouse_panel_node.all_slots()
	var vazio: Array[ItemSlot] = []
	return vazio


func update_gold(valor: int) -> void:
	if gold_label:
		gold_label.text = tr(LocaleKeys.UI_GOLD_FORMAT) % valor
	if skill_tree_panel_node and skill_tree_panel_node.is_open():
		skill_tree_panel_node.update()


func get_current_gold() -> int:
	if query_gold.is_valid():
		return maxi(0, int(query_gold.call()))
	return 0


func try_spend_gold(valor: int) -> bool:
	if valor < 0:
		return false
	if get_current_gold() < valor:
		return false
	gold_spent.emit(valor)
	return true


func skill_tree_progress() -> SkillTreeProgress:
	return _skill_tree_progress


func global_skill_tree_bonus() -> Dictionary:
	return _skill_tree_progress.global_bonus()


func skill_tree_bonus_for_slot(stage_index: int = -1) -> Dictionary:
	var bonus := global_skill_tree_bonus().duplicate(true)
	if stage_index < 0:
		stage_index = _character_index
	_somar_bonus(bonus, _equipped_gem_bonuses(stage_index))
	return bonus


func _equipped_gem_bonuses(stage_index: int) -> Dictionary:
	var total := SkillTreeDefinition.empty_bonus()
	for item in get_equipped_items(stage_index):
		var parcial := item.embedded_gem_bonus()
		for chave in parcial.keys():
			total[chave] = float(total.get(chave, 0)) + float(parcial.get(chave, 0))
	return total


static func _somar_bonus(destino: Dictionary, origem: Dictionary) -> void:
	for chave in origem.keys():
		destino[chave] = float(destino.get(chave, 0)) + float(origem.get(chave, 0))


func notify_skill_tree_changed() -> void:
	skill_tree_changed.emit()
	_sync_warehouse_skill_tree()
	if attributes_panel_node and attributes_panel_node.is_open():
		attributes_panel_node.update()
	equipment_changed.emit()
	SaveSystem.save_game()


func _align_gold_spacer() -> void:
	if gold_panel == null or gold_spacer == null:
		return
	var altura := maxf(gold_panel.size.y, gold_panel.get_combined_minimum_size().y)
	if gold_spacer.custom_minimum_size.y != altura:
		gold_spacer.custom_minimum_size = Vector2(0, altura)


func first_empty_inventory_slot() -> ItemSlot:
	for slot in _inventory_slot_list:
		if slot.item == null:
			return slot
	return null


func first_empty_warehouse_slot() -> ItemSlot:
	if warehouse_panel_node:
		return warehouse_panel_node.first_empty_slot()
	return null


func move_item_between_slots(origem: ItemSlot, destino: ItemSlot) -> void:
	_move_item(origem, destino)


func connect_forge_slot(slot: ItemSlot) -> void:
	if not slot.item_clicked.is_connected(_on_slot_clicked):
		slot.item_clicked.connect(_on_slot_clicked)
	if not slot.item_dropped.is_connected(_on_slot_dropped):
		slot.item_dropped.connect(_on_slot_dropped)
	if not slot.item_right_clicked.is_connected(_on_slot_right_clicked):
		slot.item_right_clicked.connect(_on_slot_right_clicked)


func notify_items_changed() -> void:
	equipment_changed.emit()


func drag_window_from_event(event: InputEvent) -> void:
	_on_header_gui_input(event)


func _generate_initial_item() -> void:
	var espada := ItemData.new()
	espada.id = "wooden_sword"
	espada.display_name = ""
	espada.name_key = "ITEM_wooden_sword"
	espada.item_type = ItemData.Type.WEAPON
	espada.rarity = ItemData.Rarity.COMMON
	espada.item_level = ItemData.ITEM_LEVELS[0]
	espada.damage_bonus = 5
	espada.required_class = ItemData.RequiredClass.ALL
	espada.icone = _create_wooden_sword_icon()
	_inventory_slot_list[0].set_item(espada)


func _create_wooden_sword_icon() -> Texture2D:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var lamina := Color(0.72, 0.5, 0.22, 1)
	var cabo := Color(0.38, 0.22, 0.1, 1)
	var guarda := Color(0.28, 0.18, 0.08, 1)
	for y in range(3, 22):
		for x in range(14, 18):
			img.set_pixel(x, y, lamina)
	for x in range(10, 22):
		img.set_pixel(x, 21, guarda)
		img.set_pixel(x, 22, guarda)
	for y in range(23, 30):
		for x in range(14, 18):
			img.set_pixel(x, y, cabo)
	return ImageTexture.create_from_image(img)


func _on_slot_clicked(slot: ItemSlot) -> void:
	if _slot_selecionado != null and _slot_selecionado != slot:
		if slot.aceita(_slot_selecionado.item) and (_slot_selecionado.aceita(slot.item) or slot.item == null):
			if slot.accepts_any or _can_use_item(_slot_selecionado.item):
				if not _can_move_to_slot(_slot_selecionado, slot):
					return
				_move_item(_slot_selecionado, slot)
				_set_selection(null)
				return
	if slot.item != null:
		_set_selection(slot)
	else:
		_set_selection(null)


func _on_slot_double_clicked(slot: ItemSlot) -> void:
	if slot.item == null:
		return
	if _is_forge_slot(slot):
		return
	if slot.accepts_any:
		if slot.item.is_gem():
			return
		var destino := _current_equipment_slot(slot.item.item_type)
		if destino and _can_use_item(slot.item):
			_move_item(slot, destino)
			_set_selection(null)
	else:
		var vazio := _first_empty_inventory_slot()
		if vazio:
			_move_item(slot, vazio)
			_set_selection(null)


func _on_slot_right_clicked(slot: ItemSlot) -> void:
	if slot.item == null:
		return
	if _is_forge_slot(slot):
		forge_panel_node.interact_slot(slot)
		_set_selection(null)
		equipment_changed.emit()
		return
	if _is_warehouse_slot(slot):
		var vazio_inv := first_empty_inventory_slot()
		if vazio_inv:
			_move_item(slot, vazio_inv)
			_set_selection(null)
		return
	if forge_panel_node.is_open():
		var destino := forge_panel_node.first_empty_slot()
		if destino and _can_move_to_slot(slot, destino):
			_move_item(slot, destino)
			_set_selection(null)
		return
	if warehouse_panel_node.is_open():
		var destino_armazem := warehouse_panel_node.first_empty_slot()
		if destino_armazem:
			_move_item(slot, destino_armazem)
			_set_selection(null)
		return
	_on_slot_double_clicked(slot)


func _is_forge_slot(slot: ItemSlot) -> bool:
	return forge_panel_node != null and forge_panel_node.is_forge_slot(slot)


func _is_warehouse_slot(slot: ItemSlot) -> bool:
	return warehouse_panel_node != null and slot in warehouse_panel_node.all_slots()


func _on_slot_dropped(destino: ItemSlot, _item: ItemData, origem: ItemSlot) -> void:
	if origem == null or destino == null or origem == destino:
		return
	if not destino.aceita(origem.item):
		return
	if not destino.accepts_any and not _can_use_item(origem.item):
		return
	if origem.item != null and not origem.aceita(destino.item) and destino.item != null:
		return
	if not _can_move_to_slot(origem, destino):
		return
	_move_item(origem, destino)
	_set_selection(null)


func _move_item(origem: ItemSlot, destino: ItemSlot) -> void:
	if forge_panel_node and forge_panel_node.is_open():
		var origem_ferraria := forge_panel_node.is_forge_slot(origem)
		var destino_ferraria := forge_panel_node.is_forge_slot(destino)
		if destino_ferraria and not origem_ferraria:
			if forge_panel_node.reserve_item(origem, destino):
				equipment_changed.emit()
			return
		if origem_ferraria and not destino_ferraria:
			if forge_panel_node.is_pending_result(origem):
				if forge_panel_node.collect_result_to(destino):
					equipment_changed.emit()
				return
			forge_panel_node.release_forge_slot(origem)
			equipment_changed.emit()
			return
		if origem_ferraria and destino_ferraria:
			forge_panel_node.swap_reservations(origem, destino)
			equipment_changed.emit()
			return
	if origem.forge_reserved or destino.forge_reserved:
		return
	var item_origem := origem.item
	var item_destino := destino.item
	origem.set_item(item_destino)
	destino.set_item(item_origem)
	equipment_changed.emit()


func _can_move_to_slot(origem: ItemSlot, destino: ItemSlot) -> bool:
	if origem == null or destino == null:
		return false
	if forge_panel_node == null or not forge_panel_node.is_open():
		if origem.forge_reserved or destino.forge_reserved:
			return false
		return true
	var origem_ferraria := forge_panel_node.is_forge_slot(origem)
	var destino_ferraria := forge_panel_node.is_forge_slot(destino)
	if origem.forge_reserved and not origem_ferraria:
		return false
	if destino.forge_reserved:
		return false
	if destino_ferraria and not origem_ferraria:
		if origem.item == null or destino.item != null:
			return false
		if forge_panel_node.is_origin_reserved(origem):
			return false
		if forge_panel_node.is_jewelry_target_slot(destino):
			return forge_panel_node.can_accept_target_jewelry(origem.item)
		if forge_panel_node.is_jewelry_gem_slot(destino):
			return forge_panel_node.can_accept_gem_jewelry(origem.item)
		if forge_panel_node.is_synthesis_slot(destino):
			if not forge_panel_node.can_accept_in_synthesis(origem.item):
				forge_panel_node.notify_blocked_category(origem.item)
				return false
		return true
	if origem_ferraria and not destino_ferraria:
		if forge_panel_node.is_pending_result(origem):
			return destino.item == null and not destino.forge_reserved
		return true
	return true


func _set_selection(slot: ItemSlot) -> void:
	if _slot_selecionado and is_instance_valid(_slot_selecionado):
		_slot_selecionado.update_visual(false)
	_slot_selecionado = slot
	if _slot_selecionado:
		_slot_selecionado.update_visual(true)


func _create_selected_slot_style() -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.22, 0.17, 0.1, 1)
	estilo.border_color = Color(0.95, 0.78, 0.32, 1)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(3)
	return estilo


func _current_equipment_slot(tipo: ItemData.Type) -> ItemSlot:
	for grade in _grids_for_slot(_character_index):
		for grupo in grade.get_children():
			var fundo := grupo.get_node_or_null("FundoSlot") as ItemSlot
			if fundo and fundo.accepted_type == tipo:
				return fundo
	return null


func _first_empty_inventory_slot() -> ItemSlot:
	return first_empty_inventory_slot()


func try_add_inventory_item(item: ItemData) -> bool:
	if item == null:
		return false
	var slot := first_empty_inventory_slot()
	if slot == null:
		return false
	slot.set_item(item)
	return true


func add_item(item: ItemData) -> bool:
	return try_add_inventory_item(item)


func get_current_class() -> ClassData:
	if team_ui and team_ui._party:
		var classe: Variant = team_ui._party.active_party[_character_index]
		if classe is ClassData:
			return classe
	return null


func get_equipped_damage(stage_index: int) -> int:
	var total := 0
	for item in get_equipped_items(stage_index):
		total += item.damage_bonus
	return total


func get_equipped_hp(stage_index: int) -> int:
	var total := 0
	for item in get_equipped_items(stage_index):
		total += item.hp_bonus
	return total


func current_hero_stats() -> Dictionary:
	var stage_index := _character_index
	var hero_progress := _progress_for_index(stage_index)
	var party: PartyService = team_ui._party if team_ui else null
	var computed: Dictionary = party.hero_stats(stage_index) if party else StatCalculator._empty()
	return {
		"attack": int(computed.get("damage", 0)),
		"hp": int(computed.get("hp", 0)),
		"level": int(hero_progress.get("level", 1)),
		"xp": int(hero_progress.get("xp", 0)),
		"xp_next": int(hero_progress.get("xp_next", HeroProgress.BASE_XP_PER_LEVEL)),
		"xp_bonus": float(computed.get("xp_bonus", 0.0)),
		"gold_bonus": float(computed.get("gold_bonus", 0.0)),
		"attack_speed": float(computed.get("attack_speed", 1.0)) * 100.0,
		"crit_chance": float(computed.get("crit_chance", 0.0)),
		"crit_damage": float(computed.get("crit_damage", 0.0)),
		"evasion": float(computed.get("evasion", 0.0)),
		"phys_res": float(computed.get("phys_res", 0.0)),
		"arcane_res": float(computed.get("arcane_res", 0.0)),
		"elemental_res": float(computed.get("elemental_res", 0.0)),
	}


func _update_xp_bar(xp: int = -1, xp_next: int = -1) -> void:
	if character_xp_bar == null:
		return
	var hero_progress := _progress_for_index(_character_index)
	if xp < 0:
		xp = int(hero_progress.get("xp", 0))
	if xp_next <= 0:
		xp_next = maxi(1, int(hero_progress.get("xp_next", HeroProgress.BASE_XP_PER_LEVEL)))
	var nivel := int(hero_progress.get("level", 1))
	character_xp_bar.max_value = float(xp_next)
	character_xp_bar.value = clampf(float(xp), 0.0, float(xp_next))
	if character_xp_label:
		character_xp_label.text = tr(LocaleKeys.UI_LEVEL_FORMAT) % [nivel, xp, xp_next]


func setup_party(party: PartyService) -> void:
	team_ui.configure(party, _character_index)
	if not team_ui.slot_selected.is_connected(select_character):
		team_ui.slot_selected.connect(select_character)
	if not team_ui.class_assigned.is_connected(_on_class_assigned):
		team_ui.class_assigned.connect(_on_class_assigned)
	if formation_panel_node:
		formation_panel_node.configure(self, party)
		if not formation_panel_node.slot_selected.is_connected(select_character):
			formation_panel_node.slot_selected.connect(select_character)
		if not formation_panel_node.panel_open_changed.is_connected(_on_formation_visibility_changed):
			formation_panel_node.panel_open_changed.connect(_on_formation_visibility_changed)
	if skills_panel_node:
		skills_panel_node.configure(self, party)
		if not skills_panel_node.slot_selected.is_connected(select_character):
			skills_panel_node.slot_selected.connect(select_character)
		if not skills_panel_node.panel_open_changed.is_connected(_on_skills_visibility_changed):
			skills_panel_node.panel_open_changed.connect(_on_skills_visibility_changed)
	if attributes_panel_node:
		attributes_panel_node.configure(self)
		if not attributes_panel_node.panel_open_changed.is_connected(_on_attributes_visibility_changed):
			attributes_panel_node.panel_open_changed.connect(_on_attributes_visibility_changed)
	if skill_tree_panel_node:
		skill_tree_panel_node.configure(self)
		if not skill_tree_panel_node.panel_open_changed.is_connected(_on_skill_tree_visibility_changed):
			skill_tree_panel_node.panel_open_changed.connect(_on_skill_tree_visibility_changed)
	if not party.party_changed.is_connected(_on_party_changed):
		party.party_changed.connect(_on_party_changed)
	_sync_party_names()
	_show_character_equipment(_character_index)
	_update_portrait()


func _on_class_assigned(_indice: int, _classe: ClassData) -> void:
	_sync_party_names()
	_show_character_equipment(_character_index)
	_update_portrait()
	hero_class_changed.emit(_character_index, get_current_class())
	equipment_changed.emit()


func _on_party_changed() -> void:
	_sync_party_names()
	select_character(_character_index)
	hero_class_changed.emit(_character_index, get_current_class())
	equipment_changed.emit()


func _sync_party_names() -> void:
	if team_ui == null or team_ui._party == null:
		return
	var party: PartyService = team_ui._party
	for i in PartyService.SLOTS:
		var classe: Variant = party.active_party[i]
		var dados: Dictionary = HERO_SLOTS[i].duplicate()
		if classe is ClassData:
			dados["name"] = (classe as ClassData).get_localized_name()
			dados["hero_class"] = (classe as ClassData).item_class
		else:
			dados["name"] = tr(LocaleKeys.UI_EMPTY_SLOT)
		HERO_SLOTS[i] = dados
		if i < _character_buttons.size():
			var hero_progress := _progress_for_index(i)
			_character_buttons[i].text = "%s Lv.%d" % [dados["name"], int(hero_progress.get("level", 1))]
	character_name_label.text = str(HERO_SLOTS[_character_index]["name"])


func _update_portrait() -> void:
	if character_portrait == null:
		return
	var classe: ClassData = get_current_class()
	character_portrait.texture = classe.character_sprite if classe else null
	character_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _connect_main_skill_slots() -> void:
	_bind_main_skill_slot(slot_ativa_0, SkillResource.Type.ACTIVE, 0)
	_bind_main_skill_slot(slot_ativa_1, SkillResource.Type.ACTIVE, 1)
	_bind_main_skill_slot(slot_passiva_0, SkillResource.Type.PASSIVE, 0)
	_bind_main_skill_slot(slot_passiva_1, SkillResource.Type.PASSIVE, 1)


func _bind_main_skill_slot(botao: Button, tipo: SkillResource.Type, stage_index: int) -> void:
	if botao == null:
		return
	botao.pressed.connect(_on_main_skill_slot_pressed.bind(tipo, stage_index))
	SkillTooltip.vincular(botao, func() -> SkillResource:
		var classe: ClassData = get_current_class()
		if classe == null:
			return null
		return HeroEquipment.get_equipped(classe.id, tipo, stage_index)
	)


func _on_equipment_skills_changed(_classe_id: String) -> void:
	_update_main_skill_slots()
	equipment_changed.emit()
	if attributes_panel_node and attributes_panel_node.is_open():
		attributes_panel_node.update()


func _update_main_skill_slots() -> void:
	if hero_card_row == null:
		return
	var classe: ClassData = get_current_class()
	var mostrar := classe != null
	if active_column:
		active_column.visible = mostrar
	if passive_column:
		passive_column.visible = mostrar
	if not mostrar:
		return
	var classe_id := classe.id
	_apply_skill_slot_text(slot_ativa_0, HeroEquipment.get_equipped(classe_id, SkillResource.Type.ACTIVE, 0))
	_apply_skill_slot_text(slot_ativa_1, HeroEquipment.get_equipped(classe_id, SkillResource.Type.ACTIVE, 1))
	_apply_skill_slot_text(slot_passiva_0, HeroEquipment.get_equipped(classe_id, SkillResource.Type.PASSIVE, 0))
	_apply_skill_slot_text(slot_passiva_1, HeroEquipment.get_equipped(classe_id, SkillResource.Type.PASSIVE, 1))


func _apply_skill_slot_text(botao: Button, skill: SkillResource) -> void:
	if botao == null:
		return
	if skill == null:
		botao.text = EMPTY_SKILL_SLOT_TEXT
		SkillIcons.apply_to_button(botao, null, _layout().skill_menu_slot_size)
	else:
		botao.text = ""
		SkillIcons.apply_to_button(botao, skill, _layout().skill_menu_slot_size)


func _on_main_skill_slot_pressed(tipo: SkillResource.Type, indice_slot: int) -> void:
	if get_current_class() == null:
		return
	open_equipment_skills(_character_index, tipo, indice_slot)


func _class_can_use(item: ItemData) -> bool:
	if item == null:
		return true
	if item.required_class == ItemData.RequiredClass.ALL:
		return true
	var classe: ClassData = get_current_class()
	if classe == null:
		return false
	return classe.item_class == item.required_class


func _current_hero_level() -> int:
	return int(_progress_for_index(_character_index).get("level", 1))


func _can_use_item(item: ItemData) -> bool:
	if item == null:
		return true
	if not _class_can_use(item):
		return false
	return item.can_equip(_current_hero_level())


func fill_initial_item_if_empty() -> void:
	for slot in _inventory_slot_list:
		if slot.item:
			return
	_generate_initial_item()


func serialize_inventory() -> Array:
	var lista: Array = []
	for slot in _inventory_slot_list:
		lista.append(slot.item.to_dictionary() if slot.item else {})
	return lista


func apply_inventory(lista: Array) -> void:
	for i in _inventory_slot_list.size():
		var item: ItemData = null
		if i < lista.size() and lista[i] is Dictionary:
			var dados: Dictionary = lista[i]
			if not dados.is_empty():
				item = ItemData.from_dictionary(dados)
		_inventory_slot_list[i].set_item(item)


func update_world_progress(world: int, stage: int, difficulty: int, liberadas: Array) -> void:
	if worlds_panel_node:
		worlds_panel_node.set_state(world, stage, difficulty, liberadas)


func serialize_warehouse() -> Dictionary:
	return warehouse_panel_node.serialize() if warehouse_panel_node else {}


func apply_warehouse(dados: Variant) -> void:
	if warehouse_panel_node:
		warehouse_panel_node.apply(dados)
	_sync_warehouse_skill_tree()


func serialize_skill_tree() -> Dictionary:
	return _skill_tree_progress.serialize()


func apply_skill_tree(dados: Variant) -> void:
	_skill_tree_progress.apply(dados)
	_sync_warehouse_skill_tree()


func _sync_warehouse_skill_tree() -> void:
	if warehouse_panel_node == null:
		return
	warehouse_panel_node.apply_skill_tree_unlocks(_skill_tree_progress.unlocked_warehouse_indices())


func serialize_equipment() -> Dictionary:
	var todos: Dictionary = {}
	for id_classe in _left_equipment_by_class.keys():
		var lista: Array = []
		for slot in _slots_for_class(str(id_classe)):
			lista.append({
				"type": int(slot.accepted_type),
				"item": slot.item.to_dictionary() if slot.item else {},
			})
		todos[str(id_classe)] = lista
	return todos


func apply_equipment(todos: Variant) -> void:
	if todos is Dictionary:
		for id_classe in _left_equipment_by_class.keys():
			var chave := str(id_classe)
			var lista: Array = todos[chave] if todos.has(chave) and todos[chave] is Array else []
			_apply_slot_list(_slots_for_class(chave), lista)
		return
	if todos is Array:
		var ids_antigos: Array[String] = ["warrior", "mage", "archer"]
		for i in mini(todos.size(), ids_antigos.size()):
			if todos[i] is Array:
				_apply_slot_list(_slots_for_class(ids_antigos[i]), todos[i])


func _apply_slot_list(slots: Array[ItemSlot], lista: Array) -> void:
	var by_type: Dictionary = {}
	for entrada in lista:
		if entrada is Dictionary:
			by_type[int(entrada.get("type", -1))] = entrada.get("item", {})
	for slot in slots:
		var item: ItemData = null
		var dados: Variant = by_type.get(int(slot.accepted_type), {})
		if dados is Dictionary:
			item = ItemData.from_dictionary(dados)
		slot.set_item(item)


func _class_id_for_slot(stage_index: int) -> String:
	if team_ui and team_ui._party:
		var classe: Variant = team_ui._party.active_party[stage_index]
		if classe is ClassData:
			return (classe as ClassData).id
	return ""


func _grids_for_slot(stage_index: int) -> Array[GridContainer]:
	return _grids_for_class(_class_id_for_slot(stage_index))


func _grids_for_class(id_classe: String) -> Array[GridContainer]:
	var grades: Array[GridContainer] = []
	if id_classe == "" or not _left_equipment_by_class.has(id_classe):
		return grades
	grades.append(_left_equipment_by_class[id_classe])
	grades.append(_right_equipment_by_class[id_classe])
	return grades


func _slots_for_class(id_classe: String) -> Array[ItemSlot]:
	var slots: Array[ItemSlot] = []
	for grade in _grids_for_class(id_classe):
		for filho in grade.get_children():
			var slot := filho as ItemSlot
			if slot == null:
				slot = filho.get_node_or_null("FundoSlot") as ItemSlot
			if slot:
				slots.append(slot)
	return slots


func _create_character_style(selecionado: bool) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	if selecionado:
		estilo.bg_color = Color(0.22, 0.17, 0.1, 1)
		estilo.border_color = Color(0.95, 0.78, 0.32, 1)
		estilo.set_border_width_all(3)
	else:
		estilo.bg_color = Color(0.08, 0.07, 0.06, 1)
		estilo.border_color = Color(0.42, 0.35, 0.24, 1)
		estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(3)
	return estilo


func _apply_bottom_bar_icons() -> void:
	if botao_skills:
		_setup_bar_button(botao_skills, "skills")
	_setup_bar_button(botao_inventario, "inventory")
	_setup_bar_button(forge_button, "forge")
	_setup_bar_button(world_button, "world")


func _setup_bar_button(botao: Button, chave: String, destacado: bool = false) -> void:
	if botao == null:
		return
	botao.icon = InterfaceIcons.bar_icon(chave)
	botao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	botao.expand_icon = true
	botao.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	botao.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	botao.add_theme_constant_override("icon_max_width", 18)
	botao.add_theme_constant_override("h_separation", 4)
	if not destacado:
		return
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.24, 0.18, 0.1, 1)
	estilo.border_color = Color(0.95, 0.78, 0.32, 1)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(4)
	estilo.content_margin_left = 8
	estilo.content_margin_right = 8
	estilo.content_margin_top = 6
	estilo.content_margin_bottom = 6
	botao.add_theme_stylebox_override("normal", estilo)
	botao.add_theme_stylebox_override("hover", estilo)
	botao.add_theme_stylebox_override("pressed", estilo)


func _store_forge_button_styles() -> void:
	_forge_button_styles["normal"] = forge_button.get_theme_stylebox("normal").duplicate()
	_forge_button_styles["hover"] = forge_button.get_theme_stylebox("hover").duplicate()
	_forge_button_styles["pressed"] = forge_button.get_theme_stylebox("pressed").duplicate()


func _on_forge_button_pressed() -> void:
	if forge_panel_node.is_open():
		forge_panel_node.close()
	else:
		_close_right_panels(forge_panel_node)
		forge_panel_node.open()
	forge_button.release_focus()


func _on_warehouse_button_pressed() -> void:
	warehouse_panel_node.toggle()
	warehouse_button.release_focus()


func _on_world_button_pressed() -> void:
	if worlds_panel_node.is_open():
		worlds_panel_node.close()
	else:
		_close_right_panels(worlds_panel_node)
		worlds_panel_node.open()
	world_button.release_focus()


func _on_formation_requested() -> void:
	if formation_panel_node.is_open():
		formation_panel_node.close()
		return
	_close_overlay_panels(formation_panel_node)
	_close_right_panels()
	formation_panel_node.open()


func _on_formation_visibility_changed(aberta: bool) -> void:
	_set_inventory_visible(not aberta)
	_align_side_panels()
	call_deferred("_align_side_panels")


func _on_skills_button_pressed() -> void:
	if skills_panel_node and skills_panel_node.is_open():
		skills_panel_node.close()
	else:
		_open_skills()
	if botao_skills:
		botao_skills.release_focus()


func open_equipment_skills(
	slot_heroi: int,
	tipo_slot: SkillResource.Type = SkillResource.Type.ACTIVE,
	indice_slot: int = 0
) -> void:
	_open_skills(slot_heroi, tipo_slot, indice_slot)


func _open_skills(
	slot_heroi: int = -1,
	tipo_slot: SkillResource.Type = SkillResource.Type.ACTIVE,
	indice_slot: int = 0
) -> void:
	_close_overlay_panels(skills_panel_node)
	_close_right_panels()
	if skills_panel_node:
		var heroi := slot_heroi if slot_heroi >= 0 else _character_index
		skills_panel_node.open(heroi, tipo_slot, indice_slot)


func _on_skills_visibility_changed(aberta: bool) -> void:
	_set_inventory_visible(not aberta)
	_align_side_panels()
	call_deferred("_align_side_panels")


func _on_attributes_button_pressed() -> void:
	if attributes_panel_node and attributes_panel_node.is_open():
		attributes_panel_node.close()
	else:
		_open_attributes()
	if character_attributes_button:
		character_attributes_button.release_focus()


func _open_attributes() -> void:
	_close_overlay_panels(attributes_panel_node)
	if attributes_panel_node:
		attributes_panel_node.open()


func _on_skill_tree_button_pressed() -> void:
	if skill_tree_panel_node and skill_tree_panel_node.is_open():
		skill_tree_panel_node.close()
	else:
		_open_skill_tree()
	botao_inventario.release_focus()


func _open_skill_tree() -> void:
	_close_overlay_panels(skill_tree_panel_node)
	_close_right_panels()
	if skill_tree_panel_node:
		skill_tree_panel_node.open()


func _on_skill_tree_visibility_changed(aberta: bool) -> void:
	_set_inventory_visible(not aberta)
	_align_side_panels()
	call_deferred("_align_side_panels")


func _on_attributes_visibility_changed(aberta: bool) -> void:
	_set_inventory_visible(not aberta)
	_align_side_panels()
	call_deferred("_align_side_panels")


func _close_overlay_panels(exceto: Control = null) -> void:
	if formation_panel_node and formation_panel_node != exceto and formation_panel_node.is_open():
		formation_panel_node.close()
	if attributes_panel_node and attributes_panel_node != exceto and attributes_panel_node.is_open():
		attributes_panel_node.close()
	if skills_panel_node and skills_panel_node != exceto and skills_panel_node.is_open():
		skills_panel_node.close()
	if skill_tree_panel_node and skill_tree_panel_node != exceto and skill_tree_panel_node.is_open():
		skill_tree_panel_node.close()


func _close_right_panels(exceto: Control = null) -> void:
	if forge_panel_node and forge_panel_node != exceto and forge_panel_node.is_open():
		forge_panel_node.close()
	if worlds_panel_node and worlds_panel_node != exceto and worlds_panel_node.is_open():
		worlds_panel_node.close()


func _on_forge_visibility_changed(aberta: bool) -> void:
	if not aberta:
		_set_selection(null)
		_restore_forge_button_style()
		_align_side_panels()
		return
	var estilo := _create_active_forge_button_style()
	forge_button.add_theme_stylebox_override("normal", estilo)
	forge_button.add_theme_stylebox_override("hover", estilo)
	forge_button.add_theme_stylebox_override("pressed", estilo)
	_align_side_panels()


func _on_warehouse_visibility_changed(aberta: bool) -> void:
	if aberta:
		var estilo := _create_active_forge_button_style()
		warehouse_button.add_theme_stylebox_override("normal", estilo)
		warehouse_button.add_theme_stylebox_override("hover", estilo)
		warehouse_button.add_theme_stylebox_override("pressed", estilo)
		_align_side_panels()
		return
	for nome in _warehouse_button_styles.keys():
		warehouse_button.add_theme_stylebox_override(str(nome), _warehouse_button_styles[nome])
	warehouse_button.release_focus()
	warehouse_button.set_pressed_no_signal(false)
	_align_side_panels()


func _restore_forge_button_style() -> void:
	for nome in _forge_button_styles.keys():
		forge_button.add_theme_stylebox_override(str(nome), _forge_button_styles[nome])
	forge_button.release_focus()
	forge_button.set_pressed_no_signal(false)


func _create_active_forge_button_style() -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.content_margin_left = 8
	estilo.content_margin_top = 7
	estilo.content_margin_right = 8
	estilo.content_margin_bottom = 7
	estilo.bg_color = Color(0.32, 0.24, 0.16, 1)
	estilo.border_color = Color(0.95, 0.78, 0.32, 1)
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(4)
	return estilo


func _on_worlds_visibility_changed(aberta: bool) -> void:
	if aberta:
		var estilo := _create_active_forge_button_style()
		world_button.add_theme_stylebox_override("normal", estilo)
		world_button.add_theme_stylebox_override("hover", estilo)
		world_button.add_theme_stylebox_override("pressed", estilo)
		_align_side_panels()
		return
	for nome in _world_button_styles.keys():
		world_button.add_theme_stylebox_override(str(nome), _world_button_styles[nome])
	world_button.release_focus()
	world_button.set_pressed_no_signal(false)
	_align_side_panels()


func _on_stage_started(world: int, stage: int, difficulty: int) -> void:
	stage_started.emit(world, stage, difficulty)


func _on_forge_gold_spent(amount: int) -> void:
	gold_gained.emit(amount)


func _on_menu_visibility_changed() -> void:
	if not visible:
		forge_panel_node.close()
		warehouse_panel_node.close()
		worlds_panel_node.close()
		_close_overlay_panels()
		_close_settings()
		return
	call_deferred("_align_side_panels")


func _on_exit_button_pressed() -> void:
	hide()
	closed.emit()


func _on_quit_button_pressed() -> void:
	SaveSystem.save_game()
	get_tree().quit()


func _on_settings_button_pressed() -> void:
	if settings_panel.visible:
		_close_settings()
	else:
		_open_settings()


func _open_settings() -> void:
	slider_volume.set_value_no_signal(float(AudioManager.get_volume_percent()))
	_update_volume_text(int(slider_volume.value))
	_sync_locale_selector()
	_update_localized_texts()
	settings_panel.show()
	_set_inventory_visible(false)
	_align_settings()
	menu_width_changed.emit()


func _close_settings() -> void:
	if settings_panel:
		settings_panel.hide()
	_set_inventory_visible(true)
	menu_width_changed.emit()


func _align_settings() -> void:
	if settings_panel == null or not settings_panel.visible or painel == null:
		return
	var tam := settings_panel.get_combined_minimum_size()
	tam.x = maxf(tam.x, settings_panel.custom_minimum_size.x)
	settings_panel.size = tam
	var origem := painel.position
	if formation_panel_node and formation_panel_node.visible:
		origem = formation_panel_node.position
	elif skills_panel_node and skills_panel_node.visible:
		origem = skills_panel_node.position
	elif attributes_panel_node and attributes_panel_node.visible:
		origem = attributes_panel_node.position
	elif skill_tree_panel_node and skill_tree_panel_node.visible:
		origem = skill_tree_panel_node.position
	settings_panel.position = origem + Vector2(
		painel.size.x - tam.x,
		0.0
	)


func _on_volume_changed(valor: float) -> void:
	var percentual := int(valor)
	AudioManager.set_volume_percent(percentual)
	_update_volume_text(percentual)


func _update_volume_text(percentual: int) -> void:
	if label_volume_valor:
		label_volume_valor.text = tr(LocaleKeys.SETTINGS_VOLUME_PERCENT) % percentual


func _setup_locale_selector() -> void:
	if option_locale == null:
		return
	option_locale.clear()
	for locale_code in LocaleService.get_available_locales():
		option_locale.add_item(LocaleService.locale_display_name(locale_code), option_locale.item_count)
		option_locale.set_item_metadata(option_locale.item_count - 1, locale_code)
	option_locale.item_selected.connect(_on_locale_selected)


func _sync_locale_selector() -> void:
	if option_locale == null:
		return
	var atual := LocaleService.get_locale()
	for i in option_locale.item_count:
		if str(option_locale.get_item_metadata(i)) == atual:
			option_locale.select(i)
			return


func _on_locale_selected(stage_index: int) -> void:
	if option_locale == null:
		return
	var locale_code := str(option_locale.get_item_metadata(stage_index))
	LocaleService.set_locale(locale_code)


func _on_locale_changed(_locale_code: String) -> void:
	_update_localized_texts()
	_sync_locale_selector()
	_sync_party_names()
	if worlds_panel_node:
		worlds_panel_node.refresh_locale()
	if forge_panel_node and forge_panel_node.has_method("refresh_locale"):
		forge_panel_node.refresh_locale()
	if warehouse_panel_node and warehouse_panel_node.has_method("refresh_locale"):
		warehouse_panel_node.refresh_locale()
	if formation_panel_node and formation_panel_node.has_method("refresh_locale"):
		formation_panel_node.refresh_locale()
	if team_ui and team_ui.has_method("refresh_locale"):
		team_ui.refresh_locale()
	if skills_panel_node and skills_panel_node.has_method("refresh_locale"):
		skills_panel_node.refresh_locale()
	if attributes_panel_node and attributes_panel_node.has_method("refresh_locale"):
		attributes_panel_node.refresh_locale()
	if skill_tree_panel_node and skill_tree_panel_node.has_method("refresh_locale"):
		skill_tree_panel_node.refresh_locale()


func _update_localized_texts() -> void:
	if titulo_config:
		titulo_config.text = tr(LocaleKeys.SETTINGS_TITLE).to_upper()
	if label_volume_titulo:
		label_volume_titulo.text = tr(LocaleKeys.SETTINGS_VOLUME)
	if label_language_title:
		label_language_title.text = tr(LocaleKeys.SETTINGS_LANGUAGE)
	if quit_game_button:
		quit_game_button.text = tr(LocaleKeys.BTN_QUIT_GAME)
	if settings_button:
		settings_button.tooltip_text = tr(LocaleKeys.BTN_SETTINGS)
	if exit_button:
		exit_button.text = tr(LocaleKeys.BTN_CLOSE)
	if close_settings_button:
		close_settings_button.text = tr(LocaleKeys.BTN_CLOSE)
	if character_attributes_button:
		character_attributes_button.text = tr(LocaleKeys.BTN_ATTRIBUTES)
	if formation_button:
		formation_button.text = tr(LocaleKeys.BTN_FORMATION)
	if sort_inventory_button:
		sort_inventory_button.tooltip_text = tr(LocaleKeys.BTN_SORT)
	if botao_skills:
		botao_skills.text = tr(LocaleKeys.UI_SKILLS)
	if botao_inventario:
		botao_inventario.text = tr(LocaleKeys.UI_SKILL_TREE)
	if forge_button:
		forge_button.text = tr(LocaleKeys.UI_FORGE)
	if world_button:
		world_button.text = tr(LocaleKeys.UI_PORTALS)
	if gold_label and query_gold.is_valid():
		gold_label.text = tr(LocaleKeys.UI_GOLD_FORMAT) % get_current_gold()
	if option_locale:
		for i in option_locale.item_count:
			var locale_code := str(option_locale.get_item_metadata(i))
			option_locale.set_item_text(i, LocaleService.locale_display_name(locale_code))


func _gear_icon() -> Texture2D:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cor := Color(0.95, 0.88, 0.7, 1)
	var centro := Vector2(16, 16)
	for i in 8:
		var ang := float(i) * TAU / 8.0
		var p: Vector2 = centro + Vector2(cos(ang), sin(ang)) * 11.0
		_fill_circle(img, p, 3.2, cor)
	_fill_circle(img, centro, 8.0, cor)
	_fill_circle(img, centro, 3.4, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)


func _fill_circle(img: Image, centro: Vector2, raio: float, cor: Color) -> void:
	var r := int(ceil(raio))
	for y in range(int(centro.y) - r, int(centro.y) + r + 1):
		for x in range(int(centro.x) - r, int(centro.x) + r + 1):
			if Vector2(x, y).distance_to(centro) <= raio:
				if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
					continue
				img.set_pixel(x, y, cor)


func _on_header_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse := event as InputEventMouseButton
		var soltou: bool = _dragging and not mouse.pressed
		_dragging = mouse.pressed
		if _dragging:
			_offset_mouse = DisplayServer.mouse_get_position() - DisplayServer.window_get_position()
		elif soltou:
			window_released.emit()
	elif event is InputEventMouseMotion and _dragging:
		DisplayServer.window_set_position(DisplayServer.mouse_get_position() - _offset_mouse)
