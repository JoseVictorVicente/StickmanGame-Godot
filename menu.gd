class_name MenuInventario
extends Control
## Painel flutuante de personagem / inventário.
## Abre acima do idle, sem cobrir o botão de 4 quadrados.

signal fechado
signal personagem_alterado(indice: int)
signal equipamentos_alterados
signal classe_heroi_alterada(indice: int, classe: ClasseData)
signal janela_solta
signal ouro_obtido(quantidade: int)
signal largura_menus_alterada
signal fase_iniciada(mundo: int, fase: int, dificuldade: int)

const INVENTARIO_COLUNAS := 10
const INVENTARIO_LINHAS := 5
const TAMANHO_SLOT := Vector2(42, 42)
const TAMANHO_SLOT_EQUIP := Vector2(42, 42)
const TAMANHO_SLOT_PERSONAGEM := Vector2(36, 36)
const EQUIP_COLUNAS := 2
const EQUIP_ESQUERDA: Array[String] = ["Primária", "Secundária", "Capacete", "Peitoral", "Luva", "Calça", "Bota"]
const EQUIP_DIREITA: Array[String] = ["Cinto", "Pingente", "Anel", "Bracelete", "Pet"]
var PERSONAGENS: Array[Dictionary] = [
	{"nome": "Guerreiro", "nivel": 1, "classe": ItemData.ClasseRequerida.GUERREIRO},
	{"nome": "Mago", "nivel": 1, "classe": ItemData.ClasseRequerida.MAGO},
	{"nome": "Arqueiro", "nivel": 1, "classe": ItemData.ClasseRequerida.ARQUEIRO},
]

@onready var grade_inventario: GridContainer = %GradeInventario
@onready var botao_sair: Button = %BotaoSair
@onready var botao_sair_jogo: Button = %BotaoSairJogo
@onready var cabecalho: HBoxContainer = %Cabecalho
@onready var equip_esquerda: VBoxContainer = %EquipEsquerda
@onready var equip_direita: VBoxContainer = %EquipDireita
@onready var painel: PanelContainer = %Painel
@onready var grade_personagens: HBoxContainer = %GradePersonagens
@onready var nome_personagem: Label = %NomePersonagem
@onready var nivel_personagem: Label = %NivelPersonagem
@onready var foto_personagem: TextureRect = %FotoPersonagem
@onready var ui_equipe: UiSelecaoEquipe = %AreaEquipe
@onready var area_menus: Control = %AreaMenus
@onready var painel_ferraria: Ferraria = %PainelFerraria
@onready var painel_armazem: PainelArmazem = %PainelArmazem
@onready var painel_mundos: PainelMundos = %PainelMundos
@onready var botao_ferraria: Button = %BotaoFerraria
@onready var botao_armazem: Button = %BotaoArmazem
@onready var botao_mundo: Button = %BotaoMundo
@onready var label_ouro: Label = %LabelOuro
@onready var painel_ouro: Control = %PainelOuro
@onready var espaco_ouro: Control = %EspacoOuro
@onready var centralizar: Control = %Centralizar

const TIPOS_EQUIP: Dictionary = {
	"Capacete": ItemData.Tipo.CAPACETE,
	"Peitoral": ItemData.Tipo.PEITORAL,
	"Luva": ItemData.Tipo.LUVA,
	"Calça": ItemData.Tipo.CALCA,
	"Bota": ItemData.Tipo.BOTA,
	"Cinto": ItemData.Tipo.CINTO,
	"Primária": ItemData.Tipo.ARMA,
	"Arma": ItemData.Tipo.ARMA,
	"Secundária": ItemData.Tipo.SECUNDARIA,
	"Pingente": ItemData.Tipo.PINGENTE,
	"Anel": ItemData.Tipo.ANEL,
	"Bracelete": ItemData.Tipo.BRACELETE,
	"Pet": ItemData.Tipo.PET,
}

var CLASSES: Array[ClasseData] = []

var _arrastando: bool = false
var _offset_mouse: Vector2i = Vector2i.ZERO
var _indice_personagem: int = 0
var _botoes_personagem: Array[Button] = []
var _equip_esquerdo_por_classe: Dictionary = {}
var _equip_direito_por_classe: Dictionary = {}
var _slots_inventario: Array[SlotItem] = []
var _slot_selecionado: SlotItem = null
var _estilos_botao_ferraria: Dictionary = {}
var _estilos_botao_armazem: Dictionary = {}
var _estilos_botao_mundo: Dictionary = {}
var _menus_abaixo: bool = false


