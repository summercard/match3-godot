# ============================================
# ui/scene/scene_battle.gd - 战斗场景
# 翻译自: minigame-1/js/ui/sceneBattle.js
# ============================================
# 核心职责：
# - 回合制战斗界面
# - 展示对手宠物、玩家宠物
# - 技能按钮、道具按钮
# - 战斗状态机

class_name SceneBattle
extends Control

## 设计尺寸
const DESIGN_W := 375.0
const DESIGN_H := 667.0

## 状态枚举
enum BattleState {
	IDLE,
	SWAPPING,
	MATCHING,
	FALLING,
	ENEMY_TURN,
	BATTLE_END
}

## 信号
signal battle_ended(result: String)

## 单例
static var instance: SceneBattle

## 内部变量
var _board = null  # Board 类的实例
var _battle = null  # BattleManager 的实例
var _state: BattleState = BattleState.IDLE

## 选中宝石
var _selected_gem: Vector2i = Vector2i(-1, -1)

## 选中光环脉冲动画
var _selection_pulse: float = 0.0

## 拖拽预览
var _drag_preview: Dictionary = {"active": false, "direction": Vector2i.ZERO}

## 滑动轨迹
var _swipe_trail: Array[Dictionary] = []

## 浮动文字管理器
var _floating_texts: Array[Dictionary] = []

## 连击提示
var _combo_popup: Dictionary = {
	"combo": 0,
	"timer": 0.0,
	"phase": "",
	"scale": 0.5,
	"opacity": 0.0
}

## 消息
var _message_text: String = ""
var _message_timer: float = 0.0

## 敌人攻击
var _enemy_attacks: Array = []
var _enemy_attack_timer: float = 0.0

## 受击闪烁
var _hit_flashes: Array[Dictionary] = []

## 倒下提示
var _fall_messages: Array[Dictionary] = []

## idle动画
var _idle_time: float = 0.0

## HP 渐变动画
var _enemy_display_hp: Array[Dictionary] = []
var _player_display_hp: Array[Dictionary] = []

## 宝石消除动画
var _eliminating_gems: Array[Dictionary] = []  # [{row, col, timer, duration}]
const ELIMINATE_DURATION: float = 0.3

## 宝石下落动画
var _falling_gems: Array[Dictionary] = []  # [{row, col, from_y, to_y, timer, duration}]
const FALL_DURATION: float = 0.25

## 锁定宝石解锁动画队列
var _unlock_animations: Array[Dictionary] = []  # [{row, col, x, y, timer, phase, maxTimer}]

## 毒雾扩散动画队列
var _poison_fog_spread_anims: Array[Dictionary] = []  # [{row, col, x, y, timer}]

## 毒雾清除动画队列
var _poison_fog_clear_anims: Array[Dictionary] = []  # [{row, col, x, y, timer}]

## 特殊消除动画队列
var _special_elim_phases: Array = []  # [{type, gems, delay, timer, triggered}]
var _special_elim_timer: float = 0.0
var _rainbow_flash: float = 0.0       # 全屏闪光倒计时
const RAINBOW_FLASH_DURATION: float = 0.4

## 宝石消除粒子系统
var _gem_particles: Array[Dictionary] = []  # [{x, y, vx, vy, life, max_life, color, size}]

## 障碍物破坏粒子
var _obstacle_particles: Array[Dictionary] = []  # [{x, y, vx, vy, life, max_life, color, size, gravity}]

## Boss技能视觉
var _boss_skill_visuals: Dictionary = {}

## 阶段切换
var _phase_transition_state: Dictionary = {
	"phase": 0,
	"enemies": [],
	"timer": 0.0,
	"boss_name": ""
}
var _screen_flash_timer: float = 0.0
var _shake_timer: float = 0.0

## 攻击震动
var _attack_shake_timer: float = 0.0
var _attack_flash_timer: float = 0.0
var _attack_shake_offset_x: float = 0.0

## 元素连锁光晕
var _element_glow: Dictionary = {"type": "", "timer": 0.0, "color": Color()}

## 伤害数字弹出队列
var _damage_popup_queue: Array[Dictionary] = []

## 关卡数据
var _stage_data: Dictionary = {}
var _stage_id: String = ""

## 美术资源
var _art_assets: Dictionary = {}
var _art_ready: bool = false
var _storage: Node = null
var _texture_cache: Dictionary = {}

var _pointer_down: bool = false
var _pointer_start_pos: Vector2 = Vector2.ZERO
var _pointer_start_grid: Dictionary = {}
const DRAG_SWAP_THRESHOLD: float = 14.0

## 主题颜色
const C := {
	"bg_medium": Color(0.04, 0.07, 0.15),
	"bg_card": Color(0.1, 0.15, 0.25),
	"primary": Color(0.1, 0.5, 1.0),
	"gold": Color(1.0, 0.8, 0.0),
	"fire": Color(1.0, 0.4, 0.1),
	"danger": Color(1.0, 0.15, 0.15),
	"success": Color(0.2, 0.8, 0.3),
	"white": Color(1.0, 1.0, 1.0),
	"text_primary": Color(1.0, 1.0, 1.0),
	"text_secondary": Color(0.7, 0.75, 0.85),
	"text_muted": Color(0.5, 0.55, 0.65),
	"shield": Color(0.314, 0.706, 1.0),
	"heal_green": Color(0.0, 1.0, 0.533),
	"charged_attack": Color(1.0, 0.267, 0.267)
}

## 宝石颜色映射
const GEM_COLORS := {
	"fire": Color(1.0, 0.3, 0.1),
	"water": Color(0.1, 0.4, 1.0),
	"grass": Color(0.1, 0.8, 0.2),
	"thunder": Color(0.9, 0.8, 0.1),
	"light": Color(1.0, 0.9, 0.2)
}

## 锁定宝石颜色
const LOCK_COLORS := {
	"chain": Color(0.6, 0.6, 0.7, 0.9),
	"chain_weak": Color(0.5, 0.5, 0.55, 0.7),
	"lock_icon": Color(0.78, 0.78, 0.86, 0.7)
}

## 障碍物颜色
const OBSTACLE_COLORS := {
	"rock": Color(0.35, 0.3, 0.25, 1.0),
	"rock_solid": Color(0.42, 0.38, 0.32, 1.0),
	"rock_cracked": Color(0.28, 0.24, 0.2, 1.0),
	"crack_line": Color(0.2, 0.18, 0.15, 0.9),
	"highlight": Color(1.0, 1.0, 1.0, 0.15)
}

## 毒雾颜色
const POISON_FOG_COLORS := {
	"overlay": Color(0.31, 0.78, 0.31)
}

