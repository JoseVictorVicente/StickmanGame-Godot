class_name WorldCatalog
extends RefCounted
## Narrative catalog for portal dimensions. Maps world_id to lore keys and map art.
## Briefing/trail placeholders: sprites/ui/worlds/briefing_dim_*.png, trail_dim_*.png


const _BRIEFING_TEXTURES: PackedStringArray = [
	"res://sprites/ui/worlds/briefing_dim_1.png",
	"res://sprites/ui/worlds/briefing_dim_2.png",
	"res://sprites/ui/worlds/briefing_dim_3.png",
	"res://sprites/ui/worlds/briefing_dim_4.png",
	"res://sprites/ui/worlds/briefing_dim_5.png",
]

const _TRAIL_TEXTURES: PackedStringArray = [
	"res://sprites/ui/worlds/trail_dim_1.png",
	"res://sprites/ui/worlds/trail_dim_2.png",
	"res://sprites/ui/worlds/trail_dim_3.png",
	"res://sprites/ui/worlds/trail_dim_4.png",
	"res://sprites/ui/worlds/trail_dim_5.png",
]

const _DIMENSION_NAME_KEYS: PackedStringArray = [
	"DIMENSION_1_NAME",
	"DIMENSION_2_NAME",
	"DIMENSION_3_NAME",
	"DIMENSION_4_NAME",
	"DIMENSION_5_NAME",
]

const _DEMON_KING_KEYS: PackedStringArray = [
	"DIMENSION_1_DEMON_KING",
	"DIMENSION_2_DEMON_KING",
	"DIMENSION_3_DEMON_KING",
	"DIMENSION_4_DEMON_KING",
	"DIMENSION_5_DEMON_KING",
]

const _BRIEFING_KEYS: PackedStringArray = [
	"DIMENSION_1_BRIEFING",
	"DIMENSION_2_BRIEFING",
	"DIMENSION_3_BRIEFING",
	"DIMENSION_4_BRIEFING",
	"DIMENSION_5_BRIEFING",
]

static var _briefing_texture_cache: Dictionary = {}
static var _trail_texture_cache: Dictionary = {}


static func _stage_key(world_id: int, stage: int) -> String:
	var id := clampi(world_id, 1, dimension_count())
	var fase := clampi(stage, 1, WorldProgress.STAGES_PER_WORLD)
	return "DIMENSION_%d_STAGE_%d" % [id, fase]


static func dimension_count() -> int:
	return WorldProgress.TOTAL_WORLDS


static func _world_index(world_id: int) -> int:
	return clampi(world_id, 1, dimension_count()) - 1


static func dimension_name(world_id: int) -> String:
	return TranslationServer.translate(_DIMENSION_NAME_KEYS[_world_index(world_id)])


static func demon_king_name(world_id: int) -> String:
	return TranslationServer.translate(_DEMON_KING_KEYS[_world_index(world_id)])


static func briefing_text(world_id: int) -> String:
	return TranslationServer.translate(_BRIEFING_KEYS[_world_index(world_id)])


static func stage_milestone(world_id: int, stage: int) -> String:
	return TranslationServer.translate(_stage_key(world_id, stage))


static func briefing_texture_path(world_id: int) -> String:
	return _BRIEFING_TEXTURES[_world_index(world_id)]


static func map_texture_path(world_id: int) -> String:
	return _TRAIL_TEXTURES[_world_index(world_id)]


static func briefing_texture(world_id: int) -> Texture2D:
	return _load_cached_texture(world_id, briefing_texture_path(world_id), _briefing_texture_cache)


static func map_texture(world_id: int) -> Texture2D:
	return _load_cached_texture(world_id, map_texture_path(world_id), _trail_texture_cache)


static func _load_cached_texture(world_id: int, caminho: String, cache: Dictionary) -> Texture2D:
	var id := clampi(world_id, 1, dimension_count())
	if cache.has(id):
		return cache[id]
	if caminho == "" or not ResourceLoader.exists(caminho):
		push_warning("WorldCatalog: missing texture at %s (world %d)" % [caminho, id])
		cache[id] = null
		return null
	var tex := load(caminho) as Texture2D
	if tex == null:
		push_warning("WorldCatalog: failed to load texture at %s (world %d)" % [caminho, id])
	cache[id] = tex
	return tex


static func is_boss_stage(stage: int) -> bool:
	return stage == WorldProgress.STAGES_PER_WORLD


static func is_dimension_saved(world_id: int, progress_value: int) -> bool:
	var boss_index := WorldProgress.stage_index(world_id, WorldProgress.STAGES_PER_WORLD)
	return progress_value > boss_index
