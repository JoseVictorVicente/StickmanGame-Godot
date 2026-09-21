class_name HeroEquipLeftPanel
extends GridContainer
## Left hub panel: 3×4 grid with weapons, armor, and active skill slots.

signal skill_slot_pressed(slot_type: SkillResource.Type, slot_index: int)

const EMPTY_SKILL_SLOT_TEXT := "+"
const SKILL_SLOT_ICON_SIZE := Vector2(42, 42)

const SLOT_NAMES: PackedStringArray = [
	"SlotWeapon",
	"SlotOffhand",
	"SlotSkillAtiva0",
	"SlotHelmet",
	"SlotChest",
	"SlotSkillAtiva1",
	"SlotPants",
	"SlotGloves",
	"CellSpacer22",
	"SlotBoots",
	"CellSpacer31",
	"CellSpacer32",
]
const EQUIP_SLOT_NAMES: PackedStringArray = [
	"SlotWeapon",
	"SlotOffhand",
	"SlotHelmet",
	"SlotChest",
	"SlotPants",
	"SlotGloves",
	"SlotBoots",
]
const EQUIP_TYPES: Array[ItemData.Type] = [
	ItemData.Type.WEAPON,
	ItemData.Type.OFFHAND,
	ItemData.Type.HELMET,
	ItemData.Type.CHEST,
	ItemData.Type.PANTS,
	ItemData.Type.GLOVES,
	ItemData.Type.BOOTS,
]

@onready var slot_ativa_0: Button = %SlotSkillAtiva0
@onready var slot_ativa_1: Button = %SlotSkillAtiva1

var _menu: Node
var _skill_provider: Callable
var _slots_configured := false


func configure(menu: Node) -> void:
	_menu = menu
	_wire_skill_slots()
	_configure_equip_slots()


func all_equipment_slots() -> Array[ItemSlot]:
	var slots: Array[ItemSlot] = []
	for slot_name in EQUIP_SLOT_NAMES:
		var slot := get_node_or_null(slot_name) as ItemSlot
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


func refresh_skill_slots(classe: ClassData, _layout: InventoryLayout = null) -> void:
	if classe == null:
		if slot_ativa_0:
			slot_ativa_0.visible = false
		if slot_ativa_1:
			slot_ativa_1.visible = false
		return
	if slot_ativa_0:
		slot_ativa_0.visible = true
	if slot_ativa_1:
		slot_ativa_1.visible = true
	_apply_skill_slot_text(slot_ativa_0, _skill_from_provider(SkillResource.Type.ACTIVE, 0))
	_apply_skill_slot_text(slot_ativa_1, _skill_from_provider(SkillResource.Type.ACTIVE, 1))


func _configure_equip_slots() -> void:
	if _slots_configured:
		return
	for i in EQUIP_SLOT_NAMES.size():
		var slot := get_node_or_null(EQUIP_SLOT_NAMES[i]) as ItemSlot
		if slot == null:
			continue
		slot.configure(null, EQUIP_TYPES[i], false)
		slot.slot_label = tr(ItemData.equip_slot_label_key(EQUIP_TYPES[i]))
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


func _apply_skill_slot_text(botao: Button, skill: SkillResource) -> void:
	if botao == null:
		return
	if skill == null:
		botao.text = EMPTY_SKILL_SLOT_TEXT
		SkillIcons.apply_to_button(botao, null, SKILL_SLOT_ICON_SIZE)
	else:
		botao.text = ""
		SkillIcons.apply_to_button(botao, skill, SKILL_SLOT_ICON_SIZE)


func _skill_from_provider(slot_type: SkillResource.Type, slot_index: int) -> SkillResource:
	if _skill_provider.is_valid():
		return _skill_provider.call(slot_type, slot_index) as SkillResource
	return null


func _refresh_skill_slots() -> void:
	if _menu == null or not _menu.has_method("get_current_class"):
		return
	refresh_skill_slots(_menu.get_current_class())
