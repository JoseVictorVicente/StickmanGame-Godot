class_name ArrowProjectile
extends AnimatedSprite2D
## Flecha do arqueiro: projétil estático que voa até o alvo.

const PNG := "res://sprites/projectiles/archer_arrow.png"
const DURACAO := 0.16
const ESCALA := Vector2(0.16, 0.16)

static var _frames: SpriteFrames
static var _texture: Texture2D


static func fire(pai: Node, origem: Vector2, destino: Vector2) -> void:
	if pai == null:
		return
	var flecha := ArrowProjectile.new()
	pai.add_child(flecha)
	flecha.global_position = origem
	flecha.z_index = 12
	flecha._fly(destino)


func _ready() -> void:
	centered = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scale = ESCALA
	sprite_frames = _get_frames()
	if sprite_frames:
		play("Voo")


func _fly(destino: Vector2) -> void:
	var tween := create_tween()
	tween.tween_property(self, "global_position", destino, DURACAO).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)


static func _get_frames() -> SpriteFrames:
	if _frames:
		return _frames
	var tex := _load_texture()
	if tex == null:
		return null
	var sf := SpriteFrames.new()
	sf.add_animation("Voo")
	sf.set_animation_loop("Voo", true)
	sf.set_animation_speed("Voo", 1.0)
	sf.add_frame("Voo", tex)
	_frames = sf
	return _frames


static func _load_texture() -> Texture2D:
	if _texture:
		return _texture
	if ResourceLoader.exists(PNG):
		var recurso: Resource = ResourceLoader.load(PNG)
		if recurso is Texture2D:
			_texture = recurso
			return _texture
	var img: Image = Image.load_from_file(ProjectSettings.globalize_path(PNG))
	if img != null and img.get_width() > 1:
		_texture = ImageTexture.create_from_image(img)
	return _texture
