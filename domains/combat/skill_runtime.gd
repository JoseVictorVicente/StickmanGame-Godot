class_name SkillRuntime
extends RefCounted
## Reads HeroEquipment passives and applies SkillResource stat_value bonuses.

const STAT_KEY_ATTACK := "ataque"
const STAT_KEY_ATTACK_SPEED := "vel_ataque"
const STAT_KEY_CRIT_CHANCE := "crit_chance"
const STAT_KEY_CRIT_DAMAGE := "crit_dano"
const STAT_KEY_HP := "vida"


func bonuses_for_class(class_id: String) -> Dictionary:
	var bonus := SkillTreeDefinition.bonus_vazio()
	if class_id == "":
		return bonus
	for slot_index in HeroEquipment.MAX_PASSIVE:
		var skill: SkillResource = HeroEquipment.get_equipped(
			class_id,
			SkillResource.Type.PASSIVE,
			slot_index
		)
		if skill != null:
			apply_passive(bonus, skill)
	return bonus


static func apply_passive(bonus: Dictionary, skill: SkillResource) -> void:
	if skill == null or skill.type != SkillResource.Type.PASSIVE:
		return
	if skill.stat_value == 0.0:
		return
	var key := stat_key_for_skill(skill)
	bonus[key] = float(bonus.get(key, 0.0)) + skill.stat_value


static func stat_key_for_skill(skill: SkillResource) -> String:
	var skill_id := skill.skill_id.to_lower()
	if "vel" in skill_id or "ritmo" in skill_id or "agil" in skill_id:
		return STAT_KEY_ATTACK_SPEED
	if "crit" in skill_id or "precis" in skill_id or "execu" in skill_id:
		return STAT_KEY_CRIT_CHANCE
	if "vida" in skill_id or "vigor" in skill_id or "casca" in skill_id or "resist" in skill_id:
		return STAT_KEY_HP
	if "dano" in skill_id or "forca" in skill_id or "lamina" in skill_id:
		return STAT_KEY_ATTACK
	return STAT_KEY_ATTACK


static func merge_into(target: Dictionary, source: Dictionary) -> void:
	for key in source.keys():
		target[key] = float(target.get(key, 0.0)) + float(source.get(key, 0.0))
