class_name WorldsPanel
extends Control
## Side panel: portal hall, dimension briefing, and trail map.

const WorldCatalog := preload("res://data/world_catalog.gd")

enum PanelView { PORTAL_HALL, REALM_BRIEFING, TRAIL_MAP }

signal panel_open_changed(is_open: bool)
signal stage_started(world: int, stage: int, difficulty: int)

@onready var back_button: Button = %WorldsBackButton
@onready var close_button: Button = %CloseWorldsButton
@onready var title_label: Label = %WorldsTitle
@onready var header: VBoxContainer = %WorldsHeader
@onready var hall_view = %WorldListPanel
@onready var briefing_view = %RealmBriefingPanel
@onready var trail_view = %PanelStageMap
@onready var difficulty_footer: VBoxContainer = $Margem/Conteudo/RodapeDificuldade
@onready var difficulty_button: Button = %DifficultyButton
@onready var difficulty_menu_hall: PanelContainer = %DifficultyMenuHall
@onready var difficulty_options_hall: VBoxContainer = %DifficultyOptionsHall
@onready var difficulty_menu_backdrop: ColorRect = %DifficultyMenuBackdrop

var _menu: InventoryMenu
var _panel_view: PanelView = PanelView.PORTAL_HALL
var _world_menu_open: int = 1
var _current_world: int = 1
var _current_stage: int = 1
var _difficulty: int = WorldProgress.Difficulty.EASY
var _unlocked: Array[int] = [1, 1, 1]
var _difficulty_option_buttons: Array[Button] = []
var _option_style_normal: StyleBoxFlat
var _option_style_active: StyleBoxFlat
var _option_style_locked: StyleBoxFlat


func _ready() -> void:
	hide()
	_cache_option_styles()
	close_button.pressed.connect(close)
	back_button.pressed.connect(_on_back_pressed)
	briefing_view.enter_portal_pressed.connect(_show_trail_map)
	hall_view.portal_pressed.connect(_on_portal_pressed)
	trail_view.stage_pressed.connect(_on_stage_pressed)
	difficulty_button.pressed.connect(_toggle_difficulty_menu)
	difficulty_menu_backdrop.gui_input.connect(_on_difficulty_backdrop_gui_input)
	header.gui_input.connect(_on_header_gui_input)
	gui_input.connect(_on_header_gui_input)
	_wire_difficulty_options()
	_show_portal_hall()
	_update_difficulty_button()
	LocaleService.locale_changed.connect(_on_locale_changed)
	_refresh_locale()


func configure(menu: InventoryMenu) -> void:
	_menu = menu


func set_state(world: int, stage: int, difficulty: int, liberadas: Array) -> void:
	var previous_world := _current_world
	_current_world = clampi(world, 1, WorldProgress.TOTAL_WORLDS)
	_current_stage = clampi(stage, 1, WorldProgress.STAGES_PER_WORLD)
	_difficulty = clampi(difficulty, 0, 2)
	_unlocked.clear()
	for i in 3:
		var value := 1
		if i < liberadas.size():
			value = clampi(int(liberadas[i]), 1, WorldProgress.FULL_PROGRESS)
		_unlocked.append(value)
	if not WorldProgress.is_difficulty_unlocked(_difficulty, _unlocked):
		_difficulty = WorldProgress.Difficulty.EASY
		while _difficulty < 2 and WorldProgress.is_difficulty_unlocked(_difficulty + 1, _unlocked):
			_difficulty += 1
	_update_difficulty_button()
	_refresh_active_view(previous_world)


func refresh_locale() -> void:
	_refresh_locale()


func is_open() -> bool:
	return visible


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func open() -> void:
	if _menu == null or not _menu.visible:
		return
	_show_portal_hall()
	show()
	panel_open_changed.emit(true)


func preview_briefing(world: int = 1) -> void:
	if not visible:
		show()
	_show_realm_briefing(clampi(world, 1, WorldProgress.TOTAL_WORLDS))


func preview_trail(world: int = 1) -> void:
	if not visible:
		show()
	_world_menu_open = clampi(world, 1, WorldProgress.TOTAL_WORLDS)
	_show_trail_map()


func close() -> void:
	_close_difficulty_menu()
	hide()
	panel_open_changed.emit(false)


