class_name CombatCueAdapter
extends RefCounted
## Maps combat vfx_id strings to existing presentation effects.


static func play(
	vfx_id: String,
	party: PartyService,
	slot_index: int,
	enemy_visual: Node2D,
	combat_root: Node,
	hit_count: int = 1
) -> void:
	if vfx_id == "" or party == null or combat_root == null:
		return
	match vfx_id:
		"arrow_single":
			_fire_arrow(party, slot_index, enemy_visual, combat_root, 1, 0.0)
		"arrow_burst":
			var total := maxi(1, hit_count)
			for i in total:
				_fire_arrow(party, slot_index, enemy_visual, combat_root, total, float(i) * 0.04)
		"buff_glow":
			_play_buff_glow(party, slot_index)


static func _fire_arrow(
	party: PartyService,
	slot_index: int,
	enemy_visual: Node2D,
	combat_root: Node,
	_total: int,
	delay_sec: float
) -> void:
	var origem := party.hero_world_position(slot_index) + Vector2(18, -8)
	var destino := origem + Vector2(90, 0)
	if enemy_visual:
		destino = enemy_visual.global_position
	if delay_sec <= 0.0:
		ArrowProjectile.fire(combat_root, origem, destino)
		return
	var timer := combat_root.get_tree().create_timer(delay_sec)
	timer.timeout.connect(func() -> void:
		ArrowProjectile.fire(combat_root, origem, destino)
	)


static func _play_buff_glow(party: PartyService, slot_index: int) -> void:
	var sprite := party.get_hero_sprite(slot_index)
	if sprite == null:
		return
	if sprite.has_method("play_buff_glow"):
		sprite.play_buff_glow()
