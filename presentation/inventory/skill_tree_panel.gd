class_name SkillTreePanel
extends PanelContainer
## Cobre o inventário e abriga a árvore de habilidades.

signal panel_open_changed(is_open: bool)

@onready var botao_voltar: Button = %BotaoVoltarArvore
@onready var cabecalho: HBoxContainer = %CabecalhoArvore
@onready var mapa: SkillTreeMap = %SkillTreeMap
@onready var label_ouro: Label = %LabelOuroArvore
@onready var label_mensagem: Label = %LabelMensagemArvore

var _menu: InventoryMenu


func _ready() -> void:
	hide()
	botao_voltar.pressed.connect(close)
	cabecalho.gui_input.connect(_on_header_gui_input)
	gui_input.connect(_on_header_gui_input)
	if mapa:
		mapa.node_selected.connect(_on_node_selected)


func configure(menu: InventoryMenu) -> void:
	_menu = menu


func is_open() -> bool:
	return visible


func open() -> void:
	if _menu == null or not _menu.visible:
		return
	show()
	update()
	panel_open_changed.emit(true)
	call_deferred("_reforcar_layout")


func update() -> void:
	if _menu == null or mapa == null:
		return
	mapa.configure(_menu.skill_tree_progress(), _menu.get_current_gold())
	if label_ouro:
		label_ouro.text = "Ouro  %d" % _menu.get_current_gold()
	if label_mensagem:
		label_mensagem.text = "Cada habilidade tem até 5 níveis (armazém: 1). Role para baixo."


func _reforcar_layout() -> void:
	if visible:
		panel_open_changed.emit(true)


func close() -> void:
	hide()
	panel_open_changed.emit(false)


func _on_node_selected(id_no: int) -> void:
	if _menu == null:
		return
	var hero_progress := _menu.skill_tree_progress()
	var no := hero_progress.node_by_id(id_no)
	if no.is_empty():
		return
	if hero_progress.is_at_max_level(id_no):
		_show_message("Nível máximo alcançado nesta habilidade.")
		return
	if not hero_progress.can_purchase(id_no):
		_show_message("Desbloqueie todos os nós acima deste primeiro.")
		return
	var nivel_atual := hero_progress.node_level(id_no)
	var custo := SkillTreeDefinition.custo_proximo_nivel(no, nivel_atual)
	if not _menu.try_spend_gold(custo):
		_show_message("Ouro insuficiente (%d necessários)." % custo)
		return
	hero_progress.level_up(id_no)
	_menu.notify_skill_tree_changed()
	update()
	var novo_nivel := hero_progress.node_level(id_no)
	var msg := "Nível %d/%d: %s" % [
		novo_nivel,
		hero_progress.max_level(id_no),
		SkillTreeDefinition.descricao_bonus(no, novo_nivel),
	]
	if int(no.get("tipo", -1)) == SkillTreeDefinition.TipoBonus.ARMAZEM:
		msg += " — nova página do armazém liberada."
	else:
		msg += " (todos os heróis)"
	_show_message(msg)


func _show_message(texto: String) -> void:
	if label_mensagem:
		label_mensagem.text = texto


func _on_header_gui_input(event: InputEvent) -> void:
	if _menu:
		_menu.drag_window_from_event(event)
