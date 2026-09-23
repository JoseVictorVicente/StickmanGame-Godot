extends SceneTree

## Death strip uses the same 76px cell width as attack frames (3116 / 76 = 41 frames).
const FRAME_WIDTH := 76
const PROJECT := "C:/Users/LEONARDO/ProjetosGodot/teste-jogo-stickman-iddle/"
const SRC_ABS := "C:/Users/LEONARDO/AppData/Roaming/Cursor/User/workspaceStorage/d462328bd1174e2e3c2cf0c5200792e8/images/death animation enemy-cd492c55-0333-4ae8-9898-2a059b427a7a.png"
const OUT_DIR := PROJECT + "sprites/enemies/imp_red/death/"
const LOG_PATH := PROJECT + "tools/import_death_log.txt"


func _init() -> void:
	var log_lines: PackedStringArray = []
	var img := Image.new()
	var err := img.load(SRC_ABS)
	if err != OK:
		log_lines.append("load_err=%s" % err)
		_write_log(log_lines)
		quit(1)
		return
	var sheet_w := img.get_width()
	var sheet_h := img.get_height()
	var frame_count := sheet_w / FRAME_WIDTH
	log_lines.append("sheet=%dx%d frame_w=%d count=%d" % [sheet_w, sheet_h, FRAME_WIDTH, frame_count])
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	img.save_png(OUT_DIR + "sheet.png")
	for i in frame_count:
		var frame := img.get_region(Rect2i(i * FRAME_WIDTH, 0, FRAME_WIDTH, sheet_h))
		frame.save_png("%sframe_%03d.png" % [OUT_DIR, i])
	log_lines.append("done")
	_write_log(log_lines)
	quit()


func _write_log(lines: PackedStringArray) -> void:
	var f := FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f:
		f.store_string("\n".join(lines))
