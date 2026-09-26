class_name FormationHeroGrid
extends GridContainer
## Grade de heróis desbloqueáveis na formação. Botões bakeados no .tscn.

const PARTY_HERO_BUTTON_SCENE := preload("res://presentation/inventory/party_hero_slot_button.tscn")
const COLUMNS := 3
const DEFAULT_BUTTON_SIZE := Vector2(86, 98)

const CLASS_IDS: Array[String] = [
	"priest", "tank", "barbarian", "archer", "mage", "warrior",
]


func hero_buttons() -> Array[Button]:
	return _collect_buttons()


func button_for_class(class_id: String) -> Button:
	for botao in _collect_buttons():
		if str(botao.get_meta("class_id", "")) == class_id:
			return botao
	return null


func ensure_heroes(class_ids: Array[String] = CLASS_IDS) -> Array[Button]:
	if get_child_count() == class_ids.size() and _children_are_hero_buttons():
		return _collect_buttons()

	_clear_children()
	columns = COLUMNS
	for class_id in class_ids:
		var botao := PARTY_HERO_BUTTON_SCENE.instantiate() as Button
		botao.name = "Hero_%s" % class_id
		botao.custom_minimum_size = DEFAULT_BUTTON_SIZE
		botao.set_meta("class_id", class_id)
		add_child(botao)
	return _collect_buttons()


func setup(connect_button: Callable) -> Array[Button]:
	var botoes := hero_buttons()
	if botoes.is_empty():
		botoes = ensure_heroes()
	for botao in botoes:
		_connect_button_once(botao, connect_button)
	return botoes


func _connect_button_once(botao: Button, connect_button: Callable) -> void:
	if botao.get_meta(&"formation_hero_wired", false):
		return
	if connect_button.is_valid():
		connect_button.call(botao)
	botao.set_meta(&"formation_hero_wired", true)


func _children_are_hero_buttons() -> bool:
	for filho in get_children():
		if not filho is Button:
			return false
		if not filho.has_meta("class_id"):
			return false
	return get_child_count() > 0


func _collect_buttons() -> Array[Button]:
	var lista: Array[Button] = []
	for filho in get_children():
		if filho is Button:
			lista.append(filho as Button)
	return lista


func _clear_children() -> void:
	for filho in get_children():
		filho.queue_free()
