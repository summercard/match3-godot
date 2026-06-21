@tool
# scene_sign_in.gd - 每日签到场景
class_name SceneSignIn
extends Control

signal back_pressed()
signal sign_in_complete(reward: Dictionary)

const _RoundFontSrc := preload("res://assets/fonts/ZCOOLKuaiLe-Regular.ttf")

const DESIGN_WIDTH := 375.0
const DESIGN_HEIGHT := 667.0
const PARTICLE_COUNT := 34

const BACK_RECT := Rect2(10.0, 10.0, 58.0, 58.0)
const HEADER_RECT := Rect2(92.0, 16.0, 220.0, 52.0)
const HERO_RECT := Rect2(18.0, 82.0, 339.0, 100.0)
const MONTH_RECT := Rect2(17.0, 462.0, 341.0, 126.0)
const CLAIM_RECT := Rect2(78.0, 598.0, 220.0, 52.0)

const SIGN_ASSETS := {
	"bg": "res://assets/images/ui/backgrounds/main_lobby_bg_day_v3.png",
	"dark_overlay": "res://assets/images/ui/backgrounds/black.png",
	"back": "res://assets/images/ui/buttons/ranch_ui_btn_previous_round.png",
	"header": "res://assets/images/ui/panels/shop_ui_shop_title_plaque_image2.png",
	"day_card": "res://assets/images/ui/slots/inventory_new_ui_inventory_slot.png",
	"day_card_alt": "res://assets/images/ui/slots/inventory_new_ui_inventory_slot.png",
	"day_card_today": "res://assets/images/ui/slots/inventory_new_ui_inventory_slot_selected.png",
	"day_card_locked": "res://assets/images/ui/slots/inventory_new_ui_inventory_slot_empty.png",
	"month_panel": "res://assets/images/ui/panels/inventory_new_ui_inventory_panel.png",
	"month_ribbon": "res://assets/images/ui/buttons/inventory_new_ui_inventory_tab_active.png",
	"claim_button": "res://assets/images/ui/buttons/inventory_new_ui_inventory_use_button.png",
	"claim_disabled": "res://assets/images/ui/buttons/inventory_new_ui_inventory_tab_normal.png",
	"stamp": "res://assets/images/ui/icons/album_ui_dex_bottom_nav_selected.png",
	"today_tag": "res://assets/images/ui/buttons/inventory_new_ui_inventory_tab_active.png",
	"progress": "res://assets/images/ui/buttons/inventory_new_ui_inventory_use_button.png",
	"warning": "res://assets/images/ui/icons/main_icon_plus_v3.png",
	"calendar": "res://assets/images/ui/icons/common_nav_icon_nav_signin.png",
	"mascot": "res://assets/images/monsters/monster/monster_grass_leaf.png",
	"check": "res://assets/images/ui/icons/battle_flow_new_icon_star_gold.png",
	"fx": "res://assets/images/effects/album_fx_sparkle_cluster.png",
	"gold": "res://assets/images/ui/icons/main_icon_gold_coin_v3.png",
	"exp": "res://assets/images/ui/icons/items_new_icon_exp_potion.png",
	"water": "res://assets/images/ui/gems/items_new_icon_evolution_stone_water.png",
	"fire": "res://assets/images/ui/gems/items_new_icon_evolution_stone_fire.png",
	"potion": "res://assets/images/ui/icons/items_new_icon_hp_potion.png",
	"chest_large": "res://assets/images/ui/icons/items_new_icon_gold_chest.png",
	"chest_7": "res://assets/images/ui/icons/items_new_icon_gold_chest.png",
	"chest_14": "res://assets/images/ui/icons/items_new_icon_gold_chest.png",
	"chest_21": "res://assets/images/ui/icons/items_new_icon_gold_chest.png",
	"chest_28": "res://assets/images/ui/icons/items_new_icon_gold_chest.png",
	"diamond": "res://assets/images/ui/gems/main_icon_diamond_gem_v3.png",
}
const REWARD_SCHEDULE := [
	{"day": 1, "icon": "gold", "amount": "x500"},
	{"day": 2, "icon": "exp", "amount": "x200"},
	{"day": 3, "icon": "water", "amount": "x50"},
	{"day": 4, "icon": "fire", "amount": "x2"},
	{"day": 5, "icon": "potion", "amount": "x1"},
	{"day": 6, "icon": "water", "amount": "x100"},
	{"day": 7, "icon": "chest_large", "amount": "x1"},
]

