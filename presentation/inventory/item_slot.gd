class_name ItemSlot
extends Panel
## Slot de inventário ou equipamento. Usa ItemData (Resource).

signal item_clicked(slot: ItemSlot)
signal item_double_clicked(slot: ItemSlot)
signal item_right_clicked(slot: ItemSlot)
signal item_dropped(destino: ItemSlot, item: ItemData, origem: ItemSlot)

const OFFSET_LEGENDA := Vector2(10, 0)
const CAMADA_TOOLTIP := 128
const Z_INDEX_TOOLTIP := 100
const EQUIP_RIGHT_TYPES: Array[ItemData.Type] = [
	ItemData.Type.BELT,
	ItemData.Type.PENDANT,
	ItemData.Type.RING,
	ItemData.Type.BRACELET,
	ItemData.Type.PET,
]

static var _camada_legenda: CanvasLayer
static var _caixa_legenda: PanelContainer
static var _slot_legenda: ItemSlot

var item: ItemData = null
var tipo_aceitavel: ItemData.Type = ItemData.Type.WEAPON
var aceita_qualquer: bool = true
var nome_slot: String = ""
var validar_drop_extra: Callable
var reservado_ferraria: bool = false
var icone_rect: TextureRect
var _label_sigla: Label
var _selecionado: bool = false
var _textura_vazia: Texture2D


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	visibility_changed.connect(_on_visibility_changed)
	tree_exiting.connect(_hide_tooltip)


func configure(p_icone: TextureRect, p_tipo: ItemData.Type = ItemData.Type.WEAPON, p_qualquer: bool = true) -> void:
	icone_rect = p_icone
	tipo_aceitavel = p_tipo
	aceita_qualquer = p_qualquer
	if not aceita_qualquer:
		_textura_vazia = InterfaceIcons.equipment_slot(tipo_aceitavel)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_ensure_abbreviation()
	_apply_icon()
	update_visual()


func set_item(novo: ItemData) -> void:
	item = novo
	_apply_icon()
	update_visual()


func update_visual(selecionado: bool = _selecionado) -> void:
	_selecionado = selecionado
	_ensure_abbreviation()
	add_theme_stylebox_override("panel", _current_style())
	if _label_sigla:
		if item:
			_label_sigla.text = item.type_abbreviation()
			_label_sigla.add_theme_color_override("font_color", item.get_rarity_color())
			_label_sigla.visible = true
		else:
			_label_sigla.text = ""
			_label_sigla.visible = false
	tooltip_text = ""
	if _slot_legenda == self:
		if item:
			_show_tooltip()
		else:
			_hide_tooltip()


func set_forge_reserved(ativa: bool) -> void:
	reservado_ferraria = ativa
	_apply_icon()
	update_visual()


func aceita(candidato: ItemData) -> bool:
	if candidato == null:
		return true
	if reservado_ferraria:
		return false
	if aceita_qualquer:
		return true
	return candidato.item_type == tipo_aceitavel


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	var mouse := event as InputEventMouseButton
	if mouse.button_index == MOUSE_BUTTON_LEFT:
		if mouse.double_click:
			item_double_clicked.emit(self)
		else:
			item_clicked.emit(self)
	elif mouse.button_index == MOUSE_BUTTON_RIGHT:
		item_right_clicked.emit(self)
		accept_event()


func _on_mouse_entered() -> void:
	_show_tooltip()


func _on_mouse_exited() -> void:
	_hide_tooltip()


func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		_hide_tooltip()


func _show_tooltip() -> void:
	if item == null or not is_visible_in_tree():
		_hide_tooltip()
		return
	_slot_legenda = self
	var caixa := _ensure_tooltip_box()
	_fill_tooltip(caixa, item)
	caixa.show()
	caixa.move_to_front()
	_position_tooltip()


func _hide_tooltip() -> void:
	if _slot_legenda != null and _slot_legenda != self:
		return
	_slot_legenda = null
	if _caixa_legenda and is_instance_valid(_caixa_legenda):
		_caixa_legenda.hide()


