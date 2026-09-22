class_name HeroSpritesheet
extends RefCounted
## Monta SpriteFrames do arqueiro (frames individuais) e utilitários de combate.

const ID_ARQUEIRO := "archer"
const FRAMES_DIR := "res://sprites/heroes/archer_fennec/"
const FRAME_COUNT := 21
const ESCALA_STICK := Vector2(1.25, 1.25)
const ESCALA_ARQUEIRO := Vector2(0.55, 0.55)
const BARRA_STICK := Vector2(-14, -38)
const ARCHER_BAR := Vector2(-14, -78)
const ARCHER_GROUND_OFFSET := Vector2(0, 10)

## Índice do frame dentro da animação "Ataque" em que a flecha é disparada.
const ARCHER_ATTACK_RELEASE_INDEX := 9
const ARCHER_ATTACK_START := 4
const ARCHER_ATTACK_END := 16
const ARCHER_ARROW_SPAWN := Vector2(22, -14)
const ATTACK_INTERVAL_BASE := 1.0

static var _frames: Dictionary = {}
static var _textures: Dictionary = {}


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


static func attack_release_frame(id_classe: String) -> int:
	if id_classe == ID_ARQUEIRO:
		return ARCHER_ATTACK_RELEASE_INDEX
	return 4


static func arrow_spawn_offset(id_classe: String) -> Vector2:
	if id_classe == ID_ARQUEIRO:
		return ARCHER_ARROW_SPAWN
	return Vector2(18, -8)


static func ground_offset(id_classe: String) -> Vector2:
	if id_classe == ID_ARQUEIRO:
		return ARCHER_GROUND_OFFSET
	return Vector2.ZERO


static func attack_animation_speed(id_classe: String, attack_speed: float) -> float:
	if id_classe != ID_ARQUEIRO:
		return 14.0
	var frame_count := ARCHER_ATTACK_END - ARCHER_ATTACK_START + 1
	var intervalo := ATTACK_INTERVAL_BASE / maxf(0.25, attack_speed)
	return float(frame_count) / (intervalo * 0.9)


static func _build_archer() -> SpriteFrames:
	var sf := SpriteFrames.new()
	_add_anim(sf, "Idle", _load_frame_range(0, 3), true, 5.0)
	_add_anim(sf, "Ataque", _load_frame_range(ARCHER_ATTACK_START, ARCHER_ATTACK_END), false, 20.0)
	_add_anim(sf, "Hit", _load_frame_range(5, 7), false, 12.0)
	_add_anim(sf, "Morte", _load_frame_range(8, 5), false, 8.0)
	return sf


static func _load_frame_range(from_frame: int, to_frame: int) -> Array[Texture2D]:
	var lista: Array[Texture2D] = []
	if from_frame <= to_frame:
		for i in range(from_frame, to_frame + 1):
			var tex := _load_frame(i)
			if tex:
				lista.append(tex)
	else:
		for i in range(from_frame, to_frame - 1, -1):
			var tex := _load_frame(i)
			if tex:
				lista.append(tex)
	return lista


static func _load_frame(index: int) -> Texture2D:
	var path := "%sframe_%03d.png" % [FRAMES_DIR, index]
	return _load_texture(path)


static func _add_anim(sf: SpriteFrames, nome: String, texturas: Array[Texture2D], loop: bool, fps: float) -> void:
	if texturas.is_empty():
		return
	if not sf.has_animation(nome):
		sf.add_animation(nome)
	sf.set_animation_loop(nome, loop)
	sf.set_animation_speed(nome, fps)
	for tex in texturas:
		sf.add_frame(nome, tex)


static func _load_texture(caminho: String) -> Texture2D:
	if _textures.has(caminho):
		return _textures[caminho] as Texture2D
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
		_textures[caminho] = tex
	return tex
