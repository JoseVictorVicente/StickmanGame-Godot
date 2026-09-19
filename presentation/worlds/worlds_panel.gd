class_name WorldsPanel
extends PanelContainer
## Painel direito de mundos e fases. Só um painel direito fica aberto por vez.

signal panel_open_changed(is_open: bool)
signal stage_started(world: int, stage: int, difficulty: int)

const STAGE_SIZE := 34.0
const BOSS_SIZE := 48.0
const FOREST_TRAIL_POSITIONS: Array[Vector2] = [
	Vector2(0.49, 0.89),
	Vector2(0.53, 0.79),
	Vector2(0.54, 0.69),
	Vector2(0.53, 0.59),
	Vector2(0.51, 0.49),
	Vector2(0.51, 0.39),
	Vector2(0.50, 0.29),
	Vector2(0.49, 0.18),
	Vector2(0.49, 0.08),
]
const TEXTURAS_MAPA: Dictionary = {
	1: "res://sprites/environment/forest_map_clean.png",
	2: "res://sprites/environment/forest_map_dark.jpg",
	3: "res://sprites/environment/desert_map.jpg",
	4: "res://sprites/environment/snow_map.jpg",
	5: "res://sprites/environment/volcanic_map.jpg",
}

@onready var back_button: Button = %WorldsBackButton
@onready var botao_fechar: Button = %CloseWorldsButton
@onready var titulo: Label = %WorldsTitle
@onready var cabecalho: HBoxContainer = %WorldsHeader
@onready var list_panel: VBoxContainer = %WorldListPanel
@onready var world_list: VBoxContainer = %WorldList
@onready var difficulty_button: Button = %DifficultyButton
@onready var difficulty_options: VBoxContainer = %DifficultyOptions
@onready var difficulty_menu: PanelContainer = %DifficultyMenu
@onready var difficulty_menu_backdrop: ColorRect = %DifficultyMenuBackdrop
@onready var map_panel: Control = %PanelStageMap
@onready var stage_map: StageMap = %StageMap
@onready var map_background: TextureRect = %MapBackground

var _menu: InventoryMenu
var _world_menu_open: int = 1
var _current_world: int = 1
var _current_stage: int = 1
var _dificuldade: int = WorldProgress.Difficulty.EASY
var _unlocked: Array[int] = [1, 1, 1]
var _world_buttons: Array[Button] = []
var _stage_buttons: Array[BaseButton] = []
var _stage_labels: Array[Label] = []
var _stage_anchors: Array[Control] = []
var _botoes_opcao_dificuldade: Array[Button] = []
var _stage_tex: ImageTexture
var _boss_tex: ImageTexture
var _cache_texturas_mapa: Dictionary = {}


func _ready() -> void:
	hide()
	botao_fechar.pressed.connect(close)
	back_button.pressed.connect(_show_world_list)
	difficulty_button.pressed.connect(_toggle_difficulty_options)
	difficulty_menu_backdrop.gui_input.connect(_on_difficulty_backdrop_gui_input)
	cabecalho.gui_input.connect(_on_header_gui_input)
	gui_input.connect(_on_header_gui_input)
	stage_map.resized.connect(_position_stages)
	map_panel.visibility_changed.connect(_on_map_visibility_changed)
	_create_world_list()
	_create_difficulty_options()
	_create_stage_map()
	_show_world_list()
	_update_difficulty_button()
	LocaleService.locale_changed.connect(_on_locale_changed)
	_update_localized_texts()


func configure(menu: InventoryMenu) -> void:
	_menu = menu


