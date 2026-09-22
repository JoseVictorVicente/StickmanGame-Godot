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
@onready var gold_label: Label = %GoldLabel
@onready var gold_panel: Control = %GoldPanel
@onready var settings_panel: SettingsPanel = %SettingsPanel
@onready var cabecalho: HBoxContainer = %Header
@onready var hub_column: VBoxContainer = %HubColumn
@onready var hub_chrome_bar: Control = %HubChromeBar
@onready var hub_body: PanelContainer = %HubBody
@onready var hub_content: VBoxContainer = %HubContent
@onready var hub_upper_row: HBoxContainer = %HubUpperRow
@onready var overlay_stack: Control = %OverlayStack
@onready var menu_area: HBoxContainer = %MenuArea
@onready var overlay_vbox: VBoxContainer = %OverlayVBox
@onready var top_spacer_expand: Control = %TopSpacerExpand
@onready var top_spacer_combat: Control = %TopSpacerCombat
@onready var bottom_spacer_combat: Control = %BottomSpacerCombat
@onready var bottom_spacer_expand: Control = %BottomSpacerExpand
@onready var forge_panel_node: ForgePanel = %PanelForgePanel
@onready var warehouse_panel_node: WarehousePanel = %WarehousePanel
@onready var worlds_panel_node: WorldsPanel = %WorldsPanel
@onready var formation_panel_node: FormationPanel = %FormationPanel
@onready var skills_panel_node: SkillsPanel = %SkillsPanel
@onready var attributes_panel_node: AttributesPanel = %AttributesPanel
@onready var skill_tree_panel_node: SkillTreePanel = %SkillTreePanel
@onready var hero_equip_left: HeroEquipLeftPanel = %HeroEquipLeftPanel
@onready var hero_character: HeroCharacterPanel = %HeroCharacterPanel
@onready var hero_equip_right: HeroEquipRightPanel = %HeroEquipRightPanel
@onready var inventory_panel: InventoryPanel = %InventoryPanel
@onready var bottom_nav: BottomNav = %BottomNav

var close_settings_button: Button
var slider_volume: HSlider
var label_volume_valor: Label
var titulo_config: Label
var label_volume_titulo: Label
var label_language_title: Label
var option_locale: OptionButton

var inventory_slots_grid: InventorySlotsGrid
var inventory_slot_list: Array[ItemSlot] = []
var sort_inventory_button: Button
var formation_button: Button
var botao_skills: Button
var botao_inventario: Button
var forge_button: Button
var storage_button: Button
var world_button: Button

var equipment_loadouts := EquipmentLoadoutRegistry.new()
var skill_tree_progress_data := SkillTreeProgress.new()
var _drag := InventoryDragController.new()
var _panels := InventoryPanelRouter.new()
var _persistence := InventoryPersistenceBridge.new()

var _dragging: bool = false
var _offset_mouse: Vector2i = Vector2i.ZERO
var _character_index: int = 0
var _character_buttons: Array[Button] = []
var _displayed_class_id: String = ""
var _forge_button_styles: Dictionary = {}
var _warehouse_button_styles: Dictionary = {}
var _world_button_styles: Dictionary = {}
var _menus_abaixo: bool = false
var _aligning_side_panels: bool = false
var query_gold: Callable
var query_slot_progress: Callable

@export var layout_inventario: InventoryLayout = preload("res://presentation/inventory/inventory_layout_default.tres")
@export var active_side_button_style: StyleBoxFlat


