class_name HeroSection
extends HBoxContainer
## Coluna do herói: equipamento, retrato, equipe e formação.

@onready var equip_left: VBoxContainer = %EquipLeft
@onready var equip_right: VBoxContainer = %EquipRight
@onready var gold_panel: Control = %GoldPanel
@onready var gold_label: Label = %GoldLabel
@onready var gold_spacer: Control = %GoldSpacer
@onready var character_portrait: TextureRect = %CharacterPortrait
@onready var character_xp_bar: ProgressBar = %CharacterXpBar
@onready var character_xp_label: Label = %CharacterXpLabel
@onready var character_attributes_button: Button = %CharacterAttributesButton
@onready var hero_card_row: HBoxContainer = %HeroCardRow
@onready var active_column: VBoxContainer = %ActiveColumn
@onready var passive_column: VBoxContainer = %PassiveColumn
@onready var slot_ativa_0: Button = %SlotSkillMenuAtiva0
@onready var slot_ativa_1: Button = %SlotSkillMenuAtiva1
@onready var slot_passiva_0: Button = %SlotSkillMenuPassiva0
@onready var slot_passiva_1: Button = %SlotSkillMenuPassiva1
@onready var character_row: HBoxContainer = %CharacterRow
@onready var character_name_label: Label = %CharacterNameLabel
@onready var character_level_label: Label = %CharacterLevelLabel
@onready var team_ui: TeamSelectionUI = %TeamArea
@onready var hero_visual_section: SectionVisualOffset = %HeroVisualSection
@onready var formation_button_host: SectionVisualOffset = %FormationButtonHost


func apply_layout_offsets(layout: InventoryLayout) -> void:
	if layout == null:
		return
	if hero_visual_section:
		hero_visual_section.set_visual_offset(layout.portrait_region_offset)
	if formation_button_host:
		formation_button_host.set_visual_offset(layout.formation_button_offset)
	if hero_card_row:
		hero_card_row.add_theme_constant_override("separation", int(layout.portrait_controls_spacing))
