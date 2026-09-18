class_name InventoryMenu
extends Control
## Painel flutuante de personagem / inventário.
## Abre acima do idle, sem cobrir o botão de 4 quadrados.

signal closed
signal character_changed(stage_index: int)
signal equipment_changed
signal hero_class_changed(stage_index: int, classe: ClassData)
signal window_released
signal gold_gained(quantidade: int)
signal gold_spent(quantidade: int)
signal skill_tree_changed
signal menu_width_changed
signal stage_started(world: int, stage: int, difficulty: int)

const INVENTARIO_COLUNAS := 10
const INVENTARIO_LINHAS := 5
const TAMANHO_SLOT := Vector2(38, 38)
const TAMANHO_SLOT_EQUIP := Vector2(40, 40)
const TAMANHO_SLOT_PERSONAGEM := Vector2(36, 36)
const EQUIP_COLUNAS := 2
const EQUIP_ESQUERDA: Array[String] = ["Primária", "Secundária", "Capacete", "Peitoral", "Luva", "Calça", "Bota"]
const EQUIP_DIREITA: Array[String] = ["Cinto", "Pingente", "Anel", "Bracelete", "Pet"]
const MARGEM_TOPO_UI := 8.0
const ALTURA_JANELA := 860.0
const ESPACO_RESERVADO_COMBATE := 320.0
var PERSONAGENS: Array[Dictionary] = [
	{"nome": "Guerreiro", "classe": ItemData.RequiredClass.WARRIOR},
	{"nome": "Mago", "classe": ItemData.RequiredClass.MAGE},
	{"nome": "Arqueiro", "classe": ItemData.RequiredClass.ARCHER},
]

@onready var grade_inventario: GridContainer = %GradeInventario
@onready var botao_ordenar_inventario: Button = %BotaoOrdenarInventario
@onready var botao_sair: Button = %BotaoSair
@onready var botao_sair_jogo: Button = %BotaoSairJogo
@onready var botao_configuracoes: Button = %BotaoConfiguracoes
@onready var painel_configuracoes: PanelContainer = %PainelConfiguracoes
@onready var botao_fechar_config: Button = %BotaoFecharConfig
@onready var slider_volume: HSlider = %SliderVolume
@onready var label_volume_valor: Label = %LabelVolumeValor
@onready var titulo_config: Label = %TituloConfig
@onready var label_volume_titulo: Label = %LabelVolumeTitulo
@onready var label_language_title: Label = %LabelLanguageTitle
@onready var option_locale: OptionButton = %OptionLocale
@onready var cabecalho: HBoxContainer = %Cabecalho
@onready var equip_esquerda: VBoxContainer = %EquipEsquerda
@onready var equip_direita: VBoxContainer = %EquipDireita
@onready var painel: PanelContainer = %Painel
@onready var grade_personagens: HBoxContainer = %GradePersonagens
@onready var nome_personagem: Label = %NomePersonagem
@onready var nivel_personagem: Label = %NivelPersonagem
@onready var foto_personagem: TextureRect = %FotoPersonagem
@onready var linha_card_heroi: HBoxContainer = %LinhaCardHeroi
@onready var coluna_ativas: VBoxContainer = %ColunaAtivas
@onready var coluna_passivas: VBoxContainer = %ColunaPassivas
@onready var slot_ativa_0: Button = %SlotSkillMenuAtiva0
@onready var slot_ativa_1: Button = %SlotSkillMenuAtiva1
@onready var slot_passiva_0: Button = %SlotSkillMenuPassiva0
@onready var slot_passiva_1: Button = %SlotSkillMenuPassiva1
@onready var barra_xp_personagem: ProgressBar = %BarraXpPersonagem
@onready var label_xp_personagem: Label = %LabelXpPersonagem
@onready var botao_atributos_personagem: Button = %BotaoAtributosPersonagem
@onready var secao_heroi_visual: SectionVisualOffset = %SecaoHeroiVisual
@onready var host_botao_formacao: SectionVisualOffset = %HostBotaoFormacao
@onready var ui_equipe: TeamSelectionUI = %AreaEquipe
@onready var area_menus: Control = %AreaMenus
@onready var painel_ferraria: ForgePanel = %PainelForgePanel
@onready var painel_armazem: WarehousePanel = %WarehousePanel
@onready var painel_mundos: WorldsPanel = %WorldsPanel
@onready var painel_formacao: FormationPanel = %FormationPanel
@onready var painel_skills: SkillsPanel = %SkillsPanel
@onready var painel_atributos: AttributesPanel = %AttributesPanel
@onready var painel_arvore: SkillTreePanel = %SkillTreePanel
@onready var botao_skills: Button = %BotaoSkills
@onready var botao_inventario: Button = %BotaoInventario
@onready var botao_ferraria: Button = %BotaoForgePanel
@onready var botao_armazem: Button = %BotaoArmazem
@onready var botao_mundo: Button = %BotaoMundo
@onready var label_ouro: Label = %LabelOuro
@onready var painel_ouro: Control = %PainelOuro
@onready var espaco_ouro: Control = %EspacoOuro
@onready var centralizar: Control = %Centralizar

const TIPOS_EQUIP: Dictionary = {
	"Capacete": ItemData.Tipo.CAPACETE,
	"Peitoral": ItemData.Tipo.PEITORAL,
	"Luva": ItemData.Tipo.LUVA,
	"Calça": ItemData.Tipo.CALCA,
	"Bota": ItemData.Tipo.BOTA,
	"Cinto": ItemData.Tipo.CINTO,
	"Primária": ItemData.Tipo.ARMA,
	"Arma": ItemData.Tipo.ARMA,
	"Secundária": ItemData.Tipo.SECUNDARIA,
	"Pingente": ItemData.Tipo.PINGENTE,
	"Anel": ItemData.Tipo.ANEL,
	"Bracelete": ItemData.Tipo.BRACELETE,
	"Pet": ItemData.Tipo.PET,
}

var CLASSES: Array[ClassData] = []

var _dragging: bool = false
var _offset_mouse: Vector2i = Vector2i.ZERO
var _character_index: int = 0
var _character_buttons: Array[Button] = []
var _left_equipment_by_class: Dictionary = {}
var _right_equipment_by_class: Dictionary = {}
var _inventory_slot_list: Array[ItemSlot] = []
var _slot_selecionado: ItemSlot = null
var _forge_button_styles: Dictionary = {}
var _warehouse_button_styles: Dictionary = {}
var _world_button_styles: Dictionary = {}
var _menus_abaixo: bool = false
var _skill_tree_progress := SkillTreeProgress.new()
var query_gold: Callable
var query_slot_progress: Callable

@export var layout_inventario: InventoryLayout = preload("res://presentation/inventory/inventory_layout_default.tres")

const TEXTO_SLOT_SKILL_VAZIO := "+"
const TAMANHO_SLOT_SKILL := Vector2(48, 48)


