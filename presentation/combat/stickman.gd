extends AnimatedSprite2D
## Stickman de combat_root: Idle enquanto espera, Ataque sincronizado ao cooldown.

signal attack_impact
signal attack_finished

enum State { IDLE, ATTACKING, RUNNING }

const ATTACK_LUNGE := 28.0
const LUNGE_DURATION := 0.09
const DURACAO_RETORNO := 0.12

const DEFAULT_ARROW_RELEASE_FRAME := 4
const STICK_IMPACT_FRAME := 1

var _marker_pos: Vector2 = Vector2.ZERO
var _pos_base: Vector2 = Vector2.ZERO
var _tween_ataque: Tween
var _tween_flash: Tween
var _cor_classe: Color = Color.WHITE
var _caido: bool = false
var _barra: HeroHealthBar
var _usar_arte: bool = false
var _id_classe: String = ""
var _attack_speed: float = 1.0
var _flecha_solta: bool = false
var _impact_emitted: bool = false
var _state: State = State.IDLE
var _resume_running_after_attack: bool = false
var _arrow_in_flight: bool = false
var _battle_advancing: bool = false
var _regroup_run_scale: float = 1.0
var _frames_stick: SpriteFrames


func _ready() -> void:
	centered = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite_frames = _default_frames()
	animation_finished.connect(_on_animation_finished)
	frame_changed.connect(_on_frame_changed)
	play("Idle")
	_marker_pos = position
	_pos_base = position
	_barra = HeroHealthBar.new()
	add_child(_barra)


func set_base_position(pos: Vector2) -> void:
	if _caido:
		return
	_marker_pos = pos
	_reanchor_position()
	if _tween_ataque:
		_tween_ataque.kill()


func play_attack() -> void:
	begin_attack(HeroSpritesheet.attack_cooldown(_attack_speed), _attack_speed)


func begin_running() -> void:
	if _caido:
		return
	if _state == State.ATTACKING:
		abort_attack()
	_state = State.RUNNING
	_play_running_anim()
	_apply_regroup_run_scale()


func set_regroup_run_scale(scale: float) -> void:
	_regroup_run_scale = clampf(scale, 0.05, 4.0)
	_apply_regroup_run_scale()


func end_running() -> void:
	if _caido or _state != State.RUNNING:
		return
	_state = State.IDLE
	_resume_running_after_attack = false
	_regroup_run_scale = 1.0
	speed_scale = 1.0
	play("Idle")


func uses_deferred_arrow_impact() -> bool:
	return _usar_arte and _id_classe == HeroSpritesheet.ID_ARQUEIRO


func has_arrow_in_flight() -> bool:
	return _arrow_in_flight


func clear_arrow_state() -> void:
	_arrow_in_flight = false


func set_battle_advancing(active: bool) -> void:
	_battle_advancing = active
	if _caido or _state == State.ATTACKING:
		return
	if active:
		_state = State.RUNNING
		_play_running_anim()
	elif _state == State.RUNNING:
		var party := get_parent() as PartyService
		if party != null and party.is_running():
			return
		end_running()


func reset_combat_pose() -> void:
	if _caido:
		return
	_resume_running_after_attack = false
	_arrow_in_flight = false
	_battle_advancing = false
	_regroup_run_scale = 1.0
	if _tween_ataque:
		_tween_ataque.kill()
		_tween_ataque = null
	if _state == State.ATTACKING:
		position = _pos_base
		speed_scale = 1.0
	_state = State.IDLE
	if not _caido:
		play("Idle")


func is_running() -> bool:
	return _state == State.RUNNING


func begin_march() -> void:
	begin_running()


func end_march() -> void:
	end_running()


func is_marching() -> bool:
	return is_running()


