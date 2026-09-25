class_name PartyStatsService
extends RefCounted
## Pure party stat and HP logic (no scene nodes).

const SLOTS := 3

var active_party: Array = [null, null, null]
var current_hp: Array[int] = [0, 0, 0]
var max_hp: Array[int] = [0, 0, 0]


func is_alive(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= SLOTS:
		return false
	if active_party[slot_index] == null:
		return false
	return current_hp[slot_index] > 0


func right_target_index() -> int:
	for i in range(SLOTS - 1, -1, -1):
		if is_alive(i):
			return i
	return -1


func front_target_index() -> int:
	if is_alive(1):
		return 1
	return right_target_index()


func apply_damage(slot_index: int, amount: int) -> bool:
	if not is_alive(slot_index):
		return false
	current_hp[slot_index] = maxi(0, current_hp[slot_index] - maxi(0, amount))
	return current_hp[slot_index] <= 0


func heal_all(max_values: Array[int]) -> void:
	for i in SLOTS:
		if i < max_values.size():
			max_hp[i] = max_values[i]
			current_hp[i] = max_hp[i]
