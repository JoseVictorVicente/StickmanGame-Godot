class_name PainelMundos
extends PanelContainer
## Painel direito de mundos e fases. Só um painel direito fica aberto por vez.

signal visibilidade_alterada(aberta: bool)
signal fase_iniciada(mundo: int, fase: int, dificuldade: int)

const TAMANHO_FASE := 34.0
const TAMANHO_CHEFE := 48.0

@onready var botao_voltar: Button = %BotaoVoltarMundos
@onready var botao_fechar: Button = %BotaoFecharMundos
@onready var titulo: Label = %TituloMundos
@onready var cabecalho: HBoxContainer = %CabecalhoMundos
@onready var painel_lista: VBoxContainer = %PainelListaMundos
@onready var lista_mundos: VBoxContainer = %ListaMundos
@onready var botao_dificuldade: Button = %BotaoDificuldade
@onready var opcoes_dificuldade: VBoxContainer = %OpcoesDificuldade
@onready var menu_dificuldade: PanelContainer = %MenuDificuldade
@onready var fundo_menu_dificuldade: ColorRect = %FundoMenuDificuldade
@onready var painel_mapa: Control = %PainelMapaFases
@onready var mapa_fases: MapaFases = %MapaFases

var _menu: MenuInventario
var _mundo_aberto: int = 1
var _mundo_atual: int = 1
var _fase_atual: int = 1
var _dificuldade: int = ProgressaoMundos.Dificuldade.FACIL
var _liberadas: Array[int] = [1, 1, 1]
var _botoes_mundo: Array[Button] = []
var _botoes_fase: Array[Button] = []
var _rotulos_fase: Array[Label] = []
var _ancoras_fase: Array[Control] = []
var _botoes_opcao_dificuldade: Array[Button] = []


func _ready() -> void:
	hide()
	botao_fechar.pressed.connect(fechar)
	botao_voltar.pressed.connect(_mostrar_lista_mundos)
	botao_dificuldade.pressed.connect(_alternar_opcoes_dificuldade)
	fundo_menu_dificuldade.gui_input.connect(_on_fundo_dificuldade_gui_input)
	cabecalho.gui_input.connect(_on_cabecalho_gui_input)
	gui_input.connect(_on_cabecalho_gui_input)
	mapa_fases.resized.connect(_posicionar_fases)
	painel_mapa.visibility_changed.connect(_on_mapa_visibilidade_alterada)
	_criar_lista_mundos()
	_criar_opcoes_dificuldade()
	_criar_mapa_fases()
	_mostrar_lista_mundos()
	_atualizar_botao_dificuldade()


func configurar(menu: MenuInventario) -> void:
	_menu = menu


func definir_estado(mundo: int, fase: int, dificuldade: int, liberadas: Array) -> void:
	var mundo_anterior := _mundo_atual
	_mundo_atual = clampi(mundo, 1, ProgressaoMundos.TOTAL_MUNDOS)
	_fase_atual = clampi(fase, 1, ProgressaoMundos.FASES_POR_MUNDO)
	_dificuldade = clampi(dificuldade, 0, 2)
	_liberadas.clear()
	for i in 3:
		var valor := 1
		if i < liberadas.size():
			valor = clampi(int(liberadas[i]), 1, ProgressaoMundos.PROGRESSO_COMPLETO)
		_liberadas.append(valor)
	if not ProgressaoMundos.dificuldade_liberada(_dificuldade, _liberadas):
		_dificuldade = ProgressaoMundos.Dificuldade.FACIL
		while _dificuldade < 2 and ProgressaoMundos.dificuldade_liberada(_dificuldade + 1, _liberadas):
			_dificuldade += 1
	_atualizar_botao_dificuldade()
	_atualizar_lista_mundos()
	if painel_mapa.visible and _mundo_atual != mundo_anterior and _fase_atual == 1:
		_abrir_mapa_mundo(_mundo_atual)
	else:
		_atualizar_mapa()


func esta_aberta() -> bool:
	return visible


func alternar() -> void:
	if visible:
		fechar()
	else:
		abrir()


func abrir() -> void:
	if _menu == null or not _menu.visible:
		return
	_mostrar_lista_mundos()
	show()
	visibilidade_alterada.emit(true)


