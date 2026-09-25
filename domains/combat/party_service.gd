class_name PartyService
extends Node2D
## Party of up to 3 stickmen with independent attack timers and stats.

signal party_changed
signal hero_attack_windup(slot_index: int)
signal hero_attacked(slot_index: int, damage: int, is_crit: bool)
signal hero_skill_used(slot_index: int, skill: SkillResource, hits: Array, heals: Array)
signal dps_changed(dps: float, dano_grupo: int)
signal march_regroup_phase_changed(phase_name: String, scroll_speed_px: float)
signal march_regroup_started(scroll_speed_px: float)
signal march_regroup_finished

enum RegroupPhase { NONE, CONVERGE, RETREAT }

const INTERVALO_BASE := 1.0
const SLOTS := 3
const HERO_SLOT_OFFSETS := [-28.0, 0.0, 28.0]
const HERO_PARTY_BACK_X := -72.0
const ARCHER_ROAD_BACK_EXTRA := -40.0
const HERO_FLOOR_OFFSET := 4.0
const HERO_ROAD_DROP_OFFSET := 16.0
const _Tuning := preload("res://domains/combat/sim/combat_tuning.gd")
const COMBAT_ACTOR_Z := 2
const COMBAT_ENEMY_Z := 4
enum PartyFieldState { FORMATION_MARCH, BATTLE_APPROACH, ENGAGED }

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
var _road_layout_forced: bool = false
var _field_state: PartyFieldState = PartyFieldState.ENGAGED
var _battle_advance_x: Array[float] = [0.0, 0.0, 0.0]
var _formation_spread_x: Array[float] = [0.0, 0.0, 0.0]
var _march_lead_x: float = 0.0
var _regroup_scroll_speed: float = 0.0
var _regrouping: bool = false
var _regroup_phase: RegroupPhase = RegroupPhase.NONE
var _regroup_start_lead: float = 0.0
var _regroup_phase_elapsed: float = 0.0


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
	if _regroup_phase != RegroupPhase.NONE:
		_tick_regroup(delta)
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


func set_road_layout_active(active: bool) -> void:
	_road_layout_forced = active


func is_road_combat_ground() -> bool:
	if _road_layout_forced:
		return true
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


func field_state() -> PartyFieldState:
	return _field_state


func formation_slot_x(slot_index: int) -> float:
	return (
		hero_slot_x(slot_index)
		+ _march_lead_x
		+ _formation_spread_x[slot_index]
		+ _battle_advance_x[slot_index]
	)


func hero_combat_x(slot_index: int) -> float:
	return formation_slot_x(slot_index)


func commit_march_from_combat() -> void:
	var lead := 0.0
	var totals: Array[float] = []
	totals.resize(SLOTS)
	for slot_index in SLOTS:
		if not is_hero_alive(slot_index):
			totals[slot_index] = 0.0
			continue
		var total_forward := (
			_march_lead_x + _formation_spread_x[slot_index] + _battle_advance_x[slot_index]
		)
		totals[slot_index] = total_forward
		lead = maxf(lead, total_forward)
	_march_lead_x = lead
	for slot_index in SLOTS:
		if not is_hero_alive(slot_index):
			_formation_spread_x[slot_index] = 0.0
			_battle_advance_x[slot_index] = 0.0
			continue
		_formation_spread_x[slot_index] = totals[slot_index] - lead
		_battle_advance_x[slot_index] = 0.0


func hero_engage_range(slot_index: int) -> float:
	return HeroSpritesheet.engage_range(_class_id_for_slot(slot_index))


func is_hero_in_engage_range(slot_index: int, enemy_x: float) -> bool:
	if not is_hero_alive(slot_index):
		return false
	return absf(enemy_x - hero_combat_x(slot_index)) <= hero_engage_range(slot_index)


func any_hero_in_engage_range(enemy_x: float) -> bool:
	for slot_index in SLOTS:
		if is_hero_in_engage_range(slot_index, enemy_x):
			return true
	return false


func set_field_state(state: PartyFieldState) -> void:
	_field_state = state
	if state == PartyFieldState.ENGAGED:
		_clear_battle_advance_anims()
		if _running:
			end_running()


