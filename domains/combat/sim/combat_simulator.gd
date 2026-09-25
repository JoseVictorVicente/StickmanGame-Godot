class_name CombatSimulator
extends RefCounted
## Tick-based combat simulation (Melvor-style discrete steps).

const _Encounter := preload("res://domains/combat/sim/combat_encounter.gd")
const _ActorGroup := preload("res://domains/combat/sim/combat_actor_group.gd")
const _Event := preload("res://domains/combat/sim/combat_event.gd")
const _ActionQueue := preload("res://domains/combat/sim/combat_action_queue.gd")
const _DamagePipeline := preload("res://domains/combat/sim/damage_pipeline.gd")

const TICK_SEC := 0.25
const ARCANE_BEAT_ID := "arcane_beat"
const ARCANE_BEAT_PULSES := 4
const ARCANE_BEAT_MULT_ENGAGED := 0.60
const ARCANE_BEAT_MULT_SWARM := 0.75
const ARCANE_BEAT_MULT_RUNNING := 0.30
const ARCANE_BEAT_ARMOR_PEN := 10.0

var encounter: _Encounter
var tick_index: int = 0
var _accumulator: float = 0.0
var _action_queue: RefCounted
var _pending_events: Array = []


func _init() -> void:
	_action_queue = _ActionQueue.new()


func configure(enc: _Encounter) -> void:
	encounter = enc
	tick_index = 0
	_accumulator = 0.0
	_action_queue.clear()
	_pending_events.clear()


func advance(delta: float, can_heroes_act: bool, can_enemies_act: bool) -> Array:
	_pending_events.clear()
	if encounter == null or encounter.phase == _Encounter.Phase.RESOLVING:
		return []
	if encounter.phase == _Encounter.Phase.RUNNING:
		_advance_runner(delta, can_heroes_act)
	elif encounter.has_horde and encounter.horde != null:
		_advance_horde_movement(delta)
	_accumulator += delta
	while _accumulator >= TICK_SEC:
		_accumulator -= TICK_SEC
		tick_index += 1
		_step_tick(can_heroes_act, can_enemies_act)
	return _pending_events.duplicate()


func apply_hero_hit(damage: int, is_crit: bool) -> Array:
	_pending_events.clear()
	if encounter == null or not encounter.has_living_enemies():
		return []
	if encounter.phase == _Encounter.Phase.RUNNING and not encounter.engaged:
		return []
	var target: Enemy = encounter.get_active_enemy()
	if target == null:
		return []
	var result := _DamagePipeline.apply_enemy_damage(target, damage)
	if not bool(result.get("applied", false)):
		return []
	_record_enemy_hit_events(damage, is_crit, result, {})
	return _pending_events.duplicate()


func enqueue_arcane_beat(
	slot: int,
	base_damage: int,
	crit_chance: float,
	crit_damage: float
) -> void:
	for i in ARCANE_BEAT_PULSES:
		_action_queue.enqueue({
			"kind": "hero_skill_hit",
			"skill_id": ARCANE_BEAT_ID,
			"slot": slot,
			"execute_tick": tick_index + 1 + i,
			"base_damage": base_damage,
			"crit_chance": crit_chance,
			"crit_damage": crit_damage,
			"pulse_index": i,
		})


func promote_horde_member() -> void:
	if encounter == null or not encounter.has_horde or encounter.horde == null:
		return
	encounter.horde.advance_after_kill()
	encounter.minion = encounter.horde.active_enemy()
	_pending_events.append(_Event.make(
		_Event.Kind.MEMBER_PROMOTED,
		tick_index,
		{"member_index": encounter.horde.active_index}
	))


func start_runner_phase(duration: float = 1.2) -> void:
	if encounter == null:
		return
	encounter.phase = _Encounter.Phase.RUNNING
	encounter.engaged = false
	encounter.runner_timer = 0.0
	encounter.runner_duration = maxf(0.1, duration)
	_pending_events.append(_Event.make(
		_Event.Kind.PHASE_CHANGED,
		tick_index,
		{"phase": "RUNNING"}
	))


func engage() -> void:
	if encounter == null:
		return
	encounter.phase = _Encounter.Phase.ENGAGED
	encounter.engaged = true
	encounter.enemy_attack_cooldown = 0.0
	_pending_events.append(_Event.make(
		_Event.Kind.ENGAGED,
		tick_index,
		{}
	))
	_pending_events.append(_Event.make(
		_Event.Kind.PHASE_CHANGED,
		tick_index,
		{"phase": "ENGAGED"}
	))


func _advance_runner(delta: float, can_heroes_act: bool) -> void:
	if encounter.engaged:
		return
	encounter.runner_timer += delta
	if encounter.runner_timer >= encounter.runner_duration and can_heroes_act:
		engage()


func _advance_horde_movement(delta: float) -> void:
	var horde = encounter.horde
	if horde == null:
		return
	var speed := 90.0
	if horde.enemy_data != null and horde.enemy_data.visual_profile != null:
		speed = horde.enemy_data.visual_profile.move_speed
	var contact: float = horde.contact_lane_x
	for i in horde.members.size():
		horde.advance_member_toward_contact(i, speed, delta)
		if i < horde.member_lane_x.size():
			horde.member_lane_x[i] = minf(horde.member_lane_x[i], contact)