func _ready() -> void:
	CLASSES = ClasseData.catalogo()
	_criar_equipamentos_dos_personagens()
	_criar_slots_inventario()
	_criar_seletor_personagens()
	botao_sair.pressed.connect(_on_botao_sair_pressed)
	botao_sair_jogo.pressed.connect(_on_botao_sair_jogo_pressed)
	cabecalho.gui_input.connect(_on_cabecalho_gui_input)
	painel.gui_input.connect(_on_cabecalho_gui_input)
	painel_ferraria.configurar(self)
	painel_armazem.configurar(self)
	painel_mundos.configurar(self)
	area_menus.resized.connect(_alinhar_paineis_laterais)
	painel.resized.connect(_alinhar_paineis_laterais)
	botao_ferraria.pressed.connect(_on_botao_ferraria_pressed)
	painel_ferraria.visibilidade_alterada.connect(_on_ferraria_visibilidade_alterada)
	painel_armazem.visibilidade_alterada.connect(_on_armazem_visibilidade_alterada)
	painel_mundos.visibilidade_alterada.connect(_on_mundos_visibilidade_alterada)
	painel_mundos.fase_iniciada.connect(_on_fase_iniciada)
	painel_ferraria.ouro_obtido.connect(_on_ouro_ferraria)
	visibility_changed.connect(_on_visibilidade_menu_alterada)
	if grade_personagens:
		grade_personagens.visible = false
	_guardar_estilos_botao_ferraria()
	_estilos_botao_armazem["normal"] = botao_armazem.get_theme_stylebox("normal").duplicate()
	_estilos_botao_armazem["hover"] = botao_armazem.get_theme_stylebox("hover").duplicate()
	_estilos_botao_armazem["pressed"] = botao_armazem.get_theme_stylebox("pressed").duplicate()
	_estilos_botao_mundo["normal"] = botao_mundo.get_theme_stylebox("normal").duplicate()
	_estilos_botao_mundo["hover"] = botao_mundo.get_theme_stylebox("hover").duplicate()
	_estilos_botao_mundo["pressed"] = botao_mundo.get_theme_stylebox("pressed").duplicate()
	botao_armazem.pressed.connect(_on_botao_armazem_pressed)
	botao_mundo.pressed.connect(_on_botao_mundo_pressed)
	botao_armazem.icon = _criar_icone_bau()
	botao_armazem.add_theme_constant_override("icon_max_width", 56)
	if painel_ouro:
		painel_ouro.resized.connect(_alinhar_espaco_ouro)
		_alinhar_espaco_ouro()
	call_deferred("_alinhar_paineis_laterais")


func _criar_equipamentos_dos_personagens() -> void:
	for classe in CLASSES:
		var esquerda := _criar_grade_equipamento("EquipEsq_%s" % classe.id, EQUIP_ESQUERDA)
		esquerda.visible = false
		equip_esquerda.add_child(esquerda)
		_equip_esquerdo_por_classe[classe.id] = esquerda

		var direita := _criar_grade_equipamento("EquipDir_%s" % classe.id, EQUIP_DIREITA)
		direita.visible = false
		equip_direita.add_child(direita)
		_equip_direito_por_classe[classe.id] = direita


func _criar_grade_equipamento(nome_no: String, nomes_slots: Array[String]) -> GridContainer:
	var grade := GridContainer.new()
	grade.name = nome_no
	grade.columns = EQUIP_COLUNAS
	grade.add_theme_constant_override("h_separation", 6)
	grade.add_theme_constant_override("v_separation", 6)
	_criar_slots_equipamento(grade, nomes_slots)
	return grade


func _criar_slots_equipamento(grade: GridContainer, nomes: Array[String]) -> void:
	grade.columns = EQUIP_COLUNAS
	var estilo := _criar_estilo_slot()
	for nome in nomes:
		var fundo := SlotItem.new()
		fundo.name = "Slot%s" % nome.replace(" ", "")
		fundo.custom_minimum_size = TAMANHO_SLOT_EQUIP
		fundo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		fundo.add_theme_stylebox_override("panel", estilo)
		fundo.nome_slot = nome

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
		fundo.add_child(icone)
		fundo.configurar(icone, TIPOS_EQUIP.get(nome, ItemData.Tipo.ARMA), false)
		fundo.item_clicado.connect(_on_slot_clicado)
		fundo.item_duplo_clique.connect(_on_slot_duplo_clique)
		fundo.item_botao_direito.connect(_on_slot_botao_direito)
		fundo.item_solto.connect(_on_slot_solto)
		grade.add_child(fundo)


