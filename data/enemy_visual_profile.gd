class_name EnemyVisualProfile
extends Resource
## Visual and movement tuning for an enemy archetype (sprites + combat presentation).

@export var profile_id: String = ""
@export var base_dir: String = "res://sprites/enemies/imp_red/"
@export var scale: Vector2 = Vector2(0.72, 0.72)
@export var health_bar_offset: Vector2 = Vector2(-14, -62)
@export var feet_align_fallback: float = 28.0
@export var feet_below_center: float = 19.7
## When >= 0, used for Idle animation feet alignment; otherwise feet_below_center.
@export var idle_feet_below_center: float = -1.0
@export var ground_fine_tune: float = -4.0
@export var death_ground_offset: float = 10.0
@export var spawn_offset: Vector2 = Vector2(88, 0)
@export var escort_spawn_offset: Vector2 = Vector2.ZERO
@export var escort_behind_gap: float = 0.0
@export var move_speed: float = 90.0
@export var attack_range: float = 40.0
@export var gravity: float = 520.0
@export var attack_interval: float = 1.35
@export var run_fps: float = 16.0
@export var idle_fps: float = 5.0
@export var attack_base_fps: float = 33.0
@export var death_fps: float = 18.0
@export var attack_impact_frames: PackedInt32Array = PackedInt32Array([12, 24, 36])
## Empty = load every frame in idle/; otherwise only these indices.
@export var idle_frame_indices: PackedInt32Array = PackedInt32Array()


func escort_gap_or_default(offset: Vector2) -> float:
	if escort_behind_gap > 0.0:
		return escort_behind_gap
	return maxf(8.0, offset.x * 0.15)


func feet_below_for_animation(animation_name: String) -> float:
	if animation_name == "Idle" and idle_feet_below_center >= 0.0:
		return idle_feet_below_center
	return feet_below_center
