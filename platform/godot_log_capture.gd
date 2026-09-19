extends Node
## Passive capture of Godot engine print/error/warning into GameLog.


var _logger: _CaptureLogger


func _ready() -> void:
	if not GameLog.is_enabled():
		return
	_logger = _CaptureLogger.new()
	OS.add_logger(_logger)


class _CaptureLogger extends Logger:
	var _mutex := Mutex.new()

	func _log_message(message: String, error: bool) -> void:
		if not GameLog.is_enabled() or not error:
			return
		if message.begins_with(GameLog.EVENT_PREFIX):
			return
		_mutex.lock()
		GameLog.emit_engine_event(EventCatalog.ENGINE_ERROR, message, GameLog.Level.ERROR)
		_mutex.unlock()

	func _log_error(
		function: String,
		file: String,
		line: int,
		code: String,
		rationale: String,
		editor_notify: bool,
		error_type: int,
		script_backtraces: Array[ScriptBacktrace]
	) -> void:
		if not GameLog.is_enabled():
			return
		_mutex.lock()
		var text := rationale if rationale != "" else code
		if function != "":
			text = "%s (%s:%d)" % [text, file.get_file(), line]
		GameLog.emit_engine_event(EventCatalog.ENGINE_WARNING, text, GameLog.Level.WARN)
		_mutex.unlock()
