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

const MonsterArtDBScript = preload("res://src/data/monster_art_db.gd")
const BattleUIFeedbackScript = preload("res://src/ui/components/battle_ui_feedback.gd")
const BattleInputMapperScript = preload("res://src/ui/components/battle_input_mapper.gd")
const BattleAnimationControllerScript = preload("res://src/ui/components/battle_animation_controller.gd")
const BattleBoardRendererScript = preload("res://src/ui/components/battle_board_renderer.gd")
const BattleCombatantRendererScript = preload("res://src/ui/components/battle_combatant_renderer.gd")
const BattleFlowControllerScript = preload("res://src/ui/components/battle_flow_controller.gd")
const BattleMatchRulesScript = preload("res://src/ui/components/battle_match_rules.gd")
const BattleHazardRulesScript = preload("res://src/ui/components/battle_hazard_rules.gd")

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
signal battle_fx_requested(event: Dictionary)

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
## 宝石消除动画常量（匹配微信版两段式）
const ELIMINATE_PHASE1: float = 0.1   # 阶段1：放大+闪白（100ms）
const ELIMINATE_PHASE2: float = 0.15  # 阶段2：缩小+消失（150ms）
const ELIMINATE_DURATION: float = ELIMINATE_PHASE1 + ELIMINATE_PHASE2  # 总时长 0.25s

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

## 敌人倒下粒子爆散
var _defeat_explosions: Array[Dictionary] = []  # [{x, y, vx, vy, life, max_life, color, size}]
var _defeated_enemies: Array[int] = []  # 已触发倒下特效的敌人索引（防止重复触发）

## 胜利粒子效果
var _victory_particles: Array[Dictionary] = []

## 战斗结束慢动作
var _slowmotion_timer: float = 0.0
var _battle_end_overlay_timer: float = 0.0
var _battle_end_overlay_started: bool = false
var _battle_end_particles_spawned: bool = false
var _result_transitioning: bool = false

## 棋盘屏幕震动（大量消除时）
var _board_shake_timer: float = 0.0
var _board_shake_offset: Vector2 = Vector2.ZERO

## 收服特效（inline 播放，Phase 4）
var _capture_effect_node: CaptureEffect = null
var _capture_pending: bool = false          # 是否有待播放的收服特效
var _capture_success: bool = false           # 收服是否成功
var _capture_target: Dictionary = {}         # 收服目标怪物
var _capture_result_text: Dictionary = {}    # 收服结果文本
var _capture_item_used: Dictionary = {}      # 使用的捕获道具
var _capture_waiting_for_effect: bool = false # 等待收服特效播放完成
var _capture_phase: String = ""              # "", "playing", "done"

## 特殊宝石激活动画（4-match 生成强化宝石时）
var _special_transform_anim: Dictionary = {
	"row": -1, "col": -1, "type": "", "timer": 0.0, "duration": 0.5, "triggered": false
}

## 元素连锁全屏波纹（cross/L/T 触发时）
var _element_ripple: Dictionary = {
	"active": false, "color": Color(), "timer": 0.0, "duration": 0.6
}

## 关卡数据
var _stage_data: Dictionary = {}
var _stage_id: String = ""
var _input_test_only: bool = false

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

const BATTLE_BG_PATH := "res://assets/images/battle/battle_bg_forest_ruins.png"

const BATTLE_RESULT_OVERLAY_ASSETS := {
	"victory_banner": "res://assets/images/battle/result_overlay/ui_overlay_victory_banner.png",
	"defeat_banner": "res://assets/images/battle/result_overlay/ui_overlay_defeat_banner.png",
	"panel": "res://assets/images/battle/result_overlay/ui_overlay_panel.png",
	"button_continue": "res://assets/images/battle/result_overlay/ui_overlay_button_continue.png",
	"capture_plaque": "res://assets/images/battle/result_overlay/ui_overlay_capture_plaque.png",
	"tap_strip": "res://assets/images/battle/result_overlay/ui_overlay_tap_strip.png",
	"victory_burst": "res://assets/images/battle/result_overlay/fx_overlay_victory_burst.png",
	"confetti": "res://assets/images/battle/result_overlay/fx_overlay_confetti.png",
	"defeat_smoke": "res://assets/images/battle/result_overlay/fx_overlay_defeat_smoke.png",
	"underline": "res://assets/images/battle/result_overlay/fx_overlay_underline.png"
}

## 宝石 TextureRect 缓存
var _gem_icon_pool: Array[TextureRect] = []

func _ready() -> void:
	instance = self
	set_process_input(true)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_add_background(BATTLE_BG_PATH)

func init(data: Dictionary = {}) -> void:
	var stage_data = data.get("stageData", null)
	var stage_id = data.get("stageId", "stage_1_1")
	_input_test_only = data.get("inputTestOnly", false)
	
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
	_screen_flash_timer = 0.0
	_attack_flash_timer = 0.0
	_element_glow = {"type": "", "timer": 0.0, "color": Color()}
	_damage_popup_queue = []
	_selection_pulse = 0.0
	_drag_preview = {"active": false, "direction": Vector2i.ZERO}
	_swipe_trail = []
	_battle_end_overlay_timer = 0.0
	_battle_end_overlay_started = false
	_battle_end_particles_spawned = false
	_result_transitioning = false
	
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
	
	# 精英关卡：应用eliteMultiplier加成敌人属性
	var elite_mult: float = _stage_data.get("eliteMultiplier", 0.0)
	if elite_mult > 0.0:
		for enemy: Dictionary in _battle.enemies:
			if enemy and not enemy.is_empty():
				enemy["maxHP"] = int(enemy.get("maxHP", 0) * elite_mult)
				enemy["hp"] = enemy["maxHP"]
				enemy["atk"] = int(enemy.get("atk", 0) * elite_mult)
				enemy["def"] = int(enemy.get("def", 0) * elite_mult)
	
	_show_message(_stage_data.get("name", "战斗开始！"))

## ============================================
# 输入处理
## ============================================

func _input(event: InputEvent) -> void:
	if not is_inside_tree():
		return
	_handle_input_event(event, false)

func _unhandled_input(event: InputEvent) -> void:
	if not is_inside_tree():
		return
	_handle_input_event(event, false)

func _gui_input(event: InputEvent) -> void:
	_handle_input_event(event, true)

func _handle_input_event(event: InputEvent, already_local: bool = true) -> void:
	if _state == BattleState.BATTLE_END:
		# 收服特效播放中不允许点击跳转
		if _capture_waiting_for_effect:
			get_viewport().set_input_as_handled()
			return
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
			if _try_use_skill_at_position(pos):
				get_viewport().set_input_as_handled()
				return
			_begin_pointer(pos)
		else:
			_end_pointer(pos)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		var pos: Vector2 = _get_pointer_position(event, already_local)
		if event.pressed:
			if _try_use_skill_at_position(pos):
				get_viewport().set_input_as_handled()
				return
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
	var candidates: Array[Vector2] = BattleInputMapperScript.pointer_candidates(self, event, already_local)
	for pos: Vector2 in candidates:
		if _is_board_point(pos):
			return pos
	for pos: Vector2 in candidates:
		if _is_design_point(pos):
			return pos
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
	if _pointer_start_grid.is_empty() and (not _is_design_point(_pointer_start_pos) or not _is_design_point(pos)):
		var fallback_direction := _direction_from_delta(delta)
		if not fallback_direction.is_empty() and _try_first_valid_swipe(fallback_direction):
			_pointer_start_grid = {}
			return
	if delta.length() >= DRAG_SWAP_THRESHOLD and not _pointer_start_grid.is_empty():
		var direction := _direction_from_delta(delta)
		_on_swipe(_pointer_start_pos.x, _pointer_start_pos.y, direction)
	else:
		_on_tap(pos.x, pos.y)
	_pointer_start_grid = {}

func _direction_from_delta(delta: Vector2) -> String:
	return BattleInputMapperScript.direction_from_delta(delta, DRAG_SWAP_THRESHOLD)

