extends SceneTree

## 数据化敌人出手模式回归：
## 1. MonsterDb / StageDB 中确实存在 rotation / weight 配置；
## 2. strike / charge / sweep 的伤害与行动次数符合需求；
## 3. 蓄力回合不出伤、下一回合按 1.8~2.0x 单体结算；
## 4. 前摇视觉数据区分普通、蓄力、全体三种样式。

const BattleManagerScript = preload("res://src/battle/battle_manager.gd")
const EnemyAttackModesScript = preload("res://src/battle/enemy_attack_modes.gd")
const EnemyIntentRulesScript = preload("res://src/battle/enemy_intent_rules.gd")
const StageDBScript = preload("res://src/data/stage_db.gd")
const MonsterDbScript = preload("res://src/data/monster_db.gd")
const BattleCombatantRendererScript = preload("res://src/ui/components/battle_combatant_renderer.gd")

const TEAM := ["monster_001", "monster_002", "monster_003"]

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_data_config()
	_test_rotation_and_stage_override()
	_test_weighted_selection()
	_test_strike_behavior()
	_test_charge_behavior()
	_test_sweep_behavior()
	_test_charge_and_sweep_multipliers()
	_test_windup_cues()
	_test_intent_types()
	await _test_scene_windup_state()
	_finish()


func _test_data_config() -> void:
	var enemy_006: Dictionary = MonsterDbScript.get_monster_stats("enemy_006", 9)
	var modes: Variant = enemy_006.get("attackModes", null)
	_expect(modes is Dictionary, "enemy_006 should carry attackModes in monster data")
	if modes is Dictionary:
		_expect(str(modes.get("select", "")) == "rotation", "enemy_006 should use rotation selection")
		_expect((modes.get("sequence", []) as Array).size() >= 3, "enemy_006 rotation should list all three modes")

	var stage_db := StageDBScript.new()
	var stage: Dictionary = stage_db.get_stage("stage_3_3")
	_expect(stage.get("enemyAttackModes", null) is Dictionary, "stage_3_3 should expose enemyAttackModes in level data")
	var overrides: Dictionary = stage.get("enemyAttackModes", {})
	_expect(overrides.has("enemy_008"), "stage_3_3 should override enemy_008 selection")

	var early: Dictionary = MonsterDbScript.get_monster_stats("enemy_001", 1)
	_expect(early.get("attackModes", null) == null, "early tutorial enemy should stay on default strike")


func _test_rotation_and_stage_override() -> void:
	var rotation := EnemyAttackModesScript.new()
	rotation.init([{
		"id": "test_rotator",
		"attackModes": {
			"select": "rotation",
			"sequence": ["strike", "charge", "sweep"],
			"chargeMultiplier": 1.9,
			"sweepMultiplier": 0.5
		}
	}], null)
	var types: Array = []
	for _i in range(5):
		types.append(str(rotation.consume_turn(0).get("type", "")))
	_expect(types == ["strike", "charge", "charge_release", "sweep", "strike"], "rotation should run strike -> charge -> release -> sweep, got %s" % str(types))

	var override := EnemyAttackModesScript.new()
	override.init([{
		"id": "test_override",
		"attackModes": {"select": "rotation", "sequence": ["strike"]}
	}], {
		"enemyAttackModes": {
			"test_override": {"select": "rotation", "sequence": ["sweep"]}
		}
	})
	_expect(str(override.consume_turn(0).get("type", "")) == "sweep", "stage-level enemyAttackModes should override monster data")


func _test_weighted_selection() -> void:
	var weighted := EnemyAttackModesScript.new()
	weighted.init([{
		"id": "test_weighted",
		"attackModes": {
			"select": "weight",
			"weighted": [
				{"type": "strike", "weight": 1},
				{"type": "charge", "weight": 1, "multiplier": 1.9},
				{"type": "sweep", "weight": 1, "multiplier": 0.5}
			]
		}
	}], null)
	seed(424242)
	var seen: Dictionary = {}
	for _i in range(400):
		var mode := weighted.consume_turn(0)
		var mode_type := str(mode.get("type", ""))
		if mode_type == EnemyAttackModesScript.MODE_CHARGE_RELEASE:
			continue
		seen[mode_type] = true
	_expect(seen.has("strike"), "weighted selection should be able to pick strike")
	_expect(seen.has("charge"), "weighted selection should be able to pick charge")
	_expect(seen.has("sweep"), "weighted selection should be able to pick sweep")


