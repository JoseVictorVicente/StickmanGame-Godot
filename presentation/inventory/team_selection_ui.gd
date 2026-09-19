class_name TeamSelectionUI
extends VBoxContainer
## Mostra só os heróis em campo. A formação completa substitui o inventário.

signal slot_selected(stage_index: int)
signal class_assigned(slot: int, classe: ClassData)
signal formation_requested

var _party: PartyService
var _slot_alvo: int = 0
var _botoes_slot: Array[Button] = []
var _indices_slot: Array[int] = []

@onready var slots_equipe: HBoxContainer = %SlotsEquipe
@onready var grade_classes: GridContainer = %GradeClasses
@onready var botao_formacao: Button = %BotaoFormacao
@onready var titulo_equipe: Label = $TituloEquipe
@onready var titulo_classes: Label = $TituloClasses


func configure(party: PartyService, slot_inicial: int = 0) -> void:
	_party = party
	_slot_alvo = slot_inicial
	if grade_classes:
		grade_classes.visible = false
	if titulo_classes:
		titulo_classes.visible = false
	if titulo_equipe:
		titulo_equipe.visible = false
	if botao_formacao and not botao_formacao.pressed.is_connected(_on_formation_pressed):
		botao_formacao.pressed.connect(_on_formation_pressed)
	_build_slots()
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
	_build_slots()
	_paint_slots()


func _on_formation_pressed() -> void:
	formation_requested.emit()


func _build_slots() -> void:
	for filho in slots_equipe.get_children():
		filho.queue_free()
	_botoes_slot.clear()
	_indices_slot.clear()
	if _party == null:
		return
	for i in PartyService.SLOTS:
		var classe: Variant = _party.active_party[i]
		if not (classe is ClassData):
			continue
		var dados := classe as ClassData
		var botao := Button.new()
		botao.custom_minimum_size = Vector2(64, 82)
		botao.text = dados.display_name
		botao.tooltip_text = dados.display_name
		botao.flat = true
		botao.icon = dados.character_sprite
		botao.expand_icon = true
		botao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		botao.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		botao.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		botao.alignment = HORIZONTAL_ALIGNMENT_CENTER
		botao.add_theme_constant_override("icon_max_width", 52)
		botao.add_theme_font_size_override("font_size", 9)
		botao.pressed.connect(select_slot.bind(i))
		slots_equipe.add_child(botao)
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
		var classe: Variant = _party.active_party[slot] if _party else null
		if classe is ClassData:
			botao.add_theme_color_override("font_color", (classe as ClassData).color.lightened(0.35))
