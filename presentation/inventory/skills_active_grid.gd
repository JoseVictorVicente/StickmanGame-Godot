class_name SkillsActiveGrid
extends VBoxContainer
## Active inventory: 3 rows x ([type slot] + 5 skills) = 15 skill slots, baked in .tscn.

const TYPE_SLOT_SCENE := preload("res://presentation/inventory/skill_type_slot.tscn")
const SLOT_SCENE := preload("res://presentation/inventory/skill_slot_active.tscn")
const ROW_COUNT := 3
const SKILLS_PER_ROW := 5
const MAX_SLOTS := ROW_COUNT * SKILLS_PER_ROW
const TYPE_SLOT_SIZE := Vector2(56, 56)
const SKILL_SLOT_SIZE := Vector2(48, 48)
const ROW_SEPARATION := 8
const SLOT_SEPARATION := 6
const SKILLS_ROW_WIDTH := SKILLS_PER_ROW * int(SKILL_SLOT_SIZE.x) + (SKILLS_PER_ROW - 1) * SLOT_SEPARATION


func type_slots() -> Array[Control]:
	return _collect_type_slots()


func active_slots() -> Array[TextureButton]:
	return _collect_skill_slots()


func setup(connect_slot: Callable) -> Array[TextureButton]:
	var lista := active_slots()
	if lista.is_empty():
		lista = ensure_slots()
	for slot in lista:
		_connect_slot_once(slot, connect_slot)
	return lista


func ensure_slots(
	type_size: Vector2 = TYPE_SLOT_SIZE,
	skill_size: Vector2 = SKILL_SLOT_SIZE
) -> Array[TextureButton]:
	if get_child_count() == ROW_COUNT and _children_are_rows():
		_apply_layout(type_size, skill_size)
		return _collect_skill_slots()

	_clear_children()
	for row_index in ROW_COUNT:
		var row := HBoxContainer.new()
		row.name = "ActiveRow_%02d" % (row_index + 1)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", ROW_SEPARATION)
		add_child(row)

		var type_slot := TYPE_SLOT_SCENE.instantiate() as Control
		type_slot.name = "TypeSlot_%02d" % (row_index + 1)
		row.add_child(type_slot)

		var skills_row := HBoxContainer.new()
		skills_row.name = "SkillsRow_%02d" % (row_index + 1)
		skills_row.alignment = BoxContainer.ALIGNMENT_CENTER
		skills_row.add_theme_constant_override("separation", SLOT_SEPARATION)
		row.add_child(skills_row)

		for skill_index in SKILLS_PER_ROW:
			var slot := SLOT_SCENE.instantiate() as TextureButton
			var global_index := row_index * SKILLS_PER_ROW + skill_index + 1
			slot.name = "ActiveSkillSlot_%02d" % global_index
			skills_row.add_child(slot)

	_apply_layout(type_size, skill_size)
	return _collect_skill_slots()


func _connect_slot_once(slot: TextureButton, connect_slot: Callable) -> void:
	if slot.get_meta(&"active_skill_wired", false):
		return
	if connect_slot.is_valid():
		connect_slot.call(slot)
	slot.set_meta(&"active_skill_wired", true)


func _apply_layout(type_size: Vector2, skill_size: Vector2) -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 8)
	for row_index in ROW_COUNT:
		var row := get_child(row_index) as HBoxContainer
		if row == null:
			continue
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		for child_index in row.get_child_count():
			var child := row.get_child(child_index)
			if child.has_method("apply_category"):
				child.custom_minimum_size = type_size
				child.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			elif child is HBoxContainer:
				var skills_row := child as HBoxContainer
				skills_row.custom_minimum_size = Vector2(SKILLS_ROW_WIDTH, skill_size.y)
				skills_row.alignment = BoxContainer.ALIGNMENT_CENTER
				for skill_slot in skills_row.get_children():
					if skill_slot is TextureButton:
						var slot := skill_slot as TextureButton
						slot.custom_minimum_size = skill_size
						slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
						slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
						slot.focus_mode = Control.FOCUS_NONE


func _children_are_rows() -> bool:
	if get_child_count() != ROW_COUNT:
		return false
	for row_index in ROW_COUNT:
		var row := get_child(row_index)
		if not row is HBoxContainer:
			return false
		if row.get_child_count() != 2:
			return false
		if not row.get_child(0).has_method("apply_category"):
			return false
		var skills_row := row.get_child(1)
		if not skills_row is HBoxContainer:
			return false
		if skills_row.get_child_count() != SKILLS_PER_ROW:
			return false
	return true


func _collect_type_slots() -> Array[Control]:
	var lista: Array[Control] = []
	for row_index in ROW_COUNT:
		var row := get_child(row_index) as HBoxContainer
		if row == null:
			continue
		var type_slot := row.get_child(0) as Control
		if type_slot != null and type_slot.has_method("apply_category"):
			lista.append(type_slot)
	return lista


func _collect_skill_slots() -> Array[TextureButton]:
	var lista: Array[TextureButton] = []
	for row_index in ROW_COUNT:
		var row := get_child(row_index) as HBoxContainer
		if row == null or row.get_child_count() < 2:
			continue
		var skills_row := row.get_child(1) as HBoxContainer
		if skills_row == null:
			continue
		for child_index in skills_row.get_child_count():
			var slot := skills_row.get_child(child_index)
			if slot is TextureButton:
				lista.append(slot as TextureButton)
	return lista


func _clear_children() -> void:
	for child in get_children():
		child.queue_free()
