class_name SkillResource
extends Resource
## Dados de uma habilidade (ativa ou passiva).

enum Type { ACTIVE, PASSIVE }

@export var skill_name: String = ""
@export var description: String = ""
@export var type: Type = Type.ACTIVE
@export var cooldown: float = 0.0
@export var stat_value: float = 0.0


func tipo_texto() -> String:
	return "Ativa" if type == Type.ACTIVE else "Passiva"


func texto_botao() -> String:
	return "%s\n%s" % [skill_name, tipo_texto()]
