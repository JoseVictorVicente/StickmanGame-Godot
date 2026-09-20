class_name InventoryPersistenceBridge
extends RefCounted
## Serialize/apply inventory menu state. Presentation-only bridge to domain data.


func serialize_inventory(menu: InventoryMenu) -> Array:
	var lista: Array = []
	var slots := menu.inventory_slots_grid.usable_slots() if menu.inventory_slots_grid else menu.inventory_slots()
	for slot in slots:
		lista.append(slot.item.to_dictionary() if slot.item else {})
	return lista


func apply_inventory(menu: InventoryMenu, lista: Array) -> void:
	var slots := menu.inventory_slots_grid.usable_slots() if menu.inventory_slots_grid else menu.inventory_slots()
	for i in slots.size():
		var item: ItemData = null
		if i < lista.size() and lista[i] is Dictionary:
			var dados: Dictionary = lista[i]
			if not dados.is_empty():
				item = ItemData.from_dictionary(dados)
		slots[i].set_item(item)


func serialize_equipment(menu: InventoryMenu) -> Dictionary:
	menu.flush_equipment_loadout()
	return menu.equipment_loadouts.serialize()


func apply_equipment(menu: InventoryMenu, todos: Variant) -> void:
	menu.equipment_loadouts.deserialize(todos)
	menu.refresh_equipment_ui()


func serialize_warehouse(menu: InventoryMenu) -> Dictionary:
	return menu.warehouse_panel_node.serialize() if menu.warehouse_panel_node else {}


func apply_warehouse(menu: InventoryMenu, dados: Variant) -> void:
	if menu.warehouse_panel_node:
		menu.warehouse_panel_node.apply(dados)
	menu.sync_warehouse_skill_tree()


func serialize_skill_tree(menu: InventoryMenu) -> Dictionary:
	return menu.skill_tree_progress_data.serialize()


func apply_skill_tree(menu: InventoryMenu, dados: Variant) -> void:
	menu.skill_tree_progress_data.apply(dados)
	menu.sync_warehouse_skill_tree()
