class_name ItemData
extends Resource
## Resource de item (equipamento) usado pelo inventário e pelo banco de dados.

enum Type {
	HELMET,
	CHEST,
	WEAPON,
	OFFHAND,
	GLOVES,
	PANTS,
	BOOTS,
	BELT,
	PENDANT,
	RING,
	BRACELET,
	PET,
	GEM,
}

enum GemAttribute {
	ATTACK,
	ATTACK_PCT,
	HP,
	HP_PCT,
	ATTACK_SPEED,
	CRIT_CHANCE,
	CRIT_DAMAGE,
	EVASION,
	PHYS_RES,
	ARCANE_RES,
	ELEMENTAL_RES,
}

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY,
	MYTHIC,
	PRIMORDIAL,
	ASTRAL,
	DIVINE,
	TRANSCENDENTAL,
}

enum RequiredClass {
	ALL,
	WARRIOR,
	MAGE,
	ARCHER,
	BARBARIAN,
	TANK,
	PRIEST,
}

enum Category {
	EQUIPMENT,
	ACCESSORY,
	GEM,
}

const ITEM_LEVELS: Array[int] = [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 70, 80]

@export var id: String = ""
@export var display_name: String = ""
@export var name_key: String = ""
@export var icone: Texture2D
@export var item_type: Type = Type.WEAPON
@export var rarity: Rarity = Rarity.COMMON
@export var item_level: int = 5
@export var damage_bonus: int = 0
@export var hp_bonus: int = 0
@export var required_class: RequiredClass = RequiredClass.ALL
@export var gem_attribute: GemAttribute = GemAttribute.ATTACK
@export var gem_value: float = 0.0
var embedded_gem: Dictionary = {}


func get_display_name() -> String:
	if name_key != "":
		var translated := tr(name_key)
		if translated != name_key:
			return translated
	return display_name


func description() -> String:
	return tooltip_text()


func tooltip_text() -> String:
	var linhas: PackedStringArray = [get_display_name(), rarity_name()]
	if is_gem():
		linhas.append(TranslationServer.translate(LocaleKeys.ITEM_GEM_ATTR_VALUE) % [gem_attribute_name(gem_attribute), gem_value_text()])
		linhas.append(TranslationServer.translate(LocaleKeys.ITEM_VALUE) % dismantle_value())
		return "\n".join(linhas)
	linhas.append(TranslationServer.translate(LocaleKeys.ITEM_BONUS_DAMAGE) % damage_bonus)
	if hp_bonus != 0:
		linhas.append(TranslationServer.translate(LocaleKeys.ITEM_BONUS_HP) % hp_bonus)
	if has_embedded_gem():
		var linha_gema := gem_slot_line()
		if linha_gema != "":
			linhas.append(linha_gema)
	elif has_gem_slot():
		linhas.append(gem_slot_line())
	if required_class != RequiredClass.ALL:
		linhas.append(TranslationServer.translate(LocaleKeys.ITEM_CLASS_REQUIRED) % required_class_display_name())
	linhas.append(TranslationServer.translate(LocaleKeys.ITEM_LEVEL) % item_level)
	linhas.append(TranslationServer.translate(LocaleKeys.ITEM_VALUE) % dismantle_value())
	return "\n".join(linhas)


