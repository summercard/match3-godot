@tool
# scene_settings.gd - 设置场景
class_name SceneSettings
extends Control

signal back_pressed()

const _RoundFontSrc := preload("res://assets/fonts/jf-openhuninn-2.1.ttf")

const DESIGN_W := 375.0
const DESIGN_H := 667.0
const BACK_RECT := Rect2(10.0, 10.0, 58.0, 58.0)
const HEADER_RECT := Rect2(88.0, 17.0, 232.0, 52.0)
const MAIN_PANEL_RECT := Rect2(14.0, 86.0, 347.0, 386.0)
const ABOUT_PANEL_RECT := Rect2(18.0, 486.0, 339.0, 58.0)
const RESET_RECT := Rect2(34.0, 565.0, 138.0, 46.0)
const DEFAULT_RECT := Rect2(203.0, 565.0, 138.0, 46.0)
const ROW_X := 30.0
const ROW_W := 315.0
const ROW_H := 54.0
const ROW_START_Y := 130.0
const ROW_GAP := 9.0
const CONFIRM_BOX := Rect2(41.0, 241.0, 293.0, 182.0)
const CONFIRM_YES := Rect2(64.0, 363.0, 112.0, 42.0)
const CONFIRM_NO := Rect2(199.0, 363.0, 112.0, 42.0)

const SETTINGS_ASSETS := {
	"bg": "res://assets/images/ui/backgrounds/main_lobby_bg_day_v3.png",
	"dark_overlay": "res://assets/images/ui/backgrounds/black.png",
	"back": "res://assets/images/ui/buttons/ranch_ui_btn_previous_round.png",
	"header": "res://assets/images/ui/panels/shop_ui_shop_title_plaque_image2.png",
	"title_ribbon": "res://assets/images/ui/buttons/inventory_new_ui_inventory_tab_active.png",
	"panel": "res://assets/images/ui/panels/inventory_new_ui_inventory_panel.png",
	"row": "res://assets/images/ui/panels/inventory_new_ui_inventory_detail_panel.png",
	"row_alt": "res://assets/images/ui/panels/inventory_new_ui_inventory_detail_panel.png",
	"tab_active": "res://assets/images/ui/buttons/inventory_new_ui_inventory_tab_active.png",
	"tab_inactive": "res://assets/images/ui/buttons/inventory_new_ui_inventory_tab_normal.png",
	"button": "res://assets/images/ui/buttons/inventory_new_ui_inventory_use_button.png",
	"button_disabled": "res://assets/images/ui/buttons/inventory_new_ui_inventory_tab_normal.png",
	"gear": "res://assets/images/ui/icons/common_nav_icon_nav_settings.png",
	"notice": "res://assets/images/ui/icons/main_icon_plus_v3.png",
}
const SETTINGS_ROWS := [
	{
		"id": "sound",
		"label": "游戏音效",
		"desc": "消除、按钮与奖励反馈",
		"type": "toggle",
		"key": "soundOn",
		"default": true,
	},
	{
		"id": "music",
		"label": "背景音乐",
		"desc": "大厅、战斗与结算音乐",
		"type": "toggle",
		"key": "musicOn",
		"default": true,
	},
	{
		"id": "vibration",
		"label": "震动反馈",
		"desc": "技能、胜利与按钮触感",
		"type": "toggle",
		"key": "vibrationOn",
		"default": true,
	},
	{
		"id": "quality",
		"label": "画质等级",
		"desc": "界面特效与资源清晰度",
		"type": "segment",
		"key": "qualityLevel",
		"default": "high",
		"options": [
			{"label": "流畅", "value": "low"},
			{"label": "标准", "value": "medium"},
			{"label": "精细", "value": "high"},
		],
	},
	{
		"id": "performance",
		"label": "战斗表现",
		"desc": "动画、粒子和屏幕反馈",
		"type": "segment",
		"key": "performanceMode",
		"default": "balanced",
		"options": [
			{"label": "轻量", "value": "lite"},
			{"label": "均衡", "value": "balanced"},
			{"label": "华丽", "value": "rich"},
		],
	},
]
const C := {
	"white": Color(1.0, 1.0, 1.0),
	"muted": Color(0.62, 0.36, 0.12),
	"dim": Color(0.55, 0.31, 0.10),
	"gold": Color(1.0, 0.78, 0.18),
	"green": Color(0.58, 1.0, 0.35),
	"blue": Color(0.35, 0.72, 1.0),
	"red": Color(1.0, 0.30, 0.22),
	"shadow": Color(0.0, 0.0, 0.0, 0.58),
	"panel_dark": Color(1.0, 0.93, 0.74, 0.24),
}

