extends Node2D
## Orquestra HUD, inventário, combate e janela.

@onready var menu_inventario: MenuInventario = $HudInventario/MenuInventario
@onready var area_botao_menu: ColorRect = $HudBotao/AreaBotaoMenu
@onready var botao_abrir_inventario: Button = $HudBotao/AreaBotaoMenu/BotaoAbrirInventario
@onready var painel_batalha: PanelContainer = $HudBatalha/PainelBatalha
@onready var label_inimigo: Label = %LabelInimigo
@onready var barra_vida: ProgressBar = %BarraVidaInimigo
@onready var label_nivel: Label = %LabelNivel
@onready var label_dano: Label = %LabelDano
@onready var botao_repetir_fase: Button = %BotaoRepetirFase
@onready var label_aviso: Label = %LabelAviso
@onready var palco: Control = $HudBatalha/Palco
@onready var chao: TextureRect = %Chao
@onready var combate: Node2D = $HudBatalha/Combate
@onready var party: PartyManager = $HudBatalha/Combate/PartyManager
@onready var inimigo_visual: Sprite2D = $HudBatalha/Combate/InimigoVisual
@onready var efeito_moedas: Control = $HudBatalha/CamadaEfeitos

var ouro: int = 0
var dano_total: int = 5
var _tween_aviso: Tween
var _janela: GerenciadorJanela
var _luta: ControladorCombate
var _progresso := ProgressoHerois.new()


func _ready() -> void:
	_janela = GerenciadorJanela.new()
	_janela.name = "GerenciadorJanela"
	_janela.palco = palco
	_janela.painel_batalha = painel_batalha
	_janela.area_botao_menu = area_botao_menu
	_janela.combate = combate
	_janela.chao = chao
	_janela.botao_abrir_inventario = botao_abrir_inventario
	_janela.obter_rects_menu = func() -> Array[Rect2]: return menu_inventario.obter_retangulos_clicaveis()
	_janela.menu_esta_visivel = func() -> bool: return menu_inventario.visible
	_janela.ao_soltar_arraste = _aplicar_direcao_do_menu
	add_child(_janela)
	_janela.configurar_flags()

	_luta = ControladorCombate.new()
	_luta.name = "ControladorCombate"
	_luta.party = party
	_luta.inimigo_visual = inimigo_visual
	_luta.barra_vida = barra_vida
	_luta.progresso = _progresso
	_luta.obter_indice_personagem = func() -> int: return menu_inventario.indice_personagem_atual()
	_luta.obter_destino_ouro = _destino_ouro
	_luta.obter_bonus_arvore = func() -> Dictionary: return menu_inventario.bonus_arvore_global()
	add_child(_luta)
	_luta.aviso.connect(_mostrar_aviso)
	_luta.efeito_moedas_pedido.connect(_on_efeito_moedas)
	_luta.ouro_ganho.connect(_on_ouro_combate)
	_luta.item_dropado.connect(_on_item_dropado)
	_luta.progressao_alterada.connect(_on_progressao_alterada)
	_luta.hud_atualizar.connect(_atualizar_hud)
	_luta.precisa_salvar.connect(SaveSystem.salvar)
	_luta.nivel_heroi_alterado.connect(_on_nivel_heroi_alterado)

	menu_inventario.hide()
	area_botao_menu.show()
	botao_abrir_inventario.pressed.connect(_alternar_inventario)
	menu_inventario.fechado.connect(_fechar_inventario)
	menu_inventario.janela_solta.connect(_aplicar_direcao_do_menu)
	menu_inventario.ouro_obtido.connect(_on_ouro_obtido_menu)
	menu_inventario.ouro_gasto.connect(_on_ouro_gasto_menu)
	menu_inventario.arvore_alterada.connect(recalcular_atributos)
	menu_inventario.consultar_ouro = func() -> int: return ouro
	menu_inventario.consultar_progresso_slot = _progresso_do_slot
	menu_inventario.largura_menus_alterada.connect(_on_largura_menus_alterada)
	menu_inventario.equipamentos_alterados.connect(recalcular_atributos)
	menu_inventario.personagem_alterado.connect(_on_personagem_alterado)
	menu_inventario.classe_heroi_alterada.connect(_on_classe_heroi_alterada)
	menu_inventario.fase_iniciada.connect(_luta.iniciar_fase)
	botao_repetir_fase.icon = IconeRepetir.criar()
	botao_repetir_fase.add_theme_constant_override("icon_max_width", 18)
	botao_repetir_fase.pressed.connect(_on_botao_repetir_pressed)
	_atualizar_visual_repetir()

	party.obter_dano_equip = obter_dano_equip_slot
	party.obter_vida_equip = obter_vida_equip_slot
	party.obter_nivel = obter_nivel_slot
	party.obter_bonus_arvore = obter_bonus_arvore_slot
	party.heroi_atacou.connect(_luta.on_heroi_atacou)
	party.dps_alterado.connect(_on_dps_alterado)
	menu_inventario.configurar_equipe(party)

	SaveSystem.registrar(self)
	if not SaveSystem.carregar():
		menu_inventario.preencher_item_inicial_se_vazio()

	_on_progressao_alterada()
	_luta.gerar_inimigo()
	recalcular_atributos()
	party.curar_equipe()
	palco.mouse_filter = Control.MOUSE_FILTER_STOP
	palco.gui_input.connect(_janela.on_area_arraste)
	painel_batalha.gui_input.connect(_janela.on_area_arraste)
	call_deferred("_alinhar_inicial")


