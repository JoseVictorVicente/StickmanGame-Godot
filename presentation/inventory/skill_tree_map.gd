class_name SkillTreeMap
extends Control
## Três colunas diamante centralizadas com nós clicáveis.

signal node_selected(id: int)

const TAMANHO_NO := Vector2(56, 56)

class CamadaHover:
	extends Control

	var mapa: SkillTreeMap

	func _draw() -> void:
		if mapa == null:
			return
		var rect := mapa._rect_hover()
		if rect.size.x <= 0.0:
			return
		draw_rect(rect, Color(0.95, 0.78, 0.32, 0.18), true)
		draw_rect(rect, Color(0.95, 0.78, 0.32, 1), false, 2.0, true)


var hero_progress: SkillTreeProgress
var ouro_atual: int = 0

var _catalogo: Array[Dictionary] = []
var _nos: Dictionary = {}
var _offset := Vector2.ZERO
var _linhas: Array[Dictionary] = []
var _hover_id: int = -1
var _camada_hover: CamadaHover


func _ready() -> void:
	clip_contents = false
	mouse_filter = Control.MOUSE_FILTER_PASS
	_catalogo = SkillTreeDefinition.catalog()
	_build_nodes()
	call_deferred("_center_view")


func configure(prog: SkillTreeProgress, ouro: int) -> void:
	hero_progress = prog
	ouro_atual = ouro
	_center_view()
	_update_visual()


func _dados_no(id: int) -> Dictionary:
	for no in _catalogo:
		if int(no.get("id", -1)) == id:
			return no
	return {}


func _node_for_slot(secao: int, slot: int) -> Dictionary:
	return _dados_no(SkillTreeDefinition.node_id(secao, slot))


func _draw() -> void:
	_draw_columns()
	for linha in _linhas:
		var pontos: PackedVector2Array = linha["pontos"]
		var cor: Color = linha["cor"]
		for i in range(pontos.size() - 1):
			draw_line(pontos[i] + _offset, pontos[i + 1] + _offset, cor, 2.0, true)


func _draw_columns() -> void:
	var font := ThemeDB.fallback_font
	var font_titulo := 12
	var font_pontos := 9
	var altura_arvore := float(SkillTreeDefinition.NUM_ROWS) * SkillTreeDefinition.ROW_HEIGHT
	for secao in SkillTreeDefinition.NUM_SECTIONS:
		var x := SkillTreeDefinition.centro_x_coluna(secao) + _offset.x
		var y_titulo := SkillTreeDefinition.TOP_MARGIN + _offset.y + 16.0
		var cor := SkillTreeDefinition.region_color(secao)
		var nome := tr(SkillTreeDefinition.region_name(secao))
		var pontos := 0
		if hero_progress:
			pontos = hero_progress.points_in_section(secao)
		var x_coluna := x - SkillTreeDefinition.COLUMN_WIDTH * 0.5
		var y_coluna := SkillTreeDefinition.TOP_MARGIN + _offset.y
		var faixa := Rect2(
			x_coluna,
			y_coluna,
			SkillTreeDefinition.COLUMN_WIDTH,
			SkillTreeDefinition.HEADER_HEIGHT + altura_arvore
		)
		draw_rect(faixa, Color(0.14, 0.12, 0.1, 0.55), true)
		draw_rect(faixa, cor.darkened(0.35), false, 2.0)
		draw_string(
			font,
			Vector2(x_coluna, y_titulo),
			nome,
			HORIZONTAL_ALIGNMENT_CENTER,
			SkillTreeDefinition.COLUMN_WIDTH,
			font_titulo,
			cor.lightened(0.2)
		)
		draw_string(
			font,
			Vector2(x_coluna, y_titulo + 18.0),
			tr(LocaleKeys.TREE_POINTS) % pontos,
			HORIZONTAL_ALIGNMENT_CENTER,
			SkillTreeDefinition.COLUMN_WIDTH,
			font_pontos,
			Color(0.78, 0.72, 0.58, 0.95)
		)


func _build_nodes() -> void:
	for filho in get_children():
		filho.queue_free()
	_nos.clear()
	_linhas.clear()
	for no in _catalogo:
		var id := int(no["id"])
		var tam := _node_size(no)
		var pos := SkillTreeDefinition.posicao_do_no(no) - tam * 0.5
		var botao := TextureButton.new()
		botao.name = "No_%d" % id
		botao.custom_minimum_size = tam
		botao.ignore_texture_size = true
		botao.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		botao.focus_mode = Control.FOCUS_NONE
		botao.position = pos
		var tipo := int(no.get("type", 0))
		TreeIcons.apply_to_button(botao, tipo, true)
		botao.pressed.connect(_on_node_pressed.bind(id))
		botao.mouse_entered.connect(_on_node_hover_entered.bind(id))
		botao.mouse_exited.connect(_on_node_hover_exited.bind(id))
		botao.mouse_filter = Control.MOUSE_FILTER_STOP
		var rotulo := Label.new()
		rotulo.name = "Rotulo"
		rotulo.text = _node_label_text(no, 0)
		rotulo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rotulo.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		rotulo.add_theme_font_size_override("font_size", 9)
		rotulo.add_theme_color_override("font_color", Color(0.98, 0.92, 0.72, 1))
		rotulo.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		rotulo.add_theme_constant_override("outline_size", 2)
		rotulo.offset_bottom = -2.0
		rotulo.offset_top = -14.0
		rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		botao.add_child(rotulo)
		add_child(botao)
		_nos[id] = botao
	for secao in SkillTreeDefinition.NUM_SECTIONS:
		_build_section_links(secao)
	_ensure_hover_layer()
	queue_redraw()


