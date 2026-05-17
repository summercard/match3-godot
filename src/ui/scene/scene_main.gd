# ============================================
# ui/scene/scene_main.gd - 主菜单场景
# 翻译自: minigame-1/js/ui/sceneMain.js
# ============================================
# 核心职责：
# - 游戏主界面，显示关卡选择入口
# - 签到入口、图鉴入口、商店入口
# - 宠物展示区域

class_name SceneMain
extends Control

## 信号定义
signal button_pressed(btn_id: String)

## 设计尺寸
const DESIGN_WIDTH := 375.0
const DESIGN_HEIGHT := 667.0

## 按钮配置
const PRIMARY_BTN_W := 150.0
const PRIMARY_BTN_H := 120.0
const PRIMARY_GAP_X := 20.0
const PRIMARY_GAP_Y := 16.0
const GRID_START_Y := 200.0

const SECONDARY_BTN_W := 70.0
const SECONDARY_BTN_H := 65.0
const SECONDARY_GAP := 4.0

## 大厅美术资产
const MAIN_ASSETS := {
	"bg": "res://assets/images/main/main_lobby_bg.png",
	"title_plaque": "res://assets/images/main/ui_title_plaque.png",
	"player_panel": "res://assets/images/main/ui_player_panel.png",
	"currency_capsule": "res://assets/images/main/ui_currency_capsule.png",
	"card_primary": "res://assets/images/main/ui_card_primary.png",
	"card_primary_pressed": "res://assets/images/main/ui_card_primary_pressed.png",
	"nav_frame": "res://assets/images/main/ui_nav_frame.png",
	"nav_frame_pressed": "res://assets/images/main/ui_nav_frame_pressed.png",
	"icon_start": "res://assets/images/main/icon_start_adventure.png",
	"icon_team": "res://assets/images/main/icon_team.png",
	"icon_album": "res://assets/images/main/icon_album.png",
	"icon_signin": "res://assets/images/main/icon_signin.png",
	"icon_shop": "res://assets/images/main/icon_shop.png",
	"icon_inventory": "res://assets/images/main/icon_inventory.png",
	"icon_ranch": "res://assets/images/main/icon_ranch.png",
	"icon_achievement": "res://assets/images/main/icon_achievement.png",
	"icon_settings": "res://assets/images/main/icon_settings.png",
	"icon_avatar": "res://assets/images/main/icon_avatar.png",
	"icon_gold": "res://assets/images/main/icon_gold.png",
	"icon_diamond": "res://assets/images/main/icon_diamond.png",
	"icon_exp": "res://assets/images/main/icon_exp_star.png",
}

const BUTTON_ICON_KEYS := {
	"start": "icon_start",
	"team": "icon_team",
	"album": "icon_album",
	"signin": "icon_signin",
	"shop": "icon_shop",
	"inventory": "icon_inventory",
	"ranch": "icon_ranch",
	"achievement": "icon_achievement",
	"settings": "icon_settings",
}

## 按钮数据结构
class LobbyButton:
	var id: String
	var text: String
	var emoji: String
	var x: float
	var y: float
	var w: float
	var h: float
	var action: Callable
	var primary: bool
	var is_grid: bool

## 单例
static var instance: SceneMain

## 存档引用
var _storage: Node = null

## 内部变量
var _buttons: Array[LobbyButton] = []
var _touched_btn: LobbyButton = null
var _player: Dictionary = {
	"name": "冒险家",
	"level": 1,
	"gold": 0,
	"gems": 0,
	"exp": 0,
	"exp_to_level": 100
}

## 粒子系统
var _particles: Array[Dictionary] = []
var _particle_timer: float = 0.0

## Tooltip 状态
var _tooltip: Dictionary = {
	"text": "",
	"x": 0.0,
	"y": 0.0,
	"timer": 0.0,
	"opacity": 1.0
}

## 图标 TextureRect 缓存
var _icon_textures: Dictionary = {}

## Canvas 缓存（静态区域）
var _bg_cache: Image = null
var _bg_cache_valid: bool = false

## 美术资源（模拟加载）
var _art_assets: Dictionary = {}
var _art_ready: bool = false
var _art_loading_started: bool = false

