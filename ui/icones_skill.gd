class_name IconesSkill
extends RefCounted
## Ícones de habilidades com fallback procedural quando o asset ainda não existe.

const PASTA_PADRAO := "res://sprites/ui/skills/"

static var _cache: Dictionary = {}


static func obter(skill: SkillResource) -> Texture2D:
	if skill == null:
		return _placeholder_ativo()
	var chave := "%s:%s" % [skill.skill_id, skill.icon_path]
	if _cache.has(chave):
		return _cache[chave]
	if skill.icon_path != "" and ResourceLoader.exists(skill.icon_path):
		var textura := load(skill.icon_path) as Texture2D
		if textura != null:
			_cache[chave] = textura
			return textura
	var gerado := _criar_placeholder(skill)
	_cache[chave] = gerado
	return gerado


static func _placeholder_ativo() -> Texture2D:
	return _criar_quadrado(Color(0.2, 0.24, 0.2, 1), Color(0.45, 0.62, 0.4, 1), "?")


static func _criar_placeholder(skill: SkillResource) -> Texture2D:
	var base := Color(0.14, 0.18, 0.14, 1)
	var borda := Color(0.42, 0.68, 0.38, 1)
	if skill.type == SkillResource.Type.PASSIVE:
		base = Color(0.12, 0.14, 0.22, 1)
		borda = Color(0.42, 0.52, 0.82, 1)
	var letra := skill.skill_name.substr(0, 1).to_upper() if skill.skill_name != "" else "?"
	return _criar_quadrado(base, borda, letra)


static func _criar_quadrado(fundo: Color, borda: Color, letra: String) -> Texture2D:
	var img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	img.fill(fundo)
	for x in 48:
		for y in 48:
			if x == 0 or y == 0 or x == 47 or y == 47:
				img.set_pixel(x, y, borda)
	var font := ThemeDB.fallback_font
	var tamanho := ThemeDB.fallback_font_size + 8
	if font != null:
		img.fill_rect(Rect2i(8, 8, 32, 32), fundo.lightened(0.08))
		# Letra central simplificada: ponto no centro se fonte indisponível em runtime puro
	return ImageTexture.create_from_image(img)
