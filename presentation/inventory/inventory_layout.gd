@tool
class_name InventoryLayout
extends Resource
## Proporções e offsets do painel de inventário. Ajuste `base_unit` no .tres para escalar a UI.


const INVENTORY_COLUMNS := 10
const INVENTORY_ROWS := 5
const INVENTORY_EXPAND_SLOTS := 1
const HUB_HEADER_BAND_HEIGHT := 40.0

@export_group("Proporções")
@export var base_unit: int = 42
@export var panel_min_size: Vector2 = Vector2(477, 578)
@export var spacing_tight: int = 4
@export var spacing_normal: int = 6
@export var bottom_bar_height: int = 34
@export var formation_bar_height: int = 0
@export var sort_toolbar_height: int = 40
@export var sort_button_scale: float = 1.5
@export var hub_lower_inset_top: int = 4
@export var hub_lower_inset_bottom: int = 0
@export var inventory_scroll_max_height: float = 264.0
@export var chrome_button_size: int = 40
@export var warehouse_button_min_width: float = 72.0

@export_group("Tipografia")
@export var font_nav: int = 11
@export var font_label: int = 12
@export var font_gold: int = 13
@export var nav_icon_max_width: int = 16

@export_group("Character column")
@export var portrait_region_offset: Vector2 = Vector2(0, -12)
@export var formation_button_offset: Vector2 = Vector2(0, -14)
@export var portrait_controls_spacing: float = 2.0
@export var portrait_height_extra: int = 10
@export var portrait_width_extra: int = 10
@export var pet_slot_width_scale: float = 0.88
@export var pet_slot_height_slot_units: float = 1.55

@export_group("Seções do painel")
@export var offset_area_heroi: Vector2 = Vector2.ZERO
@export var offset_linha_inventario: Vector2 = Vector2.ZERO
@export var offset_menu_inferior: Vector2 = Vector2.ZERO

@export_group("Slots")
@export var inventory_slot_size: Vector2 = Vector2(42, 42)
@export var equip_slot_size: Vector2 = Vector2(42, 42)
@export var character_slot_size: Vector2 = Vector2(42, 42)
@export var icon_margin: float = 4.0

@export_group("Grade de equipamento")
@export var equip_grid_columns: int = 2
@export var equip_grid_h_separation: int = 4
@export var equip_grid_v_separation: int = 3

@export_group("Grade de inventário")
@export var inventory_grid_columns: int = INVENTORY_COLUMNS
@export var inventory_grid_rows: int = INVENTORY_ROWS
@export var inventory_grid_h_separation: int = 2
@export var inventory_grid_v_separation: int = 2

@export_group("Painel principal")
@export var panel_min_width: float = 477.0
@export var portrait_min_size: Vector2 = Vector2(99, 99)
@export var skill_menu_slot_size: Vector2 = Vector2(42, 42)
@export var party_hero_slot_size: Vector2 = Vector2(42, 42)


static func duplicate_synced(source: InventoryLayout) -> InventoryLayout:
	if source == null:
		return null
	var dup: InventoryLayout = source.duplicate()
	if dup.get_script() == null:
		return dup
	dup.sync_from_base_unit()
	return dup


func sync_from_base_unit() -> void:
	var u := maxi(1, base_unit)
	inventory_slot_size = Vector2.ONE * u
	equip_slot_size = Vector2.ONE * u
	character_slot_size = Vector2.ONE * u
	skill_menu_slot_size = Vector2.ONE * u
	party_hero_slot_size = Vector2.ONE * u
	portrait_min_size = portrait_pixel_size()
	chrome_button_size = int(round(float(u) * 1.1))
	warehouse_button_min_width = float(int(round(float(u) * 2.0)))
	inventory_grid_columns = INVENTORY_COLUMNS
	inventory_grid_rows = INVENTORY_ROWS
	fit_panel_to_viewport()
	panel_min_width = panel_pixel_width()
	panel_min_size.x = panel_min_width
	panel_min_size.y = panel_pixel_height()


