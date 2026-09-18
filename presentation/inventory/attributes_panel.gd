class_name AttributesPanel
extends PanelContainer
## Cobre o inventário e mostra os atributos do herói selecionado.

signal panel_open_changed(is_open: bool)

const BONUS_XP_PCT := 0.0
const BONUS_OURO_PCT := 0.0
const CRIT_CHANCE_PCT := 0.0
const CRIT_DANO_PCT := 0.0
const EVASAO_PCT := 0.0
const RES_FISICA_PCT := 0.0
const RES_ARCANA_PCT := 0.0
const RES_ELEMENTAL_PCT := 0.0

@onready var botao_voltar: Button = %BotaoVoltarAtributos
@onready var cabecalho: HBoxContainer = %CabecalhoAtributos
@onready var lista: VBoxContainer = %ListaAtributos

var _menu: InventoryMenu
var _linhas: Dictionary = {}


func _ready() -> void:
	hide()
	botao_voltar.pressed.connect(close)
	cabecalho.gui_input.connect(_on_header_gui_input)
	gui_input.connect(_on_header_gui_input)
	_build_rows()


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
	call_deferred("_reforcar_layout")


func _reforcar_layout() -> void:
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
	_set_row("ataque", str(int(stats.get("ataque", 0))))
	_set_row("vida", str(int(stats.get("vida", 0))))
	_set_row("xp", "%d / %d" % [int(stats.get("xp", 0)), int(stats.get("xp_proximo", 1))])
	_set_row("bonus_xp", _pct(float(stats.get("bonus_xp", BONUS_XP_PCT))))
	_set_row("bonus_ouro", _pct(float(stats.get("bonus_ouro", BONUS_OURO_PCT))))
	_set_row("vel_ataque", _pct(float(stats.get("vel_ataque", 100.0))))
	_set_row("crit_chance", _pct(float(stats.get("crit_chance", CRIT_CHANCE_PCT))))
	_set_row("crit_dano", _pct(float(stats.get("crit_dano", CRIT_DANO_PCT))))
	_set_row("evasao", _pct(float(stats.get("evasao", EVASAO_PCT))))
	_set_row("res_fisica", _pct(float(stats.get("res_fisica", RES_FISICA_PCT))))
	_set_row("res_arcana", _pct(float(stats.get("res_arcana", RES_ARCANA_PCT))))
	_set_row("res_elemental", _pct(float(stats.get("res_elemental", RES_ELEMENTAL_PCT))))


func _build_rows() -> void:
	if lista == null:
		return
	for filho in lista.get_children():
		filho.queue_free()
	_linhas.clear()
	_adicionar_linha("ataque", "Ataque")
	_adicionar_linha("vida", "Vida")
	_adicionar_linha("xp", "Experiência para próximo nível")
	_adicionar_linha("bonus_xp", "Aumento de experiência")
	_adicionar_linha("bonus_ouro", "Aumento de ouro")
	_adicionar_linha("vel_ataque", "Velocidade de ataque")
	_adicionar_linha("crit_chance", "Chance de acerto crítico")
	_adicionar_linha("crit_dano", "Aumento de dano crítico")
	_adicionar_linha("evasao", "Evasão")
	_adicionar_linha("res_fisica", "Resistência física")
	_adicionar_linha("res_arcana", "Resistência arcana")
	_adicionar_linha("res_elemental", "Resistência elemental")


func _adicionar_linha(chave: String, titulo: String) -> void:
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 8)

	var nome := Label.new()
	nome.text = titulo
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


func _set_row(chave: String, texto: String) -> void:
	var label: Label = _linhas.get(chave) as Label
	if label:
		label.text = texto


func _pct(valor: float) -> String:
	if is_equal_approx(valor, roundf(valor)):
		return "%d%%" % int(round(valor))
	return "%.1f%%" % valor


func _on_header_gui_input(event: InputEvent) -> void:
	if _menu:
		_menu.drag_window_from_event(event)
