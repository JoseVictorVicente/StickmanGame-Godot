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

const ENEMY_ATTACK_INTERVAL := 1.35
const WAVES_PER_STAGE := 4
const ELITE_WAVE := WAVES_PER_STAGE
const HORDE_COOLDOWN_SEC := 5.0
const HORDE_COOLDOWN_RUN_ACCEL := 2.5
const WorldCatalog := preload("res://data/world_catalog.gd")

enum RunPhase { COMBAT, RUNNING }

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
var enemy_health_bar: ProgressBar
var floor_scroller: FloorScroller
var hero_progress: HeroProgress
var get_character_index: Callable
var get_gold_destination: Callable
var get_skill_tree_bonus: Callable

var _drops := DropManager.new()
var _resolvendo_morte: bool = false
var _resolvendo_derrota: bool = false
var _enemy_timer: Timer
var _combat_ready: bool = false
var _run_phase: RunPhase = RunPhase.COMBAT
var _horde_cooldown: float = 0.0
var _running_engaged: bool = false
var _combat_transition_id: int = 0
var _dying_enemy_visual: EnemyVisual = null
var _elite_enemy_timer: Timer
var _flying_demon_enemy_timer: Timer


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
	set_process(true)


func _process(delta: float) -> void:
	if _run_phase != RunPhase.RUNNING or _resolvendo_morte or _resolvendo_derrota:
		return
	if not has_living_enemies():
		return
	_update_running_engagement()
	_horde_cooldown -= delta * HORDE_COOLDOWN_RUN_ACCEL
	if _horde_cooldown <= 0.0:
		_engage_horde()


func has_living_enemies() -> bool:
	return _minion_alive() or _elite_alive() or _flying_demon_alive()


func get_active_enemy() -> Enemy:
	if _minion_alive():
		return current_enemy
	if _elite_alive():
		return current_elite_enemy
	if _flying_demon_alive():
		return current_flying_demon_enemy
	return null


func get_enemy_display_name() -> String:
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
	if _minion_alive():
		return enemy_visual
	if _elite_alive():
		return elite_enemy_visual
	if _flying_demon_alive():
		return flying_demon_enemy_visual
	return enemy_visual


func is_running_phase() -> bool:
	return _run_phase == RunPhase.RUNNING


func start_combat() -> void:
	_combat_ready = true
	stage_wave = 1
	_run_phase = RunPhase.COMBAT
	_horde_cooldown = 0.0
	_running_engaged = false
	if party != null:
		party.can_attack_target = can_heroes_attack
		party.reset_runner_state()
		party.start_combat()
	if floor_scroller:
		floor_scroller.reset_scroll()
	_spawn_wave_enemy(false)
	_schedule_enemy_attack()


func _spawn_wave_enemy(off_screen: bool) -> void:
	spawn_enemy()
	if party == null or enemy_visual == null:
		return
	var anchor := party.get_enemy_spawn_local(off_screen)
	_configure_wave_enemies(anchor)
	if enemy_health_bar:
		enemy_health_bar.show_up()


func _is_elite_wave() -> bool:
	return stage_wave == ELITE_WAVE


func _configure_wave_enemies(anchor: Vector2) -> void:
	if _minion_enemy_data != null and _minion_enemy_data.visual_profile != null:
		enemy_visual.configure(_minion_enemy_data.visual_profile)
	enemy_visual.prepare_spawn(anchor)
	enemy_visual.show_up(anchor)
	if not _is_elite_wave() or WorldCatalog.is_boss_stage(stage):
		_hide_elite_visual()
		return
	if elite_enemy_visual == null or _elite_enemy_data == null:
		return
	if _elite_enemy_data.visual_profile != null:
		elite_enemy_visual.configure(_elite_enemy_data.visual_profile)
	var escort_offset := Vector2.ZERO
	if _elite_enemy_data.visual_profile != null:
		escort_offset = _elite_enemy_data.visual_profile.escort_spawn_offset
	elite_enemy_visual.set_escort(enemy_visual, escort_offset)
	elite_enemy_visual.show_up(anchor)
	if flying_demon_enemy_visual == null or _flying_demon_enemy_data == null:
		_schedule_elite_attack()
		return
	if _flying_demon_enemy_data.visual_profile != null:
		flying_demon_enemy_visual.configure(_flying_demon_enemy_data.visual_profile)
	var flying_offset := Vector2.ZERO
	if _flying_demon_enemy_data.visual_profile != null:
		flying_offset = _flying_demon_enemy_data.visual_profile.escort_spawn_offset
	flying_demon_enemy_visual.set_escort(enemy_visual, flying_offset)
	flying_demon_enemy_visual.show_up(anchor)
	_schedule_elite_attack()
	_schedule_flying_demon_attack()


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
	_begin_running_phase_visuals()
	_spawn_wave_enemy(true)
	if party != null:
		party.combat_paused = false
	hud_refresh.emit()


