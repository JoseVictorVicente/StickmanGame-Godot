class_name EnemyVisual
extends AnimatedSprite2D
## Enemy FSM: MOVING, ATTACKING, DEAD. Visual tuning from EnemyVisualProfile.

signal attack_impact
signal attack_finished
signal death_finished

enum State { MOVING, ATTACKING, DEAD }

const _DefaultProfile := preload("res://data/enemy_visual_profiles/imp_red.tres")

var _marker_pos: Vector2 = Vector2.ZERO
var _tween: Tween
var _barra: HeroHealthBar
var _party: PartyService
var _state: State = State.MOVING
var _velocity: Vector2 = Vector2.ZERO
var _impact_frames_hit: Array[int] = []
var _combat_root: Node2D
var _death_drifting: bool = false
var _death_anim_done: bool = false
var _death_finished_emitted: bool = false
var _hero_was_close_at_death: bool = false
var _profile: EnemyVisualProfile = _DefaultProfile
var _escort_mode: bool = false
var _escort_leader: EnemyVisual = null
var _escort_offset: Vector2 = Vector2.ZERO
var _attack_vfx_spawned: bool = false

const DEATH_PASS_DISTANCE := 100.0
const DEATH_OFFSCREEN_X := -90.0
const DARK_ELITE_ATTACK_START_FRAME := 12


func _ready() -> void:
	centered = true
	z_index = PartyService.COMBAT_ENEMY_Z
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	configure(_DefaultProfile)
	animation_finished.connect(_on_animation_finished)
	animation_changed.connect(_on_animation_changed)
	frame_changed.connect(_on_frame_changed)
	_combat_root = get_parent() as Node2D
	_party = _combat_root.get_node_or_null("PartyService") as PartyService if _combat_root else null
	_marker_pos = position
	_barra = HeroHealthBar.new()
	add_child(_barra)
	_barra.adjust_in_parent(_health_bar_offset())
	_set_state(State.MOVING)
	self_modulate = Color(1, 1, 1, 0)
	_snap_to_ground(true)


func configure(profile: EnemyVisualProfile) -> void:
	if profile == null:
		profile = _DefaultProfile
	_profile = profile
	EnemySpritesheetBuilder.invalidate_cache(_profile)
	sprite_frames = EnemySpritesheetBuilder.frames(_profile)
	scale = _profile.scale
	if _barra:
		_barra.adjust_in_parent(_health_bar_offset())


func set_escort(leader: EnemyVisual, offset: Vector2) -> void:
	_escort_mode = leader != null
	_escort_leader = leader
	_escort_offset = offset
	if _barra:
		_barra.visible = false
	if leader != null:
		z_index = leader.z_index - 1


func detach_from_leader() -> void:
	_escort_leader = null
	_marker_pos = position


func is_targetable() -> bool:
	return visible and _state != State.DEAD and self_modulate.a > 0.9


static func pick_arrow_target(combat_root: Node) -> Node2D:
	var minion := combat_root.get_node_or_null("EnemyVisual") as EnemyVisual
	var elite := combat_root.get_node_or_null("EliteEnemyVisual") as EnemyVisual
	var flying := combat_root.get_node_or_null("FlyingDemonEnemyVisual") as EnemyVisual
	if minion != null and minion.is_targetable():
		return minion
	if elite != null and elite.is_targetable():
		return elite
	if flying != null and flying.is_targetable():
		return flying
	if minion != null and minion.visible:
		return minion
	if elite != null and elite.visible:
		return elite
	return flying


func clear_escort() -> void:
	_escort_mode = false
	_escort_leader = null
	_escort_offset = Vector2.ZERO
	_marker_pos = position
	z_index = PartyService.COMBAT_ENEMY_Z


func hide_escort() -> void:
	clear_escort()
	visible = false
	if _tween:
		_tween.kill()
	_velocity = Vector2.ZERO
	_impact_frames_hit.clear()
	_death_drifting = false
	_death_anim_done = false
	_death_finished_emitted = false
	_hero_was_close_at_death = false
	speed_scale = 1.0
	_set_state(State.MOVING)
	self_modulate = Color(1, 1, 1, 0)


