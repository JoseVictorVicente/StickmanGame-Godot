class_name EnemyVisual
extends AnimatedSprite2D
## Inimigo demônio com FSM: MOVING, ATTACKING, DEAD.

signal attack_impact
signal attack_finished

enum State { MOVING, ATTACKING, DEAD }

var _marker_pos: Vector2 = Vector2.ZERO
var _tween: Tween
var _barra: HeroHealthBar
var _party: PartyService
var _state: State = State.MOVING
var _velocity: Vector2 = Vector2.ZERO
var _impact_frames_hit: Array[int] = []
var _combat_root: Node2D


func _ready() -> void:
	centered = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scale = EnemySpritesheet.scale_for()
	EnemySpritesheet.invalidate_cache()
	sprite_frames = EnemySpritesheet.frames()
	animation_finished.connect(_on_animation_finished)
	frame_changed.connect(_on_frame_changed)
	_combat_root = get_parent() as Node2D
	_party = _combat_root.get_node_or_null("PartyService") as PartyService if _combat_root else null
	_marker_pos = position
	_barra = HeroHealthBar.new()
	add_child(_barra)
	_barra.adjust_in_parent(EnemySpritesheet.health_bar_offset())
	_set_state(State.MOVING)
	self_modulate = Color(1, 1, 1, 0)
	_snap_to_ground(true)


func _process(delta: float) -> void:
	if _state == State.DEAD:
		return
	if self_modulate.a < 0.99:
		return
	if _party != null and _party.combat_paused and _state != State.ATTACKING:
		return
	_apply_gravity(delta)
	if _state == State.MOVING:
		_process_moving(delta)


func is_in_attack_range() -> bool:
	return _distance_to_hero() <= EnemySpritesheet.attack_range()


func begin_attack(cooldown: float = -1.0) -> bool:
	if _state == State.DEAD:
		return false
	if not is_in_attack_range():
		return false
	if _state == State.ATTACKING:
		abort_attack()
	var intervalo := cooldown if cooldown > 0.0 else EnemySpritesheet.attack_cooldown()
	_start_attack(intervalo)
	return true


func is_attacking() -> bool:
	return _state == State.ATTACKING


func abort_attack() -> void:
	if _state != State.ATTACKING:
		return
	_finish_attack()


func play_attack() -> void:
	begin_attack()


func update_hp(atual: int, maximo: int) -> void:
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


func fade_out() -> void:
	if _tween:
		_tween.kill()
	_velocity = Vector2.ZERO
	_set_state(State.DEAD)
	if _barra:
		_barra.visible = false
	_tween = create_tween()
	_tween.tween_property(self, "self_modulate:a", 0.0, 0.35)


func prepare_spawn(anchor_local: Vector2) -> void:
	_marker_pos = anchor_local - EnemySpritesheet.spawn_offset()


func show_up(anchor_local: Vector2 = Vector2.INF) -> void:
	if _tween:
		_tween.kill()
	_velocity = Vector2.ZERO
	_impact_frames_hit.clear()
	speed_scale = 1.0
	_set_state(State.MOVING)
	if anchor_local != Vector2.INF:
		prepare_spawn(anchor_local)
	position = _marker_pos + EnemySpritesheet.spawn_offset()
	self_modulate = Color(1, 1, 1, 0)
	if _barra:
		_barra.visible = true
	_tween = create_tween()
	_tween.tween_property(self, "self_modulate", Color.WHITE, 0.2)
	_tween.tween_callback(func() -> void:
		_set_state(State.MOVING)
		_snap_to_ground(true)
	)


func _process_moving(delta: float) -> void:
	var distancia := _distance_to_hero()
	if distancia <= EnemySpritesheet.attack_range():
		_velocity.x = 0.0
		flip_h = false
		_play_idle()
		return
	_velocity.x = -EnemySpritesheet.move_speed()
	position.x += _velocity.x * delta
	flip_h = false
	_play_run()


func _start_attack(cooldown: float) -> void:
	_velocity.x = 0.0
	_impact_frames_hit.clear()
	_set_state(State.ATTACKING)
	speed_scale = EnemySpritesheet.attack_speed_scale(cooldown)
	if sprite_frames == null or not sprite_frames.has_animation("Ataque"):
		_emit_attack_impact()
		_finish_attack()
		return
	play("Ataque")
	if animation != "Ataque":
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
	var alvo := _party.right_target_index()
	if alvo < 0:
		return null
	var hero_pos := _party.hero_world_position(alvo)
	if hero_pos == Vector2.ZERO:
		return null
	return _combat_root.to_local(hero_pos)


func _ground_y() -> float:
	if _party != null:
		var slot := _party.right_target_index()
		if slot >= 0:
			var classe: Variant = _party.active_party[slot]
			var class_id := "archer"
			if classe is ClassData:
				class_id = (classe as ClassData).id
			var floor_y := _party.combat_floor_y()
			var hero_center_y := floor_y + HeroSpritesheet.ground_offset(class_id).y
			return EnemySpritesheet.center_y_for_shared_feet(
				hero_center_y,
				HeroSpritesheet.feet_below_center(class_id)
			)
	var floor_y := _marker_pos.y
	if _party != null:
		floor_y = _party.combat_floor_y()
	return floor_y + EnemySpritesheet.feet_align_offset()


func _apply_gravity(delta: float) -> void:
	var chao := _ground_y()
	if position.y < chao:
		_velocity.y += EnemySpritesheet.gravity() * delta
		position.y += _velocity.y * delta
		if position.y >= chao:
			position.y = chao
			_velocity.y = 0.0
	else:
		position.y = chao
		_velocity.y = 0.0


func _snap_to_ground(instant: bool) -> void:
	var chao := _ground_y()
	if instant:
		position.y = chao
		_velocity.y = 0.0


func _play_run() -> void:
	if animation != "Corrida" and sprite_frames and sprite_frames.has_animation("Corrida"):
		play("Corrida")


func _play_idle() -> void:
	if animation != "Idle" and animation != "Ataque":
		play("Idle")


func _on_animation_finished() -> void:
	if _state == State.DEAD:
		return
	if animation == "Ataque":
		_finish_attack()


func _on_frame_changed() -> void:
	if _state != State.ATTACKING:
		return
	if animation != "Ataque":
		return
	if not EnemySpritesheet.attack_impact_frames().has(frame):
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
	attack_finished.emit()
