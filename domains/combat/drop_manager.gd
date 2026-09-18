class_name DropManager
extends RefCounted
## Gold variance and item drop chance via ItemDatabase.

const DROP_CHANCE := 0.30
const GOLD_VARIANCE := 0.15


func gold_with_variance(base_gold: int) -> int:
	var factor := randf_range(1.0 - GOLD_VARIANCE, 1.0 + GOLD_VARIANCE)
	return maxi(1, int(round(float(base_gold) * factor)))


func try_drop_item(enemy_level: int) -> ItemData:
	if randf() > DROP_CHANCE:
		return null
	return ItemDatabase.generate_random_item(enemy_level)