func _position_tooltip() -> void:
	if _slot_legenda != self or item == null:
		return
	if _caixa_legenda == null or not is_instance_valid(_caixa_legenda):
		return
	_caixa_legenda.reset_size()
	var tam := _caixa_legenda.get_combined_minimum_size()
	if _caixa_legenda.size.x > tam.x or _caixa_legenda.size.y > tam.y:
		tam = _caixa_legenda.size
	_caixa_legenda.size = tam
	_caixa_legenda.pivot_offset = Vector2.ZERO

	var viewport := get_viewport().get_visible_rect()
	var slot_rect := get_global_rect()
	var abrir_esquerda := _should_open_tooltip_left(slot_rect)
	var pos := Vector2.ZERO

	if abrir_esquerda:
		pos.x = slot_rect.position.x - tam.x - OFFSET_LEGENDA.x
		pos.y = slot_rect.position.y + (slot_rect.size.y - tam.y) * 0.5
		if pos.x < viewport.position.x + 4.0:
			pos.x = slot_rect.end.x + OFFSET_LEGENDA.x
	else:
		pos.x = slot_rect.end.x + OFFSET_LEGENDA.x
		pos.y = slot_rect.position.y + (slot_rect.size.y - tam.y) * 0.5
		if pos.x + tam.x > viewport.end.x - 4.0:
			pos.x = slot_rect.position.x - tam.x - OFFSET_LEGENDA.x

	pos.x = clampf(pos.x, viewport.position.x + 4.0, maxf(viewport.position.x + 4.0, viewport.end.x - tam.x - 4.0))
	pos.y = clampf(pos.y, viewport.position.y + 4.0, maxf(viewport.position.y + 4.0, viewport.end.y - tam.y - 4.0))
	_caixa_legenda.global_position = pos


func _should_open_tooltip_left(slot_rect: Rect2) -> bool:
	if EQUIP_RIGHT_TYPES.has(tipo_aceitavel) or _is_in_right_column():
		return true
	var hud := _get_hud_rect()
	if hud.size.x <= 0.0:
		return slot_rect.get_center().x >= get_viewport().get_visible_rect().size.x * 0.5
	return slot_rect.get_center().x >= hud.position.x + hud.size.x * 0.5


func _is_in_right_column() -> bool:
	var no: Node = self
	while no:
		if no.name == "EquipRight" or str(no.name).begins_with("EquipDir_"):
			return true
		no = no.get_parent()
	return false


func _get_hud_rect() -> Rect2:
	var no: Node = self
	while no:
		if no is Control and (no.name == "Painel" or no.name == "Menu"):
			return (no as Control).get_global_rect()
		no = no.get_parent()
	return Rect2()


func _ensure_tooltip_box() -> PanelContainer:
	if _camada_legenda == null or not is_instance_valid(_camada_legenda):
		_camada_legenda = CanvasLayer.new()
		_camada_legenda.layer = CAMADA_TOOLTIP
		_camada_legenda.name = "CamadaLegendaItem"
		get_tree().root.add_child(_camada_legenda)
	if _caixa_legenda == null or not is_instance_valid(_caixa_legenda):
		_caixa_legenda = PanelContainer.new()
		_caixa_legenda.z_index = Z_INDEX_TOOLTIP
		_caixa_legenda.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_camada_legenda.add_child(_caixa_legenda)
	return _caixa_legenda


func _fill_tooltip(caixa: PanelContainer, dados: ItemData) -> void:
	while caixa.get_child_count() > 0:
		caixa.get_child(0).free()
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color(0.08, 0.07, 0.06, 0.96)
	fundo.border_color = dados.get_rarity_color()
	fundo.set_border_width_all(2)
	fundo.set_corner_radius_all(4)
	fundo.content_margin_left = 10
	fundo.content_margin_top = 8
	fundo.content_margin_right = 10
	fundo.content_margin_bottom = 8
	caixa.add_theme_stylebox_override("panel", fundo)

	var coluna := VBoxContainer.new()
	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_theme_constant_override("separation", 3)
	coluna.add_child(_tooltip_label(dados.get_display_name(), dados.get_rarity_color(), 13, true))
	coluna.add_child(_tooltip_label(dados.rarity_name(), dados.get_rarity_color(), 11, false))
	if dados.is_gem():
		coluna.add_child(_tooltip_label(
			tr(LocaleKeys.ITEM_GEM_ATTR_VALUE) % [ItemData.gem_attribute_name(dados.gem_attribute), dados.gem_value_text()],
			Color(0.92, 0.86, 0.7, 1),
			11,
			false
		))
	else:
		coluna.add_child(_tooltip_label(tr(LocaleKeys.ITEM_BONUS_DAMAGE) % dados.damage_bonus, Color(0.92, 0.86, 0.7, 1), 11, false))
		if dados.hp_bonus != 0:
			coluna.add_child(_tooltip_label(tr(LocaleKeys.ITEM_BONUS_HP) % dados.hp_bonus, Color(0.72, 0.9, 0.7, 1), 11, false))
		var linha_gema := dados.gem_slot_line()
		if linha_gema != "":
			coluna.add_child(_tooltip_label(linha_gema, dados.gem_slot_label_color(), 11, false))
	if dados.required_class != ItemData.RequiredClass.ALL:
		coluna.add_child(_tooltip_label(tr(LocaleKeys.ITEM_CLASS_REQUIRED) % dados.required_class_display_name(), Color(0.85, 0.78, 0.55, 1), 11, false))
	if not dados.is_gem():
		coluna.add_child(_tooltip_label(tr(LocaleKeys.ITEM_LEVEL) % dados.item_level, Color(0.78, 0.82, 0.95, 1), 11, false))
	coluna.add_child(_tooltip_label(tr(LocaleKeys.ITEM_VALUE) % dados.dismantle_value(), Color(1, 0.86, 0.38, 1), 11, false))
	caixa.add_child(coluna)


