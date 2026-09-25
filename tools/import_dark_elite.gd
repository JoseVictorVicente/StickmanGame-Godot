extends SceneTree

const PROJECT := "C:/Users/LEONARDO/ProjetosGodot/teste-jogo-stickman-iddle/"
const TMP_DIR := PROJECT + "tools/_tmp_import/"
const OUT_BASE := PROJECT + "sprites/enemies/dark_elite/"
const LOG_PATH := PROJECT + "tools/import_dark_elite_log.txt"

const SOURCES := {
	"idle": {
		"path": TMP_DIR + "idle.png",
		"out": OUT_BASE + "idle/",
		"mode": "horizontal",
		"frame_count": 8,
	},
	"run": {
		"path": TMP_DIR + "run.png",
		"out": OUT_BASE + "run/",
		"mode": "horizontal",
		"frame_count": 0,
	},
	"attack": {
		"path": TMP_DIR + "attack.png",
		"out": OUT_BASE + "attack/",
		"mode": "horizontal",
		"frame_count": 0,
	},
	"death": {
		"path": TMP_DIR + "death.png",
		"out": OUT_BASE + "death/",
		"mode": "rows",
		"frame_count": 0,
	},
}


func _init() -> void:
	var log_lines: PackedStringArray = []
	for key in ["idle", "run", "attack", "death"]:
		var cfg: Dictionary = SOURCES[key]
		var result := _slice_sheet(key, cfg)
		log_lines.append(result)
	_write_log(log_lines)
	quit()


func _slice_sheet(name: String, cfg: Dictionary) -> String:
	var src_path: String = cfg.path
	var out_dir: String = cfg.out
	var img := Image.new()
	var err := img.load(src_path)
	if err != OK:
		return "%s: load_err=%s path=%s" % [name, err, src_path]

	var sheet_w := img.get_width()
	var sheet_h := img.get_height()
	var frame_w := 0
	var frame_h := sheet_h
	var frame_count := int(cfg.frame_count)
	var mode: String = cfg.mode

	if mode == "horizontal":
		if frame_count > 0:
			frame_w = sheet_w / frame_count
		else:
			frame_w = sheet_h
			frame_count = sheet_w / frame_w
	elif mode == "rows":
		frame_w = sheet_h
		var cols := sheet_w / frame_w
		var rows := sheet_h / frame_h
		if rows > 1:
			frame_count = cols * rows
		else:
			frame_count = sheet_w / frame_w

	DirAccess.make_dir_recursive_absolute(out_dir)
	var saved := 0
	if mode == "rows" and sheet_h > frame_h * 1.5:
		var cols := sheet_w / frame_w
		var rows := sheet_h / frame_h
		var idx := 0
		for row in rows:
			for col in cols:
				var region := Rect2i(col * frame_w, row * frame_h, frame_w, frame_h)
				var frame := img.get_region(region)
				frame.save_png("%sframe_%03d.png" % [out_dir, idx])
				idx += 1
				saved += 1
	else:
		for i in frame_count:
			var region := Rect2i(i * frame_w, 0, frame_w, frame_h)
			var frame := img.get_region(region)
			frame.save_png("%sframe_%03d.png" % [out_dir, i])
			saved += 1

	return (
		"%s: sheet=%dx%d frame=%dx%d count=%d saved=%d out=%s"
		% [name, sheet_w, sheet_h, frame_w, frame_h, frame_count, saved, out_dir]
	)


func _write_log(lines: PackedStringArray) -> void:
	var f := FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f:
		f.store_string("\n".join(lines))
