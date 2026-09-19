class_name ActiveSkillRuntime
extends RefCounted
## Cooldown tracking and cast priority for equipped active skills.

const _EquipmentAccess := preload("res://domains/combat/hero_equipment_access.gd")
const NIMBLE_HANDS_COOLDOWN_MULT := 0.85

var _ready_at: Dictionary = {}


func try_cast(slot_index: int, class_id: String) -> SkillResource:
	if class_id == "":
		return null
	var equipment: Node = _EquipmentAccess.get_service()
	if equipment == null:
		return null
	var now := _now()
	for active_slot in equipment.MAX_ACTIVE:
		var skill: SkillResource = equipment.get_equipped(
			class_id,
			SkillResource.Type.ACTIVE,
			active_slot
		)
		if skill == null or skill.effects.is_empty():
			continue
		if not _is_ready(skill.skill_id, now):
			continue
		notify_skill_cast(skill, class_id)
		return skill
	return null


func notify_skill_cast(skill: SkillResource, class_id: String) -> void:
	if skill == null:
		return
	_start_cooldown(skill, class_id, _now())


func remaining_cooldown(skill_id: String) -> float:
	var ready_at := float(_ready_at.get(skill_id, 0.0))
	return maxf(0.0, ready_at - _now())


func clear_cooldowns() -> void:
	_ready_at.clear()


func _is_ready(skill_id: String, now: float) -> bool:
	return float(_ready_at.get(skill_id, 0.0)) <= now


func _start_cooldown(skill: SkillResource, class_id: String, now: float) -> void:
	var duration := maxf(0.0, skill.cooldown) * _cooldown_multiplier(class_id)
	_ready_at[skill.skill_id] = now + duration


func _cooldown_multiplier(class_id: String) -> float:
	var equipment: Node = _EquipmentAccess.get_service()
	if equipment == null:
		return 1.0
	for slot_index in equipment.MAX_PASSIVE:
		var passive: SkillResource = equipment.get_equipped(
			class_id,
			SkillResource.Type.PASSIVE,
			slot_index
		)
		if passive != null and passive.skill_id == "nimble_hands":
			return NIMBLE_HANDS_COOLDOWN_MULT
	return 1.0


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
