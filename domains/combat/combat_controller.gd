class_name CombatController
extends Node
## Idle combat rules: heroes attack, enemy counters, phase advances.

signal notice(texto: String)
signal coin_effect_requested(origem: Vector2, destino: Vector2, amount: int)
signal gold_gained(amount: int)
signal item_dropped(item: ItemData)
signal progression_changed
signal hud_refresh
signal save_needed
signal hero_level_changed(stage_index: int, level: int)
signal enemy_hp_changed(current: int, max_hp: int)
signal enemy_hit(damage: int, current: int, max_hp: int)
signal enemy_died

const WAVES_PER_STAGE := 4
const ELITE_WAVE := WAVES_PER_STAGE
const WorldCatalog := preload("res://data/world_catalog.gd")
const _CombatSession := preload("res://domains/combat/combat_session.gd")
const _PresentationBridge := preload("res://presentation/combat/combat_presentation_bridge.gd")
const _CombatEvent := preload("res://domains/combat/sim/combat_event.gd")
const _Encounter := preload("res://domains/combat/sim/combat_encounter.gd")
const _Tuning := preload("res://domains/combat/sim/combat_tuning.gd")

var world: int = 1
var stage: int = 1
var difficulty: int = WorldProgress.Difficulty.EASY
var unlocked_stages: Array[int] = [1, 1, 1]
var repeat_stage: bool = false
var wave: int = 1
var stage_wave: int = 1
var current_enemy: Enemy
var current_elite_enemy: Enemy
var current_flying_demon_enemy: Enemy
var _minion_enemy_data: EnemyData
var _elite_enemy_data: EnemyData
var _flying_demon_enemy_data: EnemyData

var party: PartyService
var enemy_visual: EnemyVisual
var elite_enemy_visual: EnemyVisual
var flying_demon_enemy_visual: EnemyVisual
var horde_visuals: EnemyHordeVisuals
var enemy_health_bar: ProgressBar
var floor_scroller: FloorScroller
var combat_background: CombatBackground
var hero_progress: HeroProgress
var get_character_index: Callable
var get_gold_destination: Callable
var get_skill_tree_bonus: Callable

var _drops := DropManager.new()
var _resolvendo_morte: bool = false
var _resolvendo_derrota: bool = false
var _enemy_timer: Timer
var _combat_ready: bool = false
var _combat_transition_id: int = 0
var _dying_enemy_visual: EnemyVisual = null
var _elite_enemy_timer: Timer
var _flying_demon_enemy_timer: Timer
var _horde_active: bool = false
var _resolvendo_horde_membro: bool = false
var _pending_defeat_after_morte: bool = false
var _session: _CombatSession
var _presentation_bridge: _PresentationBridge


func _ready() -> void:
	_enemy_timer = Timer.new()
	_enemy_timer.one_shot = true
	_enemy_timer.timeout.connect(on_enemy_attacked)
	add_child(_enemy_timer)
	_elite_enemy_timer = Timer.new()
	_elite_enemy_timer.one_shot = true
	_elite_enemy_timer.timeout.connect(_on_elite_attacked)
	add_child(_elite_enemy_timer)
	_flying_demon_enemy_timer = Timer.new()
	_flying_demon_enemy_timer.one_shot = true
	_flying_demon_enemy_timer.timeout.connect(_on_flying_demon_attacked)
	add_child(_flying_demon_enemy_timer)
	_session = _CombatSession.new()
	_presentation_bridge = _PresentationBridge.new()
	_bind_presentation_bridge()
	set_process(true)


func _bind_presentation_bridge() -> void:
	if _presentation_bridge == null:
		return
	_presentation_bridge.party = party
	_presentation_bridge.enemy_visual = enemy_visual
	_presentation_bridge.elite_enemy_visual = elite_enemy_visual
	_presentation_bridge.flying_demon_enemy_visual = flying_demon_enemy_visual
	_presentation_bridge.horde_visuals = horde_visuals
	_presentation_bridge.enemy_health_bar = enemy_health_bar
	_presentation_bridge.floor_scroller = floor_scroller
	_presentation_bridge.combat_background = combat_background
	if party != null:
		_presentation_bridge.combat_root = party.get_parent() as Node2D
		_presentation_bridge.ensure_party_regroup_wiring()
	_session.bind_bridge(_presentation_bridge)
	_session.simulator.enemy_attack_context = _enemy_attack_context


func _process(delta: float) -> void:
	if party != null and _session != null:
		_session.sync_meta(
			world,
			stage,
			stage_wave,
			difficulty,
			party.hero_engage_x()
		)
		_session.refresh_solo_block_from_party(party)
	var events: Array = _session.advance_frame(delta, can_heroes_act_for_sim(), _can_enemies_tick())
	_consume_sim_meta_events(events)
	_update_party_field_combat(delta)


func has_living_enemies() -> bool:
	if _session != null and _session.has_living_enemies():
		return true
	return _minion_alive() or _elite_alive() or _flying_demon_alive()


func get_active_enemy() -> Enemy:
	if _session != null:
		return _session.get_active_enemy()
	if _minion_alive():
		return current_enemy
	if _elite_alive():
		return current_elite_enemy
	if _flying_demon_alive():
		return current_flying_demon_enemy
	return null


func get_enemy_display_name() -> String:
	if _session != null:
		return _session.get_display_name()
	var nomes: PackedStringArray = []
	if _minion_alive():
		nomes.append(current_enemy.display_name)
	if _elite_alive():
		nomes.append(current_elite_enemy.display_name)
	if _flying_demon_alive():
		nomes.append(current_flying_demon_enemy.display_name)
	return " + ".join(nomes)


func _minion_alive() -> bool:
	return current_enemy != null and not current_enemy.is_dead()


func _elite_alive() -> bool:
	return _is_elite_wave() and current_elite_enemy != null and not current_elite_enemy.is_dead()


func _flying_demon_alive() -> bool:
	return _is_elite_wave() and current_flying_demon_enemy != null and not current_flying_demon_enemy.is_dead()


func _get_active_enemy_visual() -> EnemyVisual:
	if _horde_active and horde_visuals != null and _session != null and _session.encounter.horde != null:
		return horde_visuals.get_visual(_session.encounter.horde.active_index)
	if _minion_alive():
		return enemy_visual
	if _elite_alive():
		return elite_enemy_visual
	if _flying_demon_alive():
		return flying_demon_enemy_visual
	return enemy_visual


func is_running_phase() -> bool:
	return _session != null and _session.is_running_phase()


func start_combat() -> void:
	_combat_ready = true
	stage_wave = 1
	_apply_combat_floor()
	if party != null:
		party.can_attack_target = can_hero_attack_slot
		party.reset_runner_state()
		party.start_combat()
	_reset_stage_scroll()
	_begin_wave_one_entry()
	if _is_horde_wave(stage_wave):
		_schedule_elite_attacks_if_needed()


