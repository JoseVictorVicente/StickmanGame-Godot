class_name ClassData
extends Resource
## Playable hero class attributes.

@export var id: String = "warrior"
@export var display_name: String = "Warrior"
@export var character_sprite: Texture2D
@export var base_damage: int = 5
@export var base_hp: int = 40
@export var hp_per_level: int = 4
@export var atk_per_level: int = 0
@export var attack_multiplier: float = 1.0
@export var attack_speed: float = 1.0
@export var color: Color = Color(0.12, 0.12, 0.14, 1)
@export var item_class: ItemData.RequiredClass = ItemData.RequiredClass.WARRIOR

const LEGACY_ID_MAP := {
	"warrior": "warrior",
	"mage": "mage",
	"archer": "archer",
	"assassin": "assassin",
	"tank": "tank",
	"priest": "priest",
}


static func normalize_id(class_id: String) -> String:
	return LEGACY_ID_MAP.get(class_id, class_id)


func get_localized_name() -> String:
	match normalize_id(id):
		"warrior":
			return tr(LocaleKeys.CLASS_WARRIOR)
		"mage":
			return tr(LocaleKeys.CLASS_MAGE)
		"archer":
			return tr(LocaleKeys.CLASS_ARCHER)
		"assassin":
			return tr(LocaleKeys.CLASS_ASSASSIN)
		"tank":
			return tr(LocaleKeys.CLASS_TANK)
		"priest":
			return tr(LocaleKeys.CLASS_PRIEST)
		_:
			return display_name


static func create(
	p_id: String,
	p_display_name: String,
	p_damage: int,
	p_attack_mult: float,
	p_attack_speed: float,
	p_color: Color,
	p_item_class: ItemData.RequiredClass,
	p_hp: int = 40,
	p_art_path: String = "",
	p_hp_per_level: int = 4,
	p_atk_per_level: int = 0,
) -> ClassData:
	var data := ClassData.new()
	data.id = p_id
	data.display_name = p_display_name
	data.base_damage = p_damage
	data.base_hp = p_hp
	data.hp_per_level = p_hp_per_level
	data.atk_per_level = p_atk_per_level
	data.attack_multiplier = p_attack_mult
	data.attack_speed = p_attack_speed
	data.color = p_color
	data.item_class = p_item_class
	data.character_sprite = _load_art(p_art_path, p_color)
	return data


static func catalog() -> Array[ClassData]:
	return [
		create("priest", "Sacerdote", 3, 1.1, 0.9, Color(0.86, 0.78, 0.32), ItemData.RequiredClass.PRIEST, 32, "res://sprites/heroes/px_priest2.jpg", 4, 2),
		create("tank", "Tanque", 6, 0.85, 0.7, Color(0.22, 0.32, 0.72), ItemData.RequiredClass.TANK, 60, "res://sprites/heroes/px_tank2.jpg", 9, 1),
		create("assassin", "Assassino", 4, 1.25, 1.45, Color(0.18, 0.18, 0.18), ItemData.RequiredClass.ASSASSIN, 26, "res://sprites/heroes/px_assassin2.jpg", 6, 1),
		create("archer", "Arqueiro", 4, 1.15, 1.3, Color(0.16, 0.42, 0.2), ItemData.RequiredClass.ARCHER, 30, "res://sprites/heroes/px_archer2.png", 4, 2),
		create("mage", "Mago", 3, 1.4, 0.85, Color(0.28, 0.18, 0.62), ItemData.RequiredClass.MAGE, 24, "res://sprites/heroes/px_mage2.jpg", 4, 2),
		create("warrior", "Guerreiro", 5, 1.0, 1.0, Color(0.72, 0.16, 0.14), ItemData.RequiredClass.WARRIOR, 42, "res://sprites/heroes/px_warrior2.jpg", 7, 1),
	]


static func _load_art(path: String, fallback: Color) -> Texture2D:
	if path == "":
		return _simple_sprite(fallback)
	if ResourceLoader.exists(path):
		var resource: Resource = ResourceLoader.load(path)
		if resource is Texture2D:
			return resource
	var absolute := ProjectSettings.globalize_path(path).replace("\\", "/")
	var img: Image = Image.load_from_file(absolute)
	if img != null and img.get_width() > 1:
		return ImageTexture.create_from_image(img)
	var bytes := _read_file_bytes(path, absolute)
	if not bytes.is_empty():
		img = Image.new()
		var err := ERR_INVALID_DATA
		if bytes.size() >= 8 and bytes[0] == 0x89 and bytes[1] == 0x50:
			err = img.load_png_from_buffer(bytes)
		else:
			err = img.load_jpg_from_buffer(bytes)
		if err == OK and img.get_width() > 1:
			return ImageTexture.create_from_image(img)
		var dest := "user://portrait_" + path.get_file()
		var out := FileAccess.open(dest, FileAccess.WRITE)
		if out:
			out.store_buffer(bytes)
			out.close()
			img = Image.load_from_file(dest)
			if img != null and img.get_width() > 1:
				return ImageTexture.create_from_image(img)
	push_warning("Failed to load hero art: %s err=%s" % [path, FileAccess.get_open_error()])
	return _simple_sprite(fallback)


static func _read_file_bytes(path: String, absolute: String) -> PackedByteArray:
	for candidate in [absolute, path]:
		var file := FileAccess.open(candidate, FileAccess.READ)
		if file:
			var bytes := file.get_buffer(file.get_length())
			file.close()
			if not bytes.is_empty():
				return bytes
		if FileAccess.file_exists(candidate):
			var loaded := FileAccess.get_file_as_bytes(candidate)
			if not loaded.is_empty():
				return loaded
	return PackedByteArray()


static func _simple_sprite(p_color: Color) -> Texture2D:
	var img := Image.create(48, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center := Vector2(24, 12)
	_draw_circle(img, center, 7, p_color)
	_draw_line(img, center + Vector2(0, 7), center + Vector2(0, 28), p_color)
	_draw_line(img, center + Vector2(0, 12), center + Vector2(-11, 22), p_color)
	_draw_line(img, center + Vector2(0, 12), center + Vector2(11, 22), p_color)
	_draw_line(img, center + Vector2(0, 28), center + Vector2(-8, 48), p_color)
	_draw_line(img, center + Vector2(0, 28), center + Vector2(8, 48), p_color)
	return ImageTexture.create_from_image(img)


static func _draw_circle(img: Image, center: Vector2, radius: int, p_color: Color) -> void:
	for y in range(int(center.y) - radius, int(center.y) + radius + 1):
		for x in range(int(center.x) - radius, int(center.x) + radius + 1):
			if Vector2(x, y).distance_to(center) <= radius:
				_set_pixel(img, x, y, p_color)


static func _draw_line(img: Image, a: Vector2, b: Vector2, p_color: Color) -> void:
	var steps := maxi(1, int(a.distance_to(b)))
	for i in steps + 1:
		var p: Vector2 = a.lerp(b, float(i) / float(steps))
		for ox in range(-1, 2):
			for oy in range(-1, 2):
				_set_pixel(img, int(p.x) + ox, int(p.y) + oy, p_color)


static func _set_pixel(img: Image, x: int, y: int, p_color: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	img.set_pixel(x, y, p_color)
