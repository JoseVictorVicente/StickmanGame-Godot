extends SceneTree
## Captures inventory_menu hub screenshots for Cursor visual layout review.
## Run with display (not --headless): godot --path . -s res://tests/inventory_menu_visual_capture.gd


const LayoutStates := preload("res://tests/inventory_menu_layout_states.gd")
const MENU_SCENE_PATH := "res://presentation/inventory/inventory_menu.tscn"
const OUTPUT_DIR := "res://artifacts/inventory_layout"
const TEST_HOST_GROUP := "inventory_layout_test_host"


var _menu_scene: PackedScene
var _test_viewport: SubViewport


func _initialize() -> void:
	call_deferred("_run_capture")


func _run_capture() -> void:
	await process_frame
	_menu_scene = load(MENU_SCENE_PATH) as PackedScene
	if _menu_scene == null:
		_fail("inventory menu scene should load")
		return
	DisplayServer.window_set_size(
		Vector2i(UiConstants.WINDOW_WIDTH, UiConstants.WINDOW_HEIGHT)
	)
	var output_dir := ProjectSettings.globalize_path(OUTPUT_DIR)
	var dir_err := DirAccess.make_dir_recursive_absolute(output_dir)
	if dir_err != OK:
		_fail("could not create output dir: %s (err %d)" % [output_dir, dir_err])
		return

	var manifest: Dictionary = {
		"window_size": {
			"w": UiConstants.WINDOW_WIDTH,
			"h": UiConstants.WINDOW_HEIGHT,
		},
		"godot_version": Engine.get_version_info(),
		"timestamp": Time.get_datetime_string_from_system(true),
		"states": [],
	}

	await _clear_test_hosts()
	_test_viewport = SubViewport.new()
	_test_viewport.size = Vector2i(UiConstants.WINDOW_WIDTH, UiConstants.WINDOW_HEIGHT)
	_test_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_test_viewport.add_to_group(TEST_HOST_GROUP)
	root.add_child(_test_viewport)
	var host := _create_host()
	_test_viewport.add_child(host)
	await process_frame
	var menu := LayoutStates.instantiate_menu(host, _menu_scene)
	if menu == null:
		_fail("inventory menu scene should instantiate")
		return
	if not menu.is_node_ready():
		await menu.ready
	await process_frame
	await process_frame

	for state_id in LayoutStates.STATE_IDS:
		LayoutStates.reset_menu(menu)
		LayoutStates.apply_state(menu, state_id)
		await LayoutStates.settle(self, menu)
		var capture_w := UiConstants.WINDOW_WIDTH
		if menu.has_method("width_for_window"):
			capture_w = maxi(UiConstants.WINDOW_WIDTH, int(menu.call("width_for_window")))
		_resize_capture_host(host, capture_w)
		for _i in 3:
			await process_frame
		_test_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw

		var texture := _test_viewport.get_texture()
		if texture == null:
			_fail("viewport texture missing for state %s" % state_id)
			return
		var image := texture.get_image()
		if image == null or image.is_empty():
			_fail("blank capture for state %s (use Godot without --headless)" % state_id)
			return

		var png_path := output_dir.path_join("%s.png" % state_id)
		var save_err := image.save_png(png_path)
		if save_err != OK:
			_fail("save_png failed for %s (err %d)" % [png_path, save_err])
			return

		manifest["states"].append({
			"state_id": state_id,
			"path": png_path,
		})
		print("captured: %s" % png_path)

	var manifest_path := output_dir.path_join("manifest.json")
	var manifest_file := FileAccess.open(manifest_path, FileAccess.WRITE)
	if manifest_file == null:
		_fail("could not write manifest at %s" % manifest_path)
		return
	manifest_file.store_string(JSON.stringify(manifest, "\t"))
	manifest_file.close()

	print("INVENTORY_MENU_VISUAL_CAPTURE_OK")
	print("manifest: %s" % manifest_path)
	for entry in manifest["states"]:
		print("png: %s" % entry["path"])
	quit(0)


func _resize_capture_host(host: Control, width: int) -> void:
	var size := Vector2(width, UiConstants.WINDOW_HEIGHT)
	_test_viewport.size = Vector2i(size)
	host.custom_minimum_size = size
	host.size = size
	for child in host.get_children():
		if child is Control:
			(child as Control).size = size


func _create_host() -> Control:
	var host := Control.new()
	host.custom_minimum_size = Vector2(UiConstants.WINDOW_WIDTH, UiConstants.WINDOW_HEIGHT)
	host.size = host.custom_minimum_size

	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.12, 0.14, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.size = host.size
	host.add_child(bg)

	var checker := ColorRect.new()
	checker.color = Color(0.18, 0.18, 0.22, 1.0)
	checker.position = Vector2.ZERO
	checker.size = Vector2(48, 48)
	host.add_child(checker)

	var checker_alt := ColorRect.new()
	checker_alt.color = Color(0.22, 0.22, 0.26, 1.0)
	checker_alt.position = Vector2(48, 48)
	checker_alt.size = Vector2(48, 48)
	host.add_child(checker_alt)

	return host


func _clear_test_hosts() -> void:
	for child in root.get_children():
		if child.is_in_group(TEST_HOST_GROUP):
			child.queue_free()
	for _i in 5:
		await process_frame


func _fail(reason: String) -> void:
	print("INVENTORY_MENU_VISUAL_CAPTURE_FAILED")
	print(reason)
	quit(1)
