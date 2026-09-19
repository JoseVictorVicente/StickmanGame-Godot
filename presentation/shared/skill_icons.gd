class_name SkillIcons
extends RefCounted
## Ícones de habilidades com fallback procedural quando o asset ainda não existe.

const PASTA_PADRAO := "res://sprites/ui/skills/"
const MOLDURA_ATIVA_PATH := "res://sprites/ui/skills/active_skill_frame.png"
const LIMIAR_PRETO_RECORTE := 0.12

static var _cache: Dictionary = {}
static var _frame_cache: Texture2D = null


static func get_icon(skill: SkillResource) -> Texture2D:
	if skill == null:
		return _active_placeholder()
	var chave := "%s:%s:%s:v2" % [skill.skill_id, skill.icon_path, "inner" if skill.icon_inner_only else "full"]
	if _cache.has(chave):
		return _cache[chave]
	if skill.icon_path != "" and ResourceLoader.exists(skill.icon_path):
		var textura := load(skill.icon_path) as Texture2D
		if textura != null:
			if skill.icon_inner_only:
				textura = _composite_inner_with_frame(textura)
			else:
				textura = _normalize_texture(textura)
			_cache[chave] = textura
			return textura
	_cache.erase(chave)
	var gerado := _create_placeholder(skill)
	_cache[chave] = gerado
	return gerado


## Ícone para os 5 slots de ativas disponíveis, escalado ao slot.
static func get_active_slot_icon(skill: SkillResource = null, lado: int = 64) -> Texture2D:
	var chave := "active_slot:v11:%s:%d" % [skill.skill_id if skill else "empty", lado]
	if _cache.has(chave):
		return _cache[chave]
	var fonte: Texture2D
	if skill != null and skill.icon_path != "" and ResourceLoader.exists(skill.icon_path):
		var interna := load(skill.icon_path) as Texture2D
		if skill.icon_inner_only:
			fonte = _composite_inner_with_frame(interna)
		else:
			fonte = interna
	elif skill != null:
		fonte = _get_active_frame_texture()
	else:
		fonte = _get_active_frame_texture()
	if fonte == null:
		fonte = _active_placeholder()
	var pronta := _texture_for_slot(fonte, lado)
	_cache[chave] = pronta
	return pronta


static func slot_width(tamanho_slot: Vector2) -> int:
	return int(mini(tamanho_slot.x, tamanho_slot.y))


static func apply_to_button(
	botao: Button,
	skill: SkillResource,
	tamanho_slot: Vector2
) -> void:
	if botao == null:
		return
	var lado := slot_width(tamanho_slot)
	botao.custom_minimum_size = tamanho_slot
	botao.expand_icon = true
	botao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	botao.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	botao.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	botao.add_theme_constant_override("icon_max_width", lado)
	if skill == null:
		botao.icon = null
	else:
		botao.icon = get_icon(skill)


static func apply_to_texture_button(
	botao: TextureButton,
	skill: SkillResource,
	tamanho_slot: Vector2
) -> void:
	if botao == null:
		return
	var lado := slot_width(tamanho_slot)
	var textura := get_active_slot_icon(skill, lado)
	botao.custom_minimum_size = tamanho_slot
	botao.size = tamanho_slot
	botao.ignore_texture_size = true
	botao.stretch_mode = TextureButton.STRETCH_SCALE
	botao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	botao.texture_normal = textura
	botao.texture_hover = textura
	botao.texture_pressed = textura
	botao.texture_disabled = textura
	botao.disabled = skill == null
	botao.mouse_filter = Control.MOUSE_FILTER_STOP if skill else Control.MOUSE_FILTER_IGNORE


