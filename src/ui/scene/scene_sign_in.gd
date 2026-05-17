# ============================================
# scene_sign_in.gd - 每日签到场景
# 翻译来源: js/ui/sceneSignIn.js
# 重构: _draw() 绘制 + _gui_input 交互
# ============================================

class_name SceneSignIn
extends Control

signal back_pressed()
signal sign_in_complete(reward: Dictionary)

const DESIGN_WIDTH := 375.0
const DESIGN_HEIGHT := 667.0
const PARTICLE_COUNT := 30
const PARTICLE_COLORS := [Color("#FFD700"), Color("#FFA500"), Color("#FF6B6B"), Color("#98D8C8")]

var _game: Node = null
var _storage: Node = null
var _sign_in_data: Dictionary = {}
var _can_sign_in: bool = false
var _has_signed_in: bool = false
var _animation_complete: bool = false
var _particles: Array = []
var _floating_rewards: Array = []
var _bg_texture: ColorRect

func _add_dark_background() -> void:
	_bg_texture = ColorRect.new()
	_bg_texture.color = Color(0.04, 0.07, 0.15, 1.0)
	_bg_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_texture.z_index = -10
	add_child(_bg_texture)

func _ready() -> void:
	_add_dark_background()
	_storage = get_node_or_null("/root/SaveManager")
	mouse_filter = Control.MOUSE_FILTER_STOP

func init(_data: Dictionary = {}) -> void:
	print("[SceneSignIn] 签到场景初始化")
	_storage = get_node_or_null("/root/SaveManager")
	_sign_in_data = _storage.load_sign_in_data() if _storage else {}
	_can_sign_in = _storage.can_sign_in_today() if _storage else false
	_has_signed_in = not _can_sign_in
	_particles.clear()
	_floating_rewards.clear()
	_animation_complete = false

# ============ 签到逻辑 ============
func do_sign_in() -> void:
	if not _can_sign_in or not _storage:
		return
	var reward: Dictionary = _storage.do_sign_in()
	if reward.is_empty():
		return
	_can_sign_in = false
	_has_signed_in = true
	_sign_in_data = _storage.load_sign_in_data()
	if _storage and _storage.has_method("set_achievement_stat"):
		_storage.set_achievement_stat("maxConsecutiveSignIn", int(_sign_in_data.get("consecutiveDays", 1)))
		_storage.set_achievement_stat("totalSignInDays", int(_sign_in_data.get("totalDays", 1)))
	_play_sign_in_effect(reward)

func _play_sign_in_effect(reward: Dictionary) -> void:
	var center_x := DESIGN_WIDTH / 2.0
	var center_y := DESIGN_HEIGHT / 2.0
	for i in PARTICLE_COUNT:
		var angle: float = randf() * TAU
		var speed: float = 2.0 + randf() * 4.0
		_particles.append({
			"x": center_x + (randf() - 0.5) * 100.0,
			"y": center_y + (randf() - 0.5) * 60.0,
			"vx": cos(angle) * speed,
			"vy": sin(angle) * speed - 2.0,
			"life": 1.0,
			"color": PARTICLE_COLORS[randi() % PARTICLE_COLORS.size()],
			"size": 4.0 + randf() * 6.0,
			"rot": randf() * TAU
		})
	_floating_rewards.append({"text": "💰 +%d" % reward.get("gold", 0), "x": center_x - 50.0, "y": center_y, "vy": -1.5, "life": 1.5, "color": Color("#FFD700")})
	_floating_rewards.append({"text": "✨ +%d" % reward.get("exp", 0), "x": center_x + 20.0, "y": center_y, "vy": -1.2, "life": 1.5, "color": Color("#4CAF50")})
	_animation_complete = true

# ============ 输入 ============
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_on_tap(event.position.x, event.position.y)
		accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_on_tap(event.position.x, event.position.y)
		accept_event()

func _on_tap(x: float, y: float) -> void:
	# 签到成功后点击任意区域
	if _animation_complete and _particles.is_empty():
		var back_rect := Rect2(15, 15, 60, 35)
		if back_rect.has_point(Vector2(x, y)):
			back_pressed.emit()
		return
	
	# 返回按钮
	var back_rect := Rect2(15, 15, 60, 35)
	if back_rect.has_point(Vector2(x, y)):
		back_pressed.emit()
		return
	
	# 签到按钮
	if not _can_sign_in:
		return
	var sign_rect := Rect2(87.5, 400, 200, 60)
	if sign_rect.has_point(Vector2(x, y)):
		do_sign_in()