static func type_display_name(p_tipo: Type) -> String:
	match p_tipo:
		Type.HELMET:
			return TranslationServer.translate(LocaleKeys.ITEM_TYPE_HELMET)
		Type.CHEST:
			return TranslationServer.translate(LocaleKeys.ITEM_TYPE_CHEST)
		Type.WEAPON:
			return TranslationServer.translate(LocaleKeys.ITEM_TYPE_WEAPON)
		Type.OFFHAND:
			return TranslationServer.translate(LocaleKeys.ITEM_TYPE_OFFHAND)
		Type.GLOVES:
			return TranslationServer.translate(LocaleKeys.ITEM_TYPE_GLOVES)
		Type.PANTS:
			return TranslationServer.translate(LocaleKeys.ITEM_TYPE_PANTS)
		Type.BOOTS:
			return TranslationServer.translate(LocaleKeys.ITEM_TYPE_BOOTS)
		Type.BELT:
			return TranslationServer.translate(LocaleKeys.ITEM_TYPE_BELT)
		Type.PENDANT:
			return TranslationServer.translate(LocaleKeys.ITEM_TYPE_PENDANT)
		Type.RING:
			return TranslationServer.translate(LocaleKeys.ITEM_TYPE_RING)
		Type.BRACELET:
			return TranslationServer.translate(LocaleKeys.ITEM_TYPE_BRACELET)
		Type.PET:
			return TranslationServer.translate(LocaleKeys.ITEM_TYPE_PET)
		Type.GEM:
			return TranslationServer.translate(LocaleKeys.ITEM_TYPE_GEM)
		_:
			return TranslationServer.translate(LocaleKeys.ITEM_TYPE_GENERIC)


static func equip_slot_label_key(p_tipo: Type) -> String:
	match p_tipo:
		Type.WEAPON:
			return LocaleKeys.INV_SLOT_PRIMARY
		Type.OFFHAND:
			return LocaleKeys.INV_SLOT_OFFHAND
		Type.HELMET:
			return LocaleKeys.INV_SLOT_HELMET
		Type.CHEST:
			return LocaleKeys.INV_SLOT_CHEST
		Type.GLOVES:
			return LocaleKeys.INV_SLOT_GLOVES
		Type.PANTS:
			return LocaleKeys.INV_SLOT_PANTS
		Type.BOOTS:
			return LocaleKeys.INV_SLOT_BOOTS
		Type.BELT:
			return LocaleKeys.INV_SLOT_BELT
		Type.PENDANT:
			return LocaleKeys.INV_SLOT_PENDANT
		Type.RING:
			return LocaleKeys.INV_SLOT_RING
		Type.BRACELET:
			return LocaleKeys.INV_SLOT_BRACELET
		Type.PET:
			return LocaleKeys.INV_SLOT_PET
		_:
			return LocaleKeys.ITEM_TYPE_GENERIC


func is_gem() -> bool:
	return item_type == Type.GEM


func has_gem_slot() -> bool:
	return not is_gem() and int(rarity) >= int(Rarity.LEGENDARY)


func has_embedded_gem() -> bool:
	return not embedded_gem.is_empty()


func gem_slot_line() -> String:
	if is_gem() or not has_gem_slot():
		return ""
	if has_embedded_gem():
		var gema := get_embedded_gem()
		if gema == null:
			return ""
		return TranslationServer.translate(LocaleKeys.ITEM_GEM_EMBEDDED) % [gem_attribute_name(gema.gem_attribute), gema.gem_value_text()]
	return TranslationServer.translate(LocaleKeys.ITEM_GEM_SLOT)


func gem_slot_label_color() -> Color:
	if has_embedded_gem():
		return Color(0.95, 0.78, 0.32, 1)
	return Color(0.55, 0.82, 0.95, 1)


func get_embedded_gem() -> ItemData:
	if embedded_gem.is_empty():
		return null
	return from_dictionary(embedded_gem)


func imbue_gem(gema: ItemData) -> bool:
	if gema == null or not gema.is_gem() or not has_gem_slot() or has_embedded_gem():
		return false
	embedded_gem = gema.to_dictionary()
	return true


func embedded_gem_bonus() -> Dictionary:
	var bonus := SkillTreeDefinition.empty_bonus()
	if not has_embedded_gem():
		return bonus
	var gema := get_embedded_gem()
	if gema:
		gema.apply_bonus_to(bonus)
	return bonus


