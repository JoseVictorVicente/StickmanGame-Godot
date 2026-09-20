class_name TrailMapView
extends Control

signal stage_pressed(stage: int)

const WorldCatalog := preload("res://data/world_catalog.gd")
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

@onready var stage_map: StageMap = %StageMap
@onready var map_background: TextureRect = %MapBackground

var _stage_buttons: Array[BaseButton] = []
var _stage_numbers: Array[Label] = []
var _stage_names: Array[Label] = []
var _stage_anchors: Array[Control] = []
var _stage_tex: ImageTexture
var _boss_tex: ImageTexture


func _ready() -> void:
	stage_map.resized.connect(_position_stages)
	visibility_changed.connect(_on_visibility_changed)
	_wire_stage_nodes()


func bind_trail(
	world: int,
	current_world: int,
	current_stage: int,
	difficulty: int,
	unlocked: Array[int],
	is_stage_unlocked: Callable
) -> void:
	var tex := WorldCatalog.map_texture(world)
	if map_background:
		map_background.texture = tex
		map_background.visible = tex != null
	for i in _stage_buttons.size():
		var stage := i + 1
		var rotulo := WorldCatalog.stage_milestone(world, stage)
		if WorldCatalog.is_boss_stage(stage):
			rotulo = tr(LocaleKeys.STAGE_DEMON_KING)
		var liberada: bool = is_stage_unlocked.call(world, stage)
		var atual := world == current_world and stage == current_stage
		var concluida := WorldProgress.stage_index(world, stage) < unlocked[difficulty]
		_stage_numbers[i].text = "🔒" if not liberada else str(stage)
		_stage_names[i].text = rotulo
		_stage_buttons[i].disabled = not liberada
		_style_stage(_stage_buttons[i], _stage_numbers[i], _stage_names[i], atual, concluida, not liberada, WorldCatalog.is_boss_stage(stage))
	_apply_map_layout()
	_position_stages()


func _wire_stage_nodes() -> void:
	_stage_tex = _circle_texture(int(STAGE_SIZE))
	_boss_tex = _circle_texture(int(BOSS_SIZE))
	_stage_anchors.clear()
	_stage_numbers.clear()
	_stage_names.clear()
	_stage_buttons.clear()
	for i in WorldProgress.STAGES_PER_WORLD:
		var indice := i + 1
		var ancora := stage_map.get_node_or_null("StageAnchor_%d" % indice) as Control
		var botao := ancora.get_node_or_null("StageButton") as TextureButton if ancora else null
		var numero := botao.get_node_or_null("StageNumber") as Label if botao else null
		var nome := ancora.get_node_or_null("StageNameLabel") as Label if ancora else null
		assert(ancora != null and botao != null and numero != null and nome != null)
		var chefe := WorldCatalog.is_boss_stage(indice)
		var tamanho := BOSS_SIZE if chefe else STAGE_SIZE
		botao.custom_minimum_size = Vector2(tamanho, tamanho)
		botao.texture_normal = _boss_tex if chefe else _stage_tex
		botao.texture_pressed = botao.texture_normal
		botao.texture_hover = botao.texture_normal
		botao.texture_disabled = botao.texture_normal
		if not botao.get_meta(&"wired", false):
			botao.pressed.connect(_on_stage_pressed.bind(indice))
			botao.set_meta(&"wired", true)
		ancora.z_index = 1
		_stage_anchors.append(ancora)
		_stage_buttons.append(botao)
		_stage_numbers.append(numero)
		_stage_names.append(nome)


func _on_visibility_changed() -> void:
	if visible:
		call_deferred("_apply_map_layout")
		call_deferred("_position_stages")


func _apply_map_layout() -> void:
	if map_background == null or map_background.texture == null:
		if map_background:
			map_background.visible = false
		return
	var rect := _trail_content_rect()
	map_background.set_anchors_preset(PRESET_TOP_LEFT)
	map_background.position = rect.position
	map_background.size = rect.size
	map_background.visible = true


func _position_stages() -> void:
	if stage_map.size.x < 8.0 or stage_map.size.y < 8.0:
		return
	for i in _stage_anchors.size():
		var centro := _position_on_path(FOREST_TRAIL_POSITIONS[i])
		var botao := _stage_buttons[i]
		botao.reset_size()
		var raio := botao.size.x * 0.5
		botao.position = Vector2(-raio, -raio)
		var nome_largura := clampf(botao.size.x + 28.0, 64.0, 92.0)
		_stage_names[i].custom_minimum_size = Vector2(nome_largura, 0.0)
		_stage_names[i].reset_size()
		_stage_names[i].position = Vector2(-nome_largura * 0.5, raio + 3.0)
		_stage_anchors[i].position = centro
	var pontos: Array[Vector2] = []
	for ancora in _stage_anchors:
		pontos.append(ancora.position)
	stage_map.pontos = pontos
	stage_map.queue_redraw()


func _trail_content_rect() -> Rect2:
	var area := stage_map.size
	var tex_size := Vector2(768, 1344)
	if map_background and map_background.texture:
		tex_size = Vector2(map_background.texture.get_width(), map_background.texture.get_height())
	if tex_size.x < 1.0 or tex_size.y < 1.0 or area.x < 1.0 or area.y < 1.0:
		return Rect2(Vector2.ZERO, area)
	var scale_fit := minf(area.x / tex_size.x, area.y / tex_size.y)
	var desenhado := tex_size * scale_fit
	var origem := (area - desenhado) * 0.5
	return Rect2(origem, desenhado)


func _position_on_path(uv: Vector2) -> Vector2:
	var rect := _trail_content_rect()
	if rect.size.x < 1.0 or rect.size.y < 1.0:
		return uv * stage_map.size
	var centro := rect.position + Vector2(uv.x * rect.size.x, uv.y * rect.size.y)
	var margem := BOSS_SIZE * 0.5 + 2.0
	centro.x = clampf(centro.x, margem, stage_map.size.x - margem)
	centro.y = clampf(centro.y, margem, stage_map.size.y - margem)
	return centro


func _on_stage_pressed(stage: int) -> void:
	stage_pressed.emit(stage)


func _style_stage(
	botao: BaseButton,
	numero: Label,
	nome: Label,
	atual: bool,
	concluida: bool,
	bloqueada: bool,
	chefe: bool
) -> void:
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
	numero.add_theme_color_override("font_color", cor_texto)
	var cor_nome := Color(0.95, 0.88, 0.7, 1)
	if bloqueada:
		cor_nome = Color(0.55, 0.5, 0.4, 1)
	elif atual:
		cor_nome = Color(1, 0.94, 0.6, 1)
	nome.add_theme_color_override("font_color", cor_nome)


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
	return ImageTexture.create_from_image(img)
