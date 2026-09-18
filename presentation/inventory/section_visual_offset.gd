class_name SectionVisualOffset
extends Control
## Desloca o conteúdo filho visualmente, mantendo o espaço reservado no layout.


@export var offset: Vector2 = Vector2(0, -12)

var _conteudo: Control


func set_visual_offset(novo: Vector2) -> void:
	offset = novo
	_refresh()


func _ready() -> void:
	if get_child_count() > 0:
		_conteudo = get_child(0) as Control
	if _conteudo and not _conteudo.resized.is_connected(_refresh):
		_conteudo.resized.connect(_refresh)
	if not resized.is_connected(_refresh):
		resized.connect(_refresh)
	call_deferred("_refresh")


func _refresh() -> void:
	if _conteudo == null:
		return
	var tam := _conteudo.get_combined_minimum_size()
	var largura := tam.x
	if size.x > 1.0:
		largura = maxf(largura, size.x)
	_conteudo.size = Vector2(largura, tam.y)
	_conteudo.position = offset
	custom_minimum_size = tam
	if _conteudo is Container:
		(_conteudo as Container).queue_sort()
