class_name HeroSpritesheet
extends RefCounted
## Monta SpriteFrames de heróis com arte (frames individuais) e utilitários de combate.

const ID_ARQUEIRO := "archer"
const ID_TANK := "tank"
const ID_WARRIOR := "warrior"

const ARCHER_FRAMES_DIR := "res://sprites/heroes/archer_fennec/"
const ARCHER_RUN_DIR := ARCHER_FRAMES_DIR + "run/"
const ARCHER_DEATH_DIR := ARCHER_FRAMES_DIR + "death/"

const TANK_FRAMES_DIR := "res://sprites/heroes/tank_capybara/"
const TANK_RUN_DIR := TANK_FRAMES_DIR + "run/"
const TANK_DEATH_DIR := TANK_FRAMES_DIR + "death/"

const WARRIOR_FRAMES_DIR := "res://sprites/heroes/warrior_boar/"
const WARRIOR_RUN_DIR := WARRIOR_FRAMES_DIR + "run/"

const RUN_FPS := 14.0
const DEATH_FPS := 10.0
const ESCALA_STICK := Vector2(1.25, 1.25)
const ESCALA_HERO_ART := Vector2(0.55, 0.55)
const BARRA_STICK := Vector2(-14, -38)
const HERO_ART_BAR := Vector2(-14, -78)
const HERO_ART_GROUND_OFFSET := Vector2(0, 15)
const HERO_ART_FEET_BELOW_CENTER := 37.4
const HERO_ART_DEATH_FEET_BELOW_CENTER := 37.4
const STICK_FEET_BELOW_CENTER := 22.0

const ARCHER_ATTACK_RELEASE_INDEX := 9
const ARCHER_ATTACK_START := 4
const ARCHER_ATTACK_END := 16

const TANK_ATTACK_RELEASE_INDEX := 10
const TANK_ATTACK_START := 4
const TANK_ATTACK_END := 24
const TANK_HIT_START := 25
const TANK_HIT_END := 27

const WARRIOR_ATTACK_RELEASE_INDEX := 14
const WARRIOR_ATTACK_START := 4
const WARRIOR_ATTACK_END := 17
const WARRIOR_HIT_START := 18
const WARRIOR_HIT_END := 20

const ARCHER_ARROW_SPAWN := Vector2(22, -14)
const ARCHER_ARROW_SPAWN_BY_FRAME := {
	8: Vector2(24, -12),
	9: Vector2(30, -10),
	10: Vector2(34, -10),
}
const ATTACK_INTERVAL_BASE := 1.0
const STICK_ATTACK_FPS := 14.0
const STICK_ATTACK_FRAMES := 3
const ARCHER_ATTACK_FPS := 20.0
const TANK_ATTACK_FPS := 18.0
const WARRIOR_ATTACK_FPS := 18.0
const HIT_FPS := 12.0
const ARCHER_ENGAGE_RANGE := 345.0
const STICK_ENGAGE_RANGE := 55.0

static var _frames: Dictionary = {}
static var _textures: Dictionary = {}


static func has_class_art(id_classe: String) -> bool:
	return frames(id_classe) != null


static func frames(id_classe: String) -> SpriteFrames:
	if _frames.has(id_classe):
		return _frames[id_classe] as SpriteFrames
	var montado: SpriteFrames = null
	match id_classe:
		ID_ARQUEIRO:
			montado = _build_archer()
		ID_TANK:
			montado = _build_tank()
		ID_WARRIOR:
			montado = _build_warrior()
	if montado:
		_frames[id_classe] = montado
	return montado


static func invalidate_cache() -> void:
	_frames.clear()
	_textures.clear()


static func scale_for(id_classe: String) -> Vector2:
	if _uses_hero_art(id_classe):
		return ESCALA_HERO_ART
	return ESCALA_STICK


static func health_bar_offset(id_classe: String) -> Vector2:
	if _uses_hero_art(id_classe):
		return HERO_ART_BAR
	return BARRA_STICK


static func attack_release_frame(id_classe: String) -> int:
	match id_classe:
		ID_ARQUEIRO:
			return ARCHER_ATTACK_RELEASE_INDEX
		ID_TANK:
			return TANK_ATTACK_RELEASE_INDEX
		ID_WARRIOR:
			return WARRIOR_ATTACK_RELEASE_INDEX
	return 4


static func arrow_spawn_offset(id_classe: String) -> Vector2:
	if id_classe == ID_ARQUEIRO:
		return ARCHER_ARROW_SPAWN
	return Vector2(18, -8)


static func arrow_spawn_offset_for_frame(id_classe: String, frame_idx: int) -> Vector2:
	if id_classe == ID_ARQUEIRO and ARCHER_ARROW_SPAWN_BY_FRAME.has(frame_idx):
		return ARCHER_ARROW_SPAWN_BY_FRAME[frame_idx]
	return arrow_spawn_offset(id_classe)


