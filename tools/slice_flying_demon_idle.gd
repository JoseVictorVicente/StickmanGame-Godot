extends SceneTree

const ROOT := "res://sprites/enemies/flying_demon/"
const SOURCE_DIR := ROOT + "source/"
const SIDE_FRAMES := [5, 6, 7]


func _init() -> void:
	var sheet_path := _find_sheet()
	if sheet_path == "":
		push_error("Flying demon IDLE_ANIMATION sheet not found")
		quit(1)
		return
	var img := Image.new()
	if img.load(sheet_path) != OK:
		push_error("Failed to load %s" % sheet_path)
		quit(1)
		return
	var frame_w := img.get_height()
	for folder in ["idle", "run", "attack", "death"]:
		var out_dir := ProjectSettings.globalize_path(ROOT + folder + "/")
		DirAccess.make_dir_recursive_absolute(out_dir)
		for j in SIDE_FRAMES.size():
			var idx := SIDE_FRAMES[j]
			var region := Rect2i(idx * frame_w, 0, frame_w, img.get_height())
			var frame := img.get_region(region)
			frame.save_png("%sframe_%03d.png" % [out_dir, j])
	print("Sliced flying demon frames from ", sheet_path)
	quit()


func _find_sheet() -> String:
	var dir := DirAccess.open(SOURCE_DIR)
	if dir == null:
		return ""
	for file_name in dir.get_files():
		if file_name.contains("IDLE_ANIMATION") and file_name.ends_with(".png"):
			return ProjectSettings.globalize_path(SOURCE_DIR + file_name)
	return ""
