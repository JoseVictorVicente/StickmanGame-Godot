class_name CombatBurstVfx
extends AnimatedSprite2D
## One-shot local burst (fire, sparks) at a world position.

const ANIM := "Burst"

static var _frames_cache: Dictionary = {}


static func spawn_on(
	parent: Node2D,
	local_offset: Vector2,
	vfx_dir: String,
	scale_v: Vector2,
	fps: float
) -> void:
	if parent == null or vfx_dir == "":
		return
	var frames := _load_frames(vfx_dir)
	if frames == null or not frames.has_animation(ANIM):
		push_warning("CombatBurstVfx: no frames in %s" % vfx_dir)
		return
	var burst := CombatBurstVfx.new()
	burst.centered = true
	burst.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	burst.position = local_offset
	burst.z_index = 4
	burst.scale = scale_v
	burst.sprite_frames = frames.duplicate(true)
	burst.sprite_frames.set_animation_speed(ANIM, fps)
	parent.add_child(burst)
	burst.animation_finished.connect(burst.queue_free)
	burst.play(ANIM)


static func _load_frames(vfx_dir: String) -> SpriteFrames:
	var key := vfx_dir.trim_suffix("/") + "/"
	if _frames_cache.has(key):
		return _frames_cache[key] as SpriteFrames
	var dir_path := key
	var lista: Array[Texture2D] = []
	var index := 0
	while true:
		var path := "%sframe_%03d.png" % [dir_path, index]
		if not ResourceLoader.exists(path) and not FileAccess.file_exists(ProjectSettings.globalize_path(path)):
			break
		var tex := _load_texture(path)
		if tex == null:
			break
		lista.append(tex)
		index += 1
	if lista.is_empty():
		return null
	var sf := SpriteFrames.new()
	sf.add_animation(ANIM)
	sf.set_animation_loop(ANIM, false)
	sf.set_animation_speed(ANIM, 12.0)
	for tex in lista:
		sf.add_frame(ANIM, tex)
	_frames_cache[key] = sf
	return sf


static func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var recurso: Resource = ResourceLoader.load(path)
		if recurso is Texture2D:
			return recurso
	var absoluto := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(absoluto):
		return null
	var img: Image = Image.load_from_file(absoluto)
	if img == null or img.get_width() <= 1:
		return null
	return ImageTexture.create_from_image(img)