func is_escort() -> bool:
	return _escort_mode


func _process(delta: float) -> void:
	if _state == State.DEAD:
		if _death_drifting:
			_process_death_drift(delta)
		return
	if _escort_mode and _escort_leader != null:
		_sync_escort_to_leader(delta)
		return
	if self_modulate.a < 0.99 and not _allows_runner_sync_while_fading():
		return
	if _party != null and _party.combat_paused and _state != State.ATTACKING:
		return
	_apply_gravity(delta)
	if _state == State.MOVING:
		if _party != null and _party.is_runner_syncing():
			_process_runner_sync(delta)
		else:
			_process_moving(delta)
	elif _state == State.ATTACKING and animation == "Ataque":
		_try_spawn_attack_vfx(frame)


func is_in_attack_range() -> bool:
	return _distance_to_hero() <= _attack_range()


func begin_attack(cooldown: float = -1.0) -> bool:
	if _state == State.DEAD or _escort_mode:
		return false
	if not is_in_attack_range():
		return false
	if _state == State.ATTACKING:
		abort_attack()
	var intervalo := cooldown if cooldown > 0.0 else _attack_cooldown()
	_start_attack(intervalo)
	return true


func mirror_attack(cooldown: float) -> void:
	if _state == State.DEAD or not _escort_mode:
		return
	if not is_in_attack_range():
		return
	if _state == State.ATTACKING:
		abort_attack()
	var intervalo := cooldown if cooldown > 0.0 else _attack_cooldown()
	_start_attack(intervalo)


func is_attacking() -> bool:
	return _state == State.ATTACKING


func abort_attack() -> void:
	if _state != State.ATTACKING:
		return
	_finish_attack()


func play_attack() -> void:
	begin_attack()


func update_hp(atual: int, maximo: int) -> void:
	if _escort_mode:
		return
	if _barra:
		_barra.update(atual, maximo)


func flash_hit() -> void:
	if _state == State.DEAD:
		return
	if _tween:
		_tween.kill()
	self_modulate = Color(1.6, 0.4, 0.35, 1.0)
	_tween = create_tween()
	_tween.tween_property(self, "self_modulate", Color.WHITE, 0.12)


func fade_out(drift_with_scroll: bool = false) -> void:
	if _state == State.DEAD:
		return
	if _tween:
		_tween.kill()
	if _state == State.ATTACKING:
		abort_attack()
	_velocity = Vector2.ZERO
	speed_scale = 1.0
	_death_finished_emitted = false
	_death_anim_done = false
	_hero_was_close_at_death = _distance_to_hero() <= DEATH_PASS_DISTANCE
	_death_drifting = drift_with_scroll
	_set_state(State.DEAD)
	if _barra:
		_barra.visible = false
	position.y = _ground_y() + _death_ground_offset()
	if sprite_frames != null and sprite_frames.has_animation("Morte"):
		play("Morte")
		return
	_death_anim_done = true
	_check_death_complete()


func prepare_spawn(anchor_local: Vector2) -> void:
	_marker_pos = anchor_local - _spawn_offset()


func show_up(anchor_local: Vector2 = Vector2.INF) -> void:
	if _tween:
		_tween.kill()
	_velocity = Vector2.ZERO
	_impact_frames_hit.clear()
	_death_drifting = false
	_death_anim_done = false
	_death_finished_emitted = false
	_hero_was_close_at_death = false
	speed_scale = 1.0
	_set_state(State.MOVING)
	_snap_to_ground(true)
	visible = true
	if anchor_local != Vector2.INF:
		prepare_spawn(anchor_local)
	if _escort_mode and _escort_leader != null:
		position = _escort_leader.position + _escort_offset
	else:
		position = _marker_pos + _spawn_offset()
		_snap_to_ground(true)
	self_modulate = Color(1, 1, 1, 0)
	if _barra:
		_barra.visible = not _escort_mode
	_tween = create_tween()
	_tween.tween_property(self, "self_modulate", Color.WHITE, 0.2)
	_tween.tween_callback(func() -> void:
		_set_state(State.MOVING)
		_snap_to_ground(true)
		if _escort_mode and _escort_leader != null:
			position = _escort_leader.position + _escort_offset
		_play_spawn_move_animation()
	)