func apply_bonus_to(destino: Dictionary) -> void:
	if not is_gem():
		return
	match gem_attribute:
		GemAttribute.ATTACK:
			destino["attack"] = int(destino.get("attack", 0)) + int(round(gem_value))
		GemAttribute.ATTACK_PCT:
			destino["attack_pct"] = float(destino.get("attack_pct", 0.0)) + gem_value
		GemAttribute.HP:
			destino["hp"] = int(destino.get("hp", 0)) + int(round(gem_value))
		GemAttribute.HP_PCT:
			destino["hp_pct"] = float(destino.get("hp_pct", 0.0)) + gem_value
		GemAttribute.ATTACK_SPEED:
			destino["attack_speed"] = float(destino.get("attack_speed", 0.0)) + gem_value
		GemAttribute.CRIT_CHANCE:
			destino["crit_chance"] = float(destino.get("crit_chance", 0.0)) + gem_value
		GemAttribute.CRIT_DAMAGE:
			destino["crit_damage"] = float(destino.get("crit_damage", 0.0)) + gem_value
		GemAttribute.EVASION:
			destino["evasion"] = float(destino.get("evasion", 0.0)) + gem_value
		GemAttribute.PHYS_RES:
			destino["phys_res"] = float(destino.get("phys_res", 0.0)) + gem_value
		GemAttribute.ARCANE_RES:
			destino["arcane_res"] = float(destino.get("arcane_res", 0.0)) + gem_value
		GemAttribute.ELEMENTAL_RES:
			destino["elemental_res"] = float(destino.get("elemental_res", 0.0)) + gem_value


static func gem_attribute_name(atributo: GemAttribute) -> String:
	match atributo:
		GemAttribute.ATTACK:
			return TranslationServer.translate(LocaleKeys.GEM_ATTR_ATTACK)
		GemAttribute.ATTACK_PCT:
			return TranslationServer.translate(LocaleKeys.GEM_ATTR_ATTACK_PCT)
		GemAttribute.HP:
			return TranslationServer.translate(LocaleKeys.GEM_ATTR_HP)
		GemAttribute.HP_PCT:
			return TranslationServer.translate(LocaleKeys.GEM_ATTR_HP_PCT)
		GemAttribute.ATTACK_SPEED:
			return TranslationServer.translate(LocaleKeys.GEM_ATTR_ATTACK_SPEED)
		GemAttribute.CRIT_CHANCE:
			return TranslationServer.translate(LocaleKeys.GEM_ATTR_CRIT_CHANCE)
		GemAttribute.CRIT_DAMAGE:
			return TranslationServer.translate(LocaleKeys.GEM_ATTR_CRIT_DAMAGE)
		GemAttribute.EVASION:
			return TranslationServer.translate(LocaleKeys.GEM_ATTR_EVASION)
		GemAttribute.PHYS_RES:
			return TranslationServer.translate(LocaleKeys.GEM_ATTR_PHYS_RES)
		GemAttribute.ARCANE_RES:
			return TranslationServer.translate(LocaleKeys.GEM_ATTR_ARCANE_RES)
		GemAttribute.ELEMENTAL_RES:
			return TranslationServer.translate(LocaleKeys.GEM_ATTR_ELEMENTAL_RES)
		_:
			return TranslationServer.translate(LocaleKeys.GEM_ATTR_GENERIC)


static func base_gem_value(atributo: GemAttribute) -> float:
	match atributo:
		GemAttribute.ATTACK:
			return 5.0
		GemAttribute.ATTACK_PCT:
			return 2.0
		GemAttribute.HP:
			return 10.0
		GemAttribute.HP_PCT:
			return 2.0
		GemAttribute.ATTACK_SPEED:
			return 1.5
		GemAttribute.CRIT_CHANCE:
			return 1.0
		GemAttribute.CRIT_DAMAGE:
			return 3.0
		GemAttribute.EVASION:
			return 1.0
		GemAttribute.PHYS_RES, GemAttribute.ARCANE_RES, GemAttribute.ELEMENTAL_RES:
			return 2.0
		_:
			return 1.0


