extends SceneTree

## 战斗外七个页面主按钮音效回归：
## 1. 复用 battle_sfx.gd 的 button_click；相对既有七音，波形/频率/时长三项都不同；
## 2. 大厅、选关、战斗准备、背包、商店、图鉴、设置的主按钮逐一点击，各只播放 1 声；
## 3. soundOn=false 时七个页面点完 requests/played/players 全为 0；
## 4. 页面销毁后不残留 ButtonSfx 或 AudioStreamPlayer；
## 5. 同帧 8 次上限与 dropped_count 仍按原口径工作。
##
## 用法：
##   Godot --headless --path . --fixed-fps 60 --script res://tests/ui_button_sfx_test.gd

const BattleSfxScript = preload("res://src/ui/components/battle_sfx.gd")
const PAGES := ["main", "stage_select", "battle_prepare", "inventory", "shop", "album", "settings"]
const PAGE_LABELS := {
	"main": "大厅",
	"stage_select": "选关",
	"battle_prepare": "战斗准备",
	"inventory": "背包",
	"shop": "商店",
	"album": "图鉴",
	"settings": "设置",
}
const SCENE_PATHS := {
	"main": "res://src/ui/scenes/main_lobby.tscn",
	"stage_select": "res://src/ui/scenes/stage_select_map.tscn",
	"battle_prepare": "res://src/ui/scenes/battle_prepare.tscn",
	"inventory": "res://src/ui/scenes/inventory.tscn",
	"shop": "res://src/ui/scenes/shop.tscn",
	"album": "res://src/ui/scenes/album.tscn",
}

var _failures: Array[String] = []
var _original_settings: Dictionary = {}
var _on_counts: Array = []
var _off_counts: Array = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var save_manager := root.get_node_or_null("/root/SaveManager")
	if save_manager != null:
		_original_settings = save_manager.load_settings().duplicate(true)
	_test_button_config()
	await _test_frame_cap()
	for page_name: String in PAGES:
		_on_counts.append(await _run_page(page_name, true))
	for page_name: String in PAGES:
		_off_counts.append(await _run_page(page_name, false))
	_restore_settings()
	BattleSfxScript.enabled = true
	await process_frame
	_expect(root.find_children("ButtonSfx", "Node", true, false).is_empty(),
		"全部页面关闭后不应残留 ButtonSfx")
	_expect(root.find_children("*", "AudioStreamPlayer", true, false).is_empty(),
		"全部页面关闭后不应残留 AudioStreamPlayer")
	_print_counts()
	_finish()


func _test_button_config() -> void:
	var ids: Array = BattleSfxScript.SOUND_IDS
	_expect(ids.size() == 8, "音效层应保持七个战斗音并新增 button_click，实际 %d" % ids.size())
	_expect(BattleSfxScript.CONFIG["sounds"].has("button_click"), "应新增 button_click 音效")
	var click: Dictionary = BattleSfxScript.CONFIG["sounds"].get("button_click", {})
	var battle_ids := ["match_clear", "hit", "crit", "take_damage", "victory", "defeat", "break"]
	for sound_id: String in battle_ids:
		var params: Dictionary = BattleSfxScript.CONFIG["sounds"][sound_id]
		for key: String in ["waveform", "frequency", "duration"]:
			_expect(click.get(key) != params.get(key),
				"button_click.%s 应与既有 %s 不同" % [key, sound_id])
		var differences := 0
		for key: String in ["frequency", "duration", "waveform", "attack", "decay"]:
			if str(click.get(key, "")) != str(params.get(key, "")):
				differences += 1
		_expect(differences >= 3, "button_click 与 %s 应至少 3 项参数不同，实际 %d" % [sound_id, differences])
	print("[UiButtonSfx] button_click freq=%.1fHz dur=%.3fs wave=%s attack=%.3fs decay=%.1f" % [
		float(click.get("frequency", 0.0)),
		float(click.get("duration", 0.0)),
		str(click.get("waveform", "")),
		float(click.get("attack", 0.0)),
		float(click.get("decay", 0.0)),
	])


