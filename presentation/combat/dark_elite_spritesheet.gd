class_name DarkEliteSpritesheet
extends RefCounted
## SpriteFrames do Dark Elite (idle, corrida, ataque, morte).

const BASE_DIR := "res://sprites/enemies/dark_elite/"
const IDLE_DIR := BASE_DIR + "idle/"
const RUN_DIR := BASE_DIR + "run/"
const ATTACK_DIR := BASE_DIR + "attack/"
const DEATH_DIR := BASE_DIR + "death/"

const SCALE := Vector2(1.0, 1.0)
const HEALTH_BAR_OFFSET := Vector2(-14, -100)
## 88×88 run/attack/death: feet ~y80, center y44 → (80-44)*1.0
const FEET_ALIGN_FALLBACK := 41.0
const FEET_BELOW_CENTER := 36.0
## 64×64 idle: feet ~y59, center y32 → (59-32)*1.0
const IDLE_FEET_BELOW_CENTER := 27.0
const GROUND_FINE_TUNE := -4.0
const DEATH_GROUND_OFFSET := 15.0
const SPAWN_OFFSET := Vector2(129, 0)
const ESCORT_SPAWN_OFFSET := Vector2(115, 0)
const ESCORT_BEHIND_GAP := 14.0
const HP_MULT := 5
const DAMAGE_MULT := 3

const MOVE_SPEED := 90.0
const ATTACK_RANGE := 40.0
const GRAVITY := 520.0

const ATTACK_INTERVAL := 0.85
const RUN_FPS := 14.0
const IDLE_FPS := 5.0
const ATTACK_BASE_FPS := 20.0
const DEATH_FPS := 16.0
const ATTACK_IMPACT_FRAMES: Array[int] = [16]

static var _frames: SpriteFrames
static var _textures: Dictionary = {}


static func frames() -> SpriteFrames:
	if _frames != null:
		return _frames
	_frames = _build()
	return _frames


static func invalidate_cache() -> void:
	_frames = null
	_textures.clear()


static func scale_for() -> Vector2:
	return SCALE


static func health_bar_offset() -> Vector2:
	return HEALTH_BAR_OFFSET


static func feet_align_offset() -> float:
	return FEET_ALIGN_FALLBACK


static func feet_below_center() -> float:
	return FEET_BELOW_CENTER


static func idle_feet_below_center() -> float:
	return IDLE_FEET_BELOW_CENTER


static func ground_fine_tune() -> float:
	return GROUND_FINE_TUNE


static func death_ground_offset() -> float:
	return DEATH_GROUND_OFFSET


static func center_y_for_shared_feet(hero_center_y: float, hero_feet_below: float) -> float:
	return hero_center_y + hero_feet_below - FEET_BELOW_CENTER + GROUND_FINE_TUNE


static func spawn_offset() -> Vector2:
	return SPAWN_OFFSET


static func escort_spawn_offset() -> Vector2:
	return ESCORT_SPAWN_OFFSET


static func escort_behind_gap() -> float:
	return ESCORT_BEHIND_GAP


static func move_speed() -> float:
	return MOVE_SPEED


static func attack_range() -> float:
	return ATTACK_RANGE


static func gravity() -> float:
	return GRAVITY


static func attack_impact_frames() -> Array[int]:
	return ATTACK_IMPACT_FRAMES


static func attack_frame_count() -> int:
	return maxi(1, _count_frames_in_dir(ATTACK_DIR))


static func attack_cooldown() -> float:
	return ATTACK_INTERVAL


static func attack_speed_scale(cooldown: float = ATTACK_INTERVAL) -> float:
	var count := attack_frame_count()
	var default_duration := float(count) / ATTACK_BASE_FPS
	return default_duration / maxf(0.01, cooldown)


static func _build() -> SpriteFrames:
	_textures.clear()
	var sf := SpriteFrames.new()
	_add_anim(sf, "Idle", _load_idle_frames(), true, IDLE_FPS)
	_add_anim(sf, "Corrida", _load_dir(RUN_DIR), true, RUN_FPS)
	_add_anim(sf, "Ataque", _load_dir(ATTACK_DIR), false, ATTACK_BASE_FPS)
	_add_anim(sf, "Morte", _load_dir(DEATH_DIR), false, DEATH_FPS)
	return sf


static func _load_idle_frames() -> Array[Texture2D]:
	var lista: Array[Texture2D] = []
	for idx in [5, 6, 7]:
		var tex := _load_texture("%sframe_%03d.png" % [IDLE_DIR, idx])
		if tex:
			lista.append(tex)
	if lista.is_empty():
		return _load_dir(IDLE_DIR)
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