func begin_formation_march() -> void:
	var already_marching := _field_state == PartyFieldState.FORMATION_MARCH and _running
	_field_state = PartyFieldState.FORMATION_MARCH
	if not already_marching:
		begin_running()
	_start_march_regroup_if_needed()


func is_march_regrouping() -> bool:
	return _regrouping


func regroup_scroll_speed() -> float:
	return _regroup_scroll_speed if _regroup_phase == RegroupPhase.RETREAT else 0.0


func regroup_phase_name() -> String:
	match _regroup_phase:
		RegroupPhase.CONVERGE:
			return "CONVERGE"
		RegroupPhase.RETREAT:
			return "RETREAT"
	return ""


func begin_battle_approach() -> void:
	_cancel_march_regroup_tween()
	_field_state = PartyFieldState.BATTLE_APPROACH
	end_running()


func advance_battle_positions(enemy_x: float, delta: float) -> void:
	if _field_state != PartyFieldState.BATTLE_APPROACH:
		return
	var speed := _Tuning.SCROLL_SPEED_PX
	for slot_index in SLOTS:
		if not is_hero_alive(slot_index):
			continue
		if is_hero_in_engage_range(slot_index, enemy_x):
			_set_slot_battle_anim(slot_index, false)
			continue
		_battle_advance_x[slot_index] += speed * delta
		_refresh_slot_x(slot_index)
		_set_slot_battle_anim(slot_index, true)


func regroup_to_formation(on_complete: Callable = Callable()) -> void:
	for i in SLOTS:
		var sprite: AnimatedSprite2D = _sprites[i]
		if sprite.has_method("clear_arrow_state"):
			sprite.clear_arrow_state()
	_cancel_march_regroup_tween()
	commit_march_from_combat()
	begin_formation_march()
	if on_complete.is_valid():
		on_complete.call()


func sync_floor_y_only() -> void:
	for i in SLOTS:
		var floor_y := combat_floor_y_for_slot(i)
		_posicoes[i].position.y = floor_y
		_apply_slot_position(i)


func sync_floor_positions() -> void:
	var preserve_x := _field_state == PartyFieldState.FORMATION_MARCH or _regrouping
	for i in SLOTS:
		var floor_y := combat_floor_y_for_slot(i)
		if preserve_x:
			_posicoes[i].position.y = floor_y
		else:
			_posicoes[i].position = Vector2(formation_slot_x(i), floor_y)
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


## Rightmost living hero on the X axis (first hero the enemy meets when approaching from the right).
func engage_lane_slot() -> int:
	var best_slot := -1
	var best_x := -INF
	for slot_index in SLOTS:
		if not is_hero_alive(slot_index):
			continue
		var lane_x := hero_combat_x(slot_index)
		if lane_x > best_x:
			best_x = lane_x
			best_slot = slot_index
	return best_slot


func frontline_slot() -> int:
	return engage_lane_slot()


func hero_engage_x() -> float:
	var slot := engage_lane_slot()
	if slot < 0:
		return HERO_PARTY_BACK_X if is_road_combat_ground() else 0.0
	return hero_combat_x(slot)


func get_enemy_spawn_local(off_screen: bool = false) -> Vector2:
	var engage_slot := engage_lane_slot()
	if engage_slot < 0:
		engage_slot = front_target_index()
	var engage_x: float = hero_engage_x() if engage_slot >= 0 else HERO_PARTY_BACK_X
	var base_y := combat_floor_y_for_slot(engage_slot if engage_slot >= 0 else 1)
	var spawn_x: float = _Tuning.spawn_lane_x(
		engage_x,
		off_screen,
		is_road_combat_ground()
	)
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
		if not has_hero_in_slot(i) or not is_hero_alive(i) or not sprite.visible:
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
	_field_state = PartyFieldState.ENGAGED
	_reset_battle_advance()
	for i in SLOTS:
		_pending_attacks[i] = {}
		var sprite: AnimatedSprite2D = _sprites[i]
		if sprite.has_method("reset_combat_pose"):
			sprite.reset_combat_pose()
		elif sprite.has_method("abort_attack"):
			sprite.abort_attack()
		if sprite.has_method("clear_arrow_state"):
			sprite.clear_arrow_state()
		if sprite.has_method("end_running"):
			sprite.end_running()


