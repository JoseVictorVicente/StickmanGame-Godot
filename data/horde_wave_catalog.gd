class_name HordeWaveCatalog
extends RefCounted
## Optional multi-enemy wave rosters keyed by world:stage.

const _ROSTERS: Dictionary = {
	"1:2": {
		1: {"enemy_id": "imp_red", "count": 7},
		2: {"enemy_id": "cerberus_pup", "count": 7},
		3: {"enemy_id": "dark_elite_solo", "count": 3},
		4: {"enemy_id": "flying_demon_wave1", "count": 3},
	},
}


static func resolve(world: int, stage: int, wave: int) -> Dictionary:
	var key := "%d:%d" % [world, stage]
	if not _ROSTERS.has(key):
		return {}
	var stage_roster: Dictionary = _ROSTERS[key]
	if not stage_roster.has(wave):
		return {}
	var spec: Variant = stage_roster[wave]
	if spec is Dictionary:
		return (spec as Dictionary).duplicate()
	return {}
