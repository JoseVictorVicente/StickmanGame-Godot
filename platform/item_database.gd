extends Node
## Catálogo de ItemData e geração de drops aleatórios.

var items: Array[ItemData] = []


func _ready() -> void:
	_populate_catalog()


func generate_random_item(enemy_level: int) -> ItemData:
	if randf() < 0.22:
		return generate_random_gem(enemy_level)
	return generate_random_equipment(enemy_level)


func generate_random_equipment(enemy_level: int) -> ItemData:
	if items.is_empty():
		_populate_catalog()
	var modelo: ItemData = items[randi() % items.size()]
	var item: ItemData = modelo.duplicate() as ItemData
	item.rarity = _roll_rarity(enemy_level)
	item.item_level = ItemData.roll_item_level(enemy_level)
	var variacao := randf_range(0.9, 1.1)
	var bonus_raridade := ItemData.multiplicador_stats(item.rarity)
	var bonus_nivel := ItemData.item_level_multiplier(item.item_level)
	item.damage_bonus = maxi(1, int(round(float(modelo.damage_bonus) * variacao * bonus_raridade * bonus_nivel)))
	item.hp_bonus = maxi(0, int(round(float(modelo.hp_bonus) * variacao * bonus_raridade * bonus_nivel)))
	item.id = "%s_%d" % [modelo.id, Time.get_ticks_msec()]
	item.icone = item.generate_icon()
	return item


func generate_random_gem(enemy_level: int) -> ItemData:
	var atributos: Array[ItemData.GemAttribute] = [
		ItemData.GemAttribute.ATTACK,
		ItemData.GemAttribute.ATTACK_PCT,
		ItemData.GemAttribute.HP,
		ItemData.GemAttribute.HP_PCT,
		ItemData.GemAttribute.ATTACK_SPEED,
		ItemData.GemAttribute.CRIT_CHANCE,
		ItemData.GemAttribute.CRIT_DAMAGE,
		ItemData.GemAttribute.EVASION,
		ItemData.GemAttribute.PHYS_RES,
		ItemData.GemAttribute.ARCANE_RES,
		ItemData.GemAttribute.ELEMENTAL_RES,
	]
	var atributo := atributos[randi() % atributos.size()]
	var raridade := _roll_rarity(enemy_level)
	var item := ItemData.create_gem(atributo, raridade)
	item.id = "%s_%d" % [item.id, Time.get_ticks_msec()]
	item.gem_value *= randf_range(0.9, 1.1)
	item.icone = item.generate_icon()
	return item


func get_by_id(item_id: String) -> ItemData:
	for item in items:
		if item.id == item_id:
			return item
	return null


func _roll_rarity(enemy_level: int) -> ItemData.Rarity:
	var level := maxi(1, enemy_level)
	var tier_max := clampi(int(floor(float(level) / 5.0)), int(ItemData.Rarity.COMMON), int(ItemData.Rarity.TRANSCENDENTAL))
	var pesos: Array[float] = []
	pesos.resize(tier_max + 1)
	for tier in tier_max + 1:
		var distancia := tier_max - tier
		pesos[tier] = pow(0.58, float(distancia)) * (1.0 + float(tier) * 0.06)
	var total := 0.0
	for peso in pesos:
		total += peso
	var rolagem := randf() * total
	var acumulado := 0.0
	for tier in tier_max + 1:
		acumulado += pesos[tier]
		if rolagem <= acumulado:
			return tier as ItemData.Rarity
	return tier_max as ItemData.Rarity


