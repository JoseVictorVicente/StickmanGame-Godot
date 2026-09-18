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


func type_text() -> String:
	return "Ativa" if type == Type.ACTIVE else "Passiva"


func button_text() -> String:
	return "%s\n%s" % [skill_name, type_text()]


func get_icon() -> Texture2D:
	return SkillIcons.get_icon(self)


func type_cooldown_line() -> String:
	if type == Type.PASSIVE:
		return "Passiva"
	if cooldown <= 0.0:
		return "Ativa"
	return "Ativa | Recarga: %.1fs" % cooldown


func tooltip_text() -> String:
	return "%s\n%s\n\n%s" % [skill_name, type_cooldown_line(), description]
