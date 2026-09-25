extends SceneTree
## Headless tests for tick-based combat simulation.

const CombatEncounterScript := preload("res://domains/combat/sim/combat_encounter.gd")
const CombatSimulatorScript := preload("res://domains/combat/sim/combat_simulator.gd")
const CombatEventScript := preload("res://domains/combat/sim/combat_event.gd")
const CombatActorGroupScript := preload("res://domains/combat/sim/combat_actor_group.gd")
const DamagePipelineScript := preload("res://domains/combat/sim/damage_pipeline.gd")
const EnemyCatalogScript := preload("res://data/enemy_catalog.gd")
const EnemyDataScript := preload("res://data/enemy_data.gd")
const WorldProgressScript := preload("res://domains/progression/world_progress.gd")
const TestLog := preload("res://tests/test_log_helper.gd")

var _failed := false


func _init() -> void:
	EnemyCatalogScript.reload_for_tests()
	_test_damage_pipeline_single_pass()
	_test_resolve_horde_entry()
	_test_horde_spawn_and_kill_chain()
	_test_swarm_requires_contact()
	_test_runner_phase_engages()
	_test_solo_runner_lane_engage()
	_test_enemy_hit_hero_via_sim()
	_test_party_defeat_only_on_wipe()
	_test_elite_pack_partial_kill_event()
	_test_engage_lane_spawn_distance()
	_test_battle_approach_allows_hero_hit()
	_test_solo_block_stops_at_frontline()
	_test_arcane_beat_tick_pulses()
	_test_arcane_beat_swarm_multiplier()
	if _failed:
		TestLog.suite_complete("CombatSimulator", false)
		quit(1)
	TestLog.suite_complete("CombatSimulator", true)
	print("[TEST PASS] CombatSimulator")
	quit(0)


func _test_damage_pipeline_single_pass() -> void:
	var enemy := Enemy.new()
	enemy.configure("Imp", 100, 1, 1, 5)
	var first := DamagePipelineScript.apply_enemy_damage(enemy, 30)
	var second := DamagePipelineScript.apply_enemy_damage(enemy, 20)
	if int(first.get("hp", 0)) != 70 or int(second.get("hp", 0)) != 50:
		_fail("damage pipeline should apply once per call")
	var stats := {"evasion": 0.0, "phys_res": 50.0}
	var hero_hit := DamagePipelineScript.apply_hero_damage(2, 100, 200, stats)
	if int(hero_hit.get("damage", 0)) != 50 or int(hero_hit.get("hp", 0)) != 150:
		_fail("hero mitigation should run once in pipeline")


func _test_resolve_horde_entry() -> void:
	var data: EnemyData = EnemyCatalogScript.resolve_horde(1, 2, 1)
	if data == null or data.enemy_id != "imp_red_horde7" or data.horde_count != 7:
		_fail("expected imp_red_horde7 horde entry on world 1 stage 2 wave 1")


func _test_horde_spawn_and_kill_chain() -> void:
	var enc := CombatEncounterScript.new()
	enc.world = 1
	enc.stage = 2
	enc.stage_wave = 1
	enc.hero_front_lane_x = -112.0
	var base := WorldProgressScript.enemy_stats(1, 2, 0)
	enc.spawn_wave(base)
	if not enc.has_horde or enc.horde == null or enc.horde.member_count() != 7:
		_fail("horde spawn should create 7 members")
	var sim := CombatSimulatorScript.new()
	sim.configure(enc)
	var events := sim.apply_hero_hit(99999, false)
	var cleared := false
	for event in events:
		if event.kind == CombatEventScript.Kind.ENEMY_WAVE_CLEARED:
			cleared = true
	if cleared:
		_fail("single massive hit should kill one member, not clear wave")
	var died_events := 0
	while enc.has_living_enemies() and died_events < 20:
		events = sim.apply_hero_hit(99999, false)
		for event in events:
			if event.kind == CombatEventScript.Kind.ENEMY_MEMBER_DIED:
				died_events += 1
				sim.promote_horde_member()
			elif event.kind == CombatEventScript.Kind.ENEMY_WAVE_CLEARED:
				return
	if enc.has_living_enemies():
		_fail("horde queue should clear after sequential kills")