## 主题颜色（从 theme.gd 获取）
const C := {
	"bg_medium": Color(0.04, 0.07, 0.15),
	"bg_card": Color(0.1, 0.15, 0.25),
	"primary": Color(0.1, 0.5, 1.0),
	"gold": Color(1.0, 0.8, 0.0),
	"text_primary": Color(1.0, 1.0, 1.0),
	"text_secondary": Color(0.7, 0.75, 0.85),
	"text_muted": Color(0.5, 0.55, 0.65),
	"primary_light": Color(0.3, 0.6, 1.0)
}

## Font sizes
const FONT_SIZES := {
	"title": 22.0,
	"subtitle": 16.0,
	"body": 14.0,
	"small": 12.0,
	"tiny": 10.0,
	"icon": 28.0,
	"number": 16.0,
	"display": 32.0
}

## ============================================
# 生命周期
## ============================================

var _bg_texture: TextureRect

func _add_background(image_path: String) -> void:
	if not ResourceLoader.exists(image_path):
		return
	_bg_texture = TextureRect.new()
	_bg_texture.texture = load(image_path)
	_bg_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_texture.stretch_mode = TextureRect.STRETCH_SCALE
	_bg_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_texture.z_index = -10
	add_child(_bg_texture)

func _add_icon(image_path: String, x: float, y: float, w: float, h: float) -> void:
	if not ResourceLoader.exists(image_path):
		return
	var tex := TextureRect.new()
	tex.texture = load(image_path)
	tex.position = Vector2(x, y)
	tex.size = Vector2(w, h)
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tex.z_index = -5
	add_child(tex)
	_icon_textures[image_path] = tex

func _add_button_icons() -> void:
	# 为按钮添加图标叠加层
	var icon_map := {
		"start": "res://assets/images/main/icon_start_adventure.png",
		"team": "res://assets/images/main/icon_team.png",
		"album": "res://assets/images/main/icon_album.png",
		"signin": "res://assets/images/main/icon_signin.png",
		"shop": "res://assets/images/main/icon_shop.png",
		"inventory": "res://assets/images/main/icon_inventory.png",
		"ranch": "res://assets/images/main/icon_ranch.png",
		"achievement": "res://assets/images/main/icon_achievement.png",
		"settings": "res://assets/images/main/icon_settings.png",
	}
	for btn in _buttons:
		var icon_path: String = icon_map.get(btn.id, "")
		if icon_path == "":
			continue
		var icon_size := 36.0 if btn.primary else 28.0
		var icon_x := btn.x + (btn.w - icon_size) / 2.0
		var icon_y := btn.y + (btn.h - icon_size) / 2.0 - (10.0 if btn.primary else 4.0)
		_add_icon(icon_path, icon_x, icon_y, icon_size, icon_size)
	
	# 头像图标
	_add_icon("res://assets/images/main/icon_avatar.png", 5.0, 35.0, 36.0, 36.0)
	# 金币图标
	_add_icon("res://assets/images/main/icon_gold.png", DESIGN_WIDTH - 140.0, 40.0, 20.0, 20.0)

func _ready() -> void:
	instance = self
	_load_art_assets()
	_build_buttons()
	_init_particles()

func init(data: Dictionary = {}) -> void:
	print("[SceneMain] 主菜单初始化")
	_load_player_data()
	_load_art_assets()
	_build_bg_cache()

## ============================================
# 初始化
## ============================================

func _load_player_data() -> void:
	# 从 SaveManager 读取真实存档数据
	if _storage == null:
		_storage = get_node_or_null("/root/SaveManager")
	
	if _storage != null and _storage.has_method("get_player"):
		var player: Dictionary = _storage.get_player()
		var level: int = player.get("level", 1)
		_player = {
			"name": player.get("name", "冒险家"),
			"level": level,
			"gold": player.get("gold", 0),
			"gems": player.get("gems", 0),
			"exp": player.get("exp", 0),
			"exp_to_level": SaveManager.get_exp_for_level(level)
		}
	else:
		_player = {
			"name": "冒险家",
			"level": 1,
			"gold": 0,
			"gems": 0,
			"exp": 0,
			"exp_to_level": 100
		}