static func calculate_gem_value(atributo: GemAttribute, item_rarity: Rarity) -> float:
	var base := base_gem_value(atributo)
	return base * multiplicador_stats(item_rarity)


static func create_gem(atributo: GemAttribute, item_rarity: Rarity) -> ItemData:
	var item := ItemData.new()
	item.item_type = Type.GEM
	item.gem_attribute = atributo
	item.rarity = item_rarity
	item.item_level = ITEM_LEVELS[0]
	item.gem_value = calculate_gem_value(atributo, item_rarity)
	item.display_name = TranslationServer.translate(LocaleKeys.ITEM_GEM_OF) % gem_attribute_name(atributo)
	item.name_key = "ITEM_gema_%s" % int(atributo)
	item.id = "gema_%s" % int(atributo)
	item.required_class = RequiredClass.ALL
	item.icone = item.generate_icon()
	return item


func gem_value_text() -> String:
	if gem_attribute in [GemAttribute.ATTACK, GemAttribute.HP]:
		return str(int(round(gem_value)))
	return "%.1f%%" % gem_value


func category() -> Category:
	return categoria_do_tipo(item_type)


static func categoria_do_tipo(p_tipo: Type) -> Category:
	if p_tipo == Type.GEM:
		return Category.GEM
	match p_tipo:
		Type.BELT, Type.PENDANT, Type.RING, Type.BRACELET:
			return Category.ACCESSORY
		_:
			return Category.EQUIPMENT


static func category_display_name(p_categoria: Category) -> String:
	match p_categoria:
		Category.ACCESSORY:
			return TranslationServer.translate(LocaleKeys.ITEM_CATEGORY_ACCESSORY)
		Category.GEM:
			return TranslationServer.translate(LocaleKeys.ITEM_CATEGORY_GEM)
		_:
			return TranslationServer.translate(LocaleKeys.ITEM_CATEGORY_EQUIPMENT)


static func nome_categoria(p_categoria: Category) -> String:
	return category_display_name(p_categoria)


static func display_name_categoria(p_categoria: Category) -> String:
	return category_display_name(p_categoria)


static func tipos_da_categoria(p_categoria: Category) -> Array[Type]:
	var lista: Array[Type] = []
	for tipo_valor in Type.values():
		if categoria_do_tipo(tipo_valor as Type) == p_categoria:
			lista.append(tipo_valor as Type)
	return lista


func rarity_name() -> String:
	return rarity_display_name(rarity)


static func rarity_display_name(p_rarity: Rarity) -> String:
	match p_rarity:
		Rarity.UNCOMMON:
			return TranslationServer.translate(LocaleKeys.RARITY_UNCOMMON)
		Rarity.RARE:
			return TranslationServer.translate(LocaleKeys.RARITY_RARE)
		Rarity.EPIC:
			return TranslationServer.translate(LocaleKeys.RARITY_EPIC)
		Rarity.LEGENDARY:
			return TranslationServer.translate(LocaleKeys.RARITY_LEGENDARY)
		Rarity.MYTHIC:
			return TranslationServer.translate(LocaleKeys.RARITY_MYTHIC)
		Rarity.PRIMORDIAL:
			return TranslationServer.translate(LocaleKeys.RARITY_PRIMORDIAL)
		Rarity.ASTRAL:
			return TranslationServer.translate(LocaleKeys.RARITY_ASTRAL)
		Rarity.DIVINE:
			return TranslationServer.translate(LocaleKeys.RARITY_DIVINE)
		Rarity.TRANSCENDENTAL:
			return TranslationServer.translate(LocaleKeys.RARITY_TRANSCENDENTAL)
		_:
			return TranslationServer.translate(LocaleKeys.RARITY_COMMON)


static func forge_filter_names() -> PackedStringArray:
	var nomes := PackedStringArray([TranslationServer.translate(LocaleKeys.RARITY_ALL)])
	for i in Rarity.size():
		nomes.append(rarity_display_name(i as Rarity))
	return nomes


