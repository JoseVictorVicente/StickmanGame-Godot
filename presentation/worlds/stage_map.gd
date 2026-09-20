class_name StageMap
extends Control
## Draws the path between trail stages. Stage anchors are laid out in the scene tree.

@onready var map_layer: Control = %MapLayer

var pontos: Array[Vector2] = []


func _ready() -> void:
	resized.connect(_refresh_path)
	if map_layer:
		map_layer.resized.connect(_refresh_path)
		map_layer.child_order_changed.connect(_refresh_path)
	call_deferred("_refresh_path")


func refresh_path() -> void:
	call_deferred("_refresh_path")


func _refresh_path() -> void:
	pontos.clear()
	if map_layer == null:
		queue_redraw()
		return
	for i in range(1, WorldProgress.STAGES_PER_WORLD + 1):
		var anchor := map_layer.get_node_or_null("StageAnchor_%d" % i) as Control
		if anchor == null or not anchor.visible:
			continue
		var center_global := anchor.get_global_rect().get_center()
		pontos.append(get_global_transform().affine_inverse() * center_global)
	queue_redraw()


func _draw() -> void:
	if pontos.size() < 2:
		return
	for i in range(1, pontos.size()):
		draw_line(pontos[i - 1], pontos[i], Color(0.82, 0.68, 0.36, 0.85), 2.0, true)
