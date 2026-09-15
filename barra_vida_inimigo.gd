extends ProgressBar
## Barra de vida do inimigo: tween no preenchimento e flash no hit.

const COR_VIDA := Color(0.78, 0.18, 0.16, 1)
const DURACAO_TWEEN := 0.22

@onready var label_hp: Label = $LabelHP

var _hp_atual: int = 0
var _tween_valor: Tween
var _tween_flash: Tween


func _ready() -> void:
	show_percentage = false
	min_value = 0.0
	_aplicar_estilos()
	if label_hp:
		label_hp.mouse_filter = Control.MOUSE_FILTER_IGNORE


func inicializar_barra(hp_max: int) -> void:
	if _tween_valor:
		_tween_valor.kill()
	if _tween_flash:
		_tween_flash.kill()
	max_value = max(1, hp_max)
	_hp_atual = int(max_value)
	value = max_value
	modulate = Color.WHITE
	_atualizar_texto()


func esmaecer() -> void:
	if _tween_valor:
		_tween_valor.kill()
	if _tween_flash:
		_tween_flash.kill()
	_tween_flash = create_tween()
	_tween_flash.tween_property(self, "modulate:a", 0.0, 0.35)


func aparecer() -> void:
	if _tween_flash:
		_tween_flash.kill()
	modulate = Color(1, 1, 1, 0)
	_tween_flash = create_tween()
	_tween_flash.tween_property(self, "modulate", Color.WHITE, 0.28)


func atualizar_vida(hp_atual: int) -> void:
	_hp_atual = clampi(hp_atual, 0, int(max_value))
	_atualizar_texto()
	_animar_preenchimento()
	_piscar_dano()


func _atualizar_texto() -> void:
	if label_hp:
		label_hp.text = "%d / %d" % [_hp_atual, int(max_value)]


func _animar_preenchimento() -> void:
	if _tween_valor:
		_tween_valor.kill()
	_tween_valor = create_tween()
	_tween_valor.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween_valor.tween_property(self, "value", float(_hp_atual), DURACAO_TWEEN)


func _piscar_dano() -> void:
	if _tween_flash:
		_tween_flash.kill()
	modulate = Color(1.8, 1.8, 1.8, 1)
	_tween_flash = create_tween()
	_tween_flash.tween_property(self, "modulate", Color(1.0, 0.25, 0.2, 1), 0.05)
	_tween_flash.tween_property(self, "modulate", Color.WHITE, 0.12)


func _aplicar_estilos() -> void:
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color(0.08, 0.06, 0.05, 1)
	fundo.set_corner_radius_all(4)
	fundo.set_border_width_all(1)
	fundo.border_color = Color(0.42, 0.32, 0.2, 1)

	var preenchimento := StyleBoxFlat.new()
	preenchimento.bg_color = COR_VIDA
	preenchimento.set_corner_radius_all(3)

	add_theme_stylebox_override("background", fundo)
	add_theme_stylebox_override("fill", preenchimento)