func _try_first_valid_swipe(direction: String) -> bool:
	if _board == null:
		return false
	var delta := Vector2i.ZERO
	match direction:
		"left":
			delta = Vector2i(-1, 0)
		"right":
			delta = Vector2i(1, 0)
		"up":
			delta = Vector2i(0, -1)
		"down":
			delta = Vector2i(0, 1)
		_:
			return false
	for row in range(_board.rows):
		for col in range(_board.cols):
			var row2: int = row + delta.y
			var col2: int = col + delta.x
			if row2 < 0 or row2 >= _board.rows or col2 < 0 or col2 >= _board.cols:
				continue
			if _board.is_obstacle(row, col) or _board.is_obstacle(row2, col2):
				continue
			if _board.is_locked(row, col) or _board.is_locked(row2, col2):
				continue
			if not _board.swap(row, col, row2, col2):
				continue
			var matched: bool = not _board.find_matches().get("gems", []).is_empty()
			_board.swap(row, col, row2, col2)
			if matched:
				var x: float = _board.offset_x + col * _board.cell_size + _board.cell_size / 2.0
				var y: float = _board.offset_y + row * _board.cell_size + _board.cell_size / 2.0
				_on_swipe(x, y, direction)
				return true
	return false

func _on_tap(x: float, y: float) -> void:
	if _state == BattleState.BATTLE_END:
		_go_to_result()
		return
	
	if _state != BattleState.IDLE:
		return

	if _try_use_skill_at_position(Vector2(x, y)):
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

func _try_use_skill_at_position(pos: Vector2) -> bool:
	if _battle == null or _state != BattleState.IDLE:
		return false
	for i in range(mini(_battle.player_team.size(), 3)):
		if not _get_player_card_rect(i).has_point(pos):
			continue
		var monster: Dictionary = _battle.player_team[i]
		if monster == null or monster.is_empty() or not monster.has("skill"):
			return true
		var skill: Dictionary = monster.get("skill", {})
		var monster_id: String = monster.get("id", "")
		var cost: int = int(skill.get("cost", 999))
		var charge: int = int(_battle.skill_charges.get(monster_id, 0))
		if monster.get("hp", 0) <= 0:
			_show_message("%s 已无法行动" % monster.get("name", "伙伴"))
			return true
		if charge < cost:
			_show_message("%s 充能 %d/%d" % [skill.get("name", "技能"), charge, cost])
			return true
		var result: Dictionary = _battle.use_active_skill(monster_id)
		_apply_skill_result_visuals(result)
		return true
	return false

func _get_player_card_rect(index: int) -> Rect2:
	return Rect2(20.0 + index * 120.0, 187.0, 110.0, 58.0)

func _apply_skill_result_visuals(result: Dictionary) -> void:
	if result.is_empty() or not result.get("success", false):
		var reason: String = result.get("reason", "")
		if reason == "not_ready":
			_show_message("技能充能 %d/%d" % [result.get("charge", 0), result.get("cost", 0)])
		else:
			_show_message("技能暂时无法释放")
		return
	var skill_name: String = result.get("skill_name", result.get("skillName", "技能"))
	var attacker: String = result.get("attacker", "伙伴")
	var damage: int = result.get("remaining_damage", result.get("remainingDamage", result.get("damage", 0)))
	var shield_absorbed: int = result.get("shield_absorbed", result.get("shieldAbsorbed", 0))
	var target_idx: int = result.get("target_index", result.get("targetIndex", -1))
	_show_message("%s 释放 %s！" % [attacker, skill_name])
	_screen_flash_timer = 0.18
	_trigger_attack_shake()
	if target_idx < 0:
		target_idx = _find_enemy_index(result.get("target", ""))
	var popup_x: float = DESIGN_W / 2.0
	var popup_y: float = 95.0
	if target_idx >= 0:
		popup_x = 25.0 + target_idx * 120.0 + 55.0
		popup_y = 80.0
		_hit_flashes.append({"isEnemy": true, "monsterIndex": target_idx, "timer": 0.3, "maxTimer": 0.3})
	_floating_texts.append({
		"text": "-%d" % damage,
		"x": popup_x,
		"y": popup_y,
		"color": C["gold"] if not result.get("isWeak", false) else C["text_muted"],
		"size": 24.0 if result.get("isEffective", false) else 19.0,
		"timer": 0.0,
		"duration": 0.9,
		"critical": result.get("isEffective", false)
	})
	if shield_absorbed > 0:
		_floating_texts.append({
			"text": "盾-%d" % shield_absorbed,
			"x": popup_x,
			"y": popup_y + 16.0,
			"color": C["shield"],
			"size": 13.0,
			"timer": 0.0,
			"duration": 0.8
		})
	if result.get("targetDied", false):
		_fall_messages.append({"text": "%s 倒下了！" % result.get("target", "敌人"), "timer": 1.5})
	if result.get("battleEnded", false):
		_check_battle_end()

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
	if _input_test_only:
		_state = BattleState.IDLE
		return
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
	var match_context: Dictionary = BattleMatchRulesScript.build_context(_board, match_result, 0.5)
	var matches: Array = match_context.get("matches", [])
	
	if not match_context.get("has_matches", false):
		if _board.cascade_count >= 2:
			_show_combo_popup(_board.cascade_count)
		if _check_battle_end():
			return
		_start_enemy_turn()
		return
	
	_state = BattleState.MATCHING
	_board.cascade_count += 1
	
	# ===== 棋盘屏幕震动：大量消除或高连锁 =====
	var total_elim: int = match_context.get("total_elim", 0)
	if total_elim >= 5 or _board.cascade_count >= 4:
		_board_shake_timer = 0.3
	
	# ===== 第1步：记录普通消除宝石（动画用）=====
	_eliminating_gems.clear()
	for m in matches:
		if m is Dictionary and m.has("row") and m.has("col"):
			_eliminating_gems.append({"row": m["row"], "col": m["col"], "timer": 0.0, "duration": ELIMINATE_DURATION})
			if m.has("type"):
				spawn_eliminate_particles(m["row"], m["col"], m["type"])
	
	# ===== 第2步：读取特殊消除宝石 =====
	var explosion_gems: Array = match_context.get("explosion_gems", [])
	var bomb_gems: Array = match_context.get("bomb_gems", [])
	var rainbow_gems: Array = match_context.get("rainbow_gems", [])
	
	# ===== 第3步：构建分时消除动画队列（四段 setTimeout 链，匹配微信版 804-830 行时序）=====
	_special_elim_phases.clear()
	_special_elim_phases.append_array(match_context.get("special_phases", []))
	_special_elim_timer = 0.0
	
	# ===== 第4步：特殊宝石激活动画（4-match 生成强化宝石时的转换特效）=====
	var special_transform: Dictionary = match_context.get("special_transform", {})
	if not special_transform.is_empty():
		_special_transform_anim = special_transform
	
	# ===== 第4.5步：特殊消除视觉提示存储（延迟触发，由 _trigger_special_elim 在对应延迟时执行）=====
	# 匹配数据已存入 _special_elim_phases[].matches，供分时触发使用
	
	# ===== 第5步：播放普通消除动画 =====
	await get_tree().create_timer(ELIMINATE_DURATION).timeout
	_eliminating_gems.clear()
	
	# ===== 第5.5步：毒雾清除 & 锁定宝石解锁检查 =====
	_check_poison_fog_clears(matches)
	
	# ===== 第6步：执行消除（普通 + 特殊）=====
	var removal_result: Dictionary = BattleMatchRulesScript.apply_removals(_board, match_context)
	var gem_counts: Dictionary = removal_result.get("gem_counts", {})
	
	# ===== 第7步：伤害处理 =====
	var result: Dictionary = _battle.process_match_result(gem_counts, _board.cascade_count)
	for log: Dictionary in result.get("damage_log", []):
		var log_damage: int = log.get("damage", 0)
		var log_effective: bool = log.get("isEffective", false)
		var log_weak: bool = log.get("isWeak", false)
		var log_target: String = log.get("target", "")
		var log_died: bool = log.get("targetDied", false)
		
		# 克制提示
		if log_effective:
			_show_message("效果拔群！")
		elif log_weak:
			_show_message("效果不佳...")
		
		# 克制伤害颜色/大小
		var popup_color: Color = C["fire"] if log_effective else (C["text_muted"] if log_weak else C["gold"])
		var popup_size: float = 24.0 if log_effective else (12.0 if log_weak else 18.0)
		
		var target_idx := _find_enemy_index(log_target)
		if target_idx >= 0:
			var ex := 25.0 + target_idx * 120.0 + 55.0
			var ey := 80.0
			_floating_texts.append({
				"text": "-%d" % log_damage,
				"x": ex, "y": ey,
				"color": popup_color,
				"size": popup_size,
				"timer": 0.0,
				"duration": 0.8,
				"critical": log_effective
			})
			if not log_died:
				_hit_flashes.append({"isEnemy": true, "monsterIndex": target_idx, "timer": 0.25, "maxTimer": 0.25})
				_trigger_attack_shake()
			if log_died:
				_fall_messages.append({"text": "💢 %s 倒下了！" % log_target, "timer": 1.5})
		else:
			# 找不到目标敌人在敌方列表，显示到中央
			_floating_texts.append({
				"text": "-%d" % log_damage,
				"x": DESIGN_W / 2.0, "y": 95.0,
				"color": popup_color,
				"size": popup_size,
				"timer": 0.0,
				"duration": 0.8
			})
			_hit_flashes.append({"isEnemy": true, "monsterIndex": 0, "timer": 0.25, "maxTimer": 0.25})
			_trigger_attack_shake()
	
	# ===== 第7.5步：特殊消除的毒雾清除 & 锁定解锁 =====
	var all_special_gems: Array = removal_result.get("special_gems", explosion_gems + bomb_gems + rainbow_gems)
	_check_explosion_poison_fog(all_special_gems)
	_check_unlock_results(matches, all_special_gems)
	
	# ===== 第7.6步：状态效果附加视觉反馈 =====
	var status_effect_log: Array = result.get("status_effect_log", [])
	for log: Dictionary in status_effect_log:
		var se_idx: int = log.get("enemy_index", -1)
		var se_type: String = log.get("type", "")
		if se_idx >= 0:
			var se_emoji: String = STATUS_EMOJI.get(se_type, "")
			var se_name: String = STATUS_LABEL.get(se_type, se_type)
			var se_color: Color = STATUS_COLORS.get(se_type, C["danger"])
			var se_ex: float = 15.0 + se_idx * 120.0 + 55.0
			var se_ey: float = 65.0
			_floating_texts.append({
				"text": "%s%s" % [se_emoji, se_name],
				"x": se_ex, "y": se_ey,
				"color": se_color,
				"size": 18.0,
				"timer": 0.0,
				"duration": 0.8,
				"critical": true
			})
	
	# ===== 第7.7步：BOSS阶段转换 =====
	var phase_transition: Dictionary = result.get("phase_transition", {})
	if not phase_transition.is_empty() and _battle != null:
		var new_enemies: Array = _battle._phase_handler.execute_phase_transition(phase_transition, _battle.enemy_level)
		if not new_enemies.is_empty():
			var boss_name: String = new_enemies[0].get("name", "BOSS") if new_enemies[0] != null else "BOSS"
			_show_message("⚡ %s 进入激战状态！" % boss_name)
			_phase_transition_state = {
				"phase": phase_transition.get("phase", 1),
				"enemies": new_enemies,
				"timer": 1.5,
				"boss_name": boss_name
			}
			_screen_flash_timer = 0.3
			_shake_timer = 0.3
			_battle.enemies = new_enemies
			_enemy_display_hp.clear()
			_boss_skill_visuals.clear()
			# 延迟清空棋盘
			await get_tree().create_timer(0.1).timeout
			for r in range(_board.rows):
				for c in range(_board.cols):
					_board.grid[r][c] = ""
			# 延迟后重置棋盘
			await get_tree().create_timer(1.0).timeout
			_board.init_board()
	
	# 等待所有特殊消除动画完成（最大延迟 + 消除动画时长）
	# 微信版时序：explosion 100ms, bomb 150ms, rainbow 200ms, 每段动画 ~300ms
	await get_tree().create_timer(BattleMatchRulesScript.get_special_wait(_special_elim_phases, ELIMINATE_DURATION, FALL_DURATION)).timeout
	_special_elim_phases.clear()
	
	# ===== 第8步：下落 + 递归 =====
	_apply_gravity()
	_state = BattleState.FALLING
	await get_tree().create_timer(FALL_DURATION).timeout
	_process_matches()

