class_name CombatLane
extends RefCounted
## Abstract lane coordinates for combat simulation (mapped to pixels by presentation).

const _Tuning := preload("res://domains/combat/sim/combat_tuning.gd")

const MELEE_CONTACT: float = _Tuning.MELEE_CONTACT
const SPAWN_RUNWAY: float = _Tuning.APPROACH_RUNWAY


static func contact_x(hero_front_x: float) -> float:
	return hero_front_x + _Tuning.MELEE_CONTACT


static func spawn_x(hero_front_x: float, off_screen: bool = false, road_layout: bool = false) -> float:
	return _Tuning.spawn_lane_x(hero_front_x, off_screen, road_layout)