func _begin_running_phase_visuals() -> void:
	_run_phase = RunPhase.RUNNING
	_horde_cooldown = HORDE_COOLDOWN_SEC
	_running_engaged = false
	if party != null:
		party.begin_running()
	if floor_scroller:
		floor_scroller.set_scrolling(true)


func _engage_horde() -> void:
	if _run_phase != RunPhase.RUNNING:
		return
	_run_phase = RunPhase.COMBAT
	_horde_cooldown = 0.0
	_running_engaged = false
	if party != null:
		party.end_running()
	if floor_scroller:
		floor_scroller.set_scrolling(false)
	_schedule_enemy_attack()
	if _elite_alive():
		_schedule_elite_attack()
	if _flying_demon_alive():
		_schedule_flying_demon_attack()
	hud_refresh.emit()


func can_heroes_attack() -> bool:
	if _run_phase != RunPhase.RUNNING:
		return true
	return is_enemy_in_hero_engage_range()


func is_enemy_in_hero_engage_range() -> bool:
	var visual := _get_active_enemy_visual()
	if visual == null or party == null:
		return false
	if not has_living_enemies():
		return false
	var slot := party.right_target_index()
	if slot < 0:
		return false
	var hero_pos := party.hero_world_position(slot)
	if hero_pos == Vector2.ZERO:
		return false
	var classe: Variant = party.active_party[slot]
	var range_px := HeroSpritesheet.engage_range("archer")
	if classe is ClassData:
		range_px = HeroSpritesheet.engage_range((classe as ClassData).id)
	return absf(visual.global_position.x - hero_pos.x) <= range_px


func _update_running_engagement() -> void:
	var engaged := is_enemy_in_hero_engage_range()
	if engaged == _running_engaged:
		return
	_running_engaged = engaged
	if engaged:
		if floor_scroller:
			floor_scroller.set_scrolling(false)
		if party:
			party.pause_running_animation()
	else:
		if floor_scroller:
			floor_scroller.set_scrolling(true)
		if party:
			party.resume_running_animation()


func on_hero_skill_used(
	slot_index: int,
	skill: SkillResource,
	hits: Array,
	heals: Array = []
) -> void:
	if _resolvendo_morte or _resolvendo_derrota:
		return
	if not has_living_enemies():
		if _run_phase == RunPhase.RUNNING:
			return
		spawn_enemy()
	var combat_root: Node = enemy_visual.get_parent() if enemy_visual else self
	_apply_skill_heals(slot_index, heals, combat_root)
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
		var active := get_active_enemy()
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


func on_hero_attacked(_slot_index: int, damage: int, is_crit: bool = false) -> void:
	if _resolvendo_morte or _resolvendo_derrota:
		return
	if not has_living_enemies():
		if _run_phase == RunPhase.RUNNING:
			return
		spawn_enemy()
	if await _apply_damage_to_active_enemy(damage, is_crit):
		return
	hud_refresh.emit()


func on_enemy_attacked() -> void:
	if _resolvendo_morte or _resolvendo_derrota:
		return
	if _run_phase == RunPhase.RUNNING:
		return
	if party.combat_paused:
		_schedule_enemy_attack()
		return
	if not has_living_enemies():
		_schedule_enemy_attack()
		return
	if party.right_target_index() < 0:
		await _resolve_defeat()
		return
	var attacked := false
	if _minion_alive() and enemy_visual != null:
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
		_schedule_enemy_attack()
		return
	AudioManager.play_attack_sound()


