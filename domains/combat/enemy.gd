class_name Enemy
extends RefCounted
## Idle combat enemy. Dies at zero HP and grants gold/XP rewards.

var nome: String = "Inimigo"
var max_hp: int = 20
var current_hp: int = 20
var dano: int = 3
var gold_reward: int = 3
var xp_reward: int = 5


func configure(p_nome: String, p_hp: int, p_gold: int, p_xp: int, p_dano: int = 1) -> void:
	nome = p_nome
	max_hp = max(1, p_hp)
	current_hp = max_hp
	dano = max(1, p_dano)
	gold_reward = max(0, p_gold)
	xp_reward = max(0, p_xp)


## Applies damage and returns true if the enemy died on this hit.
func take_damage(amount: int) -> bool:
	current_hp = max(0, current_hp - max(0, amount))
	return is_dead()


func is_dead() -> bool:
	return current_hp <= 0


func hp_text() -> String:
	return "%s  %d / %d" % [nome, current_hp, max_hp]
