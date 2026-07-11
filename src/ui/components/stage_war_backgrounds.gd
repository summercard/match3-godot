class_name StageWarBackgrounds
extends RefCounted

const DEFAULT_PATH := "res://assets/images/maps/warbackgrouds/map1.png"
const TOWER_CRYSTAL_GARDEN_PATH := "res://assets/images/tower_new/battle/tower_crystal_garden_battle_v1.png"
const CHAPTER_PATHS := {
	1: "res://assets/images/maps/warbackgrouds/map1.png",
	2: "res://assets/images/maps/warbackgrouds/map2.png",
	3: "res://assets/images/maps/warbackgrouds/map3.png",
	4: "res://assets/images/maps/warbackgrouds/map4.png",
	5: "res://assets/images/maps/warbackgrouds/map5.png",
	6: "res://assets/images/maps/warbackgrouds/map6.png",
	7: "res://assets/images/maps/warbackgrouds/map7.png",
	8: "res://assets/images/maps/warbackgrouds/map8.png",
}

static func path_for(stage_id: String = "", stage_data: Dictionary = {}, context: Dictionary = {}) -> String:
	if bool(context.get("towerMode", false)) or str(stage_data.get("mode", "")) == "tower":
		return TOWER_CRYSTAL_GARDEN_PATH if ResourceLoader.exists(TOWER_CRYSTAL_GARDEN_PATH) else DEFAULT_PATH
	var chapter_no := _chapter_no_from_context(stage_id, stage_data, context)
	var path := str(CHAPTER_PATHS.get(chapter_no, DEFAULT_PATH))
	return path if ResourceLoader.exists(path) else DEFAULT_PATH

static func _chapter_no_from_context(stage_id: String, stage_data: Dictionary, context: Dictionary) -> int:
	var explicit := _chapter_no_from_explicit(context)
	if explicit > 0:
		return explicit
	explicit = _chapter_no_from_explicit(stage_data)
	if explicit > 0:
		return explicit
	var chapter_id := str(stage_data.get("chapterId", stage_data.get("chapter_id", "")))
	var from_chapter_id := _chapter_no_from_chapter_id(chapter_id)
	if from_chapter_id > 0:
		return from_chapter_id
	var data_stage_id := str(stage_data.get("id", stage_id))
	return max(1, _chapter_no_from_stage_id(data_stage_id))

static func _chapter_no_from_explicit(data: Dictionary) -> int:
	if data.has("chapterNo"):
		return int(data.get("chapterNo", 0))
	if data.has("chapter_no"):
		return int(data.get("chapter_no", 0))
	if data.has("chapterIndex"):
		return int(data.get("chapterIndex", -1)) + 1
	if data.has("chapter_index"):
		return int(data.get("chapter_index", -1)) + 1
	return 0

static func _chapter_no_from_chapter_id(chapter_id: String) -> int:
	if chapter_id.is_empty():
		return 0
	var parts := chapter_id.split("_")
	if parts.size() < 2:
		return 0
	return int(parts[1])

static func _chapter_no_from_stage_id(stage_id: String) -> int:
	if stage_id.is_empty():
		return 0
	var parts := stage_id.split("_")
	if parts.size() < 3:
		return 0
	return int(parts[1])
