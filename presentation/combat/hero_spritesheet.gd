class_name HeroSpritesheet
extends RefCounted
## Monta SpriteFrames de heróis com arte (frames individuais) e utilitários de combate.

const ID_ARQUEIRO := "archer"
const ID_MAGE := "mage"
const ID_TANK := "tank"
const ID_WARRIOR := "warrior"
const ID_BARBARIAN := "barbarian"
const ID_PRIEST := "priest"

const HERO_PX_CLASSES := [
	ID_ARQUEIRO,
	ID_TANK,
	ID_WARRIOR,
	ID_BARBARIAN,
	ID_PRIEST,
]

const MAGE_FRAMES_DIR := "res://sprites/heroes/mage_rabbit/"
const MAGE_RUN_DIR := MAGE_FRAMES_DIR + "run/"
const MAGE_DEATH_DIR := MAGE_FRAMES_DIR + "death/"

const RUN_FPS := 14.0
const IDLE_FPS := 5.0
const DEATH_FPS := 10.0
const ESCALA_STICK := Vector2(1.25, 1.25)
const HERO_ART_FRAME_SIZE := 160.0
const MAGE_ART_FRAME_SIZE := 68.0
const ESCALA_MAGE_ART := Vector2.ONE * (0.55 * (HERO_ART_FRAME_SIZE / MAGE_ART_FRAME_SIZE))
const BARRA_STICK := Vector2(-14, -38)
const HERO_ART_BAR := Vector2(-14, -78)
const HERO_ART_GROUND_OFFSET := Vector2(0, 15)
const HERO_ART_FEET_BELOW_CENTER := 37.4
const HERO_ART_DEATH_FEET_BELOW_CENTER := 37.4
const STICK_FEET_BELOW_CENTER := 22.0

const MAGE_ATTACK_RELEASE_INDEX := 10
const MAGE_ATTACK_START := 4
const MAGE_ATTACK_END := 14
const MAGE_HIT_START := 15
const MAGE_HIT_END := 17

const ARCHER_ARROW_SPAWN := Vector2(10, -8)
const ARCHER_ARROW_SPAWN_BY_FRAME := {
	8: Vector2(12, -7),
	9: Vector2(14, -6),
	10: Vector2(16, -6),
}
const MAGE_ORB_SPAWN := Vector2(30, -14)
const MAGE_ORB_SPAWN_BY_FRAME := {
	8: Vector2(32, -12),
	9: Vector2(36, -10),
	10: Vector2(40, -8),
}
const ATTACK_INTERVAL_BASE := 1.0
const STICK_ATTACK_FPS := 14.0
const STICK_ATTACK_FRAMES := 3
const PX_ATTACK_FPS := 18.0
const MAGE_ATTACK_FPS := 16.0
const HIT_FPS := 12.0
const RANGED_ENGAGE_RANGE := 345.0
const ARCHER_ENGAGE_RANGE := RANGED_ENGAGE_RANGE
const MAGE_ENGAGE_RANGE := RANGED_ENGAGE_RANGE
const STICK_ENGAGE_RANGE := 55.0

static var _frames: Dictionary = {}
static var _textures: Dictionary = {}
static var _attack_release_cache: Dictionary = {}
static var _attack_count_cache: Dictionary = {}


static func has_class_art(id_classe: String) -> bool:
	return frames(id_classe) != null


static func frames(id_classe: String) -> SpriteFrames:
	if _frames.has(id_classe):
		return _frames[id_classe] as SpriteFrames
	var montado: SpriteFrames = null
	match id_classe:
		ID_MAGE:
			montado = _build_mage()
		ID_ARQUEIRO, ID_TANK, ID_WARRIOR, ID_BARBARIAN, ID_PRIEST:
			montado = _build_px_hero(id_classe)
	if montado:
		_frames[id_classe] = montado
	return montado


