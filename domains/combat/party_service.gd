class_name PartyService
extends Node2D
## Party of up to 3 stickmen with independent attack timers and stats.

signal party_changed
signal hero_attack_windup(slot_index: int)
signal hero_attacked(slot_index: int, damage: int, is_crit: bool)
signal hero_skill_used(slot_index: int, skill: SkillResource, hits: Array, heals: Array)
signal dps_changed(dps: float, dano_grupo: int)

const INTERVALO_BASE := 1.0
const SLOTS := 3
const HERO_SLOT_OFFSETS := [-28.0, 0.0, 28.0]
const HERO_PARTY_BACK_X := -72.0
const ARCHER_ROAD_BACK_EXTRA := -40.0
const HERO_FLOOR_OFFSET := 4.0
const HERO_ROAD_DROP_OFFSET := 16.0
const ENEMY_ATTACK_GAP := 40.0
const ENEMY_APPROACH_RUNWAY := 80.0
const COMBAT_ACTOR_Z := 2
const COMBAT_ENEMY_Z := 4
const OFF_SCREEN_SPAWN_EXTRA_X := 220.0

var active_party: Array = [null, null, null]
var unlocked_classes: Array[ClassData] = []
var combat_paused: bool = false
var combat_ready: bool = false
var stat_calculator: StatCalculator = null
## Callable (slot: int) -> int  equipment damage bonus for that hero.
var get_equipped_damage: Callable
## Callable (slot: int) -> int  equipment HP bonus for that hero.
var get_equipped_hp: Callable
## Callable (slot: int) -> int  hero level for that slot.
var get_level: Callable
## Callable (slot: int) -> Dictionary  skill-tree bonuses.
var get_skill_tree_bonus: Callable
## Callable () -> bool  gate hero attacks (e.g. runner phase until enemy in range).
var can_attack_target: Callable

var _catalogo: Array[ClassData] = []
var _sprites: Array[AnimatedSprite2D] = []
var _timers: Array[Timer] = []
var _posicoes: Array[Marker2D] = []
var _vida_atual: Array[int] = [0, 0, 0]
var _vida_max: Array[int] = [0, 0, 0]
var _skill_runtime := SkillRuntime.new()
var _buff_container := BuffContainer.new()
var _active_runtime := ActiveSkillRuntime.new()
var _combat_resolver := CombatResolver.new()
var _pending_attacks: Array = [{}, {}, {}]
var _running: bool = false
var runner_sync_active: bool = false
var runner_sync_engaged: bool = false


func _ready() -> void:
	_catalogo = ClassData.catalog()
	unlocked_classes = _catalogo.duplicate()
	_ensure_positions()
	_create_hero_visuals()
	if active_party[0] == null:
		scale_character(0, get_class_by_id("warrior"))
		scale_character(1, get_class_by_id("mage"))
		scale_character(2, get_class_by_id("archer"))
	if not HeroEquipment.equipment_changed.is_connected(_on_equipment_changed):
		HeroEquipment.equipment_changed.connect(_on_equipment_changed)


func _process(delta: float) -> void:
	if _buff_container.tick(delta):
		recalculate_stats()


func _on_equipment_changed(_class_id: String) -> void:
	_active_runtime.clear_cooldowns()
	recalculate_stats()


func start_combat() -> void:
	combat_ready = true
	HeroSpritesheet.invalidate_cache()
	for i in SLOTS:
		_pending_attacks[i] = {}
		var sprite: AnimatedSprite2D = _sprites[i]
		if sprite.has_method("abort_attack"):
			sprite.abort_attack()
		_timers[i].stop()
		_update_sprite_slot(i)
		_update_timer_slot(i)


func is_running() -> bool:
	return _running


var floor_scroller: FloorScroller
var combat_background: CombatBackground


func combat_floor_y() -> float:
	return combat_floor_y_for_slot(1)


func is_road_combat_ground() -> bool:
	return (
		combat_background != null
		and combat_background.texture != null
		and combat_background.visible
	)


