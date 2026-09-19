class_name HeroEquipmentAccess
extends RefCounted
## Runtime lookup for HeroEquipment autoload (headless-test friendly).


static func get_service() -> Node:
	var tree := Engine.get_main_loop()
	if tree is SceneTree:
		return (tree as SceneTree).root.get_node_or_null("HeroEquipment")
	return null