func _test_frame_cap() -> void:
	var sfx = BattleSfxScript.new()
	root.add_child(sfx)
	sfx.set_enabled(true)
	sfx.reset_counters()
	for i in range(12):
		sfx.play("button_click")
	_expect(sfx.played_count == 8, "同帧 12 次请求应只播放 8 次，实际 %d" % sfx.played_count)
	_expect(sfx.dropped_count == 4, "同帧超出的 4 次应进入丢弃计数，实际 %d" % sfx.dropped_count)
	_expect(sfx.request_count == 12, "同帧请求计数应为 12，实际 %d" % sfx.request_count)
	_expect(sfx.player_count() == 8, "播放器池应为 8，实际 %d" % sfx.player_count())
	print("[UiButtonSfx] frame cap: requests=%d played=%d dropped=%d players=%d" % [
		sfx.request_count, sfx.played_count, sfx.dropped_count, sfx.player_count(),
	])
	sfx.free()


func _run_page(page_name: String, enabled: bool) -> Dictionary:
	_set_state(enabled)
	var scene: Control = await _spawn_page(page_name)
	var sfx = scene.get("_button_sfx") if scene != null else null
	if scene == null or sfx == null:
		_failures.append("%s 应挂载 BattleSfx" % PAGE_LABELS[page_name])
		if scene != null:
			scene.queue_free()
		return {"page": page_name, "enabled": enabled, "taps": 0, "played": 0, "requests": 0, "dropped": 0, "players": 0}
	_expect(sfx.enabled == enabled, "%s 的 ButtonSfx.enabled 应与 soundOn=%s 同步" % [PAGE_LABELS[page_name], str(enabled)])
	var taps: int = await _tap_page(page_name, scene, sfx)

	var row := {
		"page": page_name,
		"label": PAGE_LABELS[page_name],
		"enabled": enabled,
		"taps": taps,
		"played": sfx.played_count,
		"requests": sfx.request_count,
		"dropped": sfx.dropped_count,
		"players": sfx.player_count(),
	}
	if enabled:
		_expect(sfx.played_count == taps, "%s 应每次点击播放 1 声，实际 %d/%d" % [PAGE_LABELS[page_name], sfx.played_count, taps])
		_expect(sfx.request_count == taps, "%s 应每次点击只发 1 次请求，实际 %d/%d" % [PAGE_LABELS[page_name], sfx.request_count, taps])
	else:
		_expect(sfx.played_count == 0, "%s soundOn=false 时不应播放，实际 %d" % [PAGE_LABELS[page_name], sfx.played_count])
		_expect(sfx.request_count == 0, "%s soundOn=false 时不应发播放请求，实际 %d" % [PAGE_LABELS[page_name], sfx.request_count])
		_expect(sfx.player_count() == 0, "%s soundOn=false 时不应创建播放器，实际 %d" % [PAGE_LABELS[page_name], sfx.player_count()])

	scene.queue_free()
	await process_frame
	await process_frame
	_expect(not is_instance_valid(sfx), "%s 关闭后 ButtonSfx 应被释放" % PAGE_LABELS[page_name])
	_expect(root.find_children("ButtonSfx", "Node", true, false).is_empty(),
		"%s 关闭后不应残留 ButtonSfx 节点" % PAGE_LABELS[page_name])
	return row


func _spawn_page(page_name: String) -> Control:
	var scene: Control = null
	if page_name == "settings":
		var script = load("res://src/ui/scene/scene_settings.gd") as GDScript
		scene = script.new() as Control
	else:
		scene = (load(SCENE_PATHS[page_name]) as PackedScene).instantiate() as Control
	root.add_child(scene)
	await process_frame
	match page_name:
		"main":
			scene.call("init", {})
		"stage_select":
			scene.call("init", {"chapterIndex": 0})
		"battle_prepare":
			scene.call("init", {"stageId": "stage_1_1"})
		"inventory":
			scene.call("init", {})
			scene.set("_inventory", {
				"capture_ball": 3, "capture_ball_plus": 1, "exp_potion": 5, "exp_crystal": 2,
				"hp_potion": 1, "gold_bag": 4, "gold_chest": 1,
				"evolution_stone_fire": 1, "evolution_stone_water": 1, "evolution_stone_grass": 1,
				"evolution_stone_thunder": 1, "evolution_stone_light": 1, "evolution_stone_earth": 1,
				"evolution_stone_wind": 1, "evolution_stone_dark": 1,
			})
			scene.set("_player", {"gold": 1280, "gems": 36})
			scene.call("_build_item_list")
			scene.call("_sync_gui")
		"shop":
			scene.call("init", {})
			scene.set("player_data", {"gold": 5000, "gems": 120})
			scene.call("_sync_gui")
		"album":
			scene.call("init", {})
		"settings":
			scene.call("init", {})
	await process_frame
	return scene


