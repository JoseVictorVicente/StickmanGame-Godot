class_name CombatPresentationBridge
extends RefCounted
## Maps CombatSimulator events to combat visuals (no damage rules).

const _Event := preload("res://domains/combat/sim/combat_event.gd")
const _Encounter := preload("res://domains/combat/sim/combat_encounter.gd")

var party: PartyService
var enemy_visual: EnemyVisual
var elite_enemy_visual: EnemyVisual
var flying_demon_enemy_visual: EnemyVisual
var horde_visuals: EnemyHordeVisuals
var enemy_health_bar: ProgressBar
var combat_root: Node2D

var _encounter: _Encounter


func configure(encounter: _Encounter) -> void:
	_encounter = encounter


func present_spawn(anchor: Vector2, off_screen: bool) -> void:
	if _encounter == null or party == null:
		return
	if _encounter.has_horde and horde_visuals != null and _encounter.horde != null:
		_present_horde(anchor, off_screen)
		return
	_present_solo(anchor, off_screen)


func apply_events(events: Array) -> void:
	for event in events:
		if event is RefCounted:
			_apply_event(event)


func sync_horde_lanes() -> void:
	if _encounter == null or not _encounter.has_horde or _encounter.horde == null:
		return
	if horde_visuals == null or party == null:
		return
	var hero_front := party.hero_slot_x(party.front_target_index())
	for i in _encounter.horde.member_count():
		var visual := horde_visuals.get_visual(i)
		if visual == null or not visual.is_field_alive():
			continue
		var lane_x: float = _encounter.horde.member_lane_x[i] if i < _encounter.horde.member_lane_x.size() else _encounter.contact_lane_x()
		var pixel_x := _lane_to_pixel(lane_x, hero_front)
		visual.sim_set_combat_x(pixel_x)
		if i < _encounter.horde.members_at_contact.size() and _encounter.horde.members_at_contact[i]:
			visual.sim_set_at_contact(true)


func _present_horde(anchor: Vector2, off_screen: bool) -> void:
	if enemy_visual != null:
		enemy_visual.hide_escort()
	var data: EnemyData = _encounter.horde.enemy_data
	if data == null or data.visual_profile == null:
		return
	horde_visuals.show_wave(
		data.visual_profile,
		anchor,
		_encounter.horde.member_count(),
		_encounter.horde.active_index,
		off_screen
	)
	_refresh_horde_hp_bar()
	sync_horde_lanes()


func _present_solo(anchor: Vector2, off_screen: bool) -> void:
	if horde_visuals != null:
		horde_visuals.hide_all()
	if _encounter.minion_data != null and enemy_visual != null:
		if _encounter.minion_data.visual_profile != null:
			enemy_visual.configure(_encounter.minion_data.visual_profile)
		enemy_visual.prepare_spawn(anchor)
		enemy_visual.show_up(anchor)
	if _encounter.elite_data != null and elite_enemy_visual != null and _encounter.elite != null:
		if _encounter.elite_data.visual_profile != null:
			elite_enemy_visual.configure(_encounter.elite_data.visual_profile)
		var escort_offset := Vector2.ZERO
		if _encounter.elite_data.visual_profile != null:
			escort_offset = _encounter.elite_data.visual_profile.escort_spawn_offset
		elite_enemy_visual.set_escort(enemy_visual, escort_offset)
		elite_enemy_visual.show_up(anchor + escort_offset)
	if _encounter.flying_data != null and flying_demon_enemy_visual != null and _encounter.flying != null:
		if _encounter.flying_data.visual_profile != null:
			flying_demon_enemy_visual.configure(_encounter.flying_data.visual_profile)
		var escort_offset := Vector2.ZERO
		if _encounter.elite_data != null and _encounter.elite_data.visual_profile != null:
			escort_offset = _encounter.elite_data.visual_profile.escort_spawn_offset
		flying_demon_enemy_visual.set_escort(elite_enemy_visual, escort_offset)
		flying_demon_enemy_visual.show_up(anchor + escort_offset)
	if enemy_health_bar != null and _encounter.minion != null:
		enemy_health_bar.initialize_bar(_encounter.minion.max_hp)
		enemy_health_bar.show_up()


func _apply_event(event: RefCounted) -> void:
	match event.kind:
		_Event.Kind.HERO_HIT_ENEMY:
			_on_hero_hit_enemy(event.payload)
		_Event.Kind.SWARM_ATTACK:
			_on_swarm_attack(event.payload)
		_Event.Kind.MEMBER_PROMOTED:
			_on_member_promoted(event.payload)
		_Event.Kind.PHASE_CHANGED:
			_on_phase_changed(event.payload)


func _on_hero_hit_enemy(_payload: Dictionary) -> void:
	var active: Enemy = _encounter.get_active_enemy() if _encounter != null else null
	if active == null:
		return
	if enemy_health_bar != null:
		enemy_health_bar.update_hp(active.current_hp)
	var visual := _active_visual()
	if visual != null and visual.has_method("update_hp"):
		visual.update_hp(active.current_hp, active.max_hp)
	if visual != null and visual.has_method("flash_hit"):
		visual.flash_hit()


func _on_swarm_attack(payload: Dictionary) -> void:
	var interval := float(payload.get("interval", 1.35))
	var started := false
	if _encounter != null and _encounter.has_horde and horde_visuals != null:
		for visual in horde_visuals.all_visible():
			if visual != null and visual.is_field_alive() and visual.is_at_attack_stop_line():
				if visual.begin_attack(interval):
					started = true
	elif enemy_visual != null and enemy_visual.is_at_attack_stop_line():
		if enemy_visual.begin_attack(interval):
			started = true
	if started:
		AudioManager.play_attack_sound()


func _on_member_promoted(_payload: Dictionary) -> void:
	if horde_visuals == null or _encounter == null or _encounter.horde == null:
		return
	horde_visuals.refresh_active(_encounter.horde.active_index, _encounter.horde.member_count())
	_refresh_horde_hp_bar()


func _on_phase_changed(payload: Dictionary) -> void:
	if str(payload.get("phase", "")) != "RUNNING" or party == null:
		return
	party.begin_running()


func _refresh_horde_hp_bar() -> void:
	if _encounter == null or not _encounter.has_horde:
		return
	var active: Enemy = _encounter.get_active_enemy()
	if active == null or enemy_health_bar == null:
		return
	enemy_health_bar.initialize_bar(active.max_hp)
	enemy_health_bar.update_hp(active.current_hp)
	var visual := horde_visuals.get_visual(_encounter.horde.active_index) if horde_visuals != null else null
	if visual != null and visual.has_method("update_hp"):
		visual.update_hp(active.current_hp, active.max_hp)


func _active_visual() -> EnemyVisual:
	if _encounter == null:
		return enemy_visual
	if _encounter.has_horde and horde_visuals != null and _encounter.horde != null:
		return horde_visuals.get_visual(_encounter.horde.active_index)
	if _encounter.minion != null and not _encounter.minion.is_dead():
		return enemy_visual
	if _encounter.elite != null and not _encounter.elite.is_dead():
		return elite_enemy_visual
	if _encounter.flying != null and not _encounter.flying.is_dead():
		return flying_demon_enemy_visual
	return enemy_visual


func _lane_to_pixel(lane_x: float, hero_front_x: float) -> float:
	return hero_front_x + (lane_x - _encounter.contact_lane_x())
