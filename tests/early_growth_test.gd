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

	var stage_db = load("res://src/data/stage_db.gd").new()
	var stage_1_1: Dictionary = stage_db.get_stage("stage_1_1")
	var stage_1_5: Dictionary = stage_db.get_stage("stage_1_5")
	_expect(int(stage_1_1.get("rewards", {}).get("exp", 0)) >= 45, "stage_1_1 should give visible early exp")
	_expect(int(stage_1_5.get("rewards", {}).get("exp", 0)) >= 120, "chapter 1 boss should give a strong early reward")

	var exp_needed_level_1: int = save_manager.get_exp_for_level(1)
	_expect(exp_needed_level_1 <= 90, "level 1 exp requirement should allow early level-up feedback")

	var first_reward_exp: int = int(stage_1_1.get("rewards", {}).get("exp", 0))
	save_manager.add_player_exp(first_reward_exp)
	var player: Dictionary = save_manager.load_player()
	_expect(int(player.get("exp", 0)) >= exp_needed_level_1 / 2, "one first-stage win should fill at least half of level 1")

	save_manager.add_player_exp(first_reward_exp)
	player = save_manager.load_player()
	_expect(int(player.get("level", 1)) >= 2, "two first-stage wins should level up the player")

	save_manager.init_monster_pokedex("monster_001")
	var monster_result: Dictionary = save_manager.add_monster_exp("monster_001", first_reward_exp * 2)
	_expect(monster_result.get("leveledUp", false), "two first-stage monster exp grants should level a starter monster")

	var idle_rate: float = save_manager.get_idle_exp_rate("monster_001")
	_expect(idle_rate >= 6.0, "ranch idle rate should be visible in early play")

	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[EarlyGrowth] OK")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[EarlyGrowth] " + failure)
		quit(1)
