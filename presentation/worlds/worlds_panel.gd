class_name WorldsPanel
extends PanelContainer
## Painel direito de mundos e fases. Só um painel direito fica aberto por vez.

signal panel_open_changed(is_open: bool)
signal stage_started(world: int, stage: int, difficulty: int)

const TAMANHO_FASE := 34.0
const TAMANHO_CHEFE := 48.0
const POSICOES_TRILHA_FLORESTA: Array[Vector2] = [
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

@onready var botao_voltar: Button = %BotaoVoltarMundos
@onready var botao_fechar: Button = %BotaoFecharMundos
@onready var titulo: Label = %TituloMundos
@onready var cabecalho: HBoxContainer = %CabecalhoMundos
@onready var painel_lista: VBoxContainer = %PainelListaMundos
@onready var lista_mundos: VBoxContainer = %ListaMundos
@onready var botao_dificuldade: Button = %BotaoDificuldade
@onready var opcoes_dificuldade: VBoxContainer = %OpcoesDificuldade
@onready var menu_dificuldade: PanelContainer = %MenuDificuldade
@onready var fundo_menu_dificuldade: ColorRect = %FundoMenuDificuldade
@onready var painel_mapa: Control = %PainelStageMap
@onready var mapa_fases: StageMap = %StageMap
@onready var fundo_mapa: TextureRect = %FundoMapa

var _menu: InventoryMenu
var _mundo_aberto: int = 1
var _mundo_atual: int = 1
var _fase_atual: int = 1
var _dificuldade: int = WorldProgress.Difficulty.EASY
var _liberadas: Array[int] = [1, 1, 1]
var _botoes_mundo: Array[Button] = []
var _botoes_fase: Array[BaseButton] = []
var _rotulos_fase: Array[Label] = []
var _ancoras_fase: Array[Control] = []
var _botoes_opcao_dificuldade: Array[Button] = []
var _tex_fase: ImageTexture
var _tex_chefe: ImageTexture
var _cache_texturas_mapa: Dictionary = {}


func _ready() -> void:
	hide()
	botao_fechar.pressed.connect(close)
	botao_voltar.pressed.connect(_show_world_list)
	botao_dificuldade.pressed.connect(_toggle_difficulty_options)
	fundo_menu_dificuldade.gui_input.connect(_on_difficulty_backdrop_gui_input)
	cabecalho.gui_input.connect(_on_header_gui_input)
	gui_input.connect(_on_header_gui_input)
	mapa_fases.resized.connect(_position_stages)
	painel_mapa.visibility_changed.connect(_on_map_visibility_changed)
	_create_world_list()
	_create_difficulty_options()
	_create_stage_map()
	_show_world_list()
	_update_difficulty_button()


func configure(menu: InventoryMenu) -> void:
	_menu = menu


func set_state(world: int, stage: int, difficulty: int, liberadas: Array) -> void:
	var mundo_anterior := _mundo_atual
	_mundo_atual = clampi(world, 1, WorldProgress.TOTAL_MUNDOS)
	_fase_atual = clampi(stage, 1, WorldProgress.FASES_POR_MUNDO)
	_dificuldade = clampi(difficulty, 0, 2)
	_liberadas.clear()
	for i in 3:
		var valor := 1
		if i < liberadas.size():
			valor = clampi(int(liberadas[i]), 1, WorldProgress.PROGRESSO_COMPLETO)
		_liberadas.append(valor)
	if not WorldProgress.is_difficulty_unlocked(_dificuldade, _liberadas):
		_dificuldade = WorldProgress.Difficulty.EASY
		while _dificuldade < 2 and WorldProgress.is_difficulty_unlocked(_dificuldade + 1, _liberadas):
			_dificuldade += 1
	_update_difficulty_button()
	_update_world_list()
	if painel_mapa.visible and _mundo_atual != mundo_anterior and _fase_atual == 1:
		_open_world_map(_mundo_atual)
	else:
		_update_map()


func refresh_locale() -> void:
	_update_difficulty_options()
	_update_difficulty_button()


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
	for filho in lista_mundos.get_children():
		filho.queue_free()
	_botoes_mundo.clear()
	for i in WorldProgress.TOTAL_MUNDOS:
		var botao := Button.new()
		botao.name = "BotaoMundo_%d" % (i + 1)
		botao.size_flags_vertical = Control.SIZE_EXPAND_FILL
		botao.custom_minimum_size = Vector2(0, 42)
		botao.add_theme_font_size_override("font_size", 16)
		botao.pressed.connect(_open_world_map.bind(i + 1))
		lista_mundos.add_child(botao)
		_botoes_mundo.append(botao)
	_update_world_list()


func _create_difficulty_options() -> void:
	for filho in opcoes_dificuldade.get_children():
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
		opcoes_dificuldade.add_child(botao)
		_botoes_opcao_dificuldade.append(botao)
	_update_difficulty_options()


func _create_stage_map() -> void:
	_tex_fase = _circle_texture(int(TAMANHO_FASE))
	_tex_chefe = _circle_texture(int(TAMANHO_CHEFE))
	for i in WorldProgress.FASES_POR_MUNDO:
		var ancora := Control.new()
		ancora.name = "AncoraFase_%d" % (i + 1)
		ancora.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mapa_fases.add_child(ancora)

		var chefe := i == WorldProgress.FASES_POR_MUNDO - 1
		var tamanho := TAMANHO_CHEFE if chefe else TAMANHO_FASE
		var botao := TextureButton.new()
		botao.custom_minimum_size = Vector2(tamanho, tamanho)
		botao.focus_mode = Control.FOCUS_NONE
		botao.ignore_texture_size = true
		botao.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		botao.texture_normal = _tex_chefe if chefe else _tex_fase
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

		_ancoras_fase.append(ancora)
		_rotulos_fase.append(rotulo)
		_botoes_fase.append(botao)
	call_deferred("_position_stages")


func _show_world_list() -> void:
	_close_difficulty_menu()
	botao_voltar.hide()
	titulo.text = "MUNDOS"
	painel_lista.show()
	painel_mapa.hide()
	_update_world_list()


func _open_world_map(world: int) -> void:
	_mundo_aberto = clampi(world, 1, WorldProgress.TOTAL_MUNDOS)
	_close_difficulty_menu()
	botao_voltar.show()
	titulo.text = "MUNDO %d" % _mundo_aberto
	painel_lista.hide()
	painel_mapa.show()
	_update_map()
	call_deferred("_position_stages")


func _on_map_visibility_changed() -> void:
	if painel_mapa.visible:
		call_deferred("_position_stages")


func _toggle_difficulty_options() -> void:
	if menu_dificuldade.visible:
		_close_difficulty_menu()
		return
	_update_difficulty_options()
	fundo_menu_dificuldade.show()
	menu_dificuldade.show()
	call_deferred("_position_difficulty_menu")


func _close_difficulty_menu() -> void:
	if menu_dificuldade:
		menu_dificuldade.hide()
	if fundo_menu_dificuldade:
		fundo_menu_dificuldade.hide()


func _position_difficulty_menu() -> void:
	if not menu_dificuldade.visible:
		return
	menu_dificuldade.reset_size()
	var largura := botao_dificuldade.size.x
	var altura_item := botao_dificuldade.size.y
	for botao in _botoes_opcao_dificuldade:
		botao.custom_minimum_size = Vector2(largura - 4.0, altura_item)
	menu_dificuldade.reset_size()
	var tam := Vector2(largura, menu_dificuldade.get_combined_minimum_size().y)
	menu_dificuldade.size = tam
	var camada := menu_dificuldade.get_parent() as Control
	var botao_rect := botao_dificuldade.get_global_rect()
	var local_end := botao_rect.end - camada.get_global_rect().position
	var pos := Vector2(
		local_end.x - menu_dificuldade.size.x,
		local_end.y - botao_dificuldade.size.y - 4.0 - menu_dificuldade.size.y
	)
	pos.x = clampf(pos.x, 0.0, maxf(0.0, camada.size.x - menu_dificuldade.size.x))
	pos.y = clampf(pos.y, 0.0, maxf(0.0, camada.size.y - menu_dificuldade.size.y))
	menu_dificuldade.position = pos


func _on_difficulty_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close_difficulty_menu()
		fundo_menu_dificuldade.accept_event()


func _choose_difficulty(valor: int) -> void:
	if not WorldProgress.is_difficulty_unlocked(valor, _liberadas):
		return
	_dificuldade = clampi(valor, 0, 2)
	_close_difficulty_menu()
	_update_difficulty_button()
	_update_world_list()
	_update_map()


func _on_stage_pressed(stage: int) -> void:
	if not _is_stage_unlocked(_mundo_aberto, stage):
		return
	stage_started.emit(_mundo_aberto, stage, _dificuldade)


func _is_stage_unlocked(world: int, stage: int) -> bool:
	if not WorldProgress.is_difficulty_unlocked(_dificuldade, _liberadas):
		return false
	return WorldProgress.stage_index(world, stage) <= _liberadas[_dificuldade]


func _is_world_unlocked(world: int) -> bool:
	return _is_stage_unlocked(world, 1)


func _update_world_list() -> void:
	for i in _botoes_mundo.size():
		var world := i + 1
		var liberado := _is_world_unlocked(world)
		var atual := world == _mundo_atual
		var texto := "MUNDO %d" % world
		if not liberado:
			texto += "  🔒"
		_botoes_mundo[i].text = texto
		_botoes_mundo[i].disabled = false
		_paint_button(_botoes_mundo[i], atual, not liberado)


func _update_map() -> void:
	var tex := _map_texture(_mundo_aberto)
	if fundo_mapa:
		fundo_mapa.texture = tex
		fundo_mapa.visible = tex != null
	for i in _botoes_fase.size():
		var stage := i + 1
		var rotulo := "%d-%d" % [_mundo_aberto, stage]
		_rotulos_fase[i].text = rotulo
		var liberada := _is_stage_unlocked(_mundo_aberto, stage)
		var atual := _mundo_aberto == _mundo_atual and stage == _fase_atual
		var concluida := WorldProgress.stage_index(_mundo_aberto, stage) < _liberadas[_dificuldade]
		_botoes_fase[i].disabled = not liberada
		_paint_stage(_botoes_fase[i], _rotulos_fase[i], atual, concluida, not liberada, stage == WorldProgress.FASES_POR_MUNDO)
	_position_stages()


func _update_difficulty_button() -> void:
	botao_dificuldade.text = WorldProgress.difficulty_name(_dificuldade)
	_paint_button(botao_dificuldade, true)
	_update_difficulty_options()


func _update_difficulty_options() -> void:
	for i in _botoes_opcao_dificuldade.size():
		var liberada := WorldProgress.is_difficulty_unlocked(i, _liberadas)
		var texto: String = WorldProgress.difficulty_name(i)
		if not liberada:
			texto += " 🔒"
		_botoes_opcao_dificuldade[i].text = texto
		_botoes_opcao_dificuldade[i].disabled = not liberada
		_paint_button(_botoes_opcao_dificuldade[i], i == _dificuldade, not liberada, true)


func _position_stages() -> void:
	if mapa_fases.size.x < 8.0 or mapa_fases.size.y < 8.0:
		return
	var usar_trilha := _map_texture(_mundo_aberto) != null
	for i in _ancoras_fase.size():
		var centro: Vector2
		if usar_trilha:
			centro = _position_on_path(POSICOES_TRILHA_FLORESTA[i])
		else:
			var area := Rect2(Vector2(18, 10), mapa_fases.size - Vector2(36, 20))
			var ratio: Vector2 = WorldProgress.POSICOES_FASES[i]
			centro = area.position + Vector2(area.size.x * ratio.x, area.size.y * ratio.y)
		var botao := _botoes_fase[i]
		botao.reset_size()
		var raio := botao.size.x * 0.5
		botao.position = Vector2(-raio, -raio)
		_ancoras_fase[i].position = centro
	var pontos: Array[Vector2] = []
	if not usar_trilha:
		for ancora in _ancoras_fase:
			pontos.append(ancora.position)
	mapa_fases.pontos = pontos
	mapa_fases.queue_redraw()


func _position_on_path(uv: Vector2) -> Vector2:
	var area := mapa_fases.size
	var tex_size := Vector2(768, 1344)
	if fundo_mapa and fundo_mapa.texture:
		tex_size = Vector2(fundo_mapa.texture.get_width(), fundo_mapa.texture.get_height())
	if tex_size.x < 1.0 or tex_size.y < 1.0 or area.x < 1.0 or area.y < 1.0:
		return uv * area
	var escala := maxf(area.x / tex_size.x, area.y / tex_size.y)
	var desenhado := tex_size * escala
	var origem := (area - desenhado) * 0.5
	var centro := origem + Vector2(uv.x * desenhado.x, uv.y * desenhado.y)
	var margem := TAMANHO_CHEFE * 0.5 + 2.0
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


func _paint_button(botao: Button, ativo: bool = false, bloqueado: bool = false, compacto: bool = false) -> void:
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


func _paint_stage(botao: BaseButton, rotulo: Label, atual: bool, concluida: bool, bloqueada: bool, chefe: bool) -> void:
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


func _on_header_gui_input(event: InputEvent) -> void:
	if _menu == null:
		return
	_menu.drag_window_from_event(event)