func _build_buttons() -> void:
	var w := DESIGN_WIDTH
	
	# 计算网格居中起始 X
	var grid_total_w := PRIMARY_BTN_W * 2 + PRIMARY_GAP_X
	var grid_start_x := (w - grid_total_w) / 2.0
	
	_buttons = []
	
	# === 主按钮 2x2 网格 ===
	var primary_btns_data := [
		{ "id": "start", "text": "开始冒险", "emoji": "⚔️", "action": Callable(self, "_on_start_pressed") },
		{ "id": "team", "text": "队伍编成", "emoji": "👥", "action": Callable(self, "_on_team_pressed") },
		{ "id": "album", "text": "怪物图鉴", "emoji": "📖", "action": Callable(self, "_on_album_pressed") },
		{ "id": "signin", "text": "每日签到", "emoji": "📅", "action": Callable(self, "_on_signin_pressed") }
	]
	
	for i in range(4):
		var row := i / 2
		var col := i % 2
		var bx := grid_start_x + col * (PRIMARY_BTN_W + PRIMARY_GAP_X)
		var by := GRID_START_Y + row * (PRIMARY_BTN_H + PRIMARY_GAP_Y)
		
		var btn := LobbyButton.new()
		btn.id = primary_btns_data[i]["id"]
		btn.text = primary_btns_data[i]["text"]
		btn.emoji = primary_btns_data[i]["emoji"]
		btn.x = bx
		btn.y = by
		btn.w = PRIMARY_BTN_W
		btn.h = PRIMARY_BTN_H
		btn.action = primary_btns_data[i]["action"]
		btn.primary = true
		btn.is_grid = true
		_buttons.append(btn)
	
	# === 底部次要按钮 ===
	var bottom_start_y := GRID_START_Y + PRIMARY_BTN_H * 2 + PRIMARY_GAP_Y + 30
	var secondary_btns_data := [
		{ "id": "shop", "text": "商店", "emoji": "🏪", "action": Callable(self, "_on_shop_pressed") },
		{ "id": "inventory", "text": "背包", "emoji": "🎒", "action": Callable(self, "_on_inventory_pressed") },
		{ "id": "ranch", "text": "牧场", "emoji": "🏡", "action": Callable(self, "_on_ranch_pressed") },
		{ "id": "achievement", "text": "成就", "emoji": "🏆", "action": Callable(self, "_on_achievement_pressed") },
		{ "id": "settings", "text": "设置", "emoji": "⚙️", "action": Callable(self, "_on_settings_pressed") }
	]
	
	var secondary_total_w := secondary_btns_data.size() * SECONDARY_BTN_W + (secondary_btns_data.size() - 1) * SECONDARY_GAP
	var secondary_start_x := (w - secondary_total_w) / 2.0
	
	for i in range(secondary_btns_data.size()):
		var btn := LobbyButton.new()
		btn.id = secondary_btns_data[i]["id"]
		btn.text = secondary_btns_data[i]["text"]
		btn.emoji = secondary_btns_data[i]["emoji"]
		btn.x = secondary_start_x + i * (SECONDARY_BTN_W + SECONDARY_GAP)
		btn.y = bottom_start_y
		btn.w = SECONDARY_BTN_W
		btn.h = SECONDARY_BTN_H
		btn.action = secondary_btns_data[i]["action"]
		btn.primary = false
		btn.is_grid = false
		_buttons.append(btn)

func _load_art_assets() -> void:
	if _art_ready:
		return
	_art_loading_started = true
	for key in MAIN_ASSETS.keys():
		var path: String = MAIN_ASSETS[key]
		_art_assets[key] = load(path) if ResourceLoader.exists(path) else null
	_art_ready = true

func _init_particles() -> void:
	var particle_count := 18
	_particles = []
	for i in range(particle_count):
		_particles.append({
			"x": randf() * DESIGN_WIDTH,
			"y": randf() * DESIGN_HEIGHT,
			"size": 2.0 + randf() * 3.0,
			"base_opacity": 0.2 + randf() * 0.4,
			"opacity": 0.0,
			"speed_x": (randf() - 0.5) * 0.3,
			"speed_y": (randf() - 0.5) * 0.2,
			"phase": randf() * TAU,
			"phase_speed": 0.02 + randf() * 0.02
		})