func _test_strike_behavior() -> void:
	var battle = BattleManagerScript.new()
	battle.init(TEAM, ["enemy_001"], 5, 1, StageDBScript.new().get_stage("stage_1_1"), "stage_1_1")
	_force_high_hp(battle)
	var result: Dictionary = battle.enemy_action()
	var actions: Array = result.get("actions", [])
	_expect(actions.size() == 1, "strike should resolve exactly one target, got %d actions" % actions.size())
	if actions.size() == 1:
		_expect(str(actions[0].get("attack_mode", "")) == "strike", "default enemy should report strike mode")
		_expect(int(actions[0].get("damage", 0)) > 0, "strike should deal damage")
		_expect(actions[0].has("target_index"), "strike action should expose target_index")
	battle.free()


func _test_charge_behavior() -> void:
	var stage: Dictionary = StageDBScript.new().get_stage("stage_3_3")
	var battle = BattleManagerScript.new()
	battle.init(TEAM, ["enemy_006"], 5, 20, stage, "stage_3_3")
	_force_high_hp(battle)

	# 第 1 回合：轮次从 strike 开始，正常单体重击。
	var first: Dictionary = battle.enemy_action()
	var first_actions: Array = first.get("actions", [])
	_expect(first_actions.size() == 1, "charge rotation should start with one single-target strike")
	_expect(str(first_actions[0].get("attack_mode", "")) == "strike", "first rotation turn should be strike")

	# 第 2 回合：蓄力，不出伤。
	var hp_before_charge := _team_hp(battle)
	var second: Dictionary = battle.enemy_action()
	var second_actions: Array = second.get("actions", [])
	_expect(second_actions.size() == 1, "charge turn should still produce one action entry")
	if second_actions.size() == 1:
		_expect(bool(second_actions[0].get("is_charging", false)), "charge turn should flag is_charging")
		_expect(str(second_actions[0].get("attack_mode", "")) == "charge", "charge turn should report charge mode")
		_expect(int(second_actions[0].get("damage", 0)) == 0, "charge turn should not deal damage")
	_expect(_team_hp(battle) == hp_before_charge, "charge turn must not change party HP")

	# 第 3 回合：释放蓄力，单体重击并标记 1.9x。
	var third: Dictionary = battle.enemy_action()
	var third_actions: Array = third.get("actions", [])
	_expect(third_actions.size() == 1, "charge release should hit exactly one target")
	if third_actions.size() == 1:
		_expect(str(third_actions[0].get("attack_mode", "")) == "charge_release", "release turn should report charge_release")
		_expect(bool(third_actions[0].get("is_charged", false)), "release turn should flag is_charged")
		_expect(is_equal_approx(float(third_actions[0].get("charge_multiplier", 0.0)), 1.9), "release turn should use configured 1.9x")
		_expect(int(third_actions[0].get("damage", 0)) > 0, "release turn should deal damage")
	battle.free()


