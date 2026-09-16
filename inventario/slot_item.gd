class_name SlotItem
extends Panel
## Slot de inventário ou equipamento. Usa ItemData (Resource).

signal item_clicado(slot: SlotItem)
signal item_duplo_clique(slot: SlotItem)
signal item_botao_direito(slot: SlotItem)
signal item_solto(destino: SlotItem, item: ItemData, origem: SlotItem)

const OFFSET_CURSOR := Vector2(15, 15)
const CAMADA_TOOLTIP := 128
const Z_INDEX_TOOLTIP := 100
const EQUIP_DIREITA_NOMES: Array[String] = ["Cinto", "Pingente", "Anel", "Bracelete", "Pet"]

static var _camada_legenda: CanvasLayer
static var _caixa_legenda: PanelContainer
static var _slot_legenda: SlotItem

var item: ItemData = null
var tipo_aceitavel: ItemData.Tipo = ItemData.Tipo.ARMA
var aceita_qualquer: bool = true
var nome_slot: String = ""
var icone_rect: TextureRect
var _label_sigla: Label
var _selecionado: bool = false
var _textura_vazia: Texture2D


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	visibility_changed.connect(_on_visibilidade_alterada)
	tree_exiting.connect(_ocultar_legenda)


func configurar(p_icone: TextureRect, p_tipo: ItemData.Tipo = ItemData.Tipo.ARMA, p_qualquer: bool = true) -> void:
	icone_rect = p_icone
	tipo_aceitavel = p_tipo
	aceita_qualquer = p_qualquer
	if not aceita_qualquer:
		_textura_vazia = IconesInterface.slot_equipamento(tipo_aceitavel)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_garantir_sigla()
	_aplicar_icone()
	atualizar_visual()


func definir_item(novo: ItemData) -> void:
	item = novo
	_aplicar_icone()
	atualizar_visual()


func atualizar_visual(selecionado: bool = _selecionado) -> void:
	_selecionado = selecionado
	_garantir_sigla()
	add_theme_stylebox_override("panel", _estilo_atual())
	if _label_sigla:
		if item:
			_label_sigla.text = item.sigla_tipo()
			_label_sigla.add_theme_color_override("font_color", item.cor_raridade())
			_label_sigla.visible = true
		else:
			_label_sigla.text = ""
			_label_sigla.visible = false
	tooltip_text = ""
	if _slot_legenda == self:
		if item:
			_mostrar_legenda()
		else:
			_ocultar_legenda()


func aceita(candidato: ItemData) -> bool:
	if candidato == null:
		return true
	if aceita_qualquer:
		return true
	return candidato.tipo == tipo_aceitavel


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	var mouse := event as InputEventMouseButton
	if mouse.button_index == MOUSE_BUTTON_LEFT:
		if mouse.double_click:
			item_duplo_clique.emit(self)
		else:
			item_clicado.emit(self)
	elif mouse.button_index == MOUSE_BUTTON_RIGHT:
		item_botao_direito.emit(self)
		accept_event()


func _on_mouse_entered() -> void:
	_mostrar_legenda()


func _on_mouse_exited() -> void:
	_ocultar_legenda()


func _on_visibilidade_alterada() -> void:
	if not is_visible_in_tree():
		_ocultar_legenda()


func _mostrar_legenda() -> void:
	if item == null or not is_visible_in_tree():
		_ocultar_legenda()
		return
	_slot_legenda = self
	var caixa := _garantir_caixa_legenda()
	_preencher_legenda(caixa, item)
	caixa.show()
	caixa.move_to_front()
	_posicionar_legenda()
	set_process(true)


func _ocultar_legenda() -> void:
	if _slot_legenda != null and _slot_legenda != self:
		return
	if _slot_legenda == self:
		set_process(false)
	_slot_legenda = null
	if _caixa_legenda and is_instance_valid(_caixa_legenda):
		_caixa_legenda.hide()


func _process(_delta: float) -> void:
	if _slot_legenda == self and _caixa_legenda and _caixa_legenda.visible:
		_posicionar_legenda()


