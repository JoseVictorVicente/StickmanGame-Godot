class_name IconesSkill
extends RefCounted
## Ícones de habilidades com fallback procedural quando o asset ainda não existe.

const PASTA_PADRAO := "res://sprites/ui/skills/"
const LIMIAR_PRETO_RECORTE := 0.12

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
			var normalizada := _normalizar_textura(textura)
			_cache[chave] = normalizada
			return normalizada
	_cache.erase(chave)
	var gerado := _criar_placeholder(skill)
	_cache[chave] = gerado
	return gerado


static func largura_para_slot(tamanho_slot: Vector2) -> int:
	return int(mini(tamanho_slot.x, tamanho_slot.y))


static func aplicar_no_botao(botao: Button, skill: SkillResource, tamanho_slot: Vector2) -> void:
	if botao == null:
		return
	var lado := largura_para_slot(tamanho_slot)
	botao.custom_minimum_size = tamanho_slot
	botao.expand_icon = true
	botao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	botao.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	botao.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	botao.add_theme_constant_override("icon_max_width", lado)
	if skill == null:
		botao.icon = null
	else:
		botao.icon = obter(skill)


static func _normalizar_textura(textura: Texture2D) -> Texture2D:
	var img := textura.get_image()
	if img == null or img.is_empty():
		return textura
	var recortada := _recortar_margens(img)
	if recortada.get_width() == img.get_width() and recortada.get_height() == img.get_height():
		return textura
	return ImageTexture.create_from_image(recortada)


static func _recortar_margens(img: Image) -> Image:
	var largura := img.get_width()
	var altura := img.get_height()
	if largura <= 0 or altura <= 0:
		return img
	var min_x := largura
	var min_y := altura
	var max_x := 0
	var max_y := 0
	var encontrou := false
	for y in altura:
		for x in largura:
			if not _pixel_conta_para_recorte(img.get_pixel(x, y)):
				continue
			encontrou = true
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	if not encontrou:
		return img
	var rect := Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
	return img.get_region(rect)


static func _pixel_conta_para_recorte(cor: Color) -> bool:
	if cor.a < 0.05:
		return false
	return cor.r + cor.g + cor.b > LIMIAR_PRETO_RECORTE


static func _placeholder_ativo() -> Texture2D:
	return _criar_quadrado(Color(0.2, 0.24, 0.2, 1), Color(0.45, 0.62, 0.4, 1))


static func _criar_placeholder(skill: SkillResource) -> Texture2D:
	var base := Color(0.14, 0.18, 0.14, 1)
	var borda := Color(0.42, 0.68, 0.38, 1)
	if skill.type == SkillResource.Type.PASSIVE:
		base = Color(0.12, 0.14, 0.22, 1)
		borda = Color(0.42, 0.52, 0.82, 1)
	return _criar_quadrado(base, borda)


static func _criar_quadrado(fundo: Color, borda: Color) -> Texture2D:
	var img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	img.fill(fundo)
	for x in 48:
		for y in 48:
			if x == 0 or y == 0 or x == 47 or y == 47:
				img.set_pixel(x, y, borda)
	return ImageTexture.create_from_image(img)