func _build_section_links(secao: int) -> void:
	var cor := SkillTreeDefinition.region_color(secao).darkened(0.25)
	for row_idx in range(1, SkillTreeDefinition.NUM_ROWS):
		var anterior := SkillTreeDefinition.slots_in_row(row_idx - 1)
		var atual := SkillTreeDefinition.slots_in_row(row_idx)
		if atual.size() == 1 and anterior.size() == 2:
			_add_merge_link(secao, anterior[0], anterior[1], atual[0], cor)
		elif atual.size() == 2 and anterior.size() == 1:
			_add_split_link(secao, anterior[0], atual[0], atual[1], cor)


func _add_merge_link(secao: int, slot_esq: int, slot_dir: int, slot_centro: int, cor: Color) -> void:
	var no_esq := _node_for_slot(secao, slot_esq)
	var no_dir := _node_for_slot(secao, slot_dir)
	var no_centro := _node_for_slot(secao, slot_centro)
	var tam := _node_size(no_esq)
	var pos_esq := SkillTreeDefinition.posicao_do_no(no_esq)
	var pos_dir := SkillTreeDefinition.posicao_do_no(no_dir)
	var pos_centro := SkillTreeDefinition.posicao_do_no(no_centro)
	var id_centro := int(no_centro["id"])

	var sai_esq := pos_esq + Vector2(0.0, tam.y * 0.5)
	var sai_dir := pos_dir + Vector2(0.0, tam.y * 0.5)
	var entra_esq := pos_centro + Vector2(-tam.x * 0.5, 0.0)
	var entra_dir := pos_centro + Vector2(tam.x * 0.5, 0.0)
	var faixa_y := pos_centro.y

	_linhas.append({
		"pontos": PackedVector2Array([
			sai_esq,
			Vector2(sai_esq.x, faixa_y),
			entra_esq,
		]),
		"cor": cor,
		"id_de": int(no_esq["id"]),
		"id_para": id_centro,
	})
	_linhas.append({
		"pontos": PackedVector2Array([
			sai_dir,
			Vector2(sai_dir.x, faixa_y),
			entra_dir,
		]),
		"cor": cor,
		"id_de": int(no_dir["id"]),
		"id_para": id_centro,
	})


func _add_split_link(secao: int, slot_centro: int, slot_esq: int, slot_dir: int, cor: Color) -> void:
	var no_centro := _node_for_slot(secao, slot_centro)
	var no_esq := _node_for_slot(secao, slot_esq)
	var no_dir := _node_for_slot(secao, slot_dir)
	var tam := _node_size(no_centro)
	var pos_centro := SkillTreeDefinition.posicao_do_no(no_centro)
	var pos_esq := SkillTreeDefinition.posicao_do_no(no_esq)
	var pos_dir := SkillTreeDefinition.posicao_do_no(no_dir)
	var id_esq := int(no_esq["id"])
	var id_dir := int(no_dir["id"])
	var id_centro := int(no_centro["id"])

	var sai_centro := pos_centro + Vector2(0.0, tam.y * 0.5)
	var entra_esq := pos_esq + Vector2(tam.x * 0.5, 0.0)
	var entra_dir := pos_dir + Vector2(-tam.x * 0.5, 0.0)
	var faixa_y := pos_esq.y
	var junta := Vector2(pos_centro.x, faixa_y)

	_linhas.append({
		"pontos": PackedVector2Array([sai_centro, junta]),
		"cor": cor,
		"id_de": id_centro,
		"id_para": id_esq,
	})
	_linhas.append({
		"pontos": PackedVector2Array([junta, entra_esq]),
		"cor": cor,
		"id_de": id_centro,
		"id_para": id_esq,
	})
	_linhas.append({
		"pontos": PackedVector2Array([junta, entra_dir]),
		"cor": cor,
		"id_de": id_centro,
		"id_para": id_dir,
	})


func _node_size(_no: Dictionary) -> Vector2:
	return TAMANHO_NO


func _node_label_text(no: Dictionary, nivel: int) -> String:
	var max_nivel := SkillTreeDefinition.max_level(no)
	if int(no.get("type", -1)) == SkillTreeDefinition.BonusType.WAREHOUSE:
		if nivel >= 1:
			return "P%d" % (int(no.get("valor_base", no.get("valor", 0))) + 1)
		return ""
	if nivel <= 0:
		return ""
	return "%d/%d" % [nivel, max_nivel]


