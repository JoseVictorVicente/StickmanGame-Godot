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
var floor_scroller: FloorScroller
var combat_background: CombatBackground

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
	sync_solo_lane()


func apply_events(events: Array) -> void:
	for event in events:
		if event is RefCounted:
			_apply_event(event)


func sync_horde_lanes() -> void:
	if _encounter == null or not _encounter.has_horde or _encounter.horde == null:
		return
	if horde_visuals == null or party == null:
		return
	var hero_front := _encounter.hero_front_lane_x
	for i in _encounter.horde.member_count():
		var visual := horde_visuals.get_visual(i)
		if visual == null or not visual.is_field_alive():
			continue
		if i >= _encounter.horde.member_lane_x.size():
			continue
		var lane_x: float = _encounter.horde.member_lane_x[i]
		var pixel_x := _lane_to_pixel(lane_x, hero_front)
		visual.sim_set_combat_x(pixel_x)
		var at_contact := (
			i < _encounter.horde.members_at_contact.size()
			and _encounter.horde.members_at_contact[i]
		)
		visual.sim_set_at_contact(at_contact)


func sync_solo_lane() -> void:
	if _encounter == null or _encounter.has_horde or enemy_visual == null or party == null:
		return
	if not _encounter.has_living_enemies():
		return
	var pixel_x := _lane_to_pixel(_encounter.solo_lane_x, _encounter.hero_front_lane_x)
	var at_contact := (
		not _encounter.solo_runner_active
		or absf(_encounter.solo_lane_x - _encounter.solo_contact_x) <= 0.5
	)
	var sim_controlled := (
		_encounter.phase == _Encounter.Phase.RUNNING and _encounter.solo_runner_active
	)
	enemy_visual.set_sim_controlled(sim_controlled)
	enemy_visual.sim_set_combat_x(pixel_x)
	enemy_visual.sim_set_at_contact(at_contact)


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
		enemy_visual.reset_spawn_position(anchor)
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
		var flying_escort_offset := _flying_escort_offset()
		flying_demon_enemy_visual.set_escort(elite_enemy_visual, flying_escort_offset)
		flying_demon_enemy_visual.show_up(anchor + flying_escort_offset)
	if enemy_health_bar != null and _encounter.minion != null:
		enemy_health_bar.initialize_bar(_encounter.minion.max_hp)
		enemy_health_bar.show_up()


func _apply_event(event: RefCounted) -> void:
	match event.kind:
		_Event.Kind.HERO_HIT_ENEMY:
			_on_hero_hit_enemy(event.payload)
		_Event.Kind.ENEMY_HIT_HERO:
			_on_enemy_hit_hero(event.payload)
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


func _on_enemy_hit_hero(payload: Dictionary) -> void:
	if party == null:
		return
	var slot := int(payload.get("slot", -1))
	if slot < 0:
		return
	if bool(payload.get("evaded", false)):
		var posicao := party.hero_world_position(slot)
		if posicao != Vector2.ZERO:
			var root := _active_visual()
			var parent := root.get_parent() if root else null
			if parent != null:
				DamageNumber.spawn_miss(parent, posicao, tr(LocaleKeys.COMBAT_MISS))
		return
	var dano := int(payload.get("damage", 0))
	if dano > 0:
		party.apply_damage_to_hero(slot, dano)
		AudioManager.play_hit_sound()


func _on_swarm_attack(payload: Dictionary) -> void:
	var interval := float(payload.get("interval", 1.35))
	if _encounter != null and _encounter.has_horde and horde_visuals != null:
		var started := false
		for visual in horde_visuals.all_visible():
			if visual == null or not visual.is_field_alive():
				continue
			if not visual.is_in_attack_range():
				continue
			if visual.begin_attack(interval):
				started = true
		if started:
			AudioManager.play_attack_sound()
		return
	var visual := _active_visual()
	if visual != null and visual.is_field_alive() and visual.begin_attack(interval):
		AudioManager.play_attack_sound()


func _on_member_promoted(_payload: Dictionary) -> void:
	if horde_visuals == null or _encounter == null or _encounter.horde == null:
		return
	horde_visuals.refresh_active(_encounter.horde.active_index, _encounter.horde.member_count())
	_refresh_horde_hp_bar()


func _on_phase_changed(payload: Dictionary) -> void:
	var phase_name := str(payload.get("phase", ""))
	match phase_name:
		"RUNNING":
			_begin_runner_visuals()
		"ENGAGED":
			_end_runner_visuals()


func _begin_runner_visuals() -> void:
	if party != null:
		ensure_party_regroup_wiring()
		party.begin_formation_march()
		party.set_runner_sync(true, false)
	_apply_regroup_scroll_speed()
	_set_stage_scrolling(true)


func _end_runner_visuals() -> void:
	if party != null:
		party.set_field_state(PartyService.PartyFieldState.ENGAGED)
		party.set_runner_sync(false, false)
	_clear_scroll_speed_override()
	_set_stage_scrolling(false)
	if enemy_visual != null:
		enemy_visual.set_sim_controlled(false)
	sync_solo_lane()


func ensure_party_regroup_wiring() -> void:
	if party == null:
		return
	if not party.march_regroup_phase_changed.is_connected(_on_march_regroup_phase_changed):
		party.march_regroup_phase_changed.connect(_on_march_regroup_phase_changed)
	if not party.march_regroup_started.is_connected(_on_march_regroup_started):
		party.march_regroup_started.connect(_on_march_regroup_started)
	if not party.march_regroup_finished.is_connected(_on_march_regroup_finished):
		party.march_regroup_finished.connect(_on_march_regroup_finished)


func _on_march_regroup_phase_changed(phase_name: String, scroll_speed_px: float) -> void:
	match phase_name:
		"CONVERGE":
			_clear_scroll_speed_override()
			_set_stage_scrolling(true)
		"RETREAT":
			if scroll_speed_px > 0.0:
				_set_scroll_speed_override(scroll_speed_px)
			_set_stage_scrolling(true)


func _on_march_regroup_started(scroll_speed_px: float) -> void:
	if scroll_speed_px > 0.0:
		_set_scroll_speed_override(scroll_speed_px)
	_set_stage_scrolling(true)


func _apply_regroup_scroll_speed() -> void:
	if party != null and party.is_march_regrouping():
		var speed := party.regroup_scroll_speed()
		if speed > 0.0:
			_set_scroll_speed_override(speed)
			return
	_clear_scroll_speed_override()


func _on_march_regroup_finished() -> void:
	_clear_scroll_speed_override()


func _set_scroll_speed_override(speed: float) -> void:
	if combat_background != null:
		combat_background.set_scroll_speed_px(speed)
	if floor_scroller != null:
		floor_scroller.set_scroll_speed_px(speed)


func _clear_scroll_speed_override() -> void:
	if combat_background != null:
		combat_background.clear_scroll_speed_override()
	if floor_scroller != null:
		floor_scroller.clear_scroll_speed_override()


func _set_stage_scrolling(active: bool) -> void:
	if combat_background != null and combat_background.visible:
		combat_background.set_scrolling(active)
	if floor_scroller != null and floor_scroller.visible:
		floor_scroller.set_scrolling(active)


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


func _flying_escort_offset() -> Vector2:
	if _encounter == null or _encounter.flying_data == null:
		return Vector2.ZERO
	var profile := _encounter.flying_data.visual_profile
	if profile == null:
		return Vector2.ZERO
	return profile.escort_spawn_offset


func _lane_to_pixel(lane_x: float, hero_front_x: float) -> float:
	return hero_front_x + (lane_x - _encounter.hero_front_lane_x)
