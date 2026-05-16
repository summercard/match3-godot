# scene_settings.gd - 设置场景
# 翻译来源: js/ui/sceneSettings.js
class_name SceneSettings extends Control

## 布局常量
const DESIGN_W := 375.0
const DESIGN_H := 667.0
const ITEM_W := 280.0
const ITEM_H := 56.0
const TOGGLE_W := 50.0
const TOGGLE_H := 28.0
const BTN_W := 100.0
const BTN_H := 38.0

var game: Node
var settings_data: Dictionary = {}
var ui: Dictionary = {}
var confirm_dialog: Dictionary = {}
var reset_success: bool = false
var tap_handler: Callable

var _bg_texture: ColorRect

func _add_dark_background() -> void:
	_bg_texture = ColorRect.new()
	_bg_texture.color = Color(0.04, 0.07, 0.15, 1.0)
	_bg_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_texture.z_index = -10
	add_child(_bg_texture)

func _init(game_ref: Node = null) -> void:
	game = game_ref
	_add_dark_background()


func init(data: Dictionary = {}) -> void:
	print("[SceneSettings] 设置场景初始化")
	if game == null:
		game = get_node_or_null("/root/GameManager")
	_load_settings()
	_build_ui()
	tap_handler = Callable(self, "_on_tap")
	_set_input_handler()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_tap(event.position.x, event.position.y)
		accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		_on_tap(event.position.x, event.position.y)
		accept_event()


func _load_settings() -> void:
	var storage = preload("res://src/core/save_manager.gd").new()
	settings_data = storage.load_settings()
	storage.free()


func _build_ui() -> void:
	var w: float = DESIGN_W
	var h: float = DESIGN_H
	ui = {
		"title_y": h * 0.08,
		"items": [],
		"back_btn": null,
		"confirm_box": null
	}

	var item_x: float = (w - ITEM_W) / 2
	var start_y: float = h * 0.22
	var gap: float = 14.0

	var sound_on: bool = settings_data.get("soundOn", true)
	var music_on: bool = settings_data.get("musicOn", true)

	ui.items = [
		_create_toggle_item("sound", "🔊 游戏音效", start_y, sound_on),
		_create_toggle_item("music", "🎵 背景音乐", start_y + ITEM_H + gap, music_on)
	]

	# 重置数据按钮
	var reset_y: float = start_y + (ITEM_H + gap) * 2 + 20
	ui.items.append({
		"id": "reset",
		"label": "🗑️ 重置游戏数据",
		"y": reset_y,
		"x": item_x,
		"w": ITEM_W,
		"h": ITEM_H,
		"is_on": null
	})

	ui.version_y = h * 0.85
	ui.version = settings_data.get("version", "v0.1.0")

	ui.back_btn = {
		"id": "back",
		"label": "← 返回",
		"x": 15.0,
		"y": h * 0.05,
		"w": 80.0,
		"h": 36.0
	}


func _create_toggle_item(id: String, label: String, y: float, is_on: bool) -> Dictionary:
	var w: float = DESIGN_W
	return {
		"id": id,
		"label": label,
		"y": y,
		"x": (w - ITEM_W) / 2,
		"w": ITEM_W,
		"h": ITEM_H,
		"is_on": is_on,
		"toggle_x": (w - ITEM_W) / 2 + ITEM_W - 60,
		"toggle_w": TOGGLE_W,
		"toggle_h": TOGGLE_H
	}


func _set_input_handler() -> void:
	# 连接 game 的输入信号（根据实际输入系统实现）
	pass


func _on_tap(x: float, y: float) -> void:
	# 确认弹窗
	if confirm_dialog.size() > 0:
		var yes_btn: Dictionary = confirm_dialog.yes_btn
		var no_btn: Dictionary = confirm_dialog.no_btn
		if x >= yes_btn.x and x <= yes_btn.x + yes_btn.w and y >= yes_btn.y and y <= yes_btn.y + yes_btn.h:
			_do_reset_data()
			return
		if x >= no_btn.x and x <= no_btn.x + no_btn.w and y >= no_btn.y and y <= no_btn.y + no_btn.h:
			confirm_dialog = {}
			return
		return

	# 返回按钮
	var back: Dictionary = ui.back_btn
	if x >= back.x and x <= back.x + back.w and y >= back.y and y <= back.y + back.h:
		_save_and_back()
		return

	# 设置项点击
	for item in ui.items:
		if item.id == "reset":
			if x >= item.x and x <= item.x + item.w and y >= item.y and y <= item.y + item.h:
				_show_reset_confirm()
				return
		else:
			var toggle_x: float = item.toggle_x
			var toggle_y: float = item.y + (item.h - item.toggle_h) / 2
			if x >= toggle_x and x <= toggle_x + item.toggle_w and y >= toggle_y and y <= toggle_y + item.toggle_h:
				_toggle_setting(item.id)
				return


