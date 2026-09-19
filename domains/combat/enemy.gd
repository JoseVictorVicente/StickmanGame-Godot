class_name Enemy
extends RefCounted
## Idle combat enemy. Dies at zero HP and grants gold/XP rewards.

var display_name: String = "Enemy"
var max_hp: int = 20
var current_hp: int = 20
var damage: int = 3
var gold_reward: int = 3
var xp_reward: int = 5


func configure(p_display_name: String, p_hp: int, p_gold: int, p_xp: int, p_damage: int = 1) -> void:
	display_name = p_display_name
	max_hp = max(1, p_hp)
	current_hp = max_hp
	damage = max(1, p_damage)
	gold_reward = max(0, p_gold)
	xp_reward = max(0, p_xp)


## Applies damage and returns true if the enemy died on this hit.
func take_damage(amount: int) -> bool:
	current_hp = max(0, current_hp - max(0, amount))
	return is_dead()


func is_dead() -> bool:
	return current_hp <= 0


func hp_text() -> String:
	return "%s  %d / %d" % [display_name, current_hp, max_hp]
