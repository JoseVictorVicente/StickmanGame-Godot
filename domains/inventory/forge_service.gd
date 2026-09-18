class_name ForgeService
extends RefCounted
## Forge rules stub — synthesis, disenchant, and gem imbue interfaces.

const SYNTHESIS_INGREDIENT_COUNT := 9


func can_improve(item: ItemData) -> bool:
	if item == null:
		return false
	if item.is_gem():
		return true
	return not ItemData.is_max_rarity(item.rarity)


func get_cost(item: ItemData, operation: String = "synthesis") -> int:
	if item == null:
		return 0
	match operation:
		"synthesis":
			return _synthesis_gold_cost(item)
		"disenchant":
			return item.dismantle_value()
		"imbue":
			return _imbue_gold_cost(item)
		_:
			return 0


func synthesis_success_chance(item: ItemData) -> float:
	if item == null:
		return 0.0
	return ItemData.forge_success_chance(item.rarity)


func can_synthesize_ingredients(ingredients: Array) -> bool:
	if ingredients.size() != SYNTHESIS_INGREDIENT_COUNT:
		return false
	var first: ItemData = ingredients[0]
	if first == null or ItemData.is_max_rarity(first.rarity):
		return false
	for item in ingredients:
		if item == null:
			return false
		if item.category() != first.category():
			return false
		if item.rarity != first.rarity:
			return false
	return true


func can_imbue_gem(equipment: ItemData, gem: ItemData) -> bool:
	if equipment == null or gem == null:
		return false
	if not gem.is_gem():
		return false
	return equipment.has_gem_slot() and not equipment.has_embedded_gem()


func next_rarity(item: ItemData) -> ItemData.Rarity:
	if item == null:
		return ItemData.Rarity.COMMON
	return ItemData.next_rarity(item.rarity)


func _synthesis_gold_cost(item: ItemData) -> int:
	var base := item.dismantle_value()
	return maxi(1, int(round(float(base) * 0.5)))


func _imbue_gold_cost(equipment: ItemData) -> int:
	return maxi(10, equipment.dismantle_value() / 4)