func _ready() -> void:
	CLASSES = ClassData.catalog()
	_create_character_equipment()
	_create_inventory_slots()
	_setup_inventory_sort_button()
	_create_character_selector()
	botao_sair.pressed.connect(_on_exit_button_pressed)
	botao_sair_jogo.pressed.connect(_on_quit_button_pressed)
	botao_configuracoes.pressed.connect(_on_settings_button_pressed)
	botao_fechar_config.pressed.connect(_close_settings)
	slider_volume.value_changed.connect(_on_volume_changed)
	_setup_locale_selector()
	LocaleService.locale_changed.connect(_on_locale_changed)
	_update_localized_texts()
	botao_configuracoes.icon = _gear_icon()
	botao_configuracoes.add_theme_constant_override("icon_max_width", 20)
	cabecalho.gui_input.connect(_on_header_gui_input)
	painel.gui_input.connect(_on_header_gui_input)
	painel_ferraria.configure(self)
	painel_armazem.configure(self)
	_sync_warehouse_skill_tree()
	painel_mundos.configure(self)
	area_menus.resized.connect(_align_side_panels)
	painel.resized.connect(_align_side_panels)
	botao_ferraria.pressed.connect(_on_forge_button_pressed)
	painel_ferraria.panel_open_changed.connect(_on_forge_visibility_changed)
	painel_armazem.panel_open_changed.connect(_on_warehouse_visibility_changed)
	painel_mundos.panel_open_changed.connect(_on_worlds_visibility_changed)
	painel_mundos.stage_started.connect(_on_stage_started)
	painel_ferraria.gold_gained.connect(_on_forge_gold_spent)
	visibility_changed.connect(_on_menu_visibility_changed)
	if grade_personagens:
		grade_personagens.visible = false
	_store_forge_button_styles()
	_warehouse_button_styles["normal"] = botao_armazem.get_theme_stylebox("normal").duplicate()
	_warehouse_button_styles["hover"] = botao_armazem.get_theme_stylebox("hover").duplicate()
	_warehouse_button_styles["pressed"] = botao_armazem.get_theme_stylebox("pressed").duplicate()
	_world_button_styles["normal"] = botao_mundo.get_theme_stylebox("normal").duplicate()
	_world_button_styles["hover"] = botao_mundo.get_theme_stylebox("hover").duplicate()
	_world_button_styles["pressed"] = botao_mundo.get_theme_stylebox("pressed").duplicate()
	botao_armazem.pressed.connect(_on_warehouse_button_pressed)
	botao_mundo.pressed.connect(_on_world_button_pressed)
	botao_armazem.icon = load("res://sprites/ui/bau.png")
	botao_armazem.text = ""
	botao_armazem.expand_icon = true
	botao_armazem.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	botao_armazem.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	botao_armazem.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	botao_armazem.add_theme_constant_override("icon_max_width", 52)
	botao_armazem.tooltip_text = "Armazém"
	_apply_bottom_bar_icons()
	_connect_main_skill_slots()
	if not HeroEquipment.equipment_changed.is_connected(_on_equipment_skills_changed):
		HeroEquipment.equipment_changed.connect(_on_equipment_skills_changed)
	if botao_skills:
		botao_skills.pressed.connect(_on_skills_button_pressed)
	if botao_atributos_personagem:
		botao_atributos_personagem.pressed.connect(_on_attributes_button_pressed)
	if painel_atributos:
		painel_atributos.configure(self)
		if not painel_atributos.visibility_changed.is_connected(_on_attributes_visibility_changed):
			painel_atributos.panel_open_changed.connect(_on_attributes_visibility_changed)
	if painel_arvore:
		painel_arvore.configure(self)
		if not painel_arvore.visibility_changed.is_connected(_on_skill_tree_visibility_changed):
			painel_arvore.panel_open_changed.connect(_on_skill_tree_visibility_changed)
	botao_inventario.pressed.connect(_on_skill_tree_button_pressed)
	if painel_ouro:
		painel_ouro.resized.connect(_align_gold_spacer)
		_align_gold_spacer()
	call_deferred("_align_gold_spacer")
	_restore_base_panel()
	call_deferred("set_below_combat", _menus_abaixo)
	call_deferred("_align_side_panels")
	call_deferred("_apply_hero_layout")


func _create_character_equipment() -> void:
	for classe in CLASSES:
		var esquerda := _create_equipment_grid("EquipEsq_%s" % classe.id, EQUIP_ESQUERDA)
		esquerda.visible = false
		equip_esquerda.add_child(esquerda)
		_left_equipment_by_class[classe.id] = esquerda

		var direita := _create_equipment_grid("EquipDir_%s" % classe.id, EQUIP_DIREITA)
		direita.visible = false
		equip_direita.add_child(direita)
		_right_equipment_by_class[classe.id] = direita


func _create_equipment_grid(nome_no: String, nomes_slots: Array[String]) -> GridContainer:
	var grade := GridContainer.new()
	grade.name = nome_no
	grade.columns = EQUIP_COLUNAS
	grade.add_theme_constant_override("h_separation", 4)
	grade.add_theme_constant_override("v_separation", 3)
	_create_equipment_slots(grade, nomes_slots)
	return grade


func _create_equipment_slots(grade: GridContainer, nomes: Array[String]) -> void:
	grade.columns = EQUIP_COLUNAS
	var estilo := _create_slot_style()
	for nome in nomes:
		var fundo := ItemSlot.new()
		fundo.name = "Slot%s" % nome.replace(" ", "")
		fundo.custom_minimum_size = TAMANHO_SLOT_EQUIP
		fundo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		fundo.add_theme_stylebox_override("panel", estilo)
		fundo.nome_slot = nome

		var icone := TextureRect.new()
		icone.name = "Icone"
		icone.set_anchors_preset(Control.PRESET_FULL_RECT)
		icone.offset_left = 4.0
		icone.offset_top = 4.0
		icone.offset_right = -4.0
		icone.offset_bottom = -4.0
		icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icone.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fundo.add_child(icone)
		fundo.configure(icone, TIPOS_EQUIP.get(nome, ItemData.Tipo.ARMA), false)
		fundo.item_clicked.connect(_on_slot_clicked)
		fundo.item_double_clicked.connect(_on_slot_double_clicked)
		fundo.item_right_clicked.connect(_on_slot_right_clicked)
		fundo.item_dropped.connect(_on_slot_dropped)
		grade.add_child(fundo)


func _create_inventory_slots() -> void:
	grade_inventario.columns = INVENTARIO_COLUNAS
	var estilo := _create_slot_style()
	var total := INVENTARIO_COLUNAS * INVENTARIO_LINHAS

	for stage_index in total:
		var slot := ItemSlot.new()
		slot.name = "SlotInventario_%02d" % (stage_index + 1)
		slot.custom_minimum_size = TAMANHO_SLOT
		slot.add_theme_stylebox_override("panel", estilo)

		var icone := TextureRect.new()
		icone.name = "Icone"
		icone.set_anchors_preset(Control.PRESET_FULL_RECT)
		icone.offset_left = 4.0
		icone.offset_top = 4.0
		icone.offset_right = -4.0
		icone.offset_bottom = -4.0
		icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(icone)
		slot.configure(icone, ItemData.Tipo.ARMA, true)
		slot.item_clicked.connect(_on_slot_clicked)
		slot.item_double_clicked.connect(_on_slot_double_clicked)
		slot.item_right_clicked.connect(_on_slot_right_clicked)
		slot.item_dropped.connect(_on_slot_dropped)
		grade_inventario.add_child(slot)
		_inventory_slot_list.append(slot)


func _create_character_selector() -> void:
	var estilo_normal := _create_character_style(false)
	for stage_index in PERSONAGENS.size():
		var botao := Button.new()
		botao.name = "Personagem_%d" % (stage_index + 1)
		botao.custom_minimum_size = Vector2(58, 32)
		botao.text = "Herói %d" % (stage_index + 1)
		botao.add_theme_font_size_override("font_size", 11)
		botao.add_theme_color_override("font_color", Color(0.95, 0.88, 0.7, 1))
		botao.add_theme_stylebox_override("normal", estilo_normal)
		botao.add_theme_stylebox_override("hover", _create_character_style(false))
		botao.add_theme_stylebox_override("pressed", _create_character_style(true))
		botao.pressed.connect(select_character.bind(stage_index))
		grade_personagens.add_child(botao)
		_character_buttons.append(botao)
	select_character(0)