func _spawn_wave_enemy(off_screen: bool) -> void:
	spawn_enemy(off_screen)
	if enemy_health_bar:
		enemy_health_bar.show_up()


func _is_elite_wave() -> bool:
	return stage_wave == ELITE_WAVE


func _hide_elite_visual() -> void:
	_stop_elite_attack_timer()
	_stop_flying_demon_attack_timer()
	if elite_enemy_visual != null:
		elite_enemy_visual.hide_escort()
	if flying_demon_enemy_visual != null:
		flying_demon_enemy_visual.hide_escort()


func _flash_enemy_hit() -> void:
	var visual := _get_active_enemy_visual()
	if visual != null:
		visual.flash_hit()


func _start_running_phase() -> void:
	_bind_presentation_bridge()
	if party != null:
		party.regroup_to_formation(_on_regroup_before_runner)
	else:
		_on_regroup_before_runner()


func _on_regroup_before_runner() -> void:
	_begin_runner_wave_spawn()


func _begin_wave_one_entry() -> void:
	if party != null:
		party.snap_to_formation_start()
	if _is_horde_wave(stage_wave):
		_spawn_wave_enemy(false)
		if party != null:
			party.set_field_state(PartyService.PartyFieldState.ENGAGED)
		return
	_bind_presentation_bridge()
	_begin_runner_wave_spawn()


func _begin_runner_wave_spawn() -> void:
	if _session != null:
		_session.start_runner(_Tuning.RUNNER_DURATION)
	_spawn_wave_enemy(true)
	hud_refresh.emit()


func can_heroes_attack() -> bool:
	return can_heroes_act_for_sim()


func can_heroes_act_for_sim() -> bool:
	if _resolvendo_morte or _resolvendo_derrota:
		return false
	if _session == null:
		return true
	if _session.is_engaged():
		return true
	if not _session.is_running_phase():
		return true
	return _session.encounter.battle_approach_active


func can_hero_attack_slot(slot: int) -> bool:
	if party == null or not has_living_enemies():
		return false
	if _session == null:
		return true
	if _session.is_engaged():
		return true
	if not _session.is_running_phase():
		return true
	var visual := _get_active_enemy_visual()
	if visual == null:
		return false
	var enemy_x := _enemy_visual_combat_x(visual)
	return party.is_hero_in_engage_range(slot, enemy_x)


func _enemy_visual_combat_x(visual: Node2D) -> float:
	if visual == null:
		return 0.0
	if enemy_visual != null:
		var combat_root := enemy_visual.get_parent() as Node2D
		if combat_root != null:
			return combat_root.to_local(visual.global_position).x
	return visual.position.x


func _begin_battle_approach_phase() -> void:
	if party == null or _session == null:
		return
	party.begin_battle_approach()
	_session.encounter.battle_approach_active = true
	_set_stage_scrolling(false)
	party.set_runner_sync(false, false)


func _is_wave_transition_runner() -> bool:
	return (
		_resolvendo_morte
		and _session != null
		and _session.is_running_phase()
		and not _session.is_engaged()
	)


func _update_party_field_combat(delta: float) -> void:
	if party == null or _session == null or not has_living_enemies():
		return
	if _resolvendo_derrota or _horde_active:
		return
	if _resolvendo_morte and not _is_wave_transition_runner():
		return
	if not _session.is_running_phase() or _session.is_engaged():
		return
	var visual := _get_active_enemy_visual()
	if visual == null:
		return
	var enemy_x := _enemy_visual_combat_x(visual)
	if party.field_state() == PartyService.PartyFieldState.FORMATION_MARCH:
		if party.any_hero_in_engage_range(enemy_x):
			_begin_battle_approach_phase()
	elif party.field_state() == PartyService.PartyFieldState.BATTLE_APPROACH:
		party.advance_battle_positions(enemy_x, delta)


func on_hero_skill_used(
	slot_index: int,
	skill: SkillResource,
	hits: Array,
	heals: Array = []
) -> void:
	if _resolvendo_morte or _resolvendo_derrota or _resolvendo_horde_membro:
		return
	if not has_living_enemies():
		if is_running_phase() and not can_hero_attack_slot(slot_index):
			return
		spawn_enemy()
	var combat_root: Node = enemy_visual.get_parent() if enemy_visual else self
	_apply_skill_heals(slot_index, heals, combat_root)
	if skill != null and skill.skill_id == "arcane_beat":
		var stats := party.hero_stats(slot_index)
		_session.enqueue_arcane_beat(
			slot_index,
			int(stats.get("damage", 1)),
			float(stats.get("crit_chance", 0.0)),
			float(stats.get("crit_damage", 0.0))
		)
		CombatCueAdapter.play(skill.vfx_id, party, slot_index, _get_active_enemy_visual(), combat_root, 4)
		hud_refresh.emit()
		return
	CombatCueAdapter.play(skill.vfx_id, party, slot_index, _get_active_enemy_visual(), combat_root, hits.size())
	if hits.is_empty():
		hud_refresh.emit()
		return
	var transition_token := _combat_transition_id
	for hit in hits:
		if _resolvendo_morte or _resolvendo_derrota:
			return
		if _is_transition_stale(transition_token):
			return
		if get_active_enemy() == null:
			break
		var delay_sec := float(hit.get("delay_sec", 0.0))
		if delay_sec > 0.0:
			await get_tree().create_timer(delay_sec).timeout
		if _resolvendo_morte or _resolvendo_derrota:
			return
		if _is_transition_stale(transition_token):
			return
		var active: Enemy = get_active_enemy()
		if active == null or active.is_dead():
			break
		var damage := int(hit.get("damage", 0))
		var is_crit := bool(hit.get("is_crit", false))
		if damage <= 0:
			continue
		if await _apply_damage_to_active_enemy(damage, is_crit):
			return
	hud_refresh.emit()


func _apply_skill_heals(caster_slot: int, heals: Array, combat_root: Node) -> void:
	for heal in heals:
		var pct := float(heal.get("heal_pct_max_hp", 0.0))
		if pct <= 0.0:
			continue
		var scope := str(heal.get("target_scope", "party"))
		for target_slot in party.heal_slots_for_scope(caster_slot, scope):
			var healed := party.heal_hero_percent(target_slot, pct)
			if healed <= 0:
				continue
			var pos := party.hero_world_position(target_slot)
			if pos != Vector2.ZERO:
				DamageNumber.spawn_heal(combat_root, pos, healed)


func on_hero_attacked(slot_index: int, damage: int, is_crit: bool = false) -> void:
	if _resolvendo_morte or _resolvendo_derrota or _resolvendo_horde_membro:
		return
	if not has_living_enemies():
		if is_running_phase() and not can_hero_attack_slot(slot_index):
			return
		spawn_enemy()
	if await _apply_damage_to_active_enemy(damage, is_crit):
		return
	hud_refresh.emit()