func _build_bg_cache() -> void:
	_bg_cache_valid = true

## ============================================
# 按钮回调
## ============================================

func _on_start_pressed() -> void:
	emit_signal("button_pressed", "start")
	# TODO: 切换到关卡选择场景

func _on_team_pressed() -> void:
	emit_signal("button_pressed", "team")

func _on_album_pressed() -> void:
	emit_signal("button_pressed", "album")

func _on_signin_pressed() -> void:
	emit_signal("button_pressed", "signin")

func _on_shop_pressed() -> void:
	emit_signal("button_pressed", "shop")

func _on_inventory_pressed() -> void:
	emit_signal("button_pressed", "inventory")

func _on_ranch_pressed() -> void:
	emit_signal("button_pressed", "ranch")

func _on_achievement_pressed() -> void:
	emit_signal("button_pressed", "achievement")

func _on_settings_pressed() -> void:
	emit_signal("button_pressed", "settings")

## ============================================
# 输入处理
## ============================================

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var pos: Vector2 = event.position
		if event.pressed:
			_on_touch_start(pos.x, pos.y)
		else:
			_on_touch_end(pos.x, pos.y)
	elif event is InputEventScreenTouch:
		var pos: Vector2 = event.position
		if event.pressed:
			_on_touch_start(pos.x, pos.y)
		else:
			_on_touch_end(pos.x, pos.y)
	elif event is InputEventScreenDrag and event.pressed:
		pass  # 暂不处理拖拽

func _on_touch_start(x: float, y: float) -> void:
	for btn in _buttons:
		if _is_point_in_button(x, y, btn):
			_touched_btn = btn
			queue_redraw()
			return
	_touched_btn = null
	queue_redraw()

func _on_touch_end(x: float, y: float) -> void:
	if _touched_btn != null and _is_point_in_button(x, y, _touched_btn):
		_touched_btn.action.call()
	_touched_btn = null
	queue_redraw()

func _on_tap(x: float, y: float) -> void:
	for btn in _buttons:
		if _is_point_in_button(x, y, btn):
			btn.action.call()
			return

func _on_long_press(x: float, y: float) -> void:
	for btn in _buttons:
		if _is_point_in_button(x, y, btn):
			var desc := _get_button_description(btn.id)
			if desc != "":
				_show_button_tooltip(btn, desc)
			return

func _is_point_in_button(x: float, y: float, btn: LobbyButton) -> bool:
	return x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h

## ============================================
# Tooltip
## ============================================

func _get_button_description(btn_id: String) -> String:
	var descriptions := {
		"start": "选择关卡，开始三消冒险战斗！",
		"team": "编队你的怪物伙伴，打造最强阵容",
		"album": "查看已收服的怪物图鉴",
		"signin": "每日签到领取奖励",
		"shop": "购买道具和装备",
		"inventory": "查看和管理你的物品",
		"ranch": "牧场挂机培养，怪物自动获得经验",
		"achievement": "查看冒险成就进度",
		"settings": "游戏设置和选项"
	}
	return descriptions.get(btn_id, "")

func _show_button_tooltip(btn: LobbyButton, text: String) -> void:
	_tooltip = {
		"text": text,
		"x": btn.x + btn.w / 2.0,
		"y": btn.y - 12.0,
		"opacity": 1.0
	}

## ============================================
# 更新逻辑
## ============================================

func _process(delta: float) -> void:
	_update_particles(delta)
	
	# Tooltip 淡出
	if _tooltip.has("opacity") and _tooltip["opacity"] < 1.0:
		_tooltip["opacity"] -= 0.05
		if _tooltip["opacity"] <= 0.0:
			_tooltip.clear()
	
	queue_redraw()

