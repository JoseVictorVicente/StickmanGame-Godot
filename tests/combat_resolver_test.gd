extends SceneTree
## Headless tests for active skill resolver and cooldown runtime.

const CombatResolverScript := preload("res://domains/combat/combat_resolver.gd")
const ActiveSkillRuntimeScript := preload("res://domains/combat/active_skill_runtime.gd")
const BuffContainerScript := preload("res://domains/combat/buff_container.gd")
const DamageEffectScript := preload("res://data/effects/damage_effect.gd")
const BuffEffectScript := preload("res://data/effects/buff_effect.gd")
const SkillResourceScript := preload("res://data/skill_resource.gd")
const TestLog := preload("res://tests/test_log_helper.gd")


var _failed := false


func _init() -> void:
	_test_instant_double_shot()
	_test_precision_shot_scaling()
	_test_hunter_stance_buff()
	_test_cooldown_blocks_second_cast()
	_test_empty_effects_fallback()
	_test_arcane_heal_party()
	if _failed:
		TestLog.suite_complete("CombatResolver", false)
		quit(1)
	TestLog.suite_complete("CombatResolver", true)
	print("[TEST PASS] CombatResolver")
	quit(0)


func _test_instant_double_shot() -> void:
	var skill := _make_damage_skill("instant_double_shot", 1.0, 2, true, 0.0)
	var resolver := CombatResolverScript.new()
	var result: Dictionary = resolver.resolve_skill(skill, {
		"base_damage": 100,
		"crit_chance": 0.0,
		"crit_damage": 50.0,
	})
	var hits: Array = result.get("hits", [])
	TestLog.invariant("double_shot_hits", hits.size() == 2, {"hits": hits.size()})
	if hits.size() != 2:
		_fail("instant_double_shot should produce 2 hits")
	for hit in hits:
		if not bool(hit.get("is_crit", false)):
			_fail("instant_double_shot hits should force crit")


func _test_precision_shot_scaling() -> void:
	var skill := _make_damage_skill("precision_shot", 1.5, 1, true, 30.0)
	var resolver := CombatResolverScript.new()
	var result: Dictionary = resolver.resolve_skill(skill, {
		"base_damage": 100,
		"crit_chance": 0.0,
		"crit_damage": 50.0,
	})
	var hits: Array = result.get("hits", [])
	if hits.is_empty():
		_fail("precision_shot should produce a hit")
	var damage := int(hits[0].get("damage", 0))
	if damage < 195:
		_fail("precision_shot damage should include multiplier and armor pen")


func _test_hunter_stance_buff() -> void:
	var skill := SkillResourceScript.new()
	skill.skill_id = "hunter_stance"
	var buff_speed := BuffEffectScript.new()
	buff_speed.effect_type = "buff_self"
	buff_speed.stat_key = "attack_speed"
	buff_speed.stat_value = 30.0
	buff_speed.duration_sec = 3.5
	skill.effects = [buff_speed]
	var resolver := CombatResolverScript.new()
	var result: Dictionary = resolver.resolve_skill(skill, {"base_damage": 50})
	var buffs: Array = result.get("buffs", [])
	if buffs.size() != 1:
		_fail("hunter_stance should emit one buff")
	var container := BuffContainerScript.new()
	container.add_buff(0, str(buffs[0].get("stat_key", "")), float(buffs[0].get("stat_value", 0.0)), float(buffs[0].get("duration_sec", 0.0)))
	var bonus: Dictionary = container.active_bonuses(0)
	if float(bonus.get("attack_speed", 0.0)) < 30.0:
		_fail("hunter_stance buff should increase attack_speed")


func _test_cooldown_blocks_second_cast() -> void:
	var runtime := ActiveSkillRuntimeScript.new()
	var skill := SkillResourceScript.new()
	skill.skill_id = "test_skill"
	skill.cooldown = 5.0
	runtime.notify_skill_cast(skill, "archer")
	if runtime.remaining_cooldown("test_skill") <= 0.0:
		_fail("cooldown should be active immediately after cast")
	if runtime.remaining_cooldown("missing") != 0.0:
		_fail("unknown skill cooldown should be 0")


func _test_empty_effects_fallback() -> void:
	var skill := SkillResourceScript.new()
	skill.skill_id = "noop_skill"
	var resolver := CombatResolverScript.new()
	var result: Dictionary = resolver.resolve_skill(skill, {"base_damage": 10})
	if (
		not result.get("hits", []).is_empty()
		or not result.get("buffs", []).is_empty()
		or not result.get("heals", []).is_empty()
	):
		_fail("skill without effects should resolve empty")


func _test_arcane_heal_party() -> void:
	var skill := SkillResourceScript.new()
	skill.skill_id = "arcane_heal"
	var heal := preload("res://data/effects/heal_effect.gd").new()
	heal.effect_type = "heal_party"
	heal.heal_pct_max_hp = 20.0
	heal.target_scope = "party"
	skill.effects = [heal]
	var resolver := CombatResolverScript.new()
	var result: Dictionary = resolver.resolve_skill(skill, {"base_damage": 50})
	var heals: Array = result.get("heals", [])
	if heals.size() != 1:
		_fail("arcane_heal should emit one heal entry")
	if float(heals[0].get("heal_pct_max_hp", 0.0)) < 20.0:
		_fail("arcane_heal pct should be 20")


func _make_damage_skill(
	skill_id: String,
	multiplier: float,
	hits: int,
	force_crit: bool,
	armor_pen_pct: float
) -> SkillResource:
	var skill := SkillResourceScript.new()
	skill.skill_id = skill_id
	skill.effects = [_make_damage_effect(multiplier, hits, force_crit, armor_pen_pct)]
	return skill


func _make_damage_effect(
	multiplier: float,
	hits: int,
	force_crit: bool,
	armor_pen_pct: float
) -> DamageEffect:
	var effect := DamageEffectScript.new()
	effect.effect_type = "damage_multi" if hits > 1 else "damage_burst"
	effect.multiplier = multiplier
	effect.hits = hits
	effect.force_crit = force_crit
	effect.armor_pen_pct = armor_pen_pct
	return effect


func _fail(message: String) -> void:
	_failed = true
	push_error("[TEST FAIL] " + message)