static func arrow_target_horizontal(origem: Vector2, alvo: Vector2) -> Vector2:
	return Vector2(alvo.x, origem.y)


static func ground_offset(id_classe: String) -> Vector2:
	if _uses_hero_art(id_classe):
		return HERO_ART_GROUND_OFFSET
	return Vector2.ZERO


static func death_feet_below_center(id_classe: String) -> float:
	if _uses_hero_art(id_classe):
		match id_classe:
			ID_ARQUEIRO, ID_TANK, ID_WARRIOR:
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
	if id_classe == ID_ARQUEIRO:
		return ARCHER_ENGAGE_RANGE
	return STICK_ENGAGE_RANGE


static func attack_frame_count(id_classe: String) -> int:
	match id_classe:
		ID_ARQUEIRO:
			return ARCHER_ATTACK_END - ARCHER_ATTACK_START + 1
		ID_TANK:
			return TANK_ATTACK_END - TANK_ATTACK_START + 1
		ID_WARRIOR:
			return WARRIOR_ATTACK_END - WARRIOR_ATTACK_START + 1
	return STICK_ATTACK_FRAMES


static func attack_base_fps(id_classe: String) -> float:
	match id_classe:
		ID_ARQUEIRO:
			return ARCHER_ATTACK_FPS
		ID_TANK:
			return TANK_ATTACK_FPS
		ID_WARRIOR:
			return WARRIOR_ATTACK_FPS
	return STICK_ATTACK_FPS


static func attack_speed_scale(id_classe: String, attack_speed: float) -> float:
	var frame_count := attack_frame_count(id_classe)
	var base_fps := attack_base_fps(id_classe)
	var default_duration := float(frame_count) / base_fps
	var cooldown := attack_cooldown(attack_speed)
	return default_duration / maxf(0.01, cooldown)


static func _uses_hero_art(id_classe: String) -> bool:
	return id_classe == ID_ARQUEIRO or id_classe == ID_TANK or id_classe == ID_WARRIOR


static func _build_archer() -> SpriteFrames:
	var sf := SpriteFrames.new()
	_add_anim(sf, "Idle", _load_frame_range(ARCHER_FRAMES_DIR, 0, 3), true, 5.0)
	_add_anim(sf, "Corrida", _load_dir_frames(ARCHER_RUN_DIR), true, RUN_FPS)
	_add_anim(
		sf,
		"Ataque",
		_load_frame_range(ARCHER_FRAMES_DIR, ARCHER_ATTACK_START, ARCHER_ATTACK_END),
		false,
		ARCHER_ATTACK_FPS
	)
	_add_anim(sf, "Hit", _load_frame_range(ARCHER_FRAMES_DIR, 5, 7), false, HIT_FPS)
	_add_anim(sf, "Morte", _load_dir_frames(ARCHER_DEATH_DIR), false, DEATH_FPS)
	return sf


static func _build_warrior() -> SpriteFrames:
	var sf := SpriteFrames.new()
	_add_anim(sf, "Idle", _load_frame_range(WARRIOR_FRAMES_DIR, 0, 3), true, 5.0)
	_add_anim(sf, "Corrida", _load_dir_frames(WARRIOR_RUN_DIR), true, RUN_FPS)
	_add_anim(
		sf,
		"Ataque",
		_load_frame_range(WARRIOR_FRAMES_DIR, WARRIOR_ATTACK_START, WARRIOR_ATTACK_END),
		false,
		WARRIOR_ATTACK_FPS
	)
	_add_anim(
		sf,
		"Hit",
		_load_frame_range(WARRIOR_FRAMES_DIR, WARRIOR_HIT_START, WARRIOR_HIT_END),
		false,
		HIT_FPS
	)
	return sf


static func _build_tank() -> SpriteFrames:
	var sf := SpriteFrames.new()
	_add_anim(sf, "Idle", _load_frame_range(TANK_FRAMES_DIR, 0, 3), true, 5.0)
	_add_anim(sf, "Corrida", _load_dir_frames(TANK_RUN_DIR), true, RUN_FPS)
	_add_anim(
		sf,
		"Ataque",
		_load_frame_range(TANK_FRAMES_DIR, TANK_ATTACK_START, TANK_ATTACK_END),
		false,
		TANK_ATTACK_FPS
	)
	_add_anim(sf, "Hit", _load_frame_range(TANK_FRAMES_DIR, TANK_HIT_START, TANK_HIT_END), false, HIT_FPS)
	_add_anim(sf, "Morte", _load_dir_frames(TANK_DEATH_DIR), false, DEATH_FPS)
	return sf


static func _load_dir_frames(dir: String) -> Array[Texture2D]:
	var lista: Array[Texture2D] = []
	var index := 0
	while ResourceLoader.exists("%sframe_%03d.png" % [dir, index]) or _file_exists("%sframe_%03d.png" % [dir, index]):
		var tex := _load_texture("%sframe_%03d.png" % [dir, index])
		if tex:
			lista.append(tex)
		index += 1
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
