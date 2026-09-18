class_name SkillResource
extends Resource
## Skill data (active or passive).

enum Type { ACTIVE, PASSIVE }

@export var skill_id: String = ""
@export var skill_name: String = ""
@export var description: String = ""
@export var name_key: String = ""
@export var description_key: String = ""
@export var type: Type = Type.ACTIVE
@export var cooldown: float = 0.0
@export var icon_path: String = ""
## Quando true, icon_path é só a arte interna e a moldura ativa é composta em runtime.
@export var icon_inner_only: bool = false
@export var sort_order: int = 0
@export var stat_value: float = 0.0


func get_display_name() -> String:
	if name_key != "":
		var translated := tr(name_key)
		if translated != name_key:
			return translated
	return skill_name


func get_description() -> String:
	if description_key != "":
		var translated := tr(description_key)
		if translated != description_key:
			return translated
	return description


func type_text() -> String:
	return tr(LocaleKeys.SKILL_TYPE_ACTIVE) if type == Type.ACTIVE else tr(LocaleKeys.SKILL_TYPE_PASSIVE)


func button_text() -> String:
	return "%s\n%s" % [get_display_name(), type_text()]


func get_icon() -> Texture2D:
	return SkillIcons.get_icon(self)


func type_cooldown_line() -> String:
	if type == Type.PASSIVE:
		return tr(LocaleKeys.SKILL_TYPE_PASSIVE)
	if cooldown <= 0.0:
		return tr(LocaleKeys.SKILL_TYPE_ACTIVE)
	return tr(LocaleKeys.SKILL_COOLDOWN_LINE) % cooldown


func tooltip_text() -> String:
	return "%s\n%s\n\n%s" % [get_display_name(), type_cooldown_line(), get_description()]