func _update_particles(dt: float) -> void:
	var w := DESIGN_WIDTH
	var h := DESIGN_HEIGHT
	
	for p in _particles:
		p["x"] += p["speed_x"]
		p["y"] += p["speed_y"]
		
		if p["x"] < -10.0: p["x"] = w + 10.0
		if p["x"] > w + 10.0: p["x"] = -10.0
		if p["y"] < -10.0: p["y"] = h + 10.0
		if p["y"] > h + 10.0: p["y"] = -10.0
		
		p["phase"] += p["phase_speed"] * dt * 60.0
		var pulse := (sin(p["phase"]) + 1.0) / 2.0
		p["opacity"] = p["base_opacity"] * (0.5 + pulse * 0.5)

## ============================================
# 渲染
## ============================================

func _draw() -> void:
	var c := C
	
	# === 背景 ===
	var bg := _tex("bg")
	if bg != null:
		_draw_texture_cover(bg, Rect2(0, 0, DESIGN_WIDTH, DESIGN_HEIGHT))
		draw_rect(Rect2(0, 0, DESIGN_WIDTH, DESIGN_HEIGHT), Color(0.02, 0.04, 0.1, 0.18))
	else:
		draw_rect(Rect2(0, 0, DESIGN_WIDTH, DESIGN_HEIGHT), c["bg_medium"])
	
	# === 粒子背景 ===
	for p in _particles:
		if p["opacity"] > 0.01:
			var particle_color := Color(c["primary"].r, c["primary"].g, c["primary"].b, p["opacity"])
			_draw_circle(p["x"], p["y"], p["size"], particle_color)
	
	# === 玩家信息栏 ===
	_draw_lobby_title()
	_draw_info_bar()
	
	# === 绘制按钮 ===
	for btn in _buttons:
		if btn.is_grid:
			_draw_grid_button(btn)
		else:
			_draw_nav_button(btn)
	
	# === Tooltip ===
	if _tooltip.has("text") and String(_tooltip.get("text", "")) != "":
		_draw_tooltip()

## ============================================
# 绘制方法
## ============================================

func _draw_info_bar() -> void:
	var c := C
	var font_size := FONT_SIZES
	var panel_rect := Rect2(6.0, 14.0, 226.0, 72.0)
	
	# 背景面板
	if _tex("player_panel") != null:
		_draw_texture_fit(_tex("player_panel"), panel_rect)
	else:
		_draw_rounded_rect(panel_rect.position.x, panel_rect.position.y, panel_rect.size.x, panel_rect.size.y, 8.0, Color(c["bg_card"].r, c["bg_card"].g, c["bg_card"].b, 0.9))
	
	# 头像
	_draw_texture_fit(_tex("icon_avatar"), Rect2(15.0, 26.0, 48.0, 48.0))
	
	# 名称等级
	_draw_text_with_shadow("冒险家", 118.0, 39.0, c["text_primary"], font_size["body"], true)
	_draw_text_with_shadow("Lv.%d" % _player["level"], 196.0, 39.0, Color(0.95, 0.98, 1.0), font_size["small"], true)
	
	# 经验条
	var exp_bar_x := 76.0
	var exp_bar_y := 62.0
	var exp_bar_w := 112.0
	var exp_bar_h := 8.0
	
	_draw_texture_fit(_tex("icon_exp"), Rect2(52.0, 52.0, 24.0, 24.0))
	_draw_rounded_rect(exp_bar_x, exp_bar_y, exp_bar_w, exp_bar_h, 4.0, Color(0.08, 0.12, 0.24, 0.92))
	
	var exp_progress: float = minf(float(_player["exp"]) / float(_player["exp_to_level"]), 1.0)
	if exp_progress > 0.0:
		var fill_w: float = floor((exp_bar_w - 4.0) * exp_progress)
		_draw_rounded_rect(exp_bar_x + 2, exp_bar_y + 2, fill_w, exp_bar_h - 4, 3.0, c["primary"])
	
	# 经验文字
	_draw_text_with_shadow("%d/%d" % [_player["exp"], _player["exp_to_level"]], 212.0, 66.0, c["text_muted"], font_size["tiny"])
	
	_draw_currency(248.0, 28.0, "icon_gold", _format_number(_player["gold"]), c["gold"])
	_draw_currency(248.0, 56.0, "icon_diamond", _format_number(_player["gems"]), Color(0.55, 0.88, 1.0))