func fechar() -> void:
	_fechar_menu_dificuldade()
	hide()
	visibilidade_alterada.emit(false)


func _criar_lista_mundos() -> void:
	for filho in lista_mundos.get_children():
		filho.queue_free()
	_botoes_mundo.clear()
	for i in ProgressaoMundos.TOTAL_MUNDOS:
		var botao := Button.new()
		botao.name = "BotaoMundo_%d" % (i + 1)
		botao.size_flags_vertical = Control.SIZE_EXPAND_FILL
		botao.custom_minimum_size = Vector2(0, 42)
		botao.add_theme_font_size_override("font_size", 16)
		botao.pressed.connect(_abrir_mapa_mundo.bind(i + 1))
		lista_mundos.add_child(botao)
		_botoes_mundo.append(botao)
	_atualizar_lista_mundos()


func _criar_opcoes_dificuldade() -> void:
	for filho in opcoes_dificuldade.get_children():
		filho.queue_free()
	_botoes_opcao_dificuldade.clear()
	for i in ProgressaoMundos.NOMES_DIFICULDADE.size():
		var botao := Button.new()
		botao.text = ProgressaoMundos.NOMES_DIFICULDADE[i]
		botao.custom_minimum_size = Vector2(0, 32)
		botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		botao.clip_text = true
		botao.add_theme_font_size_override("font_size", 12)
		botao.pressed.connect(_escolher_dificuldade.bind(i))
		opcoes_dificuldade.add_child(botao)
		_botoes_opcao_dificuldade.append(botao)
	_atualizar_opcoes_dificuldade()


func _criar_mapa_fases() -> void:
	for i in ProgressaoMundos.FASES_POR_MUNDO:
		var ancora := Control.new()
		ancora.name = "AncoraFase_%d" % (i + 1)
		ancora.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mapa_fases.add_child(ancora)

		var rotulo := Label.new()
		rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rotulo.add_theme_font_size_override("font_size", 11)
		rotulo.add_theme_color_override("font_color", Color(0.95, 0.88, 0.7, 1))
		rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ancora.add_child(rotulo)

		var botao := Button.new()
		var tamanho := TAMANHO_CHEFE if i == ProgressaoMundos.FASES_POR_MUNDO - 1 else TAMANHO_FASE
		botao.custom_minimum_size = Vector2(tamanho, tamanho)
		botao.focus_mode = Control.FOCUS_NONE
		botao.pressed.connect(_on_fase_pressionada.bind(i + 1))
		ancora.add_child(botao)

		_ancoras_fase.append(ancora)
		_rotulos_fase.append(rotulo)
		_botoes_fase.append(botao)
	call_deferred("_posicionar_fases")


func _mostrar_lista_mundos() -> void:
	_fechar_menu_dificuldade()
	botao_voltar.hide()
	titulo.text = "MUNDOS"
	painel_lista.show()
	painel_mapa.hide()
	_atualizar_lista_mundos()


func _abrir_mapa_mundo(mundo: int) -> void:
	_mundo_aberto = clampi(mundo, 1, ProgressaoMundos.TOTAL_MUNDOS)
	_fechar_menu_dificuldade()
	botao_voltar.show()
	titulo.text = "MUNDO %d" % _mundo_aberto
	painel_lista.hide()
	painel_mapa.show()
	_atualizar_mapa()
	call_deferred("_posicionar_fases")


func _on_mapa_visibilidade_alterada() -> void:
	if painel_mapa.visible:
		call_deferred("_posicionar_fases")


func _alternar_opcoes_dificuldade() -> void:
	if menu_dificuldade.visible:
		_fechar_menu_dificuldade()
		return
	_atualizar_opcoes_dificuldade()
	fundo_menu_dificuldade.show()
	menu_dificuldade.show()
	call_deferred("_posicionar_menu_dificuldade")


func _fechar_menu_dificuldade() -> void:
	if menu_dificuldade:
		menu_dificuldade.hide()
	if fundo_menu_dificuldade:
		fundo_menu_dificuldade.hide()


