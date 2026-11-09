extends SceneTree

## 固定种子战局转录：供准备页属性克制改动前后逐字节比对。
## 本脚本不读取准备页代码，基线 893c7a1 与改动后分支应输出完全相同的 JSON。
##
## 用法：
##   Godot --headless --path . --script res://tests/prepare_matchup_transcript.gd \
##     -- --output=/tmp/prepare_matchup_battle.json

const StageDBScript = preload("res://src/data/stage_db.gd")
const BattleManagerScript = preload("res://src/battle/battle_manager.gd")

const BATTLE_SEED := 20261111
const STAGE_ID := "stage_1_1"
const PLAYER_LEVEL := 5
const ENEMY_LEVEL := 1
const MAX_TURNS := 40
const TEAM := ["monster_001", "monster_002", "monster_003"]
const MATCH_COLORS := ["fire", "water", "grass", "thunder", "light"]


func _init() -> void:
	var json := build_payload_json()
	var output := _read_arg("--output=")
	if output.is_empty():
		print(json)
		quit(0)
		return
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		push_error("[PrepareMatchupTranscript] cannot write %s" % output)
		quit(1)
		return
	file.store_string(json)
	file.close()
	print("[PrepareMatchupTranscript] wrote %s" % output)
	quit(0)


static func build_payload_json() -> String:
	seed(BATTLE_SEED)
	var stage_db = StageDBScript.new()
	var battle = BattleManagerScript.new()
	battle.init(TEAM, ["enemy_001"], PLAYER_LEVEL, ENEMY_LEVEL, stage_db.get_stage(STAGE_ID), STAGE_ID)
	battle.max_turns = MAX_TURNS

	var damage_logs: Array = []
	var taken_logs: Array = []
	battle.damage_dealt.connect(func(info: Dictionary): damage_logs.append(info.duplicate(true)))
	battle.enemy_attacked.connect(func(info: Dictionary): taken_logs.append(info.duplicate(true)))

	var turns := 0
	while not battle.battle_over and turns < MAX_TURNS:
		turns += 1
		battle.turn_count = turns
		var color: String = MATCH_COLORS[(turns - 1) % MATCH_COLORS.size()]
		battle.process_match_result({color: 3}, 2)
		if battle.check_battle_end():
			break
		battle.enemy_action()

	var payload := {
		"seed": BATTLE_SEED,
		"stage_id": STAGE_ID,
		"turns": battle.turn_count,
		"damage_dealt_log": damage_logs,
		"damage_taken_log": taken_logs,
		"result": battle.get_battle_result(),
	}
	var json := JSON.stringify(payload, "\t")
	battle.free()
	return json


func _read_arg(prefix: String) -> String:
	var args := OS.get_cmdline_args()
	args.append_array(OS.get_cmdline_user_args())
	for arg: String in args:
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return ""
