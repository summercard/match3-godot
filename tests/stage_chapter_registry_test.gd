extends SceneTree

const ChapterRegistry := preload("res://src/ui/scene/stage_select_chapter_registry.gd")
const FORMAL_DIR := "res://src/ui/scenes/stage_select/chapter_maps"
const ARCHIVE_DIR := "res://docs/archive/stage_select/chapter_maps"
const ARCHIVED_CANDIDATES := [
	"chapter_02_fire_valley.tscn",
	"chapter_07_void_domain.tscn",
]
const UNREGISTERED_COMPATIBILITY_MAPS := ["chapter_08_temporal_rift.tscn"]

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var ids := ChapterRegistry.get_chapter_ids()
	_expect(ids.size() == 11, "stage select should declare exactly 11 formal chapter maps")
	_expect(ChapterRegistry.CHAPTER_MAP_NODES.size() == ids.size(), "chapter node map should match scene map size")

	var seen_paths := {}
	var expected_files: Array[String] = []
	for chapter_id in ids:
		var scene_path := ChapterRegistry.get_scene_path(chapter_id)
		var node_path := ChapterRegistry.get_node_path(chapter_id)
		_expect(not scene_path.is_empty(), "%s should have a scene path" % chapter_id)
		_expect(not node_path.is_empty(), "%s should have a node path" % chapter_id)
		_expect(not seen_paths.has(scene_path), "%s should be unique" % scene_path)
		seen_paths[scene_path] = true
		_expect(ResourceLoader.exists(scene_path), "%s should exist" % scene_path)
		expected_files.append(scene_path.get_file())

	expected_files.sort()
	for file_name in UNREGISTERED_COMPATIBILITY_MAPS:
		expected_files.append(file_name)
	expected_files.sort()
	var actual_files := _list_tscn_files(FORMAL_DIR)
	_expect(actual_files == expected_files, "formal chapter map directory should contain registered maps and documented compatibility maps only")

	for file_name in ARCHIVED_CANDIDATES:
		_expect(not FileAccess.file_exists(FORMAL_DIR + "/" + file_name), "%s should not remain in the formal chapter directory" % file_name)
		_expect(FileAccess.file_exists(ARCHIVE_DIR + "/" + file_name), "%s should be archived outside the formal chapter directory" % file_name)
	for file_name in UNREGISTERED_COMPATIBILITY_MAPS:
		_expect(FileAccess.file_exists(FORMAL_DIR + "/" + file_name), "%s should remain available as a compatibility map" % file_name)
		_expect(not ChapterRegistry.get_scene_paths().has(FORMAL_DIR + "/" + file_name), "%s should not be used by the current chapter registry" % file_name)

	if _failures.is_empty():
		print("[StageChapterRegistry] OK")
		quit(0)
	else:
		for failure in _failures:
			push_error("[StageChapterRegistry] " + failure)
		quit(1)

func _list_tscn_files(dir_path: String) -> Array[String]:
	var files: Array[String] = []
	var dir := DirAccess.open(dir_path)
	_expect(dir != null, "%s should be readable" % dir_path)
	if dir == null:
		return files
	for file_name in dir.get_files():
		if file_name.ends_with(".tscn"):
			files.append(file_name)
	files.sort()
	return files

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
