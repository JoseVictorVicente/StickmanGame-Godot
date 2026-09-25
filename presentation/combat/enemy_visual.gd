class_name EnemyVisual
extends AnimatedSprite2D
## Enemy FSM: MOVING, ATTACKING, DEAD. Visual tuning from EnemyVisualProfile.

signal attack_impact
signal attack_finished
signal death_finished
signal ready_to_attack

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
var _horde_targetable: bool = true
var _horde_member: bool = false
var _horde_slot_index: int = 0
var _horde_backup: bool = false
var _horde_leader: EnemyVisual = null
var _horde_offset: Vector2 = Vector2.ZERO
var _attack_range_notified: bool = false
var _at_attack_stop: bool = false
var _horde_attack_cd: float = 0.0

const DEATH_PASS_DISTANCE := 100.0
const DEATH_OFFSCREEN_X := -90.0
const DARK_ELITE_ATTACK_START_FRAME := 12
const RUNNER_DEATH_ANIM_SPEED_SCALE := 4.0
const RUNNER_DEATH_DRIFT_MULT := 3.0
const RUNNER_DEATH_FADE_SEC := 0.05
const HORDE_MELEE_CONTACT := 0.0


func _ready() -> void:
	centered = true
	z_index = PartyService.COMBAT_ENEMY_Z
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	configure(_DefaultProfile)
	animation_finished.connect(_on_animation_finished)
	animation_changed.connect(_on_animation_changed)
	frame_changed.connect(_on_frame_changed)
	_ensure_combat_refs()
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


func set_horde_member(active: bool) -> void:
	_horde_member = active
	if _barra:
		_barra.visible = false
	if not active:
		clear_horde_backup()


func set_horde_slot(slot_index: int) -> void:
	_horde_slot_index = slot_index
	z_index = PartyService.COMBAT_ENEMY_Z + slot_index


func set_horde_targetable(active: bool) -> void:
	var was_targetable := _horde_targetable
	_horde_targetable = active
	if active:
		clear_horde_backup()
		_attack_range_notified = false
		_horde_attack_cd = 0.0
		if not was_targetable:
			_at_attack_stop = false
		call_deferred("_on_horde_promoted")
	elif _horde_member and _state == State.MOVING and _at_attack_stop:
		_try_horde_auto_attack()
	elif _state == State.MOVING and _at_attack_stop:
		_play_in_range_pose()


func _on_horde_promoted() -> void:
	if not _horde_targetable:
		return
	var front_stop := _horde_stop_combat_x()
	if _self_combat_x() > front_stop + 0.5:
		_at_attack_stop = false
		return
	_set_combat_x(front_stop)
	_velocity.x = 0.0
	_at_attack_stop = true
	_try_notify_attack_range()
	_try_horde_auto_attack()
	if _state != State.ATTACKING:
		_play_in_range_pose()


func set_horde_backup(leader: EnemyVisual, offset: Vector2) -> void:
	_horde_backup = leader != null
	_horde_leader = leader
	_horde_offset = offset
	if _barra:
		_barra.visible = false


func clear_horde_backup() -> void:
	_horde_backup = false
	_horde_leader = null
	_horde_offset = Vector2.ZERO


func is_horde_backup() -> bool:
	return _horde_backup


func is_dead_state() -> bool:
	return _state == State.DEAD


func is_field_alive() -> bool:
	return visible and _state != State.DEAD


func is_targetable() -> bool:
	if _state == State.DEAD or not visible:
		return false
	if _horde_member and _horde_targetable:
		return true
	return _horde_targetable and self_modulate.a > 0.9


static func pick_arrow_target(combat_root: Node) -> Node2D:
	var horde := combat_root.get_node_or_null("HordeEnemies") as EnemyHordeVisuals
	if horde != null:
		var horde_target := horde.pick_target()
		if horde_target != null:
			return horde_target
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
	clear_horde_backup()
	_reset_attack_range_notify()
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


func _ensure_combat_refs() -> void:
	if _party != null and _combat_root != null:
		if _combat_root.get_node_or_null("PartyService") != null:
			return
	var node: Node = self
	while node != null:
		var party_node := node.get_node_or_null("PartyService")
		if party_node is PartyService:
			_combat_root = node as Node2D
			_party = party_node as PartyService
			return
		node = node.get_parent()


