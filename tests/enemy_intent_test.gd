extends SceneTree

const BattleManagerScript = preload("res://src/battle/battle_manager.gd")
const EnemyIntentRulesScript = preload("res://src/battle/enemy_intent_rules.gd")
const StageDBScript = preload("res://src/data/stage_db.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_intent_rules_direct()
	_test_boss_charge_intents()
	_test_shield_intent()
	_test_battle_scene_exposes_intents()
	_finish()


func _test_intent_rules_direct() -> void:
	var release := EnemyIntentRulesScript.build_enemy_intent({}, {
		"charge": {"is_charging": true, "damage_multiplier": 2.5}
	})
	_expect(release.get("type", "") == "charge_release", "charging enemy should expose charge release intent")
	_expect(str(release.get("hint", "")).contains("束缚"), "charge release intent should explain break response")

	var upcoming := EnemyIntentRulesScript.build_enemy_intent({}, {
		"charge": {"is_charging": false, "turns_since_last": 2, "interval": 3}
	})
	_expect(upcoming.get("type", "") == "attack_then_charge", "charge interval should expose attack-then-charge intent")


func _test_boss_charge_intents() -> void:
	var stage_db := StageDBScript.new()
	var battle := BattleManagerScript.new()
	battle.init(["monster_001", "monster_002", "monster_003"], [], 5, 3, stage_db.get_stage("stage_1_12"), "stage_1_12")
	for monster: Dictionary in battle.player_team:
		monster["hp"] = 9999
		monster["maxHP"] = 9999

	var initial: Dictionary = battle.get_enemy_intents().get(0, {})
	_expect(initial.get("type", "") == "attack", "boss should start with readable normal attack intent")

	battle.enemy_action()
	battle.enemy_action()
	var warning: Dictionary = battle.get_enemy_intents().get(0, {})
	_expect(warning.get("type", "") == "attack_then_charge", "boss should warn before entering charge")

	battle.enemy_action()
	var release: Dictionary = battle.get_enemy_intents().get(0, {})
	_expect(release.get("type", "") == "charge_release", "boss should show charge release intent while charging")
	battle.free()


func _test_shield_intent() -> void:
	var battle := BattleManagerScript.new()
	battle.init(["monster_001"], ["monster_boss_002"], 5, 3)
	var shield: Dictionary = battle.get_enemy_intents().get(0, {})
	_expect(shield.get("type", "") == "shield", "shield boss should expose shield intent before activation")
	battle.free()


func _test_battle_scene_exposes_intents() -> void:
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var stage_db := StageDBScript.new()
	main.switch_scene("battle", {
		"stageId": "stage_1_12",
		"stageData": stage_db.get_stage("stage_1_12")
	})
	await process_frame
	var battle_scene: Control = main.get_current_scene()
	_expect(battle_scene != null, "battle scene should load")
	if battle_scene == null:
		main.queue_free()
		return
	var render_state: Dictionary = battle_scene.call("_combatant_render_state")
	_expect(not render_state.get("enemy_intents", {}).is_empty(), "battle UI render state should include enemy intents")
	main.queue_free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[EnemyIntent] OK")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[EnemyIntent] " + failure)
		quit(1)