func on_enemy_attack_finished() -> void:
	_schedule_enemy_attack()


func on_elite_attack_finished() -> void:
	_schedule_elite_attack()


func _on_elite_attacked() -> void:
	if _resolvendo_morte or _resolvendo_derrota:
		return
	if _run_phase == RunPhase.RUNNING:
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


func _schedule_enemy_attack() -> void:
	if _enemy_timer == null:
		return
	if not _combat_ready:
		return
	if _resolvendo_morte or _resolvendo_derrota:
		return
	if _run_phase == RunPhase.RUNNING:
		return
	_enemy_timer.wait_time = _minion_attack_interval()
	_enemy_timer.start()


func _schedule_elite_attack() -> void:
	if _elite_enemy_timer == null:
		return
	if not _combat_ready:
		return
	if _resolvendo_morte or _resolvendo_derrota:
		return
	if _run_phase == RunPhase.RUNNING:
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
		_schedule_flying_demon_attack()
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
	if _run_phase == RunPhase.RUNNING:
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
		_schedule_flying_demon_attack()
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


func _schedule_flying_demon_attack() -> void:
	if _flying_demon_enemy_timer == null:
		return
	if not _combat_ready:
		return
	if _resolvendo_morte or _resolvendo_derrota:
		return
	if _run_phase == RunPhase.RUNNING:
		return
	if not _flying_demon_alive():
		_stop_flying_demon_attack_timer()
		return
	_flying_demon_enemy_timer.wait_time = _flying_demon_attack_interval()
	_flying_demon_enemy_timer.start()


func _stop_flying_demon_attack_timer() -> void:
	if _flying_demon_enemy_timer:
		_flying_demon_enemy_timer.stop()


func on_enemy_attack_impact() -> void:
	if not _minion_alive():
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
	_reset_active_combat()
	party.heal_party()
	_spawn_wave_enemy(false)
	_schedule_enemy_attack()
	progression_changed.emit()
	hud_refresh.emit()
	save_needed.emit()


func _bump_combat_transition() -> void:
	_combat_transition_id += 1


func _is_transition_stale(token: int) -> bool:
	return token != _combat_transition_id


func _reset_active_combat() -> void:
	_resolvendo_morte = false
	_resolvendo_derrota = false
	_run_phase = RunPhase.COMBAT
	_horde_cooldown = 0.0
	_running_engaged = false
	if _enemy_timer:
		_enemy_timer.stop()
	_stop_elite_attack_timer()
	_stop_flying_demon_attack_timer()
	if party != null:
		party.combat_paused = false
		party.can_attack_target = can_heroes_attack
		party.reset_runner_state()
		party.start_combat()
	if floor_scroller:
		floor_scroller.reset_scroll()
	if enemy_visual != null and enemy_visual.has_method("abort_attack"):
		enemy_visual.abort_attack()
	if elite_enemy_visual != null and elite_enemy_visual.has_method("abort_attack"):
		elite_enemy_visual.abort_attack()
	if flying_demon_enemy_visual != null and flying_demon_enemy_visual.has_method("abort_attack"):
		flying_demon_enemy_visual.abort_attack()
	current_elite_enemy = null
	current_flying_demon_enemy = null
	_hide_elite_visual()


