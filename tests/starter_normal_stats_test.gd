extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var storage := root.get_node_or_null("/root/SaveManager")
	_expect(storage != null, "SaveManager should exist")
	if storage == null:
		_finish()
		return
	storage.clear_all_data()
	var pool: Array = storage.get_monster_pool()
	_expect(pool.size() >= 3, "new save should contain all three starters")
	for starter_id in MonsterPool.DEFAULT_STARTERS:
		var matches := pool.filter(func(instance): return str(instance.get("monsterId", "")) == starter_id)
		_expect(not matches.is_empty(), "starter pool should contain %s" % starter_id)
		if matches.is_empty():
			continue
		var instance: Dictionary = matches[0]
		var expected := StatCalculator.calc(starter_id, int(instance.get("level", 1)), str(instance.get("nature", "")))
		var view := MonsterService.build_instance_view(instance)
		_expect(not bool(instance.get("isElite", false)), "%s should start as a normal non-elite pet" % starter_id)
		_expect(view.get("stats", {}) == expected, "%s should use base player stats without enemy multipliers" % starter_id)

	var team_stats: Array = storage.get_team_battle_stats()
	_expect(team_stats.size() == 3, "starter battle team should contain three pets")
	for unit: Dictionary in team_stats:
		var instance: Dictionary = storage.get_monster_instance(str(unit.get("instanceId", "")))
		var expected: Dictionary = StatCalculator.calc(str(instance.get("monsterId", "")), int(instance.get("level", 1)), str(instance.get("nature", "")))
		_expect(int(unit.get("hp", 0)) == int(expected.get("hp", -1)), "battle HP should match normal starter HP")
		_expect(int(unit.get("atk", 0)) == int(expected.get("atk", -1)), "battle ATK should match normal starter ATK")
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[StarterNormalStats] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[StarterNormalStats] " + failure)
	quit(1)