func _toggle_setting(id: String) -> void:
	if id == "sound":
		settings_data["soundOn"] = not settings_data.get("soundOn", true)
	elif id == "music":
		settings_data["musicOn"] = not settings_data.get("musicOn", true)
	_save_settings()
	print("[SceneSettings] " + id + " = " + ("true" if id == "sound" else "false" if id == "music" else ""))


func _save_settings() -> void:
	var storage = preload("res://src/core/save_manager.gd").new()
	storage.save_settings(settings_data)
	storage.free()


func _show_reset_confirm() -> void:
	var w: float = DESIGN_W
	var h: float = DESIGN_H
	var box_w: float = 260
	var box_h: float = 140
	var box_x: float = (w - box_w) / 2
	var box_y: float = (h - box_h) / 2
	var btn_gap: float = 20
	var btn_y: float = box_y + box_h - 55
	var yes_x: float = box_x + (box_w - BTN_W * 2 - btn_gap) / 2
	var no_x: float = yes_x + BTN_W + btn_gap

	confirm_dialog = {
		"box": {"x": box_x, "y": box_y, "w": box_w, "h": box_h},
		"yes_btn": {"id": "yes", "x": yes_x, "y": btn_y, "w": BTN_W, "h": BTN_H},
		"no_btn": {"id": "no", "x": no_x, "y": btn_y, "w": BTN_W, "h": BTN_H}
	}


func _do_reset_data() -> void:
	confirm_dialog = {}
	# 清除所有存档
	var storage = preload("res://src/core/save_manager.gd").new()
	storage.clear_all_data()
	storage.free()
	print("[SceneSettings] 游戏数据已重置")
	_show_reset_success()


func _show_reset_success() -> void:
	reset_success = true
	# 延迟返回主菜单（1.5秒后）
	await get_tree().create_timer(1.5).timeout
	_go_main()


func _save_and_back() -> void:
	_save_settings()
	_go_main()


func _go_main() -> void:
	if game and game.get("scene_manager") and game.scene_manager.has_method("switch_scene"):
		game.scene_manager.switch_scene("main", {}, "slide")
	elif has_node("/root/SceneManager"):
		get_node("/root/SceneManager").switch_scene("main", {}, "slide")


