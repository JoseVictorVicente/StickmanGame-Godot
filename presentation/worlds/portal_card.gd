class_name PortalCard
extends PanelContainer

@onready var world_button: Button = %WorldButton
@onready var portal_progress: Label = %PortalProgress


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
	var cor_botao := Color(0.52, 0.46, 0.38, 1) if bloqueado else Color(0.95, 0.88, 0.7, 1)
	if not bloqueado and ativo:
		cor_botao = Color(1, 0.92, 0.72, 1)
	world_button.add_theme_color_override("font_color", cor_botao)
	var estilo := StyleBoxFlat.new()
	estilo.content_margin_left = 8
	estilo.content_margin_top = 4
	estilo.content_margin_right = 8
	estilo.content_margin_bottom = 4
	estilo.set_corner_radius_all(5)
	estilo.set_border_width_all(3 if ativo else 2)
	if bloqueado:
		estilo.bg_color = Color(0.1, 0.08, 0.07, 1)
		estilo.border_color = Color(0.34, 0.28, 0.2, 1)
	elif ativo:
		estilo.bg_color = Color(0.28, 0.2, 0.12, 1)
		estilo.border_color = Color(0.95, 0.78, 0.32, 1)
	else:
		estilo.bg_color = Color(0.14, 0.11, 0.08, 1)
		estilo.border_color = Color(0.72, 0.58, 0.3, 1)
	add_theme_stylebox_override("panel", estilo)