func select_character(stage_index: int) -> void:
	if ui_equipe and ui_equipe._party:
		var party: PartyService = ui_equipe._party
		if stage_index < 0 or stage_index >= PartyService.SLOTS or not (party.active_party[stage_index] is ClassData):
			stage_index = party.first_occupied_slot()
	_character_index = stage_index
	var dados: Dictionary = PERSONAGENS[stage_index]
	var hero_progress := _progress_for_index(stage_index)
	nome_personagem.text = str(dados["nome"])
	nivel_personagem.text = "Lv. %d" % int(hero_progress["nivel"])
	_update_xp_bar()
	if painel_atributos and painel_atributos.is_open():
		painel_atributos.update()
	if painel_arvore and painel_arvore.is_open():
		painel_arvore.update()
	if ui_equipe:
		ui_equipe.select_slot(stage_index, false)
	_update_portrait()
	_update_main_skill_slots()

	for i in _character_buttons.size():
		var selecionado := i == stage_index
		var estilo := _create_character_style(selecionado)
		_character_buttons[i].add_theme_stylebox_override("normal", estilo)
		_character_buttons[i].add_theme_stylebox_override("hover", estilo)

	_show_character_equipment(stage_index)
	character_changed.emit(stage_index)
	equipment_changed.emit()


func _show_character_equipment(_indice: int) -> void:
	var id_ativo := _class_id_for_slot(_character_index)
	for id_classe in _left_equipment_by_class.keys():
		var ativo := str(id_classe) == id_ativo
		(_left_equipment_by_class[id_classe] as GridContainer).visible = ativo
		(_right_equipment_by_class[id_classe] as GridContainer).visible = ativo


func current_character_index() -> int:
	return _character_index


func get_equipped_items(stage_index: int = -1) -> Array[ItemData]:
	var itens: Array[ItemData] = []
	if stage_index < 0:
		stage_index = _character_index
	var grades := _grids_for_slot(stage_index)
	for grade in grades:
		for filho in grade.get_children():
			var slot := filho as ItemSlot
			if slot == null:
				slot = filho.get_node_or_null("FundoSlot") as ItemSlot
			if slot and slot.item:
				itens.append(slot.item)
	return itens


func update_displayed_level(nivel: int, xp: int = -1, xp_proximo: int = -1) -> void:
	nivel_personagem.text = "Lv. %d" % nivel
	_update_xp_bar(xp, xp_proximo)
	_sync_party_names()
	if painel_atributos and painel_atributos.is_open():
		painel_atributos.update()


func _progress_for_index(stage_index: int) -> Dictionary:
	if query_slot_progress.is_valid():
		var dados: Variant = query_slot_progress.call(stage_index)
		if dados is Dictionary:
			return dados
	return {"nivel": 1, "xp": 0, "xp_proximo": HeroProgress.BASE_XP_PER_LEVEL}


func _configure_ui_anchor() -> void:
	centralizar.set_anchors_preset(Control.PRESET_TOP_WIDE, false)
	centralizar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	centralizar.grow_vertical = Control.GROW_DIRECTION_BEGIN


func set_below_combat(abaixo: bool) -> void:
	_menus_abaixo = abaixo
	_configure_ui_anchor()
	if abaixo:
		centralizar.offset_top = ESPACO_RESERVADO_COMBATE
		centralizar.offset_bottom = ALTURA_JANELA - MARGEM_TOPO_UI
	else:
		centralizar.offset_top = MARGEM_TOPO_UI
		centralizar.offset_bottom = ALTURA_JANELA - ESPACO_RESERVADO_COMBATE
	_align_side_panels()


func get_clickable_rects() -> Array[Rect2]:
	if not visible:
		return []
	var rects: Array[Rect2] = []
	if painel_formacao and painel_formacao.visible:
		rects.append(painel_formacao.get_global_rect().grow(4.0))
	elif painel_skills and painel_skills.visible:
		rects.append(painel_skills.get_global_rect().grow(4.0))
	elif painel_atributos and painel_atributos.visible:
		rects.append(painel_atributos.get_global_rect().grow(4.0))
	elif painel_arvore and painel_arvore.visible:
		rects.append(painel_arvore.get_global_rect().grow(4.0))
	elif painel:
		rects.append(painel.get_global_rect().grow(4.0))
	if painel_armazem and painel_armazem.visible:
		rects.append(painel_armazem.get_global_rect().grow(4.0))
	if painel_ferraria and painel_ferraria.visible:
		rects.append(painel_ferraria.get_global_rect().grow(4.0))
	if painel_mundos and painel_mundos.visible:
		rects.append(painel_mundos.get_global_rect().grow(4.0))
	if painel_configuracoes and painel_configuracoes.visible:
		rects.append(painel_configuracoes.get_global_rect().grow(4.0))
	return rects


func width_for_window() -> int:
	return PanelLayout.largura_janela(painel, painel_armazem, painel_ferraria, painel_mundos, painel_formacao)


func _align_side_panels() -> void:
	_restore_base_panel()
	PanelLayout.alinhar(painel, area_menus, painel_armazem, painel_ferraria, painel_mundos, _menus_abaixo, painel_formacao, painel_atributos, painel_skills, painel_arvore)
	_align_settings()
	menu_width_changed.emit()
	call_deferred("_apply_hero_layout")


func _apply_hero_layout() -> void:
	var layout := layout_inventario if layout_inventario else InventoryLayout.new()
	if secao_heroi_visual:
		secao_heroi_visual.set_visual_offset(layout.offset_regiao_retrato)
	if host_botao_formacao:
		host_botao_formacao.set_visual_offset(layout.offset_botao_formacao)


func _restore_base_panel() -> void:
	if painel == null:
		return
	painel.modulate = Color.WHITE
	painel.mouse_filter = Control.MOUSE_FILTER_STOP
	if painel.custom_minimum_size.x < 580.0:
		painel.custom_minimum_size.x = 580.0


func _set_inventory_visible(visivel: bool) -> void:
	if painel == null:
		return
	_restore_base_panel()
	if visivel:
		painel.visible = true
		return
	var tam := painel.size
	if tam.y < 1.0:
		tam = painel.get_combined_minimum_size()
		tam.x = maxf(tam.x, painel.custom_minimum_size.x)
	painel.visible = false
	painel.size = tam


func inventory_slots() -> Array[ItemSlot]:
	return _inventory_slot_list


static func ordenar_slots(slots: Array[ItemSlot]) -> void:
	var itens: Array[ItemData] = []
	for slot in slots:
		if slot.item != null:
			itens.append(slot.item)
	itens.sort_custom(ItemData.comparar_ordenacao)
	for i in slots.size():
		slots[i].set_item(itens[i] if i < itens.size() else null)


static func configurar_botao_icone(botao: Button, caminho_icone: String, lado: int = 42) -> void:
	if botao == null:
		return
	var sem_fundo := StyleBoxEmpty.new()
	botao.add_theme_stylebox_override("normal", sem_fundo)
	botao.add_theme_stylebox_override("hover", sem_fundo)
	botao.add_theme_stylebox_override("pressed", sem_fundo)
	botao.add_theme_stylebox_override("focus", sem_fundo)
	botao.text = ""
	if ResourceLoader.exists(caminho_icone):
		botao.icon = load(caminho_icone)
	botao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	botao.expand_icon = true
	botao.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	botao.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	botao.add_theme_constant_override("icon_max_width", lado)
	botao.custom_minimum_size = Vector2(lado, lado)


func _setup_inventory_sort_button() -> void:
	if botao_ordenar_inventario == null:
		return
	configurar_botao_icone(botao_ordenar_inventario, "res://sprites/ui/sort_inventory.png")
	if not botao_ordenar_inventario.pressed.is_connected(_on_inventory_sort_pressed):
		botao_ordenar_inventario.pressed.connect(_on_inventory_sort_pressed)


func _on_inventory_sort_pressed() -> void:
	ordenar_slots(_inventory_slot_list)
	_set_selection(null)
	equipment_changed.emit()
	botao_ordenar_inventario.release_focus()


