class_name WorldProgress
extends RefCounted
## World/stage progression rules: 5 worlds, 9 stages, 3 difficulties.

enum Difficulty { EASY, HARD, HELL }

const TOTAL_MUNDOS := 5
const FASES_POR_MUNDO := 9
const TOTAL_FASES := TOTAL_MUNDOS * FASES_POR_MUNDO
const PROGRESSO_COMPLETO := TOTAL_FASES + 1
const _DIFFICULTY_KEYS: PackedStringArray = [
	LocaleKeys.DIFFICULTY_EASY,
	LocaleKeys.DIFFICULTY_HARD,
	LocaleKeys.DIFFICULTY_HELL,
]
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


static func stage_index(world: int, stage: int) -> int:
	var m := clampi(world, 1, TOTAL_MUNDOS)
	var f := clampi(stage, 1, FASES_POR_MUNDO)
	return (m - 1) * FASES_POR_MUNDO + f


static func world_from_index(valor: int) -> int:
	return clampi(int((clampi(valor, 1, TOTAL_FASES) - 1) / float(FASES_POR_MUNDO)) + 1, 1, TOTAL_MUNDOS)


static func stage_from_index(valor: int) -> int:
	return ((clampi(valor, 1, TOTAL_FASES) - 1) % FASES_POR_MUNDO) + 1


static func next_stage(world: int, stage: int) -> Vector2i:
	var atual := stage_index(world, stage)
	if atual >= TOTAL_FASES:
		return Vector2i(TOTAL_MUNDOS, FASES_POR_MUNDO)
	var seguinte := atual + 1
	return Vector2i(world_from_index(seguinte), stage_from_index(seguinte))


static func difficulty_name(value: int) -> String:
	var i := clampi(value, 0, _DIFFICULTY_KEYS.size() - 1)
	return TranslationServer.translate(_DIFFICULTY_KEYS[i])


static func is_difficulty_completed(progress_value: int) -> bool:
	return progress_value >= PROGRESSO_COMPLETO


static func is_difficulty_unlocked(difficulty: int, liberadas: Array) -> bool:
	if difficulty <= int(Difficulty.EASY):
		return true
	var anterior := difficulty - 1
	if anterior < 0 or anterior >= liberadas.size():
		return false
	return is_difficulty_completed(int(liberadas[anterior]))


static func apply_stage_completion(progress_value: int, world: int, stage: int) -> int:
	var atual := stage_index(world, stage)
	if atual >= TOTAL_FASES:
		return maxi(progress_value, PROGRESSO_COMPLETO)
	var seguinte := next_stage(world, stage)
	return maxi(progress_value, stage_index(seguinte.x, seguinte.y))


static func challenge_curve(nivel: int) -> float:
	var n := float(maxi(1, nivel))
	return pow(1.0 + n / HP_ESCALA, HP_EXPONENTE)


static func reward_curve(nivel: int) -> float:
	var n := float(maxi(1, nivel))
	return pow(1.0 + n / RECOMP_ESCALA, RECOMP_EXPONENTE)


static func world_multiplier(world: int) -> float:
	return pow(HP_MULT_MUNDO, float(maxi(1, world) - 1))


static func enemy_stats(world: int, stage: int, difficulty: int) -> Dictionary:
	var nivel := stage_index(world, stage)
	var mult: float = MULTIPLICADORES[clampi(difficulty, 0, MULTIPLICADORES.size() - 1)]
	var chefe_vida := CHEFE_VIDA if stage == FASES_POR_MUNDO else 1.0
	var chefe_dano := CHEFE_DANO if stage == FASES_POR_MUNDO else 1.0
	var mundo_mult := world_multiplier(world)
	var desafio := challenge_curve(nivel)
	var recomp := reward_curve(nivel)
	var recomp_mundo := pow(mundo_mult, 0.35)
	var vida := HP_BASE * desafio * mult * chefe_vida * mundo_mult
	var dano := DANO_BASE * pow(1.0 + float(nivel) / DANO_ESCALA, DANO_EXPONENTE) * mult * chefe_dano * sqrt(mundo_mult)
	var ouro := 4.0 * recomp * mult * recomp_mundo
	var xp := 6.0 * recomp * mult * 1.15 * recomp_mundo
	return {
		"nome": "Monstro %d-%d" % [world, stage],
		"rotulo": "%d-%d" % [world, stage],
		"vida": maxi(1, int(round(vida))),
		"dano": maxi(1, int(round(dano))),
		"ouro": maxi(1, int(round(ouro))),
		"xp": maxi(1, int(round(xp))),
		"nivel": nivel,
	}
