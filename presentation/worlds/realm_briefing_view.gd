class_name RealmBriefingView
extends VBoxContainer

signal enter_portal_pressed()

const WorldCatalog := preload("res://data/world_catalog.gd")

@onready var briefing_banner: TextureRect = %BriefingBanner
@onready var briefing_title: Label = %BriefingTitle
@onready var briefing_lore: Label = %BriefingLore
@onready var briefing_demon_king: Label = %BriefingDemonKing
@onready var enter_portal_button: Button = %EnterPortalButton


func _ready() -> void:
	enter_portal_button.pressed.connect(func() -> void: enter_portal_pressed.emit())


func bind_briefing(world: int) -> void:
	briefing_banner.texture = WorldCatalog.briefing_texture(world)
	var nome := WorldCatalog.dimension_name(world)
	briefing_title.text = tr(LocaleKeys.DIMENSION_DECAYED_PREFIX) % nome
	briefing_lore.text = WorldCatalog.briefing_text(world)
	briefing_demon_king.text = WorldCatalog.demon_king_name(world)
	enter_portal_button.text = tr(LocaleKeys.BTN_ENTER_PORTAL)


func refresh_static_texts() -> void:
	enter_portal_button.text = tr(LocaleKeys.BTN_ENTER_PORTAL)
