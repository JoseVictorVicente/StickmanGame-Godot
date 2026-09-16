class_name PainelArvore
extends PanelContainer
## Cobre o inventário e abriga a árvore de habilidades.

signal visibilidade_alterada(aberta: bool)

@onready var botao_voltar: Button = %BotaoVoltarArvore
@onready var cabecalho: HBoxContainer = %CabecalhoArvore
@onready var mapa: MapaArvore = %MapaArvore
@onready var label_ouro: Label = %LabelOuroArvore
@onready var label_mensagem: Label = %LabelMensagemArvore

var _menu: MenuInventario


func _ready() -> void:
	hide()
	botao_voltar.pressed.connect(fechar)
	cabecalho.gui_input.connect(_on_cabecalho_gui_input)
	gui_input.connect(_on_cabecalho_gui_input)
	if mapa:
		mapa.no_selecionado.connect(_on_no_selecionado)


func configurar(menu: MenuInventario) -> void:
	_menu = menu


func esta_aberta() -> bool:
	return visible


func abrir() -> void:
	if _menu == null or not _menu.visible:
		return
	show()
	atualizar()
	visibilidade_alterada.emit(true)
	call_deferred("_reforcar_layout")


func atualizar() -> void:
	if _menu == null or mapa == null:
		return
	mapa.configurar(_menu.progresso_arvore(), _menu.obter_ouro_atual())
	if label_ouro:
		label_ouro.text = "Ouro  %d" % _menu.obter_ouro_atual()
	if label_mensagem:
		label_mensagem.text = "Arraste para navegar. Clique nos nós para comprar habilidades."


func _reforcar_layout() -> void:
	if visible:
		visibilidade_alterada.emit(true)


func fechar() -> void:
	hide()
	visibilidade_alterada.emit(false)


func _on_no_selecionado(id_no: int) -> void:
	if _menu == null:
		return
	var progresso := _menu.progresso_arvore()
	if progresso.esta_desbloqueado(id_no):
		_mostrar_mensagem("Habilidade já adquirida.")
		return
	if not progresso.pode_comprar(id_no):
		_mostrar_mensagem("Desbloqueie o nó anterior primeiro.")
		return
	var no := progresso.no_por_id(id_no)
	var custo := ArvoreHabilidades.custo_do_no(no)
	if not _menu.tentar_gastar_ouro(custo):
		_mostrar_mensagem("Ouro insuficiente (%d necessários)." % custo)
		return
	progresso.desbloquear(id_no)
	_menu.notificar_arvore_alterada()
	atualizar()
	_mostrar_mensagem("Adquirido: %s (todos os heróis)" % str(no.get("nome", "")))


func _mostrar_mensagem(texto: String) -> void:
	if label_mensagem:
		label_mensagem.text = texto


func _on_cabecalho_gui_input(event: InputEvent) -> void:
	if _menu:
		_menu.arrastar_janela_pelo_evento(event)
