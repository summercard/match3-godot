extends SceneTree

const CaptureSystemScript = preload("res://src/battle/capture_system.gd")
const RewardRulesScript = preload("res://src/battle/reward_rules.gd")
const StageDBScript = preload("res://src/data/stage_db.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_star_source()
	_test_reward_math()
	_test_guaranteed_items()
	_test_save_manager_sweep()
	_finish()


func _test_star_source() -> void:
	_expect(RewardRulesScript.calc_battle_stars(3, 10, 0.9) == 3, "fast healthy win should be 3 stars")
	_expect(RewardRulesScript.calc_battle_stars(8, 10, 0.1) == 1, "slow low-hp win should be 1 star")
	var reward_stars := RewardRulesScript.calc_battle_stars(5, 10, 0.7)
	var capture_stars := CaptureSystemScript.calc_battle_stars(5, 10, 0.7)
	_expect(capture_stars == reward_stars, "CaptureSystem stars should delegate to RewardRules")


func _test_reward_math() -> void:
	var stage_rewards := {"gold": 100, "exp": 50}
	var three_star := RewardRulesScript.calc_battle_rewards(stage_rewards, 3, true)
	var two_star := RewardRulesScript.calc_battle_rewards(stage_rewards, 2, true)
	var loss := RewardRulesScript.calc_battle_rewards(stage_rewards, 3, false)
	var sweep_one_star := RewardRulesScript.calc_sweep_rewards(stage_rewards, 1)
	var sweep_three_star := RewardRulesScript.calc_sweep_rewards(stage_rewards, 3)

	_expect(int(three_star.get("gold", 0)) == 100 and int(three_star.get("exp", 0)) == 50, "3-star rewards should pay full base")
	_expect(int(two_star.get("gold", 0)) == 80 and int(two_star.get("exp", 0)) == 40, "2-star rewards should pay 80 percent")
	_expect(int(loss.get("gold", 0)) == 30 and int(loss.get("exp", 0)) == 15, "loss rewards should pay 30 percent")
	_expect(int(sweep_one_star.get("gold", 0)) == 48 and int(sweep_one_star.get("exp", 0)) == 24, "1-star sweep should combine star and sweep multipliers")
	_expect(int(sweep_three_star.get("gold", 0)) == 80 and int(sweep_three_star.get("exp", 0)) == 40, "3-star sweep should pay 80 percent of full reward")
	_expect(RewardRulesScript.calc_monster_exp(stage_rewards, 2, true) == 40, "monster exp should match star-adjusted win exp")
	_expect(RewardRulesScript.calc_monster_exp(stage_rewards, 2, false) == 0, "monster exp should not pay on loss")


func _test_guaranteed_items() -> void:
	var stage_db := StageDBScript.new()
	var stage_1_2: Dictionary = stage_db.get_stage("stage_1_2")
	var first_item := RewardRulesScript.get_first_guaranteed_item(stage_1_2.get("rewards", {}))
	_expect(str(first_item.get("id", "")) == "capture_ball", "stage_1_2 should guarantee a capture ball")
	_expect(int(first_item.get("count", 0)) >= 1, "guaranteed capture ball should have a visible count")


func _test_save_manager_sweep() -> void:
	var save_manager := root.get_node_or_null("/root/SaveManager")
	_expect(save_manager != null, "SaveManager should exist")
	if save_manager == null:
		return
	save_manager.clear_all_data()
	save_manager.save_stage_stars("stage_1_1", 3)
	var reward: Dictionary = save_manager.get_sweep_reward("stage_1_1")
	var stage_db := StageDBScript.new()
	var expected := RewardRulesScript.calc_sweep_rewards(stage_db.get_stage("stage_1_1").get("rewards", {}), 3)
	_expect(reward == expected, "SaveManager sweep reward should use RewardRules")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[RewardRules] OK")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[RewardRules] " + failure)
		quit(1)
