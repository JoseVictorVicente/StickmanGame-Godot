class_name PainelFormacao
extends PanelContainer
## Substitui o inventário para montar a equipe em campo.

signal visibilidade_alterada(aberta: bool)
signal slot_escolhido(indice: int)

@onready var botao_fechar: Button = %BotaoFecharFormacao
@onready var cabecalho: HBoxContainer = %CabecalhoFormacao
@onready var slots_equipe: HBoxContainer = %SlotsFormacao
@onready var rolagem_herois: ScrollContainer = %RolagemHerois
@onready var grade_herois: GridContainer = %GradeHeroisFormacao
@onready var label_dica: Label = %LabelDicaFormacao

var _menu: MenuInventario
var _party: PartyManager
var _slot_alvo: int = 0
var _botoes_slot: Array[Button] = []
var _botoes_retirar: Array[Button] = []
var _botoes_heroi: Array[Button] = []


func _ready() -> void:
	hide()
	botao_fechar.pressed.connect(fechar)
	cabecalho.gui_input.connect(_on_cabecalho_gui_input)
	gui_input.connect(_on_cabecalho_gui_input)
	if rolagem_herois:
		rolagem_herois.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		rolagem_herois.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
		rolagem_herois.custom_minimum_size.y = 160


func configurar(menu: MenuInventario, party: PartyManager) -> void:
	_menu = menu
	_party = party
	if _party and not _party.equipe_alterada.is_connected(atualizar):
		_party.equipe_alterada.connect(atualizar)
	atualizar()


func esta_aberta() -> bool:
	return visible


func abrir() -> void:
	if _menu == null or not _menu.visible:
		return
	show()
	atualizar()
	visibilidade_alterada.emit(true)
	call_deferred("_reforcar_layout")


func _reforcar_layout() -> void:
	if visible:
		visibilidade_alterada.emit(true)


func fechar() -> void:
	custom_minimum_size = Vector2(580, 0)
	hide()
	visibilidade_alterada.emit(false)


func atualizar() -> void:
	if _party == null:
		return
	if not (_party.equipe_ativa[_slot_alvo] is ClasseData):
		_slot_alvo = _party.primeiro_slot_ocupado()
	_montar_slots()
	_montar_herois()
	if label_dica:
		if _party.pode_remover():
			label_dica.text = "Toque num herói para colocar na equipe. O último em campo não pode sair."
		else:
			label_dica.text = "Pelo menos 1 herói precisa ficar em campo."


func _montar_slots() -> void:
	for filho in slots_equipe.get_children():
		filho.queue_free()
	_botoes_slot.clear()
	_botoes_retirar.clear()
	for i in PartyManager.SLOTS:
		var caixa := VBoxContainer.new()
		caixa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		caixa.add_theme_constant_override("separation", 4)
		var botao := Button.new()
		botao.custom_minimum_size = Vector2(88, 102)
		botao.clip_text = true
		botao.expand_icon = true
		botao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		botao.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		botao.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		botao.alignment = HORIZONTAL_ALIGNMENT_CENTER
		botao.add_theme_constant_override("icon_max_width", 64)
		botao.add_theme_font_size_override("font_size", 10)
		botao.pressed.connect(_on_slot_pressionado.bind(i))
		var classe: Variant = _party.equipe_ativa[i]
		if classe is ClasseData:
			var dados := classe as ClasseData
			botao.icon = dados.sprite_personagem
			botao.text = dados.nome_classe
		else:
			botao.text = "Vazio"
			botao.disabled = true
		caixa.add_child(botao)
		var retirar := Button.new()
		retirar.text = "Retirar"
		retirar.add_theme_font_size_override("font_size", 10)
		retirar.pressed.connect(_on_retirar.bind(i))
		var ocupado := classe is ClasseData
		retirar.disabled = not ocupado or not _party.pode_remover()
		retirar.tooltip_text = "O último herói não pode ser retirado." if retirar.disabled and ocupado else "Tira este herói da equipe."
		caixa.add_child(retirar)
		slots_equipe.add_child(caixa)
		_botoes_slot.append(botao)
		_botoes_retirar.append(retirar)
		_pintar_slot(botao, i == _slot_alvo and ocupado)


