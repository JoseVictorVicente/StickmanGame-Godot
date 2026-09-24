class_name HeroEquipRightPanel
extends VBoxContainer
## Right hub panel: passive skills, jewelry, pet, inventory sort.

signal skill_slot_pressed(slot_type: SkillResource.Type, slot_index: int)


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

@onready var slot_passiva_0: HubSkillSlot = %SlotSkillMenuPassiva0
@onready var slot_passiva_1: HubSkillSlot = %SlotSkillMenuPassiva1
@onready var slot_pet: ItemSlot = %SlotPet
@onready var sort_button: TextureButton = %SortInventoryButton
@onready var transfer_button: TextureButton = %TransferInventory

var _menu: Node
var _skill_provider: Callable
var _slots_configured := false


func configure(menu: Node) -> void:
	_menu = menu
	_wire_sort_button()
	_wire_transfer_button()
	_wire_skill_slots()
	_configure_item_slots()
	set_transfer_button_visible(false)


func all_equipment_slots() -> Array[ItemSlot]:
	return slots()


func slots() -> Array[ItemSlot]:
	var lista: Array[ItemSlot] = []
	for slot_name in JEWELRY_SLOT_NAMES:
		var slot := get_node_or_null("MainGrid/%s" % slot_name) as ItemSlot
		if slot:
			lista.append(slot)
	var pet := get_node_or_null("%SlotPet") as ItemSlot
	if pet:
		lista.append(pet)
	return lista


func get_sort_button() -> TextureButton:
	return sort_button


func get_transfer_button() -> TextureButton:
	return transfer_button


func set_transfer_button_visible(should_show: bool) -> void:
	if transfer_button == null:
		return
	transfer_button.visible = should_show
	transfer_button.disabled = not should_show


func refresh_transfer_button_locale() -> void:
	if transfer_button == null:
		return
	transfer_button.tooltip_text = tr(LocaleKeys.BTN_INVENTORY_TRANSFER_WAREHOUSE)


func bind_skill_provider(provider: Callable) -> void:
	_skill_provider = provider
	_refresh_skill_slots()


func refresh_skill_slots(classe: ClassData, _layout: InventoryLayout = null) -> void:
	if slot_passiva_0:
		slot_passiva_0.visible = classe != null
	if slot_passiva_1:
		slot_passiva_1.visible = classe != null
	if classe == null:
		return
	_apply_skill_slot_text(slot_passiva_0, _skill_from_provider(SkillResource.Type.PASSIVE, 0))
	_apply_skill_slot_text(slot_passiva_1, _skill_from_provider(SkillResource.Type.PASSIVE, 1))


func _configure_item_slots() -> void:
	if _slots_configured:
		return
	for i in JEWELRY_SLOT_NAMES.size():
		var slot := get_node_or_null("MainGrid/%s" % JEWELRY_SLOT_NAMES[i]) as ItemSlot
		if slot == null:
			continue
		slot.configure(null, JEWELRY_TYPES[i], false)
		slot.slot_label = tr(ItemData.equip_slot_label_key(JEWELRY_TYPES[i]))
	if slot_pet:
		slot_pet.configure(null, ItemData.Type.PET, false)
		slot_pet.slot_label = tr(ItemData.equip_slot_label_key(ItemData.Type.PET))
	_slots_configured = true


func _wire_sort_button() -> void:
	if sort_button == null or _menu == null:
		return
	if not sort_button.pressed.is_connected(_menu.on_inventory_sort_pressed):
		sort_button.pressed.connect(_menu.on_inventory_sort_pressed)


func _wire_transfer_button() -> void:
	if transfer_button == null or _menu == null:
		return
	if not transfer_button.pressed.is_connected(_on_transfer_button_pressed):
		transfer_button.pressed.connect(_on_transfer_button_pressed)
	refresh_transfer_button_locale()
	transfer_button.visible = false


func _on_transfer_button_pressed() -> void:
	if _menu and _menu.has_method("transfer_inventory_to_warehouse"):
		_menu.transfer_inventory_to_warehouse()
	if transfer_button:
		transfer_button.release_focus()


func _wire_skill_slots() -> void:
	_bind_main_skill_slot(slot_passiva_0, SkillResource.Type.PASSIVE, 0)
	_bind_main_skill_slot(slot_passiva_1, SkillResource.Type.PASSIVE, 1)


func _bind_main_skill_slot(botao: HubSkillSlot, slot_type: SkillResource.Type, slot_index: int) -> void:
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


func _apply_skill_slot_text(botao: HubSkillSlot, skill: SkillResource) -> void:
	if botao == null:
		return
	if skill == null:
		botao.set_empty()
	else:
		botao.set_skill(skill)


func _skill_from_provider(slot_type: SkillResource.Type, slot_index: int) -> SkillResource:
	if _skill_provider.is_valid():
		return _skill_provider.call(slot_type, slot_index) as SkillResource
	return null


func _refresh_skill_slots() -> void:
	if _menu == null or not _menu.has_method("get_current_class"):
		return
	refresh_skill_slots(_menu.get_current_class())
