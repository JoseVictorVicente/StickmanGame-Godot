class_name PanelLayout
extends RefCounted
## Full-bleed overlay alignment for the inventory hub.
## Horizontal side panels are laid out by MenuArea (HBoxContainer); do not position them here.


static func align_overlays(
	host: PanelContainer,
	formacao: Control = null,
	atributos: Control = null,
	skills: Control = null,
	arvore: Control = null,
	overlay_parent: Control = null
) -> void:
	if host == null:
		return
	var parent := overlay_parent if overlay_parent else host
	_overlay_panel(formacao, host, parent)
	_overlay_panel(atributos, host, parent)
	_overlay_panel(skills, host, parent)
	_overlay_panel(arvore, host, parent)


static func window_width(menu_row: Control, margem: int = UiConstants.WINDOW_WIDTH_HORIZONTAL_MARGIN) -> int:
	if menu_row == null:
		return UiConstants.WINDOW_WIDTH
	return margem + int(menu_row.get_combined_minimum_size().x)


static func _overlay_panel(lado: Control, host: Control, parent: Control) -> void:
	if lado == null or not lado.visible or host == null or parent == null:
		return
	if lado.get_parent() != parent:
		return
	lado.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Documented exception: responsive forge jewelry row inside ForgeCanvas.
static func fit_forge_jewelry_row(
	area: HBoxContainer,
	slot_alvo: ItemSlot,
	slot_gema: ItemSlot,
	seta: Control,
	inner_rect: Rect2,
	arrow_width: float
) -> void:
	if area == null or slot_alvo == null or slot_gema == null or inner_rect.size.x < 1.0:
		return
	var separacao := float(area.get_theme_constant("separation"))
	var lado := minf((inner_rect.size.x - arrow_width - separacao * 2.0) * 0.5, inner_rect.size.y)
	lado = maxf(1.0, lado)
	var tamanho_slot := Vector2.ONE * lado
	slot_alvo.custom_minimum_size = tamanho_slot
	slot_gema.custom_minimum_size = tamanho_slot
	area.reset_size()
	if seta:
		seta.custom_minimum_size = Vector2(arrow_width, lado)
		seta.queue_redraw()
