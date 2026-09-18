class_name SkillResource
extends Resource
## Dados de uma habilidade (ativa ou passiva).

enum Type { ACTIVE, PASSIVE }

@export var skill_id: String = ""
@export var skill_name: String = ""
@export var description: String = ""
@export var type: Type = Type.ACTIVE
@export var cooldown: float = 0.0
@export var icon_path: String = ""
@export var sort_order: int = 0
@export var stat_value: float = 0.0


func tipo_texto() -> String:
	return "Ativa" if type == Type.ACTIVE else "Passiva"


func texto_botao() -> String:
	return "%s\n%s" % [skill_name, tipo_texto()]


func obter_icone() -> Texture2D:
	return IconesSkill.obter(self)


func linha_tipo_cooldown() -> String:
	if type == Type.PASSIVE:
		return "Passiva"
	if cooldown <= 0.0:
		return "Ativa"
	return "Ativa | Recarga: %.1fs" % cooldown


func texto_tooltip() -> String:
	return "%s\n%s\n\n%s" % [skill_name, linha_tipo_cooldown(), description]
