# ============================================
# ui/scene/scene_battle_prepare.gd - 战斗准备场景
# 翻译自: minigame-1/js/ui/sceneBattlePrepare.js
# ============================================
# 核心职责：
# - 队伍编辑（怪物选择 / 排序）
# - 阵型选择（攻击 / 防御 / 平衡）
# - 战斗道具携带
# - 开始战斗按钮

class_name SceneBattlePrepare
extends Control

const StageDBScript = preload("res://src/data/stage_db.gd")
const MonsterDBScript = preload("res://src/data/monster_db.gd")

## 信号定义
signal battle_started(stage_id: String, stage_data: Dictionary)

## 设计尺寸
const DESIGN_W := 375.0
const DESIGN_H := 667.0

## 布局参数
const MARGIN := 15.0

## 按钮区域
var _back_btn_rect: Rect2 = Rect2(15, 15, 60, 35)
var _start_btn_rect: Rect2 = Rect2(0, 555, 200, 50)

## 队伍显示区
const TEAM_Y := 292.0
const ENEMY_Y := 84.0
const HINT_Y := 444.0
const SYNERGY_Y := 504.0
const REWARD_Y := 552.0
const BTN_Y := 602.0

## 战斗准备美术资产
const PREPARE_ASSETS := {
	"bg": "res://assets/images/battle_prepare/battle_prepare_bg.png",
	"back_button": "res://assets/images/battle_prepare/ui_back_button.png",
	"back_arrow": "res://assets/images/stage/icon_back_arrow.png",
	"header": "res://assets/images/battle_prepare/ui_prepare_header.png",
	"team_card": "res://assets/images/battle_prepare/ui_team_card.png",
	"enemy_card": "res://assets/images/battle_prepare/ui_enemy_card.png",
	"power_panel": "res://assets/images/battle_prepare/ui_power_panel.png",
	"info_panel": "res://assets/images/battle_prepare/ui_info_panel.png",
	"synergy_panel": "res://assets/images/battle_prepare/ui_synergy_panel.png",
	"start_button": "res://assets/images/battle_prepare/ui_start_button.png",
	"start_button_ready": "res://assets/images/battle_prepare/ui_start_button_ready.png",
	"start_button_disabled": "res://assets/images/battle_prepare/ui_start_button_disabled.png",
	"alert_panel": "res://assets/images/battle_prepare/ui_alert_panel.png",
	"reward_slot": "res://assets/images/battle_prepare/ui_reward_slot.png",
	"chip": "res://assets/images/battle_prepare/ui_chip.png",
	"sword": "res://assets/images/battle_prepare/icon_sword_cross.png",
	"gold": "res://assets/images/stage/icon_gold_coin.png",
	"exp": "res://assets/images/stage/icon_exp_badge.png",
	"capture_ball": "res://assets/images/stage/icon_capture_ball.png",
}

const ELEMENT_ICON_ASSETS := {
	"fire": "res://assets/images/stage/icon_gem_fire.png",
	"water": "res://assets/images/stage/icon_gem_water.png",
	"grass": "res://assets/images/stage/icon_gem_grass.png",
	"thunder": "res://assets/images/stage/icon_gem_thunder.png",
	"light": "res://assets/images/stage/icon_gem_light.png",
}

const MONSTER_ASSETS := {
	"monster_001": "res://assets/images/battle/monsters/monster_001_fire_lizard.png",
	"monster_002": "res://assets/images/battle/monsters/monster_002_water_cub.png",
	"monster_003": "res://assets/images/battle/monsters/monster_003_grass_leaf.png",
	"enemy_001": "res://assets/images/battle/monsters/monster_001_fire_lizard.png",
	"enemy_002": "res://assets/images/battle/monsters/monster_002_water_cub.png",
	"enemy_003": "res://assets/images/battle/monsters/monster_003_grass_leaf.png",
	"monster_boss_001": "res://assets/images/battle/monsters/monster_boss_001_grass_flower_512.png",
}

## 单例
static var instance: SceneBattlePrepare

## 关卡数据
var _stage_data: Dictionary = {}
var _stage_id: String = ""

## 玩家队伍
var _player_team: Array[Dictionary] = []

## 敌方队伍
var _enemy_team: Array[Dictionary] = []

## 空队伍提示
var _show_empty_team_alert: bool = false
var _alert_show_time: float = 0.0

