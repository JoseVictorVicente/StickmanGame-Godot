class_name PortalCard
extends PanelContainer

@onready var world_button: Button = %WorldButton
@onready var portal_progress: Label = %PortalProgress

var _style_normal: StyleBoxFlat
var _style_active: StyleBoxFlat
var _style_locked: StyleBoxFlat


func _ready() -> void:
	_style_normal = get_theme_stylebox("panel") as StyleBoxFlat
	_style_active = _style_normal.duplicate() as StyleBoxFlat
	_style_active.bg_color = Color(0.28, 0.2, 0.12, 1)
	_style_active.border_width_left = 3
	_style_active.border_width_top = 3
	_style_active.border_width_right = 3
	_style_active.border_width_bottom = 3
	_style_active.border_color = Color(0.95, 0.78, 0.32, 1)
	_style_locked = _style_normal.duplicate() as StyleBoxFlat
	_style_locked.bg_color = Color(0.1, 0.08, 0.07, 1)
	_style_locked.border_color = Color(0.34, 0.28, 0.2, 1)


func apply_state(
	nome: String,
	ativo: bool,
	bloqueado: bool,
	meta_texto: String,
	mostrar_meta: bool
) -> void:
	world_button.text = nome
	if mostrar_meta:
		portal_progress.text = meta_texto
		portal_progress.show()
	else:
		portal_progress.hide()
	if bloqueado:
		world_button.add_theme_color_override("font_color", Color(0.52, 0.46, 0.38, 1))
		add_theme_stylebox_override("panel", _style_locked)
	elif ativo:
		world_button.add_theme_color_override("font_color", Color(1, 0.92, 0.72, 1))
		add_theme_stylebox_override("panel", _style_active)
	else:
		world_button.add_theme_color_override("font_color", Color(0.95, 0.88, 0.7, 1))
		add_theme_stylebox_override("panel", _style_normal)