func _criar_slots_inventario() -> void:
	grade_inventario.columns = INVENTARIO_COLUNAS
	var estilo := _criar_estilo_slot()
	var total := INVENTARIO_COLUNAS * INVENTARIO_LINHAS

	for indice in total:
		var slot := SlotItem.new()
		slot.name = "SlotInventario_%02d" % (indice + 1)
		slot.custom_minimum_size = TAMANHO_SLOT
		slot.add_theme_stylebox_override("panel", estilo)

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
		slot.item_clicado.connect(_on_slot_clicado)
		slot.item_duplo_clique.connect(_on_slot_duplo_clique)
		slot.item_botao_direito.connect(_on_slot_botao_direito)
		slot.item_solto.connect(_on_slot_solto)
		grade_inventario.add_child(slot)
		_slots_inventario.append(slot)


func _criar_seletor_personagens() -> void:
	var estilo_normal := _criar_estilo_personagem(false)
	for indice in PERSONAGENS.size():
		var botao := Button.new()
		botao.name = "Personagem_%d" % (indice + 1)
		botao.custom_minimum_size = Vector2(58, 32)
		botao.text = "Herói %d" % (indice + 1)
		botao.add_theme_font_size_override("font_size", 11)
		botao.add_theme_color_override("font_color", Color(0.95, 0.88, 0.7, 1))
		botao.add_theme_stylebox_override("normal", estilo_normal)
		botao.add_theme_stylebox_override("hover", _criar_estilo_personagem(false))
		botao.add_theme_stylebox_override("pressed", _criar_estilo_personagem(true))
		botao.pressed.connect(selecionar_personagem.bind(indice))
		grade_personagens.add_child(botao)
		_botoes_personagem.append(botao)
	selecionar_personagem(0)


func selecionar_personagem(indice: int) -> void:
	_indice_personagem = indice
	var dados: Dictionary = PERSONAGENS[indice]
	nome_personagem.text = str(dados["nome"])
	nivel_personagem.text = "Lv. %d" % int(dados["nivel"])
	if ui_equipe:
		ui_equipe.selecionar_slot(indice, false)
	_atualizar_retrato()

	for i in _botoes_personagem.size():
		var selecionado := i == indice
		var estilo := _criar_estilo_personagem(selecionado)
		_botoes_personagem[i].add_theme_stylebox_override("normal", estilo)
		_botoes_personagem[i].add_theme_stylebox_override("hover", estilo)

	_mostrar_equipamento_do_personagem(indice)
	personagem_alterado.emit(indice)
	equipamentos_alterados.emit()


func _mostrar_equipamento_do_personagem(_indice: int) -> void:
	var id_ativo := _id_classe_do_slot(_indice_personagem)
	for id_classe in _equip_esquerdo_por_classe.keys():
		var ativo := str(id_classe) == id_ativo
		(_equip_esquerdo_por_classe[id_classe] as GridContainer).visible = ativo
		(_equip_direito_por_classe[id_classe] as GridContainer).visible = ativo


func indice_personagem_atual() -> int:
	return _indice_personagem


func obter_itens_equipados(indice: int = -1) -> Array[ItemData]:
	var itens: Array[ItemData] = []
	if indice < 0:
		indice = _indice_personagem
	var grades := _grades_do_slot(indice)
	for grade in grades:
		for filho in grade.get_children():
			var slot := filho as SlotItem
			if slot == null:
				slot = filho.get_node_or_null("FundoSlot") as SlotItem
			if slot and slot.item:
				itens.append(slot.item)
	return itens


func atualizar_nivel_exibido(nivel: int) -> void:
	var dados: Dictionary = PERSONAGENS[_indice_personagem].duplicate()
	dados["nivel"] = nivel
	PERSONAGENS[_indice_personagem] = dados
	nivel_personagem.text = "Lv. %d" % nivel


func definir_abaixo_do_combate(abaixo: bool) -> void:
	_menus_abaixo = abaixo
	if abaixo:
		centralizar.offset_top = 228.0
		centralizar.offset_bottom = -8.0
	else:
		centralizar.offset_top = 8.0
		centralizar.offset_bottom = -228.0
	_alinhar_paineis_laterais()


func obter_retangulos_clicaveis() -> Array[Rect2]:
	if not visible:
		return []
	var rects: Array[Rect2] = [painel.get_global_rect().grow(4.0)]
	if painel_armazem and painel_armazem.visible:
		rects.append(painel_armazem.get_global_rect().grow(4.0))
	if painel_ferraria and painel_ferraria.visible:
		rects.append(painel_ferraria.get_global_rect().grow(4.0))
	if painel_mundos and painel_mundos.visible:
		rects.append(painel_mundos.get_global_rect().grow(4.0))
	return rects


