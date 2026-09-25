class_name CombatLane
extends RefCounted
## Abstract lane coordinates for combat simulation (mapped to pixels by presentation).

const MELEE_CONTACT := 0.0
const SPAWN_RUNWAY := 120.0
const RUNNER_START_OFFSET := 200.0


static func contact_x(hero_front_x: float) -> float:
	return hero_front_x + MELEE_CONTACT


static func spawn_x(hero_front_x: float) -> float:
	return hero_front_x + MELEE_CONTACT + SPAWN_RUNWAY


static func runner_start_x(hero_front_x: float) -> float:
	return hero_front_x + MELEE_CONTACT + RUNNER_START_OFFSET
