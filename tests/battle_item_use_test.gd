extends SceneTree

## 战斗内道具（HP 药水）回归：
## 1. 顶栏道具按钮打开面板，面板只列 type="battle" 道具，且不覆盖棋盘；
## 2. 数量 0 时点击不扣数量、不推进回合、不改血量、不报错；
## 3. 用 1 个药水：总量恰为 healRatio × 存活伙伴 maxHP 之和，数量 N→N-1 并落盘；
## 4. 使用道具消耗一回合：回合数 +1，之后敌人正常前摇并出手一次；
## 5. 2x 倍速下使用道具后暂停/继续，时间尺度与回合结算不被改乱；
## 6. 全程不用道具时，固定种子转录与 b07a03e 基线逐字节一致。
##
## 用法：
##   MATCH3_SAVE_PATH=/tmp/match3_item_test.cfg \
##   Godot --headless --path . --fixed-fps 60 --script res://tests/battle_item_use_test.gd

const StageDBScript = preload("res://src/data/stage_db.gd")
const TranscriptScript = preload("res://tests/prepare_matchup_transcript.gd")

const SEED := 20261111
const ITEM_ID := "hp_potion"
const STATE_IDLE := 0
const STATE_MATCHING := 2
const STATE_ENEMY_TURN := 4
const STATE_BATTLE_END := 6
const BASELINE_TRANSCRIPT_SHA256 := "0d6d3c718332bd2a09e2bf44b9f1116d23d6fd962216cc3fa77fb93153490adb"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_panel_and_zero_count()
	await _test_use_potion_turn_and_persist()
	await _test_zero_after_last_potion()
	await _test_use_under_2x_and_pause()
	_test_fixed_seed_transcript()
	_finish()


## ============================================
## 1. 面板、列表过滤与数量 0
## ============================================

func _test_panel_and_zero_count() -> void:
	_prepare_save({ITEM_ID: 0, "capture_ball": 3})
	var main := await _load_main()
	await _enter_battle(main, SEED)
	var battle: Control = main.get_current_scene()
	var board = battle.get("_board")
	var bm = battle.get("_battle")
	var items: Array = battle.call("get_battle_items")
	_expect(items.size() == 1, "面板应只列出 type=battle 的道具，实际 %d 项" % items.size())
	if items.size() == 1:
		_expect(str(items[0].get("id", "")) == ITEM_ID, "唯一战斗道具应为 hp_potion")
		_expect(int(items[0].get("count", -1)) == 0, "数量 0 的道具也应保留在列表中")
	_send_mouse_click(battle, (battle.call("_get_item_button_rect") as Rect2).get_center())
	await process_frame
	_expect(bool(battle.call("is_item_panel_open")), "点击道具按钮应展开列表")
	var panel: Rect2 = battle.call("_get_item_panel_rect")
	_expect(panel.end.y <= float(board.offset_y), "道具面板不应压住棋盘（panel_end=%.1f board_top=%.1f）" % [panel.end.y, float(board.offset_y)])
	_expect(panel.has_point((battle.call("_get_item_row_rect", 0) as Rect2).get_center()), "面板首行应落在面板内")

	var hp_before := _team_hp(bm)
	var turn_before := int(bm.turn_count)
	var hits := [0]
	bm.enemy_attacked.connect(func(_info: Dictionary): hits[0] += 1)
	_send_mouse_click(battle, (battle.call("_get_item_row_rect", 0) as Rect2).get_center())
	await process_frame
	await process_frame
	_expect(int(_inventory().get(ITEM_ID, 0)) == 0, "数量 0 时点击不应改变背包数量")
	_expect(_team_hp(bm) == hp_before, "数量 0 时点击不应改变血量")
	_expect(int(bm.turn_count) == turn_before, "数量 0 时点击不应推进回合")
	_expect(int(battle.get("_state")) == STATE_IDLE, "数量 0 时点击后仍应停留在玩家回合")
	_expect(hits[0] == 0, "数量 0 时点击不应触发敌方行动")
	_expect(bool(battle.call("is_item_panel_open")), "数量 0 的点击只应被忽略，面板保持打开")
	_send_mouse_click(battle, (battle.call("_get_item_close_rect") as Rect2).get_center())
	await process_frame
	_expect(not bool(battle.call("is_item_panel_open")), "点击关闭按钮应收起面板")
	print("[BattleItem] zero_count count=%d turn=%d hp=%d state=%d enemy_hits=%d panel_above_board=true" % [
		int(_inventory().get(ITEM_ID, 0)), int(bm.turn_count), _team_hp(bm),
		int(battle.get("_state")), hits[0],
	])
	await _free_main(main)


