@tool
class_name NavWorldIcon
extends RefCounted
## Builds animated portal icon frames for the worlds nav button.

const FRAME_DURATION := 0.15
const ANIM := "default"

var _frames: SpriteFrames
var _frame_index := 0
var _frame_clock := 0.0


func reset(frames: SpriteFrames) -> void:
	_frames = frames
	_frame_index = 0
	_frame_clock = 0.0


func advance(delta: float) -> Texture2D:
	if _frames == null or not _frames.has_animation(ANIM):
		return null
	var frame_count := _frames.get_frame_count(ANIM)
	if frame_count <= 0:
		return null
	_frame_clock += delta
	if frame_count > 1 and _frame_clock >= FRAME_DURATION:
		_frame_clock = 0.0
		_frame_index = (_frame_index + 1) % frame_count
	return _frames.get_frame_texture(ANIM, _frame_index)