func _draw_grid_button(btn: LobbyButton) -> void:
	var c := C
	var font_size := FONT_SIZES
	var is_pressed := _touched_btn == btn
	var scale := 0.96 if is_pressed else 1.0
	var draw_w := btn.w * scale
	var draw_h := btn.h * scale
	var draw_x := btn.x + (btn.w - draw_w) / 2.0
	var draw_y := btn.y + (btn.h - draw_h) / 2.0
	var cx := btn.x + btn.w / 2.0
	var cy := btn.y + btn.h / 2.0
	
	# 按钮背景
	var frame_key := "card_primary_pressed" if is_pressed else "card_primary"
	if _tex(frame_key) != null:
		_draw_texture_fit(_tex(frame_key), Rect2(draw_x, draw_y, draw_w, draw_h))
	else:
		_draw_rounded_rect(draw_x, draw_y, draw_w, draw_h, 12.0, c["bg_card"], 0.95)
	
	if is_pressed:
		_draw_rounded_rect(draw_x, draw_y, draw_w, draw_h, 12.0, c["primary"], 0.13)
	
	# 功能图标
	var icon_key: String = BUTTON_ICON_KEYS.get(btn.id, "")
	var icon := _tex(icon_key)
	if icon != null:
		_draw_texture_fit(icon, Rect2(cx - 34.0, cy - 48.0, 68.0, 68.0))
	else:
		_draw_text_with_shadow(btn.emoji, cx, cy - 22, c["primary"], font_size["display"])
	
	# 标签文字
	_draw_text_with_shadow(btn.text, cx, cy + 35, c["text_primary"], font_size["body"], true)

func _draw_nav_button(btn: LobbyButton) -> void:
	var c := C
	var font_size := FONT_SIZES
	var is_pressed := _touched_btn == btn
	var scale := 0.95 if is_pressed else 1.0
	var draw_w := btn.w * scale
	var draw_h := btn.h * scale
	var draw_x := btn.x + (btn.w - draw_w) / 2.0
	var draw_y := btn.y + (btn.h - draw_h) / 2.0
	var cx := btn.x + btn.w / 2.0
	
	# 按钮背景
	var frame_key := "nav_frame_pressed" if is_pressed else "nav_frame"
	if _tex(frame_key) != null:
		_draw_texture_fit(_tex(frame_key), Rect2(draw_x, draw_y, draw_w, draw_h))
	else:
		_draw_rounded_rect(draw_x, draw_y, draw_w, draw_h, 8.0, c["bg_card"], 0.9)
	
	# 功能图标
	var icon_key: String = BUTTON_ICON_KEYS.get(btn.id, "")
	var icon := _tex(icon_key)
	if icon != null:
		_draw_texture_fit(icon, Rect2(cx - 18.0, btn.y + 7.0, 36.0, 36.0))
	else:
		_draw_text_with_shadow(btn.emoji, cx, btn.y + 28, c["primary"], font_size["icon"])
	
	# 标签文字
	_draw_text_with_shadow(btn.text, cx, btn.y + 54, c["text_primary"], font_size["tiny"], true)

func _draw_lobby_title() -> void:
	var title_rect := Rect2(55.0, 104.0, 265.0, 72.0)
	if _tex("title_plaque") != null:
		_draw_texture_fit(_tex("title_plaque"), title_rect)
	else:
		_draw_rounded_rect(title_rect.position.x, title_rect.position.y, title_rect.size.x, title_rect.size.y, 10.0, Color(0.08, 0.14, 0.28, 0.88))
	_draw_text_with_shadow("冒 险 大 厅", DESIGN_WIDTH / 2.0, 139.0, Color(1.0, 0.96, 0.72), FONT_SIZES["title"], true)
	_draw_text_with_shadow("Monster Match Hub", DESIGN_WIDTH / 2.0, 163.0, Color(0.72, 0.86, 1.0), FONT_SIZES["tiny"])

