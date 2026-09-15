class_name Inimigo
extends RefCounted
## Inimigo do combate idle. Morre ao zerar a vida e concede ouro/XP.

var nome: String = "Inimigo"
var vida_maxima: int = 20
var vida_atual: int = 20
var ouro_recompensa: int = 3
var xp_recompensa: int = 5


func configurar(p_nome: String, p_vida: int, p_ouro: int, p_xp: int) -> void:
	nome = p_nome
	vida_maxima = max(1, p_vida)
	vida_atual = vida_maxima
	ouro_recompensa = max(0, p_ouro)
	xp_recompensa = max(0, p_xp)


## Aplica dano e retorna true se o inimigo morreu neste golpe.
func tomar_dano(quantidade: int) -> bool:
	vida_atual = max(0, vida_atual - max(0, quantidade))
	return esta_morto()


func esta_morto() -> bool:
	return vida_atual <= 0


func texto_vida() -> String:
	return "%s  %d / %d" % [nome, vida_atual, vida_maxima]
