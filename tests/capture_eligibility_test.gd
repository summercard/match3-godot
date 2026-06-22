extends SceneTree

const BattleManagerScript = preload("res://src/battle/battle_manager.gd")
const CaptureSystemScript = preload("res://src/battle/capture_system.gd")
const StatCalculatorScript = preload("res://src/core/stat_calculator.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_expect(CaptureSystemScript.can_capture({"id": "enemy_001", "isBoss": false}), "normal enemy should be capturable by default")
	_expect(not CaptureSystemScript.can_capture({"id": "monster_boss_001", "isBoss": true}), "boss should not be capturable by default")
	_expect(CaptureSystemScript.can_capture({"id": "event_boss", "isBoss": true, "capturable": true}), "explicit capturable flag should allow a special boss")
	_expect(CaptureSystemScript.can_capture({"id": "monster_boss_001", "isBoss": true}, {"allowBossCapture": true}), "stage override should allow an event boss")

	var boss_stats: Dictionary = StatCalculatorScript.calc("monster_boss_001", 5)
	var normal_stats: Dictionary = StatCalculatorScript.calc("enemy_001", 5)
	_expect(not bool(boss_stats.get("capturable", true)), "battle stats should mark bosses as non-capturable")
	_expect(bool(normal_stats.get("capturable", false)), "battle stats should mark normal enemies as capturable")

	var boss_battle = BattleManagerScript.new()
	boss_battle.init(["monster_001"], ["monster_boss_001"], 5, 5)
	_expect(boss_battle.get_best_capture_candidate().is_empty(), "boss battle should expose no capture candidate")
	_expect(boss_battle.capture_windows.is_empty(), "boss battle should create no capture window")
	boss_battle.free()

	var normal_battle = BattleManagerScript.new()
	normal_battle.init(["monster_001"], ["enemy_001"], 5, 5)
	_expect(not normal_battle.get_best_capture_candidate().is_empty(), "normal battle should still expose a capture candidate")
	normal_battle.free()
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[CaptureEligibility] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[CaptureEligibility] " + failure)
	quit(1)
