class_name TeamSelectionUI
extends VBoxContainer
## Mostra só os heróis em campo. A formação completa substitui o inventário.

signal slot_selected(stage_index: int)
signal class_assigned(slot: int, classe: ClassData)

var layout_resource: InventoryLayout
var _party: PartyService
var _slot_alvo: int = 0
var _botoes_slot: Array[Button] = []
var _indices_slot: Array[int] = []

@onready var party_slots: HBoxContainer = %PartySlots
@onready var grade_classes: GridContainer = %GradeClasses
@onready var party_title: Label = $PartyTitle
@onready var classes_title: Label = $ClassesTitle
@onready var _party_slot_nodes: Array[Button] = [%PartySlot0, %PartySlot1, %PartySlot2]


func _ready() -> void:
	var locale_service := get_node_or_null("/root/LocaleService")
	if locale_service != null and not locale_service.locale_changed.is_connected(_on_locale_changed):
		locale_service.locale_changed.connect(_on_locale_changed)
	_update_localized_texts()
	_wire_party_slot_buttons()


func _find_menu_layout() -> InventoryLayout:
	var atual: Node = self
	while atual:
		var layout: Variant = atual.get("layout_inventario")
		if layout is InventoryLayout:
			return layout
		atual = atual.get_parent()
	return null


func configure(party: PartyService, slot_inicial: int = 0) -> void:
	_party = party
	_slot_alvo = slot_inicial
	if grade_classes:
		grade_classes.visible = false
	if classes_title:
		classes_title.visible = false
	if party_title:
		party_title.visible = false
	_update_localized_texts()
	update()
	if not _party.party_changed.is_connected(update):
		_party.party_changed.connect(update)


func select_slot(stage_index: int, emitir_sinal: bool = true) -> void:
	if _party and not (_party.active_party[stage_index] is ClassData):
		stage_index = _party.first_occupied_slot()
	_slot_alvo = clampi(stage_index, 0, PartyService.SLOTS - 1)
	_paint_slots()
	if emitir_sinal:
		slot_selected.emit(_slot_alvo)


func update() -> void:
	if _party and not (_party.active_party[_slot_alvo] is ClassData):
		_slot_alvo = _party.first_occupied_slot()
	_sync_party_slot_buttons()
	_paint_slots()


func refresh_locale() -> void:
	_update_localized_texts()
	update()


func _update_localized_texts() -> void:
	pass


func _on_locale_changed(_locale_code: String) -> void:
	_update_localized_texts()


func _wire_party_slot_buttons() -> void:
	if has_meta("_party_slots_wired"):
		return
	for i in PartyService.SLOTS:
		var botao := _party_slot_nodes[i]
		if botao == null:
			continue
		botao.pressed.connect(select_slot.bind(i))
		botao.visible = false
	set_meta("_party_slots_wired", true)


func _sync_party_slot_buttons() -> void:
	_botoes_slot.clear()
	_indices_slot.clear()
	if _party == null:
		for botao in _party_slot_nodes:
			if botao:
				botao.visible = false
		return
	var tamanho := layout_resource.party_hero_slot_size if layout_resource else Vector2(42, 42)
	for i in PartyService.SLOTS:
		var botao := _party_slot_nodes[i]
		if botao == null:
			continue
		var classe: Variant = _party.active_party[i]
		if not (classe is ClassData):
			botao.visible = false
			continue
		var dados := classe as ClassData
		botao.visible = true
		botao.custom_minimum_size = tamanho
		botao.text = ""
		botao.tooltip_text = dados.get_localized_name()
		botao.flat = true
		botao.icon = dados.character_sprite
		botao.expand_icon = true
		botao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		botao.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		botao.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		botao.alignment = HORIZONTAL_ALIGNMENT_CENTER
		botao.add_theme_constant_override("icon_max_width", int(round(tamanho.x * 0.92)))
		_botoes_slot.append(botao)
		_indices_slot.append(i)


func _paint_slots() -> void:
	for i in _botoes_slot.size():
		var botao: Button = _botoes_slot[i]
		var slot := _indices_slot[i]
		var estilo := StyleBoxFlat.new()
		estilo.set_corner_radius_all(4)
		if slot == _slot_alvo:
			estilo.bg_color = Color(0.22, 0.16, 0.08, 0.55)
			estilo.border_color = Color(0.95, 0.78, 0.32, 1)
			estilo.set_border_width_all(2)
		else:
			estilo.bg_color = Color(0, 0, 0, 0)
			estilo.border_color = Color(0.42, 0.35, 0.24, 1)
			estilo.set_border_width_all(1)
		botao.add_theme_stylebox_override("normal", estilo)
		botao.add_theme_stylebox_override("hover", estilo)
