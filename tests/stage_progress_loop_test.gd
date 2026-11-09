extends SceneTree

## 主线首通闭环回归（headless 集成测试）：
## 1. 胜利后，结算页「下一关」进入 stage_1_2 的战斗链路（准备页 → 战斗），中途不卡住；
## 2. 回到关卡选择后，stage_1_1 显示星级、stage_1_2 由锁定变为可点；重启游戏（新进程）后仍是该状态；
## 3. 失败后「重打」回到同一关 stage_1_1，星级与解锁状态都不前进。
##
## 重启部分用 OS.execute 拉起一个新的 Godot 进程跑 --restart-phase，
## 由新进程从 user://test_save_game.cfg 读取存档，验证真实重启后的表现。

const StageDBScript = preload("res://src/data/stage_db.gd")

var _failures: Array[String] = []
var _main: Control = null


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if _is_restart_phase():
		await _run_restart_phase()
		return
	await _run_main_phase()


func _is_restart_phase() -> bool:
	return OS.get_cmdline_user_args().has("--restart-phase")


# ==================== 第一次启动 ====================

func _run_main_phase() -> void:
	var save := root.get_node_or_null("/root/SaveManager")
	_expect(save != null, "SaveManager should exist")
	if save == null:
		await _finish_suite()
		return
	save.clear_all_data()

	_main = load("res://main.tscn").instantiate()
	root.add_child(_main)
	await _wait_frames(3)
	await _wait_scene("start", 300)

	# --- 初始状态：stage_1_1 可点，stage_1_2 锁定 ---
	_main.switch_scene("stage_select", {"chapterIndex": 0})
	_expect(await _wait_scene("stage_select"), "stage select should open")
	await _wait_scene_manager_idle()
	var select_scene: Control = _current_scene()
	_expect(select_scene != null, "stage select scene should exist")
	if select_scene == null:
		await _finish_suite()
		return
	_expect_stage_select_state(select_scene, "fresh save before first clear", {
		"stage_1_1_unlocked": true,
		"stage_1_2_unlocked": false,
		"stage_1_1_stars_at_least": 0,
		"stage_1_2_button_enabled": false,
	})

	# --- 胜利一次 ---
	var battle_scene: Control = await _enter_battle("stage_1_1")
	_expect(battle_scene != null, "battle scene should start for stage_1_1")
	if battle_scene == null:
		await _finish_suite()
		return
	await _force_battle_win(battle_scene)
	battle_scene.call("_go_to_result")
	_expect(await _wait_scene("result", 600), "winning stage_1_1 should open the result screen")
	var result_scene: Control = _current_scene()
	_expect(result_scene != null, "result scene should exist after a win")
	if result_scene == null:
		await _finish_suite()
		return
	_expect(bool(result_scene.get("_is_win")), "winning stage_1_1 should show a victory result")
	_expect(bool(result_scene.get("_has_next_stage")), "victory on stage_1_1 should offer the next stage")
	var next_button := result_scene.get_node_or_null("Buttons/NextButton") as BaseButton
	var back_button := result_scene.get_node_or_null("Buttons/BackButton") as BaseButton
	_expect(next_button != null and next_button.visible, "victory result should show the 下一关 button")
	_expect(back_button != null and back_button.visible, "victory result should show the back-to-stages button")
	var cleared_stars := int(save.get_stage_stars("stage_1_1"))
	_expect(cleared_stars >= 1, "clearing stage_1_1 should save at least one star, got %d" % cleared_stars)
	_expect(bool(save.is_stage_unlocked("stage_1_2")), "clearing stage_1_1 should unlock stage_1_2")
	_expect(not bool(save.is_stage_unlocked("stage_1_3")), "clearing stage_1_1 should not unlock stage_1_3")

	# --- 2. 回到关卡选择：星级与解锁 ---
	if back_button != null:
		back_button.pressed.emit()
	_expect(await _wait_scene("stage_select", 600), "the result screen's back button should return to stage select")
	await _wait_scene_manager_idle()
	select_scene = _current_scene()
	_expect(select_scene != null, "stage select scene should exist after returning")
	if select_scene != null:
		_expect_stage_select_state(select_scene, "after clearing stage_1_1", {
			"stage_1_1_unlocked": true,
			"stage_1_2_unlocked": true,
			"stage_1_1_stars_at_least": 1,
			"stage_1_2_button_enabled": true,
		})
		var tapped_stage := await _tap_stage_button(select_scene, 1)
		_expect(tapped_stage == "stage_1_2", "stage_1_2's map button should be tappable after the clear, got '%s'" % tapped_stage)
		_expect(await _wait_scene("battle_prepare", 600), "tapping stage_1_2 on stage select should open its prepare screen")
		await _wait_scene_manager_idle()
		var tapped_prepare: Control = _current_scene()
		_expect(tapped_prepare != null and str(tapped_prepare.get("_stage_id")) == "stage_1_2", "tapped stage should be stage_1_2")

	# --- 1. 胜利 → 下一关 → stage_1_2 战斗 ---
	battle_scene = await _enter_battle("stage_1_1")
	_expect(battle_scene != null, "battle scene should start again for the next-stage flow")
	if battle_scene != null:
		await _force_battle_win(battle_scene)
		battle_scene.call("_go_to_result")
		_expect(await _wait_scene("result", 600), "winning stage_1_1 again should open the result screen")
		var next_result: Control = _current_scene()
		_expect(next_result != null and bool(next_result.get("_is_win")), "the next-stage flow needs a victory result")
		if next_result != null:
			next_button = next_result.get_node_or_null("Buttons/NextButton") as BaseButton
			_expect(next_button != null and next_button.visible, "victory result should show the 下一关 button")
			if next_button != null:
				next_button.pressed.emit()
			_expect(await _wait_scene("battle_prepare", 600), "the 下一关 button should open stage_1_2's prepare screen without stalling")
			var prepare_scene: Control = _current_scene()
			_expect(prepare_scene != null and str(prepare_scene.get("_stage_id")) == "stage_1_2", "prepare screen should target stage_1_2")
			if prepare_scene != null:
				prepare_scene.call("_start_battle")
				_expect(await _wait_scene("battle", 600), "starting from stage_1_2's prepare screen should enter battle without stalling")
				await _wait_scene_manager_idle()
				var next_battle: Control = _current_scene()
				_expect(next_battle != null and str(next_battle.get("_stage_id")) == "stage_1_2", "the next battle should be stage_1_2")

	# --- 3. 失败重打同一关，进度不前进 ---
	await _wait_scene_manager_idle()
	var stars_before_loss := int(save.get_stage_stars("stage_1_1"))
	var unlocked_1_2_before_loss := bool(save.is_stage_unlocked("stage_1_2"))
	var unlocked_1_3_before_loss := bool(save.is_stage_unlocked("stage_1_3"))
	battle_scene = await _enter_battle("stage_1_1")
	_expect(battle_scene != null, "battle scene should start for the loss flow")
	if battle_scene != null:
		await _force_battle_loss(battle_scene)
		battle_scene.call("_go_to_result")
		_expect(await _wait_scene("result", 600), "losing stage_1_1 should open the result screen")
		var loss_result: Control = _current_scene()
		_expect(loss_result != null, "result scene should exist after a loss")
		if loss_result != null:
			_expect(not bool(loss_result.get("_is_win")), "losing stage_1_1 should show a defeat result")
			_expect(not bool(loss_result.get("_has_next_stage")), "defeat should not offer the next stage")
			var loss_next := loss_result.get_node_or_null("Buttons/NextButton") as BaseButton
			var retry_button := loss_result.get_node_or_null("Buttons/RetryButton") as BaseButton
			_expect(loss_next != null and not loss_next.visible, "defeat result should hide the 下一关 button")
			_expect(retry_button != null and retry_button.visible, "defeat result should show the 重打 button")
			if retry_button != null:
				var retry_text := retry_button.get_node_or_null("Text") as Label
				_expect(retry_text != null and retry_text.text == "重打", "defeat retry button should read 重打")
				retry_button.pressed.emit()
		_expect(await _wait_scene("battle_prepare", 600), "重打 should return to stage_1_1's prepare screen")
		var retry_prepare: Control = _current_scene()
		_expect(retry_prepare != null and str(retry_prepare.get("_stage_id")) == "stage_1_1", "重打 should stay on stage_1_1")
		if retry_prepare != null:
			retry_prepare.call("_start_battle")
			_expect(await _wait_scene("battle", 600), "重打 should re-enter stage_1_1's battle")
			var retry_battle: Control = _current_scene()
			_expect(retry_battle != null and str(retry_battle.get("_stage_id")) == "stage_1_1", "retry battle should be stage_1_1")
	_expect(int(save.get_stage_stars("stage_1_1")) == stars_before_loss, "a loss must not change stage_1_1's stars")
	_expect(bool(save.is_stage_unlocked("stage_1_2")) == unlocked_1_2_before_loss, "a loss must not change stage_1_2's unlock state")
	_expect(bool(save.is_stage_unlocked("stage_1_3")) == unlocked_1_3_before_loss, "a loss must not unlock stage_1_3")

	# --- 重启：新进程重新读取存档 ---
	save.flush()
	if _main != null:
		_main.queue_free()
		_main = null
	await _wait_frames(3)
	_expect(_restart_process_passed(), "a freshly restarted game should keep stage_1_1's stars and stage_1_2 unlocked")
	await _finish_suite()