func request_minion_attack() -> void:
	if not _combat_ready or not has_living_enemies():
		return
	if _resolvendo_morte or _resolvendo_derrota or _resolvendo_horde_membro:
		if not _horde_active:
			_schedule_enemy_attack(true)
		return
	if _horde_active:
		_request_horde_minion_attack()
		return
	if is_running_phase() and not _session.is_engaged():
		if not _enemy_can_attack_during_approach():
			_schedule_enemy_attack(true)
			return
	if party.combat_paused:
		_schedule_enemy_attack(true)
		return
	on_enemy_attacked()


func on_enemy_attacked() -> void:
	if _resolvendo_morte or _resolvendo_derrota or _resolvendo_horde_membro:
		_schedule_enemy_attack(true)
		return
	if is_running_phase() and not _session.is_engaged():
		if not _enemy_can_attack_during_approach():
			_schedule_enemy_attack(true)
			return
	if party.combat_paused:
		_schedule_enemy_attack(true)
		return
	if not has_living_enemies():
		_schedule_enemy_attack()
		return
	if party.frontline_slot() < 0:
		await _resolve_defeat()
		return
	var attacked := false
	if _horde_active:
		_request_horde_minion_attack()
		return
	elif _minion_alive() and enemy_visual != null:
		if enemy_visual.is_attacking():
			enemy_visual.abort_attack()
		if enemy_visual.begin_attack(_minion_attack_interval()):
			attacked = true
			_mirror_elite_attack_with_minion()
	elif _elite_alive() and elite_enemy_visual != null:
		elite_enemy_visual.clear_escort()
		if elite_enemy_visual.begin_attack(_elite_attack_interval()):
			attacked = true
			_mirror_flying_demon_attack_with_minion()
	elif _flying_demon_alive() and flying_demon_enemy_visual != null:
		flying_demon_enemy_visual.clear_escort()
		if flying_demon_enemy_visual.begin_attack(_flying_demon_attack_interval()):
			attacked = true
	if not attacked:
		_schedule_enemy_attack(_enemy_needs_approach_retry())
		return
	AudioManager.play_attack_sound()


func on_enemy_attack_finished() -> void:
	if _horde_active:
		return
	_schedule_enemy_attack()


func _request_horde_minion_attack() -> void:
	if not _horde_active or horde_visuals == null:
		return
	if _resolvendo_morte or _resolvendo_derrota or _resolvendo_horde_membro:
		return
	if is_running_phase() or party.combat_paused:
		return
	if not _horde_swarm_ready():
		return
	var attacked := false
	for visual in horde_visuals.all_visible():
		if visual == null or not visual.is_field_alive():
			continue
		if visual.begin_attack(_minion_attack_interval()):
			attacked = true
	if attacked:
		AudioManager.play_attack_sound()


func _horde_swarm_ready() -> bool:
	if horde_visuals == null:
		return false
	var found := false
	for visual in horde_visuals.all_visible():
		if visual == null or not visual.is_field_alive():
			continue
		found = true
		if visual.is_attacking():
			return false
		if not visual.is_at_attack_stop_line():
			return false
	return found


func on_elite_attack_finished() -> void:
	_schedule_elite_attack()


func _on_elite_attacked() -> void:
	if _resolvendo_morte or _resolvendo_derrota:
		return
	if is_running_phase() and not _session.is_engaged():
		return
	if party.combat_paused:
		_schedule_elite_attack()
		return
	if not _elite_alive() or elite_enemy_visual == null:
		_stop_elite_attack_timer()
		return
	if party.right_target_index() < 0:
		await _resolve_defeat()
		return
	if not elite_enemy_visual.is_in_attack_range():
		_schedule_elite_attack()
		return
	if elite_enemy_visual.is_attacking():
		elite_enemy_visual.abort_attack()
	var cooldown := _elite_attack_interval()
	if elite_enemy_visual.is_escort():
		elite_enemy_visual.mirror_attack(cooldown)
	elif elite_enemy_visual.begin_attack(cooldown):
		pass
	else:
		_schedule_elite_attack()
		return
	AudioManager.play_attack_sound()


func _enemy_needs_approach_retry() -> bool:
	if not has_living_enemies():
		return false
	var visual := _get_active_enemy_visual()
	if visual == null:
		return false
	if visual.has_method("is_at_attack_stop_line") and visual.is_at_attack_stop_line():
		return false
	return not visual.is_in_attack_range()


func _schedule_enemy_attack(approach_retry: bool = false) -> void:
	if _horde_active:
		return
	if not _is_elite_wave():
		return
	if _enemy_timer == null:
		return
	if not _combat_ready:
		return
	if _resolvendo_morte or _resolvendo_derrota:
		return
	if is_running_phase() and not _session.is_engaged():
		return
	var wait_time := _minion_attack_interval()
	if approach_retry or _enemy_needs_approach_retry():
		wait_time = 0.1
	_enemy_timer.wait_time = wait_time
	_enemy_timer.start()


func _schedule_elite_attack() -> void:
	if _elite_enemy_timer == null:
		return
	if not _combat_ready:
		return
	if _resolvendo_morte or _resolvendo_derrota:
		return
	if is_running_phase() and not _session.is_engaged():
		return
	if not _elite_alive():
		_stop_elite_attack_timer()
		return
	_elite_enemy_timer.wait_time = _elite_attack_interval()
	_elite_enemy_timer.start()


func _stop_elite_attack_timer() -> void:
	if _elite_enemy_timer:
		_elite_enemy_timer.stop()


func _mirror_elite_attack_with_minion() -> void:
	if not _elite_alive() or elite_enemy_visual == null:
		return
	if not elite_enemy_visual.is_escort():
		return
	if not elite_enemy_visual.is_in_attack_range():
		_schedule_elite_attack()
		return
	if elite_enemy_visual.is_attacking():
		elite_enemy_visual.abort_attack()
	var cooldown := _elite_attack_interval()
	elite_enemy_visual.mirror_attack(cooldown)
	_schedule_elite_attack()
	_mirror_flying_demon_attack_with_minion()


func _mirror_flying_demon_attack_with_minion() -> void:
	if not _flying_demon_alive() or flying_demon_enemy_visual == null:
		return
	if not flying_demon_enemy_visual.is_escort():
		return
	if not flying_demon_enemy_visual.is_in_attack_range():
		_schedule_flying_demon_attack(true)
		return
	if flying_demon_enemy_visual.is_attacking():
		flying_demon_enemy_visual.abort_attack()
	var cooldown := _flying_demon_attack_interval()
	flying_demon_enemy_visual.mirror_attack(cooldown)
	_schedule_flying_demon_attack()


