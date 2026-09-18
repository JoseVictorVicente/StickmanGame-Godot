class_name HeroSpritesheet
extends RefCounted
## Recorta a spritesheet do herói (JSON + PNG) em Idle / Ataque / Hit / Morte.

const ID_ARQUEIRO := "archer"
const PNG_ARQUEIRO := "res://sprites/heroes/A_2D_pixel-art_stickman-Idle.png"
const JSON_ARQUEIRO := "res://sprites/heroes/A_2D_pixel-art_stickman-Idle.json"
const ESCALA_STICK := Vector2(1.25, 1.25)
const ESCALA_ARQUEIRO := Vector2(0.34, 0.34)
const BARRA_STICK := Vector2(-14, -38)
const ARCHER_BAR := Vector2(-14, -118)

static var _frames: Dictionary = {}
static var _sheets: Dictionary = {}


static func has_class_art(id_classe: String) -> bool:
	return frames(id_classe) != null


static func frames(id_classe: String) -> SpriteFrames:
	if _frames.has(id_classe):
		return _frames[id_classe] as SpriteFrames
	if id_classe != ID_ARQUEIRO:
		return null
	var montado: SpriteFrames = _build_archer()
	if montado:
		_frames[id_classe] = montado
	return montado


static func scale_for(id_classe: String) -> Vector2:
	if id_classe == ID_ARQUEIRO:
		return ESCALA_ARQUEIRO
	return ESCALA_STICK


static func health_bar_offset(id_classe: String) -> Vector2:
	if id_classe == ID_ARQUEIRO:
		return ARCHER_BAR
	return BARRA_STICK


static func _build_archer() -> SpriteFrames:
	var sheet := _load_texture(PNG_ARQUEIRO)
	if sheet == null:
		return null
	var cell: int = 256
	var dados: Variant = _read_json(JSON_ARQUEIRO)
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
	_add_anim(sf, "Ataque", _draw_line(sheet, 2, 9, cell), false, 12.0)
	_add_anim(sf, "Hit", _draw_line(sheet, 1, 5, cell), false, 10.0)
	_add_anim(sf, "Morte", _draw_line(sheet, 8, 17, cell), false, 10.0)
	return sf


static func _add_anim(sf: SpriteFrames, nome: String, texturas: Array[Texture2D], loop: bool, fps: float) -> void:
	if not sf.has_animation(nome):
		sf.add_animation(nome)
	sf.set_animation_loop(nome, loop)
	sf.set_animation_speed(nome, fps)
	for tex in texturas:
		sf.add_frame(nome, tex)


static func _draw_line(sheet: Texture2D, row: int, amount: int, cell: int) -> Array[Texture2D]:
	var lista: Array[Texture2D] = []
	for col in amount:
		lista.append(_celula(sheet, col, row, cell))
	return lista


static func _celula(sheet: Texture2D, col: int, row: int, cell: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.filter_clip = true
	atlas.region = Rect2(col * cell, row * cell, cell, cell)
	return atlas


static func _load_texture(caminho: String) -> Texture2D:
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


static func _read_json(caminho: String) -> Variant:
	if not FileAccess.file_exists(caminho):
		return {}
	var txt: String = FileAccess.get_file_as_string(caminho)
	var parsed: Variant = JSON.parse_string(txt)
	return parsed
