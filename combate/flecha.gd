class_name FlechaProjetil
extends AnimatedSprite2D
## Flecha verde que voa do arqueiro até o alvo.

const PNG := "res://sprites/projeteis/2D_pixel-art_animated_arrow_projectile_flying_hori.png"
const DURACAO := 0.18
const ESCALA := Vector2(0.28, 0.28)
const FRAME_VOO := 9
const CELL := 256
const LINHA_VOO := 1

static var _frames: SpriteFrames
static var _sheet: Texture2D


static func disparar(pai: Node, origem: Vector2, destino: Vector2) -> void:
	if pai == null:
		return
	var flecha := FlechaProjetil.new()
	pai.add_child(flecha)
	flecha.global_position = origem
	flecha.z_index = 12
	flecha._voar(destino)


func _ready() -> void:
	centered = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scale = ESCALA
	sprite_frames = _obter_frames()
	if sprite_frames:
		play("Voo")


func _voar(destino: Vector2) -> void:
	var tween := create_tween()
	tween.tween_property(self, "global_position", destino, DURACAO).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)


static func _obter_frames() -> SpriteFrames:
	if _frames:
		return _frames
	var sheet := _carregar_sheet()
	if sheet == null:
		return null
	var sf := SpriteFrames.new()
	sf.add_animation("Voo")
	sf.set_animation_loop("Voo", true)
	sf.set_animation_speed("Voo", 16.0)
	for col in FRAME_VOO:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.filter_clip = true
		atlas.region = Rect2(col * CELL, LINHA_VOO * CELL, CELL, CELL)
		sf.add_frame("Voo", atlas)
	_frames = sf
	return _frames


static func _carregar_sheet() -> Texture2D:
	if _sheet:
		return _sheet
	if ResourceLoader.exists(PNG):
		var recurso: Resource = ResourceLoader.load(PNG)
		if recurso is Texture2D:
			_sheet = recurso
			return _sheet
	var img: Image = Image.load_from_file(ProjectSettings.globalize_path(PNG))
	if img != null and img.get_width() > 1:
		_sheet = ImageTexture.create_from_image(img)
	return _sheet
