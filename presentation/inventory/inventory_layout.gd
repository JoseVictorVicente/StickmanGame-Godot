class_name InventoryLayout
extends Resource
## Proporções e offsets do painel de inventário. Ajuste `base_unit` no .tres para escalar a UI.


const INVENTORY_COLUMNS := 10
const INVENTORY_ROWS := 5

@export_group("Proporções")
@export var base_unit: int = 36
@export var panel_min_size: Vector2 = Vector2(600, 560)
@export var spacing_tight: int = 4
@export var spacing_normal: int = 6
@export var bottom_bar_height: int = 34
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

@export_group("Seções do painel")
@export var offset_area_heroi: Vector2 = Vector2.ZERO
@export var offset_linha_inventario: Vector2 = Vector2.ZERO
@export var offset_menu_inferior: Vector2 = Vector2.ZERO

@export_group("Slots")
@export var inventory_slot_size: Vector2 = Vector2(36, 36)
@export var equip_slot_size: Vector2 = Vector2(36, 36)
@export var character_slot_size: Vector2 = Vector2(36, 36)
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
@export var panel_min_width: float = 600.0
@export var portrait_min_size: Vector2 = Vector2(99, 99)
@export var skill_menu_slot_size: Vector2 = Vector2(40, 40)
@export var party_hero_slot_size: Vector2 = Vector2(58, 72)


func sync_from_base_unit() -> void:
	var u := maxi(1, base_unit)
	inventory_slot_size = Vector2.ONE * u
	equip_slot_size = Vector2.ONE * u
	character_slot_size = Vector2.ONE * u
	skill_menu_slot_size = Vector2.ONE * int(round(float(u) * 1.1))
	portrait_min_size = Vector2.ONE * int(round(float(u) * 2.75))
	party_hero_slot_size = Vector2(int(round(float(u) * 1.6)), int(round(float(u) * 2.0)))
	chrome_button_size = int(round(float(u) * 1.1))
	warehouse_button_min_width = float(int(round(float(u) * 2.0)))
	panel_min_width = panel_min_size.x
	inventory_grid_columns = INVENTORY_COLUMNS
	inventory_grid_rows = INVENTORY_ROWS


func inventory_grid_pixel_size() -> Vector2:
	var cols := maxi(1, inventory_grid_columns)
	var rows := maxi(1, inventory_grid_rows)
	var w := cols * inventory_slot_size.x + (cols - 1) * inventory_grid_h_separation
	var h := rows * inventory_slot_size.y + (rows - 1) * inventory_grid_v_separation
	return Vector2(w, h)


func inventory_row_pixel_size() -> Vector2:
	var grid := inventory_grid_pixel_size()
	var chrome := float(chrome_button_size)
	return Vector2(
		grid.x + chrome + warehouse_button_min_width + spacing_normal * 2.0,
		maxf(grid.y, chrome),
	)


func hero_band_min_height() -> float:
	var portrait_h := portrait_min_size.y
	var skills_h := skill_menu_slot_size.y * 2.0 + float(spacing_normal)
	var attrs_h := 26.0
	var party_h := party_hero_slot_size.y
	return maxf(portrait_h, skills_h) + attrs_h + party_h + float(spacing_tight) * 2.0


func expected_slot_count() -> int:
	return inventory_grid_columns * inventory_grid_rows
