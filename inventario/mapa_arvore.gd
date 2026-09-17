class_name MapaArvore
extends Control
## Três colunas diamante centralizadas com nós clicáveis.

signal no_selecionado(id: int)

const TAMANHO_NO := Vector2(44, 44)

var progresso: ProgressoArvore
var ouro_atual: int = 0

var _catalogo: Array[Dictionary] = []
var _nos: Dictionary = {}
var _offset := Vector2.ZERO
var _linhas: Array[Dictionary] = []


func _ready() -> void:
	clip_contents = false
	mouse_filter = Control.MOUSE_FILTER_PASS
	_catalogo = ArvoreHabilidades.catalogo()
	_montar_nos()
	call_deferred("_centralizar")


func configurar(prog: ProgressoArvore, ouro: int) -> void:
	progresso = prog
	ouro_atual = ouro
	_centralizar()
	_atualizar_visual()


func _dados_no(id: int) -> Dictionary:
	for no in _catalogo:
		if int(no.get("id", -1)) == id:
			return no
	return {}


func _no_por_slot(secao: int, slot: int) -> Dictionary:
	return _dados_no(ArvoreHabilidades.id_do_no(secao, slot))


func _draw() -> void:
	_desenhar_colunas()
	for linha in _linhas:
		var pontos: PackedVector2Array = linha["pontos"]
		var cor: Color = linha["cor"]
		for i in range(pontos.size() - 1):
			draw_line(pontos[i] + _offset, pontos[i + 1] + _offset, cor, 2.0, true)


func _desenhar_colunas() -> void:
	var font := ThemeDB.fallback_font
	var font_titulo := 12
	var font_pontos := 9
	var altura_arvore := float(ArvoreHabilidades.NUM_LINHAS) * ArvoreHabilidades.ALTURA_LINHA
	for secao in ArvoreHabilidades.NUM_SECOES:
		var x := ArvoreHabilidades.centro_x_coluna(secao) + _offset.x
		var y_titulo := ArvoreHabilidades.MARGEM_SUPERIOR + _offset.y + 16.0
		var cor := ArvoreHabilidades.cor_regiao(secao)
		var nome := ArvoreHabilidades.nome_regiao(secao)
		var pontos := 0
		if progresso:
			pontos = progresso.pontos_na_regiao(secao)
		var x_coluna := x - ArvoreHabilidades.LARGURA_COLUNA * 0.5
		var y_coluna := ArvoreHabilidades.MARGEM_SUPERIOR + _offset.y
		var faixa := Rect2(
			x_coluna,
			y_coluna,
			ArvoreHabilidades.LARGURA_COLUNA,
			ArvoreHabilidades.ALTURA_CABECALHO + altura_arvore
		)
		draw_rect(faixa, Color(0.14, 0.12, 0.1, 0.55), true)
		draw_rect(faixa, cor.darkened(0.35), false, 2.0)
		draw_string(
			font,
			Vector2(x_coluna, y_titulo),
			nome,
			HORIZONTAL_ALIGNMENT_CENTER,
			ArvoreHabilidades.LARGURA_COLUNA,
			font_titulo,
			cor.lightened(0.2)
		)
		draw_string(
			font,
			Vector2(x_coluna, y_titulo + 18.0),
			"%d pts" % pontos,
			HORIZONTAL_ALIGNMENT_CENTER,
			ArvoreHabilidades.LARGURA_COLUNA,
			font_pontos,
			Color(0.78, 0.72, 0.58, 0.95)
		)


func _montar_nos() -> void:
	for filho in get_children():
		filho.queue_free()
	_nos.clear()
	_linhas.clear()
	for no in _catalogo:
		var id := int(no["id"])
		var tam := _tamanho_no(no)
		var pos := ArvoreHabilidades.posicao_do_no(no) - tam * 0.5
		var botao := TextureButton.new()
		botao.name = "No_%d" % id
		botao.custom_minimum_size = tam
		botao.ignore_texture_size = true
		botao.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		botao.focus_mode = Control.FOCUS_NONE
		botao.position = pos
		botao.texture_normal = _textura_no()
		botao.pressed.connect(_on_no_pressionado.bind(id))
		botao.mouse_filter = Control.MOUSE_FILTER_STOP
		var rotulo := Label.new()
		rotulo.text = _texto_rotulo(no)
		rotulo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rotulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		rotulo.add_theme_font_size_override("font_size", 9)
		rotulo.add_theme_color_override("font_color", Color(0.95, 0.88, 0.7, 1))
		rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		botao.add_child(rotulo)
		add_child(botao)
		_nos[id] = botao
	for secao in ArvoreHabilidades.NUM_SECOES:
		_montar_ligacoes_secao(secao)
	queue_redraw()


func _montar_ligacoes_secao(secao: int) -> void:
	var cor := ArvoreHabilidades.cor_regiao(secao).darkened(0.25)
	for row_idx in range(1, ArvoreHabilidades.NUM_LINHAS):
		var anterior := ArvoreHabilidades.slots_da_linha(row_idx - 1)
		var atual := ArvoreHabilidades.slots_da_linha(row_idx)
		if atual.size() == 1 and anterior.size() == 2:
			_adicionar_ligacao_merge(secao, anterior[0], anterior[1], atual[0], cor)
		elif atual.size() == 2 and anterior.size() == 1:
			_adicionar_ligacao_split(secao, anterior[0], atual[0], atual[1], cor)


