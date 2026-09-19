class_name DamageNumber
extends Label
## Número flutuante de damage: sobe, some e se destrói.

const CENA := preload("res://presentation/combat/damage_number.tscn")
const SUBIDA := 32.0
const DURACAO := 0.7

static var _rng := RandomNumberGenerator.new()


static func spawn(
	pai: Node,
	posicao_global: Vector2,
	damage: int,
	cor: Color = Color(1, 0.92, 0.4, 1),
	is_crit: bool = false
) -> void:
	if pai == null or damage <= 0:
		return
	var numero: DamageNumber = CENA.instantiate()
	pai.add_child(numero)
	numero.global_position = posicao_global + Vector2(_rng.randf_range(-10.0, 10.0), -20.0)
	numero.show_damage(damage, cor, is_crit)


static func spawn_heal(pai: Node, posicao_global: Vector2, amount: int) -> void:
	if pai == null or amount <= 0:
		return
	var numero: DamageNumber = CENA.instantiate()
	pai.add_child(numero)
	numero.global_position = posicao_global + Vector2(_rng.randf_range(-8.0, 8.0), -18.0)
	numero.show_text("+%d" % amount, Color(0.45, 1.0, 0.55, 1), 13)


static func spawn_miss(pai: Node, posicao_global: Vector2, texto: String) -> void:
	if pai == null or texto == "":
		return
	var numero: DamageNumber = CENA.instantiate()
	pai.add_child(numero)
	numero.global_position = posicao_global + Vector2(_rng.randf_range(-8.0, 8.0), -18.0)
	numero.show_text(texto, Color(0.72, 0.82, 0.95, 1), 12)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 40
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func show_damage(damage: int, cor: Color, is_crit: bool = false) -> void:
	show_text(str(damage), cor, 14 if is_crit else 12)


func show_text(label: String, cor: Color, font_size: int = 12) -> void:
	text = label
	modulate = Color(1, 1, 1, 1)
	add_theme_color_override("font_color", cor)
	add_theme_font_size_override("font_size", font_size)
	reset_size()
	pivot_offset = size * 0.5
	position -= size * 0.5
	var destino := position + Vector2(0.0, -SUBIDA)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", destino, DURACAO).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, DURACAO).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)
