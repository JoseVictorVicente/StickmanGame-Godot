class_name TrailMapLayout
extends RefCounted
## Trail stage UVs on the map **texture** (0–1). Edit data/trail_paths/dim_*.tres in the inspector.

const _PATHS: Array[TrailPathData] = [
	preload("res://data/trail_paths/dim_1.tres"),
	preload("res://data/trail_paths/dim_2.tres"),
	preload("res://data/trail_paths/dim_3.tres"),
	preload("res://data/trail_paths/dim_4.tres"),
	preload("res://data/trail_paths/dim_5.tres"),
]


static func stage_uv(world_id: int, stage: int) -> Vector2:
	var world := clampi(world_id, 1, WorldProgress.TOTAL_WORLDS)
	return _PATHS[world - 1].stage_uv(stage)