func largura_para_janela() -> int:
	var extra_esq := 0
	var extra_dir := 0
	if painel_armazem and painel_armazem.visible:
		extra_esq = 8 + int(painel_armazem.custom_minimum_size.x)
	if painel_ferraria and painel_ferraria.visible:
		extra_dir = 8 + int(painel_ferraria.custom_minimum_size.x)
	if painel_mundos and painel_mundos.visible:
		extra_dir = 8 + int(painel_mundos.custom_minimum_size.x)
	return 40 + int(painel.custom_minimum_size.x) + 2 * maxi(extra_esq, extra_dir)


func _avisar_largura_menus() -> void:
	call_deferred("_emitir_largura_menus")


func _emitir_largura_menus() -> void:
	_alinhar_paineis_laterais()
	largura_menus_alterada.emit()


func _alinhar_paineis_laterais() -> void:
	if painel == null or area_menus == null:
		return
	painel.reset_size()
	var tam_painel := painel.get_combined_minimum_size()
	tam_painel.x = maxf(tam_painel.x, painel.custom_minimum_size.x)
	if painel.size != tam_painel:
		painel.size = tam_painel
	var y := 0.0
	if _menus_abaixo:
		y = maxf(0.0, area_menus.size.y - painel.size.y)
	var pos_painel := Vector2((area_menus.size.x - painel.size.x) * 0.5, y)
	if painel.position != pos_painel:
		painel.position = pos_painel
	_posicionar_painel_lateral(painel_armazem, true, y, painel.size.y)
	_posicionar_painel_lateral(painel_ferraria, false, y, painel.size.y)
	_posicionar_painel_lateral(painel_mundos, false, y, painel.size.y)


func _posicionar_painel_lateral(lado: Control, na_esquerda: bool, y: float, altura: float) -> void:
	if lado == null or not lado.visible:
		return
	lado.reset_size()
	var largura := maxf(lado.custom_minimum_size.x, lado.get_combined_minimum_size().x)
	var tam := Vector2(largura, maxf(altura, lado.get_combined_minimum_size().y))
	if lado.size != tam:
		lado.size = tam
	var pos: Vector2
	if na_esquerda:
		pos = Vector2(painel.position.x - 8.0 - lado.size.x, y)
	else:
		pos = Vector2(painel.position.x + painel.size.x + 8.0, y)
	if lado.position != pos:
		lado.position = pos


func slots_inventario() -> Array[SlotItem]:
	return _slots_inventario


func atualizar_ouro(valor: int) -> void:
	if label_ouro:
		label_ouro.text = "Ouro  %d" % valor


func _alinhar_espaco_ouro() -> void:
	if painel_ouro == null or espaco_ouro == null:
		return
	espaco_ouro.custom_minimum_size = Vector2(0, painel_ouro.size.y)


func primeiro_slot_inventario_vazio() -> SlotItem:
	for slot in _slots_inventario:
		if slot.item == null:
			return slot
	return null


func primeiro_slot_armazem_vazio() -> SlotItem:
	if painel_armazem:
		return painel_armazem.primeiro_slot_vazio()
	return null


func mover_item_entre_slots(origem: SlotItem, destino: SlotItem) -> void:
	_mover_item(origem, destino)


func conectar_slot_ferraria(slot: SlotItem) -> void:
	if not slot.item_clicado.is_connected(_on_slot_clicado):
		slot.item_clicado.connect(_on_slot_clicado)
	if not slot.item_solto.is_connected(_on_slot_solto):
		slot.item_solto.connect(_on_slot_solto)
	if not slot.item_botao_direito.is_connected(_on_slot_botao_direito):
		slot.item_botao_direito.connect(_on_slot_botao_direito)


func notificar_itens_alterados() -> void:
	equipamentos_alterados.emit()


func arrastar_janela_pelo_evento(event: InputEvent) -> void:
	_on_cabecalho_gui_input(event)


func _gerar_item_inicial() -> void:
	var espada := ItemData.new()
	espada.id = "espada_madeira"
	espada.nome = "Espada de Madeira"
	espada.tipo = ItemData.Tipo.ARMA
	espada.raridade = ItemData.Raridade.COMUM
	espada.dano_bonus = 5
	espada.classe_requerida = ItemData.ClasseRequerida.TODAS
	espada.icone = _criar_icone_espada_madeira()
	_slots_inventario[0].definir_item(espada)