func warehouse_slots() -> Array[ItemSlot]:
	if painel_armazem:
		return painel_armazem.all_slots()
	var vazio: Array[ItemSlot] = []
	return vazio


func update_gold(valor: int) -> void:
	if label_ouro:
		label_ouro.text = "Ouro  %d" % valor
	if painel_arvore and painel_arvore.is_open():
		painel_arvore.update()


func get_current_gold() -> int:
	if query_gold.is_valid():
		return maxi(0, int(query_gold.call()))
	return 0


func try_spend_gold(valor: int) -> bool:
	if valor < 0:
		return false
	if get_current_gold() < valor:
		return false
	gold_spent.emit(valor)
	return true


func skill_tree_progress() -> SkillTreeProgress:
	return _skill_tree_progress


func global_skill_tree_bonus() -> Dictionary:
	return _skill_tree_progress.global_bonus()


func skill_tree_bonus_for_slot(stage_index: int = -1) -> Dictionary:
	var bonus := global_skill_tree_bonus().duplicate(true)
	if stage_index < 0:
		stage_index = _character_index
	_somar_bonus(bonus, _equipped_gem_bonuses(stage_index))
	return bonus


func _equipped_gem_bonuses(stage_index: int) -> Dictionary:
	var total := SkillTreeDefinition.bonus_vazio()
	for item in get_equipped_items(stage_index):
		var parcial := item.embedded_gem_bonus()
		for chave in parcial.keys():
			total[chave] = float(total.get(chave, 0)) + float(parcial.get(chave, 0))
	return total


static func _somar_bonus(destino: Dictionary, origem: Dictionary) -> void:
	for chave in origem.keys():
		destino[chave] = float(destino.get(chave, 0)) + float(origem.get(chave, 0))


func notify_skill_tree_changed() -> void:
	skill_tree_changed.emit()
	_sync_warehouse_skill_tree()
	if painel_atributos and painel_atributos.is_open():
		painel_atributos.update()
	equipment_changed.emit()
	SaveSystem.save_game()


func _align_gold_spacer() -> void:
	if painel_ouro == null or espaco_ouro == null:
		return
	var altura := maxf(painel_ouro.size.y, painel_ouro.get_combined_minimum_size().y)
	if espaco_ouro.custom_minimum_size.y != altura:
		espaco_ouro.custom_minimum_size = Vector2(0, altura)


func first_empty_inventory_slot() -> ItemSlot:
	for slot in _inventory_slot_list:
		if slot.item == null:
			return slot
	return null


func first_empty_warehouse_slot() -> ItemSlot:
	if painel_armazem:
		return painel_armazem.first_empty_slot()
	return null


func move_item_between_slots(origem: ItemSlot, destino: ItemSlot) -> void:
	_move_item(origem, destino)


func connect_forge_slot(slot: ItemSlot) -> void:
	if not slot.item_clicked.is_connected(_on_slot_clicked):
		slot.item_clicked.connect(_on_slot_clicked)
	if not slot.item_dropped.is_connected(_on_slot_dropped):
		slot.item_dropped.connect(_on_slot_dropped)
	if not slot.item_right_clicked.is_connected(_on_slot_right_clicked):
		slot.item_right_clicked.connect(_on_slot_right_clicked)


func notify_items_changed() -> void:
	equipment_changed.emit()


func drag_window_from_event(event: InputEvent) -> void:
	_on_header_gui_input(event)


func _generate_initial_item() -> void:
	var espada := ItemData.new()
	espada.id = "espada_madeira"
	espada.nome = "Espada de Madeira"
	espada.tipo = ItemData.Tipo.ARMA
	espada.raridade = ItemData.Raridade.COMUM
	espada.nivel_item = ItemData.NIVEIS_ITEM[0]
	espada.dano_bonus = 5
	espada.required_class = ItemData.RequiredClass.ALL
	espada.icone = _create_wooden_sword_icon()
	_inventory_slot_list[0].set_item(espada)


func _create_wooden_sword_icon() -> Texture2D:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var lamina := Color(0.72, 0.5, 0.22, 1)
	var cabo := Color(0.38, 0.22, 0.1, 1)
	var guarda := Color(0.28, 0.18, 0.08, 1)
	for y in range(3, 22):
		for x in range(14, 18):
			img.set_pixel(x, y, lamina)
	for x in range(10, 22):
		img.set_pixel(x, 21, guarda)
		img.set_pixel(x, 22, guarda)
	for y in range(23, 30):
		for x in range(14, 18):
			img.set_pixel(x, y, cabo)
	return ImageTexture.create_from_image(img)


func _on_slot_clicked(slot: ItemSlot) -> void:
	if _slot_selecionado != null and _slot_selecionado != slot:
		if slot.aceita(_slot_selecionado.item) and (_slot_selecionado.aceita(slot.item) or slot.item == null):
			if slot.aceita_qualquer or _can_use_item(_slot_selecionado.item):
				if not _can_move_to_slot(_slot_selecionado, slot):
					return
				_move_item(_slot_selecionado, slot)
				_set_selection(null)
				return
	if slot.item != null:
		_set_selection(slot)
	else:
		_set_selection(null)


func _on_slot_double_clicked(slot: ItemSlot) -> void:
	if slot.item == null:
		return
	if _is_forge_slot(slot):
		return
	if slot.aceita_qualquer:
		if slot.item.is_gem():
			return
		var destino := _current_equipment_slot(slot.item.tipo)
		if destino and _can_use_item(slot.item):
			_move_item(slot, destino)
			_set_selection(null)
	else:
		var vazio := _first_empty_inventory_slot()
		if vazio:
			_move_item(slot, vazio)
			_set_selection(null)


func _on_slot_right_clicked(slot: ItemSlot) -> void:
	if slot.item == null:
		return
	if _is_forge_slot(slot):
		painel_ferraria.interact_slot(slot)
		_set_selection(null)
		equipment_changed.emit()
		return
	if _is_warehouse_slot(slot):
		var vazio_inv := first_empty_inventory_slot()
		if vazio_inv:
			_move_item(slot, vazio_inv)
			_set_selection(null)
		return
	if painel_ferraria.is_open():
		var destino := painel_ferraria.first_empty_slot()
		if destino and _can_move_to_slot(slot, destino):
			_move_item(slot, destino)
			_set_selection(null)
		return
	if painel_armazem.is_open():
		var destino_armazem := painel_armazem.first_empty_slot()
		if destino_armazem:
			_move_item(slot, destino_armazem)
			_set_selection(null)
		return
	_on_slot_double_clicked(slot)


func _is_forge_slot(slot: ItemSlot) -> bool:
	return painel_ferraria != null and painel_ferraria.is_forge_slot(slot)


func _is_warehouse_slot(slot: ItemSlot) -> bool:
	return painel_armazem != null and slot in painel_armazem.all_slots()


func _on_slot_dropped(destino: ItemSlot, _item: ItemData, origem: ItemSlot) -> void:
	if origem == null or destino == null or origem == destino:
		return
	if not destino.aceita(origem.item):
		return
	if not destino.aceita_qualquer and not _can_use_item(origem.item):
		return
	if origem.item != null and not origem.aceita(destino.item) and destino.item != null:
		return
	if not _can_move_to_slot(origem, destino):
		return
	_move_item(origem, destino)
	_set_selection(null)


