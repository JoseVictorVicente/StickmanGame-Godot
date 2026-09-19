class_name PartyService
extends Node2D
## Party of up to 3 stickmen with independent attack timers and stats.

signal party_changed
signal hero_attacked(slot_index: int, damage: int)
signal dps_changed(dps: float, dano_grupo: int)

const INTERVALO_BASE := 1.0
const SLOTS := 3

var active_party: Array = [null, null, null]
var unlocked_classes: Array[ClassData] = []
var combat_paused: bool = false
var stat_calculator: StatCalculator = null
## Callable (slot: int) -> int  equipment damage bonus for that hero.
var get_equipped_damage: Callable
## Callable (slot: int) -> int  equipment HP bonus for that hero.
var get_equipped_hp: Callable
## Callable (slot: int) -> int  hero level for that slot.
var get_level: Callable
## Callable (slot: int) -> Dictionary  skill-tree bonuses.
var get_skill_tree_bonus: Callable

var _catalogo: Array[ClassData] = []
var _sprites: Array[AnimatedSprite2D] = []
var _timers: Array[Timer] = []
var _posicoes: Array[Marker2D] = []
var _vida_atual: Array[int] = [0, 0, 0]
var _vida_max: Array[int] = [0, 0, 0]
var _skill_runtime := SkillRuntime.new()


func _ready() -> void:
	_catalogo = ClassData.catalog()
	unlocked_classes = _catalogo.duplicate()
	_ensure_positions()
	_create_hero_visuals()
	if active_party[0] == null:
		scale_character(0, get_class_by_id("warrior"))
		scale_character(1, get_class_by_id("mage"))
		scale_character(2, get_class_by_id("archer"))


func get_class_by_id(class_id: String) -> ClassData:
	var normalized := ClassData.normalize_id(class_id)
	for classe in _catalogo:
		if classe.id == normalized:
			return classe
	return null


func scale_character(slot_index: int, new_class: ClassData = null) -> void:
	if slot_index < 0 or slot_index >= SLOTS:
		return
	if new_class != null:
		var ocupado := _index_of_class(new_class.id)
		if ocupado == slot_index:
			return
		if ocupado >= 0:
			var anterior: Variant = active_party[slot_index]
			var hp_slot := _vida_atual[slot_index]
			var hp_outro := _vida_atual[ocupado]
			active_party[slot_index] = new_class
			active_party[ocupado] = anterior
			_vida_atual[slot_index] = hp_outro
			_vida_atual[ocupado] = hp_slot
			_update_max_hp_slot(slot_index, false)
			_update_max_hp_slot(ocupado, false)
			_update_sprite_slot(slot_index)
			_update_timer_slot(slot_index)
			_update_sprite_slot(ocupado)
			_update_timer_slot(ocupado)
			_emit_dps()
			party_changed.emit()
			return
	active_party[slot_index] = new_class
	_update_max_hp_slot(slot_index, true)
	_update_sprite_slot(slot_index)
	_update_timer_slot(slot_index)
	_emit_dps()
	party_changed.emit()


func count_active() -> int:
	var total := 0
	for classe in active_party:
		if classe is ClassData:
			total += 1
	return total


func can_remove() -> bool:
	return count_active() > 1


func first_empty_slot() -> int:
	for i in SLOTS:
		if not (active_party[i] is ClassData):
			return i
	return -1


func first_occupied_slot() -> int:
	for i in SLOTS:
		if active_party[i] is ClassData:
			return i
	return 0


