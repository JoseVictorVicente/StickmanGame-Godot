class_name StatCalculator
extends RefCounted
## Pure stat aggregation for a party slot (equipment + skill tree + gems).

var get_equipped_damage: Callable
var get_equipped_hp: Callable
var get_level: Callable
var get_skill_tree_bonus: Callable


func compute(slot_index: int, class_data: ClassData) -> Dictionary:
	if class_data == null:
		return _empty()
	var bonus := _skill_tree_bonus(slot_index)
	var level := _level(slot_index)
	var equip_damage := _equipped_damage(slot_index)
	var equip_hp := _equipped_hp(slot_index)
	var damage := _compute_damage(class_data, level, equip_damage, bonus)
	var hp := _compute_hp(class_data, level, equip_hp, bonus)
	return {
		"damage": damage,
		"hp": hp,
		"attack_speed_bonus": float(bonus.get("vel_ataque", 0.0)),
		"crit_chance": float(bonus.get("crit_chance", 0.0)),
		"gold_bonus": float(bonus.get("bonus_ouro", 0.0)),
		"xp_bonus": float(bonus.get("bonus_xp", 0.0)),
		"skill_tree_bonus": bonus,
	}


func compute_global_skill_tree_bonus() -> Dictionary:
	if get_skill_tree_bonus.is_valid():
		var result: Variant = get_skill_tree_bonus.call(-1)
		if result is Dictionary:
			return result
	return SkillTreeDefinition.empty_bonus()


static func _compute_damage(class_data: ClassData, level: int, equip_damage: int, bonus: Dictionary) -> int:
	var base := maxi(1, int(round(float(class_data.base_damage + equip_damage) * class_data.attack_multiplier)))
	base += (level - 1) * class_data.atk_per_level + int(bonus.get("ataque", 0))
	var pct := float(bonus.get("ataque_pct", 0.0))
	return maxi(1, int(round(float(base) * (1.0 + pct / 100.0))))


static func _compute_hp(class_data: ClassData, level: int, equip_hp: int, bonus: Dictionary) -> int:
	var base := maxi(1, class_data.base_hp + equip_hp + (level - 1) * class_data.hp_per_level + int(bonus.get("vida", 0)))
	var pct := float(bonus.get("vida_pct", 0.0))
	return maxi(1, int(round(float(base) * (1.0 + pct / 100.0))))


func _equipped_damage(slot_index: int) -> int:
	if get_equipped_damage.is_valid():
		return int(get_equipped_damage.call(slot_index))
	return 0


func _equipped_hp(slot_index: int) -> int:
	if get_equipped_hp.is_valid():
		return int(get_equipped_hp.call(slot_index))
	return 0


func _level(slot_index: int) -> int:
	if get_level.is_valid():
		return maxi(1, int(get_level.call(slot_index)))
	return 1


func _skill_tree_bonus(slot_index: int) -> Dictionary:
	if get_skill_tree_bonus.is_valid():
		var bonus: Variant = get_skill_tree_bonus.call(slot_index)
		if bonus is Dictionary:
			return bonus
	return SkillTreeDefinition.empty_bonus()


static func _empty() -> Dictionary:
	return {
		"damage": 0,
		"hp": 0,
		"attack_speed_bonus": 0.0,
		"crit_chance": 0.0,
		"gold_bonus": 0.0,
		"xp_bonus": 0.0,
		"skill_tree_bonus": SkillTreeDefinition.empty_bonus(),
	}
