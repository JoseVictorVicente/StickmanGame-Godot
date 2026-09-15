extends Node2D
## Combate idle: o Stickman ataca sozinho a cada 1s.
## O dano total soma o dano base com o dano_bonus dos itens equipados.

const DANO_BASE := 5
const INTERVALO_ATAQUE := 1.0
const XP_BASE_NIVEL := 20
const LARGURA_JANELA := 960
const ALTURA_JANELA := 860
const PALCO_MARGEM_TOPO := 8
const PALCO_ALTURA := 124
const PALCO_BASE_JANELA := 108
const PAINEL_ALTURA := 100
const BOTAO_TAMANHO := 80

@onready var menu_inventario: MenuInventario = $HudInventario/MenuInventario
@onready var area_botao_menu: ColorRect = $HudBotao/AreaBotaoMenu
@onready var botao_abrir_inventario: Button = $HudBotao/AreaBotaoMenu/BotaoAbrirInventario
@onready var timer_ataque: Timer = $TimerAtaque
@onready var painel_batalha: PanelContainer = $HudBatalha/PainelBatalha
@onready var label_inimigo: Label = %LabelInimigo
@onready var barra_vida: ProgressBar = %BarraVidaInimigo
@onready var label_nivel: Label = %LabelNivel
@onready var label_dano: Label = %LabelDano
@onready var label_aviso: Label = %LabelAviso
@onready var palco: Control = $HudBatalha/Palco
@onready var chao: ColorRect = %Chao
@onready var combate: Node2D = $HudBatalha/Combate
@onready var party: PartyManager = $HudBatalha/Combate/PartyManager
@onready var inimigo_visual: Sprite2D = $HudBatalha/Combate/InimigoVisual
@onready var efeito_moedas: Control = $HudBatalha/CamadaEfeitos

var ouro: int = 0
var dano_base: int = DANO_BASE
var dano_total: int = DANO_BASE
var onda: int = 1
var inimigo_atual: Inimigo
var _drops := GerenciadorDrops.new()
var _tween_aviso: Tween
var _resolvendo_morte: bool = false
var _arrastando_janela: bool = false
var _offset_arraste: Vector2i = Vector2i.ZERO
var _combate_no_topo: bool = false

## XP e nível de cada um dos 3 personagens.
var _progresso: Array[Dictionary] = [
	{"nivel": 1, "xp": 0, "xp_proximo": XP_BASE_NIVEL},
	{"nivel": 1, "xp": 0, "xp_proximo": XP_BASE_NIVEL},
	{"nivel": 1, "xp": 0, "xp_proximo": XP_BASE_NIVEL},
]


func _ready() -> void:
	_configurar_janela()
	menu_inventario.hide()
	area_botao_menu.show()
	botao_abrir_inventario.pressed.connect(_alternar_inventario)
	menu_inventario.fechado.connect(_fechar_inventario)
	menu_inventario.janela_solta.connect(_aplicar_direcao_do_menu)
	menu_inventario.ouro_obtido.connect(_on_ouro_obtido_menu)
	menu_inventario.largura_menus_alterada.connect(_ajustar_largura_janela)
	timer_ataque.stop()
	# Sempre que equipar/desequipar (ou trocar de personagem), o dano é recalculado.
	menu_inventario.equipamentos_alterados.connect(recalcular_atributos)
	menu_inventario.personagem_alterado.connect(_on_personagem_alterado)
	menu_inventario.classe_heroi_alterada.connect(_on_classe_heroi_alterada)

	party.obter_dano_equip = obter_dano_equip_slot
	party.heroi_atacou.connect(_on_heroi_atacou)
	party.dps_alterado.connect(_on_dps_alterado)
	menu_inventario.configurar_equipe(party)

	SaveSystem.registrar(self)
	if not SaveSystem.carregar():
		menu_inventario.preencher_item_inicial_se_vazio()

	_gerar_inimigo()
	recalcular_atributos()
	palco.mouse_filter = Control.MOUSE_FILTER_STOP
	palco.gui_input.connect(_on_area_arraste_gui_input)
	painel_batalha.gui_input.connect(_on_area_arraste_gui_input)
	call_deferred("_alinhar_combate")
	_atualizar_click_through()


func _process(_delta: float) -> void:
	_alinhar_combate()
	_atualizar_click_through()


func _configurar_janela() -> void:
	get_viewport().transparent_bg = true
	get_tree().get_root().transparent_bg = true
	DisplayServer.window_set_size(Vector2i(LARGURA_JANELA, ALTURA_JANELA))
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_MOUSE_PASSTHROUGH, false)