func _tap_page(page_name: String, scene: Control, sfx) -> int:
	var taps := 0
	match page_name:
		"main":
			for button_name: String in [
				"StartButton", "TeamButton", "RanchButton", "ShopButton", "AlbumButton",
				"InventoryButton", "AchievementButton", "SettingsButton", "SigninButton",
			]:
				var button := scene.get_node("%" + button_name) as TextureButton
				var action: Callable
				if button_name == "StartButton":
					action = func(): button.button_down.emit()
				else:
					action = func(): button.pressed.emit()
				taps += await _tap(sfx, "%s %s" % [PAGE_LABELS[page_name], button_name], action)
		"stage_select":
			_expect((scene.get_node("Header/BackButton") as BaseButton).has_meta("ui_button_sfx_wired"),
				"选关 BackButton 应接入按钮音效")
			for path: String in [
				"Header/PreviousButton",
				"Header/NextButton",
				"ChapterMaps/Chapter01Grassland/StageNodes/Stage01",
			]:
				var button := scene.get_node(path) as BaseButton
				var action := func(): button.pressed.emit()
				taps += await _tap(sfx, "%s %s" % [PAGE_LABELS[page_name], path], action)
		"battle_prepare":
			_expect((scene.get_node("Header/BackButton") as BaseButton).has_meta("ui_button_sfx_wired"),
				"战斗准备 BackButton 应接入按钮音效")
			var start := scene.get_node("StartButton") as BaseButton
			taps += await _tap(sfx, "战斗准备 StartButton", func(): start.pressed.emit())
		"inventory":
			taps += await _tap_button_path(scene, sfx, "背包 Tabs/Gems", "Tabs/Gems")
			taps += await _tap_button_path(scene, sfx, "背包 PageControls/NextButton", "GridPanel/PageControls/NextButton")
			taps += await _tap_button_path(scene, sfx, "背包 Slot1", "GridPanel/Slots/Slot1")
			taps += await _tap_button_path(scene, sfx, "背包 UseButton", "DetailPanel/UseButton")
			taps += await _tap_button_path(scene, sfx, "背包 BackButton", "Header/BackButton")
		"shop":
			_expect((scene.get_node("Header/BackButton") as BaseButton).has_meta("ui_button_sfx_wired"),
				"商店 BackButton 应接入按钮音效")
			taps += await _tap_button_path(scene, sfx, "商店 Tabs/Gems", "Tabs/Gems")
			taps += await _tap_button_path(scene, sfx, "商店 Card1", "ProductGrid/Cards/Card1")
			taps += await _tap_button_path(scene, sfx, "商店 PlusTenButton", "PopupOverlay/Panel/PlusTenButton")
			taps += await _tap_button_path(scene, sfx, "商店 MinusButton", "PopupOverlay/Panel/MinusButton")
			taps += await _tap_button_path(scene, sfx, "商店 CloseButton", "PopupOverlay/Panel/CloseButton")
		"album":
			_expect((scene.get_node("Header/BackButton") as BaseButton).has_meta("ui_button_sfx_wired"),
				"图鉴 BackButton 应接入按钮音效")
			taps += await _tap_button_path(scene, sfx, "图鉴 Fire", "AlbumPage/Filters/Fire")
			taps += await _tap_button_path(scene, sfx, "图鉴 NextButton", "AlbumPage/PageControls/NextButton")
			taps += await _tap_button_path(scene, sfx, "图鉴 Card1", "AlbumPage/Grid/Card1")
			taps += await _tap_button_path(scene, sfx, "图鉴 CloseButton", "DetailPanel/CloseButton")
			taps += await _tap_button_path(scene, sfx, "图鉴 BondTab", "BottomTabs/BondTab")
		"settings":
			scene.back_pressed.connect(func(): pass)
			var music_point: Vector2 = (scene.call("_get_row_rect", 1) as Rect2).get_center()
			taps += await _tap(sfx, "设置 背景音乐开关", func(): scene.call("_on_tap", music_point))
			var quality_rect: Rect2 = scene.call("_get_row_rect", 3)
			var segment_point := Vector2(quality_rect.position.x + quality_rect.size.x - 40.0, quality_rect.position.y + 27.0)
			taps += await _tap(sfx, "设置 画质分段", func(): scene.call("_on_tap", segment_point))
			taps += await _tap(sfx, "设置 重置数据", func(): scene.call("_on_tap", Vector2(103.0, 588.0)))
			taps += await _tap(sfx, "设置 取消重置", func(): scene.call("_on_tap", Vector2(255.0, 384.0)))
			taps += await _tap(sfx, "设置 返回", func(): scene.call("_on_tap", Vector2(39.0, 39.0)))
	return taps


