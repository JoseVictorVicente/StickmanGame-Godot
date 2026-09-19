class_name SaveService
extends RefCounted
## Save/load with versioned schema and PT→EN key migration on read.

const SAVE_PATH := "user://save.cfg"
const AUTOSAVE_INTERVAL := 30.0
const SAVE_VERSION := 6

const _LEGACY_KEY_MAP := {
	"ouro": "gold",
	"world": "world",
	"stage": "stage",
	"difficulty": "difficulty",
	"unlocked_stages": "unlocked_stages",
	"repeat_stage": "repeat_stage",
	"wave": "wave",
	"personagem_atual": "active_character_index",
	"hero_progress": "progress",
	"inventario": "inventory",
	"armazem": "warehouse",
	"equipamentos": "equipment",
	"equipe": "party",
	"arvore": "skill_tree",
}


static func save_game(root: Node) -> void:
	if root == null or not is_instance_valid(root):
		return
	if not root.has_method("collect_save") and not root.has_method("collect_save"):
		return
	var payload: Dictionary
	if root.has_method("collect_save"):
		payload = root.collect_save()
	else:
		payload = root.collect_save()
	payload = normalize_keys(payload)
	var cfg := ConfigFile.new()
	if FileAccess.file_exists(SAVE_PATH):
		cfg.load(SAVE_PATH)
	cfg.set_value("game", "version", SAVE_VERSION)
	cfg.set_value("game", "gold", int(payload.get("gold", 0)))
	cfg.set_value("game", "wave", int(payload.get("wave", 1)))
	cfg.set_value("game", "world", int(payload.get("world", 1)))
	cfg.set_value("game", "stage", int(payload.get("stage", 1)))
	cfg.set_value("game", "difficulty", int(payload.get("difficulty", 0)))
	cfg.set_value("game", "unlocked_stages", JSON.stringify(payload.get("unlocked_stages", [1, 1, 1])))
	cfg.set_value("game", "repeat_stage", bool(payload.get("repeat_stage", false)))
	cfg.set_value("game", "active_character_index", int(payload.get("active_character_index", 0)))
	cfg.set_value("progress", "heroes", JSON.stringify(payload.get("progress", [])))
	cfg.set_value("inventory", "items", JSON.stringify(payload.get("inventory", [])))
	cfg.set_value("inventory", "warehouse", JSON.stringify(payload.get("warehouse", [])))
	cfg.set_value("equipment", "data", JSON.stringify(payload.get("equipment", [])))
	cfg.set_value("party", "data", JSON.stringify(payload.get("party", {})))
	cfg.set_value("skill_tree", "data", JSON.stringify(payload.get("skill_tree", [])))
	cfg.set_value("hero_equipment", "data", JSON.stringify(payload.get("hero_equipment", {})))
	var err := cfg.save(SAVE_PATH)
	if err != OK:
		push_warning("SaveService: failed to save: %s" % err)


static func load_game(root: Node) -> bool:
	if root == null or not is_instance_valid(root):
		return false
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return false
	var version := int(cfg.get_value("game", "version", cfg.get_value("jogo", "versao", 0)))
	if version < 1:
		_clear_progress(cfg)
		return false
	var payload := _build_payload_from_config(cfg, version)
	payload = normalize_keys(payload)
	payload = migrate_domain_ids(payload)
	if version < 3:
		payload["skill_tree"] = []
	if version < 4:
		payload["hero_equipment"] = {}
	if version < 5:
		payload = _migrate_schema_v5(payload)
	if version < 6:
		payload = _migrate_schema_v6(payload)
	if root.has_method("apply_from_save"):
		root.apply_from_save(payload)
		return true
	return false


static func normalize_keys(data: Dictionary) -> Dictionary:
	var result := {}
	for key in data.keys():
		var normalized := str(_LEGACY_KEY_MAP.get(str(key), key))
		result[normalized] = data[key]
	return result


static func migrate_domain_ids(payload: Dictionary) -> Dictionary:
	var migrated := payload.duplicate(true)
	var party: Variant = migrated.get("party", {})
	if party is Dictionary:
		migrated["party"] = _migrate_party_ids(party)
	var equipment: Variant = migrated.get("equipment", {})
	if equipment is Dictionary:
		migrated["equipment"] = _migrate_equipment_keys(equipment)
	var hero_equipment: Variant = migrated.get("hero_equipment", {})
	if hero_equipment is Dictionary:
		migrated["hero_equipment"] = _migrate_hero_equipment_ids(hero_equipment)
	migrated["inventory"] = _migrate_item_list(migrated.get("inventory", []))
	migrated["warehouse"] = _migrate_warehouse(migrated.get("warehouse", []))
	migrated["equipment"] = _migrate_equipment_items(migrated.get("equipment", {}))
	return migrated


