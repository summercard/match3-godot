class_name StageSelectChapterRegistry
extends RefCounted

const CHAPTER_MAP_NODES := {
	"chapter_1": "MapScroll/ChapterMaps/Chapter01BreezePlain",
	"chapter_2": "MapScroll/ChapterMaps/Chapter02WaterfallKingdom",
	"chapter_3": "MapScroll/ChapterMaps/Chapter03FeatherForest",
	"chapter_4": "MapScroll/ChapterMaps/Chapter04PassionDesert",
	"chapter_5": "MapScroll/ChapterMaps/Chapter05SouthernSea",
	"chapter_6": "MapScroll/ChapterMaps/Chapter06IceKingdom",
	"chapter_7": "MapScroll/ChapterMaps/Chapter07SpiritVoid",
	"chapter_8": "MapScroll/ChapterMaps/Chapter08BarbecueRock",
	"chapter_9": "MapScroll/ChapterMaps/Chapter09StarlitTemple",
	"chapter_10": "MapScroll/ChapterMaps/Chapter10ChaosDomain",
	"chapter_11": "MapScroll/ChapterMaps/Chapter11RadiantTemple",
}

const CHAPTER_MAP_SCENES := {
	"chapter_1": "res://src/ui/scenes/stage_select/chapter_maps/chapter_01_breeze_plain.tscn",
	"chapter_2": "res://src/ui/scenes/stage_select/chapter_maps/chapter_02_waterfall_kingdom.tscn",
	"chapter_3": "res://src/ui/scenes/stage_select/chapter_maps/chapter_03_feather_forest.tscn",
	"chapter_4": "res://src/ui/scenes/stage_select/chapter_maps/chapter_04_passion_desert.tscn",
	"chapter_5": "res://src/ui/scenes/stage_select/chapter_maps/chapter_05_southern_sea.tscn",
	"chapter_6": "res://src/ui/scenes/stage_select/chapter_maps/chapter_06_ice_kingdom.tscn",
	"chapter_7": "res://src/ui/scenes/stage_select/chapter_maps/chapter_07_spirit_void.tscn",
	"chapter_8": "res://src/ui/scenes/stage_select/chapter_maps/chapter_08_barbecue_rock.tscn",
	"chapter_9": "res://src/ui/scenes/stage_select/chapter_maps/chapter_09_starlit_temple.tscn",
	"chapter_10": "res://src/ui/scenes/stage_select/chapter_maps/chapter_10_chaos_domain.tscn",
	"chapter_11": "res://src/ui/scenes/stage_select/chapter_maps/chapter_11_radiant_temple.tscn",
}

static func get_chapter_ids() -> Array[String]:
	var ids: Array[String] = []
	for chapter_id in CHAPTER_MAP_SCENES.keys():
		ids.append(str(chapter_id))
	ids.sort_custom(func(a: String, b: String) -> bool:
		return _chapter_number(a) < _chapter_number(b)
	)
	return ids

static func get_scene_path(chapter_id: String) -> String:
	return str(CHAPTER_MAP_SCENES.get(chapter_id, ""))

static func get_node_path(chapter_id: String) -> String:
	return str(CHAPTER_MAP_NODES.get(chapter_id, ""))

static func get_scene_paths() -> Array[String]:
	var paths: Array[String] = []
	for chapter_id in get_chapter_ids():
		paths.append(get_scene_path(chapter_id))
	return paths

static func _chapter_number(chapter_id: String) -> int:
	return int(chapter_id.trim_prefix("chapter_"))