func _get_last_7_days() -> Array:
	var days := []
	var now: Dictionary = Time.get_datetime_dict_from_system()
	# 当天0点的 unix timestamp
	var today_unix: int = Time.get_unix_time_from_datetime_dict(now) - (now["hour"] * 3600 + now["minute"] * 60 + now["second"])
	for i in range(6, -1, -1):
		var unix := today_unix - (i * 86400)
		var d: Dictionary = Time.get_datetime_dict_from_unix_time(unix)
		days.append({
			"date": d["day"],
			"month": d["month"],
			"year": d["year"],
			"is_today": i == 0,
			"signed": _check_day_signed(d)
		})
	return days

func _check_day_signed(date_dict: Dictionary) -> bool:
	if _sign_in_data.is_empty():
		return false
	var last_sign_raw = _sign_in_data.get("lastSignInDate", "")
	# lastSignInDate 可能是 null 或空字符串
	if last_sign_raw == null or str(last_sign_raw).is_empty():
		return false
	var last_sign: String = str(last_sign_raw)
	if last_sign.is_empty():
		return false
	var parts: PackedStringArray = last_sign.split("-")
	if parts.size() < 3:
		return false
	return parts[0].to_int() == date_dict.get("year", 0) and parts[1].to_int() == date_dict.get("month", 0) and parts[2].to_int() == date_dict.get("day", 0)

func get_today_reward() -> Dictionary:
	var consecutive: int = _sign_in_data.get("consecutiveDays", 0)
	return _storage.get_sign_in_reward(consecutive) if _storage and _storage.has_method("get_sign_in_reward") else {"gold": 50, "exp": 30}

func get_stats() -> Dictionary:
	return {"total_days": _sign_in_data.get("totalDays", 0), "consecutive_days": _sign_in_data.get("consecutiveDays", 0)}

# ============ 帧更新 ============
func _process(dt: float) -> void:
	# 粒子
	for i in range(_particles.size() - 1, -1, -1):
		var p: Dictionary = _particles[i]
		p["x"] += p["vx"]
		p["y"] += p["vy"]
		p["vy"] += 0.15 * 60.0 * dt
		p["life"] -= dt * 0.8
		if p["life"] <= 0.0:
			_particles.remove_at(i)
	# 飘字
	for i in range(_floating_rewards.size() - 1, -1, -1):
		var r: Dictionary = _floating_rewards[i]
		r["y"] += r["vy"]
		r["life"] -= dt
		if r["life"] <= 0.0:
			_floating_rewards.remove_at(i)
	queue_redraw()