func begin_attack(_cooldown: float, attack_speed: float) -> bool:
	if _caido:
		return false
	if _arrow_in_flight and _attack_speed < 8.0:
		return false
	if _state == State.ATTACKING:
		abort_attack()
	_attack_speed = attack_speed
	_impact_emitted = false
	_flecha_solta = false
	_resume_running_after_attack = _state == State.RUNNING
	_state = State.ATTACKING
	speed_scale = HeroSpritesheet.attack_speed_scale(_id_classe, attack_speed)
	if sprite_frames == null or not sprite_frames.has_animation("Ataque"):
		_emit_attack_impact()
		_finish_attack()
		return true
	play("Ataque")
	if animation != "Ataque":
		_emit_attack_impact()
		_finish_attack()
		return true
	if not _usar_arte and not _uses_road_attack_pose():
		_slide_attack(speed_scale)
	return true


func _uses_road_attack_pose() -> bool:
	var party := get_parent() as PartyService
	return party != null and party.is_road_combat_ground()


func is_attacking() -> bool:
	return _state == State.ATTACKING


func abort_attack() -> void:
	if _state != State.ATTACKING:
		return
	if _tween_ataque:
		_tween_ataque.kill()
	position = _pos_base
	_finish_attack()


func apply_class(classe: ClassData) -> void:
	if classe != null and classe.id == _id_classe and not _caido and _state != State.RUNNING:
		_attack_speed = classe.attack_speed
		_reanchor_position()
		_adjust_bar()
		return
	if classe == null:
		_id_classe = ""
		_attack_speed = 1.0
		_usar_arte = false
		_cor_classe = Color.WHITE
		self_modulate = Color.WHITE
		scale = HeroSpritesheet.ESCALA_STICK
		sprite_frames = _default_frames()
		_reanchor_position()
		_adjust_bar()
		return
	_id_classe = classe.id
	_attack_speed = classe.attack_speed
	var arte := HeroSpritesheet.frames(classe.id)
	_usar_arte = arte != null
	scale = HeroSpritesheet.scale_for(classe.id)
	if _usar_arte:
		_cor_classe = Color.WHITE
		self_modulate = Color.WHITE
		sprite_frames = arte
	else:
		_cor_classe = classe.color
		if not _caido:
			self_modulate = _cor_classe
		sprite_frames = _default_frames()
	_reanchor_position()
	_adjust_bar()
	_state = State.IDLE
	speed_scale = 1.0
	if not _caido:
		play("Idle")


func _reanchor_position() -> void:
	_pos_base = _marker_pos + HeroSpritesheet.ground_offset(_id_classe)
	position = _pos_base


func play_buff_glow() -> void:
	if _caido:
		return
	if _tween_flash:
		_tween_flash.kill()
	var alvo := Color.WHITE if _usar_arte else _cor_classe
	self_modulate = Color(0.65, 1.0, 0.55, 1.0)
	_tween_flash = create_tween()
	_tween_flash.tween_interval(0.12)
	_tween_flash.tween_property(self, "self_modulate", alvo, 0.18)


func update_hp(atual: int, maximo: int) -> void:
	if _barra:
		_barra.visible = maximo > 0
		_barra.update(atual, maximo)


func hide_slot() -> void:
	_caido = false
	_arrow_in_flight = false
	_resume_running_after_attack = false
	_battle_advancing = false
	_regroup_run_scale = 1.0
	if _state == State.ATTACKING:
		abort_attack()
	elif _state == State.RUNNING:
		_state = State.IDLE
	if _tween_ataque:
		_tween_ataque.kill()
		_tween_ataque = null
	if _tween_flash:
		_tween_flash.kill()
	speed_scale = 1.0
	visible = false
	if _barra:
		_barra.visible = false
	self_modulate = Color.WHITE


