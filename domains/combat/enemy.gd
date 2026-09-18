class_name Enemy
extends RefCounted
## Idle combat enemy. Dies at zero HP and grants gold/XP rewards.

var nome: String = "Inimigo"
var vida_maxima: int = 20
var vida_atual: int = 20
var dano: int = 3
var ouro_recompensa: int = 3
var xp_recompensa: int = 5


func configure(p_nome: String, p_vida: int, p_ouro: int, p_xp: int, p_dano: int = 1) -> void:
	nome = p_nome
	vida_maxima = max(1, p_vida)
	vida_atual = vida_maxima
	dano = max(1, p_dano)
	ouro_recompensa = max(0, p_ouro)
	xp_recompensa = max(0, p_xp)


## Applies damage and returns true if the enemy died on this hit.
func take_damage(amount: int) -> bool:
	vida_atual = max(0, vida_atual - max(0, amount))
	return is_dead()


func is_dead() -> bool:
	return vida_atual <= 0


func hp_text() -> String:
	return "%s  %d / %d" % [nome, vida_atual, vida_maxima]
