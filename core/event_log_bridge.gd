class_name EventLogBridge
extends RefCounted
## Connects domain signals to GameLog with throttling and trace IDs.

const DPS_THROTTLE_SEC := 5.0

var _snapshot_fn: Callable = Callable()
var _combat: CombatController = null
var _dps_last_emit_ms: int = 0
var _death_trace_id: String = ""
var _attack_count: int = 0
var _death_count: int = 0
var _gold_total: int = 0


func connect_combat(combat: CombatController, party: PartyService) -> void:
	_combat = combat
	party.hero_attacked.connect(_on_hero_attacked)
	party.hero_skill_used.connect(_on_hero_skill_used)
	party.dps_changed.connect(_on_dps_changed)
	combat.enemy_hit.connect(_on_enemy_hit)
	combat.enemy_died.connect(_on_enemy_died)
	combat.gold_gained.connect(_on_combat_gold_gained)
	combat.item_dropped.connect(_on_item_dropped)
	combat.hero_level_changed.connect(_on_hero_level_changed)
	combat.progression_changed.connect(func() -> void: _on_progression_changed(combat))


func connect_inventory(menu: InventoryMenu) -> void:
	menu.equipment_changed.connect(_on_equipment_changed)
	menu.character_changed.connect(_on_character_changed)
	menu.gold_gained.connect(func(amount: int) -> void: _on_gold_gained(amount, "menu"))
	menu.gold_spent.connect(_on_gold_spent)
	menu.skill_tree_changed.connect(_on_skill_tree_changed)
	menu.stage_started.connect(_on_stage_started)


func connect_hero_equipment() -> void:
	if not HeroEquipment.equipment_changed.is_connected(_on_hero_equipment_changed):
		HeroEquipment.equipment_changed.connect(_on_hero_equipment_changed)


func set_snapshot_provider(fn: Callable) -> void:
	_snapshot_fn = fn


func emit_boot_snapshot() -> void:
	emit_snapshot("boot")


func emit_snapshot(label: String) -> void:
	if not GameLog.is_enabled():
		return
	if _snapshot_fn.is_valid():
		var state: Variant = _snapshot_fn.call()
		if state is Dictionary:
			GameLog.snapshot(label, state)


func get_smoke_counters() -> Dictionary:
	return {
		"attacks": _attack_count,
		"deaths": _death_count,
		"gold_total": _gold_total,
	}


func _on_hero_attacked(slot_index: int, damage: int, is_crit: bool) -> void:
	if not GameLog.is_enabled():
		return
	_attack_count += 1
	if _death_trace_id == "":
		_death_trace_id = GameLog.trace_start("enemy_kill")
	var level := GameLog.Level.INFO if is_crit else GameLog.Level.DEBUG
	GameLog.event(
		GameLog.Category.COMBAT,
		EventCatalog.COMBAT_HERO_ATTACK,
		{"slot": slot_index, "damage": damage, "is_crit": is_crit},
		level,
		GameLog.Kind.DOMAIN,
		_death_trace_id,
	)


func _on_hero_skill_used(
	slot_index: int,
	skill: SkillResource,
	hits: Array,
	heals: Array = []
) -> void:
	if not GameLog.is_enabled():
		return
	if _death_trace_id == "":
		_death_trace_id = GameLog.trace_start("enemy_kill")
	var skill_id := skill.skill_id if skill != null else ""
	GameLog.event(
		GameLog.Category.COMBAT,
		EventCatalog.COMBAT_SKILL_CAST,
		{"slot": slot_index, "skill_id": skill_id, "hit_count": hits.size(), "heal_count": heals.size()},
		GameLog.Level.INFO,
		GameLog.Kind.DOMAIN,
		_death_trace_id,
	)


func _on_enemy_hit(damage: int, current: int, max_hp: int) -> void:
	if not GameLog.is_enabled():
		return
	GameLog.invariant("hp_non_negative", current >= 0, {"hp": current, "max_hp": max_hp})
	GameLog.event(
		GameLog.Category.COMBAT,
		EventCatalog.COMBAT_ENEMY_HIT,
		{"damage": damage, "hp": current, "max_hp": max_hp},
		GameLog.Level.DEBUG,
		GameLog.Kind.DOMAIN,
		_death_trace_id,
	)


