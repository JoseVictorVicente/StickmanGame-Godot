class_name InventoryDragController
extends RefCounted
## Item slot drag-and-drop for the inventory menu hub and side panels.


var _menu: InventoryMenu
var _selected_slot: ItemSlot = null


func setup(menu: InventoryMenu) -> void:
	_menu = menu


func clear_selection() -> void:
	set_selection(null)


func set_selection(slot: ItemSlot) -> void:
	if _selected_slot and is_instance_valid(_selected_slot):
		_selected_slot.update_visual(false)
	_selected_slot = slot
	if _selected_slot:
		_selected_slot.update_visual(true)


func on_slot_clicked(slot: ItemSlot) -> void:
	if _selected_slot != null and _selected_slot != slot:
		if slot.aceita(_selected_slot.item) and (_selected_slot.aceita(slot.item) or slot.item == null):
			if slot.accepts_any or _menu.can_use_item(_selected_slot.item):
				if not can_move_to_slot(_selected_slot, slot):
					return
				move_item(_selected_slot, slot)
				set_selection(null)
				return
	if slot.item != null:
		set_selection(slot)
	else:
		set_selection(null)


func on_slot_double_clicked(slot: ItemSlot) -> void:
	if slot.item == null:
		return
	if is_forge_slot(slot):
		return
	if slot.accepts_any:
		if slot.item.is_gem():
			return
		var dest := _menu.current_equipment_slot(slot.item.item_type)
		if dest and _menu.can_use_item(slot.item):
			move_item(slot, dest)
			set_selection(null)
	else:
		var empty := _menu.first_empty_inventory_slot()
		if empty:
			move_item(slot, empty)
			set_selection(null)


func on_slot_right_clicked(slot: ItemSlot) -> void:
	if slot.item == null:
		return
	if is_forge_slot(slot):
		_menu.forge_panel_node.interact_slot(slot)
		set_selection(null)
		_menu.equipment_changed.emit()
		return
	if is_warehouse_slot(slot):
		var empty_inv := _menu.first_empty_inventory_slot()
		if empty_inv:
			move_item(slot, empty_inv)
			set_selection(null)
		return
	if _menu.forge_panel_node.is_open():
		var dest := _menu.forge_panel_node.first_empty_slot()
		if dest and can_move_to_slot(slot, dest):
			move_item(slot, dest)
			set_selection(null)
		return
	if _menu.warehouse_panel_node.is_open():
		var dest_wh := _menu.warehouse_panel_node.first_empty_slot()
		if dest_wh:
			move_item(slot, dest_wh)
			set_selection(null)
		return
	on_slot_double_clicked(slot)


func on_slot_dropped(destino: ItemSlot, _item: ItemData, origem: ItemSlot) -> void:
	if origem == null or destino == null or origem == destino:
		return
	if not destino.aceita(origem.item):
		return
	if not destino.accepts_any and not _menu.can_use_item(origem.item):
		return
	if origem.item != null and not origem.aceita(destino.item) and destino.item != null:
		return
	if not can_move_to_slot(origem, destino):
		return
	move_item(origem, destino)
	set_selection(null)


func move_item(origem: ItemSlot, destino: ItemSlot) -> void:
	var forge := _menu.forge_panel_node
	if forge and forge.is_open():
		var origem_forge := forge.is_forge_slot(origem)
		var destino_forge := forge.is_forge_slot(destino)
		if destino_forge and not origem_forge:
			if forge.reserve_item(origem, destino):
				_menu.equipment_changed.emit()
			return
		if origem_forge and not destino_forge:
			if forge.is_pending_result(origem):
				if forge.collect_result_to(destino):
					_menu.equipment_changed.emit()
				return
			forge.release_forge_slot(origem)
			_menu.equipment_changed.emit()
			return
		if origem_forge and destino_forge:
			forge.swap_reservations(origem, destino)
			_menu.equipment_changed.emit()
			return
	if origem.forge_reserved or destino.forge_reserved:
		return
	var item_origem := origem.item
	var item_destino := destino.item
	origem.set_item(item_destino)
	destino.set_item(item_origem)
	if _menu.is_equipment_slot(origem) or _menu.is_equipment_slot(destino):
		_menu.flush_equipment_loadout()
	_menu.equipment_changed.emit()


func can_move_to_slot(origem: ItemSlot, destino: ItemSlot) -> bool:
	if origem == null or destino == null:
		return false
	var forge := _menu.forge_panel_node
	if forge == null or not forge.is_open():
		if origem.forge_reserved or destino.forge_reserved:
			return false
		return true
	var origem_forge := forge.is_forge_slot(origem)
	var destino_forge := forge.is_forge_slot(destino)
	if origem.forge_reserved and not origem_forge:
		return false
	if destino.forge_reserved:
		return false
	if destino_forge and not origem_forge:
		if origem.item == null or destino.item != null:
			return false
		if forge.is_origin_reserved(origem):
			return false
		if forge.is_jewelry_target_slot(destino):
			return forge.can_accept_target_jewelry(origem.item)
		if forge.is_jewelry_gem_slot(destino):
			return forge.can_accept_gem_jewelry(origem.item)
		if forge.is_synthesis_slot(destino):
			if not forge.can_accept_in_synthesis(origem.item):
				forge.notify_blocked_category(origem.item)
				return false
		return true
	if origem_forge and not destino_forge:
		if forge.is_pending_result(origem):
			return destino.item == null and not destino.forge_reserved
		return true
	return true


func is_forge_slot(slot: ItemSlot) -> bool:
	return _menu.forge_panel_node != null and _menu.forge_panel_node.is_forge_slot(slot)


func is_warehouse_slot(slot: ItemSlot) -> bool:
	return _menu.warehouse_panel_node != null and slot in _menu.warehouse_panel_node.all_slots()