## ============================================
## 2. 使用 1 个药水：回血、扣数量、落盘、消耗回合、敌方出手
## ============================================

func _test_use_potion_turn_and_persist() -> void:
	_prepare_save({ITEM_ID: 2, "capture_ball": 3})
	var main := await _load_main()
	await _enter_battle(main, SEED)
	var battle: Control = main.get_current_scene()
	var bm = battle.get("_battle")
	_damage_team_to(bm, 0.2)
	var total_max := _living_max_hp_total(bm)
	var hp_before := _team_hp(bm)
	var turn_before := int(bm.turn_count)
	var hits := [0]
	bm.enemy_attacked.connect(func(_info: Dictionary): hits[0] += 1)

	_send_mouse_click(battle, (battle.call("_get_item_button_rect") as Rect2).get_center())
	await process_frame
	_send_mouse_click(battle, (battle.call("_get_item_row_rect", 0) as Rect2).get_center())
	await process_frame
	await process_frame

	var expected_heal := int(total_max * 0.5)
	var healed := _team_hp(bm) - hp_before
	_expect(healed == expected_heal,
		"1 个药水应回 0.5 × 存活 maxHP 之和 = %d，实际 %d" % [expected_heal, healed])
	_expect(int(_inventory().get(ITEM_ID, 0)) == 1, "使用后内存背包数量应从 2 变 1")
	_expect(_disk_inventory_count(ITEM_ID) == 1, "使用后落盘数量应从 2 变 1")
	_expect(int(bm.turn_count) == turn_before + 1, "使用道具应消耗 1 回合")
	_expect(int(battle.get("_state")) == STATE_MATCHING, "使用道具后应先进入回血停顿")
	_expect(not bool(battle.call("is_item_panel_open")), "使用后应自动收起面板")
	for i in range(bm.player_team.size()):
		var m: Dictionary = bm.player_team[i]
		if m == null or m.is_empty():
			continue
		_expect(int(m.get("hp", 0)) <= int(m.get("maxHP", 0)), "回血后伙伴 %d 不应超过 maxHP" % i)

	var windup_seen := [false]
	var deadline := Time.get_ticks_msec() + 8000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if int(battle.get("_state")) == STATE_ENEMY_TURN and float(battle.get("_enemy_windup_timer")) > 0.0:
			windup_seen[0] = true
			break
	_expect(windup_seen[0], "道具回合之后应照常出现敌方前摇")
	_expect(hits[0] == 0, "敌方前摇期间不应已经出手")
	var wait_deadline := Time.get_ticks_msec() + 15000
	while Time.get_ticks_msec() < wait_deadline:
		await process_frame
		var state := int(battle.get("_state"))
		if state == STATE_IDLE or state == STATE_BATTLE_END:
			break
	_expect(hits[0] == 1, "一个道具回合之后 stage_1_1 的敌人应正常出手一次，实际 %d" % hits[0])
	_expect(int(bm.turn_count) == turn_before + 1, "敌方出手不应再额外推进回合")
	print("[BattleItem] use count=2->1 turn=%d->%d heal=%d/%d ratio=0.5 windup=%s enemy_hits=%d" % [
		turn_before, int(bm.turn_count), healed, expected_heal, str(windup_seen[0]), hits[0],
	])
	await _free_main(main)

	# 重新进战斗，确认数量来自落盘存档。
	var main_again := await _load_main()
	await _enter_battle(main_again, SEED)
	var battle_again: Control = main_again.get_current_scene()
	var items_again: Array = battle_again.call("get_battle_items")
	_expect(items_again.size() == 1 and int(items_again[0].get("count", -1)) == 1,
		"重新进入战斗后应从存档读回数量 1")
	print("[BattleItem] persisted count=%d" % (int(items_again[0].get("count", -1)) if items_again.size() > 0 else -1))
	await _free_main(main_again)


## ============================================
## 3. 用完最后一个后，数量 0 再点仍无副作用
## ============================================