func on_flying_demon_attack_finished() -> void:
	_schedule_flying_demon_attack()


func _on_flying_demon_attacked() -> void:
	if _resolvendo_morte or _resolvendo_derrota:
		return
	if is_running_phase() and not _session.is_engaged():
		return
	if party.combat_paused:
		_schedule_flying_demon_attack()
		return
	if not _flying_demon_alive() or flying_demon_enemy_visual == null:
		_stop_flying_demon_attack_timer()
		return
	if party.right_target_index() < 0:
		await _resolve_defeat()
		return
	if not flying_demon_enemy_visual.is_in_attack_range():
		_schedule_flying_demon_attack(true)
		return
	if flying_demon_enemy_visual.is_attacking():
		flying_demon_enemy_visual.abort_attack()
	var cooldown := _flying_demon_attack_interval()
	if flying_demon_enemy_visual.is_escort():
		flying_demon_enemy_visual.mirror_attack(cooldown)
	elif flying_demon_enemy_visual.begin_attack(cooldown):
		pass
	else:
		_schedule_flying_demon_attack()
		return
	AudioManager.play_attack_sound()


func _schedule_flying_demon_attack(approach_retry: bool = false) -> void:
	if _flying_demon_enemy_timer == null:
		return
	if not _combat_ready:
		return
	if _resolvendo_morte or _resolvendo_derrota:
		return
	if is_running_phase() and not _session.is_engaged():
		return
	if not _flying_demon_alive():
		_stop_flying_demon_attack_timer()
		return
	var wait_time := _flying_demon_attack_interval()
	if approach_retry or (
		flying_demon_enemy_visual != null and not flying_demon_enemy_visual.is_in_attack_range()
	):
		wait_time = 0.1
	_flying_demon_enemy_timer.wait_time = wait_time
	_flying_demon_enemy_timer.start()


func _stop_flying_demon_attack_timer() -> void:
	if _flying_demon_enemy_timer:
		_flying_demon_enemy_timer.stop()


func on_attack_impact(role: String = "minion") -> void:
	match role:
		"elite":
			await on_elite_attack_impact()
		"flying":
			await on_flying_demon_attack_impact()
		_:
			await on_enemy_attack_impact()


func on_enemy_attack_impact() -> void:
	if not _horde_active:
		return
	if current_enemy == null or current_enemy.is_dead():
		return
	await _apply_enemy_damage_to_hero(current_enemy.damage)


func on_elite_attack_impact() -> void:
	if not _elite_alive():
		return
	await _apply_enemy_damage_to_hero(current_elite_enemy.damage)


func on_flying_demon_attack_impact() -> void:
	if not _flying_demon_alive():
		return
	await _apply_enemy_damage_to_hero(current_flying_demon_enemy.damage)


func start_stage(new_world: int, new_stage: int, new_difficulty: int) -> void:
	_combat_ready = true
	var m := clampi(new_world, 1, WorldProgress.TOTAL_WORLDS)
	var f := clampi(new_stage, 1, WorldProgress.STAGES_PER_WORLD)
	var d := clampi(new_difficulty, 0, 2)
	if not WorldProgress.is_difficulty_unlocked(d, unlocked_stages):
		return
	if WorldProgress.stage_index(m, f) > unlocked_stages[d]:
		return
	_bump_combat_transition()
	world = m
	stage = f
	difficulty = d
	stage_wave = 1
	_apply_combat_floor()
	_reset_active_combat()
	party.heal_party()
	_begin_wave_one_entry()
	if _is_horde_wave(stage_wave):
		_schedule_elite_attacks_if_needed()
	progression_changed.emit()
	hud_refresh.emit()
	save_needed.emit()


func _bump_combat_transition() -> void:
	_combat_transition_id += 1


func _is_transition_stale(token: int) -> bool:
	return token != _combat_transition_id


func _reset_active_combat() -> void:
	_combat_ready = true
	_resolvendo_morte = false
	_resolvendo_derrota = false
	if _enemy_timer:
		_enemy_timer.stop()
	_stop_elite_attack_timer()
	_stop_flying_demon_attack_timer()
	if party != null:
		party.combat_paused = false
		party.can_attack_target = can_hero_attack_slot
		party.reset_runner_state()
		party.start_combat()
	_reset_stage_scroll()
	if enemy_visual != null and enemy_visual.has_method("abort_attack"):
		enemy_visual.abort_attack()
	if elite_enemy_visual != null and elite_enemy_visual.has_method("abort_attack"):
		elite_enemy_visual.abort_attack()
	if flying_demon_enemy_visual != null and flying_demon_enemy_visual.has_method("abort_attack"):
		flying_demon_enemy_visual.abort_attack()
	current_elite_enemy = null
	current_flying_demon_enemy = null
	_hide_elite_visual()


func spawn_enemy(off_screen: bool = false) -> void:
	var base_stats := WorldProgress.enemy_stats(world, stage, difficulty)
	if party != null:
		_bind_presentation_bridge()
		if off_screen:
			party.sync_floor_y_only()
		else:
			party.sync_floor_positions()
		_session.sync_meta(
			world,
			stage,
			stage_wave,
			difficulty,
			party.hero_engage_x()
		)
	var anchor := party.get_enemy_spawn_local(off_screen) if party != null else Vector2.ZERO
	_session.spawn_wave(base_stats, anchor, off_screen)
	_sync_legacy_from_session()
	wave = _session.level()
	if enemy_health_bar and current_enemy != null:
		enemy_health_bar.initialize_bar(current_enemy.max_hp)
	_emit_enemy_hp()
	if enemy_visual and current_enemy != null and enemy_visual.has_method("update_hp"):
		enemy_visual.update_hp(current_enemy.current_hp, current_enemy.max_hp)
	if party != null and not off_screen:
		party.set_field_state(PartyService.PartyFieldState.ENGAGED)


func _sync_legacy_from_session() -> void:
	var enc: _Encounter = _session.encounter
	_horde_active = enc.has_horde
	current_enemy = enc.minion
	current_elite_enemy = enc.elite
	current_flying_demon_enemy = enc.flying
	_minion_enemy_data = enc.minion_data
	_elite_enemy_data = enc.elite_data
	_flying_demon_enemy_data = enc.flying_data
	if enc.has_horde:
		_horde_active = true
	else:
		_deactivate_horde()


func _death_corpse_should_drift() -> bool:
	return party != null and party.is_runner_syncing()


func _enemy_can_attack_during_approach() -> bool:
	if _session == null or party == null:
		return false
	if not _session.encounter.battle_approach_active:
		return false
	return _session.encounter.solo_at_block_contact()