func obter_dano_equip_slot(slot_index: int) -> int:
	return menu_inventario.obter_dano_equipado(slot_index)


func recalcular_atributos() -> void:
	party.recalcular_status()
	dano_total = party.dano_total_grupo()
	_atualizar_hud()


func _on_dps_alterado(dps: float, dano_grupo: int) -> void:
	dano_total = dano_grupo
	label_dano.text = "DPS %.1f" % dps


func _on_classe_heroi_alterada(_indice: int, _classe: ClasseData) -> void:
	recalcular_atributos()


func _on_heroi_atacou(_slot_index: int, dano: int) -> void:
	if _resolvendo_morte:
		return
	if inimigo_atual == null or inimigo_atual.esta_morto():
		_gerar_inimigo()
	AudioManager.tocar_som_ataque()
	var morreu := inimigo_atual.tomar_dano(dano)
	barra_vida.atualizar_vida(inimigo_atual.vida_atual)
	inimigo_visual.piscar_hit()
	AudioManager.tocar_som_dano()
	if morreu:
		await _resolver_morte()
	_atualizar_hud()


func _gerar_inimigo() -> void:
	inimigo_atual = Inimigo.new()
	inimigo_atual.configurar(
		"Monstro Lv. %d" % onda,
		20 + (onda - 1) * 12,
		3 + onda,
		5 + onda * 2
	)
	barra_vida.inicializar_barra(inimigo_atual.vida_maxima)


func _resolver_morte() -> void:
	_resolvendo_morte = true
	party.combate_pausado = true
	AudioManager.tocar_som_morte()
	var ouro_ganho := _drops.ouro_com_variacao(inimigo_atual.ouro_recompensa)
	var destino_ouro := painel_batalha.get_global_rect().get_center()
	if menu_inventario.visible:
		destino_ouro = menu_inventario.label_ouro.get_global_rect().get_center()
	efeito_moedas.lancar(
		inimigo_visual.global_position,
		destino_ouro,
		2 + ouro_ganho / 2
	)
	inimigo_visual.esmaecer()
	barra_vida.esmaecer()
	await get_tree().create_timer(0.4).timeout
	ouro += ouro_ganho
	AudioManager.tocar_som_moeda()
	_aplicar_xp(inimigo_atual.xp_recompensa)
	_tentar_drop_item()
	onda += 1
	_gerar_inimigo()
	inimigo_visual.aparecer()
	barra_vida.aparecer()
	_resolvendo_morte = false
	party.combate_pausado = false
	SaveSystem.salvar()


func _alinhar_combate() -> void:
	var rect := chao.get_global_rect()
	combate.position = Vector2(rect.get_center().x, rect.position.y + 2)


func _on_area_arraste_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_arrastando_janela = event.pressed
		if _arrastando_janela:
			_offset_arraste = DisplayServer.mouse_get_position() - DisplayServer.window_get_position()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		var estava_arrastando := _arrastando_janela
		_arrastando_janela = false
		if estava_arrastando and menu_inventario.visible:
			_aplicar_direcao_do_menu()
	elif event is InputEventMouseMotion and _arrastando_janela:
		DisplayServer.window_set_position(DisplayServer.mouse_get_position() - _offset_arraste)


func _aplicar_direcao_do_menu() -> void:
	var abrir_para_baixo := _deve_abrir_para_baixo()
	_ancorar_combate_no_topo(abrir_para_baixo)
	menu_inventario.definir_abaixo_do_combate(abrir_para_baixo)
	_manter_combate_na_tela()


func _deve_abrir_para_baixo() -> bool:
	var tela := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	var palco_tela := _rect_controle_na_tela(palco)
	var win := DisplayServer.window_get_position()
	var limite_alto := float(tela.position.y) + float(tela.size.y) * 0.45
	if win.y <= tela.position.y + 80:
		return true
	if palco_tela.position.y <= limite_alto:
		return true
	if palco_tela.position.y - float(tela.position.y) < 500.0:
		return true
	return false


func _manter_combate_na_tela() -> void:
	var tela := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	var palco_tela := _rect_controle_na_tela(palco)
	var win := DisplayServer.window_get_position()
	var dy := 0
	if palco_tela.position.y < float(tela.position.y) + 4.0:
		dy = int(float(tela.position.y) + 4.0 - palco_tela.position.y)
	elif palco_tela.end.y > float(tela.end.y) - 4.0:
		dy = int(float(tela.end.y) - 4.0 - palco_tela.end.y)
	if dy != 0:
		DisplayServer.window_set_position(Vector2i(win.x, win.y + dy))