func _test_zero_after_last_potion() -> void:
	_prepare_save({ITEM_ID: 1})
	var main := await _load_main()
	await _enter_battle(main, SEED)
	var battle: Control = main.get_current_scene()
	var bm = battle.get("_battle")
	_damage_team_to(bm, 0.2)
	var hits := [0]
	bm.enemy_attacked.connect(func(_info: Dictionary): hits[0] += 1)
	_send_mouse_click(battle, (battle.call("_get_item_button_rect") as Rect2).get_center())
	await process_frame
	_send_mouse_click(battle, (battle.call("_get_item_row_rect", 0) as Rect2).get_center())
	var wait_deadline := Time.get_ticks_msec() + 15000
	while Time.get_ticks_msec() < wait_deadline:
		await process_frame
		var state := int(battle.get("_state"))
		if state == STATE_IDLE or state == STATE_BATTLE_END:
			break
	var count_after_use := int(_inventory().get(ITEM_ID, 0))
	var turn_after_use := int(bm.turn_count)
	var hp_after_use := _team_hp(bm)
	var hits_after_use: int = hits[0]
	_expect(count_after_use == 0, "最后一个药水用完后数量应为 0")
	_expect(hits_after_use == 1, "用完最后一个药水的回合敌人应出手一次")

	_send_mouse_click(battle, (battle.call("_get_item_button_rect") as Rect2).get_center())
	await process_frame
	var items: Array = battle.call("get_battle_items")
	_expect(items.size() == 1 and int(items[0].get("count", -1)) == 0, "用完后列表中应保留灰显的 x0 行")
	_send_mouse_click(battle, (battle.call("_get_item_row_rect", 0) as Rect2).get_center())
	await process_frame
	await process_frame
	_expect(int(_inventory().get(ITEM_ID, 0)) == 0, "用完后再次点击不应改变数量")
	_expect(int(bm.turn_count) == turn_after_use, "用完后再次点击不应推进回合")
	_expect(_team_hp(bm) == hp_after_use, "用完后再次点击不应改变血量")
	_expect(hits[0] == hits_after_use, "用完后再次点击不应触发敌方行动")
	print("[BattleItem] zero_after_last count=%d turn=%d hp=%d enemy_hits=%d" % [
		count_after_use, turn_after_use, hp_after_use, hits_after_use,
	])
	await _free_main(main)


## ============================================
## 4. 2x 倍速 + 暂停
## ============================================

func _test_use_under_2x_and_pause() -> void:
	_prepare_save({ITEM_ID: 2})
	var main := await _load_main()
	await _enter_battle(main, SEED)
	var battle: Control = main.get_current_scene()
	var bm = battle.get("_battle")
	_damage_team_to(bm, 0.2)
	var hp_before := _team_hp(bm)
	var turn_before := int(bm.turn_count)
	var hits := [0]
	bm.enemy_attacked.connect(func(_info: Dictionary): hits[0] += 1)
	battle.call("set_battle_speed", 2)
	_expect(is_equal_approx(Engine.time_scale, 2.0), "2x 倍速应写入 Engine.time_scale=2")

	_send_mouse_click(battle, (battle.call("_get_item_button_rect") as Rect2).get_center())
	await process_frame
	_send_mouse_click(battle, (battle.call("_get_item_row_rect", 0) as Rect2).get_center())
	await process_frame
	var hp_after_use := _team_hp(bm)
	_expect(hp_after_use > hp_before, "2x 下使用药水仍应回血")
	_expect(is_equal_approx(Engine.time_scale, 2.0), "使用道具不应改变 2x 时间尺度")

	# 回血停顿期间打开暂停；计时器应冻结，敌人不能出手。
	_send_mouse_click(battle, (battle.call("_get_settings_button_rect") as Rect2).get_center())
	await process_frame
	_expect(bool(battle.call("is_paused")), "道具回合中应能打开暂停")
	_expect(is_equal_approx(Engine.time_scale, 0.0), "暂停后时间尺度应为 0")
	var freeze_start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - freeze_start < 600:
		await process_frame
	_expect(hits[0] == 0, "暂停期间道具回合不应继续到敌方出手")
	_expect(int(bm.turn_count) == turn_before + 1, "暂停期间回合数不应变化")
	_expect(_team_hp(bm) == hp_after_use, "暂停期间回血结果不应被重复结算")
	_expect(int(battle.get("_state")) == STATE_MATCHING, "暂停期间应停在道具回合的回血停顿")

	var overlay = battle.get("_pause_overlay")
	_send_mouse_click(battle, (overlay.call("resume_rect") as Rect2).get_center())
	await process_frame
	_expect(not bool(battle.call("is_paused")), "继续后应退出暂停")
	_expect(is_equal_approx(Engine.time_scale, 2.0), "继续后应恢复 2x 时间尺度")
	var wait_deadline := Time.get_ticks_msec() + 15000
	while Time.get_ticks_msec() < wait_deadline:
		await process_frame
		var state := int(battle.get("_state"))
		if state == STATE_IDLE or state == STATE_BATTLE_END:
			break
	_expect(hits[0] == 1, "2x + 暂停后敌人仍应只出手一次，实际 %d" % hits[0])
	_expect(int(bm.turn_count) == turn_before + 1, "2x + 暂停后回合数仍应只 +1")
	_expect(_team_hp(bm) <= _living_max_hp_total(bm), "2x + 暂停后血量不应溢出 maxHP")
	_expect(is_equal_approx(Engine.time_scale, 2.0), "整段流程结束后时间尺度应仍为 2x")
	print("[BattleItem] speed2x_pause heal=%d turn=%d enemy_hits=%d time_scale=%.2f" % [
		hp_after_use - hp_before, int(bm.turn_count), hits[0], Engine.time_scale,
	])
	await _free_main(main)
	_expect(is_equal_approx(Engine.time_scale, 1.0), "离开战斗后时间尺度应恢复 1.0")