func _cache_option_styles() -> void:
	var sample := difficulty_options_hall.get_node("DifficultyOptionHall_0") as Button
	_option_style_normal = sample.get_theme_stylebox("normal") as StyleBoxFlat
	_option_style_active = _option_style_normal.duplicate() as StyleBoxFlat
	_option_style_active.bg_color = Color(0.28, 0.2, 0.12, 1)
	_option_style_active.border_width_left = 3
	_option_style_active.border_width_top = 3
	_option_style_active.border_width_right = 3
	_option_style_active.border_width_bottom = 3
	_option_style_active.border_color = Color(0.95, 0.78, 0.32, 1)
	_option_style_locked = sample.get_theme_stylebox("disabled") as StyleBoxFlat


func _wire_difficulty_options() -> void:
	_difficulty_option_buttons.clear()
	for i in WorldProgress.Difficulty.size():
		var button := difficulty_options_hall.get_node_or_null("DifficultyOptionHall_%d" % i) as Button
		assert(button != null, "difficulty menu should bake option Hall %d" % i)
		if not button.get_meta(&"wired", false):
			button.pressed.connect(_choose_difficulty.bind(i))
			button.set_meta(&"wired", true)
		_difficulty_option_buttons.append(button)
	_update_difficulty_options()


func _show_portal_hall() -> void:
	_panel_view = PanelView.PORTAL_HALL
	_close_difficulty_menu()
	back_button.show()
	title_label.text = tr(LocaleKeys.PORTALS_TITLE).to_upper()
	hall_view.show()
	briefing_view.hide()
	trail_view.hide()
	difficulty_footer.show()
	_refresh_hall()


func _show_realm_briefing(world: int) -> void:
	if not _is_world_unlocked(world):
		return
	_world_menu_open = clampi(world, 1, WorldProgress.TOTAL_WORLDS)
	_panel_view = PanelView.REALM_BRIEFING
	_close_difficulty_menu()
	back_button.show()
	hall_view.hide()
	trail_view.hide()
	briefing_view.show()
	difficulty_footer.hide()
	title_label.text = WorldCatalog.dimension_name(_world_menu_open)
	briefing_view.bind_briefing(_world_menu_open)


func _show_trail_map() -> void:
	_panel_view = PanelView.TRAIL_MAP
	_close_difficulty_menu()
	back_button.show()
	hall_view.hide()
	briefing_view.hide()
	trail_view.show()
	difficulty_footer.hide()
	_refresh_trail()


func _on_back_pressed() -> void:
	match _panel_view:
		PanelView.PORTAL_HALL:
			close()
		PanelView.TRAIL_MAP:
			_show_realm_briefing(_world_menu_open)
		PanelView.REALM_BRIEFING:
			_show_portal_hall()


func _on_portal_pressed(world: int) -> void:
	if not _is_world_unlocked(world):
		return
	_show_realm_briefing(world)


func _on_stage_pressed(stage: int) -> void:
	if not _is_stage_unlocked(_world_menu_open, stage):
		return
	stage_started.emit(_world_menu_open, stage, _difficulty)


func _refresh_active_view(previous_world: int) -> void:
	match _panel_view:
		PanelView.TRAIL_MAP:
			if _current_world != previous_world and _current_stage == 1:
				_show_realm_briefing(_current_world)
			else:
				_refresh_trail()
		PanelView.REALM_BRIEFING:
			briefing_view.bind_briefing(_world_menu_open)
		_:
			_refresh_hall()


func _refresh_hall() -> void:
	hall_view.refresh_static_texts()
	hall_view.bind_hall(
		_current_world,
		_is_world_unlocked,
		_completed_stages_in_dimension,
		_is_dimension_fully_saved
	)


func _refresh_trail() -> void:
	title_label.text = WorldCatalog.dimension_name(_world_menu_open)
	trail_view.bind_trail(
		_world_menu_open,
		_current_world,
		_current_stage,
		_difficulty,
		_unlocked,
		_is_stage_unlocked
	)