func _test_sweep_behavior() -> void:
	var stage: Dictionary = StageDBScript.new().get_stage("stage_3_3")
	var battle = BattleManagerScript.new()
	battle.init(TEAM, ["enemy_007"], 5, 20, stage, "stage_3_3")
	_force_high_hp(battle)
	battle.player_team[2]["hp"] = 0
	var hp_before: Array = battle.player_team.map(func(m): return int(m.get("hp", 0)))
	_force_mode(battle, "sweep")

	var result: Dictionary = battle.enemy_action()
	var actions: Array = result.get("actions", [])
	_expect(actions.size() == 2, "sweep should hit every living ally (2 alive), got %d" % actions.size())
	var hit_indices: Array = []
	for action: Dictionary in actions:
		hit_indices.append(int(action.get("target_index", -1)))
		_expect(bool(action.get("is_aoe", false)), "sweep action should flag is_aoe")
		_expect(int(action.get("damage", 0)) > 0, "sweep should deal damage to each living ally")
		_expect(is_equal_approx(float(action.get("sweep_multiplier", 0.0)), 0.5), "sweep should report 0.5x multiplier")
	hit_indices.sort()
	_expect(hit_indices == [0, 1], "sweep should skip the defeated ally, got %s" % str(hit_indices))
	_expect(int(battle.player_team[2].get("hp", 0)) == 0, "sweep should not revive or damage a defeated ally")
	_expect(int(battle.player_team[0].get("hp", 0)) < hp_before[0], "sweep should damage ally 0")
	_expect(int(battle.player_team[1].get("hp", 0)) < hp_before[1], "sweep should damage ally 1")
	battle.free()


func _test_charge_and_sweep_multipliers() -> void:
	# 同一敌人、同一随机种子下比较强制 strike 与 charge_release 的实际伤害。
	var strike_battle = _build_forced_battle("strike")
	seed(20261109)
	var strike_action: Dictionary = strike_battle.enemy_action().get("actions", [{}])[0]
	var strike_damage := int(strike_action.get("damage", 0))
	strike_battle.free()

	var release_battle = _build_forced_battle("charge_release")
	seed(20261109)
	var release_action: Dictionary = release_battle.enemy_action().get("actions", [{}])[0]
	var release_damage := int(release_action.get("damage", 0))
	release_battle.free()

	_expect(strike_damage > 0 and release_damage > 0, "both strike and charge release should deal damage")
	if strike_damage > 0 and release_damage > 0:
		var ratio := float(release_damage) / float(strike_damage)
		_expect(ratio >= 1.75 and ratio <= 2.05, "charge release should be about 1.8-2.0x strike, got %.2f" % ratio)

	var sweep_battle = _build_forced_battle("sweep")
	battle_set_single_alive(sweep_battle)
	sweep_battle.get("_attack_modes").call("force_next_mode", 0, "sweep")
	seed(20261109)
	var sweep_actions: Array = sweep_battle.enemy_action().get("actions", [])
	_expect(sweep_actions.size() == 1, "single living ally should receive one sweep hit")
	if sweep_actions.size() == 1:
		_expect(is_equal_approx(float(sweep_actions[0].get("sweep_multiplier", 0.0)), 0.5), "sweep multiplier should be 0.5")
	sweep_battle.free()


func _test_windup_cues() -> void:
	var battle = _build_forced_battle("strike")
	var modes = battle.get("_attack_modes")
	modes.call("force_next_mode", 0, "strike")
	var strike_cue: Dictionary = battle.get_enemy_windup_cues().get(0, {})
	_expect(str(strike_cue.get("style", "")) == "strike", "normal windup should use strike style")
	_expect(str(strike_cue.get("label", "")) == "普攻", "normal windup should label as basic attack")

	modes.call("force_next_mode", 0, "charge")
	var charge_cue: Dictionary = battle.get_enemy_windup_cues().get(0, {})
	_expect(str(charge_cue.get("style", "")) == "charge", "charge windup should use charge style")
	_expect(str(charge_cue.get("label", "")) == "蓄力", "charge windup should label as charge")

	modes.call("force_next_mode", 0, "charge_release")
	var release_cue: Dictionary = battle.get_enemy_windup_cues().get(0, {})
	_expect(str(release_cue.get("style", "")) == "charge", "charge release windup should keep charge style")

	modes.call("force_next_mode", 0, "sweep")
	var sweep_cue: Dictionary = battle.get_enemy_windup_cues().get(0, {})
	_expect(str(sweep_cue.get("style", "")) == "sweep", "sweep windup should use sweep style")
	_expect(str(sweep_cue.get("label", "")) == "全体攻击", "sweep windup should label as all-party attack")

	var strike_color: Color = BattleCombatantRendererScript.windup_style_color("strike")
	var charge_color: Color = BattleCombatantRendererScript.windup_style_color("charge")
	var sweep_color: Color = BattleCombatantRendererScript.windup_style_color("sweep")
	_expect(strike_color != charge_color, "charge windup color must differ from normal")
	_expect(charge_color != sweep_color, "charge and sweep windup colors must differ")
	_expect(strike_color != sweep_color, "sweep windup color must differ from normal")
	battle.free()