func _move_item(origem: ItemSlot, destino: ItemSlot) -> void:
	if painel_ferraria and painel_ferraria.is_open():
		var origem_ferraria := painel_ferraria.is_forge_slot(origem)
		var destino_ferraria := painel_ferraria.is_forge_slot(destino)
		if destino_ferraria and not origem_ferraria:
			if painel_ferraria.reserve_item(origem, destino):
				equipment_changed.emit()
			return
		if origem_ferraria and not destino_ferraria:
			if painel_ferraria.is_pending_result(origem):
				if painel_ferraria.collect_result_to(destino):
					equipment_changed.emit()
				return
			painel_ferraria.release_forge_slot(origem)
			equipment_changed.emit()
			return
		if origem_ferraria and destino_ferraria:
			painel_ferraria.swap_reservations(origem, destino)
			equipment_changed.emit()
			return
	if origem.reservado_ferraria or destino.reservado_ferraria:
		return
	var item_origem := origem.item
	var item_destino := destino.item
	origem.set_item(item_destino)
	destino.set_item(item_origem)
	equipment_changed.emit()


func _can_move_to_slot(origem: ItemSlot, destino: ItemSlot) -> bool:
	if origem == null or destino == null:
		return false
	if painel_ferraria == null or not painel_ferraria.is_open():
		if origem.reservado_ferraria or destino.reservado_ferraria:
			return false
		return true
	var origem_ferraria := painel_ferraria.is_forge_slot(origem)
	var destino_ferraria := painel_ferraria.is_forge_slot(destino)
	if origem.reservado_ferraria and not origem_ferraria:
		return false
	if destino.reservado_ferraria:
		return false
	if destino_ferraria and not origem_ferraria:
		if origem.item == null or destino.item != null:
			return false
		if painel_ferraria.is_origin_reserved(origem):
			return false
		if painel_ferraria.is_jewelry_target_slot(destino):
			return painel_ferraria.can_accept_target_jewelry(origem.item)
		if painel_ferraria.is_jewelry_gem_slot(destino):
			return painel_ferraria.can_accept_gem_jewelry(origem.item)
		if painel_ferraria.is_synthesis_slot(destino):
			if not painel_ferraria.can_accept_in_synthesis(origem.item):
				painel_ferraria.notify_blocked_category(origem.item)
				return false
		return true
	if origem_ferraria and not destino_ferraria:
		if painel_ferraria.is_pending_result(origem):
			return destino.item == null and not destino.reservado_ferraria
		return true
	return true


func _set_selection(slot: ItemSlot) -> void:
	if _slot_selecionado and is_instance_valid(_slot_selecionado):
		_slot_selecionado.update_visual(false)
	_slot_selecionado = slot
	if _slot_selecionado:
		_slot_selecionado.update_visual(true)


func _create_selected_slot_style() -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.22, 0.17, 0.1, 1)
	estilo.border_color = Color(0.95, 0.78, 0.32, 1)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(3)
	return estilo


func _current_equipment_slot(tipo: ItemData.Tipo) -> ItemSlot:
	for grade in _grids_for_slot(_character_index):
		for grupo in grade.get_children():
			var fundo := grupo.get_node_or_null("FundoSlot") as ItemSlot
			if fundo and fundo.tipo_aceitavel == tipo:
				return fundo
	return null


func _first_empty_inventory_slot() -> ItemSlot:
	return first_empty_inventory_slot()


func add_item(item: ItemData) -> bool:
	var slot := first_empty_inventory_slot()
	if slot == null:
		slot = first_empty_warehouse_slot()
	if slot == null:
		return false
	slot.set_item(item)
	return true


func get_current_class() -> ClassData:
	if ui_equipe and ui_equipe._party:
		var classe: Variant = ui_equipe._party.active_party[_character_index]
		if classe is ClassData:
			return classe
	return null


func get_equipped_damage(stage_index: int) -> int:
	var total := 0
	for item in get_equipped_items(stage_index):
		total += item.dano_bonus
	return total


func get_equipped_hp(stage_index: int) -> int:
	var total := 0
	for item in get_equipped_items(stage_index):
		total += item.vida_bonus
	return total


func current_hero_stats() -> Dictionary:
	var stage_index := _character_index
	var dados: Dictionary = PERSONAGENS[stage_index] if stage_index >= 0 and stage_index < PERSONAGENS.size() else {}
	var hero_progress := _progress_for_index(stage_index)
	var classe: ClassData = get_current_class()
	var party: PartyService = ui_equipe._party if ui_equipe else null
	var ataque := 0
	var vida := 0
	if party:
		ataque = party.hero_damage(stage_index)
		vida = party.hero_max_hp(stage_index)
	elif classe:
		var nivel := maxi(1, int(hero_progress.get("nivel", 1)))
		ataque = maxi(1, int(round(float(classe.base_damage) * classe.attack_multiplier)))
		ataque += (nivel - 1) * classe.atk_per_level
		vida = classe.base_hp + (nivel - 1) * classe.hp_per_level
	var vel := 100.0
	if classe:
		vel = classe.attack_speed * 100.0
	var bonus: Dictionary = skill_tree_bonus_for_slot(stage_index)
	var atk_extra := 0
	var vida_extra := 0
	if not party:
		atk_extra = int(bonus.get("ataque", 0))
		vida_extra = int(bonus.get("vida", 0))
		var pct := float(bonus.get("ataque_pct", 0.0))
		ataque = maxi(1, int(round(float(ataque + atk_extra) * (1.0 + pct / 100.0))))
		vida += vida_extra
	return {
		"ataque": ataque,
		"vida": vida,
		"nivel": int(hero_progress.get("nivel", 1)),
		"xp": int(hero_progress.get("xp", 0)),
		"xp_proximo": int(hero_progress.get("xp_proximo", HeroProgress.BASE_XP_PER_LEVEL)),
		"bonus_xp": float(bonus.get("bonus_xp", 0.0)),
		"bonus_ouro": float(bonus.get("bonus_ouro", 0.0)),
		"vel_ataque": vel + float(bonus.get("vel_ataque", 0.0)),
		"crit_chance": float(bonus.get("crit_chance", 0.0)),
		"crit_dano": float(bonus.get("crit_dano", 0.0)),
		"evasao": float(bonus.get("evasao", 0.0)),
		"res_fisica": float(bonus.get("res_fisica", 0.0)),
		"res_arcana": float(bonus.get("res_arcana", 0.0)),
		"res_elemental": float(bonus.get("res_elemental", 0.0)),
	}


func _update_xp_bar(xp: int = -1, xp_proximo: int = -1) -> void:
	if barra_xp_personagem == null:
		return
	var hero_progress := _progress_for_index(_character_index)
	if xp < 0:
		xp = int(hero_progress.get("xp", 0))
	if xp_proximo <= 0:
		xp_proximo = maxi(1, int(hero_progress.get("xp_proximo", HeroProgress.BASE_XP_PER_LEVEL)))
	var nivel := int(hero_progress.get("nivel", 1))
	barra_xp_personagem.max_value = float(xp_proximo)
	barra_xp_personagem.value = clampf(float(xp), 0.0, float(xp_proximo))
	if label_xp_personagem:
		label_xp_personagem.text = "Nv.%d  %d/%d" % [nivel, xp, xp_proximo]


