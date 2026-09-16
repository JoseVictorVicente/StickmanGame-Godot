class_name PainelSkills
extends PanelContainer
## Painel dedicado ao equipamento de skills dos heróis.

signal visibilidade_alterada(aberta: bool)
signal slot_escolhido(indice: int)

const TEXTO_SLOT_VAZIO := "[ Vazio ]"

@onready var botao_fechar: Button = %BotaoFecharSkills
@onready var cabecalho: HBoxContainer = %CabecalhoSkills
@onready var slots_heroi: HBoxContainer = %SlotsHeroiSkills
@onready var label_skills_heroi: Label = %LabelSkillsHeroi
@onready var sessao_ativas: VBoxContainer = %SessaoAtivas
@onready var sessao_passivas: VBoxContainer = %SessaoPassivas
@onready var sessao_disponiveis: VBoxContainer = %SessaoDisponiveis
@onready var lista_habilidades: VBoxContainer = %ListaHabilidades
@onready var label_skills_indisponivel: Label = %LabelSkillsIndisponivel
@onready var slot_ativa_0: Button = %SlotAtiva0
@onready var slot_ativa_1: Button = %SlotAtiva1
@onready var slot_passiva_0: Button = %SlotPassiva0
@onready var slot_passiva_1: Button = %SlotPassiva1

var _menu: MenuInventario
var _party: PartyManager
var _slot_alvo: int = 0
var _botoes_heroi: Array[Button] = []
var _indices_heroi: Array[int] = []
var _botoes_catalogo: Array[Button] = []
var _slot_ativo_selecionado: int = 0
var _slot_passivo_selecionado: int = 0


func _ready() -> void:
	hide()
	botao_fechar.pressed.connect(fechar)
	cabecalho.gui_input.connect(_on_cabecalho_gui_input)
	gui_input.connect(_on_cabecalho_gui_input)
	_conectar_slots_skills()
	if not ArcherEquipment.equipamento_alterado.is_connected(_atualizar_ui_skills):
		ArcherEquipment.equipamento_alterado.connect(_atualizar_ui_skills)


func configurar(menu: MenuInventario, party: PartyManager) -> void:
	_menu = menu
	_party = party
	if _party and not _party.equipe_alterada.is_connected(atualizar):
		_party.equipe_alterada.connect(atualizar)
	atualizar()


func esta_aberta() -> bool:
	return visible


func abrir(
	slot_heroi: int = -1,
	tipo_slot: SkillResource.Type = SkillResource.Type.ACTIVE,
	indice_slot: int = 0
) -> void:
	if _menu == null or not _menu.visible:
		return
	if slot_heroi >= 0:
		_slot_alvo = slot_heroi
	elif _party != null and not (_party.equipe_ativa[_slot_alvo] is ClasseData):
		_slot_alvo = _party.primeiro_slot_ocupado()
	definir_slot_equipamento(tipo_slot, indice_slot)
	show()
	atualizar()
	visibilidade_alterada.emit(true)
	call_deferred("_reforcar_layout")


func definir_slot_equipamento(tipo: SkillResource.Type, indice: int) -> void:
	if tipo == SkillResource.Type.ACTIVE:
		_slot_ativo_selecionado = clampi(indice, 0, ArcherEquipment.MAX_ACTIVE - 1)
	else:
		_slot_passivo_selecionado = clampi(indice, 0, ArcherEquipment.MAX_PASSIVE - 1)


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
	_montar_seletor_herois()
	_atualizar_cabecalho()
	_atualizar_visibilidade_skills()
	_atualizar_ui_skills()


func _conectar_slots_skills() -> void:
	slot_ativa_0.pressed.connect(_on_slot_ativo_pressionado.bind(0))
	slot_ativa_1.pressed.connect(_on_slot_ativo_pressionado.bind(1))
	slot_passiva_0.pressed.connect(_on_slot_passivo_pressionado.bind(0))
	slot_passiva_1.pressed.connect(_on_slot_passivo_pressionado.bind(1))


func _montar_seletor_herois() -> void:
	for filho in slots_heroi.get_children():
		filho.queue_free()
	_botoes_heroi.clear()
	_indices_heroi.clear()
	for i in PartyManager.SLOTS:
		var classe: Variant = _party.equipe_ativa[i]
		if not (classe is ClasseData):
			continue
		var dados := classe as ClasseData
		var botao := Button.new()
		botao.custom_minimum_size = Vector2(72, 82)
		botao.text = dados.nome_classe
		botao.icon = dados.sprite_personagem
		botao.expand_icon = true
		botao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		botao.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		botao.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		botao.alignment = HORIZONTAL_ALIGNMENT_CENTER
		botao.add_theme_constant_override("icon_max_width", 48)
		botao.add_theme_font_size_override("font_size", 9)
		botao.pressed.connect(_on_heroi_slot_pressionado.bind(i))
		slots_heroi.add_child(botao)
		_botoes_heroi.append(botao)
		_indices_heroi.append(i)
		_pintar_heroi(botao, i == _slot_alvo)


func _atualizar_cabecalho() -> void:
	if label_skills_heroi == null or _party == null:
		return
	var classe: Variant = _party.equipe_ativa[_slot_alvo]
	if classe is ClasseData:
		label_skills_heroi.text = (classe as ClasseData).nome_classe
	else:
		label_skills_heroi.text = "Nenhum herói"


func _heroi_eh_arqueiro() -> bool:
	if _party == null:
		return false
	var classe: Variant = _party.equipe_ativa[_slot_alvo]
	return classe is ClasseData and (classe as ClasseData).id == "arqueiro"