func _criar_icone_espada_madeira() -> Texture2D:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var lamina := Color(0.72, 0.5, 0.22, 1)
	var cabo := Color(0.38, 0.22, 0.1, 1)
	var guarda := Color(0.28, 0.18, 0.08, 1)
	for y in range(3, 22):
		for x in range(14, 18):
			img.set_pixel(x, y, lamina)
	for x in range(10, 22):
		img.set_pixel(x, 21, guarda)
		img.set_pixel(x, 22, guarda)
	for y in range(23, 30):
		for x in range(14, 18):
			img.set_pixel(x, y, cabo)
	return ImageTexture.create_from_image(img)


func _on_slot_clicado(slot: SlotItem) -> void:
	if _slot_selecionado != null and _slot_selecionado != slot:
		if slot.aceita(_slot_selecionado.item) and (_slot_selecionado.aceita(slot.item) or slot.item == null):
			if slot.aceita_qualquer or _classe_pode_usar(_slot_selecionado.item):
				_mover_item(_slot_selecionado, slot)
				_definir_selecao(null)
				return
	if slot.item != null:
		_definir_selecao(slot)
	else:
		_definir_selecao(null)


func _on_slot_duplo_clique(slot: SlotItem) -> void:
	if slot.item == null:
		return
	if _eh_slot_ferraria(slot):
		return
	if slot.aceita_qualquer:
		var destino := _slot_equipamento_atual(slot.item.tipo)
		if destino and _classe_pode_usar(slot.item):
			_mover_item(slot, destino)
			_definir_selecao(null)
	else:
		var vazio := _primeiro_slot_inventario_vazio()
		if vazio:
			_mover_item(slot, vazio)
			_definir_selecao(null)


func _on_slot_botao_direito(slot: SlotItem) -> void:
	if slot.item == null:
		return
	if _eh_slot_ferraria(slot):
		var vazio_inv := primeiro_slot_inventario_vazio()
		if vazio_inv:
			_mover_item(slot, vazio_inv)
			_definir_selecao(null)
		return
	if _eh_slot_armazem(slot):
		var vazio_inv := primeiro_slot_inventario_vazio()
		if vazio_inv:
			_mover_item(slot, vazio_inv)
			_definir_selecao(null)
		return
	if painel_ferraria.esta_aberta():
		var destino := painel_ferraria.primeiro_slot_vazio()
		if destino:
			_mover_item(slot, destino)
			_definir_selecao(null)
		return
	if painel_armazem.esta_aberta():
		var destino_armazem := painel_armazem.primeiro_slot_vazio()
		if destino_armazem:
			_mover_item(slot, destino_armazem)
			_definir_selecao(null)
		return
	_on_slot_duplo_clique(slot)


func _eh_slot_ferraria(slot: SlotItem) -> bool:
	return painel_ferraria != null and slot in painel_ferraria.slots_sintese()


func _eh_slot_armazem(slot: SlotItem) -> bool:
	return painel_armazem != null and slot in painel_armazem.slots_todos()


func _on_slot_solto(destino: SlotItem, _item: ItemData, origem: SlotItem) -> void:
	if origem == null or destino == null or origem == destino:
		return
	if not destino.aceita(origem.item):
		return
	if not destino.aceita_qualquer and not _classe_pode_usar(origem.item):
		return
	if origem.item != null and not origem.aceita(destino.item) and destino.item != null:
		return
	_mover_item(origem, destino)
	_definir_selecao(null)


func _mover_item(origem: SlotItem, destino: SlotItem) -> void:
	var item_origem := origem.item
	var item_destino := destino.item
	origem.definir_item(item_destino)
	destino.definir_item(item_origem)
	equipamentos_alterados.emit()


func _definir_selecao(slot: SlotItem) -> void:
	if _slot_selecionado and is_instance_valid(_slot_selecionado):
		_slot_selecionado.atualizar_visual(false)
	_slot_selecionado = slot
	if _slot_selecionado:
		_slot_selecionado.atualizar_visual(true)


func _criar_estilo_slot_selecionado() -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.22, 0.17, 0.1, 1)
	estilo.border_color = Color(0.95, 0.78, 0.32, 1)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(3)
	return estilo


func _slot_equipamento_atual(tipo: ItemData.Tipo) -> SlotItem:
	for grade in _grades_do_slot(_indice_personagem):
		for grupo in grade.get_children():
			var fundo := grupo.get_node_or_null("FundoSlot") as SlotItem
			if fundo and fundo.tipo_aceitavel == tipo:
				return fundo
	return null


func _primeiro_slot_inventario_vazio() -> SlotItem:
	return primeiro_slot_inventario_vazio()


