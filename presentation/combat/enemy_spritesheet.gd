class_name EnemySpritesheet
extends RefCounted
## Legacy wrapper — visual data lives in data/enemy_visual_profiles/imp_red.tres.

const _PROFILE := preload("res://data/enemy_visual_profiles/imp_red.tres")

const BASE_DIR := "res://sprites/enemies/imp_red/"
const SCALE := Vector2(0.72, 0.72)
const HEALTH_BAR_OFFSET := Vector2(-14, -62)
const FEET_ALIGN_FALLBACK := 28.0
const FEET_BELOW_CENTER := 19.7
const GROUND_FINE_TUNE := -4.0
const DEATH_GROUND_OFFSET := 10.0
const SPAWN_OFFSET := Vector2(88, 0)
const MOVE_SPEED := 90.0
const ATTACK_RANGE := 40.0
const GRAVITY := 520.0
const ATTACK_INTERVAL := 1.35
const RUN_FPS := 16.0
const IDLE_FPS := 5.0
const ATTACK_BASE_FPS := 33.0
const DEATH_FPS := 18.0
const ATTACK_IMPACT_FRAMES: Array[int] = [12, 24, 36]


static func frames() -> SpriteFrames:
	return EnemySpritesheetBuilder.frames(_PROFILE)


static func invalidate_cache() -> void:
	EnemySpritesheetBuilder.invalidate_cache(_PROFILE)


static func scale_for() -> Vector2:
	return _PROFILE.scale


static func health_bar_offset() -> Vector2:
	return _PROFILE.health_bar_offset


static func feet_align_offset() -> float:
	return _PROFILE.feet_align_fallback


static func feet_below_center() -> float:
	return _PROFILE.feet_below_center


static func ground_fine_tune() -> float:
	return _PROFILE.ground_fine_tune


static func death_ground_offset() -> float:
	return _PROFILE.death_ground_offset


static func center_y_for_shared_feet(hero_center_y: float, hero_feet_below: float) -> float:
	return hero_center_y + hero_feet_below - FEET_BELOW_CENTER + GROUND_FINE_TUNE


static func spawn_offset() -> Vector2:
	return _PROFILE.spawn_offset


static func move_speed() -> float:
	return _PROFILE.move_speed


static func attack_range() -> float:
	return _PROFILE.attack_range


static func gravity() -> float:
	return _PROFILE.gravity


static func attack_impact_frames() -> Array[int]:
	var frames: Array[int] = []
	for frame_idx in _PROFILE.attack_impact_frames:
		frames.append(frame_idx)
	return frames


static func attack_frame_count() -> int:
	return EnemySpritesheetBuilder.attack_frame_count(_PROFILE)


static func attack_cooldown() -> float:
	return _PROFILE.attack_interval


static func attack_speed_scale(cooldown: float = ATTACK_INTERVAL) -> float:
	return EnemySpritesheetBuilder.attack_speed_scale(_PROFILE, cooldown)