# ==================== 重启后（新进程） ====================

func _run_restart_phase() -> void:
	var save := root.get_node_or_null("/root/SaveManager")
	_expect(save != null, "SaveManager should exist after restart")
	if save == null:
		quit(1)
		return
	_expect(int(save.get_stage_stars("stage_1_1")) >= 1, "restarted save should keep stage_1_1's stars")
	_expect(bool(save.is_stage_unlocked("stage_1_2")), "restarted save should keep stage_1_2 unlocked")
	_expect(not bool(save.is_stage_unlocked("stage_1_3")), "restarted save should still lock stage_1_3")

	_main = load("res://main.tscn").instantiate()
	root.add_child(_main)
	await _wait_frames(3)
	await _wait_scene("start", 300)

	_main.switch_scene("stage_select", {"chapterIndex": 0})
	_expect(await _wait_scene("stage_select"), "stage select should open after restart")
	await _wait_scene_manager_idle()
	var select_scene: Control = _current_scene()
	_expect(select_scene != null, "stage select scene should exist after restart")
	if select_scene != null:
		_expect_stage_select_state(select_scene, "after restart", {
			"stage_1_1_unlocked": true,
			"stage_1_2_unlocked": true,
			"stage_1_1_stars_at_least": 1,
			"stage_1_2_button_enabled": true,
		})
		var tapped_stage := await _tap_stage_button(select_scene, 1)
		_expect(tapped_stage == "stage_1_2", "stage_1_2 should stay tappable after restart, got '%s'" % tapped_stage)
		_expect(await _wait_scene("battle_prepare", 600), "tapping stage_1_2 after restart should open its prepare screen")
	print("[StageProgressLoop][Restart] phase finished")
	await _finish_suite()