func _apply_gravity() -> void:
	if _board:
		_board.apply_gravity()

## 触发特殊消除动画（在对应延迟时调用，匹配微信版 setTimeout 链时序）
func _trigger_special_elim(phase: Dictionary) -> void:
	var type: String = phase["type"]
	var gems: Array = phase["gems"]
	var matches: Array = phase.get("matches", [])
	var cell_size: float = float(_board.cell_size) if _board != null else 42.0
	_request_battle_fx({"type": "special_elim", "special_type": type, "gems": gems, "matches": matches})
	
	match type:
		"explosion":
			# 十字爆炸：延迟 100ms 后播放
			_show_message("💥 十字爆炸！")
			_trigger_element_glow("fire", Color(1.0, 0.4, 0.0, 0.15))
			_trigger_element_ripple("fire", Color(1.0, 0.4, 0.0))
			for enh in matches:
				var cx: float = float(_board.offset_x + enh["col"] * cell_size + cell_size / 2.0)
				var cy: float = float(_board.offset_y + enh["row"] * cell_size + cell_size / 2.0)
				_floating_texts.append({"text": "💥", "x": cx, "y": cy - 10.0, "color": C["white"], "size": 22.0, "timer": 0.0, "duration": 0.8})
		
		"bomb":
			# 炸弹消除：延迟 150ms 后播放
			_trigger_attack_shake()
			_trigger_element_glow("fire", Color(1.0, 0.4, 0.0, 0.15))
			for bomb in matches:
				var cx: float = float(_board.offset_x + bomb["col"] * cell_size + cell_size / 2.0)
				var cy: float = float(_board.offset_y + bomb["row"] * cell_size + cell_size / 2.0)
				var shape: String = bomb.get("shape", "?")
				_floating_texts.append({"text": "💣", "x": cx, "y": cy - 10.0, "color": C["white"], "size": 24.0, "timer": 0.0, "duration": 0.8})
				_show_message("💣 %s形炸弹爆炸！" % shape)
		
		"rainbow":
			# 彩虹消除：延迟 200ms 后播放，全屏闪光 0.4s
			_rainbow_flash = RAINBOW_FLASH_DURATION
			_trigger_attack_shake()
			_trigger_element_glow("rainbow", Color(1.0, 0.95, 0.9, 0.2))
			for rainbow in matches:
				_show_message("🌈 彩虹消除！清除全部%s！" % GEM_EMOJI.get(rainbow["type"], "💎"))
				var match_cells: Array = rainbow.get("matchCells", rainbow.get("cells", []))
				if match_cells.size() > 0:
					var cx: float = float(_board.offset_x + match_cells[0]["col"] * cell_size + cell_size / 2.0)
					var cy: float = float(_board.offset_y + match_cells[0]["row"] * cell_size + cell_size / 2.0)
					_floating_texts.append({"text": "🌈", "x": cx, "y": cy - 15.0, "color": C["white"], "size": 28.0, "timer": 0.0, "duration": 1.0})
	
	# 通用：每个受影响宝石的粒子 + 消除动画
	var half_cell: float = float(_board.cell_size) / 2.0 if _board != null else 21.0
	for g in gems:
		var gem_type: String = g.get("type", "")
		spawn_eliminate_particles(g["row"], g["col"], gem_type)
		
		_eliminating_gems.append({"row": g["row"], "col": g["col"], "timer": 0.0, "duration": ELIMINATE_DURATION})
		
		var emoji: String = "💥" if type == "explosion" else ("💣" if type == "bomb" else "🌈")
		var emoji_size: float = 14.0 if type == "explosion" else (13.0 if type == "bomb" else 12.0)
		var gem_y: float = g.get("y", half_cell)
		_floating_texts.append({
			"text": GEM_EMOJI.get(gem_type, emoji),
			"x": g.get("x", 0.0),
			"y": gem_y - half_cell,
			"color": GEM_COLORS.get(gem_type, C["white"]),
			"size": emoji_size,
			"timer": 0.0,
			"duration": 0.8
		})