func _process(delta: float) -> void:
	_ensure_combat_refs()
	if _horde_attack_cd > 0.0:
		_horde_attack_cd = maxf(0.0, _horde_attack_cd - delta)
	if _state == State.DEAD:
		var accelerate_death := _should_accelerate_death()
		if accelerate_death and not _death_anim_done:
			speed_scale = RUNNER_DEATH_ANIM_SPEED_SCALE
		if _death_drifting:
			var drift_delta := delta
			if accelerate_death:
				drift_delta *= RUNNER_DEATH_DRIFT_MULT
			_process_death_drift(drift_delta)
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


func is_at_attack_stop_line() -> bool:
	return _at_attack_stop


func is_at_attack_stop() -> bool:
	if _at_attack_stop:
		return true
	var hero_x := _hero_combat_x()
	if hero_x == INF:
		return false
	return _self_combat_x() <= _horde_stop_combat_x() + 0.5


func is_in_attack_range() -> bool:
	if _horde_member:
		return _at_attack_stop
	if _at_attack_stop:
		return true
	var offset_x := _hero_combat_offset_x()
	if offset_x == INF:
		return false
	var range_px := _attack_range()
	return absf(offset_x) <= range_px + 2.0


func begin_attack(cooldown: float = -1.0) -> bool:
	if _state == State.DEAD or _escort_mode:
		return false
	if _horde_member:
		if not _at_attack_stop:
			return false
	elif not _at_attack_stop and not is_in_attack_range():
		return false
	if _state == State.ATTACKING:
		if _horde_member:
			return true
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
	if _escort_mode or _horde_member:
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
	var death_drop := _death_ground_offset()
	if absf(death_drop) > 0.001:
		position.y = _snap_y_target() + death_drop
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
	_reset_attack_range_notify()
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
		_barra.visible = not _escort_mode and not _horde_member
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
	if _state == State.ATTACKING:
		position.y = _snap_y_target()
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
	if _horde_member:
		_process_moving(delta)
		return
	_at_attack_stop = false
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
	var hero_x := _hero_combat_x()
	if hero_x == INF:
		_at_attack_stop = false
		_set_combat_x(_self_combat_x() - _move_speed() * delta)
		_velocity.x = -_move_speed()
		flip_h = false
		_play_run()
		return
	var stop_x := _horde_stop_combat_x()
	var self_x := _self_combat_x()
	if self_x <= stop_x:
		_set_combat_x(stop_x)
		_velocity.x = 0.0
		flip_h = false
		_at_attack_stop = true
		_try_notify_attack_range()
		_try_horde_auto_attack()
		if _state != State.ATTACKING:
			_play_in_range_pose()
		return
	_at_attack_stop = false
	_set_combat_x(maxf(stop_x, self_x - _move_speed() * delta))
	_velocity.x = -_move_speed()
	flip_h = false
	_play_run()


func _reset_attack_range_notify() -> void:
	_attack_range_notified = false
	_at_attack_stop = false
	_horde_attack_cd = 0.0


func _try_horde_auto_attack() -> void:
	if not _horde_member and not _horde_targetable:
		return
	if _state != State.MOVING or not _at_attack_stop:
		return
	if _horde_attack_cd > 0.0:
		return
	if _escort_mode or _state == State.DEAD:
		return
	if _party != null and _party.combat_paused:
		return
	if _horde_member:
		_try_notify_attack_range()
		return
	_start_attack(_attack_cooldown())


func _can_notify_attack_range() -> bool:
	if _state == State.DEAD or _escort_mode:
		return false
	if _horde_member and not _horde_targetable:
		return false
	return _at_attack_stop or is_in_attack_range()


func _try_notify_attack_range() -> void:
	if _attack_range_notified or not _can_notify_attack_range():
		return
	_attack_range_notified = true
	ready_to_attack.emit()


func _start_attack(cooldown: float) -> void:
	_velocity.x = 0.0
	_impact_frames_hit.clear()
	_attack_vfx_spawned = false
	_set_state(State.ATTACKING)
	speed_scale = _attack_speed_scale(cooldown)
	if sprite_frames == null or not sprite_frames.has_animation("Ataque"):
		if not _escort_mode and not (_horde_member and not _horde_targetable):
			_emit_attack_impact()
		_finish_attack()
		return
	play("Ataque")
	if not _uses_run_ready_pose():
		frame = 0
	_apply_attack_start_frame()
	frame_progress = 0.0
	if animation != "Ataque":
		if not _escort_mode and not (_horde_member and not _horde_targetable):
			_emit_attack_impact()
		_finish_attack()


func _set_state(novo: State) -> void:
	_state = novo


func _distance_to_hero() -> float:
	var offset_x := _hero_combat_offset_x()
	if offset_x == INF:
		return INF
	return absf(offset_x)