func _atualizar_visibilidade_skills() -> void:
	var mostrar := _heroi_eh_arqueiro()
	sessao_ativas.visible = mostrar
	sessao_passivas.visible = mostrar
	sessao_disponiveis.visible = mostrar
	label_skills_indisponivel.visible = not mostrar and _party.equipe_ativa[_slot_alvo] is ClasseData


func _atualizar_ui_skills() -> void:
	if not _heroi_eh_arqueiro():
		return
	_atualizar_texto_slot(slot_ativa_0, ArcherEquipment.obter_equipada(SkillResource.Type.ACTIVE, 0))
	_atualizar_texto_slot(slot_ativa_1, ArcherEquipment.obter_equipada(SkillResource.Type.ACTIVE, 1))
	_atualizar_texto_slot(slot_passiva_0, ArcherEquipment.obter_equipada(SkillResource.Type.PASSIVE, 0))
	_atualizar_texto_slot(slot_passiva_1, ArcherEquipment.obter_equipada(SkillResource.Type.PASSIVE, 1))
	_pintar_slot_skill(slot_ativa_0, _slot_ativo_selecionado == 0)
	_pintar_slot_skill(slot_ativa_1, _slot_ativo_selecionado == 1)
	_pintar_slot_skill(slot_passiva_0, _slot_passivo_selecionado == 0)
	_pintar_slot_skill(slot_passiva_1, _slot_passivo_selecionado == 1)
	_montar_catalogo_skills()


func _atualizar_texto_slot(botao: Button, skill: SkillResource) -> void:
	if skill == null:
		botao.text = TEXTO_SLOT_VAZIO
	else:
		botao.text = skill.skill_name
	# TODO: adicionar TextureRect/Sprite2D com ícone da habilidade no slot.


func _montar_catalogo_skills() -> void:
	for filho in lista_habilidades.get_children():
		filho.queue_free()
	_botoes_catalogo.clear()
	for skill in ArcherEquipment.catalogo:
		var botao := Button.new()
		botao.text = skill.texto_botao()
		botao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		botao.custom_minimum_size = Vector2(0, 44)
		botao.alignment = HORIZONTAL_ALIGNMENT_LEFT
		botao.add_theme_font_size_override("font_size", 11)
		botao.pressed.connect(_on_habilidade_catalogo_pressionada.bind(skill))
		lista_habilidades.add_child(botao)
		_botoes_catalogo.append(botao)
		_pintar_botao_catalogo(botao, ArcherEquipment.is_equipped(skill))
	# TODO: adicionar ícone (TextureRect) e animação de preview em cada botão do catálogo.


func _on_heroi_slot_pressionado(indice: int) -> void:
	_slot_alvo = indice
	atualizar()
	slot_escolhido.emit(indice)


func _on_slot_ativo_pressionado(indice: int) -> void:
	_slot_ativo_selecionado = indice
	_atualizar_ui_skills()


func _on_slot_passivo_pressionado(indice: int) -> void:
	_slot_passivo_selecionado = indice
	_atualizar_ui_skills()


func _on_habilidade_catalogo_pressionada(skill: SkillResource) -> void:
	if skill == null:
		return
	var slot_alvo := _slot_ativo_selecionado if skill.type == SkillResource.Type.ACTIVE else _slot_passivo_selecionado
	ArcherEquipment.equip_skill(skill, slot_alvo)
	# TODO: disparar animação de equipamento na UI ao equipar uma skill.


func _pintar_heroi(botao: Button, selecionado: bool) -> void:
	var estilo := StyleBoxFlat.new()
	estilo.set_corner_radius_all(4)
	estilo.set_border_width_all(2)
	if selecionado:
		estilo.bg_color = Color(0.22, 0.16, 0.08, 1)
		estilo.border_color = Color(0.95, 0.78, 0.32, 1)
	else:
		estilo.bg_color = Color(0.08, 0.07, 0.06, 1)
		estilo.border_color = Color(0.42, 0.35, 0.24, 1)
	botao.add_theme_stylebox_override("normal", estilo)
	botao.add_theme_stylebox_override("hover", estilo)


func _pintar_slot_skill(botao: Button, selecionado: bool) -> void:
	var estilo := StyleBoxFlat.new()
	estilo.set_corner_radius_all(4)
	estilo.set_border_width_all(2)
	if selecionado:
		estilo.bg_color = Color(0.22, 0.16, 0.08, 1)
		estilo.border_color = Color(0.95, 0.78, 0.32, 1)
	else:
		estilo.bg_color = Color(0.06, 0.05, 0.04, 1)
		estilo.border_color = Color(0.55, 0.44, 0.26, 1)
	botao.add_theme_stylebox_override("normal", estilo)
	botao.add_theme_stylebox_override("hover", estilo)
	botao.add_theme_stylebox_override("pressed", estilo)


func _pintar_botao_catalogo(botao: Button, equipada: bool) -> void:
	var estilo := StyleBoxFlat.new()
	estilo.set_corner_radius_all(4)
	estilo.set_border_width_all(1)
	if equipada:
		estilo.bg_color = Color(0.18, 0.24, 0.14, 1)
		estilo.border_color = Color(0.55, 0.82, 0.38, 1)
	else:
		estilo.bg_color = Color(0.1, 0.09, 0.08, 1)
		estilo.border_color = Color(0.42, 0.35, 0.24, 1)
	botao.add_theme_stylebox_override("normal", estilo)
	botao.add_theme_stylebox_override("hover", estilo)


func _on_cabecalho_gui_input(evento: InputEvent) -> void:
	if _menu and _menu.has_method("_on_cabecalho_gui_input"):
		_menu._on_cabecalho_gui_input(evento)