func adicionar_item(item: ItemData) -> bool:
	var slot := primeiro_slot_inventario_vazio()
	if slot == null:
		slot = primeiro_slot_armazem_vazio()
	if slot == null:
		return false
	slot.definir_item(item)
	return true


func obter_classe_atual() -> ClasseData:
	if ui_equipe and ui_equipe._party:
		var classe: Variant = ui_equipe._party.equipe_ativa[_indice_personagem]
		if classe is ClasseData:
			return classe
	if CLASSES.is_empty():
		return ClasseData.criar("guerreiro", "Guerreiro", 5, 1.0, 1.0, Color(0.14, 0.14, 0.16), ItemData.ClasseRequerida.GUERREIRO)
	return CLASSES[mini(_indice_personagem, CLASSES.size() - 1)]


func obter_dano_equipado(indice: int) -> int:
	var total := 0
	for item in obter_itens_equipados(indice):
		total += item.dano_bonus
	return total


func configurar_equipe(party: PartyManager) -> void:
	ui_equipe.configurar(party, _indice_personagem)
	if not ui_equipe.slot_selecionado.is_connected(selecionar_personagem):
		ui_equipe.slot_selecionado.connect(selecionar_personagem)
	if not ui_equipe.classe_atribuida.is_connected(_on_classe_atribuida):
		ui_equipe.classe_atribuida.connect(_on_classe_atribuida)
	_sincronizar_nomes_da_equipe()
	_mostrar_equipamento_do_personagem(_indice_personagem)
	_atualizar_retrato()


func _on_classe_atribuida(_indice: int, _classe: ClasseData) -> void:
	_sincronizar_nomes_da_equipe()
	_mostrar_equipamento_do_personagem(_indice_personagem)
	_atualizar_retrato()
	classe_heroi_alterada.emit(_indice_personagem, obter_classe_atual())
	equipamentos_alterados.emit()


func _sincronizar_nomes_da_equipe() -> void:
	if ui_equipe == null or ui_equipe._party == null:
		return
	var party: PartyManager = ui_equipe._party
	for i in PartyManager.SLOTS:
		var classe: Variant = party.equipe_ativa[i]
		var dados: Dictionary = PERSONAGENS[i].duplicate()
		if classe is ClasseData:
			dados["nome"] = (classe as ClasseData).nome_classe
			dados["classe"] = (classe as ClasseData).classe_item
		else:
			dados["nome"] = "Vazio"
		PERSONAGENS[i] = dados
	nome_personagem.text = str(PERSONAGENS[_indice_personagem]["nome"])


func _atualizar_retrato() -> void:
	if foto_personagem == null:
		return
	var classe: ClasseData = obter_classe_atual()
	foto_personagem.texture = classe.sprite_personagem if classe else null


func _classe_pode_usar(item: ItemData) -> bool:
	if item == null:
		return true
	if item.classe_requerida == ItemData.ClasseRequerida.TODAS:
		return true
	var classe: ClasseData = obter_classe_atual()
	if classe == null:
		return false
	return classe.classe_item == item.classe_requerida


func preencher_item_inicial_se_vazio() -> void:
	for slot in _slots_inventario:
		if slot.item:
			return
	_gerar_item_inicial()


func serializar_inventario() -> Array:
	var lista: Array = []
	for slot in _slots_inventario:
		lista.append(slot.item.para_dicionario() if slot.item else {})
	return lista


func aplicar_inventario(lista: Array) -> void:
	for i in _slots_inventario.size():
		var item: ItemData = null
		if i < lista.size() and lista[i] is Dictionary:
			item = ItemData.de_dicionario(lista[i])
		_slots_inventario[i].definir_item(item)


func atualizar_progressao_mundos(mundo: int, fase: int, dificuldade: int, liberadas: Array) -> void:
	if painel_mundos:
		painel_mundos.definir_estado(mundo, fase, dificuldade, liberadas)


func serializar_armazem() -> Dictionary:
	return painel_armazem.serializar() if painel_armazem else {}


func aplicar_armazem(dados: Variant) -> void:
	if painel_armazem:
		painel_armazem.aplicar(dados)


func serializar_equipamentos() -> Dictionary:
	var todos: Dictionary = {}
	for id_classe in _equip_esquerdo_por_classe.keys():
		var lista: Array = []
		for slot in _slots_da_classe(str(id_classe)):
			lista.append({
				"tipo": int(slot.tipo_aceitavel),
				"item": slot.item.para_dicionario() if slot.item else {},
			})
		todos[str(id_classe)] = lista
	return todos


