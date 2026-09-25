extends SceneTree
## Headless tests for formation engage ranges and march commit.

const HeroSpritesheetScript := preload("res://presentation/combat/hero_spritesheet.gd")
const CombatTuningScript := preload("res://domains/combat/sim/combat_tuning.gd")
const TestLog := preload("res://tests/test_log_helper.gd")

var _failed := false


func _init() -> void:
	_test_archer_outranges_melee()
	_test_commit_preserves_visual_x()
	_test_two_phase_regroup()
	if _failed:
		TestLog.suite_complete("PartyFormation", false)
		quit(1)
	TestLog.suite_complete("PartyFormation", true)
	print("[TEST PASS] PartyFormation")
	quit(0)


func _test_archer_outranges_melee() -> void:
	var archer_range := HeroSpritesheetScript.engage_range("archer")
	var warrior_range := HeroSpritesheetScript.engage_range("warrior")
	if archer_range <= warrior_range:
		_fail("archer engage range should exceed warrior/melee range")


func _test_commit_preserves_visual_x() -> void:
	var slot_x := [-72.0, -28.0, -68.0]
	var march_lead := 0.0
	var spread := [0.0, 0.0, 0.0]
	var advance := [200.0, 150.0, 0.0]
	var before: Array[float] = []
	for i in 3:
		before.append(_lane_x(slot_x, march_lead, spread, advance, i))
	var committed := _commit_lane_offsets(march_lead, spread, advance)
	for i in 3:
		var after := _lane_x(slot_x, committed.lead, committed.spread, committed.advance, i)
		if absf(before[i] - after) > 0.01:
			_fail("commit must preserve lane x for slot %d" % i)


func _test_two_phase_regroup() -> void:
	var slot_x := [-72.0, -28.0, -68.0]
	var committed := _commit_lane_offsets(0.0, [0.0, 0.0, 0.0], [200.0, 150.0, 0.0])
	var lead: float = committed.lead
	var spread: Array = committed.spread.duplicate()
	var spread_sec := CombatTuningScript.FORMATION_REGROUP_SPREAD_SEC
	var steps := 40
	for step in steps:
		var delta := spread_sec / float(steps)
		var elapsed := float(step + 1) * delta
		var time_remaining := maxf(0.001, spread_sec - elapsed)
		for i in 3:
			if spread[i] < -0.001:
				var catch_up := maxf(
					CombatTuningScript.SCROLL_SPEED_PX * CombatTuningScript.FORMATION_REGROUP_CATCHUP_MULT,
					absf(spread[i]) / time_remaining
				)
				spread[i] = minf(0.0, float(spread[i]) + catch_up * delta)
		if absf(lead - committed.lead) > 0.01:
			_fail("phase 1 should keep lead constant")
	for i in 3:
		if absf(float(spread[i])) > 0.01:
			_fail("phase 1 should zero spreads for slot %d" % i)
	var retreat_sec := CombatTuningScript.FORMATION_REGROUP_RETREAT_SEC
	for step in steps:
		var t := float(step + 1) / float(steps)
		lead = lerpf(committed.lead, 0.0, t)
	for i in 3:
		var end_x: float = slot_x[i] + lead
		if absf(end_x - slot_x[i]) > 0.01:
			_fail("phase 2 should rest at left anchor for slot %d" % i)
	if committed.lead < 199.0:
		_fail("commit should retain march lead from max advance")


func _lane_x(
	slot_x: Array,
	march_lead: float,
	spread: Array,
	advance: Array,
	slot_index: int
) -> float:
	return slot_x[slot_index] + march_lead + spread[slot_index] + advance[slot_index]


func _commit_lane_offsets(
	march_lead: float,
	spread: Array,
	advance: Array
) -> Dictionary:
	var lead := march_lead
	var totals: Array[float] = []
	for i in 3:
		var total_forward: float = march_lead + spread[i] + advance[i]
		totals.append(total_forward)
		lead = maxf(lead, total_forward)
	var new_spread: Array[float] = []
	for i in 3:
		new_spread.append(totals[i] - lead)
	return {
		"lead": lead,
		"spread": new_spread,
		"advance": [0.0, 0.0, 0.0],
	}


func _fail(message: String) -> void:
	_failed = true
	push_error(message)
