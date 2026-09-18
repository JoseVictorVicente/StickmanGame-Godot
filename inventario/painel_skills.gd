class_name PainelSkills
extends PanelContainer
## Painel dedicado ao equipamento de skills dos heróis.

signal visibilidade_alterada(aberta: bool)
signal slot_escolhido(indice: int)

const TEXTO_SLOT_VAZIO := "[ Vazio ]"
const SKILLS_ATIVAS_DISPONIVEIS := 5
const SKILLS_PASSIVAS_DISPONIVEIS := 10
const COLUNAS_GRADE := 5
const TAMANHO_SLOT_EQUIPADO := Vector2(120, 64)
const TAMANHO_SLOT_HABILIDADE := Vector2(56, 56)

@onready var botao_fechar: Button = %BotaoFecharSkills
@onready var cabecalho: HBoxContainer = %CabecalhoSkills
@onready var slots_heroi: HBoxContainer = %SlotsHeroiSkills
@onready var label_skills_heroi: Label = %LabelSkillsHeroi
@onready var sessao_equipadas: VBoxContainer = %SessaoEquipadas
@onready var sessao_ativas: VBoxContainer = %SessaoAtivas
@onready var sessao_passivas: VBoxContainer = %SessaoPassivas
@onready var grade_equip_ativas: GridContainer = %GradeEquipAtivas
@onready var grade_equip_passivas: GridContainer = %GradeEquipPassivas
@onready var grade_ativas: GridContainer = %GradeAtivas
@onready var grade_passivas: GridContainer = %GradePassivas

var _menu: MenuInventario
var _party: PartyManager
var _slot_alvo: int = 0
var _botoes_heroi: Array[Button] = []
var _indices_heroi: Array[int] = []
var _slots_equipados_ativos: Array[Button] = []
var _slots_equipados_passivos: Array[Button] = []
var _slots_ativos: Array[Button] = []
var _slots_passivos: Array[Button] = []
var _slot_ativo_selecionado: int = 0
var _slot_passivo_selecionado: int = 0
var _grades_montadas: bool = false


func _ready() -> void:
	hide()
	botao_fechar.pressed.connect(fechar)
	cabecalho.gui_input.connect(_on_cabecalho_gui_input)
	gui_input.connect(_on_cabecalho_gui_input)
	_montar_grades_skills()
	if not HeroEquipment.equipamento_alterado.is_connected(_on_equipamento_alterado):
		HeroEquipment.equipamento_alterado.connect(_on_equipamento_alterado)


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
		_slot_ativo_selecionado = clampi(indice, 0, HeroEquipment.MAX_ACTIVE - 1)
	else:
		_slot_passivo_selecionado = clampi(indice, 0, HeroEquipment.MAX_PASSIVE - 1)


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
	_atualizar_ui_skills()


func _montar_grades_skills() -> void:
	if _grades_montadas:
		return
	_criar_slots_equipados()
	grade_ativas.columns = COLUNAS_GRADE
	grade_passivas.columns = COLUNAS_GRADE
	_criar_slots_habilidade(grade_ativas, _slots_ativos, SKILLS_ATIVAS_DISPONIVEIS)
	_criar_slots_habilidade(grade_passivas, _slots_passivos, SKILLS_PASSIVAS_DISPONIVEIS)
	_grades_montadas = true


func _criar_slots_equipados() -> void:
	_slots_equipados_ativos.clear()
	_slots_equipados_passivos.clear()
	for indice in HeroEquipment.MAX_ACTIVE:
		var botao := _criar_botao_slot_equipado("SlotAtiva%d" % indice, indice, true)
		grade_equip_ativas.add_child(botao)
		_slots_equipados_ativos.append(botao)
	for indice in HeroEquipment.MAX_PASSIVE:
		var botao := _criar_botao_slot_equipado("SlotPassiva%d" % indice, indice, false)
		grade_equip_passivas.add_child(botao)
		_slots_equipados_passivos.append(botao)


func _criar_botao_slot_equipado(nome: String, indice: int, ativo: bool) -> Button:
	var botao := Button.new()
	botao.name = nome
	botao.custom_minimum_size = TAMANHO_SLOT_EQUIPADO
	botao.text = TEXTO_SLOT_VAZIO
	botao.expand_icon = true
	botao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	botao.add_theme_font_size_override("font_size", 10)
	botao.set_meta("slot_equipado_ativo", ativo)
	botao.set_meta("slot_equipado_indice", indice)
	if ativo:
		botao.pressed.connect(_on_slot_ativo_pressionado.bind(indice))
	else:
		botao.pressed.connect(_on_slot_passivo_pressionado.bind(indice))
	TooltipSkill.vincular(botao, func() -> SkillResource:
		var classe_id := _obter_classe_id()
		var tipo := SkillResource.Type.ACTIVE if ativo else SkillResource.Type.PASSIVE
		return HeroEquipment.obter_equipada(classe_id, tipo, indice)
	)
	return botao


