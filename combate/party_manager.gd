class_name PartyManager
extends Node2D
## Equipe de até 3 Stickmans ativos, cada um com timer e dano próprios.

signal equipe_alterada
signal heroi_atacou(slot_index: int, dano: int)
signal dps_alterado(dps: float, dano_grupo: int)

const INTERVALO_BASE := 1.0
const SLOTS := 3
const HP_POR_NIVEL := 4

var equipe_ativa: Array = [null, null, null]
var classes_desbloqueadas: Array[ClasseData] = []
var combate_pausado: bool = false
## Callable (slot: int) -> int  com o dano_bonus dos itens daquele herói.
var obter_dano_equip: Callable
## Callable (slot: int) -> int  com o vida_bonus dos itens daquele herói.
var obter_vida_equip: Callable
## Callable (slot: int) -> int  com o nível daquele herói.
var obter_nivel: Callable

var _catalogo: Array[ClasseData] = []
var _sprites: Array[AnimatedSprite2D] = []
var _timers: Array[Timer] = []
var _posicoes: Array[Marker2D] = []
var _vida_atual: Array[int] = [0, 0, 0]
var _vida_max: Array[int] = [0, 0, 0]


func _ready() -> void:
	_catalogo = ClasseData.catalogo()
	classes_desbloqueadas = _catalogo.duplicate()
	_garantir_posicoes()
	_criar_herois_visuais()
	if equipe_ativa[0] == null:
		escalar_personagem(0, obter_classe_por_id("guerreiro"))
		escalar_personagem(1, obter_classe_por_id("mago"))
		escalar_personagem(2, obter_classe_por_id("arqueiro"))


func obter_classe_por_id(id_classe: String) -> ClasseData:
	for classe in _catalogo:
		if classe.id == id_classe:
			return classe
	return null


func escalar_personagem(slot_index: int, nova_classe: ClasseData = null) -> void:
	if slot_index < 0 or slot_index >= SLOTS:
		return
	if nova_classe != null:
		var ocupado := _indice_da_classe(nova_classe.id)
		if ocupado == slot_index:
			return
		if ocupado >= 0:
			var anterior: Variant = equipe_ativa[slot_index]
			var hp_slot := _vida_atual[slot_index]
			var hp_outro := _vida_atual[ocupado]
			equipe_ativa[slot_index] = nova_classe
			equipe_ativa[ocupado] = anterior
			_vida_atual[slot_index] = hp_outro
			_vida_atual[ocupado] = hp_slot
			_atualizar_vida_max_slot(slot_index, false)
			_atualizar_vida_max_slot(ocupado, false)
			_atualizar_sprite_slot(slot_index)
			_atualizar_timer_slot(slot_index)
			_atualizar_sprite_slot(ocupado)
			_atualizar_timer_slot(ocupado)
			_emitir_dps()
			equipe_alterada.emit()
			return
	equipe_ativa[slot_index] = nova_classe
	_atualizar_vida_max_slot(slot_index, true)
	_atualizar_sprite_slot(slot_index)
	_atualizar_timer_slot(slot_index)
	_emitir_dps()
	equipe_alterada.emit()


func _indice_da_classe(id_classe: String) -> int:
	for i in SLOTS:
		var classe: Variant = equipe_ativa[i]
		if classe is ClasseData and (classe as ClasseData).id == id_classe:
			return i
	return -1


func dano_do_heroi(slot_index: int) -> int:
	if slot_index < 0 or slot_index >= SLOTS:
		return 0
	var classe: Variant = equipe_ativa[slot_index]
	if classe == null or not (classe is ClasseData):
		return 0
	var dados: ClasseData = classe
	var extra := 0
	if obter_dano_equip.is_valid():
		extra = int(obter_dano_equip.call(slot_index))
	return maxi(1, int(round(float(dados.dano_base + extra) * dados.multiplicador_ataque)))


func dano_total_grupo() -> int:
	var total := 0
	for i in SLOTS:
		if heroi_vivo(i):
			total += dano_do_heroi(i)
	return total


