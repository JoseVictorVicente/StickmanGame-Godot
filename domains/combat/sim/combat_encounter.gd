class_name CombatEncounter
extends RefCounted
## Serializable combat encounter state (simulation layer).

const _ActorGroup := preload("res://domains/combat/sim/combat_actor_group.gd")
const _Lane := preload("res://domains/combat/sim/combat_lane.gd")

enum Phase { RUNNING, ENGAGED, RESOLVING }

const WorldCatalog := preload("res://data/world_catalog.gd")

var world: int = 1
var stage: int = 1
var stage_wave: int = 1
var difficulty: int = 0
var phase: Phase = Phase.ENGAGED
var level: int = 1
var hero_front_lane_x: float = 0.0

var minion: Enemy
var minion_data: EnemyData
var elite: Enemy
var elite_data: EnemyData
var flying: Enemy
var flying_data: EnemyData
var horde: _ActorGroup

var has_horde: bool = false
var enemy_attack_cooldown: float = 0.0
var runner_timer: float = 0.0
var runner_duration: float = 1.2
var engaged: bool = true


func clear_enemies() -> void:
	minion = null
	elite = null
	flying = null
	minion_data = null
	elite_data = null
	flying_data = null
	has_horde = false
	if horde != null:
		horde.clear()


func is_elite_wave() -> bool:
	return stage_wave == 4


func has_living_enemies() -> bool:
	if has_horde and horde != null:
		return horde.has_living()
	if minion != null and not minion.is_dead():
		return true
	if elite != null and not elite.is_dead():
		return true
	if flying != null and not flying.is_dead():
		return true
	return false


func get_active_enemy() -> Enemy:
	if has_horde and horde != null:
		return horde.active_enemy()
	if minion != null and not minion.is_dead():
		return minion
	if elite != null and not elite.is_dead():
		return elite
	if flying != null and not flying.is_dead():
		return flying
	return null


func get_display_name() -> String:
	if has_horde and horde != null:
		return horde.display_name()
	var names: PackedStringArray = []
	if minion != null and not minion.is_dead():
		names.append(minion.display_name)
	if elite != null and not elite.is_dead():
		names.append(elite.display_name)
	if flying != null and not flying.is_dead():
		names.append(flying.display_name)
	return " + ".join(names)


func get_active_enemy_data() -> EnemyData:
	if has_horde:
		return horde.enemy_data if horde != null else minion_data
	if minion != null and not minion.is_dead():
		return minion_data
	if elite != null and not elite.is_dead():
		return elite_data
	if flying != null and not flying.is_dead():
		return flying_data
	return minion_data


func contact_lane_x() -> float:
	return _Lane.contact_x(hero_front_lane_x)


func spawn_wave(base_stats: Dictionary) -> void:
	clear_enemies()
	var contact_x := contact_lane_x()
	var horde_entry := EnemyCatalog.resolve_horde(world, stage, stage_wave)
	if horde_entry != null and horde_entry.horde_count > 1:
		_spawn_horde(base_stats, horde_entry, contact_x)
		return
	_spawn_solo_wave(base_stats, contact_x)


func _spawn_horde(base_stats: Dictionary, data: EnemyData, contact_x: float) -> void:
	has_horde = true
	if horde == null:
		horde = _ActorGroup.new()
	var mode := _ActorGroup.AttackMode.SWARM
	if data.horde_attack_mode == EnemyData.HordeAttackMode.QUEUE:
		mode = _ActorGroup.AttackMode.QUEUE
	horde.build(base_stats, data, data.horde_count, world, contact_x, mode)
	minion_data = data
	minion = horde.active_enemy()
	var runtime := EnemyCatalog.build_runtime(base_stats, data)
	level = int(runtime.get("level", base_stats.get("level", 1)))
	phase = Phase.ENGAGED
	engaged = true
	enemy_attack_cooldown = 0.0


func _spawn_solo_wave(base_stats: Dictionary, contact_x: float) -> void:
	has_horde = false
	var minion_role := EnemyCatalog.resolve_role_for_stage(stage, EnemyData.SpawnRole.MINION)
	minion_data = EnemyCatalog.resolve(world, stage, stage_wave, minion_role)
	var runtime := EnemyCatalog.build_runtime(base_stats, minion_data)
	level = int(runtime.get("level", base_stats.get("level", 1)))
	minion = Enemy.new()
	minion.configure(
		EnemyCatalog.display_name(minion_data, world),
		int(runtime["hp"]),
		int(runtime["gold"]),
		int(runtime["xp"]),
		int(runtime["damage"])
	)
	elite = null
	flying = null
	elite_data = null
	flying_data = null
	if is_elite_wave() and not WorldCatalog.is_boss_stage(stage):
		elite_data = EnemyCatalog.resolve(world, stage, stage_wave, EnemyData.SpawnRole.ELITE)
		if elite_data != null:
			var elite_runtime := EnemyCatalog.build_runtime(base_stats, elite_data)
			elite = Enemy.new()
			elite.configure(
				EnemyCatalog.display_name(elite_data, world),
				int(elite_runtime["hp"]),
				int(elite_runtime["gold"]),
				int(elite_runtime["xp"]),
				int(elite_runtime["damage"])
			)
		flying_data = EnemyCatalog.get_by_id("flying_demon")
		if flying_data != null:
			var flying_runtime := EnemyCatalog.build_runtime(base_stats, flying_data)
			flying = Enemy.new()
			flying.configure(
				EnemyCatalog.display_name(flying_data, world),
				int(flying_runtime["hp"]),
				int(flying_runtime["gold"]),
				int(flying_runtime["xp"]),
				int(flying_runtime["damage"])
			)
	enemy_attack_cooldown = 0.0