# ==================== 场景与战斗驱动 ====================

func _current_scene() -> Control:
	if _main == null:
		return null
	return _main.get_current_scene() if _main.has_method("get_current_scene") else null


func _enter_battle(stage_id: String) -> Control:
	if _main == null:
		return null
	var stage_db := StageDBScript.new()
	_main.switch_scene("battle", {"stageId": stage_id, "stageData": stage_db.get_stage(stage_id)})
	if not await _wait_scene("battle", 600):
		return null
	await _wait_frames(2)
	return _current_scene()


func _force_battle_win(battle_scene: Control) -> void:
	var battle = battle_scene.get("_battle")
	if battle == null:
		return
	for enemy: Dictionary in battle.enemies:
		if enemy != null:
			enemy["maxHP"] = maxi(int(enemy.get("maxHP", 1)), 1)
			enemy["hp"] = 1
	var turns := 0
	while not battle.battle_over and turns < 20:
		turns += 1
		battle.turn_count = turns
		battle.process_match_result({"fire": 3, "water": 3, "grass": 3}, 2)
		if battle.check_battle_end():
			break
		battle.enemy_action()
	_expect(str(battle.battle_result) == "win", "scripted stage_1_1 battle should end in a win")
	battle_scene.call("_check_battle_end")
	await _wait_frames(2)


func _force_battle_loss(battle_scene: Control) -> void:
	var battle = battle_scene.get("_battle")
	if battle == null:
		return
	for monster: Dictionary in battle.player_team:
		if monster != null:
			monster["hp"] = 0
	battle_scene.call("_start_enemy_turn")
	# 敌方回合要等前摇与伤害结算完成，等待战斗进入 BATTLE_END（枚举值 6）。
	for _i in range(600):
		await process_frame
		if int(battle_scene.get("_state")) == 6:
			break
	_expect(str(battle.battle_result) == "lose", "scripted stage_1_1 battle should end in a loss")
	await _wait_frames(2)


# ==================== 关卡选择断言 ====================

