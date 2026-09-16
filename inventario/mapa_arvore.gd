class_name MapaArvore
extends Control
## Mapa radial com pan por arraste e nós clicáveis.

signal no_selecionado(id: int)

const TAMANHO_NO := Vector2(52, 52)
const TAMANHO_CENTRO := Vector2(58, 58)
const TAMANHO_CANVAS := Vector2(900, 900)

var progresso: ProgressoArvore
var ouro_atual: int = 0

var _catalogo: Array[Dictionary] = []
var _nos: Dictionary = {}
var _offset := Vector2.ZERO
var _arrastando := false
var _mouse_inicio := Vector2.ZERO
var _offset_inicio := Vector2.ZERO
var _linhas: Array[Dictionary] = []


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_catalogo = ArvoreHabilidades.catalogo()
	_montar_nos()
	call_deferred("_centralizar")


func configurar(prog: ProgressoArvore, ouro: int) -> void:
	progresso = prog
	ouro_atual = ouro
	_atualizar_visual()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse := event as InputEventMouseButton
		if mouse.pressed:
			if _mouse_sobre_no(mouse.position):
				return
			_arrastando = true
			_mouse_inicio = mouse.position
			_offset_inicio = _offset
		else:
			_arrastando = false
	elif event is InputEventMouseMotion and _arrastando:
		_offset = _offset_inicio + (event as InputEventMouseMotion).position - _mouse_inicio
		_aplicar_offset()


func _mouse_sobre_no(pos: Vector2) -> bool:
	for id in _nos.keys():
		var controle := _nos[id] as Control
		if Rect2(controle.position, controle.size).has_point(pos):
			return true
	return false


func _dados_no(id: int) -> Dictionary:
	for no in _catalogo:
		if int(no.get("id", -1)) == id:
			return no
	return {}


func _draw() -> void:
	if _linhas.is_empty():
		return
	for linha in _linhas:
		var de: Vector2 = linha["de"] + _offset
		var para: Vector2 = linha["para"] + _offset
		var cor: Color = linha["cor"]
		draw_line(de, para, cor, 2.0, true)


func _montar_nos() -> void:
	for filho in get_children():
		filho.queue_free()
	_nos.clear()
	_linhas.clear()
	for no in _catalogo:
		var id := int(no["id"])
		var pos := ArvoreHabilidades.posicao_do_no(no) - (TAMANHO_CENTRO if id == 0 else TAMANHO_NO) * 0.5
		var botao := TextureButton.new()
		botao.name = "No_%d" % id
		botao.custom_minimum_size = TAMANHO_CENTRO if id == 0 else TAMANHO_NO
		botao.ignore_texture_size = true
		botao.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		botao.focus_mode = Control.FOCUS_NONE
		botao.position = pos
		botao.texture_normal = _textura_no(id == 0)
		botao.pressed.connect(_on_no_pressionado.bind(id))
		botao.mouse_filter = Control.MOUSE_FILTER_STOP
		var rotulo := Label.new()
		rotulo.text = "ATK" if id == 0 else str(id)
		rotulo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rotulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		rotulo.add_theme_font_size_override("font_size", 9 if id == 0 else 8)
		rotulo.add_theme_color_override("font_color", Color(0.95, 0.88, 0.7, 1))
		rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		botao.add_child(rotulo)
		add_child(botao)
		_nos[id] = botao
		var pai := int(no.get("pai", -1))
		if pai >= 0:
			var no_pai := _dados_no(pai)
			_linhas.append({
				"de": ArvoreHabilidades.posicao_do_no(no_pai),
				"para": ArvoreHabilidades.posicao_do_no(no),
				"cor": Color(0.55, 0.44, 0.26, 0.85),
			})
	queue_redraw()


func _on_no_pressionado(id: int) -> void:
	no_selecionado.emit(id)


func _atualizar_visual() -> void:
	if progresso == null:
		return
	for id in _nos.keys():
		var botao: TextureButton = _nos[id]
		var no := progresso.no_por_id(int(id))
		var desbloqueado := progresso.esta_desbloqueado(int(id))
		var pode := progresso.pode_comprar(int(id))
		var custo := ArvoreHabilidades.custo_do_no(no)
		var cor := Color(0.18, 0.14, 0.11, 0.95)
		if desbloqueado:
			cor = Color(0.22, 0.38, 0.16, 0.96)
		elif pode and ouro_atual >= custo:
			cor = Color(0.32, 0.24, 0.16, 0.96)
		elif pode:
			cor = Color(0.28, 0.18, 0.12, 0.92)
		else:
			cor = Color(0.10, 0.09, 0.08, 0.82)
		if int(id) == 0:
			cor = cor.lightened(0.08)
		botao.self_modulate = cor
		var dica := str(no.get("nome", "")) + "\n(Afeta todos os heróis)"
		if not desbloqueado:
			dica += "\nCusto: %d ouro" % custo
			if not progresso.pode_comprar(int(id)):
				dica += "\nRequer nó anterior"
			elif ouro_atual < custo:
				dica += "\nOuro insuficiente"
		botao.tooltip_text = dica
	for linha in _linhas:
		var id_de := _id_do_no_na_posicao(linha["de"])
		var id_para := _id_do_no_na_posicao(linha["para"])
		var desbloqueada := progresso.esta_desbloqueado(id_de) and progresso.esta_desbloqueado(id_para)
		var disponivel := progresso.esta_desbloqueado(id_de) and progresso.pode_comprar(id_para)
		if desbloqueada:
			linha["cor"] = Color(0.35, 0.72, 0.28, 0.95)
		elif disponivel:
			linha["cor"] = Color(0.95, 0.78, 0.32, 0.9)
		else:
			linha["cor"] = Color(0.35, 0.28, 0.18, 0.75)
	queue_redraw()


func _id_do_no_na_posicao(pos: Vector2) -> int:
	for no in _catalogo:
		if ArvoreHabilidades.posicao_do_no(no).distance_to(pos) < 1.0:
			return int(no.get("id", -1))
	return -1


func _centralizar() -> void:
	var area := size
	if area.x < 8.0 or area.y < 8.0:
		return
	_offset = (area - TAMANHO_CANVAS) * 0.5
	_aplicar_offset()


func _aplicar_offset() -> void:
	for id in _nos.keys():
		var no := _dados_no(int(id))
		var tam := TAMANHO_CENTRO if int(id) == 0 else TAMANHO_NO
		var pos := ArvoreHabilidades.posicao_do_no(no) - tam * 0.5 + _offset
		(_nos[id] as Control).position = pos
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		call_deferred("_centralizar")


func _textura_no(centro: bool) -> Texture2D:
	var tam := int(TAMANHO_CENTRO.x if centro else TAMANHO_NO.x)
	var img := Image.create(tam, tam, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var meio := Vector2(tam, tam) * 0.5
	var raio := tam * 0.5 - 3.0
	for y in tam:
		for x in tam:
			var dist := Vector2(x + 0.5, y + 0.5).distance_to(meio)
			if dist <= raio - 2.0:
				img.set_pixel(x, y, Color.WHITE)
			elif dist <= raio:
				img.set_pixel(x, y, Color(0.95, 0.82, 0.4, 1))
	return ImageTexture.create_from_image(img)