func _can_enemies_tick() -> bool:
	if _resolvendo_derrota or _resolvendo_horde_membro:
		return false
	if _resolvendo_morte:
		return _is_wave_transition_runner() and _combat_ready and has_living_enemies()
	if party != null and party.combat_paused:
		return false
	if _session != null and _session.is_running_phase() and not _session.is_engaged():
		return _enemy_can_attack_during_approach()
	return _combat_ready and has_living_enemies()


func _deactivate_horde() -> void:
	_horde_active = false
	if horde_visuals != null:
		horde_visuals.hide_all()


func _refresh_horde_hp_bar() -> void:
	if not _horde_active or _session == null:
		return
	var enc: _Encounter = _session.encounter
	if enc == null or not enc.has_horde:
		return
	var active: Enemy = enc.get_active_enemy()
	if active == null:
		return
	current_enemy = active
	if enemy_health_bar:
		enemy_health_bar.initialize_bar(active.max_hp)
	var visual := _get_active_enemy_visual()
	if visual != null and visual.has_method("update_hp"):
		visual.update_hp(active.current_hp, active.max_hp)


func _hide_legacy_enemy_visuals() -> void:
	if enemy_visual != null:
		enemy_visual.hide_escort()


func _minion_attack_interval() -> float:
	if _minion_enemy_data != null:
		return _minion_enemy_data.get_attack_interval()
	return _Tuning.ENEMY_ATTACK_INTERVAL


func _elite_attack_interval() -> float:
	if _elite_enemy_data != null:
		return _elite_enemy_data.get_attack_interval()
	return _Tuning.ENEMY_ATTACK_INTERVAL


func _flying_demon_attack_interval() -> float:
	if _flying_demon_enemy_data != null:
		return _flying_demon_enemy_data.get_attack_interval()
	return _Tuning.ENEMY_ATTACK_INTERVAL


func _flying_escort_offset() -> Vector2:
	if _flying_demon_enemy_data != null and _flying_demon_enemy_data.visual_profile != null:
		return _flying_demon_enemy_data.visual_profile.escort_spawn_offset
	return Vector2.ZERO


func toggle_repeat() -> void:
	repeat_stage = not repeat_stage
	save_needed.emit()


func apply_state(dados: Dictionary) -> void:
	wave = maxi(1, int(dados.get("wave", dados.get("onda", 1))))
	world = clampi(int(dados.get("world", dados.get("mundo", 1))), 1, WorldProgress.TOTAL_WORLDS)
	stage = clampi(int(dados.get("stage", dados.get("fase", 1))), 1, WorldProgress.STAGES_PER_WORLD)
	difficulty = clampi(int(dados.get("difficulty", dados.get("dificuldade", 0))), 0, 2)
	var liberadas: Variant = dados.get("unlocked_stages", dados.get("fases_liberadas", [1, 1, 1]))
	unlocked_stages = [1, 1, 1]
	if liberadas is Array:
		for i in mini(liberadas.size(), 3):
			unlocked_stages[i] = clampi(int(liberadas[i]), 1, WorldProgress.FULL_PROGRESS)
	while difficulty > 0 and not WorldProgress.is_difficulty_unlocked(difficulty, unlocked_stages):
		difficulty -= 1
	repeat_stage = bool(dados.get("repeat_stage", dados.get("repetir_fase", false)))
	_apply_combat_floor()


func sync_combat_floor() -> void:
	_apply_combat_floor()


func _apply_combat_floor() -> void:
	var bg_tex: Texture2D = null
	if WorldCatalog.uses_combat_background(world):
		bg_tex = WorldCatalog.combat_background_texture(world)
		if bg_tex == null:
			push_warning(
				"CombatController: missing combat background for world %d at %s"
				% [world, WorldCatalog.combat_background_texture_path(world)]
			)
	var has_bg := bg_tex != null
	if combat_background != null:
		combat_background.set_background_texture(bg_tex if has_bg else null)
		if has_bg:
			combat_background.refresh_layout()
	if floor_scroller != null:
		floor_scroller.visible = not has_bg
		if has_bg:
			floor_scroller.set_scrolling(false)
		elif not has_bg:
			var floor_tex := WorldCatalog.combat_floor_texture(world)
			if floor_tex != null:
				floor_scroller.set_floor_texture(floor_tex)
	if party != null:
		party.set_road_layout_active(WorldCatalog.uses_combat_background(world))
		party.sync_floor_positions()
	resync_enemy_anchors()


func _set_stage_scrolling(active: bool) -> void:
	if combat_background != null and combat_background.visible:
		combat_background.set_scrolling(active)
	if floor_scroller != null and floor_scroller.visible:
		floor_scroller.set_scrolling(active)


func _reset_stage_scroll() -> void:
	if combat_background != null:
		combat_background.reset_scroll()
	if floor_scroller != null:
		floor_scroller.reset_scroll()


func resync_enemy_anchors() -> void:
	if party == null:
		return
	var anchor := party.get_enemy_spawn_local(false)
	if _horde_active and horde_visuals != null and _session != null and _session.encounter.horde != null:
		var enc: _Encounter = _session.encounter
		horde_visuals.resync_anchors(anchor, enc.horde.member_count(), enc.horde.active_index)
		if _presentation_bridge != null:
			_presentation_bridge.sync_horde_lanes()
		return
	for visual in [enemy_visual, elite_enemy_visual, flying_demon_enemy_visual]:
		if visual == null or not visual.visible:
			continue
		if not visual.is_field_alive():
			continue
		if visual.is_attacking():
			visual.snap_to_combat_ground()
			continue
		if visual.is_at_attack_stop_line() or visual.is_in_attack_range():
			visual.snap_to_combat_ground()
			continue
		visual.reset_spawn_position(anchor)


func _is_horde_wave(wave_num: int) -> bool:
	var data: EnemyData = EnemyCatalog.resolve_horde(world, stage, wave_num)
	return data != null and data.horde_count > 1