func spawn_enemy() -> void:
	var base_stats := WorldProgress.enemy_stats(world, stage, difficulty)
	var minion_role := EnemyCatalog.resolve_role_for_stage(stage, EnemyData.SpawnRole.MINION)
	_minion_enemy_data = EnemyCatalog.resolve(world, stage, stage_wave, minion_role)
	var runtime := EnemyCatalog.build_runtime(base_stats, _minion_enemy_data)
	wave = int(runtime.get("level", base_stats.get("level", 1)))
	current_enemy = Enemy.new()
	current_enemy.configure(
		EnemyCatalog.display_name(_minion_enemy_data, world),
		int(runtime["hp"]),
		int(runtime["gold"]),
		int(runtime["xp"]),
		int(runtime["damage"])
	)
	current_elite_enemy = null
	current_flying_demon_enemy = null
	_elite_enemy_data = null
	_flying_demon_enemy_data = null
	if _is_elite_wave() and not WorldCatalog.is_boss_stage(stage):
		_elite_enemy_data = EnemyCatalog.resolve(world, stage, stage_wave, EnemyData.SpawnRole.ELITE)
		if _elite_enemy_data != null:
			var elite_runtime := EnemyCatalog.build_runtime(base_stats, _elite_enemy_data)
			current_elite_enemy = Enemy.new()
			current_elite_enemy.configure(
				EnemyCatalog.display_name(_elite_enemy_data, world),
				int(elite_runtime["hp"]),
				int(elite_runtime["gold"]),
				int(elite_runtime["xp"]),
				int(elite_runtime["damage"])
			)
		_flying_demon_enemy_data = EnemyCatalog.get_by_id("flying_demon")
		if _flying_demon_enemy_data != null:
			var flying_runtime := EnemyCatalog.build_runtime(base_stats, _flying_demon_enemy_data)
			current_flying_demon_enemy = Enemy.new()
			current_flying_demon_enemy.configure(
				EnemyCatalog.display_name(_flying_demon_enemy_data, world),
				int(flying_runtime["hp"]),
				int(flying_runtime["gold"]),
				int(flying_runtime["xp"]),
				int(flying_runtime["damage"])
			)
	enemy_health_bar.initialize_bar(current_enemy.max_hp)
	_emit_enemy_hp()
	if enemy_visual and enemy_visual.has_method("update_hp"):
		enemy_visual.update_hp(current_enemy.current_hp, current_enemy.max_hp)


func _minion_attack_interval() -> float:
	if _minion_enemy_data != null:
		return _minion_enemy_data.get_attack_interval()
	return ENEMY_ATTACK_INTERVAL


func _elite_attack_interval() -> float:
	if _elite_enemy_data != null:
		return _elite_enemy_data.get_attack_interval()
	return ENEMY_ATTACK_INTERVAL


func _flying_demon_attack_interval() -> float:
	if _flying_demon_enemy_data != null:
		return _flying_demon_enemy_data.get_attack_interval()
	return ENEMY_ATTACK_INTERVAL


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


func _resolve_death() -> void:
	if _resolvendo_morte or _resolvendo_derrota:
		return
	_resolvendo_morte = true
	var transition_token := _combat_transition_id
	var will_enter_run := stage_wave < WAVES_PER_STAGE
	party.combat_paused = true
	AudioManager.play_death_sound()
	var gold := _drops.gold_with_variance(current_enemy.gold_reward)
	gold = _apply_gold_bonus(gold)
	var destino := Vector2.ZERO
	if get_gold_destination.is_valid():
		destino = get_gold_destination.call()
	var dying_visual := _dying_enemy_visual if _dying_enemy_visual != null else _get_active_enemy_visual()
	if dying_visual != null:
		coin_effect_requested.emit(dying_visual.global_position, destino, 2 + gold / 2)
		dying_visual.fade_out(will_enter_run)
	enemy_health_bar.fade_out()
	if will_enter_run:
		_begin_running_phase_visuals()
	if dying_visual != null and dying_visual.has_signal("death_finished"):
		await dying_visual.death_finished
	else:
		await get_tree().create_timer(0.4).timeout
	_dying_enemy_visual = null
	if _is_transition_stale(transition_token):
		_resolvendo_morte = false
		return
	gold_gained.emit(gold)
	_apply_xp(_apply_xp_bonus(current_enemy.xp_reward))
	_try_drop()
	party.apply_on_kill_passives()
	if will_enter_run:
		stage_wave += 1
		_resolvendo_morte = false
		_spawn_wave_enemy(true)
		party.combat_paused = false
		hud_refresh.emit()
		save_needed.emit()
		return
	_advance_stage()
	stage_wave = 1
	_run_phase = RunPhase.COMBAT
	_horde_cooldown = 0.0
	_running_engaged = false
	if floor_scroller:
		floor_scroller.reset_scroll()
	party.heal_party()
	_resume_party_combat_loop()
	_spawn_wave_enemy(false)
	_resolvendo_morte = false
	_schedule_enemy_attack()
	hud_refresh.emit()
	save_needed.emit()


