class_name EnemyHorde
extends RefCounted
## Runtime squad for a single horde wave (several enemies killed in sequence).

var _members: Array[Enemy] = []
var _enemy_data: EnemyData
var _active_index: int = 0


func clear() -> void:
	_members.clear()
	_enemy_data = null
	_active_index = 0


func build(base_stats: Dictionary, data: EnemyData, count: int, world: int) -> void:
	clear()
	_enemy_data = data
	var amount := maxi(1, count)
	for _i in amount:
		var runtime := EnemyCatalog.build_runtime(base_stats, data)
		var enemy := Enemy.new()
		enemy.configure(
			EnemyCatalog.display_name(data, world),
			int(runtime["hp"]),
			int(runtime["gold"]),
			int(runtime["xp"]),
			int(runtime["damage"])
		)
		_members.append(enemy)


func get_enemy_data() -> EnemyData:
	return _enemy_data


func member_count() -> int:
	return _members.size()


func living_count() -> int:
	var total := 0
	for member in _members:
		if member != null and not member.is_dead():
			total += 1
	return total


func has_living() -> bool:
	return living_count() > 0


func active_index() -> int:
	return _active_index


func active_enemy() -> Enemy:
	if _active_index < 0 or _active_index >= _members.size():
		return null
	var member: Enemy = _members[_active_index]
	if member == null or member.is_dead():
		return _find_next_living()
	return member


func advance_after_kill() -> void:
	if _active_index < _members.size() - 1:
		_active_index += 1
	_find_next_living()


func display_name(world: int) -> String:
	var data := get_enemy_data()
	if data == null:
		return "Enemy"
	var base_name := EnemyCatalog.display_name(data, world)
	var remaining := living_count()
	if remaining <= 1:
		return base_name
	return "%s x%d" % [base_name, remaining]


func _find_next_living() -> Enemy:
	for i in _members.size():
		var member: Enemy = _members[i]
		if member != null and not member.is_dead():
			_active_index = i
			return member
	return null
