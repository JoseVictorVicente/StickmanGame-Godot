class_name PortalCard
extends PanelContainer

@export var style_normal: StyleBoxFlat
@export var style_active: StyleBoxFlat
@export var style_locked: StyleBoxFlat

@onready var world_button: Button = %WorldButton
@onready var world_name: Label = %WorldName
@onready var portal_progress: Label = %PortalProgress


func apply_state(
	nome: String,
	ativo: bool,
	bloqueado: bool,
	meta_texto: String,
	mostrar_meta: bool
) -> void:
	world_name.text = nome
	if mostrar_meta:
		portal_progress.text = meta_texto
		portal_progress.show()
	else:
		portal_progress.hide()
	if bloqueado:
		world_name.add_theme_color_override("font_color", Color(0.52, 0.46, 0.38, 1))
		portal_progress.add_theme_color_override("font_color", Color(0.62, 0.54, 0.42, 1))
		add_theme_stylebox_override("panel", style_locked)
	elif ativo:
		world_name.add_theme_color_override("font_color", Color(1, 0.92, 0.72, 1))
		portal_progress.add_theme_color_override("font_color", Color(0.95, 0.82, 0.45, 1))
		add_theme_stylebox_override("panel", style_active)
	else:
		world_name.add_theme_color_override("font_color", Color(0.95, 0.88, 0.7, 1))
		portal_progress.add_theme_color_override("font_color", Color(0.82, 0.74, 0.52, 1))
		add_theme_stylebox_override("panel", style_normal)