func _posicionar_menu_dificuldade() -> void:
	if not menu_dificuldade.visible:
		return
	menu_dificuldade.reset_size()
	var largura := botao_dificuldade.size.x
	var altura_item := botao_dificuldade.size.y
	for botao in _botoes_opcao_dificuldade:
		botao.custom_minimum_size = Vector2(largura - 4.0, altura_item)
	menu_dificuldade.reset_size()
	var tam := Vector2(largura, menu_dificuldade.get_combined_minimum_size().y)
	menu_dificuldade.size = tam
	var camada := menu_dificuldade.get_parent() as Control
	var botao_rect := botao_dificuldade.get_global_rect()
	var local_end := botao_rect.end - camada.get_global_rect().position
	var pos := Vector2(
		local_end.x - menu_dificuldade.size.x,
		local_end.y - botao_dificuldade.size.y - 4.0 - menu_dificuldade.size.y
	)
	pos.x = clampf(pos.x, 0.0, maxf(0.0, camada.size.x - menu_dificuldade.size.x))
	pos.y = clampf(pos.y, 0.0, maxf(0.0, camada.size.y - menu_dificuldade.size.y))
	menu_dificuldade.position = pos


func _on_fundo_dificuldade_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_fechar_menu_dificuldade()
		fundo_menu_dificuldade.accept_event()


func _escolher_dificuldade(valor: int) -> void:
	if not ProgressaoMundos.dificuldade_liberada(valor, _liberadas):
		return
	_dificuldade = clampi(valor, 0, 2)
	_fechar_menu_dificuldade()
	_atualizar_botao_dificuldade()
	_atualizar_lista_mundos()
	_atualizar_mapa()


func _on_fase_pressionada(fase: int) -> void:
	if not _fase_liberada(_mundo_aberto, fase):
		return
	fase_iniciada.emit(_mundo_aberto, fase, _dificuldade)


func _fase_liberada(mundo: int, fase: int) -> bool:
	if not ProgressaoMundos.dificuldade_liberada(_dificuldade, _liberadas):
		return false
	return ProgressaoMundos.indice(mundo, fase) <= _liberadas[_dificuldade]


func _mundo_liberado(mundo: int) -> bool:
	return _fase_liberada(mundo, 1)


func _atualizar_lista_mundos() -> void:
	for i in _botoes_mundo.size():
		var mundo := i + 1
		var liberado := _mundo_liberado(mundo)
		var atual := mundo == _mundo_atual
		var texto := "MUNDO %d" % mundo
		if not liberado:
			texto += "  🔒"
		_botoes_mundo[i].text = texto
		_botoes_mundo[i].disabled = false
		_pintar_botao(_botoes_mundo[i], atual, not liberado)


func _atualizar_mapa() -> void:
	for i in _botoes_fase.size():
		var fase := i + 1
		var rotulo := "%d-%d" % [_mundo_aberto, fase]
		_rotulos_fase[i].text = rotulo
		_botoes_fase[i].text = ""
		var liberada := _fase_liberada(_mundo_aberto, fase)
		var atual := _mundo_aberto == _mundo_atual and fase == _fase_atual
		var concluida := ProgressaoMundos.indice(_mundo_aberto, fase) < _liberadas[_dificuldade]
		_botoes_fase[i].disabled = not liberada
		_pintar_fase(_botoes_fase[i], _rotulos_fase[i], atual, concluida, not liberada, fase == ProgressaoMundos.FASES_POR_MUNDO)
	_posicionar_fases()


func _atualizar_botao_dificuldade() -> void:
	botao_dificuldade.text = ProgressaoMundos.nome_dificuldade(_dificuldade)
	_pintar_botao(botao_dificuldade, true)
	_atualizar_opcoes_dificuldade()


func _atualizar_opcoes_dificuldade() -> void:
	for i in _botoes_opcao_dificuldade.size():
		var liberada := ProgressaoMundos.dificuldade_liberada(i, _liberadas)
		var texto := ProgressaoMundos.NOMES_DIFICULDADE[i]
		if not liberada:
			texto += " 🔒"
		_botoes_opcao_dificuldade[i].text = texto
		_botoes_opcao_dificuldade[i].disabled = not liberada
		_pintar_botao(_botoes_opcao_dificuldade[i], i == _dificuldade, not liberada, true)


