class_name SettingsPanel
extends PanelContainer
## Settings overlay: volume and locale controls (wired by InventoryMenu).

@onready var close_settings_button: Button = %CloseSettingsButton
@onready var titulo_config: Label = %SettingsTitle
@onready var label_volume_titulo: Label = %VolumeTitleLabel
@onready var slider_volume: HSlider = %VolumeSlider
@onready var label_volume_valor: Label = %VolumeValueLabel
@onready var label_language_title: Label = %LabelLanguageTitle
@onready var option_locale: OptionButton = %OptionLocale
