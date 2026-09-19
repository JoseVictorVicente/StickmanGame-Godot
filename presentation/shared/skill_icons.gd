class_name SkillIcons
extends RefCounted
## Ícones de habilidades com fallback procedural quando o asset ainda não existe.

const PASTA_PADRAO := "res://sprites/ui/skills/"
const MOLDURA_ATIVA_PATH := "res://sprites/ui/skills/active_skill_frame.png"
const LIMIAR_PRETO_RECORTE := 0.12
const PLACEHOLDER_SIZE := 48
const DIGIT_WIDTH := 5
const DIGIT_HEIGHT := 7

static var _cache: Dictionary = {}
static var _frame_cache: Texture2D = null

static var _DIGIT_PATTERNS: Dictionary = {
	"0": ["01110", "10001", "10001", "10001", "10001", "10001", "01110"],
	"1": ["00100", "01100", "00100", "00100", "00100", "00100", "01110"],
	"2": ["01110", "10001", "00001", "00110", "01000", "10000", "11111"],
	"3": ["11110", "00001", "00001", "01110", "00001", "00001", "11110"],
	"4": ["00010", "00110", "01010", "10010", "11111", "00010", "00010"],
	"5": ["11111", "10000", "10000", "11110", "00001", "00001", "11110"],
	"6": ["01110", "10000", "10000", "11110", "10001", "10001", "01110"],
	"7": ["11111", "00001", "00010", "00100", "01000", "01000", "01000"],
	"8": ["01110", "10001", "10001", "01110", "10001", "10001", "01110"],
	"9": ["01110", "10001", "10001", "01111", "00001", "00001", "01110"],
}


static func get_icon(skill: SkillResource) -> Texture2D:
	if skill == null:
		return _active_placeholder()
	var chave := "%s:%s:%s:%d:v3" % [
		skill.skill_id,
		skill.icon_path,
		"inner" if skill.icon_inner_only else "full",
		skill.sort_order,
	]
	if _cache.has(chave):
		return _cache[chave]
	if _has_icon_file(skill):
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
	var ordem := skill.sort_order if skill else 0
	var chave := "active_slot:v12:%s:%d:%d" % [skill.skill_id if skill else "empty", ordem, lado]
	if _cache.has(chave):
		return _cache[chave]
	var fonte: Texture2D
	if skill != null and _has_icon_file(skill):
		var interna := load(skill.icon_path) as Texture2D
		if skill.icon_inner_only:
			fonte = _composite_inner_with_frame(interna)
		else:
			fonte = interna
	elif skill != null:
		fonte = _composite_inner_with_frame(_create_number_inner_texture(skill))
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


static func _has_icon_file(skill: SkillResource) -> bool:
	return skill != null and skill.icon_path != "" and ResourceLoader.exists(skill.icon_path)


static func _label_for_skill(skill: SkillResource) -> String:
	var ordem := maxi(1, skill.sort_order)
	return str(ordem)


static func _placeholder_palette(skill: SkillResource) -> Dictionary:
	if skill.type == SkillResource.Type.PASSIVE:
		return {
			"base": Color(0.12, 0.14, 0.22, 1),
			"border": Color(0.42, 0.52, 0.82, 1),
			"text": Color(0.88, 0.92, 1.0, 1),
		}
	return {
		"base": Color(0.14, 0.18, 0.14, 1),
		"border": Color(0.42, 0.68, 0.38, 1),
		"text": Color(0.98, 0.9, 0.55, 1),
	}


static func _create_placeholder(skill: SkillResource) -> Texture2D:
	return ImageTexture.create_from_image(_render_number_image(skill))


static func _create_number_inner_texture(skill: SkillResource) -> Texture2D:
	return ImageTexture.create_from_image(_render_number_image(skill))


static func _render_number_image(skill: SkillResource) -> Image:
	var paleta := _placeholder_palette(skill)
	var img := Image.create(PLACEHOLDER_SIZE, PLACEHOLDER_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(paleta["base"])
	_draw_border(img, paleta["border"])
	_draw_digits(img, _label_for_skill(skill), paleta["text"])
	return img


static func _draw_border(img: Image, borda: Color) -> void:
	var largura := img.get_width()
	var altura := img.get_height()
	for x in largura:
		img.set_pixel(x, 0, borda)
		img.set_pixel(x, altura - 1, borda)
	for y in altura:
		img.set_pixel(0, y, borda)
		img.set_pixel(largura - 1, y, borda)


static func _draw_digits(img: Image, texto: String, cor: Color) -> void:
	var escala := 3 if texto.length() <= 1 else 2
	var bloco_largura := DIGIT_WIDTH * escala
	var bloco_altura := DIGIT_HEIGHT * escala
	var espacamento := escala
	var largura_total := texto.length() * bloco_largura + maxi(0, texto.length() - 1) * espacamento
	var altura_total := bloco_altura
	var inicio_x := (img.get_width() - largura_total) / 2
	var inicio_y := (img.get_height() - altura_total) / 2
	for indice in texto.length():
		var digito := texto.substr(indice, 1)
		var offset_x := inicio_x + indice * (bloco_largura + espacamento)
		_draw_digit(img, digito, Vector2i(offset_x, inicio_y), escala, cor)


static func _draw_digit(img: Image, digito: String, origem: Vector2i, escala: int, cor: Color) -> void:
	var padrao: Array = _DIGIT_PATTERNS.get(digito, [])
	for y in padrao.size():
		var linha := str(padrao[y])
		for x in linha.length():
			if linha[x] != "1":
				continue
			for dy in escala:
				for dx in escala:
					var px := origem.x + x * escala + dx
					var py := origem.y + y * escala + dy
					if px < 0 or py < 0 or px >= img.get_width() or py >= img.get_height():
						continue
					img.set_pixel(px, py, cor)


static func _create_square(fundo: Color, borda: Color) -> Texture2D:
	var img := Image.create(PLACEHOLDER_SIZE, PLACEHOLDER_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(fundo)
	_draw_border(img, borda)
	return ImageTexture.create_from_image(img)