## 渲染区域缓存
var _back_btn_rendered: Rect2 = Rect2(0, 0, 0, 0)
var _start_btn_rendered: Rect2 = Rect2(0, 0, 0, 0)
var _texture_cache: Dictionary = {}

## 主题颜色
const C := {
	"bg_medium": Color(0.04, 0.07, 0.15),
	"bg_card": Color(0.1, 0.15, 0.25),
	"primary": Color(0.1, 0.5, 1.0),
	"success": Color(0.2, 0.8, 0.3),
	"gold": Color(1.0, 0.8, 0.0),
	"danger": Color(1.0, 0.15, 0.15),
	"warning": Color(1.0, 0.8, 0.2),
	"fire": Color(1.0, 0.3, 0.1),
	"water": Color(0.1, 0.4, 1.0),
	"grass": Color(0.1, 0.8, 0.2),
	"thunder": Color(0.9, 0.8, 0.1),
	"light": Color(1.0, 0.9, 0.2),
	"white": Color(1.0, 1.0, 1.0),
	"text_primary": Color(1.0, 1.0, 1.0),
	"text_secondary": Color(0.7, 0.75, 0.85),
	"text_muted": Color(0.5, 0.55, 0.65)
}

## Font sizes
const FONT_SIZES := {
	"title": 22.0,
	"subtitle": 16.0,
	"body": 14.0,
	"small": 12.0,
	"tiny": 10.0,
	"icon": 28.0,
	"number": 16.0
}

## 元素名称映射
const ELEMENT_NAMES := {
	"fire": "火",
	"water": "水",
	"grass": "草",
	"thunder": "雷",
	"light": "光"
}

