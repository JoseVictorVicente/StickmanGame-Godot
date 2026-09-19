extends Node
## Autoload facade for SaveService persistence.

const SaveServiceScript := preload("res://core/save_service.gd")

var _root: Node = null
var _timer: Timer


func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	_timer = Timer.new()
	_timer.wait_time = SaveServiceScript.AUTOSAVE_INTERVAL
	_timer.autostart = true
	_timer.timeout.connect(save)
	add_child(_timer)


func register(root: Node) -> void:
	_root = root


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save()
		get_tree().quit()


func save() -> void:
	if GameLog.is_enabled():
		GameLog.event(
			GameLog.Category.SAVE,
			EventCatalog.SAVE_AUTOSAVE,
			{"interval": SaveServiceScript.AUTOSAVE_INTERVAL},
			GameLog.Level.DEBUG,
		)
	SaveServiceScript.save_game(_root)


func load_game() -> bool:
	return SaveServiceScript.load_game(_root)


func save_game() -> void:
	save()