func _populate_catalog() -> void:
	items.clear()
	var G := ItemData.RequiredClass.WARRIOR
	var M := ItemData.RequiredClass.MAGE
	var A := ItemData.RequiredClass.ARCHER
	var B := ItemData.RequiredClass.BARBARIAN
	var T := ItemData.RequiredClass.TANK
	var C := ItemData.RequiredClass.PRIEST
	# Warrior
	items.append(_create("iron_sword", ItemData.Type.WEAPON, 8, 0, G))
	items.append(_create("training_sword", ItemData.Type.WEAPON, 9, 0, G))
	items.append(_create("wooden_shield", ItemData.Type.OFFHAND, 2, 8, G))
	items.append(_create("warrior_helmet", ItemData.Type.HELMET, 3, 6, G))
	items.append(_create("warrior_chestplate", ItemData.Type.CHEST, 2, 10, G))
	items.append(_create("warrior_gloves", ItemData.Type.GLOVES, 2, 4, G))
	items.append(_create("warrior_pants", ItemData.Type.PANTS, 2, 6, G))
	items.append(_create("warrior_boots", ItemData.Type.BOOTS, 1, 5, G))
	items.append(_create("lion_pet", ItemData.Type.PET, 3, 4, G))
	items.append(_create("ring_of_honor", ItemData.Type.RING, 2, 2, G))
	items.append(_create("warrior_bracelet", ItemData.Type.BRACELET, 2, 3, G))
	# Mage
	items.append(_create("arcane_staff", ItemData.Type.WEAPON, 7, 0, M))
	items.append(_create("grimoire", ItemData.Type.OFFHAND, 4, 0, M))
	items.append(_create("arcane_familiar", ItemData.Type.PET, 3, 0, M))
	items.append(_create("mystic_cloak", ItemData.Type.CHEST, 2, 8, M))
	items.append(_create("arcane_tiara", ItemData.Type.HELMET, 2, 4, M))
	items.append(_create("mage_gloves", ItemData.Type.GLOVES, 3, 2, M))
	items.append(_create("mage_pants", ItemData.Type.PANTS, 2, 5, M))
	items.append(_create("mage_boots", ItemData.Type.BOOTS, 1, 4, M))
	items.append(_create("arcane_ring", ItemData.Type.RING, 2, 3, M))
	items.append(_create("mana_pendant", ItemData.Type.PENDANT, 2, 4, M))
	# Archer
	items.append(_create("short_bow", ItemData.Type.WEAPON, 7, 0, A))
	items.append(_create("quiver", ItemData.Type.OFFHAND, 3, 0, A))
	items.append(_create("leather_hood", ItemData.Type.HELMET, 2, 4, A))
	items.append(_create("archer_chestplate", ItemData.Type.CHEST, 2, 6, A))
	items.append(_create("archer_gloves", ItemData.Type.GLOVES, 2, 3, A))
	items.append(_create("archer_pants", ItemData.Type.PANTS, 2, 5, A))
	items.append(_create("archer_boots", ItemData.Type.BOOTS, 1, 4, A))
	items.append(_create("companion_falcon", ItemData.Type.PET, 3, 2, A))
	items.append(_create("precision_ring", ItemData.Type.RING, 3, 0, A))
	# Barbarian
	items.append(_create("shadow_dagger", ItemData.Type.WEAPON, 6, 0, B))
	items.append(_create("twin_dagger", ItemData.Type.OFFHAND, 5, 0, B))
	items.append(_create("barbarian_hood", ItemData.Type.HELMET, 3, 2, B))
	items.append(_create("shadow_chestplate", ItemData.Type.CHEST, 2, 5, B))
	items.append(_create("barbarian_gloves", ItemData.Type.GLOVES, 3, 2, B))
	items.append(_create("barbarian_pants", ItemData.Type.PANTS, 2, 4, B))
	items.append(_create("barbarian_boots", ItemData.Type.BOOTS, 1, 3, B))
	items.append(_create("shadow_ring", ItemData.Type.RING, 2, 2, B))
	items.append(_create("shadow_bracelet", ItemData.Type.BRACELET, 3, 1, B))
	# Tank
	items.append(_create("heavy_mace", ItemData.Type.WEAPON, 8, 4, T))
	items.append(_create("tower_shield", ItemData.Type.OFFHAND, 1, 14, T))
	items.append(_create("iron_chestplate", ItemData.Type.CHEST, 2, 16, T))
	items.append(_create("tower_helmet", ItemData.Type.HELMET, 2, 10, T))
	items.append(_create("tank_gloves", ItemData.Type.GLOVES, 2, 6, T))
	items.append(_create("tank_pants", ItemData.Type.PANTS, 2, 12, T))
	items.append(_create("tank_boots", ItemData.Type.BOOTS, 1, 8, T))
	items.append(_create("turtle_pet", ItemData.Type.PET, 1, 8, T))
	items.append(_create("guardian_pendant", ItemData.Type.PENDANT, 1, 6, T))
	# Priest
	items.append(_create("holy_staff", ItemData.Type.WEAPON, 5, 6, C))
	items.append(_create("tome_of_light", ItemData.Type.OFFHAND, 2, 8, C))
	items.append(_create("clerical_cloak", ItemData.Type.CHEST, 1, 12, C))
	items.append(_create("faith_pendant", ItemData.Type.PENDANT, 1, 5, C))
	items.append(_create("sacred_tiara", ItemData.Type.HELMET, 2, 6, C))
	items.append(_create("priest_gloves", ItemData.Type.GLOVES, 1, 5, C))
	items.append(_create("priest_pants", ItemData.Type.PANTS, 1, 8, C))
	items.append(_create("priest_boots", ItemData.Type.BOOTS, 1, 6, C))
	items.append(_create("devotion_ring", ItemData.Type.RING, 2, 4, C))
	# Common (all classes)
	items.append(_create("cloth_gloves", ItemData.Type.GLOVES, 2, 2))
	items.append(_create("leather_pants", ItemData.Type.PANTS, 2, 5))
	items.append(_create("travel_boots", ItemData.Type.BOOTS, 1, 3))
	items.append(_create("simple_ring", ItemData.Type.RING, 1, 2))
	items.append(_create("rough_ring", ItemData.Type.RING, 2, 0))
	items.append(_create("iron_bracelet", ItemData.Type.BRACELET, 2, 1))
	items.append(_create("travel_hood", ItemData.Type.HELMET, 1, 3))
	items.append(_create("leather_chestplate", ItemData.Type.CHEST, 2, 4))
	items.append(_create("simple_pendant", ItemData.Type.PENDANT, 1, 2))
	items.append(_create("rat_pet", ItemData.Type.PET, 1, 2))
	for item in items:
		item.icone = item.generate_icon()



func _create(
	p_id: String,
	p_tipo: ItemData.Type,
	p_damage: int,
	p_hp: int,
	p_classe: ItemData.RequiredClass = ItemData.RequiredClass.ALL
) -> ItemData:
	var item := ItemData.new()
	item.id = p_id
	item.display_name = ""
	item.name_key = "ITEM_%s" % p_id
	item.item_type = p_tipo
	item.damage_bonus = p_damage
	item.hp_bonus = p_hp
	item.required_class = p_classe
	item.rarity = ItemData.Rarity.COMMON
	item.item_level = ItemData.ITEM_LEVELS[0]
	return item
