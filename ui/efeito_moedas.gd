extends Control
## Moedas que saltam do monstro até o contador de ouro.

const TAMANHO := Vector2(12, 12)


func lancar(origem_global: Vector2, destino_global: Vector2, quantidade: int) -> void:
	var total := clampi(quantidade, 3, 8)
	for i in total:
		_criar_moeda(origem_global, destino_global, i * 0.04)


func _criar_moeda(origem: Vector2, destino: Vector2, atraso: float) -> void:
	var moeda := TextureRect.new()
	moeda.texture = _textura_moeda()
	moeda.custom_minimum_size = TAMANHO
	moeda.size = TAMANHO
	moeda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moeda.global_position = origem - TAMANHO * 0.5
	add_child(moeda)

	var pico := origem + Vector2(randf_range(-28.0, 28.0), randf_range(-52.0, -28.0))
	var tween := moeda.create_tween()
	tween.tween_interval(atraso)
	tween.tween_property(moeda, "global_position", pico - TAMANHO * 0.5, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(moeda, "global_position", destino - TAMANHO * 0.5, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(moeda, "modulate:a", 0.0, 0.12).set_delay(0.28)
	tween.tween_callback(moeda.queue_free)


func _textura_moeda() -> Texture2D:
	var img := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var centro := Vector2(6, 6)
	for y in 12:
		for x in 12:
			var d := Vector2(x, y).distance_to(centro)
			if d <= 5.2:
				img.set_pixel(x, y, Color(0.95, 0.78, 0.22, 1) if d < 4.2 else Color(0.72, 0.52, 0.1, 1))
	return ImageTexture.create_from_image(img)
