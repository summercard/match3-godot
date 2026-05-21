extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var save_manager := root.get_node_or_null("/root/SaveManager")
	_expect(save_manager != null, "SaveManager should exist")
	if save_manager == null:
		_finish()
		return

	save_manager.clear_all_data()
	var report: Dictionary = MonsterService.validate_monster_catalog(save_manager)
	_expect(report.get("missingFields", []).is_empty(), "monster templates should have required fields")
	_expect(report.get("invalidEvolutions", []).is_empty(), "monster evolution targets should exist")
	_expect(report.get("brokenInstanceRefs", []).is_empty(), "team/ranch instance refs should resolve")
	_expect(report.has("missingBattleArt"), "catalog report should include missing art list")

	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[MonsterCatalog] OK")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[MonsterCatalog] " + failure)
		quit(1)