func remove_from_slot(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= SLOTS:
		return false
	if not (active_party[slot_index] is ClassData):
		return false
	if not can_remove():
		return false
	active_party[slot_index] = null
	_update_max_hp_slot(slot_index, true)
	_update_sprite_slot(slot_index)
	_update_timer_slot(slot_index)
	_emit_dps()
	party_changed.emit()
	return true


func add_class(classe: ClassData) -> int:
	if classe == null:
		return -1
	var ja := _index_of_class(classe.id)
	if ja >= 0:
		return ja
	var vazio := first_empty_slot()
	if vazio < 0:
		return -1
	scale_character(vazio, classe)
	return vazio


func _index_of_class(id_classe: String) -> int:
	for i in SLOTS:
		var classe: Variant = active_party[i]
		if classe is ClassData and (classe as ClassData).id == id_classe:
			return i
	return -1


func hero_damage(slot_index: int) -> int:
	if slot_index < 0 or slot_index >= SLOTS:
		return 0
	var classe: Variant = active_party[slot_index]
	if classe == null or not (classe is ClassData):
		return 0
	if stat_calculator != null:
		var stats := stat_calculator.compute(slot_index, classe as ClassData)
		return int(stats.get("damage", 0))
	var dados: ClassData = classe
	var extra := 0
	if get_equipped_damage.is_valid():
		extra = int(get_equipped_damage.call(slot_index))
	var bonus := _skill_tree_bonus(slot_index)
	var base := maxi(1, int(round(float(dados.base_damage + extra) * dados.attack_multiplier)))
	base += (_slot_level(slot_index) - 1) * dados.atk_per_level + int(bonus.get("attack", 0))
	var pct := float(bonus.get("attack_pct", 0.0))
	return maxi(1, int(round(float(base) * (1.0 + pct / 100.0))))


func total_party_damage() -> int:
	var total := 0
	for i in SLOTS:
		if is_hero_alive(i):
			total += hero_damage(i)
	return total


func party_dps() -> float:
	var dps := 0.0
	for i in SLOTS:
		if not is_hero_alive(i):
			continue
		var classe: ClassData = active_party[i]
		var bonus := _skill_tree_bonus(i)
		var vel := classe.attack_speed * (1.0 + float(bonus.get("attack_speed", 0.0)) / 100.0)
		var intervalo := INTERVALO_BASE / maxf(0.25, vel)
		dps += float(hero_damage(i)) / intervalo
	return dps


func hero_max_hp(slot_index: int) -> int:
	if slot_index < 0 or slot_index >= SLOTS:
		return 0
	var classe: Variant = active_party[slot_index]
	if classe == null or not (classe is ClassData):
		return 0
	if stat_calculator != null:
		var stats := stat_calculator.compute(slot_index, classe as ClassData)
		return int(stats.get("hp", 0))
	var extra := 0
	if get_equipped_hp.is_valid():
		extra = int(get_equipped_hp.call(slot_index))
	var dados := classe as ClassData
	var bonus := _skill_tree_bonus(slot_index)
	var base := maxi(1, dados.base_hp + extra + (_slot_level(slot_index) - 1) * dados.hp_per_level + int(bonus.get("hp", 0)))
	var pct := float(bonus.get("hp_pct", 0.0))
	return maxi(1, int(round(float(base) * (1.0 + pct / 100.0))))


func _skill_tree_bonus(slot_index: int) -> Dictionary:
	var bonus := SkillTreeDefinition.empty_bonus()
	if get_skill_tree_bonus.is_valid():
		var raw: Variant = get_skill_tree_bonus.call(slot_index)
		if raw is Dictionary:
			bonus = raw.duplicate(true)
	var classe: Variant = active_party[slot_index]
	if classe is ClassData:
		SkillRuntime.merge_into(bonus, _skill_runtime.bonuses_for_class((classe as ClassData).id))
	return bonus


func _slot_level(slot_index: int) -> int:
	if get_level.is_valid():
		return maxi(1, int(get_level.call(slot_index)))
	return 1


func is_hero_alive(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= SLOTS:
		return false
	if active_party[slot_index] == null:
		return false
	return _vida_atual[slot_index] > 0


func right_target_index() -> int:
	for i in range(SLOTS - 1, -1, -1):
		if is_hero_alive(i):
			return i
	return -1


func apply_damage_to_hero(slot_index: int, amount: int) -> bool:
	if not is_hero_alive(slot_index):
		return false
	_vida_atual[slot_index] = maxi(0, _vida_atual[slot_index] - maxi(0, amount))
	var sprite: AnimatedSprite2D = _sprites[slot_index]
	if sprite.has_method("flash_damage"):
		sprite.flash_damage()
	_update_bar_slot(slot_index)
	DamageNumber.spawn(get_parent(), sprite.global_position, amount, Color(1, 0.38, 0.32, 1))
	if _vida_atual[slot_index] <= 0:
		_set_fallen(slot_index, true)
		_emit_dps()
		return true
	return false


func heal_party() -> void:
	for i in SLOTS:
		if active_party[i] == null:
			_vida_atual[i] = 0
			_vida_max[i] = 0
			_set_fallen(i, false)
			_update_bar_slot(i)
			continue
		_update_max_hp_slot(i, true)
		_set_fallen(i, false)
		_update_sprite_slot(i)
		_update_timer_slot(i)
	_emit_dps()


func recalculate_stats() -> void:
	for i in SLOTS:
		_update_max_hp_slot(i, false)
		_update_timer_slot(i)
		_update_bar_slot(i)
	_emit_dps()


func serialize() -> Dictionary:
	var ids: Array = []
	for i in SLOTS:
		var classe: Variant = active_party[i]
		if classe is ClassData:
			ids.append((classe as ClassData).id)
		else:
			ids.append("")
	var unlocked: Array = []
	for classe in unlocked_classes:
		unlocked.append(classe.id)
	return {"classes": ids, "unlocked": unlocked}


func apply_from_save(dados: Dictionary) -> void:
	var ids: Variant = dados.get("classes", [])
	if ids is Array and ids.size() > 0:
		for i in SLOTS:
			var id_classe := str(ids[i]) if i < ids.size() else ""
			scale_character(i, get_class_by_id(id_classe))
	var lista: Variant = dados.get("unlocked", [])
	if lista is Array and not lista.is_empty():
		unlocked_classes.clear()
		for id_classe in lista:
			var classe: ClassData = get_class_by_id(str(id_classe))
			if classe:
				unlocked_classes.append(classe)
	_ensure_unlocked_catalog()
	if count_active() <= 0:
		scale_character(0, get_class_by_id("warrior"))


func _ensure_unlocked_catalog() -> void:
	for classe in _catalogo:
		var ja_tem := false
		for atual in unlocked_classes:
			if atual.id == classe.id:
				ja_tem = true
				break
		if not ja_tem:
			unlocked_classes.append(classe)


func _ensure_positions() -> void:
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


func _create_hero_visuals() -> void:
	var script_stick := load("res://presentation/combat/stickman.gd")
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
		timer.timeout.connect(_on_hero_timer.bind(i))
		add_child(timer)
		_timers.append(timer)


func _update_sprite_slot(slot_index: int) -> void:
	var sprite: AnimatedSprite2D = _sprites[slot_index]
	var classe: Variant = active_party[slot_index]
	if classe == null:
		sprite.visible = false
		_set_fallen(slot_index, false)
		_update_bar_slot(slot_index)
		return
	sprite.visible = true
	if sprite.has_method("set_base_position"):
		sprite.set_base_position(_posicoes[slot_index].position)
	else:
		sprite.position = _posicoes[slot_index].position
	if sprite.has_method("apply_class"):
		sprite.apply_class(classe)
	_set_fallen(slot_index, not is_hero_alive(slot_index))
	_update_bar_slot(slot_index)


func _update_timer_slot(slot_index: int) -> void:
	var timer: Timer = _timers[slot_index]
	var classe: Variant = active_party[slot_index]
	if classe == null or not is_hero_alive(slot_index):
		timer.stop()
		return
	var dados: ClassData = classe
	var bonus := _skill_tree_bonus(slot_index)
	var vel := dados.attack_speed * (1.0 + float(bonus.get("attack_speed", 0.0)) / 100.0)
	timer.wait_time = INTERVALO_BASE / maxf(0.25, vel)
	if timer.is_stopped():
		timer.start()


func _update_max_hp_slot(slot_index: int, reset_hp: bool) -> void:
	var novo_max := hero_max_hp(slot_index)
	if novo_max <= 0:
		_vida_max[slot_index] = 0
		_vida_atual[slot_index] = 0
		return
	if reset_hp:
		_vida_max[slot_index] = novo_max
		_vida_atual[slot_index] = novo_max
		return
	if _vida_atual[slot_index] > 0 and novo_max > _vida_max[slot_index]:
		_vida_atual[slot_index] += novo_max - _vida_max[slot_index]
	_vida_max[slot_index] = novo_max
	_vida_atual[slot_index] = clampi(_vida_atual[slot_index], 0, novo_max)


func _update_bar_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= _sprites.size():
		return
	var sprite: AnimatedSprite2D = _sprites[slot_index]
	if sprite.has_method("update_hp"):
		sprite.update_hp(_vida_atual[slot_index], _vida_max[slot_index])


func _set_fallen(slot_index: int, fallen: bool) -> void:
	if slot_index < 0 or slot_index >= _sprites.size():
		return
	var sprite: AnimatedSprite2D = _sprites[slot_index]
	if sprite.has_method("set_fallen"):
		sprite.set_fallen(fallen)
	if fallen:
		_timers[slot_index].stop()


func _on_hero_timer(slot_index: int) -> void:
	if combat_paused:
		return
	if not is_hero_alive(slot_index):
		return
	var sprite: AnimatedSprite2D = _sprites[slot_index]
	if sprite.has_method("play_attack"):
		sprite.play_attack()
	hero_attacked.emit(slot_index, hero_damage(slot_index))


func _emit_dps() -> void:
	dps_changed.emit(party_dps(), total_party_damage())