var game: Node = null
var settings_data: Dictionary = {}
var confirm_dialog := false
var reset_success := false
var _storage: Node = null
var _texture_cache: Dictionary = {}
var _round_font_normal: Font = null
var _round_font_bold: Font = null

# === 设置入场动画状态（_draw 风格）===
const ENTRY_DURATION := 0.42
const ENTRY_TOP_OFFSET_START := 26.0
const ENTRY_BOTTOM_OFFSET_START := 22.0
var _entry_t := 0.0
var _process_enabled := false


func _init(game_ref: Node = null) -> void:
	game = game_ref


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_process_enabled = true
	set_process(true)
	self.modulate.a = 0.0  # 入场动画起点：透明


func init(_data: Dictionary = {}) -> void:
	if game == null:
		game = _get_autoload("GameManager")
	_storage = _get_storage()
	_load_settings()
	confirm_dialog = false
	reset_success = false
	queue_redraw()


func _get_storage() -> Node:
	if _storage and is_instance_valid(_storage):
		return _storage
	_storage = _get_autoload("SaveManager")
	if _storage == null and game and game.get("storage"):
		_storage = game.storage
	return _storage


func _get_autoload(node_name: String) -> Node:
	if not is_inside_tree():
		return null
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(node_name)


func _load_settings() -> void:
	var storage := _get_storage()
	settings_data = storage.load_settings() if storage and storage.has_method("load_settings") else {}
	for row: Dictionary in SETTINGS_ROWS:
		var key := str(row.get("key", ""))
		if key != "" and not settings_data.has(key):
			settings_data[key] = row.get("default")
	settings_data["version"] = settings_data.get("version", "v0.1.0")


func _save_settings() -> void:
	var storage := _get_storage()
	if storage and storage.has_method("save_settings"):
		storage.save_settings(settings_data)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_tap(event.position)
		accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		_on_tap(event.position)
		accept_event()


func _on_tap(point: Vector2) -> void:
	if confirm_dialog:
		if CONFIRM_YES.has_point(point):
			_do_reset_data()
			return
		if CONFIRM_NO.has_point(point):
			confirm_dialog = false
			queue_redraw()
			return
		return

	if BACK_RECT.has_point(point):
		_save_and_back()
		return
	if RESET_RECT.has_point(point):
		confirm_dialog = true
		queue_redraw()
		return
	if DEFAULT_RECT.has_point(point):
		_restore_defaults()
		return

	for i in range(SETTINGS_ROWS.size()):
		var row: Dictionary = SETTINGS_ROWS[i]
		var row_rect := _get_row_rect(i)
		if not row_rect.has_point(point):
			continue
		if row.get("type", "") == "toggle":
			_toggle_bool(str(row.get("key", "")))
			return
		if row.get("type", "") == "segment":
			var hit := _hit_segment(row, row_rect, point)
			if hit != "":
				settings_data[str(row.get("key", ""))] = hit
				_save_settings()
				queue_redraw()
			return


func _toggle_bool(key: String) -> void:
	if key.is_empty():
		return
	settings_data[key] = not bool(settings_data.get(key, true))
	_save_settings()
	queue_redraw()


func _restore_defaults() -> void:
	for row: Dictionary in SETTINGS_ROWS:
		settings_data[str(row.get("key", ""))] = row.get("default")
	_save_settings()
	reset_success = false
	queue_redraw()


func _show_reset_success() -> void:
	reset_success = true
	queue_redraw()
	await get_tree().create_timer(1.2).timeout
	_go_main()


func _do_reset_data() -> void:
	confirm_dialog = false
	var storage := _get_storage()
	if storage and storage.has_method("clear_all_data"):
		storage.clear_all_data()
	if storage and storage.has_method("reset_tutorial_progress"):
		storage.reset_tutorial_progress()
	elif storage and storage.has_method("save_tutorial_progress"):
		storage.save_tutorial_progress(0)
	_show_reset_success()


func _save_and_back() -> void:
	_save_settings()
	if back_pressed.get_connections().size() > 0:
		back_pressed.emit()
	else:
		_go_main()