func _rect_controle_na_tela(controle: Control) -> Rect2:
	var local := controle.get_global_rect()
	var win := Vector2(DisplayServer.window_get_position())
	var xform := get_window().get_final_transform()
	var pos := win + xform * local.position
	var canto := win + xform * local.end
	return Rect2(pos, canto - pos)


func _ancorar_combate_no_topo(no_topo: bool) -> void:
	_combate_no_topo = no_topo
	if no_topo:
		_definir_ancoras(palco, 0.5, 0.0, 0.5, 0.0, -240, PALCO_MARGEM_TOPO, 240, PALCO_MARGEM_TOPO + PALCO_ALTURA)
		var painel_topo := PALCO_MARGEM_TOPO + PALCO_ALTURA
		_definir_ancoras(painel_batalha, 0.5, 0.0, 0.5, 0.0, -160, painel_topo, 160, painel_topo + PAINEL_ALTURA)
		var botao_topo := painel_topo + 10
		_definir_ancoras(area_botao_menu, 1.0, 0.0, 1.0, 0.0, -96, botao_topo, -16, botao_topo + BOTAO_TAMANHO)
	else:
		_definir_ancoras(palco, 0.5, 1.0, 0.5, 1.0, -240, -232, 240, -PALCO_BASE_JANELA)
		_definir_ancoras(painel_batalha, 0.5, 1.0, 0.5, 1.0, -160, -108, 160, -8)
		_definir_ancoras(area_botao_menu, 1.0, 1.0, 1.0, 1.0, -96, -96, -16, -16)


func _definir_ancoras(
	controle: Control,
	a_esq: float,
	a_topo: float,
	a_dir: float,
	a_base: float,
	o_esq: int,
	o_topo: int,
	o_dir: int,
	o_base: int
) -> void:
	controle.anchor_left = a_esq
	controle.anchor_top = a_topo
	controle.anchor_right = a_dir
	controle.anchor_bottom = a_base
	controle.offset_left = o_esq
	controle.offset_top = o_topo
	controle.offset_right = o_dir
	controle.offset_bottom = o_base


func _aplicar_xp(quantidade: int) -> void:
	for indice in PartyManager.SLOTS:
		if party.equipe_ativa[indice] == null:
			continue
		var progresso: Dictionary = _progresso[indice]
		progresso["xp"] = int(progresso["xp"]) + quantidade
		while int(progresso["xp"]) >= int(progresso["xp_proximo"]) and int(progresso["xp_proximo"]) > 0:
			progresso["xp"] = int(progresso["xp"]) - int(progresso["xp_proximo"])
			progresso["nivel"] = int(progresso["nivel"]) + 1
			var proximo: int = int(XP_BASE_NIVEL * pow(1.35, int(progresso["nivel"]) - 1))
			progresso["xp_proximo"] = max(1, proximo)
		if indice == menu_inventario.indice_personagem_atual():
			menu_inventario.atualizar_nivel_exibido(int(progresso["nivel"]))


func _tentar_drop_item() -> void:
	var item := _drops.tentar_drop_item(onda)
	if item == null:
		return
	if menu_inventario.adicionar_item(item):
		_mostrar_aviso("Drop: %s" % item.nome)
		AudioManager.tocar_som_moeda()
	else:
		_mostrar_aviso("Inventário Cheio!")


func _mostrar_aviso(texto: String) -> void:
	label_aviso.visible = true
	label_aviso.text = texto
	label_aviso.modulate.a = 1.0
	if _tween_aviso:
		_tween_aviso.kill()
	_tween_aviso = create_tween()
	_tween_aviso.tween_interval(1.4)
	_tween_aviso.tween_property(label_aviso, "modulate:a", 0.0, 0.4)
	_tween_aviso.tween_callback(func() -> void: label_aviso.visible = false)


func _on_personagem_alterado(_indice: int) -> void:
	var progresso: Dictionary = _progresso[menu_inventario.indice_personagem_atual()]
	menu_inventario.atualizar_nivel_exibido(int(progresso["nivel"]))
	recalcular_atributos()


func _on_ouro_obtido_menu(quantidade: int) -> void:
	ouro += maxi(0, quantidade)
	AudioManager.tocar_som_moeda()
	_atualizar_hud()
	SaveSystem.salvar()