# ============ 绘制 ============
func _draw() -> void:
	var font := ThemeDB.fallback_font
	var w := DESIGN_WIDTH
	var h := DESIGN_HEIGHT
	
	# 背景
	draw_rect(Rect2(0, 0, w, h), Color(0.06, 0.08, 0.16))
	
	# 返回按钮
	draw_rect(Rect2(15, 15, 60, 35), Color(0.18, 0.20, 0.30))
	draw_rect(Rect2(15, 15, 60, 35), Color(0.30, 0.35, 0.50), false)
	draw_string(font, Vector2(22, 38), "← 返回", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.8, 0.8, 0.9))
	
	# 标题
	draw_string(font, Vector2(w / 2, 70), "📅 每日签到", HORIZONTAL_ALIGNMENT_CENTER, -1, 22, Color.WHITE)
	
	# 统计
	var total: int = _sign_in_data.get("totalDays", 0)
	var consecutive: int = _sign_in_data.get("consecutiveDays", 0)
	var stats_y := 100.0
	
	# 累计签到卡片
	draw_rect(Rect2(30, stats_y, 145, 80), Color(0.10, 0.12, 0.20))
	draw_rect(Rect2(30, stats_y, 145, 80), Color(0.22, 0.25, 0.35), false)
	draw_string(font, Vector2(102, stats_y + 25), "累计签到", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.5, 0.5, 0.6))
	draw_string(font, Vector2(102, stats_y + 58), "%d 天" % total, HORIZONTAL_ALIGNMENT_CENTER, -1, 24, Color(1.0, 0.84, 0.0))
	
	# 连续签到卡片
	draw_rect(Rect2(200, stats_y, 145, 80), Color(0.10, 0.12, 0.20))
	draw_rect(Rect2(200, stats_y, 145, 80), Color(0.22, 0.25, 0.35), false)
	draw_string(font, Vector2(272, stats_y + 25), "连续签到", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.5, 0.5, 0.6))
	draw_string(font, Vector2(272, stats_y + 58), "%d 天" % consecutive, HORIZONTAL_ALIGNMENT_CENTER, -1, 24, Color(0.9, 0.3, 0.3))
	
	# 7天日历
	var calendar_y := 200.0
	draw_rect(Rect2(30, calendar_y, 315, 75), Color(0.10, 0.12, 0.20))
	draw_rect(Rect2(30, calendar_y, 315, 75), Color(0.22, 0.25, 0.35), false)
	draw_string(font, Vector2(w / 2, calendar_y + 20), "近7天签到记录", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(0.5, 0.5, 0.6))
	
	var days := _get_last_7_days()
	var cell_w := 40.0
	var cal_start_x := (w - 7 * cell_w) / 2.0
	var cell_y := calendar_y + 40.0
	
	for i in range(days.size()):
		var day: Dictionary = days[i]
		var cx: float = cal_start_x + i * cell_w
		
		# 圆圈背景
		if day.is_today:
			draw_circle(Vector2(cx + cell_w / 2, cell_y + 14), 16, Color(1.0, 0.84, 0.0))
			draw_string(font, Vector2(cx + cell_w / 2, cell_y + 18), str(day.get("date", "")), HORIZONTAL_ALIGNMENT_CENTER, -1, 13, Color(0.06, 0.08, 0.16))
		else:
			var c := Color(0.3, 0.8, 0.3) if day.signed else Color(0.15, 0.17, 0.25)
			draw_circle(Vector2(cx + cell_w / 2, cell_y + 14), 16, c)
			draw_string(font, Vector2(cx + cell_w / 2, cell_y + 18), str(day.get("date", "")), HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.WHITE if day.signed else Color(0.5, 0.5, 0.6))
		
		# 标记
		if day.signed:
			draw_string(font, Vector2(cx + cell_w / 2, cell_y + 35), "✓", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.3, 0.8, 0.3))
		elif day.is_today and _can_sign_in:
			draw_string(font, Vector2(cx + cell_w / 2, cell_y + 35), "?", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.5, 0.5, 0.6))
	
	# 今日奖励
	var reward_y := 295.0
	draw_rect(Rect2(30, reward_y, 315, 80), Color(0.10, 0.12, 0.20))
	draw_rect(Rect2(30, reward_y, 315, 80), Color(0.22, 0.25, 0.35), false)
	draw_string(font, Vector2(w / 2, reward_y + 20), "🎁 今日签到奖励", HORIZONTAL_ALIGNMENT_CENTER, -1, 15, Color.WHITE)
	
	var today_reward := get_today_reward()
	draw_string(font, Vector2(100, reward_y + 50), "💰 金币: +%d" % today_reward.get("gold", 50), HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color(1.0, 0.84, 0.0))
	draw_string(font, Vector2(230, reward_y + 50), "✨ 经验: +%d" % today_reward.get("exp", 30), HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color(0.3, 0.8, 0.3))
	
	# 签到按钮
	if _can_sign_in:
		draw_rect(Rect2(87.5, 400, 200, 60), Color(1.0, 0.84, 0.0))
		draw_string(font, Vector2(w / 2, 438), "🎊 签到领奖", HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color(0.1, 0.1, 0.15))
	else:
		draw_rect(Rect2(87.5, 400, 200, 60), Color(0.18, 0.20, 0.30))
		draw_string(font, Vector2(w / 2, 438), "✅ 今日已签到", HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color(0.5, 0.5, 0.6))
	
	# 粒子
	for p in _particles:
		var alpha: float = clampf(p.get("life", 0.0), 0.0, 1.0)
		var c: Color = p.get("color", Color.WHITE)
		c.a = alpha
		var sz: float = p.get("size", 4.0)
		draw_rect(Rect2(p.get("x", 0.0) - sz / 2.0, p.get("y", 0.0) - sz / 2.0, sz, sz), c)
	
	# 飘字
	for r in _floating_rewards:
		var alpha: float = clampf(r.get("life", 0.0) / 1.5, 0.0, 1.0)
		var c: Color = r.get("color", Color.WHITE)
		c.a = alpha
		draw_string(font, Vector2(r.get("x", 0.0), r.get("y", 0.0)), r.get("text", ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, c)
	
	# 签到成功提示
	if _has_signed_in and _animation_complete and _particles.is_empty():
		draw_string(font, Vector2(w / 2, 480), "🎉 签到成功！奖励已发放", HORIZONTAL_ALIGNMENT_CENTER, -1, 15, Color(1.0, 0.84, 0.0))
		draw_string(font, Vector2(w / 2, 510), "点击返回按钮回到主界面", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(0.5, 0.5, 0.6))