func combat_road_ground_y(feet_below_center: float) -> float:
	var road_y := combat_background.walk_surface_y()
	return road_y - feet_below_center + HERO_ROAD_DROP_OFFSET


func combat_floor_y_for_slot(slot_index: int) -> float:
	if is_road_combat_ground():
		var class_id := _class_id_for_slot(slot_index)
		return (
			combat_road_ground_y(HeroSpritesheet.feet_below_center(class_id))
			- HeroSpritesheet.ground_offset(class_id).y
		)
	if floor_scroller != null and floor_scroller.visible:
		return floor_scroller.platform_top_y() + HERO_FLOOR_OFFSET
	return _posicoes[slot_index].position.y if slot_index < _posicoes.size() else -30.0


func hero_slot_x(slot_index: int) -> float:
	var spacing: float = HERO_SLOT_OFFSETS[slot_index] if slot_index >= 0 and slot_index < SLOTS else 0.0
	if is_road_combat_ground():
		var x: float = HERO_PARTY_BACK_X + spacing
		if _class_id_for_slot(slot_index) == "archer":
			x += ARCHER_ROAD_BACK_EXTRA
		return x
	return spacing


func sync_floor_positions() -> void:
	for i in SLOTS:
		var floor_y := combat_floor_y_for_slot(i)
		_posicoes[i].position = Vector2(hero_slot_x(i), floor_y)
		_apply_slot_position(i)
		if is_road_combat_ground() and i < _sprites.size():
			_sprites[i].z_index = COMBAT_ACTOR_Z


func _class_id_for_slot(slot_index: int) -> String:
	if slot_index < 0 or slot_index >= SLOTS:
		return "warrior"
	var classe: Variant = active_party[slot_index]
	if classe is ClassData:
		return (classe as ClassData).id
	return "warrior"


func front_target_index() -> int:
	if is_hero_alive(1):
		return 1
	return right_target_index()


func get_enemy_spawn_local(off_screen: bool = false) -> Vector2:
	var front_slot := front_target_index()
	var front_x: float = hero_slot_x(front_slot) if front_slot >= 0 else HERO_PARTY_BACK_X
	var base_y := combat_floor_y_for_slot(front_slot)
	var spawn_x: float = front_x + ENEMY_ATTACK_GAP + ENEMY_APPROACH_RUNWAY
	if off_screen:
		spawn_x += OFF_SCREEN_SPAWN_EXTRA_X
	return Vector2(spawn_x, base_y)


func set_runner_sync(active: bool, engaged: bool = false) -> void:
	runner_sync_active = active
	runner_sync_engaged = engaged


func is_runner_syncing() -> bool:
	return runner_sync_active and not runner_sync_engaged


func begin_running() -> void:
	_running = true
	_set_running_animation(true)


func pause_running_animation() -> void:
	_set_running_animation(false)


func resume_running_animation() -> void:
	if _running:
		_set_running_animation(true)


func _set_running_animation(active: bool) -> void:
	for i in SLOTS:
		var sprite: AnimatedSprite2D = _sprites[i]
		if active_party[i] == null or not sprite.visible:
			continue
		if active and sprite.has_method("begin_running"):
			sprite.begin_running()
		elif sprite.has_method("end_running"):
			sprite.end_running()


func end_running() -> void:
	if not _running:
		return
	_running = false
	for i in SLOTS:
		var sprite: AnimatedSprite2D = _sprites[i]
		if sprite.has_method("end_running"):
			sprite.end_running()


func reset_runner_state() -> void:
	_running = false
	set_runner_sync(false, false)
	for i in SLOTS:
		_pending_attacks[i] = {}
		var sprite: AnimatedSprite2D = _sprites[i]
		if sprite.has_method("reset_combat_pose"):
			sprite.reset_combat_pose()
		elif sprite.has_method("abort_attack"):
			sprite.abort_attack()
		if sprite.has_method("end_running"):
			sprite.end_running()