const MILESTONES := [
	{"day": 7, "icon": "chest_7"},
	{"day": 14, "icon": "chest_14"},
	{"day": 21, "icon": "chest_21"},
	{"day": 28, "icon": "chest_28"},
]

const C := {
	"white": Color(1.0, 1.0, 1.0),
	"muted": Color(0.67, 0.74, 0.84),
	"dim": Color(0.44, 0.50, 0.60),
	"gold": Color(1.0, 0.80, 0.22),
	"green": Color(0.62, 1.0, 0.36),
	"blue": Color(0.42, 0.78, 1.0),
	"red": Color(1.0, 0.35, 0.25),
	"shadow": Color(0.0, 0.0, 0.0, 0.58),
}

var _storage: Node = null
var _sign_in_data: Dictionary = {}
var _can_sign_in := false
var _has_signed_in := false
var _animation_complete := false
var _particles: Array = []
var _floating_rewards: Array = []
var _texture_cache: Dictionary = {}
var _style_box_cache: Dictionary = {}
var _round_font_normal: Font = null
var _round_font_bold: Font = null

# === 签到入场动画状态（_draw 风格）===
const ENTRY_DURATION := 0.42  # 全局淡入时长
const ENTRY_TOTAL_DURATION := 1.30  # 入场总时长（含元素依次入场）
const ENTRY_TOP_OFFSET_START := 26.0
const ENTRY_BOTTOM_OFFSET_START := 26.0
var _entry_t := 0.0

# === 元素级入场（参考胜利界面奖励槽节奏）===
# hero 面板（连续签到 + 今日奖励）：顶部滑下
const HERO_ENTRY_START := 0.10
const HERO_ENTRY_DURATION := 0.32
const HERO_ENTRY_OFFSET_Y := -18.0
# 7 张周奖励卡片：依次 scale bounce + 上滑
const WEEK_CARD_START := 0.22
const WEEK_CARD_STAGGER := 0.05
const WEEK_CARD_DURATION := 0.32
const WEEK_CARD_SCALE_START := 0.55
const WEEK_CARD_OFFSET_Y := 16.0
# 月度累计面板：从下方滑入
const MONTH_PANEL_START := 0.50
const MONTH_PANEL_DURATION := 0.32
const MONTH_PANEL_OFFSET_Y := 22.0
# 4 个里程碑宝箱：依次 scale bounce
const MILESTONE_START := 0.62
const MILESTONE_STAGGER := 0.07
const MILESTONE_DURATION := 0.30
const MILESTONE_SCALE_START := 0.5


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_storage = get_node_or_null("/root/SaveManager")
	self.modulate.a = 0.0  # 入场动画起点：透明


func init(_data: Dictionary = {}) -> void:
	_storage = get_node_or_null("/root/SaveManager")
	_sign_in_data = _storage.load_sign_in_data() if _storage else {}
	_can_sign_in = _storage.can_sign_in_today() if _storage else false
	_has_signed_in = not _can_sign_in
	_animation_complete = false
	_particles.clear()
	_floating_rewards.clear()
	queue_redraw()


func do_sign_in() -> void:
	if not _can_sign_in or not _storage:
		return
	var reward: Dictionary = _storage.do_sign_in()
	if reward.is_empty():
		return
	_can_sign_in = false
	_has_signed_in = true
	_sign_in_data = _storage.load_sign_in_data()
	if _storage.has_method("set_achievement_stat"):
		_storage.set_achievement_stat("maxConsecutiveSignIn", int(_sign_in_data.get("consecutiveDays", 1)))
		_storage.set_achievement_stat("totalSignInDays", int(_sign_in_data.get("totalDays", 1)))
	_play_sign_in_effect(reward)
	sign_in_complete.emit(reward)
	queue_redraw()


func _play_sign_in_effect(reward: Dictionary) -> void:
	var center := CLAIM_RECT.get_center()
	for i in PARTICLE_COUNT:
		var angle := randf() * TAU
		var speed := 1.8 + randf() * 4.0
		_particles.append({
			"x": center.x + (randf() - 0.5) * 110.0,
			"y": center.y + (randf() - 0.5) * 30.0,
			"vx": cos(angle) * speed,
			"vy": sin(angle) * speed - 2.2,
			"life": 1.0,
			"size": 3.0 + randf() * 5.0,
			"color": [C["gold"], C["green"], C["blue"], Color(1.0, 0.36, 0.66)][randi() % 4],
		})
	_floating_rewards.append({"text": "+%d 金币" % int(reward.get("gold", 0)), "x": 125.0, "y": 586.0, "vy": -1.35, "life": 1.5, "color": C["gold"]})
	_floating_rewards.append({"text": "+%d EXP" % int(reward.get("exp", 0)), "x": 210.0, "y": 586.0, "vy": -1.18, "life": 1.5, "color": C["green"]})
	_animation_complete = true

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_on_tap(event.position)
		accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_on_tap(event.position)
		accept_event()


