class_name InterfaceIcons
extends RefCounted
## Ícones recortados da interface de referência.

const PASTA := "res://sprites/ui/"

static var _cache: Dictionary = {}


static func equipment_slot(tipo: ItemData.Tipo) -> Texture2D:
	var arquivo := ""
	match tipo:
		ItemData.Tipo.ARMA:
			arquivo = "arma.png"
		ItemData.Tipo.SECUNDARIA:
			arquivo = "secundaria.png"
		ItemData.Tipo.CAPACETE:
			arquivo = "capacete.png"
		ItemData.Tipo.PEITORAL:
			arquivo = "peitoral.png"
		ItemData.Tipo.LUVA:
			arquivo = "luva.png"
		ItemData.Tipo.CALCA:
			arquivo = "calca.png"
		ItemData.Tipo.BOTA:
			arquivo = "bota.png"
		ItemData.Tipo.CINTO:
			arquivo = "cinto.png"
		ItemData.Tipo.PINGENTE:
			arquivo = "pingente.png"
		ItemData.Tipo.ANEL:
			arquivo = "anel.png"
		ItemData.Tipo.BRACELETE:
			arquivo = "bracelete.png"
		ItemData.Tipo.PET:
			arquivo = "pet.png"
		_:
			arquivo = "arma.png"
	return _load_texture(arquivo)


static func bar_icon(nome: String) -> Texture2D:
	return _load_texture("nav_%s.png" % nome)


static func base_gem() -> Texture2D:
	return _load_texture("gema.png")


static func gem_icon(raridade: ItemData.Raridade) -> Texture2D:
	var chave := "gema_raridade:%d" % int(raridade)
	if _cache.has(chave):
		return _cache[chave]
	var textura := _create_gem_icon_with_outline(raridade)
	_cache[chave] = textura
	return textura


static func _create_gem_icon_with_outline(raridade: ItemData.Raridade) -> Texture2D:
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
	_draw_rarity_outline(img, ItemData.cor_de_raridade(raridade), 2)
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


static func _procedural_gem_icon(raridade: ItemData.Raridade) -> Texture2D:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(8, 24):
		for x in range(8, 24):
			img.set_pixel(x, y, Color(0.2, 0.45, 0.95, 1))
	_draw_rarity_outline(img, ItemData.cor_de_raridade(raridade), 2)
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