func _resolve_death() -> void:
	if _resolvendo_morte or _resolvendo_derrota:
		return
	_resolvendo_morte = true
	var transition_token := _combat_transition_id
	var will_enter_run := stage_wave < WAVES_PER_STAGE
	var next_wave := stage_wave + 1
	var horde_skip_run := will_enter_run and _is_horde_wave(next_wave)
	var runner_started := false
	var reward_enemy := _enemy_for_death_rewards()
	if reward_enemy == null:
		_release_morte_resolution()
		return
	party.combat_paused = true
	AudioManager.play_death_sound()
	var gold := _drops.gold_with_variance(reward_enemy.gold_reward)
	gold = _apply_gold_bonus(gold)
	var destino := Vector2.ZERO
	if get_gold_destination.is_valid():
		destino = get_gold_destination.call()
	var dying_visual := _dying_enemy_visual if _dying_enemy_visual != null else _get_active_enemy_visual()
	if dying_visual != null:
		coin_effect_requested.emit(dying_visual.global_position, destino, 2 + gold / 2)
		dying_visual.fade_out(_death_corpse_should_drift())
	if will_enter_run and not horde_skip_run:
		stage_wave += 1
		_start_running_phase()
		runner_started = true
	elif enemy_health_bar != null:
		enemy_health_bar.fade_out()
	if runner_started:
		await get_tree().create_timer(0.4).timeout
	elif dying_visual != null and dying_visual.has_signal("death_finished"):
		await dying_visual.death_finished
	else:
		await get_tree().create_timer(0.4).timeout
	_dying_enemy_visual = null
	if _is_transition_stale(transition_token):
		_release_morte_resolution()
		return
	gold_gained.emit(gold)
	_apply_xp(_apply_xp_bonus(reward_enemy.xp_reward))
	_try_drop()
	party.apply_on_kill_passives()
	if will_enter_run:
		_release_morte_resolution()
		party.combat_paused = false
		if horde_skip_run:
			stage_wave += 1
			if _session != null:
				_session.engage()
			_spawn_wave_enemy(false)
			if party != null:
				party.set_field_state(PartyService.PartyFieldState.ENGAGED)
				party.can_attack_target = can_hero_attack_slot
			_schedule_elite_attacks_if_needed()
		elif not runner_started:
			stage_wave += 1
			_start_running_phase()
		hud_refresh.emit()
		save_needed.emit()
		return
	_advance_stage()
	stage_wave = 1
	_reset_stage_scroll()
	party.heal_party()
	_resume_party_combat_loop()
	_begin_wave_one_entry()
	_release_morte_resolution()
	if _is_horde_wave(stage_wave):
		_schedule_elite_attacks_if_needed()
	hud_refresh.emit()
	save_needed.emit()


func _resolve_defeat() -> void:
	if _resolvendo_derrota:
		return
	if _resolvendo_morte:
		_pending_defeat_after_morte = true
		return
	await _run_defeat_sequence()


func _run_defeat_sequence() -> void:
	_resolvendo_derrota = true
	_bump_combat_transition()
	var transition_token := _combat_transition_id
	if party != null:
		party.combat_paused = true
	_stop_enemy_attack_timers()
	AudioManager.play_death_sound()
	notice.emit(tr(LocaleKeys.UI_TEAM_DEFEATED))
	await get_tree().create_timer(1.15).timeout
	if _is_transition_stale(transition_token):
		_resolvendo_derrota = false
		return
	_abort_encounter_after_defeat()
	stage_wave = 1
	_reset_stage_scroll()
	if party != null:
		party.heal_party()
		party.reset_runner_state()
		party.start_combat()
		party.can_attack_target = can_hero_attack_slot
	_begin_wave_one_entry_after_defeat(transition_token)


func _begin_wave_one_entry_after_defeat(transition_token: int) -> void:
	if _is_transition_stale(transition_token):
		_resolvendo_derrota = false
		return
	_begin_wave_one_entry()
	_finish_defeat_reset(transition_token)


func _finish_defeat_reset(transition_token: int) -> void:
	if _is_transition_stale(transition_token):
		_resolvendo_derrota = false
		return
	if party != null:
		party.combat_paused = false
	_resolvendo_derrota = false
	if _is_horde_wave(stage_wave):
		_schedule_elite_attacks_if_needed()
	hud_refresh.emit()
	save_needed.emit()


func _stop_enemy_attack_timers() -> void:
	if _enemy_timer:
		_enemy_timer.stop()
	_stop_elite_attack_timer()
	_stop_flying_demon_attack_timer()


func _abort_encounter_after_defeat() -> void:
	_stop_enemy_attack_timers()
	_deactivate_horde()
	if enemy_visual != null and enemy_visual.has_method("hide_escort"):
		enemy_visual.hide_escort()
	_hide_elite_visual()
	if enemy_health_bar != null:
		enemy_health_bar.fade_out()
	if _session != null and _session.encounter != null:
		_session.encounter.clear_enemies()
	_sync_legacy_from_session()
	_dying_enemy_visual = null


func _try_run_pending_defeat() -> void:
	if not _pending_defeat_after_morte or _resolvendo_derrota:
		return
	_pending_defeat_after_morte = false
	_resolve_defeat()


func _advance_stage() -> void:
	var progresso_antes := unlocked_stages[difficulty]
	var mundo_anterior := world
	var fase_anterior := stage
	unlocked_stages[difficulty] = WorldProgress.apply_stage_completion(progresso_antes, world, stage)
	if not repeat_stage:
		var next_stage := WorldProgress.next_stage(world, stage)
		world = next_stage.x
		stage = next_stage.y
	progression_changed.emit()
	if WorldProgress.is_difficulty_completed(unlocked_stages[difficulty]) and not WorldProgress.is_difficulty_completed(progresso_antes):
		if difficulty < int(WorldProgress.Difficulty.HELL):
			notice.emit(tr(LocaleKeys.COMBAT_DIFFICULTY_UNLOCKED) % WorldProgress.difficulty_name(difficulty + 1))
		else:
			notice.emit(tr(LocaleKeys.COMBAT_HELL_COMPLETED))
	elif WorldCatalog.is_boss_stage(fase_anterior) and not repeat_stage:
		notice.emit(
			tr(LocaleKeys.COMBAT_REALM_SAVED) % [
				WorldCatalog.demon_king_name(mundo_anterior),
				WorldCatalog.dimension_name(mundo_anterior),
			]
		)
	elif not repeat_stage and world > mundo_anterior:
		notice.emit(tr(LocaleKeys.COMBAT_PORTAL_UNLOCKED) % WorldCatalog.dimension_name(world))
	elif repeat_stage:
		var seguinte := WorldProgress.next_stage(mundo_anterior, fase_anterior)
		if seguinte.x > mundo_anterior and progresso_antes < WorldProgress.stage_index(seguinte.x, 1):
			notice.emit(tr(LocaleKeys.COMBAT_PORTAL_UNLOCKED) % WorldCatalog.dimension_name(seguinte.x))


func _apply_xp(amount: int) -> void:
	if hero_progress == null:
		return
	var niveis: PackedInt32Array = hero_progress.apply_xp(amount, party.active_party)
	for stage_index in HeroProgress.SLOTS:
		if stage_index < niveis.size():
			hero_level_changed.emit(stage_index, niveis[stage_index])
	hud_refresh.emit()


func _skill_tree_bonus() -> Dictionary:
	if get_skill_tree_bonus.is_valid():
		var bonus: Variant = get_skill_tree_bonus.call()
		if bonus is Dictionary:
			return bonus
	return SkillTreeDefinition.empty_bonus()


func _apply_gold_bonus(valor: int) -> int:
	var pct := float(_skill_tree_bonus().get("gold_bonus", 0.0))
	return maxi(1, int(round(float(valor) * (1.0 + pct / 100.0))))


