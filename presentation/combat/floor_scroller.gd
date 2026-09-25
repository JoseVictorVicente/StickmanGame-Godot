class_name FloorScroller
extends Sprite2D
## Centered floating combat platform; hero anchor sits at x=0 (platform center).

const _Tuning := preload("res://domains/combat/sim/combat_tuning.gd")
const SCROLL_SPEED_PX: float = _Tuning.SCROLL_SPEED_PX
const PLATFORM_SCALE := 1.0
const UV_WRAP := 1.0

var scrolling: bool = false

var _shader_mat: ShaderMaterial
var _scroll_offset: float = 0.0
var _scroll_speed_override: float = -1.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	centered = true
	z_index = -10
	_shader_mat = ShaderMaterial.new()
	_shader_mat.shader = load("res://shaders/floor_scroll.gdshader")
	material = _shader_mat
	_apply_layout()


func _process(delta: float) -> void:
	if not scrolling or texture == null:
		return
	var tex_width := texture.get_size().x
	_scroll_offset = fmod(_scroll_offset + _effective_scroll_speed() * delta / tex_width, UV_WRAP)
	_apply_scroll()


func platform_top_y() -> float:
	if texture == null:
		return -48.0 * PLATFORM_SCALE
	return position.y - _display_height() * 0.5


func platform_half_width() -> float:
	if texture == null:
		return 128.0
	return texture.get_size().x * scale.x * 0.5


func set_scrolling(active: bool) -> void:
	scrolling = active


func set_scroll_speed_px(speed: float) -> void:
	_scroll_speed_override = maxf(0.0, speed)


func clear_scroll_speed_override() -> void:
	_scroll_speed_override = -1.0


func _effective_scroll_speed() -> float:
	if _scroll_speed_override >= 0.0:
		return _scroll_speed_override
	return SCROLL_SPEED_PX


func reset_scroll() -> void:
	scrolling = false
	_scroll_offset = 0.0
	_apply_scroll()


func set_floor_texture(tex: Texture2D) -> void:
	if tex == null:
		return
	texture = tex
	_apply_layout()
	reset_scroll()


func _display_height() -> float:
	if texture == null:
		return 0.0
	return texture.get_size().y * scale.y


func _apply_layout() -> void:
	if texture == null:
		return
	scale = Vector2(PLATFORM_SCALE, PLATFORM_SCALE)
	var height := _display_height()
	position = Vector2(0.0, -height * 0.5)


func _apply_scroll() -> void:
	if _shader_mat:
		_shader_mat.set_shader_parameter("scroll_offset", _scroll_offset)
