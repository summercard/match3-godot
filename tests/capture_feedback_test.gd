extends SceneTree

const CaptureSystemScript = preload("res://src/battle/capture_system.gd")
const MonsterDbScript = preload("res://src/data/monster_db.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_failure_feedback()
	_test_success_feedback()
	_test_target_value_tags()
	_finish()


func _test_failure_feedback() -> void:
	var locked := CaptureSystemScript.calc_taming_window(90, 100)
	var feedback: Dictionary = CaptureSystemScript.get_capture_feedback(0.12, false, locked, {})
	_expect(str(feedback.get("title", "")).contains("失败"), "failure feedback should have failure title")
	_expect(str(feedback.get("reason", "")).contains("概率") or str(feedback.get("reason", "")).contains("稳定"), "failure feedback should explain why it failed")
	_expect(str(feedback.get("advice", "")).contains("血量") or str(feedback.get("advice", "")).contains("窗口"), "failure feedback should give next action")


func _test_success_feedback() -> void:
	var prime := CaptureSystemScript.calc_taming_window(10, 100)
	var feedback: Dictionary = CaptureSystemScript.get_capture_feedback(0.72, true, prime, {"item_used": {"id": "capture_ball"}})
	_expect(str(feedback.get("title", "")).contains("成功"), "success feedback should have success title")
	_expect(str(feedback.get("reason", "")).contains("道具") or str(feedback.get("reason", "")).contains("窗口"), "success feedback should explain what helped")
	_expect(str(feedback.get("advice", "")).contains("队伍"), "success feedback should point to team inspection")


func _test_target_value_tags() -> void:
	var monster: Dictionary = MonsterDbScript.get_monster_stats("monster_003", 3)
	var tags: Array[String] = CaptureSystemScript.get_target_value_tags(monster)
	_expect(tags.has("★2"), "target tags should include rarity")
	_expect(tags.has("草能量"), "target tags should include board affinity")
	_expect(tags.has("输出技"), "current target tags should include its configured skill role")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[CaptureFeedback] OK")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[CaptureFeedback] " + failure)
		quit(1)