## ============================================
## 5. 不用道具：固定种子转录与 b07a03e 逐字节一致
## ============================================

func _test_fixed_seed_transcript() -> void:
	var json: String = TranscriptScript.build_payload_json()
	var hash := json.sha256_text()
	_expect(hash == BASELINE_TRANSCRIPT_SHA256, "不用道具时固定种子转录应与 b07a03e 基线逐字节一致")
	var baseline_path := "res://docs/evidence/battle_pause/battle_before.json"
	if FileAccess.file_exists(baseline_path):
		var baseline := FileAccess.get_file_as_string(baseline_path)
		_expect(json == baseline, "转录内容应与基线文件完全一致")
	print("[BattleItem] fixed_seed_transcript sha256=%s baseline=%s bytes=%d" % [
		hash, BASELINE_TRANSCRIPT_SHA256, json.length(),
	])


## ============================================
## 公共辅助
## ============================================

func _prepare_save(inventory: Dictionary) -> void:
	var storage := _storage()
	storage.clear_all_data()
	var settings: Dictionary = storage.load_settings()
	settings["soundOn"] = true
	settings["musicOn"] = true
	settings["vibrationOn"] = true
	storage.save_settings(settings)
	storage.save_inventory(inventory.duplicate(true))


func _inventory() -> Dictionary:
	return _storage().load_inventory()


func _disk_inventory_count(item_id: String) -> int:
	var path := OS.get_environment("MATCH3_SAVE_PATH")
	if path.is_empty():
		path = ProjectSettings.globalize_path("user://test_save_game.cfg")
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return -1
	var inv: Variant = config.get_value("inventory", "data", {})
	if not inv is Dictionary:
		return -1
	return int((inv as Dictionary).get(item_id, 0))


func _damage_team_to(battle_manager, ratio: float) -> void:
	for m in battle_manager.player_team:
		if m == null or not m is Dictionary:
			continue
		var monster: Dictionary = m
		if int(monster.get("hp", 0)) <= 0:
			continue
		monster["hp"] = maxi(1, int(int(monster.get("maxHP", 1)) * ratio))


func _team_hp(battle_manager) -> int:
	var total := 0
	for m in battle_manager.player_team:
		if m == null or not m is Dictionary:
			continue
		total += maxi(0, int((m as Dictionary).get("hp", 0)))
	return total


func _living_max_hp_total(battle_manager) -> int:
	var total := 0
	for m in battle_manager.player_team:
		if m == null or not m is Dictionary:
			continue
		var monster: Dictionary = m
		if int(monster.get("hp", 0)) <= 0:
			continue
		total += int(monster.get("maxHP", 0))
	return total


func _enter_battle(main: Control, battle_seed: int = -1) -> void:
	if battle_seed >= 0:
		seed(battle_seed)
	var data := {
		"stageId": "stage_1_1",
		"stageData": StageDBScript.new().get_stage("stage_1_1"),
	}
	main.switch_scene("battle", data)
	await process_frame
	await process_frame


func _load_main() -> Control:
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	return main


func _free_main(main: Control) -> void:
	if is_instance_valid(main):
		main.queue_free()
	await process_frame
	await process_frame
	# 时间尺度由战斗场景的 _exit_tree 负责恢复；这里不再手动写入，便于断言。


func _storage() -> Node:
	return root.get_node("SaveManager")


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


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	Engine.time_scale = 1.0
	if _failures.is_empty():
		print("[BattleItem] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[BattleItem] " + failure)
	quit(1)