func _on_node_pressed(id: int) -> void:
	node_selected.emit(id)


func _on_node_hover_entered(id: int) -> void:
	_hover_id = id
	if _camada_hover:
		_camada_hover.queue_redraw()


func _on_node_hover_exited(id: int) -> void:
	if _hover_id == id:
		_hover_id = -1
		if _camada_hover:
			_camada_hover.queue_redraw()


func _rect_hover() -> Rect2:
	if _hover_id < 0 or not _nos.has(_hover_id):
		return Rect2()
	var botao: Control = _nos[_hover_id]
	return Rect2(botao.position, botao.size).grow(2.0)


func _ensure_hover_layer() -> void:
	if _camada_hover != null and is_instance_valid(_camada_hover):
		return
	_camada_hover = CamadaHover.new()
	_camada_hover.name = "CamadaHover"
	_camada_hover.mapa = self
	_camada_hover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_camada_hover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_camada_hover.z_index = 50
	add_child(_camada_hover)


func _update_visual() -> void:
	if hero_progress == null:
		return
	for id in _nos.keys():
		var botao: TextureButton = _nos[id]
		var no := hero_progress.node_by_id(int(id))
		var nivel := hero_progress.node_level(int(id))
		var max_nivel := hero_progress.max_level(int(id))
		var pode := hero_progress.can_purchase(int(id))
		var custo := SkillTreeDefinition.next_level_cost(no, nivel)
		var bloqueado := nivel <= 0 and not pode
		TreeIcons.apply_to_button(botao, int(no.get("type", 0)), bloqueado)
		var modulate := Color.WHITE
		if bool(no.get("premium", false)) and not bloqueado:
			modulate = Color(1.08, 1.02, 0.82, 1)
		botao.self_modulate = modulate
		var rotulo: Label = botao.get_node("Rotulo")
		if rotulo:
			rotulo.text = _node_label_text(no, nivel)
		var dica := SkillTreeDefinition.bonus_description(no, maxi(nivel, 1))
		if nivel > 0:
			dica = tr(LocaleKeys.TREE_CURRENT) % SkillTreeDefinition.bonus_description(no, nivel)
		if int(no.get("type", -1)) == SkillTreeDefinition.BonusType.WAREHOUSE:
			dica += "\n" + tr(LocaleKeys.TREE_WAREHOUSE_NODE)
		else:
			dica += "\n" + tr(LocaleKeys.TREE_ALL_HEROES_NOTE)
		if bool(no.get("premium", false)):
			dica += "\n" + tr(LocaleKeys.TREE_PREMIUM_COST)
		if nivel < max_nivel:
			dica += "\n" + tr(LocaleKeys.TREE_NEXT) % SkillTreeDefinition.next_level_name(no, nivel)
			dica += "\n" + tr(LocaleKeys.TREE_COST) % custo
			if not hero_progress.can_purchase(int(id)):
				dica += "\n" + tr(LocaleKeys.TREE_UNLOCK_ABOVE)
			elif ouro_atual < custo:
				dica += "\n" + tr(LocaleKeys.TREE_NOT_ENOUGH_GOLD) % custo
		else:
			dica += "\n" + tr(LocaleKeys.TREE_MAX_LEVEL_NODE)
		botao.tooltip_text = dica
	for linha in _linhas:
		var id_de := int(linha["id_de"])
		var id_para := int(linha["id_para"])
		var no_para := hero_progress.node_by_id(id_para)
		var secao := int(no_para.get("secao", 0))
		var cor_secao := SkillTreeDefinition.region_color(secao)
		var nivel_de := hero_progress.node_level(id_de)
		var nivel_para := hero_progress.node_level(id_para)
		var max_para := hero_progress.max_level(id_para)
		var desbloqueada := nivel_de >= 1 and nivel_para >= max_para
		var disponivel := nivel_de >= 1 and hero_progress.can_purchase(id_para) and nivel_para < max_para
		if desbloqueada:
			linha["cor"] = cor_secao.lightened(0.1)
		elif disponivel or (nivel_de >= 1 and nivel_para > 0):
			linha["cor"] = Color(0.95, 0.78, 0.32, 0.9)
		else:
			linha["cor"] = cor_secao.darkened(0.45)
	queue_redraw()


func _center_view() -> void:
	var canvas := SkillTreeDefinition.tamanho_canvas()
	custom_minimum_size = canvas
	size = canvas
	var largura_viewport := canvas.x
	var pai := get_parent()
	if pai is ScrollContainer:
		largura_viewport = (pai as ScrollContainer).size.x
	elif size.x > 0.0:
		largura_viewport = size.x
	_offset.x = maxf(0.0, (largura_viewport - canvas.x) * 0.5)
	_offset.y = 0.0
	_apply_offset()


func _apply_offset() -> void:
	for id in _nos.keys():
		var no := _dados_no(int(id))
		var tam := _node_size(no)
		var pos := SkillTreeDefinition.posicao_do_no(no) - tam * 0.5 + _offset
		(_nos[id] as Control).position = pos
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		call_deferred("_center_view")