static func _migrate_party_ids(party: Dictionary) -> Dictionary:
	var result := party.duplicate(true)
	for field in ["classes", "unlocked"]:
		var lista: Variant = result.get(field, [])
		if lista is Array:
			var normalized: Array = []
			for entry in lista:
				normalized.append(ClassData.normalize_id(str(entry)))
			result[field] = normalized
	return result


static func _migrate_equipment_keys(data: Dictionary) -> Dictionary:
	var result := {}
	for key in data.keys():
		result[ClassData.normalize_id(str(key))] = data[key]
	return result


static func _migrate_schema_v5(payload: Dictionary) -> Dictionary:
	var migrated := payload.duplicate(true)
	migrated["progress"] = _migrate_progress_dict(migrated.get("progress", {}))
	var party: Variant = migrated.get("party", {})
	if party is Dictionary:
		migrated["party"] = _migrate_party_runtime_keys(party)
	return migrated


static func _migrate_progress_dict(progress: Variant) -> Variant:
	if progress is Dictionary:
		var result := {}
		for class_id in progress.keys():
			var entry: Variant = progress[class_id]
			if entry is Dictionary:
				result[class_id] = _migrate_progress_entry(entry)
			else:
				result[class_id] = entry
		return result
	if progress is Array:
		var result: Array = []
		for entry in progress:
			if entry is Dictionary:
				result.append(_migrate_progress_entry(entry))
			else:
				result.append(entry)
		return result
	return progress


static func _migrate_progress_entry(entry: Dictionary) -> Dictionary:
	var result := entry.duplicate(true)
	if result.has("nivel") and not result.has("level"):
		result["level"] = result["nivel"]
	if result.has("xp_proximo") and not result.has("xp_next"):
		result["xp_next"] = result["xp_proximo"]
	return result


static func _migrate_party_runtime_keys(party: Dictionary) -> Dictionary:
	var result := party.duplicate(true)
	if result.has("desbloqueadas") and not result.has("unlocked"):
		result["unlocked"] = result["desbloqueadas"]
	return result


static func _migrate_schema_v6(payload: Dictionary) -> Dictionary:
	var migrated := payload.duplicate(true)
	migrated["warehouse"] = _migrate_warehouse_schema(migrated.get("warehouse", {}))
	migrated["equipment"] = _migrate_equipment_slot_types(migrated.get("equipment", {}))
	return migrated


static func _migrate_warehouse_schema(warehouse: Variant) -> Variant:
	if warehouse is Dictionary:
		var result: Dictionary = warehouse.duplicate(true)
		if result.has("abas") and not result.has("tabs"):
			result["tabs"] = result["abas"]
		return result
	return warehouse


static func _migrate_equipment_slot_types(equipment: Variant) -> Variant:
	if not (equipment is Dictionary):
		return equipment
	var result := {}
	for class_key in equipment.keys():
		var slots: Variant = equipment[class_key]
		if slots is Array:
			var migrated_slots: Array = []
			for slot in slots:
				if slot is Dictionary:
					migrated_slots.append(_migrate_equipment_slot_entry(slot))
				else:
					migrated_slots.append(slot)
			result[class_key] = migrated_slots
		else:
			result[class_key] = slots
	return result


static func _migrate_equipment_slot_entry(entry: Dictionary) -> Dictionary:
	var result := entry.duplicate(true)
	if result.has("tipo") and not result.has("type"):
		result["type"] = result["tipo"]
	return result


static func _migrate_hero_equipment_ids(data: Dictionary) -> Dictionary:
	var result := {}
	for raw_class_id in data.keys():
		var class_id := ClassData.normalize_id(str(raw_class_id))
		var loadout: Variant = data[raw_class_id]
		if not (loadout is Dictionary):
			continue
		result[class_id] = {
			"actives": _migrate_skill_id_list(loadout.get("actives", [])),
			"passives": _migrate_skill_id_list(loadout.get("passives", [])),
		}
	return result


static func _migrate_skill_id_list(ids: Variant) -> Array:
	var result: Array = []
	if not (ids is Array):
		return result
	for skill_id in ids:
		result.append(IdMigration.migrate_skill_id(str(skill_id)))
	return result


static func _migrate_item_list(items: Variant) -> Variant:
	if not (items is Array):
		return items
	var result: Array = []
	for entry in items:
		if entry is Dictionary and not entry.is_empty():
			result.append(_migrate_item_dict(entry))
		else:
			result.append(entry)
	return result


static func _migrate_warehouse(warehouse: Variant) -> Variant:
	if warehouse is Array:
		var tabs: Array = []
		for tab in warehouse:
			if tab is Array:
				tabs.append(_migrate_item_list(tab))
			else:
				tabs.append(tab)
		return tabs
	if warehouse is Dictionary:
		var result := {}
		for key in warehouse.keys():
			result[key] = _migrate_item_list(warehouse[key])
		return result
	return warehouse