func _step_tick(can_heroes_act: bool, can_enemies_act: bool) -> void:
	if can_enemies_act and encounter.has_living_enemies():
		_resolve_scheduled_hero_skill_hits()
	if not can_enemies_act or not encounter.has_living_enemies():
		return
	if encounter.phase != _Encounter.Phase.ENGAGED or not encounter.engaged:
		return
	var interval := _enemy_attack_interval()
	encounter.enemy_attack_cooldown = maxf(0.0, encounter.enemy_attack_cooldown - TICK_SEC)
	if encounter.enemy_attack_cooldown > 0.0:
		return
	if encounter.has_horde and encounter.horde != null:
		if not encounter.horde.all_at_contact():
			return
		encounter.enemy_attack_cooldown = interval
		_pending_events.append(_Event.make(
			_Event.Kind.SWARM_ATTACK,
			tick_index,
			{"interval": interval, "member_count": encounter.horde.living_count()}
		))
		return
	encounter.enemy_attack_cooldown = interval
	_action_queue.enqueue({"kind": "enemy_attack", "interval": interval})
	_resolve_action_queue()


func resolve_enemy_attack(
	target_slot: int,
	raw_damage: int,
	hero_hp: int,
	hero_stats: Dictionary
) -> Array:
	_pending_events.clear()
	var result := _DamagePipeline.apply_hero_damage(target_slot, raw_damage, hero_hp, hero_stats)
	_pending_events.append(_Event.make(
		_Event.Kind.ENEMY_HIT_HERO,
		tick_index,
		{
			"slot": target_slot,
			"damage": result.get("damage", 0),
			"evaded": result.get("evaded", false),
			"hp": result.get("hp", hero_hp),
		}
	))
	if int(result.get("hp", 0)) <= 0:
		_pending_events.append(_Event.make(
			_Event.Kind.PARTY_DEFEATED,
			tick_index,
			{"slot": target_slot}
		))
	return _pending_events.duplicate()


func _resolve_action_queue() -> void:
	for action in _action_queue.drain():
		if str(action.get("kind", "")) == "enemy_attack":
			_pending_events.append(_Event.make(
				_Event.Kind.SWARM_ATTACK,
				tick_index,
				{"interval": float(action.get("interval", 1.35)), "member_count": 1}
			))


func consume_pending_events() -> Array:
	var out := _pending_events.duplicate()
	_pending_events.clear()
	return out


func _enemy_attack_interval() -> float:
	var data: EnemyData = encounter.get_active_enemy_data()
	if data != null:
		return data.get_attack_interval()
	return 1.35


func _resolve_scheduled_hero_skill_hits() -> void:
	if encounter == null or not encounter.has_living_enemies():
		return
	for action in _action_queue.drain_for_tick(tick_index):
		if str(action.get("kind", "")) != "hero_skill_hit":
			continue
		if str(action.get("skill_id", "")) != ARCANE_BEAT_ID:
			continue
		_apply_arcane_beat_pulse(action)


func _apply_arcane_beat_pulse(action: Dictionary) -> void:
	var target: Enemy = encounter.get_active_enemy()
	if target == null:
		return
	var base_damage := int(action.get("base_damage", 1))
	var crit_chance := float(action.get("crit_chance", 0.0))
	var crit_damage := float(action.get("crit_damage", 0.0))
	var mult := _arcane_beat_multiplier()
	var scaled := maxi(
		1,
		int(round(float(base_damage) * mult * (1.0 + ARCANE_BEAT_ARMOR_PEN / 100.0)))
	)
	var roll := CombatMath.roll_crit_damage(scaled, crit_chance, crit_damage)
	var damage := int(roll.get("damage", scaled))
	var is_crit := bool(roll.get("is_crit", false))
	var result := _DamagePipeline.apply_enemy_damage(target, damage)
	if not bool(result.get("applied", false)):
		return
	var extra := {
		"skill_id": ARCANE_BEAT_ID,
		"pulse_index": int(action.get("pulse_index", 0)),
		"slot": int(action.get("slot", 0)),
	}
	_record_enemy_hit_events(damage, is_crit, result, extra)


func _arcane_beat_multiplier() -> float:
	if encounter.phase == _Encounter.Phase.RUNNING and not encounter.engaged:
		return ARCANE_BEAT_MULT_RUNNING
	if encounter.has_horde and encounter.horde != null and encounter.horde.all_at_contact():
		return ARCANE_BEAT_MULT_SWARM
	return ARCANE_BEAT_MULT_ENGAGED


func _record_enemy_hit_events(
	damage: int,
	is_crit: bool,
	result: Dictionary,
	extra: Dictionary
) -> void:
	var payload := {
		"damage": damage,
		"is_crit": is_crit,
		"hp": result.get("hp", 0),
		"max_hp": result.get("max_hp", 1),
		"died": result.get("died", false),
	}
	for key in extra.keys():
		payload[key] = extra[key]
	_pending_events.append(_Event.make(_Event.Kind.HERO_HIT_ENEMY, tick_index, payload))
	if bool(result.get("died", false)):
		if encounter.has_horde and encounter.horde != null and encounter.horde.living_count() > 0:
			_pending_events.append(_Event.make(
				_Event.Kind.ENEMY_MEMBER_DIED,
				tick_index,
				{"member_index": encounter.horde.active_index, "skill_id": extra.get("skill_id", "")}
			))
		else:
			_pending_events.append(_Event.make(
				_Event.Kind.ENEMY_WAVE_CLEARED,
				tick_index,
				{"skill_id": extra.get("skill_id", "")}
			))
