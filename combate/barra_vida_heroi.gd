class_name BarraVidaHeroi
extends TextureProgressBar
## TextureProgressBar flutuando acima da cabeça. O valor é a porcentagem de vida.

const LARGURA := 28
const ALTURA := 5
const DESLOCAMENTO := Vector2(-14, -38)

static var _tex_fundo: Texture2D
static var _tex_preenchimento: Texture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	min_value = 0.0
	max_value = 100.0
	value = 100.0
	nine_patch_stretch = true
	fill_mode = FILL_LEFT_TO_RIGHT
	custom_minimum_size = Vector2(LARGURA, ALTURA)
	size = Vector2(LARGURA, ALTURA)
	position = DESLOCAMENTO
	z_index = 8
	texture_under = _textura_fundo()
	texture_progress = _textura_preenchimento()
	tint_progress = Color(0.28, 0.82, 0.32, 1)
	_corrigir_escala_do_pai()


func ajustar_no_pai(deslocamento: Vector2) -> void:
	position = deslocamento
	_corrigir_escala_do_pai()


func atualizar(atual: int, maximo: int) -> void:
	var pct := 0.0
	if maximo > 0:
		pct = clampf(float(atual) / float(maximo) * 100.0, 0.0, 100.0)
	max_value = 100.0
	value = pct
	visible = maximo > 0
	if pct <= 25.0:
		tint_progress = Color(0.86, 0.22, 0.18, 1)
	elif pct <= 55.0:
		tint_progress = Color(0.88, 0.72, 0.18, 1)
	else:
		tint_progress = Color(0.28, 0.82, 0.32, 1)


func _corrigir_escala_do_pai() -> void:
	var pai: Node = get_parent()
	if pai is Node2D:
		var s: Vector2 = (pai as Node2D).scale
		if s.x != 0.0 and s.y != 0.0:
			scale = Vector2(1.0 / s.x, 1.0 / s.y)


static func _textura_fundo() -> Texture2D:
	if _tex_fundo == null:
		_tex_fundo = _textura_solida(Color(0.08, 0.06, 0.05, 0.95))
	return _tex_fundo


static func _textura_preenchimento() -> Texture2D:
	if _tex_preenchimento == null:
		_tex_preenchimento = _textura_solida(Color(1, 1, 1, 1))
	return _tex_preenchimento


static func _textura_solida(cor: Color) -> Texture2D:
	var img := Image.create(8, ALTURA, false, Image.FORMAT_RGBA8)
	img.fill(cor)
	return ImageTexture.create_from_image(img)