func _posicionar_legenda() -> void:
	if _slot_legenda != self or item == null:
		return
	if _caixa_legenda == null or not is_instance_valid(_caixa_legenda):
		return
	_caixa_legenda.reset_size()
	var tam := _caixa_legenda.get_combined_minimum_size()
	if _caixa_legenda.size.x > tam.x or _caixa_legenda.size.y > tam.y:
		tam = _caixa_legenda.size
	_caixa_legenda.size = tam

	var viewport_size := get_viewport().get_visible_rect().size
	var mouse := get_viewport().get_mouse_position()
	var slot_rect := get_global_rect()
	var abrir_esquerda := _deve_abrir_tooltip_esquerda(slot_rect)
	var pos := Vector2.ZERO

	if abrir_esquerda:
		_caixa_legenda.pivot_offset = Vector2(tam.x, 0.0)
		pos.x = slot_rect.position.x - tam.x - OFFSET_CURSOR.x
		pos.y = mouse.y + OFFSET_CURSOR.y
		if pos.x < 0.0:
			pos.x = slot_rect.end.x + OFFSET_CURSOR.x
	else:
		_caixa_legenda.pivot_offset = Vector2.ZERO
		pos = mouse + OFFSET_CURSOR
		if pos.x + tam.x > viewport_size.x:
			pos.x = mouse.x - tam.x - OFFSET_CURSOR.x

	if pos.y + tam.y > viewport_size.y:
		pos.y = mouse.y - tam.y - OFFSET_CURSOR.y

	pos.x = clampf(pos.x, 0.0, maxf(0.0, viewport_size.x - tam.x))
	pos.y = clampf(pos.y, 0.0, maxf(0.0, viewport_size.y - tam.y))
	_caixa_legenda.global_position = pos


func _deve_abrir_tooltip_esquerda(slot_rect: Rect2) -> bool:
	if EQUIP_DIREITA_NOMES.has(nome_slot) or _esta_em_coluna_direita():
		return true
	var hud := _obter_retangulo_hud()
	if hud.size.x <= 0.0:
		return slot_rect.get_center().x >= get_viewport().get_visible_rect().size.x * 0.5
	return slot_rect.get_center().x >= hud.position.x + hud.size.x * 0.5


func _esta_em_coluna_direita() -> bool:
	var no: Node = self
	while no:
		if no.name == "EquipDireita" or str(no.name).begins_with("EquipDir_"):
			return true
		no = no.get_parent()
	return false


func _obter_retangulo_hud() -> Rect2:
	var no: Node = self
	while no:
		if no is Control and (no.name == "Painel" or no.name == "Menu"):
			return (no as Control).get_global_rect()
		no = no.get_parent()
	return Rect2()


func _garantir_caixa_legenda() -> PanelContainer:
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


func _preencher_legenda(caixa: PanelContainer, dados: ItemData) -> void:
	while caixa.get_child_count() > 0:
		caixa.get_child(0).free()
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color(0.08, 0.07, 0.06, 0.96)
	fundo.border_color = dados.cor_raridade()
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
	coluna.add_child(_rotulo_tooltip(dados.nome, dados.cor_raridade(), 13, true))
	coluna.add_child(_rotulo_tooltip(dados.nome_raridade(), dados.cor_raridade(), 11, false))
	coluna.add_child(_rotulo_tooltip("Dano Bônus: +%d" % dados.dano_bonus, Color(0.92, 0.86, 0.7, 1), 11, false))
	if dados.vida_bonus != 0:
		coluna.add_child(_rotulo_tooltip("Vida Bônus: +%d" % dados.vida_bonus, Color(0.72, 0.9, 0.7, 1), 11, false))
	if dados.classe_requerida != ItemData.ClasseRequerida.TODAS:
		coluna.add_child(_rotulo_tooltip("Classe: %s" % dados.nome_classe_requerida(), Color(0.85, 0.78, 0.55, 1), 11, false))
	coluna.add_child(_rotulo_tooltip("Valor: %d ouro" % dados.valor_desmonte(), Color(1, 0.86, 0.38, 1), 11, false))
	caixa.add_child(coluna)


func _rotulo_tooltip(texto: String, cor: Color, tamanho: int, negrito: bool) -> Label:
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
	_ocultar_legenda()
	if item == null:
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
	var origem: SlotItem = dados.get("origem")
	if origem == self:
		return false
	return aceita(dados["item"])


func _drop_data(_posicao: Vector2, dados: Variant) -> void:
	item_solto.emit(self, dados["item"], dados["origem"])


func _aplicar_icone() -> void:
	if icone_rect == null:
		return
	if item and item.icone:
		icone_rect.texture = item.icone
		icone_rect.modulate = Color.WHITE
	else:
		icone_rect.texture = _textura_vazia
		icone_rect.modulate = Color(1, 1, 1, 1)


func _garantir_sigla() -> void:
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


func _estilo_atual() -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.set_corner_radius_all(3)
	if item:
		var raridade := item.cor_raridade()
		estilo.bg_color = Color(raridade.r * 0.18, raridade.g * 0.16, raridade.b * 0.16, 1)
		estilo.border_color = raridade
	else:
		estilo.bg_color = Color(0.06, 0.05, 0.04, 1)
		estilo.border_color = Color(0.72, 0.58, 0.28, 1)
	estilo.set_border_width_all(3 if _selecionado else 2)
	if _selecionado:
		estilo.border_color = Color(0.95, 0.78, 0.32, 1)
	return estilo
