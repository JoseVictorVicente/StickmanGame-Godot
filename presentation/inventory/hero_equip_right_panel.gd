@tool
class_name HeroEquipRightPanel
extends VBoxContainer
## Right hub panel: passive skills, jewelry 2×2, pet, inventory sort.

signal skill_slot_pressed(slot_type: SkillResource.Type, slot_index: int)

const EMPTY_SKILL_SLOT_TEXT := "+"
const DEFAULT_LAYOUT := preload("res://presentation/inventory/inventory_layout_default.tres")
const SORT_ICON := "res://sprites/ui/sort_inventory.png"

const JEWELRY_SLOT_NAMES: PackedStringArray = [
	"SlotRing",
	"SlotPendant",
	"SlotBracelet",
	"SlotBelt",
]
const JEWELRY_TYPES: Array[ItemData.Type] = [
	ItemData.Type.RING,
	ItemData.Type.PENDANT,
	ItemData.Type.BRACELET,
	ItemData.Type.BELT,
]

@export var layout_resource: InventoryLayout = DEFAULT_LAYOUT

@onready var right_upper: HBoxContainer = %RightUpper
@onready var passive_column: VBoxContainer = %PassiveColumn
@onready var slot_passiva_0: Button = %SlotSkillMenuPassiva0
@onready var slot_passiva_1: Button = %SlotSkillMenuPassiva1
@onready var jewelry_grid: GridContainer = %JewelryGrid
@onready var right_column_anchor: HBoxContainer = %RightColumnAnchor
@onready var slot_pet: ItemSlot = %SlotPet
@onready var sort_button: Button = %SortInventoryButton

var _menu: Node
var _skill_provider: Callable
var _slots_configured := false


func _ready() -> void:
	if Engine.is_editor_hint():
		call_deferred("_apply_editor_preview")


func configure(menu: Node) -> void:
	_menu = menu
	_wire_sort_button()
	_wire_skill_slots()


func apply_layout(layout: InventoryLayout = null) -> void:
	var tokens := _resolve_layout(layout)
	if tokens == null:
		return
	custom_minimum_size = tokens.hero_equip_right_panel_size()
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	add_theme_constant_override("separation", tokens.spacing_tight)
	if right_upper:
		right_upper.add_theme_constant_override("separation", tokens.equip_grid_h_separation)
		right_upper.alignment = BoxContainer.ALIGNMENT_END
	var grid_size := tokens.equip_block_pixel_size(2, 2)
	if jewelry_grid:
		jewelry_grid.custom_minimum_size = grid_size
		jewelry_grid.add_theme_constant_override("h_separation", tokens.equip_grid_h_separation)
		jewelry_grid.add_theme_constant_override("v_separation", tokens.equip_grid_v_separation)
	if right_column_anchor:
		right_column_anchor.custom_minimum_size.x = grid_size.x
		right_column_anchor.add_theme_constant_override("separation", 0)
	_apply_skill_column(passive_column, tokens)
	for botao_skill in [slot_passiva_0, slot_passiva_1]:
		if botao_skill:
			botao_skill.custom_minimum_size = tokens.equip_slot_size
	_configure_item_slots(tokens)
	if slot_pet:
		slot_pet.custom_minimum_size = tokens.pet_slot_pixel_size()
		slot_pet.size_flags_horizontal = Control.SIZE_SHRINK_END
	if sort_button:
		var sort_size := tokens.sort_button_pixel_size()
		sort_button.custom_minimum_size = sort_size
		sort_button.size_flags_horizontal = Control.SIZE_SHRINK_END
		var icon_side := int(round(sort_size.x))
		InterfaceIcons.setup_icon_button(sort_button, SORT_ICON, icon_side)


func all_equipment_slots() -> Array[ItemSlot]:
	return slots()


func slots() -> Array[ItemSlot]:
	var lista: Array[ItemSlot] = []
	if jewelry_grid:
		for slot_name in JEWELRY_SLOT_NAMES:
			var slot := jewelry_grid.get_node_or_null(slot_name) as ItemSlot
			if slot:
				lista.append(slot)
	if slot_pet:
		lista.append(slot_pet)
	return lista


func get_sort_button() -> Button:
	return sort_button


func bind_skill_provider(provider: Callable) -> void:
	_skill_provider = provider
	_refresh_skill_slots()


func refresh_skill_slots(classe: ClassData, layout: InventoryLayout) -> void:
	if passive_column:
		passive_column.visible = classe != null
	if classe == null:
		return
	_apply_skill_slot_text(
		slot_passiva_0,
		_skill_from_provider(SkillResource.Type.PASSIVE, 0),
		layout
	)
	_apply_skill_slot_text(
		slot_passiva_1,
		_skill_from_provider(SkillResource.Type.PASSIVE, 1),
		layout
	)


func _configure_item_slots(layout: InventoryLayout) -> void:
	if jewelry_grid:
		for i in JEWELRY_SLOT_NAMES.size():
			var slot := jewelry_grid.get_node_or_null(JEWELRY_SLOT_NAMES[i]) as ItemSlot
			if slot == null:
				continue
			slot.custom_minimum_size = layout.equip_slot_size
			if not _slots_configured or Engine.is_editor_hint():
				slot.configure(null, JEWELRY_TYPES[i], false)
				slot.slot_label = tr(ItemData.equip_slot_label_key(JEWELRY_TYPES[i]))
	if slot_pet and (not _slots_configured or Engine.is_editor_hint()):
		slot_pet.configure(null, ItemData.Type.PET, false)
		slot_pet.slot_label = tr(ItemData.equip_slot_label_key(ItemData.Type.PET))
	_slots_configured = true


func _wire_sort_button() -> void:
	if sort_button == null or _menu == null:
		return
	var layout := _resolve_layout(null)
	var icon_side := int(round(layout.sort_button_pixel_size().x)) if layout else 42
	InterfaceIcons.setup_icon_button(sort_button, SORT_ICON, icon_side)
	if not sort_button.pressed.is_connected(_menu.on_inventory_sort_pressed):
		sort_button.pressed.connect(_menu.on_inventory_sort_pressed)


func _wire_skill_slots() -> void:
	_bind_main_skill_slot(slot_passiva_0, SkillResource.Type.PASSIVE, 0)
	_bind_main_skill_slot(slot_passiva_1, SkillResource.Type.PASSIVE, 1)


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
		layout.equip_block_pixel_size(1, 2).y
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