func _adicionar_ligacao_merge(secao: int, slot_esq: int, slot_dir: int, slot_centro: int, cor: Color) -> void:
	var no_esq := _no_por_slot(secao, slot_esq)
	var no_dir := _no_por_slot(secao, slot_dir)
	var no_centro := _no_por_slot(secao, slot_centro)
	var tam := _tamanho_no(no_esq)
	var pos_esq := ArvoreHabilidades.posicao_do_no(no_esq)
	var pos_dir := ArvoreHabilidades.posicao_do_no(no_dir)
	var pos_centro := ArvoreHabilidades.posicao_do_no(no_centro)
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


func _adicionar_ligacao_split(secao: int, slot_centro: int, slot_esq: int, slot_dir: int, cor: Color) -> void:
	var no_centro := _no_por_slot(secao, slot_centro)
	var no_esq := _no_por_slot(secao, slot_esq)
	var no_dir := _no_por_slot(secao, slot_dir)
	var tam := _tamanho_no(no_centro)
	var pos_centro := ArvoreHabilidades.posicao_do_no(no_centro)
	var pos_esq := ArvoreHabilidades.posicao_do_no(no_esq)
	var pos_dir := ArvoreHabilidades.posicao_do_no(no_dir)
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


func _tamanho_no(_no: Dictionary) -> Vector2:
	return TAMANHO_NO


func _texto_rotulo(no: Dictionary) -> String:
	if int(no.get("tipo", -1)) == ArvoreHabilidades.TipoBonus.ARMAZEM:
		return "P%d" % (int(no.get("valor", 0)) + 1)
	return str(no.get("sigla", ""))


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
		var secao := int(no.get("secao", -1))
		var cor_base := ArvoreHabilidades.cor_regiao(secao).darkened(0.55)
		var cor := cor_base
		if desbloqueado:
			cor = cor_base.lightened(0.35)
		elif pode and ouro_atual >= custo:
			cor = cor_base.lightened(0.18)
		elif pode:
			cor = cor_base.lightened(0.08)
		else:
			cor = cor_base.darkened(0.35)
		if bool(no.get("premium", false)) and not desbloqueado:
			cor = cor.lerp(Color(0.95, 0.78, 0.22, 1), 0.25)
		botao.self_modulate = cor
		var dica := str(no.get("nome", ""))
		if int(no.get("tipo", -1)) == ArvoreHabilidades.TipoBonus.ARMAZEM:
			dica += "\nDesbloqueia uma página do armazém"
		else:
			dica += "\n(Afeta todos os heróis)"
		if bool(no.get("premium", false)):
			dica += "\n[Custo elevado]"
		if not desbloqueado:
			dica += "\nCusto: %d ouro" % custo
			if not progresso.pode_comprar(int(id)):
				dica += "\nDesbloqueie todos os nós acima"
			elif ouro_atual < custo:
				dica += "\nOuro insuficiente"
		botao.tooltip_text = dica
	for linha in _linhas:
		var id_de := int(linha["id_de"])
		var id_para := int(linha["id_para"])
		var no_para := progresso.no_por_id(id_para)
		var secao := int(no_para.get("secao", 0))
		var cor_secao := ArvoreHabilidades.cor_regiao(secao)
		var desbloqueada := progresso.esta_desbloqueado(id_de) and progresso.esta_desbloqueado(id_para)
		var disponivel := progresso.esta_desbloqueado(id_de) and progresso.pode_comprar(id_para)
		if desbloqueada:
			linha["cor"] = cor_secao.lightened(0.1)
		elif disponivel:
			linha["cor"] = Color(0.95, 0.78, 0.32, 0.9)
		else:
			linha["cor"] = cor_secao.darkened(0.45)
	queue_redraw()


func _centralizar() -> void:
	var canvas := ArvoreHabilidades.tamanho_canvas()
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
	_aplicar_offset()


func _aplicar_offset() -> void:
	for id in _nos.keys():
		var no := _dados_no(int(id))
		var tam := _tamanho_no(no)
		var pos := ArvoreHabilidades.posicao_do_no(no) - tam * 0.5 + _offset
		(_nos[id] as Control).position = pos
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		call_deferred("_centralizar")


func _textura_no() -> Texture2D:
	var tam := int(TAMANHO_NO.x)
	var img := Image.create(tam, tam, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var borda := Color(0.95, 0.82, 0.4, 1)
	var preenchimento := Color(0.92, 0.88, 0.82, 1)
	for y in tam:
		for x in tam:
			var na_borda := x == 0 or y == 0 or x == tam - 1 or y == tam - 1
			if na_borda:
				img.set_pixel(x, y, borda)
			else:
				img.set_pixel(x, y, preenchimento)
	return ImageTexture.create_from_image(img)
