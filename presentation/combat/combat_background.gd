class_name CombatBackground
extends Sprite2D
## Combat backdrop inside the Combate node; covers the stage panel above y=0.

const _Tuning := preload("res://domains/combat/sim/combat_tuning.gd")
const SCROLL_SPEED_PX: float = _Tuning.SCROLL_SPEED_PX
const UV_WRAP := 1.0
## Pixels cropped from the stage viewport edges (zooms into the road art).
const VERTICAL_CROP_TOP_PX := 18.0
const VERTICAL_CROP_BOTTOM_PX := 26.0

var scrolling: bool = false

var _shader_mat: ShaderMaterial
var _scroll_offset: float = 0.0
var _edge_scroll_uv: float = 0.0
var _scroll_speed_override: float = -1.0
var _stage_panel: Control


func _ready() -> void:
	z_index = -15
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	centered = true
	_shader_mat = ShaderMaterial.new()
	_shader_mat.shader = load("res://shaders/floor_scroll.gdshader")
	material = _shader_mat
	_apply_scroll()


func configure_stage_panel(panel: Control) -> void:
	if _stage_panel != panel:
		if _stage_panel != null and _stage_panel.resized.is_connected(_on_stage_resized):
			_stage_panel.resized.disconnect(_on_stage_resized)
		_stage_panel = panel
		if _stage_panel != null and not _stage_panel.resized.is_connected(_on_stage_resized):
			_stage_panel.resized.connect(_on_stage_resized)
	refresh_layout()


func refresh_layout() -> void:
	_apply_layout()
	if _needs_deferred_layout():
		call_deferred("_apply_layout")


func _process(delta: float) -> void:
	if not scrolling or texture == null:
		return
	var tex_width := texture.get_size().x
	_scroll_offset = fmod(_scroll_offset + _effective_scroll_speed() * delta / tex_width, UV_WRAP)
	_apply_scroll()


func set_background_texture(tex: Texture2D) -> void:
	texture = tex
	visible = tex != null
	reset_scroll()
	refresh_layout()


func set_scrolling(active: bool) -> void:
	scrolling = active


func set_scroll_speed_px(speed: float) -> void:
	_scroll_speed_override = maxf(0.0, speed)


func clear_scroll_speed_override() -> void:
	_scroll_speed_override = -1.0


func scroll_speed_px() -> float:
	if not scrolling:
		return 0.0
	return _effective_scroll_speed()


func _effective_scroll_speed() -> float:
	if _scroll_speed_override >= 0.0:
		return _scroll_speed_override
	return SCROLL_SPEED_PX


func set_combat_edge_scroll_px(scroll_px: float) -> void:
	if texture == null or texture.get_size().x <= 0.0:
		_edge_scroll_uv = 0.0
	else:
		_edge_scroll_uv = scroll_px / texture.get_size().x
	_apply_scroll()


func reset_scroll() -> void:
	scrolling = false
	_scroll_offset = 0.0
	_edge_scroll_uv = 0.0
	_apply_scroll()


func walk_surface_y() -> float:
	if texture == null or _stage_panel == null:
		return -62.0
	var layout := _layout_metrics(_stage_panel.size)
	if layout.is_empty():
		return -62.0
	var road_y_tex := texture.get_size().y * 0.5
	return layout["sprite_center_y"] + (road_y_tex * layout["cover_scale"] - layout["scaled_h"] * 0.5)


func _needs_deferred_layout() -> bool:
	if texture == null or _stage_panel == null:
		return false
	return _stage_panel.size.x <= 0.0 or _stage_panel.size.y <= 0.0


func _on_stage_resized() -> void:
	_apply_layout()


func _apply_layout() -> void:
	if texture == null or _stage_panel == null:
		return
	var layout := _layout_metrics(_stage_panel.size)
	if layout.is_empty():
		return
	scale = Vector2.ONE * layout["cover_scale"]
	position = Vector2(0.0, layout["sprite_center_y"])


func _layout_metrics(stage_size: Vector2) -> Dictionary:
	if texture == null or stage_size.x <= 0.0 or stage_size.y <= 0.0:
		return {}
	var tex_size := texture.get_size()
	var crop_top := VERTICAL_CROP_TOP_PX
	var crop_bottom := VERTICAL_CROP_BOTTOM_PX
	var visible_h := maxf(1.0, stage_size.y - crop_top - crop_bottom)
	var cover_scale := maxf(stage_size.x / tex_size.x, visible_h / tex_size.y)
	var scaled_h := tex_size.y * cover_scale
	var sprite_center_y := -(crop_bottom + visible_h * 0.5)
	return {
		"cover_scale": cover_scale,
		"scaled_h": scaled_h,
		"sprite_center_y": sprite_center_y,
	}


func _apply_scroll() -> void:
	if _shader_mat:
		_shader_mat.set_shader_parameter(
			"scroll_offset",
			fmod(_scroll_offset + _edge_scroll_uv, UV_WRAP)
		)