func set_state(world: int, stage: int, difficulty: int, liberadas: Array) -> void:
	var mundo_anterior := _current_world
	_current_world = clampi(world, 1, WorldProgress.TOTAL_WORLDS)
	_current_stage = clampi(stage, 1, WorldProgress.STAGES_PER_WORLD)
	_dificuldade = clampi(difficulty, 0, 2)
	_unlocked.clear()
	for i in 3:
		var valor := 1
		if i < liberadas.size():
			valor = clampi(int(liberadas[i]), 1, WorldProgress.FULL_PROGRESS)
		_unlocked.append(valor)
	if not WorldProgress.is_difficulty_unlocked(_dificuldade, _unlocked):
		_dificuldade = WorldProgress.Difficulty.EASY
		while _dificuldade < 2 and WorldProgress.is_difficulty_unlocked(_dificuldade + 1, _unlocked):
			_dificuldade += 1
	_update_difficulty_button()
	_update_world_list()
	if map_panel.visible and _current_world != mundo_anterior and _current_stage == 1:
		_open_world_map(_current_world)
	else:
		_update_map()


func refresh_locale() -> void:
	_update_localized_texts()
	_update_difficulty_options()
	_update_difficulty_button()
	if list_panel.visible:
		_update_world_list()
	elif map_panel.visible:
		_update_map()


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
	_show_world_list()
	show()
	panel_open_changed.emit(true)


func close() -> void:
	_close_difficulty_menu()
	hide()
	panel_open_changed.emit(false)


func _create_world_list() -> void:
	for filho in world_list.get_children():
		filho.queue_free()
	_world_buttons.clear()
	for i in WorldProgress.TOTAL_WORLDS:
		var botao := Button.new()
		botao.name = "WorldButton_%d" % (i + 1)
		botao.size_flags_vertical = Control.SIZE_EXPAND_FILL
		botao.custom_minimum_size = Vector2(0, 42)
		botao.add_theme_font_size_override("font_size", 16)
		botao.pressed.connect(_open_world_map.bind(i + 1))
		world_list.add_child(botao)
		_world_buttons.append(botao)
	_update_world_list()


func _create_difficulty_options() -> void:
	for filho in difficulty_options.get_children():
		filho.queue_free()
	_botoes_opcao_dificuldade.clear()
	for i in WorldProgress.Difficulty.size():
		var botao := Button.new()
		botao.text = WorldProgress.difficulty_name(i)
		botao.custom_minimum_size = Vector2(0, 32)
		botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		botao.clip_text = true
		botao.add_theme_font_size_override("font_size", 12)
		botao.pressed.connect(_choose_difficulty.bind(i))
		difficulty_options.add_child(botao)
		_botoes_opcao_dificuldade.append(botao)
	_update_difficulty_options()


func _create_stage_map() -> void:
	_stage_tex = _circle_texture(int(STAGE_SIZE))
	_boss_tex = _circle_texture(int(BOSS_SIZE))
	for i in WorldProgress.STAGES_PER_WORLD:
		var ancora := Control.new()
		ancora.name = "AncoraFase_%d" % (i + 1)
		ancora.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage_map.add_child(ancora)

		var chefe := i == WorldProgress.STAGES_PER_WORLD - 1
		var tamanho := BOSS_SIZE if chefe else STAGE_SIZE
		var botao := TextureButton.new()
		botao.custom_minimum_size = Vector2(tamanho, tamanho)
		botao.focus_mode = Control.FOCUS_NONE
		botao.ignore_texture_size = true
		botao.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		botao.texture_normal = _boss_tex if chefe else _stage_tex
		botao.texture_pressed = botao.texture_normal
		botao.texture_hover = botao.texture_normal
		botao.texture_disabled = botao.texture_normal
		botao.pressed.connect(_on_stage_pressed.bind(i + 1))
		ancora.add_child(botao)

		var rotulo := Label.new()
		rotulo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rotulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		rotulo.add_theme_font_size_override("font_size", 10 if chefe else 9)
		rotulo.add_theme_color_override("font_color", Color(0.95, 0.88, 0.7, 1))
		rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		botao.add_child(rotulo)

		_stage_anchors.append(ancora)
		_stage_labels.append(rotulo)
		_stage_buttons.append(botao)
	call_deferred("_position_stages")