## 状态效果Emoji映射
const STATUS_EMOJI := {"burn": "🔥", "freeze": "❄️", "poison": "☠️", "stun": "⚡"}

## 状态效果名称
const STATUS_LABEL := {"burn": "灼烧!", "freeze": "冰冻!", "poison": "中毒!", "stun": "眩晕!"}

## 状态效果颜色
const STATUS_COLORS := {
	"burn": Color(1.0, 0.4, 0.1),
	"poison": Color(0.6, 0.2, 0.8),
	"freeze": Color(0.3, 0.7, 1.0),
	"stun": Color(1.0, 0.85, 0.2)
}

func _start_enemy_turn() -> void:
	_state = BattleState.ENEMY_TURN
	
	# ===== 毒雾回合逻辑 =====
	_process_poison_fog_turn()
	
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
						"shield_max_hp": 0.0,
						"heal_floats": []
					}
				_boss_skill_visuals[attacker_idx]["charge_timer"] = 999.0
			continue
		
		if action.get("damage", 0) > 0:
			var dmg_size := 28.0 if action.get("is_charged", false) else 16.0
			var dmg_color := C["charged_attack"] if action.get("is_charged", false) else C["danger"]
			var target_idx := _find_player_index(action.get("target", ""))
			var popup_x: float = 80.0
			var popup_y: float = 225.0 + _damage_popup_queue.size() * 20.0
			if target_idx >= 0:
				popup_x = 15.0 + target_idx * 120.0 + 55.0
				popup_y = 218.0
				_hit_flashes.append({"isEnemy": false, "monsterIndex": target_idx, "timer": 0.35, "maxTimer": 0.35})
			# 伤害数字加入队列（依次弹出，延迟编排）
			var entry: Dictionary = {
				"text": "-%d" % action.get("damage", 0),
				"x": popup_x,
				"y": popup_y,
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
	var next_state := BattleFlowControllerScript.enemy_turn_end_state(_battle)
	if next_state.get("state", "") == "battle_end":
		_state = BattleState.BATTLE_END
		_begin_battle_end_overlay()
		_show_message(next_state.get("message", "战斗结束"))
		return
	_state = BattleState.IDLE
	_show_message(next_state.get("message", "你的回合"))

func _check_battle_end() -> bool:
	if BattleFlowControllerScript.should_end_battle(_battle):
		_state = BattleState.BATTLE_END
		_begin_battle_end_overlay()
		# Phase 4: 战斗结束时 inline 播放收服特效
		# 成功序列：闪白→弹跳→GET! 文字（win）
		# 失败序列：震动→MISS 文字（lose）
		if _battle.battle_result == "win":
			_trigger_inline_capture()
		else:
			# 失败时也要播放 MISS 特效
			_trigger_inline_capture()
		return true
	return false

func _begin_battle_end_overlay() -> void:
	if _battle_end_overlay_started:
		return
	_battle_end_overlay_started = true
	_battle_end_overlay_timer = 0.0
	_battle_end_particles_spawned = false
	_result_transitioning = false
	_attack_shake_timer = 0.0
	_attack_flash_timer = 0.0
	_board_shake_timer = 0.0
	_board_shake_offset = Vector2.ZERO
	_screen_flash_timer = 0.0
	_rainbow_flash = 0.0
	_element_ripple = {"active": false, "color": Color(), "timer": 0.0, "duration": 0.6}
	if _battle != null and _battle.battle_result == "win":
		_slowmotion_timer = 0.5
	else:
		_slowmotion_timer = 0.0

## ============================================
# 收服特效 inline 播放（Phase 4: 移回 battle inline）
## ============================================

func _trigger_inline_capture() -> void:
	"""战斗胜利时，在 scene_battle 中直接触发收服特效"""
	if _battle == null:
		return
	
	var enemies: Array = _battle.enemies
	if enemies.is_empty():
		_capture_phase = "done"
		return
	
	# 选择收服目标：优先存活的，否则随机一个被击败的
	var target_enemy: Dictionary = {}
	for e in enemies:
		if e != null and e.get("hp", 0) > 0:
			target_enemy = e
			break
	if target_enemy.is_empty():
		var valid_enemies: Array = enemies.filter(func(e): return e != null and e.has("id"))
		if not valid_enemies.is_empty():
			target_enemy = valid_enemies[randi() % valid_enemies.size()]
	
	if target_enemy.is_empty():
		_capture_phase = "done"
		return
	
	_capture_target = target_enemy
	var enemy_rarity: int = target_enemy.get("rarity", 1)
	
	# 读取连续失败计数
	var consecutive_fails: int = 0
	if _storage and _storage.has_method("load_player"):
		var player: Dictionary = _storage.load_player()
		consecutive_fails = player.get("captureFails", 0)
	
	# 计算收服概率
	var prob: float = CaptureSystem.calc_capture_probability(
		target_enemy.get("hp", 0), target_enemy.get("maxHP", 1),
		_battle.player_level if _battle else 1,
		_battle.enemy_level if _battle else 1,
		enemy_rarity,
		{"stage_id": _stage_id, "consecutive_fails": consecutive_fails}
	)
	
	# 消耗最佳捕获道具
	var bonus: float = _consume_best_capture_item()
	if bonus > 0.0:
		prob = minf(0.95, prob + bonus)
	
	# 执行收服判定
	_capture_success = CaptureSystem.attempt_capture(prob)
	_capture_result_text = CaptureSystem.get_capture_result_text(prob, _capture_success)
	
	# 更新连续失败计数
	if _storage and _storage.has_method("load_player") and _storage.has_method("save_player"):
		var player: Dictionary = _storage.load_player()
		if _capture_success:
			player["captureFails"] = 0
		else:
			player["captureFails"] = consecutive_fails + 1
		_storage.save_player(player)
	
	# 计算怪物在屏幕上的位置（敌方区域）
	var target_idx: int = enemies.find(target_enemy)
	if target_idx < 0:
		for i in range(enemies.size()):
			if enemies[i] != null and enemies[i].get("id", "") == target_enemy.get("id", ""):
				target_idx = i
				break
	var center_pos := Vector2(DESIGN_W / 2.0, 125.0)
	if target_idx >= 0:
		center_pos = Vector2(15.0 + target_idx * 120.0 + 55.0, 125.0)
	
	# 播放 CaptureEffect
	_capture_effect_node = CaptureEffect.play_capture(self, _capture_success, center_pos)
	_capture_phase = "playing"
	_capture_waiting_for_effect = true
	_show_message(_capture_result_text.get("title", ""))

func _consume_best_capture_item() -> float:
	"""消耗最佳捕获道具，返回概率加成"""
	if not _storage or not _storage.has_method("load_inventory") or not _storage.has_method("use_item"):
		return 0.0
	var inventory: Dictionary = _storage.load_inventory()
	var candidates: Array[Dictionary] = [
		{"id": "capture_ball_plus", "bonus": 0.30, "name": "超级捕获球"},
		{"id": "capture_ball", "bonus": 0.15, "name": "捕获球"}
	]
	for candidate: Dictionary in candidates:
		if inventory.get(candidate["id"], 0) > 0:
			if _storage.use_item(candidate["id"], 1):
				_capture_item_used = candidate
				return candidate["bonus"]
	return 0.0

## ============================================
# 消息与弹窗
## ============================================

func _show_message(text: String) -> void:
	_message_text = text
	_message_timer = 1.5

func _request_battle_fx(event: Dictionary) -> void:
	emit_signal("battle_fx_requested", event)

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

func _trigger_element_ripple(element_type: String, ripple_color: Color) -> void:
	_element_ripple = {
		"active": true,
		"color": ripple_color,
		"timer": 0.6,
		"duration": 0.6
	}

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
			"shield_max_hp": 0.0,
			"heal_floats": []
		}
	var vis: Dictionary = _boss_skill_visuals[idx]
	var event_type: String = event.get("type", "")
	var enemy: Dictionary = event.get("enemy", {})
	var enemy_name: String = enemy.get("name", "???")
	match event_type:
		"charge_start":
			vis["charge_timer"] = 999.0
			vis["heal_floats"] = []  # 蓄力时清空治疗浮动记录
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
				"shield_max_hp": 0.0,
				"heal_floats": []
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

