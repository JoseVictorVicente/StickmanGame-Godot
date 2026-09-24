class_name FlyingDemonSpritesheet
extends RefCounted
## SpriteFrames do Flying Demon (idle hover, corrida/voo, ataque aéreo, morte).

const BASE_DIR := "res://sprites/enemies/flying_demon/"
const SOURCE_DIR := BASE_DIR + "source/"
const IDLE_DIR := BASE_DIR + "idle/"
const RUN_DIR := BASE_DIR + "run/"
const ATTACK_DIR := BASE_DIR + "attack/"
const DEATH_DIR := BASE_DIR + "death/"

const SCALE := Vector2(1.3, 1.3)
const HEALTH_BAR_OFFSET := Vector2(-14, -100)
const FEET_ALIGN_FALLBACK := 36.0
## 88x88 run/attack/death: feet ~y72, center y44
const FEET_BELOW_CENTER := 30.0
## 88x88 idle hover: feet ~y68, center y44
const IDLE_FEET_BELOW_CENTER := 26.0
const GROUND_FINE_TUNE := -29.0
const DEATH_GROUND_OFFSET := 8.0
const SPAWN_OFFSET := Vector2(145, -10)
const ESCORT_SPAWN_OFFSET := Vector2(200, -12)
const ESCORT_BEHIND_GAP := 14.0
const HP_MULT := 10
const DAMAGE_MULT := 3

const MOVE_SPEED := 95.0
const ATTACK_RANGE := 42.0
const GRAVITY := 280.0

const ATTACK_INTERVAL := 0.85
const RUN_FPS := 12.0
const IDLE_FPS := 8.0
const ATTACK_BASE_FPS := 16.0
const DEATH_FPS := 14.0
const ATTACK_IMPACT_FRAMES: Array[int] = [21]

const IDLE_FRAME_COUNT := 8
const RUN_FRAME_COUNT := 41
const ATTACK_FRAME_COUNT := 41
const DEATH_FRAME_COUNT := 41
const MIN_BAKED_FRAMES := {
	"idle": 6,
	"run": 30,
	"attack": 25,
	"death": 30,
}

const SOURCE_ALIASES := {
	"idle": ["idle.png", "BOSS_CORRENDO"],
	"run": ["run.png", "ANDANDO", "VOANDO"],
	"attack": ["attack.png", "ATAQUE"],
	"death": ["death.png", "MORRENDO"],
}

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
	var dir_count := _count_frames_in_dir(ATTACK_DIR)
	if dir_count >= int(MIN_BAKED_FRAMES.attack):
		return dir_count
	var sheet := _find_source(SOURCE_ALIASES.attack)
	if sheet == "":
		return 1
	return maxi(1, _count_sheet_frames(sheet, 0))


static func attack_cooldown() -> float:
	return ATTACK_INTERVAL


static func attack_speed_scale(cooldown: float = ATTACK_INTERVAL) -> float:
	var count := attack_frame_count()
	var default_duration := float(count) / ATTACK_BASE_FPS
	return default_duration / maxf(0.01, cooldown)


static func _build() -> SpriteFrames:
	_textures.clear()
	var sf := SpriteFrames.new()
	var idle := _load_idle_anim()
	var run := _load_run_anim()
	var attack := _load_attack_anim()
	var death := _load_death_anim()
	_add_anim(sf, "Idle", idle, true, IDLE_FPS)
	_add_anim(sf, "Corrida", run, true, RUN_FPS)
	_add_anim(sf, "Ataque", attack, false, ATTACK_BASE_FPS)
	_add_anim(sf, "Morte", death, false, DEATH_FPS)
	return sf


static func _load_idle_anim() -> Array[Texture2D]:
	var baked := _load_dir_if_complete(IDLE_DIR, int(MIN_BAKED_FRAMES.idle))
	if not baked.is_empty():
		return baked
	var sheet := _find_source(SOURCE_ALIASES.idle)
	if sheet != "":
		return _load_horizontal_sheet(sheet, IDLE_FRAME_COUNT)
	var rotation := _find_source(["IDLE_ANIMATION"])
	if rotation != "":
		return _load_side_idle_from_rotation(rotation)
	return []