func _go_main() -> void:
	if game and game.get("scene_manager") and game.scene_manager.has_method("switch_scene"):
		game.scene_manager.switch_scene("main", {}, "slide")
	else:
		var scene_manager := _get_autoload("SceneManager")
		if scene_manager and scene_manager.has_method("switch_scene"):
			scene_manager.switch_scene("main", {}, "slide")


func _get_row_rect(index: int) -> Rect2:
	return Rect2(ROW_X, ROW_START_Y + index * (ROW_H + ROW_GAP), ROW_W, ROW_H)


func _hit_segment(row: Dictionary, row_rect: Rect2, point: Vector2) -> String:
	var options: Array = row.get("options", [])
	if options.is_empty():
		return ""
	var total_w := 128.0
	var seg_w := total_w / float(options.size())
	var start_x := row_rect.position.x + row_rect.size.x - total_w - 13.0
	var rect := Rect2(start_x, row_rect.position.y + 13.0, total_w, 28.0)
	if not rect.has_point(point):
		return ""
	var idx := clampi(int((point.x - rect.position.x) / seg_w), 0, options.size() - 1)
	return str(options[idx].get("value", ""))


func _process(delta: float) -> void:
	if not _process_enabled:
		return
	if _entry_t < ENTRY_DURATION:
		_entry_t = minf(_entry_t + delta, ENTRY_DURATION)
		# 整体淡入
		if _entry_t < ENTRY_DURATION:
			self.modulate.a = ease(_entry_t / ENTRY_DURATION, -1.5)
		else:
			self.modulate.a = 1.0
		queue_redraw()
	else:
		_process_enabled = false
		set_process(false)


func _draw() -> void:
	_draw_texture_cover(_tex("bg"), Rect2(0.0, 0.0, DESIGN_W, DESIGN_H))
	_draw_texture_cover(_tex("dark_overlay"), Rect2(0.0, 0.0, DESIGN_W, DESIGN_H), 0.5)
	# 顶部：header 从上方滑入
	var top_off := _entry_top_offset()
	if top_off != 0.0:
		draw_set_transform(Vector2(0.0, top_off))
	_draw_header()
	if top_off != 0.0:
		draw_set_transform(Vector2.ZERO)
	# 中间内容：跟随整体淡入
	_draw_main_panel()
	_draw_about_panel()
	# 底部：reset/default 按钮从下方滑入
	var bottom_off := _entry_bottom_offset()
	if bottom_off != 0.0:
		draw_set_transform(Vector2(0.0, bottom_off))
	_draw_bottom_buttons()
	if bottom_off != 0.0:
		draw_set_transform(Vector2.ZERO)
	if confirm_dialog:
		_draw_confirm_dialog()
	if reset_success:
		_draw_toast("数据已重置")


func _entry_top_offset() -> float:
	if _entry_t >= ENTRY_DURATION:
		return 0.0
	var progress := _entry_t / ENTRY_DURATION
	return -ENTRY_TOP_OFFSET_START * (1.0 - ease(progress, -1.5))


func _entry_bottom_offset() -> float:
	if _entry_t >= ENTRY_DURATION:
		return 0.0
	var progress := _entry_t / ENTRY_DURATION
	return ENTRY_BOTTOM_OFFSET_START * (1.0 - ease(progress, -1.5))


func _draw_header() -> void:
	_draw_texture_fit(_tex("back"), BACK_RECT)
	_draw_text("‹", BACK_RECT.get_center().x, BACK_RECT.position.y + 43.0, Color(1.0, 0.92, 0.78), 42.0, true, 44.0)
	_draw_texture_fit(_tex("header"), HEADER_RECT)
	_draw_texture_contain(_tex("gear"), Rect2(105.0, 24.0, 35.0, 35.0))
	_draw_text("游戏设置", HEADER_RECT.get_center().x + 18.0, HEADER_RECT.position.y + 35.0, C["white"], 24.0, true, 152.0)


func _draw_main_panel() -> void:
	_draw_texture_fit(_tex("panel"), MAIN_PANEL_RECT)
	draw_rect(Rect2(MAIN_PANEL_RECT.position + Vector2(14.0, 13.0), MAIN_PANEL_RECT.size - Vector2(28.0, 26.0)), C["panel_dark"], true)
	_draw_texture_fit(_tex("title_ribbon"), Rect2(104.0, 96.0, 166.0, 31.0))
	_draw_text("偏好设置", 187.0, 119.0, Color(1.0, 0.87, 0.38), 16.0, true, 124.0)
	for i in range(SETTINGS_ROWS.size()):
		_draw_setting_row(i, SETTINGS_ROWS[i])