func _test_swarm_requires_contact() -> void:
	var enc := CombatEncounterScript.new()
	enc.world = 1
	enc.stage = 2
	enc.stage_wave = 1
	enc.hero_front_lane_x = -112.0
	enc.spawn_wave(WorldProgressScript.enemy_stats(1, 2, 0))
	var sim := CombatSimulatorScript.new()
	sim.configure(enc)
	var before := sim.advance(1.0, true, true)
	for event in before:
		if event.kind == CombatEventScript.Kind.SWARM_ATTACK:
			_fail("swarm should not attack before all members reach contact")
	for i in enc.horde.member_count():
		enc.horde.mark_member_at_contact(i, enc.horde.contact_lane_x)
	var after := sim.advance(1.0, true, true)
	var found_swarm := false
	for event in after:
		if event.kind == CombatEventScript.Kind.SWARM_ATTACK:
			found_swarm = true
	if not found_swarm:
		_fail("swarm should attack once all members are at contact")


func _test_runner_phase_engages() -> void:
	var enc := CombatEncounterScript.new()
	enc.hero_front_lane_x = -80.0
	enc.spawn_wave(WorldProgressScript.enemy_stats(1, 1, 0), true)
	var sim := CombatSimulatorScript.new()
	sim.configure(enc)
	sim.start_runner_phase(5.0)
	if enc.phase != CombatEncounterScript.Phase.RUNNING:
		_fail("runner phase should set RUNNING")
	sim.advance(0.05, true, false)
	if enc.engaged:
		_fail("runner should not engage before solo lane reaches contact")
	var steps := 0
	while not enc.engaged and steps < 200:
		sim.advance(0.05, true, false)
		steps += 1
	if not enc.engaged or enc.phase != CombatEncounterScript.Phase.ENGAGED:
		_fail("runner should engage when solo lane reaches contact")


func _test_solo_runner_lane_engage() -> void:
	var enc := CombatEncounterScript.new()
	enc.hero_front_lane_x = 28.0
	enc.spawn_wave(WorldProgressScript.enemy_stats(1, 1, 0), true)
	if not enc.solo_runner_active:
		_fail("off-screen solo spawn should activate runner lanes")
	if enc.solo_lane_x <= enc.solo_contact_x:
		_fail("solo spawn lane should start right of contact")


func _test_enemy_hit_hero_via_sim() -> void:
	var enc := CombatEncounterScript.new()
	enc.hero_front_lane_x = -80.0
	enc.spawn_wave(WorldProgressScript.enemy_stats(1, 1, 0))
	var sim := CombatSimulatorScript.new()
	sim.configure(enc)
	sim.enemy_attack_context = func() -> Dictionary:
		return {
			"target_slot": 2,
			"raw_damage": enc.minion.damage,
			"hero_hp": 200,
			"hero_stats": {"evasion": 0.0, "phys_res": 0.0, "arcane_res": 0.0, "elemental_res": 0.0},
		}
	var found_hit := false
	for _step in 12:
		var events := sim.advance(0.25, true, true)
		for event in events:
			if event.kind == CombatEventScript.Kind.ENEMY_HIT_HERO:
				found_hit = true
				if int(event.payload.get("damage", 0)) <= 0:
					_fail("enemy hit should apply positive damage")
	if not found_hit:
		_fail("solo engaged combat should emit ENEMY_HIT_HERO from sim")


func _test_party_defeat_only_on_wipe() -> void:
	var sim := CombatSimulatorScript.new()
	var stats := {
		"evasion": 0.0,
		"phys_res": 0.0,
		"arcane_res": 0.0,
		"elemental_res": 0.0,
	}
	var partial := sim.resolve_enemy_attack(1, 500, 200, stats, 3)
	var partial_defeat := false
	for event in partial:
		if event.kind == CombatEventScript.Kind.PARTY_DEFEATED:
			partial_defeat = true
	if partial_defeat:
		_fail("PARTY_DEFEATED should not fire when other heroes remain alive")
	var wipe := sim.resolve_enemy_attack(2, 500, 120, stats, 1)
	var wipe_defeat := false
	for event in wipe:
		if event.kind == CombatEventScript.Kind.PARTY_DEFEATED:
			wipe_defeat = true
	if not wipe_defeat:
		_fail("PARTY_DEFEATED should fire when the last living hero dies")


func _test_elite_pack_partial_kill_event() -> void:
	var enc := CombatEncounterScript.new()
	enc.world = 1
	enc.stage = 1
	enc.stage_wave = 4
	enc.spawn_wave(WorldProgressScript.enemy_stats(1, 1, 0))
	if enc.elite == null or enc.flying == null:
		_fail("elite wave 4 should spawn elite and flying escorts")
	var sim := CombatSimulatorScript.new()
	sim.configure(enc)
	var lethal := enc.minion.max_hp + 100
	var events := sim.apply_hero_hit(lethal, false)
	var pack_kill := false
	var wave_cleared := false
	for event in events:
		if event.kind == CombatEventScript.Kind.ENEMY_MEMBER_DIED:
			if bool(event.payload.get("pack_kill", false)):
				pack_kill = true
		if event.kind == CombatEventScript.Kind.ENEMY_WAVE_CLEARED:
			wave_cleared = true
	if not pack_kill:
		_fail("minion death with elite alive should emit pack ENEMY_MEMBER_DIED")
	if wave_cleared:
		_fail("minion death with elite alive should not emit ENEMY_WAVE_CLEARED")
	if not enc.minion.is_dead() or enc.elite.is_dead():
		_fail("only minion should die on the killing blow")
	if not enc.has_living_enemies():
		_fail("elite pack should still have living enemies after minion dies")