func aplicar_equipamentos(todos: Variant) -> void:
	if todos is Dictionary:
		for id_classe in _equip_esquerdo_por_classe.keys():
			var chave := str(id_classe)
			var lista: Array = todos[chave] if todos.has(chave) and todos[chave] is Array else []
			_aplicar_lista_slots(_slots_da_classe(chave), lista)
		return
	if todos is Array:
		var ids_antigos: Array[String] = ["guerreiro", "mago", "arqueiro"]
		for i in mini(todos.size(), ids_antigos.size()):
			if todos[i] is Array:
				_aplicar_lista_slots(_slots_da_classe(ids_antigos[i]), todos[i])


func _aplicar_lista_slots(slots: Array[SlotItem], lista: Array) -> void:
	var por_tipo: Dictionary = {}
	for entrada in lista:
		if entrada is Dictionary:
			por_tipo[int(entrada.get("tipo", -1))] = entrada.get("item", {})
	for slot in slots:
		var item: ItemData = null
		var dados: Variant = por_tipo.get(int(slot.tipo_aceitavel), {})
		if dados is Dictionary:
			item = ItemData.de_dicionario(dados)
		slot.definir_item(item)


func _id_classe_do_slot(indice: int) -> String:
	if ui_equipe and ui_equipe._party:
		var classe: Variant = ui_equipe._party.equipe_ativa[indice]
		if classe is ClasseData:
			return (classe as ClasseData).id
	return ""


func _grades_do_slot(indice: int) -> Array[GridContainer]:
	return _grades_da_classe(_id_classe_do_slot(indice))


func _grades_da_classe(id_classe: String) -> Array[GridContainer]:
	var grades: Array[GridContainer] = []
	if id_classe == "" or not _equip_esquerdo_por_classe.has(id_classe):
		return grades
	grades.append(_equip_esquerdo_por_classe[id_classe])
	grades.append(_equip_direito_por_classe[id_classe])
	return grades


func _slots_da_classe(id_classe: String) -> Array[SlotItem]:
	var slots: Array[SlotItem] = []
	for grade in _grades_da_classe(id_classe):
		for filho in grade.get_children():
			var slot := filho as SlotItem
			if slot == null:
				slot = filho.get_node_or_null("FundoSlot") as SlotItem
			if slot:
				slots.append(slot)
	return slots


func _criar_estilo_personagem(selecionado: bool) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	if selecionado:
		estilo.bg_color = Color(0.22, 0.17, 0.1, 1)
		estilo.border_color = Color(0.95, 0.78, 0.32, 1)
		estilo.set_border_width_all(3)
	else:
		estilo.bg_color = Color(0.08, 0.07, 0.06, 1)
		estilo.border_color = Color(0.42, 0.35, 0.24, 1)
		estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(3)
	return estilo


func _criar_estilo_slot() -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.08, 0.07, 0.06, 1)
	estilo.border_color = Color(0.42, 0.35, 0.24, 1)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(3)
	return estilo


func _guardar_estilos_botao_ferraria() -> void:
	_estilos_botao_ferraria["normal"] = botao_ferraria.get_theme_stylebox("normal").duplicate()
	_estilos_botao_ferraria["hover"] = botao_ferraria.get_theme_stylebox("hover").duplicate()
	_estilos_botao_ferraria["pressed"] = botao_ferraria.get_theme_stylebox("pressed").duplicate()


func _on_botao_ferraria_pressed() -> void:
	if painel_ferraria.esta_aberta():
		painel_ferraria.fechar()
	else:
		_fechar_paineis_direita(painel_ferraria)
		painel_ferraria.abrir()
	botao_ferraria.release_focus()


func _on_botao_armazem_pressed() -> void:
	painel_armazem.alternar()
	botao_armazem.release_focus()


func _on_botao_mundo_pressed() -> void:
	if painel_mundos.esta_aberta():
		painel_mundos.fechar()
	else:
		_fechar_paineis_direita(painel_mundos)
		painel_mundos.abrir()
	botao_mundo.release_focus()


func _fechar_paineis_direita(exceto: Control = null) -> void:
	if painel_ferraria and painel_ferraria != exceto and painel_ferraria.esta_aberta():
		painel_ferraria.fechar()
	if painel_mundos and painel_mundos != exceto and painel_mundos.esta_aberta():
		painel_mundos.fechar()


