class_name ArrowProjectile
extends AnimatedSprite2D
## Flecha do arqueiro: projétil estático que voa até o alvo.

const PNG := "res://sprites/projectiles/archer_arrow.png"
const SPEED_PX := 620.0
const MIN_DURACAO := 0.06
const MAX_DURACAO := 0.75
const ESCALA := Vector2(0.16, 0.16)

static var _frames: SpriteFrames
static var _texture: Texture2D


static func fire(pai: Node, origem: Vector2, destino: Vector2, on_hit: Callable = Callable()) -> void:
	if pai == null:
		return
	var flecha := ArrowProjectile.new()
	pai.add_child(flecha)
	flecha.global_position = origem
	flecha.z_index = 12
	flecha._fly(destino, on_hit)


func _ready() -> void:
	centered = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scale = ESCALA
	sprite_frames = _get_frames()
	if sprite_frames:
		play("Voo")


func _fly(destino: Vector2, on_hit: Callable) -> void:
	var delta := destino - global_position
	if delta.length_squared() < 1.0:
		_call_hit(on_hit)
		queue_free()
		return
	rotation = delta.angle()
	var duracao := maxf(MIN_DURACAO, delta.length() / SPEED_PX)
	duracao = minf(duracao, MAX_DURACAO)
	var tween := create_tween()
	tween.tween_property(self, "global_position", destino, duracao).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(func() -> void:
		_call_hit(on_hit)
		queue_free()
	)


func _call_hit(on_hit: Callable) -> void:
	if on_hit.is_valid():
		on_hit.call()


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