func _sync_escort_to_leader(delta: float) -> void:
	if _escort_leader == null:
		return
	if _escort_leader._state == State.DEAD:
		detach_from_leader()
		_apply_gravity(delta)
		if _state == State.MOVING:
			_process_moving(delta)
		return
	_apply_gravity(delta)
	if _state == State.ATTACKING:
		position.y = _ground_y()
		_update_escort_z_index()
		return
	if _party != null and _party.is_runner_syncing():
		_process_runner_sync(delta)
	elif _escort_leader_engaged():
		speed_scale = 1.0
		_process_moving(delta)
	else:
		speed_scale = 1.0
		_process_escort_catch_up(delta)
	if not (_party != null and _party.is_runner_syncing()):
		position.y = _snap_y_target()
	_update_escort_z_index()


func _escort_leader_engaged() -> bool:
	if _escort_leader == null:
		return false
	return _escort_leader.is_in_attack_range() or _escort_leader._state == State.ATTACKING


func _process_escort_catch_up(delta: float) -> void:
	var leader_x := _escort_leader.position.x
	var max_lag_x := leader_x + _escort_offset.x
	var gap := _escort_behind_gap()
	var behind_leader := position.x > leader_x + gap
	if behind_leader:
		position.x = maxf(leader_x, position.x - _move_speed() * delta)
		if position.x > max_lag_x:
			position.x = max_lag_x
		_velocity.x = -_move_speed()
		_play_run()
	else:
		if position.x > max_lag_x:
			position.x = max_lag_x
		_velocity.x = 0.0
		_sync_escort_animation_to_leader()


func _update_escort_z_index() -> void:
	if _escort_leader == null:
		return
	if is_in_attack_range():
		z_index = PartyService.COMBAT_ENEMY_Z
		return
	if position.x <= _escort_leader.position.x + 2.0:
		z_index = _escort_leader.z_index + 1
	else:
		z_index = _escort_leader.z_index - 1


func _sync_escort_animation_to_leader() -> void:
	if _escort_leader == null or _escort_leader._state == State.ATTACKING:
		return
	if _party != null and _party.is_runner_syncing():
		_play_run_for_runner_sync()
		return
	if is_in_attack_range():
		_play_in_range_pose()
		return
	match _escort_leader.animation:
		"Corrida":
			_play_run()
		"Idle":
			_play_idle()


func _escort_behind_gap() -> float:
	return _profile.escort_gap_or_default(_escort_offset)


func _allows_runner_sync_while_fading() -> bool:
	return _party != null and _party.is_runner_syncing()


func _runner_sync_speed_scale() -> float:
	if _profile.profile_id == "dark_elite" or _profile.profile_id == "flying_demon":
		return 1.75
	return 1.4


func _process_runner_sync(delta: float) -> void:
	_velocity.x = -FloorScroller.SCROLL_SPEED_PX
	speed_scale = _runner_sync_speed_scale()
	if _escort_mode and _escort_leader != null:
		position = _escort_leader.position + _escort_offset
	else:
		position.x += _velocity.x * delta
		position.y = _ground_y()
	flip_h = false
	_play_run_for_runner_sync()


func _process_moving(delta: float) -> void:
	speed_scale = 1.0
	var distancia := _distance_to_hero()
	if distancia <= _attack_range():
		_velocity.x = 0.0
		flip_h = false
		_play_in_range_pose()
		return
	_velocity.x = -_move_speed()
	position.x += _velocity.x * delta
	flip_h = false
	_play_run()


func _start_attack(cooldown: float) -> void:
	_velocity.x = 0.0
	_impact_frames_hit.clear()
	_attack_vfx_spawned = false
	_set_state(State.ATTACKING)
	speed_scale = _attack_speed_scale(cooldown)
	if sprite_frames == null or not sprite_frames.has_animation("Ataque"):
		if not _escort_mode:
			_emit_attack_impact()
		_finish_attack()
		return
	play("Ataque")
	_apply_attack_start_frame()
	if animation != "Ataque":
		if not _escort_mode:
			_emit_attack_impact()
		_finish_attack()


