class_name CombatActionQueue
extends RefCounted
## Per-tick action queue for combat simulation.


var _actions: Array[Dictionary] = []


func clear() -> void:
	_actions.clear()


func enqueue(action: Dictionary) -> void:
	_actions.append(action.duplicate())


func drain() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	out.assign(_actions)
	_actions.clear()
	return out


func drain_for_tick(tick: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var kept: Array[Dictionary] = []
	for action in _actions:
		if int(action.get("execute_tick", -1)) == tick:
			out.append(action)
		else:
			kept.append(action)
	_actions = kept
	return out