func _find_player_index(name: String) -> int:
	if _battle == null:
		return -1
	var team: Array = _battle.player_team
	for i in range(team.size()):
		if team[i] != null and team[i].get("name", "") == name:
			return i
	return -1

## ============================================
# 更新逻辑
## ============================================

func _process(delta: float) -> void:
	# 战斗结束慢动作效果（局部时间缩放，不影响 Engine.time_scale）
	var effective_delta: float = delta
	if _slowmotion_timer > 0:
		_slowmotion_timer -= delta
		effective_delta = delta * 0.3  # 0.3x 慢动作
		if _slowmotion_timer <= 0:
			_slowmotion_timer = 0.0
			if _state == BattleState.BATTLE_END and not _battle_end_particles_spawned:
				_battle_end_particles_spawned = true
				_spawn_victory_particles()
	
	# 更新消息
	_message_timer = BattleAnimationControllerScript.tick_countdown(_message_timer, effective_delta)
	
	# 更新连击弹窗
	if _combo_popup.has("combo"):
		_update_combo_popup(effective_delta)
	
	# 更新受击闪烁
	BattleAnimationControllerScript.tick_timed_entries(_hit_flashes, effective_delta)
	
	# 更新倒下提示
	BattleAnimationControllerScript.tick_timed_entries(_fall_messages, effective_delta)
	
	# 更新 idle 动画
	if _state == BattleState.IDLE or _state == BattleState.ENEMY_TURN:
		_idle_time += effective_delta
	
	# 更新选中光环脉冲
	if _selected_gem.x >= 0 and _selected_gem.y >= 0:
		_selection_pulse += effective_delta
	
	# 更新攻击震动
	_update_attack_shake(effective_delta)
	_screen_flash_timer = BattleAnimationControllerScript.tick_countdown(_screen_flash_timer, delta)
	
	# 更新 HP 渐变动画
	_update_hp_display(effective_delta)
	
	# 更新浮动文字
	_update_floating_texts(effective_delta)
	
	# 更新宝石消除动画
	_update_gem_animations(effective_delta)
	
	# 更新特殊消除分时动画
	_special_elim_timer += effective_delta
	for phase in _special_elim_phases:
		if phase["triggered"]:
			continue
		phase["timer"] += effective_delta
		if phase["timer"] >= phase["delay"]:
			phase["triggered"] = true
			_trigger_special_elim(phase)
	
	# 更新彩虹全屏闪光
	if _rainbow_flash > 0:
		_rainbow_flash -= effective_delta
	
	# 更新下落动画
	_update_fall_animations(effective_delta)
	
	# 更新解锁碎裂动画
	_update_unlock_animations(effective_delta)
	
	# 更新毒雾扩散动画
	_update_poison_fog_anims(effective_delta)
	
	# 更新宝石消除粒子
	_update_gem_particles(effective_delta)
	
	# 更新障碍物破坏粒子
	_update_obstacle_particles(effective_delta)
	
	# 更新敌人倒下粒子
	_update_defeat_particles(effective_delta)
	
	# 更新胜利粒子
	_update_victory_particles(effective_delta)

	if _state == BattleState.BATTLE_END:
		_battle_end_overlay_timer += delta
		if _battle != null and _battle.battle_result == "win" and not _battle_end_particles_spawned and _battle_end_overlay_timer >= 0.35:
			_battle_end_particles_spawned = true
			_spawn_victory_particles()
	
	# 更新棋盘屏幕震动
	var board_shake := BattleAnimationControllerScript.update_board_shake(_board_shake_timer, effective_delta)
	_board_shake_timer = board_shake["timer"]
	_board_shake_offset = board_shake["offset"]
	
	# 更新特殊宝石激活动画
	if _special_transform_anim.get("timer", 0.0) > 0:
		_special_transform_anim["timer"] -= effective_delta
	
	# 更新元素连锁全屏波纹
	BattleAnimationControllerScript.update_element_ripple(_element_ripple, effective_delta)
	
	# 同步 BOSS 技能视觉状态
	_sync_boss_skill_visuals()
	
	# 检查收服特效是否播放完成（Phase 4）
	if _capture_waiting_for_effect and _capture_phase == "playing":
		if _capture_effect_node == null or not is_instance_valid(_capture_effect_node) or not _capture_effect_node.is_active():
			_capture_waiting_for_effect = false
			_capture_phase = "done"
	
	# 每帧重绘
	queue_redraw()

func _update_combo_popup(dt: float) -> void:
	BattleAnimationControllerScript.update_combo_popup(_combo_popup, dt)

func _update_attack_shake(dt: float) -> void:
	var state := BattleAnimationControllerScript.update_attack_shake(_attack_shake_timer, _attack_flash_timer, dt)
	_attack_shake_timer = state["timer"]
	_attack_flash_timer = state["flash_timer"]
	_attack_shake_offset_x = state["offset_x"]

func _update_hp_display(dt: float) -> void:
	BattleAnimationControllerScript.update_hp_display(_enemy_display_hp, dt)
	BattleAnimationControllerScript.update_hp_display(_player_display_hp, dt)

func _update_floating_texts(dt: float) -> void:
	BattleAnimationControllerScript.update_floating_texts(_floating_texts, _damage_popup_queue, _element_glow, _swipe_trail, dt)

## ============================================
# 渲染
## ============================================

func _draw() -> void:
	# 应用攻击震动偏移
	if _attack_shake_timer > 0 and _state != BattleState.BATTLE_END:
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
	
	# 渲染敌人倒下粒子
	_draw_defeat_particles()
	
	# 渲染胜利粒子
	_draw_victory_particles()

	# 全屏白闪只压在战场内容层，避免盖住结算/Boss UI。
	_draw_screen_flash()
	
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
	
	# 彩虹全屏闪光
	if _rainbow_flash > 0:
		var rainbow_alpha: float = (_rainbow_flash / RAINBOW_FLASH_DURATION) * 0.4
		var rainbow_color := Color(1.0, 0.9, 0.95, rainbow_alpha)
		draw_rect(Rect2(0, 0, DESIGN_W, DESIGN_H), rainbow_color)
	
	# 阶段切换提示
	_draw_phase_transition()
	
	# 元素连锁光晕
	_draw_element_glow()
	
	# 元素连锁全屏波纹（cross/L/T 触发）
	_draw_element_ripple()
	
	# 特殊宝石激活动画
	_draw_special_transform()

	# 战斗结束覆盖必须最后绘制，避免白闪、彩虹闪、波纹盖在胜负 UI 上。
	if _state == BattleState.BATTLE_END:
		_draw_restore()
		_draw_battle_end_overlay()
		
	# 关闭震动
	if _attack_shake_timer > 0:
		_draw_restore()

## ============================================
# 绘制方法
## ============================================

func _draw_apply_shake() -> void:
	var offset := BattleUIFeedbackScript.shake_offset(_attack_shake_timer)
	draw_set_transform(offset, 0.0, Vector2.ONE)

func _draw_restore() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_screen_flash() -> void:
	if _screen_flash_timer <= 0.0:
		return
	var alpha: float = clampf(_screen_flash_timer / 0.3, 0.0, 1.0) * 0.22
	draw_rect(Rect2(0, 0, DESIGN_W, DESIGN_H), Color(1.0, 1.0, 1.0, alpha))

