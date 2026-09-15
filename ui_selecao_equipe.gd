class_name UiSelecaoEquipe
extends VBoxContainer
## UI para escalar os 3 slots da equipe com classes desbloqueadas.

signal slot_selecionado(indice: int)
signal classe_atribuida(slot: int, classe: ClasseData)

var _party: PartyManager
var _slot_alvo: int = 0
var _botoes_slot: Array[Button] = []
var _botoes_classe: Array[Button] = []

@onready var slots_equipe: HBoxContainer = %SlotsEquipe
@onready var grade_classes: GridContainer = %GradeClasses
@onready var label_dps_equipe: Label = %LabelDpsEquipe


func configurar(party: PartyManager, slot_inicial: int = 0) -> void:
	_party = party
	_slot_alvo = slot_inicial
	if _botoes_slot.is_empty():
		_montar_slots()
	if _botoes_classe.size() != _party.classes_desbloqueadas.size():
		_montar_classes()
	atualizar()
	if not _party.dps_alterado.is_connected(_on_dps_alterado):
		_party.dps_alterado.connect(_on_dps_alterado)
	if not _party.equipe_alterada.is_connected(atualizar):
		_party.equipe_alterada.connect(atualizar)


func selecionar_slot(indice: int, emitir_sinal: bool = true) -> void:
	_slot_alvo = clampi(indice, 0, PartyManager.SLOTS - 1)
	_pintar_slots()
	_pintar_classes()
	if emitir_sinal:
		slot_selecionado.emit(_slot_alvo)


func atualizar() -> void:
	_pintar_slots()
	_pintar_classes()
	if _party:
		_on_dps_alterado(_party.dps_grupo(), _party.dano_total_grupo())


func _montar_slots() -> void:
	for filho in slots_equipe.get_children():
		filho.queue_free()
	_botoes_slot.clear()
	for i in PartyManager.SLOTS:
		var botao := Button.new()
		botao.custom_minimum_size = Vector2(88, 42)
		botao.add_theme_font_size_override("font_size", 11)
		botao.pressed.connect(selecionar_slot.bind(i))
		slots_equipe.add_child(botao)
		_botoes_slot.append(botao)


func _montar_classes() -> void:
	for filho in grade_classes.get_children():
		grade_classes.remove_child(filho)
		filho.free()
	_botoes_classe.clear()
	if _party == null:
		return
	grade_classes.columns = 3
	for classe in _party.classes_desbloqueadas:
		var botao := Button.new()
		botao.custom_minimum_size = Vector2(92, 28)
		botao.text = classe.nome_classe
		botao.add_theme_font_size_override("font_size", 11)
		botao.pressed.connect(_on_classe_pressionada.bind(classe))
		grade_classes.add_child(botao)
		_botoes_classe.append(botao)


func _on_classe_pressionada(classe: ClasseData) -> void:
	if _party == null:
		return
	_party.escalar_personagem(_slot_alvo, classe)
	classe_atribuida.emit(_slot_alvo, classe)


func _pintar_slots() -> void:
	for i in _botoes_slot.size():
		var botao: Button = _botoes_slot[i]
		var classe: Variant = _party.equipe_ativa[i] if _party else null
		var nome: String = "Vazio"
		if classe is ClasseData:
			nome = (classe as ClasseData).nome_classe
		botao.text = "Slot %d\n%s" % [i + 1, nome]
		var estilo := StyleBoxFlat.new()
		estilo.set_corner_radius_all(4)
		estilo.set_border_width_all(2)
		if i == _slot_alvo:
			estilo.bg_color = Color(0.22, 0.17, 0.1, 1)
			estilo.border_color = Color(0.95, 0.78, 0.32, 1)
		else:
			estilo.bg_color = Color(0.08, 0.07, 0.06, 1)
			estilo.border_color = Color(0.42, 0.35, 0.24, 1)
		botao.add_theme_stylebox_override("normal", estilo)
		botao.add_theme_stylebox_override("hover", estilo)


func _pintar_classes() -> void:
	if _party == null:
		return
	var total := mini(_botoes_classe.size(), _party.classes_desbloqueadas.size())
	var atual: Variant = _party.equipe_ativa[_slot_alvo] if _slot_alvo < _party.equipe_ativa.size() else null
	var id_atual: String = ""
	if atual is ClasseData:
		id_atual = (atual as ClasseData).id
	for i in total:
		var classe: ClasseData = _party.classes_desbloqueadas[i]
		var estilo := StyleBoxFlat.new()
		estilo.set_corner_radius_all(3)
		estilo.set_border_width_all(1)
		if classe.id == id_atual:
			estilo.bg_color = Color(0.28, 0.2, 0.1, 1)
			estilo.border_color = Color(0.95, 0.78, 0.32, 1)
		else:
			estilo.bg_color = Color(0.14, 0.12, 0.1, 1)
			estilo.border_color = Color(0.5, 0.4, 0.25, 1)
		_botoes_classe[i].add_theme_stylebox_override("normal", estilo)
		_botoes_classe[i].add_theme_stylebox_override("hover", estilo)
		_botoes_classe[i].add_theme_color_override("font_color", classe.cor.lightened(0.35))


func _on_dps_alterado(dps: float, dano_grupo: int) -> void:
	if label_dps_equipe:
		label_dps_equipe.text = "DPS do grupo: %.1f   |   Dano/hit: %d" % [dps, dano_grupo]