func _set_state(novo: State) -> void:
	_state = novo


func _distance_to_hero() -> float:
	var hero_local: Variant = _hero_local_pos()
	if hero_local == null:
		return INF
	return absf(position.x - (hero_local as Vector2).x)


func _hero_local_pos() -> Variant:
	if _party == null or _combat_root == null:
		return null
	var alvo := _party.front_target_index()
	if alvo < 0:
		return null
	var hero_pos := _party.hero_world_position(alvo)
	if hero_pos == Vector2.ZERO:
		return null
	return _combat_root.to_local(hero_pos)


func _ground_y() -> float:
	if _party != null and _party.is_road_combat_ground():
		return _party.combat_road_ground_y(_active_feet_below_center())
	if _party != null:
		var slot := _party.front_target_index()
		if slot >= 0:
			var classe: Variant = _party.active_party[slot]
			var class_id := "mage"
			if classe is ClassData:
				class_id = (classe as ClassData).id
			var floor_y := _party.combat_floor_y()
			var hero_center_y := floor_y + HeroSpritesheet.ground_offset(class_id).y
			return _center_y_for_shared_feet(
				hero_center_y,
				HeroSpritesheet.feet_below_center(class_id)
			)
	var floor_y := _marker_pos.y
	if _party != null:
		floor_y = _party.combat_floor_y()
	return floor_y + _feet_align_offset()


func _apply_gravity(delta: float) -> void:
	var chao := _ground_y()
	if position.y < chao:
		_velocity.y += _gravity() * delta
		position.y += _velocity.y * delta
		if position.y >= chao:
			position.y = chao
			_velocity.y = 0.0
	else:
		position.y = chao
		_velocity.y = 0.0


func snap_to_combat_ground() -> void:
	_snap_to_ground(true)


func _snap_y_target() -> float:
	if _escort_mode and _escort_leader != null:
		return _escort_leader.position.y + _escort_offset.y
	return _ground_y()


func _snap_to_ground(instant: bool) -> void:
	var chao := _snap_y_target()
	if instant:
		position.y = chao
		_velocity.y = 0.0


func _play_spawn_move_animation() -> void:
	if _party != null and _party.is_runner_syncing():
		_play_run_for_runner_sync()
		return
	if sprite_frames != null and sprite_frames.has_animation("Idle"):
		play("Idle")
	elif sprite_frames != null and sprite_frames.has_animation("Corrida"):
		play("Corrida")


func _play_run_for_runner_sync() -> void:
	if sprite_frames == null or not sprite_frames.has_animation("Corrida"):
		return
	if animation != "Corrida" or not is_playing():
		play("Corrida")
	_snap_to_ground(true)


func _play_run() -> void:
	if animation != "Corrida" and sprite_frames and sprite_frames.has_animation("Corrida"):
		play("Corrida")
		_snap_to_ground(true)


func _uses_run_ready_pose() -> bool:
	return _profile.profile_id == "dark_elite"


func _play_in_range_pose() -> void:
	if _uses_run_ready_pose():
		_hold_corrida_pose()
		return
	_play_idle()


func _hold_corrida_pose() -> void:
	if sprite_frames == null or not sprite_frames.has_animation("Corrida"):
		_play_idle()
		return
	if animation != "Corrida":
		play("Corrida")
	var last_frame := sprite_frames.get_frame_count("Corrida") - 1
	if last_frame >= 0:
		frame = last_frame
	pause()
	_snap_to_ground(true)


func _apply_attack_start_frame() -> void:
	if not _uses_run_ready_pose() or sprite_frames == null:
		return
	var total := sprite_frames.get_frame_count("Ataque")
	if total <= DARK_ELITE_ATTACK_START_FRAME:
		return
	frame = DARK_ELITE_ATTACK_START_FRAME


func _play_idle() -> void:
	if animation != "Idle" and animation != "Ataque":
		play("Idle")
		_snap_to_ground(true)


func _on_animation_changed() -> void:
	if _state == State.DEAD:
		return
	if _party != null and _party.is_runner_syncing() and animation == "Corrida":
		return
	_snap_to_ground(true)


