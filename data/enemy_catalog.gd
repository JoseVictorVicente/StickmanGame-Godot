class_name EnemyCatalog
extends RefCounted
## Loads enemy .tres files and resolves spawn by world/stage/wave/role.

const ENEMIES_FOLDER := "res://data/enemies/"
const DEFAULT_ENEMY_ID := "imp_red"

const _WorldCatalog := preload("res://data/world_catalog.gd")

static var _entries: Array[EnemyData] = []
static var _by_id: Dictionary = {}
static var _loaded := false


static func ensure_loaded() -> void:
	if _loaded:
		return
	_entries.clear()
	_by_id.clear()
	_scan_dir(ENEMIES_FOLDER, _entries)
	for entry in _entries:
		if entry.enemy_id != "":
			_by_id[entry.enemy_id] = entry
	_loaded = true


static func all_entries() -> Array[EnemyData]:
	ensure_loaded()
	return _entries


static func get_by_id(enemy_id: String) -> EnemyData:
	ensure_loaded()
	return _by_id.get(enemy_id, null) as EnemyData


static func resolve_horde(world: int, stage: int, wave: int) -> EnemyData:
	ensure_loaded()
	var best: EnemyData = null
	var best_score := -1
	for entry in _entries:
		if entry.horde_count <= 1:
			continue
		if not entry.matches_spawn(world, stage, wave, EnemyData.SpawnRole.MINION):
			continue
		var score := entry.specificity_score(world)
		if score > best_score:
			best_score = score
			best = entry
	return best


static func resolve(world: int, stage: int, wave: int, role: EnemyData.SpawnRole) -> EnemyData:
	ensure_loaded()
	var best: EnemyData = null
	var best_score := -1
	for entry in _entries:
		if not entry.matches_spawn(world, stage, wave, role):
			continue
		var score := entry.specificity_score(world)
		if score > best_score:
			best_score = score
			best = entry
	if best != null:
		return best
	return get_by_id(DEFAULT_ENEMY_ID)


static func resolve_role_for_stage(stage: int, role: EnemyData.SpawnRole) -> EnemyData.SpawnRole:
	if _WorldCatalog.is_boss_stage(stage) and role == EnemyData.SpawnRole.MINION:
		return EnemyData.SpawnRole.BOSS
	return role


static func display_name(data: EnemyData, world: int) -> String:
	if data == null:
		return "Enemy"
	if data.use_demon_king_name:
		return _WorldCatalog.demon_king_name(world)
	if data.name_key != "":
		var translated := TranslationServer.translate(data.name_key)
		if translated != data.name_key:
			return translated
	return data.enemy_id if data.enemy_id != "" else "Enemy"


static func build_runtime(base_stats: Dictionary, data: EnemyData) -> Dictionary:
	if data == null:
		return base_stats.duplicate()
	return {
		"hp": maxi(1, int(round(float(base_stats.get("hp", 1)) * data.hp_mult))),
		"damage": maxi(1, int(round(float(base_stats.get("damage", 1)) * data.damage_mult))),
		"gold": maxi(0, int(round(float(base_stats.get("gold", 0)) * data.gold_mult))),
		"xp": maxi(0, int(round(float(base_stats.get("xp", 0)) * data.xp_mult))),
		"level": int(base_stats.get("level", 1)),
	}


static func reload_for_tests() -> void:
	_loaded = false
	ensure_loaded()


static func _scan_dir(path: String, lista: Array) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry_name := dir.get_next()
	while entry_name != "":
		var full_path := "%s/%s" % [path.trim_suffix("/"), entry_name]
		if dir.current_is_dir() and not entry_name.begins_with("."):
			_scan_dir(full_path, lista)
		elif entry_name.ends_with(".tres"):
			if ResourceLoader.exists(full_path):
				var resource: Resource = load(full_path)
				if resource is EnemyData:
					lista.append(resource)
		entry_name = dir.get_next()
	dir.list_dir_end()