func _posicionar_fases() -> void:
	if mapa_fases.size.x < 8.0 or mapa_fases.size.y < 8.0:
		return
	var area := Rect2(Vector2(18, 10), mapa_fases.size - Vector2(36, 20))
	for i in _ancoras_fase.size():
		var ratio: Vector2 = ProgressaoMundos.POSICOES_FASES[i]
		var centro := area.position + Vector2(area.size.x * ratio.x, area.size.y * ratio.y)
		var botao := _botoes_fase[i]
		var rotulo := _rotulos_fase[i]
		botao.reset_size()
		rotulo.reset_size()
		var raio := botao.size.x * 0.5
		botao.position = Vector2(-raio, -raio)
		rotulo.position = Vector2(-rotulo.size.x * 0.5, -raio - rotulo.size.y - 2.0)
		_ancoras_fase[i].position = centro
	var pontos: Array[Vector2] = []
	for ancora in _ancoras_fase:
		pontos.append(ancora.position)
	mapa_fases.pontos = pontos
	mapa_fases.queue_redraw()


func _pintar_botao(botao: Button, ativo: bool = false, bloqueado: bool = false, compacto: bool = false) -> void:
	var estilo := StyleBoxFlat.new()
	var margem := 6 if compacto else 10
	estilo.content_margin_left = margem
	estilo.content_margin_top = 6 if compacto else 8
	estilo.content_margin_right = margem
	estilo.content_margin_bottom = 6 if compacto else 8
	estilo.set_corner_radius_all(4)
	estilo.set_border_width_all(2)
	if bloqueado:
		estilo.bg_color = Color(0.12, 0.1, 0.09, 1)
		estilo.border_color = Color(0.38, 0.32, 0.22, 1)
		botao.add_theme_color_override("font_color", Color(0.62, 0.56, 0.46, 1))
	elif ativo:
		estilo.bg_color = Color(0.32, 0.24, 0.16, 1)
		estilo.border_color = Color(0.95, 0.78, 0.32, 1)
		botao.add_theme_color_override("font_color", Color(1, 0.92, 0.72, 1))
	else:
		estilo.bg_color = Color(0.16, 0.13, 0.1, 1)
		estilo.border_color = Color(0.72, 0.6, 0.34, 1)
		botao.add_theme_color_override("font_color", Color(0.95, 0.88, 0.7, 1))
	botao.add_theme_stylebox_override("normal", estilo)
	botao.add_theme_stylebox_override("hover", estilo)
	botao.add_theme_stylebox_override("pressed", estilo)
	botao.add_theme_stylebox_override("disabled", estilo)


func _pintar_fase(botao: Button, rotulo: Label, atual: bool, concluida: bool, bloqueada: bool, chefe: bool) -> void:
	var estilo := StyleBoxFlat.new()
	var raio := int(TAMANHO_CHEFE if chefe else TAMANHO_FASE)
	estilo.set_corner_radius_all(raio)
	estilo.set_border_width_all(3 if chefe or atual else 2)
	if bloqueada:
		estilo.bg_color = Color(0.12, 0.1, 0.09, 1)
		estilo.border_color = Color(0.36, 0.3, 0.2, 1)
		rotulo.add_theme_color_override("font_color", Color(0.55, 0.5, 0.4, 1))
	elif atual:
		estilo.bg_color = Color(0.42, 0.18, 0.12, 1)
		estilo.border_color = Color(1, 0.86, 0.38, 1)
		rotulo.add_theme_color_override("font_color", Color(1, 0.92, 0.55, 1))
	elif concluida:
		estilo.bg_color = Color(0.22, 0.28, 0.16, 1)
		estilo.border_color = Color(0.78, 0.72, 0.38, 1)
		rotulo.add_theme_color_override("font_color", Color(0.92, 0.86, 0.62, 1))
	else:
		estilo.bg_color = Color(0.18, 0.14, 0.11, 1)
		estilo.border_color = Color(0.82, 0.68, 0.36, 1)
		rotulo.add_theme_color_override("font_color", Color(0.95, 0.88, 0.7, 1))
	botao.add_theme_stylebox_override("normal", estilo)
	botao.add_theme_stylebox_override("hover", estilo)
	botao.add_theme_stylebox_override("pressed", estilo)
	botao.add_theme_stylebox_override("disabled", estilo)


func _on_cabecalho_gui_input(event: InputEvent) -> void:
	if _menu == null:
		return
	_menu.arrastar_janela_pelo_evento(event)