func _refresh_locale() -> void:
	close_button.tooltip_text = tr(LocaleKeys.BTN_CLOSE)
	back_button.tooltip_text = tr(LocaleKeys.BTN_BACK)
	briefing_view.refresh_static_texts()
	_update_difficulty_button()
	match _panel_view:
		PanelView.PORTAL_HALL:
			title_label.text = tr(LocaleKeys.PORTALS_TITLE).to_upper()
			_refresh_hall()
		PanelView.REALM_BRIEFING:
			title_label.text = WorldCatalog.dimension_name(_world_menu_open)
			briefing_view.bind_briefing(_world_menu_open)
		PanelView.TRAIL_MAP:
			_refresh_trail()


func _active_difficulty_menu() -> PanelContainer:
	return difficulty_menu_hall


func _toggle_difficulty_menu() -> void:
	var menu := _active_difficulty_menu()
	if menu.visible:
		_close_difficulty_menu()
		return
	_update_difficulty_options()
	difficulty_menu_backdrop.show()
	menu.show()


func _close_difficulty_menu() -> void:
	difficulty_menu_hall.hide()
	difficulty_menu_backdrop.hide()


func _on_difficulty_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close_difficulty_menu()
		difficulty_menu_backdrop.accept_event()


func _choose_difficulty(value: int) -> void:
	if not WorldProgress.is_difficulty_unlocked(value, _unlocked):
		return
	_difficulty = clampi(value, 0, 2)
	_close_difficulty_menu()
	_update_difficulty_button()
	if _panel_view == PanelView.PORTAL_HALL:
		_refresh_hall()
	elif _panel_view == PanelView.TRAIL_MAP:
		_refresh_trail()


func _update_difficulty_button() -> void:
	var label := WorldProgress.difficulty_name(_difficulty)
	difficulty_button.text = label
	_update_difficulty_options()


func _update_difficulty_options() -> void:
	for i in WorldProgress.Difficulty.size():
		var button := difficulty_options_hall.get_node_or_null("DifficultyOptionHall_%d" % i) as Button
		if button == null:
			continue
		var unlocked := WorldProgress.is_difficulty_unlocked(i, _unlocked)
		var text: String = WorldProgress.difficulty_name(i)
		if not unlocked:
			text += " 🔒"
		button.text = text
		button.disabled = not unlocked
		_apply_option_style(button, i == _difficulty, not unlocked)


func _apply_option_style(button: Button, active: bool, locked: bool) -> void:
	if locked:
		button.add_theme_color_override("font_color", Color(0.52, 0.46, 0.38, 1))
		button.add_theme_stylebox_override("normal", _option_style_locked)
		button.add_theme_stylebox_override("hover", _option_style_locked)
		button.add_theme_stylebox_override("pressed", _option_style_locked)
		button.add_theme_stylebox_override("disabled", _option_style_locked)
	elif active:
		button.add_theme_color_override("font_color", Color(1, 0.92, 0.72, 1))
		button.add_theme_stylebox_override("normal", _option_style_active)
		button.add_theme_stylebox_override("hover", _option_style_active)
		button.add_theme_stylebox_override("pressed", _option_style_active)
	else:
		button.add_theme_color_override("font_color", Color(0.95, 0.88, 0.7, 1))
		button.add_theme_stylebox_override("normal", _option_style_normal)
		button.add_theme_stylebox_override("hover", _option_style_normal)
		button.add_theme_stylebox_override("pressed", _option_style_normal)


func _is_stage_unlocked(world: int, stage: int) -> bool:
	if not WorldProgress.is_difficulty_unlocked(_difficulty, _unlocked):
		return false
	return WorldProgress.stage_index(world, stage) <= _unlocked[_difficulty]


func _is_world_unlocked(world: int) -> bool:
	return _is_stage_unlocked(world, 1)


func _completed_stages_in_dimension(world: int) -> int:
	var start := WorldProgress.stage_index(world, 1)
	var progress := _unlocked[_difficulty]
	if progress <= start:
		return 0
	return mini(WorldProgress.STAGES_PER_WORLD, progress - start)


func _is_dimension_fully_saved(world: int) -> bool:
	var boss_index := WorldProgress.stage_index(world, WorldProgress.STAGES_PER_WORLD)
	return _unlocked[_difficulty] > boss_index


func _on_locale_changed(_locale_code: String) -> void:
	refresh_locale()


func _on_header_gui_input(event: InputEvent) -> void:
	if _menu == null:
		return
	_menu.drag_window_from_event(event)
