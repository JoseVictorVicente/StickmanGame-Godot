class_name HealEffect
extends CombatEffectResource
## Heal allies in combat (party, self, or lowest HP).

@export var heal_pct_max_hp: float = 15.0
## party | self | lowest_hp
@export var target_scope: String = "party"
