class_name ClasseData
extends Resource
## Atributos de uma classe jogável.

@export var id: String = "guerreiro"
@export var nome_classe: String = "Guerreiro"
@export var sprite_personagem: Texture2D
@export var dano_base: int = 5
@export var vida_base: int = 40
@export var multiplicador_ataque: float = 1.0
@export var velocidade_ataque: float = 1.0
@export var cor: Color = Color(0.12, 0.12, 0.14, 1)
@export var classe_item: ItemData.ClasseRequerida = ItemData.ClasseRequerida.GUERREIRO


static func criar(
	p_id: String,
	p_nome: String,
	p_dano: int,
	p_multi: float,
	p_vel: float,
	p_cor: Color,
	p_classe_item: ItemData.ClasseRequerida,
	p_vida: int = 40,
	p_arte: String = ""
) -> ClasseData:
	var dados := ClasseData.new()
	dados.id = p_id
	dados.nome_classe = p_nome
	dados.dano_base = p_dano
	dados.vida_base = p_vida
	dados.multiplicador_ataque = p_multi
	dados.velocidade_ataque = p_vel
	dados.cor = p_cor
	dados.classe_item = p_classe_item
	dados.sprite_personagem = _carregar_arte(p_arte, p_cor)
	return dados


static func catalogo() -> Array[ClasseData]:
	var lista: Array[ClasseData] = [
		criar("sacerdote", "Sacerdote", 3, 1.1, 0.9, Color(0.86, 0.78, 0.32), ItemData.ClasseRequerida.SACERDOTE, 32, "res://sprites/herois/sacerdote.jpg"),
		criar("tanque", "Tanque", 6, 0.85, 0.7, Color(0.22, 0.32, 0.72), ItemData.ClasseRequerida.TANQUE, 60, "res://sprites/herois/tanque.jpg"),
		criar("assassino", "Assassino", 4, 1.25, 1.45, Color(0.18, 0.18, 0.18), ItemData.ClasseRequerida.ASSASSINO, 26, "res://sprites/herois/assassino.jpg"),
		criar("arqueiro", "Arqueiro", 4, 1.15, 1.3, Color(0.16, 0.42, 0.2), ItemData.ClasseRequerida.ARQUEIRO, 30, "res://sprites/herois/arqueiro.jpg"),
		criar("mago", "Mago", 3, 1.4, 0.85, Color(0.28, 0.18, 0.62), ItemData.ClasseRequerida.MAGO, 24, "res://sprites/herois/mago.jpg"),
		criar("guerreiro", "Guerreiro", 5, 1.0, 1.0, Color(0.72, 0.16, 0.14), ItemData.ClasseRequerida.GUERREIRO, 42, "res://sprites/herois/guerreiro.jpg"),
	]
	return lista


static func _carregar_arte(caminho: String, fallback: Color) -> Texture2D:
	if caminho != "":
		var img := Image.new()
		if img.load(caminho) == OK:
			return ImageTexture.create_from_image(img)
		if ResourceLoader.exists(caminho):
			var recurso := load(caminho)
			if recurso is Texture2D:
				return recurso
	return _sprite_simples(fallback)


static func _sprite_simples(p_cor: Color) -> Texture2D:
	var img := Image.create(48, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var centro := Vector2(24, 12)
	_circulo(img, centro, 7, p_cor)
	_linha(img, centro + Vector2(0, 7), centro + Vector2(0, 28), p_cor)
	_linha(img, centro + Vector2(0, 12), centro + Vector2(-11, 22), p_cor)
	_linha(img, centro + Vector2(0, 12), centro + Vector2(11, 22), p_cor)
	_linha(img, centro + Vector2(0, 28), centro + Vector2(-8, 48), p_cor)
	_linha(img, centro + Vector2(0, 28), centro + Vector2(8, 48), p_cor)
	return ImageTexture.create_from_image(img)


static func _circulo(img: Image, centro: Vector2, raio: int, p_cor: Color) -> void:
	for y in range(int(centro.y) - raio, int(centro.y) + raio + 1):
		for x in range(int(centro.x) - raio, int(centro.x) + raio + 1):
			if Vector2(x, y).distance_to(centro) <= raio:
				_pixel(img, x, y, p_cor)


static func _linha(img: Image, a: Vector2, b: Vector2, p_cor: Color) -> void:
	var passos := maxi(1, int(a.distance_to(b)))
	for i in passos + 1:
		var p: Vector2 = a.lerp(b, float(i) / float(passos))
		for ox in range(-1, 2):
			for oy in range(-1, 2):
				_pixel(img, int(p.x) + ox, int(p.y) + oy, p_cor)


static func _pixel(img: Image, x: int, y: int, p_cor: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	img.set_pixel(x, y, p_cor)
