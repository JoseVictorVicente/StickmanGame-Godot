class_name TrailPathData
extends Resource
## Normalized UV points (0–1) on the trail map texture. Stage 1 = path start (bottom).

@export var stage_points: PackedVector2Array = PackedVector2Array()


func stage_uv(stage: int) -> Vector2:
	var index := clampi(stage, 1, stage_points.size()) - 1
	return stage_points[index]