func _on_tap(point: Vector2) -> void:
	if BACK_RECT.has_point(point):
		back_pressed.emit()
		return
	if CLAIM_RECT.has_point(point) and _can_sign_in:
		do_sign_in()


func get_today_reward() -> Dictionary:
	var consecutive := int(_sign_in_data.get("consecutiveDays", 0))
	return _storage.get_sign_in_reward(consecutive) if _storage and _storage.has_method("get_sign_in_reward") else {"gold": 50, "exp": 30}


func _process(dt: float) -> void:
	for i in range(_particles.size() - 1, -1, -1):
		var p: Dictionary = _particles[i]
		p["x"] += p["vx"]
		p["y"] += p["vy"]
		p["vy"] += 0.15 * 60.0 * dt
		p["life"] -= dt * 0.82
		if p["life"] <= 0.0:
			_particles.remove_at(i)
	for i in range(_floating_rewards.size() - 1, -1, -1):
		var r: Dictionary = _floating_rewards[i]
		r["y"] += r["vy"]
		r["life"] -= dt
		if r["life"] <= 0.0:
			_floating_rewards.remove_at(i)
	# 入场动画推进（包含全局淡入和元素依次入场）
	if _entry_t < ENTRY_TOTAL_DURATION:
		_entry_t = minf(_entry_t + dt, ENTRY_TOTAL_DURATION)
		# 全局淡入（0..ENTRY_DURATION 区间）
		var fade_t := _entry_t / ENTRY_DURATION
		if fade_t < 1.0:
			self.modulate.a = ease(fade_t, -1.5)
		else:
			self.modulate.a = 1.0
	queue_redraw()


func _draw() -> void:
	_draw_texture_cover(_tex("bg"), Rect2(0.0, 0.0, DESIGN_WIDTH, DESIGN_HEIGHT))
	_draw_texture_cover(_tex("dark_overlay"), Rect2(0.0, 0.0, DESIGN_WIDTH, DESIGN_HEIGHT), 0.5)
	# 顶部：header 从上方滑入
	var top_off := _entry_top_offset()
	if top_off != 0.0:
		draw_set_transform(Vector2(0.0, top_off))
	_draw_header()
	if top_off != 0.0:
		draw_set_transform(Vector2.ZERO)
	# 中间内容：跟随整体淡入
	_draw_hero()
	_draw_week_rewards()
	_draw_month_rewards()
	# 底部：claim_area 从下方滑入
	var bottom_off := _entry_bottom_offset()
	if bottom_off != 0.0:
		draw_set_transform(Vector2(0.0, bottom_off))
	_draw_claim_area()
	if bottom_off != 0.0:
		draw_set_transform(Vector2.ZERO)
	_draw_effects()


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


# === 元素级入场：通用缓动 + bounce scale ===
# 将 local_t (0..1) 映射为从 total_offset 平滑回到 0 的偏移量
func _ease_offset(local_t: float, total_offset: float) -> float:
	if local_t <= 0.0:
		return total_offset
	if local_t >= 1.0:
		return 0.0
	return total_offset * (1.0 - ease(local_t, -1.5))

# 卡片 bounce 缩放：start_scale → overshoot → 1.0（参考胜利界面奖励槽节奏）
# 注：Godot 4.6 的 ease(s, 0.0) 始终返回 0，因此 phase 2 用 ease(s, -1.0) 做线性插值
func _bounce_scale(local_t: float, start_scale: float, overshoot: float) -> float:
	if local_t <= 0.0:
		return start_scale
	if local_t >= 1.0:
		return 1.0
	if local_t < 0.6:
		var p := local_t / 0.6
		return lerpf(start_scale, overshoot, ease(p, -1.5))
	else:
		var p := (local_t - 0.6) / 0.4
		return lerpf(overshoot, 1.0, ease(p, -1.0))