func _criar_icone_bau() -> Texture2D:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var madeira := Color(0.55, 0.32, 0.12, 1)
	var madeira_escura := Color(0.32, 0.16, 0.06, 1)
	var ferro := Color(0.72, 0.62, 0.28, 1)
	var ouro := Color(0.95, 0.78, 0.22, 1)
	for y in range(22, 56):
		for x in range(8, 56):
			img.set_pixel(x, y, madeira if y < 38 else madeira_escura.lerp(madeira, 0.35))
	for y in range(18, 28):
		for x in range(6, 58):
			img.set_pixel(x, y, madeira)
	for x in range(8, 56):
		img.set_pixel(x, 37, ferro)
		img.set_pixel(x, 38, ferro)
	for y in range(22, 56):
		img.set_pixel(31, y, ferro)
		img.set_pixel(32, y, ferro)
	for y in range(34, 46):
		for x in range(28, 36):
			img.set_pixel(x, y, ouro)
	return ImageTexture.create_from_image(img)


func _on_ferraria_visibilidade_alterada(aberta: bool) -> void:
	if not aberta:
		_definir_selecao(null)
		_restaurar_estilo_botao_ferraria()
		_avisar_largura_menus()
		return
	var estilo := _criar_estilo_botao_ferraria_ativo()
	botao_ferraria.add_theme_stylebox_override("normal", estilo)
	botao_ferraria.add_theme_stylebox_override("hover", estilo)
	botao_ferraria.add_theme_stylebox_override("pressed", estilo)
	_avisar_largura_menus()


func _on_armazem_visibilidade_alterada(aberta: bool) -> void:
	if aberta:
		var estilo := _criar_estilo_botao_ferraria_ativo()
		botao_armazem.add_theme_stylebox_override("normal", estilo)
		botao_armazem.add_theme_stylebox_override("hover", estilo)
		botao_armazem.add_theme_stylebox_override("pressed", estilo)
		_avisar_largura_menus()
		return
	for nome in _estilos_botao_armazem.keys():
		botao_armazem.add_theme_stylebox_override(str(nome), _estilos_botao_armazem[nome])
	botao_armazem.release_focus()
	botao_armazem.set_pressed_no_signal(false)
	_avisar_largura_menus()


func _restaurar_estilo_botao_ferraria() -> void:
	for nome in _estilos_botao_ferraria.keys():
		botao_ferraria.add_theme_stylebox_override(str(nome), _estilos_botao_ferraria[nome])
	botao_ferraria.release_focus()
	botao_ferraria.set_pressed_no_signal(false)


func _criar_estilo_botao_ferraria_ativo() -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.content_margin_left = 8
	estilo.content_margin_top = 7
	estilo.content_margin_right = 8
	estilo.content_margin_bottom = 7
	estilo.bg_color = Color(0.32, 0.24, 0.16, 1)
	estilo.border_color = Color(0.95, 0.78, 0.32, 1)
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(4)
	return estilo


func _on_mundos_visibilidade_alterada(aberta: bool) -> void:
	if aberta:
		var estilo := _criar_estilo_botao_ferraria_ativo()
		botao_mundo.add_theme_stylebox_override("normal", estilo)
		botao_mundo.add_theme_stylebox_override("hover", estilo)
		botao_mundo.add_theme_stylebox_override("pressed", estilo)
		_avisar_largura_menus()
		return
	for nome in _estilos_botao_mundo.keys():
		botao_mundo.add_theme_stylebox_override(str(nome), _estilos_botao_mundo[nome])
	botao_mundo.release_focus()
	botao_mundo.set_pressed_no_signal(false)
	_avisar_largura_menus()


func _on_fase_iniciada(mundo: int, fase: int, dificuldade: int) -> void:
	fase_iniciada.emit(mundo, fase, dificuldade)


func _on_ouro_ferraria(quantidade: int) -> void:
	ouro_obtido.emit(quantidade)


func _on_visibilidade_menu_alterada() -> void:
	if not visible:
		painel_ferraria.fechar()
		painel_armazem.fechar()
		painel_mundos.fechar()
		return
	call_deferred("_alinhar_paineis_laterais")


func _on_botao_sair_pressed() -> void:
	hide()
	fechado.emit()


func _on_botao_sair_jogo_pressed() -> void:
	SaveSystem.salvar()
	get_tree().quit()


func _on_cabecalho_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse := event as InputEventMouseButton
		var soltou: bool = _arrastando and not mouse.pressed
		_arrastando = mouse.pressed
		if _arrastando:
			_offset_mouse = DisplayServer.mouse_get_position() - DisplayServer.window_get_position()
		elif soltou:
			janela_solta.emit()
	elif event is InputEventMouseMotion and _arrastando:
		DisplayServer.window_set_position(DisplayServer.mouse_get_position() - _offset_mouse)