## 宝石 Emoji
const GEM_EMOJI := {
	"fire": "🔥",
	"water": "💧",
	"grass": "🌿",
	"thunder": "⚡",
	"light": "✨"
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

## 宝石图片路径映射
const GEM_IMAGE_PATHS := {
	"fire": "res://assets/images/battle/gems/gem_fire.png",
	"water": "res://assets/images/battle/gems/gem_water.png",
	"grass": "res://assets/images/battle/gems/gem_grass.png",
	"thunder": "res://assets/images/battle/gems/gem_thunder.png",
	"light": "res://assets/images/battle/gems/gem_light.png"
}

const MONSTER_IMAGE_PATHS := {
	"monster_001": "res://assets/images/battle/monsters/monster_001_fire_lizard.png",
	"monster_002": "res://assets/images/battle/monsters/monster_002_water_cub.png",
	"monster_003": "res://assets/images/battle/monsters/monster_003_grass_leaf.png",
	"enemy_001": "res://assets/images/battle/monsters/monster_001_fire_lizard.png",
	"enemy_002": "res://assets/images/battle/monsters/monster_002_water_cub.png",
	"enemy_003": "res://assets/images/battle/monsters/monster_003_grass_leaf.png",
	"monster_boss_001": "res://assets/images/battle/monsters/monster_boss_001_grass_flower_512.png"
}

## 宝石 TextureRect 缓存
var _gem_icon_pool: Array[TextureRect] = []

func _ready() -> void:
	instance = self
	set_process_input(true)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_add_background("res://assets/images/battle/battle_bg_forest_ruins.png")

func init(data: Dictionary = {}) -> void:
	print("[SceneBattle] 战斗场景初始化")
	
	var stage_data = data.get("stageData", null)
	var stage_id = data.get("stageId", "stage_1_1")
	
	_selected_gem = Vector2i(-1, -1)
	_hit_flashes = []
	_fall_messages = []
	_enemy_display_hp = []
	_player_display_hp = []
	_boss_skill_visuals = {}
	_eliminating_gems = []
	_falling_gems = []
	_unlock_animations = []
	_poison_fog_spread_anims = []
	_poison_fog_clear_anims = []
	_gem_particles = []
	_obstacle_particles = []
	_special_elim_phases = []
	_special_elim_timer = 0.0
	_rainbow_flash = 0.0
	_element_glow = {"type": "", "timer": 0.0, "color": Color()}
	_damage_popup_queue = []
	_selection_pulse = 0.0
	_drag_preview = {"active": false, "direction": Vector2i.ZERO}
	_swipe_trail = []
	
	_stage_data = stage_data if stage_data else { "id": stage_id, "name": stage_id, "enemies": [], "enemyLevel": 3 }
	_stage_id = stage_id
	
	_init_battle()
	_state = BattleState.IDLE
	_show_message("%s 开始！" % _stage_data.get("name", "战斗"))

## ============================================
# 初始化战斗
## ============================================

func _init_battle() -> void:
	_storage = get_node_or_null("/root/SaveManager")
	_board = Match3Board.new(8, 8)
	_board.cell_size = 42
	_board.offset_x = int((DESIGN_W - _board.cols * _board.cell_size) / 2.0)
	_board.offset_y = 235
	
	if _stage_data.has("obstacles"):
		_board.set_obstacles(_stage_data.get("obstacles", []))
		_board.init_board()
	if _stage_data.has("lockedGems"):
		_board.set_locked_gems(_stage_data.get("lockedGems", []))
	if _stage_data.has("poisonFog"):
		_board.set_poison_fog(_stage_data.get("poisonFog", {}))
	
	var player_level := 5
	var player_team_ids: Array = ["monster_001", "monster_002", "monster_003"]
	if _storage:
		var player: Dictionary = _storage.load_player()
		player_level = maxi(player.get("level", 1), 5)
		var team: Dictionary = _storage.load_team()
		player_team_ids = []
		for slot: String in ["leader", "member1", "member2"]:
			var monster_id: String = team.get(slot, "")
			if monster_id != "":
				player_team_ids.append(monster_id)
		if player_team_ids.is_empty():
			player_team_ids = ["monster_001", "monster_002", "monster_003"]
	
	var enemy_ids: Array = _stage_data.get("enemies", ["enemy_001"])
	var enemy_level: int = _stage_data.get("enemyLevel", 1)
	if is_instance_valid(_battle):
		_battle.queue_free()
	_battle = BattleManager.new()
	add_child(_battle)
	_battle.init(player_team_ids, enemy_ids, player_level, enemy_level, _stage_data, _stage_id)
	
	# 连接 BOSS 技能信号
	if not _battle.enemy_skill_action.is_connected(_on_enemy_skill_action):
		_battle.enemy_skill_action.connect(_on_enemy_skill_action)
	
	_show_message(_stage_data.get("name", "战斗开始！"))

## ============================================
# 输入处理
## ============================================

func _input(event: InputEvent) -> void:
	if not is_inside_tree():
		return
	_handle_input_event(event, false)

func _gui_input(event: InputEvent) -> void:
	_handle_input_event(event, true)

func _handle_input_event(event: InputEvent, already_local: bool = true) -> void:
	if _state == BattleState.BATTLE_END:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_go_to_result()
			get_viewport().set_input_as_handled()
		elif event is InputEventScreenTouch and not event.pressed:
			_go_to_result()
			get_viewport().set_input_as_handled()
		return
	
	if _state != BattleState.IDLE:
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var pos: Vector2 = _get_pointer_position(event, already_local)
		if event.pressed:
			_begin_pointer(pos)
		else:
			_end_pointer(pos)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		var pos: Vector2 = _get_pointer_position(event, already_local)
		if event.pressed:
			_begin_pointer(pos)
		else:
			_end_pointer(pos)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var drag_pos: Vector2 = _get_pointer_position(event, already_local)
		var drag_delta: Vector2 = event.relative
		
		# 记录滑动轨迹
		_swipe_trail.append({
			"x": drag_pos.x,
			"y": drag_pos.y,
			"timer": 0.2,
			"maxTimer": 0.2
		})
		
		# 限制轨迹长度
		if _swipe_trail.size() > 20:
			_swipe_trail.remove_at(0)
		
		if drag_delta.length() > 20:
			var direction := ""
			if abs(drag_delta.x) > abs(drag_delta.y):
				direction = "left" if drag_delta.x < 0 else "right"
			else:
				direction = "up" if drag_delta.y < 0 else "down"
			_on_swipe(drag_pos.x, drag_pos.y, direction)
			get_viewport().set_input_as_handled()
			
			# 更新交换预览方向
			if _selected_gem.x >= 0 and _selected_gem.y >= 0:
				var cell_size := float(_board.cell_size) if _board != null else 42.0
				var board_x := float(_board.offset_x) if _board != null else (DESIGN_W - 336.0) / 2.0
				var board_y := float(_board.offset_y) if _board != null else 280.0
				var gem_cx: float = board_x + _selected_gem.x * cell_size + cell_size / 2.0
				var gem_cy: float = board_y + _selected_gem.y * cell_size + cell_size / 2.0
				var dx: float = drag_pos.x - gem_cx
				var dy: float = drag_pos.y - gem_cy
				var drag_dir := Vector2i.ZERO
				if abs(dx) > abs(dy):
					drag_dir = Vector2i(1 if dx > 0 else -1, 0)
				else:
					drag_dir = Vector2i(0, 1 if dy > 0 else -1)
				_drag_preview = {"active": true, "direction": drag_dir}

func _get_pointer_position(event: InputEvent, already_local: bool) -> Vector2:
	var raw_pos: Vector2 = event.position
	if already_local:
		return raw_pos

	var local_event := make_input_local(event)
	var local_pos: Vector2 = local_event.position
	if _is_board_point(local_pos):
		return local_pos
	if _is_board_point(raw_pos):
		return raw_pos
	if _is_design_point(local_pos):
		return local_pos
	return raw_pos

func _is_board_point(pos: Vector2) -> bool:
	if _board == null:
		return false
	return not _board.screen_to_grid(pos.x, pos.y).is_empty()

func _is_design_point(pos: Vector2) -> bool:
	return pos.x >= 0.0 and pos.x <= DESIGN_W and pos.y >= 0.0 and pos.y <= DESIGN_H

func _begin_pointer(pos: Vector2) -> void:
	_pointer_down = true
	_pointer_start_pos = pos
	_pointer_start_grid = _board.screen_to_grid(pos.x, pos.y) if _board != null else {}

func _end_pointer(pos: Vector2) -> void:
	if not _pointer_down:
		_on_tap(pos.x, pos.y)
		return
	_pointer_down = false
	var delta := pos - _pointer_start_pos
	if delta.length() >= DRAG_SWAP_THRESHOLD and not _pointer_start_grid.is_empty():
		var direction := ""
		if abs(delta.x) > abs(delta.y):
			direction = "left" if delta.x < 0 else "right"
		else:
			direction = "up" if delta.y < 0 else "down"
		_on_swipe(_pointer_start_pos.x, _pointer_start_pos.y, direction)
	else:
		_on_tap(pos.x, pos.y)
	_pointer_start_grid = {}

func _on_tap(x: float, y: float) -> void:
	if _state == BattleState.BATTLE_END:
		_go_to_result()
		return
	
	if _state != BattleState.IDLE:
		return
	
	if _board == null:
		return
	var pos: Dictionary = _board.screen_to_grid(x, y)
	if pos.is_empty():
		return
	if _board.is_obstacle(pos["row"], pos["col"]):
		return
	if _board.is_locked(pos["row"], pos["col"]):
		_show_message("锁住！消除旁边同色宝石解锁")
		return
	
	if _selected_gem.x < 0:
		_selected_gem = Vector2i(pos["col"], pos["row"])
		return
	
	var dr: int = abs(_selected_gem.y - pos["row"])
	var dc: int = abs(_selected_gem.x - pos["col"])
	if dr + dc == 1:
		_do_swap(_selected_gem.y, _selected_gem.x, pos["row"], pos["col"])
	_selected_gem = Vector2i(-1, -1)

func _on_swipe(x: float, y: float, direction: String) -> void:
	if _state != BattleState.IDLE:
		return
	
	if _board == null:
		return
	var pos: Dictionary = _board.screen_to_grid(x, y)
	if pos.is_empty():
		return
	var tr: int = pos["row"]
	var tc: int = pos["col"]
	match direction:
		"up":
			tr -= 1
		"down":
			tr += 1
		"left":
			tc -= 1
		"right":
			tc += 1
	if tr < 0 or tr >= _board.rows or tc < 0 or tc >= _board.cols:
		return
	_do_swap(pos["row"], pos["col"], tr, tc)

func _do_swap(r1: int, c1: int, r2: int, c2: int) -> void:
	if _board == null or _battle == null:
		return
	_state = BattleState.SWAPPING
	if not _board.swap(r1, c1, r2, c2):
		_state = BattleState.IDLE
		_show_message("无法交换")
		return
	var match_result: Dictionary = _board.find_matches()
	if match_result.get("gems", []).is_empty():
		_board.swap(r1, c1, r2, c2)
		_state = BattleState.IDLE
		_show_message("无效交换")
		return
	_battle.turn_count += 1
	_board.cascade_count = 0
	_process_matches()

## ============================================
# 战斗逻辑
## ============================================

func _process_matches() -> void:
	if _board == null or _battle == null:
		_state = BattleState.IDLE
		return
	
	var match_result: Dictionary = _board.find_matches()
	var matches: Array = match_result.get("gems", [])
	var enhanced_matches: Array = match_result.get("enhanced", [])
	var bomb_matches: Array = match_result.get("bomb", [])
	var rainbow_matches: Array = match_result.get("rainbow", [])
	
	if matches.is_empty() and enhanced_matches.is_empty() and bomb_matches.is_empty() and rainbow_matches.is_empty():
		if _board.cascade_count >= 2:
			_show_combo_popup(_board.cascade_count)
		if _check_battle_end():
			return
		_start_enemy_turn()
		return
	
	_state = BattleState.MATCHING
	_board.cascade_count += 1
	
	# ===== 第1步：记录普通消除宝石（动画用）=====
	_eliminating_gems.clear()
	for m in matches:
		if m is Dictionary and m.has("row") and m.has("col"):
			_eliminating_gems.append({"row": m["row"], "col": m["col"], "timer": 0.0, "duration": ELIMINATE_DURATION})
			if m.has("type"):
				spawn_eliminate_particles(m["row"], m["col"], m["type"])
	
	# ===== 第2步：收集特殊消除宝石 =====
	var explosion_gems: Array = _collect_explosion_gems(enhanced_matches, matches)
	var all_excluded: Array = matches + explosion_gems
	var bomb_gems: Array = _collect_bomb_gems(bomb_matches, all_excluded)
	var all_excluded_2: Array = all_excluded + bomb_gems
	var rainbow_gems: Array = _collect_rainbow_gems(rainbow_matches, all_excluded_2)
	
	# ===== 第3步：构建分时消除动画队列 =====
	_special_elim_phases.clear()
	if explosion_gems.size() > 0:
		_special_elim_phases.append({"type": "explosion", "gems": explosion_gems, "delay": 0.1, "timer": 0.0, "triggered": false})
	if bomb_gems.size() > 0:
		_special_elim_phases.append({"type": "bomb", "gems": bomb_gems, "delay": 0.15, "timer": 0.0, "triggered": false})
	if rainbow_gems.size() > 0:
		_special_elim_phases.append({"type": "rainbow", "gems": rainbow_gems, "delay": 0.2, "timer": 0.0, "triggered": false})
	_special_elim_timer = 0.0
	
	# ===== 第4步：特殊消除的视觉提示 =====
	# 十字爆炸 emoji
	for enh in enhanced_matches:
		var cell_size: float = float(_board.cell_size)
		var cx: float = float(_board.offset_x + enh["col"] * cell_size + cell_size / 2.0)
		var cy: float = float(_board.offset_y + enh["row"] * cell_size + cell_size / 2.0)
		_floating_texts.append({"text": "💥", "x": cx, "y": cy - 10.0, "color": C["white"], "size": 22.0, "timer": 0.0, "duration": 0.8})
		_show_message("💥 十字爆炸！")
		# 触发火焰连锁光晕
		_trigger_element_glow("fire", Color(1.0, 0.4, 0.0, 0.15))
	
	# 炸弹 emoji + 震动
	for bomb in bomb_matches:
		var cell_size: float = float(_board.cell_size)
		var cx: float = float(_board.offset_x + bomb["col"] * cell_size + cell_size / 2.0)
		var cy: float = float(_board.offset_y + bomb["row"] * cell_size + cell_size / 2.0)
		var shape: String = bomb.get("shape", "?")
		_floating_texts.append({"text": "💣", "x": cx, "y": cy - 10.0, "color": C["white"], "size": 24.0, "timer": 0.0, "duration": 0.8})
		_show_message("💣 %s形炸弹爆炸！" % shape)
		_trigger_attack_shake()
		# 触发爆炸连锁光晕（橙色）
		_trigger_element_glow("fire", Color(1.0, 0.4, 0.0, 0.15))
	
	# 彩虹 emoji + 全屏闪光 + 震动
	for rainbow in rainbow_matches:
		_rainbow_flash = RAINBOW_FLASH_DURATION
		_show_message("🌈 彩虹消除！清除全部%s！" % GEM_EMOJI.get(rainbow["type"], "💎"))
		_trigger_attack_shake()
		# 触发彩虹连锁光晕（明亮多色）
		_trigger_element_glow("rainbow", Color(1.0, 0.95, 0.9, 0.2))
		var match_cells: Array = rainbow.get("matchCells", rainbow.get("cells", []))
		if match_cells.size() > 0:
			var cell_size: float = float(_board.cell_size)
			var cx: float = float(_board.offset_x + match_cells[0]["col"] * cell_size + cell_size / 2.0)
			var cy: float = float(_board.offset_y + match_cells[0]["row"] * cell_size + cell_size / 2.0)
			_floating_texts.append({"text": "🌈", "x": cx, "y": cy - 15.0, "color": C["white"], "size": 28.0, "timer": 0.0, "duration": 1.0})
	
	# ===== 第5步：播放普通消除动画 =====
	await get_tree().create_timer(ELIMINATE_DURATION).timeout
	_eliminating_gems.clear()
	
	# ===== 第6步：执行消除（普通 + 特殊）=====
	var gem_counts: Dictionary = _board.remove_matches(matches)
	
	# 十字爆炸消除
	for enh in enhanced_matches:
		var positions: Array = _board.get_cross_explosion_positions(enh["row"], enh["col"])
		var e_counts: Dictionary = _board.remove_explosion_gems(positions)
		for type_key in e_counts:
			gem_counts[type_key] = gem_counts.get(type_key, 0) + e_counts[type_key]
	
	# 炸弹消除
	for bomb in bomb_matches:
		var positions: Array = _board.get_bomb_explosion_positions(bomb["row"], bomb["col"])
		var b_counts: Dictionary = _board.remove_explosion_gems(positions)
		for type_key in b_counts:
			gem_counts[type_key] = gem_counts.get(type_key, 0) + b_counts[type_key]
	
	# 彩虹消除
	var rainbow_removed_set: Array = []
	for m in matches:
		rainbow_removed_set.append("%d,%d" % [m["row"], m["col"]])
	for g in explosion_gems:
		rainbow_removed_set.append("%d,%d" % [g["row"], g["col"]])
	for g in bomb_gems:
		rainbow_removed_set.append("%d,%d" % [g["row"], g["col"]])
	for rainbow in rainbow_matches:
		var positions: Array = _board.get_rainbow_positions(rainbow["type"], rainbow_removed_set)
		var r_counts: Dictionary = _board.remove_explosion_gems(positions)
		for type_key in r_counts:
			gem_counts[type_key] = gem_counts.get(type_key, 0) + r_counts[type_key]
		for p in positions:
			rainbow_removed_set.append("%d,%d" % [p["row"], p["col"]])
	
	# ===== 第7步：伤害处理 =====
	var result: Dictionary = _battle.process_match_result(gem_counts, _board.cascade_count)
	for log: Dictionary in result.get("damage_log", []):
		_floating_texts.append({
			"text": "-%d" % log.get("damage", 0),
			"x": DESIGN_W / 2.0,
			"y": 95.0,
			"color": C["gold"],
			"size": 18.0,
			"timer": 0.0,
			"duration": 0.8
		})
		_hit_flashes.append({"isEnemy": true, "monsterIndex": 0, "timer": 0.25, "maxTimer": 0.25})
	_trigger_attack_shake()
	
	# 等待所有特殊消除动画完成（最大延迟 0.2 + 消除时间 0.3）
	var special_wait: float = 0.0
	if _special_elim_phases.size() > 0:
		special_wait = 0.5
	await get_tree().create_timer(maxf(FALL_DURATION, special_wait)).timeout
	_special_elim_phases.clear()
	
	# ===== 第8步：下落 + 递归 =====
	_apply_gravity()
	_state = BattleState.FALLING
	await get_tree().create_timer(FALL_DURATION).timeout
	_process_matches()

func _apply_gravity() -> void:
	if _board:
		_board.apply_gravity()

## 收集十字爆炸宝石（去重）
func _collect_explosion_gems(enhanced_matches: Array, normal_gems: Array) -> Array:
	var gems: Array = []
	var normal_set: Dictionary = {}
	for m in normal_gems:
		normal_set["%d,%d" % [m["row"], m["col"]]] = true
	for enh in enhanced_matches:
		var positions: Array = _board.get_cross_explosion_positions(enh["row"], enh["col"])
		for p in positions:
			var key: String = "%d,%d" % [p["row"], p["col"]]
			if not normal_set.has(key):
				normal_set[key] = true
				var cell_size: float = float(_board.cell_size)
				gems.append({
					"row": p["row"],
					"col": p["col"],
					"type": p["type"],
					"x": float(_board.offset_x + p["col"] * cell_size + cell_size / 2.0),
					"y": float(_board.offset_y + p["row"] * cell_size + cell_size / 2.0),
					"is_explosion": true
				})
	return gems

## 收集炸弹消除宝石（去重，排除普通+爆炸已消除）
func _collect_bomb_gems(bomb_matches: Array, excluded_gems: Array) -> Array:
	var gems: Array = []
	var removed_set: Dictionary = {}
	for g in excluded_gems:
		removed_set["%d,%d" % [g.get("row", -1), g.get("col", -1)]] = true
	for bomb in bomb_matches:
		var positions: Array = _board.get_bomb_explosion_positions(bomb["row"], bomb["col"])
		for p in positions:
			var key: String = "%d,%d" % [p["row"], p["col"]]
			if not removed_set.has(key):
				removed_set[key] = true
				var cell_size: float = float(_board.cell_size)
				gems.append({
					"row": p["row"],
					"col": p["col"],
					"type": p["type"],
					"x": float(_board.offset_x + p["col"] * cell_size + cell_size / 2.0),
					"y": float(_board.offset_y + p["row"] * cell_size + cell_size / 2.0),
					"is_bomb": true
				})
	return gems

## 收集彩虹消除宝石（去重，排除之前所有已消除）
func _collect_rainbow_gems(rainbow_matches: Array, all_removed: Array) -> Array:
	var gems: Array = []
	var removed_set: Dictionary = {}
	for g in all_removed:
		removed_set["%d,%d" % [g.get("row", -1), g.get("col", -1)]] = true
	for rainbow in rainbow_matches:
		var positions: Array = _board.get_rainbow_positions(rainbow["type"], removed_set.keys())
		for p in positions:
			var key: String = "%d,%d" % [p["row"], p["col"]]
			removed_set[key] = true
			var cell_size: float = float(_board.cell_size)
			gems.append({
				"row": p["row"],
				"col": p["col"],
				"type": p["type"],
				"x": float(_board.offset_x + p["col"] * cell_size + cell_size / 2.0),
				"y": float(_board.offset_y + p["row"] * cell_size + cell_size / 2.0),
				"is_rainbow": true
			})
	return gems

## 触发特殊消除动画
func _trigger_special_elim(phase: Dictionary) -> void:
	var type: String = phase["type"]
	var gems: Array = phase["gems"]
	
	for g in gems:
		var gem_type: String = g.get("type", "")
		spawn_eliminate_particles(g["row"], g["col"], gem_type)
		
		_eliminating_gems.append({"row": g["row"], "col": g["col"], "timer": 0.0, "duration": ELIMINATE_DURATION})
		
		var emoji: String = "💥" if type == "explosion" else ("💣" if type == "bomb" else "🌈")
		var emoji_size: float = 14.0 if type == "explosion" else (13.0 if type == "bomb" else 12.0)
		_floating_texts.append({
			"text": GEM_EMOJI.get(gem_type, emoji),
			"x": g["x"],
			"y": g["y"] - float(_board.cell_size) / 2.0,
			"color": GEM_COLORS.get(gem_type, C["white"]),
			"size": emoji_size,
			"timer": 0.0,
			"duration": 0.8
		})

## 状态效果Emoji映射
const STATUS_EMOJI := {"burn": "🔥", "freeze": "❄️", "poison": "☠️", "stun": "⚡"}

## 状态效果颜色
const STATUS_COLORS := {
	"burn": Color(1.0, 0.4, 0.1),
	"poison": Color(0.6, 0.2, 0.8),
	"freeze": Color(0.3, 0.7, 1.0),
	"stun": Color(1.0, 0.85, 0.2)
}

func _start_enemy_turn() -> void:
	_state = BattleState.ENEMY_TURN
	_show_message("敌方回合")
	
	if _battle == null:
		_state = BattleState.IDLE
		return
	var result: Dictionary = _battle.enemy_action()
	
	# 处理状态效果日志（DoT弹出、stun提示、效果消失）
	for log in result.get("status_logs", []):
		var log_type: String = log.get("type", "")
		var enemy_idx: int = log.get("enemy_index", -1)
		var enemy_name: String = log.get("enemy_name", "???")
		
		if log_type == "burn" or log_type == "poison":
			# DoT伤害浮动文字
			var dmg: int = log.get("damage", 0)
			var emoji: String = STATUS_EMOJI.get(log_type, "")
			var color: Color = STATUS_COLORS.get(log_type, C["danger"])
			var ex: float = 15.0 + enemy_idx * 120.0 + 55.0
			var ey: float = 80.0
			_floating_texts.append({
				"text": "-%d%s" % [dmg, emoji],
				"x": ex,
				"y": ey,
				"color": color,
				"size": 16.0,
				"timer": 0.0,
				"duration": 0.8
			})
			# 受击闪烁
			_hit_flashes.append({"isEnemy": true, "monsterIndex": enemy_idx, "timer": 0.25, "maxTimer": 0.25})
		
		elif log_type == "stun":
			_show_message("⚡ %s 眩晕了，无法行动！" % enemy_name)
		
		elif log_type == "freeze":
			_show_message("❄️ %s 冰冻中，ATK降低30%%！" % enemy_name)
		
		elif log_type.ends_with("_end"):
			_show_message(log.get("message", ""))
	
	# 处理DoT击杀提示
	for kill in result.get("dot_kills", []):
		var idx: int = kill.get("enemy_index", -1)
		var name: String = kill.get("enemy_name", "???")
		_fall_messages.append({"text": "☠️ %s 被状态效果击杀！" % name, "timer": 1.5})
	
	for action: Dictionary in result.get("actions", []):
		# 蓄力回合：只显示蓄力提示，不显示伤害
		if action.get("is_charging", false):
			_show_message("⚡ %s 正在蓄力..." % action.get("attacker", ""))
			var attacker_idx := _find_enemy_index(action.get("attacker", ""))
			if attacker_idx >= 0:
				if not _boss_skill_visuals.has(attacker_idx):
					_boss_skill_visuals[attacker_idx] = {
						"charge_timer": 0.0,
						"shield_hp": 0.0,
						"shield_max_hp": 0.0
					}
				_boss_skill_visuals[attacker_idx]["charge_timer"] = 999.0
			continue
		
		if action.get("damage", 0) > 0:
			var dmg_size := 28.0 if action.get("is_charged", false) else 16.0
			var dmg_color := C["charged_attack"] if action.get("is_charged", false) else C["danger"]
			# 伤害数字加入队列（依次弹出，延迟编排）
			var base_y: float = 225.0 + _damage_popup_queue.size() * 20.0
			var entry: Dictionary = {
				"text": "-%d" % action.get("damage", 0),
				"x": 80.0,
				"y": base_y,
				"color": dmg_color,
				"size": dmg_size,
				"delay": _damage_popup_queue.size() * 0.1,
				"elapsed": 0.0,
				"duration": 0.8,
				"critical": action.get("is_charged", false)
			}
			if _damage_popup_queue.size() < 5:
				_damage_popup_queue.append(entry)
	
	await get_tree().create_timer(0.8).timeout
	_enemy_attacks = []
	if _battle.battle_over:
		_state = BattleState.BATTLE_END
		_show_message("战斗结束")
		return
	_state = BattleState.IDLE
	_show_message("你的回合")

func _check_battle_end() -> bool:
	if _battle and _battle.check_battle_end():
		_state = BattleState.BATTLE_END
		return true
	return false

## ============================================
# 消息与弹窗
## ============================================

func _show_message(text: String) -> void:
	_message_text = text
	_message_timer = 1.5

func _show_combo_popup(combo: int) -> void:
	_combo_popup = {
		"combo": combo,
		"timer": 0.0,
		"phase": "in",
		"scale": 0.5,
		"opacity": 0.0
	}
	# Burst Combo 增强视觉：cascade 3次以上触发屏幕闪白
	if combo >= 3:
		_screen_flash_timer = 0.15 if combo == 3 else 0.25
		_trigger_attack_shake()

func _trigger_attack_shake() -> void:
	_attack_shake_timer = 0.2
	_attack_flash_timer = 0.1
	_attack_shake_offset_x = 0.0

func _trigger_element_glow(element_type: String, glow_color: Color) -> void:
	_element_glow = {"type": element_type, "timer": 0.5, "color": glow_color}

## ============================================
# BOSS 技能视觉
## ============================================

func _on_enemy_skill_action(event: Dictionary) -> void:
	var idx: int = event.get("enemy_index", -1)
	if idx < 0:
		return
	if not _boss_skill_visuals.has(idx):
		_boss_skill_visuals[idx] = {
			"charge_timer": 0.0,
			"shield_hp": 0.0,
			"shield_max_hp": 0.0
		}
	var vis: Dictionary = _boss_skill_visuals[idx]
	var event_type: String = event.get("type", "")
	var enemy: Dictionary = event.get("enemy", {})
	var enemy_name: String = enemy.get("name", "???")
	match event_type:
		"charge_start":
			vis["charge_timer"] = 999.0
			_show_message("⚡ %s 正在蓄力..." % enemy_name)
		"charge_release":
			vis["charge_timer"] = 0.0
			var dmg_mult: float = event.get("damage_multiplier", 2.0)
			_show_message("💥 %s 蓄力攻击！×%.1f" % [enemy_name, dmg_mult])
			_trigger_attack_shake()
			_screen_flash_timer = 0.3
		"shield_appear":
			vis["shield_hp"] = float(event.get("shield_hp", 0))
			vis["shield_max_hp"] = float(event.get("shield_max_hp", 0))
			_show_message("🛡️ %s 生成了护盾！" % enemy_name)
		"heal":
			var heal_amount: int = event.get("heal_amount", 0)
			var ex: float = 15.0 + idx * 120.0 + 55.0
			var ey: float = 80.0
			_floating_texts.append({
				"text": "+%d" % heal_amount,
				"x": ex,
				"y": ey,
				"color": C["heal_green"],
				"size": 22.0,
				"timer": 0.0,
				"duration": 1.0,
				"critical": true
			})
			_show_message("💚 %s 回复了 %d HP！" % [enemy_name, heal_amount])

func _sync_boss_skill_visuals() -> void:
	if _battle == null:
		return
	var skill_states: Dictionary = _battle.enemy_skill_states
	for idx in skill_states.keys():
		var skill_state: Dictionary = skill_states[idx]
		if not _boss_skill_visuals.has(idx):
			_boss_skill_visuals[idx] = {
				"charge_timer": 0.0,
				"shield_hp": 0.0,
				"shield_max_hp": 0.0
			}
		var vis: Dictionary = _boss_skill_visuals[idx]
		if skill_state.has("shield"):
			vis["shield_hp"] = float(skill_state["shield"].get("current_hp", 0))
			vis["shield_max_hp"] = float(skill_state["shield"].get("max_hp", 0))
		if skill_state.has("charge"):
			if skill_state["charge"].get("is_charging", false):
				vis["charge_timer"] = 999.0

func _find_enemy_index(name: String) -> int:
	if _battle == null:
		return -1
	var enemies: Array = _battle.enemies
	for i in range(enemies.size()):
		if enemies[i] != null and enemies[i].get("name", "") == name:
			return i
	return -1

## ============================================
# 更新逻辑
## ============================================

func _process(delta: float) -> void:
	# 更新消息
	if _message_timer > 0:
		_message_timer -= delta
	
	# 更新连击弹窗
	if _combo_popup.has("combo"):
		_update_combo_popup(delta)
	
	# 更新受击闪烁
	for i in range(_hit_flashes.size() - 1, -1, -1):
		_hit_flashes[i]["timer"] -= delta
		if _hit_flashes[i]["timer"] <= 0:
			_hit_flashes.remove_at(i)
	
	# 更新倒下提示
	for i in range(_fall_messages.size() - 1, -1, -1):
		_fall_messages[i]["timer"] -= delta
		if _fall_messages[i]["timer"] <= 0:
			_fall_messages.remove_at(i)
	
	# 更新 idle 动画
	if _state == BattleState.IDLE or _state == BattleState.ENEMY_TURN:
		_idle_time += delta
	
	# 更新选中光环脉冲
	if _selected_gem.x >= 0 and _selected_gem.y >= 0:
		_selection_pulse += delta
	
	# 更新攻击震动
	_update_attack_shake(delta)
	
	# 更新 HP 渐变动画
	_update_hp_display(delta)
	
	# 更新浮动文字
	_update_floating_texts(delta)
	
	# 更新宝石消除动画
	_update_gem_animations(delta)
	
	# 更新特殊消除分时动画
	_special_elim_timer += delta
	for phase in _special_elim_phases:
		if phase["triggered"]:
			continue
		phase["timer"] += delta
		if phase["timer"] >= phase["delay"]:
			phase["triggered"] = true
			_trigger_special_elim(phase)
	
	# 更新彩虹全屏闪光
	if _rainbow_flash > 0:
		_rainbow_flash -= delta
	
	# 更新下落动画
	_update_fall_animations(delta)
	
	# 更新解锁碎裂动画
	_update_unlock_animations(delta)
	
	# 更新毒雾扩散动画
	_update_poison_fog_anims(delta)
	
	# 更新宝石消除粒子
	_update_gem_particles(delta)
	
	# 更新障碍物破坏粒子
	_update_obstacle_particles(delta)
	
	# 同步 BOSS 技能视觉状态
	_sync_boss_skill_visuals()
	
	# 每帧重绘
	queue_redraw()

func _update_combo_popup(dt: float) -> void:
	_combo_popup["timer"] += dt
	var t: float = _combo_popup["timer"]
	var phase: String = _combo_popup["phase"]
	
	if phase == "in":
		if t < 0.15:
			var progress: float = t / 0.15
			_combo_popup["scale"] = 0.5 + 0.7 * progress
			_combo_popup["opacity"] = progress
		else:
			_combo_popup["phase"] = "peak"
			_combo_popup["timer"] = 0.0
			_combo_popup["scale"] = 1.2
			_combo_popup["opacity"] = 1.0
	
	elif phase == "peak":
		if t < 0.15:
			var progress: float = t / 0.15
			_combo_popup["scale"] = 1.2 - 0.2 * progress
		else:
			_combo_popup["phase"] = "out"
			_combo_popup["timer"] = 0.0
			_combo_popup["scale"] = 1.0
	
	elif phase == "out":
		if t < 0.3:
			var progress: float = t / 0.3
			_combo_popup["opacity"] = 1.0 - progress
		else:
			_combo_popup.clear()

func _update_attack_shake(dt: float) -> void:
	if _attack_shake_timer <= 0:
		_attack_shake_offset_x = 0.0
		return
	
	_attack_shake_timer -= dt
	var shake_speed := TAU / 0.05
	var max_offset := 4.0
	_attack_shake_offset_x = sin(_attack_shake_timer * shake_speed) * max_offset
	
	if _attack_flash_timer > 0:
		_attack_flash_timer -= dt

func _update_hp_display(dt: float) -> void:
	# 更新敌方 HP 渐变
	for i in range(_enemy_display_hp.size() - 1, -1, -1):
		var h: Dictionary = _enemy_display_hp[i]
		h["timer"] += dt
		if h["timer"] >= h["maxTimer"]:
			h["displayHP"] = h["targetHP"]
			_enemy_display_hp.remove_at(i)
		else:
			var progress: float = h["timer"] / h["maxTimer"]
			var eased: float = 1.0 - pow(1.0 - progress, 2.0)
			h["displayHP"] = h["displayHP"] - (h["displayHP"] - h["targetHP"]) * eased
	
	# 更新我方 HP 渐变
	for i in range(_player_display_hp.size() - 1, -1, -1):
		var h: Dictionary = _player_display_hp[i]
		h["timer"] += dt
		if h["timer"] >= h["maxTimer"]:
			h["displayHP"] = h["targetHP"]
			_player_display_hp.remove_at(i)
		else:
			var progress: float = h["timer"] / h["maxTimer"]
			var eased: float = 1.0 - pow(1.0 - progress, 2.0)
			h["displayHP"] = h["displayHP"] - (h["displayHP"] - h["targetHP"]) * eased

func _update_floating_texts(dt: float) -> void:
	# 处理伤害数字弹出队列
	for i in range(_damage_popup_queue.size() - 1, -1, -1):
		var entry: Dictionary = _damage_popup_queue[i]
		entry["elapsed"] += dt
		if entry["elapsed"] >= entry["delay"]:
			# 延迟到达，将伤害数字加入 _floating_texts
			var text_entry: Dictionary = {
				"text": entry["text"],
				"x": entry["x"],
				"y": entry["y"],
				"color": entry["color"],
				"size": entry["size"],
				"timer": entry["elapsed"] - entry["delay"],
				"duration": entry["duration"],
				"critical": entry.get("critical", false)
			}
			_floating_texts.append(text_entry)
			_damage_popup_queue.remove_at(i)
	
	# 更新浮动文字
	for i in range(_floating_texts.size() - 1, -1, -1):
		var ft: Dictionary = _floating_texts[i]
		ft["timer"] += dt
		if ft["timer"] >= ft.get("duration", 1.0):
			_floating_texts.remove_at(i)
	
	# 更新元素连锁光晕
	if _element_glow.get("timer", 0.0) > 0.0:
		_element_glow["timer"] -= dt
	
	# 更新滑动轨迹
	for i in range(_swipe_trail.size() - 1, -1, -1):
		_swipe_trail[i]["timer"] -= dt
		if _swipe_trail[i]["timer"] <= 0:
			_swipe_trail.remove_at(i)

## ============================================
# 渲染
## ============================================

func _draw() -> void:
	# 应用攻击震动偏移
	if _attack_shake_timer > 0:
		_draw_apply_shake()
	
	# 背景
	_draw_background()
	
	# 攻击白闪
	if _attack_flash_timer > 0:
		var alpha: float = _attack_flash_timer / 0.1 * 0.3
		draw_rect(Rect2(0, 0, DESIGN_W, DESIGN_H), Color(1.0, 1.0, 1.0, alpha))
	
	# 标题栏
	_draw_title_bar()
	
	# 敌方信息区
	_draw_enemies()
	
	# 我方信息区
	_draw_team()
	
	# 棋盘背景
	_draw_board_background()
	
	# 绘制棋盘
	_draw_board()
	
	# 渲染宝石消除粒子
	_draw_gem_particles()
	
	# 渲染障碍物破坏粒子
	_draw_obstacle_particles()
	
	# 选中高亮
	_draw_selection()
	
	# 拖拽预览箭头
	_draw_drag_preview()
	
	# 滑动轨迹
	_draw_swipe_trail()
	
	# 浮动文字
	_draw_floating_texts()
	
	# 连锁弹窗
	_draw_combo_popup()
	
	# 倒下提示
	_draw_fall_messages()
	
	# 底部信息栏
	_draw_bottom_bar()
	
	# 中间消息
	_draw_message()
	
	# 战斗结束覆盖
	if _state == BattleState.BATTLE_END:
		_draw_battle_end_overlay()
	
	# 屏幕闪烁
	if _screen_flash_timer > 0:
		var alpha: float = _screen_flash_timer / 0.3 * 0.5
		draw_rect(Rect2(0, 0, DESIGN_W, DESIGN_H), Color(1.0, 1.0, 1.0, alpha))
	
	# 彩虹全屏闪光
	if _rainbow_flash > 0:
		var rainbow_alpha: float = (_rainbow_flash / RAINBOW_FLASH_DURATION) * 0.4
		var rainbow_color := Color(1.0, 0.9, 0.95, rainbow_alpha)
		draw_rect(Rect2(0, 0, DESIGN_W, DESIGN_H), rainbow_color)
	
	# 阶段切换提示
	_draw_phase_transition()
	
	# 元素连锁光晕
	_draw_element_glow()
	
	# 关闭震动
	if _attack_shake_timer > 0:
		_draw_restore()

## ============================================
# 绘制方法
## ============================================

func _draw_apply_shake() -> void:
	# 通过平移 context 实现震动效果
	pass

func _draw_restore() -> void:
	pass

func _draw_background() -> void:
	draw_rect(Rect2(0, 0, DESIGN_W, DESIGN_H), Color(0.02, 0.03, 0.09, 0.18))

func _draw_title_bar() -> void:
	var title_color := C["white"]
	_draw_rounded_rect(0, 0, DESIGN_W, 50, 0.0, C["bg_card"])
	_draw_text_with_shadow("三消宝可梦 ⚔️", DESIGN_W / 2.0, 25, title_color, 16.0)

func _draw_enemies() -> void:
	_draw_text_with_shadow("— 敌方 —", DESIGN_W / 2.0, 65.0, C["danger"], 12.0)
	
	var start_x := 15.0
	var start_y := 80.0
	if _battle == null:
		return
	for i in range(mini(_battle.enemies.size(), 3)):
		var enemy: Dictionary = _battle.enemies[i]
		if enemy == null:
			continue
		_draw_enemy_card(
			start_x + i * 120.0,
			start_y,
			i,
			enemy.get("name", "敌人"),
			maxi(enemy.get("hp", 0), 0),
			maxi(enemy.get("maxHP", 1), 1),
			enemy
		)

func _draw_enemy_card(x: float, y: float, index: int, name: String, hp: int, max_hp: int, enemy: Dictionary) -> void:
	var card_w := 110.0
	var card_h := 92.0
	
	# 检查受击闪烁
	var flash := _hit_flashes.filter(func(f): return f.get("isEnemy", false) and f.get("monsterIndex", -1) == index)
	var has_flash := flash.size() > 0
	
	# 卡片背景
	var card_color := C["bg_card"]
	if has_flash:
		var flash_alpha: float = flash[0]["timer"] / flash[0]["maxTimer"] * 0.6
		card_color = Color(1.0, 0.2, 0.2, flash_alpha)
	
	_draw_panel(x + 5, y - 5, 110, card_h, card_color, 0.82)
	
	var monster_tex := _get_monster_texture(enemy)
	if monster_tex:
		var sprite_size := 70.0 if enemy.get("isBoss", false) else 54.0
		_draw_texture_fit(monster_tex, Rect2(x + 55.0 - sprite_size / 2.0, y - 2.0 + sin(_idle_time * TAU / 1.5) * 3.0, sprite_size, sprite_size), 1.0 if hp > 0 else 0.35)
	else:
		_draw_text_with_shadow(enemy.get("emoji", "👾"), x + card_w / 2.0, y + 25.0, C["white"], 32.0)
	
	# 名称
	_draw_text_with_shadow(name, x + card_w / 2.0, y + 55, C["text_primary"], 12.0)
	
	# 血条
	_draw_hp_bar(x + 12, y + 66, 96.0, 8.0, float(hp), float(max_hp), C["danger"])
	
	# HP 数值
	_draw_text_with_shadow("%d/%d" % [hp, max_hp], x + card_w / 2.0, y + 82, C["text_muted"], 9.0)
	
	# ===== BOSS 技能视觉反馈 =====
	if _boss_skill_visuals.has(index) and hp > 0:
		var vis: Dictionary = _boss_skill_visuals[index]
		
		# 护盾光圈 + HP 条
		if vis.get("shield_hp", 0.0) > 0.0:
			var shield_hp: float = vis["shield_hp"]
			var shield_max: float = vis["shield_max_hp"]
			var shield_ratio: float = shield_hp / shield_max if shield_max > 0 else 0.0
			var shield_color := Color(0.314, 0.706, 1.0, 0.3 + shield_ratio * 0.4)
			draw_arc(Vector2(x + 55.0, y + 28.0), 36.0, 0.0, TAU, 32, shield_color, 2.0, true)
			_draw_hp_bar(x + 12.0, y + 75.0, 96.0, 4.0, shield_hp, shield_max, C["shield"])
			_draw_text_with_shadow("🛡️%d" % int(shield_hp), x + 55.0, y + 81.0, C["shield"], 8.0)
		
		# 蓄力中闪烁文字
		if vis.get("charge_timer", 0.0) > 0.0:
			var blink_alpha: float = 0.5 + 0.5 * sin(_idle_time * PI * 4.0)
			var charge_color := Color(1.0, 0.784, 0.196, blink_alpha)
			_draw_text_with_shadow("⚡蓄力中...", x + 55.0, y - 2.0, charge_color, 10.0)
	
	# ===== 状态效果图标 =====
	if _battle != null and hp > 0:
		var effects: Array = _battle._status_effect.get_effects_snapshot()
		if index < effects.size() and effects[index] != null:
			var effect: Dictionary = effects[index]
			var status_type: String = effect.get("type", "")
			var emoji: String = STATUS_EMOJI.get(status_type, "?")
			var turns: int = effect.get("turns_left", 1)
			var blink_alpha: float = 0.7 + 0.3 * sin(_idle_time * PI * 3.0)
			var status_color: Color = STATUS_COLORS.get(status_type, C["text_muted"])
			status_color.a = blink_alpha
			_draw_text_with_shadow("%s%d" % [emoji, turns], x + card_w - 10.0, y - 2.0, status_color, 11.0)

func _draw_team() -> void:
	_draw_text_with_shadow("— 我方 —", DESIGN_W / 2.0, 180.0, C["success"], 12.0)
	
	var start_x := 15.0
	var start_y := 195.0
	if _battle == null:
		return
	for i in range(mini(_battle.player_team.size(), 3)):
		var monster: Dictionary = _battle.player_team[i]
		if monster == null:
			continue
		_draw_player_card(
			start_x + i * 120.0,
			start_y,
			i,
			monster.get("name", "伙伴"),
			maxi(monster.get("hp", 0), 0),
			maxi(monster.get("maxHP", 1), 1),
			monster
		)

func _draw_player_card(x: float, y: float, index: int, name: String, hp: int, max_hp: int, monster: Dictionary) -> void:
	var card_w := 110.0
	var card_h := 58.0
	
	_draw_panel(x + 5, y - 8, 110, 58, C["bg_card"], 0.78)
	
	var monster_tex := _get_monster_texture(monster)
	if monster_tex:
		_draw_texture_fit(monster_tex, Rect2(x + 8.0, y - 5.0 + sin(_idle_time * TAU / 1.5) * 1.2, 42, 42), 1.0 if hp > 0 else 0.35)
	else:
		_draw_text_with_shadow(monster.get("emoji", "👾"), x + 30.0, y + 16.0, C["white"], 28.0)
	
	# 名称
	_draw_text_with_shadow(name, x + card_w - 55, y + 6, C["text_primary"], 12.0)
	
	# 血条
	_draw_hp_bar(x + 52, y + 16, 58.0, 7.0, float(hp), float(max_hp), C["success"])
	
	# HP 数值
	_draw_text_with_shadow("%d/%d" % [hp, max_hp], x + card_w - 28, y + 31, C["text_muted"], 8.0)
	
	# 技能充能条（玩家卡片才有）
	if monster.has("skill"):
		var skill_cost: int = monster.get("skill", {}).get("cost", 10)
		var charge: int = 0
		if _battle != null and _battle.skill_charges.has(monster.get("id", "")):
			charge = _battle.skill_charges[monster.get("id", "")]
		var charge_ratio: float = clamp(float(charge) / float(skill_cost) if skill_cost > 0 else 0.0, 0.0, 1.0)
		if charge_ratio >= 1.0:
			_draw_hp_bar(x + 52.0, y + 38.0, 58.0, 5.0, charge_ratio * skill_cost, skill_cost, C["gold"], C["gold"])
		else:
			_draw_hp_bar(x + 52.0, y + 38.0, 58.0, 5.0, charge_ratio * skill_cost, skill_cost, C["bg_card"], C["gold"])

func _draw_board_background() -> void:
	# 棋盘区域背景
	var board_x := (DESIGN_W - 336.0) / 2.0  # 8 * 42 = 336
	var board_y := 235.0
	var board_w := 336.0 + 10.0
	var board_h := 336.0 + 10.0
	
	_draw_rounded_rect(board_x - 5, board_y - 5, board_w, board_h, 8.0, Color(0.06, 0.2, 0.38, 0.88))

func _draw_board() -> void:
	var cell_size := 42.0
	var board_x := (DESIGN_W - 336.0) / 2.0
	var board_y := 280.0
	if _board != null:
		cell_size = float(_board.cell_size)
		board_x = float(_board.offset_x)
		board_y = float(_board.offset_y)
	
	for row in range(8):
		for col in range(8):
			var x := board_x + col * cell_size
			var y := board_y + row * cell_size
			_draw_rounded_rect(x + 1, y + 1, cell_size - 2, cell_size - 2, 4.0, Color(0.02, 0.07, 0.16, 0.66))
			if _board == null:
				continue
			# 障碍物格子：保留格子底色，跳过宝石渲染
			if _board.is_obstacle(row, col):
				continue
			var gem_type: String = _board.grid[row][col]
			if gem_type == "":
				continue
			
			# 检查是否在消除动画中
			var is_eliminating := false
			var elim_progress := 0.0
			for eg in _eliminating_gems:
				if eg["row"] == row and eg["col"] == col:
					is_eliminating = true
					elim_progress = eg["timer"] / eg["duration"]
					break
			
			var gem_color: Color = GEM_COLORS.get(gem_type, C["white"])
			var cx := x + cell_size / 2.0
			var cy := y + cell_size / 2.0
			
			if is_eliminating:
				# 消除动画：放大+淡出
				var scale := 1.0 + 0.5 * elim_progress
				var alpha := 1.0 - elim_progress
				_draw_gem_animated(cx, cy, gem_type, gem_color, scale, alpha)
			else:
				# idle 状态下轻微呼吸
				var idle_scale := 1.0 + 0.02 * sin(_idle_time * TAU / 2.0 + row * 0.5 + col * 0.3)
				_draw_gem_animated(cx, cy, gem_type, gem_color, idle_scale, 1.0)
	
	# 渲染特殊元素（锁定宝石、障碍物、毒雾）
	_draw_locked_gems(_board)
	_draw_obstacles(_board)
	_draw_poison_fog(_board)
	_draw_unlock_animations()
	_draw_poison_fog_anims()

func _draw_gem(cx: float, cy: float, gem_type: String, color: Color) -> void:
	_draw_gem_animated(cx, cy, gem_type, color, 1.0, 1.0)

func _draw_gem_animated(cx: float, cy: float, gem_type: String, color: Color, scale: float, alpha: float) -> void:
	var gem_tex := _get_texture(GEM_IMAGE_PATHS.get(gem_type, ""))
	var draw_size := 36.0 * scale
	
	if gem_tex:
		_draw_texture_fit(gem_tex, Rect2(cx - draw_size / 2.0, cy - draw_size / 2.0, draw_size, draw_size), alpha)
		return
	
	var radius := 15.0 * scale
	# 圆形宝石
	_draw_circle(cx, cy, radius, Color(color.r, color.g, color.b, alpha))
	
	# 高光
	_draw_circle(cx - 2.0 * scale, cy - 2.0 * scale, radius * 0.5, Color(1.0, 1.0, 1.0, 0.3 * alpha))
	
	# Emoji
	var emoji: String = GEM_EMOJI.get(gem_type, "💎")
	_draw_text_with_shadow(emoji, cx, cy, Color(1.0, 1.0, 1.0, 1.0), 14.0)

func _draw_selection() -> void:
	if _selected_gem.x >= 0 and _selected_gem.y >= 0:
		var cell_size := float(_board.cell_size) if _board != null else 42.0
		var board_x := float(_board.offset_x) if _board != null else (DESIGN_W - 336.0) / 2.0
		var board_y := float(_board.offset_y) if _board != null else 280.0
		var sx := board_x + _selected_gem.x * cell_size
		var sy := board_y + _selected_gem.y * cell_size
		
		# 选中光环（脉冲动画）
		var pulse_alpha := 0.3 + 0.5 * (sin(_selection_pulse * TAU / 0.6) + 1.0) / 2.0
		var glow_color := Color(1.0, 0.85, 0.2, pulse_alpha)
		var glow_size := 4.0
		_draw_rounded_rect(sx - glow_size, sy - glow_size, cell_size + glow_size * 2, cell_size + glow_size * 2, 6.0, glow_color)
		
		# 原有的选择框
		_draw_stroke_rect(sx, sy, cell_size, cell_size, 3.0, C["white"])

func _draw_floating_texts() -> void:
	for ft in _floating_texts:
		var text: String = ft.get("text", "")
		var x: float = ft.get("x", 0.0)
		var y: float = ft.get("y", 0.0)
		var color: Color = ft.get("color", C["white"])
		var size: float = ft.get("size", 16.0)
		
		_draw_text_with_shadow(text, x, y, color, size)

func _draw_combo_popup() -> void:
	if not _combo_popup.has("combo"):
		return
	
	var cx := DESIGN_W / 2.0
	var cy := 160.0
	var combo: int = _combo_popup["combo"]
	var scale: float = _combo_popup["scale"]
	var opacity: float = _combo_popup["opacity"]
	
	var box_w := 160.0 * scale
	var box_h := 60.0 * scale
	var bg_color := Color(0.0, 0.0, 0.0, 0.7 * opacity)
	_draw_rounded_rect(cx - box_w / 2.0, cy - box_h / 2.0, box_w, box_h, 12.0 * scale, bg_color)
	
	var text_color := Color(1.0, 0.85, 0.0, opacity)
	_draw_text_with_shadow("%d连击！" % combo, cx, cy, text_color, 22.0 * scale, true)

func _draw_fall_messages() -> void:
	for i in range(_fall_messages.size()):
		var fm: Dictionary = _fall_messages[i]
		var alpha: float = mini(1.0, fm["timer"])
		var text_color := Color(1.0, 0.4, 0.4, alpha)
		_draw_text_with_shadow(fm["text"], DESIGN_W / 2.0, 300.0 + i * 25.0, text_color, 14.0)

func _draw_drag_preview() -> void:
	if not _drag_preview.get("active", false) or _selected_gem.x < 0:
		return
	var dir: Vector2i = _drag_preview.get("direction", Vector2i.ZERO)
	if dir == Vector2i.ZERO:
		return
	var cell_size := float(_board.cell_size) if _board != null else 42.0
	var board_x := float(_board.offset_x) if _board != null else (DESIGN_W - 336.0) / 2.0
	var board_y := float(_board.offset_y) if _board != null else 280.0
	var sx: float = board_x + _selected_gem.x * cell_size + cell_size / 2.0
	var sy: float = board_y + _selected_gem.y * cell_size + cell_size / 2.0
	
	# 绘制箭头（从选中位置到目标位置）
	var target_x: float = sx + dir.x * cell_size
	var target_y: float = sy + dir.y * cell_size
	var preview_color := Color(0.3, 0.8, 1.0, 0.5)
	draw_line(Vector2(sx, sy), Vector2(target_x, target_y), preview_color, 3.0)
	
	# 箭头头部
	var angle: float = atan2(dir.y, dir.x)
	var arrow_size: float = 10.0
	var arrow_color := preview_color
	# 左箭头翼
	draw_line(Vector2(target_x, target_y), Vector2(target_x - cos(angle - 0.4) * arrow_size, target_y - sin(angle - 0.4) * arrow_size), arrow_color, 3.0)
	# 右箭头翼
	draw_line(Vector2(target_x, target_y), Vector2(target_x - cos(angle + 0.4) * arrow_size, target_y - sin(angle + 0.4) * arrow_size), arrow_color, 3.0)

func _draw_swipe_trail() -> void:
	for trail in _swipe_trail:
		var progress: float = 1.0 - trail["timer"] / trail["maxTimer"]
		var alpha: float = (1.0 - progress) * 0.7
		var size: float = 6.0 - progress * 4.0
		var trail_color := Color(0.3, 0.8, 1.0, alpha)
		_draw_circle(trail["x"], trail["y"], size, trail_color)

func _draw_bottom_bar() -> void:
	var bottom_y: float = float(_board.offset_y + _board.rows * _board.cell_size + 15.0) if _board != null else 586.0
	_draw_rounded_rect(10, bottom_y, DESIGN_W - 20, 45, 8.0, C["bg_card"])
	
	var state_color := C["text_muted"]
	if _state == BattleState.ENEMY_TURN:
		state_color = C["danger"]
	
	var turn_count: int = _battle.turn_count if _battle != null else 0
	var max_turns: int = _battle.max_turns if _battle != null else 20
	var combo_count: int = _board.cascade_count if _board != null else 0
	_draw_text_with_shadow("回合: %d/%d" % [turn_count, max_turns], 80.0, bottom_y + 15, C["text_muted"], 12.0)
	_draw_text_with_shadow("连锁: %dx" % combo_count, 190.0, bottom_y + 15, C["gold"], 12.0)
	
	var status_text := "等待操作"
	if _state == BattleState.ENEMY_TURN:
		status_text = "敌方回合"
	elif _state != BattleState.IDLE:
		status_text = "处理中..."
	
	_draw_text_with_shadow("状态: %s" % status_text, 300.0, bottom_y + 15, state_color, 12.0)

func _draw_message() -> void:
	if _message_timer <= 0:
		return
	
	var alpha: float = mini(1.0, _message_timer)
	_draw_rounded_rect(DESIGN_W / 2.0 - 100, DESIGN_H / 2.0 - 20, 200, 40, 12.0, Color(0.0, 0.0, 0.0, 0.7))
	
	var text_color := Color(1.0, 1.0, 1.0, alpha)
	_draw_text_with_shadow(_message_text, DESIGN_W / 2.0, DESIGN_H / 2.0, text_color, 14.0)

func _draw_battle_end_overlay() -> void:
	draw_rect(Rect2(0, 0, DESIGN_W, DESIGN_H), Color(0.0, 0.0, 0.0, 0.6))
	
	var result_text := "🎉 胜利！"
	var result_color := C["white"]
	_draw_text_with_shadow(result_text, DESIGN_W / 2.0, DESIGN_H / 2.0 - 30, result_color, 22.0, true)
	_draw_text_with_shadow("点击查看结算", DESIGN_W / 2.0, DESIGN_H / 2.0 + 20, C["text_muted"], 14.0)

func _draw_phase_transition() -> void:
	if _phase_transition_state.is_empty():
		return
	
	var timer: float = _phase_transition_state.get("timer", 0.0)
	if timer <= 0.5:
		return
	
	var alpha: float = mini(1.0, (timer - 0.5) * 2.0)
	var boss_name: String = _phase_transition_state.get("boss_name", "BOSS")
	
	_draw_rounded_rect(DESIGN_W / 2.0 - 120, DESIGN_H / 2.0 - 30, 240, 60, 12.0, Color(0.0, 0.0, 0.0, 0.8))
	
	var fire_color := Color(1.0, 0.4, 0.1, alpha)
	_draw_text_with_shadow("⚡ %s" % boss_name, DESIGN_W / 2.0, DESIGN_H / 2.0 - 5, fire_color, 16.0, true)
	_draw_text_with_shadow("进入激战状态！", DESIGN_W / 2.0, DESIGN_H / 2.0 + 20, C["white"], 14.0)

## ============================================
# 特殊元素渲染（锁定宝石、障碍物、毒雾）
## ============================================

func _draw_locked_gems(b) -> void:
	if b == null:
		return
	for row in range(b.rows):
		for col in range(b.cols):
			if not b.is_locked(row, col):
				continue
			# 跳过正在播放碎裂动画的锁定宝石
			var is_shattering := false
			for anim in _unlock_animations:
				if anim.get("row") == row and anim.get("col") == col and anim.get("phase") == "shatter":
					is_shattering = true
					break
			if is_shattering:
				continue
			
			var lock: Dictionary = b.locked_gems[row][col]
			var x := float(b.offset_x + col * b.cell_size)
			var y := float(b.offset_y + row * b.cell_size)
			var size := float(b.cell_size)
			var cx := x + size / 2.0
			var cy := y + size / 2.0
			
			# 锁链边框
			var chain_color: Color = LOCK_COLORS.chain if lock.get("hp", 1) >= 2 else LOCK_COLORS.chain_weak
			var corners := [
				Vector2(x + 3, y + 3), Vector2(x + size - 3, y + 3),
				Vector2(x + 3, y + size - 3), Vector2(x + size - 3, y + size - 3)
			]
			for i in range(4):
				draw_line(corners[i], corners[(i + 1) % 4], chain_color, 2.5)
			
			# 四角锁链emoji
			var icon_color := Color(0.78, 0.78, 0.86, 0.9)
			_draw_text_with_shadow("⛓", corners[0].x, corners[0].y, icon_color, 8.0)
			_draw_text_with_shadow("⛓", corners[1].x, corners[1].y, icon_color, 8.0)
			_draw_text_with_shadow("⛓", corners[2].x, corners[2].y, icon_color, 8.0)
			_draw_text_with_shadow("⛓", corners[3].x, corners[3].y, icon_color, 8.0)
			
			# 中心锁标记
			if lock.get("hp", 1) >= 2:
				_draw_text_with_shadow("🔒", cx, cy - 4, Color(1.0, 1.0, 1.0, 0.7), 8.0)
			else:
				_draw_text_with_shadow("×1", cx, cy + 4, Color(1.0, 1.0, 1.0, 0.8), 8.0)

func _draw_obstacles(b) -> void:
	if b == null:
		return
	for row in range(b.rows):
		for col in range(b.cols):
			if not b.is_obstacle(row, col):
				continue
			var ob: Dictionary = b.obstacles[row][col]
			var x := float(b.offset_x + col * b.cell_size)
			var y := float(b.offset_y + row * b.cell_size)
			var size := float(b.cell_size)
			var cx := x + size / 2.0
			var cy := y + size / 2.0
			
			if ob.get("hp", 2) >= 2:
				# 完好石块
				_draw_rounded_rect(x + 2, y + 2, size - 4, size - 4, 4.0, OBSTACLE_COLORS.rock)
				_draw_rounded_rect(x + 4, y + 4, size - 8, size - 8, 3.0, OBSTACLE_COLORS.rock_solid)
				_draw_rounded_rect(x + 6, y + 6, size - 16, (size - 8) / 3, 2.0, OBSTACLE_COLORS.highlight)
				_draw_text_with_shadow("🪨", cx, cy, Color(1.0, 1.0, 1.0, 0.7), 12.0)
			else:
				# 裂纹石块
				_draw_rounded_rect(x + 2, y + 2, size - 4, size - 4, 4.0, OBSTACLE_COLORS.rock)
				_draw_rounded_rect(x + 4, y + 4, size - 8, size - 8, 3.0, OBSTACLE_COLORS.rock_cracked)
				_draw_stroke_rect(x + 4, y + 4, size - 8, size - 8, 1.0, OBSTACLE_COLORS.crack_line)
				# 裂纹线条
				draw_line(Vector2(cx - 6, cy - 4), Vector2(cx, cy + 2), OBSTACLE_COLORS.crack_line, 1.5)
				draw_line(Vector2(cx, cy + 2), Vector2(cx + 5, cy - 6), OBSTACLE_COLORS.crack_line, 1.5)
				draw_line(Vector2(cx - 3, cy + 1), Vector2(cx + 2, cy + 6), OBSTACLE_COLORS.crack_line, 1.5)
				_draw_text_with_shadow("🪨", cx, cy, Color(1.0, 1.0, 1.0, 0.5), 14.0)

func _draw_poison_fog(b) -> void:
	if b == null:
		return
	var pulse_period := 1.5
	var pulse_min := 0.2
	var pulse_max := 0.4
	var t := fmod(_idle_time, pulse_period) / pulse_period
	var pulse_opacity := pulse_min + (pulse_max - pulse_min) * (sin(t * TAU) + 1.0) / 2.0
	
	for row in range(b.rows):
		for col in range(b.cols):
			if not b.is_poison_fog(row, col):
				continue
			var x := float(b.offset_x + col * b.cell_size)
			var y := float(b.offset_y + row * b.cell_size)
			var size := float(b.cell_size)
			var cx := x + size / 2.0
			var cy := y + size / 2.0
			
			# 绿色半透明覆盖
			draw_rect(Rect2(x + 1, y + 1, size - 2, size - 2), Color(0.31, 0.78, 0.31, pulse_opacity))
			# 骷髅图标
			var icon_alpha := 0.5 + pulse_opacity
			_draw_text_with_shadow("💀", cx, cy, Color(1.0, 1.0, 1.0, icon_alpha), 10.0)

func _draw_unlock_animations() -> void:
	for i in range(_unlock_animations.size() - 1, -1, -1):
		var anim: Dictionary = _unlock_animations[i]
		var progress: float = anim["timer"] / anim.get("maxTimer", 0.6)
		if progress >= 1.0:
			continue
		var alpha: float = 1.0 - progress
		var dist: float = progress * 20.0
		var row: int = anim["row"]
		var col: int = anim["col"]
		var cell_size := 42.0
		var board_x := (DESIGN_W - 336.0) / 2.0
		var board_y := 280.0
		if _board != null:
			cell_size = float(_board.cell_size)
			board_x = float(_board.offset_x)
			board_y = float(_board.offset_y)
		var cx: float = board_x + col * cell_size + cell_size / 2.0
		var cy: float = board_y + row * cell_size + cell_size / 2.0
		var dirs := [[-1, -1], [1, -1], [-1, 1], [1, 1]]
		for d: Array in dirs:
			var px: float = cx + d[0] * dist
			var py: float = cy + d[1] * dist
			_draw_text_with_shadow("⛓", px, py, Color(0.6, 0.6, 0.7, alpha), 10.0)

func _draw_poison_fog_anims() -> void:
	# 扩散动画
	for i in range(_poison_fog_spread_anims.size() - 1, -1, -1):
		var anim: Dictionary = _poison_fog_spread_anims[i]
		var progress: float = anim["timer"] / 0.6
		if progress >= 1.0:
			continue
		var alpha: float = (1.0 - progress) * 0.6
		var radius: float = 42.0 * 0.3 * progress * 2.0
		var cx: float = anim["x"] + 21.0
		var cy: float = anim["y"] + 21.0
		var ring_color := Color(0.31, 0.78, 0.31, alpha)
		# 绘制圆弧
		var points := maxi(32, radius * 2)
		for p in range(points):
			var angle1: float = TAU * p / points
			var angle2: float = TAU * (p + 1) / points
			var p1 := Vector2(cx + cos(angle1) * radius, cy + sin(angle1) * radius)
			var p2 := Vector2(cx + cos(angle2) * radius, cy + sin(angle2) * radius)
			draw_line(p1, p2, ring_color, 2.0)
	
	# 清除动画
	for i in range(_poison_fog_clear_anims.size() - 1, -1, -1):
		var anim: Dictionary = _poison_fog_clear_anims[i]
		var progress: float = anim["timer"] / 0.5
		if progress >= 1.0:
			continue
		var alpha: float = 1.0 - progress
		var dist: float = progress * 15.0
		var cx: float = anim["x"] + 21.0
		var cy: float = anim["y"] + 21.0
		var dirs := [[-1, -1], [1, -1], [-1, 1], [1, 1]]
		for d: Array in dirs:
			var px: float = cx + d[0] * dist
			var py: float = cy + d[1] * dist
			_draw_text_with_shadow("☁️", px, py, Color(0.31, 0.78, 0.31, alpha), 10.0)

## ============================================
# 粒子特效系统
## ============================================

func spawn_eliminate_particles(row: int, col: int, gem_type: String) -> void:
	var cell_size := float(_board.cell_size) if _board != null else 42.0
	var board_x := float(_board.offset_x) if _board != null else (DESIGN_W - 336.0) / 2.0
	var board_y := float(_board.offset_y) if _board != null else 280.0
	
	var cx: float = board_x + col * cell_size + cell_size / 2.0
	var cy: float = board_y + row * cell_size + cell_size / 2.0
	
	var gem_color: Color = GEM_COLORS.get(gem_type, C["white"])
	var particle_count := 8
	var speed_base := 80.0
	
	for i in range(particle_count):
		var angle: float = TAU * i / particle_count + randf() * 0.3
		var speed: float = speed_base * (0.6 + randf() * 0.8)
		_gem_particles.append({
			"x": cx,
			"y": cy,
			"vx": cos(angle) * speed,
			"vy": sin(angle) * speed,
			"life": 0.3,
			"max_life": 0.3,
			"color": gem_color,
			"size": 4.0 + randf() * 3.0
		})

func spawn_obstacle_destroy_particles(row: int, col: int) -> void:
	var cell_size := float(_board.cell_size) if _board != null else 42.0
	var board_x := float(_board.offset_x) if _board != null else (DESIGN_W - 336.0) / 2.0
	var board_y := float(_board.offset_y) if _board != null else 280.0
	
	var cx: float = board_x + col * cell_size + cell_size / 2.0
	var cy: float = board_y + row * cell_size + cell_size / 2.0
	
	var particle_count := 12
	var speed_base := 100.0
	
	for i in range(particle_count):
		var angle: float = TAU * i / particle_count + randf() * 0.4
		var speed: float = speed_base * (0.4 + randf() * 1.2)
		_obstacle_particles.append({
			"x": cx,
			"y": cy,
			"vx": cos(angle) * speed,
			"vy": sin(angle) * speed - 50.0,
			"life": 0.5,
			"max_life": 0.5,
			"color": OBSTACLE_COLORS.rock,
			"size": 5.0 + randf() * 4.0,
			"gravity": 300.0
		})

func spawn_unlock_particles(row: int, col: int) -> void:
	var cell_size := float(_board.cell_size) if _board != null else 42.0
	var board_x := float(_board.offset_x) if _board != null else (DESIGN_W - 336.0) / 2.0
	var board_y := float(_board.offset_y) if _board != null else 280.0
	
	var cx: float = board_x + col * cell_size + cell_size / 2.0
	var cy: float = board_y + row * cell_size + cell_size / 2.0
	
	var dirs := [[-1, -1], [1, -1], [-1, 1], [1, 1], [0, -1], [0, 1], [-1, 0], [1, 0]]
	for d: Array in dirs:
		var dist: float = 15.0 + randf() * 10.0
		var angle: float = atan2(d[1], d[0]) + randf() * 0.5 - 0.25
		_unlock_animations.append({
			"row": row,
			"col": col,
			"x": cx + d[0] * dist,
			"y": cy + d[1] * dist,
			"timer": 0.0,
			"maxTimer": 0.4,
			"phase": "shatter"
		})

func _update_gem_particles(delta: float) -> void:
	for i in range(_gem_particles.size() - 1, -1, -1):
		var p: Dictionary = _gem_particles[i]
		p["x"] += p["vx"] * delta
		p["y"] += p["vy"] * delta
		p["vy"] += 200.0 * delta
		p["life"] -= delta
		if p["life"] <= 0:
			_gem_particles.remove_at(i)

func _update_obstacle_particles(delta: float) -> void:
	for i in range(_obstacle_particles.size() - 1, -1, -1):
		var p: Dictionary = _obstacle_particles[i]
		p["x"] += p["vx"] * delta
		p["y"] += p["vy"] * delta
		p["vy"] += p.get("gravity", 300.0) * delta
		p["life"] -= delta
		if p["life"] <= 0:
			_obstacle_particles.remove_at(i)

func _draw_gem_particles() -> void:
	for p: Dictionary in _gem_particles:
		var progress: float = 1.0 - p["life"] / p["max_life"]
		var alpha: float = 1.0 - progress
		var size: float = p["size"] * (1.0 - progress * 0.5)
		var color: Color = Color(p["color"].r, p["color"].g, p["color"].b, alpha)
		_draw_circle(p["x"], p["y"], size, color)

func _draw_obstacle_particles() -> void:
	for p: Dictionary in _obstacle_particles:
		var progress: float = 1.0 - p["life"] / p["max_life"]
		var alpha: float = 1.0 - progress
		var size: float = p["size"] * (1.0 - progress * 0.3)
		var color: Color = Color(p["color"].r, p["color"].g, p["color"].b, alpha)
		var half_size: float = size / 2.0
		_draw_rounded_rect(p["x"] - half_size, p["y"] - half_size, size, size, 1.0, color)

## ============================================
# 辅助绘制方法
## ============================================

func _draw_rounded_rect(x: float, y: float, w: float, h: float, r: float, color: Color) -> void:
	draw_rect(Rect2(x + r, y, w - r * 2, h), color)
	draw_rect(Rect2(x, y + r, w, h - r * 2), color)
	draw_rect(Rect2(x, y, r, r), color)
	draw_rect(Rect2(x + w - r, y, r, r), color)
	draw_rect(Rect2(x, y + h - r, r, r), color)
	draw_rect(Rect2(x + w - r, y + h - r, r, r), color)

func _draw_stroke_rect(x: float, y: float, w: float, h: float, line_width: float, color: Color) -> void:
	# 简化：使用 4 条线绘制边框
	draw_rect(Rect2(x, y, w, line_width), color)
	draw_rect(Rect2(x, y + h - line_width, w, line_width), color)
	draw_rect(Rect2(x, y, line_width, h), color)
	draw_rect(Rect2(x + w - line_width, y, line_width, h), color)

func _draw_circle(cx: float, cy: float, r: float, color: Color) -> void:
	for dy in range(-int(r), int(r) + 1):
		for dx in range(-int(r), int(r) + 1):
			if dx * dx + dy * dy <= r * r:
				draw_rect(Rect2(cx + dx, cy + dy, 1, 1), color)

func _get_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	if not _texture_cache.has(path):
		_texture_cache[path] = load(path)
	return _texture_cache[path]

func _get_monster_texture(monster: Dictionary) -> Texture2D:
	var monster_id: String = monster.get("id", "")
	var path: String = MONSTER_IMAGE_PATHS.get(monster_id, "")
	return _get_texture(path)

func _draw_texture_fit(tex: Texture2D, rect: Rect2, opacity: float = 1.0) -> void:
	if tex == null:
		return
	draw_texture_rect(tex, rect, false, Color(1, 1, 1, opacity))

func _draw_element_glow() -> void:
	if _element_glow.get("timer", 0.0) <= 0.0:
		return
	var remaining: float = _element_glow["timer"]
	var max_time: float = 0.5
	var alpha: float = (remaining / max_time) * 0.15 if remaining <= max_time else 0.0
	var glow_color: Color = _element_glow.get("color", Color.WHITE)
	glow_color.a = alpha
	draw_rect(Rect2(0, 0, DESIGN_W, DESIGN_H), glow_color)

func _draw_panel(x: float, y: float, w: float, h: float, color: Color, opacity: float = 1.0) -> void:
	var panel_tex := _get_texture("res://assets/images/battle/ui/ui_panel_dark_large.png")
	if panel_tex:
		_draw_texture_fit(panel_tex, Rect2(x, y, w, h), opacity)
	else:
		var panel_color := color
		panel_color.a *= opacity
		_draw_rounded_rect(x, y, w, h, 8.0, panel_color)

func _draw_text_with_shadow(text: String, x: float, y: float, color: Color, size: float, bold: bool = false) -> void:
	var shadow_color := Color(0.0, 0.0, 0.0, 0.55)
	var text_w := 200.0
	draw_string(ThemeDB.fallback_font, Vector2(x - text_w / 2.0 + 1, y + 2), text, HORIZONTAL_ALIGNMENT_CENTER, text_w, size, shadow_color)
	draw_string(ThemeDB.fallback_font, Vector2(x - text_w / 2.0, y), text, HORIZONTAL_ALIGNMENT_CENTER, text_w, size, color)

func _draw_hp_bar(x: float, y: float, w: float, h: float, current: float, maximum: float, color: Color) -> void:
	var bg_color := Color(0.2, 0.2, 0.3, 0.8)
	draw_rect(Rect2(x, y, w, h), bg_color)
	
	if current > 0 and maximum > 0:
		var ratio: float = mini(current / maximum, 1.0)
		var fill_w: float = floor((w - 2) * ratio)
		draw_rect(Rect2(x + 1, y + 1, fill_w, h - 2), color)

## ============================================
# 场景切换
## ============================================

func _go_to_result() -> void:
	print("[SceneBattle] 进入结算画面")
	var result: Dictionary = _battle.get_battle_result() if _battle != null else {"result": "win"}
	if has_node("/root/SceneManager"):
		get_node("/root/SceneManager").switch_scene("result", result)
	else:
		emit_signal("battle_ended", result.get("result", "win"))

## ============================================
# 清理
## ============================================

func destroy() -> void:
	_floating_texts.clear()
	_hit_flashes.clear()
	_fall_messages.clear()
	_eliminating_gems.clear()
	_falling_gems.clear()
	_unlock_animations.clear()
	_poison_fog_spread_anims.clear()
	_poison_fog_clear_anims.clear()
	_gem_particles.clear()
	_obstacle_particles.clear()
	_special_elim_phases.clear()

## ============================================
# 宝石消除动画更新
## ============================================

func _update_gem_animations(delta: float) -> void:
	for i in range(_eliminating_gems.size() - 1, -1, -1):
		var eg: Dictionary = _eliminating_gems[i]
		eg["timer"] += delta
		if eg["timer"] >= eg["duration"]:
			_eliminating_gems.remove_at(i)

## ============================================
# 宝石下落动画更新
## ============================================

func _update_fall_animations(delta: float) -> void:
	for i in range(_falling_gems.size() - 1, -1, -1):
		var fg: Dictionary = _falling_gems[i]
		fg["timer"] += delta
		if fg["timer"] >= fg["duration"]:
			_falling_gems.remove_at(i)

func _update_unlock_animations(delta: float) -> void:
	for i in range(_unlock_animations.size() - 1, -1, -1):
		var anim: Dictionary = _unlock_animations[i]
		anim["timer"] += delta
		var progress: float = anim["timer"] / anim.get("maxTimer", 0.6)
		if progress >= 1.0:
			_unlock_animations.remove_at(i)

func _update_poison_fog_anims(delta: float) -> void:
	# 扩散动画
	for i in range(_poison_fog_spread_anims.size() - 1, -1, -1):
		var anim: Dictionary = _poison_fog_spread_anims[i]
		anim["timer"] += delta
		if anim["timer"] >= 0.6:
			_poison_fog_spread_anims.remove_at(i)
	
	# 清除动画
	for i in range(_poison_fog_clear_anims.size() - 1, -1, -1):
		var anim: Dictionary = _poison_fog_clear_anims[i]
		anim["timer"] += delta
		if anim["timer"] >= 0.5:
			_poison_fog_clear_anims.remove_at(i)
