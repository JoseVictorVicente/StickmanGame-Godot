class_name UiConstants
extends RefCounted
## Shared overlay and inventory hub layout constants.


const WINDOW_WIDTH := 960
const WINDOW_HEIGHT := 860
const STAGE_WIDTH_HALF := 240
const STAGE_HEIGHT := 200
const BATTLE_PANEL_HEIGHT := 100
const BATTLE_PANEL_BOTTOM_MARGIN := 8
const PALCO_BASE_JANELA := BATTLE_PANEL_HEIGHT + BATTLE_PANEL_BOTTOM_MARGIN
const COMBAT_STAGE_TOP_OFFSET := PALCO_BASE_JANELA + STAGE_HEIGHT
const COMBAT_RESERVED_SPACE := float(COMBAT_STAGE_TOP_OFFSET + 88)
const UI_TOP_MARGIN := 8.0
const MENU_ROW_SEPARATION := 8
const WINDOW_WIDTH_HORIZONTAL_MARGIN := 40
## Inset for worlds_bg-style panel frames (matches StyleBoxTexture texture margins).
const PANEL_TEXTURE_MARGIN_LEFT := 35
const PANEL_TEXTURE_MARGIN_TOP := 28
const PANEL_TEXTURE_MARGIN_RIGHT := 31
const PANEL_TEXTURE_MARGIN_BOTTOM := 26
## Measured from `sprites/ui/inventory_bg.png` inner content (515×512 texture).
const INVENTORY_BG_INNER_WIDTH := 451.0
const INVENTORY_BG_INNER_HEIGHT := 458.0
const INVENTORY_BG_UPPER_BAND_RATIO := 222.0 / INVENTORY_BG_INNER_HEIGHT
const INVENTORY_BG_GRID_BAND_RATIO := 166.0 / INVENTORY_BG_INNER_HEIGHT
const INVENTORY_BG_NAV_BAND_RATIO := 52.0 / INVENTORY_BG_INNER_HEIGHT


static func inventory_bg_inner_aspect() -> float:
	return INVENTORY_BG_INNER_HEIGHT / INVENTORY_BG_INNER_WIDTH


static func max_hub_panel_pixel_height() -> float:
	return float(WINDOW_HEIGHT) - COMBAT_RESERVED_SPACE - UI_TOP_MARGIN
