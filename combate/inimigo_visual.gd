extends Sprite2D
## Sprite do monstro: hit, fade na morte e reaparece no próximo.

const AVANCO_ATAQUE := 28.0
const DURACAO_AVANCO := 0.09
const DURACAO_RETORNO := 0.12

var _pos_base: Vector2 = Vector2.ZERO
var _tween: Tween
var _tween_ataque: Tween


func _ready() -> void:
	centered = true
	texture = _criar_textura()
	scale.x = -1.0
	_pos_base = position


func tocar_ataque() -> void:
	if _tween_ataque:
		_tween_ataque.kill()
	position = _pos_base
	_tween_ataque = create_tween()
	_tween_ataque.set_trans(Tween.TRANS_QUAD)
	_tween_ataque.tween_property(self, "position:x", _pos_base.x - AVANCO_ATAQUE, DURACAO_AVANCO).set_ease(Tween.EASE_OUT)
	_tween_ataque.tween_property(self, "position:x", _pos_base.x, DURACAO_RETORNO).set_ease(Tween.EASE_IN)


func piscar_hit() -> void:
	if _tween:
		_tween.kill()
	if _tween_ataque:
		_tween_ataque.kill()
	modulate = Color(1.6, 0.4, 0.35, 1)
	position = _pos_base + Vector2(10, 0)
	_tween = create_tween()
	_tween.tween_property(self, "modulate", Color.WHITE, 0.12)
	_tween.parallel().tween_property(self, "position", _pos_base, 0.12)


func esmaecer() -> void:
	if _tween:
		_tween.kill()
	if _tween_ataque:
		_tween_ataque.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, 0.35)


func aparecer() -> void:
	if _tween:
		_tween.kill()
	if _tween_ataque:
		_tween_ataque.kill()
	position = _pos_base
	modulate = Color(1, 1, 1, 0)
	_tween = create_tween()
	_tween.tween_property(self, "modulate", Color.WHITE, 0.28)


func _criar_textura() -> Texture2D:
	var img := Image.create(48, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var origem := Vector2(24, 12)
	var cor := Color(0.45, 0.08, 0.1, 1)
	_circulo(img, origem, 7, cor)
	_linha(img, origem + Vector2(-5, -4), origem + Vector2(-10, -12), cor)
	_linha(img, origem + Vector2(5, -4), origem + Vector2(10, -12), cor)
	_linha(img, origem + Vector2(0, 7), origem + Vector2(0, 28), cor)
	_linha(img, origem + Vector2(0, 12), origem + Vector2(-12, 22), cor)
	_linha(img, origem + Vector2(0, 12), origem + Vector2(12, 22), cor)
	_linha(img, origem + Vector2(0, 28), origem + Vector2(-8, 48), cor)
	_linha(img, origem + Vector2(0, 28), origem + Vector2(8, 48), cor)
	return ImageTexture.create_from_image(img)


func _circulo(img: Image, centro: Vector2, raio: int, cor: Color) -> void:
	for y in range(int(centro.y) - raio, int(centro.y) + raio + 1):
		for x in range(int(centro.x) - raio, int(centro.x) + raio + 1):
			if Vector2(x, y).distance_to(centro) <= raio:
				_pixel(img, x, y, cor)


func _linha(img: Image, a: Vector2, b: Vector2, cor: Color) -> void:
	var passos := maxi(1, int(a.distance_to(b)))
	for i in passos + 1:
		var p: Vector2 = a.lerp(b, float(i) / float(passos))
		for ox in range(-1, 2):
			for oy in range(-1, 2):
				_pixel(img, int(p.x) + ox, int(p.y) + oy, cor)


func _pixel(img: Image, x: int, y: int, cor: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	img.set_pixel(x, y, cor)