func _expect_stage_select_state(select_scene: Control, phase: String, expected: Dictionary) -> void:
	var card_1_1 := _card_for(select_scene, "stage_1_1")
	var card_1_2 := _card_for(select_scene, "stage_1_2")
	_expect(not card_1_1.is_empty(), "%s: stage_1_1 card should exist" % phase)
	_expect(not card_1_2.is_empty(), "%s: stage_1_2 card should exist" % phase)
	if not card_1_1.is_empty():
		_expect(bool(card_1_1.get("enabled", false)) == bool(expected["stage_1_1_unlocked"]),
			"%s: stage_1_1 unlocked should be %s" % [phase, str(expected["stage_1_1_unlocked"])])
		_expect(int(card_1_1.get("stars", 0)) >= int(expected["stage_1_1_stars_at_least"]),
			"%s: stage_1_1 should show at least %d star(s)" % [phase, int(expected["stage_1_1_stars_at_least"])])
	if not card_1_2.is_empty():
		_expect(bool(card_1_2.get("enabled", false)) == bool(expected["stage_1_2_unlocked"]),
			"%s: stage_1_2 unlocked should be %s" % [phase, str(expected["stage_1_2_unlocked"])])
	var button_1_2 := _stage_button(select_scene, 1)
	_expect(button_1_2 != null, "%s: stage_1_2 map button should exist" % phase)
	if button_1_2 != null:
		_expect(button_1_2.disabled == not bool(expected["stage_1_2_button_enabled"]),
			"%s: stage_1_2 map button enabled should be %s" % [phase, str(expected["stage_1_2_button_enabled"])])
		var lock := button_1_2.get_node_or_null("LockState") as Control
		if lock != null:
			_expect(lock.visible == not bool(expected["stage_1_2_button_enabled"]),
				"%s: stage_1_2 lock badge should match its unlock state" % phase)
	# stage_1_1 的星级要真实点亮；stage_1_2 未通关时星级保持暗色。
	var button_1_1 := _stage_button(select_scene, 0)
	if button_1_1 != null:
		var star := button_1_1.get_node_or_null("Stars/Star01") as TextureRect
		if star != null and star.texture != null:
			_expect(star.texture.resource_path.ends_with("icon_star_lit.png") == (int(expected["stage_1_1_stars_at_least"]) >= 1),
				"%s: stage_1_1 star icon should match its stars" % phase)
	if button_1_2 != null and int(expected["stage_1_1_stars_at_least"]) == 0:
		var dim := button_1_2.get_node_or_null("Stars/Star01") as TextureRect
		if dim != null and dim.texture != null:
			_expect(dim.texture.resource_path.ends_with("icon_star_dim.png"), "%s: uncleared stage_1_2 stars should stay dim" % phase)


func _card_for(select_scene: Control, stage_id: String) -> Dictionary:
	var cards: Array = select_scene.get("_cards")
	for card: Dictionary in cards:
		if str(card.get("id", "")) == stage_id:
			return card
	return {}


func _stage_button(select_scene: Control, index: int) -> TextureButton:
	var chapter_map = select_scene.get("_chapter_map")
	if chapter_map == null:
		return null
	return chapter_map.get_node_or_null("StageNodes/Stage%02d" % (index + 1)) as TextureButton


func _tap_stage_button(select_scene: Control, index: int) -> String:
	var tapped := {"stage_id": ""}
	select_scene.connect("stage_selected", func(stage_id: String, _data: Dictionary, _chapter: int):
		tapped["stage_id"] = stage_id
	)
	var button := _stage_button(select_scene, index)
	if button == null:
		return ""
	button.pressed.emit()
	await process_frame
	return str(tapped["stage_id"])


# ==================== 重启与收尾 ====================

func _restart_process_passed() -> bool:
	var output: Array = []
	var code := OS.execute(OS.get_executable_path(), PackedStringArray([
		"--headless",
		"--path", ProjectSettings.globalize_path("res://"),
		"--script", "res://tests/stage_progress_loop_test.gd",
		"--", "--restart-phase",
	]), output, true)
	if code != 0:
		push_error("[StageProgressLoop][Restart] child process failed:\n" + "\n".join(output))
	return code == 0


func _wait_frames(count: int) -> void:
	for _i in range(count):
		await process_frame


func _wait_scene(scene_name: String, max_frames: int = 600) -> bool:
	for _i in range(max_frames):
		await process_frame
		if _main == null:
			return false
		if _main.get_current_scene_name() == scene_name:
			return true
	return false


func _wait_scene_manager_idle() -> void:
	var manager := root.get_node_or_null("/root/SceneManager")
	if manager == null:
		return
	for _i in range(600):
		if not bool(manager.get("_is_transitioning")):
			return
		await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish_suite() -> void:
	if _main != null:
		_main.queue_free()
		_main = null
	await _wait_frames(3)
	if _failures.is_empty():
		print("[StageProgressLoop] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[StageProgressLoop] " + failure)
	quit(1)
