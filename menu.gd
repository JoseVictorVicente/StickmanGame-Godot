extends Control

const CENA_JOGO := "res://main.tscn"

var arrastando: bool = false
var offset_mouse: Vector2i = Vector2i.ZERO


func _ready() -> void:
	get_viewport().transparent_bg = true
	get_tree().get_root().transparent_bg = true
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true)


func _on_botao_jogar_pressed() -> void:
	get_tree().change_scene_to_file(CENA_JOGO)


func _on_botao_sair_pressed() -> void:
	get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			arrastando = true
			offset_mouse = DisplayServer.mouse_get_position() - DisplayServer.window_get_position()
		else:
			arrastando = false
	elif event is InputEventMouseMotion and arrastando:
		DisplayServer.window_set_position(DisplayServer.mouse_get_position() - offset_mouse)
