class_name StageMap
extends Control
## Desenha o caminho entre as fases do world.

var pontos: Array[Vector2] = []


func _draw() -> void:
	if pontos.size() < 2:
		return
	for i in range(1, pontos.size()):
		draw_line(pontos[i - 1], pontos[i], Color(0.82, 0.68, 0.36, 0.85), 2.0, true)
