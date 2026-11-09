extends SceneTree

## 画质 / 战斗表现档位跨进程恢复回归：
## 第一次进程写入非默认档位，第二次进程（真正重启）只从存档读取，
## 并进入战斗确认两个档位都恢复生效。
##
## 两次运行必须使用同一个 MATCH3_SAVE_PATH：
##   rm -f /tmp/match3_presentation_restart.cfg
##   MATCH3_SAVE_PATH=/tmp/match3_presentation_restart.cfg \
##     Godot --headless --path . --script res://tests/presentation_settings_restart_test.gd -- --phase=write
##   MATCH3_SAVE_PATH=/tmp/match3_presentation_restart.cfg \
##     Godot --headless --path . --script res://tests/presentation_settings_restart_test.gd -- --phase=read

const StageDBScript = preload("res://src/data/stage_db.gd")

const TARGET_QUALITY := "low"
const TARGET_PERFORMANCE := "rich"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var phase := _read_arg("--phase=", "read")
	if phase == "write":
		_phase_write()
	else:
		await _phase_read()
	_finish()


func _phase_write() -> void:
	var save_manager := root.get_node_or_null("SaveManager")
	if save_manager == null or not save_manager.has_method("save_settings"):
		_failures.append("应挂载 SaveManager Autoload")
		return
	var settings: Dictionary = save_manager.load_settings()
	settings["qualityLevel"] = TARGET_QUALITY
	settings["performanceMode"] = TARGET_PERFORMANCE
	settings["soundOn"] = false
	settings["musicOn"] = false
	settings["vibrationOn"] = false
	save_manager.save_settings(settings)
	var stored: Dictionary = save_manager.load_settings()
	print("[PresentationRestart] write path=%s quality=%s performance=%s soundOn=%s musicOn=%s vibrationOn=%s" % [
		ProjectSettings.globalize_path(save_manager._get_save_path()),
		str(stored.get("qualityLevel", "")),
		str(stored.get("performanceMode", "")),
		str(stored.get("soundOn", "")),
		str(stored.get("musicOn", "")),
		str(stored.get("vibrationOn", "")),
	])
	_expect(str(stored.get("qualityLevel", "")) == TARGET_QUALITY, "写入后存档中应保存流畅画质")
	_expect(str(stored.get("performanceMode", "")) == TARGET_PERFORMANCE, "写入后存档中应保存华丽战斗表现")


func _phase_read() -> void:
	var save_manager := root.get_node_or_null("SaveManager")
	if save_manager == null or not save_manager.has_method("load_settings"):
		_failures.append("应挂载 SaveManager Autoload")
		return
	var settings: Dictionary = save_manager.load_settings()
	print("[PresentationRestart] read path=%s quality=%s performance=%s" % [
		ProjectSettings.globalize_path(save_manager._get_save_path()),
		str(settings.get("qualityLevel", "")),
		str(settings.get("performanceMode", "")),
	])
	_expect(str(settings.get("qualityLevel", "")) == TARGET_QUALITY,
		"重启后流畅画质应从存档恢复，实际 %s" % str(settings.get("qualityLevel", "")))
	_expect(str(settings.get("performanceMode", "")) == TARGET_PERFORMANCE,
		"重启后华丽战斗表现应从存档恢复，实际 %s" % str(settings.get("performanceMode", "")))

	# 进入真实战斗，确认恢复的档位已经应用到表现层。
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.switch_scene("battle", {
		"stageId": "stage_1_1",
		"stageData": StageDBScript.new().get_stage("stage_1_1"),
		"inputTestOnly": true,
	})
	await process_frame
	await process_frame
	var battle: Control = main.get_current_scene()
	if battle == null:
		_failures.append("重启后应能加载战斗场景")
		return
	var profile: Dictionary = battle.call("get_presentation_profile")
	print("[PresentationRestart] battle profile quality=%s performance=%s particle_density=%.2f shake_scale=%.2f popup_layers=%d" % [
		str(profile.get("quality", "")),
		str(profile.get("performance", "")),
		float(profile.get("effect_density", 0.0)),
		float(profile.get("shake_scale", 0.0)),
		int(profile.get("popup_layers", 0)),
	])
	_expect(str(profile.get("quality", "")) == TARGET_QUALITY, "重启后战斗应使用存档中的流畅画质")
	_expect(str(profile.get("performance", "")) == TARGET_PERFORMANCE, "重启后战斗应使用存档中的华丽战斗表现")
	_expect(is_equal_approx(float(profile.get("effect_density", 0.0)), 0.75),
		"流畅画质 × 华丽表现的粒子密度应为 0.75，实际 %.2f" % float(profile.get("effect_density", 0.0)))
	_expect(int(profile.get("popup_layers", 0)) == 3, "华丽战斗表现应恢复 3 层飘字")
	main.queue_free()
	await process_frame
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[PresentationRestart] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[PresentationRestart] " + failure)
	quit(1)


func _read_arg(prefix: String, fallback: String) -> String:
	var args := OS.get_cmdline_args()
	args.append_array(OS.get_cmdline_user_args())
	for arg in args:
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return fallback