static func _texture_for_slot(textura: Texture2D, lado: int) -> Texture2D:
	if textura == null or lado <= 0:
		return textura
	var img := textura.get_image()
	if img == null or img.is_empty():
		return textura
	var recortada := _trim_outer_black(img)
	var copia := recortada.duplicate()
	copia.resize(lado, lado, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(copia)


static func _composite_inner_with_frame(arte_interna: Texture2D) -> Texture2D:
	var moldura := _get_active_frame_texture()
	if moldura == null or arte_interna == null:
		return arte_interna
	var frame_img := moldura.get_image()
	var inner_img := arte_interna.get_image()
	if frame_img == null or frame_img.is_empty() or inner_img == null or inner_img.is_empty():
		return moldura
	frame_img = _trim_outer_black(frame_img)
	inner_img = _trim_outer_black(inner_img)
	var resultado := frame_img.duplicate()
	var area := _frame_inner_rect(frame_img.get_width(), frame_img.get_height())
	var escalada := _scale_image_cover(inner_img, area.size)
	resultado.blit_rect(
		escalada,
		Rect2i(0, 0, area.size.x, area.size.y),
		area.position
	)
	return ImageTexture.create_from_image(resultado)


static func _frame_inner_rect(largura: int, altura: int) -> Rect2i:
	# Abertura interna da moldura RPG (alinhada aos ícones completos do arqueiro).
	var margem := int(mini(largura, altura) * 0.13)
	return Rect2i(margem, margem, largura - margem * 2, altura - margem * 2)


static func _scale_image_cover(img: Image, tamanho_dest: Vector2i) -> Image:
	if tamanho_dest.x <= 0 or tamanho_dest.y <= 0:
		return img
	var largura := img.get_width()
	var altura := img.get_height()
	if largura <= 0 or altura <= 0:
		return img
	var escala := maxf(float(tamanho_dest.x) / largura, float(tamanho_dest.y) / altura)
	var nova_largura := maxi(1, int(largura * escala))
	var nova_altura := maxi(1, int(altura * escala))
	var copia := img.duplicate()
	copia.resize(nova_largura, nova_altura, Image.INTERPOLATE_NEAREST)
	var corte_x := (nova_largura - tamanho_dest.x) / 2
	var corte_y := (nova_altura - tamanho_dest.y) / 2
	return copia.get_region(Rect2i(corte_x, corte_y, tamanho_dest.x, tamanho_dest.y))


static func _get_active_frame_texture() -> Texture2D:
	if _frame_cache != null:
		return _frame_cache
	if ResourceLoader.exists(MOLDURA_ATIVA_PATH):
		_frame_cache = load(MOLDURA_ATIVA_PATH) as Texture2D
	return _frame_cache


static func _normalize_texture(textura: Texture2D) -> Texture2D:
	var img := textura.get_image()
	if img == null or img.is_empty():
		return textura
	var recortada := _trim_outer_black(img)
	if recortada.get_width() == img.get_width() and recortada.get_height() == img.get_height():
		return textura
	return ImageTexture.create_from_image(recortada)


static func _trim_outer_black(img: Image) -> Image:
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
			if not _pixel_counts_for_trim(img.get_pixel(x, y)):
				continue
			encontrou = true
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	if not encontrou:
		return img
	return img.get_region(Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1))


static func _pixel_counts_for_trim(cor: Color) -> bool:
	if cor.a < 0.05:
		return false
	return cor.r + cor.g + cor.b > LIMIAR_PRETO_RECORTE


static func _active_placeholder() -> Texture2D:
	return _create_square(Color(0.2, 0.24, 0.2, 1), Color(0.45, 0.62, 0.4, 1))


static func _create_placeholder(skill: SkillResource) -> Texture2D:
	var base := Color(0.14, 0.18, 0.14, 1)
	var borda := Color(0.42, 0.68, 0.38, 1)
	if skill.type == SkillResource.Type.PASSIVE:
		base = Color(0.12, 0.14, 0.22, 1)
		borda = Color(0.42, 0.52, 0.82, 1)
	return _create_square(base, borda)


static func _create_square(fundo: Color, borda: Color) -> Texture2D:
	var img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	img.fill(fundo)
	for x in 48:
		for y in 48:
			if x == 0 or y == 0 or x == 47 or y == 47:
				img.set_pixel(x, y, borda)
	return ImageTexture.create_from_image(img)