func _apply_slot_position(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= _sprites.size():
		return
	var sprite: AnimatedSprite2D = _sprites[slot_index]
	var pos := _posicoes[slot_index].position
	if sprite.has_method("set_base_position"):
		sprite.set_base_position(pos)
	else:
		sprite.position = pos


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


func hero_stats(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= SLOTS:
		return StatCalculator._empty()
	var classe: Variant = active_party[slot_index]
	if classe == null or not (classe is ClassData):
		return StatCalculator._empty()
	if stat_calculator == null:
		return StatCalculator._empty()
	return _apply_buff_overlay(
		slot_index,
		classe as ClassData,
		stat_calculator.compute(slot_index, classe as ClassData)
	)


func get_hero_sprite(slot_index: int) -> AnimatedSprite2D:
	if slot_index < 0 or slot_index >= _sprites.size():
		return null
	return _sprites[slot_index]


func _apply_buff_overlay(slot_index: int, class_data: ClassData, stats: Dictionary) -> Dictionary:
	var buff_bonus := _buff_container.active_bonuses(slot_index)
	if buff_bonus.is_empty():
		return stats
	var overlay := stats.duplicate(true)
	var bonus: Variant = overlay.get("skill_tree_bonus")
	if bonus is Dictionary:
		bonus = bonus.duplicate(true)
	else:
		bonus = SkillTreeDefinition.empty_bonus()
	SkillRuntime.merge_into(bonus, buff_bonus)
	bonus = StatCalculator.apply_bonus_caps(bonus)
	overlay["skill_tree_bonus"] = bonus
	var level := _slot_level(slot_index)
	var equip_damage := 0
	if get_equipped_damage.is_valid():
		equip_damage = int(get_equipped_damage.call(slot_index))
	var equip_hp := 0
	if get_equipped_hp.is_valid():
		equip_hp = int(get_equipped_hp.call(slot_index))
	overlay["damage"] = StatCalculator._compute_damage(class_data, level, equip_damage, bonus)
	overlay["hp"] = StatCalculator._compute_hp(class_data, level, equip_hp, bonus)
	overlay["attack_speed"] = class_data.attack_speed * (1.0 + float(bonus.get("attack_speed", 0.0)) / 100.0)
	overlay["attack_speed_bonus"] = float(bonus.get("attack_speed", 0.0))
	overlay["crit_chance"] = float(bonus.get("crit_chance", 0.0))
	overlay["crit_damage"] = float(bonus.get("crit_damage", 0.0))
	overlay["evasion"] = float(bonus.get("evasion", 0.0))
	overlay["phys_res"] = float(bonus.get("phys_res", 0.0))
	overlay["arcane_res"] = float(bonus.get("arcane_res", 0.0))
	overlay["elemental_res"] = float(bonus.get("elemental_res", 0.0))
	overlay["cooldown_reduction"] = float(bonus.get("cooldown_reduction", 0.0))
	return overlay


func hero_damage(slot_index: int) -> int:
	if slot_index < 0 or slot_index >= SLOTS:
		return 0
	var classe: Variant = active_party[slot_index]
	if classe == null or not (classe is ClassData):
		return 0
	if stat_calculator != null:
		return int(hero_stats(slot_index).get("damage", 0))
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
		var intervalo := INTERVALO_BASE / maxf(0.25, _hero_attack_speed(i))
		dps += float(hero_damage(i)) / intervalo
	return dps


func hero_max_hp(slot_index: int) -> int:
	if slot_index < 0 or slot_index >= SLOTS:
		return 0
	var classe: Variant = active_party[slot_index]
	if classe == null or not (classe is ClassData):
		return 0
	if stat_calculator != null:
		return int(hero_stats(slot_index).get("hp", 0))
	var extra := 0
	if get_equipped_hp.is_valid():
		extra = int(get_equipped_hp.call(slot_index))
	var dados := classe as ClassData
	var bonus := _skill_tree_bonus(slot_index)
	var base := maxi(1, dados.base_hp + extra + (_slot_level(slot_index) - 1) * dados.hp_per_level + int(bonus.get("hp", 0)))
	var pct := float(bonus.get("hp_pct", 0.0))
	return maxi(1, int(round(float(base) * (1.0 + pct / 100.0))))


func _skill_tree_bonus(slot_index: int) -> Dictionary:
	if stat_calculator != null:
		var stats := hero_stats(slot_index)
		var bonus: Variant = stats.get("skill_tree_bonus")
		if bonus is Dictionary:
			return bonus
	var bonus := SkillTreeDefinition.empty_bonus()
	if get_skill_tree_bonus.is_valid():
		var raw: Variant = get_skill_tree_bonus.call(slot_index)
		if raw is Dictionary:
			bonus = raw.duplicate(true)
	var classe: Variant = active_party[slot_index]
	if classe is ClassData:
		SkillRuntime.merge_into(bonus, _skill_runtime.bonuses_for_class((classe as ClassData).id))
	return StatCalculator.apply_bonus_caps(bonus)


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


func hero_world_position(slot_index: int) -> Vector2:
	if slot_index < 0 or slot_index >= _sprites.size():
		return Vector2.ZERO
	var sprite: AnimatedSprite2D = _sprites[slot_index]
	if sprite == null or not sprite.visible:
		return Vector2.ZERO
	return sprite.global_position


func roll_attack_damage(slot_index: int) -> Dictionary:
	var base := hero_damage(slot_index)
	var stats := hero_stats(slot_index)
	return CombatMath.roll_crit_damage(
		base,
		float(stats.get("crit_chance", 0.0)),
		float(stats.get("crit_damage", 0.0))
	)


func mitigate_incoming_damage(slot_index: int, raw_damage: int) -> Dictionary:
	var stats := hero_stats(slot_index)
	return CombatMath.mitigate_damage(
		raw_damage,
		float(stats.get("evasion", 0.0)),
		float(stats.get("phys_res", 0.0)),
		float(stats.get("arcane_res", 0.0)),
		float(stats.get("elemental_res", 0.0))
	)


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


func heal_hero_percent(slot_index: int, pct: float) -> int:
	if slot_index < 0 or slot_index >= SLOTS or pct <= 0.0:
		return 0
	if not is_hero_alive(slot_index):
		return 0
	var max_hp := _vida_max[slot_index]
	if max_hp <= 0:
		return 0
	var amount := maxi(1, int(round(float(max_hp) * pct / 100.0)))
	var before := _vida_atual[slot_index]
	_vida_atual[slot_index] = mini(max_hp, before + amount)
	var healed := _vida_atual[slot_index] - before
	if healed > 0:
		_update_bar_slot(slot_index)
	return healed


func heal_slots_for_scope(caster_slot: int, target_scope: String) -> Array[int]:
	var scope := target_scope if target_scope != "" else "party"
	if scope == "self":
		return [caster_slot] if is_hero_alive(caster_slot) else []
	if scope == "lowest_hp":
		var best_slot := -1
		var best_ratio := 2.0
		for i in SLOTS:
			if not is_hero_alive(i):
				continue
			if _vida_max[i] <= 0:
				continue
			var ratio := float(_vida_atual[i]) / float(_vida_max[i])
			if ratio < best_ratio:
				best_ratio = ratio
				best_slot = i
		return [best_slot] if best_slot >= 0 else []
	var slots: Array[int] = []
	for i in SLOTS:
		if is_hero_alive(i):
			slots.append(i)
	return slots


func apply_on_kill_passives() -> void:
	var flat_reduction := 0.0
	for slot_index in SLOTS:
		var classe: Variant = active_party[slot_index]
		if classe == null or not (classe is ClassData):
			continue
		if not is_hero_alive(slot_index):
			continue
		var class_id := (classe as ClassData).id
		for passive_slot in HeroEquipment.MAX_PASSIVE:
			var passive: SkillResource = HeroEquipment.get_equipped(
				class_id,
				SkillResource.Type.PASSIVE,
				passive_slot
			)
			if passive == null:
				continue
			match passive.skill_id:
				"adrenaline":
					flat_reduction = maxf(flat_reduction, 1.0)
				"adrenaline_surge":
					flat_reduction = maxf(flat_reduction, 0.5)
	if flat_reduction > 0.0:
		_active_runtime.reduce_all_cooldowns(flat_reduction)


func cooldown_reduction_pct(slot_index: int) -> float:
	var stats := hero_stats(slot_index)
	if stats.is_empty():
		return 0.0
	var bonus: Variant = stats.get("skill_tree_bonus")
	if bonus is Dictionary:
		return float(bonus.get("cooldown_reduction", 0.0))
	return float(stats.get("cooldown_reduction", 0.0))


func _apply_skill_buffs(caster_slot: int, buffs: Array) -> bool:
	var changed := false
	for buff in buffs:
		var stat_key := str(buff.get("stat_key", ""))
		var stat_value := float(buff.get("stat_value", 0.0))
		var duration_sec := float(buff.get("duration_sec", 0.0))
		if stat_key == "" or duration_sec <= 0.0 or stat_value == 0.0:
			continue
		var scope := str(buff.get("target_scope", "self"))
		if scope == "party":
			var slots: Array = []
			for i in SLOTS:
				if is_hero_alive(i):
					slots.append(i)
			_buff_container.add_buff_to_slots(slots, stat_key, stat_value, duration_sec)
		else:
			_buff_container.add_buff(caster_slot, stat_key, stat_value, duration_sec)
		changed = true
	return changed


func _apply_rune_resonance_stacking(slot_index: int, class_id: String) -> bool:
	for passive_slot in HeroEquipment.MAX_PASSIVE:
		var passive: SkillResource = HeroEquipment.get_equipped(
			class_id,
			SkillResource.Type.PASSIVE,
			passive_slot
		)
		if passive == null or passive.skill_id != "rune_resonance":
			continue
		if _buff_container.count_stacks(slot_index, "cooldown_reduction") >= 4:
			return false
		_buff_container.add_buff(slot_index, "cooldown_reduction", 5.0, 3.0)
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
	var floor_y := -44.0
	var locais: Array[Vector2] = []
	for offset_x in HERO_SLOT_OFFSETS:
		locais.append(Vector2(offset_x, floor_y))
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

		sprite.connect("attack_impact", _on_hero_attack_impact.bind(i))
		sprite.connect("attack_finished", _on_hero_attack_finished.bind(i))

		var timer := Timer.new()
		timer.name = "TimerHeroi_%d" % (i + 1)
		timer.one_shot = true
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
	_apply_slot_position(slot_index)
	if sprite.has_method("apply_class"):
		sprite.apply_class(classe)
	_set_fallen(slot_index, not is_hero_alive(slot_index))
	_update_bar_slot(slot_index)


func _hero_attack_speed(slot_index: int) -> float:
	return float(hero_stats(slot_index).get("attack_speed", 1.0))


func _hero_attack_interval(slot_index: int) -> float:
	return HeroSpritesheet.attack_cooldown(_hero_attack_speed(slot_index))


func _update_timer_slot(slot_index: int) -> void:
	var timer: Timer = _timers[slot_index]
	var classe: Variant = active_party[slot_index]
	if classe == null or not is_hero_alive(slot_index):
		timer.stop()
		return
	timer.wait_time = _hero_attack_interval(slot_index)
	if not combat_ready:
		timer.stop()
		return
	if timer.is_stopped() and not _is_slot_attacking(slot_index):
		timer.start()


func _is_slot_attacking(slot_index: int) -> bool:
	if _has_arrow_in_flight(slot_index):
		return true
	var sprite: AnimatedSprite2D = _sprites[slot_index]
	return sprite.has_method("is_attacking") and sprite.is_attacking()


func _restart_hero_timer(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= _timers.size():
		return
	var classe: Variant = active_party[slot_index]
	if classe == null or not is_hero_alive(slot_index):
		_timers[slot_index].stop()
		return
	var timer: Timer = _timers[slot_index]
	timer.wait_time = _hero_attack_interval(slot_index)
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
	if not combat_ready:
		return
	if can_attack_target.is_valid() and not bool(can_attack_target.call()):
		_restart_hero_timer(slot_index)
		return
	if combat_paused:
		_restart_hero_timer(slot_index)
		return
	if not is_hero_alive(slot_index):
		return
	var classe: Variant = active_party[slot_index]
	if classe == null or not (classe is ClassData):
		return
	var sprite: AnimatedSprite2D = _sprites[slot_index]
	if _is_slot_attacking(slot_index):
		if sprite.has_method("abort_attack"):
			sprite.abort_attack()
	var stats := hero_stats(slot_index)
	var vel := _hero_attack_speed(slot_index)
	var cooldown := _hero_attack_interval(slot_index)
	var class_data := classe as ClassData
	var cdr_pct := cooldown_reduction_pct(slot_index)
	var skill := _active_runtime.try_cast(slot_index, class_data.id, cdr_pct)
	var pending: Dictionary = {}
	if skill != null:
		var ctx := {
			"base_damage": int(stats.get("damage", 1)),
			"crit_chance": float(stats.get("crit_chance", 0.0)),
			"crit_damage": float(stats.get("crit_damage", 0.0)),
		}
		var result: Dictionary = _combat_resolver.resolve_skill(skill, ctx)
		if _apply_skill_buffs(slot_index, result.get("buffs", [])):
			recalculate_stats()
		if _apply_rune_resonance_stacking(slot_index, class_data.id):
			recalculate_stats()
		pending = {"kind": "skill", "skill": skill, "result": result}
	else:
		var roll := roll_attack_damage(slot_index)
		pending = {"kind": "basic", "roll": roll}
	_pending_attacks[slot_index] = pending
	if not sprite.has_method("begin_attack") or not sprite.begin_attack(cooldown, vel):
		_pending_attacks[slot_index] = {}
		_restart_hero_timer(slot_index)
		return
	hero_attack_windup.emit(slot_index)


func _on_hero_attack_impact(slot_index: int) -> void:
	if combat_paused:
		_wait_and_apply_attack_impact(slot_index)
		return
	_apply_hero_attack_impact(slot_index)


func _wait_and_apply_attack_impact(slot_index: int) -> void:
	while combat_paused:
		var tree := get_tree()
		if tree == null:
			return
		await tree.process_frame
	_apply_hero_attack_impact(slot_index)


func _apply_hero_attack_impact(slot_index: int) -> void:
	var pending: Dictionary = _pending_attacks[slot_index]
	if pending.is_empty():
		return
	_pending_attacks[slot_index] = {}
	if pending.get("kind") == "skill":
		var skill: SkillResource = pending.get("skill")
		var result: Dictionary = pending.get("result", {})
		hero_skill_used.emit(
			slot_index,
			skill,
			result.get("hits", []),
			result.get("heals", [])
		)
		return
	var roll: Dictionary = pending.get("roll", {})
	hero_attacked.emit(slot_index, int(roll.get("damage", 0)), bool(roll.get("is_crit", false)))
	if _uses_deferred_arrow_impact(slot_index):
		_restart_hero_timer(slot_index)


func _on_hero_attack_finished(slot_index: int) -> void:
	if _uses_deferred_arrow_impact(slot_index):
		if _has_arrow_in_flight(slot_index):
			return
		_pending_attacks[slot_index] = {}
		_restart_hero_timer(slot_index)
		return
	_pending_attacks[slot_index] = {}
	_restart_hero_timer(slot_index)


func _uses_deferred_arrow_impact(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= _sprites.size():
		return false
	var sprite: AnimatedSprite2D = _sprites[slot_index]
	return sprite.has_method("uses_deferred_arrow_impact") and sprite.uses_deferred_arrow_impact()


func _has_arrow_in_flight(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= _sprites.size():
		return false
	var sprite: AnimatedSprite2D = _sprites[slot_index]
	return sprite.has_method("has_arrow_in_flight") and sprite.has_arrow_in_flight()


func _emit_dps() -> void:
	dps_changed.emit(party_dps(), total_party_damage())
