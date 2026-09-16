class_name DamageNumber
extends Label
## Número flutuante de dano: sobe, some e se destrói.

const CENA := preload("res://combate/damage_number.tscn")
const SUBIDA := 32.0
const DURACAO := 0.7

static var _rng := RandomNumberGenerator.new()


static func spawn(pai: Node, posicao_global: Vector2, dano: int, cor: Color = Color(1, 0.92, 0.4, 1)) -> void:
	if pai == null or dano <= 0:
		return
	var numero: DamageNumber = CENA.instantiate()
	pai.add_child(numero)
	numero.global_position = posicao_global + Vector2(_rng.randf_range(-10.0, 10.0), -20.0)
	numero.exibir(dano, cor)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 40
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func exibir(dano: int, cor: Color) -> void:
	text = str(dano)
	modulate = Color(1, 1, 1, 1)
	add_theme_color_override("font_color", cor)
	reset_size()
	pivot_offset = size * 0.5
	position -= size * 0.5
	var destino := position + Vector2(0.0, -SUBIDA)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", destino, DURACAO).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, DURACAO).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)