static func _migrate_equipment_items(equipment: Variant) -> Variant:
	if not (equipment is Dictionary):
		return equipment
	var result := {}
	for class_id in equipment.keys():
		var slots: Variant = equipment[class_id]
		if slots is Array:
			var migrated_slots: Array = []
			for slot in slots:
				if slot is Dictionary and not slot.is_empty():
					migrated_slots.append(_migrate_item_dict(slot))
				else:
					migrated_slots.append(slot)
			result[class_id] = migrated_slots
		else:
			result[class_id] = slots
	return result


static func _migrate_item_dict(item_dict: Dictionary) -> Dictionary:
	var result := item_dict.duplicate(true)
	if result.has("id"):
		result["id"] = IdMigration.migrate_item_id(str(result["id"]))
	return result


static func _build_payload_from_config(cfg: ConfigFile, version: int) -> Dictionary:
	var use_legacy := cfg.has_section("jogo")
	if use_legacy:
		return {
			"gold": int(cfg.get_value("jogo", "ouro", 0)),
			"wave": int(cfg.get_value("jogo", "wave", 1)),
			"world": int(cfg.get_value("jogo", "world", 1)),
			"stage": int(cfg.get_value("jogo", "stage", 1)),
			"difficulty": int(cfg.get_value("jogo", "difficulty", 0)),
			"unlocked_stages": _parse_json(str(cfg.get_value("jogo", "unlocked_stages", "[1,1,1]")), [1, 1, 1]),
			"repeat_stage": bool(cfg.get_value("jogo", "repeat_stage", false)),
			"active_character_index": int(cfg.get_value("jogo", "personagem_atual", 0)),
			"progress": _parse_json(str(cfg.get_value("hero_progress", "personagens", "[]")), []),
			"inventory": _parse_json(str(cfg.get_value("inventario", "itens", "[]")), []),
			"warehouse": _parse_json(str(cfg.get_value("inventario", "armazem", "[]")), []),
			"equipment": _parse_json(str(cfg.get_value("equipamentos", "dados", "[]")), []),
			"party": _parse_json(str(cfg.get_value("equipe", "dados", "{}")), {}),
			"skill_tree": _parse_json(str(cfg.get_value("arvore", "dados", "[]")), []) if version >= 3 else [],
			"hero_equipment": _parse_json(str(cfg.get_value("hero_equipment", "data", "{}")), {}) if version >= 4 else {},
		}
	return {
		"gold": int(cfg.get_value("game", "gold", 0)),
		"wave": int(cfg.get_value("game", "wave", 1)),
		"world": int(cfg.get_value("game", "world", 1)),
		"stage": int(cfg.get_value("game", "stage", 1)),
		"difficulty": int(cfg.get_value("game", "difficulty", 0)),
		"unlocked_stages": _parse_json(str(cfg.get_value("game", "unlocked_stages", "[1,1,1]")), [1, 1, 1]),
		"repeat_stage": bool(cfg.get_value("game", "repeat_stage", false)),
		"active_character_index": int(cfg.get_value("game", "active_character_index", 0)),
		"progress": _parse_json(str(cfg.get_value("progress", "heroes", "[]")), []),
		"inventory": _parse_json(str(cfg.get_value("inventory", "items", "[]")), []),
		"warehouse": _parse_json(str(cfg.get_value("inventory", "warehouse", "[]")), []),
		"equipment": _parse_json(str(cfg.get_value("equipment", "data", "[]")), []),
		"party": _parse_json(str(cfg.get_value("party", "data", "{}")), {}),
		"skill_tree": _parse_json(str(cfg.get_value("skill_tree", "data", "[]")), []),
		"hero_equipment": _parse_json(str(cfg.get_value("hero_equipment", "data", "{}")), {}),
	}


static func _to_legacy_payload(data: Dictionary) -> Dictionary:
	var legacy := {}
	for key in data.keys():
		var found := false
		for pt_key in _LEGACY_KEY_MAP.keys():
			if _LEGACY_KEY_MAP[pt_key] == key:
				legacy[pt_key] = data[key]
				found = true
				break
		if not found:
			legacy[key] = data[key]
	return legacy


static func _parse_json(text: String, default_value: Variant) -> Variant:
	var parsed: Variant = JSON.parse_string(text)
	return parsed if parsed != null else default_value


static func _clear_progress(cfg: ConfigFile) -> void:
	for section in ["game", "jogo", "progress", "hero_progress", "inventory", "inventario", "equipment", "equipamentos", "party", "equipe", "skill_tree", "arvore", "hero_equipment"]:
		if cfg.has_section(section):
			cfg.erase_section(section)
	cfg.set_value("game", "version", SAVE_VERSION)
	cfg.save(SAVE_PATH)