# === 各元素 entry transform ===
func _hero_entry_offset_y() -> float:
	if _entry_t < HERO_ENTRY_START:
		return HERO_ENTRY_OFFSET_Y
	var local_t := (_entry_t - HERO_ENTRY_START) / HERO_ENTRY_DURATION
	return _ease_offset(local_t, HERO_ENTRY_OFFSET_Y)

func _week_card_xform(index: int) -> Dictionary:
	var start := WEEK_CARD_START + float(index) * WEEK_CARD_STAGGER
	if _entry_t < start:
		return {"offset_y": WEEK_CARD_OFFSET_Y, "scale": WEEK_CARD_SCALE_START}
	var local_t := (_entry_t - start) / WEEK_CARD_DURATION
	if local_t >= 1.0:
		return {"offset_y": 0.0, "scale": 1.0}
	return {
		"offset_y": _ease_offset(local_t, WEEK_CARD_OFFSET_Y),
		"scale": _bounce_scale(local_t, WEEK_CARD_SCALE_START, 1.08),
	}

func _month_panel_offset_y() -> float:
	if _entry_t < MONTH_PANEL_START:
		return MONTH_PANEL_OFFSET_Y
	var local_t := (_entry_t - MONTH_PANEL_START) / MONTH_PANEL_DURATION
	return _ease_offset(local_t, MONTH_PANEL_OFFSET_Y)

func _milestone_xform(index: int) -> Dictionary:
	var start := MILESTONE_START + float(index) * MILESTONE_STAGGER
	if _entry_t < start:
		return {"scale": MILESTONE_SCALE_START}
	var local_t := (_entry_t - start) / MILESTONE_DURATION
	if local_t >= 1.0:
		return {"scale": 1.0}
	return {
		"scale": _bounce_scale(local_t, MILESTONE_SCALE_START, 1.12),
	}

func _draw_header() -> void:
	_draw_texture_fit(_tex("back"), BACK_RECT)
	_draw_texture_fit(_tex("header"), HEADER_RECT)
	_draw_text("每日签到", HEADER_RECT.get_center().x, HEADER_RECT.position.y + 34.0, C["white"], 24.0, true, 170.0)

func _draw_hero() -> void:
	var offset_y := _hero_entry_offset_y()
	if offset_y != 0.0:
		draw_set_transform(Vector2(0.0, offset_y))
		_draw_hero_inner()
		draw_set_transform(Vector2.ZERO)
	else:
		_draw_hero_inner()

func _draw_hero_inner() -> void:
	_draw_nine_patch("month_panel", HERO_RECT)
	_draw_texture_contain(_tex("calendar"), Rect2(28.0, 88.0, 88.0, 82.0))
	_draw_texture_contain(_tex("mascot"), Rect2(255.0, 76.0, 88.0, 100.0))
	var consecutive := int(_sign_in_data.get("consecutiveDays", 0))
	var next_reward := _get_schedule_item(_current_cycle_day())
	_draw_text("连续签到", 174.0, 112.0, Color(0.55, 0.31, 0.12), 18.0, true, 110.0)
	_draw_text(str(consecutive), 158.0, 154.0, C["gold"], 42.0, true, 76.0)
	_draw_text("天", 205.0, 154.0, Color(0.43, 0.24, 0.07), 22.0, true, 28.0)
	_draw_text("今日奖励", 177.0, 174.0, C["muted"], 12.0, false, 82.0)
	_draw_texture_contain(_tex(str(next_reward.get("icon", "gold"))), Rect2(217.0, 142.0, 38.0, 38.0))

