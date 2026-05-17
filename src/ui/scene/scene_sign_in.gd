# ============================================
# scene_sign_in.gd - 每日签到场景
# 翻译来源: js/ui/sceneSignIn.js
# ============================================
# 使用说明：
# - 继承 Control，作为场景根节点
# - 通过 SaveManager 读写签到数据
# - 粒子效果使用 CPUParticles2D
# ============================================

class_name SceneSignIn
extends Control

# 信号
signal back_pressed()
signal sign_in_complete(reward: Dictionary)

# 粒子配置
const PARTICLE_COUNT := 30
const PARTICLE_COLORS := [
	Color("#FFD700"),  # 金色
	Color("#FFA500"),  # 橙色
	Color("#FF6B6B"),  # 红色
	Color("#98D8C8"),  # 薄荷绿
]

# 布局常量
const DESIGN_WIDTH := 375.0
const DESIGN_HEIGHT := 667.0

# 内部状态
var _game: Node = null
var _storage: Node = null
var _sign_in_data: Dictionary = {}
var _can_sign_in: bool = false
var _has_signed_in: bool = false
var _animation_complete: bool = false

# 粒子数据
var _particles: Array[Dictionary] = []
var _floating_rewards: Array[Dictionary] = []

# UI 区域
var _back_btn_rect := Rect2(15.0, 15.0, 60.0, 35.0)
var _sign_btn_rect := Rect2(87.5, 400.0, 200.0, 60.0)

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
	_game = get_node_or_null("/root/GameManager")
	_storage = get_node_or_null("/root/SaveManager")

# 初始化入口
func init(_data: Dictionary = {}) -> void:
	print("[SceneSignIn] 签到场景初始化")
	
	_storage = get_node_or_null("/root/SaveManager")
	_sign_in_data = _storage.load_sign_in_data() if _storage else {}
	_can_sign_in = _storage.can_sign_in_today() if _storage else false
	_has_signed_in = not _can_sign_in
	
	# 重置动画状态
	_particles.clear()
	_floating_rewards.clear()
	_animation_complete = false

# 执行签到
func do_sign_in() -> void:
	if not _can_sign_in:
		return
	
	if not _storage:
		return
	var reward: Dictionary = _storage.do_sign_in()
	if reward.is_empty():
		return
	
	_can_sign_in = false
	_has_signed_in = true
	
	# 更新本地显示数据
	_sign_in_data = _storage.load_sign_in_data()
	
	if _storage and _storage.has_method("set_achievement_stat"):
		_storage.set_achievement_stat("maxConsecutiveSignIn", int(_sign_in_data.get("consecutiveDays", 1)))
		_storage.set_achievement_stat("totalSignInDays", int(_sign_in_data.get("totalDays", 1)))
	
	# 播放金色撒花动画
	_play_sign_in_effect(reward)

# 播放签到特效
func _play_sign_in_effect(reward: Dictionary) -> void:
	var center_x: float = DESIGN_WIDTH / 2.0
	var center_y: float = DESIGN_HEIGHT / 2.0
	
	# 粒子效果
	for i in PARTICLE_COUNT:
		var angle: float = randf() * TAU
		var speed: float = 2.0 + randf() * 4.0
		var start_x: float = center_x + (randf() - 0.5) * 100.0
		var start_y: float = center_y + (randf() - 0.5) * 60.0
		var color_idx: int = randi() % PARTICLE_COLORS.size()
		
		_particles.append({
			"x": start_x,
			"y": start_y,
			"vx": cos(angle) * speed,
			"vy": sin(angle) * speed - 2.0,
			"life": 1.0,
			"color": PARTICLE_COLORS[color_idx],
			"size": 4.0 + randf() * 6.0,
			"rot": randf() * TAU
		})
	
	# 飘字奖励
	_floating_rewards.append({
		"text": "💰 +%d" % reward.get("gold", 0),
		"x": center_x - 50.0,
		"y": center_y,
		"vy": -1.5,
		"life": 1.5,
		"color": Color("#FFD700")
	})
	_floating_rewards.append({
		"text": "✨ +%d" % reward.get("exp", 0),
		"x": center_x + 20.0,
		"y": center_y,
		"vy": -1.2,
		"life": 1.5,
		"color": Color("#4CAF50")
	})
	
	_animation_complete = true