func set_fallen(fallen: bool) -> void:
	if fallen and _caido and not visible:
		return
	_caido = fallen
	_arrow_in_flight = false
	_resume_running_after_attack = false
	if _state == State.ATTACKING:
		abort_attack()
	elif _state == State.RUNNING:
		_state = State.IDLE
	if _tween_ataque:
		_tween_ataque.kill()
	speed_scale = 1.0
	_reanchor_position()
	if fallen:
		if _tween_flash:
			_tween_flash.kill()
		if _barra:
			_barra.visible = false
		position += HeroSpritesheet.death_ground_offset(_id_classe)
		if _usar_arte and sprite_frames and sprite_frames.has_animation("Morte"):
			visible = true
			self_modulate = Color.WHITE
			play("Morte")
		else:
			visible = false
			self_modulate = Color(_cor_classe.r * 0.4, _cor_classe.g * 0.4, _cor_classe.b * 0.4, 0.55)
			play("Idle")
	else:
		visible = true
		if _barra:
			_barra.visible = true
		self_modulate = _cor_classe if not _usar_arte else Color.WHITE
		play("Idle")


func flash_damage() -> void:
	if _caido:
		return
	var restore := Color.WHITE if _usar_arte else _cor_classe
	if _state == State.ATTACKING or _arrow_in_flight:
		if _tween_flash:
			_tween_flash.kill()
		self_modulate = Color(1.45, 0.35, 0.32, 1.0)
		_tween_flash = create_tween()
		_tween_flash.tween_property(self, "self_modulate", restore, 0.12)
		return
	if _usar_arte and sprite_frames and sprite_frames.has_animation("Hit"):
		play("Hit")
		return
	if _tween_flash:
		_tween_flash.kill()
	self_modulate = Color.RED
	_tween_flash = create_tween()
	_tween_flash.tween_interval(0.1)
	_tween_flash.tween_property(self, "self_modulate", _cor_classe, 0.08)


func _slide_attack(scale_factor: float) -> void:
	if _tween_ataque:
		_tween_ataque.kill()
	position = _pos_base
	var factor := maxf(0.25, scale_factor)
	_tween_ataque = create_tween()
	_tween_ataque.set_trans(Tween.TRANS_QUAD)
	_tween_ataque.tween_property(
		self, "position:x", _pos_base.x + ATTACK_LUNGE, LUNGE_DURATION / factor
	).set_ease(Tween.EASE_OUT)
	_tween_ataque.tween_property(
		self, "position:x", _pos_base.x, DURACAO_RETORNO / factor
	).set_ease(Tween.EASE_IN)


func _on_animation_finished() -> void:
	if animation == "Morte":
		visible = false
		return
	if animation == "Ataque":
		_emit_attack_impact()
		_finish_attack()
		return
	if animation == "Hit":
		if _state == State.ATTACKING:
			_finish_attack()
		else:
			play("Idle")


func _on_frame_changed() -> void:
	if _caido or _impact_emitted or animation != "Ataque":
		return
	var release_frame := HeroSpritesheet.attack_release_frame(_id_classe)
	if not _usar_arte:
		release_frame = STICK_IMPACT_FRAME
	if frame < release_frame:
		return
	_emit_attack_impact()


func _emit_attack_impact() -> void:
	if _impact_emitted:
		return
	_impact_emitted = true
	if _usar_arte and _id_classe == HeroSpritesheet.ID_ARQUEIRO and not _flecha_solta:
		_flecha_solta = true
		if _fire_arrow_deferred_impact():
			return
	attack_impact.emit()


func _finish_attack() -> void:
	speed_scale = 1.0
	if _resume_running_after_attack:
		_state = State.RUNNING
		_resume_running_after_attack = false
	else:
		_state = State.IDLE
	attack_finished.emit()
	if _state == State.RUNNING:
		_play_running_anim()
	else:
		play("Idle")


func _play_running_anim() -> void:
	if _usar_arte and sprite_frames and sprite_frames.has_animation("Corrida"):
		play("Corrida")
	else:
		play("Idle")
	_apply_regroup_run_scale()


func _apply_regroup_run_scale() -> void:
	if _state != State.RUNNING:
		return
	speed_scale = _regroup_run_scale


