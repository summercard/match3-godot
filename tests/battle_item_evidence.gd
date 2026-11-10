extends SceneTree

## 战斗内道具两态证据：同一固定种子、同一存档，分别跑「不用道具 / 用一次药水」。
## 输出 JSON 含战斗日志、回合数、队伍血量、背包数量与结算结果。
##
## 用法（先用 --prepare=1 创建固定队伍存档，再复用同一存档跑两态）：
##   MATCH3_SAVE_PATH=/tmp/item_evidence/save.cfg \
##   Godot --headless --path . --fixed-fps 60 --script res://tests/battle_item_evidence.gd -- \
##     --prepare=1 --use-item=0 --output=docs/evidence/battle_item_use/battle_unused.json

const StageDBScript = preload("res://src/data/stage_db.gd")

const SEED := 20261111
const STAGE_ID := "stage_1_1"
const ITEM_ID := "hp_potion"
const TEST_ENEMY_HP := 420
const MAX_BATTLE_MS := 180000
const STATE_IDLE := 0
const STATE_ENEMY_TURN := 4
const STATE_BATTLE_END := 6


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var use_item := _read_arg("--use-item=", "0") == "1"
	var output := _read_arg("--output=", "")
	var prepare := _read_arg("--prepare=", "0") == "1"
	var storage := root.get_node("SaveManager")
	if prepare:
		storage.clear_all_data()
		var player: Dictionary = storage.get_player()
		player["level"] = 5
		storage.save_player(player)
		# 首次准备时创建固定队伍并落盘，后续 baseline / 分支复用同一份实例。
		storage.get_team_battle_stats()
		storage.load_team()
	storage.save_inventory({ITEM_ID: 2, "capture_ball": 3})

	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	seed(SEED)
	main.switch_scene("battle", {
		"stageId": STAGE_ID,
		"stageData": StageDBScript.new().get_stage(STAGE_ID),
	})
	await process_frame
	await process_frame
	var battle: Control = main.get_current_scene()
	var bm = battle.get("_battle")
	var board = battle.get("_board")
	bm.enemies[0]["maxHP"] = TEST_ENEMY_HP
	bm.enemies[0]["hp"] = TEST_ENEMY_HP
	var damage_logs: Array = []
	var taken_logs: Array = []
	bm.damage_dealt.connect(func(info: Dictionary): damage_logs.append(info.duplicate(true)))
	bm.enemy_attacked.connect(func(info: Dictionary): taken_logs.append(info.duplicate(true)))

	var item_record: Dictionary = {"used": false}
	if use_item:
		var hits_before_item := taken_logs.size()
		item_record = await _use_one_item(battle, bm)
		var windup_seen := false
		var item_turn_deadline := Time.get_ticks_msec() + 20000
		while Time.get_ticks_msec() < item_turn_deadline:
			await process_frame
			if int(battle.get("_state")) == STATE_ENEMY_TURN and float(battle.get("_enemy_windup_timer")) > 0.0:
				windup_seen = true
			var state := int(battle.get("_state"))
			if state == STATE_IDLE or state == STATE_BATTLE_END:
				break
		item_record["windup_seen"] = windup_seen
		item_record["enemy_hits_after_item"] = taken_logs.size() - hits_before_item

	var actions := 0
	var start_ms := Time.get_ticks_msec()
	while int(battle.get("_state")) != STATE_BATTLE_END and Time.get_ticks_msec() - start_ms < MAX_BATTLE_MS:
		await process_frame
		if int(battle.get("_state")) != STATE_IDLE:
			continue
		var move := _find_valid_move(board)
		if move.is_empty():
			break
		battle.call("_do_swap", move["r1"], move["c1"], move["r2"], move["c2"])
		actions += 1
		await _wait_until_turn_idle(battle)

	var payload := {
		"seed": SEED,
		"stage_id": STAGE_ID,
		"enemy_max_hp": TEST_ENEMY_HP,
		"item_use": item_record,
		"moves": actions,
		"turns": int(bm.turn_count),
		"damage_dealt_log": damage_logs,
		"damage_taken_log": taken_logs,
		"team_hp_after": _team_hp(bm),
		"team_max_hp": _team_max_hp(bm),
		"inventory_after": storage.load_inventory(),
		"result": bm.get_battle_result(),
	}
	var json := JSON.stringify(payload, "\t")
	if output.is_empty():
		print(json)
	else:
		var file := FileAccess.open(output, FileAccess.WRITE)
		if file == null:
			push_error("[BattleItemEvidence] cannot write %s" % output)
			quit(1)
			return
		file.store_string(json)
		file.close()
		print("[BattleItemEvidence] wrote %s use_item=%s turns=%d actions=%d logs=%d/%d result=%s" % [
			output, str(use_item), int(bm.turn_count), actions,
			damage_logs.size(), taken_logs.size(), str(bm.get_battle_result().get("result", "")),
		])
	main.queue_free()
	await process_frame
	await process_frame
	quit(0)