func _show_world_list() -> void:
	_close_difficulty_menu()
	back_button.hide()
	titulo.text = tr(LocaleKeys.WORLDS_TITLE).to_upper()
	list_panel.show()
	map_panel.hide()
	_update_world_list()


func _open_world_map(world: int) -> void:
	_world_menu_open = clampi(world, 1, WorldProgress.TOTAL_WORLDS)
	_close_difficulty_menu()
	back_button.show()
	titulo.text = tr(LocaleKeys.WORLD_N) % _world_menu_open
	list_panel.hide()
	map_panel.show()
	_update_map()
	call_deferred("_position_stages")


func _on_map_visibility_changed() -> void:
	if map_panel.visible:
		call_deferred("_position_stages")


func _toggle_difficulty_options() -> void:
	if difficulty_menu.visible:
		_close_difficulty_menu()
		return
	_update_difficulty_options()
	difficulty_menu_backdrop.show()
	difficulty_menu.show()
	call_deferred("_position_difficulty_menu")


func _close_difficulty_menu() -> void:
	if difficulty_menu:
		difficulty_menu.hide()
	if difficulty_menu_backdrop:
		difficulty_menu_backdrop.hide()


func _position_difficulty_menu() -> void:
	if not difficulty_menu.visible:
		return
	difficulty_menu.reset_size()
	var largura := difficulty_button.size.x
	var altura_item := difficulty_button.size.y
	for botao in _botoes_opcao_dificuldade:
		botao.custom_minimum_size = Vector2(largura - 4.0, altura_item)
	difficulty_menu.reset_size()
	var tam := Vector2(largura, difficulty_menu.get_combined_minimum_size().y)
	difficulty_menu.size = tam
	var camada := difficulty_menu.get_parent() as Control
	var botao_rect := difficulty_button.get_global_rect()
	var local_end := botao_rect.end - camada.get_global_rect().position
	var pos := Vector2(
		local_end.x - difficulty_menu.size.x,
		local_end.y - difficulty_button.size.y - 4.0 - difficulty_menu.size.y
	)
	pos.x = clampf(pos.x, 0.0, maxf(0.0, camada.size.x - difficulty_menu.size.x))
	pos.y = clampf(pos.y, 0.0, maxf(0.0, camada.size.y - difficulty_menu.size.y))
	difficulty_menu.position = pos


func _on_difficulty_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close_difficulty_menu()
		difficulty_menu_backdrop.accept_event()


func _choose_difficulty(valor: int) -> void:
	if not WorldProgress.is_difficulty_unlocked(valor, _unlocked):
		return
	_dificuldade = clampi(valor, 0, 2)
	_close_difficulty_menu()
	_update_difficulty_button()
	_update_world_list()
	_update_map()


func _on_stage_pressed(stage: int) -> void:
	if not _is_stage_unlocked(_world_menu_open, stage):
		return
	stage_started.emit(_world_menu_open, stage, _dificuldade)


func _is_stage_unlocked(world: int, stage: int) -> bool:
	if not WorldProgress.is_difficulty_unlocked(_dificuldade, _unlocked):
		return false
	return WorldProgress.stage_index(world, stage) <= _unlocked[_dificuldade]


func _is_world_unlocked(world: int) -> bool:
	return _is_stage_unlocked(world, 1)


func _update_world_list() -> void:
	for i in _world_buttons.size():
		var world := i + 1
		var liberado := _is_world_unlocked(world)
		var atual := world == _current_world
		var texto := tr(LocaleKeys.WORLD_N) % world
		if not liberado:
			texto += "  " + tr(LocaleKeys.WORLD_LOCKED)
		_world_buttons[i].text = texto
		_world_buttons[i].disabled = false
		_style_button(_world_buttons[i], atual, not liberado)