static func invalidate_cache() -> void:
	_frames.clear()
	_textures.clear()
	_attack_release_cache.clear()
	_attack_count_cache.clear()


static func scale_for(id_classe: String) -> Vector2:
	if _uses_hero_art(id_classe):
		return ESCALA_MAGE_ART
	return ESCALA_STICK


static func health_bar_offset(id_classe: String) -> Vector2:
	if _uses_hero_art(id_classe):
		return HERO_ART_BAR
	return BARRA_STICK


static func attack_release_frame(id_classe: String) -> int:
	if id_classe == ID_MAGE:
		return MAGE_ATTACK_RELEASE_INDEX
	if _attack_release_cache.has(id_classe):
		return _attack_release_cache[id_classe]
	var count := attack_frame_count(id_classe)
	var release := maxi(0, int(floor(float(count - 1) * 0.65)))
	_attack_release_cache[id_classe] = release
	return release


static func arrow_spawn_offset(id_classe: String) -> Vector2:
	match id_classe:
		ID_ARQUEIRO:
			return ARCHER_ARROW_SPAWN
		ID_MAGE:
			return MAGE_ORB_SPAWN
	return Vector2(18, -8)


static func arrow_spawn_offset_for_frame(id_classe: String, frame_idx: int) -> Vector2:
	if id_classe == ID_ARQUEIRO and ARCHER_ARROW_SPAWN_BY_FRAME.has(frame_idx):
		return ARCHER_ARROW_SPAWN_BY_FRAME[frame_idx]
	if id_classe == ID_MAGE and MAGE_ORB_SPAWN_BY_FRAME.has(frame_idx):
		return MAGE_ORB_SPAWN_BY_FRAME[frame_idx]
	return arrow_spawn_offset(id_classe)


static func arrow_target_horizontal(origem: Vector2, alvo: Vector2) -> Vector2:
	return Vector2(alvo.x, origem.y)


static func ground_offset(id_classe: String) -> Vector2:
	if _uses_hero_art(id_classe):
		return HERO_ART_GROUND_OFFSET
	return Vector2.ZERO


static func death_feet_below_center(id_classe: String) -> float:
	if _uses_hero_art(id_classe):
		return HERO_ART_DEATH_FEET_BELOW_CENTER
	return STICK_FEET_BELOW_CENTER


static func death_ground_offset(id_classe: String) -> Vector2:
	if not _uses_hero_art(id_classe):
		return Vector2.ZERO
	var feet_shift := (
		feet_below_center(id_classe) - death_feet_below_center(id_classe)
	) * scale_for(id_classe).y
	return Vector2(0, feet_shift)


static func feet_below_center(id_classe: String) -> float:
	if _uses_hero_art(id_classe):
		return HERO_ART_FEET_BELOW_CENTER
	return STICK_FEET_BELOW_CENTER


static func attack_cooldown(attack_speed: float) -> float:
	return ATTACK_INTERVAL_BASE / maxf(0.25, attack_speed)


static func engage_range(id_classe: String) -> float:
	match id_classe:
		ID_ARQUEIRO:
			return ARCHER_ENGAGE_RANGE
		ID_MAGE:
			return MAGE_ENGAGE_RANGE
	return STICK_ENGAGE_RANGE


static func attack_frame_count(id_classe: String) -> int:
	if _attack_count_cache.has(id_classe):
		return _attack_count_cache[id_classe]
	var count := STICK_ATTACK_FRAMES
	match id_classe:
		ID_MAGE:
			count = MAGE_ATTACK_END - MAGE_ATTACK_START + 1
		ID_ARQUEIRO, ID_TANK, ID_WARRIOR, ID_BARBARIAN, ID_PRIEST:
			count = maxi(1, _count_frames_in_dir(_px_anim_dir(id_classe, "attack")))
	_attack_count_cache[id_classe] = count
	return count


