class_name ProgressaoMundos
extends RefCounted
## Regras da progressão: 5 mundos, 9 fases e 3 dificuldades.

enum Dificuldade { FACIL, DIFICIL, INFERNO }

const TOTAL_MUNDOS := 5
const FASES_POR_MUNDO := 9
const TOTAL_FASES := TOTAL_MUNDOS * FASES_POR_MUNDO
const PROGRESSO_COMPLETO := TOTAL_FASES + 1
const NOMES_DIFICULDADE: PackedStringArray = ["Fácil", "Difícil", "Inferno"]
const MULTIPLICADORES: Array[float] = [1.0, 1.8, 3.2]
## Curva em S: início acessível, endgame exige farm prolongado.
const HP_BASE := 22.0
const HP_ESCALA := 7.0
const HP_EXPONENTE := 1.52
const HP_MULT_MUNDO := 1.20
const RECOMP_ESCALA := 11.0
const RECOMP_EXPONENTE := 1.10
const DANO_BASE := 3.0
const DANO_ESCALA := 9.0
const DANO_EXPONENTE := 1.22
const CHEFE_VIDA := 1.70
const CHEFE_DANO := 1.35
const POSICOES_FASES: Array[Vector2] = [
	Vector2(0.18, 0.88),
	Vector2(0.42, 0.80),
	Vector2(0.70, 0.70),
	Vector2(0.82, 0.50),
	Vector2(0.54, 0.46),
	Vector2(0.28, 0.40),
	Vector2(0.22, 0.26),
	Vector2(0.50, 0.24),
	Vector2(0.42, 0.14),
]


static func indice(mundo: int, fase: int) -> int:
	var m := clampi(mundo, 1, TOTAL_MUNDOS)
	var f := clampi(fase, 1, FASES_POR_MUNDO)
	return (m - 1) * FASES_POR_MUNDO + f


static func mundo_de(valor: int) -> int:
	return clampi(int((clampi(valor, 1, TOTAL_FASES) - 1) / float(FASES_POR_MUNDO)) + 1, 1, TOTAL_MUNDOS)


static func fase_de(valor: int) -> int:
	return ((clampi(valor, 1, TOTAL_FASES) - 1) % FASES_POR_MUNDO) + 1


static func proximo(mundo: int, fase: int) -> Vector2i:
	var atual := indice(mundo, fase)
	if atual >= TOTAL_FASES:
		return Vector2i(TOTAL_MUNDOS, FASES_POR_MUNDO)
	var seguinte := atual + 1
	return Vector2i(mundo_de(seguinte), fase_de(seguinte))


static func nome_dificuldade(valor: int) -> String:
	var i := clampi(valor, 0, NOMES_DIFICULDADE.size() - 1)
	return NOMES_DIFICULDADE[i]


static func dificuldade_concluida(progresso: int) -> bool:
	return progresso >= PROGRESSO_COMPLETO


static func dificuldade_liberada(dificuldade: int, liberadas: Array) -> bool:
	if dificuldade <= int(Dificuldade.FACIL):
		return true
	var anterior := dificuldade - 1
	if anterior < 0 or anterior >= liberadas.size():
		return false
	return dificuldade_concluida(int(liberadas[anterior]))


static func aplicar_conclusao(progresso: int, mundo: int, fase: int) -> int:
	var atual := indice(mundo, fase)
	if atual >= TOTAL_FASES:
		return maxi(progresso, PROGRESSO_COMPLETO)
	var seguinte := proximo(mundo, fase)
	return maxi(progresso, indice(seguinte.x, seguinte.y))


static func curva_desafio(nivel: int) -> float:
	var n := float(maxi(1, nivel))
	return pow(1.0 + n / HP_ESCALA, HP_EXPONENTE)


static func curva_recompensa(nivel: int) -> float:
	var n := float(maxi(1, nivel))
	return pow(1.0 + n / RECOMP_ESCALA, RECOMP_EXPONENTE)


static func mult_mundo(mundo: int) -> float:
	return pow(HP_MULT_MUNDO, float(maxi(1, mundo) - 1))


static func stats_inimigo(mundo: int, fase: int, dificuldade: int) -> Dictionary:
	var nivel := indice(mundo, fase)
	var mult: float = MULTIPLICADORES[clampi(dificuldade, 0, MULTIPLICADORES.size() - 1)]
	var chefe_vida := CHEFE_VIDA if fase == FASES_POR_MUNDO else 1.0
	var chefe_dano := CHEFE_DANO if fase == FASES_POR_MUNDO else 1.0
	var mundo_mult := mult_mundo(mundo)
	var desafio := curva_desafio(nivel)
	var recomp := curva_recompensa(nivel)
	var recomp_mundo := pow(mundo_mult, 0.35)
	var vida := HP_BASE * desafio * mult * chefe_vida * mundo_mult
	var dano := DANO_BASE * pow(1.0 + float(nivel) / DANO_ESCALA, DANO_EXPONENTE) * mult * chefe_dano * sqrt(mundo_mult)
	var ouro := 4.0 * recomp * mult * recomp_mundo
	var xp := 6.0 * recomp * mult * 1.15 * recomp_mundo
	return {
		"nome": "Monstro %d-%d" % [mundo, fase],
		"rotulo": "%d-%d" % [mundo, fase],
		"vida": maxi(1, int(round(vida))),
		"dano": maxi(1, int(round(dano))),
		"ouro": maxi(1, int(round(ouro))),
		"xp": maxi(1, int(round(xp))),
		"nivel": nivel,
	}
