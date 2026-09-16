class_name ArcherSkills
extends Node
## Habilidades ativas e passivas do Arqueiro.

signal skill_used(skill_name: String)
signal cooldown_updated(skill_name: String, time_left: float, max_time: float)

const SKILL_VERDANT_RAIN := "Verdant Rain"
const SKILL_SOULSEEKER_SHOT := "Soulseeker Shot"
const SKILL_PHANTOM_QUIVER := "Phantom Quiver"
const SKILL_GALE_PRECISION := "Gale Precision"

const COOLDOWN_VERDANT_RAIN := 6.0
const COOLDOWN_SOULSEEKER_SHOT := 4.0
const PHANTOM_QUIVER_ATTACK_SPEED_BONUS := 0.15
const GALE_PRECISION_CRIT_BONUS := 0.10

var _maximo: Dictionary = {}
var _timers: Dictionary = {}


func _ready() -> void:
	_configurar_ativa(SKILL_VERDANT_RAIN, COOLDOWN_VERDANT_RAIN)
	_configurar_ativa(SKILL_SOULSEEKER_SHOT, COOLDOWN_SOULSEEKER_SHOT)


func _process(_delta: float) -> void:
	for nome in _timers.keys():
		var timer: Timer = _timers[nome]
		if timer.time_left <= 0.0:
			continue
		cooldown_updated.emit(nome, timer.time_left, float(_maximo[nome]))


func cast_verdant_rain() -> bool:
	if not _pode_usar(SKILL_VERDANT_RAIN):
		return false
	print("Verdant Rain ativada!")
	# TODO: animação de conjuração do Arqueiro (ex.: levantar o arco para cima).
	# TODO: VFX de chuva de flechas verdes em área no alvo/inimigo.
	_iniciar_cooldown(SKILL_VERDANT_RAIN)
	skill_used.emit(SKILL_VERDANT_RAIN)
	return true


func cast_soulseeker_shot() -> bool:
	if not _pode_usar(SKILL_SOULSEEKER_SHOT):
		return false
	print("Soulseeker Shot ativada!")
	# TODO: animação de tiro carregado / pose de mira prolongada.
	# TODO: VFX de flecha perfurante (trail + impacto em linha reta).
	_iniciar_cooldown(SKILL_SOULSEEKER_SHOT)
	skill_used.emit(SKILL_SOULSEEKER_SHOT)
	return true


func multiplicador_velocidade_ataque() -> float:
	## Phantom Quiver: +15% na velocidade de ataque base.
	return 1.0 + PHANTOM_QUIVER_ATTACK_SPEED_BONUS


func bonus_chance_critico() -> float:
	## Gale Precision: +10% de chance crítica.
	return GALE_PRECISION_CRIT_BONUS


func esta_em_cooldown(skill_name: String) -> bool:
	return tempo_restante(skill_name) > 0.0


func tempo_restante(skill_name: String) -> float:
	if not _timers.has(skill_name):
		return 0.0
	return (_timers[skill_name] as Timer).time_left


func tempo_maximo(skill_name: String) -> float:
	return float(_maximo.get(skill_name, 0.0))


func _configurar_ativa(nome: String, duracao: float) -> void:
	_maximo[nome] = duracao
	var timer := Timer.new()
	timer.name = "Cooldown_%s" % nome
	timer.one_shot = true
	timer.timeout.connect(_on_cooldown_terminou.bind(nome))
	add_child(timer)
	_timers[nome] = timer


func _pode_usar(nome: String) -> bool:
	return not esta_em_cooldown(nome)


func _iniciar_cooldown(nome: String) -> void:
	var duracao := float(_maximo.get(nome, 0.0))
	if duracao <= 0.0:
		return
	var timer: Timer = _timers[nome]
	timer.stop()
	timer.wait_time = duracao
	timer.start()
	cooldown_updated.emit(nome, duracao, duracao)


func _on_cooldown_terminou(nome: String) -> void:
	cooldown_updated.emit(nome, 0.0, float(_maximo.get(nome, 0.0)))