func _alinhar_inicial() -> void:
	_janela.alinhar_combate()
	_janela.atualizar_click_through()


func obter_dano_equip_slot(slot_index: int) -> int:
	return menu_inventario.obter_dano_equipado(slot_index)


func obter_vida_equip_slot(slot_index: int) -> int:
	return menu_inventario.obter_vida_equipada(slot_index)


func obter_nivel_slot(slot_index: int) -> int:
	return _progresso.obter_nivel_do_slot(slot_index, party.equipe_ativa)


func _progresso_do_slot(slot_index: int) -> Dictionary:
	return _progresso.do_indice(slot_index, party.equipe_ativa)


func obter_bonus_arvore_slot(_slot_index: int) -> Dictionary:
	return menu_inventario.bonus_arvore_global()


func recalcular_atributos() -> void:
	party.recalcular_status()
	dano_total = party.dano_total_grupo()
	_atualizar_hud()


func _on_dps_alterado(dps: float, dano_grupo: int) -> void:
	dano_total = dano_grupo
	label_dano.text = "DPS %.1f" % dps


func _on_classe_heroi_alterada(_indice: int, _classe: ClasseData) -> void:
	recalcular_atributos()


func _on_botao_repetir_pressed() -> void:
	_luta.alternar_repetir()
	_atualizar_visual_repetir()


func _atualizar_visual_repetir() -> void:
	var estilo := StyleBoxFlat.new()
	estilo.content_margin_left = 3
	estilo.content_margin_top = 3
	estilo.content_margin_right = 3
	estilo.content_margin_bottom = 3
	estilo.set_corner_radius_all(4)
	estilo.set_border_width_all(2)
	if _luta.repetir_fase:
		estilo.bg_color = Color(0.32, 0.24, 0.16, 1)
		estilo.border_color = Color(0.95, 0.78, 0.32, 1)
		botao_repetir_fase.tooltip_text = "Avançar para a próxima fase"
	else:
		estilo.bg_color = Color(0.16, 0.13, 0.1, 1)
		estilo.border_color = Color(0.62, 0.5, 0.28, 1)
		botao_repetir_fase.tooltip_text = "Repetir a fase atual"
	botao_repetir_fase.add_theme_stylebox_override("normal", estilo)
	botao_repetir_fase.add_theme_stylebox_override("hover", estilo)
	botao_repetir_fase.add_theme_stylebox_override("pressed", estilo)


func _aplicar_direcao_do_menu() -> void:
	var abrir_para_baixo := _janela.aplicar_direcao_do_menu()
	menu_inventario.definir_abaixo_do_combate(abrir_para_baixo)


func _destino_ouro() -> Vector2:
	if menu_inventario.visible:
		return menu_inventario.label_ouro.get_global_rect().get_center()
	return painel_batalha.get_global_rect().get_center()


func _on_efeito_moedas(origem: Vector2, destino: Vector2, quantidade: int) -> void:
	efeito_moedas.lancar(origem, destino, quantidade)


func _on_ouro_combate(quantidade: int) -> void:
	ouro += quantidade
	AudioManager.tocar_som_moeda()
	_atualizar_hud()


func _on_item_dropado(item: ItemData) -> void:
	if menu_inventario.adicionar_item(item):
		_mostrar_aviso("Drop: %s" % item.nome)
		AudioManager.tocar_som_moeda()
	else:
		_mostrar_aviso("Inventário Cheio!")


func _on_progressao_alterada() -> void:
	menu_inventario.atualizar_progressao_mundos(_luta.mundo, _luta.fase, _luta.dificuldade, _luta.fases_liberadas)


