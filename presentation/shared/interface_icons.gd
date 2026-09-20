class_name InterfaceIcons
extends RefCounted
## Ícones recortados da interface de referência.

const PASTA := "res://sprites/ui/"

static var _cache: Dictionary = {}


static func equipment_slot(tipo: ItemData.Type) -> Texture2D:
	var arquivo := ""
	match tipo:
		ItemData.Type.WEAPON:
			arquivo = "weapon.png"
		ItemData.Type.OFFHAND:
			arquivo = "offhand.png"
		ItemData.Type.HELMET:
			arquivo = "helmet.png"
		ItemData.Type.CHEST:
			arquivo = "chest.png"
		ItemData.Type.GLOVES:
			arquivo = "gloves.png"
		ItemData.Type.PANTS:
			arquivo = "pants.png"
		ItemData.Type.BOOTS:
			arquivo = "boots.png"
		ItemData.Type.BELT:
			arquivo = "belt.png"
		ItemData.Type.PENDANT:
			arquivo = "pendant.png"
		ItemData.Type.RING:
			arquivo = "ring.png"
		ItemData.Type.BRACELET:
			arquivo = "bracelet.png"
		ItemData.Type.PET:
			arquivo = "pet.png"
		_:
			arquivo = "weapon.png"
	return _load_texture(arquivo)


static func bar_icon(nome: String) -> Texture2D:
	return _load_texture("nav_%s.png" % nome)


static func setup_icon_button(botao: Button, caminho_icone: String, lado: int = 42) -> void:
	if botao == null:
		return
	var sem_fundo := StyleBoxEmpty.new()
	botao.add_theme_stylebox_override("normal", sem_fundo)
	botao.add_theme_stylebox_override("hover", sem_fundo)
	botao.add_theme_stylebox_override("pressed", sem_fundo)
	botao.add_theme_stylebox_override("focus", sem_fundo)
	botao.text = ""
	if ResourceLoader.exists(caminho_icone):
		botao.icon = load(caminho_icone)
	botao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	botao.expand_icon = true
	botao.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	botao.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	botao.add_theme_constant_override("icon_max_width", lado)
	botao.custom_minimum_size = Vector2(lado, lado)


static func base_gem() -> Texture2D:
	return _load_texture("gem.png")


static func gem_icon(raridade: ItemData.Rarity) -> Texture2D:
	var chave := "gema_raridade:%d" % int(raridade)
	if _cache.has(chave):
		return _cache[chave]
	var textura := _create_gem_icon_with_outline(raridade)
	_cache[chave] = textura
	return textura


static func _create_gem_icon_with_outline(raridade: ItemData.Rarity) -> Texture2D:
	const TAMANHO := 32
	const MARGEM := 2
	var base := base_gem()
	if base == null:
		return _procedural_gem_icon(raridade)
	var origem := base.get_image()
	if origem.is_empty():
		return _procedural_gem_icon(raridade)
	origem = origem.duplicate()
	var area := TAMANHO - MARGEM * 2
	origem.resize(area, area, Image.INTERPOLATE_NEAREST)
	var img := Image.create(TAMANHO, TAMANHO, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in area:
		for x in area:
			img.set_pixel(MARGEM + x, MARGEM + y, origem.get_pixel(x, y))
	_draw_rarity_outline(img, ItemData.color_for_rarity(raridade), 2)
	return ImageTexture.create_from_image(img)


static func _draw_rarity_outline(img: Image, cor: Color, espessura: int) -> void:
	var original := img.duplicate()
	var largura := img.get_width()
	var altura := img.get_height()
	for y in altura:
		for x in largura:
			if original.get_pixel(x, y).a > 0.05:
				continue
			var pintar := false
			for dy in range(-espessura, espessura + 1):
				for dx in range(-espessura, espessura + 1):
					if dx == 0 and dy == 0:
						continue
					var nx := x + dx
					var ny := y + dy
					if nx < 0 or ny < 0 or nx >= largura or ny >= altura:
						continue
					if original.get_pixel(nx, ny).a > 0.05:
						pintar = true
						break
				if pintar:
					break
			if pintar:
				img.set_pixel(x, y, cor)


static func _procedural_gem_icon(raridade: ItemData.Rarity) -> Texture2D:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(8, 24):
		for x in range(8, 24):
			img.set_pixel(x, y, Color(0.2, 0.45, 0.95, 1))
	_draw_rarity_outline(img, ItemData.color_for_rarity(raridade), 2)
	return ImageTexture.create_from_image(img)


static func _load_texture(arquivo: String) -> Texture2D:
	if _cache.has(arquivo):
		return _cache[arquivo]
	var caminho := PASTA + arquivo
	if not ResourceLoader.exists(caminho):
		_cache[arquivo] = null
		return null
	var tex := load(caminho) as Texture2D
	_cache[arquivo] = tex
	return tex