static func max_rarity() -> Rarity:
	return Rarity.TRANSCENDENTAL


static func is_max_rarity(p_rarity: Rarity) -> bool:
	return p_rarity >= Rarity.TRANSCENDENTAL


static func next_rarity(p_rarity: Rarity) -> Rarity:
	if is_max_rarity(p_rarity):
		return p_rarity
	return (int(p_rarity) + 1) as Rarity


static func forge_success_chance(p_rarity: Rarity) -> float:
	match p_rarity:
		Rarity.COMMON, Rarity.UNCOMMON, Rarity.RARE:
			return 1.0
		Rarity.EPIC:
			return 0.9
		Rarity.LEGENDARY:
			return 0.5
		Rarity.MYTHIC:
			return 0.45
		Rarity.PRIMORDIAL:
			return 0.4
		Rarity.ASTRAL:
			return 0.35
		Rarity.DIVINE:
			return 0.3
		Rarity.TRANSCENDENTAL:
			return 0.25
		_:
			return 1.0


static func forge_success_chance_pct(p_rarity: Rarity) -> int:
	return int(round(forge_success_chance(p_rarity) * 100.0))


static func migrate_saved_rarity(valor: int) -> Rarity:
	if valor >= 0 and valor <= 3:
		var legado: Array[Rarity] = [
			Rarity.COMMON,
			Rarity.RARE,
			Rarity.EPIC,
			Rarity.LEGENDARY,
		]
		return legado[valor]
	return clampi(valor, 0, int(Rarity.TRANSCENDENTAL)) as Rarity


static func multiplicador_stats(p_rarity: Rarity) -> float:
	return pow(1.22, float(int(p_rarity)))


static func normalize_item_level(valor: int) -> int:
	if ITEM_LEVELS.has(valor):
		return valor
	var melhor := ITEM_LEVELS[0]
	var menor_dist := absi(valor - melhor)
	for nivel in ITEM_LEVELS:
		var dist := absi(valor - nivel)
		if dist < menor_dist:
			menor_dist = dist
			melhor = nivel
	return melhor


static func item_level_index(nivel: int) -> int:
	var normalizado := normalize_item_level(nivel)
	var stage_index := ITEM_LEVELS.find(normalizado)
	return stage_index if stage_index >= 0 else 0


static func compare_sort(a: ItemData, b: ItemData) -> bool:
	if a == null and b == null:
		return false
	if a == null:
		return false
	if b == null:
		return true
	var cat_a := int(a.category())
	var cat_b := int(b.category())
	if cat_a != cat_b:
		return cat_a < cat_b
	if int(a.item_type) != int(b.item_type):
		return int(a.item_type) < int(b.item_type)
	if int(a.rarity) != int(b.rarity):
		return int(a.rarity) > int(b.rarity)
	var indice_a := item_level_index(a.item_level)
	var indice_b := item_level_index(b.item_level)
	if indice_a != indice_b:
		return indice_a > indice_b
	return sort_key(a).nocasecmp_to(sort_key(b)) < 0


static func sort_key(item: ItemData) -> String:
	if item == null:
		return ""
	if item.id != "":
		return item.id
	if item.name_key != "":
		return item.name_key
	return item.get_display_name()


static func item_level_multiplier(nivel: int) -> float:
	return pow(1.088, float(item_level_index(nivel)))


static func max_item_level(hero_progress: int) -> int:
	var maximo := ITEM_LEVELS[0]
	for nivel in ITEM_LEVELS:
		if nivel <= hero_progress + 4:
			maximo = nivel
	return maximo


