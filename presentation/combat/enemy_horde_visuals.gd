class_name EnemyHordeVisuals
extends Node2D
## Visual pool for multi-enemy horde waves.

const MAX_SLOTS := 7
const SLOT_SPACING := 48.0
var _slots: Array[EnemyVisual] = []


func _ready() -> void:
	for i in MAX_SLOTS:
		var visual := EnemyVisual.new()
		visual.name = "HordeSlot%d" % i
		visual.visible = false
		add_child(visual)
		_slots.append(visual)


func slot_count() -> int:
	return _slots.size()


func get_visual(index: int) -> EnemyVisual:
	if index < 0 or index >= _slots.size():
		return null
	return _slots[index]


func pick_target() -> EnemyVisual:
	for visual in _slots:
		if visual != null and visual.is_targetable():
			return visual
	return null


func hide_all() -> void:
	for visual in _slots:
		if visual == null:
			continue
		visual.set_horde_member(false)
		visual.set_horde_targetable(false)
		visual.hide_escort()


func show_wave(
	profile: EnemyVisualProfile,
	anchor: Vector2,
	count: int,
	active_index: int,
	off_screen: bool
) -> void:
	var amount := clampi(count, 1, _slots.size())
	for i in _slots.size():
		var visual := _slots[i]
		if visual == null:
			continue
		if i >= amount:
			visual.set_horde_member(false)
			visual.set_horde_targetable(false)
			visual.clear_horde_backup()
			visual.hide_escort()
			continue
		visual.configure(profile)
		var lane_anchor := _lane_anchor(anchor, i)
		visual.prepare_spawn(lane_anchor)
		visual.set_horde_member(true)
		visual.set_horde_slot(i)
		visual.set_horde_targetable(i == active_index)
		visual.show_up(lane_anchor if off_screen else lane_anchor)
	set_active_target(amount, active_index)


func set_active_target(count: int, active_index: int) -> void:
	var amount := clampi(count, 1, _slots.size())
	for i in amount:
		var visual := _slots[i]
		if visual == null:
			continue
		if visual.is_dead_state():
			visual.set_horde_member(false)
			visual.set_horde_targetable(false)
			continue
		visual.set_horde_member(true)
		visual.clear_horde_backup()
		visual.set_horde_slot(i)
		visual.set_horde_targetable(i == active_index)


func refresh_active(active_index: int, count: int) -> void:
	set_active_target(count, active_index)


func fade_member(index: int, drift_with_scroll: bool) -> void:
	var visual := get_visual(index)
	if visual == null:
		return
	visual.set_horde_member(false)
	visual.set_horde_targetable(false)
	visual.clear_horde_backup()
	visual.fade_out(drift_with_scroll)


func update_member_hp(index: int, current: int, max_hp: int) -> void:
	var visual := get_visual(index)
	if visual != null and visual.has_method("update_hp"):
		visual.update_hp(current, max_hp)


func resync_anchors(anchor: Vector2, count: int, active_index: int) -> void:
	var amount := clampi(count, 1, _slots.size())
	for i in amount:
		var visual := _slots[i]
		if visual == null or not visual.is_field_alive():
			continue
		var lane_anchor := _lane_anchor(anchor, i)
		visual.prepare_spawn(lane_anchor)
	set_active_target(amount, active_index)


func all_visible() -> Array[EnemyVisual]:
	var lista: Array[EnemyVisual] = []
	for visual in _slots:
		if visual != null and visual.visible:
			lista.append(visual)
	return lista


func connect_attack_signals(
	impact_cb: Callable,
	finished_cb: Callable,
	ready_cb: Callable = Callable()
) -> void:
	for visual in _slots:
		if visual == null:
			continue
		if not visual.attack_impact.is_connected(impact_cb):
			visual.attack_impact.connect(impact_cb)
		if not visual.attack_finished.is_connected(finished_cb):
			visual.attack_finished.connect(finished_cb)
		if ready_cb.is_valid() and not visual.ready_to_attack.is_connected(ready_cb):
			visual.ready_to_attack.connect(ready_cb)


func _lane_anchor(anchor: Vector2, index: int) -> Vector2:
	return anchor + Vector2(float(index) * SLOT_SPACING, 0.0)