func _draw_setting_row(index: int, row: Dictionary) -> void:
	var rect := _get_row_rect(index)
	_draw_texture_fit(_tex("row" if index % 2 == 0 else "row_alt"), rect, 0.96)
	var accent := C["blue"] if row.get("type", "") == "segment" else C["green"]
	draw_rect(Rect2(rect.position.x + 6.0, rect.position.y + 8.0, 3.0, rect.size.y - 16.0), accent, true)
	_draw_text_left(str(row.get("label", "")), Vector2(rect.position.x + 18.0, rect.position.y + 23.0), Color(0.43, 0.24, 0.07), 17.0, true, 128.0)
	_draw_text_left(str(row.get("desc", "")), Vector2(rect.position.x + 18.0, rect.position.y + 44.0), C["muted"], 10.0, false, 160.0)
	if row.get("type", "") == "toggle":
		_draw_toggle(rect, bool(settings_data.get(str(row.get("key", "")), row.get("default", true))))
	else:
		_draw_segments(rect, row)


func _draw_toggle(row_rect: Rect2, is_on: bool) -> void:
	var track := Rect2(row_rect.position.x + row_rect.size.x - 74.0, row_rect.position.y + 14.0, 56.0, 27.0)
	var color := Color(0.18, 0.72, 0.28) if is_on else Color(0.21, 0.27, 0.36)
	draw_circle(track.position + Vector2(track.size.y * 0.5, track.size.y * 0.5), track.size.y * 0.5, color)
	draw_circle(track.position + Vector2(track.size.x - track.size.y * 0.5, track.size.y * 0.5), track.size.y * 0.5, color)
	draw_rect(Rect2(track.position.x + track.size.y * 0.5, track.position.y, track.size.x - track.size.y, track.size.y), color, true)
	var knob_x := track.position.x + track.size.x - track.size.y * 0.5 if is_on else track.position.x + track.size.y * 0.5
	draw_circle(Vector2(knob_x, track.position.y + track.size.y * 0.5), 11.0, Color(1.0, 0.95, 0.77))
	_draw_text("ON" if is_on else "OFF", track.get_center().x, track.position.y + 19.0, C["white"], 10.0, true, 38.0)


func _draw_segments(row_rect: Rect2, row: Dictionary) -> void:
	var options: Array = row.get("options", [])
	var current := str(settings_data.get(str(row.get("key", "")), row.get("default", "")))
	var total_w := 128.0
	var seg_w := total_w / float(options.size())
	var start_x := row_rect.position.x + row_rect.size.x - total_w - 13.0
	for i in range(options.size()):
		var option: Dictionary = options[i]
		var active := current == str(option.get("value", ""))
		var rect := Rect2(start_x + i * seg_w, row_rect.position.y + 13.0, seg_w, 28.0)
		_draw_texture_fit(_tex("tab_active" if active else "tab_inactive"), rect)
		_draw_text(str(option.get("label", "")), rect.get_center().x, rect.position.y + 19.0, C["gold"] if active else C["muted"], 11.0, active, seg_w - 2.0)


func _draw_about_panel() -> void:
	_draw_texture_fit(_tex("row"), ABOUT_PANEL_RECT, 0.94)
	_draw_texture_contain(_tex("gear"), Rect2(30.0, 497.0, 34.0, 34.0), 0.92)
	_draw_text_left("当前版本", Vector2(76.0, 511.0), C["white"], 15.0, true, 88.0)
	_draw_text_left(str(settings_data.get("version", "v0.1.0")), Vector2(76.0, 532.0), C["muted"], 12.0, false, 90.0)
	_draw_text_left("设置会自动保存，返回大厅后立即生效", Vector2(170.0, 522.0), C["dim"], 11.0, false, 168.0)

func _draw_bottom_buttons() -> void:
	_draw_texture_fit(_tex("button_disabled"), RESET_RECT)
	_draw_text("重置数据", RESET_RECT.get_center().x, RESET_RECT.position.y + 30.0, Color(1.0, 0.36, 0.30), 16.0, true, 100.0)
	_draw_texture_fit(_tex("button"), DEFAULT_RECT)
	_draw_text("恢复默认", DEFAULT_RECT.get_center().x, DEFAULT_RECT.position.y + 30.0, C["white"], 16.0, true, 100.0)

