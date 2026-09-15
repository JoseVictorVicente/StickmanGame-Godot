class_name IconeRepetir
extends RefCounted
## Ícone circular de repetir fase, desenhado em código.


static func criar() -> Texture2D:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cor := Color(0.95, 0.88, 0.7, 1)
	var centro := Vector2(16, 16)
	_desenhar_arco(img, centro, 11.0, deg_to_rad(-20.0), deg_to_rad(150.0), cor)
	_desenhar_arco(img, centro, 11.0, deg_to_rad(160.0), deg_to_rad(330.0), cor)
	_desenhar_seta(img, centro + Vector2(10.2, 3.2), Vector2(0.35, 1), cor)
	_desenhar_seta(img, centro + Vector2(-10.2, -3.2), Vector2(-0.35, -1), cor)
	return ImageTexture.create_from_image(img)


static func _desenhar_arco(img: Image, centro: Vector2, raio: float, angulo_ini: float, angulo_fim: float, cor: Color) -> void:
	var passos := 28
	for i in passos + 1:
		var t := float(i) / float(passos)
		var ang: float = lerpf(angulo_ini, angulo_fim, t)
		var p: Vector2 = centro + Vector2(cos(ang), sin(ang)) * raio
		for ox in range(-1, 2):
			for oy in range(-1, 2):
				_pixel(img, int(p.x) + ox, int(p.y) + oy, cor)


static func _desenhar_seta(img: Image, ponta: Vector2, direcao: Vector2, cor: Color) -> void:
	var dir := direcao.normalized()
	var perp := Vector2(-dir.y, dir.x)
	var a := ponta
	var b := ponta - dir * 6.0 + perp * 4.0
	var c := ponta - dir * 6.0 - perp * 4.0
	_linha(img, a, b, cor)
	_linha(img, a, c, cor)
	_linha(img, b, c, cor)


static func _linha(img: Image, a: Vector2, b: Vector2, cor: Color) -> void:
	var passos := maxi(1, int(a.distance_to(b)))
	for i in passos + 1:
		var p: Vector2 = a.lerp(b, float(i) / float(passos))
		for ox in range(-1, 2):
			for oy in range(-1, 2):
				_pixel(img, int(p.x) + ox, int(p.y) + oy, cor)


static func _pixel(img: Image, x: int, y: int, cor: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	img.set_pixel(x, y, cor)
