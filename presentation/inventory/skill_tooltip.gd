class_name SkillTooltip
extends RefCounted
## Popup de tooltip para slots de habilidade.

const CAMADA_TOOLTIP := 128
const Z_INDEX_TOOLTIP := 4096
const OFFSET := Vector2(10, 0)
const LARGURA_MAXIMA := 260

static var _camada: CanvasLayer
static var _painel: PanelContainer
static var _slot_atual: Control


static func vincular(controle: Control, obter_skill: Callable) -> void:
	if controle == null:
		return
	controle.mouse_entered.connect(func() -> void:
		var skill: Variant = obter_skill.call()
		if skill is SkillResource:
			_mostrar(controle, skill as SkillResource)
	)
	controle.mouse_exited.connect(_ocultar)
	if not controle.visibility_changed.is_connected(_on_visibility_changed):
		controle.visibility_changed.connect(_on_visibility_changed.bind(controle))
	if not controle.tree_exiting.is_connected(_ocultar):
		controle.tree_exiting.connect(_ocultar)


static func vincular_skill(controle: Control, skill: SkillResource) -> void:
	vincular(controle, func() -> SkillResource: return skill)


static func _on_visibility_changed(controle: Control) -> void:
	if controle == _slot_atual and not controle.is_visible_in_tree():
		_ocultar()


static func _mostrar(controle: Control, skill: SkillResource) -> void:
	if skill == null or controle == null or not is_instance_valid(controle):
		return
	if not controle.is_visible_in_tree():
		return
	_slot_atual = controle
	var painel := _garantir_painel()
	_preencher(painel, skill)
	painel.show()
	painel.move_to_front()
	_posicionar_deferred()


static func _posicionar_deferred() -> void:
	var arvore := Engine.get_main_loop() as SceneTree
	if arvore != null:
		arvore.process_frame.connect(_posicionar_apos_frame, CONNECT_ONE_SHOT)


static func _posicionar_apos_frame() -> void:
	_posicionar()


static func _ocultar() -> void:
	_slot_atual = null
	if _painel and is_instance_valid(_painel):
		_painel.hide()


static func _garantir_painel() -> PanelContainer:
	if _camada == null or not is_instance_valid(_camada):
		_camada = CanvasLayer.new()
		_camada.layer = CAMADA_TOOLTIP
		_camada.name = "CamadaSkillTooltip"
		var arvore := Engine.get_main_loop() as SceneTree
		if arvore != null:
			arvore.root.add_child(_camada)
	if _painel == null or not is_instance_valid(_painel):
		_painel = PanelContainer.new()
		_painel.z_index = Z_INDEX_TOOLTIP
		_painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_camada.add_child(_painel)
	return _painel


static func _preencher(painel: PanelContainer, skill: SkillResource) -> void:
	for filho in painel.get_children():
		filho.queue_free()
	var cor_borda := Color(0.55, 0.82, 0.38, 1)
	if skill.type == SkillResource.Type.PASSIVE:
		cor_borda = Color(0.52, 0.62, 0.95, 1)
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color(0.08, 0.07, 0.06, 0.96)
	fundo.border_color = cor_borda
	fundo.set_border_width_all(2)
	fundo.set_corner_radius_all(4)
	fundo.content_margin_left = 10
	fundo.content_margin_top = 8
	fundo.content_margin_right = 10
	fundo.content_margin_bottom = 8
	painel.add_theme_stylebox_override("panel", fundo)

	var coluna := VBoxContainer.new()
	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_theme_constant_override("separation", 4)
	coluna.custom_minimum_size.x = LARGURA_MAXIMA
	coluna.add_child(_rotulo(skill.get_display_name(), Color(0.95, 0.9, 0.7, 1), 13, true))
	coluna.add_child(_rotulo(skill.type_cooldown_line(), cor_borda, 11, false))
	coluna.add_child(_rotulo(skill.get_description(), Color(0.82, 0.78, 0.68, 1), 11, false, true))
	painel.add_child(coluna)


static func _rotulo(texto: String, cor: Color, tamanho: int, negrito: bool, autowrap: bool = false) -> Label:
	var rotulo := Label.new()
	rotulo.text = texto
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rotulo.add_theme_color_override("font_color", cor)
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.custom_minimum_size.x = LARGURA_MAXIMA
	if autowrap:
		rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rotulo.size.x = LARGURA_MAXIMA
	if negrito:
		rotulo.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
		rotulo.add_theme_constant_override("outline_size", 2)
	return rotulo


static func _posicionar() -> void:
	if _slot_atual == null or _painel == null or not is_instance_valid(_painel):
		return
	_painel.reset_size()
	var tam := _painel.get_combined_minimum_size()
	if _painel.size.x > tam.x or _painel.size.y > tam.y:
		tam = _painel.size
	_painel.size = tam
	_painel.pivot_offset = Vector2.ZERO

	var viewport := _slot_atual.get_viewport().get_visible_rect()
	var slot_rect := _slot_atual.get_global_rect()
	var abrir_esquerda := _deve_abrir_esquerda(_slot_atual, slot_rect)
	var pos := Vector2.ZERO

	if abrir_esquerda:
		pos.x = slot_rect.position.x - tam.x - OFFSET.x
		pos.y = slot_rect.position.y + (slot_rect.size.y - tam.y) * 0.5
		if pos.x < viewport.position.x + 4.0:
			pos.x = slot_rect.end.x + OFFSET.x
	else:
		pos.x = slot_rect.end.x + OFFSET.x
		pos.y = slot_rect.position.y + (slot_rect.size.y - tam.y) * 0.5
		if pos.x + tam.x > viewport.end.x - 4.0:
			pos.x = slot_rect.position.x - tam.x - OFFSET.x

	pos.x = clampf(pos.x, viewport.position.x + 4.0, maxf(viewport.position.x + 4.0, viewport.end.x - tam.x - 4.0))
	pos.y = clampf(pos.y, viewport.position.y + 4.0, maxf(viewport.position.y + 4.0, viewport.end.y - tam.y - 4.0))
	_painel.global_position = pos


static func _deve_abrir_esquerda(controle: Control, slot_rect: Rect2) -> bool:
	if _esta_em_coluna_esquerda(controle):
		return false
	if _is_in_right_column(controle):
		return true
	var hud := _get_hud_rect(controle)
	if hud.size.x <= 0.0:
		return slot_rect.get_center().x >= controle.get_viewport().get_visible_rect().size.x * 0.5
	return slot_rect.get_center().x >= hud.position.x + hud.size.x * 0.5


static func _esta_em_coluna_esquerda(controle: Control) -> bool:
	var no: Node = controle
	while no:
		var nome := str(no.name)
		if nome == "ActiveColumn" or nome == "ColunaEquipAtivas":
			return true
		if nome.begins_with("EquipEsq_"):
			return true
		no = no.get_parent()
	return false


static func _is_in_right_column(controle: Control) -> bool:
	var no: Node = controle
	while no:
		var nome := str(no.name)
		if nome == "PassiveColumn" or nome == "ColunaEquipPassivas":
			return true
		if nome.begins_with("EquipDir_"):
			return true
		no = no.get_parent()
	return false


static func _get_hud_rect(controle: Control) -> Rect2:
	var no: Node = controle
	while no:
		if no is Control and (no.name == "Painel" or no.name == "Menu" or no.name == "SkillsPanel"):
			return (no as Control).get_global_rect()
		no = no.get_parent()
	return Rect2()
