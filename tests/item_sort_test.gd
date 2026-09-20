extends SceneTree
## ItemData.compare_sort and InventoryMenu.sort_slots ordering.


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var helmet := _item("helm", ItemData.Type.HELMET, ItemData.Rarity.COMMON, 5)
	var sword_rare := _item("sword_r", ItemData.Type.WEAPON, ItemData.Rarity.RARE, 10)
	var sword_common := _item("sword_c", ItemData.Type.WEAPON, ItemData.Rarity.COMMON, 50)
	var ring := _item("ring", ItemData.Type.RING, ItemData.Rarity.EPIC, 5)
	var items: Array[ItemData] = [sword_common, ring, helmet, sword_rare]
	items.sort_custom(ItemData.compare_sort)
	assert(items[0].id == "helm", "equipment before accessories")
	assert(items[1].id == "sword_r", "higher rarity weapon before common")
	assert(items[2].id == "sword_c", "same type lower rarity after")
	assert(items[3].id == "ring", "accessories after equipment")
	print("[TEST PASS] Item sort order")
	quit()


func _item(id: String, tipo: ItemData.Type, raridade: ItemData.Rarity, nivel: int) -> ItemData:
	var item := ItemData.new()
	item.id = id
	item.name_key = "ITEM_%s" % id
	item.item_type = tipo
	item.rarity = raridade
	item.item_level = nivel
	return item
