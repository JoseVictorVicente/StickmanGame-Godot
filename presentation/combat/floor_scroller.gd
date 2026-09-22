class_name FloorScroller
extends TextureRect
## Parallax floor scroll during the auto-runner phase (heroes stay fixed on screen).

const SCROLL_SPEED_PX := 140.0
const UV_WRAP := 1.0

var scrolling: bool = false

var _shader_mat: ShaderMaterial
var _scroll_offset: float = 0.0


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_shader_mat = ShaderMaterial.new()
	_shader_mat.shader = load("res://shaders/floor_scroll.gdshader")
	material = _shader_mat
	_apply_scroll()


func _process(delta: float) -> void:
	if not scrolling:
		return
	_scroll_offset = fmod(_scroll_offset + SCROLL_SPEED_PX * delta / 480.0, UV_WRAP)
	_apply_scroll()


func set_scrolling(active: bool) -> void:
	scrolling = active


func reset_scroll() -> void:
	scrolling = false
	_scroll_offset = 0.0
	_apply_scroll()


func _apply_scroll() -> void:
	if _shader_mat:
		_shader_mat.set_shader_parameter("scroll_offset", _scroll_offset)
