class_name ActiveSkillRuntime
extends RefCounted
## Cooldown tracking and cast priority for equipped active skills.

const _EquipmentAccess := preload("res://domains/combat/hero_equipment_access.gd")

var _ready_at: Dictionary = {}


func try_cast(slot_index: int, class_id: String, cdr_pct: float = 0.0) -> SkillResource:
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
		notify_skill_cast(skill, cdr_pct)
		return skill
	return null


func notify_skill_cast(skill: SkillResource, cdr_pct: float = 0.0) -> void:
	if skill == null:
		return
	_start_cooldown(skill, cdr_pct, _now())


func remaining_cooldown(skill_id: String) -> float:
	var ready_at := float(_ready_at.get(skill_id, 0.0))
	return maxf(0.0, ready_at - _now())


func clear_cooldowns() -> void:
	_ready_at.clear()


func reduce_all_cooldowns(flat_sec: float) -> void:
	if flat_sec <= 0.0:
		return
	var now := _now()
	for skill_id in _ready_at.keys():
		var ready_at := float(_ready_at[skill_id])
		_ready_at[skill_id] = maxf(now, ready_at - flat_sec)


func _is_ready(skill_id: String, now: float) -> bool:
	return float(_ready_at.get(skill_id, 0.0)) <= now


func _start_cooldown(skill: SkillResource, cdr_pct: float, now: float) -> void:
	var mult := cooldown_multiplier_from_pct(cdr_pct)
	var duration := maxf(0.0, skill.cooldown) * mult
	_ready_at[skill.skill_id] = now + duration


static func cooldown_multiplier_from_pct(cdr_pct: float) -> float:
	return maxf(0.1, 1.0 - maxf(0.0, cdr_pct) / 100.0)


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