func _draw_currency(x: float, y: float, icon_key: String, value: String, color: Color) -> void:
	_draw_texture_fit(_tex("currency_capsule"), Rect2(x, y - 13.0, 112.0, 26.0))
	_draw_texture_fit(_tex(icon_key), Rect2(x + 5.0, y - 14.0, 26.0, 26.0))
	_draw_text_with_shadow(value, x + 72.0, y + 5.0, color, FONT_SIZES["small"], true)

func _tex(key: String) -> Texture2D:
	var tex = _art_assets.get(key)
	if tex is Texture2D:
		return tex
	return null

func _draw_texture_fit(tex: Texture2D, rect: Rect2, opacity: float = 1.0) -> void:
	if tex == null:
		return
	draw_texture_rect(tex, rect, false, Color(1.0, 1.0, 1.0, opacity))

func _draw_texture_cover(tex: Texture2D, rect: Rect2, opacity: float = 1.0) -> void:
	if tex == null:
		return
	var tex_size := tex.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	var scale := maxf(rect.size.x / tex_size.x, rect.size.y / tex_size.y)
	var source_size := rect.size / scale
	var source_pos := (tex_size - source_size) * 0.5
	draw_texture_rect_region(tex, rect, Rect2(source_pos, source_size), Color(1.0, 1.0, 1.0, opacity))

func _draw_tooltip() -> void:
	var text: String = _tooltip["text"]
	var x: float = _tooltip["x"]
	var y: float = _tooltip["y"]
	var opacity: float = _tooltip.get("opacity", 1.0)
	
	var alpha_int := int(opacity * 230)
	var alpha_hex := "%02x" % alpha_int
	
	var padding := 10.0
	var text_width := text.length() * FONT_SIZES["small"] * 0.6
	var bg_x := x - text_width / 2.0 - padding
	var bg_y := y - FONT_SIZES["small"] - padding
	var bg_w := text_width + padding * 2.0
	var bg_h := FONT_SIZES["small"] + padding * 2.0
	
	var bg_color := Color(0.1, 0.1, 0.18, opacity * 0.9)
	_draw_rounded_rect(bg_x, bg_y, bg_w, bg_h, 8.0, bg_color)
	
	var text_color := Color(1.0, 1.0, 1.0, opacity)
	draw_string(ThemeDB.fallback_font, Vector2(x, y + 5), text, HORIZONTAL_ALIGNMENT_CENTER, bg_w - padding * 2, FONT_SIZES["small"], text_color)

func _draw_text_with_shadow(text: String, x: float, y: float, color: Color, size: float, bold: bool = false) -> void:
	var shadow_color := Color(0.0, 0.0, 0.0, 0.55)
	var text_w := 200.0
	draw_string(ThemeDB.fallback_font, Vector2(x - text_w / 2.0 + 1, y + 2), text, HORIZONTAL_ALIGNMENT_CENTER, text_w, size, shadow_color)
	draw_string(ThemeDB.fallback_font, Vector2(x - text_w / 2.0, y), text, HORIZONTAL_ALIGNMENT_CENTER, text_w, size, color)

func _draw_rounded_rect(x: float, y: float, w: float, h: float, r: float, color: Color, alpha: float = 1.0) -> void:
	if alpha < 1.0:
		color.a = alpha
	# 简化圆角矩形：直接用 draw_rect 配合角块
	draw_rect(Rect2(x + r, y, w - r * 2, h), color)
	draw_rect(Rect2(x, y + r, w, h - r * 2), color)
	draw_rect(Rect2(x, y, r, r), color)
	draw_rect(Rect2(x + w - r, y, r, r), color)
	draw_rect(Rect2(x, y + h - r, r, r), color)
	draw_rect(Rect2(x + w - r, y + h - r, r, r), color)

func _draw_circle(x: float, y: float, r: float, color: Color) -> void:
	# 使用多个小矩形模拟圆形（简化版本）
	for dy in range(-int(r), int(r) + 1):
		for dx in range(-int(r), int(r) + 1):
			if dx * dx + dy * dy <= r * r:
				draw_rect(Rect2(x + dx, y + dy, 1, 1), color)

func _format_number(num: int) -> String:
	return str(num)

## ============================================
# 清理
## ============================================

func destroy() -> void:
	_particles.clear()
	_tooltip.clear()