func _update_map() -> void:
	var tex := _map_texture(_world_menu_open)
	if map_background:
		map_background.texture = tex
		map_background.visible = tex != null
	for i in _stage_buttons.size():
		var stage := i + 1
		var rotulo := "%d-%d" % [_world_menu_open, stage]
		_stage_labels[i].text = rotulo
		var liberada := _is_stage_unlocked(_world_menu_open, stage)
		var atual := _world_menu_open == _current_world and stage == _current_stage
		var concluida := WorldProgress.stage_index(_world_menu_open, stage) < _unlocked[_dificuldade]
		_stage_buttons[i].disabled = not liberada
		_style_stage(_stage_buttons[i], _stage_labels[i], atual, concluida, not liberada, stage == WorldProgress.STAGES_PER_WORLD)
	_position_stages()


func _update_difficulty_button() -> void:
	difficulty_button.text = WorldProgress.difficulty_name(_dificuldade)
	_style_button(difficulty_button, true)
	_update_difficulty_options()


func _update_difficulty_options() -> void:
	for i in _botoes_opcao_dificuldade.size():
		var liberada := WorldProgress.is_difficulty_unlocked(i, _unlocked)
		var texto: String = WorldProgress.difficulty_name(i)
		if not liberada:
			texto += " 🔒"
		_botoes_opcao_dificuldade[i].text = texto
		_botoes_opcao_dificuldade[i].disabled = not liberada
		_style_button(_botoes_opcao_dificuldade[i], i == _dificuldade, not liberada, true)


func _position_stages() -> void:
	if stage_map.size.x < 8.0 or stage_map.size.y < 8.0:
		return
	var usar_trilha := _map_texture(_world_menu_open) != null
	for i in _stage_anchors.size():
		var centro: Vector2
		if usar_trilha:
			centro = _position_on_path(FOREST_TRAIL_POSITIONS[i])
		else:
			var area := Rect2(Vector2(18, 10), stage_map.size - Vector2(36, 20))
			var ratio: Vector2 = WorldProgress.STAGE_POSITIONS[i]
			centro = area.position + Vector2(area.size.x * ratio.x, area.size.y * ratio.y)
		var botao := _stage_buttons[i]
		botao.reset_size()
		var raio := botao.size.x * 0.5
		botao.position = Vector2(-raio, -raio)
		_stage_anchors[i].position = centro
	var pontos: Array[Vector2] = []
	if not usar_trilha:
		for ancora in _stage_anchors:
			pontos.append(ancora.position)
	stage_map.pontos = pontos
	stage_map.queue_redraw()


func _position_on_path(uv: Vector2) -> Vector2:
	var area := stage_map.size
	var tex_size := Vector2(768, 1344)
	if map_background and map_background.texture:
		tex_size = Vector2(map_background.texture.get_width(), map_background.texture.get_height())
	if tex_size.x < 1.0 or tex_size.y < 1.0 or area.x < 1.0 or area.y < 1.0:
		return uv * area
	var scale_for := maxf(area.x / tex_size.x, area.y / tex_size.y)
	var desenhado := tex_size * scale_for
	var origem := (area - desenhado) * 0.5
	var centro := origem + Vector2(uv.x * desenhado.x, uv.y * desenhado.y)
	var margem := BOSS_SIZE * 0.5 + 2.0
	centro.x = clampf(centro.x, margem, area.x - margem)
	centro.y = clampf(centro.y, margem, area.y - margem)
	return centro


func _map_texture(world: int) -> Texture2D:
	if _cache_texturas_mapa.has(world):
		return _cache_texturas_mapa[world]
	var caminho: String = str(TEXTURAS_MAPA.get(world, ""))
	if caminho == "" or not ResourceLoader.exists(caminho):
		_cache_texturas_mapa[world] = null
		return null
	var tex := load(caminho) as Texture2D
	_cache_texturas_mapa[world] = tex
	return tex


