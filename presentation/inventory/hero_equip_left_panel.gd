@tool
class_name HeroEquipLeftPanel
extends HBoxContainer
## Left hub panel: baked equip grid (7 slots) + ultimate + two active skill slots.

signal skill_slot_pressed(slot_type: SkillResource.Type, slot_index: int)

const EMPTY_SKILL_SLOT_TEXT := "+"
const DEFAULT_LAYOUT := preload("res://presentation/inventory/inventory_layout_default.tres")

const SLOT_NAMES: PackedStringArray = [
	"SlotWeapon",
	"SlotOffhand",
	"SlotHelmet",
	"SlotChest",
	"SlotPants",
	"SlotGloves",
	"SlotBoots",
]
const SLOT_TYPES: Array[ItemData.Type] = [
	ItemData.Type.WEAPON,
	ItemData.Type.OFFHAND,
	ItemData.Type.HELMET,
	ItemData.Type.CHEST,
	ItemData.Type.PANTS,
	ItemData.Type.GLOVES,
	ItemData.Type.BOOTS,
]

@export var layout_resource: InventoryLayout = DEFAULT_LAYOUT

@onready var equip_grid: GridContainer = %EquipGrid
@onready var active_column: VBoxContainer = %ActiveColumn
@onready var slot_ultimate: Button = %SlotSkillMenuUltimate
@onready var slot_ativa_0: Button = %SlotSkillMenuAtiva0
@onready var slot_ativa_1: Button = %SlotSkillMenuAtiva1

var _menu: Node
var _skill_provider: Callable
var _slots_configured := false


func _ready() -> void:
	if Engine.is_editor_hint():
		call_deferred("_apply_editor_preview")


func configure(menu: Node) -> void:
	_menu = menu
	_wire_skill_slots()


func apply_layout(layout: InventoryLayout = null) -> void:
	var tokens := _resolve_layout(layout)
	if tokens == null:
		return
	custom_minimum_size = tokens.hero_equip_left_panel_size()
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	alignment = BoxContainer.ALIGNMENT_BEGIN
	add_theme_constant_override("separation", tokens.equip_grid_h_separation)
	if equip_grid:
		equip_grid.custom_minimum_size = tokens.equip_block_pixel_size(2, 4)
		equip_grid.add_theme_constant_override("h_separation", tokens.equip_grid_h_separation)
		equip_grid.add_theme_constant_override("v_separation", tokens.equip_grid_v_separation)
	_configure_equip_slots(tokens)
	_apply_skill_column(active_column, tokens)
	for botao_skill in [slot_ativa_0, slot_ativa_1, slot_ultimate]:
		if botao_skill:
			botao_skill.custom_minimum_size = tokens.equip_slot_size


func all_equipment_slots() -> Array[ItemSlot]:
	var slots: Array[ItemSlot] = []
	if equip_grid == null:
		return slots
	for slot_name in SLOT_NAMES:
		var slot := equip_grid.get_node_or_null(slot_name) as ItemSlot
		if slot:
			slots.append(slot)
	return slots


func connect_equipment_slots(slot_callback: Callable) -> Array[ItemSlot]:
	var slots := all_equipment_slots()
	for slot in slots:
		if slot_callback.is_valid():
			slot_callback.call(slot)
	return slots


func bind_skill_provider(provider: Callable) -> void:
	_skill_provider = provider
	_refresh_skill_slots()


func refresh_skill_slots(classe: ClassData, layout: InventoryLayout) -> void:
	if active_column:
		active_column.visible = classe != null
	if classe == null:
		return
	_apply_skill_slot_text(
		slot_ativa_0,
		_skill_from_provider(SkillResource.Type.ACTIVE, 0),
		layout
	)
	_apply_skill_slot_text(
		slot_ativa_1,
		_skill_from_provider(SkillResource.Type.ACTIVE, 1),
		layout
	)


func _configure_equip_slots(layout: InventoryLayout) -> void:
	if equip_grid == null:
		return
	for i in SLOT_NAMES.size():
		var slot := equip_grid.get_node_or_null(SLOT_NAMES[i]) as ItemSlot
		if slot == null:
			continue
		slot.custom_minimum_size = layout.equip_slot_size
		if not _slots_configured or Engine.is_editor_hint():
			slot.configure(null, SLOT_TYPES[i], false)
			slot.slot_label = tr(ItemData.equip_slot_label_key(SLOT_TYPES[i]))
	_slots_configured = true


func _wire_skill_slots() -> void:
	_bind_main_skill_slot(slot_ativa_0, SkillResource.Type.ACTIVE, 0)
	_bind_main_skill_slot(slot_ativa_1, SkillResource.Type.ACTIVE, 1)


func _bind_main_skill_slot(botao: Button, slot_type: SkillResource.Type, slot_index: int) -> void:
	if botao == null:
		return
	if not botao.pressed.is_connected(_on_skill_slot_pressed):
		botao.pressed.connect(_on_skill_slot_pressed.bind(slot_type, slot_index))
	SkillTooltip.vincular(botao, func() -> SkillResource:
		if _skill_provider.is_valid():
			return _skill_provider.call(slot_type, slot_index) as SkillResource
		return null
	)


func _on_skill_slot_pressed(slot_type: SkillResource.Type, slot_index: int) -> void:
	skill_slot_pressed.emit(slot_type, slot_index)


func _apply_skill_column(col: VBoxContainer, layout: InventoryLayout) -> void:
	if col == null:
		return
	col.custom_minimum_size = Vector2(
		layout.equip_slot_size.x,
		layout.equip_block_pixel_size(1, 3).y
	)
	col.add_theme_constant_override("separation", layout.equip_grid_v_separation)


func _apply_skill_slot_text(botao: Button, skill: SkillResource, layout: InventoryLayout) -> void:
	if botao == null:
		return
	if skill == null:
		botao.text = EMPTY_SKILL_SLOT_TEXT
		SkillIcons.apply_to_button(botao, null, layout.skill_menu_slot_size)
	else:
		botao.text = ""
		SkillIcons.apply_to_button(botao, skill, layout.skill_menu_slot_size)


func _skill_from_provider(slot_type: SkillResource.Type, slot_index: int) -> SkillResource:
	if _skill_provider.is_valid():
		return _skill_provider.call(slot_type, slot_index) as SkillResource
	return null


func _refresh_skill_slots() -> void:
	if _menu == null:
		return
	refresh_skill_slots(_menu.get_current_class(), _menu.get_layout())


func _resolve_layout(layout: InventoryLayout) -> InventoryLayout:
	var tokens := layout if layout else layout_resource
	if tokens == null:
		tokens = DEFAULT_LAYOUT
	return InventoryLayout.duplicate_synced(tokens)


func _apply_editor_preview() -> void:
	apply_layout()
