extends AnimatedSprite2D
## Stickman de combate: Idle enquanto espera, Ataque no timer de dano.

const AVANCO_ATAQUE := 28.0
const DURACAO_AVANCO := 0.09
const DURACAO_RETORNO := 0.12

var _pos_base: Vector2 = Vector2.ZERO
var _tween_ataque: Tween
var _tween_flash: Tween
var _cor_classe: Color = Color.WHITE
var _caido: bool = false
var _barra: Node2D


func _ready() -> void:
	centered = true
	sprite_frames = _criar_frames()
	animation_finished.connect(_on_animacao_terminou)
	play("Idle")
	_pos_base = position
	_barra = (load("res://combate/barra_vida_heroi.gd") as GDScript).new()
	_barra.position = Vector2(0, -34)
	add_child(_barra)


func definir_posicao_base(pos: Vector2) -> void:
	_pos_base = pos
	if _tween_ataque:
		_tween_ataque.kill()
	position = pos


func tocar_ataque() -> void:
	if _caido:
		return
	play("Ataque")
	_deslizar_ataque()


func aplicar_classe(classe: ClasseData) -> void:
	if classe == null:
		_cor_classe = Color.WHITE
		self_modulate = Color.WHITE
		return
	_cor_classe = classe.cor
	if not _caido:
		self_modulate = _cor_classe
	if not is_playing():
		play("Idle")


func atualizar_vida(atual: int, maximo: int) -> void:
	if _barra:
		_barra.visible = maximo > 0
		_barra.atualizar(atual, maximo)


func definir_caido(caido: bool) -> void:
	_caido = caido
	if _tween_ataque:
		_tween_ataque.kill()
	position = _pos_base
	if caido:
		if _tween_flash:
			_tween_flash.kill()
		self_modulate = Color(_cor_classe.r * 0.4, _cor_classe.g * 0.4, _cor_classe.b * 0.4, 0.55)
		play("Idle")
	else:
		self_modulate = _cor_classe


## Pisca vermelho por 0.1s (hit no Stickman) e volta à cor da classe.
func piscar_dano() -> void:
	if _caido:
		return
	if _tween_flash:
		_tween_flash.kill()
	self_modulate = Color.RED
	_tween_flash = create_tween()
	_tween_flash.tween_interval(0.1)
	_tween_flash.tween_property(self, "self_modulate", _cor_classe, 0.08)


func _deslizar_ataque() -> void:
	if _tween_ataque:
		_tween_ataque.kill()
	position = _pos_base
	_tween_ataque = create_tween()
	_tween_ataque.set_trans(Tween.TRANS_QUAD)
	_tween_ataque.tween_property(self, "position:x", _pos_base.x + AVANCO_ATAQUE, DURACAO_AVANCO).set_ease(Tween.EASE_OUT)
	_tween_ataque.tween_property(self, "position:x", _pos_base.x, DURACAO_RETORNO).set_ease(Tween.EASE_IN)


func _on_animacao_terminou() -> void:
	if animation == "Ataque":
		play("Idle")


func _criar_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation("Idle")
	frames.set_animation_loop("Idle", true)
	frames.set_animation_speed("Idle", 5.0)
	frames.add_frame("Idle", _textura_pose(Vector2.ZERO, 0.0, 0.0))
	frames.add_frame("Idle", _textura_pose(Vector2(0, -2), 0.12, -0.08))

	frames.add_animation("Ataque")
	frames.set_animation_loop("Ataque", false)
	frames.set_animation_speed("Ataque", 14.0)
	frames.add_frame("Ataque", _textura_pose(Vector2(4, 0), 0.85, -0.2))
	frames.add_frame("Ataque", _textura_pose(Vector2(8, -1), 1.15, -0.35))
	frames.add_frame("Ataque", _textura_pose(Vector2(2, 0), 0.3, -0.1))
	return frames


func _textura_pose(deslocamento: Vector2, braco_frente: float, braco_tras: float) -> Texture2D:
	var img := Image.create(48, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var origem := Vector2(24, 12) + deslocamento
	var cor := Color(0.92, 0.92, 0.95, 1)
	_circulo(img, origem, 7, cor)
	_linha(img, origem + Vector2(0, 7), origem + Vector2(0, 28), cor)
	_linha(img, origem + Vector2(0, 12), origem + Vector2(-11 + braco_tras * 6.0, 22), cor)
	_linha(img, origem + Vector2(0, 12), origem + Vector2(10 + braco_frente * 14.0, 8 - braco_frente * 4.0), cor)
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