static func roll_item_level(hero_progress: int) -> int:
	var maximo := max_item_level(maxi(1, hero_progress))
	var opcoes: Array[int] = []
	for nivel in ITEM_LEVELS:
		if nivel <= maximo:
			opcoes.append(nivel)
	if opcoes.is_empty():
		return ITEM_LEVELS[0]
	var pesos: Array[float] = []
	var total := 0.0
	for i in opcoes.size():
		var peso := pow(0.62, float(opcoes.size() - 1 - i))
		pesos.append(peso)
		total += peso
	var rolagem := randf() * total
	var acumulado := 0.0
	for i in opcoes.size():
		acumulado += pesos[i]
		if rolagem <= acumulado:
			return opcoes[i]
	return opcoes[0]


func can_equip(hero_level: int) -> bool:
	return hero_level >= normalize_item_level(item_level)


func required_class_name() -> String:
	return required_class_display_name()


func required_class_display_name() -> String:
	match required_class:
		RequiredClass.WARRIOR:
			return TranslationServer.translate(LocaleKeys.CLASS_WARRIOR)
		RequiredClass.MAGE:
			return TranslationServer.translate(LocaleKeys.CLASS_MAGE)
		RequiredClass.ARCHER:
			return TranslationServer.translate(LocaleKeys.CLASS_ARCHER)
		RequiredClass.BARBARIAN:
			return TranslationServer.translate(LocaleKeys.CLASS_BARBARIAN)
		RequiredClass.TANK:
			return TranslationServer.translate(LocaleKeys.CLASS_TANK)
		RequiredClass.PRIEST:
			return TranslationServer.translate(LocaleKeys.CLASS_PRIEST)
		_:
			return TranslationServer.translate(LocaleKeys.CLASS_ALL)


func display_name_requerida() -> String:
	return required_class_display_name()


func color_raridade() -> Color:
	return get_rarity_color()


func get_rarity_color() -> Color:
	return color_for_rarity(rarity)


static func color_for_rarity(p_rarity: Rarity) -> Color:
	match p_rarity:
		Rarity.UNCOMMON:
			return Color(0.35, 0.85, 0.42, 1)
		Rarity.RARE:
			return Color(0.28, 0.52, 0.98, 1)
		Rarity.EPIC:
			return Color(0.68, 0.28, 0.92, 1)
		Rarity.LEGENDARY:
			return Color(0.95, 0.78, 0.22, 1)
		Rarity.MYTHIC:
			return Color(0.95, 0.52, 0.18, 1)
		Rarity.PRIMORDIAL:
			return Color(0.92, 0.22, 0.22, 1)
		Rarity.ASTRAL:
			return Color(0.28, 0.88, 0.92, 1)
		Rarity.DIVINE:
			return Color(0.92, 0.22, 0.78, 1)
		Rarity.TRANSCENDENTAL:
			return Color(1.0, 0.45, 0.82, 1)
		_:
			return Color(0.92, 0.92, 0.95, 1)


func dismantle_value() -> int:
	var bases: Array[int] = [8, 14, 28, 90, 240, 600, 1500, 3800, 9500, 24000]
	var stage_index := clampi(int(rarity), 0, bases.size() - 1)
	var extra := damage_bonus + hp_bonus
	if is_gem():
		extra = int(round(gem_value * 2.0))
	return maxi(1, bases[stage_index] + extra)


func type_abbreviation() -> String:
	return sigla_do_tipo(item_type)


func shows_type_abbreviation_in_slot() -> bool:
	return not uses_custom_item_icon()


func uses_custom_item_icon() -> bool:
	if item_type == Type.WEAPON and required_class == RequiredClass.WARRIOR:
		return InterfaceIcons.warrior_sword_icon(rarity) != null
	if item_type in [Type.HELMET, Type.CHEST, Type.GLOVES, Type.PANTS, Type.BOOTS]:
		return InterfaceIcons.armor_icon(item_type, rarity) != null
	return false