func _atualizar_hud() -> void:
	if inimigo_atual:
		label_inimigo.text = inimigo_atual.nome
	menu_inventario.atualizar_ouro(ouro)
	var progresso: Dictionary = _progresso[menu_inventario.indice_personagem_atual()]
	label_nivel.text = "Nv.%d  %d/%d" % [
		int(progresso["nivel"]),
		int(progresso["xp"]),
		int(progresso["xp_proximo"]),
	]
	label_dano.text = "DPS %.1f" % party.dps_grupo()


func _alternar_inventario() -> void:
	if menu_inventario.visible:
		_fechar_inventario()
	else:
		_abrir_inventario()


func _abrir_inventario() -> void:
	_aplicar_direcao_do_menu()
	menu_inventario.show()
	area_botao_menu.show()
	_ajustar_largura_janela()
	_atualizar_click_through()


func _fechar_inventario() -> void:
	menu_inventario.hide()
	area_botao_menu.show()
	_ajustar_largura_janela()
	_atualizar_click_through()
	SaveSystem.salvar()


func _ajustar_largura_janela() -> void:
	var desejada := LARGURA_JANELA
	if menu_inventario.visible:
		desejada = maxi(LARGURA_JANELA, menu_inventario.largura_para_janela())
	var tela := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	desejada = mini(desejada, tela.size.x)
	var atual := DisplayServer.window_get_size()
	if atual.x == desejada:
		return
	var pos := DisplayServer.window_get_position()
	var centro := pos.x + int(atual.x / 2.0)
	var nova_x := centro - int(desejada / 2.0)
	nova_x = clampi(nova_x, tela.position.x, tela.position.x + tela.size.x - desejada)
	DisplayServer.window_set_size(Vector2i(desejada, ALTURA_JANELA))
	DisplayServer.window_set_position(Vector2i(nova_x, pos.y))


func _atualizar_click_through() -> void:
	var retangulos: Array[Rect2] = []
	if botao_abrir_inventario.visible and botao_abrir_inventario.is_visible_in_tree():
		retangulos.append(botao_abrir_inventario.get_global_rect().grow(6.0))
	if painel_batalha.visible:
		retangulos.append(painel_batalha.get_global_rect().grow(4.0))
	if palco.visible:
		retangulos.append(palco.get_global_rect().grow(4.0))
	if menu_inventario.visible:
		retangulos.append_array(menu_inventario.obter_retangulos_clicaveis())

	var cantos := PackedVector2Array()
	var xform := get_window().get_final_transform()
	for retangulo in retangulos:
		cantos.append(xform * retangulo.position)
		cantos.append(xform * Vector2(retangulo.end.x, retangulo.position.y))
		cantos.append(xform * retangulo.end)
		cantos.append(xform * Vector2(retangulo.position.x, retangulo.end.y))

	var pontos := cantos
	if cantos.size() > 4:
		pontos = Geometry2D.convex_hull(cantos)
	DisplayServer.window_set_mouse_passthrough(pontos)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if menu_inventario.visible:
			_fechar_inventario()
		return


func coletar_save() -> Dictionary:
	return {
		"ouro": ouro,
		"onda": onda,
		"personagem_atual": menu_inventario.indice_personagem_atual(),
		"progresso": _progresso.duplicate(true),
		"inventario": menu_inventario.serializar_inventario(),
		"armazem": menu_inventario.serializar_armazem(),
		"equipamentos": menu_inventario.serializar_equipamentos(),
		"equipe": party.serializar(),
	}


func aplicar_save(dados: Dictionary) -> void:
	ouro = int(dados.get("ouro", 0))
	onda = maxi(1, int(dados.get("onda", 1)))
	var progresso: Variant = dados.get("progresso", [])
	if progresso is Array:
		for i in mini(progresso.size(), _progresso.size()):
			if progresso[i] is Dictionary:
				_progresso[i] = {
					"nivel": int(progresso[i].get("nivel", 1)),
					"xp": int(progresso[i].get("xp", 0)),
					"xp_proximo": int(progresso[i].get("xp_proximo", XP_BASE_NIVEL)),
				}
	menu_inventario.aplicar_inventario(dados.get("inventario", []))
	menu_inventario.aplicar_armazem(dados.get("armazem", []))
	menu_inventario.aplicar_equipamentos(dados.get("equipamentos", []))
	var equipe_save: Variant = dados.get("equipe", {})
	if equipe_save is Dictionary:
		party.aplicar_save(equipe_save)
	menu_inventario.configurar_equipe(party)
	menu_inventario.selecionar_personagem(int(dados.get("personagem_atual", 0)))
	var atual: Dictionary = _progresso[menu_inventario.indice_personagem_atual()]
	menu_inventario.atualizar_nivel_exibido(int(atual["nivel"]))
	_atualizar_hud()
