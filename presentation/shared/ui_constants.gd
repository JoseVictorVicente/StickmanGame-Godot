class_name UiConstants
extends RefCounted
## Shared overlay and inventory hub layout constants.


const WINDOW_WIDTH := 960
const WINDOW_HEIGHT := 860
const COMBAT_RESERVED_SPACE := 320.0
const UI_TOP_MARGIN := 8.0
const MENU_ROW_SEPARATION := 8
const WINDOW_WIDTH_HORIZONTAL_MARGIN := 40
## Inset for worlds_bg-style panel frames (matches StyleBoxTexture texture margins).
const PANEL_TEXTURE_MARGIN_LEFT := 10
const PANEL_TEXTURE_MARGIN_TOP := 19
const PANEL_TEXTURE_MARGIN_RIGHT := 10
const PANEL_TEXTURE_MARGIN_BOTTOM := 6


static func max_hub_panel_pixel_height() -> float:
	return float(WINDOW_HEIGHT) - COMBAT_RESERVED_SPACE - UI_TOP_MARGIN
