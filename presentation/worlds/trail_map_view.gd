class_name TrailMapView
extends Control

signal stage_pressed(stage: int)

const WorldCatalog := preload("res://data/world_catalog.gd")
const BOSS_SIZE := 48.0
const STAGE_SIZE := 34.0

@onready var stage_map: StageMap = %StageMap
@onready var map_background: TextureRect = %MapBackground
@onready var map_layer: Control = %MapLayer

var _stage_buttons: Array[BaseButton] = []
var _stage_numbers: Array[Label] = []
var _stage_names: Array[Label] = []
var _stage_tex: ImageTexture
var _boss_tex: ImageTexture


func _ready() -> void:
	_wire_stage_nodes()


func bind_trail(
	world: int,
	current_world: int,
	current_stage: int,
	difficulty: int,
	unlocked: Array[int],
	is_stage_unlocked: Callable
) -> void:
	map_background.texture = WorldCatalog.map_texture(world)
	stage_map.refresh_path()
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


func _wire_stage_nodes() -> void:
	_stage_tex = _circle_texture(int(STAGE_SIZE))
	_boss_tex = _circle_texture(int(BOSS_SIZE))
	_stage_numbers.clear()
	_stage_names.clear()
	_stage_buttons.clear()
	for i in WorldProgress.STAGES_PER_WORLD:
		var indice := i + 1
		var ancora := map_layer.get_node_or_null("StageAnchor_%d" % indice) as Control
		var coluna := ancora.get_node_or_null("CenterWrap/StageColumn") as VBoxContainer if ancora else null
		var botao := coluna.get_node_or_null("StageButton") as TextureButton if coluna else null
		var numero := botao.get_node_or_null("StageNumber") as Label if botao else null
		var nome := coluna.get_node_or_null("StageNameLabel") as Label if coluna else null
		assert(ancora != null and coluna != null and botao != null and numero != null and nome != null)
		var chefe := WorldCatalog.is_boss_stage(indice)
		botao.texture_normal = _boss_tex if chefe else _stage_tex
		botao.texture_pressed = botao.texture_normal
		botao.texture_hover = botao.texture_normal
		botao.texture_disabled = botao.texture_normal
		if not botao.get_meta(&"wired", false):
			botao.pressed.connect(_on_stage_pressed.bind(indice))
			botao.set_meta(&"wired", true)
		_stage_buttons.append(botao)
		_stage_numbers.append(numero)
		_stage_names.append(nome)


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
