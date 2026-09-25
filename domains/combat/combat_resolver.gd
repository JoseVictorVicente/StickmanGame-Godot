class_name CombatResolver
extends RefCounted
## Resolves SkillResource.effects into combat hits and buff applications.


func resolve_skill(skill: SkillResource, ctx: Dictionary) -> Dictionary:
	if skill == null or skill.effects.is_empty():
		return {"hits": [], "buffs": [], "heals": []}
	if skill.skill_id == "arcane_beat":
		return _resolve_non_damage_effects(skill)
	var hits: Array = []
	var buffs: Array = []
	var heals: Array = []
	var base_damage := int(ctx.get("base_damage", 1))
	var crit_chance := float(ctx.get("crit_chance", 0.0))
	var crit_damage := float(ctx.get("crit_damage", 0.0))
	var vfx_id := str(skill.vfx_id)
	var hit_index := 0
	for effect in skill.effects:
		if effect is DamageEffect:
			_append_damage_hits(
				hits,
				effect as DamageEffect,
				base_damage,
				crit_chance,
				crit_damage,
				vfx_id,
				hit_index
			)
			hit_index += maxi(1, (effect as DamageEffect).hits)
		elif effect is BuffEffect:
			var buff := effect as BuffEffect
			if buff.stat_key != "" and buff.duration_sec > 0.0 and buff.stat_value != 0.0:
				buffs.append({
					"stat_key": buff.stat_key,
					"stat_value": buff.stat_value,
					"duration_sec": buff.duration_sec,
					"target_scope": buff.target_scope if buff.target_scope != "" else "self",
				})
		elif effect is HealEffect:
			var heal := effect as HealEffect
			if heal.heal_pct_max_hp > 0.0:
				heals.append({
					"target_scope": heal.target_scope,
					"heal_pct_max_hp": heal.heal_pct_max_hp,
					"delay_sec": 0.0,
				})
	return {"hits": hits, "buffs": buffs, "heals": heals}


func _resolve_non_damage_effects(skill: SkillResource) -> Dictionary:
	var buffs: Array = []
	var heals: Array = []
	for effect in skill.effects:
		if effect is BuffEffect:
			var buff := effect as BuffEffect
			if buff.stat_key != "" and buff.duration_sec > 0.0 and buff.stat_value != 0.0:
				buffs.append({
					"stat_key": buff.stat_key,
					"stat_value": buff.stat_value,
					"duration_sec": buff.duration_sec,
					"target_scope": buff.target_scope if buff.target_scope != "" else "self",
				})
		elif effect is HealEffect:
			var heal := effect as HealEffect
			if heal.heal_pct_max_hp > 0.0:
				heals.append({
					"target_scope": heal.target_scope,
					"heal_pct_max_hp": heal.heal_pct_max_hp,
					"delay_sec": 0.0,
				})
	return {"hits": [], "buffs": buffs, "heals": heals}


func _append_damage_hits(
	hits: Array,
	effect: DamageEffect,
	base_damage: int,
	crit_chance: float,
	crit_damage: float,
	vfx_id: String,
	start_index: int
) -> void:
	var strike_count := maxi(1, effect.hits)
	var scaled_base := maxi(
		1,
		int(round(float(base_damage) * effect.multiplier * (1.0 + effect.armor_pen_pct / 100.0)))
	)
	for i in strike_count:
		var roll := CombatMath.roll_crit_damage(scaled_base, crit_chance, crit_damage)
		if effect.force_crit:
			roll = CombatMath.roll_crit_damage(scaled_base, 100.0, crit_damage, 0.0)
		hits.append({
			"damage": int(roll.get("damage", scaled_base)),
			"is_crit": bool(roll.get("is_crit", false)),
			"vfx_id": vfx_id,
			"delay_sec": float(start_index + i) * 0.05,
		})
