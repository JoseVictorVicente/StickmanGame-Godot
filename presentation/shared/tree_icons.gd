class_name TreeIcons
extends RefCounted
## Ícones da árvore de habilidades. O estado disabled é gerado a partir de normal.png.

const PASTA := "res://sprites/ui/skill_tree/"

static var _cache: Dictionary = {}


static func get_icon(tipo: int, estado: String = "normal") -> Texture2D:
	var chave_pasta := _folder_for_type(tipo)
	if chave_pasta == "":
		return _placeholder(estado == "disabled")
	var cache_key := "%s:%s" % [chave_pasta, estado]
	if _cache.has(cache_key):
		return _cache[cache_key]
	var normal := _load_normal(chave_pasta)
	if normal == null:
		return _placeholder(estado == "disabled")
	var textura := _create_disabled(normal) if estado == "disabled" else normal
	_cache[cache_key] = textura
	return textura


static func apply_to_button(botao: TextureButton, tipo: int, bloqueado: bool) -> void:
	if botao == null:
		return
	botao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var textura := get_icon(tipo, "disabled") if bloqueado else get_icon(tipo, "normal")
	botao.texture_normal = textura
	botao.texture_hover = textura
	botao.texture_pressed = textura
	botao.texture_disabled = get_icon(tipo, "disabled")
	botao.disabled = false


static func _load_normal(chave_pasta: String) -> Texture2D:
	var cache_key := "%s:normal" % chave_pasta
	if _cache.has(cache_key):
		return _cache[cache_key]
	var caminho := PASTA + chave_pasta + "/normal.png"
	if not ResourceLoader.exists(caminho):
		return null
	var textura: Texture2D = load(caminho)
	if textura == null:
		return null
	_cache[cache_key] = textura
	return textura


static func _create_disabled(normal: Texture2D) -> Texture2D:
	var img := normal.get_image()
	if img.is_empty():
		return normal
	img = img.duplicate()
	for y in img.get_height():
		for x in img.get_width():
			var cor := img.get_pixel(x, y)
			if cor.a < 0.01:
				continue
			var cinza := cor.r * 0.299 + cor.g * 0.587 + cor.b * 0.114
			cor.r = cinza * 0.42 + 0.04
			cor.g = cinza * 0.40 + 0.04
			cor.b = cinza * 0.44 + 0.05
			cor.a *= 0.72
			img.set_pixel(x, y, cor)
	return ImageTexture.create_from_image(img)


static func _folder_for_type(tipo: int) -> String:
	match tipo:
		SkillTreeDefinition.BonusType.ATTACK:
			return "attack"
		SkillTreeDefinition.BonusType.ATTACK_PCT:
			return "attack_pct"
		SkillTreeDefinition.BonusType.HP:
			return "health"
		SkillTreeDefinition.BonusType.BONUS_XP:
			return "xp"
		SkillTreeDefinition.BonusType.GOLD_BONUS:
			return "gold"
		SkillTreeDefinition.BonusType.ATTACK_SPEED:
			return "attack_speed"
		SkillTreeDefinition.BonusType.CRIT_CHANCE:
			return "crit_chance"
		SkillTreeDefinition.BonusType.CRIT_DAMAGE:
			return "crit_damage"
		SkillTreeDefinition.BonusType.EVASION:
			return "evasion"
		SkillTreeDefinition.BonusType.PHYS_RES:
			return "physical_res"
		SkillTreeDefinition.BonusType.ARCANE_RES:
			return "arcane_res"
		SkillTreeDefinition.BonusType.ELEMENTAL_RES:
			return "elemental_res"
		SkillTreeDefinition.BonusType.WAREHOUSE:
			return "warehouse"
	return ""


static func _placeholder(disabled: bool = false) -> Texture2D:
	var chave := "placeholder:disabled" if disabled else "placeholder:normal"
	if _cache.has(chave):
		return _cache[chave]
	if disabled:
		var desativada := _create_disabled(_placeholder(false))
		_cache[chave] = desativada
		return desativada
	var img := Image.create(38, 38, false, Image.FORMAT_RGBA8)
	var fundo := Color(0.08, 0.07, 0.06, 1)
	var borda := Color(0.72, 0.58, 0.28, 0.8)
	img.fill(fundo)
	for x in 38:
		for y in 38:
			if x == 0 or y == 0 or x == 37 or y == 37:
				img.set_pixel(x, y, borda)
	var textura := ImageTexture.create_from_image(img)
	_cache[chave] = textura
	return textura
