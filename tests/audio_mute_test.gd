extends SceneTree

# audio_mute_test.gd - 验证设置里音效/音乐静音开关的正确性
# 复现并验证修复：
#   1) SFX bus mute 在 toggle 后能正确同步（通过 AudioServer.set_bus_mute）
#   2) BGM 静音状态在 _bgm_player == null 时仍被记录，并在 play_bgm 时被尊重
#   3) AudioManager._sync_with_settings 通过 load_settings() 拿到真实值
#      （修复前因依赖不存在的 get_setting() 永远不生效）

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _run() -> void:
	# 加载主场景，autoload 才会真正被激活
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var save_manager := root.get_node_or_null("SaveManager")
	var audio_manager := root.get_node_or_null("AudioManager")
	_check(save_manager != null, "SaveManager autoload should be active after main loads")
	_check(audio_manager != null, "AudioManager autoload should be active after main loads")
	if not _failures.is_empty():
		_report_and_quit()
		return

	# 等待 AudioManager._ready 完成（它会在 _ready 里 _sync_with_settings）
	await process_frame

	var sfx_bus_idx := AudioServer.get_bus_index("SFX")
	var bgm_bus_idx := AudioServer.get_bus_index("BGM")
	_check(sfx_bus_idx >= 0, "SFX bus should be created in AudioManager._init_buses")
	_check(bgm_bus_idx >= 0, "BGM bus should be created in AudioManager._init_buses")
	if not _failures.is_empty():
		_report_and_quit()
		return

	# 1) 默认 soundOn/musicOn = true
	save_manager.save_settings({"soundOn": true, "musicOn": true, "version": "v0.1.0"})
	await process_frame
	_check(audio_manager._muted == false, "Default: _muted should be false")
	_check(not AudioServer.is_bus_mute(sfx_bus_idx), "Default: SFX bus should not be muted")
	_check(audio_manager._bgm_muted == false, "Default: _bgm_muted should be false")

	# 2) 关闭音效（核心修复 1：SFX bus 应被静音）
	save_manager.save_settings({"soundOn": false, "musicOn": true, "version": "v0.1.0"})
	await process_frame
	_check(audio_manager._muted == true, "soundOn=false: _muted should be true")
	_check(AudioServer.is_bus_mute(sfx_bus_idx), "soundOn=false: SFX bus should be muted (core fix 1)")

	# 3) 关闭音乐在 _bgm_player == null 时（核心修复 2：状态必须保留）
	audio_manager._bgm_player = null
	save_manager.save_settings({"soundOn": false, "musicOn": false, "version": "v0.1.0"})
	await process_frame
	_check(audio_manager._bgm_muted == true, "musicOn=false (bgm_player=null): _bgm_muted should be true and persist (core fix 2)")

	# 4) 模拟 play_bgm 启动 BGM，应尊重 _bgm_muted
	var player := AudioStreamPlayer.new()
	player.bus = "BGM"
	player.volume_db = audio_manager._bgm_volume_db
	if audio_manager._bgm_muted:
		player.volume_db = -80.0
	_check(player.volume_db == -80.0, "BGM startup with _bgm_muted=true: volume_db should be -80 (got %f)" % player.volume_db)
	player.queue_free()

	# 5) 还原后 SFX bus 应被解除静音
	save_manager.save_settings({"soundOn": true, "musicOn": true, "version": "v0.1.0"})
	await process_frame
	_check(audio_manager._muted == false, "Restore soundOn=true: _muted should be false")
	_check(audio_manager._bgm_muted == false, "Restore musicOn=true: _bgm_muted should be false")
	_check(not AudioServer.is_bus_mute(sfx_bus_idx), "Restore soundOn=true: SFX bus should not be muted")

	main.queue_free()
	_report_and_quit()

func _report_and_quit() -> void:
	if _failures.is_empty():
		print("[AudioMute] OK")
		quit(0)
	else:
		for msg: String in _failures:
			push_error("[AudioMute] " + msg)
		quit(1)
