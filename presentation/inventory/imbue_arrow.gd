extends Control
## Seta horizontal desenhada no estilo das bordas dos slots da ferraria.

const COR_BORDA := Color(0.72, 0.58, 0.28, 1)
const ESPESSURA := 2.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var centro_y := size.y * 0.5
	var ponta_x := 4.0
	var cauda_x := size.x - 6.0
	draw_line(Vector2(cauda_x, centro_y), Vector2(ponta_x + 7.0, centro_y), COR_BORDA, ESPESSURA)
	draw_line(Vector2(ponta_x + 7.0, centro_y), Vector2(ponta_x + 14.0, centro_y - 7.0), COR_BORDA, ESPESSURA)
	draw_line(Vector2(ponta_x + 7.0, centro_y), Vector2(ponta_x + 14.0, centro_y + 7.0), COR_BORDA, ESPESSURA)
