class_name ControladorCombate
extends Node
## Regras de luta idle: heróis atacam, inimigo rebate e a fase avança.

signal aviso(texto: String)
signal efeito_moedas_pedido(origem: Vector2, destino: Vector2, quantidade: int)
signal ouro_ganho(quantidade: int)
signal item_dropado(item: ItemData)
signal progressao_alterada
signal hud_atualizar
signal precisa_salvar
signal nivel_heroi_alterado(indice: int, nivel: int)

const INTERVALO_ATAQUE_INIMIGO := 1.35

var mundo: int = 1
var fase: int = 1
var dificuldade: int = ProgressaoMundos.Dificuldade.FACIL
var fases_liberadas: Array[int] = [1, 1, 1]
var repetir_fase: bool = false
var onda: int = 1
var inimigo_atual: Inimigo

var party: PartyManager
var inimigo_visual: Sprite2D
var barra_vida: ProgressBar
var progresso: ProgressoHerois
var obter_indice_personagem: Callable
var obter_destino_ouro: Callable

var _drops := GerenciadorDrops.new()
var _resolvendo_morte: bool = false
var _resolvendo_derrota: bool = false
var _timer_inimigo: Timer


func _ready() -> void:
	_timer_inimigo = Timer.new()
	_timer_inimigo.wait_time = INTERVALO_ATAQUE_INIMIGO
	_timer_inimigo.timeout.connect(on_inimigo_atacou)
	add_child(_timer_inimigo)
	_timer_inimigo.start()


func on_heroi_atacou(_slot_index: int, dano: int) -> void:
	if _resolvendo_morte or _resolvendo_derrota:
		return
	if inimigo_atual == null or inimigo_atual.esta_morto():
		gerar_inimigo()
	AudioManager.tocar_som_ataque()
	var morreu := inimigo_atual.tomar_dano(dano)
	barra_vida.atualizar_vida(inimigo_atual.vida_atual)
	inimigo_visual.piscar_hit()
	AudioManager.tocar_som_dano()
	if morreu:
		await _resolver_morte()
	hud_atualizar.emit()


func on_inimigo_atacou() -> void:
	if _resolvendo_morte or _resolvendo_derrota:
		return
	if party.combate_pausado:
		return
	if inimigo_atual == null or inimigo_atual.esta_morto():
		return
	var alvo := party.indice_alvo_direita()
	if alvo < 0:
		await _resolver_derrota()
		return
	if inimigo_visual.has_method("tocar_ataque"):
		inimigo_visual.tocar_ataque()
	AudioManager.tocar_som_ataque()
	party.aplicar_dano_no_heroi(alvo, inimigo_atual.dano)
	AudioManager.tocar_som_dano()
	if party.indice_alvo_direita() < 0:
		await _resolver_derrota()


func iniciar_fase(novo_mundo: int, nova_fase: int, nova_dificuldade: int) -> void:
	var m := clampi(novo_mundo, 1, ProgressaoMundos.TOTAL_MUNDOS)
	var f := clampi(nova_fase, 1, ProgressaoMundos.FASES_POR_MUNDO)
	var d := clampi(nova_dificuldade, 0, 2)
	if not ProgressaoMundos.dificuldade_liberada(d, fases_liberadas):
		return
	if ProgressaoMundos.indice(m, f) > fases_liberadas[d]:
		return
	mundo = m
	fase = f
	dificuldade = d
	_resolvendo_morte = false
	_resolvendo_derrota = false
	party.combate_pausado = false
	party.curar_equipe()
	gerar_inimigo()
	inimigo_visual.aparecer()
	barra_vida.aparecer()
	progressao_alterada.emit()
	hud_atualizar.emit()
	precisa_salvar.emit()


func gerar_inimigo() -> void:
	var stats := ProgressaoMundos.stats_inimigo(mundo, fase, dificuldade)
	onda = int(stats["nivel"])
	inimigo_atual = Inimigo.new()
	inimigo_atual.configurar(
		str(stats["nome"]),
		int(stats["vida"]),
		int(stats["ouro"]),
		int(stats["xp"]),
		int(stats.get("dano", 1))
	)
	barra_vida.inicializar_barra(inimigo_atual.vida_maxima)


func alternar_repetir() -> void:
	repetir_fase = not repetir_fase
	precisa_salvar.emit()