func _hero_world_x() -> float:
	_ensure_combat_refs()
	if _party == null:
		return INF
	var alvo := _party.front_target_index()
	if alvo < 0:
		return INF
	var hero_pos := _party.hero_world_position(alvo)
	if hero_pos == Vector2.ZERO:
		return INF
	return hero_pos.x


func _hero_combat_x() -> float:
	_ensure_combat_refs()
	if _party == null:
		return INF
	var slot := _party.front_target_index()
	if slot < 0:
		return INF
	return _party.hero_slot_x(slot)


func _self_combat_x() -> float:
	_ensure_combat_refs()
	if _combat_root == null:
		return position.x
	var parent_node := get_parent() as Node2D
	if parent_node == null or parent_node == _combat_root:
		return position.x
	return _combat_root.to_local(global_position).x


func _set_combat_x(combat_x: float) -> void:
	_ensure_combat_refs()
	if _combat_root == null:
		position.x = combat_x
		return
	var parent_node := get_parent() as Node2D
	if parent_node == null or parent_node == _combat_root:
		position.x = combat_x
		return
	var local_y := _combat_root.to_local(global_position).y
	var global_pt := _combat_root.to_global(Vector2(combat_x, local_y))
	var local_pos := parent_node.to_local(global_pt)
	position.x = local_pos.x


func _hero_combat_offset_x() -> float:
	var hero_x := _hero_combat_x()
	if hero_x == INF:
		return INF
	return _self_combat_x() - hero_x


func _attack_stop_combat_x() -> float:
	var hero_x := _hero_combat_x()
	if hero_x == INF:
		return _self_combat_x()
	return hero_x + _attack_range()


func _horde_stop_combat_x() -> float:
	if not _horde_member:
		return _attack_stop_combat_x()
	var hero_x := _hero_combat_x()
	if hero_x == INF:
		return _self_combat_x()
	return hero_x + HORDE_MELEE_CONTACT


func _hero_local_pos() -> Variant:
	_ensure_combat_refs()
	if _party == null or _combat_root == null:
		return null
	var alvo := _party.front_target_index()
	if alvo < 0:
		return null
	var hero_pos := _party.hero_world_position(alvo)
	if hero_pos == Vector2.ZERO:
		return null
	var space_root := get_parent() as Node2D
	if space_root == null:
		return _combat_root.to_local(hero_pos)
	return space_root.to_local(hero_pos)


func _ground_y() -> float:
	if _party != null and _party.is_road_combat_ground():
		return _party.combat_road_ground_y(_active_feet_below_center()) + _ground_fine_tune()
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
	return _profile.profile_id == "dark_elite" or _profile.profile_id == "flying_demon"


func _play_in_range_pose() -> void:
	if _horde_member:
		_play_horde_idle()
		return
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


func _play_horde_idle() -> void:
	if sprite_frames == null or not sprite_frames.has_animation("Idle"):
		return
	if animation == "Idle" and is_playing():
		return
	play("Idle")
	frame_progress = 0.0
	_snap_to_ground(true)


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
	if _horde_member and not _horde_targetable:
		return
	attack_impact.emit()


func _emit_attack_impact() -> void:
	attack_impact.emit()


func _finish_attack() -> void:
	var chain_horde_swing := _horde_member and _at_attack_stop and animation == "Ataque"
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
	if not _at_attack_stop:
		return
	if chain_horde_swing:
		_horde_attack_cd = 0.0
		_attack_range_notified = false
		call_deferred("_try_horde_auto_attack")
	elif _horde_member or _horde_targetable:
		_horde_attack_cd = _attack_cooldown()


func _process_death_drift(delta: float) -> void:
	position.x -= FloorScroller.SCROLL_SPEED_PX * delta
	_check_death_complete()


func _corpse_passed_hero() -> bool:
	var hero_local: Variant = _hero_local_pos()
	if hero_local == null:
		return position.x <= DEATH_OFFSCREEN_X
	return position.x <= (hero_local as Vector2).x - 24.0


func _should_accelerate_death() -> bool:
	return _party != null and _party.is_runner_syncing()


func _check_death_complete() -> void:
	if _death_finished_emitted or not _death_anim_done:
		return
	if _should_accelerate_death():
		_finish_death_sequence()
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
	var fade_sec := RUNNER_DEATH_FADE_SEC if _should_accelerate_death() else 0.12
	_tween = create_tween()
	_tween.tween_property(self, "self_modulate:a", 0.0, fade_sec)
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