## 元素颜色映射
const ELEMENT_COLORS := {
	"fire": C["fire"],
	"water": C["water"],
	"grass": C["grass"],
	"thunder": C["thunder"],
	"light": C["light"]
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

func _ready() -> void:
	instance = self

func init(data: Dictionary = {}) -> void:
	print("[SceneBattlePrepare] 战斗准备初始化")
	
	# 接收关卡数据
	_stage_id = data.get("stageId", "stage_1_1")
	
	# 优先使用传入的 stageData；否则从关卡数据查找
	if data.get("stageData") and data.get("stageData", {}).get("enemies"):
		_stage_data = data["stageData"]
	else:
		_stage_data = _lookup_stage_data(_stage_id)
		if _stage_data.is_empty():
			_stage_data = _get_default_stage_data()
	
	# 加载玩家队伍
	_load_player_team()
	
	# 加载敌方数据
	_load_enemy_team()

## ============================================
# 数据加载
## ============================================

func _get_default_stage_data() -> Dictionary:
	return {
		"id": "stage_1_1",
		"name": "新手训练",
		"enemies": ["enemy_001", "enemy_002", "enemy_003"],
		"enemyLevel": 3
	}

func _lookup_stage_data(stage_id: String) -> Dictionary:
	var db := StageDBScript.new()
	return db.get_stage(stage_id)

func _load_player_team() -> void:
	_player_team = []
	var storage := get_node_or_null("/root/SaveManager")
	var team_data: Dictionary = storage.load_team() if storage else {
		"leader": "monster_001",
		"member1": "monster_002",
		"member2": "monster_003"
	}
	var player: Dictionary = storage.load_player() if storage else {"level": 5}
	var level: int = maxi(player.get("level", 1), 5)
	for slot: String in ["leader", "member1", "member2"]:
		var monster_id: String = team_data.get(slot, "")
		if monster_id == "":
			continue
		var monster: Dictionary = MonsterDBScript.get_monster_stats(monster_id, level)
		if not monster.is_empty():
			monster["power"] = monster.get("hp", 0) + monster.get("atk", 0) + monster.get("def", 0) + monster.get("spd", 0)
			_player_team.append(monster)

func _load_enemy_team() -> void:
	_enemy_team = []
	var enemy_ids: Array = _stage_data.get("enemies", ["enemy_001", "enemy_002", "enemy_003"])
	var enemy_level: int = _stage_data.get("enemyLevel", 3)
	for enemy_id: String in enemy_ids:
		var enemy: Dictionary = MonsterDBScript.get_monster_stats(enemy_id, enemy_level)
		if not enemy.is_empty():
			enemy["power"] = enemy.get("hp", 0) + enemy.get("atk", 0) + enemy.get("def", 0) + enemy.get("spd", 0)
			_enemy_team.append(enemy)

func _get_team_total_power(team: Array) -> int:
	var total := 0
	for monster in team:
		total += monster.get("power", 0)
	return total

func _is_player_team_empty() -> bool:
	return _player_team.is_empty()

## ============================================
# 属性分析
## ============================================

func _get_element_hint() -> String:
	if _enemy_team.is_empty():
		return ""
	
	# TODO: 实现属性克制分析
	return "属性无明显克制关系"

func _calc_synergy_preview() -> Array:
	# 计算队伍属性协同信息
	var element_counts: Dictionary = {}
	for monster in _player_team:
		if monster.is_empty():
			continue
		var elem: String = monster.get("element", "")
		element_counts[elem] = element_counts.get(elem, 0) + 1
	
	var result: Array = []
	for elem in element_counts:
		var count: int = element_counts[elem]
		if count < 2:
			continue
		
		var pct_label: String
		if count == 2:
			pct_label = "+15%ATK/+10%DEF/+10%HP"
		else:
			pct_label = "+30%ATK/+20%DEF/+20%HP"
		
		var elem_name: String = ELEMENT_NAMES.get(elem, elem)
		var elem_color: Color = ELEMENT_COLORS.get(elem, C["text_muted"])
		
		result.append({
			"element": elem,
			"count": count,
			"label": "×%d %s属性共鸣 %s" % [count, elem_name, pct_label],
			"color": elem_color
		})
	
	return result

## ============================================
# 输入处理
## ============================================

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_tap(event.position.x, event.position.y)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_on_tap(event.position.x, event.position.y)

func _on_tap(x: float, y: float) -> void:
	# 返回按钮
	if _back_btn_rendered.has_point(Vector2(x, y)):
		_back_button_pressed()
		return
	
	# 开始战斗按钮
	if _start_btn_rendered.has_point(Vector2(x, y)):
		_start_battle()
		return

func _back_button_pressed() -> void:
	var sm := get_node_or_null("/root/SceneManager")
	if sm:
		sm.switch_scene("stage_select")

func _start_battle() -> void:
	if _is_player_team_empty():
		print("[SceneBattlePrepare] 队伍为空，跳转队伍编成")
		_show_empty_team_alert = true
		_alert_show_time = Time.get_ticks_msec() / 1000.0
		
		# 1.5秒后自动跳转到队伍编成页面
		await get_tree().create_timer(1.5).timeout
		var sm := get_node_or_null("/root/SceneManager")
		if sm:
			sm.switch_scene("team")
		return
	
	print("[SceneBattlePrepare] 开始战斗: %s" % _stage_id)
	emit_signal("battle_started", _stage_id, _stage_data)

## ============================================
# 辅助方法
## ============================================

func _get_element_emoji(element: String) -> String:
	var emojis := {
		"fire": "🔥",
		"water": "💧",
		"grass": "🌿",
		"thunder": "⚡",
		"light": "✨"
	}
	return emojis.get(element, "💎")

func _get_element_color(element: String) -> Color:
	return ELEMENT_COLORS.get(element, C["text_muted"])

func _get_element_name(element: String) -> String:
	return ELEMENT_NAMES.get(element, element)

func _point_in_rect(x: float, y: float, rect: Rect2) -> bool:
	return rect.has_point(Vector2(x, y))

## ============================================
# 更新逻辑
## ============================================

func _process(delta: float) -> void:
	if _show_empty_team_alert:
		var elapsed := (Time.get_ticks_msec() / 1000.0) - _alert_show_time
		if elapsed > 2.0:
			_show_empty_team_alert = false
	queue_redraw()

## ============================================
# 渲染
## ============================================

func _draw() -> void:
	# 背景
	var bg := _tex("bg")
	if bg != null:
		_draw_texture_cover(bg, Rect2(0, 0, DESIGN_W, DESIGN_H))
		draw_rect(Rect2(0, 0, DESIGN_W, DESIGN_H), Color(0.02, 0.05, 0.12, 0.28))
	else:
		draw_rect(Rect2(0, 0, DESIGN_W, DESIGN_H), C["bg_medium"])
	
	# 返回按钮
	_back_btn_rendered = _draw_back_button()
	
	# 标题区
	_draw_header()
	
	# 敌方信息
	_render_enemy_team()
	
	# 战力对比
	_render_power_comparison()
	
	# 我方队伍
	_render_player_team()
	
	# 属性克制提示
	_render_element_hint()
	
	# 属性协同提示
	_render_synergy_preview()
	
	# 奖励预览
	_render_reward_preview()
	
	# 开始战斗按钮
	_start_btn_rendered = _render_start_button()
	
	# 空队伍提示弹窗
	if _show_empty_team_alert:
		_render_empty_team_alert()

## ============================================
# 渲染方法
## ============================================

func _draw_back_button() -> Rect2:
	var rect := Rect2(10.0, 14.0, 52.0, 52.0)
	var pressed := false  # TODO: 检测按下状态
	
	var scale := 0.95 if pressed else 1.0
	var draw_w := rect.size.x * scale
	var draw_h := rect.size.y * scale
	var draw_x := rect.position.x + (rect.size.x - draw_w) / 2.0
	var draw_y := rect.position.y + (rect.size.y - draw_h) / 2.0
	
	_draw_texture_fit(_tex("back_button"), Rect2(draw_x, draw_y, draw_w, draw_h))
	_draw_texture_fit(_tex("back_arrow"), Rect2(draw_x + 9.0, draw_y + 9.0, 34.0, 34.0))
	
	return Rect2(draw_x, draw_y, draw_w, draw_h)

func _draw_header() -> void:
	_draw_texture_fit(_tex("header"), Rect2(70.0, 13.0, 295.0, 64.0))
	_draw_texture_fit(_tex("sword"), Rect2(84.0, 23.0, 34.0, 34.0))
	_draw_text_with_shadow("战斗准备", 190.0, 39.0, C["white"], FONT_SIZES["subtitle"], true)
	_draw_text_with_shadow(_stage_data.get("name", _stage_id), 232.0, 63.0, C["gold"], FONT_SIZES["small"])

func _render_player_team() -> void:
	var y := TEAM_Y
	
	_draw_text_with_shadow("我方队伍", DESIGN_W / 2.0, y + 10.0, C["success"], FONT_SIZES["small"], true)
	
	var card_w := 100.0
	var card_h := 124.0
	var gap := 10.0
	var total_w := _player_team.size() * card_w + (_player_team.size() - 1) * gap
	var start_x := (DESIGN_W - total_w) / 2.0
	var card_y := y + 25.0
	
	# 空队伍提示
	if _player_team.is_empty():
		_draw_text_with_shadow("（队伍为空，请在队伍编成中配置）", DESIGN_W / 2.0, card_y + card_h / 2.0, C["text_muted"], FONT_SIZES["small"])
		return
	
	for i in range(_player_team.size()):
		var monster: Dictionary = _player_team[i]
		var x := start_x + i * (card_w + gap)
		
		_draw_texture_fit(_tex("team_card"), Rect2(x, card_y, card_w, card_h))
		
		var elem_color := _get_element_color(monster.get("element", ""))
		_draw_card_border(x, card_y, card_w, card_h, 2.0, elem_color)
		
		_draw_monster_portrait(monster, Rect2(x + 23.0, card_y + 9.0, 54.0, 54.0))
		_draw_text_with_shadow(monster.get("name", "怪物"), x + card_w / 2.0, card_y + 72.0, C["white"], FONT_SIZES["small"], true)
		
		# 属性标签
		_draw_element_badge(monster.get("element", ""), x + 10.0, card_y + 81.0)
		
		_draw_text_with_shadow("%d" % monster.get("power", 0), x + card_w / 2.0, card_y + 106.0, C["gold"], FONT_SIZES["small"], true)
		
		var rarity: int = monster.get("rarity", 1)
		var stars: String = "★".repeat(rarity)
		_draw_text_with_shadow(stars, x + card_w / 2.0, card_y + 119.0, C["gold"], 8.0)

func _render_power_comparison() -> void:
	var y := 225.0
	var player_power := _get_team_total_power(_player_team)
	var enemy_power := _get_team_total_power(_enemy_team)
	var is_player_stronger := player_power > enemy_power
	var is_team_empty := _is_player_team_empty()
	
	_draw_texture_fit(_tex("power_panel"), Rect2(MARGIN, y, DESIGN_W - MARGIN * 2.0, 62.0))
	
	_draw_texture_fit(_tex("sword"), Rect2(DESIGN_W / 2.0 - 16.0, y + 3.0, 32.0, 32.0))
	_draw_text_with_shadow("战力对比", DESIGN_W / 2.0, y + 21.0, C["white"], FONT_SIZES["small"], true)
	
	# 我方战力
	var player_color: Color = C["text_muted"] if is_team_empty else (C["success"] if is_player_stronger else C["danger"])
	_draw_text_with_shadow("我方 %d" % player_power, DESIGN_W / 2.0 - 82.0, y + 43.0, player_color, FONT_SIZES["number"], true)
	
	# VS
	_draw_text_with_shadow("VS", DESIGN_W / 2.0, y + 43.0, C["white"], FONT_SIZES["small"], true)
	
	# 敌方战力
	_draw_text_with_shadow("敌方 %d" % enemy_power, DESIGN_W / 2.0 + 82.0, y + 43.0, C["danger"], FONT_SIZES["number"], true)
	
	# 差距提示
	if not is_team_empty:
		var diff := player_power - enemy_power
		var diff_text: String
		var diff_color: Color
		
		if diff > 0:
			diff_text = "领先 %d" % diff
			diff_color = C["success"]
		elif diff < 0:
			diff_text = "落后 %d" % (-diff)
			diff_color = C["danger"]
		else:
			diff_text = "势均力敌"
			diff_color = C["gold"]
		
		_draw_text_with_shadow(diff_text, DESIGN_W / 2.0, y + 58.0, diff_color, FONT_SIZES["tiny"])

func _render_enemy_team() -> void:
	var y := ENEMY_Y
	
	_draw_text_with_shadow("敌方信息", DESIGN_W / 2.0, y + 10.0, C["danger"], FONT_SIZES["small"], true)
	
	var card_w := 95.0
	var card_h := 110.0
	var gap := 8.0
	var total_w := _enemy_team.size() * card_w + (_enemy_team.size() - 1) * gap
	var start_x := (DESIGN_W - total_w) / 2.0
	var card_y := y + 25.0
	
	for i in range(_enemy_team.size()):
		var enemy: Dictionary = _enemy_team[i]
		var x := start_x + i * (card_w + gap)
		
		var rarity: int = enemy.get("rarity", 1)
		var is_boss: bool = rarity >= 3
		
		_draw_texture_fit(_tex("enemy_card"), Rect2(x, card_y, card_w, card_h))
		
		var border_color: Color = C["danger"] if is_boss else _get_element_color(enemy.get("element", ""))
		_draw_card_border(x, card_y, card_w, card_h, 3.0 if is_boss else 2.0, border_color)
		
		_draw_monster_portrait(enemy, Rect2(x + 22.0, card_y + 8.0, 51.0, 51.0))
		
		var name_color: Color = C["danger"] if is_boss else C["white"]
		_draw_text_with_shadow(enemy.get("name", "敌人"), x + card_w / 2.0, card_y + 66.0, name_color, FONT_SIZES["small"], true)
		
		_draw_text_with_shadow("Lv.%d" % enemy.get("level", 1), x + card_w / 2.0, card_y + 80.0, C["text_muted"], 9.0)
		
		# 属性标签
		_draw_element_badge(enemy.get("element", ""), x + 8.0, card_y + 86.0, 18.0)
		
		_draw_text_with_shadow("%d" % enemy.get("power", 0), x + card_w / 2.0, card_y + 103.0, C["gold"], FONT_SIZES["tiny"], true)

func _render_element_hint() -> void:
	var y := HINT_Y
	
	_draw_texture_fit(_tex("info_panel"), Rect2(MARGIN, y, DESIGN_W - MARGIN * 2.0, 52.0))
	
	_draw_text_with_shadow("属性分析", DESIGN_W / 2.0, y + 18.0, C["white"], FONT_SIZES["small"], true)
	
	var hint: String = _get_element_hint()
	var lines: Array = hint.split("\n")
	
	var line_y: float = y + 38.0
	for line in lines:
		var color: Color = C["warning"] if "警告" in line else C["text_muted"]
		_draw_text_with_shadow(line, DESIGN_W / 2.0, line_y, color, FONT_SIZES["small"])
		line_y += 18.0

func _render_synergy_preview() -> void:
	var synergies: Array = _calc_synergy_preview()
	var y := SYNERGY_Y
	
	var card_h: float = 30.0 if synergies.is_empty() else 35.0 + synergies.size() * 20.0
	_draw_texture_fit(_tex("synergy_panel"), Rect2(MARGIN, y, DESIGN_W - MARGIN * 2.0, maxf(card_h, 42.0)))
	
	if synergies.is_empty():
		_draw_text_with_shadow("属性协同：无（队伍属性分散）", DESIGN_W / 2.0, y + 22.0, C["text_muted"], FONT_SIZES["small"])
		return
	
	_draw_text_with_shadow("属性协同", DESIGN_W / 2.0, y + 16.0, C["white"], FONT_SIZES["small"], true)
	
	for i in range(synergies.size()):
		var syn: Dictionary = synergies[i]
		_draw_text_with_shadow(syn["label"], DESIGN_W / 2.0, y + 34.0 + i * 20.0, syn["color"], FONT_SIZES["small"])

func _render_reward_preview() -> void:
	var rewards := [
		{"icon": "gold", "text": "金币"},
		{"icon": "exp", "text": "EXP"},
		{"icon": "capture_ball", "text": "捕获"},
	]
	var slot_w := 38.0
	var gap := 14.0
	var total_w := rewards.size() * slot_w + (rewards.size() - 1) * gap
	var start_x := (DESIGN_W - total_w) / 2.0
	_draw_text_with_shadow("通关奖励", DESIGN_W / 2.0 - 104.0, REWARD_Y + 24.0, C["text_muted"], FONT_SIZES["tiny"])
	for i in range(rewards.size()):
		var x := start_x + i * (slot_w + gap)
		_draw_texture_fit(_tex("reward_slot"), Rect2(x, REWARD_Y, slot_w, slot_w))
		_draw_texture_fit(_tex(rewards[i]["icon"]), Rect2(x + 7.0, REWARD_Y + 6.0, 24.0, 24.0))

func _render_start_button() -> Rect2:
	var btn_w := 200.0
	var btn_h := 50.0
	var btn_x := (DESIGN_W - btn_w) / 2.0
	var btn_y := BTN_Y
	
	var rect := Rect2(btn_x, btn_y, btn_w, btn_h)
	
	var is_team_empty := _is_player_team_empty()
	var player_power := _get_team_total_power(_player_team)
	var enemy_power := _get_team_total_power(_enemy_team)
	var is_power_enough := player_power > enemy_power and not is_team_empty
	
	# 战力达标发光效果
	if is_power_enough:
		_draw_rounded_rect(btn_x - 3.0, btn_y - 3.0, btn_w + 6.0, btn_h + 6.0, 14.0, Color(C["success"].r, C["success"].g, C["success"].b, 0.25))
		_draw_rounded_rect(btn_x - 1.0, btn_y - 1.0, btn_w + 2.0, btn_h + 2.0, 13.0, Color(C["success"].r, C["success"].g, C["success"].b, 0.13))
	
	var text: String
	
	if is_team_empty:
		text = "请先编成队伍"
	else:
		text = "开始战斗"
	
	var key := "start_button_disabled" if is_team_empty else ("start_button_ready" if is_power_enough else "start_button")
	_draw_texture_fit(_tex(key), Rect2(btn_x, btn_y, btn_w, btn_h))
	_draw_texture_fit(_tex("sword"), Rect2(btn_x + 44.0, btn_y + 11.0, 30.0, 30.0), 0.65 if is_team_empty else 1.0)
	_draw_text_with_shadow(text, btn_x + btn_w / 2.0, btn_y + btn_h / 2.0, C["white"], FONT_SIZES["subtitle"], true)
	
	return rect

func _render_empty_team_alert() -> void:
	var elapsed := (Time.get_ticks_msec() / 1000.0) - _alert_show_time
	if elapsed > 2.0:
		return
	
	var alert_w := 260.0
	var alert_h := 80.0
	var alert_x := (DESIGN_W - alert_w) / 2.0
	var alert_y := DESIGN_H / 2.0 - alert_h / 2.0
	
	draw_rect(Rect2(0, 0, DESIGN_W, DESIGN_H), Color(0, 0, 0, 0.45))
	_draw_texture_fit(_tex("alert_panel"), Rect2(alert_x, alert_y, alert_w, alert_h))
	
	_draw_text_with_shadow("提示", DESIGN_W / 2.0, alert_y + 25.0, C["danger"], FONT_SIZES["subtitle"], true)
	_draw_text_with_shadow("请先在\"队伍编成\"中", DESIGN_W / 2.0, alert_y + 45.0, C["white"], FONT_SIZES["body"])
	_draw_text_with_shadow("配置你的队伍！", DESIGN_W / 2.0, alert_y + 60.0, C["white"], FONT_SIZES["body"])
	_draw_text_with_shadow("（即将跳转...）", DESIGN_W / 2.0, alert_y + 75.0, C["text_muted"], FONT_SIZES["tiny"])

## ============================================
# 辅助绘制方法
## ============================================

func _draw_rounded_rect(x: float, y: float, w: float, h: float, r: float, color: Color) -> void:
	if w > r * 2.0:
		draw_rect(Rect2(x + r, y, w - r * 2.0, h), color)
	if h > r * 2.0:
		draw_rect(Rect2(x, y + r, w, h - r * 2.0), color)
	draw_rect(Rect2(x, y, r, r), color)
	draw_rect(Rect2(x + w - r, y, r, r), color)
	draw_rect(Rect2(x, y + h - r, r, r), color)
	draw_rect(Rect2(x + w - r, y + h - r, r, r), color)

func _draw_card_border(x: float, y: float, w: float, h: float, line_width: float, color: Color) -> void:
	draw_rect(Rect2(x, y, w, line_width), color)
	draw_rect(Rect2(x, y + h - line_width, w, line_width), color)
	draw_rect(Rect2(x, y, line_width, h), color)
	draw_rect(Rect2(x + w - line_width, y, line_width, h), color)

func _draw_circle(cx: float, cy: float, r: float, color: Color) -> void:
	for dy in range(-int(r), int(r) + 1):
		for dx in range(-int(r), int(r) + 1):
			if dx * dx + dy * dy <= r * r:
				draw_rect(Rect2(cx + dx, cy + dy, 1, 1), color)

func _draw_line(x1: float, y1: float, x2: float, y2: float, color: Color) -> void:
	draw_rect(Rect2(x1, y1, x2 - x1, 1.0), color)

func _draw_text_with_shadow(text: String, x: float, y: float, color: Color, size: float, bold: bool = false) -> void:
	var shadow_color := Color(0.0, 0.0, 0.0, 0.55)
	var text_w := 200.0
	draw_string(ThemeDB.fallback_font, Vector2(x - text_w / 2.0 + 1, y + 2), text, HORIZONTAL_ALIGNMENT_CENTER, text_w, size, shadow_color)
	draw_string(ThemeDB.fallback_font, Vector2(x - text_w / 2.0, y), text, HORIZONTAL_ALIGNMENT_CENTER, text_w, size, color)

func _tex(key: String) -> Texture2D:
	var path: String = PREPARE_ASSETS.get(key, "")
	if path.is_empty():
		return null
	return _get_texture(path)

func _get_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	if not _texture_cache.has(path):
		_texture_cache[path] = load(path)
	return _texture_cache[path] as Texture2D

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

func _draw_monster_portrait(monster: Dictionary, rect: Rect2) -> void:
	var monster_id: String = monster.get("id", "")
	var path: String = MONSTER_ASSETS.get(monster_id, "")
	var tex := _get_texture(path)
	if tex != null:
		_draw_texture_fit(tex, rect)
	else:
		_draw_text_with_shadow(monster.get("emoji", "?"), rect.position.x + rect.size.x / 2.0, rect.position.y + rect.size.y / 2.0, C["white"], 28.0)

func _draw_element_badge(element: String, x: float, y: float, size: float = 20.0) -> void:
	var path: String = ELEMENT_ICON_ASSETS.get(element, "")
	var tex := _get_texture(path)
	if tex != null:
		_draw_texture_fit(tex, Rect2(x, y, size, size))
	else:
		var elem_color := _get_element_color(element)
		_draw_rounded_rect(x, y, size, size, 4.0, elem_color)
		_draw_text_with_shadow(_get_element_name(element), x + size / 2.0, y + size * 0.68, C["white"], 8.0)

## ============================================
# 清理
## ============================================

func destroy() -> void:
	_show_empty_team_alert = false