func setup_party(party: PartyService) -> void:
	ui_equipe.configure(party, _character_index)
	call_deferred("_apply_hero_layout")
	if not ui_equipe.slot_selected.is_connected(select_character):
		ui_equipe.slot_selected.connect(select_character)
	if not ui_equipe.class_assigned.is_connected(_on_class_assigned):
		ui_equipe.class_assigned.connect(_on_class_assigned)
	if not ui_equipe.formation_requested.is_connected(_on_formation_requested):
		ui_equipe.formation_requested.connect(_on_formation_requested)
	if painel_formacao:
		painel_formacao.configure(self, party)
		if not painel_formacao.slot_selected.is_connected(select_character):
			painel_formacao.slot_selected.connect(select_character)
		if not painel_formacao.visibility_changed.is_connected(_on_formation_visibility_changed):
			painel_formacao.panel_open_changed.connect(_on_formation_visibility_changed)
	if painel_skills:
		painel_skills.configure(self, party)
		if not painel_skills.slot_selected.is_connected(select_character):
			painel_skills.slot_selected.connect(select_character)
		if not painel_skills.visibility_changed.is_connected(_on_skills_visibility_changed):
			painel_skills.panel_open_changed.connect(_on_skills_visibility_changed)
	if painel_atributos:
		painel_atributos.configure(self)
		if not painel_atributos.visibility_changed.is_connected(_on_attributes_visibility_changed):
			painel_atributos.panel_open_changed.connect(_on_attributes_visibility_changed)
	if painel_arvore:
		painel_arvore.configure(self)
		if not painel_arvore.visibility_changed.is_connected(_on_skill_tree_visibility_changed):
			painel_arvore.panel_open_changed.connect(_on_skill_tree_visibility_changed)
	if not party.party_changed.is_connected(_on_party_changed):
		party.party_changed.connect(_on_party_changed)
	_sync_party_names()
	_show_character_equipment(_character_index)
	_update_portrait()


func _on_class_assigned(_indice: int, _classe: ClassData) -> void:
	_sync_party_names()
	_show_character_equipment(_character_index)
	_update_portrait()
	hero_class_changed.emit(_character_index, get_current_class())
	equipment_changed.emit()


func _on_party_changed() -> void:
	_sync_party_names()
	select_character(_character_index)
	hero_class_changed.emit(_character_index, get_current_class())
	equipment_changed.emit()


func _sync_party_names() -> void:
	if ui_equipe == null or ui_equipe._party == null:
		return
	var party: PartyService = ui_equipe._party
	for i in PartyService.SLOTS:
		var classe: Variant = party.active_party[i]
		var dados: Dictionary = PERSONAGENS[i].duplicate()
		if classe is ClassData:
			dados["nome"] = (classe as ClassData).get_localized_name()
			dados["classe"] = (classe as ClassData).item_class
		else:
			dados["nome"] = tr(LocaleKeys.UI_EMPTY_SLOT)
		PERSONAGENS[i] = dados
		if i < _character_buttons.size():
			var hero_progress := _progress_for_index(i)
			_character_buttons[i].text = "%s Lv.%d" % [dados["nome"], int(hero_progress.get("nivel", 1))]
	nome_personagem.text = str(PERSONAGENS[_character_index]["nome"])


func _update_portrait() -> void:
	if foto_personagem == null:
		return
	var classe: ClassData = get_current_class()
	foto_personagem.texture = classe.character_sprite if classe else null
	foto_personagem.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _connect_main_skill_slots() -> void:
	_bind_main_skill_slot(slot_ativa_0, SkillResource.Type.ACTIVE, 0)
	_bind_main_skill_slot(slot_ativa_1, SkillResource.Type.ACTIVE, 1)
	_bind_main_skill_slot(slot_passiva_0, SkillResource.Type.PASSIVE, 0)
	_bind_main_skill_slot(slot_passiva_1, SkillResource.Type.PASSIVE, 1)


func _bind_main_skill_slot(botao: Button, tipo: SkillResource.Type, stage_index: int) -> void:
	if botao == null:
		return
	botao.pressed.connect(_on_main_skill_slot_pressed.bind(tipo, stage_index))
	SkillTooltip.vincular(botao, func() -> SkillResource:
		var classe: ClassData = get_current_class()
		if classe == null:
			return null
		return HeroEquipment.get_equipped(classe.id, tipo, stage_index)
	)


func _on_equipment_skills_changed(_classe_id: String) -> void:
	_update_main_skill_slots()


func _update_main_skill_slots() -> void:
	if linha_card_heroi == null:
		return
	var classe: ClassData = get_current_class()
	var mostrar := classe != null
	if coluna_ativas:
		coluna_ativas.visible = mostrar
	if coluna_passivas:
		coluna_passivas.visible = mostrar
	if not mostrar:
		return
	var classe_id := classe.id
	_apply_skill_slot_text(slot_ativa_0, HeroEquipment.get_equipped(classe_id, SkillResource.Type.ACTIVE, 0))
	_apply_skill_slot_text(slot_ativa_1, HeroEquipment.get_equipped(classe_id, SkillResource.Type.ACTIVE, 1))
	_apply_skill_slot_text(slot_passiva_0, HeroEquipment.get_equipped(classe_id, SkillResource.Type.PASSIVE, 0))
	_apply_skill_slot_text(slot_passiva_1, HeroEquipment.get_equipped(classe_id, SkillResource.Type.PASSIVE, 1))


func _apply_skill_slot_text(botao: Button, skill: SkillResource) -> void:
	if botao == null:
		return
	if skill == null:
		botao.text = TEXTO_SLOT_SKILL_VAZIO
		SkillIcons.apply_to_button(botao, null, TAMANHO_SLOT_SKILL)
	else:
		botao.text = ""
		SkillIcons.apply_to_button(botao, skill, TAMANHO_SLOT_SKILL)


func _on_main_skill_slot_pressed(tipo: SkillResource.Type, indice_slot: int) -> void:
	if get_current_class() == null:
		return
	open_equipment_skills(_character_index, tipo, indice_slot)


func _class_can_use(item: ItemData) -> bool:
	if item == null:
		return true
	if item.required_class == ItemData.RequiredClass.ALL:
		return true
	var classe: ClassData = get_current_class()
	if classe == null:
		return false
	return classe.item_class == item.required_class


func _current_hero_level() -> int:
	return int(_progress_for_index(_character_index).get("nivel", 1))


func _can_use_item(item: ItemData) -> bool:
	if item == null:
		return true
	if not _class_can_use(item):
		return false
	return item.can_equip(_current_hero_level())


func fill_initial_item_if_empty() -> void:
	for slot in _inventory_slot_list:
		if slot.item:
			return
	_generate_initial_item()


func serialize_inventory() -> Array:
	var lista: Array = []
	for slot in _inventory_slot_list:
		lista.append(slot.item.to_dictionary() if slot.item else {})
	return lista


func apply_inventory(lista: Array) -> void:
	for i in _inventory_slot_list.size():
		var item: ItemData = null
		if i < lista.size() and lista[i] is Dictionary:
			item = ItemData.de_dicionario(lista[i])
		_inventory_slot_list[i].set_item(item)


func update_world_progress(world: int, stage: int, difficulty: int, liberadas: Array) -> void:
	if painel_mundos:
		painel_mundos.set_state(world, stage, difficulty, liberadas)


func serialize_warehouse() -> Dictionary:
	return painel_armazem.serialize() if painel_armazem else {}


func apply_warehouse(dados: Variant) -> void:
	if painel_armazem:
		painel_armazem.aplicar(dados)
	_sync_warehouse_skill_tree()


func serialize_skill_tree() -> Dictionary:
	return _skill_tree_progress.serialize()


func apply_skill_tree(dados: Variant) -> void:
	_skill_tree_progress.aplicar(dados)
	_sync_warehouse_skill_tree()


func _sync_warehouse_skill_tree() -> void:
	if painel_armazem == null:
		return
	painel_armazem.apply_skill_tree_unlocks(_skill_tree_progress.unlocked_warehouse_indices())


func serialize_equipment() -> Dictionary:
	var todos: Dictionary = {}
	for id_classe in _left_equipment_by_class.keys():
		var lista: Array = []
		for slot in _slots_for_class(str(id_classe)):
			lista.append({
				"tipo": int(slot.tipo_aceitavel),
				"item": slot.item.to_dictionary() if slot.item else {},
			})
		todos[str(id_classe)] = lista
	return todos


