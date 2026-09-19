class_name BuffContainer
extends RefCounted
## Timed combat buffs per party slot (merged into hero stats).

var _buffs: Array = []


func add_buff(slot_index: int, stat_key: String, stat_value: float, duration_sec: float) -> void:
	if slot_index < 0 or stat_key == "" or duration_sec <= 0.0 or stat_value == 0.0:
		return
	_buffs.append({
		"slot": slot_index,
		"stat_key": stat_key,
		"stat_value": stat_value,
		"expires_at": Time.get_ticks_msec() / 1000.0 + duration_sec,
	})


func tick(delta: float) -> bool:
	if _buffs.is_empty():
		return false
	var now := Time.get_ticks_msec() / 1000.0
	var antes := _buffs.size()
	_buffs = _buffs.filter(func(entry: Dictionary) -> bool:
		return float(entry.get("expires_at", 0.0)) > now
	)
	return _buffs.size() != antes


func active_bonuses(slot_index: int) -> Dictionary:
	var bonus := SkillTreeDefinition.empty_bonus()
	var now := Time.get_ticks_msec() / 1000.0
	for entry in _buffs:
		if int(entry.get("slot", -1)) != slot_index:
			continue
		if float(entry.get("expires_at", 0.0)) <= now:
			continue
		var key := str(entry.get("stat_key", ""))
		if key == "":
			continue
		bonus[key] = float(bonus.get(key, 0.0)) + float(entry.get("stat_value", 0.0))
	return StatCalculator.apply_bonus_caps(bonus)


func count_stacks(slot_index: int, stat_key: String) -> int:
	var count := 0
	var now := Time.get_ticks_msec() / 1000.0
	for entry in _buffs:
		if int(entry.get("slot", -1)) != slot_index:
			continue
		if str(entry.get("stat_key", "")) != stat_key:
			continue
		if float(entry.get("expires_at", 0.0)) <= now:
			continue
		count += 1
	return count


func add_buff_to_slots(slots: Array, stat_key: String, stat_value: float, duration_sec: float) -> void:
	for slot_value in slots:
		add_buff(int(slot_value), stat_key, stat_value, duration_sec)


func clear_slot(slot_index: int) -> void:
	_buffs = _buffs.filter(func(entry: Dictionary) -> bool:
		return int(entry.get("slot", -1)) != slot_index
	)


func clear_all() -> void:
	_buffs.clear()
