class_name PainelArmazem
extends PanelContainer
## Painel lateral de armazém, à esquerda do inventário.
## Várias abas; só a primeira começa desbloqueada.

signal visibilidade_alterada(aberta: bool)

const ABAS := 8
const COLUNAS_ABAS := 4
const PAGINAS_ARVORE := 3
const INDICE_PRIMEIRA_PAGINA_EXTRA := 4
const COLUNAS := 5
const LINHAS := 8
const TAMANHO_SLOT := Vector2(42, 42)

@onready var cabecalho: HBoxContainer = %CabecalhoArmazem
@onready var botao_fechar: Button = %BotaoFecharArmazem
@onready var linha_abas: GridContainer = %LinhaAbas
@onready var grade_armazem: GridContainer = %GradeArmazem
@onready var label_status: Label = %LabelStatusArmazem
@onready var botao_ordenar: Button = %BotaoOrdenarArmazem

var _menu: MenuInventario
var _slots_por_aba: Array = []
var _botoes_aba: Array[Button] = []
var _aba_atual: int = 0
var _desbloqueadas: Array[bool] = []


func _ready() -> void:
	hide()
	_inicializar_desbloqueio()
	_criar_abas()
	_criar_grades()
	botao_fechar.pressed.connect(fechar)
	cabecalho.gui_input.connect(_on_cabecalho_gui_input)
	gui_input.connect(_on_cabecalho_gui_input)
	_configurar_botao_ordenar()
	mostrar_aba(0)


func configurar(menu: MenuInventario) -> void:
	_menu = menu
	for lista in _slots_por_aba:
		for slot in lista:
			_menu.conectar_slot_ferraria(slot)


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
	show()
	visibilidade_alterada.emit(true)


func fechar() -> void:
	hide()
	visibilidade_alterada.emit(false)


func primeiro_slot_vazio() -> SlotItem:
	if not _desbloqueadas[_aba_atual]:
		return null
	for slot in _slots_da_aba(_aba_atual):
		if slot.item == null:
			return slot
	return null


func slots_todos() -> Array[SlotItem]:
	var todos: Array[SlotItem] = []
	for lista in _slots_por_aba:
		for slot in lista:
			todos.append(slot)
	return todos


func mostrar_aba(indice: int) -> void:
	if indice < 0 or indice >= ABAS:
		return
	if not _desbloqueadas[indice]:
		label_status.text = "Aba %d bloqueada." % (indice + 1)
		if botao_ordenar:
			botao_ordenar.disabled = true
		return
	_aba_atual = indice
	for i in ABAS:
		var grade: GridContainer = grade_armazem.get_node("GradeAba_%d" % i)
		grade.visible = i == indice
		_pintar_aba(_botoes_aba[i], i == indice, _desbloqueadas[i])
	label_status.text = "Armazém %d" % (indice + 1)
	if botao_ordenar:
		botao_ordenar.disabled = false


func _configurar_botao_ordenar() -> void:
	if botao_ordenar == null:
		return
	MenuInventario.configurar_botao_icone(botao_ordenar, "res://sprites/ui/sort_inventory.png")
	botao_ordenar.pressed.connect(_on_botao_ordenar_pressed)


func _on_botao_ordenar_pressed() -> void:
	if not _desbloqueadas[_aba_atual]:
		return
	MenuInventario.ordenar_slots(_slots_da_aba(_aba_atual))
	if _menu:
		_menu.notificar_itens_alterados()
	botao_ordenar.release_focus()


func desbloquear_aba(indice: int) -> void:
	if indice < 0 or indice >= ABAS:
		return
	if indice >= 1 and indice <= PAGINAS_ARVORE:
		return
	_definir_estado_aba(indice, true)


func aplicar_desbloqueios_arvore(indices: Array[int]) -> void:
	for indice in range(1, PAGINAS_ARVORE + 1):
		_definir_estado_aba(indice, indice in indices)
	if not _desbloqueadas[_aba_atual]:
		mostrar_aba(0)


func _definir_estado_aba(indice: int, desbloqueada: bool) -> void:
	if indice < 0 or indice >= ABAS:
		return
	_desbloqueadas[indice] = desbloqueada
	if indice >= _botoes_aba.size():
		return
	var botao := _botoes_aba[indice]
	botao.disabled = not desbloqueada
	botao.text = str(indice + 1) if desbloqueada else "🔒"
	_pintar_aba(botao, indice == _aba_atual, desbloqueada)


func _inicializar_desbloqueio() -> void:
	_desbloqueadas.clear()
	for i in ABAS:
		_desbloqueadas.append(i == 0)


func serializar() -> Dictionary:
	var abas: Array = []
	for lista in _slots_por_aba:
		var itens: Array = []
		for slot in lista:
			itens.append(slot.item.para_dicionario() if slot.item else {})
		abas.append(itens)
	return {
		"desbloqueadas": _desbloqueadas.duplicate(),
		"abas": abas,
	}


