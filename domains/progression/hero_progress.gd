class_name HeroProgress
extends RefCounted
## Per-class hero level and XP tracking.

const BASE_XP_PER_LEVEL := 300
const XP_GROWTH := 1.43
const SLOTS := 3

var _by_class: Dictionary = {}


func _init() -> void:
	for class_data in ClassData.catalog():
		_by_class[class_data.id] = _empty_slot()


static func xp_for_next_level(level: int) -> int:
	return maxi(1, int(BASE_XP_PER_LEVEL * pow(XP_GROWTH, float(maxi(1, level) - 1))))


func class_id_at_slot(slot_index: int, active_party: Array) -> String:
	if slot_index < 0 or slot_index >= active_party.size():
		return ""
	var class_data: Variant = active_party[slot_index]
	if class_data is ClassData:
		return (class_data as ClassData).id
	return ""


func get_by_class(class_id: String) -> Dictionary:
	if class_id == "":
		return _empty_slot()
	if not _by_class.has(class_id):
		_by_class[class_id] = _empty_slot()
	return _by_class[class_id]


func get_level_at_slot(slot_index: int, active_party: Array) -> int:
	var class_id := class_id_at_slot(slot_index, active_party)
	if class_id == "":
		return 1
	return maxi(1, int(get_by_class(class_id)["nivel"]))


func at_index(slot_index: int, active_party: Array) -> Dictionary:
	var class_id := class_id_at_slot(slot_index, active_party)
	if class_id == "":
		return _empty_slot()
	return get_by_class(class_id).duplicate()


func apply_xp(amount: int, active_party: Array) -> PackedInt32Array:
	var levels := PackedInt32Array()
	levels.resize(SLOTS)
	for slot_index in SLOTS:
		levels[slot_index] = get_level_at_slot(slot_index, active_party)
		var class_id := class_id_at_slot(slot_index, active_party)
		if class_id == "":
			continue
		var progress: Dictionary = get_by_class(class_id)
		progress["xp"] = int(progress["xp"]) + amount
		while int(progress["xp"]) >= int(progress["xp_proximo"]) and int(progress["xp_proximo"]) > 0:
			progress["xp"] = int(progress["xp"]) - int(progress["xp_proximo"])
			progress["nivel"] = int(progress["nivel"]) + 1
			progress["xp_proximo"] = xp_for_next_level(int(progress["nivel"]))
		_by_class[class_id] = progress
		levels[slot_index] = int(progress["nivel"])
	return levels


func serialize() -> Dictionary:
	var data: Dictionary = {}
	for class_id in _by_class.keys():
		var progress: Dictionary = _by_class[class_id]
		data[class_id] = {
			"nivel": int(progress["nivel"]),
			"xp": int(progress["xp"]),
		}
	return data


func apply(data: Variant, party_class_ids: Array = []) -> void:
	if data is Dictionary:
		for class_id in data.keys():
			if not (data[class_id] is Dictionary):
				continue
			var entry: Dictionary = data[class_id]
			var level := maxi(1, int(entry.get("nivel", 1)))
			_by_class[str(class_id)] = {
				"nivel": level,
				"xp": maxi(0, int(entry.get("xp", 0))),
				"xp_proximo": xp_for_next_level(level),
			}
		return
	if not (data is Array):
		return
	for i in mini(data.size(), party_class_ids.size()):
		var class_id := str(party_class_ids[i])
		if class_id == "" or not (data[i] is Dictionary):
			continue
		var level := maxi(1, int(data[i].get("nivel", 1)))
		_by_class[class_id] = {
			"nivel": level,
			"xp": maxi(0, int(data[i].get("xp", 0))),
			"xp_proximo": xp_for_next_level(level),
		}


func _empty_slot() -> Dictionary:
	return {"nivel": 1, "xp": 0, "xp_proximo": BASE_XP_PER_LEVEL}
