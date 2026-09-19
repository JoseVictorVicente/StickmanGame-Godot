extends SceneTree
## Headless smoke test: runs main scene idle combat for 30s and validates structured events.
## Run: godot --headless --path . -s res://tests/scenario_idle_smoke.gd

const SMOKE_DURATION_SEC := 30.0

const TestLog := preload("res://tests/test_log_helper.gd")
const EventCatalogScript := preload("res://data/event_catalog.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	TestLog.event(
		EventCatalogScript.TEST_SCENARIO_START,
		{"suite": "idle_smoke", "duration_sec": SMOKE_DURATION_SEC},
	)

	var main_scene: PackedScene = load("res://scenes/main.tscn")
	if main_scene == null:
		_fail("failed to load main.tscn")
		_finish({})
		return

	change_scene_to_packed(main_scene)
	await create_timer(0.5).timeout
	await create_timer(SMOKE_DURATION_SEC).timeout

	var log := TestLog._log()
	var counters := {
		"attacks": log.count_event(EventCatalogScript.COMBAT_HERO_ATTACK) if log else 0,
		"deaths": log.count_event(EventCatalogScript.COMBAT_ENEMY_DIED) if log else 0,
		"gold_events": log.count_event(EventCatalogScript.PROGRESSION_GOLD_GAINED) if log else 0,
	}

	if counters.get("attacks", 0) < 1:
		_fail("expected at least 1 hero attack")
	if counters.get("deaths", 0) < 1:
		_fail("expected at least 1 enemy death")
	if counters.get("gold_events", 0) < 1:
		_fail("expected at least 1 gold gained event")

	_finish(counters)


func _finish(counters: Dictionary) -> void:
	TestLog.event(
		EventCatalogScript.TEST_SCENARIO_END,
		{"suite": "idle_smoke", "passed": not _failed, "counters": counters},
	)
	if _failed:
		quit(1)
	print("[TEST PASS] IdleSmoke")
	quit(0)


func _fail(message: String) -> void:
	_failed = true
	var log := TestLog._log()
	if log != null:
		log.event(
			log.Category.TEST,
			EventCatalogScript.TEST_ASSERTION,
			{"name": message, "ok": false},
			log.Level.ERROR,
		)
	push_error("[TEST FAIL] " + message)
