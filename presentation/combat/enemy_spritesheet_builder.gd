class_name EnemySpritesheetBuilder
extends RefCounted
## Builds cached SpriteFrames from an EnemyVisualProfile.

static var _frames_cache: Dictionary = {}
static var _textures: Dictionary = {}


static func frames(profile: EnemyVisualProfile) -> SpriteFrames:
	if profile == null:
		return null
	var key := profile.resource_path if profile.resource_path != "" else profile.profile_id
	if key == "":
		key = profile.base_dir
	if _frames_cache.has(key):
		return _frames_cache[key] as SpriteFrames
	var built := _build(profile)
	_frames_cache[key] = built
	return built


static func invalidate_cache(profile: EnemyVisualProfile = null) -> void:
	if profile == null:
		_frames_cache.clear()
		_textures.clear()
		return
	var key := profile.resource_path if profile.resource_path != "" else profile.profile_id
	if key == "":
		key = profile.base_dir
	_frames_cache.erase(key)


static func attack_frame_count(profile: EnemyVisualProfile) -> int:
	if profile == null:
		return 1
	var attack_dir := _attack_dir(profile)
	return maxi(1, _count_frames_in_dir(attack_dir))


static func attack_speed_scale(profile: EnemyVisualProfile, cooldown: float) -> float:
	if profile == null:
		return 1.0
	var count := attack_frame_count(profile)
	var default_duration := float(count) / maxf(0.01, profile.attack_base_fps)
	return default_duration / maxf(0.01, cooldown)


static func _build(profile: EnemyVisualProfile) -> SpriteFrames:
	var sf := SpriteFrames.new()
	_add_anim(sf, "Idle", _load_idle_frames(profile), true, profile.idle_fps)
	_add_anim(sf, "Corrida", _load_dir(_run_dir(profile)), true, profile.run_fps)
	_add_anim(sf, "Ataque", _load_dir(_attack_dir(profile)), false, profile.attack_base_fps)
	_add_anim(sf, "Morte", _load_dir(_death_dir(profile)), false, profile.death_fps)
	return sf


static func _idle_dir(profile: EnemyVisualProfile) -> String:
	return profile.base_dir.trim_suffix("/") + "/idle/"


static func _run_dir(profile: EnemyVisualProfile) -> String:
	return profile.base_dir.trim_suffix("/") + "/run/"


static func _attack_dir(profile: EnemyVisualProfile) -> String:
	return profile.base_dir.trim_suffix("/") + "/attack/"


static func _death_dir(profile: EnemyVisualProfile) -> String:
	return profile.base_dir.trim_suffix("/") + "/death/"


static func _load_idle_frames(profile: EnemyVisualProfile) -> Array[Texture2D]:
	if profile.idle_frame_indices.is_empty():
		return _load_dir(_idle_dir(profile))
	var lista: Array[Texture2D] = []
	for idx in profile.idle_frame_indices:
		var tex := _load_texture("%sframe_%03d.png" % [_idle_dir(profile), idx])
		if tex:
			lista.append(tex)
	if lista.is_empty():
		return _load_dir(_idle_dir(profile))
	return lista


static func _load_dir(dir: String) -> Array[Texture2D]:
	var lista: Array[Texture2D] = []
	var count := _count_frames_in_dir(dir)
	for i in count:
		var tex := _load_texture("%sframe_%03d.png" % [dir, i])
		if tex:
			lista.append(tex)
	return lista


static func _count_frames_in_dir(dir: String) -> int:
	var total := 0
	while ResourceLoader.exists("%sframe_%03d.png" % [dir, total]) or _file_exists("%sframe_%03d.png" % [dir, total]):
		total += 1
	return total


static func _file_exists(path: String) -> bool:
	return FileAccess.file_exists(ProjectSettings.globalize_path(path))


static func _add_anim(sf: SpriteFrames, nome: String, texturas: Array[Texture2D], loop: bool, fps: float) -> void:
	if texturas.is_empty():
		return
	if not sf.has_animation(nome):
		sf.add_animation(nome)
	sf.set_animation_loop(nome, loop)
	sf.set_animation_speed(nome, fps)
	for tex in texturas:
		sf.add_frame(nome, tex)


static func _load_texture(caminho: String) -> Texture2D:
	if _textures.has(caminho):
		return _textures[caminho] as Texture2D
	var tex: Texture2D = null
	if ResourceLoader.exists(caminho):
		var recurso: Resource = ResourceLoader.load(caminho)
		if recurso is Texture2D:
			tex = recurso
	if tex == null:
		var absoluto := ProjectSettings.globalize_path(caminho)
		var img: Image = Image.load_from_file(absoluto)
		if img != null and img.get_width() > 1:
			tex = ImageTexture.create_from_image(img)
	if tex:
		_textures[caminho] = tex
	return tex