func aplicar(dados: Variant) -> void:
	if dados is Array:
		_aplicar_lista(_slots_da_aba(0), dados)
		return
	if not (dados is Dictionary):
		return
	var flags: Variant = dados.get("desbloqueadas", [])
	if flags is Array:
		for i in range(INDICE_PRIMEIRA_PAGINA_EXTRA, mini(flags.size(), ABAS)):
			_desbloqueadas[i] = bool(flags[i])
			_definir_estado_aba(i, _desbloqueadas[i])
	var abas: Variant = dados.get("abas", [])
	if abas is Array:
		for i in mini(abas.size(), ABAS):
			if abas[i] is Array:
				_aplicar_lista(_slots_da_aba(i), abas[i])
	mostrar_aba(_aba_atual)


func _criar_abas() -> void:
	linha_abas.columns = COLUNAS_ABAS
	for i in ABAS:
		var botao := Button.new()
		botao.name = "Aba_%d" % (i + 1)
		botao.custom_minimum_size = Vector2(0, 28)
		botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		botao.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		botao.add_theme_font_size_override("font_size", 12)
		if _desbloqueadas[i]:
			botao.text = str(i + 1)
		else:
			botao.text = "🔒"
			botao.disabled = true
		botao.pressed.connect(mostrar_aba.bind(i))
		linha_abas.add_child(botao)
		_botoes_aba.append(botao)
		_pintar_aba(botao, i == 0, _desbloqueadas[i])


func _criar_grades() -> void:
	grade_armazem.columns = 1
	for i in ABAS:
		var grade := GridContainer.new()
		grade.name = "GradeAba_%d" % i
		grade.columns = COLUNAS
		grade.add_theme_constant_override("h_separation", 4)
		grade.add_theme_constant_override("v_separation", 4)
		grade.visible = i == 0
		var lista: Array[SlotItem] = []
		for n in COLUNAS * LINHAS:
			lista.append(_criar_slot(grade, i, n))
		_slots_por_aba.append(lista)
		grade_armazem.add_child(grade)


func _criar_slot(grade: GridContainer, aba: int, indice: int) -> SlotItem:
	var slot := SlotItem.new()
	slot.name = "SlotArmazem_%d_%02d" % [aba, indice + 1]
	slot.custom_minimum_size = TAMANHO_SLOT
	var icone := TextureRect.new()
	icone.name = "Icone"
	icone.set_anchors_preset(Control.PRESET_FULL_RECT)
	icone.offset_left = 4.0
	icone.offset_top = 4.0
	icone.offset_right = -4.0
	icone.offset_bottom = -4.0
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(icone)
	slot.configurar(icone, ItemData.Tipo.ARMA, true)
	grade.add_child(slot)
	return slot


func _slots_da_aba(indice: int) -> Array[SlotItem]:
	var saida: Array[SlotItem] = []
	if indice < 0 or indice >= _slots_por_aba.size():
		return saida
	for slot in _slots_por_aba[indice]:
		saida.append(slot)
	return saida


func _aplicar_lista(slots: Array[SlotItem], lista: Array) -> void:
	for i in slots.size():
		var item: ItemData = null
		if i < lista.size() and lista[i] is Dictionary:
			item = ItemData.de_dicionario(lista[i])
		slots[i].definir_item(item)


func _pintar_aba(botao: Button, ativa: bool, desbloqueada: bool) -> void:
	var estilo := StyleBoxFlat.new()
	estilo.content_margin_left = 6
	estilo.content_margin_top = 6
	estilo.content_margin_right = 6
	estilo.content_margin_bottom = 6
	estilo.set_corner_radius_all(4)
	estilo.set_border_width_all(1)
	if not desbloqueada:
		estilo.bg_color = Color(0.1, 0.09, 0.08, 1)
		estilo.border_color = Color(0.32, 0.28, 0.22, 1)
		botao.add_theme_color_override("font_color", Color(0.5, 0.46, 0.4, 1))
	elif ativa:
		estilo.bg_color = Color(0.32, 0.24, 0.16, 1)
		estilo.border_color = Color(0.95, 0.78, 0.32, 1)
		botao.add_theme_color_override("font_color", Color(1, 0.92, 0.72, 1))
	else:
		estilo.bg_color = Color(0.18, 0.14, 0.11, 1)
		estilo.border_color = Color(0.62, 0.5, 0.28, 1)
		botao.add_theme_color_override("font_color", Color(0.95, 0.88, 0.7, 1))
	botao.add_theme_stylebox_override("normal", estilo)
	botao.add_theme_stylebox_override("hover", estilo)
	botao.add_theme_stylebox_override("disabled", estilo)


func _on_cabecalho_gui_input(event: InputEvent) -> void:
	if _menu == null:
		return
	_menu.arrastar_janela_pelo_evento(event)