func _on_nivel_heroi_alterado(indice: int, nivel: int) -> void:
	var progresso: Dictionary = _progresso.do_indice(indice, party.equipe_ativa)
	if indice == menu_inventario.indice_personagem_atual():
		menu_inventario.atualizar_nivel_exibido(
			nivel,
			int(progresso.get("xp", 0)),
			int(progresso.get("xp_proximo", ProgressoHerois.XP_BASE_NIVEL)),
		)
	recalcular_atributos()


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
	var progresso: Dictionary = _progresso.do_indice(menu_inventario.indice_personagem_atual(), party.equipe_ativa)
	menu_inventario.atualizar_nivel_exibido(
		int(progresso["nivel"]),
		int(progresso.get("xp", 0)),
		int(progresso.get("xp_proximo", ProgressoHerois.XP_BASE_NIVEL)),
	)
	recalcular_atributos()


func _on_ouro_obtido_menu(quantidade: int) -> void:
	ouro += maxi(0, quantidade)
	AudioManager.tocar_som_moeda()
	_atualizar_hud()
	SaveSystem.salvar()


func _on_ouro_gasto_menu(quantidade: int) -> void:
	ouro = maxi(0, ouro - maxi(0, quantidade))
	_atualizar_hud()
	SaveSystem.salvar()


func _atualizar_hud() -> void:
	if _luta.inimigo_atual:
		label_inimigo.text = "%s  %s" % [
			_luta.inimigo_atual.nome,
			ProgressaoMundos.nome_dificuldade(_luta.dificuldade),
		]
	menu_inventario.atualizar_ouro(ouro)
	var progresso: Dictionary = _progresso.do_indice(menu_inventario.indice_personagem_atual(), party.equipe_ativa)
	label_nivel.text = "Nv.%d  %d/%d" % [
		int(progresso["nivel"]),
		int(progresso["xp"]),
		int(progresso["xp_proximo"]),
	]
	menu_inventario.atualizar_nivel_exibido(
		int(progresso["nivel"]),
		int(progresso["xp"]),
		int(progresso["xp_proximo"]),
	)
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
	_janela.ajustar_largura(true, menu_inventario.largura_para_janela())
	_janela.atualizar_click_through()


func _on_largura_menus_alterada() -> void:
	if menu_inventario.visible:
		_janela.ajustar_largura(true, menu_inventario.largura_para_janela())
	_janela.atualizar_click_through()


func _fechar_inventario() -> void:
	menu_inventario.hide()
	area_botao_menu.show()
	_janela.ajustar_largura(false, menu_inventario.largura_para_janela())
	_janela.atualizar_click_through()
	SaveSystem.salvar()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if menu_inventario.visible:
			_fechar_inventario()
		return


func coletar_save() -> Dictionary:
	return {
		"ouro": ouro,
		"onda": _luta.onda,
		"mundo": _luta.mundo,
		"fase": _luta.fase,
		"dificuldade": _luta.dificuldade,
		"fases_liberadas": _luta.fases_liberadas.duplicate(),
		"repetir_fase": _luta.repetir_fase,
		"personagem_atual": menu_inventario.indice_personagem_atual(),
		"progresso": _progresso.serializar(),
		"inventario": menu_inventario.serializar_inventario(),
		"armazem": menu_inventario.serializar_armazem(),
		"equipamentos": menu_inventario.serializar_equipamentos(),
		"equipe": party.serializar(),
		"arvore": menu_inventario.serializar_arvore(),
	}


func aplicar_save(dados: Dictionary) -> void:
	ouro = int(dados.get("ouro", 0))
	_luta.aplicar_estado(dados)
	var equipe_save: Variant = dados.get("equipe", {})
	var ids_equipe: Array = []
	if equipe_save is Dictionary:
		var classes: Variant = equipe_save.get("classes", [])
		if classes is Array:
			for id_classe in classes:
				ids_equipe.append(str(id_classe))
		party.aplicar_save(equipe_save)
	_progresso.aplicar(dados.get("progresso", []), ids_equipe)
	menu_inventario.aplicar_inventario(dados.get("inventario", []))
	menu_inventario.aplicar_armazem(dados.get("armazem", []))
	menu_inventario.aplicar_equipamentos(dados.get("equipamentos", []))
	menu_inventario.aplicar_arvore(dados.get("arvore", []))
	menu_inventario.configurar_equipe(party)
	menu_inventario.selecionar_personagem(int(dados.get("personagem_atual", 0)))
	var atual: Dictionary = _progresso.do_indice(menu_inventario.indice_personagem_atual(), party.equipe_ativa)
	menu_inventario.atualizar_nivel_exibido(
		int(atual["nivel"]),
		int(atual.get("xp", 0)),
		int(atual.get("xp_proximo", ProgressoHerois.XP_BASE_NIVEL)),
	)
	_on_progressao_alterada()
	_atualizar_visual_repetir()
	recalcular_atributos()
	_atualizar_hud()
