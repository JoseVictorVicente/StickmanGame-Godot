class_name EnemyData
extends Resource
## Data-driven enemy archetype: spawn scope, stat multipliers, visual profile.

enum SpawnRole { MINION, ELITE, BOSS }

@export var enemy_id: String = ""
@export var name_key: String = ""
@export var visual_profile: EnemyVisualProfile
@export var hp_mult: float = 1.0
@export var damage_mult: float = 1.0
@export var gold_mult: float = 1.0
@export var xp_mult: float = 1.0
## Seconds between attacks; <= 0 uses visual_profile.attack_interval.
@export var attack_interval: float = -1.0
@export var spawn_role: SpawnRole = SpawnRole.MINION
## 0 = any world; 1..5 = specific dimension.
@export var world_id: int = 0
@export var stage_min: int = 1
@export var stage_max: int = 9
@export var wave_min: int = 1
@export var wave_max: int = 4
## Higher wins when multiple entries match the same spawn.
@export var sort_order: int = 0
## When true, display name comes from WorldCatalog.demon_king_name(world).
@export var use_demon_king_name: bool = false


func matches_spawn(world: int, stage: int, wave: int, role: SpawnRole) -> bool:
	if spawn_role != role:
		return false
	if world_id > 0 and world_id != world:
		return false
	if stage < stage_min or stage > stage_max:
		return false
	if wave < wave_min or wave > wave_max:
		return false
	return true


func specificity_score(world: int) -> int:
	var score := sort_order
	if world_id > 0:
		score += 1000
	score += (10 - (stage_max - stage_min)) * 10
	score += (4 - (wave_max - wave_min)) * 5
	if world_id == world:
		score += 100
	return score


func get_attack_interval() -> float:
	if attack_interval > 0.0:
		return attack_interval
	if visual_profile != null and visual_profile.attack_interval > 0.0:
		return visual_profile.attack_interval
	return 1.35
