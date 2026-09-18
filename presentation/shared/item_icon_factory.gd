class_name ItemIconFactory
extends RefCounted
## Procedural item icons — delegates to ItemData until full render split.


static func create_icon(item: ItemData) -> Texture2D:
	if item == null:
		return null
	if item.has_method("generate_icon"):
		return item.generate_icon()
	if item.has_method("create_icon"):
		return item.create_icon()
	return null
