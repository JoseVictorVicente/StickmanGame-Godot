extends SceneTree
## Headless sanity check for StatCalculator (run: godot --headless -s res://tests/stat_calculator_test.gd)

const StatCalculatorScript := preload("res://core/stat_calculator.gd")
const ClassDataScript := preload("res://data/class_data.gd")


func _init() -> void:
	var calc := StatCalculatorScript.new()
	var warrior: ClassData = null
	for class_data in ClassDataScript.catalog():
		if class_data.id == "warrior":
			warrior = class_data
			break
	calc.get_equipped_damage = func(_slot: int) -> int: return 5
	calc.get_equipped_hp = func(_slot: int) -> int: return 10
	calc.get_level = func(_slot: int) -> int: return 3
	calc.get_skill_tree_bonus = func(_slot: int) -> Dictionary: return {"ataque": 2, "vida": 4}
	var stats: Dictionary = calc.compute(0, warrior)
	if int(stats.get("damage", 0)) < 1:
		push_error("[TEST FAIL] damage should be positive")
		quit(1)
	if int(stats.get("hp", 0)) < 1:
		push_error("[TEST FAIL] hp should be positive")
		quit(1)
	print("[TEST PASS] StatCalculator")
	quit(0)