static func attack_base_fps(id_classe: String) -> float:
	if id_classe == ID_MAGE:
		return MAGE_ATTACK_FPS
	if _uses_hero_art(id_classe):
		return PX_ATTACK_FPS
	return STICK_ATTACK_FPS


static func attack_speed_scale(id_classe: String, attack_speed: float) -> float:
	var frame_count := attack_frame_count(id_classe)
	var base_fps := attack_base_fps(id_classe)
	var default_duration := float(frame_count) / base_fps
	var cooldown := attack_cooldown(attack_speed)
	return default_duration / maxf(0.01, cooldown)


static func _uses_hero_art(id_classe: String) -> bool:
	return HERO_PX_CLASSES.has(id_classe) or id_classe == ID_MAGE


static func _px_base_dir(id_classe: String) -> String:
	return "res://sprites/heroes/%s/" % id_classe


static func _px_anim_dir(id_classe: String, anim: String) -> String:
	return _px_base_dir(id_classe).trim_suffix("/") + "/%s/" % anim


static func _build_px_hero(id_classe: String) -> SpriteFrames:
	var sf := SpriteFrames.new()
	_add_anim(sf, "Idle", _load_dir_frames(_px_anim_dir(id_classe, "idle")), true, IDLE_FPS)
	_add_anim(sf, "Corrida", _load_dir_frames(_px_anim_dir(id_classe, "run")), true, RUN_FPS)
	_add_anim(
		sf,
		"Ataque",
		_load_dir_frames(_px_anim_dir(id_classe, "attack")),
		false,
		PX_ATTACK_FPS
	)
	_add_anim(sf, "Morte", _load_dir_frames(_px_anim_dir(id_classe, "death")), false, DEATH_FPS)
	if not sf.has_animation("Idle"):
		return null
	return sf


static func _build_mage() -> SpriteFrames:
	var sf := SpriteFrames.new()
	_add_anim(sf, "Idle", _load_frame_range(MAGE_FRAMES_DIR, 0, 3), true, IDLE_FPS)
	_add_anim(sf, "Corrida", _load_dir_frames(MAGE_RUN_DIR), true, RUN_FPS)
	_add_anim(
		sf,
		"Ataque",
		_load_frame_range(MAGE_FRAMES_DIR, MAGE_ATTACK_START, MAGE_ATTACK_END),
		false,
		MAGE_ATTACK_FPS
	)
	_add_anim(sf, "Hit", _load_frame_range(MAGE_FRAMES_DIR, MAGE_HIT_START, MAGE_HIT_END), false, HIT_FPS)
	_add_anim(sf, "Morte", _load_dir_frames(MAGE_DEATH_DIR), false, DEATH_FPS)
	return sf


static func _count_frames_in_dir(dir: String) -> int:
	var total := 0
	while ResourceLoader.exists("%sframe_%03d.png" % [dir, total]) or _file_exists("%sframe_%03d.png" % [dir, total]):
		total += 1
	return total


static func _load_dir_frames(dir: String) -> Array[Texture2D]:
	var lista: Array[Texture2D] = []
	var count := _count_frames_in_dir(dir)
	for i in count:
		var tex := _load_texture("%sframe_%03d.png" % [dir, i])
		if tex:
			lista.append(tex)
	return lista


static func _file_exists(path: String) -> bool:
	return FileAccess.file_exists(ProjectSettings.globalize_path(path))


static func _load_frame_range(base_dir: String, from_frame: int, to_frame: int) -> Array[Texture2D]:
	var lista: Array[Texture2D] = []
	if from_frame <= to_frame:
		for i in range(from_frame, to_frame + 1):
			var tex := _load_texture("%sframe_%03d.png" % [base_dir, i])
			if tex:
				lista.append(tex)
	else:
		for i in range(from_frame, to_frame - 1, -1):
			var tex := _load_texture("%sframe_%03d.png" % [base_dir, i])
			if tex:
				lista.append(tex)
	return lista


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