func _test_engage_lane_spawn_distance() -> void:
	const Tuning := preload("res://domains/combat/sim/combat_tuning.gd")
	var hero_x := 28.0
	var spawn_x := Tuning.spawn_lane_x(hero_x, true, false)
	var contact_x := hero_x + 40.0
	if spawn_x <= contact_x:
		_fail("spawn lane should be right of melee contact for engage lane hero")


func _test_solo_block_stops_at_frontline() -> void:
	var enc := CombatEncounterScript.new()
	enc.hero_front_lane_x = 80.0
	enc.spawn_wave(WorldProgressScript.enemy_stats(1, 1, 0), true)
	enc.phase = CombatEncounterScript.Phase.RUNNING
	enc.engaged = false
	enc.battle_approach_active = true
	enc.solo_runner_active = true
	enc.refresh_solo_block_contact(80.0)
	enc.solo_lane_x = 300.0
	var sim := CombatSimulatorScript.new()
	sim.configure(enc)
	sim.advance(2.0, true, true)
	if enc.solo_lane_x < enc.solo_contact_x - 1.0:
		_fail("enemy should not pass through frontline block contact")
	if enc.engaged:
		_fail("battle approach block should not auto-engage while queueing heroes")


func _test_battle_approach_allows_hero_hit() -> void:
	var enc := CombatEncounterScript.new()
	enc.hero_front_lane_x = -80.0
	enc.spawn_wave(WorldProgressScript.enemy_stats(1, 1, 0), true)
	enc.phase = CombatEncounterScript.Phase.RUNNING
	enc.engaged = false
	enc.battle_approach_active = true
	var sim := CombatSimulatorScript.new()
	sim.configure(enc)
	var events := sim.apply_hero_hit(10, false)
	if events.is_empty():
		_fail("battle approach should allow hero hits before melee engage")


func _test_arcane_beat_tick_pulses() -> void:
	var enc := CombatEncounterScript.new()
	enc.world = 1
	enc.stage = 1
	enc.stage_wave = 1
	enc.hero_front_lane_x = -112.0
	enc.spawn_wave(WorldProgressScript.enemy_stats(1, 1, 0))
	var sim := CombatSimulatorScript.new()
	sim.configure(enc)
	sim.enqueue_arcane_beat(1, 1, 0.0, 0.0)
	var pulse_events := 0
	for _step in 8:
		var events := sim.advance(0.25, true, true)
		for event in events:
			if event.kind != CombatEventScript.Kind.HERO_HIT_ENEMY:
				continue
			if str(event.payload.get("skill_id", "")) != "arcane_beat":
				continue
			pulse_events += 1
	if pulse_events != 4:
		_fail("arcane_beat should emit exactly 4 tick-aligned pulses (got %d)" % pulse_events)


func _test_arcane_beat_swarm_multiplier() -> void:
	var enc := CombatEncounterScript.new()
	enc.world = 1
	enc.stage = 2
	enc.stage_wave = 1
	enc.hero_front_lane_x = -112.0
	enc.spawn_wave(WorldProgressScript.enemy_stats(1, 2, 0))
	var sim := CombatSimulatorScript.new()
	sim.configure(enc)
	for i in enc.horde.member_count():
		enc.horde.mark_member_at_contact(i, enc.horde.contact_lane_x)
	sim.enqueue_arcane_beat(1, 100, 0.0, 0.0)
	var first_damage := -1
	for _step in 8:
		var events := sim.advance(0.25, true, true)
		for event in events:
			if event.kind != CombatEventScript.Kind.HERO_HIT_ENEMY:
				continue
			if str(event.payload.get("skill_id", "")) != "arcane_beat":
				continue
			first_damage = int(event.payload.get("damage", 0))
			break
		if first_damage >= 0:
			break
	var expected := int(round(100.0 * 0.75 * 1.1))
	if first_damage != expected:
		_fail("swarm arcane_beat pulse should deal %d at contact (got %d)" % [expected, first_damage])


func _fail(message: String) -> void:
	_failed = true
	push_error(message)
