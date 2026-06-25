extends SceneTree

const StageWarBackgroundsScript = preload("res://src/ui/components/stage_war_backgrounds.gd")

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for chapter_no in range(1, 9):
		var stage_id := "stage_%d_1" % chapter_no
		var path := StageWarBackgroundsScript.path_for(stage_id)
		var expected_map := 5 if chapter_no == 4 else chapter_no
		_expect(path.ends_with("warbackgrouds/map%d.png" % expected_map), "%s should map to map%d.png, got %s" % [stage_id, expected_map, path])
		_expect(ResourceLoader.exists(path), "war background should exist: %s" % path)
	_expect(StageWarBackgroundsScript.path_for("", {}, {"chapterIndex": 7}).ends_with("warbackgrouds/map8.png"), "chapterIndex 7 should map to chapter 8 background")
	if _failures.is_empty():
		print("[StageWarBackgrounds] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[StageWarBackgrounds] " + failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
