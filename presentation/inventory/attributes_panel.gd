class_name AttributesPanel
extends PanelContainer
## Covers the inventory and shows the selected hero's attributes.

signal panel_open_changed(is_open: bool)

const BONUS_XP_PCT := 0.0
const BONUS_OURO_PCT := 0.0
const CRIT_CHANCE_PCT := 0.0
const CRIT_DANO_PCT := 0.0
const EVASAO_PCT := 0.0
const RES_FISICA_PCT := 0.0
const RES_ARCANA_PCT := 0.0
const RES_ELEMENTAL_PCT := 0.0

const ROW_KEYS: Array[String] = [
	"attack", "hp", "xp", "xp_bonus", "gold_bonus", "attack_speed",
	"crit_chance", "crit_damage", "evasion", "phys_res", "arcane_res", "elemental_res",
]

const TITLE_KEYS: Dictionary = {
	"attack": LocaleKeys.ATTR_ATTACK,
	"hp": LocaleKeys.ATTR_HP,
	"xp": LocaleKeys.ATTR_XP_NEXT,
	"xp_bonus": LocaleKeys.ATTR_BONUS_XP,
	"gold_bonus": LocaleKeys.ATTR_BONUS_GOLD,
	"attack_speed": LocaleKeys.ATTR_ATTACK_SPEED,
	"crit_chance": LocaleKeys.ATTR_CRIT_CHANCE,
	"crit_damage": LocaleKeys.ATTR_CRIT_DAMAGE,
	"evasion": LocaleKeys.ATTR_EVASION,
	"phys_res": LocaleKeys.ATTR_PHYS_RES,
	"arcane_res": LocaleKeys.ATTR_ARCANE_RES,
	"elemental_res": LocaleKeys.ATTR_ELEMENTAL_RES,
}

@onready var back_button: Button = %AttributesBackButton
@onready var cabecalho: HBoxContainer = %AttributesHeader
@onready var title_label: Label = $Conteudo/AttributesHeader/BannerTitulo/Titulo
@onready var lista: VBoxContainer = %AttributesList

var _menu: InventoryMenu
var _rows: Dictionary = {}


func _ready() -> void:
	hide()
	back_button.pressed.connect(close)
	cabecalho.gui_input.connect(_on_header_gui_input)
	gui_input.connect(_on_header_gui_input)
	_wire_rows()
	LocaleService.locale_changed.connect(_on_locale_changed)
	_update_localized_texts()


func configure(menu: InventoryMenu) -> void:
	_menu = menu


func is_open() -> bool:
	return visible


func open() -> void:
	if _menu == null or not _menu.visible:
		return
	show()
	update()
	panel_open_changed.emit(true)
	call_deferred("_enforce_layout")


func _enforce_layout() -> void:
	if visible:
		panel_open_changed.emit(true)


func close() -> void:
	custom_minimum_size = Vector2(580, 0)
	hide()
	panel_open_changed.emit(false)


func update() -> void:
	if _menu == null or _rows.is_empty():
		return
	var stats: Dictionary = _menu.current_hero_stats()
	_set_row("attack", str(int(stats.get("attack", 0))))
	_set_row("hp", str(int(stats.get("hp", 0))))
	_set_row("xp", "%d / %d" % [int(stats.get("xp", 0)), int(stats.get("xp_next", 1))])
	_set_row("xp_bonus", _pct(float(stats.get("xp_bonus", BONUS_XP_PCT))))
	_set_row("gold_bonus", _pct(float(stats.get("gold_bonus", BONUS_OURO_PCT))))
	_set_row("attack_speed", _pct(float(stats.get("attack_speed", 100.0))))
	_set_row("crit_chance", _pct(float(stats.get("crit_chance", CRIT_CHANCE_PCT))))
	_set_row("crit_damage", _pct(float(stats.get("crit_damage", CRIT_DANO_PCT))))
	_set_row("evasion", _pct(float(stats.get("evasion", EVASAO_PCT))))
	_set_row("phys_res", _pct(float(stats.get("phys_res", RES_FISICA_PCT))))
	_set_row("arcane_res", _pct(float(stats.get("arcane_res", RES_ARCANA_PCT))))
	_set_row("elemental_res", _pct(float(stats.get("elemental_res", RES_ELEMENTAL_PCT))))


func refresh_locale() -> void:
	_update_localized_texts()
	update()


func _wire_rows() -> void:
	_rows.clear()
	for filho in lista.get_children():
		if filho is AttributeRow:
			var linha := filho as AttributeRow
			var chave := linha.row_key
			if chave.is_empty():
				chave = linha.name.replace("AttrRow_", "")
			_rows[chave] = linha
	assert(_rows.size() == ROW_KEYS.size(), "attributes list should bake %d rows" % ROW_KEYS.size())


func _set_row(chave: String, texto: String) -> void:
	var linha: AttributeRow = _rows.get(chave) as AttributeRow
	if linha:
		linha.set_value(texto)


func _pct(valor: float) -> String:
	if is_equal_approx(valor, roundf(valor)):
		return "%d%%" % int(round(valor))
	return "%.1f%%" % valor


func _update_localized_texts() -> void:
	if title_label:
		title_label.text = tr(LocaleKeys.ATTR_TITLE).to_upper()
	if back_button:
		back_button.tooltip_text = tr(LocaleKeys.BTN_BACK_INVENTORY)
	for chave in ROW_KEYS:
		var linha: AttributeRow = _rows.get(chave) as AttributeRow
		if linha:
			linha.set_title(tr(str(TITLE_KEYS.get(chave, ""))))


func _on_locale_changed(_locale_code: String) -> void:
	_update_localized_texts()
	if is_open():
		update()


func _on_header_gui_input(event: InputEvent) -> void:
	if _menu:
		_menu.drag_window_from_event(event)