func apply_equipment(todos: Variant) -> void:
	if todos is Dictionary:
		for id_classe in _left_equipment_by_class.keys():
			var chave := str(id_classe)
			var lista: Array = todos[chave] if todos.has(chave) and todos[chave] is Array else []
			_apply_slot_list(_slots_for_class(chave), lista)
		return
	if todos is Array:
		var ids_antigos: Array[String] = ["warrior", "mage", "archer"]
		for i in mini(todos.size(), ids_antigos.size()):
			if todos[i] is Array:
				_apply_slot_list(_slots_for_class(ids_antigos[i]), todos[i])


func _apply_slot_list(slots: Array[ItemSlot], lista: Array) -> void:
	var por_tipo: Dictionary = {}
	for entrada in lista:
		if entrada is Dictionary:
			por_tipo[int(entrada.get("tipo", -1))] = entrada.get("item", {})
	for slot in slots:
		var item: ItemData = null
		var dados: Variant = por_tipo.get(int(slot.tipo_aceitavel), {})
		if dados is Dictionary:
			item = ItemData.de_dicionario(dados)
		slot.set_item(item)


func _class_id_for_slot(stage_index: int) -> String:
	if ui_equipe and ui_equipe._party:
		var classe: Variant = ui_equipe._party.active_party[stage_index]
		if classe is ClassData:
			return (classe as ClassData).id
	return ""


func _grids_for_slot(stage_index: int) -> Array[GridContainer]:
	return _grids_for_class(_class_id_for_slot(stage_index))


func _grids_for_class(id_classe: String) -> Array[GridContainer]:
	var grades: Array[GridContainer] = []
	if id_classe == "" or not _left_equipment_by_class.has(id_classe):
		return grades
	grades.append(_left_equipment_by_class[id_classe])
	grades.append(_right_equipment_by_class[id_classe])
	return grades


func _slots_for_class(id_classe: String) -> Array[ItemSlot]:
	var slots: Array[ItemSlot] = []
	for grade in _grids_for_class(id_classe):
		for filho in grade.get_children():
			var slot := filho as ItemSlot
			if slot == null:
				slot = filho.get_node_or_null("FundoSlot") as ItemSlot
			if slot:
				slots.append(slot)
	return slots


func _create_character_style(selecionado: bool) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	if selecionado:
		estilo.bg_color = Color(0.22, 0.17, 0.1, 1)
		estilo.border_color = Color(0.95, 0.78, 0.32, 1)
		estilo.set_border_width_all(3)
	else:
		estilo.bg_color = Color(0.08, 0.07, 0.06, 1)
		estilo.border_color = Color(0.42, 0.35, 0.24, 1)
		estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(3)
	return estilo


func _create_slot_style() -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.06, 0.05, 0.04, 1)
	estilo.border_color = Color(0.72, 0.58, 0.28, 1)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(3)
	return estilo


func _apply_bottom_bar_icons() -> void:
	if botao_skills:
		_setup_bar_button(botao_skills, "skills")
	_setup_bar_button(botao_inventario, "inventario")
	_setup_bar_button(botao_ferraria, "ferraria")
	_setup_bar_button(botao_mundo, "world")


func _setup_bar_button(botao: Button, chave: String, destacado: bool = false) -> void:
	if botao == null:
		return
	botao.icon = InterfaceIcons.bar_icon(chave)
	botao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	botao.expand_icon = true
	botao.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	botao.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	botao.add_theme_constant_override("icon_max_width", 18)
	botao.add_theme_constant_override("h_separation", 4)
	if not destacado:
		return
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.24, 0.18, 0.1, 1)
	estilo.border_color = Color(0.95, 0.78, 0.32, 1)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(4)
	estilo.content_margin_left = 8
	estilo.content_margin_right = 8
	estilo.content_margin_top = 6
	estilo.content_margin_bottom = 6
	botao.add_theme_stylebox_override("normal", estilo)
	botao.add_theme_stylebox_override("hover", estilo)
	botao.add_theme_stylebox_override("pressed", estilo)


func _store_forge_button_styles() -> void:
	_forge_button_styles["normal"] = botao_ferraria.get_theme_stylebox("normal").duplicate()
	_forge_button_styles["hover"] = botao_ferraria.get_theme_stylebox("hover").duplicate()
	_forge_button_styles["pressed"] = botao_ferraria.get_theme_stylebox("pressed").duplicate()


func _on_forge_button_pressed() -> void:
	if painel_ferraria.is_open():
		painel_ferraria.close()
	else:
		_close_right_panels(painel_ferraria)
		painel_ferraria.open()
	botao_ferraria.release_focus()


func _on_warehouse_button_pressed() -> void:
	painel_armazem.toggle()
	botao_armazem.release_focus()


func _on_world_button_pressed() -> void:
	if painel_mundos.is_open():
		painel_mundos.close()
	else:
		_close_right_panels(painel_mundos)
		painel_mundos.open()
	botao_mundo.release_focus()


func _on_formation_requested() -> void:
	if painel_formacao.is_open():
		painel_formacao.close()
		return
	_close_overlay_panels(painel_formacao)
	_close_right_panels()
	painel_formacao.open()


func _on_formation_visibility_changed(aberta: bool) -> void:
	_set_inventory_visible(not aberta)
	_align_side_panels()
	call_deferred("_align_side_panels")


func _on_skills_button_pressed() -> void:
	if painel_skills and painel_skills.is_open():
		painel_skills.close()
	else:
		_open_skills()
	if botao_skills:
		botao_skills.release_focus()


func open_equipment_skills(
	slot_heroi: int,
	tipo_slot: SkillResource.Type = SkillResource.Type.ACTIVE,
	indice_slot: int = 0
) -> void:
	_open_skills(slot_heroi, tipo_slot, indice_slot)


func _open_skills(
	slot_heroi: int = -1,
	tipo_slot: SkillResource.Type = SkillResource.Type.ACTIVE,
	indice_slot: int = 0
) -> void:
	_close_overlay_panels(painel_skills)
	_close_right_panels()
	if painel_skills:
		var heroi := slot_heroi if slot_heroi >= 0 else _character_index
		painel_skills.open(heroi, tipo_slot, indice_slot)


func _on_skills_visibility_changed(aberta: bool) -> void:
	_set_inventory_visible(not aberta)
	_align_side_panels()
	call_deferred("_align_side_panels")


func _on_attributes_button_pressed() -> void:
	if painel_atributos and painel_atributos.is_open():
		painel_atributos.close()
	else:
		_open_attributes()
	if botao_atributos_personagem:
		botao_atributos_personagem.release_focus()


func _open_attributes() -> void:
	_close_overlay_panels(painel_atributos)
	if painel_atributos:
		painel_atributos.open()


func _on_skill_tree_button_pressed() -> void:
	if painel_arvore and painel_arvore.is_open():
		painel_arvore.close()
	else:
		_open_skill_tree()
	botao_inventario.release_focus()


func _open_skill_tree() -> void:
	_close_overlay_panels(painel_arvore)
	_close_right_panels()
	if painel_arvore:
		painel_arvore.open()


func _on_skill_tree_visibility_changed(aberta: bool) -> void:
	if painel:
		painel.visible = not aberta
	_align_side_panels()
	call_deferred("_align_side_panels")


func _on_attributes_visibility_changed(aberta: bool) -> void:
	_set_inventory_visible(not aberta)
	_align_side_panels()
	call_deferred("_align_side_panels")


func _close_overlay_panels(exceto: Control = null) -> void:
	if painel_formacao and painel_formacao != exceto and painel_formacao.is_open():
		painel_formacao.close()
	if painel_atributos and painel_atributos != exceto and painel_atributos.is_open():
		painel_atributos.close()
	if painel_skills and painel_skills != exceto and painel_skills.is_open():
		painel_skills.close()
	if painel_arvore and painel_arvore != exceto and painel_arvore.is_open():
		painel_arvore.close()


func _close_right_panels(exceto: Control = null) -> void:
	if painel_ferraria and painel_ferraria != exceto and painel_ferraria.is_open():
		painel_ferraria.close()
	if painel_mundos and painel_mundos != exceto and painel_mundos.is_open():
		painel_mundos.close()