func dps_grupo() -> float:
	var dps := 0.0
	for i in SLOTS:
		if not heroi_vivo(i):
			continue
		var classe: ClasseData = equipe_ativa[i]
		var intervalo := INTERVALO_BASE / maxf(0.25, classe.velocidade_ataque)
		dps += float(dano_do_heroi(i)) / intervalo
	return dps


func vida_maxima_do_heroi(slot_index: int) -> int:
	if slot_index < 0 or slot_index >= SLOTS:
		return 0
	var classe: Variant = equipe_ativa[slot_index]
	if classe == null or not (classe is ClasseData):
		return 0
	var extra := 0
	if obter_vida_equip.is_valid():
		extra = int(obter_vida_equip.call(slot_index))
	var nivel := 1
	if obter_nivel.is_valid():
		nivel = maxi(1, int(obter_nivel.call(slot_index)))
	return maxi(1, (classe as ClasseData).vida_base + extra + (nivel - 1) * HP_POR_NIVEL)


func heroi_vivo(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= SLOTS:
		return false
	if equipe_ativa[slot_index] == null:
		return false
	return _vida_atual[slot_index] > 0


func indice_alvo_direita() -> int:
	for i in range(SLOTS - 1, -1, -1):
		if heroi_vivo(i):
			return i
	return -1


func aplicar_dano_no_heroi(slot_index: int, quantidade: int) -> bool:
	if not heroi_vivo(slot_index):
		return false
	_vida_atual[slot_index] = maxi(0, _vida_atual[slot_index] - maxi(0, quantidade))
	var sprite: AnimatedSprite2D = _sprites[slot_index]
	if sprite.has_method("piscar_dano"):
		sprite.piscar_dano()
	_atualizar_barra_slot(slot_index)
	if _vida_atual[slot_index] <= 0:
		_marcar_caido(slot_index, true)
		_emitir_dps()
		return true
	return false


func curar_equipe() -> void:
	for i in SLOTS:
		if equipe_ativa[i] == null:
			_vida_atual[i] = 0
			_vida_max[i] = 0
			_marcar_caido(i, false)
			_atualizar_barra_slot(i)
			continue
		_atualizar_vida_max_slot(i, true)
		_marcar_caido(i, false)
		_atualizar_sprite_slot(i)
		_atualizar_timer_slot(i)
	_emitir_dps()


func recalcular_status() -> void:
	for i in SLOTS:
		_atualizar_vida_max_slot(i, false)
		_atualizar_timer_slot(i)
		_atualizar_barra_slot(i)
	_emitir_dps()


func serializar() -> Dictionary:
	var ids: Array = []
	for i in SLOTS:
		var classe: Variant = equipe_ativa[i]
		if classe is ClasseData:
			ids.append((classe as ClasseData).id)
		else:
			ids.append("")
	var desbloqueadas: Array = []
	for classe in classes_desbloqueadas:
		desbloqueadas.append(classe.id)
	return {"classes": ids, "desbloqueadas": desbloqueadas}


func aplicar_save(dados: Dictionary) -> void:
	var ids: Variant = dados.get("classes", [])
	if ids is Array and ids.size() > 0:
		for i in SLOTS:
			var id_classe := str(ids[i]) if i < ids.size() else ""
			escalar_personagem(i, obter_classe_por_id(id_classe))
	var lista: Variant = dados.get("desbloqueadas", [])
	if lista is Array and not lista.is_empty():
		classes_desbloqueadas.clear()
		for id_classe in lista:
			var classe: ClasseData = obter_classe_por_id(str(id_classe))
			if classe:
				classes_desbloqueadas.append(classe)
	_garantir_catalogo_desbloqueado()


func _garantir_catalogo_desbloqueado() -> void:
	for classe in _catalogo:
		var ja_tem := false
		for atual in classes_desbloqueadas:
			if atual.id == classe.id:
				ja_tem = true
				break
		if not ja_tem:
			classes_desbloqueadas.append(classe)


func _garantir_posicoes() -> void:
	var nomes := ["Posicao1", "Posicao2", "Posicao3"]
	var locais := [Vector2(-118, -46), Vector2(-72, -46), Vector2(-26, -46)]
	for i in SLOTS:
		var marcador := get_node_or_null(nomes[i]) as Marker2D
		if marcador == null:
			marcador = Marker2D.new()
			marcador.name = nomes[i]
			marcador.position = locais[i]
			add_child(marcador)
		_posicoes.append(marcador)


func _criar_herois_visuais() -> void:
	var script_stick := load("res://combate/stickman.gd")
	for i in SLOTS:
		var sprite := AnimatedSprite2D.new()
		sprite.name = "Heroi_%d" % (i + 1)
		sprite.set_script(script_stick)
		sprite.scale = Vector2(1.25, 1.25)
		sprite.position = _posicoes[i].position
		add_child(sprite)
		_sprites.append(sprite)

		var timer := Timer.new()
		timer.name = "TimerHeroi_%d" % (i + 1)
		timer.one_shot = false
		timer.timeout.connect(_on_timer_heroi.bind(i))
		add_child(timer)
		_timers.append(timer)


func _atualizar_sprite_slot(slot_index: int) -> void:
	var sprite: AnimatedSprite2D = _sprites[slot_index]
	var classe: Variant = equipe_ativa[slot_index]
	if classe == null:
		sprite.visible = false
		_marcar_caido(slot_index, false)
		_atualizar_barra_slot(slot_index)
		return
	sprite.visible = true
	if sprite.has_method("definir_posicao_base"):
		sprite.definir_posicao_base(_posicoes[slot_index].position)
	else:
		sprite.position = _posicoes[slot_index].position
	if sprite.has_method("aplicar_classe"):
		sprite.aplicar_classe(classe)
	_marcar_caido(slot_index, not heroi_vivo(slot_index))
	_atualizar_barra_slot(slot_index)


func _atualizar_timer_slot(slot_index: int) -> void:
	var timer: Timer = _timers[slot_index]
	var classe: Variant = equipe_ativa[slot_index]
	if classe == null or not heroi_vivo(slot_index):
		timer.stop()
		return
	var dados: ClasseData = classe
	timer.wait_time = INTERVALO_BASE / maxf(0.25, dados.velocidade_ataque)
	if timer.is_stopped():
		timer.start()


func _atualizar_vida_max_slot(slot_index: int, resetar: bool) -> void:
	var novo_max := vida_maxima_do_heroi(slot_index)
	if novo_max <= 0:
		_vida_max[slot_index] = 0
		_vida_atual[slot_index] = 0
		return
	if resetar:
		_vida_max[slot_index] = novo_max
		_vida_atual[slot_index] = novo_max
		return
	if _vida_atual[slot_index] > 0 and novo_max > _vida_max[slot_index]:
		_vida_atual[slot_index] += novo_max - _vida_max[slot_index]
	_vida_max[slot_index] = novo_max
	_vida_atual[slot_index] = clampi(_vida_atual[slot_index], 0, novo_max)


func _atualizar_barra_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= _sprites.size():
		return
	var sprite: AnimatedSprite2D = _sprites[slot_index]
	if sprite.has_method("atualizar_vida"):
		sprite.atualizar_vida(_vida_atual[slot_index], _vida_max[slot_index])


func _marcar_caido(slot_index: int, caido: bool) -> void:
	if slot_index < 0 or slot_index >= _sprites.size():
		return
	var sprite: AnimatedSprite2D = _sprites[slot_index]
	if sprite.has_method("definir_caido"):
		sprite.definir_caido(caido)
	if caido:
		_timers[slot_index].stop()


func _on_timer_heroi(slot_index: int) -> void:
	if combate_pausado:
		return
	if not heroi_vivo(slot_index):
		return
	var sprite: AnimatedSprite2D = _sprites[slot_index]
	if sprite.has_method("tocar_ataque"):
		sprite.tocar_ataque()
	heroi_atacou.emit(slot_index, dano_do_heroi(slot_index))


func _emitir_dps() -> void:
	dps_alterado.emit(dps_grupo(), dano_total_grupo())
