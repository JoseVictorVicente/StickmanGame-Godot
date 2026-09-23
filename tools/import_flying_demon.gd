extends SceneTree

const PROJECT := "C:/Users/LEONARDO/ProjetosGodot/teste-jogo-stickman-iddle/"
const SOURCE_DIR := PROJECT + "sprites/enemies/flying_demon/source/"
const OUT_BASE := PROJECT + "sprites/enemies/flying_demon/"
const LOG_PATH := PROJECT + "tools/import_flying_demon_log.txt"

const SOURCES := {
	"idle": {
		"path": SOURCE_DIR + "idle.png",
		"out": OUT_BASE + "idle/",
		"frame_count": 0,
	},
	"run": {
		"path": SOURCE_DIR + "run.png",
		"out": OUT_BASE + "run/",
		"frame_count": 0,
	},
	"attack": {
		"path": SOURCE_DIR + "attack.png",
		"out": OUT_BASE + "attack/",
		"frame_count": 0,
	},
	"death": {
		"path": SOURCE_DIR + "death.png",
		"out": OUT_BASE + "death/",
		"frame_count": 0,
	},
}


func _init() -> void:
	var log_lines: PackedStringArray = []
	for key in ["idle", "run", "attack", "death"]:
		var cfg: Dictionary = SOURCES[key]
		log_lines.append(_slice_sheet(key, cfg))
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
	var frame_w := sheet_h
	var frame_count := int(cfg.frame_count)
	if frame_count <= 0:
		frame_count = sheet_w / frame_w

	DirAccess.make_dir_recursive_absolute(out_dir)
	var saved := 0
	for i in frame_count:
		var region := Rect2i(i * frame_w, 0, frame_w, sheet_h)
		var frame := img.get_region(region)
		frame.save_png("%sframe_%03d.png" % [out_dir, i])
		saved += 1

	return (
		"%s: sheet=%dx%d frame=%dx%d count=%d saved=%d out=%s"
		% [name, sheet_w, sheet_h, frame_w, sheet_h, frame_count, saved, out_dir]
	)


func _write_log(lines: PackedStringArray) -> void:
	var f := FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f:
		f.store_string("\n".join(lines))