func _use_one_item(battle: Control, bm) -> Dictionary:
	var hp_before: Array = []
	var max_hp: Array = []
	for m in bm.player_team:
		if m == null or not m is Dictionary:
			continue
		var monster: Dictionary = m
		if int(monster.get("hp", 0)) <= 0:
			continue
		monster["hp"] = maxi(1, int(int(monster.get("maxHP", 1)) * 0.2))
		hp_before.append(int(monster.get("hp", 0)))
		max_hp.append(int(monster.get("maxHP", 0)))
	var turn_before := int(bm.turn_count)
	var count_before := int(root.get_node("SaveManager").get_item_count(ITEM_ID))
	_send_mouse_click(battle, (battle.call("_get_item_button_rect") as Rect2).get_center())
	await process_frame
	_send_mouse_click(battle, (battle.call("_get_item_row_rect", 0) as Rect2).get_center())
	await process_frame
	await process_frame
	var hp_after: Array = []
	for m in bm.player_team:
		if m == null or not m is Dictionary:
			continue
		var monster: Dictionary = m
		if int(monster.get("maxHP", 0)) <= 0:
			continue
		hp_after.append(int(monster.get("hp", 0)))
	var total_max := 0
	for v in max_hp:
		total_max += int(v)
	var heal_total := 0
	for i in range(mini(hp_before.size(), hp_after.size())):
		heal_total += int(hp_after[i]) - int(hp_before[i])
	return {
		"used": true,
		"item_id": ITEM_ID,
		"count_before": count_before,
		"count_after": int(root.get_node("SaveManager").get_item_count(ITEM_ID)),
		"turn_before": turn_before,
		"turn_after_use": int(bm.turn_count),
		"hp_before": hp_before,
		"hp_after_use": hp_after,
		"max_hp": max_hp,
		"living_max_hp_total": total_max,
		"heal_total": heal_total,
		"expected_heal": int(total_max * 0.5),
		"state_after_use": int(battle.get("_state")),
	}


func _wait_until_turn_idle(battle: Control) -> void:
	var deadline := Time.get_ticks_msec() + 20000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var state := int(battle.get("_state"))
		if state == STATE_IDLE or state == STATE_BATTLE_END:
			return


func _find_valid_move(board) -> Dictionary:
	for r in range(board.rows):
		for c in range(board.cols):
			for delta in [Vector2i(1, 0), Vector2i(0, 1)]:
				var r2: int = r + delta.y
				var c2: int = c + delta.x
				if r2 < 0 or r2 >= board.rows or c2 < 0 or c2 >= board.cols:
					continue
				if not board.swap(r, c, r2, c2):
					continue
				var matched: bool = not board.find_matches().get("gems", []).is_empty()
				board.swap(r, c, r2, c2)
				if matched:
					return {"r1": r, "c1": c, "r2": r2, "c2": c2}
	return {}


func _team_hp(battle_manager) -> Array:
	var result: Array = []
	for m in battle_manager.player_team:
		if m == null or not m is Dictionary:
			continue
		result.append(int((m as Dictionary).get("hp", 0)))
	return result


func _team_max_hp(battle_manager) -> Array:
	var result: Array = []
	for m in battle_manager.player_team:
		if m == null or not m is Dictionary:
			continue
		result.append(int((m as Dictionary).get("maxHP", 0)))
	return result


func _send_mouse_click(battle_scene: Control, local_pos: Vector2) -> void:
	var transform := battle_scene.get_global_transform_with_canvas()
	var global_pos: Vector2 = transform * local_pos
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = global_pos
	battle_scene.call("_input", press)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = global_pos
	battle_scene.call("_input", release)


func _read_arg(prefix: String, fallback: String) -> String:
	var args := OS.get_cmdline_args()
	args.append_array(OS.get_cmdline_user_args())
	for arg: String in args:
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return fallback