func equip_block_pixel_size(cols: int, rows: int) -> Vector2:
	var c := maxi(1, cols)
	var r := maxi(1, rows)
	var w := c * equip_slot_size.x + float(c - 1) * float(equip_grid_h_separation)
	var h := r * equip_slot_size.y + float(r - 1) * float(equip_grid_v_separation)
	return Vector2(w, h)


func left_zone_pixel_size() -> Vector2:
	return equip_block_pixel_size(3, 4)


func hero_equip_left_core_width() -> float:
	var equip := equip_block_pixel_size(2, 4)
	var active_w := equip_slot_size.x + float(equip_grid_h_separation)
	return equip.x + active_w


func hero_equip_left_panel_size() -> Vector2:
	var equip := equip_block_pixel_size(2, 4)
	return Vector2(
		hero_equip_left_core_width() + hero_row_leading_slack(),
		maxf(equip.y, equip_block_pixel_size(1, 2).y)
	)


func hero_character_panel_size() -> Vector2:
	return center_column_pixel_size()


func hero_equip_right_panel_size() -> Vector2:
	return right_zone_pixel_size()


func hub_upper_row_size() -> Vector2:
	return hero_row_pixel_size()


func inventory_panel_size() -> Vector2:
	return inventory_row_pixel_size()


func hub_body_height() -> float:
	return hub_inner_height()


func equip_right_columns_pixel_size() -> Vector2:
	var jewelry_h := equip_block_pixel_size(2, 2).y
	var pet_h := pet_slot_pixel_size().y
	var sort_h := sort_button_pixel_size().y
	var h := jewelry_h + float(spacing_tight) + pet_h + float(spacing_tight) + sort_h
	return Vector2(left_zone_pixel_size().x, h)


func right_zone_pixel_size() -> Vector2:
	var passive_h := equip_block_pixel_size(1, 2).y
	return Vector2(
		left_zone_pixel_size().x + hero_row_trailing_slack(),
		maxf(passive_h, equip_right_columns_pixel_size().y)
	)


func portrait_pixel_size() -> Vector2:
	var party_row_w := equip_block_pixel_size(3, 1).x
	var width_extra := float(portrait_width_extra) * float(base_unit) / 42.0
	var left_h := equip_block_pixel_size(2, 4).y
	var party_h := party_hero_slot_size.y
	var height_extra := float(portrait_height_extra) * float(base_unit) / 42.0
	var portrait_h := maxf(
		equip_slot_size.y * 2.0 + height_extra,
		left_h - party_h - float(spacing_tight) + height_extra
	)
	return Vector2(party_row_w + width_extra, portrait_h)


func pet_slot_pixel_size() -> Vector2:
	var jewelry_w := equip_block_pixel_size(2, 1).x
	var w := jewelry_w * pet_slot_width_scale
	var h := equip_slot_size.y * pet_slot_height_slot_units + float(equip_grid_v_separation)
	return Vector2(w, h)


func sort_button_pixel_size() -> Vector2:
	var pet_w := pet_slot_pixel_size().x
	var side := minf(equip_slot_size.x * sort_button_scale, pet_w)
	return Vector2(side, side)


func center_column_pixel_size() -> Vector2:
	var portrait := portrait_pixel_size()
	return Vector2(portrait.x, portrait.y + float(spacing_tight) + party_hero_slot_size.y)


func hero_row_core_width() -> float:
	return (
		hero_equip_left_core_width()
		+ float(spacing_tight)
		+ center_column_pixel_size().x
		+ float(spacing_tight)
		+ left_zone_pixel_size().x
	)


func hero_row_width_slack() -> float:
	return maxf(0.0, hub_content_pixel_width() - hero_row_core_width())


func hero_row_leading_slack() -> float:
	return hero_row_width_slack() * 0.5


func hero_row_trailing_slack() -> float:
	return hero_row_width_slack() - hero_row_leading_slack()


func hero_row_inner_width() -> float:
	return hero_row_core_width() + hero_row_width_slack()


func hero_row_pixel_size() -> Vector2:
	var row_h := maxf(
		left_zone_pixel_size().y,
		maxf(center_column_pixel_size().y, right_zone_pixel_size().y)
	)
	return Vector2(hub_content_pixel_width(), row_h)