func _draw_week_rewards() -> void:
	var current_day := _current_cycle_day()
	var signed_limit := _signed_cycle_limit(current_day)
	for i in range(REWARD_SCHEDULE.size()):
		var item: Dictionary = REWARD_SCHEDULE[i]
		var day := int(item["day"])
		var today := day == current_day
		var signed := day <= signed_limit
		var rect := _day_rect(i)
		var xform := _week_card_xform(i)
		var scale := float(xform.get("scale", 1.0))
		# 通过矩阵缩放（绕卡片中心）让卡片内容（纹理 + 文字）一起缩放
		if scale != 1.0:
			var center := rect.position + rect.size * 0.5
			var x := Transform2D()
			x = x.translated(Vector2(-center.x, -center.y))
			x = x.scaled(Vector2(scale, scale))
			x = x.translated(center)
			draw_set_transform_matrix(x)
		var card_key := "day_card_today" if today else ("day_card" if i % 2 == 0 else "day_card_alt")
		if day > signed_limit + 1 and not today:
			card_key = "day_card_locked"
		_draw_nine_patch(card_key, rect)
		_draw_text("第%d天" % day, rect.get_center().x, rect.position.y + 22.0, Color(1.0, 0.88, 0.62) if today else Color(0.43, 0.24, 0.07), 15.0, true, rect.size.x - 8.0)
		if today:
			_draw_nine_patch("today_tag", Rect2(rect.position.x + 5.0, rect.position.y + 28.0, 42.0, 23.0))
			_draw_text("今日", rect.position.x + 26.0, rect.position.y + 45.0, C["white"], 11.0, true, 34.0)
		_draw_texture_contain(_tex(str(item["icon"])), Rect2(rect.position.x + 16.0, rect.position.y + 42.0, rect.size.x - 32.0, 45.0))
		_draw_text(str(item["amount"]), rect.get_center().x, rect.position.y + rect.size.y - 14.0, Color(0.43, 0.24, 0.07), 15.0, true, rect.size.x - 18.0)
		if signed:
			_draw_texture_contain(_tex("stamp"), Rect2(rect.end.x - 31.0, rect.position.y + 31.0, 25.0, 25.0), 0.92)
		if scale != 1.0:
			draw_set_transform_matrix(Transform2D.IDENTITY)

func _draw_month_rewards() -> void:
	var panel_offset_y := _month_panel_offset_y()
	# 月度面板 + 内容（不包括里程碑宝箱，宝箱有自己的 bounce）：整体从下方滑入
	_draw_nine_patch("month_panel", Rect2(MONTH_RECT.position + Vector2(0, panel_offset_y), MONTH_RECT.size))
	_draw_nine_patch("month_ribbon", Rect2(74.0, 448.0 + panel_offset_y, 228.0, 40.0))
	_draw_text("本月累计签到奖励", 188.0, 474.0 + panel_offset_y, C["white"], 15.0, true, 180.0)
	var total := int(_sign_in_data.get("totalDays", 0))
	var month_count := clampi(total % 29, 0, 28)
	if total > 0 and total % 28 == 0:
		month_count = 28
	_draw_texture_contain(_tex("chest_large"), Rect2(30.0, 487.0 + panel_offset_y, 76.0, 70.0))
	_draw_text("本月已签到 %d/28 天" % month_count, 205.0, 505.0 + panel_offset_y, Color(0.43, 0.24, 0.07), 14.0, true, 160.0)
	var progress_track := Rect2(108.0, 547.0 + panel_offset_y, 230.0, 20.0)
	_draw_nine_patch("claim_disabled", progress_track)
	var progress_width := (progress_track.size.x - 6.0) * float(month_count) / 28.0
	if progress_width > 0.0:
		_draw_nine_patch("progress", Rect2(progress_track.position + Vector2(3.0, 3.0), Vector2(maxf(progress_width, 10.0), progress_track.size.y - 6.0)))
	# 里程碑宝箱：每个有自己的 bounce scale（缩放中心随面板上移）
	for i in range(MILESTONES.size()):
		var m: Dictionary = MILESTONES[i]
		var x := 128.0 + i * 64.0
		var xform := _milestone_xform(i)
		var scale := float(xform.get("scale", 1.0))
		var orig_chest := Rect2(x - 22.0, 518.0, 44.0, 34.0)
		var center := orig_chest.position + orig_chest.size * 0.5 + Vector2(0, panel_offset_y)
		if scale != 1.0:
			var xf := Transform2D()
			xf = xf.translated(Vector2(-center.x, -center.y))
			xf = xf.scaled(Vector2(scale, scale))
			xf = xf.translated(center)
			draw_set_transform_matrix(xf)
		var reached := month_count >= int(m["day"])
		_draw_texture_contain(_tex(str(m["icon"])), orig_chest, 1.0 if reached else 0.55)
		if scale != 1.0:
			draw_set_transform_matrix(Transform2D.IDENTITY)
		_draw_text("%d天" % int(m["day"]), x, 579.0 + panel_offset_y, C["green"] if reached else C["muted"], 11.0, true, 42.0)

func _draw_claim_area() -> void:
	var key := "claim_button" if _can_sign_in else "claim_disabled"
	_draw_nine_patch(key, CLAIM_RECT)
	var label := "领取奖励" if _can_sign_in else "今日已签到"
	_draw_text(label, CLAIM_RECT.get_center().x, CLAIM_RECT.position.y + 35.0, C["white"], 24.0 if _can_sign_in else 19.0, true, 170.0)