func _apply_xp_bonus(valor: int) -> int:
	var pct := float(_skill_tree_bonus().get("xp_bonus", 0.0))
	return maxi(1, int(round(float(valor) * (1.0 + pct / 100.0))))


func _try_drop() -> void:
	var item := _drops.try_drop_item(wave)
	if item:
		item_dropped.emit(item)


func _emit_enemy_hp() -> void:
	var active: Enemy = get_active_enemy()
	if active == null:
		return
	enemy_hp_changed.emit(active.current_hp, active.max_hp)


func _resume_party_combat_loop() -> void:
	if party == null:
		return
	party.combat_paused = false
	party.can_attack_target = can_hero_attack_slot
	party.reset_runner_state()
	party.start_combat()


func _consume_sim_meta_events(events: Array) -> void:
	if events.is_empty() or _session == null:
		return
	var member_died := false
	var wave_cleared := false
	for event in events:
		if not (event is RefCounted):
			continue
		if event.kind == _CombatEvent.Kind.HERO_HIT_ENEMY:
			if str(event.payload.get("skill_id", "")) != "":
				_feedback_sim_skill_hit(event.payload)
		elif event.kind == _CombatEvent.Kind.ENEMY_MEMBER_DIED:
			member_died = true
		elif event.kind == _CombatEvent.Kind.ENEMY_WAVE_CLEARED:
			wave_cleared = true
		elif event.kind == _CombatEvent.Kind.ENGAGED:
			if party != null:
				party.can_attack_target = can_hero_attack_slot
			_schedule_elite_attacks_if_needed()
			hud_refresh.emit()
		elif event.kind == _CombatEvent.Kind.PARTY_DEFEATED:
			call_deferred("_handle_sim_party_defeated")
	_sync_legacy_from_session()
	if member_died and not _resolvendo_horde_membro and not _resolvendo_morte:
		if _last_pack_member_died_event(events):
			_resolve_pack_member_killed()
		else:
			_resolve_horde_member_killed()
	elif wave_cleared and not _resolvendo_morte and not _resolvendo_derrota:
		_trigger_sim_wave_cleared()
	if (
		party != null
		and party.living_hero_count() <= 0
		and not _resolvendo_derrota
		and not _resolvendo_morte
	):
		call_deferred("_handle_sim_party_defeated")


func _release_morte_resolution() -> void:
	_resolvendo_morte = false
	_try_run_pending_defeat()


func _enemy_for_death_rewards() -> Enemy:
	if _session != null and _session.encounter != null:
		var enc: _Encounter = _session.encounter
		if enc.minion != null:
			return enc.minion
		if enc.elite != null:
			return enc.elite
		if enc.flying != null:
			return enc.flying
	if current_enemy != null:
		return current_enemy
	if current_elite_enemy != null:
		return current_elite_enemy
	if current_flying_demon_enemy != null:
		return current_flying_demon_enemy
	return null


func _payload_int(payload: Dictionary, key: String, fallback: int) -> int:
	var raw: Variant = payload.get(key, null)
	if raw == null:
		return fallback
	return int(raw)


func _feedback_sim_skill_hit(payload: Dictionary) -> void:
	var damage := _payload_int(payload, "damage", 0)
	var hp := _payload_int(payload, "hp", 0)
	var max_hp := _payload_int(payload, "max_hp", 1)
	var is_crit := bool(payload.get("is_crit", false))
	_emit_enemy_hp()
	enemy_hit.emit(damage, hp, max_hp)
	if enemy_health_bar:
		enemy_health_bar.update_hp(hp)
	var visual := _get_active_enemy_visual()
	if visual != null and visual.has_method("update_hp"):
		visual.update_hp(hp, max_hp)
	var cor := Color(1, 0.92, 0.4, 1) if not is_crit else Color(1, 0.78, 0.2, 1)
	if visual != null:
		DamageNumber.spawn(visual.get_parent(), visual.global_position, damage, cor, is_crit)
	_flash_enemy_hit()
	AudioManager.play_hit_sound()


func _trigger_sim_wave_cleared() -> void:
	_dying_enemy_visual = _get_active_enemy_visual()
	enemy_died.emit()
	_resolve_death()


func _last_pack_member_died_event(events: Array) -> bool:
	for i in range(events.size() - 1, -1, -1):
		var event: Variant = events[i]
		if not (event is RefCounted):
			continue
		if event.kind != _CombatEvent.Kind.ENEMY_MEMBER_DIED:
			continue
		return bool(event.payload.get("pack_kill", false))
	return false


func _resolve_pack_member_killed() -> void:
	if _session == null or _session.encounter == null:
		return
	var enc: _Encounter = _session.encounter
	# Elite must be checked before minion: imp is already dead when elite dies.
	if enc.elite != null and enc.elite.is_dead() and _flying_demon_alive():
		await _resolve_elite_killed()
		return
	if enc.minion != null and enc.minion.is_dead() and (_elite_alive() or _flying_demon_alive()):
		await _resolve_minion_killed()
		return
	_dying_enemy_visual = _get_active_enemy_visual()
	enemy_died.emit()
	await _resolve_death()


func _apply_damage_to_active_enemy(damage: int, is_crit: bool) -> bool:
	var target_before: Enemy = get_active_enemy()
	var visual := _get_active_enemy_visual()
	var events: Array = _session.apply_hero_hit(damage, is_crit)
	_sync_legacy_from_session()
	var active: Enemy = get_active_enemy()
	for event in events:
		if not (event is RefCounted):
			continue
		if event.kind != _CombatEvent.Kind.HERO_HIT_ENEMY:
			continue
		var payload: Dictionary = event.payload
		var hp := _payload_int(payload, "hp", active.current_hp if active != null else 0)
		var max_hp := _payload_int(
			payload,
			"max_hp",
			target_before.max_hp if target_before != null else 1
		)
		_emit_enemy_hp()
		enemy_hit.emit(damage, hp, max_hp)
		if enemy_health_bar:
			enemy_health_bar.update_hp(hp)
		if visual != null and visual.has_method("update_hp"):
			visual.update_hp(hp, max_hp)
		var cor := Color(1, 0.92, 0.4, 1) if not is_crit else Color(1, 0.78, 0.2, 1)
		if visual != null:
			DamageNumber.spawn(visual.get_parent(), visual.global_position, damage, cor, is_crit)
		_flash_enemy_hit()
		AudioManager.play_hit_sound()
	for event in events:
		if not (event is RefCounted):
			continue
		if event.kind == _CombatEvent.Kind.ENEMY_MEMBER_DIED:
			if bool(event.payload.get("pack_kill", false)):
				await _resolve_pack_member_killed()
			else:
				await _resolve_horde_member_killed()
			return false
		if event.kind == _CombatEvent.Kind.ENEMY_WAVE_CLEARED:
			var cleared_target := target_before if target_before != null else active
			if cleared_target == current_enemy and (_elite_alive() or _flying_demon_alive()):
				await _resolve_minion_killed()
				return false
			if cleared_target == current_elite_enemy and _flying_demon_alive():
				await _resolve_elite_killed()
				return false
			_dying_enemy_visual = visual
			enemy_died.emit()
			await _resolve_death()
			return true
	return false


