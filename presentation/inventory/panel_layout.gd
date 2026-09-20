class_name PanelLayout
extends RefCounted
## Full-bleed overlay alignment for the inventory hub.
## Horizontal side panels are laid out by MenuArea (HBoxContainer); do not position them here.


static func align_overlays(
	host: PanelContainer,
	formacao: Control = null,
	atributos: Control = null,
	skills: Control = null,
	arvore: Control = null
) -> void:
	if host == null:
		return
	_overlay_panel(formacao, host)
	_overlay_panel(atributos, host)
	_overlay_panel(skills, host)
	_overlay_panel(arvore, host)


static func window_width(menu_row: Control, margem: int = UiConstants.WINDOW_WIDTH_HORIZONTAL_MARGIN) -> int:
	if menu_row == null:
		return UiConstants.WINDOW_WIDTH
	return margem + int(menu_row.get_combined_minimum_size().x)


static func _overlay_panel(lado: Control, host: Control) -> void:
	if lado == null or not lado.visible or host == null:
		return
	if lado.get_parent() != host:
		return
	lado.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