# 点击处理
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		var pos: Vector2 = event.position
		_on_tap(pos.x, pos.y)

func _on_tap(x: float, y: float) -> void:
	# 动画进行中，点击任意位置继续
	if _animation_complete and _particles.is_empty():
		var back_btn: Rect2 = _get_back_button()
		if _is_point_in_rect(x, y, back_btn):
			_go_back()
		return
	
	# 返回按钮
	var back_btn: Rect2 = _get_back_button()
	if _is_point_in_rect(x, y, back_btn):
		_go_back()
		return
	
	# 签到按钮
	if not _can_sign_in:
		return
	var sign_btn: Rect2 = _get_sign_in_button()
	if _is_point_in_rect(x, y, sign_btn):
		do_sign_in()

func _get_back_button() -> Rect2:
	return Rect2(15.0, 15.0, 60.0, 35.0)

func _get_sign_in_button() -> Rect2:
	return Rect2(87.5, 400.0, 200.0, 60.0)

func _is_point_in_rect(x: float, y: float, rect: Rect2) -> bool:
	return x >= rect.position.x and x <= rect.position.x + rect.size.x and y >= rect.position.y and y <= rect.position.y + rect.size.y

func _go_back() -> void:
	back_pressed.emit()

# 帧更新
func _process(dt: float) -> void:
	_update_particles(dt)
	_update_floating_rewards(dt)

# 更新粒子
func _update_particles(dt: float) -> void:
	var gravity: float = 0.15 * 60.0  # 转换为每秒
	var decay: float = 0.8 * 60.0
	
	for i in range(_particles.size() - 1, -1, -1):
		var p: Dictionary = _particles[i]
		p["x"] += p["vx"]
		p["y"] += p["vy"]
		p["vy"] += gravity * dt
		p["life"] -= dt * 0.8
		if p["life"] <= 0.0:
			_particles.remove_at(i)

# 更新飘字
func _update_floating_rewards(dt: float) -> void:
	for i in range(_floating_rewards.size() - 1, -1, -1):
		var r: Dictionary = _floating_rewards[i]
		r["y"] += r["vy"]
		r["life"] -= dt
		if r["life"] <= 0.0:
			_floating_rewards.remove_at(i)

# 获取近7天签到状态
func _get_last_7_days() -> Array[Dictionary]:
	var days: Array[Dictionary] = []
	var now: Dictionary = Time.get_datetime_dict_from_system()
	
	# 获取今天 0 点
	var today_start: Dictionary = {
		"year": now["year"],
		"month": now["month"],
		"day": now["day"]
	}
	
	for i in range(6, -1, -1):
		var d: Dictionary = {}
		d["date"] = today_start["day"] - i
		d["is_today"] = (i == 0)
		d["signed"] = _check_day_signed(d["date"], today_start)
		days.append(d)
	
	return days

# 检查某天是否签到
func _check_day_signed(date: int, today: Dictionary) -> bool:
	if _sign_in_data.is_empty():
		return false
	
	var last_sign: String = _sign_in_data.get("lastSignInDate", "")
	if last_sign.is_empty():
		return false
	
	# 解析最后签到日期
	var parts: PackedStringArray = last_sign.split("-")
	if parts.size() < 3:
		return false
	
	var sign_year: int = parts[0].to_int()
	var sign_month: int = parts[1].to_int()
	var sign_day: int = parts[2].to_int()
	
	# 简化比较：只比较天数
	return sign_day == date and sign_month == today.month

# 获取今日奖励预览
func get_today_reward() -> Dictionary:
	var consecutive: int = _sign_in_data.get("consecutiveDays", 0)
	return _storage.get_sign_in_reward(consecutive) if _storage else {}

# 获取统计数据
func get_stats() -> Dictionary:
	return {
		"total_days": _sign_in_data.get("totalDays", 0),
		"consecutive_days": _sign_in_data.get("consecutiveDays", 0)
	}

# 清理资源
func destroy() -> void:
	_particles.clear()
	_floating_rewards.clear()
