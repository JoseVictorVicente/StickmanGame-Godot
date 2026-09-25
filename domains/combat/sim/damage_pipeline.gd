class_name DamagePipeline
extends RefCounted
## Single-pass damage application for combat simulation.


static func apply_enemy_damage(enemy: Enemy, amount: int) -> Dictionary:
	if enemy == null:
		return {"applied": false}
	var died := enemy.take_damage(amount)
	return {
		"applied": true,
		"died": died,
		"hp": enemy.current_hp,
		"max_hp": enemy.max_hp,
	}


static func apply_hero_damage(
	slot: int,
	raw_damage: int,
	current_hp: int,
	stats: Dictionary
) -> Dictionary:
	if slot < 0 or current_hp <= 0:
		return {"damage": 0, "evaded": false, "hp": current_hp}
	var mitigation := CombatMath.mitigate_damage(
		raw_damage,
		float(stats.get("evasion", 0.0)),
		float(stats.get("phys_res", 0.0)),
		float(stats.get("arcane_res", 0.0)),
		float(stats.get("elemental_res", 0.0))
	)
	var received := int(mitigation.get("damage", 0))
	var hp := maxi(0, current_hp - received)
	return {
		"damage": received,
		"evaded": bool(mitigation.get("evaded", false)),
		"hp": hp,
	}