func _combatant_render_state() -> Dictionary:
	return {
		"design_w": DESIGN_W,
		"colors": C,
		"idle_time": _idle_time,
		"hit_flashes": _hit_flashes,
		"defeated_enemies": _defeated_enemies,
		"boss_skill_visuals": _boss_skill_visuals,
		"status_emoji": STATUS_EMOJI,
		"status_colors": STATUS_COLORS
	}

func _board_render_state() -> Dictionary:
	return {
		"design_w": DESIGN_W,
		"colors": C,
		"gem_colors": GEM_COLORS,
		"lock_colors": LOCK_COLORS,
		"obstacle_colors": OBSTACLE_COLORS,
		"poison_fog_colors": POISON_FOG_COLORS,
		"idle_time": _idle_time,
		"board_shake_offset": _board_shake_offset,
		"eliminating_gems": _eliminating_gems,
		"selected_gem": _selected_gem,
		"unlock_animations": _unlock_animations,
		"poison_fog_spread_anims": _poison_fog_spread_anims,
		"poison_fog_clear_anims": _poison_fog_clear_anims,
		"special_transform_anim": _special_transform_anim,
		"eliminate_phase1": ELIMINATE_PHASE1,
		"eliminate_phase2": ELIMINATE_PHASE2,
		"eliminate_duration": ELIMINATE_DURATION
	}

func _draw_background() -> void:
	var bg_tex := _get_texture(BATTLE_BG_PATH)
	if bg_tex:
		_draw_texture_cover(bg_tex, Rect2(0, 0, DESIGN_W, DESIGN_H))
	draw_rect(Rect2(0, 0, DESIGN_W, DESIGN_H), Color(0.02, 0.03, 0.09, 0.34))

func _draw_title_bar() -> void:
	var title_color := C["white"]
	_draw_rounded_rect(0, 0, DESIGN_W, 50, 0.0, C["bg_card"])
	_draw_text_with_shadow("三消宝可梦 ⚔️", DESIGN_W / 2.0, 25, title_color, 16.0)
	
	# BOSS阶段指示器
	if _battle != null:
		var status: Dictionary = _battle.get_status()
		if status.get("is_boss_battle", false):
			var phase_color := C["fire"] if _phase_transition_state.get("timer", 0.0) > 0 else C["danger"]
			_draw_text_with_shadow("阶段 %d/%d" % [status.get("current_phase", 1), status.get("total_phases", 1)], DESIGN_W - 60.0, 25.0, phase_color, 10.0)
	
	# 队长技能信息条（标题栏下方）
	if _battle != null:
		var ls_info = _battle.get_status().get("leader_skill_info", null)
		if ls_info != null:
			var ls_bar_y := 42.0
			_draw_rounded_rect(5, ls_bar_y, DESIGN_W - 10, 16, 3.0, Color(1.0, 0.84, 0.0, 0.15))
			var ls_dict: Dictionary = ls_info if ls_info is Dictionary else {}
			var ls_name: String = ls_dict.get("name", "")
			var ls_desc: String = ls_dict.get("desc", "")
			var ls_icon: String = ls_dict.get("icon", "👑")
			_draw_text_with_shadow("👑 队长技能: %s %s — %s" % [ls_icon, ls_name, ls_desc], DESIGN_W / 2.0, ls_bar_y + 10, C["gold"], 9.0)
		
		# 属性协同信息条
		var syn_info: Array = _battle.get_status().get("synergy_info", [])
		if syn_info.size() > 0:
			var syn_bar_y := 60.0 if ls_info != null else 42.0
			_draw_rounded_rect(5, syn_bar_y, DESIGN_W - 10, 14.0 + syn_info.size() * 2.0, 3.0, Color(0.4, 0.8, 0.4, 0.12))
			var syn_labels: Array = []
			for s in syn_info:
				if s is Dictionary:
					syn_labels.append(s.get("label", ""))
			var syn_text: String = "🤝 " + " | ".join(syn_labels)
			_draw_text_with_shadow(syn_text, DESIGN_W / 2.0, syn_bar_y + 9.0, C["success"], 8.0)

func _draw_enemies() -> void:
	BattleCombatantRendererScript.draw_enemies(self, _battle, _combatant_render_state())

func _draw_enemy_card(x: float, y: float, index: int, name: String, hp: int, max_hp: int, enemy: Dictionary) -> void:
	BattleCombatantRendererScript.draw_enemy_card(self, _battle, _combatant_render_state(), x, y, index, name, hp, max_hp, enemy)

func _draw_team() -> void:
	BattleCombatantRendererScript.draw_team(self, _battle, _combatant_render_state())

func _draw_player_card(x: float, y: float, index: int, name: String, hp: int, max_hp: int, monster: Dictionary) -> void:
	BattleCombatantRendererScript.draw_player_card(self, _battle, _combatant_render_state(), x, y, index, name, hp, max_hp, monster)

func _draw_board_background() -> void:
	BattleBoardRendererScript.draw_board_background(self, DESIGN_W)

func _draw_board() -> void:
	BattleBoardRendererScript.draw_board(self, _board, _board_render_state())

func _draw_gem(cx: float, cy: float, gem_type: String, color: Color) -> void:
	_draw_gem_animated(cx, cy, gem_type, color, 1.0, 1.0)

