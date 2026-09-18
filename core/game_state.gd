class_name GameState
extends RefCounted
## Single source of truth for session-wide economy and phase flags.

signal gold_changed(new_amount: int)
signal phase_changed(world: int, stage: int, difficulty: int)
signal save_requested()

var gold: int = 0
var world: int = 1
var stage: int = 1
var difficulty: int = 0
var unlocked_stages: Array[int] = [1, 1, 1]
var repeat_stage: bool = false
var wave: int = 1


func get_gold() -> int:
	return gold


func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	gold_changed.emit(gold)


func try_spend_gold(amount: int) -> bool:
	if amount <= 0:
		return true
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	save_requested.emit()
	return true


func set_gold(amount: int) -> void:
	gold = maxi(0, amount)
	gold_changed.emit(gold)


func sync_from_combat(combat_state: Dictionary) -> void:
	world = int(combat_state.get("world", combat_state.get("world", world)))
	stage = int(combat_state.get("stage", combat_state.get("stage", stage)))
	difficulty = int(combat_state.get("difficulty", combat_state.get("difficulty", difficulty)))
	wave = int(combat_state.get("wave", combat_state.get("wave", wave)))
	repeat_stage = bool(combat_state.get("repeat_stage", combat_state.get("repeat_stage", repeat_stage)))
	var unlocked: Variant = combat_state.get("unlocked_stages", combat_state.get("unlocked_stages", unlocked_stages))
	if unlocked is Array:
		unlocked_stages = unlocked.duplicate()
	phase_changed.emit(world, stage, difficulty)


func to_dict() -> Dictionary:
	return {
		"gold": gold,
		"world": world,
		"stage": stage,
		"difficulty": difficulty,
		"unlocked_stages": unlocked_stages.duplicate(),
		"repeat_stage": repeat_stage,
		"wave": wave,
	}
