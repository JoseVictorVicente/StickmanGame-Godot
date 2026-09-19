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

@onready var back_button: Button = %AttributesBackButton
@onready var cabecalho: HBoxContainer = %AttributesHeader
@onready var title_label: Label = $Conteudo/AttributesHeader/BannerTitulo/Titulo
@onready var lista: VBoxContainer = %AttributesList

var _menu: InventoryMenu
var _linhas: Dictionary = {}
var _title_labels: Dictionary = {}
var _title_keys: Dictionary = {}


func _ready() -> void:
	hide()
	back_button.pressed.connect(close)
	cabecalho.gui_input.connect(_on_header_gui_input)
	gui_input.connect(_on_header_gui_input)
	_build_rows()
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
	if _menu == null or _linhas.is_empty():
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


func _build_rows() -> void:
	if lista == null:
		return
	for filho in lista.get_children():
		filho.queue_free()
	_linhas.clear()
	_title_labels.clear()
	_title_keys.clear()
	_add_row("attack", LocaleKeys.ATTR_ATTACK)
	_add_row("hp", LocaleKeys.ATTR_HP)
	_add_row("xp", LocaleKeys.ATTR_XP_NEXT)
	_add_row("xp_bonus", LocaleKeys.ATTR_BONUS_XP)
	_add_row("gold_bonus", LocaleKeys.ATTR_BONUS_GOLD)
	_add_row("attack_speed", LocaleKeys.ATTR_ATTACK_SPEED)
	_add_row("crit_chance", LocaleKeys.ATTR_CRIT_CHANCE)
	_add_row("crit_damage", LocaleKeys.ATTR_CRIT_DAMAGE)
	_add_row("evasion", LocaleKeys.ATTR_EVASION)
	_add_row("phys_res", LocaleKeys.ATTR_PHYS_RES)
	_add_row("arcane_res", LocaleKeys.ATTR_ARCANE_RES)
	_add_row("elemental_res", LocaleKeys.ATTR_ELEMENTAL_RES)


func _add_row(chave: String, title_key: String) -> void:
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 8)

	var nome := Label.new()
	nome.text = tr(title_key)
	nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nome.add_theme_color_override("font_color", Color(0.92, 0.84, 0.62, 1))
	nome.add_theme_font_size_override("font_size", 13)
	linha.add_child(nome)

	var valor := Label.new()
	valor.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	valor.custom_minimum_size.x = 88
	valor.add_theme_color_override("font_color", Color(1, 0.94, 0.78, 1))
	valor.add_theme_font_size_override("font_size", 13)
	valor.text = "—"
	linha.add_child(valor)

	lista.add_child(linha)
	_linhas[chave] = valor
	_title_labels[chave] = nome
	_title_keys[chave] = title_key


func _set_row(chave: String, texto: String) -> void:
	var label: Label = _linhas.get(chave) as Label
	if label:
		label.text = texto


func _pct(valor: float) -> String:
	if is_equal_approx(valor, roundf(valor)):
		return "%d%%" % int(round(valor))
	return "%.1f%%" % valor


func _update_localized_texts() -> void:
	if title_label:
		title_label.text = tr(LocaleKeys.ATTR_TITLE).to_upper()
	if back_button:
		back_button.tooltip_text = tr(LocaleKeys.BTN_BACK_INVENTORY)
	for chave in _title_labels.keys():
		var nome: Label = _title_labels[chave] as Label
		if nome:
			nome.text = tr(str(_title_keys.get(chave, "")))


func _on_locale_changed(_locale_code: String) -> void:
	_update_localized_texts()
	if is_open():
		update()


func _on_header_gui_input(event: InputEvent) -> void:
	if _menu:
		_menu.drag_window_from_event(event)
