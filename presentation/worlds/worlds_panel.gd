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
@onready var trail_progress_label: Label = %TrailProgressLabel
@onready var trail_difficulty_row: CenterContainer = %TrailDifficultyRow
@onready var trail_difficulty_slot: HBoxContainer = %TrailDifficultySlot
@onready var header: VBoxContainer = %WorldsHeader
@onready var hall_view = %WorldListPanel
@onready var briefing_view = %RealmBriefingPanel
@onready var trail_view = %PanelStageMap
@onready var difficulty_footer: CenterContainer = $Margem/Conteudo/RodapeDificuldade
@onready var difficulty_button: Button = %DifficultyButton
@onready var difficulty_options: VBoxContainer = %DifficultyOptions
@onready var difficulty_menu: PanelContainer = %DifficultyMenu
@onready var difficulty_menu_backdrop: ColorRect = %DifficultyMenuBackdrop

var _menu: InventoryMenu
var _panel_view: PanelView = PanelView.PORTAL_HALL
var _world_menu_open: int = 1
var _current_world: int = 1
var _current_stage: int = 1
var _difficulty: int = WorldProgress.Difficulty.EASY
var _unlocked: Array[int] = [1, 1, 1]
var _difficulty_option_buttons: Array[Button] = []


func _ready() -> void:
	hide()
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


func _wire_difficulty_options() -> void:
	_difficulty_option_buttons.clear()
	for i in WorldProgress.Difficulty.size():
		var button := difficulty_options.get_node_or_null("DifficultyOption_%d" % i) as Button
		assert(button != null, "difficulty menu should bake option %d" % i)
		if not button.get_meta(&"wired", false):
			button.pressed.connect(_choose_difficulty.bind(i))
			button.set_meta(&"wired", true)
		_difficulty_option_buttons.append(button)
	_update_difficulty_options()


func _show_portal_hall() -> void:
	_panel_view = PanelView.PORTAL_HALL
	_close_difficulty_menu()
	back_button.hide()
	trail_progress_label.hide()
	trail_difficulty_row.hide()
	title_label.text = tr(LocaleKeys.PORTALS_TITLE).to_upper()
	hall_view.show()
	briefing_view.hide()
	trail_view.hide()
	_place_difficulty_button(false)
	difficulty_footer.show()
	_refresh_hall()


func _show_realm_briefing(world: int) -> void:
	if not _is_world_unlocked(world):
		return
	_world_menu_open = clampi(world, 1, WorldProgress.TOTAL_WORLDS)
	_panel_view = PanelView.REALM_BRIEFING
	_close_difficulty_menu()
	back_button.show()
	trail_progress_label.hide()
	trail_difficulty_row.hide()
	hall_view.hide()
	trail_view.hide()
	briefing_view.show()
	difficulty_footer.hide()
	title_label.text = WorldCatalog.dimension_name(_world_menu_open)
	briefing_view.bind_briefing(
		_world_menu_open,
		int(size.y),
		int(header.size.y),
		int(briefing_view.enter_portal_button.custom_minimum_size.y)
	)


func _show_trail_map() -> void:
	_panel_view = PanelView.TRAIL_MAP
	_close_difficulty_menu()
	back_button.show()
	hall_view.hide()
	briefing_view.hide()
	trail_view.show()
	difficulty_footer.hide()
	trail_difficulty_row.show()
	_place_difficulty_button(true)
	_refresh_trail()


func _on_back_pressed() -> void:
	match _panel_view:
		PanelView.TRAIL_MAP:
			_show_realm_briefing(_world_menu_open)
		PanelView.REALM_BRIEFING:
			_show_portal_hall()
		_:
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
			briefing_view.bind_briefing(
				_world_menu_open,
				int(size.y),
				int(header.size.y),
				int(briefing_view.enter_portal_button.custom_minimum_size.y)
			)
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
	trail_progress_label.show()
	trail_progress_label.text = tr(LocaleKeys.TRAIL_PROGRESS_FORMAT) % [
		_current_stage,
		WorldProgress.STAGES_PER_WORLD,
	]
	trail_view.bind_trail(
		_world_menu_open,
		_current_world,
		_current_stage,
		_difficulty,
		_unlocked,
		_is_stage_unlocked
	)