func _on_forge_visibility_changed(aberta: bool) -> void:
	if not aberta:
		_set_selection(null)
		_restore_forge_button_style()
		_align_side_panels()
		return
	var estilo := _create_active_forge_button_style()
	botao_ferraria.add_theme_stylebox_override("normal", estilo)
	botao_ferraria.add_theme_stylebox_override("hover", estilo)
	botao_ferraria.add_theme_stylebox_override("pressed", estilo)
	_align_side_panels()


func _on_warehouse_visibility_changed(aberta: bool) -> void:
	if aberta:
		var estilo := _create_active_forge_button_style()
		botao_armazem.add_theme_stylebox_override("normal", estilo)
		botao_armazem.add_theme_stylebox_override("hover", estilo)
		botao_armazem.add_theme_stylebox_override("pressed", estilo)
		_align_side_panels()
		return
	for nome in _warehouse_button_styles.keys():
		botao_armazem.add_theme_stylebox_override(str(nome), _warehouse_button_styles[nome])
	botao_armazem.release_focus()
	botao_armazem.set_pressed_no_signal(false)
	_align_side_panels()


func _restore_forge_button_style() -> void:
	for nome in _forge_button_styles.keys():
		botao_ferraria.add_theme_stylebox_override(str(nome), _forge_button_styles[nome])
	botao_ferraria.release_focus()
	botao_ferraria.set_pressed_no_signal(false)


func _create_active_forge_button_style() -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.content_margin_left = 8
	estilo.content_margin_top = 7
	estilo.content_margin_right = 8
	estilo.content_margin_bottom = 7
	estilo.bg_color = Color(0.32, 0.24, 0.16, 1)
	estilo.border_color = Color(0.95, 0.78, 0.32, 1)
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(4)
	return estilo


func _on_worlds_visibility_changed(aberta: bool) -> void:
	if aberta:
		var estilo := _create_active_forge_button_style()
		botao_mundo.add_theme_stylebox_override("normal", estilo)
		botao_mundo.add_theme_stylebox_override("hover", estilo)
		botao_mundo.add_theme_stylebox_override("pressed", estilo)
		_align_side_panels()
		return
	for nome in _world_button_styles.keys():
		botao_mundo.add_theme_stylebox_override(str(nome), _world_button_styles[nome])
	botao_mundo.release_focus()
	botao_mundo.set_pressed_no_signal(false)
	_align_side_panels()


func _on_stage_started(world: int, stage: int, difficulty: int) -> void:
	stage_started.emit(world, stage, difficulty)


func _on_forge_gold_spent(quantidade: int) -> void:
	gold_gained.emit(quantidade)


func _on_menu_visibility_changed() -> void:
	if not visible:
		painel_ferraria.close()
		painel_armazem.close()
		painel_mundos.close()
		_close_overlay_panels()
		_close_settings()
		return
	call_deferred("_align_side_panels")


func _on_exit_button_pressed() -> void:
	hide()
	closed.emit()


func _on_quit_button_pressed() -> void:
	SaveSystem.save_game()
	get_tree().quit()


func _on_settings_button_pressed() -> void:
	if painel_configuracoes.visible:
		_close_settings()
	else:
		_open_settings()


func _open_settings() -> void:
	slider_volume.set_value_no_signal(float(AudioManager.get_volume_percent()))
	_update_volume_text(int(slider_volume.value))
	_sync_locale_selector()
	_update_localized_texts()
	painel_configuracoes.show()
	_align_settings()
	menu_width_changed.emit()


func _close_settings() -> void:
	if painel_configuracoes:
		painel_configuracoes.hide()
	menu_width_changed.emit()


func _align_settings() -> void:
	if painel_configuracoes == null or not painel_configuracoes.visible or painel == null:
		return
	var tam := painel_configuracoes.get_combined_minimum_size()
	tam.x = maxf(tam.x, painel_configuracoes.custom_minimum_size.x)
	painel_configuracoes.size = tam
	var origem := painel.position
	if painel_formacao and painel_formacao.visible:
		origem = painel_formacao.position
	elif painel_skills and painel_skills.visible:
		origem = painel_skills.position
	elif painel_atributos and painel_atributos.visible:
		origem = painel_atributos.position
	elif painel_arvore and painel_arvore.visible:
		origem = painel_arvore.position
	painel_configuracoes.position = origem + Vector2(
		painel.size.x - tam.x,
		0.0
	)


func _on_volume_changed(valor: float) -> void:
	var percentual := int(valor)
	AudioManager.set_volume_percent(percentual)
	_update_volume_text(percentual)


func _update_volume_text(percentual: int) -> void:
	if label_volume_valor:
		label_volume_valor.text = tr(LocaleKeys.SETTINGS_VOLUME_PERCENT) % percentual


func _setup_locale_selector() -> void:
	if option_locale == null:
		return
	option_locale.clear()
	for locale_code in LocaleService.get_available_locales():
		option_locale.add_item(LocaleService.locale_display_name(locale_code), option_locale.item_count)
		option_locale.set_item_metadata(option_locale.item_count - 1, locale_code)
	option_locale.item_selected.connect(_on_locale_selected)


func _sync_locale_selector() -> void:
	if option_locale == null:
		return
	var atual := LocaleService.get_locale()
	for i in option_locale.item_count:
		if str(option_locale.get_item_metadata(i)) == atual:
			option_locale.select(i)
			return


func _on_locale_selected(stage_index: int) -> void:
	if option_locale == null:
		return
	var locale_code := str(option_locale.get_item_metadata(stage_index))
	LocaleService.set_locale(locale_code)


func _on_locale_changed(_locale_code: String) -> void:
	_update_localized_texts()
	_sync_locale_selector()
	_sync_party_names()
	if painel_mundos:
		painel_mundos.refresh_locale()


func _update_localized_texts() -> void:
	if titulo_config:
		titulo_config.text = tr(LocaleKeys.SETTINGS_TITLE).to_upper()
	if label_volume_titulo:
		label_volume_titulo.text = tr(LocaleKeys.SETTINGS_VOLUME)
	if label_language_title:
		label_language_title.text = tr(LocaleKeys.SETTINGS_LANGUAGE)
	if option_locale:
		for i in option_locale.item_count:
			var locale_code := str(option_locale.get_item_metadata(i))
			option_locale.set_item_text(i, LocaleService.locale_display_name(locale_code))


func _gear_icon() -> Texture2D:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cor := Color(0.95, 0.88, 0.7, 1)
	var centro := Vector2(16, 16)
	for i in 8:
		var ang := float(i) * TAU / 8.0
		var p: Vector2 = centro + Vector2(cos(ang), sin(ang)) * 11.0
		_fill_circle(img, p, 3.2, cor)
	_fill_circle(img, centro, 8.0, cor)
	_fill_circle(img, centro, 3.4, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)


func _fill_circle(img: Image, centro: Vector2, raio: float, cor: Color) -> void:
	var r := int(ceil(raio))
	for y in range(int(centro.y) - r, int(centro.y) + r + 1):
		for x in range(int(centro.x) - r, int(centro.x) + r + 1):
			if Vector2(x, y).distance_to(centro) <= raio:
				if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
					continue
				img.set_pixel(x, y, cor)


func _on_header_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse := event as InputEventMouseButton
		var soltou: bool = _dragging and not mouse.pressed
		_dragging = mouse.pressed
		if _dragging:
			_offset_mouse = DisplayServer.mouse_get_position() - DisplayServer.window_get_position()
		elif soltou:
			window_released.emit()
	elif event is InputEventMouseMotion and _dragging:
		DisplayServer.window_set_position(DisplayServer.mouse_get_position() - _offset_mouse)
