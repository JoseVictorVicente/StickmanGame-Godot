class_name CombatMath
extends RefCounted
## Pure combat roll helpers (deterministic when rolls are injected).


static func roll_crit_damage(
	base_damage: int,
	crit_chance: float,
	crit_damage_pct: float,
	chance_roll: float = -1.0
) -> Dictionary:
	var roll := chance_roll if chance_roll >= 0.0 else randf() * 100.0
	var is_crit := roll < crit_chance
	var final_damage := base_damage
	if is_crit:
		final_damage = maxi(1, int(round(float(base_damage) * (1.0 + crit_damage_pct / 100.0))))
	return {"damage": final_damage, "is_crit": is_crit}


static func mitigate_damage(
	raw_damage: int,
	evasion: float,
	phys_res: float,
	arcane_res: float = 0.0,
	elemental_res: float = 0.0,
	evasion_roll: float = -1.0
) -> Dictionary:
	if raw_damage <= 0:
		return {"damage": 0, "evaded": false}
	var roll := evasion_roll if evasion_roll >= 0.0 else randf() * 100.0
	if roll < evasion:
		return {"damage": 0, "evaded": true}
	var effective_res := maxf(phys_res, maxf(arcane_res, elemental_res))
	var mitigated := maxi(0, int(round(float(raw_damage) * (1.0 - effective_res / 100.0))))
	return {"damage": mitigated, "evaded": false}
