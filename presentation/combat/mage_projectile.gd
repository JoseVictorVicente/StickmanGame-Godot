class_name MageProjectile
extends AnimatedSprite2D
## Orbe arcano do mago: projétil animado, mais lento que a flecha do arqueiro.

const FRAMES_DIR := "res://sprites/projectiles/mage_orb/"
const SPEED_PX := 460.0
const MIN_DURACAO := 0.08
const MAX_DURACAO := 0.95
const ESCALA := Vector2(1.45, 1.45)
const ANIM_FPS := 12.0

static var _frames: SpriteFrames
static var _textures: Dictionary = {}


static func fire(
	pai: Node,
	origem: Vector2,
	destino: Vector2,
	on_hit: Callable = Callable(),
	speed_mult: float = 1.0
) -> void:
	if pai == null:
		return
	var orbe := MageProjectile.new()
	pai.add_child(orbe)
	orbe.global_position = origem
	orbe.z_index = 12
	orbe._fly(destino, on_hit, speed_mult)


func _ready() -> void:
	centered = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scale = ESCALA
	sprite_frames = _get_frames()
	if sprite_frames:
		play("Voo")


func _fly(destino: Vector2, on_hit: Callable, speed_mult: float = 1.0) -> void:
	var delta := destino - global_position
	if delta.length_squared() < 1.0:
		_call_hit(on_hit)
		queue_free()
		return
	rotation = delta.angle()
	var duracao := maxf(MIN_DURACAO, delta.length() / SPEED_PX)
	duracao /= maxf(1.0, speed_mult)
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
	var texturas: Array[Texture2D] = []
	var index := 0
	while true:
		var caminho := "%sframe_%03d.png" % [FRAMES_DIR, index]
		if not ResourceLoader.exists(caminho) and not FileAccess.file_exists(
			ProjectSettings.globalize_path(caminho)
		):
			break
		var tex := _load_texture(caminho)
		if tex == null:
			break
		texturas.append(tex)
		index += 1
	if texturas.is_empty():
		return null
	var sf := SpriteFrames.new()
	sf.add_animation("Voo")
	sf.set_animation_loop("Voo", true)
	sf.set_animation_speed("Voo", ANIM_FPS)
	for tex in texturas:
		sf.add_frame("Voo", tex)
	_frames = sf
	return _frames


static func _load_texture(caminho: String) -> Texture2D:
	if _textures.has(caminho):
		return _textures[caminho] as Texture2D
	var tex: Texture2D = null
	if ResourceLoader.exists(caminho):
		var recurso: Resource = ResourceLoader.load(caminho)
		if recurso is Texture2D:
			tex = recurso
	if tex == null:
		var img: Image = Image.load_from_file(ProjectSettings.globalize_path(caminho))
		if img != null and img.get_width() > 1:
			tex = ImageTexture.create_from_image(img)
	if tex:
		_textures[caminho] = tex
	return tex