func _test_intent_types() -> void:
	var charge_intent: Dictionary = EnemyIntentRulesScript.build_enemy_intent({}, {}, {}, {"type": "charge", "multiplier": 1.9})
	_expect(str(charge_intent.get("type", "")) == "charge_windup", "charge mode should expose charge_windup intent")
	_expect(str(charge_intent.get("label", "")) == "蓄力", "charge intent should be labelled 蓄力")

	var release_intent: Dictionary = EnemyIntentRulesScript.build_enemy_intent({}, {}, {}, {"type": "charge_release", "multiplier": 1.9})
	_expect(str(release_intent.get("type", "")) == "charge_release", "release mode should expose charge_release intent")

	var sweep_intent: Dictionary = EnemyIntentRulesScript.build_enemy_intent({}, {}, {}, {"type": "sweep", "multiplier": 0.5})
	_expect(str(sweep_intent.get("type", "")) == "sweep", "sweep mode should expose sweep intent")
	_expect(str(sweep_intent.get("label", "")) == "全体攻击", "sweep intent should be labelled 全体攻击")


func _test_scene_windup_state() -> void:
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var stage_db := StageDBScript.new()
	main.switch_scene("battle", {
		"stageId": "stage_1_1",
		"stageData": stage_db.get_stage("stage_1_1"),
		"inputTestOnly": true,
	})
	await process_frame
	var battle_scene: Control = main.get_current_scene()
	_expect(battle_scene != null, "battle scene should load")
	if battle_scene == null:
		main.queue_free()
		return
	var battle = battle_scene.get("_battle")
	if battle != null:
		var modes = battle.get("_attack_modes")
		if modes != null:
			modes.call("force_next_mode", 0, "charge")
	battle_scene.call("_start_enemy_turn")
	await process_frame
	var cues: Dictionary = battle_scene.get("_enemy_windup_cues")
	_expect(cues.get(0, {}).get("style", "") == "charge", "battle scene should store the charge windup cue")
	var render_state: Dictionary = battle_scene.call("_combatant_render_state")
	_expect(render_state.get("enemy_windup_cues", {}).get(0, {}).get("style", "") == "charge", "render state should expose the charge windup cue")
	await create_timer(0.8).timeout
	main.queue_free()
	await process_frame


func _build_forced_battle(mode_type: String):
	var stage: Dictionary = StageDBScript.new().get_stage("stage_3_3")
	var battle = BattleManagerScript.new()
	battle.init(TEAM, ["enemy_006"], 5, 20, stage, "stage_3_3")
	_force_high_hp(battle)
	_force_mode(battle, mode_type)
	return battle


func _force_mode(battle, mode_type: String) -> void:
	var modes = battle.get("_attack_modes")
	if modes != null:
		modes.call("force_next_mode", 0, mode_type)


func battle_set_single_alive(battle) -> void:
	battle.player_team[1]["hp"] = 0
	battle.player_team[2]["hp"] = 0


func _force_high_hp(battle) -> void:
	for monster: Dictionary in battle.player_team:
		monster["maxHP"] = 99999
		monster["hp"] = 99999


func _team_hp(battle) -> int:
	var total := 0
	for monster: Dictionary in battle.player_team:
		total += maxi(0, int(monster.get("hp", 0)))
	return total


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[EnemyAttackModes] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[EnemyAttackModes] " + failure)
	quit(1)
