extends SceneTree
## Headless sanity check for StatCalculator (run: godot --headless -s res://tests/stat_calculator_test.gd)

const StatCalculatorScript := preload("res://core/stat_calculator.gd")
const ClassDataScript := preload("res://data/class_data.gd")
const SkillResourceScript := preload("res://data/skill_resource.gd")
const SkillRuntimeScript := preload("res://domains/combat/skill_runtime.gd")
const CombatMathScript := preload("res://domains/combat/combat_math.gd")
const TestLog := preload("res://tests/test_log_helper.gd")

var _failed := false


func _init() -> void:
	_test_basic_damage_and_hp()
	_test_bonus_caps()
	_test_passive_stat_bonus_key()
	_test_combat_math()
	if _failed:
		TestLog.suite_complete("StatCalculator", false)
		quit(1)
	TestLog.suite_complete("StatCalculator", true)
	print("[TEST PASS] StatCalculator")
	quit(0)


func _test_basic_damage_and_hp() -> void:
	var calc := StatCalculatorScript.new()
	var warrior: ClassData = null
	for class_data in ClassDataScript.catalog():
		if class_data.id == "warrior":
			warrior = class_data
			break
	calc.get_equipped_damage = func(_slot: int) -> int: return 5
	calc.get_equipped_hp = func(_slot: int) -> int: return 10
	calc.get_level = func(_slot: int) -> int: return 3
	calc.get_skill_tree_bonus = func(_slot: int) -> Dictionary: return {"attack": 2, "hp": 4}
	var stats: Dictionary = calc.compute(0, warrior)
	if int(stats.get("damage", 0)) < 1:
		_fail("damage should be positive")
	if int(stats.get("hp", 0)) < 1:
		_fail("hp should be positive")


func _test_bonus_caps() -> void:
	var bonus := {"crit_chance": 40.0, "attack": 5}
	var capped: Dictionary = StatCalculatorScript.apply_bonus_caps(bonus)
	if float(capped.get("crit_chance", 0.0)) > 25.0:
		_fail("crit_chance should be capped at 25")


func _test_combat_math() -> void:
	var crit: Dictionary = CombatMathScript.roll_crit_damage(100, 50.0, 50.0, 10.0)
	if not bool(crit.get("is_crit", false)):
		_fail("low roll should crit")
	if int(crit.get("damage", 0)) != 150:
		_fail("crit damage should apply 50% bonus")
	var no_crit: Dictionary = CombatMathScript.roll_crit_damage(100, 50.0, 50.0, 90.0)
	if bool(no_crit.get("is_crit", false)):
		_fail("high roll should not crit")
	var evade: Dictionary = CombatMathScript.mitigate_damage(100, 80.0, 0.0, 10.0)
	if not bool(evade.get("evaded", false)):
		_fail("low evasion roll should evade")
	var resisted: Dictionary = CombatMathScript.mitigate_damage(100, 0.0, 50.0, 90.0)
	if int(resisted.get("damage", 0)) != 50:
		_fail("phys res should halve damage")


func _test_passive_stat_bonus_key() -> void:
	var skill := SkillResourceScript.new()
	skill.type = SkillResource.Type.PASSIVE
	skill.stat_bonus_key = "crit_chance"
	skill.stat_value = 6.0
	var bonus := SkillTreeDefinition.empty_bonus()
	SkillRuntimeScript.apply_passive(bonus, skill)
	if not is_equal_approx(float(bonus.get("crit_chance", 0.0)), 6.0):
		_fail("passive should apply crit_chance from stat_bonus_key")


func _fail(message: String) -> void:
	_failed = true
	push_error("[TEST FAIL] %s" % message)