func _on_animation_finished() -> void:
	if animation == "Morte":
		_death_anim_done = true
		_check_death_complete()
		return
	if _state == State.DEAD:
		return
	if animation == "Ataque":
		_finish_attack()


func _on_frame_changed() -> void:
	if _state != State.ATTACKING:
		return
	if animation != "Ataque":
		return
	_try_spawn_attack_vfx(frame)
	if not _attack_impact_frames().has(frame):
		return
	if _impact_frames_hit.has(frame):
		return
	_impact_frames_hit.append(frame)
	attack_impact.emit()


func _emit_attack_impact() -> void:
	attack_impact.emit()


func _finish_attack() -> void:
	_impact_frames_hit.clear()
	speed_scale = 1.0
	if _state == State.ATTACKING:
		_set_state(State.MOVING)
	if _escort_mode and _escort_leader != null:
		if _escort_leader_engaged():
			if is_in_attack_range():
				_play_in_range_pose()
			else:
				_play_run()
		elif position.x > _escort_leader.position.x + _escort_behind_gap():
			_play_run()
		else:
			_sync_escort_animation_to_leader()
	elif is_in_attack_range():
		_play_in_range_pose()
	else:
		_play_run()
	attack_finished.emit()


func _process_death_drift(delta: float) -> void:
	position.x -= FloorScroller.SCROLL_SPEED_PX * delta
	_check_death_complete()


func _corpse_passed_hero() -> bool:
	var hero_local: Variant = _hero_local_pos()
	if hero_local == null:
		return position.x <= DEATH_OFFSCREEN_X
	return position.x <= (hero_local as Vector2).x - 24.0


func _check_death_complete() -> void:
	if _death_finished_emitted or not _death_anim_done:
		return
	if _death_drifting:
		if _hero_was_close_at_death:
			if not _corpse_passed_hero():
				return
		elif position.x > DEATH_OFFSCREEN_X:
			return
	_finish_death_sequence()


func _finish_death_sequence() -> void:
	if _death_finished_emitted:
		return
	_death_finished_emitted = true
	_death_drifting = false
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "self_modulate:a", 0.0, 0.12)
	_tween.tween_callback(func() -> void:
		death_finished.emit()
	)


func _health_bar_offset() -> Vector2:
	return _profile.health_bar_offset


func _spawn_offset() -> Vector2:
	return _profile.spawn_offset


func _attack_range() -> float:
	return _profile.attack_range


func _move_speed() -> float:
	return _profile.move_speed


func _gravity() -> float:
	return _profile.gravity


func _feet_align_offset() -> float:
	return _profile.feet_align_fallback


func _death_ground_offset() -> float:
	return _profile.death_ground_offset


func _active_feet_below_center() -> float:
	return _profile.feet_below_for_animation(animation)


func _center_y_for_shared_feet(hero_center_y: float, hero_feet_below: float) -> float:
	var feet := _active_feet_below_center()
	var fine := _ground_fine_tune()
	return hero_center_y + hero_feet_below - feet + fine


func _ground_fine_tune() -> float:
	return _profile.ground_fine_tune


func _attack_cooldown() -> float:
	return _profile.attack_interval


func _attack_speed_scale(cooldown: float) -> float:
	return EnemySpritesheetBuilder.attack_speed_scale(_profile, cooldown)


func _attack_impact_frames() -> Array[int]:
	var frames: Array[int] = []
	for frame_idx in _profile.attack_impact_frames:
		frames.append(frame_idx)
	return frames


func _try_spawn_attack_vfx(current_frame: int) -> void:
	if _attack_vfx_spawned or _profile.attack_vfx_dir == "":
		return
	var start_frame := _profile.attack_vfx_start_frame
	if start_frame < 0 or current_frame < start_frame:
		return
	_attack_vfx_spawned = true
	_spawn_attack_vfx()


func _spawn_attack_vfx() -> void:
	if _profile.attack_vfx_dir == "":
		return
	CombatBurstVfx.spawn_on(
		self,
		_profile.attack_vfx_offset,
		_profile.attack_vfx_dir,
		_profile.attack_vfx_scale,
		_profile.attack_vfx_fps
	)
