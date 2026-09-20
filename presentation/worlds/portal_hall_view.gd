class_name PortalHallView
extends VBoxContainer

signal portal_pressed(world: int)

const WorldCatalog := preload("res://data/world_catalog.gd")

@onready var portal_subtitle: Label = %PortalSubtitle
@onready var world_list: VBoxContainer = %WorldList

var _cards: Array = []


func _ready() -> void:
	_cards.clear()
	for i in WorldProgress.TOTAL_WORLDS:
		var card := world_list.get_node_or_null("PortalCard_%d" % (i + 1))
		assert(card != null, "PortalCard_%d missing" % (i + 1))
		var indice := i + 1
		if not card.world_button.get_meta(&"wired", false):
			card.world_button.pressed.connect(_on_portal_pressed.bind(indice))
			card.world_button.set_meta(&"wired", true)
		_cards.append(card)


func refresh_static_texts() -> void:
	portal_subtitle.text = tr(LocaleKeys.PORTALS_SUBTITLE)


func bind_hall(
	current_world: int,
	is_world_unlocked: Callable,
	completed_in_dimension: Callable,
	is_dimension_saved: Callable
) -> void:
	for i in _cards.size():
		var world := i + 1
		var liberado: bool = is_world_unlocked.call(world)
		var atual := world == current_world
		var salvo: bool = is_dimension_saved.call(world)
		var nome := WorldCatalog.dimension_name(world)
		var meta := ""
		if not liberado:
			meta = "🔒"
		elif salvo:
			meta = tr(LocaleKeys.PORTAL_SAVED)
		else:
			var concluidas: int = completed_in_dimension.call(world)
			meta = "⚔ " + (tr(LocaleKeys.PORTAL_PROGRESS_FORMAT) % [
				concluidas,
				WorldProgress.STAGES_PER_WORLD,
			])
		_cards[i].apply_state(nome, atual, not liberado, meta, true)


func _on_portal_pressed(world: int) -> void:
	portal_pressed.emit(world)