func _resolve_defeat() -> void:
	if _resolvendo_derrota or _resolvendo_morte:
		return
	_resolvendo_derrota = true
	var transition_token := _combat_transition_id
	party.combat_paused = true
	AudioManager.play_death_sound()
	notice.emit(tr(LocaleKeys.UI_TEAM_DEFEATED))
	await get_tree().create_timer(1.15).timeout
	if _is_transition_stale(transition_token):
		_resolvendo_derrota = false
		return
	party.heal_party()
	stage_wave = 1
	_run_phase = RunPhase.COMBAT
	_horde_cooldown = 0.0
	_running_engaged = false
	if floor_scroller:
		floor_scroller.reset_scroll()
	_resume_party_combat_loop()
	_spawn_wave_enemy(false)
	_resolvendo_derrota = false
	_schedule_enemy_attack()
	hud_refresh.emit()


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
	var active := get_active_enemy()
	if active == null:
		return
	enemy_hp_changed.emit(active.current_hp, active.max_hp)


func _resume_party_combat_loop() -> void:
	if party == null:
		return
	party.combat_paused = false
	party.can_attack_target = can_heroes_attack
	party.reset_runner_state()
	party.start_combat()


func _apply_damage_to_active_enemy(damage: int, is_crit: bool) -> bool:
	var active := get_active_enemy()
	var visual := _get_active_enemy_visual()
	if active == null or visual == null:
		return false
	var morreu := active.take_damage(damage)
	_emit_enemy_hp()
	enemy_hit.emit(damage, active.current_hp, active.max_hp)
	enemy_health_bar.update_hp(active.current_hp)
	if visual.has_method("update_hp"):
		visual.update_hp(active.current_hp, active.max_hp)
	var cor := Color(1, 0.92, 0.4, 1) if not is_crit else Color(1, 0.78, 0.2, 1)
	DamageNumber.spawn(visual.get_parent(), visual.global_position, damage, cor, is_crit)
	_flash_enemy_hit()
	AudioManager.play_hit_sound()
	if not morreu:
		return false
	if active == current_enemy and (_elite_alive() or _flying_demon_alive()):
		await _resolve_minion_killed()
		return false
	if active == current_elite_enemy and _flying_demon_alive():
		await _resolve_elite_killed()
		return false
	_dying_enemy_visual = visual
	enemy_died.emit()
	await _resolve_death()
	return true


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
		var elite_offset := Vector2.ZERO
		if _elite_enemy_data != null and _elite_enemy_data.visual_profile != null:
			elite_offset = _elite_enemy_data.visual_profile.escort_spawn_offset
		flying_demon_enemy_visual.set_escort(elite_enemy_visual, elite_offset)
	elif flying_demon_enemy_visual != null:
		flying_demon_enemy_visual.clear_escort()
	if _elite_alive():
		enemy_health_bar.initialize_bar(current_elite_enemy.max_hp)
		enemy_health_bar.show_up()
		_emit_enemy_hp()
		elite_enemy_visual.update_hp(current_elite_enemy.current_hp, current_elite_enemy.max_hp)
		_schedule_elite_attack()
	elif _flying_demon_alive():
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
	if flying_demon_enemy_visual != null:
		flying_demon_enemy_visual.detach_from_leader()
	elite_enemy_visual.fade_out(false)
	enemy_health_bar.fade_out()
	if elite_enemy_visual.has_signal("death_finished"):
		await elite_enemy_visual.death_finished
	if flying_demon_enemy_visual != null:
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
	if _run_phase == RunPhase.RUNNING:
		return
	if party.combat_paused:
		return
	var alvo := party.right_target_index()
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
	if party.right_target_index() < 0:
		await _resolve_defeat()
