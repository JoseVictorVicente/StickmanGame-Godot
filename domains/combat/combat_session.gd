class_name CombatSession
extends RefCounted
## Orchestrates tick simulation + presentation bridge for one combat loop.

const _Encounter := preload("res://domains/combat/sim/combat_encounter.gd")
const _Simulator := preload("res://domains/combat/sim/combat_simulator.gd")
const _Bridge := preload("res://presentation/combat/combat_presentation_bridge.gd")

var encounter: _Encounter
var simulator: _Simulator
var bridge: _Bridge

var use_simulation: bool = true


func _init() -> void:
	encounter = _Encounter.new()
	simulator = _Simulator.new()
	simulator.configure(encounter)


func bind_bridge(presentation: _Bridge) -> void:
	bridge = presentation
	bridge.configure(encounter)


func sync_meta(world: int, stage: int, stage_wave: int, difficulty: int, hero_front_x: float) -> void:
	encounter.world = world
	encounter.stage = stage
	encounter.stage_wave = stage_wave
	encounter.difficulty = difficulty
	encounter.hero_front_lane_x = hero_front_x


func refresh_solo_block_from_party(party: PartyService) -> void:
	if party == null or encounter.has_horde:
		return
	if not encounter.solo_runner_active or encounter.phase != _Encounter.Phase.RUNNING:
		return
	var slot := party.frontline_slot()
	if slot < 0:
		return
	encounter.refresh_solo_block_contact(party.hero_engage_x())


func spawn_wave(base_stats: Dictionary, anchor: Vector2, off_screen: bool) -> void:
	encounter.spawn_wave(base_stats, off_screen)
	if not encounter.has_horde:
		encounter.configure_solo_lanes(
			encounter.solo_lane_x,
			encounter.melee_lane_x(),
			encounter.solo_runner_active
		)
	simulator.configure(encounter)
	if bridge != null:
		bridge.configure(encounter)
		bridge.present_spawn(anchor, off_screen)


func advance_frame(delta: float, can_heroes_act: bool, can_enemies_act: bool) -> Array:
	if not use_simulation:
		return []
	var events: Array = simulator.advance(delta, can_heroes_act, can_enemies_act)
	if bridge != null:
		if encounter.has_horde:
			bridge.sync_horde_lanes()
		elif encounter.solo_runner_active and encounter.phase == _Encounter.Phase.RUNNING:
			bridge.sync_solo_lane()
		bridge.apply_events(events)
	return events


func apply_hero_hit(damage: int, is_crit: bool) -> Array:
	if not use_simulation:
		return []
	var events: Array = simulator.apply_hero_hit(damage, is_crit)
	if bridge != null:
		bridge.apply_events(events)
	return events


func promote_horde_member() -> void:
	simulator.promote_horde_member()
	if bridge != null:
		bridge.configure(encounter)


func start_runner(duration: float = 1.2) -> void:
	simulator.start_runner_phase(duration)
	if bridge != null:
		bridge.apply_events(simulator.consume_pending_events())


func is_horde_wave() -> bool:
	var horde_entry: EnemyData = EnemyCatalog.resolve_horde(encounter.world, encounter.stage, encounter.stage_wave)
	return horde_entry != null and horde_entry.horde_count > 1


func has_living_enemies() -> bool:
	return encounter.has_living_enemies()


func get_active_enemy() -> Enemy:
	return encounter.get_active_enemy()


func get_display_name() -> String:
	return encounter.get_display_name()


func is_running_phase() -> bool:
	return encounter.phase == _Encounter.Phase.RUNNING


func engage() -> void:
	simulator.engage()
	if bridge != null:
		bridge.apply_events(simulator.consume_pending_events())


func is_engaged() -> bool:
	return encounter.engaged


func level() -> int:
	return encounter.level


func enqueue_arcane_beat(
	slot: int,
	base_damage: int,
	crit_chance: float,
	crit_damage: float
) -> void:
	if not use_simulation:
		return
	simulator.enqueue_arcane_beat(slot, base_damage, crit_chance, crit_damage)