func _tooltip_label(texto: String, cor: Color, tamanho: int, negrito: bool) -> Label:
	var rotulo := Label.new()
	rotulo.text = texto
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rotulo.add_theme_color_override("font_color", cor)
	rotulo.add_theme_font_size_override("font_size", tamanho)
	if negrito:
		rotulo.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
		rotulo.add_theme_constant_override("outline_size", 2)
	return rotulo


func _get_drag_data(_posicao: Vector2) -> Variant:
	_hide_tooltip()
	if item == null or reservado_ferraria:
		return null
	var preview := TextureRect.new()
	preview.texture = item.icone
	preview.custom_minimum_size = Vector2(42, 42)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(preview)
	return {"item": item, "origem": self}


func _can_drop_data(_posicao: Vector2, dados: Variant) -> bool:
	if not (dados is Dictionary and dados.get("item") is ItemData):
		return false
	var origem: ItemSlot = dados.get("origem")
	if origem == self:
		return false
	var candidato: ItemData = dados["item"]
	if not aceita(candidato):
		return false
	if validar_drop_extra.is_valid():
		var ok := true
		if origem != null:
			ok = bool(validar_drop_extra.call(candidato, origem))
		else:
			ok = bool(validar_drop_extra.call(candidato))
		if not ok:
			return false
	return true


func _drop_data(_posicao: Vector2, dados: Variant) -> void:
	item_dropped.emit(self, dados["item"], dados["origem"])


func _apply_icon() -> void:
	if icone_rect == null:
		return
	if item and item.icone:
		icone_rect.texture = item.icone
		if reservado_ferraria:
			icone_rect.modulate = Color(0.42, 0.42, 0.45, 0.75)
		else:
			icone_rect.modulate = Color.WHITE
	else:
		icone_rect.texture = _textura_vazia
		icone_rect.modulate = Color(1, 1, 1, 1)


func _ensure_abbreviation() -> void:
	if _label_sigla and is_instance_valid(_label_sigla):
		return
	_label_sigla = Label.new()
	_label_sigla.name = "SiglaCategoria"
	_label_sigla.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label_sigla.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label_sigla.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_sigla.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label_sigla.add_theme_font_size_override("font_size", 11)
	_label_sigla.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_label_sigla.add_theme_constant_override("outline_size", 4)
	add_child(_label_sigla)


func _current_style() -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.set_corner_radius_all(3)
	if item:
		var raridade := item.get_rarity_color()
		estilo.bg_color = Color(raridade.r * 0.18, raridade.g * 0.16, raridade.b * 0.16, 1)
		estilo.border_color = raridade
	else:
		estilo.bg_color = Color(0.06, 0.05, 0.04, 1)
		estilo.border_color = Color(0.72, 0.58, 0.28, 1)
	estilo.set_border_width_all(3 if _selecionado else 2)
	if _selecionado:
		estilo.border_color = Color(0.95, 0.78, 0.32, 1)
	if reservado_ferraria:
		estilo.bg_color = Color(estilo.bg_color.r * 0.45, estilo.bg_color.g * 0.45, estilo.bg_color.b * 0.45, estilo.bg_color.a)
		estilo.border_color = Color(estilo.border_color.r * 0.55, estilo.border_color.g * 0.55, estilo.border_color.b * 0.55, 0.65)
	return estilo
