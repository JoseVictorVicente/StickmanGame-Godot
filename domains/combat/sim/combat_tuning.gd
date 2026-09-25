class_name CombatTuning
extends RefCounted
## Shared combat movement and timing constants (sim + presentation).

const TICK_SEC := 0.25
const SCROLL_SPEED_PX := 140.0
const ATTACK_GAP := 40.0
const APPROACH_RUNWAY := 80.0
const ROAD_RUNWAY_EXTRA := 48.0
const OFF_SCREEN_EXTRA := 300.0
const RUNNER_DURATION := 5.0
const FORMATION_REGROUP_SPREAD_SEC := 0.8
const FORMATION_SOLO_MIN_MARCH_SEC := 0.9
const FORMATION_REGROUP_RETREAT_SEC := 0.6
const FORMATION_REGROUP_CATCHUP_MULT := 2.5
const FORMATION_REGROUP_FRONT_RUN_SCALE := 0.35
const ENEMY_ATTACK_INTERVAL := 1.35
const MELEE_CONTACT := 0.0


static func spawn_lane_x(hero_front_x: float, off_screen: bool, road_layout: bool = false) -> float:
	var runway := APPROACH_RUNWAY
	if road_layout:
		runway += ROAD_RUNWAY_EXTRA
	var x := hero_front_x + ATTACK_GAP + runway
	if off_screen:
		x += OFF_SCREEN_EXTRA
	return x