func _draw_gem_animated(cx: float, cy: float, gem_type: String, color: Color, scale: float, alpha: float, brightness: float = 0.0) -> void:
	var gem_tex := _get_texture(GEM_IMAGE_PATHS.get(gem_type, ""))
	var draw_size := 36.0 * scale
	
	# 闪白效果：先画一个更大的白色光圈
	if brightness > 0.0 and alpha > 0.0:
		var glow_radius := 20.0 * scale * (1.0 + brightness * 0.3)
		_draw_circle(cx, cy, glow_radius, Color(1.0, 1.0, 1.0, brightness * 0.6 * alpha))
	
	if gem_tex:
		_draw_texture_fit(gem_tex, Rect2(cx - draw_size / 2.0, cy - draw_size / 2.0, draw_size, draw_size), alpha)
		return
	
	var radius := 15.0 * scale
	# 圆形宝石（亮度混合：向白色靠拢）
	var draw_color := Color(
		color.r + (1.0 - color.r) * brightness,
		color.g + (1.0 - color.g) * brightness,
		color.b + (1.0 - color.b) * brightness,
		alpha
	)
	_draw_circle(cx, cy, radius, draw_color)
	
	# 高光
	_draw_circle(cx - 2.0 * scale, cy - 2.0 * scale, radius * 0.5, Color(1.0, 1.0, 1.0, 0.3 * alpha))
	
	# Emoji
	var emoji: String = GEM_EMOJI.get(gem_type, "💎")
	_draw_text_with_shadow(emoji, cx, cy, Color(1.0, 1.0, 1.0, alpha), 14.0)

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
	_draw_restore()
	var is_win: bool = _battle != null and _battle.battle_result == "win"
	var t: float = _battle_end_overlay_timer
	var fade: float = clampf(t / 0.22, 0.0, 1.0)
	var panel_alpha: float = clampf((t - 0.12) / 0.28, 0.0, 1.0)
	var banner_y: float = DESIGN_H / 2.0 - 142.0
	
	draw_rect(Rect2(0, 0, DESIGN_W, DESIGN_H), Color(0.0, 0.0, 0.0, 0.66 * fade))
	
	if is_win:
		var burst_tex := _get_texture(BATTLE_RESULT_OVERLAY_ASSETS["victory_burst"])
		_draw_texture_centered(burst_tex, Vector2(DESIGN_W / 2.0, DESIGN_H / 2.0 - 100.0), Vector2(250.0, 176.0), 0.78 * fade)
		var confetti_tex := _get_texture(BATTLE_RESULT_OVERLAY_ASSETS["confetti"])
		_draw_texture_fit(confetti_tex, Rect2(16.0, 88.0, 343.0, 229.0), 0.78 * fade)
	else:
		var smoke_tex := _get_texture(BATTLE_RESULT_OVERLAY_ASSETS["defeat_smoke"])
		_draw_texture_fit(smoke_tex, Rect2(-50.0, DESIGN_H / 2.0 - 55.0, 475.0, 154.0), 0.92 * fade)
	
	var panel_tex := _get_texture(BATTLE_RESULT_OVERLAY_ASSETS["panel"])
	_draw_texture_centered(panel_tex, Vector2(DESIGN_W / 2.0, DESIGN_H / 2.0 + 34.0), Vector2(306.0, 168.0), panel_alpha)
	
	var banner_path: String = BATTLE_RESULT_OVERLAY_ASSETS["victory_banner"] if is_win else BATTLE_RESULT_OVERLAY_ASSETS["defeat_banner"]
	var banner_tex := _get_texture(banner_path)
	_draw_texture_centered(banner_tex, Vector2(DESIGN_W / 2.0, banner_y), Vector2(280.0, 130.0), fade)
	
	var title_text := "胜利" if is_win else "失败"
	var title_color: Color = C["gold"] if is_win else Color(0.78, 0.78, 0.86)
	_draw_text_with_shadow(title_text, DESIGN_W / 2.0, banner_y + 13.0, title_color, 26.0, true)
	
	var underline_tex := _get_texture(BATTLE_RESULT_OVERLAY_ASSETS["underline"])
	_draw_texture_centered(underline_tex, Vector2(DESIGN_W / 2.0, DESIGN_H / 2.0 - 10.0), Vector2(220.0, 39.0), 0.85 * panel_alpha)
	
	var state_text := "点击查看结算"
	var state_color: Color = C["text_muted"]
	if _capture_phase != "done" and _capture_phase != "":
		state_text = "收服判定中..."
		state_color = C["gold"]
	elif not _capture_result_text.is_empty():
		state_text = _capture_result_text.get("title", state_text)
		state_color = C["success"] if _capture_success else C["text_muted"]
	
	if not _capture_result_text.is_empty():
		var plaque_tex := _get_texture(BATTLE_RESULT_OVERLAY_ASSETS["capture_plaque"])
		_draw_texture_centered(plaque_tex, Vector2(DESIGN_W / 2.0, DESIGN_H / 2.0 + 33.0), Vector2(186.0, 66.0), panel_alpha)
		_draw_text_with_shadow(state_text, DESIGN_W / 2.0, DESIGN_H / 2.0 + 39.0, state_color, 15.0, true)
	else:
		_draw_text_with_shadow(state_text, DESIGN_W / 2.0, DESIGN_H / 2.0 + 28.0, state_color, 15.0, true)
	
	if _capture_phase == "done" or _capture_phase == "":
		var tap_tex := _get_texture(BATTLE_RESULT_OVERLAY_ASSETS["tap_strip"])
		_draw_texture_centered(tap_tex, Vector2(DESIGN_W / 2.0, DESIGN_H / 2.0 + 91.0), Vector2(188.0, 50.0), 0.86 * panel_alpha)
		_draw_text_with_shadow("点击继续", DESIGN_W / 2.0 + 6.0, DESIGN_H / 2.0 + 96.0, C["white"], 13.0)
	else:
		var button_tex := _get_texture(BATTLE_RESULT_OVERLAY_ASSETS["button_continue"])
		_draw_texture_centered(button_tex, Vector2(DESIGN_W / 2.0, DESIGN_H / 2.0 + 91.0), Vector2(170.0, 70.0), 0.65 * panel_alpha)
	_draw_restore()

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
	BattleBoardRendererScript.draw_locked_gems(self, b, _board_render_state())

func _draw_obstacles(b) -> void:
	BattleBoardRendererScript.draw_obstacles(self, b, _board_render_state())

func _draw_poison_fog(b) -> void:
	BattleBoardRendererScript.draw_poison_fog(self, b, _board_render_state())

func _draw_unlock_animations() -> void:
	BattleBoardRendererScript.draw_unlock_animations(self, _board, _board_render_state())

func _draw_poison_fog_anims() -> void:
	BattleBoardRendererScript.draw_poison_fog_anims(self, _board_render_state())

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
	BattleAnimationControllerScript.update_particle_list(_gem_particles, delta, 200.0)

func _update_obstacle_particles(delta: float) -> void:
	BattleAnimationControllerScript.update_particle_list(_obstacle_particles, delta, 300.0)

func _update_defeat_particles(delta: float) -> void:
	BattleAnimationControllerScript.update_particle_list(_defeat_explosions, delta, 180.0)

func _update_victory_particles(delta: float) -> void:
	BattleAnimationControllerScript.update_particle_list(_victory_particles, delta, 80.0)

func _spawn_defeat_particles(cx: float, cy: float, color: Color) -> void:
	# 生成 8-12 个粒子向外散射
	var count: int = 8 + randi() % 5
	for i in range(count):
		var angle: float = randf() * TAU
		var speed: float = 80.0 + randf() * 120.0
		_defeat_explosions.append({
			"x": cx,
			"y": cy,
			"vx": cos(angle) * speed,
			"vy": sin(angle) * speed - 50.0,
			"life": 0.4 + randf() * 0.2,
			"max_life": 0.4 + randf() * 0.2,
			"color": color,
			"size": 4.0 + randf() * 4.0
		})

func _spawn_victory_particles() -> void:
	# 全屏胜利粒子爆发
	var colors: Array[Color] = [C["gold"], C["success"], Color(1.0, 1.0, 1.0), C["primary"]]
	for i in range(30):
		var x: float = randf() * DESIGN_W
		var y: float = DESIGN_H + 20.0  # 从底部开始
		var vx: float = (randf() - 0.5) * 60.0
		var vy: float = -120.0 - randf() * 80.0  # 向上飞
		var color: Color = colors[randi() % colors.size()]
		_victory_particles.append({
			"x": x,
			"y": y,
			"vx": vx,
			"vy": vy,
			"life": 1.0 + randf() * 0.5,
			"max_life": 1.0 + randf() * 0.5,
			"color": color,
			"size": 3.0 + randf() * 3.0
		})

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

func _draw_defeat_particles() -> void:
	for p: Dictionary in _defeat_explosions:
		var progress: float = 1.0 - p["life"] / p["max_life"]
		var alpha: float = 1.0 - progress
		var size: float = p["size"] * (1.0 - progress * 0.5)
		var color: Color = Color(p["color"].r, p["color"].g, p["color"].b, alpha)
		_draw_circle(p["x"], p["y"], size, color)

func _draw_victory_particles() -> void:
	for p: Dictionary in _victory_particles:
		var progress: float = 1.0 - p["life"] / p["max_life"]
		var alpha: float = 1.0 - progress
		var size: float = p["size"] * (1.0 - progress * 0.4)
		var color: Color = Color(p["color"].r, p["color"].g, p["color"].b, alpha)
		_draw_circle(p["x"], p["y"], size, color)

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
	var path: String = MonsterArtDBScript.get_battle_portrait_path(monster_id)
	return _get_texture(path)

func _draw_texture_fit(tex: Texture2D, rect: Rect2, opacity: float = 1.0) -> void:
	if tex == null:
		return
	draw_texture_rect(tex, rect, false, Color(1, 1, 1, opacity))

func _draw_texture_cover(tex: Texture2D, rect: Rect2, opacity: float = 1.0) -> void:
	if tex == null:
		return
	var tex_size := tex.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	var scale: float = maxf(rect.size.x / tex_size.x, rect.size.y / tex_size.y)
	var src_size := rect.size / scale
	var source_pos := (tex_size - src_size) / 2.0
	draw_texture_rect_region(tex, rect, Rect2(source_pos, src_size), Color(1.0, 1.0, 1.0, opacity))

func _draw_texture_centered(tex: Texture2D, center: Vector2, size: Vector2, opacity: float = 1.0) -> void:
	if tex == null:
		return
	_draw_texture_fit(tex, Rect2(center - size / 2.0, size), opacity)

func _draw_element_glow() -> void:
	if _element_glow.get("timer", 0.0) <= 0.0:
		return
	var remaining: float = _element_glow["timer"]
	var max_time: float = 0.5
	var alpha: float = (remaining / max_time) * 0.15 if remaining <= max_time else 0.0
	var glow_color: Color = _element_glow.get("color", Color.WHITE)
	glow_color.a = alpha
	draw_rect(Rect2(0, 0, DESIGN_W, DESIGN_H), glow_color)

