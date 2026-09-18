extends Node
## Runtime locale switching (gettext-style via Godot TranslationServer + .po files).

signal locale_changed(locale_code: String)

const SAVE_PATH := "user://locale.cfg"
const DEFAULT_LOCALE := "en"

const AVAILABLE_LOCALES: Array[String] = ["pt_BR", "en"]

const LOCALE_LABEL_KEYS := {
	"pt_BR": "SETTINGS_LOCALE_PT",
	"en": "SETTINGS_LOCALE_EN",
}


func _ready() -> void:
	_load_saved_locale()


func get_locale() -> String:
	return TranslationServer.get_locale()


func get_available_locales() -> Array[String]:
	return AVAILABLE_LOCALES.duplicate()


func set_locale(locale_code: String) -> void:
	var normalized := _normalize(locale_code)
	if not AVAILABLE_LOCALES.has(normalized):
		push_warning("LocaleService: unsupported locale '%s'" % locale_code)
		return
	if TranslationServer.get_locale() == normalized:
		return
	TranslationServer.set_locale(normalized)
	_save_locale(normalized)
	locale_changed.emit(normalized)


func locale_display_name(locale_code: String) -> String:
	var key: String = LOCALE_LABEL_KEYS.get(_normalize(locale_code), "")
	return tr(key) if key != "" else locale_code


static func translate(key: String, args: Array = []) -> String:
	var text := TranslationServer.translate(key)
	if args.is_empty():
		return text
	return text % args


func _normalize(locale_code: String) -> String:
	return locale_code.replace("-", "_")


func _load_saved_locale() -> void:
	var cfg := ConfigFile.new()
	var locale := DEFAULT_LOCALE
	if cfg.load(SAVE_PATH) == OK:
		locale = str(cfg.get_value("locale", "code", DEFAULT_LOCALE))
	set_locale(locale)


func _save_locale(locale_code: String) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("locale", "code", locale_code)
	cfg.save(SAVE_PATH)
