class_name EnemyVisual
extends Sprite2D
## Enemy sprite: hit flash, death fade, and respawn on next wave.

const ATTACK_LUNGE := 28.0
const LUNGE_DURATION := 0.09
const DURACAO_RETORNO := 0.12

var _pos_base: Vector2 = Vector2.ZERO
var _tween: Tween
var _tween_ataque: Tween
var _barra: HeroHealthBar


func _ready() -> void:
	centered = true
	texture = _create_texture()
	scale.x = -1.0
	_pos_base = position
	_barra = HeroHealthBar.new()
	add_child(_barra)
	_barra.position = Vector2(-14, -28)


func play_attack() -> void:
	if _tween_ataque:
		_tween_ataque.kill()
	position = _pos_base
	_tween_ataque = create_tween()
	_tween_ataque.set_trans(Tween.TRANS_QUAD)
	_tween_ataque.tween_property(self, "position:x", _pos_base.x - ATTACK_LUNGE, LUNGE_DURATION).set_ease(Tween.EASE_OUT)
	_tween_ataque.tween_property(self, "position:x", _pos_base.x, DURACAO_RETORNO).set_ease(Tween.EASE_IN)


func update_hp(atual: int, maximo: int) -> void:
	if _barra:
		_barra.update(atual, maximo)


func flash_hit() -> void:
	if _tween:
		_tween.kill()
	if _tween_ataque:
		_tween_ataque.kill()
	self_modulate = Color(1.6, 0.4, 0.35, 1)
	position = _pos_base + Vector2(10, 0)
	_tween = create_tween()
	_tween.tween_property(self, "self_modulate", Color.WHITE, 0.12)
	_tween.parallel().tween_property(self, "position", _pos_base, 0.12)


func fade_out() -> void:
	if _tween:
		_tween.kill()
	if _tween_ataque:
		_tween_ataque.kill()
	if _barra:
		_barra.visible = false
	_tween = create_tween()
	_tween.tween_property(self, "self_modulate:a", 0.0, 0.35)


func show_up() -> void:
	if _tween:
		_tween.kill()
	if _tween_ataque:
		_tween_ataque.kill()
	position = _pos_base
	self_modulate = Color(1, 1, 1, 0)
	if _barra:
		_barra.visible = true
	_tween = create_tween()
	_tween.tween_property(self, "self_modulate", Color.WHITE, 0.28)


func _create_texture() -> Texture2D:
	var img := Image.create(48, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var origem := Vector2(24, 12)
	var cor := Color(0.45, 0.08, 0.1, 1)
	_circulo(img, origem, 7, cor)
	_draw_line(img, origem + Vector2(-5, -4), origem + Vector2(-10, -12), cor)
	_draw_line(img, origem + Vector2(5, -4), origem + Vector2(10, -12), cor)
	_draw_line(img, origem + Vector2(0, 7), origem + Vector2(0, 28), cor)
	_draw_line(img, origem + Vector2(0, 12), origem + Vector2(-12, 22), cor)
	_draw_line(img, origem + Vector2(0, 12), origem + Vector2(12, 22), cor)
	_draw_line(img, origem + Vector2(0, 28), origem + Vector2(-8, 48), cor)
	_draw_line(img, origem + Vector2(0, 28), origem + Vector2(8, 48), cor)
	return ImageTexture.create_from_image(img)


func _circulo(img: Image, centro: Vector2, raio: int, cor: Color) -> void:
	for y in range(int(centro.y) - raio, int(centro.y) + raio + 1):
		for x in range(int(centro.x) - raio, int(centro.x) + raio + 1):
			if Vector2(x, y).distance_to(centro) <= raio:
				_set_pixel(img, x, y, cor)


func _draw_line(img: Image, a: Vector2, b: Vector2, cor: Color) -> void:
	var passos := maxi(1, int(a.distance_to(b)))
	for i in passos + 1:
		var p: Vector2 = a.lerp(b, float(i) / float(passos))
		for ox in range(-1, 2):
			for oy in range(-1, 2):
				_set_pixel(img, int(p.x) + ox, int(p.y) + oy, cor)


func _set_pixel(img: Image, x: int, y: int, cor: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	img.set_pixel(x, y, cor)
