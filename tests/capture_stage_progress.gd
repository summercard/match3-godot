extends SceneTree

## 主线首通闭环证据截图：跑真实胜利 / 失败流程与回关卡选择，各截一张。
## 用法（需要窗口渲染，不能加 --headless）：
##   GODOT=~/Applications/Godot.app/Contents/MacOS/Godot
##   $GODOT --path . --script res://tests/capture_stage_progress.gd -- \
##     --output-dir=docs/evidence/stage_progress

const StageDBScript = preload("res://src/data/stage_db.gd")
const DEFAULT_OUTPUT_DIR := "docs/evidence/stage_progress"

var _main: Control = null
var _output_dir := DEFAULT_OUTPUT_DIR


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_output_dir = _read_arg("--output-dir=", DEFAULT_OUTPUT_DIR)
	var save := root.get_node_or_null("/root/SaveManager")
	save.clear_all_data()

	_main = load("res://main.tscn").instantiate()
	root.add_child(_main)
	await _wait_frames(3)
	await _wait_scene("start", 300)
	await _wait_scene_manager_idle()

	# --- 胜利结算 ---
	var battle_scene: Control = await _enter_battle("stage_1_1")
	await _force_battle_win(battle_scene)
	battle_scene.call("_go_to_result")
	if not await _wait_scene("result", 600):
		_fail("win result scene did not open")
		return
	await _wait_scene_manager_idle()
	await _wait_seconds(2.6)
	await _capture("win_result.png")

	# --- 回到关卡选择（stage_1_1 星级 / stage_1_2 解锁）---
	var result_scene: Control = _current_scene()
	var back_button := result_scene.get_node_or_null("Buttons/BackButton") as BaseButton
	if back_button != null:
		back_button.pressed.emit()
	if not await _wait_scene("stage_select", 600):
		_fail("stage select did not open from the result screen")
		return
	await _wait_scene_manager_idle()
	await _wait_seconds(1.2)
	await _capture("stage_select_after_clear.png")

	# --- 失败结算 ---
	await _wait_scene_manager_idle()
	battle_scene = await _enter_battle("stage_1_1")
	if battle_scene == null:
		_fail("loss battle scene did not start")
		return
	await _force_battle_loss(battle_scene)
	battle_scene.call("_go_to_result")
	if not await _wait_scene("result", 600):
		_fail("loss result scene did not open")
		return
	await _wait_scene_manager_idle()
	await _wait_seconds(2.6)
	await _capture("lose_result.png")

	print("[StageProgressCapture] done -> %s" % ProjectSettings.globalize_path(_output_dir))
	quit(0)


func _read_arg(prefix: String, fallback: String) -> String:
	for arg: String in OS.get_cmdline_args() + OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return fallback


func _current_scene() -> Control:
	return _main.get_current_scene() if _main != null else null


func _enter_battle(stage_id: String) -> Control:
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
	for _i in range(600):
		await process_frame
		if int(battle_scene.get("_state")) == 6:
			break
	await _wait_frames(2)


func _capture(file_name: String) -> void:
	var dir := ProjectSettings.globalize_path(_output_dir)
	DirAccess.make_dir_recursive_absolute(dir)
	var image := root.get_texture().get_image()
	var path := dir.path_join(file_name)
	var error := image.save_png(path)
	if error != OK:
		_fail("save %s failed: %s" % [path, error_string(error)])
		return
	print("[StageProgressCapture] %s (%dx%d)" % [path, image.get_width(), image.get_height()])


func _fail(message: String) -> void:
	push_error("[StageProgressCapture] " + message)
	quit(1)


func _wait_frames(count: int) -> void:
	for _i in range(count):
		await process_frame


func _wait_seconds(seconds: float) -> void:
	await create_timer(seconds).timeout


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
