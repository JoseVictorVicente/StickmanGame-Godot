extends SceneTree
## Verifies key inventory scenes load without parse errors.

const SCENES := [
	"res://presentation/inventory/forge_panel.tscn",
	"res://presentation/inventory/warehouse_panel.tscn",
	"res://presentation/inventory/formation_panel.tscn",
	"res://presentation/inventory/skills_panel.tscn",
	"res://presentation/inventory/inventory_menu.tscn",
]


func _initialize() -> void:
	for caminho in SCENES:
		var packed := load(caminho)
		assert(packed != null, "scene should load: %s" % caminho)
		var instancia := (packed as PackedScene).instantiate()
		assert(instancia != null, "scene should instantiate: %s" % caminho)
		instancia.queue_free()
	print("[TEST PASS] Inventory scene load smoke")
	quit()