func _draw() -> void:
	var theme = _get_theme()

	# 背景
	_draw_rect(Rect2(0, 0, size.x, size.y), theme.bg_medium)

	# 标题
	_draw_text("⚙️ 游戏设置", Vector2(size.x / 2, ui.title_y + 30), theme.text_primary, theme.font.title.size, theme.font.title.weight)

	# 返回按钮
	var back: Dictionary = ui.back_btn
	_draw_rect(Rect2(back.x, back.y, back.w, back.h), theme.buttons.secondary.bg_color)
	_draw_text(back.label, Vector2(back.x + 16, back.y + back.h / 2 + 5), theme.buttons.secondary.text_color, theme.font.body.size)

	# 设置项
	for item in ui.items:
		if item.id == "reset":
			_draw_rect(Rect2(item.x, item.y, item.w, item.h), theme.danger)
			_draw_text(item.label, Vector2(item.x + item.w / 2, item.y + item.h / 2 + 5), theme.white, theme.font.body.size, theme.font.body.weight)
		else:
			# 开关设置项背景
			_draw_rect(Rect2(item.x, item.y, item.w, item.h), theme.bg_card)
			# 标签
			_draw_text(item.label, Vector2(item.x + 16, item.y + item.h / 2 + 5), theme.text_secondary, theme.font.body.size, theme.font.body.weight)

			# 开关状态
			var is_on: bool = true
			if item.id == "sound":
				is_on = settings_data.get("soundOn", true)
			else:
				is_on = settings_data.get("musicOn", true)

			var toggle_x: float = item.toggle_x
			var toggle_y: float = item.y + (item.h - item.toggle_h) / 2

			# 开关轨道
			var track_color: Color = theme.success if is_on else theme.text_dark
			_draw_rect(Rect2(toggle_x, toggle_y, item.toggle_w, item.toggle_h), track_color)
			_draw_rect(Rect2(toggle_x, toggle_y, item.toggle_w, item.toggle_h), track_color)
			_draw_circle(Vector2(toggle_x + item.toggle_h / 2 - 1, toggle_y + item.toggle_h / 2), item.toggle_h / 2 - 3, theme.white)
			# ON/OFF 文字
			var label_color: Color = theme.white if is_on else theme.text_muted
			_draw_text("ON" if is_on else "OFF", Vector2(toggle_x + item.toggle_w / 2, toggle_y + item.toggle_h / 2 + 4), label_color, theme.font.tiny.size, theme.font.tiny.weight)

	# 确认弹窗
	if confirm_dialog.size() > 0:
		var d: Dictionary = confirm_dialog
		# 遮罩
		_draw_rect(Rect2(0, 0, size.x, size.y), Color(0, 0, 0, 0.7))
		# 弹窗背景
		_draw_rect(Rect2(d.box.x, d.box.y, d.box.w, d.box.h), theme.bg_card)
		# 提示文字
		_draw_text("确认重置？", Vector2(d.box.x + d.box.w / 2, d.box.y + 40), theme.danger, theme.font.subtitle.size, theme.font.subtitle.weight)
		_draw_text("所有数据将被清除，无法恢复", Vector2(d.box.x + d.box.w / 2, d.box.y + 65), theme.text_muted, theme.font.small.size)
		# 按钮
		_draw_rect(Rect2(d.yes_btn.x, d.yes_btn.y, d.yes_btn.w, d.yes_btn.h), theme.danger)
		_draw_text("确认", Vector2(d.yes_btn.x + d.yes_btn.w / 2, d.yes_btn.y + d.yes_btn.h / 2 + 5), theme.white, theme.font.body.size, theme.font.body.weight)
		_draw_rect(Rect2(d.no_btn.x, d.no_btn.y, d.no_btn.w, d.no_btn.h), theme.buttons.secondary.bg_color)
		_draw_text("取消", Vector2(d.no_btn.x + d.no_btn.w / 2, d.no_btn.y + d.no_btn.h / 2 + 5), theme.buttons.secondary.text_color, theme.font.body.size)

	# 重置成功提示
	if reset_success:
		_draw_text("✅ 数据已重置", Vector2(size.x / 2, ui.title_y + 80), theme.success, theme.font.subtitle.size, theme.font.subtitle.weight)

	# 版本信息
	_draw_text(ui.version, Vector2(size.x / 2, ui.version_y), theme.text_dark, theme.font.small.size)


func _draw_rect(rect: Rect2, color: Color) -> void:
	draw_rect(rect, color, true)


func _draw_circle(center: Vector2, radius: float, color: Color) -> void:
	draw_circle(center, radius, color)


func _draw_text(text: String, pos: Vector2, color: Color, size: float = 16, weight: int = 0) -> void:
	var f = ThemeDB.fallback_font
	var fnt_size = int(size * 2)
	draw_string(f, Vector2(pos.x - 100, pos.y), text, HORIZONTAL_ALIGNMENT_CENTER, 200, fnt_size, color)


func _get_theme():
	if ResourceLoader.exists("res://src/core/theme.gd"):
		var theme_res = load("res://src/core/theme.gd")
		if theme_res:
			var inst = theme_res.new()
			var result = inst.get_theme_data()
			inst.free()
			return result
	return _get_default_theme()


func _get_default_theme():
	return {
		"bg_medium": Color("#16213e"),
		"bg_card": Color("#1a1a2e"),
		"text_primary": Color("#e8e8e8"),
		"text_secondary": Color("#a0a0a0"),
		"text_muted": Color("#6b6b6b"),
		"text_dark": Color("#2d2d2d"),
		"primary": Color("#4a90d9"),
		"gold": Color("#f5c518"),
		"success": Color("#4caf50"),
		"danger": Color("#e53935"),
		"white": Color("#ffffff"),
		"font": {
			"title": {"size": 22, "weight": 700},
			"subtitle": {"size": 18, "weight": 600},
			"body": {"size": 14, "weight": 400},
			"small": {"size": 12, "weight": 400},
			"tiny": {"size": 10, "weight": 400}
		},
		"buttons": {
			"primary": {"bg_color": Color("#4a90d9"), "text_color": Color("#ffffff"), "font_size": 14, "font_weight": 600},
			"secondary": {"bg_color": Color("#2d2d44"), "text_color": Color("#e8e8e8"), "font_size": 14, "font_weight": 400},
			"danger": {"bg_color": Color("#e53935"), "text_color": Color("#ffffff"), "font_size": 14, "font_weight": 600}
		},
		"radius": {"sm": 4, "md": 8, "lg": 16}
	}


func _process(_delta: float) -> void:
	queue_redraw()