func get_arrow_spawn_global() -> Vector2:
	var local := HeroSpritesheet.arrow_spawn_offset_for_frame(_id_classe, frame)
	return to_global(local)


func _resolve_arrow_target(combat_root: Node) -> Vector2:
	var origem := get_arrow_spawn_global()
	var inimigo := EnemyVisual.pick_arrow_target(combat_root)
	if inimigo:
		return HeroSpritesheet.arrow_target_horizontal(origem, inimigo.global_position)
	return origem + Vector2(90, 0)


func _fire_arrow_deferred_impact() -> bool:
	var combat_root: Node = get_parent()
	if combat_root:
		combat_root = combat_root.get_parent()
	if combat_root == null:
		return false
	var origem := get_arrow_spawn_global()
	var destino := _resolve_arrow_target(combat_root)
	_arrow_in_flight = true
	ArrowProjectile.fire(
		combat_root,
		origem,
		destino,
		func() -> void:
			_arrow_in_flight = false
			attack_impact.emit(),
		maxf(1.0, _attack_speed)
	)
	return true


func _adjust_bar() -> void:
	if _barra == null:
		return
	_barra.adjust_in_parent(HeroSpritesheet.health_bar_offset(_id_classe))


func _default_frames() -> SpriteFrames:
	if _frames_stick == null:
		_frames_stick = _create_frames()
	return _frames_stick


func _create_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation("Idle")
	frames.set_animation_loop("Idle", true)
	frames.set_animation_speed("Idle", 5.0)
	frames.add_frame("Idle", _pose_texture(Vector2.ZERO, 0.0, 0.0))
	frames.add_frame("Idle", _pose_texture(Vector2(0, -2), 0.12, -0.08))

	frames.add_animation("Ataque")
	frames.set_animation_loop("Ataque", false)
	frames.set_animation_speed("Ataque", 14.0)
	frames.add_frame("Ataque", _pose_texture(Vector2(4, 0), 0.85, -0.2))
	frames.add_frame("Ataque", _pose_texture(Vector2(8, -1), 1.15, -0.35))
	frames.add_frame("Ataque", _pose_texture(Vector2(2, 0), 0.3, -0.1))
	return frames


func _pose_texture(deslocamento: Vector2, braco_frente: float, braco_tras: float) -> Texture2D:
	var img := Image.create(48, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var origem := Vector2(24, 12) + deslocamento
	var cor := Color(0.92, 0.92, 0.95, 1)
	_circulo(img, origem, 7, cor)
	_draw_line(img, origem + Vector2(0, 7), origem + Vector2(0, 28), cor)
	_draw_line(img, origem + Vector2(0, 12), origem + Vector2(-11 + braco_tras * 6.0, 22), cor)
	_draw_line(img, origem + Vector2(0, 12), origem + Vector2(10 + braco_frente * 14.0, 8 - braco_frente * 4.0), cor)
	_draw_line(img, origem + Vector2(0, 28), origem + Vector2(-8, 48), cor)
	_draw_line(img, origem + Vector2(0, 28), origem + Vector2(8, 48), cor)
	return ImageTexture.create_from_image(img)


func _circulo(img: Image, centro: Vector2, raio: int, cor: Color) -> void:
	for y in range(int(centro.y) - raio, int(centro.y) + raio + 1):
		for x in range(int(centro.x) - raio, int(centro.x) + raio + 1):
			if Vector2(x, y).distance_to(centro) <= raio:
				_set_pixel(img, x, y, cor)


func _draw_line(img: Image, a: Vector2, b: Vector2, cor: Color) -> void:
	var passos := maxi(1, int(a.distance_to(b)))
	for i in passos + 1:
		var p: Vector2 = a.lerp(b, float(i) / float(passos))
		for ox in range(-1, 2):
			for oy in range(-1, 2):
				_set_pixel(img, int(p.x) + ox, int(p.y) + oy, cor)


func _set_pixel(img: Image, x: int, y: int, cor: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	img.set_pixel(x, y, cor)