func _draw_effects() -> void:
	for p in _particles:
		var alpha := clampf(float(p.get("life", 0.0)), 0.0, 1.0)
		var color: Color = p.get("color", C["gold"])
		color.a = alpha
		var sz := float(p.get("size", 4.0))
		draw_rect(Rect2(float(p.get("x", 0.0)) - sz / 2.0, float(p.get("y", 0.0)) - sz / 2.0, sz, sz), color)
	if _animation_complete and _particles.is_empty():
		_draw_texture_contain(_tex("fx"), Rect2(92.0, 520.0, 190.0, 60.0), 0.85)
		_draw_text("签到成功！奖励已发放", DESIGN_WIDTH / 2.0, 564.0, C["gold"], 15.0, true, 220.0)
	for r in _floating_rewards:
		var alpha := clampf(float(r.get("life", 0.0)) / 1.5, 0.0, 1.0)
		var color: Color = r.get("color", C["white"])
		color.a = alpha
		_draw_text(str(r.get("text", "")), float(r.get("x", 0.0)), float(r.get("y", 0.0)), color, 16.0, true, 82.0)

func _day_rect(index: int) -> Rect2:
	if index < 4:
		return Rect2(18.0 + index * 86.0, 194.0, 78.0, 112.0)
	return Rect2(42.0 + (index - 4) * 102.0, 316.0, 88.0, 124.0)


func _current_cycle_day() -> int:
	var streak := int(_sign_in_data.get("consecutiveDays", 0))
	if _can_sign_in:
		return clampi(streak % 7 + 1, 1, 7)
	return clampi((maxi(streak, 1) - 1) % 7 + 1, 1, 7)


func _signed_cycle_limit(current_day: int) -> int:
	if _can_sign_in:
		return max(0, current_day - 1)
	return current_day


func _get_schedule_item(day: int) -> Dictionary:
	for item in REWARD_SCHEDULE:
		if int(item["day"]) == day:
			return item
	return REWARD_SCHEDULE[0]


func _tex(key: String) -> Texture2D:
	if not _texture_cache.has(key):
		var path: String = SIGN_ASSETS.get(key, "")
		_texture_cache[key] = load(path) if path != "" and ResourceLoader.exists(path) else null
	var tex = _texture_cache.get(key)
	return tex if tex is Texture2D else null


func _draw_texture_fit(tex: Texture2D, rect: Rect2, opacity: float = 1.0) -> void:
	if tex == null:
		return
	draw_texture_rect(tex, rect, false, Color(1.0, 1.0, 1.0, opacity))


func _draw_nine_patch(key: String, rect: Rect2) -> void:
	var tex := _tex(key)
	if tex == null:
		return
	if not _style_box_cache.has(key):
		var style := StyleBoxTexture.new()
		style.texture = tex
		var margins := _nine_patch_margins(key)
		style.set_texture_margin(SIDE_LEFT, margins.x)
		style.set_texture_margin(SIDE_TOP, margins.y)
		style.set_texture_margin(SIDE_RIGHT, margins.z)
		style.set_texture_margin(SIDE_BOTTOM, margins.w)
		_style_box_cache[key] = style
	draw_style_box(_style_box_cache[key], rect)


func _nine_patch_margins(key: String) -> Vector4:
	if key.begins_with("day_card"):
		return Vector4(30.0, 30.0, 30.0, 30.0)
	if key == "month_panel":
		return Vector4(54.0, 54.0, 54.0, 54.0)
	if key == "month_ribbon" or key == "today_tag" or key == "claim_disabled":
		return Vector4(46.0, 28.0, 46.0, 28.0)
	return Vector4(58.0, 30.0, 58.0, 30.0)


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
		draw_rect(rect, Color(0.04, 0.07, 0.15))
		return
	var size := tex.get_size()
	var scale := maxf(rect.size.x / size.x, rect.size.y / size.y)
	var source_size := rect.size / scale
	var source_pos := (size - source_size) * 0.5
	draw_texture_rect_region(tex, rect, Rect2(source_pos, source_size), Color(1.0, 1.0, 1.0, opacity))


func _draw_text(text: String, x: float, y: float, color: Color, size: float, bold: bool = false, width: float = 180.0) -> void:
	var font := _get_round_font(bold)
	var fitted_size := size
	while fitted_size > 9.0 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fitted_size).x > width:
		fitted_size -= 1.0
	draw_string(font, Vector2(x - width / 2.0, y), text, HORIZONTAL_ALIGNMENT_CENTER, width, fitted_size, color)


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
