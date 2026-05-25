extends SceneTree

const SceneStageSelectScript = preload("res://src/ui/scene/scene_stage_select.gd")
const StageDBScript = preload("res://src/data/stage_db.gd")

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
	save_manager.save_stage_stars("stage_1_1", 3)

	var scene: Control = SceneStageSelectScript.new()
	root.add_child(scene)
	scene.initialize(null, {})

	var stage_db := StageDBScript.new()
	var stage_1_1: Dictionary = stage_db.get_stage("stage_1_1")
	scene.call("_show_sweep_dialog", "stage_1_1", str(stage_1_1.get("name", "")))

	var exp_label := scene.find_child("ExpLabel", true, false) as Label
	var rule_label := scene.find_child("RuleLabel", true, false) as Label
	var reward: Dictionary = scene.get("_sweep_dialog_reward")
	var cards: Array = scene.get("_cards")
	var stage_1_2_card: Dictionary = _find_card(cards, "stage_1_2")
	var stage_1_3_card: Dictionary = _find_card(cards, "stage_1_3")

	_expect(not reward.is_empty(), "sweep dialog should cache visible reward values")
	_expect(int(reward.get("gold", 0)) > 0, "sweep dialog should show gold reward")
	_expect(int(reward.get("exp", 0)) > 0, "sweep dialog should show exp reward")
	_expect(exp_label != null and exp_label.text.contains("经验"), "sweep dialog should include an exp label")
	_expect(rule_label != null and rule_label.text.contains("3 星"), "sweep dialog should explain current star basis")
	_expect(bool(stage_1_2_card.get("enabled", false)), "stage select should enable the next unlocked stage")
	_expect(not bool(stage_1_3_card.get("enabled", true)), "stage select should keep later stages locked")

	scene.queue_free()
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _find_card(cards: Array, stage_id: String) -> Dictionary:
	for card: Dictionary in cards:
		if str(card.get("id", "")) == stage_id:
			return card
	return {}


func _finish() -> void:
	if _failures.is_empty():
		print("[StageSelectRewardUI] OK")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[StageSelectRewardUI] " + failure)
		quit(1)
