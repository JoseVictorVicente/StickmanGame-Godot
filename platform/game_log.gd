extends Node
## Structured event logger for assisted testing and AI-readable diagnostics.

enum Level { TRACE, DEBUG, INFO, WARN, ERROR, FATAL }
enum Kind { DEBUG, DOMAIN, INVARIANT }
enum Category { COMBAT, PARTY, INVENTORY, SAVE, PROGRESSION, TEST, SYSTEM }

const SCHEMA_VERSION := 1
const EVENT_PREFIX := "[EVENT] "
const LOG_DIR := "user://logs/"
const MAX_EVENTS_PER_RUN := 10000
const MAX_FILE_BYTES := 2 * 1024 * 1024
const BUFFER_FLUSH_LINES := 50
const MAX_LOG_FILES := 5

var run_id: String = ""
var current_trace_id: String = ""

var _enabled: bool = false
var _min_level: Level = Level.DEBUG
var _event_count: int = 0
var _budget_exhausted: bool = false
var _file_path: String = ""
var _file: FileAccess
var _buffer_lines: int = 0
var _trace_starts: Dictionary = {}
var _event_counts: Dictionary = {}
var _rng_seed: int = 0


func _init() -> void:
	run_id = _make_run_id()
	_rng_seed = randi()
	_enabled = _detect_enabled()


func _ready() -> void:
	if not _enabled:
		return
	_ensure_log_dir()
	_file_path = LOG_DIR + run_id + ".jsonl"
	_file = FileAccess.open(_file_path, FileAccess.WRITE)
	_rotate_old_logs()
	event(
		Category.SYSTEM,
		EventCatalog.SYSTEM_BOOT,
		{
			"godot_version": Engine.get_version_info(),
			"headless": DisplayServer.get_name() == "headless",
			"save_version": SaveService.SAVE_VERSION,
			"run_id": run_id,
			"rng_seed": _rng_seed,
		},
		Level.INFO,
	)


func is_enabled() -> bool:
	return _enabled


func count_event(event_name: String) -> int:
	return int(_event_counts.get(event_name, 0))


func event(
	cat: Category,
	event_name: String,
	data: Dictionary = {},
	level: Level = Level.INFO,
	kind: Kind = Kind.DOMAIN,
	trace_id: String = ""
) -> void:
	if not _enabled:
		return
	if _budget_exhausted and level < Level.WARN:
		return
	if level < _min_level:
		return
	var record := _build_record(cat, event_name, data, level, kind, trace_id)
	_emit_record(record)
	_event_count += 1
	if _event_count >= MAX_EVENTS_PER_RUN:
		_budget_exhausted = true


func trace_start(action: String) -> String:
	var trace_id := "%s-%04d" % [action, _trace_starts.size()]
	_trace_starts[trace_id] = Time.get_ticks_msec()
	current_trace_id = trace_id
	event(
		Category.SYSTEM,
		EventCatalog.SYSTEM_TRACE_START,
		{"action": action, "trace_id": trace_id},
		Level.DEBUG,
	)
	return trace_id


func trace_end(trace_id: String, data: Dictionary = {}) -> void:
	var payload := data.duplicate()
	payload["trace_id"] = trace_id
	if _trace_starts.has(trace_id):
		payload["duration_ms"] = Time.get_ticks_msec() - int(_trace_starts[trace_id])
		_trace_starts.erase(trace_id)
	if current_trace_id == trace_id:
		current_trace_id = ""
	event(
		Category.SYSTEM,
		EventCatalog.SYSTEM_TRACE_END,
		payload,
		Level.DEBUG,
	)


func invariant(rule: String, ok: bool, data: Dictionary = {}) -> void:
	var payload := data.duplicate()
	payload["rule"] = rule
	payload["ok"] = ok
	event(
		Category.TEST,
		"invariant.%s" % rule,
		payload,
		Level.ERROR if not ok else Level.DEBUG,
		Kind.INVARIANT,
	)


func snapshot(label: String, state: Dictionary) -> void:
	var payload := state.duplicate()
	payload["label"] = label
	event(Category.TEST, EventCatalog.TEST_STATE_DUMP, payload, Level.INFO)


func emit_engine_event(event_name: String, message: String, level: Level) -> void:
	event(
		Category.SYSTEM,
		event_name,
		{"message": message},
		level,
		Kind.DEBUG,
	)


func _build_record(
	cat: Category,
	event_name: String,
	data: Dictionary,
	level: Level,
	kind: Kind,
	trace_id: String
) -> Dictionary:
	var record := {
		"v": SCHEMA_VERSION,
		"ts": _timestamp(),
		"run_id": run_id,
		"level": Level.keys()[level],
		"kind": Kind.keys()[kind].to_lower(),
		"cat": Category.keys()[cat].to_lower(),
		"event": event_name,
		"data": data.duplicate(),
	}
	var effective_trace := trace_id if trace_id != "" else current_trace_id
	if effective_trace != "":
		record["trace_id"] = effective_trace
	return record


func _emit_record(record: Dictionary) -> void:
	var event_name := str(record.get("event", ""))
	if event_name != "":
		_event_counts[event_name] = int(_event_counts.get(event_name, 0)) + 1
	var line := EVENT_PREFIX + JSON.stringify(record)
	print(line)
	if _file == null:
		return
	if _file.get_position() >= MAX_FILE_BYTES:
		return
	_file.store_line(line)
	_buffer_lines += 1
	var level_name := str(record.get("level", "INFO"))
	if _buffer_lines >= BUFFER_FLUSH_LINES or level_name in ["WARN", "ERROR", "FATAL"]:
		_file.flush()
		_buffer_lines = 0


func _detect_enabled() -> bool:
	if OS.get_environment("GAMELOG") == "1":
		return true
	for arg in OS.get_cmdline_args():
		if arg == "--game-log":
			return true
	if DisplayServer.get_name() == "headless":
		return true
	return false


func _timestamp() -> float:
	return float(Time.get_unix_time_from_system()) + float(Time.get_ticks_usec() % 1000000) / 1000000.0


func _make_run_id() -> String:
	var chars := "abcdefghijklmnopqrstuvwxyz0123456789"
	var result := ""
	for _i in 8:
		result += chars[randi() % chars.length()]
	return result


func _ensure_log_dir() -> void:
	if not DirAccess.dir_exists_absolute(LOG_DIR):
		DirAccess.make_dir_recursive_absolute(LOG_DIR)


func _rotate_old_logs() -> void:
	if not DirAccess.dir_exists_absolute(LOG_DIR):
		return
	var files: Array[String] = []
	var dir := DirAccess.open(LOG_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.ends_with(".jsonl"):
			files.append(entry)
		entry = dir.get_next()
	dir.list_dir_end()
	files.sort()
	while files.size() >= MAX_LOG_FILES:
		var oldest: String = files[0]
		DirAccess.remove_absolute(LOG_DIR + oldest)
		files.remove_at(0)


func _exit_tree() -> void:
	if _file != null:
		_file.flush()
		_file.close()
		_file = null