static func _load_run_anim() -> Array[Texture2D]:
	var baked := _load_dir_if_complete(RUN_DIR, int(MIN_BAKED_FRAMES.run))
	if not baked.is_empty():
		return baked
	var sheet := _find_source(SOURCE_ALIASES.run)
	if sheet != "":
		return _load_horizontal_sheet(sheet, RUN_FRAME_COUNT)
	return []


static func _load_attack_anim() -> Array[Texture2D]:
	var baked := _load_dir_if_complete(ATTACK_DIR, int(MIN_BAKED_FRAMES.attack))
	if not baked.is_empty():
		return baked
	var sheet := _find_source(SOURCE_ALIASES.attack)
	if sheet != "":
		return _load_horizontal_sheet(sheet, ATTACK_FRAME_COUNT)
	return []


static func _load_death_anim() -> Array[Texture2D]:
	var baked := _load_dir_if_complete(DEATH_DIR, int(MIN_BAKED_FRAMES.death))
	if not baked.is_empty():
		return baked
	var sheet := _find_source(SOURCE_ALIASES.death)
	if sheet != "":
		return _load_horizontal_sheet(sheet, DEATH_FRAME_COUNT)
	return []


static func _load_dir_if_complete(dir: String, min_frames: int) -> Array[Texture2D]:
	var lista := _load_dir(dir)
	if lista.size() >= min_frames:
		return lista
	return []


static func _load_side_idle_from_rotation(sheet_path: String) -> Array[Texture2D]:
	var all := _load_horizontal_sheet(sheet_path, 8)
	if all.is_empty():
		return []
	if all.size() >= 8:
		return [all[5], all[6], all[7], all[6]]
	if all.size() >= 7:
		return [all[5], all[6], all[7]]
	return [all[mini(6, all.size() - 1)]]


static func _find_source(aliases: Array) -> String:
	for alias in aliases:
		var direct := SOURCE_DIR + str(alias)
		if _file_exists(direct) or ResourceLoader.exists(direct):
			return direct
	var dir := DirAccess.open(SOURCE_DIR)
	if dir == null:
		return ""
	for file_name in dir.get_files():
		if not file_name.to_lower().ends_with(".png"):
			continue
		for alias in aliases:
			if file_name.contains(str(alias)):
				return SOURCE_DIR + file_name
	return ""


static func _load_dir(dir: String) -> Array[Texture2D]:
	var lista: Array[Texture2D] = []
	var count := _count_frames_in_dir(dir)
	for i in count:
		var tex := _load_texture("%sframe_%03d.png" % [dir, i])
		if tex:
			lista.append(tex)
	return lista


static func _load_horizontal_sheet(path: String, frame_count: int) -> Array[Texture2D]:
	var img := _load_image(path)
	if img == null:
		return []
	var sheet_w := img.get_width()
	var sheet_h := img.get_height()
	if sheet_h <= 0:
		return []
	var frame_w := sheet_h
	if frame_count > 0:
		frame_w = sheet_w / frame_count
	var total := frame_count if frame_count > 0 else sheet_w / frame_w
	if total <= 0 or frame_w <= 0:
		return []
	var lista: Array[Texture2D] = []
	for i in total:
		var region := Rect2i(i * frame_w, 0, frame_w, sheet_h)
		var frame := img.get_region(region)
		var tex := ImageTexture.create_from_image(frame)
		lista.append(tex)
	return lista


static func _count_sheet_frames(path: String, frame_count: int) -> int:
	if frame_count > 0:
		return frame_count
	var img := _load_image(path)
	if img == null or img.get_height() <= 0:
		return 0
	return img.get_width() / img.get_height()


static func _count_frames_in_dir(dir: String) -> int:
	var total := 0
	while ResourceLoader.exists("%sframe_%03d.png" % [dir, total]) or _file_exists("%sframe_%03d.png" % [dir, total]):
		total += 1
	return total


static func _file_exists(path: String) -> bool:
	return FileAccess.file_exists(ProjectSettings.globalize_path(path))


static func _load_image(path: String) -> Image:
	var tex := _load_texture(path)
	if tex != null:
		return tex.get_image()
	var absoluto := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(absoluto):
		return null
	return Image.load_from_file(absoluto)


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