static func sigla_do_tipo(p_tipo: Type) -> String:
	match p_tipo:
		Type.WEAPON:
			return "ESP"
		Type.OFFHAND:
			return "ADG"
		Type.HELMET:
			return "CAP"
		Type.CHEST:
			return "PEI"
		Type.GLOVES:
			return "LUV"
		Type.PANTS:
			return "CAL"
		Type.BOOTS:
			return "BOT"
		Type.BELT:
			return "CIN"
		Type.PENDANT:
			return "PIN"
		Type.RING:
			return "ANL"
		Type.BRACELET:
			return "BRA"
		Type.PET:
			return "PET"
		Type.GEM:
			return "GEM"
		_:
			return "ITM"


func to_dictionary() -> Dictionary:
	var dados := {
		"id": id,
		"display_name": display_name,
		"item_type": int(item_type),
		"rarity": int(rarity),
		"item_level": item_level,
		"damage_bonus": damage_bonus,
		"hp_bonus": hp_bonus,
		"classe_requerida": int(required_class),
		"required_class": int(required_class),
		"gem_attribute": int(gem_attribute),
		"gem_value": gem_value,
	}
	if not embedded_gem.is_empty():
		dados["embedded_gem"] = embedded_gem.duplicate(true)
	return dados


static func from_dictionary(dados: Dictionary) -> ItemData:
	if dados.is_empty():
		return null
	var item := ItemData.new()
	item.id = str(dados.get("id", ""))
	item.display_name = str(dados.get("display_name", ""))
	item.item_type = int(dados.get("item_type", Type.WEAPON)) as Type
	item.rarity = migrate_saved_rarity(int(dados.get("rarity", Rarity.COMMON)))
	item.item_level = normalize_item_level(int(dados.get("item_level", ITEM_LEVELS[0])))
	item.damage_bonus = int(dados.get("damage_bonus", 0))
	item.hp_bonus = int(dados.get("hp_bonus", 0))
	var raw_class: Variant = dados.get("required_class", dados.get("classe_requerida", RequiredClass.ALL))
	item.required_class = int(raw_class) as RequiredClass
	item.gem_attribute = int(dados.get("gem_attribute", GemAttribute.ATTACK)) as GemAttribute
	item.gem_value = float(dados.get("gem_value", 0.0))
	var gema_salva: Variant = dados.get("embedded_gem", {})
	item.embedded_gem = gema_salva.duplicate(true) if gema_salva is Dictionary else {}
	item.icone = item.generate_icon()
	return item


func generate_icon() -> Texture2D:
	if is_gem():
		return _generate_gem_icon()
	if item_type == Type.WEAPON and required_class == RequiredClass.WARRIOR:
		var sword := InterfaceIcons.warrior_sword_icon(rarity)
		if sword:
			return sword
	if item_type in [Type.HELMET, Type.CHEST, Type.GLOVES, Type.PANTS, Type.BOOTS]:
		var armor := InterfaceIcons.armor_icon(item_type, rarity)
		if armor:
			return armor
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(6, 26):
		for x in range(6, 26):
			var cor := _icon_pixel_color(x, y)
			img.set_pixel(x, y, cor)
	return ImageTexture.create_from_image(img)


func _generate_gem_icon() -> Texture2D:
	return InterfaceIcons.gem_icon(rarity)


func _icon_pixel_color(x: int, y: int) -> Color:
	if rarity == Rarity.TRANSCENDENTAL:
		var matiz := fmod(float(x + y) * 0.08 + float(x - y) * 0.05, 1.0)
		return Color.from_hsv(matiz, 0.85, 1.0, 1.0).lerp(_type_color(), 0.25)
	var cor := get_rarity_color().lerp(_type_color(), 0.4)
	return cor


func _type_color() -> Color:
	match item_type:
		Type.WEAPON:
			return Color(0.55, 0.58, 0.65)
		Type.OFFHAND:
			return Color(0.45, 0.38, 0.28)
		Type.HELMET:
			return Color(0.5, 0.32, 0.18)
		Type.CHEST:
			return Color(0.35, 0.4, 0.5)
		Type.RING:
			return Color(0.75, 0.62, 0.2)
		_:
			return Color(0.6, 0.55, 0.45)
