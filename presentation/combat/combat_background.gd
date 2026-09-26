class_name CombatBackground
extends Sprite2D
## Combat backdrop inside the Combate node; covers the stage panel above y=0.

const _Tuning := preload("res://domains/combat/sim/combat_tuning.gd")
const SCROLL_SPEED_PX: float = _Tuning.SCROLL_SPEED_PX
const UV_WRAP := 1.0

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
	var stage_h := _stage_panel.size.y
	var stage_w := _stage_panel.size.x
	if stage_h <= 0.0 or stage_w <= 0.0:
		return -62.0
	var tex_size := texture.get_size()
	var cover_scale := maxf(stage_w / tex_size.x, stage_h / tex_size.y)
	var road_y_tex := tex_size.y * 0.5
	var scaled_h := tex_size.y * cover_scale
	var crop_top := (scaled_h - stage_h) * 0.5
	var road_y_from_top := road_y_tex * cover_scale - crop_top
	return -(stage_h - road_y_from_top)


func _needs_deferred_layout() -> bool:
	if texture == null or _stage_panel == null:
		return false
	return _stage_panel.size.x <= 0.0 or _stage_panel.size.y <= 0.0


func _on_stage_resized() -> void:
	_apply_layout()


func _apply_layout() -> void:
	if texture == null or _stage_panel == null:
		return
	var stage_size := _stage_panel.size
	if stage_size.x <= 0.0 or stage_size.y <= 0.0:
		return
	var tex_size := texture.get_size()
	var cover_scale := maxf(stage_size.x / tex_size.x, stage_size.y / tex_size.y)
	scale = Vector2.ONE * cover_scale
	position = Vector2(0.0, -stage_size.y * 0.5)


func _apply_scroll() -> void:
	if _shader_mat:
		_shader_mat.set_shader_parameter(
			"scroll_offset",
			fmod(_scroll_offset + _edge_scroll_uv, UV_WRAP)
		)
