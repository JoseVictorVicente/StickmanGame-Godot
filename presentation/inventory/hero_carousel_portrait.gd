class_name HeroCarouselPortrait
extends TextureButton
## Hero portrait for the skills carousel — no skill frame, sprite only.


func _ready() -> void:
	ignore_texture_size = true
	stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_COVERED
	focus_mode = Control.FOCUS_NONE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func apply_hero(hero_texture: Texture2D, slot_size: Vector2, dimmed: bool = false) -> void:
	custom_minimum_size = slot_size
	disabled = hero_texture == null
	mouse_filter = Control.MOUSE_FILTER_STOP if hero_texture != null else Control.MOUSE_FILTER_IGNORE
	modulate = Color(1, 1, 1, 0.6) if dimmed else Color.WHITE
	texture_normal = hero_texture
	texture_hover = hero_texture
	texture_pressed = hero_texture
	texture_disabled = hero_texture
