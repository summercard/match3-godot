extends SceneTree

## 音频混音总线改动的固定战局基线（只调用受保护的战斗模块，不引用任何音频代码）。
##
## 基线 e36fa13 与本分支的同一脚本应输出逐位一致的 JSON；
## `audio_mix_bus_test.gd` 在四种音频开关状态下跑同一战局，并把战斗日志与
## 结算 JSON 与本脚本生成的基线逐字节比对。
##
## 用法：
##   Godot --headless --path . --script res://tests/audio_mix_bus_battle_baseline.gd \
##     -- --output=tests/fixtures/audio_mix_bus_battle_baseline.json

const StageDBScript = preload("res://src/data/stage_db.gd")
const BattleManagerScript = preload("res://src/battle/battle_manager.gd")

const BATTLE_SEED := 20261109
const STAGE_ID := "stage_1_1"
const PLAYER_LEVEL := 5
const ENEMY_LEVEL := 1
const ENEMY_HP := 900
const MAX_TURNS := 50
const LOOP_TURNS := 20
const TEAM := ["monster_001", "monster_002", "monster_003"]
const MATCH_COLORS := {"fire": 3, "water": 3, "grass": 3}
const COMBOS := [4, 3, 2, 1]


func _init() -> void:
	var json := build_payload_json()
	var output := _read_arg("--output=")
	if output.is_empty():
		print(json)
		quit(0)
		return
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		push_error("[AudioMixBaseline] cannot write %s" % output)
		quit(1)
		return
	file.store_string(json)
	file.close()
	print("[AudioMixBaseline] wrote %s bytes=%d" % [output, json.length()])
	quit(0)


## 固定种子战局；`on_damage` / `on_taken` 允许测试在伤害事件上触发音效，
## 回调不得消耗全局随机数，否则会改变战斗结果。
static func build_payload_json(on_damage: Callable = Callable(), on_taken: Callable = Callable()) -> String:
	seed(BATTLE_SEED)
	var stage_db = StageDBScript.new()
	var battle = BattleManagerScript.new()
	battle.init(
		TEAM.duplicate(),
		["enemy_001"],
		PLAYER_LEVEL,
		ENEMY_LEVEL,
		stage_db.get_stage(STAGE_ID),
		STAGE_ID
	)
	battle.enemies[0]["maxHP"] = ENEMY_HP
	battle.enemies[0]["hp"] = ENEMY_HP
	battle.max_turns = MAX_TURNS

	var damage_logs: Array = []
	var taken_logs: Array = []
	battle.damage_dealt.connect(func(info: Dictionary):
		damage_logs.append(info.duplicate(true))
		if on_damage.is_valid():
			on_damage.call(info)
	)
	battle.enemy_attacked.connect(func(info: Dictionary):
		taken_logs.append(info.duplicate(true))
		if on_taken.is_valid():
			on_taken.call(info)
	)

	var turns: Array = []
	for turn in range(1, LOOP_TURNS + 1):
		battle.turn_count = turn
		var combo := int(COMBOS[(turn - 1) % COMBOS.size()])
		var result: Dictionary = battle.process_match_result(MATCH_COLORS, combo)
		turns.append({
			"turn": turn,
			"combo": combo,
			"damage_log": result.get("damage_log", []),
		})
		if battle.check_battle_end():
			break
		var enemy: Dictionary = battle.enemy_action()
		turns[turns.size() - 1]["actions"] = enemy.get("actions", [])
		if battle.battle_over:
			break

	var payload := {
		"seed": BATTLE_SEED,
		"stage_id": STAGE_ID,
		"turns": turns,
		"damage_dealt_log": damage_logs,
		"damage_taken_log": taken_logs,
		"result": battle.get_battle_result(),
	}
	var json := JSON.stringify(payload, "\t")
	battle.free()
	return json


static func _read_arg(prefix: String) -> String:
	var args := OS.get_cmdline_args()
	args.append_array(OS.get_cmdline_user_args())
	for arg: String in args:
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return ""