func _style_button(botao: Button, ativo: bool = false, bloqueado: bool = false, compacto: bool = false) -> void:
	var estilo := StyleBoxFlat.new()
	var margem := 6 if compacto else 10
	estilo.content_margin_left = margem
	estilo.content_margin_top = 6 if compacto else 8
	estilo.content_margin_right = margem
	estilo.content_margin_bottom = 6 if compacto else 8
	estilo.set_corner_radius_all(4)
	estilo.set_border_width_all(2)
	if bloqueado:
		estilo.bg_color = Color(0.12, 0.1, 0.09, 1)
		estilo.border_color = Color(0.38, 0.32, 0.22, 1)
		botao.add_theme_color_override("font_color", Color(0.62, 0.56, 0.46, 1))
	elif ativo:
		estilo.bg_color = Color(0.32, 0.24, 0.16, 1)
		estilo.border_color = Color(0.95, 0.78, 0.32, 1)
		botao.add_theme_color_override("font_color", Color(1, 0.92, 0.72, 1))
	else:
		estilo.bg_color = Color(0.16, 0.13, 0.1, 1)
		estilo.border_color = Color(0.72, 0.6, 0.34, 1)
		botao.add_theme_color_override("font_color", Color(0.95, 0.88, 0.7, 1))
	botao.add_theme_stylebox_override("normal", estilo)
	botao.add_theme_stylebox_override("hover", estilo)
	botao.add_theme_stylebox_override("pressed", estilo)
	botao.add_theme_stylebox_override("disabled", estilo)


func _style_stage(botao: BaseButton, rotulo: Label, atual: bool, concluida: bool, bloqueada: bool, chefe: bool) -> void:
	var cor := Color(0.18, 0.14, 0.11, 0.95)
	var cor_texto := Color(0.95, 0.88, 0.7, 1)
	if bloqueada:
		cor = Color(0.10, 0.09, 0.08, 0.82)
		cor_texto = Color(0.55, 0.5, 0.4, 1)
	elif atual:
		cor = Color(0.72, 0.28, 0.14, 0.96)
		cor_texto = Color(1, 0.94, 0.6, 1)
	elif concluida:
		cor = Color(0.22, 0.38, 0.16, 0.94)
		cor_texto = Color(0.92, 0.9, 0.62, 1)
	elif chefe:
		cor = Color(0.42, 0.16, 0.12, 0.96)
		cor_texto = Color(1, 0.86, 0.45, 1)
	botao.self_modulate = cor
	rotulo.add_theme_color_override("font_color", cor_texto)
	rotulo.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.03, 0.9))
	rotulo.add_theme_constant_override("outline_size", 4)


func _circle_texture(diametro: int) -> ImageTexture:
	var img := Image.create(diametro, diametro, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var centro := Vector2(diametro, diametro) * 0.5
	var raio := diametro * 0.5 - 1.5
	for y in diametro:
		for x in diametro:
			var dist := Vector2(x + 0.5, y + 0.5).distance_to(centro)
			if dist <= raio - 2.0:
				img.set_pixel(x, y, Color.WHITE)
			elif dist <= raio:
				img.set_pixel(x, y, Color(0.95, 0.82, 0.4, 1))
			elif dist <= raio + 1.0:
				img.set_pixel(x, y, Color(0.95, 0.82, 0.4, clampf(1.0 - (dist - raio), 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


func _update_localized_texts() -> void:
	if botao_fechar:
		botao_fechar.text = tr(LocaleKeys.BTN_CLOSE)
	if back_button:
		back_button.tooltip_text = tr(LocaleKeys.BTN_BACK)
	if list_panel.visible:
		titulo.text = tr(LocaleKeys.WORLDS_TITLE).to_upper()
	elif map_panel.visible:
		titulo.text = tr(LocaleKeys.WORLD_N) % _world_menu_open


func _on_locale_changed(_locale_code: String) -> void:
	refresh_locale()


func _on_header_gui_input(event: InputEvent) -> void:
	if _menu == null:
		return
	_menu.drag_window_from_event(event)