func _tap_button_path(scene: Control, sfx, label: String, path: String) -> int:
	var button := scene.get_node(path) as BaseButton
	_expect(button.has_meta("ui_button_sfx_wired"), "%s 应接入按钮音效" % label)
	var action := func(): button.pressed.emit()
	return await _tap(sfx, label, action)


func _tap(sfx, label: String, action: Callable) -> int:
	var before_played: int = sfx.played_count
	var before_requests: int = sfx.request_count
	action.call()
	var played_delta: int = sfx.played_count - before_played
	var request_delta: int = sfx.request_count - before_requests
	if sfx.enabled:
		_expect(played_delta == 1, "%s 应只播放 1 声，实际 %d" % [label, played_delta])
		_expect(request_delta == 1, "%s 应只发 1 次播放请求，实际 %d" % [label, request_delta])
		_expect(sfx.last_sound_id == "button_click", "%s 应播放 button_click，实际 %s" % [label, sfx.last_sound_id])
	else:
		_expect(played_delta == 0, "%s soundOn=false 时不应播放，实际 %d" % [label, played_delta])
		_expect(request_delta == 0, "%s soundOn=false 时不应发请求，实际 %d" % [label, request_delta])
	await process_frame
	return 1


func _set_state(enabled: bool) -> void:
	var save_manager := root.get_node_or_null("/root/SaveManager")
	if save_manager != null:
		var settings: Dictionary = save_manager.load_settings().duplicate(true)
		settings["soundOn"] = enabled
		settings["musicOn"] = false
		settings["vibrationOn"] = false
		save_manager.save_settings(settings)
	BattleSfxScript.enabled = enabled


func _restore_settings() -> void:
	var save_manager := root.get_node_or_null("/root/SaveManager")
	if save_manager != null and not _original_settings.is_empty():
		save_manager.save_settings(_original_settings.duplicate(true))


func _print_counts() -> void:
	for row: Dictionary in _on_counts:
		print("[UiButtonSfx] on  page=%-14s taps=%d played=%d requests=%d dropped=%d players=%d" % [
			str(row["page"]), int(row["taps"]), int(row["played"]), int(row["requests"]),
			int(row["dropped"]), int(row["players"]),
		])
	for row: Dictionary in _off_counts:
		print("[UiButtonSfx] off page=%-14s taps=%d played=%d requests=%d dropped=%d players=%d" % [
			str(row["page"]), int(row["taps"]), int(row["played"]), int(row["requests"]),
			int(row["dropped"]), int(row["players"]),
		])
	print("[UiButtonSfx] totals: on_taps=%d on_played=%d on_requests=%d; off_taps=%d off_played=%d off_requests=%d" % [
		_sum(_on_counts, "taps"), _sum(_on_counts, "played"), _sum(_on_counts, "requests"),
		_sum(_off_counts, "taps"), _sum(_off_counts, "played"), _sum(_off_counts, "requests"),
	])


func _sum(rows: Array, key: String) -> int:
	var total := 0
	for row: Dictionary in rows:
		total += int(row.get(key, 0))
	return total


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[UiButtonSfx] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[UiButtonSfx] " + failure)
	quit(1)
