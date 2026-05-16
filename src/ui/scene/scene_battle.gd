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

## 消除中宝石特效
var _eliminating_gems: Array[Dictionary] = []

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
	"text_muted": Color(0.5, 0.55, 0.65)
}

## 宝石颜色映射
const GEM_COLORS := {
	"fire": Color(1.0, 0.3, 0.1),
	"water": Color(0.1, 0.4, 1.0),
	"grass": Color(0.1, 0.8, 0.2),
	"thunder": Color(0.9, 0.8, 0.1),
	"light": Color(1.0, 0.9, 0.2)
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
		
		if drag_delta.length() > 20:
			var direction := ""
			if abs(drag_delta.x) > abs(drag_delta.y):
				direction = "left" if drag_delta.x < 0 else "right"
			else:
				direction = "up" if drag_delta.y < 0 else "down"
			_on_swipe(drag_pos.x, drag_pos.y, direction)
			get_viewport().set_input_as_handled()

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
	if matches.is_empty():
		if _board.cascade_count >= 2:
			_show_combo_popup(_board.cascade_count)
		if _check_battle_end():
			return
		_start_enemy_turn()
		return
	
	_state = BattleState.MATCHING
	_board.cascade_count += 1
	
	# 记录消除的宝石位置（动画用）
	_eliminating_gems.clear()
	for m in matches:
		if m is Dictionary and m.has("row") and m.has("col"):
			_eliminating_gems.append({
				"row": m["row"],
				"col": m["col"],
				"timer": 0.0,
				"duration": ELIMINATE_DURATION
			})
	
	# 等消除动画播放
	await get_tree().create_timer(ELIMINATE_DURATION).timeout
	_eliminating_gems.clear()
	
	var gem_counts: Dictionary = _board.remove_matches(matches)
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
	
	# 触发攻击震动
	_trigger_attack_shake()
	
	_apply_gravity()
	_state = BattleState.FALLING
	
	await get_tree().create_timer(FALL_DURATION).timeout
	_process_matches()

func _apply_gravity() -> void:
	if _board:
		_board.apply_gravity()

func _start_enemy_turn() -> void:
	_state = BattleState.ENEMY_TURN
	_show_message("敌方回合")
	
	if _battle == null:
		_state = BattleState.IDLE
		return
	var result: Dictionary = _battle.enemy_action()
	for action: Dictionary in result.get("actions", []):
		if action.get("damage", 0) > 0:
			_floating_texts.append({
				"text": "-%d" % action.get("damage", 0),
				"x": 80.0,
				"y": 225.0,
				"color": C["danger"],
				"size": 16.0,
				"timer": 0.0,
				"duration": 0.8
			})
	
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

func _trigger_attack_shake() -> void:
	_attack_shake_timer = 0.2
	_attack_flash_timer = 0.1
	_attack_shake_offset_x = 0.0

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
	
	# 更新攻击震动
	_update_attack_shake(delta)
	
	# 更新 HP 渐变动画
	_update_hp_display(delta)
	
	# 更新浮动文字
	_update_floating_texts(delta)
	
	# 更新宝石消除动画
	_update_gem_animations(delta)
	
	# 更新下落动画
	_update_fall_animations(delta)
	
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
	for i in range(_floating_texts.size() - 1, -1, -1):
		var ft: Dictionary = _floating_texts[i]
		ft["timer"] += dt
		if ft["timer"] >= ft.get("duration", 1.0):
			_floating_texts.remove_at(i)

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
	
	# 选中高亮
	_draw_selection()
	
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
	
	# 阶段切换提示
	_draw_phase_transition()
	
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
			if _board == null or _board.is_obstacle(row, col):
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