func _on_enemy_died() -> void:
	if not GameLog.is_enabled():
		return
	_death_count += 1
	var death_data := {}
	if _combat != null:
		death_data = {
			"world": _combat.world,
			"stage": _combat.stage,
			"wave": _combat.wave,
		}
	GameLog.event(
		GameLog.Category.COMBAT,
		EventCatalog.COMBAT_ENEMY_DIED,
		death_data,
		GameLog.Level.INFO,
		GameLog.Kind.DOMAIN,
		_death_trace_id,
	)
	if _death_trace_id != "":
		GameLog.trace_end(_death_trace_id)
		_death_trace_id = ""
	call_deferred("emit_snapshot", "enemy_died")


func _on_combat_gold_gained(amount: int) -> void:
	_on_gold_gained(amount, "combat")


func _on_gold_gained(amount: int, source: String) -> void:
	if not GameLog.is_enabled():
		return
	_gold_total += maxi(0, amount)
	GameLog.invariant("gold_non_negative", amount >= 0, {"amount": amount, "source": source})
	GameLog.event(
		GameLog.Category.PROGRESSION,
		EventCatalog.PROGRESSION_GOLD_GAINED,
		{"amount": amount, "source": source},
		GameLog.Level.INFO,
		GameLog.Kind.DOMAIN,
		_death_trace_id,
	)


func _on_gold_spent(amount: int) -> void:
	if not GameLog.is_enabled():
		return
	GameLog.event(
		GameLog.Category.PROGRESSION,
		EventCatalog.PROGRESSION_GOLD_SPENT,
		{"amount": amount, "reason": "skill_tree"},
		GameLog.Level.INFO,
	)


func _on_item_dropped(item: ItemData) -> void:
	if not GameLog.is_enabled():
		return
	var item_id := item.id if item != null else ""
	GameLog.event(
		GameLog.Category.INVENTORY,
		EventCatalog.INVENTORY_ITEM_DROPPED,
		{"item_id": item_id},
		GameLog.Level.INFO,
	)


func _on_hero_level_changed(slot_index: int, level: int) -> void:
	if not GameLog.is_enabled():
		return
	GameLog.event(
		GameLog.Category.PROGRESSION,
		EventCatalog.PROGRESSION_LEVEL_UP,
		{"slot": slot_index, "level": level},
		GameLog.Level.INFO,
	)


func _on_progression_changed(combat: CombatController) -> void:
	if not GameLog.is_enabled():
		return
	GameLog.event(
		GameLog.Category.PROGRESSION,
		EventCatalog.PROGRESSION_STAGE_CHANGED,
		{
			"world": combat.world,
			"stage": combat.stage,
			"difficulty": combat.difficulty,
		},
		GameLog.Level.INFO,
	)


func _on_dps_changed(dps: float, group_damage: int) -> void:
	if not GameLog.is_enabled():
		return
	var now_ms := Time.get_ticks_msec()
	if now_ms - _dps_last_emit_ms < int(DPS_THROTTLE_SEC * 1000.0):
		return
	_dps_last_emit_ms = now_ms
	GameLog.event(
		GameLog.Category.PARTY,
		EventCatalog.PARTY_DPS_CHANGED,
		{"dps": dps, "group_damage": group_damage},
		GameLog.Level.TRACE,
	)


func _on_equipment_changed() -> void:
	if not GameLog.is_enabled():
		return
	GameLog.event(
		GameLog.Category.INVENTORY,
		EventCatalog.INVENTORY_EQUIP_CHANGED,
		{},
		GameLog.Level.INFO,
	)


func _on_character_changed(index: int) -> void:
	if not GameLog.is_enabled():
		return
	GameLog.event(
		GameLog.Category.INVENTORY,
		EventCatalog.INVENTORY_CHARACTER_CHANGED,
		{"index": index},
		GameLog.Level.INFO,
	)


func _on_skill_tree_changed() -> void:
	if not GameLog.is_enabled():
		return
	GameLog.event(
		GameLog.Category.PROGRESSION,
		EventCatalog.PROGRESSION_SKILL_TREE_CHANGED,
		{},
		GameLog.Level.INFO,
	)


func _on_stage_started(world: int, stage: int, difficulty: int) -> void:
	if not GameLog.is_enabled():
		return
	GameLog.event(
		GameLog.Category.PROGRESSION,
		EventCatalog.PROGRESSION_STAGE_STARTED,
		{"world": world, "stage": stage, "difficulty": difficulty},
		GameLog.Level.INFO,
	)


func _on_hero_equipment_changed(class_id: String) -> void:
	if not GameLog.is_enabled():
		return
	GameLog.event(
		GameLog.Category.INVENTORY,
		EventCatalog.INVENTORY_HERO_EQUIP_CHANGED,
		{"class_id": class_id},
		GameLog.Level.INFO,
	)