func inventory_grid_pixel_size() -> Vector2:
	var cols := maxi(1, inventory_grid_columns)
	var rows := maxi(1, inventory_grid_rows)
	var w := cols * inventory_slot_size.x + (cols - 1) * inventory_grid_h_separation
	var h := rows * inventory_slot_size.y + (rows - 1) * inventory_grid_v_separation
	return Vector2(w, h)


func inventory_row_pixel_size() -> Vector2:
	var grid := inventory_grid_pixel_size()
	var grid_band_h := minf(grid.y, inventory_scroll_max_height)
	var row_h := float(hub_lower_inset_top) + grid_band_h
	return Vector2(grid.x, row_h)


func hub_content_pixel_width() -> float:
	return inventory_grid_pixel_size().x


func panel_pixel_width() -> float:
	return hub_content_pixel_width() + float(
		UiConstants.PANEL_TEXTURE_MARGIN_LEFT + UiConstants.PANEL_TEXTURE_MARGIN_RIGHT
	)


func max_hub_panel_pixel_height() -> float:
	return UiConstants.max_hub_panel_pixel_height()


func hub_lower_nav_gap() -> float:
	return float(spacing_tight)


func hub_lower_fixed_height() -> float:
	return (
		float(hub_lower_inset_top)
		+ float(bottom_bar_height)
		+ hub_lower_nav_gap()
		+ float(hub_lower_inset_bottom)
	)


func hub_lower_band_height() -> float:
	return inventory_row_pixel_size().y + float(bottom_bar_height) + hub_lower_nav_gap() + float(hub_lower_inset_bottom)


func hub_chrome_bar_height() -> float:
	return HUB_HEADER_BAND_HEIGHT + float(spacing_tight)


func hub_upper_band_height() -> float:
	return float(spacing_normal) + hero_band_min_height() + float(spacing_normal)


func hub_inner_height() -> float:
	return hub_upper_band_height() + hub_lower_band_height()


func panel_pixel_height() -> float:
	return hub_inner_height() + float(
		UiConstants.PANEL_TEXTURE_MARGIN_TOP + UiConstants.PANEL_TEXTURE_MARGIN_BOTTOM
	)


func hub_column_pixel_height() -> float:
	return hub_chrome_bar_height() + panel_pixel_height()


## Keeps the hub column (chrome bar + panel) inside the overlay band above combat.
## Shrinks visible grid rows via `inventory_scroll_max_height` when slot sizes grow.
func fit_panel_to_viewport() -> bool:
	var max_h := max_hub_panel_pixel_height()
	var full_grid_h := inventory_grid_pixel_size().y
	var desired_scroll := minf(full_grid_h, inventory_scroll_max_height)
	inventory_scroll_max_height = desired_scroll
	if hub_column_pixel_height() <= max_h + 0.5:
		return false
	var max_panel_h := max_h - hub_chrome_bar_height()
	var margins := float(
		UiConstants.PANEL_TEXTURE_MARGIN_TOP + UiConstants.PANEL_TEXTURE_MARGIN_BOTTOM
	)
	var max_inner := max_panel_h - margins
	var max_grid_band := max_inner - hub_upper_band_height() - hub_lower_fixed_height()
	var min_row_h := inventory_slot_size.y
	if max_grid_band < min_row_h - 0.5:
		push_warning(
			"InventoryLayout: base_unit=%d exceeds overlay viewport; reduce base_unit or window layout."
			% base_unit
		)
		inventory_scroll_max_height = minf(desired_scroll, min_row_h)
		return true
	inventory_scroll_max_height = clampf(max_grid_band, min_row_h, desired_scroll)
	return inventory_scroll_max_height < desired_scroll - 0.5


func hero_band_min_height() -> float:
	return hero_row_pixel_size().y + float(spacing_tight)


func expected_slot_count() -> int:
	return inventory_grid_columns * inventory_grid_rows


func usable_inventory_slot_count() -> int:
	return maxi(0, expected_slot_count() - INVENTORY_EXPAND_SLOTS)