func _criar_slots_habilidade(grade: GridContainer, destino: Array[Button], quantidade: int) -> void:
	destino.clear()
	for indice in quantidade:
		var slot := Button.new()
		slot.name = "SlotHabilidade%d" % (indice + 1)
		slot.custom_minimum_size = TAMANHO_SLOT_HABILIDADE
		slot.text = ""
		slot.disabled = true
		slot.add_theme_font_size_override("font_size", 9)
		slot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		slot.pressed.connect(_on_habilidade_disponivel_pressionada.bind(slot))
		TooltipSkill.vincular(slot, func() -> SkillResource:
			var skill: Variant = slot.get_meta("skill", null)
			return skill if skill is SkillResource else null
		)
		grade.add_child(slot)
		destino.append(slot)


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


func _obter_classe_id() -> String:
	if _party == null:
		return ""
	var classe: Variant = _party.equipe_ativa[_slot_alvo]
	if classe is ClasseData:
		return (classe as ClasseData).id
	return ""


func _on_equipamento_alterado(_classe_id: String) -> void:
	_atualizar_ui_skills()


func _atualizar_ui_skills() -> void:
	_atualizar_slots_equipados()
	for i in _slots_equipados_ativos.size():
		_pintar_slot_equipado(_slots_equipados_ativos[i], _slot_ativo_selecionado == i)
	for i in _slots_equipados_passivos.size():
		_pintar_slot_equipado(_slots_equipados_passivos[i], _slot_passivo_selecionado == i)
	_atualizar_habilidades_disponiveis()


func _atualizar_slots_equipados() -> void:
	var classe_id := _obter_classe_id()
	for i in _slots_equipados_ativos.size():
		_atualizar_texto_slot(
			_slots_equipados_ativos[i],
			HeroEquipment.obter_equipada(classe_id, SkillResource.Type.ACTIVE, i)
		)
	for i in _slots_equipados_passivos.size():
		_atualizar_texto_slot(
			_slots_equipados_passivos[i],
			HeroEquipment.obter_equipada(classe_id, SkillResource.Type.PASSIVE, i)
		)


func _atualizar_habilidades_disponiveis() -> void:
	var classe_id := _obter_classe_id()
	for slot in _slots_ativos:
		_configurar_slot_disponivel(slot, null, classe_id)
	for slot in _slots_passivos:
		_configurar_slot_disponivel(slot, null, classe_id)
	var indice_ativa := 0
	var indice_passiva := 0
	for skill in HeroEquipment.catalogo_de(classe_id):
		if skill == null:
			continue
		if skill.type == SkillResource.Type.ACTIVE and indice_ativa < _slots_ativos.size():
			_configurar_slot_disponivel(_slots_ativos[indice_ativa], skill, classe_id)
			indice_ativa += 1
		elif skill.type == SkillResource.Type.PASSIVE and indice_passiva < _slots_passivos.size():
			_configurar_slot_disponivel(_slots_passivos[indice_passiva], skill, classe_id)
			indice_passiva += 1


func _configurar_slot_disponivel(slot: Button, skill: SkillResource, classe_id: String) -> void:
	slot.set_meta("skill", skill)
	if skill == null:
		slot.text = ""
		slot.icon = null
		slot.disabled = true
		_pintar_slot_disponivel(slot, false)
	else:
		slot.text = ""
		slot.icon = skill.obter_icone()
		slot.disabled = false
		_pintar_slot_disponivel(slot, HeroEquipment.is_equipped(classe_id, skill))


func _atualizar_texto_slot(botao: Button, skill: SkillResource) -> void:
	if skill == null:
		botao.text = TEXTO_SLOT_VAZIO
		botao.icon = null
	else:
		botao.text = ""
		botao.icon = skill.obter_icone()


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


func _on_habilidade_disponivel_pressionada(slot: Button) -> void:
	var classe_id := _obter_classe_id()
	if classe_id == "":
		return
	var skill: Variant = slot.get_meta("skill", null)
	if not (skill is SkillResource):
		return
	var slot_alvo := _slot_ativo_selecionado if skill.type == SkillResource.Type.ACTIVE else _slot_passivo_selecionado
	HeroEquipment.equip_skill(classe_id, skill, slot_alvo)


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


func _pintar_slot_disponivel(botao: Button, equipada: bool) -> void:
	var estilo := StyleBoxFlat.new()
	estilo.set_corner_radius_all(4)
	estilo.set_border_width_all(2)
	if equipada:
		estilo.bg_color = Color(0.18, 0.24, 0.14, 1)
		estilo.border_color = Color(0.55, 0.82, 0.38, 1)
	else:
		estilo.bg_color = Color(0.1, 0.16, 0.1, 1)
		estilo.border_color = Color(0.35, 0.58, 0.32, 0.85)
	botao.add_theme_stylebox_override("normal", estilo)
	botao.add_theme_stylebox_override("hover", estilo)
	botao.add_theme_stylebox_override("pressed", estilo)
	botao.add_theme_stylebox_override("disabled", estilo)


func _pintar_slot_equipado(botao: Button, selecionado: bool) -> void:
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


func _on_cabecalho_gui_input(evento: InputEvent) -> void:
	if _menu and _menu.has_method("_on_cabecalho_gui_input"):
		_menu._on_cabecalho_gui_input(evento)