func _refresh_locale() -> void:
	close_button.text = tr(LocaleKeys.BTN_CLOSE)
	back_button.tooltip_text = tr(LocaleKeys.BTN_BACK)
	briefing_view.refresh_static_texts()
	_update_difficulty_button()
	match _panel_view:
		PanelView.PORTAL_HALL:
			title_label.text = tr(LocaleKeys.PORTALS_TITLE).to_upper()
			_refresh_hall()
		PanelView.REALM_BRIEFING:
			title_label.text = WorldCatalog.dimension_name(_world_menu_open)
			briefing_view.bind_briefing(
				_world_menu_open,
				int(size.y),
				int(header.size.y),
				int(briefing_view.enter_portal_button.custom_minimum_size.y)
			)
		PanelView.TRAIL_MAP:
			_refresh_trail()


func _place_difficulty_button(in_header: bool) -> void:
	var parent: Node = trail_difficulty_slot if in_header else difficulty_footer
	if difficulty_button.get_parent() != parent:
		difficulty_button.reparent(parent)
	difficulty_button.custom_minimum_size = Vector2(108, 0)


func _toggle_difficulty_menu() -> void:
	if difficulty_menu.visible:
		_close_difficulty_menu()
		return
	_update_difficulty_options()
	difficulty_menu_backdrop.show()
	difficulty_menu.show()
	call_deferred("_position_difficulty_menu")


func _close_difficulty_menu() -> void:
	difficulty_menu.hide()
	difficulty_menu_backdrop.hide()


func _position_difficulty_menu() -> void:
	if not difficulty_menu.visible:
		return
	difficulty_menu.reset_size()
	var width := difficulty_button.size.x
	var item_height := difficulty_button.size.y
	for button in _difficulty_option_buttons:
		button.custom_minimum_size = Vector2(width - 4.0, item_height)
	difficulty_menu.reset_size()
	var menu_size := Vector2(width, difficulty_menu.get_combined_minimum_size().y)
	difficulty_menu.size = menu_size
	var layer := difficulty_menu.get_parent() as Control
	var button_rect := difficulty_button.get_global_rect()
	var local_end := button_rect.end - layer.get_global_rect().position
	var pos := Vector2(
		local_end.x - difficulty_menu.size.x,
		local_end.y - difficulty_button.size.y - 4.0 - difficulty_menu.size.y
	)
	pos.x = clampf(pos.x, 0.0, maxf(0.0, layer.size.x - difficulty_menu.size.x))
	pos.y = clampf(pos.y, 0.0, maxf(0.0, layer.size.y - difficulty_menu.size.y))
	difficulty_menu.position = pos


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
	difficulty_button.text = WorldProgress.difficulty_name(_difficulty)
	_style_button(difficulty_button, true)
	_update_difficulty_options()


func _update_difficulty_options() -> void:
	for i in _difficulty_option_buttons.size():
		var unlocked := WorldProgress.is_difficulty_unlocked(i, _unlocked)
		var text: String = WorldProgress.difficulty_name(i)
		if not unlocked:
			text += " 🔒"
		_difficulty_option_buttons[i].text = text
		_difficulty_option_buttons[i].disabled = not unlocked
		_style_button(_difficulty_option_buttons[i], i == _difficulty, not unlocked, true)


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


func _style_button(button: Button, active: bool = false, locked: bool = false, compact: bool = false) -> void:
	var style := StyleBoxFlat.new()
	var margin := 6 if compact else 10
	style.content_margin_left = margin
	style.content_margin_top = 6 if compact else 8
	style.content_margin_right = margin
	style.content_margin_bottom = 6 if compact else 8
	style.set_corner_radius_all(5 if not compact else 4)
	style.set_border_width_all(3 if active and not compact else 2)
	if locked:
		style.bg_color = Color(0.1, 0.08, 0.07, 1)
		style.border_color = Color(0.34, 0.28, 0.2, 1)
		button.add_theme_color_override("font_color", Color(0.52, 0.46, 0.38, 1))
	elif active:
		style.bg_color = Color(0.28, 0.2, 0.12, 1)
		style.border_color = Color(0.95, 0.78, 0.32, 1)
		button.add_theme_color_override("font_color", Color(1, 0.92, 0.72, 1))
	else:
		style.bg_color = Color(0.14, 0.11, 0.08, 1)
		style.border_color = Color(0.72, 0.58, 0.3, 1)
		button.add_theme_color_override("font_color", Color(0.95, 0.88, 0.7, 1))
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("disabled", style)


func _on_locale_changed(_locale_code: String) -> void:
	refresh_locale()


func _on_header_gui_input(event: InputEvent) -> void:
	if _menu == null:
		return
	_menu.drag_window_from_event(event)
