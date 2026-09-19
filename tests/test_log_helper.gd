extends RefCounted
## Runtime access to GameLog autoload from headless SceneTree tests.

const EventCatalogScript := preload("res://data/event_catalog.gd")


static func _log() -> Node:
	var loop := Engine.get_main_loop()
	if loop == null:
		return null
	return loop.root.get_node_or_null("GameLog")


static func suite_complete(suite: String, passed: bool) -> void:
	var log := _log()
	if log == null:
		return
	log.event(
		log.Category.TEST,
		EventCatalogScript.TEST_SUITE_COMPLETE,
		{"suite": suite, "passed": passed},
		log.Level.INFO if passed else log.Level.ERROR,
	)


static func invariant(rule: String, ok: bool, data: Dictionary = {}) -> void:
	var log := _log()
	if log == null:
		return
	log.invariant(rule, ok, data)


static func event(event_name: String, data: Dictionary = {}, level: int = -1) -> void:
	var log := _log()
	if log == null:
		return
	var resolved_level: int = log.Level.INFO if level < 0 else level
	log.event(log.Category.TEST, event_name, data, resolved_level)
