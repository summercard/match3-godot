extends SceneTree

## 生成三消元素飞行特效验收用的 a322404 基线战斗日志与结算 JSON。
## 用法（a322404 工作树）：
##   Godot --headless --path . --script res://tests/element_flight_baseline.gd -- \
##     --output=res://docs/qa/element_flight/baseline_combat_log.json
## 固定 stage_1_1、seed 20261109、20 回合脚本输入；只读 BattleManager，
## 不经过任何表现层代码。

const BattleManagerScript = preload("res://src/battle/battle_manager.gd")
const StageDBScript = preload("res://src/data/stage_db.gd")

var _output := "res://docs/qa/element_flight/baseline_combat_log.json"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			_output = arg.trim_prefix("--output=")
	var payload := _run_deterministic_battle()
	var file := FileAccess.open(_output, FileAccess.WRITE)
	if file == null:
		push_error("[ElementFlightBaseline] cannot write %s" % _output)
		quit(1)
		return
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	print("[ElementFlightBaseline] %s" % ProjectSettings.globalize_path(_output))
	quit(0)


func _run_deterministic_battle() -> Dictionary:
	seed(20261109)
	var stage: Dictionary = StageDBScript.new().get_stage("stage_1_1")
	var battle = BattleManagerScript.new()
	battle.init(["monster_001", "monster_002", "monster_003"], ["enemy_001"], 5, 1, stage, "stage_1_1")
	battle.enemies[0]["maxHP"] = 900
	battle.enemies[0]["hp"] = 900
	battle.max_turns = 50

	var damage_logs: Array = []
	var taken_logs: Array = []
	battle.damage_dealt.connect(func(info: Dictionary): damage_logs.append(info.duplicate(true)))
	battle.enemy_attacked.connect(func(info: Dictionary): taken_logs.append(info.duplicate(true)))

	var combos: Array = [4, 3, 2, 1]
	var turns: Array = []
	for turn in range(1, 21):
		battle.turn_count = turn
		var combo := int(combos[(turn - 1) % combos.size()])
		var result: Dictionary = battle.process_match_result({"fire": 3, "water": 3, "grass": 3}, combo)
		turns.append({
			"turn": turn,
			"combo": combo,
			"damage_log": result.get("damage_log", [])
		})
		if battle.check_battle_end():
			break
		var enemy: Dictionary = battle.enemy_action()
		turns[turns.size() - 1]["actions"] = enemy.get("actions", [])
		if battle.battle_over:
			break

	var result: Dictionary = battle.get_battle_result()
	var payload := {
		"source_commit": "a322404",
		"seed": 20261109,
		"stage_id": "stage_1_1",
		"player_level": 5,
		"enemy_level": 1,
		"turns": turns,
		"damage_dealt_log": damage_logs,
		"damage_taken_log": taken_logs,
		"battle_result": result
	}
	battle.free()
	return payload