func _apply_slot_position(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= _sprites.size():
		return
	if not has_hero_in_slot(slot_index) or not is_hero_alive(slot_index):
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
	_formation_spread_x[slot_index] = 0.0
	_battle_advance_x[slot_index] = 0.0
	_pending_attacks[slot_index] = {}
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


func hero_current_hp(slot_index: int) -> int:
	if slot_index < 0 or slot_index >= SLOTS:
		return 0
	return _vida_atual[slot_index]


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


func has_hero_in_slot(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= SLOTS:
		return false
	return active_party[slot_index] is ClassData


func is_hero_alive(slot_index: int) -> bool:
	if not has_hero_in_slot(slot_index):
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
		if not has_hero_in_slot(i):
			_vida_atual[i] = 0
			_vida_max[i] = 0
			_update_sprite_slot(i)
			_timers[i].stop()
			continue
		_update_max_hp_slot(i, true)
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
	if not has_hero_in_slot(slot_index):
		if sprite.has_method("hide_slot"):
			sprite.hide_slot()
		else:
			sprite.visible = false
		_update_bar_slot(slot_index)
		return
	if not is_hero_alive(slot_index):
		_set_fallen(slot_index, true)
		_update_bar_slot(slot_index)
		return
	sprite.visible = true
	_apply_slot_position(slot_index)
	if sprite.has_method("apply_class"):
		sprite.apply_class(classe)
	_set_fallen(slot_index, false)
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
	if not _can_slot_attack(slot_index):
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


func _can_slot_attack(slot_index: int) -> bool:
	if not can_attack_target.is_valid():
		return true
	if can_attack_target.get_argument_count() >= 1:
		return bool(can_attack_target.call(slot_index))
	return bool(can_attack_target.call())


func _reset_battle_advance() -> void:
	_reset_lane_offsets()


func _reset_lane_offsets() -> void:
	_cancel_march_regroup_tween()
	_march_lead_x = 0.0
	for i in SLOTS:
		_formation_spread_x[i] = 0.0
		_battle_advance_x[i] = 0.0
	_clear_battle_advance_anims()


func _cancel_march_regroup_tween() -> void:
	var was_regrouping := _regrouping
	_regroup_phase = RegroupPhase.NONE
	_regrouping = false
	_regroup_scroll_speed = 0.0
	_regroup_phase_elapsed = 0.0
	_clear_regroup_run_scales()
	if was_regrouping:
		march_regroup_finished.emit()


func _start_march_regroup_if_needed() -> void:
	if _regrouping:
		return
	var start_spreads := _formation_spread_x.duplicate()
	var start_lead := _march_lead_x
	var needs_regroup := absf(start_lead) > 0.001
	var needs_converge := false
	if not needs_regroup:
		for spread in start_spreads:
			if absf(float(spread)) > 0.001:
				needs_regroup = true
				needs_converge = true
				break
	else:
		for spread in start_spreads:
			if absf(float(spread)) > 0.001:
				needs_converge = true
				break
	if not needs_regroup:
		_regroup_scroll_speed = 0.0
		return
	_regrouping = true
	_regroup_start_lead = start_lead
	_regroup_phase_elapsed = 0.0
	if needs_converge:
		_regroup_phase = RegroupPhase.CONVERGE
		march_regroup_phase_changed.emit("CONVERGE", 0.0)
	else:
		_begin_regroup_retreat()


func _tick_regroup(delta: float) -> void:
	match _regroup_phase:
		RegroupPhase.CONVERGE:
			_tick_regroup_converge(delta)
		RegroupPhase.RETREAT:
			_tick_regroup_retreat(delta)


func _tick_regroup_converge(delta: float) -> void:
	_regroup_phase_elapsed += delta
	var time_remaining := maxf(
		0.001,
		_Tuning.FORMATION_REGROUP_SPREAD_SEC - _regroup_phase_elapsed
	)
	_march_lead_x = _regroup_start_lead
	var max_spread := 0.0
	for slot_index in SLOTS:
		if not is_hero_alive(slot_index):
			continue
		max_spread = maxf(max_spread, absf(_formation_spread_x[slot_index]))
	for slot_index in SLOTS:
		if not is_hero_alive(slot_index):
			continue
		var spread := _formation_spread_x[slot_index]
		if spread < -0.001:
			var catch_up := maxf(
				_Tuning.SCROLL_SPEED_PX * _Tuning.FORMATION_REGROUP_CATCHUP_MULT,
				absf(spread) / time_remaining
			)
			_formation_spread_x[slot_index] = minf(0.0, spread + catch_up * delta)
			_set_slot_regroup_run_scale(slot_index, _catch_up_run_scale(catch_up))
		else:
			_set_slot_regroup_run_scale(
				slot_index,
				_Tuning.FORMATION_REGROUP_FRONT_RUN_SCALE
			)
		_refresh_slot_x(slot_index)
	if max_spread <= 0.001 or _regroup_phase_elapsed >= _Tuning.FORMATION_REGROUP_SPREAD_SEC:
		_begin_regroup_retreat()


func _tick_regroup_retreat(delta: float) -> void:
	_regroup_phase_elapsed += delta
	var duration := maxf(0.001, _Tuning.FORMATION_REGROUP_RETREAT_SEC)
	var t := clampf(_regroup_phase_elapsed / duration, 0.0, 1.0)
	_march_lead_x = lerpf(_regroup_start_lead, 0.0, t)
	for slot_index in SLOTS:
		_formation_spread_x[slot_index] = 0.0
		_set_slot_regroup_run_scale(slot_index, 1.0)
		_refresh_slot_x(slot_index)
	if t >= 1.0:
		_finish_regroup()


func _begin_regroup_retreat() -> void:
	for slot_index in SLOTS:
		_formation_spread_x[slot_index] = 0.0
	_regroup_phase = RegroupPhase.RETREAT
	_regroup_phase_elapsed = 0.0
	_regroup_start_lead = _march_lead_x
	_regroup_scroll_speed = absf(_regroup_start_lead) / _Tuning.FORMATION_REGROUP_RETREAT_SEC
	if _regroup_scroll_speed <= 0.001:
		_finish_regroup()
		return
	march_regroup_phase_changed.emit("RETREAT", _regroup_scroll_speed)
	march_regroup_started.emit(_regroup_scroll_speed)


func _finish_regroup() -> void:
	_regroup_phase = RegroupPhase.NONE
	_regrouping = false
	_march_lead_x = 0.0
	_regroup_scroll_speed = 0.0
	_regroup_phase_elapsed = 0.0
	for slot_index in SLOTS:
		_formation_spread_x[slot_index] = 0.0
		_refresh_slot_x(slot_index)
	_clear_regroup_run_scales()
	march_regroup_finished.emit()


func _refresh_slot_x(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= _posicoes.size():
		return
	if not has_hero_in_slot(slot_index) or not is_hero_alive(slot_index):
		return
	var floor_y := _posicoes[slot_index].position.y
	_posicoes[slot_index].position = Vector2(formation_slot_x(slot_index), floor_y)
	_apply_slot_position(slot_index)


func _catch_up_run_scale(catch_up_speed: float) -> float:
	return clampf(catch_up_speed / _Tuning.SCROLL_SPEED_PX, 1.0, 3.5)


func _set_slot_regroup_run_scale(slot_index: int, scale: float) -> void:
	if slot_index < 0 or slot_index >= _sprites.size():
		return
	if not has_hero_in_slot(slot_index) or not is_hero_alive(slot_index):
		return
	var sprite: AnimatedSprite2D = _sprites[slot_index]
	if sprite.has_method("set_regroup_run_scale"):
		sprite.set_regroup_run_scale(scale)


func _clear_regroup_run_scales() -> void:
	for slot_index in SLOTS:
		_set_slot_regroup_run_scale(slot_index, 1.0)


func _set_slot_battle_anim(slot_index: int, advancing: bool) -> void:
	if slot_index < 0 or slot_index >= _sprites.size():
		return
	if not has_hero_in_slot(slot_index) or not is_hero_alive(slot_index):
		return
	var sprite: AnimatedSprite2D = _sprites[slot_index]
	if sprite.has_method("set_battle_advancing"):
		sprite.set_battle_advancing(advancing)


func _clear_battle_advance_anims() -> void:
	for i in SLOTS:
		_set_slot_battle_anim(i, false)
