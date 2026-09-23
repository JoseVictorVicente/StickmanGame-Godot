extends SceneTree
## Headless tests for enemy catalog resolution and runtime stat scaling.

const EnemyCatalogScript := preload("res://data/enemy_catalog.gd")
const EnemyDataScript := preload("res://data/enemy_data.gd")
const WorldProgressScript := preload("res://domains/progression/world_progress.gd")
const TestLog := preload("res://tests/test_log_helper.gd")

var _failed := false


func _init() -> void:
	EnemyCatalogScript.reload_for_tests()
	_test_resolve_minion_world1()
	_test_resolve_boss_world1()
	_test_resolve_elite_wave4()
	_test_build_runtime_multipliers()
	_test_fallback_unknown_spawn()
	if _failed:
		TestLog.suite_complete("EnemyCatalog", false)
		quit(1)
	TestLog.suite_complete("EnemyCatalog", true)
	print("[TEST PASS] EnemyCatalog")
	quit(0)


func _test_resolve_minion_world1() -> void:
	var data: EnemyData = EnemyCatalogScript.resolve(1, 3, 2, EnemyDataScript.SpawnRole.MINION)
	if data == null or data.enemy_id != "imp_red":
		_fail("expected imp_red minion for world 1 stage 3 wave 2")


func _test_resolve_boss_world1() -> void:
	var data: EnemyData = EnemyCatalogScript.resolve(1, 9, 1, EnemyDataScript.SpawnRole.BOSS)
	if data == null or data.enemy_id != "boss_world_1":
		_fail("expected boss_world_1 for world 1 stage 9")


func _test_resolve_elite_wave4() -> void:
	var data: EnemyData = EnemyCatalogScript.resolve(2, 5, 4, EnemyDataScript.SpawnRole.ELITE)
	if data == null or data.enemy_id != "dark_elite":
		_fail("expected dark_elite on wave 4")


func _test_build_runtime_multipliers() -> void:
	var base := WorldProgressScript.enemy_stats(1, 3, 0)
	var elite: EnemyData = EnemyCatalogScript.get_by_id("dark_elite")
	var runtime := EnemyCatalogScript.build_runtime(base, elite)
	if runtime["hp"] != maxi(1, int(round(float(base["hp"]) * 5.0))):
		_fail("elite hp multiplier not applied")
	if runtime["gold"] != 0:
		_fail("elite gold multiplier should zero rewards")


func _test_fallback_unknown_spawn() -> void:
	var data: EnemyData = EnemyCatalogScript.resolve(99, 99, 99, EnemyDataScript.SpawnRole.BOSS)
	if data == null or data.enemy_id != "imp_red":
		_fail("expected imp_red fallback when no boss match")


func _fail(message: String) -> void:
	_failed = true
	push_error(message)