func aplicar_estado(dados: Dictionary) -> void:
	onda = maxi(1, int(dados.get("onda", 1)))
	mundo = clampi(int(dados.get("mundo", 1)), 1, ProgressaoMundos.TOTAL_MUNDOS)
	fase = clampi(int(dados.get("fase", 1)), 1, ProgressaoMundos.FASES_POR_MUNDO)
	dificuldade = clampi(int(dados.get("dificuldade", 0)), 0, 2)
	var liberadas: Variant = dados.get("fases_liberadas", [1, 1, 1])
	fases_liberadas = [1, 1, 1]
	if liberadas is Array:
		for i in mini(liberadas.size(), 3):
			fases_liberadas[i] = clampi(int(liberadas[i]), 1, ProgressaoMundos.PROGRESSO_COMPLETO)
	while dificuldade > 0 and not ProgressaoMundos.dificuldade_liberada(dificuldade, fases_liberadas):
		dificuldade -= 1
	repetir_fase = bool(dados.get("repetir_fase", false))


func _resolver_morte() -> void:
	if _resolvendo_morte or _resolvendo_derrota:
		return
	_resolvendo_morte = true
	party.combate_pausado = true
	AudioManager.tocar_som_morte()
	var ouro := _drops.ouro_com_variacao(inimigo_atual.ouro_recompensa)
	var destino := Vector2.ZERO
	if obter_destino_ouro.is_valid():
		destino = obter_destino_ouro.call()
	efeito_moedas_pedido.emit(inimigo_visual.global_position, destino, 2 + ouro / 2)
	inimigo_visual.esmaecer()
	barra_vida.esmaecer()
	await get_tree().create_timer(0.4).timeout
	ouro_ganho.emit(ouro)
	_aplicar_xp(inimigo_atual.xp_recompensa)
	_tentar_drop()
	_avancar_fase()
	party.curar_equipe()
	gerar_inimigo()
	inimigo_visual.aparecer()
	barra_vida.aparecer()
	_resolvendo_morte = false
	party.combate_pausado = false
	precisa_salvar.emit()


func _resolver_derrota() -> void:
	if _resolvendo_derrota or _resolvendo_morte:
		return
	_resolvendo_derrota = true
	party.combate_pausado = true
	AudioManager.tocar_som_morte()
	aviso.emit("Equipe derrotada!")
	await get_tree().create_timer(1.15).timeout
	party.curar_equipe()
	gerar_inimigo()
	inimigo_visual.aparecer()
	barra_vida.aparecer()
	_resolvendo_derrota = false
	party.combate_pausado = false
	hud_atualizar.emit()


func _avancar_fase() -> void:
	var progresso_antes := fases_liberadas[dificuldade]
	fases_liberadas[dificuldade] = ProgressaoMundos.aplicar_conclusao(progresso_antes, mundo, fase)
	var mundo_anterior := mundo
	if not repetir_fase:
		var proximo := ProgressaoMundos.proximo(mundo, fase)
		mundo = proximo.x
		fase = proximo.y
	progressao_alterada.emit()
	if ProgressaoMundos.dificuldade_concluida(fases_liberadas[dificuldade]) and not ProgressaoMundos.dificuldade_concluida(progresso_antes):
		if dificuldade < int(ProgressaoMundos.Dificuldade.INFERNO):
			aviso.emit("%s liberado!" % ProgressaoMundos.nome_dificuldade(dificuldade + 1))
		else:
			aviso.emit("Inferno concluído!")
	elif not repetir_fase and mundo > mundo_anterior:
		aviso.emit("Mundo %d liberado!" % mundo)
	elif repetir_fase:
		var seguinte := ProgressaoMundos.proximo(mundo_anterior, fase)
		if seguinte.x > mundo_anterior and progresso_antes < ProgressaoMundos.indice(seguinte.x, 1):
			aviso.emit("Mundo %d liberado!" % seguinte.x)


func _aplicar_xp(quantidade: int) -> void:
	if progresso == null:
		return
	var niveis := progresso.aplicar_xp(quantidade, party.equipe_ativa)
	var indice_ui := 0
	if obter_indice_personagem.is_valid():
		indice_ui = int(obter_indice_personagem.call())
	if indice_ui >= 0 and indice_ui < niveis.size():
		nivel_heroi_alterado.emit(indice_ui, niveis[indice_ui])


func _tentar_drop() -> void:
	var item := _drops.tentar_drop_item(onda)
	if item:
		item_dropado.emit(item)
