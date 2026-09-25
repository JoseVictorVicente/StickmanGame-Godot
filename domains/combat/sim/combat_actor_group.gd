class_name CombatActorGroup
extends RefCounted
## Runtime enemy squad (horde or sequential queue).

const _Lane := preload("res://domains/combat/sim/combat_lane.gd")

enum AttackMode { SWARM, QUEUE }

var members: Array[Enemy] = []
var enemy_data: EnemyData
var attack_mode: AttackMode = AttackMode.SWARM
var active_index: int = 0
var display_world: int = 1
var contact_lane_x: float = 0.0
var member_lane_x: Array[float] = []
var members_at_contact: Array[bool] = []


func clear() -> void:
	members.clear()
	enemy_data = null
	active_index = 0
	member_lane_x.clear()
	members_at_contact.clear()
	contact_lane_x = 0.0


func build(
	base_stats: Dictionary,
	data: EnemyData,
	count: int,
	world: int,
	contact_x: float,
	mode: AttackMode = AttackMode.SWARM
) -> void:
	clear()
	enemy_data = data
	display_world = world
	attack_mode = mode
	contact_lane_x = contact_x
	var amount := maxi(1, count)
	for i in amount:
		var runtime := EnemyCatalog.build_runtime(base_stats, data)
		var enemy := Enemy.new()
		enemy.configure(
			EnemyCatalog.display_name(data, world),
			int(runtime["hp"]),
			int(runtime["gold"]),
			int(runtime["xp"]),
			int(runtime["damage"])
		)
		members.append(enemy)
		member_lane_x.append(_Lane.spawn_x(contact_x - _Lane.MELEE_CONTACT) + float(i) * 48.0)
		members_at_contact.append(false)
	_find_next_living()


func member_count() -> int:
	return members.size()


func living_count() -> int:
	var total := 0
	for member in members:
		if member != null and not member.is_dead():
			total += 1
	return total


func has_living() -> bool:
	return living_count() > 0


func active_enemy() -> Enemy:
	if active_index < 0 or active_index >= members.size():
		return null
	var member: Enemy = members[active_index]
	if member == null or member.is_dead():
		return _find_next_living()
	return member


func advance_after_kill() -> void:
	if active_index < members.size() - 1:
		active_index += 1
	_find_next_living()


func display_name() -> String:
	if enemy_data == null:
		return "Enemy"
	var base_name := EnemyCatalog.display_name(enemy_data, display_world)
	var remaining := living_count()
	if remaining <= 1:
		return base_name
	return "%s x%d" % [base_name, remaining]


func all_at_contact() -> bool:
	if members.is_empty():
		return false
	for i in members.size():
		if members[i] == null or members[i].is_dead():
			continue
		if i >= members_at_contact.size() or not members_at_contact[i]:
			return false
	return true


func mark_member_at_contact(index: int, contact_x: float) -> void:
	while members_at_contact.size() <= index:
		members_at_contact.append(false)
	while member_lane_x.size() <= index:
		member_lane_x.append(contact_lane_x)
	members_at_contact[index] = true
	member_lane_x[index] = contact_x


func advance_member_toward_contact(index: int, speed: float, delta: float) -> bool:
	if index < 0 or index >= members.size():
		return false
	var member: Enemy = members[index]
	if member == null or member.is_dead():
		return false
	if index < members_at_contact.size() and members_at_contact[index]:
		return true
	while member_lane_x.size() <= index:
		member_lane_x.append(_Lane.spawn_x(0.0))
	var lane_x: float = member_lane_x[index]
	lane_x -= speed * delta
	if lane_x <= contact_lane_x:
		lane_x = contact_lane_x
		mark_member_at_contact(index, contact_lane_x)
		return true
	member_lane_x[index] = lane_x
	return false


func _find_next_living() -> Enemy:
	for i in members.size():
		var member: Enemy = members[i]
		if member != null and not member.is_dead():
			active_index = i
			return member
	return null