func _ready() -> void:
	CLASSES = ClassData.catalog()
	_bind_settings_nodes()
	_drag.setup(self)
	_panels.setup(self)
	_configure_hub_prefabs()
	_setup_equipment()
	_apply_combat_spacers()
	_wire_character_selector()
	exit_button.pressed.connect(_on_exit_button_pressed)
	quit_game_button.pressed.connect(_on_quit_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	if close_settings_button:
		close_settings_button.pressed.connect(_close_settings)
	if slider_volume:
		slider_volume.value_changed.connect(_on_volume_changed)
	_setup_locale_selector()
	LocaleService.locale_changed.connect(_on_locale_changed)
	_update_localized_texts()
	settings_button.icon = _gear_icon()
	settings_button.add_theme_constant_override("icon_max_width", 20)
	settings_button.text = "S"
	cabecalho.gui_input.connect(_on_header_gui_input)
	if hub_chrome_bar:
		hub_chrome_bar.gui_input.connect(_on_header_gui_input)
	if hub_body:
		hub_body.gui_input.connect(_on_header_gui_input)
	forge_panel_node.configure(self)
	warehouse_panel_node.configure(self)
	sync_warehouse_skill_tree()
	worlds_panel_node.configure(self)
	menu_area.resized.connect(align_side_panels)
	if hub_body:
		hub_body.resized.connect(align_side_panels)
	forge_panel_node.panel_open_changed.connect(_on_forge_visibility_changed)
	warehouse_panel_node.panel_open_changed.connect(_on_warehouse_visibility_changed)
	worlds_panel_node.panel_open_changed.connect(_on_worlds_visibility_changed)
	worlds_panel_node.stage_started.connect(_on_stage_started)
	forge_panel_node.gold_gained.connect(_on_forge_gold_spent)
	visibility_changed.connect(_on_menu_visibility_changed)
	_store_forge_button_styles()
	_store_warehouse_button_styles()
	_store_world_button_styles()
	if not bottom_nav.nav_requested.is_connected(_on_nav_requested):
		bottom_nav.nav_requested.connect(_on_nav_requested)
	if not hero_character.attributes_requested.is_connected(_on_attributes_button_pressed):
		hero_character.attributes_requested.connect(_on_attributes_button_pressed)
	if not hero_equip_left.skill_slot_pressed.is_connected(_on_hero_skill_slot_pressed):
		hero_equip_left.skill_slot_pressed.connect(_on_hero_skill_slot_pressed)
	if not hero_equip_right.skill_slot_pressed.is_connected(_on_hero_skill_slot_pressed):
		hero_equip_right.skill_slot_pressed.connect(_on_hero_skill_slot_pressed)
	if not HeroEquipment.equipment_changed.is_connected(_on_equipment_skills_changed):
		HeroEquipment.equipment_changed.connect(_on_equipment_skills_changed)
	restore_base_panel()
	call_deferred("align_side_panels")


func get_layout() -> InventoryLayout:
	return layout_inventario if layout_inventario else InventoryLayout.new()


func _layout() -> InventoryLayout:
	return get_layout()


func _bind_settings_nodes() -> void:
	if settings_panel == null:
		return
	close_settings_button = settings_panel.close_settings_button
	slider_volume = settings_panel.slider_volume
	label_volume_valor = settings_panel.label_volume_valor
	titulo_config = settings_panel.titulo_config
	label_volume_titulo = settings_panel.label_volume_titulo
	label_language_title = settings_panel.label_language_title
	option_locale = settings_panel.option_locale


func _configure_hub_prefabs() -> void:
	inventory_slots_grid = inventory_panel.inventory_grid
	sort_inventory_button = null
	storage_button = bottom_nav.storage_button
	formation_button = bottom_nav.formation_button
	botao_skills = bottom_nav.skills_button
	botao_inventario = bottom_nav.tree_button
	forge_button = bottom_nav.forge_button
	world_button = bottom_nav.world_button
	hero_equip_left.configure(self)
	hero_equip_left.bind_skill_provider(_hero_skill_provider)
	hero_character.configure(self)
	hero_equip_right.configure(self)
	hero_equip_right.bind_skill_provider(_hero_skill_provider)
	inventory_panel.configure(self)
	bottom_nav.configure(self)
	sort_inventory_button = hero_equip_right.get_sort_button() if hero_equip_right else null
	if skill_tree_panel_node:
		skill_tree_panel_node.configure(self)
		if not skill_tree_panel_node.panel_open_changed.is_connected(_on_skill_tree_visibility_changed):
			skill_tree_panel_node.panel_open_changed.connect(_on_skill_tree_visibility_changed)


func _all_equipment_slots() -> Array[ItemSlot]:
	var slots: Array[ItemSlot] = []
	slots.append_array(hero_equip_left.all_equipment_slots())
	slots.append_array(hero_equip_right.all_equipment_slots())
	return slots


func _refresh_all_skill_slots() -> void:
	var layout := get_layout()
	var classe := get_current_class()
	hero_equip_left.refresh_skill_slots(classe, layout)
	hero_equip_right.refresh_skill_slots(classe, layout)


func _hero_skill_provider(slot_type: SkillResource.Type, slot_index: int) -> SkillResource:
	var classe := get_current_class()
	if classe == null:
		return null
	return HeroEquipment.get_equipped(classe.id, slot_type, slot_index)


func _on_nav_requested(action: String) -> void:
	match action:
		"storage":
			_panels.open_warehouse()
		"skills":
			_on_skills_button_pressed()
		"tree":
			_on_skill_tree_button_pressed()
		"formation":
			_on_formation_requested()
		"forge":
			_panels.open_forge()
		"world":
			_panels.open_worlds()


func connect_item_slot(slot: ItemSlot) -> void:
	slot.item_clicked.connect(_on_slot_clicked)
	slot.item_double_clicked.connect(_on_slot_double_clicked)
	slot.item_right_clicked.connect(_on_slot_right_clicked)
	slot.item_dropped.connect(_on_slot_dropped)


func _setup_equipment() -> void:
	var class_ids: Array = []
	for classe in CLASSES:
		class_ids.append(classe.id)
	equipment_loadouts.ensure_classes(class_ids)
	hero_equip_left.connect_equipment_slots(Callable(self, "connect_item_slot"))
	for slot in hero_equip_right.slots():
		connect_item_slot(slot)
	refresh_equipment_ui()


func flush_equipment_loadout(class_id: String = "") -> void:
	if class_id == "":
		class_id = _displayed_class_id if _displayed_class_id != "" else _class_id_for_slot(_character_index)
	if class_id == "":
		return
	for slot in _all_equipment_slots():
		equipment_loadouts.set_item(class_id, slot.accepted_type, slot.item)


func refresh_equipment_ui(class_id: String = "") -> void:
	if class_id == "":
		class_id = _class_id_for_slot(_character_index)
	for slot in _all_equipment_slots():
		slot.set_item(equipment_loadouts.get_item(class_id, slot.accepted_type))
	_displayed_class_id = class_id


func can_use_item(item: ItemData) -> bool:
	if item == null:
		return true
	if not _class_can_use(item):
		return false
	return item.can_equip(_current_hero_level())


func is_equipment_slot(slot: ItemSlot) -> bool:
	return slot != null and slot in _all_equipment_slots()


func current_equipment_slot(tipo: ItemData.Type) -> ItemSlot:
	for slot in _all_equipment_slots():
		if slot.accepted_type == tipo:
			return slot
	return null


func clear_slot_selection() -> void:
	_drag.clear_selection()


func restore_base_panel() -> void:
	if hub_body == null:
		return
	hub_body.modulate = Color.WHITE
	hub_body.mouse_filter = Control.MOUSE_FILTER_STOP
func restore_forge_button_style() -> void:
	_apply_stored_button_styles(forge_button, _forge_button_styles)
	if forge_button:
		forge_button.release_focus()
		forge_button.set_pressed_no_signal(false)


func restore_warehouse_button_style() -> void:
	_apply_stored_button_styles(storage_button, _warehouse_button_styles)
	if storage_button:
		storage_button.release_focus()
		storage_button.set_pressed_no_signal(false)


func restore_world_button_style() -> void:
	_apply_stored_button_styles(world_button, _world_button_styles)
	if world_button:
		world_button.release_focus()
		world_button.set_pressed_no_signal(false)


func create_active_side_button_style() -> StyleBoxFlat:
	if active_side_button_style == null:
		return null
	var style := active_side_button_style.duplicate() as StyleBoxFlat
	# Nav icons are full-bleed; content margins shrink animated icons when a panel is open.
	style.content_margin_left = 0.0
	style.content_margin_top = 0.0
	style.content_margin_right = 0.0
	style.content_margin_bottom = 0.0
	return style


func setup_bar_button(botao: Button, chave: String, destacado: bool = false) -> void:
	if botao == null:
		return
	botao.icon = InterfaceIcons.bar_icon(chave)
	botao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	botao.text = ""
	botao.flat = true
	botao.expand_icon = true
	botao.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	botao.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	var layout := get_layout()
	var icon_w := layout.nav_icon_max_width if layout else 18
	if chave == "world" and layout:
		icon_w = layout.nav_world_icon_pixel_width()
	botao.add_theme_constant_override("icon_max_width", icon_w)
	if not destacado:
		return
	botao.modulate = Color(1.0, 0.92, 0.72, 1.0)


func _wire_character_selector() -> void:
	_character_buttons = []
	select_character(0)


func select_character(stage_index: int) -> void:
	var team := hero_character.team_ui
	if team and team._party:
		var party: PartyService = team._party
		if stage_index < 0 or stage_index >= PartyService.SLOTS or not (party.active_party[stage_index] is ClassData):
			stage_index = party.first_occupied_slot()
	var old_class_id := _class_id_for_slot(_character_index)
	flush_equipment_loadout(old_class_id)
	_character_index = stage_index
	var dados: Dictionary = HERO_SLOTS[stage_index]
	var hero_progress := _progress_for_index(stage_index)
	hero_character.set_character_header(
		str(dados["name"]),
		tr(LocaleKeys.UI_LEVEL_SHORT) % int(hero_progress["level"])
	)
	_update_xp_bar()
	if attributes_panel_node and attributes_panel_node.is_open():
		attributes_panel_node.update()
	if skill_tree_panel_node and skill_tree_panel_node.is_open():
		skill_tree_panel_node.update()
	if team:
		team.select_slot(stage_index, false)
	_update_portrait()
	_refresh_all_skill_slots()
	refresh_equipment_ui()
	character_changed.emit(stage_index)
	equipment_changed.emit()


func current_character_index() -> int:
	return _character_index


func get_equipped_items(stage_index: int = -1) -> Array[ItemData]:
	if stage_index < 0:
		stage_index = _character_index
	return equipment_loadouts.items_for_class(_class_id_for_slot(stage_index))


func update_displayed_level(nivel: int, xp: int = -1, xp_next: int = -1) -> void:
	hero_character.set_character_header(
		str(HERO_SLOTS[_character_index]["name"]),
		tr(LocaleKeys.UI_LEVEL_SHORT) % nivel
	)
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
	align_side_panels()


func _apply_combat_spacers() -> void:
	if top_spacer_expand == null or top_spacer_combat == null:
		return
	if bottom_spacer_combat == null or bottom_spacer_expand == null:
		return
	if _menus_abaixo:
		top_spacer_expand.visible = false
		top_spacer_combat.visible = true
		bottom_spacer_combat.visible = false
		bottom_spacer_expand.visible = true
	else:
		top_spacer_expand.visible = true
		top_spacer_combat.visible = false
		bottom_spacer_combat.visible = true
		bottom_spacer_expand.visible = false


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
	elif hub_column:
		rects.append(hub_column.get_global_rect().grow(4.0))
	elif hub_body:
		rects.append(hub_body.get_global_rect().grow(4.0))
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


func align_side_panels() -> void:
	if _aligning_side_panels:
		return
	_aligning_side_panels = true
	restore_base_panel()
	PanelLayout.align_overlays(
		hub_body,
		formation_panel_node,
		attributes_panel_node,
		skills_panel_node,
		skill_tree_panel_node,
		overlay_stack
	)
	menu_width_changed.emit()
	_aligning_side_panels = false


func set_hub_visible(visible_hub: bool) -> void:
	_panels.set_inventory_visible(visible_hub)


func close_right_panels(except: Control = null) -> void:
	_panels.close_right_panels(except)


func open_skill_tree_panel() -> void:
	_panels.open_skill_tree()


func inventory_slots() -> Array[ItemSlot]:
	if inventory_slots_grid:
		return inventory_slots_grid.slots()
	return inventory_slot_list


static func sort_slots(slots: Array[ItemSlot]) -> void:
	var items: Array[ItemData] = []
	for slot in slots:
		if slot.item != null:
			items.append(slot.item)
	items.sort_custom(ItemData.compare_sort)
	for i in slots.size():
		slots[i].set_item(items[i] if i < items.size() else null)


static func setup_icon_button(botao: Button, caminho_icone: String, lado: int = 42) -> void:
	InterfaceIcons.setup_icon_button(botao, caminho_icone, lado)


func on_inventory_sort_pressed() -> void:
	var slots := _inventory_sort_slots()
	sort_slots(slots)
	clear_slot_selection()
	equipment_changed.emit()
	if sort_inventory_button:
		sort_inventory_button.release_focus()


func _inventory_sort_slots() -> Array[ItemSlot]:
	if inventory_slots_grid:
		return inventory_slots_grid.usable_slots()
	var limite := get_layout().usable_inventory_slot_count()
	if inventory_slot_list.size() <= limite:
		return inventory_slot_list
	return inventory_slot_list.slice(0, limite)


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
	return skill_tree_progress_data


func global_skill_tree_bonus() -> Dictionary:
	return skill_tree_progress_data.global_bonus()


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
	sync_warehouse_skill_tree()
	if attributes_panel_node and attributes_panel_node.is_open():
		attributes_panel_node.update()
	equipment_changed.emit()
	SaveSystem.save_game()


func first_empty_inventory_slot() -> ItemSlot:
	if inventory_slots_grid:
		for slot in inventory_slots_grid.usable_slots():
			if slot.item == null:
				return slot
		return null
	for slot in inventory_slot_list:
		if slot.item == null:
			return slot
	return null


func first_empty_warehouse_slot() -> ItemSlot:
	if warehouse_panel_node:
		return warehouse_panel_node.first_empty_slot()
	return null


func move_item_between_slots(origem: ItemSlot, destino: ItemSlot) -> void:
	_drag.move_item(origem, destino)


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
	var slot := first_empty_inventory_slot()
	if slot == null:
		slot = inventory_slots_grid.usable_slots()[0] if inventory_slots_grid else inventory_slot_list[0]
	slot.set_item(espada)


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
	_drag.on_slot_clicked(slot)


func _on_slot_double_clicked(slot: ItemSlot) -> void:
	_drag.on_slot_double_clicked(slot)


func _on_slot_right_clicked(slot: ItemSlot) -> void:
	_drag.on_slot_right_clicked(slot)


func _on_slot_dropped(destino: ItemSlot, item: ItemData, origem: ItemSlot) -> void:
	_drag.on_slot_dropped(destino, item, origem)


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
	var team := hero_character.team_ui
	if team and team._party:
		var classe: Variant = team._party.active_party[_character_index]
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
	var party: PartyService = hero_character.team_ui._party if hero_character.team_ui else null
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
	var hero_progress := _progress_for_index(_character_index)
	if xp < 0:
		xp = int(hero_progress.get("xp", 0))
	if xp_next <= 0:
		xp_next = maxi(1, int(hero_progress.get("xp_next", HeroProgress.BASE_XP_PER_LEVEL)))
	var nivel := int(hero_progress.get("level", 1))
	hero_character.update_xp_bar(nivel, xp, xp_next)


func setup_party(party: PartyService) -> void:
	hero_character.team_ui.configure(party, _character_index)
	if not hero_character.team_ui.slot_selected.is_connected(select_character):
		hero_character.team_ui.slot_selected.connect(select_character)
	if not hero_character.team_ui.class_assigned.is_connected(_on_class_assigned):
		hero_character.team_ui.class_assigned.connect(_on_class_assigned)
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
	if not party.party_changed.is_connected(_on_party_changed):
		party.party_changed.connect(_on_party_changed)
	_sync_party_names()
	refresh_equipment_ui()
	_update_portrait()


func _on_class_assigned(indice: int, _classe: ClassData) -> void:
	if indice == _character_index:
		flush_equipment_loadout()
	_sync_party_names()
	if indice == _character_index:
		refresh_equipment_ui()
	_update_portrait()
	hero_class_changed.emit(_character_index, get_current_class())
	equipment_changed.emit()


func _on_party_changed() -> void:
	_sync_party_names()
	select_character(_character_index)
	hero_class_changed.emit(_character_index, get_current_class())
	equipment_changed.emit()


func _sync_party_names() -> void:
	var team := hero_character.team_ui
	if team == null or team._party == null:
		return
	var party: PartyService = team._party
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
	var hero_progress := _progress_for_index(_character_index)
	hero_character.set_character_header(
		str(HERO_SLOTS[_character_index]["name"]),
		tr(LocaleKeys.UI_LEVEL_SHORT) % int(hero_progress.get("level", 1))
	)


func _update_portrait() -> void:
	hero_character.update_portrait(get_current_class())


func _on_equipment_skills_changed(_classe_id: String) -> void:
	_refresh_all_skill_slots()
	equipment_changed.emit()
	if attributes_panel_node and attributes_panel_node.is_open():
		attributes_panel_node.update()


func _on_hero_skill_slot_pressed(slot_type: SkillResource.Type, slot_index: int) -> void:
	if get_current_class() == null:
		return
	open_equipment_skills(_character_index, slot_type, slot_index)


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


func fill_initial_item_if_empty() -> void:
	for slot in inventory_slots_grid.usable_slots() if inventory_slots_grid else inventory_slot_list:
		if slot.item:
			return
	_generate_initial_item()


func serialize_inventory() -> Array:
	return _persistence.serialize_inventory(self)


func apply_inventory(dados: Variant) -> void:
	_persistence.apply_inventory(self, dados)


func update_world_progress(world: int, stage: int, difficulty: int, liberadas: Array) -> void:
	if worlds_panel_node:
		worlds_panel_node.set_state(world, stage, difficulty, liberadas)


func serialize_warehouse() -> Dictionary:
	return _persistence.serialize_warehouse(self)


func apply_warehouse(dados: Variant) -> void:
	_persistence.apply_warehouse(self, dados)


func serialize_skill_tree() -> Dictionary:
	return _persistence.serialize_skill_tree(self)


func apply_skill_tree(dados: Variant) -> void:
	_persistence.apply_skill_tree(self, dados)


func sync_warehouse_skill_tree() -> void:
	if warehouse_panel_node == null:
		return
	warehouse_panel_node.apply_skill_tree_unlocks(skill_tree_progress_data.unlocked_warehouse_indices())


func serialize_equipment() -> Dictionary:
	return _persistence.serialize_equipment(self)


func apply_equipment(todos: Variant) -> void:
	_persistence.apply_equipment(self, todos)


func _class_id_for_slot(stage_index: int) -> String:
	var team := hero_character.team_ui
	if team and team._party:
		var classe: Variant = team._party.active_party[stage_index]
		if classe is ClassData:
			return (classe as ClassData).id
	return ""


func _store_forge_button_styles() -> void:
	_store_side_button_styles(forge_button, _forge_button_styles)


func _store_warehouse_button_styles() -> void:
	_store_side_button_styles(storage_button, _warehouse_button_styles)


func _store_world_button_styles() -> void:
	_store_side_button_styles(world_button, _world_button_styles)


func _store_side_button_styles(botao: Button, styles: Dictionary) -> void:
	if botao == null:
		return
	for state in ["normal", "hover", "pressed"]:
		var box := botao.get_theme_stylebox(state)
		if box:
			styles[state] = box.duplicate()


func _apply_stored_button_styles(botao: Button, styles: Dictionary) -> void:
	if botao == null:
		return
	for state in styles.keys():
		var box: StyleBox = styles[state]
		if box:
			botao.add_theme_stylebox_override(str(state), box)


func _on_formation_requested() -> void:
	_panels.open_formation()


func _on_formation_visibility_changed(aberta: bool) -> void:
	_panels.on_overlay_visibility_changed(aberta)


func _on_skills_button_pressed() -> void:
	if skills_panel_node and skills_panel_node.is_open():
		skills_panel_node.close()
	else:
		_panels.open_skills()
	if botao_skills:
		botao_skills.release_focus()


func open_equipment_skills(
	slot_heroi: int,
	tipo_slot: SkillResource.Type = SkillResource.Type.ACTIVE,
	indice_slot: int = 0
) -> void:
	_panels.open_skills(slot_heroi, tipo_slot, indice_slot)


func _on_skills_visibility_changed(aberta: bool) -> void:
	_panels.on_overlay_visibility_changed(aberta)


func _on_attributes_button_pressed() -> void:
	if attributes_panel_node and attributes_panel_node.is_open():
		attributes_panel_node.close()
	else:
		_panels.open_attributes()
	if hero_character.character_attributes_button:
		hero_character.character_attributes_button.release_focus()


func _on_skill_tree_button_pressed() -> void:
	if skill_tree_panel_node and skill_tree_panel_node.is_open():
		skill_tree_panel_node.close()
	else:
		_panels.open_skill_tree()
	botao_inventario.release_focus()


func _on_skill_tree_visibility_changed(aberta: bool) -> void:
	_panels.on_overlay_visibility_changed(aberta)


func _on_attributes_visibility_changed(aberta: bool) -> void:
	_panels.on_overlay_visibility_changed(aberta)


func _on_forge_visibility_changed(aberta: bool) -> void:
	_panels.on_forge_visibility_changed(aberta)


func _on_warehouse_visibility_changed(aberta: bool) -> void:
	_panels.on_warehouse_visibility_changed(aberta)


func _on_worlds_visibility_changed(aberta: bool) -> void:
	_panels.on_worlds_visibility_changed(aberta)


func _on_stage_started(world: int, stage: int, difficulty: int) -> void:
	stage_started.emit(world, stage, difficulty)


func _on_forge_gold_spent(amount: int) -> void:
	gold_gained.emit(amount)


func _on_menu_visibility_changed() -> void:
	if not visible:
		forge_panel_node.close()
		warehouse_panel_node.close()
		worlds_panel_node.close()
		_panels.close_overlay_panels()
		_close_settings()
		return
	call_deferred("align_side_panels")


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
	_panels.set_inventory_visible(false)
	menu_width_changed.emit()


func _close_settings() -> void:
	if settings_panel:
		settings_panel.hide()
	_panels.set_inventory_visible(true)
	menu_width_changed.emit()


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
	if hero_character.team_ui and hero_character.team_ui.has_method("refresh_locale"):
		hero_character.team_ui.refresh_locale()
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
	if hero_character.character_attributes_button:
		hero_character.character_attributes_button.tooltip_text = tr(LocaleKeys.BTN_ATTRIBUTES)
	if formation_button:
		formation_button.text = ""
		formation_button.tooltip_text = tr(LocaleKeys.BTN_FORMATION)
	if storage_button:
		storage_button.text = ""
		storage_button.tooltip_text = tr(LocaleKeys.UI_WAREHOUSE)
	if sort_inventory_button:
		sort_inventory_button.tooltip_text = tr(LocaleKeys.BTN_SORT)
	if botao_skills:
		botao_skills.text = ""
		botao_skills.tooltip_text = tr(LocaleKeys.UI_SKILLS)
	if botao_inventario:
		botao_inventario.text = ""
		botao_inventario.tooltip_text = tr(LocaleKeys.UI_SKILL_TREE)
	if forge_button:
		forge_button.text = ""
		forge_button.tooltip_text = tr(LocaleKeys.UI_FORGE)
	if world_button:
		world_button.text = ""
		world_button.tooltip_text = tr(LocaleKeys.UI_PORTALS)
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
