extends Node2D

func _ready() -> void:
	# 1. Habilita o fundo transparente da janela e do viewport
	get_viewport().transparent_bg = true
	get_tree().get_root().transparent_bg = true
	
	# 2. Configura as propriedades da janela no sistema operacional
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true)

# Variáveis para movimentação da janela com o mouse
var arrastando: bool = false
var offset_mouse: Vector2i = Vector2i.ZERO

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://menu.tscn")
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				arrastando = true
				offset_mouse = DisplayServer.mouse_get_position() - DisplayServer.window_get_position()
			else:
				arrastando = false

	elif event is InputEventMouseMotion and arrastando:
		var nova_posicao: Vector2i = DisplayServer.mouse_get_position() - offset_mouse
		DisplayServer.window_set_position(nova_posicao)
