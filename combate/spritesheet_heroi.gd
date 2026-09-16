class_name SpritesheetHeroi
extends RefCounted
## Recorta a spritesheet do herói (JSON + PNG) em Idle / Ataque / Hit / Morte.

const ID_ARQUEIRO := "arqueiro"
const PNG_ARQUEIRO := "res://sprites/herois/A_2D_pixel-art_stickman-Idle.png"
const JSON_ARQUEIRO := "res://sprites/herois/A_2D_pixel-art_stickman-Idle.json"
const ESCALA_STICK := Vector2(1.25, 1.25)
const ESCALA_ARQUEIRO := Vector2(0.34, 0.34)
const BARRA_STICK := Vector2(-14, -38)
const BARRA_ARQUEIRO := Vector2(-14, -118)

static var _frames: Dictionary = {}
static var _sheets: Dictionary = {}


static func tem(id_classe: String) -> bool:
	return frames(id_classe) != null


static func frames(id_classe: String) -> SpriteFrames:
	if _frames.has(id_classe):
		return _frames[id_classe] as SpriteFrames
	if id_classe != ID_ARQUEIRO:
		return null
	var montado: SpriteFrames = _montar_arqueiro()
	if montado:
		_frames[id_classe] = montado
	return montado


static func escala(id_classe: String) -> Vector2:
	if id_classe == ID_ARQUEIRO:
		return ESCALA_ARQUEIRO
	return ESCALA_STICK


static func barra_offset(id_classe: String) -> Vector2:
	if id_classe == ID_ARQUEIRO:
		return BARRA_ARQUEIRO
	return BARRA_STICK


static func _montar_arqueiro() -> SpriteFrames:
	var sheet := _carregar_textura(PNG_ARQUEIRO)
	if sheet == null:
		return null
	var cell: int = 256
	var dados: Variant = _ler_json(JSON_ARQUEIRO)
	if dados is Dictionary:
		var info: Variant = (dados as Dictionary).get("spritesheet", {})
		if info is Dictionary:
			var cell_info: Variant = (info as Dictionary).get("cell_size", {})
			if cell_info is Dictionary:
				cell = int((cell_info as Dictionary).get("width", 256))
	var sf := SpriteFrames.new()
	var idle: Array[Texture2D] = []
	idle.append(_celula(sheet, 2, 0, cell))
	_add_anim(sf, "Idle", idle, true, 1.0)
	_add_anim(sf, "Ataque", _linha(sheet, 2, 9, cell), false, 12.0)
	_add_anim(sf, "Hit", _linha(sheet, 1, 5, cell), false, 10.0)
	_add_anim(sf, "Morte", _linha(sheet, 8, 17, cell), false, 10.0)
	return sf


static func _add_anim(sf: SpriteFrames, nome: String, texturas: Array[Texture2D], loop: bool, fps: float) -> void:
	if not sf.has_animation(nome):
		sf.add_animation(nome)
	sf.set_animation_loop(nome, loop)
	sf.set_animation_speed(nome, fps)
	for tex in texturas:
		sf.add_frame(nome, tex)


static func _linha(sheet: Texture2D, row: int, quantidade: int, cell: int) -> Array[Texture2D]:
	var lista: Array[Texture2D] = []
	for col in quantidade:
		lista.append(_celula(sheet, col, row, cell))
	return lista


static func _celula(sheet: Texture2D, col: int, row: int, cell: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.filter_clip = true
	atlas.region = Rect2(col * cell, row * cell, cell, cell)
	return atlas


static func _carregar_textura(caminho: String) -> Texture2D:
	if _sheets.has(caminho):
		return _sheets[caminho] as Texture2D
	var tex: Texture2D = null
	if ResourceLoader.exists(caminho):
		var recurso: Resource = ResourceLoader.load(caminho)
		if recurso is Texture2D:
			tex = recurso
	if tex == null:
		var absoluto := ProjectSettings.globalize_path(caminho)
		var img: Image = Image.load_from_file(absoluto)
		if img != null and img.get_width() > 1:
			tex = ImageTexture.create_from_image(img)
	if tex:
		_sheets[caminho] = tex
	return tex


static func _ler_json(caminho: String) -> Variant:
	if not FileAccess.file_exists(caminho):
		return {}
	var txt: String = FileAccess.get_file_as_string(caminho)
	var parsed: Variant = JSON.parse_string(txt)
	return parsed