func _draw_element_ripple() -> void:
	if not _element_ripple.get("active", false) or _element_ripple.get("timer", 0.0) <= 0:
		return
	var duration: float = _element_ripple.get("duration", 0.6)
	var timer: float = _element_ripple.get("timer", 0.0)
	var progress: float = 1.0 - timer / duration
	var alpha: float = 0.4 * (1.0 - progress)
	var edge_width: float = 30.0 * (1.0 - progress)
	
	var ripple_color: Color = Color(
		_element_ripple.get("color", Color.WHITE).r,
		_element_ripple.get("color", Color.WHITE).g,
		_element_ripple.get("color", Color.WHITE).b,
		alpha
	)
	# 上边
	draw_rect(Rect2(0, 0, DESIGN_W, edge_width), ripple_color)
	# 下边
	draw_rect(Rect2(0, DESIGN_H - edge_width, DESIGN_W, edge_width), ripple_color)
	# 左边
	draw_rect(Rect2(0, 0, edge_width, DESIGN_H), ripple_color)
	# 右边
	draw_rect(Rect2(DESIGN_W - edge_width, 0, edge_width, DESIGN_H), ripple_color)

func _draw_special_transform() -> void:
	BattleBoardRendererScript.draw_special_transform(self, _board, _board_render_state())

func _draw_panel(x: float, y: float, w: float, h: float, color: Color, opacity: float = 1.0) -> void:
	var panel_tex := _get_texture("res://assets/images/battle/ui/ui_panel_dark_large.png")
	if panel_tex:
		_draw_texture_fit(panel_tex, Rect2(x, y, w, h), opacity)
	else:
		var panel_color := color
		panel_color.a *= opacity
		_draw_rounded_rect(x, y, w, h, 8.0, panel_color)

func _draw_text_with_shadow(text: String, x: float, y: float, color: Color, size: float, bold: bool = false) -> void:
	BattleUIFeedbackScript.draw_text_with_shadow(self, text, x, y, color, size, 200.0, HORIZONTAL_ALIGNMENT_CENTER)

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
	# 如果收服特效还在播放，等待完成
	if _capture_waiting_for_effect:
		return
	if _result_transitioning:
		return
	_result_transitioning = true
	
	var remaining: float = maxf(0.0, 0.72 - _battle_end_overlay_timer)
	if remaining > 0.0:
		await get_tree().create_timer(remaining).timeout
	else:
		await get_tree().create_timer(0.12).timeout
	
	if not is_inside_tree() or _battle == null:
		return
	
	var result: Dictionary = BattleFlowControllerScript.build_result_payload(_battle, {
		"success": _capture_success,
		"target": _capture_target,
		"result_text": _capture_result_text,
		"item_used": _capture_item_used
	})
	
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
	_defeat_explosions.clear()
	_victory_particles.clear()
	_defeated_enemies.clear()
	_screen_flash_timer = 0.0
	_attack_flash_timer = 0.0
	_special_transform_anim = {"row": -1, "col": -1, "type": "", "timer": 0.0, "duration": 0.5, "triggered": false}
	_element_ripple = {"active": false, "color": Color(), "timer": 0.0, "duration": 0.6}
	_element_glow = {"type": "", "timer": 0.0, "color": Color()}
	_combo_popup = {"combo": 0, "timer": 0.0, "phase": "", "scale": 0.5, "opacity": 0.0}
	_drag_preview = {"active": false, "direction": Vector2i.ZERO, "from_pos": Vector2.ZERO}
	_swipe_trail.clear()
	_battle_end_overlay_timer = 0.0
	_battle_end_overlay_started = false
	_battle_end_particles_spawned = false
	_result_transitioning = false
	# Phase 4: 清理收服特效
	if _capture_effect_node and is_instance_valid(_capture_effect_node):
		_capture_effect_node.queue_free()
		_capture_effect_node = null
	_capture_phase = ""
	_capture_waiting_for_effect = false

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

## ============================================
# 毒雾回合逻辑
## ============================================

func _process_poison_fog_turn() -> void:
	var result: Dictionary = BattleHazardRulesScript.process_poison_turn(_board, _battle)
	var new_tiles: Array = result.get("spread_tiles", [])
	if not new_tiles.is_empty():
		for t in new_tiles:
			_poison_fog_spread_anims.append({"row": t["row"], "col": t["col"], "x": t["x"], "y": t["y"], "timer": 0.0})
		_request_battle_fx({"type": "poison_spread", "tiles": new_tiles})
		_show_message("☠️ 毒雾扩散了！+%d格" % new_tiles.size())

	var total_fog_damage: int = result.get("total_damage", 0)
	if total_fog_damage <= 0:
		return
	for hit in result.get("hits", []):
		var team_index: int = hit.get("team_index", -1)
		var mx: float = 15.0 + float(team_index) * 120.0 + 55.0
		_floating_texts.append({
			"text": "-%d☠️" % hit.get("damage", 0),
			"x": mx, "y": 195.0,
			"color": STATUS_COLORS.get("poison", C["danger"]),
			"size": 16.0,
			"timer": 0.0,
			"duration": 0.8
		})
	_request_battle_fx({"type": "poison_damage", "hits": result.get("hits", []), "total_damage": total_fog_damage})
	_show_message("☠️ 毒雾伤害！%d格 × 3%% = %d" % [result.get("fog_count", 0), total_fog_damage])

## ============================================
# 消除时的毒雾清除 & 锁定宝石解锁
## ============================================

func _check_poison_fog_clears(matches: Array) -> void:
	"""消除宝石时检查是否清除了毒雾格子"""
	var clears: Array = BattleHazardRulesScript.clear_poison_for_gems(_board, matches)
	for clear in clears:
		clear["timer"] = 0.0
		_floating_texts.append({"text": "🧹清除!", "x": clear["x"], "y": clear["y"] - 15.0, "color": C["success"], "size": 14.0, "timer": 0.0, "duration": 0.8})
	if clears.size() > 0:
		_poison_fog_clear_anims.append_array(clears)
		_request_battle_fx({"type": "poison_clear", "tiles": clears})
		_show_message("🧹 毒雾被清除了！")

func _check_explosion_poison_fog(gems: Array) -> void:
	"""特殊消除（爆炸/炸弹/彩虹）也检查毒雾清除"""
	var clears: Array = BattleHazardRulesScript.clear_poison_for_gems(_board, gems)
	for clear in clears:
		_floating_texts.append({"text": "🧹", "x": clear["x"], "y": clear["y"] - 10.0, "color": C["success"], "size": 12.0, "timer": 0.0, "duration": 0.8})
	if not clears.is_empty():
		_request_battle_fx({"type": "poison_clear_special", "tiles": clears})

func _check_unlock_results(matches: Array, extra_gems: Array = []) -> void:
	"""消除后检查相邻锁定宝石解锁"""
	var unlock_results: Array = BattleHazardRulesScript.check_unlocks(_board, matches, extra_gems)
	for ur in unlock_results:
		if ur.get("fullyUnlocked", false):
			_unlock_animations.append({"row": ur["row"], "col": ur["col"], "timer": 0.0, "maxTimer": 0.6, "phase": "shatter"})
			_floating_texts.append({"text": "🔓解锁!", "x": ur["x"], "y": ur["y"] - 15.0, "color": C["gold"], "size": 16.0, "timer": 0.0, "duration": 0.8})
		else:
			_floating_texts.append({"text": "⛓️×%d" % ur.get("remainingHP", 1), "x": ur["x"], "y": ur["y"] - 10.0, "color": C["text_muted"], "size": 12.0, "timer": 0.0, "duration": 0.8})
	
	if unlock_results.any(func(ur): return ur.get("fullyUnlocked", false)):
		_request_battle_fx({"type": "unlock", "results": unlock_results})
		_show_message("🔓 宝石解锁！")
