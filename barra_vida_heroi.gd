class_name BarraVidaHeroi
extends Node2D
## Barra compacta acima da cabeça do herói.

const LARGURA := 22.0
const ALTURA := 3.5

var vida_max := 1
var vida_atual := 1


func _ready() -> void:
	z_index = 8
	z_as_relative = false


func atualizar(atual: int, maximo: int) -> void:
	vida_atual = maxi(0, atual)
	vida_max = maxi(1, maximo)
	queue_redraw()


func _draw() -> void:
	var fundo := Rect2(-LARGURA * 0.5, 0.0, LARGURA, ALTURA)
	draw_rect(fundo, Color(0.08, 0.06, 0.05, 0.95), true)
	var ratio := clampf(float(vida_atual) / float(vida_max), 0.0, 1.0)
	var cor := Color(0.28, 0.82, 0.32, 1)
	if ratio <= 0.25:
		cor = Color(0.86, 0.22, 0.18, 1)
	elif ratio <= 0.55:
		cor = Color(0.88, 0.72, 0.18, 1)
	if ratio > 0.0:
		draw_rect(Rect2(-LARGURA * 0.5, 0.0, LARGURA * ratio, ALTURA), cor, true)
	draw_rect(fundo, Color(0.42, 0.32, 0.2, 1), false, 1.0)
