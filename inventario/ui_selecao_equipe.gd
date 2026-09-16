class_name UiSelecaoEquipe
extends VBoxContainer
## Mostra só os heróis em campo. A formação completa substitui o inventário.

signal slot_selecionado(indice: int)
signal classe_atribuida(slot: int, classe: ClasseData)
signal formacao_pedida

var _party: PartyManager
var _slot_alvo: int = 0
var _botoes_slot: Array[Button] = []
var _indices_slot: Array[int] = []

@onready var slots_equipe: HBoxContainer = %SlotsEquipe
@onready var grade_classes: GridContainer = %GradeClasses
@onready var label_dps_equipe: Label = %LabelDpsEquipe
@onready var botao_formacao: Button = %BotaoFormacao
@onready var titulo_equipe: Label = $TituloEquipe
@onready var titulo_classes: Label = $TituloClasses


func configurar(party: PartyManager, slot_inicial: int = 0) -> void:
	_party = party
	_slot_alvo = slot_inicial
	if grade_classes:
		grade_classes.visible = false
	if titulo_classes:
		titulo_classes.visible = false
	if titulo_equipe:
		titulo_equipe.visible = false
	if botao_formacao and not botao_formacao.pressed.is_connected(_on_formacao_pressed):
		botao_formacao.pressed.connect(_on_formacao_pressed)
	_montar_slots()
	atualizar()
	if not _party.dps_alterado.is_connected(_on_dps_alterado):
		_party.dps_alterado.connect(_on_dps_alterado)
	if not _party.equipe_alterada.is_connected(atualizar):
		_party.equipe_alterada.connect(atualizar)


func selecionar_slot(indice: int, emitir_sinal: bool = true) -> void:
	if _party and not (_party.equipe_ativa[indice] is ClasseData):
		indice = _party.primeiro_slot_ocupado()
	_slot_alvo = clampi(indice, 0, PartyManager.SLOTS - 1)
	_pintar_slots()
	if emitir_sinal:
		slot_selecionado.emit(_slot_alvo)


func atualizar() -> void:
	if _party and not (_party.equipe_ativa[_slot_alvo] is ClasseData):
		_slot_alvo = _party.primeiro_slot_ocupado()
	_montar_slots()
	_pintar_slots()
	if _party:
		_on_dps_alterado(_party.dps_grupo(), _party.dano_total_grupo())


func _on_formacao_pressed() -> void:
	formacao_pedida.emit()


func _montar_slots() -> void:
	for filho in slots_equipe.get_children():
		filho.queue_free()
	_botoes_slot.clear()
	_indices_slot.clear()
	if _party == null:
		return
	for i in PartyManager.SLOTS:
		var classe: Variant = _party.equipe_ativa[i]
		if not (classe is ClasseData):
			continue
		var dados := classe as ClasseData
		var botao := Button.new()
		botao.custom_minimum_size = Vector2(64, 82)
		botao.text = dados.nome_classe
		botao.tooltip_text = dados.nome_classe
		botao.flat = true
		botao.icon = dados.sprite_personagem
		botao.expand_icon = true
		botao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		botao.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		botao.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		botao.alignment = HORIZONTAL_ALIGNMENT_CENTER
		botao.add_theme_constant_override("icon_max_width", 52)
		botao.add_theme_font_size_override("font_size", 9)
		botao.pressed.connect(selecionar_slot.bind(i))
		slots_equipe.add_child(botao)
		_botoes_slot.append(botao)
		_indices_slot.append(i)


func _pintar_slots() -> void:
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
		var classe: Variant = _party.equipe_ativa[slot] if _party else null
		if classe is ClasseData:
			botao.add_theme_color_override("font_color", (classe as ClasseData).cor.lightened(0.35))


func _on_dps_alterado(dps: float, dano_grupo: int) -> void:
	if label_dps_equipe:
		label_dps_equipe.text = "DPS do grupo: %.1f   |   Dano/hit: %d" % [dps, dano_grupo]