func _draw_confirm_dialog() -> void:
	draw_rect(Rect2(0.0, 0.0, DESIGN_W, DESIGN_H), Color(0.0, 0.0, 0.0, 0.50), true)
	_draw_texture_fit(_tex("panel"), CONFIRM_BOX)
	draw_rect(Rect2(CONFIRM_BOX.position + Vector2(14.0, 14.0), CONFIRM_BOX.size - Vector2(28.0, 28.0)), Color(1.0, 0.92, 0.70, 0.34), true)
	_draw_texture_contain(_tex("notice"), Rect2(CONFIRM_BOX.position.x + 132.0, CONFIRM_BOX.position.y + 18.0, 28.0, 28.0))
	_draw_text("确认重置？", CONFIRM_BOX.get_center().x, CONFIRM_BOX.position.y + 62.0, Color(1.0, 0.38, 0.28), 22.0, true, 180.0)
	_draw_text("所有存档和养成进度会被清除", CONFIRM_BOX.get_center().x, CONFIRM_BOX.position.y + 93.0, C["muted"], 13.0, false, 220.0)
	_draw_texture_fit(_tex("button_disabled"), CONFIRM_YES)
	_draw_text("确认", CONFIRM_YES.get_center().x, CONFIRM_YES.position.y + 28.0, Color(1.0, 0.36, 0.30), 15.0, true, 82.0)
	_draw_texture_fit(_tex("button"), CONFIRM_NO)
	_draw_text("取消", CONFIRM_NO.get_center().x, CONFIRM_NO.position.y + 28.0, C["white"], 15.0, true, 82.0)

func _draw_toast(text: String) -> void:
	var rect := Rect2(96.0, 620.0, 183.0, 34.0)
	_draw_texture_fit(_tex("title_ribbon"), rect)
	_draw_text(text, rect.get_center().x, rect.position.y + 23.0, C["green"], 15.0, true, 150.0)


func _tex(key: String) -> Texture2D:
	if not _texture_cache.has(key):
		var path := str(SETTINGS_ASSETS.get(key, ""))
		_texture_cache[key] = load(path) if path != "" and ResourceLoader.exists(path) else null
	var tex = _texture_cache.get(key)
	return tex if tex is Texture2D else null


func _draw_texture_fit(tex: Texture2D, rect: Rect2, opacity: float = 1.0) -> void:
	if tex == null:
		return
	draw_texture_rect(tex, rect, false, Color(1.0, 1.0, 1.0, opacity))


func _draw_texture_contain(tex: Texture2D, rect: Rect2, opacity: float = 1.0) -> void:
	if tex == null:
		return
	var size := tex.get_size()
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var scale := minf(rect.size.x / size.x, rect.size.y / size.y)
	var draw_size := size * scale
	var draw_pos := rect.position + (rect.size - draw_size) * 0.5
	draw_texture_rect(tex, Rect2(draw_pos, draw_size), false, Color(1.0, 1.0, 1.0, opacity))


func _draw_texture_cover(tex: Texture2D, rect: Rect2, opacity: float = 1.0) -> void:
	if tex == null:
		draw_rect(rect, Color(0.04, 0.07, 0.15), true)
		return
	var size := tex.get_size()
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var scale := maxf(rect.size.x / size.x, rect.size.y / size.y)
	var source_size := rect.size / scale
	var source_pos := (size - source_size) * 0.5
	draw_texture_rect_region(tex, rect, Rect2(source_pos, source_size), Color(1.0, 1.0, 1.0, opacity))


func _draw_text(text: String, x: float, y: float, color: Color, font_size: float, bold: bool = false, width: float = 160.0) -> void:
	var font := _get_round_font(bold)
	var size_i := int(font_size)
	draw_string(font, Vector2(x - width / 2.0, y), text, HORIZONTAL_ALIGNMENT_CENTER, width, size_i, color)


func _draw_text_left(text: String, pos: Vector2, color: Color, font_size: float, bold: bool = false, width: float = 160.0) -> void:
	var font := _get_round_font(bold)
	var size_i := int(font_size)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, width, size_i, color)


func _get_round_font(bold: bool) -> Font:
	if bold:
		if _round_font_bold == null:
			var f := FontVariation.new()
			f.base_font = _RoundFontSrc
			f.set("variation_embolden", 0.95)
			_round_font_bold = f
		return _round_font_bold
	if _round_font_normal == null:
		var f := FontVariation.new()
		f.base_font = _RoundFontSrc
		f.set("variation_embolden", 0.45)
		_round_font_normal = f
	return _round_font_normal
