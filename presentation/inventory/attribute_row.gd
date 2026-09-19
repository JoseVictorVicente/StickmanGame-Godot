class_name AttributeRow
extends HBoxContainer
## Linha de atributo bakeada (título + valor).

@export var row_key: String = ""

@onready var title_label: Label = %TitleLabel
@onready var value_label: Label = %ValueLabel


func set_title(texto: String) -> void:
	if title_label:
		title_label.text = texto


func set_value(texto: String) -> void:
	if value_label:
		value_label.text = texto
