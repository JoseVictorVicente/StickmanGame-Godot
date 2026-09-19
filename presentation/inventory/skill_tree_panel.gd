class_name SkillTreePanel
extends PanelContainer
## Cobre o inventário e abriga a árvore de habilidades.

signal panel_open_changed(is_open: bool)

@onready var back_button: Button = %SkillTreeBackButton
@onready var cabecalho: HBoxContainer = %SkillTreeHeader
@onready var mapa: SkillTreeMap = %SkillTreeMap
@onready var gold_label: Label = %SkillTreeGoldLabel
@onready var message_label: Label = %SkillTreeMessageLabel
@onready var title_label: Label = $Conteudo/SkillTreeHeader/BannerTitulo/Titulo

var _menu: InventoryMenu


func _ready() -> void:
	hide()
	back_button.pressed.connect(close)
	cabecalho.gui_input.connect(_on_header_gui_input)
	gui_input.connect(_on_header_gui_input)
	if mapa:
		mapa.node_selected.connect(_on_node_selected)
	LocaleService.locale_changed.connect(_on_locale_changed)
	_update_localized_texts()


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
	call_deferred("_enforce_layout")


func update() -> void:
	if _menu == null or mapa == null:
		return
	mapa.configure(_menu.skill_tree_progress(), _menu.get_current_gold())
	if gold_label:
		gold_label.text = tr(LocaleKeys.UI_GOLD_FORMAT) % _menu.get_current_gold()
	if message_label:
		message_label.text = tr(LocaleKeys.TREE_HINT)


func _enforce_layout() -> void:
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
		_show_message(tr(LocaleKeys.TREE_MAX_LEVEL))
		return
	if not hero_progress.can_purchase(id_no):
		_show_message(tr(LocaleKeys.TREE_UNLOCK_FIRST))
		return
	var nivel_atual := hero_progress.node_level(id_no)
	var custo := SkillTreeDefinition.next_level_cost(no, nivel_atual)
	if not _menu.try_spend_gold(custo):
		_show_message(tr(LocaleKeys.TREE_NOT_ENOUGH_GOLD) % custo)
		return
	hero_progress.level_up(id_no)
	_menu.notify_skill_tree_changed()
	update()
	var novo_nivel := hero_progress.node_level(id_no)
	var msg := tr(LocaleKeys.TREE_LEVEL_UP) % [
		novo_nivel,
		hero_progress.max_level(id_no),
		SkillTreeDefinition.bonus_description(no, novo_nivel),
	]
	if int(no.get("type", -1)) == SkillTreeDefinition.BonusType.WAREHOUSE:
		msg += tr(LocaleKeys.TREE_WAREHOUSE_UNLOCK)
	else:
		msg += tr(LocaleKeys.TREE_ALL_HEROES)
	_show_message(msg)


func _show_message(texto: String) -> void:
	if message_label:
		message_label.text = texto


func refresh_locale() -> void:
	_update_localized_texts()
	update()


func _update_localized_texts() -> void:
	if title_label:
		title_label.text = tr(LocaleKeys.TREE_TITLE).to_upper()
	if back_button:
		back_button.tooltip_text = tr(LocaleKeys.BTN_BACK_INVENTORY)
	if mapa:
		mapa.queue_redraw()


func _on_locale_changed(_locale_code: String) -> void:
	_update_localized_texts()
	if is_open():
		update()


func _on_header_gui_input(event: InputEvent) -> void:
	if _menu:
		_menu.drag_window_from_event(event)
