class_name RealmBriefingView
extends VBoxContainer

signal enter_portal_pressed()

const WorldCatalog := preload("res://data/world_catalog.gd")
const BANNER_RATIO := 0.42
const BANNER_MAX_HEIGHT := 160.0
const BANNER_MIN_HEIGHT := 80.0

@onready var briefing_art_frame: PanelContainer = %BriefingArtFrame
@onready var briefing_banner: TextureRect = %BriefingBanner
@onready var briefing_title: Label = %BriefingTitle
@onready var briefing_lore: Label = %BriefingLore
@onready var briefing_demon_king: Label = %BriefingDemonKing
@onready var enter_portal_button: Button = %EnterPortalButton

var _panel_height := -1
var _header_height := -1
var _cta_height := -1


func _ready() -> void:
	enter_portal_button.pressed.connect(func() -> void: enter_portal_pressed.emit())
	resized.connect(_on_resized)


func bind_briefing(world: int, panel_height: int, header_height: int, cta_height: int) -> void:
	_panel_height = panel_height
	_header_height = header_height
	_cta_height = cta_height
	briefing_banner.texture = WorldCatalog.briefing_texture(world)
	var nome := WorldCatalog.dimension_name(world)
	briefing_title.text = tr(LocaleKeys.DIMENSION_DECAYED_PREFIX) % nome
	briefing_lore.text = WorldCatalog.briefing_text(world)
	briefing_demon_king.text = WorldCatalog.demon_king_name(world)
	enter_portal_button.text = tr(LocaleKeys.BTN_ENTER_PORTAL)
	_apply_banner_layout()


func refresh_static_texts() -> void:
	enter_portal_button.text = tr(LocaleKeys.BTN_ENTER_PORTAL)


func _on_resized() -> void:
	_apply_banner_layout()


func _apply_banner_layout() -> void:
	if not is_visible_in_tree() or briefing_art_frame == null:
		return
	var usable := size.y
	if _panel_height > 0:
		usable = float(_panel_height)
		if _header_height > 0:
			usable -= float(_header_height)
		if _cta_height > 0:
			usable -= float(_cta_height)
		usable -= 28.0
	usable = maxf(usable, 200.0)
	var banner_h := clampf(usable * BANNER_RATIO, BANNER_MIN_HEIGHT, BANNER_MAX_HEIGHT)
	briefing_art_frame.custom_minimum_size.y = banner_h
	briefing_banner.custom_minimum_size.y = maxf(banner_h - 8.0, 72.0)