func _montar_herois() -> void:
	for filho in grade_herois.get_children():
		filho.queue_free()
	_botoes_heroi.clear()
	grade_herois.columns = 3
	for classe in _party.classes_desbloqueadas:
		var botao := Button.new()
		botao.custom_minimum_size = Vector2(86, 98)
		botao.text = classe.nome_classe
		botao.tooltip_text = classe.nome_classe
		botao.icon = classe.sprite_personagem
		botao.expand_icon = true
		botao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		botao.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		botao.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		botao.alignment = HORIZONTAL_ALIGNMENT_CENTER
		botao.add_theme_constant_override("icon_max_width", 56)
		botao.add_theme_font_size_override("font_size", 10)
		botao.pressed.connect(_on_heroi_pressionado.bind(classe))
		grade_herois.add_child(botao)
		_botoes_heroi.append(botao)
		var na_equipe := _party._indice_da_classe(classe.id) >= 0
		_pintar_heroi(botao, na_equipe)


func _on_slot_pressionado(indice: int) -> void:
	if not (_party.equipe_ativa[indice] is ClasseData):
		return
	_slot_alvo = indice
	atualizar()
	slot_escolhido.emit(indice)


func _on_retirar(indice: int) -> void:
	if _party.remover_do_slot(indice):
		_slot_alvo = _party.primeiro_slot_ocupado()
		slot_escolhido.emit(_slot_alvo)


func _on_heroi_pressionado(classe: ClasseData) -> void:
	var ja := _party._indice_da_classe(classe.id)
	if ja >= 0:
		_slot_alvo = ja
		atualizar()
		slot_escolhido.emit(ja)
		return
	var colocado := _party.incluir_classe(classe)
	if colocado >= 0:
		_slot_alvo = colocado
		slot_escolhido.emit(colocado)
		return
	_party.escalar_personagem(_slot_alvo, classe)
	slot_escolhido.emit(_slot_alvo)


func _pintar_slot(botao: Button, ativo: bool) -> void:
	var estilo := StyleBoxFlat.new()
	estilo.set_corner_radius_all(4)
	estilo.set_border_width_all(2)
	if ativo:
		estilo.bg_color = Color(0.22, 0.16, 0.08, 1)
		estilo.border_color = Color(0.95, 0.78, 0.32, 1)
	else:
		estilo.bg_color = Color(0.08, 0.07, 0.06, 1)
		estilo.border_color = Color(0.42, 0.35, 0.24, 1)
	botao.add_theme_stylebox_override("normal", estilo)
	botao.add_theme_stylebox_override("hover", estilo)
	botao.add_theme_stylebox_override("disabled", estilo)


func _pintar_heroi(botao: Button, na_equipe: bool) -> void:
	var estilo := StyleBoxFlat.new()
	estilo.set_corner_radius_all(4)
	if na_equipe:
		estilo.bg_color = Color(0.22, 0.16, 0.08, 0.7)
		estilo.border_color = Color(0.95, 0.78, 0.32, 1)
		estilo.set_border_width_all(2)
	else:
		estilo.bg_color = Color(0.1, 0.09, 0.08, 1)
		estilo.border_color = Color(0.42, 0.35, 0.24, 1)
		estilo.set_border_width_all(1)
	botao.add_theme_stylebox_override("normal", estilo)
	botao.add_theme_stylebox_override("hover", estilo)


func _on_cabecalho_gui_input(evento: InputEvent) -> void:
	if _menu and _menu.has_method("_on_cabecalho_gui_input"):
		_menu._on_cabecalho_gui_input(evento)