func _resolve_horde_member_killed() -> void:
	if _resolvendo_horde_membro:
		return
	var enc: _Encounter = _session.encounter
	if enc == null or not enc.has_horde or enc.horde == null:
		return
	_resolvendo_horde_membro = true
	var dying_index: int = enc.horde.active_index
	var dying_visual := _get_active_enemy_visual()
	var killed: Enemy = enc.horde.active_enemy()
	if killed == null:
		_resolvendo_horde_membro = false
		return
	AudioManager.play_death_sound()
	var gold := _drops.gold_with_variance(killed.gold_reward)
	gold = _apply_gold_bonus(gold)
	var destino := Vector2.ZERO
	if get_gold_destination.is_valid():
		destino = get_gold_destination.call()
	if dying_visual != null:
		coin_effect_requested.emit(dying_visual.global_position, destino, 2 + gold / 2)
		horde_visuals.fade_member(dying_index, false)
		if dying_visual.has_signal("death_finished"):
			await dying_visual.death_finished
	gold_gained.emit(gold)
	_apply_xp(_apply_xp_bonus(killed.xp_reward))
	_try_drop()
	party.apply_on_kill_passives()
	_session.promote_horde_member()
	_sync_legacy_from_session()
	if horde_visuals != null and enc.horde != null:
		horde_visuals.refresh_active(enc.horde.active_index, enc.horde.member_count())
	_refresh_horde_hp_bar()
	_emit_enemy_hp()
	_resolvendo_horde_membro = false
	call_deferred("_request_horde_minion_attack")
	hud_refresh.emit()
	save_needed.emit()


func _resolve_minion_killed() -> void:
	if elite_enemy_visual != null:
		elite_enemy_visual.detach_from_leader()
	if flying_demon_enemy_visual != null:
		flying_demon_enemy_visual.detach_from_leader()
	enemy_visual.fade_out(false)
	enemy_health_bar.fade_out()
	if enemy_visual.has_signal("death_finished"):
		await enemy_visual.death_finished
	if elite_enemy_visual != null:
		elite_enemy_visual.clear_escort()
	if flying_demon_enemy_visual != null and _elite_alive():
		flying_demon_enemy_visual.set_escort(elite_enemy_visual, _flying_escort_offset())
	elif flying_demon_enemy_visual != null:
		flying_demon_enemy_visual.clear_escort()
	if _elite_alive() and current_elite_enemy != null:
		enemy_health_bar.initialize_bar(current_elite_enemy.max_hp)
		enemy_health_bar.show_up()
		_emit_enemy_hp()
		elite_enemy_visual.update_hp(current_elite_enemy.current_hp, current_elite_enemy.max_hp)
		_schedule_elite_attack()
	elif _flying_demon_alive() and current_flying_demon_enemy != null:
		enemy_health_bar.initialize_bar(current_flying_demon_enemy.max_hp)
		enemy_health_bar.show_up()
		_emit_enemy_hp()
		flying_demon_enemy_visual.update_hp(
			current_flying_demon_enemy.current_hp,
			current_flying_demon_enemy.max_hp
		)
		_schedule_flying_demon_attack()
	_schedule_enemy_attack()
	hud_refresh.emit()


func _resolve_elite_killed() -> void:
	_stop_elite_attack_timer()
	if flying_demon_enemy_visual != null:
		flying_demon_enemy_visual.detach_from_leader()
	if elite_enemy_visual != null:
		elite_enemy_visual.detach_from_leader()
		elite_enemy_visual.clear_escort()
		elite_enemy_visual.fade_out(false)
		enemy_health_bar.fade_out()
		if elite_enemy_visual.has_signal("death_finished"):
			await elite_enemy_visual.death_finished
	elif enemy_health_bar != null:
		enemy_health_bar.fade_out()
	if flying_demon_enemy_visual != null and current_flying_demon_enemy != null:
		flying_demon_enemy_visual.clear_escort()
		enemy_health_bar.initialize_bar(current_flying_demon_enemy.max_hp)
		enemy_health_bar.show_up()
		_emit_enemy_hp()
		flying_demon_enemy_visual.update_hp(
			current_flying_demon_enemy.current_hp,
			current_flying_demon_enemy.max_hp
		)
		_schedule_flying_demon_attack()
	_schedule_enemy_attack()
	hud_refresh.emit()


func _apply_enemy_damage_to_hero(damage_amount: int) -> void:
	if _resolvendo_morte or _resolvendo_derrota:
		return
	if is_running_phase() and not _session.is_engaged():
		if not _enemy_can_attack_during_approach():
			return
	if party.combat_paused:
		return
	var alvo := party.frontline_slot()
	if alvo < 0:
		await _resolve_defeat()
		return
	var mitigation: Dictionary = party.mitigate_incoming_damage(alvo, damage_amount)
	if bool(mitigation.get("evaded", false)):
		var posicao := party.hero_world_position(alvo)
		if posicao != Vector2.ZERO:
			var root := _get_active_enemy_visual()
			var parent := root.get_parent() if root else self
			DamageNumber.spawn_miss(parent, posicao, tr(LocaleKeys.COMBAT_MISS))
		return
	var dano_recebido := int(mitigation.get("damage", 0))
	if dano_recebido > 0:
		party.apply_damage_to_hero(alvo, dano_recebido)
		AudioManager.play_hit_sound()
	if party.frontline_slot() < 0:
		await _resolve_defeat()


func _enemy_attack_context() -> Dictionary:
	if party == null:
		return {}
	var slot := party.frontline_slot()
	if slot < 0:
		return {}
	var enemy := get_active_enemy()
	if enemy == null:
		return {}
	return {
		"target_slot": slot,
		"raw_damage": enemy.damage,
		"hero_hp": party.hero_current_hp(slot),
		"hero_stats": party.hero_stats(slot),
		"living_hero_count": party.living_hero_count(),
	}


func _schedule_elite_attacks_if_needed() -> void:
	if _elite_alive():
		_schedule_elite_attack()
	if _flying_demon_alive():
		_schedule_flying_demon_attack()


func _handle_sim_party_defeated() -> void:
	if _resolvendo_derrota or _resolvendo_morte:
		return
	if party == null or party.living_hero_count() > 0:
		return
	await _resolve_defeat()
