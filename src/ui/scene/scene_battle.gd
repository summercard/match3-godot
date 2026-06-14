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
const BattleFeedbackOverlayScript = preload("res://src/ui/components/battle_feedback_overlay.gd")
const CaptureEffectScript = preload("res://src/battle/capture_effect.gd")
const ItemDBScript = preload("res://src/data/item_db.gd")
const FX_ROUND_FONT: Font = preload("res://assets/fonts/ZCOOLKuaiLe-Regular.ttf")

## 设计尺寸
const DESIGN_W := 375.0
const DESIGN_H := 667.0
const BATTLE_BOARD_CELL_SIZE := 39
const BATTLE_BOARD_Y := 300
const ATTACK_CUE_DURATION := 0.58
const ATTACK_IMPACT_DELAY := 0.24
const ATTACK_RECOVERY_DELAY := 0.16
const MATCH_CHAIN_TAIL_WAIT_MAX := 0.72
const HOTBAR_SLOT_COUNT := 3

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

## 玩家宠物弹动动画（主人定 2026-06-10：攻击时往前弹一下回位）
var _player_lunge_anims: Array[Dictionary] = []

## 弹道动画（主人定 2026-06-10：同属性颜色弹道飞向目标）
var _bullet_anims: Array[Dictionary] = []

## 攻击者弹性放大动画（★ 主人定 2026-06-11：小幅度弹性放大作为攻击主反馈）
## 每条记录：{isEnemy, index, timer, duration, maxDuration}，progress 0→1
var _attacker_elastic_anims: Array[Dictionary] = []

## 倒下过渡动画（★ 主人定 2026-06-11：先怪物图消失，再幽灵从下冲上渐显）
## 每条记录：{isEnemy, index, timer, duration, maxDuration}，覆盖 (hp<=0) 的瞬时切换
var _defeat_transitions: Array[Dictionary] = []

## 攻击观察提示：高亮攻击者、目标和弹道方向
var _attack_cues: Array[Dictionary] = []
var _suppress_enemy_attack_signal_visuals := false

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
const ELIMINATE_PHASE1: float = 0.12  # 阶段1：果冻弹起
const ELIMINATE_PHASE2: float = 0.18  # 阶段2：回缩淡出
const ELIMINATE_DURATION: float = ELIMINATE_PHASE1 + ELIMINATE_PHASE2  # 总时长 0.30s

## 宝石下落动画
var _falling_gems: Array[Dictionary] = []  # [{row, col, from_y, to_y, timer, duration}]
const FALL_DURATION: float = 0.42

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
const OBSTACLE_PARTICLE_LIMIT: int = 96

## 道具使用瞬态特效
var _item_use_effects: Array[Dictionary] = []  # [{kind, x, y, timer, duration, color, ...}]
const ITEM_USE_EFFECT_LIMIT: int = 24

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
var _capture_target: Dictionary = {}         # 收服目标精灵
var _capture_result_text: Dictionary = {}    # 收服结果文本
var _capture_item_used: Dictionary = {}      # 使用的捕获道具
var _capture_window: Dictionary = {}         # 本场用于结算的捕捉窗口
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

## 道具快捷栏（Phase 14）
var _hotbar_items: Array[Dictionary] = []       # [{id, count}, ...] 最多3个
var _capture_slot_items: Array = []
var _selected_hotbar_slot: int = -1             # 当前选中的格子索引
var _pending_hotbar_slot: int = -1
var _auto_capture_enabled: bool = false
var _equipped_capture_item_id: String = ""
var _equipped_battle_item_ids: Array = []

## 关卡数据
var _stage_data: Dictionary = {}
var _stage_id: String = ""
var _input_test_only: bool = false

## 音频辅助（直接走 autoload，避免每处重复 get_node）
func _am() -> Node:
	return get_node_or_null("/root/AudioManager")

func _sfx(key: String) -> void:
	var am := _am()
	if am != null and am.has_method("play_sfx"):
		am.call("play_sfx", key)

func _sfx_combo(level: int) -> void:
	var am := _am()
	if am != null and am.has_method("play_combo"):
		am.call("play_combo", level)

func _sfx_attack_by_element(element: String) -> void:
	var am := _am()
	if am != null and am.has_method("play_attack_by_element"):
		am.call("play_attack_by_element", element)

func _sfx_match_by_element(element: String) -> void:
	var am := _am()
	if am != null and am.has_method("play_match_by_element"):
		am.call("play_match_by_element", element)

## 美术资源
var _art_assets: Dictionary = {}
var _art_ready: bool = false
var _storage: Node = null
var _texture_cache: Dictionary = {}
var _feedback_overlay: Control = null

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
	"fire": "火",
	"water": "水",
	"grass": "叶",
	"thunder": "雷",
	"light": "光"
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
	"fire": "res://assets/images/ui/gems/battle_gem_fire.png",
	"water": "res://assets/images/ui/gems/battle_gem_water.png",
	"grass": "res://assets/images/ui/gems/battle_gem_grass.png",
	"thunder": "res://assets/images/ui/gems/battle_gem_thunder.png",
	"light": "res://assets/images/ui/gems/battle_gem_light.png"
}

const BATTLE_BG_PATH := "res://assets/images/maps/backgrounds/battle_garden_ruins_bg.png"

const BATTLE_UI_ASSETS := {
	"toast_panel": "res://assets/images/ui/panels/battle_ui_battle_toast_panel.png",
	"combo_banner": "res://assets/images/ui/panels/battle_ui_combo_banner.png",
	"top_scrim": "res://assets/images/ui/panels/battle_ui_top_scrim.png",
	"turn_badge": "res://assets/images/ui/icons/battle_ui_turn_badge.png",
	"board_frame": "res://assets/images/ui/misc/battle_ui_board_frame.png",
	"board_cell": "res://assets/images/ui/misc/battle_ui_board_cell.png",
	"footer_panel": "res://assets/images/ui/panels/battle_ui_footer_panel.png",
	"capture_toggle_off": "res://assets/images/ui/buttons/battle_ui_capture_toggle_off.png",
	"capture_toggle_on": "res://assets/images/ui/buttons/battle_ui_capture_toggle_on.png",
	"item_slot": "res://assets/images/ui/slots/battle_ui_item_slot.png",
	"item_slot_selected": "res://assets/images/ui/slots/battle_ui_item_slot_selected.png",
	"capture_slot": "res://assets/images/ui/slots/battle_ui_capture_slot.png",
	"item_capture_ball": "res://assets/images/ui/icons/items_new_icon_capture_ball.png",
	"item_capture_ball_plus": "res://assets/images/ui/icons/items_new_icon_capture_ball_plus.png",
	"item_hp_potion": "res://assets/images/ui/icons/items_new_icon_hp_potion.png",
	"item_exp_crystal": "res://assets/images/ui/icons/items_new_icon_exp_crystal.png",
	"item_focus_crystal": "res://assets/images/ui/icons/battle_icon_focus_crystal.png",
	"item_stone_earth": "res://assets/images/ui/gems/items_new_icon_evolution_stone_earth.png",
	"item_stone_light": "res://assets/images/ui/gems/items_new_icon_evolution_stone_light.png",
	"item_stone_thunder": "res://assets/images/ui/gems/items_new_icon_evolution_stone_thunder.png",
	"item_stone_water": "res://assets/images/ui/gems/items_new_icon_evolution_stone_water.png",
	"item_rock_hammer": "res://assets/images/ui/icons/battle_icon_rock_hammer.png",
	"item_guard_charm": "res://assets/images/ui/icons/battle_icon_guard_charm.png",
	"item_board_reset": "res://assets/images/ui/icons/battle_icon_board_reset.png",
	"item_absorb_shield": "res://assets/images/ui/icons/battle_icon_absorb_shield.png",
	"item_gem_type_shift": "res://assets/images/ui/icons/battle_icon_gem_type_shift.png",
	"hp_frame": "res://assets/images/ui/bars/battle_ui_hp_frame.png",
	"hp_frame_overlay": "res://assets/images/ui/bars/battle_ui_hp_frame_overlay.png",
	"hp_fill_green": "res://assets/images/ui/bars/battle_ui_hp_fill_green.png",
	"hp_fill_red": "res://assets/images/ui/bars/battle_ui_hp_fill_red.png",
	"hp_fill_blue": "res://assets/images/ui/bars/battle_ui_hp_fill_blue.png",
	"hp_fill_gold": "res://assets/images/ui/bars/battle_ui_hp_fill_gold.png"
}

const BATTLE_FX_ASSETS := {
	"damage_plate": "res://assets/images/effects/battle_fx_damage_plate.png",
	"critical_plate": "res://assets/images/effects/battle_fx_critical_plate.png",
	"heal_plate": "res://assets/images/effects/battle_fx_heal_plate.png",
	"combo_word": "res://assets/images/effects/battle_fx_combo_word.png",
	"damage_digits": "res://assets/images/effects/battle_fx_damage_digits.png",
	"shield_ring": "res://assets/images/effects/battle_fx_shield_ring.png",
	"heal_ring": "res://assets/images/effects/battle_fx_heal_ring.png",
	"charge_aura": "res://assets/images/effects/battle_fx_charge_aura.png",
	"stage_ring_cyan": "res://assets/images/effects/battle_fx_stage_ring_cyan.png",
	"stage_ring_green": "res://assets/images/effects/battle_fx_stage_ring_green.png",
	"stage_ring_fire": "res://assets/images/effects/battle_fx_stage_ring_fire.png",
	"stage_ring_void": "res://assets/images/effects/battle_fx_stage_ring_void.png",
	"selected_cell": "res://assets/images/effects/battle_fx_selected_cell.png",
	"gem_pop": "res://assets/images/effects/battle_fx_gem_pop.png"
}

const BATTLE_RESULT_OVERLAY_ASSETS := {
	"victory_banner": "res://assets/images/ui/panels/battle_flow_new_ui_battle_victory_plaque.png",
	"defeat_banner": "res://assets/images/ui/panels/battle_flow_new_ui_battle_victory_plaque.png",
	"panel": "res://assets/images/ui/panels/battle_flow_new_ui_panel_large.png",
	"button_continue": "res://assets/images/ui/buttons/battle_flow_new_ui_battle_continue_button.png",
	"capture_plaque": "res://assets/images/ui/panels/battle_flow_new_ui_capture_status_plaque.png",
	"tap_strip": "res://assets/images/ui/buttons/battle_flow_new_ui_battle_continue_button.png",
	"victory_burst": "res://assets/images/effects/battle_flow_new_fx_golden_burst.png"
}

# === 战局结束弹窗（胜利/失败）入场动画（参考胜利界面奖励槽节奏）===
# 元素依次进入：背景遮罩 → 爆发光晕 → 主横幅 + 标题 → 面板 → 收服状态 → 点击条
# 总时长约束 ≤ 0.72s（_go_to_result 等待时长）
const BATTLE_END_BG_START := 0.00
const BATTLE_END_BG_DURATION := 0.18
const BATTLE_END_BURST_START := 0.04
const BATTLE_END_BURST_DURATION := 0.32
const BATTLE_END_BURST_SCALE_START := 0.70
const BATTLE_END_BURST_OFFSET_Y := 12.0
const BATTLE_END_BANNER_START := 0.08
const BATTLE_END_BANNER_DURATION := 0.28
const BATTLE_END_BANNER_SCALE_START := 0.80
const BATTLE_END_BANNER_OFFSET_Y := -22.0
const BATTLE_END_PANEL_START := 0.14
const BATTLE_END_PANEL_DURATION := 0.24
const BATTLE_END_PANEL_SCALE_START := 0.92
const BATTLE_END_UNDERLINE_START := 0.28
const BATTLE_END_UNDERLINE_DURATION := 0.24
const BATTLE_END_PLAQUE_START := 0.36
const BATTLE_END_PLAQUE_DURATION := 0.22
const BATTLE_END_PLAQUE_SCALE_START := 0.78
const BATTLE_END_TAP_START := 0.46
const BATTLE_END_TAP_DURATION := 0.22
const BATTLE_END_TAP_SCALE_START := 0.85
const BATTLE_END_TAP_OFFSET_Y := 10.0
# 弹窗入场总时长
const BATTLE_END_TOTAL_DURATION := 0.70

## 宝石 TextureRect 缓存
var _gem_icon_pool: Array[TextureRect] = []

func _ready() -> void:
	instance = self
	set_process_input(true)
	mouse_filter = Control.MOUSE_FILTER_STOP
	if not _uses_editable_gui():
		_add_background(BATTLE_BG_PATH)
	_ensure_feedback_overlay()

func _uses_editable_gui() -> bool:
	return false

func _uses_editable_battle_end_overlay() -> bool:
	return false

func _ensure_feedback_overlay() -> void:
	if _feedback_overlay != null and is_instance_valid(_feedback_overlay):
		return
	_feedback_overlay = BattleFeedbackOverlayScript.new()
	_feedback_overlay.name = "TopFeedbackOverlay"
	_feedback_overlay.set("owner_scene", self)
	_feedback_overlay.z_index = 3000
	_feedback_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_feedback_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_feedback_overlay)

func init(data: Dictionary = {}) -> void:
	var stage_data = data.get("stageData", null)
	var stage_id = data.get("stageId", "stage_1_1")
	_input_test_only = data.get("inputTestOnly", false)

	# 进入战斗：切到 battle BGM
	var am := get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("play_bgm"):
		am.call("play_bgm", "bgm_battle")

	_selected_gem = Vector2i(-1, -1)
	_hit_flashes = []
	_fall_messages = []
	_player_lunge_anims = []
	_bullet_anims = []
	_attack_cues = []
	_suppress_enemy_attack_signal_visuals = false
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
	_board.cell_size = BATTLE_BOARD_CELL_SIZE
	_board.offset_x = int((DESIGN_W - _board.cols * _board.cell_size) / 2.0)
	_board.offset_y = BATTLE_BOARD_Y
	
	if _stage_data.has("obstacles"):
		_board.set_obstacles(_stage_data.get("obstacles", []))
		_board.init_board()
	if _stage_data.has("lockedGems"):
		_board.set_locked_gems(_stage_data.get("lockedGems", []))
	if _stage_data.has("poisonFog"):
		_board.set_poison_fog(_stage_data.get("poisonFog", {}))
	
	var player_level := 5
	var player_team_ids: Array = ["monster_001", "monster_002", "monster_003"]
	var player_team_units: Array = []
	if _storage:
		var player: Dictionary = _storage.load_player()
		player_level = maxi(player.get("level", 1), 5)
		if _storage.has_method("get_team_battle_stats"):
			player_team_units = _storage.get_team_battle_stats()
		if player_team_units.is_empty():
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
	if not player_team_units.is_empty() and _battle.has_method("init_with_player_team"):
		_battle.init_with_player_team(player_team_units, enemy_ids, player_level, enemy_level, _stage_data, _stage_id)
	else:
		_battle.init(player_team_ids, enemy_ids, player_level, enemy_level, _stage_data, _stage_id)
	
	# 连接 BOSS 技能信号
	if not _battle.enemy_skill_action.is_connected(_on_enemy_skill_action):
		_battle.enemy_skill_action.connect(_on_enemy_skill_action)

	# 伤害视觉由消除/技能流程统一渲染，避免 damage_dealt 信号再重复追加浮动数字。

	# 连接敌人攻击信号（用于伤害数字队列）
	if not _battle.enemy_attacked.is_connected(_on_enemy_attacked):
		_battle.enemy_attacked.connect(_on_enemy_attacked)

	# 连接技能就绪信号
	if not _battle.skill_ready.is_connected(_on_skill_ready):
		_battle.skill_ready.connect(_on_skill_ready)

	# 精英关卡：应用eliteMultiplier加成敌人属性
	var elite_mult: float = _stage_data.get("eliteMultiplier", 0.0)
	if elite_mult > 0.0:
		for enemy: Dictionary in _battle.enemies:
			if enemy and not enemy.is_empty():
				enemy["maxHP"] = int(enemy.get("maxHP", 0) * elite_mult)
				enemy["hp"] = enemy["maxHP"]
				enemy["atk"] = int(enemy.get("atk", 0) * elite_mult)
				enemy["def"] = int(enemy.get("def", 0) * elite_mult)
	
	var battle_hint := str(_stage_data.get("battleHint", ""))
	_show_message(battle_hint if not battle_hint.is_empty() else _stage_data.get("name", "战斗开始！"))
	_load_capture_preferences()
	_load_hotbar_items()

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

	# 优先检测道具快捷栏点击
	if _pending_hotbar_slot >= 0:
		_try_tap_item_confirm_popup(x, y)
		return

	if _try_tap_hotbar(x, y):
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
		_sfx("ui_tile_select_leaf")
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
	# 玩家技能释放音（按释放者元素选攻击音）
	var attacker_idx: int = _find_player_index(result.get("attacker", ""))
	if attacker_idx >= 0 and _battle != null and attacker_idx < _battle.player_team.size():
		var attacker: Dictionary = _battle.player_team[attacker_idx]
		_sfx_attack_by_element(str(attacker.get("element", "fire")))
	var skill_name: String = result.get("skill_name", result.get("skillName", "技能"))
	var attacker: String = result.get("attacker", "伙伴")
	var damage: int = result.get("remaining_damage", result.get("remainingDamage", result.get("damage", 0)))
	var shield_absorbed: int = result.get("shield_absorbed", result.get("shieldAbsorbed", 0))
	var target_idx: int = result.get("target_index", result.get("targetIndex", -1))
	if target_idx < 0:
		target_idx = _find_enemy_index(result.get("target", ""))
	var skill_element := str(result.get("element", "fire"))
	if attacker_idx >= 0 and target_idx >= 0:
		_start_attack_cue(false, attacker_idx, true, target_idx, skill_element, "%s 释放 %s → %s" % [attacker, skill_name, result.get("target", "敌人")], true)
	_show_message("%s 释放 %s！" % [attacker, skill_name])
	_screen_flash_timer = 0.18
	_trigger_attack_shake()
	var popup_x: float = DESIGN_W / 2.0
	var popup_y: float = 95.0
	if target_idx >= 0:
		popup_x = 25.0 + target_idx * 120.0 + 55.0
		popup_y = 80.0
		_hit_flashes.append({"isEnemy": true, "monsterIndex": target_idx, "timer": 0.42, "maxTimer": 0.42})
	if damage > 0:
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
	for effect: Dictionary in result.get("effect_logs", result.get("effectLogs", [])):
		var kind := str(effect.get("kind", ""))
		if kind == "heal":
			_sfx("battle_heal_leaf_bubble")
		elif kind == "guard":
			_sfx("battle_shield_soft_bloom")
		if kind == "heal" or kind == "guard":
			var player_idx := _find_player_index(str(effect.get("target_id", "")), str(effect.get("target", "")))
			var card_rect := _get_player_card_rect(player_idx) if player_idx >= 0 else Rect2(DESIGN_W / 2.0 - 55.0, 187.0, 110.0, 58.0)
			var text := "+%d" % int(effect.get("amount", 0)) if kind == "heal" else "护-%d%%" % int(round(float(effect.get("reduction", 0.0)) * 100.0))
			_floating_texts.append({
				"text": text,
				"x": card_rect.position.x + card_rect.size.x / 2.0,
				"y": card_rect.position.y + 12.0,
				"color": C["heal_green"] if kind == "heal" else C["shield"],
				"size": 16.0,
				"timer": 0.0,
				"duration": 0.9
			})
		elif kind == "weaken":
			var weaken_idx := int(effect.get("target_index", target_idx))
			var wx := 25.0 + weaken_idx * 120.0 + 55.0 if weaken_idx >= 0 else popup_x
			_floating_texts.append({
				"text": "缚-%d%%" % int(round(float(effect.get("reduction", 0.0)) * 100.0)),
				"x": wx,
				"y": 100.0,
				"color": GEM_COLORS["grass"],
				"size": 15.0,
				"timer": 0.0,
				"duration": 0.9
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
		_sfx("ui_invalid_move_bouncy")
		return
	_sfx("ui_tile_swap_soft")
	var match_result: Dictionary = _board.find_matches()
	if match_result.get("gems", []).is_empty():
		_board.swap(r1, c1, r2, c2)
		_state = BattleState.IDLE
		_show_message("无效交换")
		_sfx("ui_invalid_move_bouncy")
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
		if _check_battle_end():
			return
		await _wait_for_player_resolution_tail()
		if _check_battle_end():
			return
		_start_enemy_turn()
		return
	
	_state = BattleState.MATCHING
	_board.cascade_count += 1
	if _board.cascade_count >= 2:
		_show_combo_popup(_board.cascade_count)
		_sfx_combo(_board.cascade_count)

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

	# ===== 消除音：按首个消除宝石的元素选音效；高连锁/高消除数给更重的 5 消版本 =====
	var first_gem: Dictionary = (matches[0] if not matches.is_empty() else {})
	var first_type: String = str(first_gem.get("type", "fire"))
	_sfx_match_by_element(first_type)
	if total_elim >= 5 or _board.cascade_count >= 4:
		_sfx("powerup_burst_soft")
	if not explosion_gems.is_empty() or not bomb_gems.is_empty() or not rainbow_gems.is_empty():
		_sfx("powerup_created_star")

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
		var log_effective: bool = bool(log.get("isEffective", log.get("is_effective", false)))
		var log_weak: bool = bool(log.get("isWeak", log.get("is_weak", false)))
		var log_target: String = log.get("target", "")
		var log_died: bool = bool(log.get("targetDied", log.get("target_died", false)))
		var log_attacker: String = str(log.get("attacker", "伙伴"))
		var log_element: String = str(log.get("element", "fire"))
		var attacker_idx := _find_player_index(log_attacker)
		var target_idx := _find_enemy_index(log_target)
		if attacker_idx >= 0 and target_idx >= 0:
			_sfx_attack_by_element(log_element)
			await _play_attack_observation(false, attacker_idx, true, target_idx, log_element, "%s → %s" % [log_attacker, log_target], log_effective)
		
		# 克制提示
		if log_effective:
			_show_message("效果拔群！")
		elif log_weak:
			_show_message("效果不佳...")
		
		# 克制伤害颜色/大小
		var popup_color: Color = C["fire"] if log_effective else (C["text_muted"] if log_weak else C["gold"])
		var popup_size: float = 24.0 if log_effective else (12.0 if log_weak else 18.0)
		
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
				_hit_flashes.append({"isEnemy": true, "monsterIndex": target_idx, "timer": 0.4, "maxTimer": 0.4})
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
			_hit_flashes.append({"isEnemy": true, "monsterIndex": 0, "timer": 0.4, "maxTimer": 0.4})
			_trigger_attack_shake()
		if attacker_idx >= 0 and target_idx >= 0:
			await get_tree().create_timer(ATTACK_RECOVERY_DELAY).timeout
	
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
		var new_enemies: Array = _battle.execute_phase_transition(phase_transition)
		if not new_enemies.is_empty():
			var boss_name: String = new_enemies[0].get("name", "BOSS") if new_enemies[0] != null else "BOSS"
			_show_message("%s 进入激战状态！" % boss_name)
			_phase_transition_state = {
				"phase": phase_transition.get("phase", 1),
				"enemies": new_enemies,
				"timer": 1.5,
				"boss_name": boss_name
			}
			_screen_flash_timer = 0.3
			_shake_timer = 0.3
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

func _wait_for_player_resolution_tail() -> void:
	await get_tree().process_frame
	var waited := 0.0
	while _has_pending_player_resolution_fx() and waited < MATCH_CHAIN_TAIL_WAIT_MAX:
		await get_tree().create_timer(0.03).timeout
		waited += 0.03

func _has_pending_player_resolution_fx() -> bool:
	return (
		not _falling_gems.is_empty()
		or not _hit_flashes.is_empty()
		or not _attack_cues.is_empty()
		or not _bullet_anims.is_empty()
		or not _player_lunge_anims.is_empty()
		or not _attacker_elastic_anims.is_empty()
		or not _damage_popup_queue.is_empty()
		or _attack_shake_timer > 0.0
	)

func _apply_gravity() -> void:
	if _board:
		var movements: Array = _board.apply_gravity()
		_falling_gems.clear()
		var cell_size := float(_board.cell_size)
		for move: Dictionary in movements:
			var from_row := int(move.get("fromRow", 0))
			var to_row := int(move.get("toRow", 0))
			var col := int(move.get("col", 0))
			var distance := absf(float(to_row - from_row))
			var delay := clampf(float(col) * 0.012 + maxf(0.0, distance - 1.0) * 0.018, 0.0, 0.10)
			_falling_gems.append({
				"type": str(move.get("type", "")),
				"row": to_row,
				"col": col,
				"from_y": float(_board.offset_y) + float(from_row) * cell_size + cell_size / 2.0,
				"to_y": float(_board.offset_y) + float(to_row) * cell_size + cell_size / 2.0,
				"timer": 0.0,
				"delay": delay,
				"duration": FALL_DURATION - 0.08,
				"is_new": bool(move.get("isNew", false))
			})

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
			_show_message("十字爆裂！")
			_trigger_element_glow("fire", Color(1.0, 0.4, 0.0, 0.15))
			_trigger_element_ripple("fire", Color(1.0, 0.4, 0.0))
			for enh in matches:
				var cx: float = float(_board.offset_x + enh["col"] * cell_size + cell_size / 2.0)
				var cy: float = float(_board.offset_y + enh["row"] * cell_size + cell_size / 2.0)
				_floating_texts.append({"text": "爆裂", "x": cx, "y": cy - 10.0, "color": C["gold"], "size": 15.0, "timer": 0.0, "duration": 0.8, "critical": true})
		
		"bomb":
			# 炸弹消除：延迟 150ms 后播放
			_trigger_attack_shake()
			_trigger_element_glow("fire", Color(1.0, 0.4, 0.0, 0.15))
			for bomb in matches:
				var cx: float = float(_board.offset_x + bomb["col"] * cell_size + cell_size / 2.0)
				var cy: float = float(_board.offset_y + bomb["row"] * cell_size + cell_size / 2.0)
				var shape: String = bomb.get("shape", "?")
				_floating_texts.append({"text": "轰!", "x": cx, "y": cy - 10.0, "color": C["gold"], "size": 16.0, "timer": 0.0, "duration": 0.8, "critical": true})
				_show_message("%s形范围弹跳！" % shape)
		
		"rainbow":
			# 彩虹消除：延迟 200ms 后播放，全屏闪光 0.4s
			_rainbow_flash = RAINBOW_FLASH_DURATION
			_trigger_attack_shake()
			_trigger_element_glow("rainbow", Color(1.0, 0.95, 0.9, 0.2))
			for rainbow in matches:
				_show_message("虹光清屏！")
				var match_cells: Array = rainbow.get("matchCells", rainbow.get("cells", []))
				if match_cells.size() > 0:
					var cx: float = float(_board.offset_x + match_cells[0]["col"] * cell_size + cell_size / 2.0)
					var cy: float = float(_board.offset_y + match_cells[0]["row"] * cell_size + cell_size / 2.0)
					_floating_texts.append({"text": "清屏", "x": cx, "y": cy - 15.0, "color": C["gold"], "size": 17.0, "timer": 0.0, "duration": 1.0, "critical": true})
	
	# 通用：每个受影响宝石的粒子 + 消除动画
	var half_cell: float = float(_board.cell_size) / 2.0 if _board != null else 21.0
	for g in gems:
		var gem_type: String = g.get("type", "")
		spawn_eliminate_particles(g["row"], g["col"], gem_type)
		
		_eliminating_gems.append({"row": g["row"], "col": g["col"], "timer": 0.0, "duration": ELIMINATE_DURATION})
		
		var badge_text: String = "弹!" if type == "explosion" else ("跳!" if type == "bomb" else "亮!")
		var badge_size: float = 11.5
		var gem_y: float = g.get("y", half_cell)
		_floating_texts.append({
			"text": badge_text,
			"x": g.get("x", 0.0),
			"y": gem_y - half_cell,
			"color": GEM_COLORS.get(gem_type, C["white"]),
			"size": badge_size,
			"timer": 0.0,
			"duration": 0.8
		})

## 状态效果Emoji映射
const STATUS_EMOJI := {"burn": "灼", "freeze": "冰", "poison": "毒", "stun": "晕"}

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
	_suppress_enemy_attack_signal_visuals = true
	var result: Dictionary = _battle.enemy_action()
	_suppress_enemy_attack_signal_visuals = false
	
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
			_hit_flashes.append({"isEnemy": true, "monsterIndex": enemy_idx, "timer": 0.4, "maxTimer": 0.4})
		
		elif log_type == "stun":
			_show_message("%s 眩晕了，无法行动！" % enemy_name)
		
		elif log_type == "freeze":
			_show_message("%s 冰冻中，ATK降低30%%！" % enemy_name)
		
		elif log_type.ends_with("_end"):
			_show_message(log.get("message", ""))
	
	# 处理DoT击杀提示
	for kill in result.get("dot_kills", []):
		var idx: int = kill.get("enemy_index", -1)
		var name: String = kill.get("enemy_name", "???")
		_fall_messages.append({"text": "%s 被状态效果击杀！" % name, "timer": 1.5})
	
	for action: Dictionary in result.get("actions", []):
		# 蓄力回合：只显示蓄力提示，不显示伤害
		if action.get("is_charging", false):
			_show_message("%s 正在蓄力..." % action.get("attacker", ""))
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
			var enemy_idx: int = _find_enemy_index(action.get("attacker", ""))
			var action_element := str(action.get("element", "fire"))
			if enemy_idx >= 0 and target_idx >= 0:
				_sfx_attack_by_element(action_element)
				var attack_label := "%s → %s" % [action.get("attacker", "敌人"), action.get("target", "伙伴")]
				if action.get("is_charged", false):
					attack_label = "%s 蓄力攻击 → %s" % [action.get("attacker", "敌人"), action.get("target", "伙伴")]
				await _play_attack_observation(true, enemy_idx, false, target_idx, action_element, attack_label, action.get("is_charged", false))
			if target_idx >= 0:
				popup_x = 15.0 + target_idx * 120.0 + 55.0
				popup_y = 218.0
				_hit_flashes.append({"isEnemy": false, "monsterIndex": target_idx, "timer": 0.5, "maxTimer": 0.5})
			# 敌人攻击音（按敌人元素）
			_sfx("battle_player_hit_cushion")
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
			if int(action.get("guard_absorbed", 0)) > 0:
				_floating_texts.append({
					"text": "护-%d" % int(action.get("guard_absorbed", 0)),
					"x": popup_x,
					"y": popup_y + 16.0,
					"color": C["shield"],
					"size": 13.0,
					"timer": 0.0,
					"duration": 0.8
				})
			if action.get("shield_absorbed", false):
				_floating_texts.append({
					"text": "盾-吸收",
					"x": popup_x,
					"y": popup_y + 32.0,
					"color": C["shield"],
					"size": 14.0,
					"timer": 0.0,
					"duration": 0.9
				})
			if action.get("is_weakened", false):
				_show_message("%s 被束缚，伤害降低" % action.get("attacker", "敌人"))
			if enemy_idx >= 0 and target_idx >= 0:
				await get_tree().create_timer(ATTACK_RECOVERY_DELAY).timeout
	
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
		if _battle.battle_result == "win":
			if _auto_capture_enabled:
				_trigger_inline_capture()
			else:
				_skip_inline_capture()
		else:
			_trigger_inline_capture_miss()
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
		_sfx("battle_victory_fresh_fanfare")
	else:
		_slowmotion_timer = 0.0
		_sfx("battle_defeat_gentle")
		_sfx("player_ko_soft_fall")

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
	
	# 选择收服目标：优先使用本场创造过的最佳捕捉窗口
	var target_enemy: Dictionary = {}
	var target_window: Dictionary = {}
	var target_idx: int = -1
	var candidate: Dictionary = _battle.get_best_capture_candidate() if _battle.has_method("get_best_capture_candidate") else {}
	if not candidate.is_empty():
		target_enemy = candidate.get("enemy", {})
		target_window = candidate.get("window", {})
		target_idx = int(candidate.get("enemy_index", -1))
	if target_enemy.is_empty():
		var valid_enemies: Array = enemies.filter(func(e): return e != null and e.has("id"))
		if not valid_enemies.is_empty():
			target_enemy = valid_enemies[randi() % valid_enemies.size()]
			target_idx = enemies.find(target_enemy)
			target_window = CaptureSystem.calc_taming_window(
				float(target_enemy.get("hp", 0)),
				float(target_enemy.get("maxHP", 1))
			)
	
	if target_enemy.is_empty():
		_capture_phase = "done"
		return
	
	_capture_target = target_enemy
	_capture_window = target_window.duplicate(true)
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
		{
			"stage_id": _stage_id,
			"consecutive_fails": consecutive_fails,
			"taming_window": target_window
		}
	)
	
	# 消耗玩家预选的捕获道具；没有可用捕捉球时不进行空手判定
	var item_use: Dictionary = _consume_selected_capture_item()
	if not bool(item_use.get("ok", false)):
		_capture_success = false
		_capture_item_used = {}
		_capture_result_text = CaptureSystem.get_capture_skip_feedback(str(item_use.get("reason", "no_item")), {
			"target": target_enemy,
			"item_name": str(item_use.get("item_name", "捕捉球"))
		})
		_capture_phase = "done"
		_capture_waiting_for_effect = false
		_show_message(_capture_result_text.get("title", "未捕捉"))
		return
	var bonus: float = float(item_use.get("bonus", 0.0))
	prob = minf(0.95, prob + bonus)
	
	# 执行收服判定
	_capture_success = CaptureSystem.attempt_capture(prob)
	_capture_result_text = CaptureSystem.get_capture_result_text(prob, _capture_success, target_window, {
		"target": target_enemy,
		"item_used": _capture_item_used,
		"consecutive_fails": consecutive_fails
	})
	
	# 更新连续失败计数
	if _storage and _storage.has_method("load_player") and _storage.has_method("save_player"):
		var player: Dictionary = _storage.load_player()
		if _capture_success:
			player["captureFails"] = 0
		else:
			player["captureFails"] = consecutive_fails + 1
		_storage.save_player(player)
	
	# 计算精灵在屏幕上的位置（敌方区域）
	if target_idx < 0:
		for i in range(enemies.size()):
			if enemies[i] != null and enemies[i].get("id", "") == target_enemy.get("id", ""):
				target_idx = i
				break
	var center_pos := Vector2(DESIGN_W / 2.0, 125.0)
	if target_idx >= 0:
		center_pos = Vector2(15.0 + target_idx * 120.0 + 55.0, 125.0)
	
	# 播放 CaptureEffect
	_capture_effect_node = CaptureEffectScript.play_capture(self, _capture_success, center_pos)
	_capture_phase = "playing"
	_capture_waiting_for_effect = true
	_show_message(_capture_result_text.get("title", ""))

func _skip_inline_capture() -> void:
	_capture_success = false
	_capture_target = {}
	_capture_item_used = {}
	_capture_window = {}
	_capture_result_text = CaptureSystem.get_capture_skip_feedback("auto_off")
	_capture_phase = "done"
	_capture_waiting_for_effect = false

func _trigger_inline_capture_miss() -> void:
	if _battle == null:
		return
	_capture_success = false
	_capture_target = {}
	_capture_item_used = {}
	_capture_window = {}
	_capture_result_text = {
		"title": "MISS",
		"desc": "战斗失败，无法收服。"
	}

	var center_pos := Vector2(DESIGN_W / 2.0, 125.0)
	var enemies: Array = _battle.enemies
	for i in range(enemies.size()):
		var enemy: Dictionary = enemies[i]
		if enemy != null and enemy.get("hp", 0) > 0:
			center_pos = Vector2(15.0 + i * 120.0 + 55.0, 125.0)
			break

	_capture_effect_node = CaptureEffectScript.play_capture(self, false, center_pos)
	_capture_phase = "playing"
	_capture_waiting_for_effect = true
	_show_message(_capture_result_text.get("title", ""))

func _consume_selected_capture_item() -> Dictionary:
	"""消耗玩家预选的捕获道具，返回本次捕捉道具结果"""
	if not _storage or not _storage.has_method("load_inventory") or not _storage.has_method("use_item"):
		return {"ok": false, "reason": "storage_unavailable"}
	if _equipped_capture_item_id.is_empty():
		return {"ok": false, "reason": "no_item"}
	var inventory: Dictionary = _storage.load_inventory()
	if int(inventory.get(_equipped_capture_item_id, 0)) <= 0:
		var empty_def: Dictionary = ItemDB.get_item(_equipped_capture_item_id)
		return {"ok": false, "reason": "item_empty", "item_name": str(empty_def.get("name", "捕捉球"))}
	var item_def: Dictionary = ItemDB.get_item(_equipped_capture_item_id)
	if str(item_def.get("type", "")) != "capture":
		return {"ok": false, "reason": "invalid_item", "item_name": str(item_def.get("name", "道具"))}
	if _storage.use_item(_equipped_capture_item_id, 1):
		var bonus: float = float(item_def.get("effect", {}).get("captureBonus", 0.0))
		_capture_item_used = {
			"id": _equipped_capture_item_id,
			"bonus": bonus,
			"name": str(item_def.get("name", "捕获球"))
		}
		_load_hotbar_items()
		return {"ok": true, "bonus": bonus, "item": _capture_item_used.duplicate(true)}
	return {"ok": false, "reason": "item_empty", "item_name": str(item_def.get("name", "捕捉球"))}

## ============================================
# 消息与弹窗
## ============================================

func _show_message(text: String) -> void:
	_message_text = _clean_battle_fx_text(text)
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
	# ★ 主人定 2026-06-11：缩短震动（0.28→0.18），去掉白闪，攻击主反馈改由 attacker 弹性放大承担
	_attack_shake_timer = 0.18
	_attack_flash_timer = 0.0
	_attack_shake_offset_x = 0.0

# ★ 主人定 2026-06-11：清理同 combatant 的旧 elastic anim，避免快速连击时叠加
func _remove_elastic_anim(is_enemy: bool, index: int) -> void:
	for i in range(_attacker_elastic_anims.size() - 1, -1, -1):
		var entry: Dictionary = _attacker_elastic_anims[i]
		if bool(entry.get("isEnemy", false)) == is_enemy and int(entry.get("index", -1)) == index:
			_attacker_elastic_anims.remove_at(i)

# ★ 主人定 2026-06-11：检测新出现的倒下，登记进 _defeat_transitions
# 怪物图先消失（0.20s）→ 短暂空隙（0.10s）→ 幽灵从下冲上 + 渐显（0.40s）→ 稳定
# 总时长 0.70s
func _scan_new_defeats() -> void:
	if _battle == null:
		return
	for i in range(_battle.enemies.size()):
		var enemy: Dictionary = _battle.enemies[i]
		if enemy == null:
			continue
		if maxi(int(enemy.get("hp", 0)), 0) <= 0 and not _has_defeat_transition(true, i):
			_defeat_transitions.append({
				"isEnemy": true,
				"index": i,
				"timer": 0.70,
				"duration": 0.70,
				"maxDuration": 0.70,
			})
	for i in range(_battle.player_team.size()):
		var monster: Dictionary = _battle.player_team[i]
		if monster == null:
			continue
		if maxi(int(monster.get("hp", 0)), 0) <= 0 and not _has_defeat_transition(false, i):
			_defeat_transitions.append({
				"isEnemy": false,
				"index": i,
				"timer": 0.70,
				"duration": 0.70,
				"maxDuration": 0.70,
			})

func _has_defeat_transition(is_enemy: bool, index: int) -> bool:
	for entry in _defeat_transitions:
		if bool(entry.get("isEnemy", false)) == is_enemy and int(entry.get("index", -1)) == index:
			return true
	return false

func _tick_defeat_transitions(dt: float) -> void:
	for entry in _defeat_transitions:
		entry["timer"] = maxf(0.0, float(entry.get("timer", 0.0)) - dt)

func _start_attack_cue(attacker_is_enemy: bool, attacker_idx: int, target_is_enemy: bool, target_idx: int, element: String, label: String, charged: bool = false) -> void:
	if attacker_idx < 0 or target_idx < 0:
		return
	_attack_cues.append({
		"attacker_is_enemy": attacker_is_enemy,
		"attacker_index": attacker_idx,
		"target_is_enemy": target_is_enemy,
		"target_index": target_idx,
		"element": element,
		"label": label,
		"charged": charged,
		"timer": ATTACK_CUE_DURATION,
		"duration": ATTACK_CUE_DURATION
	})
	# ★ 主人定 2026-06-11：攻击者小幅度弹性放大（缩放到 1.08→0.97→1.0 持续 0.32s）
	# 适用于玩家和敌人；先清理掉同 combatant 的旧 anim 避免叠加
	_remove_elastic_anim(attacker_is_enemy, attacker_idx)
	_attacker_elastic_anims.append({
		"isEnemy": attacker_is_enemy,
		"index": attacker_idx,
		"timer": 0.32,
		"duration": 0.32,
		"maxDuration": 0.32,
	})
	if not attacker_is_enemy:
		_player_lunge_anims.append({
			"playerIndex": attacker_idx,
			"timer": ATTACK_CUE_DURATION,
			"duration": ATTACK_CUE_DURATION,
			"maxDuration": ATTACK_CUE_DURATION
		})

func _play_attack_observation(attacker_is_enemy: bool, attacker_idx: int, target_is_enemy: bool, target_idx: int, element: String, label: String, charged: bool = false) -> void:
	_start_attack_cue(attacker_is_enemy, attacker_idx, target_is_enemy, target_idx, element, label, charged)
	if not label.is_empty():
		_show_message(label)
	await get_tree().create_timer(ATTACK_IMPACT_DELAY).timeout

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
# 伤害数字信号处理
## ============================================

func _on_damage_dealt(damage_info: Dictionary) -> void:
	"""处理 BattleManager.damage_dealt 信号，显示浮动伤害数字"""
	var damage: int = damage_info.get("damage", 0)
	if damage <= 0:
		return

	var info_type: String = damage_info.get("type", "match")
	var is_critical: bool = damage_info.get("isEffective", false) or damage_info.get("is_effective", false)
	var is_weak: bool = damage_info.get("isWeak", false) or damage_info.get("is_weak", false)
	var target_name: String = damage_info.get("target", "")
	var attacker_name: String = damage_info.get("attacker", "")
	var target_idx: int = -1

	if info_type == "active_skill":
		target_idx = damage_info.get("targetIndex", damage_info.get("target_index", -1))
	else:
		target_idx = _find_enemy_index(target_name)

	# 颜色与大小分类
	var popup_color: Color = C["gold"]
	var popup_size: float = 20.0
	if is_critical:
		popup_color = C["fire"]
		popup_size = 26.0
	elif is_weak:
		popup_color = C["text_muted"]
		popup_size = 14.0

	# 位置计算
	var popup_x: float = DESIGN_W / 2.0
	var popup_y: float = 95.0
	if target_idx >= 0:
		popup_x = 25.0 + target_idx * 120.0 + 55.0
		popup_y = 80.0

	_floating_texts.append({
		"text": "-%d" % damage,
		"x": popup_x,
		"y": popup_y,
		"color": popup_color,
		"size": popup_size,
		"timer": 0.0,
		"duration": 0.9,
		"critical": is_critical
	})

	# 护盾吸收显示
	var shield_absorbed: int = damage_info.get("shieldAbsorbed", damage_info.get("shield_absorbed", 0))
	if shield_absorbed > 0:
		_floating_texts.append({
			"text": "盾-%d" % shield_absorbed,
			"x": popup_x,
			"y": popup_y + 18.0,
			"color": C["shield"],
			"size": 13.0,
			"timer": 0.0,
			"duration": 0.8
		})

	# 敌人受击闪烁
	if target_idx >= 0:
		_hit_flashes.append({"isEnemy": true, "monsterIndex": target_idx, "timer": 0.4, "maxTimer": 0.4})

	# ★ 主人定 2026-06-10：我方宠物弹动 + 同属性弹道
	if info_type != "active_skill":  # 主动技能已经有弹道，只补常规攻击
		var attacker_idx: int = _find_player_index(attacker_name)
		if attacker_idx >= 0:
			# 1) 玩家宠物往前弹一下回位（0.3s）
			_player_lunge_anims.append({
				"playerIndex": attacker_idx,
				"timer": 0.0,
				"duration": 0.3,
				"maxDuration": 0.3,
			})
			# 2) 同属性弹道 飞向目标
			if target_idx >= 0:
				var element: String = str(damage_info.get("element", "fire"))
				_bullet_anims.append({
					"playerIndex": attacker_idx,
					"targetIndex": target_idx,
					"element": element,
					"timer": 0.0,
					"duration": 0.4,
					"maxDuration": 0.4,
				})

func _on_enemy_attacked(action_info: Dictionary) -> void:
	"""处理 BattleManager.enemy_attacked 信号，显示敌人攻击伤害"""
	if _suppress_enemy_attack_signal_visuals:
		return
	var damage: int = action_info.get("damage", 0)
	if damage <= 0:
		return

	var is_charged: bool = action_info.get("is_charged", false)
	var dmg_size: float = 28.0 if is_charged else 16.0
	var dmg_color: Color = C["charged_attack"] if is_charged else C["danger"]
	var target_name: String = action_info.get("target", "")
	var target_idx: int = _find_player_index(target_name)

	var popup_x: float = 80.0
	var popup_y: float = 225.0 + _damage_popup_queue.size() * 20.0
	if target_idx >= 0:
		popup_x = 15.0 + target_idx * 120.0 + 55.0
		popup_y = 218.0
		_hit_flashes.append({"isEnemy": false, "monsterIndex": target_idx, "timer": 0.5, "maxTimer": 0.5})

	if _damage_popup_queue.size() < 5:
		_damage_popup_queue.append({
			"text": "-%d" % damage,
			"x": popup_x,
			"y": popup_y,
			"color": dmg_color,
			"size": dmg_size,
			"delay": _damage_popup_queue.size() * 0.1,
			"elapsed": 0.0,
			"duration": 0.8,
			"critical": is_charged
		})

func _on_skill_ready(monster: Dictionary) -> void:
	"""处理 BattleManager.skill_ready 信号，显示技能充能完成提示"""
	var monster_name: String = monster.get("name", "伙伴")
	var skill_name: String = monster.get("skill", {}).get("name", "技能")
	_show_message("%s 的 %s 充能完毕！" % [monster_name, skill_name])

	# 找到对应的玩家卡片位置
	var team: Array = _battle.player_team if _battle != null else []
	for i in range(team.size()):
		if team[i] != null and team[i].get("id", "") == monster.get("id", ""):
			var card_x: float = 20.0 + i * 120.0 + 55.0
			var card_y: float = 215.0
			_floating_texts.append({
				"text": "%s!" % skill_name,
				"x": card_x,
				"y": card_y,
				"color": C["gold"],
				"size": 16.0,
				"timer": 0.0,
				"duration": 1.2,
				"critical": true
			})
			break

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
			_show_message("%s 正在蓄力..." % enemy_name)
		"charge_release":
			vis["charge_timer"] = 0.0
			var dmg_mult: float = event.get("damage_multiplier", 2.0)
			_show_message("%s 蓄力攻击！×%.1f" % [enemy_name, dmg_mult])
			_trigger_attack_shake()
			_screen_flash_timer = 0.3
		"shield_appear":
			vis["shield_hp"] = float(event.get("shield_hp", 0))
			vis["shield_max_hp"] = float(event.get("shield_max_hp", 0))
			_show_message("%s 生成了护盾！" % enemy_name)
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
			_show_message("%s 回复了 %d HP！" % [enemy_name, heal_amount])

func _sync_boss_skill_visuals() -> void:
	if _battle == null:
		return
	var skill_states: Dictionary = _battle.get_status().get("enemy_skill_states", {})
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

func _find_player_index(name: String, fallback_name: String = "") -> int:
	if _battle == null:
		return -1
	var team: Array = _battle.player_team
	for i in range(team.size()):
		if team[i] == null:
			continue
		if not name.is_empty() and (team[i].get("name", "") == name or team[i].get("id", "") == name):
			return i
		if not fallback_name.is_empty() and team[i].get("name", "") == fallback_name:
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
	
	# 更新阶段切换状态
	if not _phase_transition_state.is_empty():
		var pt_timer: float = _phase_transition_state.get("timer", 0.0)
		pt_timer = BattleAnimationControllerScript.tick_countdown(pt_timer, effective_delta)
		_phase_transition_state["timer"] = pt_timer
	
	# 更新连击弹窗
	if _combo_popup.has("combo"):
		_update_combo_popup(effective_delta)
	
	# 更新受击闪烁
	BattleAnimationControllerScript.tick_timed_entries(_hit_flashes, effective_delta)

	# ★ 主人定 2026-06-10：更新玩家宠物弹动 + 弹道动画
	BattleAnimationControllerScript.tick_timed_entries(_player_lunge_anims, effective_delta)
	BattleAnimationControllerScript.tick_timed_entries(_bullet_anims, effective_delta)
	BattleAnimationControllerScript.tick_timed_entries(_attack_cues, effective_delta)
	# ★ 主人定 2026-06-11：attacker 弹性放大 + 倒下过渡
	BattleAnimationControllerScript.tick_timed_entries(_attacker_elastic_anims, effective_delta)
	_scan_new_defeats()
	_tick_defeat_transitions(effective_delta)

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

	# 更新道具使用特效
	_update_item_use_effects(effective_delta)
	
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
	if _feedback_overlay != null and is_instance_valid(_feedback_overlay):
		_feedback_overlay.queue_redraw()

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
	
	# 可编辑 GUI 模式下，背景、HUD 和角色由 .tscn 节点负责。
	if not _uses_editable_gui():
		_draw_background()
	
	# 攻击白闪（★ 2026-06-11：移除，避免压过退位动画）
	# 攻击主反馈改由 attacker 弹性放大承担
	
	if not _uses_editable_gui():
		# 标题栏
		_draw_title_bar()

		# 敌方信息区
		_draw_enemies()

		# 我方信息区
		_draw_team()
	else:
		# 角色主体由 UI 节点承载，瞬态战斗特效仍位于代码绘制层。
		_draw_combatant_fx()
	
	# 棋盘背景
	_draw_board_background()
	
	# 绘制棋盘
	_draw_board()
	
	# 渲染宝石消除粒子
	_draw_gem_particles()
	
	# 渲染障碍物破坏粒子
	_draw_obstacle_particles()

	# 渲染道具使用特效
	_draw_item_use_effects()
	
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
	
	if not _uses_editable_gui():
		# 独立底部捕捉控件，不绘制整块底栏背板。
		_draw_bottom_capture_controls()
	
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

	# 战斗结束覆盖由 TopFeedbackOverlay 绘制，保证压住 GUI 子节点；这里仅作兜底。
	if _state == BattleState.BATTLE_END and (_feedback_overlay == null or not is_instance_valid(_feedback_overlay)):
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
		"player_lunge_anims": _player_lunge_anims,
		"bullet_anims": _bullet_anims,
		"attack_cues": _attack_cues,
		"defeated_enemies": _defeated_enemies,
		"attacker_elastic_anims": _attacker_elastic_anims,
		"defeat_transitions": _defeat_transitions,
		"boss_skill_visuals": _boss_skill_visuals,
		"enemy_intents": _battle.get_status().get("enemy_intents", {}) if _battle != null else {},
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
		"falling_gems": _falling_gems,
		"eliminate_phase1": ELIMINATE_PHASE1,
		"eliminate_phase2": ELIMINATE_PHASE2,
		"eliminate_duration": ELIMINATE_DURATION
	}

func _draw_background() -> void:
	var bg_tex := _get_texture(BATTLE_BG_PATH)
	if bg_tex:
		_draw_texture_cover(bg_tex, Rect2(0, 0, DESIGN_W, DESIGN_H))

func _draw_title_bar() -> void:
	var turn_count: int = _battle.turn_count if _battle != null else 0
	var max_turns: int = _battle.max_turns if _battle != null else 20
	var turn_tex := _get_texture(BATTLE_UI_ASSETS["turn_badge"])
	var pause_rect := Rect2(DESIGN_W - 59.0, 8.0, 44.0, 42.0)
	if turn_tex:
		_draw_texture_contain(turn_tex, Rect2(9.0, 5.0, 72.0, 48.0), 1.0)
	else:
		_draw_rounded_rect(12.0, 9.0, 62.0, 42.0, 5.0, Color(0.07, 0.13, 0.26, 0.92))
	_draw_text_with_shadow("回合", 45.0, 18.5, C["white"], 7.4, true)
	_draw_text_with_shadow("%d/%d" % [turn_count, max_turns], 45.0, 36.5, C["gold"], 10.8, true)
	_draw_pause_button_backplate(pause_rect)
	_draw_pause_mark(pause_rect, C["white"], 1.0)

	# BOSS阶段指示器
	if _battle != null:
		var status: Dictionary = _battle.get_status()
		if status.get("is_boss_battle", false):
			var phase_color := C["fire"] if _phase_transition_state.get("timer", 0.0) > 0 else C["danger"]
			_draw_text_with_shadow("阶段 %d/%d" % [status.get("current_phase", 1), status.get("total_phases", 1)], DESIGN_W - 62.0, 62.0, phase_color, 9.2, true)

func _draw_pause_button_backplate(rect: Rect2) -> void:
	_draw_rounded_rect(rect.position.x, rect.position.y, rect.size.x, rect.size.y, 8.0, Color(1.0, 0.93, 0.69, 0.96))
	_draw_rounded_rect(rect.position.x + 3.0, rect.position.y + 3.0, rect.size.x - 6.0, rect.size.y - 6.0, 6.0, Color(0.11, 0.36, 0.74, 0.78))
	draw_arc(rect.get_center(), rect.size.x * 0.43, 0.0, TAU, 24, Color(1.0, 0.73, 0.19, 0.96), 2.2, true)
	draw_arc(rect.get_center(), rect.size.x * 0.35, 0.0, TAU, 24, Color(1.0, 1.0, 1.0, 0.35), 1.2, true)

func _draw_pause_mark(rect: Rect2, color: Color, opacity: float = 1.0) -> void:
	var center := rect.get_center() + Vector2(0.0, 2.0)
	var bar_size := Vector2(3.4, 19.0)
	var gap := 5.0
	var shadow := Color(0.03, 0.07, 0.16, 0.42 * opacity)
	var fill := Color(color.r, color.g, color.b, color.a * opacity)
	var left_pos := Vector2(center.x - gap - bar_size.x, center.y - bar_size.y * 0.5)
	var right_pos := Vector2(center.x + gap, center.y - bar_size.y * 0.5)
	draw_rect(Rect2(left_pos + Vector2(1.0, 1.0), bar_size), shadow, true)
	draw_rect(Rect2(right_pos + Vector2(1.0, 1.0), bar_size), shadow, true)
	draw_rect(Rect2(left_pos, bar_size), fill, true)
	draw_rect(Rect2(right_pos, bar_size), fill, true)
	
func _draw_enemies() -> void:
	BattleCombatantRendererScript.draw_enemies(self, _battle, _combatant_render_state())

func _draw_enemy_card(x: float, y: float, index: int, name: String, hp: int, max_hp: int, enemy: Dictionary) -> void:
	BattleCombatantRendererScript.draw_enemy_card(self, _battle, _combatant_render_state(), x, y, index, name, hp, max_hp, enemy)

func _draw_team() -> void:
	BattleCombatantRendererScript.draw_team(self, _battle, _combatant_render_state())

func _draw_combatant_fx() -> void:
	BattleCombatantRendererScript.draw_fx(self, _battle, _combatant_render_state())

func _draw_player_card(x: float, y: float, index: int, name: String, hp: int, max_hp: int, monster: Dictionary) -> void:
	BattleCombatantRendererScript.draw_player_card(self, _battle, _combatant_render_state(), x, y, index, name, hp, max_hp, monster)

func _draw_board_background() -> void:
	BattleBoardRendererScript.draw_board_background(self, DESIGN_W, _board)

func _draw_board() -> void:
	BattleBoardRendererScript.draw_board(self, _board, _board_render_state())

func _draw_gem(cx: float, cy: float, gem_type: String, color: Color) -> void:
	_draw_gem_animated(cx, cy, gem_type, color, 1.0, 1.0)

func _draw_gem_animated(cx: float, cy: float, gem_type: String, color: Color, scale: float, alpha: float, brightness: float = 0.0) -> void:
	var gem_tex := _get_texture(GEM_IMAGE_PATHS.get(gem_type, ""))
	var draw_size := 36.0 * scale
	
	# 闪白效果：先画一个更大的白色光圈
	if brightness > 0.0 and alpha > 0.0:
		var pop_tex := _get_texture(BATTLE_FX_ASSETS["gem_pop"])
		if pop_tex:
			var pop_size := 56.0 * scale * (1.0 + brightness * 0.22)
			_draw_texture_fit(pop_tex, Rect2(cx - pop_size / 2.0, cy - pop_size / 2.0, pop_size, pop_size), brightness * alpha)
		else:
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
	var emoji: String = GEM_EMOJI.get(gem_type, "晶")
	_draw_text_with_shadow(emoji, cx, cy, Color(1.0, 1.0, 1.0, alpha), 14.0)

func _draw_selection() -> void:
	if _selected_gem.x < 0 or _selected_gem.y < 0:
		return
	var cell_size := float(_board.cell_size) if _board != null else 42.0
	var board_x := float(_board.offset_x) if _board != null else (DESIGN_W - 336.0) / 2.0
	var board_y := float(_board.offset_y) if _board != null else 280.0
	var center := Vector2(
		board_x + _board_shake_offset.x + float(_selected_gem.x) * cell_size + cell_size / 2.0,
		board_y + _board_shake_offset.y + float(_selected_gem.y) * cell_size + cell_size / 2.0
	)
	var pulse := (sin(_selection_pulse * TAU / 0.72) + 1.0) * 0.5
	var ring_radius := cell_size * 0.43 + pulse * 1.5
	var main_alpha := 0.72 + pulse * 0.18
	var shine_alpha := 0.30 + pulse * 0.20
	draw_arc(center, ring_radius + 2.6, 0.0, TAU, 56, Color(0.18, 0.44, 0.68, 0.18), 4.8, true)
	draw_arc(center, ring_radius, 0.0, TAU, 56, Color(1.0, 0.86, 0.24, main_alpha), 3.0, true)
	draw_arc(center, ring_radius - 3.0, -0.15 * PI, 1.15 * PI, 56, Color(1.0, 1.0, 1.0, shine_alpha), 1.4, true)
	for i in range(3):
		var angle := _selection_pulse * 1.8 + float(i) * TAU / 3.0
		var sparkle_pos := center + Vector2(cos(angle), sin(angle)) * (ring_radius + 4.0)
		draw_circle(sparkle_pos, 1.5 + pulse * 0.6, Color(1.0, 0.95, 0.54, 0.55 + pulse * 0.20))

func _draw_floating_texts(canvas: CanvasItem = self) -> void:
	for ft in _floating_texts:
		var text: String = _clean_battle_fx_text(str(ft.get("text", "")))
		if text.is_empty():
			continue
		var x: float = ft.get("x", 0.0)
		var y: float = ft.get("y", 0.0)
		var color: Color = ft.get("color", C["white"])
		var size: float = ft.get("size", 16.0)
		var duration: float = ft.get("duration", 1.0)
		var timer: float = ft.get("timer", 0.0)
		var progress: float = clampf(timer / maxf(0.01, duration), 0.0, 1.0)
		var pop: float = 1.0 + sin(clampf(progress / 0.24, 0.0, 1.0) * PI) * (0.24 if ft.get("critical", false) else 0.16)
		var float_y: float = y - 24.0 * (1.0 - pow(1.0 - progress, 2.0))
		var wobble_x: float = sin(progress * TAU) * (2.2 if ft.get("critical", false) else 1.2)
		var fade: float = clampf(1.0 - maxf(0.0, progress - 0.68) / 0.32, 0.0, 1.0)
		color.a *= fade
		var style := "gold" if ft.get("critical", false) else _fx_text_style(text, color)
		if _is_digit_fx_text(text):
			_draw_digit_fx_text(canvas, text, x + wobble_x, float_y, size * pop, fade, style)
		else:
			_draw_soft_sparkles(canvas, Vector2(x + wobble_x, float_y - size * 0.90), color, fade, ft.get("critical", false))
			_draw_fx_text(canvas, text, x + wobble_x, float_y, color, size * pop, 170.0, style)

func _draw_combo_popup(canvas: CanvasItem = self) -> void:
	if not _combo_popup.has("combo"):
		return
	
	var cx := DESIGN_W / 2.0
	var cy: float = float(_board.offset_y) + 150.0 if _board != null else 450.0
	var combo: int = _combo_popup["combo"]
	var scale: float = _combo_popup["scale"]
	var opacity: float = _combo_popup["opacity"]
	if combo <= 0 or opacity <= 0.0:
		return
	
	var glow_color := Color(1.0, 0.92, 0.46, 0.20 * opacity)
	canvas.draw_arc(Vector2(cx, cy - 1.0), 64.0 * scale, -0.18 * PI, 1.18 * PI, 42, glow_color, 3.0, true)
	_draw_soft_sparkles(canvas, Vector2(cx, cy - 27.0 * scale), Color(1.0, 0.88, 0.36, opacity), opacity, combo >= 3)
	
	_draw_combo_art_text(canvas, combo, cx, cy, scale, opacity)

func _draw_top_feedback_layer(canvas: CanvasItem = self) -> void:
	_draw_floating_texts(canvas)
	_draw_combo_popup(canvas)
	_draw_fall_messages(canvas)
	_draw_message(canvas)
	if _state == BattleState.BATTLE_END and not _uses_editable_battle_end_overlay():
		_draw_battle_end_overlay(canvas)

func _draw_fall_messages(canvas: CanvasItem = self) -> void:
	for i in range(_fall_messages.size()):
		var fm: Dictionary = _fall_messages[i]
		var text := _clean_battle_fx_text(str(fm["text"]))
		if text.is_empty():
			continue
		var alpha: float = mini(1.0, fm["timer"])
		var y := 300.0 + i * 25.0
		var panel_w := clampf(FX_ROUND_FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13.5).x + 42.0, 128.0, 260.0)
		canvas.draw_line(Vector2(DESIGN_W / 2.0 - panel_w * 0.36, y + 9.0), Vector2(DESIGN_W / 2.0 + panel_w * 0.36, y + 5.0), Color(1.0, 0.70, 0.42, 0.34 * alpha), 2.0)
		_draw_fx_text(canvas, text, DESIGN_W / 2.0, y + 3.0, Color(1.0, 0.54, 0.34, alpha), 13.5, panel_w - 22.0, "damage")

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
	var bottom_y: float = float(_board.offset_y + _board.rows * _board.cell_size + 7.0) if _board != null else 614.0
	var panel_h := 45.0
	var panel_tex := _get_texture(BATTLE_UI_ASSETS["footer_panel"])
	if panel_tex:
		_draw_texture_fit(panel_tex, Rect2(10.0, bottom_y, DESIGN_W - 20.0, panel_h), 1.0)
	else:
		_draw_rounded_rect(10, bottom_y, DESIGN_W - 20, panel_h, 7.0, Color(0.06, 0.11, 0.22, 0.94))
	
	var state_color := C["text_muted"]
	if _state == BattleState.ENEMY_TURN:
		state_color = C["danger"]
	
	var turn_count: int = _battle.turn_count if _battle != null else 0
	var max_turns: int = _battle.max_turns if _battle != null else 20
	var combo_count: int = _board.cascade_count if _board != null else 0
	
	var status_text := "等待操作"
	if _state == BattleState.ENEMY_TURN:
		status_text = "敌方回合"
	elif _state != BattleState.IDLE:
		status_text = "处理中..."
	
	_draw_text_with_shadow("回合 %d/%d" % [turn_count, max_turns], 232.0, bottom_y + 14.0, C["text_secondary"], 9.5, true)
	_draw_text_with_shadow("连锁 %dx" % combo_count, 292.0, bottom_y + 14.0, C["gold"], 10.5, true)
	_draw_text_with_shadow(status_text, 334.0, bottom_y + 14.0, state_color, 9.0, true)
	_draw_capture_window_hint(bottom_y)
	_draw_capture_toggle(bottom_y)
	_draw_capture_item_slots(bottom_y)
	_draw_item_hotbar(bottom_y)

func _draw_bottom_capture_controls() -> void:
	var bottom_y: float = float(_board.offset_y + _board.rows * _board.cell_size + 7.0) if _board != null else 619.0
	_draw_capture_toggle(bottom_y)
	_draw_capture_item_slots(bottom_y)
	_draw_item_hotbar(bottom_y)

func _draw_capture_window_hint(base_y: float) -> void:
	if _battle == null:
		return
	var candidate: Dictionary = _battle.get_best_capture_candidate() if _battle.has_method("get_best_capture_candidate") else {}
	var window: Dictionary = candidate.get("window", {})
	if window.is_empty():
		return
	var label := str(window.get("label", "未开启"))
	var stability := int(round(float(window.get("stability", 0.0)) * 100.0))
	var state := str(window.get("state", "locked"))
	var color := C["text_muted"]
	if state == "prime":
		color = C["gold"]
	elif state == "open":
		color = C["success"]
	elif state == "unstable":
		color = C["shield"]
	elif state == "overpowered":
		color = C["danger"]
	_draw_text_with_shadow("捕捉 %s %d%%" % [label, stability], 277.0, base_y + 33.0, color, 8.8, true)

func _draw_capture_toggle(base_y: float) -> void:
	var rect := _get_capture_toggle_rect(base_y)
	var key := "capture_toggle_on" if _auto_capture_enabled else "capture_toggle_off"
	var tex := _get_texture(BATTLE_UI_ASSETS[key])
	if tex:
		_draw_texture_contain(tex, rect, 1.0)
	else:
		var bg := C["success"] if _auto_capture_enabled else C["bg_medium"]
		_draw_rounded_rect(rect.position.x, rect.position.y, rect.size.x, rect.size.y, 6.0, bg)
	_draw_bottom_button_badge(rect, "开" if _auto_capture_enabled else "关")

func _draw_item_hotbar(base_y: float) -> void:
	"""绘制底部道具快捷栏"""

	for i in range(HOTBAR_SLOT_COUNT):
		var slot_rect := _get_hotbar_slot_rect(base_y, i)
		var item: Dictionary = _hotbar_items[i] if i < _hotbar_items.size() else {}
		var has_item: bool = not item.is_empty() and item.get("count", 0) > 0
		var is_selected := _is_hotbar_item_selected(i, item)
		var slot_key := "item_slot_selected" if is_selected else "item_slot"
		var slot_tex := _get_texture(BATTLE_UI_ASSETS[slot_key])
		if slot_tex:
			_draw_texture_fit(slot_tex, slot_rect, 1.0 if has_item else 0.72)
		if not has_item:
			draw_circle(slot_rect.get_center(), 4.0, Color(1.0, 1.0, 1.0, 0.28))
			continue

		if has_item:
			var item_def: Dictionary = ItemDB.get_item(item["id"])
			var icon_tex := _get_texture(_item_icon_asset_path(str(item["id"])))
			if icon_tex:
				_draw_texture_contain(icon_tex, slot_rect, 1.0)
			else:
				var emoji: String = item_def.get("emoji", "?")
				_draw_text(emoji, slot_rect.get_center().x, slot_rect.position.y + 13.0, C["white"], 13.5, true)
			if is_selected:
				_draw_rounded_rect_outline(slot_rect.position.x + 1.0, slot_rect.position.y + 1.0, slot_rect.size.x - 2.0, slot_rect.size.y - 2.0, 9.0, C["gold"], 2.0)

			# 数量标签
			var count: int = item["count"]
			if count > 1:
				_draw_bottom_button_badge(slot_rect, str(count))

func _draw_capture_item_slots(base_y: float) -> void:
	for i in range(2):
		var slot_rect := _get_capture_item_slot_rect(base_y, i)
		var item: Dictionary = _capture_slot_items[i] if i < _capture_slot_items.size() else {}
		var has_item := not item.is_empty() and int(item.get("count", 0)) > 0
		var item_id := str(item.get("id", ""))
		var selected := has_item and item_id == _equipped_capture_item_id
		# 精灵球槽使用专属底图 (capture_slot)
		var slot_tex := _get_texture(BATTLE_UI_ASSETS["capture_slot"])
		if slot_tex:
			_draw_texture_fit(slot_tex, slot_rect, 1.0 if has_item else 0.72)
		if selected:
			_draw_rounded_rect_outline(slot_rect.position.x + 1.0, slot_rect.position.y + 1.0, slot_rect.size.x - 2.0, slot_rect.size.y - 2.0, 9.0, C["gold"], 2.0)
		if not has_item:
			draw_circle(slot_rect.get_center(), 4.0, Color(1.0, 1.0, 1.0, 0.28))
			continue
		var icon_tex := _get_texture(_item_icon_asset_path(item_id))
		if icon_tex:
			_draw_texture_contain(icon_tex, slot_rect, 1.0)
		var count := int(item.get("count", 0))
		if count > 1:
			_draw_bottom_button_badge(slot_rect, str(count))

func _draw_bottom_button_badge(rect: Rect2, label: String) -> void:
	var badge_center := Vector2(rect.end.x - 4.0, rect.end.y - 4.0)
	draw_circle(badge_center, 8.0, Color(0.92, 0.20, 0.36, 1.0))
	draw_arc(badge_center, 8.0, 0.0, TAU, 20, Color(1.0, 0.72, 0.80, 1.0), 1.0, true)
	_draw_text_with_shadow(label, badge_center.x, badge_center.y + 3.0, C["white"], 7.6, true)

func _get_capture_toggle_rect(base_y: float) -> Rect2:
	return Rect2(18.0, base_y + 3.0, 39.0, 39.0)

func _get_capture_item_slot_rect(base_y: float, slot_idx: int) -> Rect2:
	var slot_size: float = 39.0
	var slot_gap: float = 7.0
	var start_x: float = 67.0
	return Rect2(start_x + slot_idx * (slot_size + slot_gap), base_y + 3.0, slot_size, slot_size)

func _get_hotbar_slot_rect(base_y: float, slot_idx: int) -> Rect2:
	var slot_size: float = 39.0
	var slot_gap: float = 7.0
	var start_x: float = 159.0
	return Rect2(start_x + slot_idx * (slot_size + slot_gap), base_y + 3.0, slot_size, slot_size)

func _item_icon_asset_path(item_id: String) -> String:
	if item_id == "capture_ball":
		return BATTLE_UI_ASSETS["item_capture_ball"]
	if item_id == "capture_ball_plus" or item_id == "capture_ball_elite":
		return BATTLE_UI_ASSETS["item_capture_ball_plus"]
	if item_id == "hp_potion" or item_id == "hp_potion_large":
		return BATTLE_UI_ASSETS["item_hp_potion"]
	if item_id == "guard_charm":
		return BATTLE_UI_ASSETS["item_guard_charm"]
	if item_id == "rock_hammer" or item_id == "rock_hammer_plus":
		return BATTLE_UI_ASSETS["item_rock_hammer"]
	if item_id == "unlock_key":
		return BATTLE_UI_ASSETS["item_stone_thunder"]
	if item_id == "mist_cleanser":
		return BATTLE_UI_ASSETS["item_stone_water"]
	if item_id == "focus_crystal":
		return BATTLE_UI_ASSETS["item_focus_crystal"]
	if item_id == "board_reset":
		return BATTLE_UI_ASSETS["item_board_reset"]
	if item_id == "absorb_shield":
		return BATTLE_UI_ASSETS["item_absorb_shield"]
	if item_id == "gem_type_shift":
		return BATTLE_UI_ASSETS["item_gem_type_shift"]
	return ""

func _is_hotbar_item_selected(slot_idx: int, item: Dictionary) -> bool:
	if item.is_empty() or item.get("count", 0) <= 0:
		return false
	return _selected_hotbar_slot == slot_idx

func _load_hotbar_items() -> void:
	"""从背包加载前3个战斗相关道具到快捷栏"""
	_hotbar_items.clear()
	if not _storage or not _storage.has_method("load_inventory"):
		return
	var equipped_inventory: Dictionary = _storage.call("load_inventory")
	_load_capture_slot_items(equipped_inventory)
	for equipped_id in _equipped_battle_item_ids:
		var item_id := str(equipped_id)
		var count: int = int(equipped_inventory.get(item_id, 0))
		if count <= 0:
			continue
		var def: Dictionary = ItemDB.get_item(item_id)
		if str(def.get("type", "")) != "battle":
			continue
		_hotbar_items.append({"id": item_id, "count": count, "rarity": def.get("rarity", 1), "type": "battle"})
		if _hotbar_items.size() >= HOTBAR_SLOT_COUNT:
			break
	_selected_hotbar_slot = -1
	return
	# 收集所有 type 为 capture 或 battle 的道具
	var inventory: Dictionary = {}
	var candidates: Array[Dictionary] = []
	for item_id in inventory:
		var count: int = inventory[item_id]
		if count <= 0:
			continue
		var def: Dictionary = ItemDB.get_item(item_id)
		var item_type: String = def.get("type", "")
		if item_type == "capture" or item_type == "battle":
			candidates.append({"id": item_id, "count": count, "rarity": def.get("rarity", 1), "type": item_type})
	# 按rarity降序（稀有在前）、然后count降序
	candidates.sort_custom(func(a, b):
		var a_equipped := str(a.get("id", "")) == _equipped_capture_item_id
		var b_equipped := str(b.get("id", "")) == _equipped_capture_item_id
		if a_equipped != b_equipped:
			return a_equipped
		if str(a.get("type", "")) != str(b.get("type", "")):
			return str(a.get("type", "")) == "battle"
		return a["rarity"] > b["rarity"] or (a["rarity"] == b["rarity"] and a["count"] > b["count"])
	)
	for i in range(mini(candidates.size(), HOTBAR_SLOT_COUNT)):
		_hotbar_items.append(candidates[i])
	_selected_hotbar_slot = -1
	for i in range(_hotbar_items.size()):
		if str(_hotbar_items[i].get("id", "")) == _equipped_capture_item_id:
			_selected_hotbar_slot = i
			break

func _load_capture_preferences() -> void:
	var settings := {"autoCapture": false, "equippedItem": "", "equippedBattleItems": []}
	if _storage and _storage.has_method("load_capture_settings"):
		settings = _storage.call("load_capture_settings")
	_auto_capture_enabled = bool(settings.get("autoCapture", false))
	_equipped_capture_item_id = str(settings.get("equippedItem", ""))
	_equipped_battle_item_ids = _sanitize_equipped_battle_items(settings.get("equippedBattleItems", []))

func _load_capture_slot_items(inventory: Dictionary) -> void:
	_capture_slot_items.clear()
	var ordered_ids: Array = ["capture_ball", "capture_ball_plus", "capture_ball_elite"]
	if not _equipped_capture_item_id.is_empty() and int(inventory.get(_equipped_capture_item_id, 0)) > 0:
		var equipped_def: Dictionary = ItemDB.get_item(_equipped_capture_item_id)
		if str(equipped_def.get("type", "")) == "capture":
			_capture_slot_items.append({
				"id": _equipped_capture_item_id,
				"count": int(inventory.get(_equipped_capture_item_id, 0)),
				"rarity": equipped_def.get("rarity", 1),
				"type": "capture"
			})
	for item_id in ordered_ids:
		if _capture_slot_items.size() >= 2:
			break
		if str(item_id) == _equipped_capture_item_id:
			continue
		var count := int(inventory.get(item_id, 0))
		if count <= 0:
			continue
		var def: Dictionary = ItemDB.get_item(item_id)
		if str(def.get("type", "")) != "capture":
			continue
		_capture_slot_items.append({"id": item_id, "count": count, "rarity": def.get("rarity", 1), "type": "capture"})

func _save_capture_preferences() -> void:
	if _storage and _storage.has_method("save_capture_settings"):
		_storage.call("save_capture_settings", {
			"autoCapture": _auto_capture_enabled,
			"equippedItem": _equipped_capture_item_id,
			"equippedBattleItems": _equipped_battle_item_ids.duplicate()
		})

func _sanitize_equipped_battle_items(source: Array) -> Array:
	var result: Array = []
	for value in source:
		var item_id := str(value)
		if result.size() >= HOTBAR_SLOT_COUNT:
			break
		if item_id.is_empty() or result.has(item_id):
			continue
		var def: Dictionary = ItemDB.get_item(item_id)
		if str(def.get("type", "")) == "battle":
			result.append(item_id)
	return result

func _try_tap_hotbar(x: float, y: float) -> bool:
	"""检测独立底部捕捉控件，不依赖整块底栏背板。"""
	var bottom_y: float = float(_board.offset_y + _board.rows * _board.cell_size + 7.0) if _board != null else 619.0
	if _get_capture_toggle_rect(bottom_y).has_point(Vector2(x, y)):
		_auto_capture_enabled = not _auto_capture_enabled
		_save_capture_preferences()
		if _auto_capture_enabled and _equipped_capture_item_id.is_empty():
			_show_message("自动捕捉已开启，请选择捕捉球")
		elif _auto_capture_enabled:
			var item_def: Dictionary = ItemDB.get_item(_equipped_capture_item_id)
			_show_message("自动捕捉：开启，使用%s" % item_def.get("name", "捕捉球"))
		else:
			_show_message("自动捕捉：关闭")
		queue_redraw()
		return true

	if _try_tap_capture_item_slots(x, y, bottom_y):
		return true

	for i in range(HOTBAR_SLOT_COUNT):
		var slot_rect := _get_hotbar_slot_rect(bottom_y, i)
		if not slot_rect.has_point(Vector2(x, y)):
			continue
		if i >= _hotbar_items.size():
			return false
		var item: Dictionary = _hotbar_items[i]
		if item.is_empty() or item.get("count", 0) <= 0:
			return false
		_selected_hotbar_slot = i
		_open_hotbar_item_confirm(i)
		return true
		var def: Dictionary = ItemDB.get_item(item["id"])
		if str(def.get("type", "")) == "capture":
			_try_use_item_at_slot(i)
			return true
		if _selected_hotbar_slot == i:
			_try_use_item_at_slot(i)
			return true
		_selected_hotbar_slot = i
		_show_message("选中 %s x%d" % [def.get("name", "?"), item["count"]])
		return true
	return false

func _try_tap_capture_item_slots(x: float, y: float, bottom_y: float) -> bool:
	for i in range(2):
		var slot_rect := _get_capture_item_slot_rect(bottom_y, i)
		if not slot_rect.has_point(Vector2(x, y)):
			continue
		if i >= _capture_slot_items.size():
			return false
		var item: Dictionary = _capture_slot_items[i]
		if item.is_empty() or int(item.get("count", 0)) <= 0:
			return false
		var item_id := str(item.get("id", ""))
		var def: Dictionary = ItemDB.get_item(item_id)
		if str(def.get("type", "")) != "capture":
			return false
		_equipped_capture_item_id = item_id
		_save_capture_preferences()
		var bonus := float(def.get("effect", {}).get("captureBonus", 0.0))
		_show_message("已激活 %s +%.0f%%" % [str(def.get("name", "捕获球")), bonus * 100.0])
		queue_redraw()
		if has_method("_sync_gui"):
			call("_sync_gui")
		return true
	return false

func _open_hotbar_item_confirm(slot_idx: int) -> void:
	if slot_idx < 0 or slot_idx >= _hotbar_items.size():
		return
	_pending_hotbar_slot = slot_idx
	var item: Dictionary = _hotbar_items[slot_idx]
	var def: Dictionary = ItemDB.get_item(str(item.get("id", "")))
	_show_message("是否使用 %s？" % str(def.get("name", "道具")))
	if has_method("_sync_gui"):
		call("_sync_gui")
	queue_redraw()

func _cancel_hotbar_item_confirm() -> void:
	_pending_hotbar_slot = -1
	queue_redraw()
	if has_method("_sync_gui"):
		call("_sync_gui")

func _confirm_hotbar_item_use() -> bool:
	var slot_idx := _pending_hotbar_slot
	if slot_idx < 0:
		return false
	_pending_hotbar_slot = -1
	var used := _try_use_item_at_slot(slot_idx)
	queue_redraw()
	if has_method("_sync_gui"):
		call("_sync_gui")
	return used

func _try_tap_item_confirm_popup(x: float, y: float) -> bool:
	var point := Vector2(x, y)
	if _item_confirm_use_rect().has_point(point):
		_confirm_hotbar_item_use()
		return true
	if _item_confirm_cancel_rect().has_point(point):
		_cancel_hotbar_item_confirm()
		return true
	return true

func _item_confirm_use_rect() -> Rect2:
	return _control_local_rect_or_fallback("ItemConfirmLayer/Panel/UseButton", Rect2(204.0, 376.0, 80.0, 41.0))

func _item_confirm_cancel_rect() -> Rect2:
	return _control_local_rect_or_fallback("ItemConfirmLayer/Panel/CancelButton", Rect2(92.0, 376.0, 80.0, 41.0))

func _control_local_rect_or_fallback(path: NodePath, fallback: Rect2) -> Rect2:
	if not is_inside_tree() or not has_node(path):
		return fallback
	var node := get_node(path) as Control
	if node == null:
		return fallback
	var root_inverse := get_global_transform_with_canvas().affine_inverse()
	var origin := root_inverse * node.get_global_transform_with_canvas().origin
	return Rect2(origin, node.size)

func _try_use_item_at_slot(slot_idx: int) -> bool:
	"""尝试使用指定快捷栏格子中的道具，返回是否处理了"""
	if slot_idx < 0 or slot_idx >= _hotbar_items.size():
		return false
	var item: Dictionary = _hotbar_items[slot_idx]
	if item.is_empty() or item.get("count", 0) <= 0:
		return false
	var item_id: String = item["id"]
	var def: Dictionary = ItemDB.get_item(item_id)
	var item_type: String = def.get("type", "")
	if item_type == "capture":
		_equipped_capture_item_id = item_id
		_selected_hotbar_slot = slot_idx
		_save_capture_preferences()
		var bonus: float = float(def.get("effect", {}).get("captureBonus", 0.0))
		_show_message("已选择 %s +%.0f%%" % [def.get("name", "捕获球"), bonus * 100.0])
		queue_redraw()
		return true
	elif item_type == "battle":
		if _state != BattleState.IDLE:
			_show_message("当前无法使用道具")
			return true
		if not _has_hotbar_item_available(item_id):
			return true
		var effect: Dictionary = def.get("effect", {})
		var used := false
		if effect.has("healRatio"):
			used = _use_hotbar_heal(def, effect)
		elif effect.has("guardReduction"):
			used = _use_hotbar_guard(def, effect)
		elif effect.has("obstacleDamage"):
			used = _use_hotbar_obstacle_damage(def, effect)
		elif effect.has("unlockDamage"):
			used = _use_hotbar_unlock(def, effect)
		elif effect.has("clearPoisonCount"):
			used = _use_hotbar_clear_poison(def, effect)
		elif effect.has("chargeGain"):
			used = _use_hotbar_charge(def, effect)
		elif effect.has("resetBoard"):
			used = _use_hotbar_board_reset(def, effect)
		elif effect.has("absorbShield"):
			used = _use_hotbar_absorb_shield(def, effect)
		elif effect.has("convertType"):
			used = _use_hotbar_gem_type_shift(def, effect)
		else:
			_show_message("%s 暂时无法使用" % def.get("name", "道具"))
			return true
		if used:
			_consume_hotbar_item(item_id, slot_idx)
		return true
	else:
		_show_message("%s 不能在战斗中使用" % def.get("name", "道具"))
		return true

func _use_hotbar_heal(def: Dictionary, effect: Dictionary) -> bool:
	if _battle == null:
		return false
	var heal_ratio := float(effect.get("healRatio", 0.5))
	var healed := 0
	for i in range(_battle.player_team.size()):
		var monster: Dictionary = _battle.player_team[i]
		if monster == null or monster.is_empty() or int(monster.get("hp", 0)) <= 0:
			continue
		var max_hp := int(monster.get("maxHP", 100))
		var cur_hp := int(monster.get("hp", max_hp))
		var add := maxi(1, int(round(float(max_hp) * heal_ratio)))
		var next_hp := mini(cur_hp + add, max_hp)
		var actual := next_hp - cur_hp
		if actual <= 0:
			continue
		monster["hp"] = next_hp
		_battle.player_team[i] = monster
		healed += actual
		var card := _get_player_card_rect(i)
		_spawn_item_use_effect("heal", card.get_center(), C["heal_green"], 0.82, {"label": "+", "scale": 1.0})
		_floating_texts.append({"text": "+%d" % actual, "x": card.get_center().x, "y": card.position.y + 10.0, "color": C["heal_green"], "size": 15.0, "timer": 0.0, "duration": 0.8})
	if healed <= 0:
		_show_message("队伍生命已满")
		return false
	_show_message("使用 %s，恢复 %d HP" % [def.get("name", "HP药水"), healed])
	_sfx("battle_heal_leaf_bubble")
	return true

func _use_hotbar_guard(def: Dictionary, effect: Dictionary) -> bool:
	if _battle == null:
		return false
	var reduction := clampf(float(effect.get("guardReduction", 0.25)), 0.0, 0.8)
	var turns := maxi(1, int(effect.get("guardTurns", 1)))
	var guards_var: Variant = _battle.get("player_guards")
	var guards: Dictionary = guards_var.duplicate(true) if guards_var is Dictionary else {}
	var applied := 0
	for i in range(_battle.player_team.size()):
		var monster: Dictionary = _battle.player_team[i]
		if monster == null or monster.is_empty() or int(monster.get("hp", 0)) <= 0:
			continue
		var monster_id := str(monster.get("id", ""))
		if monster_id.is_empty():
			continue
		guards[monster_id] = {"reduction": reduction, "turns": turns}
		applied += 1
		var card := _get_player_card_rect(i)
		_spawn_item_use_effect("guard", card.get_center(), C["shield"], 0.90, {"scale": 1.08})
		_floating_texts.append({"text": "护-%d%%" % int(round(reduction * 100.0)), "x": card.get_center().x, "y": card.position.y + 10.0, "color": C["shield"], "size": 14.0, "timer": 0.0, "duration": 0.9})
	if applied <= 0:
		_show_message("没有可守护的队员")
		return false
	_battle.set("player_guards", guards)
	_show_message("使用 %s，全队获得护盾" % def.get("name", "护符"))
	_sfx("battle_shield_soft_bloom")
	return true

func _use_hotbar_obstacle_damage(def: Dictionary, effect: Dictionary) -> bool:
	if _board == null:
		return false
	var target_count := maxi(1, int(effect.get("targetCount", 3)))
	if bool(effect.get("clearAllObstacles", false)):
		target_count = _board.rows * _board.cols
	var damage := maxi(1, int(effect.get("obstacleDamage", 1)))
	var touched := 0
	var destroyed := 0
	for row in range(_board.rows):
		for col in range(_board.cols):
			if touched >= target_count:
				break
			if not _board.is_obstacle(row, col):
				continue
			touched += 1
			var broke := false
			for _step in range(damage):
				if _board.damage_obstacle(row, col):
					broke = true
					break
			var center := _board_cell_center(row, col)
			_spawn_item_use_effect("hammer", center, Color(1.0, 0.72, 0.22, 1.0), 0.72, {"row": row, "col": col, "strong": broke})
			_floating_texts.append({"text": "破岩", "x": center.x, "y": center.y - 12.0, "color": C["gold"], "size": 13.0, "timer": 0.0, "duration": 0.75})
			if broke:
				destroyed += 1
				spawn_obstacle_destroy_particles(row, col)
		if touched >= target_count:
			break
	if touched <= 0:
		_show_message("当前没有岩石障碍")
		return false
		if destroyed > 0:
			_apply_gravity()
		_board_shake_timer = maxf(_board_shake_timer, 0.22)
		_sfx("powerup_burst_soft")
		_show_message("使用 %s，处理 %d 块岩石" % [def.get("name", "破岩锤"), touched])
		queue_redraw()
	return true

func _use_hotbar_unlock(def: Dictionary, effect: Dictionary) -> bool:
	if _board == null:
		return false
	var target_count := maxi(1, int(effect.get("targetCount", 3)))
	var damage := maxi(1, int(effect.get("unlockDamage", 1)))
	var touched := 0
	var unlocked := 0
	for row in range(_board.rows):
		for col in range(_board.cols):
			if touched >= target_count:
				break
			if not _board.is_locked(row, col):
				continue
			touched += 1
			var result: Dictionary = {}
			for _step in range(damage):
				result = _board.unlock_gem(row, col)
				if result.get("fullyUnlocked", false):
					break
				var center := _board_cell_center(row, col)
				var text := "解锁" if result.get("fullyUnlocked", false) else "破链"
				_spawn_item_use_effect("unlock", center, C["gold"], 0.65, {"strong": result.get("fullyUnlocked", false)})
				_floating_texts.append({"text": text, "x": center.x, "y": center.y - 12.0, "color": C["gold"], "size": 13.0, "timer": 0.0, "duration": 0.75})
			if result.get("fullyUnlocked", false):
				unlocked += 1
				_unlock_animations.append({"row": row, "col": col, "timer": 0.0, "maxTimer": 0.6, "phase": "shatter"})
		if touched >= target_count:
			break
	if touched <= 0:
		_show_message("当前没有锁链宝石")
		return false
	_show_message("使用 %s，解除 %d 处锁链" % [def.get("name", "钥匙"), maxi(touched, unlocked)])
	queue_redraw()
	return true

func _use_hotbar_clear_poison(def: Dictionary, effect: Dictionary) -> bool:
	if _board == null:
		return false
	var target_count := maxi(1, int(effect.get("clearPoisonCount", 5)))
	var cleared := 0
	for row in range(_board.rows):
		for col in range(_board.cols):
			if cleared >= target_count:
				break
			if not _board.is_poison_fog(row, col):
				continue
			_board.clear_poison_fog(row, col)
			cleared += 1
			var center := _board_cell_center(row, col)
			_spawn_item_use_effect("cleanse", center, C["success"], 0.72)
			_poison_fog_clear_anims.append({"row": row, "col": col, "x": center.x, "y": center.y, "timer": 0.0})
			_floating_texts.append({"text": "净雾", "x": center.x, "y": center.y - 12.0, "color": C["success"], "size": 13.0, "timer": 0.0, "duration": 0.75})
		if cleared >= target_count:
			break
	if cleared <= 0:
		_show_message("当前没有毒雾")
		return false
	_show_message("使用 %s，清除 %d 格毒雾" % [def.get("name", "净雾露"), cleared])
	queue_redraw()
	return true

func _use_hotbar_charge(def: Dictionary, effect: Dictionary) -> bool:
	if _battle == null:
		return false
	var gain := maxi(1, int(effect.get("chargeGain", 1)))
	var charges_var: Variant = _battle.get("skill_charges")
	var charges: Dictionary = charges_var.duplicate(true) if charges_var is Dictionary else {}
	var total_gain := 0
	for i in range(_battle.player_team.size()):
		var monster: Dictionary = _battle.player_team[i]
		if monster == null or monster.is_empty() or int(monster.get("hp", 0)) <= 0 or not monster.has("skill"):
			continue
		var monster_id := str(monster.get("id", ""))
		var skill: Dictionary = monster.get("skill", {})
		var cost := int(skill.get("cost", 999))
		var before := int(charges.get(monster_id, 0))
		var after := mini(cost, before + gain)
		if after <= before:
			continue
		charges[monster_id] = after
		total_gain += after - before
		var card := _get_player_card_rect(i)
		_spawn_item_use_effect("charge", card.get_center(), C["gold"], 0.88, {"scale": 1.0})
		_floating_texts.append({"text": "+%d 能量" % (after - before), "x": card.get_center().x, "y": card.position.y + 10.0, "color": C["gold"], "size": 13.0, "timer": 0.0, "duration": 0.85})
	if total_gain <= 0:
		_show_message("技能能量已满")
		return false
	_battle.set("skill_charges", charges)
	_show_message("使用 %s，补充 %d 点能量" % [def.get("name", "水晶"), total_gain])
	queue_redraw()
	return true

func _use_hotbar_board_reset(def: Dictionary, effect: Dictionary) -> bool:
	if _board == null:
		return false
	# 重新生成整盘宝石（保留岩石/锁链/毒雾布局）
	_board.init_board()
	_screen_flash_timer = 0.22
	_element_glow = {"type": "light", "timer": 0.5, "color": GEM_COLORS.get("light", C["gold"])}
	var center_x := float(_board.offset_x) + float(_board.cols) * float(_board.cell_size) * 0.5
	var center_y := float(_board.offset_y) + float(_board.rows) * float(_board.cell_size) * 0.5
	_spawn_item_use_effect("board_reset", Vector2(center_x, center_y), C["gold"], 0.95, {"cols": _board.cols, "rows": _board.rows})
	_floating_texts.append({"text": "棋盘重置！", "x": center_x, "y": center_y, "color": C["gold"], "size": 18.0, "timer": 0.0, "duration": 1.0})
	_show_message("使用 %s，整盘宝石已重置" % def.get("name", "棋盘重置"))
	_sfx("battle_heal_leaf_bubble")
	queue_redraw()
	return true

func _use_hotbar_absorb_shield(def: Dictionary, effect: Dictionary) -> bool:
	if _battle == null:
		return false
	var shields_var: Variant = _battle.get("player_absorb_shields")
	var shields: Dictionary = shields_var.duplicate(true) if shields_var is Dictionary else {}
	var applied := 0
	for i in range(_battle.player_team.size()):
		var monster: Dictionary = _battle.player_team[i]
		if monster == null or monster.is_empty() or int(monster.get("hp", 0)) <= 0:
			continue
		var monster_id := str(monster.get("id", ""))
		if monster_id.is_empty():
			continue
		shields[monster_id] = {"turns": 1}
		applied += 1
		var card := _get_player_card_rect(i)
		_spawn_item_use_effect("absorb", card.get_center(), Color(0.40, 0.88, 1.0, 1.0), 1.0, {"scale": 1.14})
		_floating_texts.append({"text": "护盾已就绪", "x": card.get_center().x, "y": card.position.y + 10.0, "color": C["shield"], "size": 14.0, "timer": 0.0, "duration": 0.9})
	if applied <= 0:
		_show_message("没有可守护的队员")
		return false
	_battle.set("player_absorb_shields", shields)
	_show_message("使用 %s，全队获得一次性护盾" % def.get("name", "强能护盾"))
	_sfx("battle_shield_soft_bloom")
	queue_redraw()
	return true

func _use_hotbar_gem_type_shift(def: Dictionary, effect: Dictionary) -> bool:
	if _battle == null or _board == null:
		return false
	# 选源/目标属性的 picker 在 .tscn 的 GemConvertLayer 中实现。
	# 仅在 GUI 版（场景里挂有该节点）下生效；legacy 版直接提示。
	const GEM_CONVERT_LAYER_PATH := NodePath("GemConvertLayer")
	if not is_inside_tree() or not has_node(GEM_CONVERT_LAYER_PATH):
		_show_message("该道具需要 GUI 模式")
		return false
	var slot_idx := _pending_hotbar_slot
	if slot_idx < 0 or slot_idx >= _hotbar_items.size():
		return false
	# 打开 picker，由 scene_battle_gui.gd 接管后续流程
	call("_open_gem_convert_picker", _hotbar_items[slot_idx].get("id", ""), slot_idx)
	return false  # 不立即消费，等待 picker 完成

func _consume_hotbar_item(item_id: String, slot_idx: int) -> bool:
	if _storage and _storage.has_method("use_item"):
		if not bool(_storage.call("use_item", item_id, 1)):
			_show_message("道具数量不足")
			_load_hotbar_items()
			_refresh_hotbar_ui()
			return false
		_load_hotbar_items()
	elif slot_idx >= 0 and slot_idx < _hotbar_items.size():
		var item: Dictionary = _hotbar_items[slot_idx]
		item["count"] = int(item.get("count", 0)) - 1
		if int(item.get("count", 0)) <= 0:
			_hotbar_items.remove_at(slot_idx)
		else:
			_hotbar_items[slot_idx] = item
	_selected_hotbar_slot = -1
	_pending_hotbar_slot = -1
	_refresh_hotbar_ui()
	return true

func _has_hotbar_item_available(item_id: String) -> bool:
	if _storage and _storage.has_method("load_inventory"):
		var inventory: Dictionary = _storage.call("load_inventory")
		if int(inventory.get(item_id, 0)) <= 0:
			_show_message("道具数量不足")
			_load_hotbar_items()
			_refresh_hotbar_ui()
			return false
	return true

func _refresh_hotbar_ui() -> void:
	queue_redraw()
	if has_method("_sync_gui"):
		call("_sync_gui")

func _board_cell_center(row: int, col: int) -> Vector2:
	if _board == null:
		return Vector2.ZERO
	var cell_size := float(_board.cell_size)
	return Vector2(float(_board.offset_x) + float(col) * cell_size + cell_size / 2.0, float(_board.offset_y) + float(row) * cell_size + cell_size / 2.0)

func _draw_message(canvas: CanvasItem = self) -> void:
	if _message_timer <= 0:
		return
	
	var alpha: float = mini(1.0, _message_timer)
	var progress: float = clampf(1.0 - _message_timer / 1.5, 0.0, 1.0)
	var is_turn_message := _is_turn_message(_message_text)
	var is_major_message := is_turn_message or _is_major_battle_message(_message_text)
	var pop: float = 1.0 + sin(clampf(progress / 0.24, 0.0, 1.0) * PI) * (0.16 if is_major_message else 0.08)
	var toast_y: float = float(_board.offset_y) + 28.0 if _board != null else 328.0
	if is_turn_message:
		toast_y = float(_board.offset_y) - 14.0 if _board != null else 276.0
	elif is_major_message:
		toast_y = float(_board.offset_y) + 12.0 if _board != null else 312.0
	var base_text_size := 17.0 if is_turn_message else (14.5 if is_major_message else 12.2)
	var text_w := FX_ROUND_FONT.get_string_size(_message_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, base_text_size).x
	var toast_w := clampf(text_w + (76.0 if is_turn_message else 56.0), 186.0, 288.0) * pop
	var toast_h := (44.0 if is_turn_message else (36.0 if is_major_message else 31.0)) * pop

	var msg_style := _message_fx_style(_message_text)
	var msg_color := _message_fx_color(_message_text, alpha)
	if is_major_message:
		_draw_soft_sparkles(canvas, Vector2(DESIGN_W / 2.0, toast_y - 9.0), msg_color, alpha, true)
		canvas.draw_arc(Vector2(DESIGN_W / 2.0, toast_y + 1.0), (92.0 if is_turn_message else 74.0) * pop, -0.08 * PI, 1.08 * PI, 46, Color(msg_color.r, msg_color.g, msg_color.b, 0.22 * alpha), 2.6, true)
		canvas.draw_circle(Vector2(DESIGN_W / 2.0 - toast_w * 0.42, toast_y - toast_h * 0.18), 2.4 * pop, Color(1.0, 1.0, 0.78, 0.55 * alpha))
		canvas.draw_circle(Vector2(DESIGN_W / 2.0 + toast_w * 0.42, toast_y - toast_h * 0.20), 2.1 * pop, Color(1.0, 0.86, 0.42, 0.48 * alpha))
	else:
		canvas.draw_line(Vector2(DESIGN_W / 2.0 - toast_w * 0.28, toast_y + 12.0), Vector2(DESIGN_W / 2.0 + toast_w * 0.28, toast_y + 9.0), Color(msg_color.r, msg_color.g, msg_color.b, 0.22 * alpha), 1.6)

	_draw_fx_text(canvas, _message_text, DESIGN_W / 2.0, toast_y + (7.0 if is_turn_message else 5.0), msg_color, base_text_size * pop, toast_w - 28.0, msg_style)

# === 战局结束弹窗：元素级入场 transform 辅助 ===
# ease(s, 0.0) 在 Godot 4.6 始终返回 0，phase 2 改用 ease(s, -1.0)（线性）
func _overlay_bounce_scale(local_t: float, start_scale: float, overshoot: float) -> float:
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

func _overlay_ease_offset(local_t: float, total_offset: float) -> float:
	if local_t <= 0.0:
		return total_offset
	if local_t >= 1.0:
		return 0.0
	return total_offset * (1.0 - ease(local_t, -1.5))

# 给定元素起始时间 + 时长 + 起始 scale + overshoot + 起始 Y 偏移，返回 {alpha, scale, offset_y}
func _overlay_xform(start: float, duration: float, start_scale: float, overshoot: float, offset_y: float) -> Dictionary:
	var t := _battle_end_overlay_timer
	if t < start:
		return {"alpha": 0.0, "scale": start_scale, "offset_y": offset_y}
	var local_t := (t - start) / duration
	if local_t >= 1.0:
		return {"alpha": 1.0, "scale": 1.0, "offset_y": 0.0}
	return {
		"alpha": clampf(ease(local_t, -1.5), 0.0, 1.0),
		"scale": _overlay_bounce_scale(local_t, start_scale, overshoot),
		"offset_y": _overlay_ease_offset(local_t, offset_y),
	}

# 横向伸展（如下划线光晕）：从 0 宽度展到完整
func _overlay_stretch_x(start: float, duration: float) -> Dictionary:
	var t := _battle_end_overlay_timer
	if t < start:
		return {"alpha": 0.0, "scale_x": 0.0}
	var local_t := (t - start) / duration
	if local_t >= 1.0:
		return {"alpha": 1.0, "scale_x": 1.0}
	return {
		"alpha": clampf(ease(local_t, -1.5), 0.0, 1.0),
		"scale_x": ease(local_t, -1.0),  # 线性展开
	}

# 纯 fade 元素（背景遮罩）
func _overlay_fade(start: float, duration: float) -> float:
	var t := _battle_end_overlay_timer
	if t < start:
		return 0.0
	var local_t := (t - start) / duration
	if local_t >= 1.0:
		return 1.0
	return ease(local_t, -1.5)

# 围绕 center 做 scale 矩阵（供 _draw_texture_centered 之前用）
func _make_centered_scale_xform(center: Vector2, scale: float) -> Transform2D:
	var x := Transform2D()
	x = x.translated(Vector2(-center.x, -center.y))
	x = x.scaled(Vector2(scale, scale))
	x = x.translated(center)
	return x

# 围绕 center 做 (scale_x, 1.0) 横向 stretch 矩阵
func _make_centered_stretch_x_xform(center: Vector2, scale_x: float) -> Transform2D:
	var x := Transform2D()
	x = x.translated(Vector2(-center.x, -center.y))
	x = x.scaled(Vector2(scale_x, 1.0))
	x = x.translated(center)
	return x

# 围绕 center 做 (scale, scale) 缩放并叠加 (0, offset_y) 偏移
func _make_centered_scale_offset_xform(center: Vector2, scale: float, offset_y: float) -> Transform2D:
	var x := Transform2D()
	x = x.translated(Vector2(-center.x, -center.y - offset_y))
	x = x.scaled(Vector2(scale, scale))
	x = x.translated(Vector2(center.x, center.y + offset_y))
	return x

func _draw_battle_end_overlay(canvas: CanvasItem = self) -> void:
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)
	var is_win: bool = _battle != null and _battle.battle_result == "win"
	var t: float = _battle_end_overlay_timer
	var banner_y: float = DESIGN_H / 2.0 - 142.0
	var panel_center := Vector2(DESIGN_W / 2.0, DESIGN_H / 2.0 + 34.0)
	var banner_center := Vector2(DESIGN_W / 2.0, banner_y)
	var burst_center := Vector2(DESIGN_W / 2.0, DESIGN_H / 2.0 - 108.0)
	var plaque_center := Vector2(DESIGN_W / 2.0, DESIGN_H / 2.0 + 30.0)
	var tap_center := Vector2(DESIGN_W / 2.0, DESIGN_H / 2.0 + 91.0)
	var underline_center := Vector2(DESIGN_W / 2.0, DESIGN_H / 2.0 - 10.0)

	# 1) 背景遮罩：纯 fade
	var bg_alpha: float = _overlay_fade(BATTLE_END_BG_START, BATTLE_END_BG_DURATION)
	canvas.draw_rect(Rect2(0, 0, DESIGN_W, DESIGN_H), Color(0.0, 0.0, 0.0, 0.66 * bg_alpha))

	# 2) Victory burst：scale bounce + 上滑 + fade（仅胜利显示）
	if is_win:
		var burst_xform: Dictionary = _overlay_xform(BATTLE_END_BURST_START, BATTLE_END_BURST_DURATION, BATTLE_END_BURST_SCALE_START, 1.08, BATTLE_END_BURST_OFFSET_Y)
		var burst_tex := _get_texture(BATTLE_RESULT_OVERLAY_ASSETS["victory_burst"])
		canvas.draw_set_transform_matrix(_make_centered_scale_offset_xform(burst_center, burst_xform["scale"], burst_xform["offset_y"]))
		_draw_texture_centered_on(canvas, burst_tex, burst_center, Vector2(218.0, 136.0), 0.58 * burst_xform["alpha"])
		canvas.draw_set_transform_matrix(Transform2D.IDENTITY)
		_draw_victory_particles(bg_alpha, true, canvas)
	# 失败界面去掉 "defeat_smoke" 星星条带（原本贴图路径错配到 sparkles，已删除）

	# 3) Panel 面板：scale 0.92→1.0 + fade
	var panel_xform: Dictionary = _overlay_xform(BATTLE_END_PANEL_START, BATTLE_END_PANEL_DURATION, BATTLE_END_PANEL_SCALE_START, 1.0, 0.0)
	var panel_tex := _get_texture(BATTLE_RESULT_OVERLAY_ASSETS["panel"])
	canvas.draw_set_transform_matrix(_make_centered_scale_xform(panel_center, panel_xform["scale"]))
	_draw_texture_centered_on(canvas, panel_tex, panel_center, Vector2(292.0, 158.0), panel_xform["alpha"])
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)

	# 4) Banner 条幅：scale bounce + 上滑 + fade；标题文字跟随矩阵一起 pop
	var banner_xform: Dictionary = _overlay_xform(BATTLE_END_BANNER_START, BATTLE_END_BANNER_DURATION, BATTLE_END_BANNER_SCALE_START, 1.05, BATTLE_END_BANNER_OFFSET_Y)
	var banner_path: String = BATTLE_RESULT_OVERLAY_ASSETS["victory_banner"] if is_win else BATTLE_RESULT_OVERLAY_ASSETS["defeat_banner"]
	var banner_tex := _get_texture(banner_path)
	canvas.draw_set_transform_matrix(_make_centered_scale_offset_xform(banner_center, banner_xform["scale"], banner_xform["offset_y"]))
	_draw_texture_centered_on(canvas, banner_tex, banner_center, Vector2(316.0, 114.0), banner_xform["alpha"])
	var title_text := "胜利" if is_win else "失败"
	var title_color: Color = C["gold"] if is_win else Color(0.78, 0.78, 0.86)
	_draw_battle_end_text_on(canvas, title_text, Vector2(DESIGN_W / 2.0, banner_y - 3.0), title_color, 44.0, 170.0)
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)

	# 5) 下划线光晕：横向伸展
	var underline_xform: Dictionary = _overlay_stretch_x(BATTLE_END_UNDERLINE_START, BATTLE_END_UNDERLINE_DURATION)
	canvas.draw_set_transform_matrix(_make_centered_stretch_x_xform(underline_center, underline_xform["scale_x"]))
	_draw_underline_glow_on(canvas, underline_center, 110.0, 0.85 * underline_xform["alpha"])
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)

	# 6) Capture plaque / state text：scale bounce + fade
	var state_text := "点击查看结算"
	var state_color: Color = C["text_muted"]
	if _capture_phase != "done" and _capture_phase != "":
		state_text = "收服判定中..."
		state_color = C["gold"]
	elif not _capture_result_text.is_empty():
		state_text = _clean_battle_end_status_text(str(_capture_result_text.get("title", state_text)))
		state_color = C["success"] if _capture_success else Color(0.52, 0.67, 0.86)

	if not _capture_result_text.is_empty():
		var plaque_xform: Dictionary = _overlay_xform(BATTLE_END_PLAQUE_START, BATTLE_END_PLAQUE_DURATION, BATTLE_END_PLAQUE_SCALE_START, 1.05, 0.0)
		var plaque_tex := _get_texture(BATTLE_RESULT_OVERLAY_ASSETS["capture_plaque"])
		canvas.draw_set_transform_matrix(_make_centered_scale_xform(plaque_center, plaque_xform["scale"]))
		_draw_texture_centered_on(canvas, plaque_tex, plaque_center, Vector2(218.0, 54.0), plaque_xform["alpha"])
		_draw_battle_end_text_on(canvas, state_text, Vector2(DESIGN_W / 2.0, DESIGN_H / 2.0 + 30.0), state_color, 16.0, 172.0)
		canvas.draw_set_transform_matrix(Transform2D.IDENTITY)
	else:
		# 没有 plaque 时仅 state text 用 pop
		var state_xform: Dictionary = _overlay_xform(BATTLE_END_PLAQUE_START, BATTLE_END_PLAQUE_DURATION, BATTLE_END_PLAQUE_SCALE_START, 1.05, 0.0)
		canvas.draw_set_transform_matrix(_make_centered_scale_xform(Vector2(DESIGN_W / 2.0, DESIGN_H / 2.0 + 28.0), state_xform["scale"]))
		_draw_battle_end_text_on(canvas, state_text, Vector2(DESIGN_W / 2.0, DESIGN_H / 2.0 + 28.0), state_color, 16.0, 172.0)
		canvas.draw_set_transform_matrix(Transform2D.IDENTITY)

	# 7) Tap strip / 继续按钮：scale bounce + 上滑 + fade
	var tap_xform: Dictionary = _overlay_xform(BATTLE_END_TAP_START, BATTLE_END_TAP_DURATION, BATTLE_END_TAP_SCALE_START, 1.06, BATTLE_END_TAP_OFFSET_Y)
	canvas.draw_set_transform_matrix(_make_centered_scale_offset_xform(tap_center, tap_xform["scale"], tap_xform["offset_y"]))
	if _capture_phase == "done" or _capture_phase == "":
		var tap_tex := _get_texture(BATTLE_RESULT_OVERLAY_ASSETS["tap_strip"])
		_draw_texture_centered_on(canvas, tap_tex, tap_center, Vector2(194.0, 54.0), 0.92 * tap_xform["alpha"])
		_draw_battle_end_text_on(canvas, "点击继续", Vector2(DESIGN_W / 2.0, DESIGN_H / 2.0 + 91.0), C["white"], 15.0, 140.0)
	else:
		var button_tex := _get_texture(BATTLE_RESULT_OVERLAY_ASSETS["button_continue"])
		_draw_texture_centered_on(canvas, button_tex, tap_center, Vector2(194.0, 54.0), 0.65 * tap_xform["alpha"])
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)

func _clean_battle_end_status_text(text: String) -> String:
	var cleaned := text.strip_edges()
	for token in ["👉", "👈", "👆", "👇", "☞", "☝"]:
		cleaned = cleaned.replace(token, "")
	return cleaned.strip_edges()

func _draw_phase_transition() -> void:
	if _phase_transition_state.is_empty():
		return
	
	var timer: float = _phase_transition_state.get("timer", 0.0)
	if timer <= 0:
		_phase_transition_state.clear()  # 状态清空
		return
	if timer <= 0.5:
		return
	
	var alpha: float = mini(1.0, (timer - 0.5) * 2.0)
	var boss_name: String = _phase_transition_state.get("boss_name", "BOSS")
	
	_draw_rounded_rect(DESIGN_W / 2.0 - 120, DESIGN_H / 2.0 - 30, 240, 60, 12.0, Color(0.0, 0.0, 0.0, 0.8))
	
	var fire_color := Color(1.0, 0.4, 0.1, alpha)
	_draw_fx_text(self, boss_name, DESIGN_W / 2.0, DESIGN_H / 2.0 - 3, fire_color, 16.0, 220.0, "damage")
	_draw_fx_text(self, "进入激战状态!", DESIGN_W / 2.0, DESIGN_H / 2.0 + 22, Color(1.0, 0.86, 0.30, alpha), 14.0, 220.0, "gold")

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
	
	var room := OBSTACLE_PARTICLE_LIMIT - _obstacle_particles.size()
	if room <= 0:
		return
	var particle_count: int = mini(12, room)
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

func _update_item_use_effects(delta: float) -> void:
	for i in range(_item_use_effects.size() - 1, -1, -1):
		var fx: Dictionary = _item_use_effects[i]
		fx["timer"] = float(fx.get("timer", 0.0)) + delta
		if float(fx.get("timer", 0.0)) >= float(fx.get("duration", 0.75)):
			_item_use_effects.remove_at(i)

func _update_defeat_particles(delta: float) -> void:
	BattleAnimationControllerScript.update_particle_list(_defeat_explosions, delta, 180.0)

func _spawn_item_use_effect(kind: String, center: Vector2, color: Color, duration: float = 0.75, extra: Dictionary = {}) -> void:
	var fx := extra.duplicate(true)
	fx["kind"] = kind
	fx["x"] = center.x
	fx["y"] = center.y
	fx["color"] = color
	fx["timer"] = 0.0
	fx["duration"] = duration
	_item_use_effects.append(fx)
	while _item_use_effects.size() > ITEM_USE_EFFECT_LIMIT:
		_item_use_effects.remove_at(0)

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
	_victory_particles.clear()
	# 全屏胜利粒子爆发
	var colors: Array[Color] = [
		Color(1.0, 0.23, 0.42),
		Color(1.0, 0.78, 0.10),
		Color(0.34, 0.78, 1.0),
		Color(0.72, 0.36, 1.0),
		Color(0.54, 1.0, 0.42)
	]
	for i in range(42):
		var x: float = -24.0 + randf() * (DESIGN_W + 48.0)
		var y: float = -170.0 + randf() * 250.0
		var vx: float = (randf() - 0.5) * 24.0
		var vy: float = 36.0 + randf() * 72.0
		var color: Color = colors[randi() % colors.size()]
		_victory_particles.append({
			"x": x,
			"y": y,
			"vx": vx,
			"vy": vy,
			"gravity": 6.0 + randf() * 12.0,
			"life": 2.6 + randf() * 1.4,
			"max_life": 2.6 + randf() * 1.4,
			"color": color,
			"w": 8.0 + randf() * 7.0,
			"h": 22.0 + randf() * 22.0,
			"angle": randf() * TAU,
			"spin": -3.6 + randf() * 7.2,
			"swing": 8.0 + randf() * 18.0,
			"swing_freq": 0.8 + randf() * 1.8,
			"phase": randf() * TAU
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

func _draw_item_use_effects() -> void:
	for fx: Dictionary in _item_use_effects:
		var duration := maxf(0.01, float(fx.get("duration", 0.75)))
		var progress := clampf(float(fx.get("timer", 0.0)) / duration, 0.0, 1.0)
		var alpha := clampf(1.0 - maxf(0.0, progress - 0.62) / 0.38, 0.0, 1.0)
		var center := Vector2(float(fx.get("x", 0.0)), float(fx.get("y", 0.0)))
		var color: Color = fx.get("color", C["gold"])
		match str(fx.get("kind", "")):
			"hammer":
				_draw_item_fx_hammer(fx, center, color, progress, alpha)
			"heal":
				_draw_item_fx_heal(center, color, progress, alpha)
			"guard":
				_draw_item_fx_guard(center, color, progress, alpha, false)
			"absorb":
				_draw_item_fx_guard(center, color, progress, alpha, true)
			"charge":
				_draw_item_fx_charge(center, color, progress, alpha)
			"board_reset":
				_draw_item_fx_board_reset(center, color, progress, alpha)
			"gem_shift":
				_draw_item_fx_gem_shift(fx, center, color, progress, alpha)
			"unlock":
				_draw_item_fx_unlock(center, color, progress, alpha)
			"cleanse":
				_draw_item_fx_cleanse(center, color, progress, alpha)

func _draw_item_fx_hammer(fx: Dictionary, center: Vector2, color: Color, progress: float, alpha: float) -> void:
	var swing := clampf(progress / 0.38, 0.0, 1.0)
	var hammer_pos := center + Vector2(lerpf(-22.0, 3.0, swing), lerpf(-34.0, -8.0, swing))
	var hammer_size := 29.0 + sin(swing * PI) * 5.0
	var hammer_tex := _get_texture(BATTLE_UI_ASSETS.get("item_rock_hammer", ""))
	if hammer_tex:
		_draw_texture_contain(hammer_tex, Rect2(hammer_pos.x - hammer_size / 2.0, hammer_pos.y - hammer_size / 2.0, hammer_size, hammer_size), clampf(alpha + 0.12, 0.0, 1.0))
	else:
		draw_line(hammer_pos + Vector2(-8.0, 10.0), hammer_pos + Vector2(8.0, -10.0), Color(0.80, 0.40, 0.16, alpha), 4.0)
		_draw_rounded_rect(hammer_pos.x - 11.0, hammer_pos.y - 13.0, 20.0, 10.0, 2.0, Color(1.0, 0.32, 0.18, alpha))
	var impact := clampf((progress - 0.16) / 0.38, 0.0, 1.0)
	if impact <= 0.0:
		return
	var ring_alpha := alpha * (1.0 - impact)
	draw_arc(center, 8.0 + impact * 28.0, 0.0, TAU, 44, Color(color.r, color.g, color.b, 0.75 * ring_alpha), 3.0, true)
	draw_arc(center, 4.0 + impact * 16.0, 0.0, TAU, 34, Color(1.0, 1.0, 1.0, 0.45 * ring_alpha), 1.5, true)
	for i in range(7):
		var angle := float(i) * TAU / 7.0 + 0.22
		var dir := Vector2(cos(angle), sin(angle))
		var crack_len := 9.0 + impact * 18.0 + (4.0 if bool(fx.get("strong", false)) else 0.0)
		draw_line(center + dir * 4.0, center + dir * crack_len, Color(0.42, 0.22, 0.11, 0.72 * alpha), 1.4)
	for i in range(5):
		var angle := float(i) * TAU / 5.0 + progress * 0.8
		var chip_pos := center + Vector2(cos(angle), sin(angle)) * (8.0 + impact * 18.0)
		_draw_rounded_rect(chip_pos.x - 2.0, chip_pos.y - 2.0, 4.0, 4.0, 1.0, Color(0.78, 0.54, 0.28, alpha * (1.0 - impact * 0.35)))

func _draw_item_fx_heal(center: Vector2, color: Color, progress: float, alpha: float) -> void:
	var pulse := sin(clampf(progress / 0.42, 0.0, 1.0) * PI)
	draw_circle(center, 17.0 + progress * 18.0, Color(color.r, color.g, color.b, 0.16 * alpha))
	draw_arc(center, 20.0 + pulse * 5.0, 0.0, TAU, 42, Color(color.r, color.g, color.b, 0.65 * alpha), 2.4, true)
	draw_line(center + Vector2(-8.0, 0.0), center + Vector2(8.0, 0.0), Color(1.0, 1.0, 1.0, 0.82 * alpha), 3.0)
	draw_line(center + Vector2(0.0, -8.0), center + Vector2(0.0, 8.0), Color(1.0, 1.0, 1.0, 0.82 * alpha), 3.0)
	_draw_soft_sparkles(self, center, color, alpha, true)

func _draw_item_fx_guard(center: Vector2, color: Color, progress: float, alpha: float, absorb: bool) -> void:
	var scale := 1.0 + sin(clampf(progress / 0.36, 0.0, 1.0) * PI) * 0.12
	var radius := (26.0 if absorb else 23.0) * scale
	draw_circle(center, radius, Color(color.r, color.g, color.b, (0.16 if absorb else 0.11) * alpha))
	draw_arc(center, radius, -0.18 * PI, 1.18 * PI, 52, Color(color.r, color.g, color.b, 0.78 * alpha), 2.6 if absorb else 2.2, true)
	draw_arc(center, radius - 6.0, 0.82 * PI, 1.86 * PI, 34, Color(1.0, 1.0, 1.0, 0.42 * alpha), 1.3, true)
	if absorb:
		draw_arc(center, radius + 5.0 + progress * 8.0, 0.0, TAU, 56, Color(0.76, 0.96, 1.0, 0.32 * alpha * (1.0 - progress * 0.35)), 1.8, true)

func _draw_item_fx_charge(center: Vector2, color: Color, progress: float, alpha: float) -> void:
	var radius := 20.0 + sin(progress * PI) * 8.0
	for i in range(5):
		var angle := progress * TAU * 1.4 + float(i) * TAU / 5.0
		var pos := center + Vector2(cos(angle), sin(angle)) * radius
		draw_circle(pos, 3.2, Color(color.r, color.g, color.b, 0.74 * alpha))
	draw_arc(center, radius + 2.0, -0.2 * PI, 1.1 * PI, 44, Color(color.r, color.g, color.b, 0.45 * alpha), 2.0, true)

func _draw_item_fx_board_reset(center: Vector2, color: Color, progress: float, alpha: float) -> void:
	if _board != null:
		var board_rect := Rect2(float(_board.offset_x), float(_board.offset_y), float(_board.cols * _board.cell_size), float(_board.rows * _board.cell_size))
		var sweep_x := lerpf(board_rect.position.x, board_rect.end.x, clampf(progress / 0.72, 0.0, 1.0))
		draw_rect(Rect2(sweep_x - 9.0, board_rect.position.y, 18.0, board_rect.size.y), Color(color.r, color.g, color.b, 0.16 * alpha))
		_draw_stroke_rect_on(self, board_rect.position.x - 2.0, board_rect.position.y - 2.0, board_rect.size.x + 4.0, board_rect.size.y + 4.0, 2.0, Color(color.r, color.g, color.b, 0.55 * alpha))
	draw_arc(center, 42.0 + progress * 92.0, 0.0, TAU, 72, Color(color.r, color.g, color.b, 0.34 * alpha * (1.0 - progress * 0.45)), 3.0, true)

func _draw_item_fx_gem_shift(fx: Dictionary, center: Vector2, color: Color, progress: float, alpha: float) -> void:
	var source_color: Color = GEM_COLORS.get(str(fx.get("source", "")), C["white"])
	var target_color: Color = GEM_COLORS.get(str(fx.get("target", "")), color)
	draw_arc(center, 38.0 + progress * 92.0, -0.1 * PI, 1.1 * PI, 68, Color(source_color.r, source_color.g, source_color.b, 0.34 * alpha), 3.0, true)
	draw_arc(center, 24.0 + progress * 74.0, 0.9 * PI, 1.95 * PI, 58, Color(target_color.r, target_color.g, target_color.b, 0.52 * alpha), 3.2, true)
	for i in range(6):
		var angle := progress * TAU + float(i) * TAU / 6.0
		var pos := center + Vector2(cos(angle), sin(angle)) * (20.0 + progress * 45.0)
		draw_circle(pos, 3.5, Color(target_color.r, target_color.g, target_color.b, 0.70 * alpha))

func _draw_item_fx_unlock(center: Vector2, color: Color, progress: float, alpha: float) -> void:
	var burst := sin(clampf(progress / 0.42, 0.0, 1.0) * PI)
	draw_arc(center, 12.0 + progress * 28.0, 0.0, TAU, 38, Color(color.r, color.g, color.b, 0.46 * alpha), 2.0, true)
	for i in range(4):
		var angle := float(i) * TAU / 4.0 + PI / 4.0
		var dir := Vector2(cos(angle), sin(angle))
		draw_line(center - dir * 4.0, center + dir * (12.0 + burst * 10.0), Color(1.0, 0.92, 0.42, 0.72 * alpha), 2.0)

func _draw_item_fx_cleanse(center: Vector2, color: Color, progress: float, alpha: float) -> void:
	draw_circle(center, 18.0 + progress * 20.0, Color(color.r, color.g, color.b, 0.12 * alpha))
	for i in range(5):
		var angle := float(i) * TAU / 5.0 + progress * 0.8
		var pos := center + Vector2(cos(angle), sin(angle)) * (8.0 + progress * 18.0)
		draw_circle(pos, 2.6 + progress * 2.0, Color(0.74, 1.0, 0.88, 0.62 * alpha))

func _draw_defeat_particles() -> void:
	for p: Dictionary in _defeat_explosions:
		var progress: float = 1.0 - p["life"] / p["max_life"]
		var alpha: float = 1.0 - progress
		var size: float = p["size"] * (1.0 - progress * 0.5)
		var color: Color = Color(p["color"].r, p["color"].g, p["color"].b, alpha)
		_draw_circle(p["x"], p["y"], size, color)

func _draw_victory_particles(opacity: float = 1.0, overlay_pass: bool = false, canvas: CanvasItem = null) -> void:
	if _state == BattleState.BATTLE_END and not overlay_pass:
		return
	if canvas == null:
		canvas = self
	for p: Dictionary in _victory_particles:
		var progress: float = 1.0 - p["life"] / p["max_life"]
		var alpha: float = clampf((1.0 - progress * 0.55) * opacity, 0.0, 1.0)
		var w: float = p.get("w", 10.0)
		var h: float = p.get("h", 28.0)
		var x: float = p["x"] + sin(progress * TAU * p.get("swing_freq", 1.0) + p.get("phase", 0.0)) * p.get("swing", 10.0)
		var y: float = p["y"]
		var angle: float = p.get("angle", 0.0) + progress * p.get("spin", 0.0)
		var color: Color = Color(p["color"].r, p["color"].g, p["color"].b, alpha)
		canvas.draw_set_transform(Vector2(x, y), angle, Vector2.ONE)
		canvas.draw_rect(Rect2(-w * 0.5, -h * 0.5, w, h), color)
		canvas.draw_rect(Rect2(-w * 0.32, -h * 0.45, maxf(1.0, w * 0.22), h * 0.9), Color(1.0, 1.0, 1.0, alpha * 0.22))
		canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

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

func _draw_rounded_rect_on(canvas: CanvasItem, x: float, y: float, w: float, h: float, r: float, color: Color) -> void:
	canvas.draw_rect(Rect2(x + r, y, w - r * 2, h), color)
	canvas.draw_rect(Rect2(x, y + r, w, h - r * 2), color)
	canvas.draw_rect(Rect2(x, y, r, r), color)
	canvas.draw_rect(Rect2(x + w - r, y, r, r), color)
	canvas.draw_rect(Rect2(x, y + h - r, r, r), color)
	canvas.draw_rect(Rect2(x + w - r, y + h - r, r, r), color)

func _draw_rounded_rect_outline(x: float, y: float, w: float, h: float, r: float, color: Color, line_width: float = 2.0) -> void:
	_draw_stroke_rect(x, y, w, h, line_width, color)

func _draw_rounded_rect_outline_on(canvas: CanvasItem, x: float, y: float, w: float, h: float, r: float, color: Color, line_width: float = 2.0) -> void:
	_draw_stroke_rect_on(canvas, x, y, w, h, line_width, color)

func _draw_text(text: String, x: float, y: float, color: Color, size: float, center: bool = false) -> void:
	var font: Font = ThemeDB.fallback_font
	var align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER if center else HORIZONTAL_ALIGNMENT_LEFT
	if center:
		draw_string(font, Vector2(x, y + size * 0.75), text, align, -1.0, size, color)
	else:
		draw_string(font, Vector2(x, y + size * 0.75), text, align, -1.0, size, color)

func _draw_stroke_rect(x: float, y: float, w: float, h: float, line_width: float, color: Color) -> void:
	# 简化：使用 4 条线绘制边框
	draw_rect(Rect2(x, y, w, line_width), color)
	draw_rect(Rect2(x, y + h - line_width, w, line_width), color)
	draw_rect(Rect2(x, y, line_width, h), color)
	draw_rect(Rect2(x + w - line_width, y, line_width, h), color)

func _draw_stroke_rect_on(canvas: CanvasItem, x: float, y: float, w: float, h: float, line_width: float, color: Color) -> void:
	canvas.draw_rect(Rect2(x, y, w, line_width), color)
	canvas.draw_rect(Rect2(x, y + h - line_width, w, line_width), color)
	canvas.draw_rect(Rect2(x, y, line_width, h), color)
	canvas.draw_rect(Rect2(x + w - line_width, y, line_width, h), color)

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
	var monster_id: String = monster.get("monsterId", monster.get("id", ""))
	var path: String = MonsterArtDBScript.get_art_path(monster_id, "battle")
	return _get_texture(path)

func _draw_texture_fit(tex: Texture2D, rect: Rect2, opacity: float = 1.0) -> void:
	if tex == null:
		return
	draw_texture_rect(tex, rect, false, Color(1, 1, 1, opacity))

func _draw_texture_fit_on(canvas: CanvasItem, tex: Texture2D, rect: Rect2, opacity: float = 1.0) -> void:
	if tex == null:
		return
	canvas.draw_texture_rect(tex, rect, false, Color(1, 1, 1, opacity))

func _draw_texture_contain(tex: Texture2D, rect: Rect2, opacity: float = 1.0) -> void:
	if tex == null:
		return
	var tex_size := tex.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	var scale: float = minf(rect.size.x / tex_size.x, rect.size.y / tex_size.y)
	var draw_size := tex_size * scale
	var target := Rect2(rect.position + (rect.size - draw_size) / 2.0, draw_size)
	draw_texture_rect(tex, target, false, Color(1.0, 1.0, 1.0, opacity))

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

func _draw_texture_centered_on(canvas: CanvasItem, tex: Texture2D, center: Vector2, size: Vector2, opacity: float = 1.0) -> void:
	if tex == null:
		return
	_draw_texture_fit_on(canvas, tex, Rect2(center - size / 2.0, size), opacity)

## 战斗结算面板下划线：渐变金色细横线（替代原本的 sparkles 星星条带）
func _draw_underline_glow(center: Vector2, half_width: float, alpha: float = 1.0) -> void:
	var line_y := center.y
	var line_h := 1.6
	# 主体横线：暗金渐变（中央亮，向两侧暗）
	var grad_steps := 12
	for i in range(grad_steps):
		var t0: float = float(i) / float(grad_steps)
		var t1: float = float(i + 1) / float(grad_steps)
		var x0: float = lerpf(-half_width, half_width, t0)
		var x1: float = lerpf(-half_width, half_width, t1)
		var edge_fade: float = 1.0 - pow(absf((t0 + t1) * 0.5 - 0.5) * 2.0, 1.6)
		var col := Color(0.96, 0.78, 0.36, 0.78 * alpha * edge_fade)
		draw_rect(Rect2(center.x + x0, line_y, x1 - x0, line_h), col)
	# 中央高光：细一点的白金色短线
	var glow_w: float = half_width * 0.45
	draw_rect(Rect2(center.x - glow_w, line_y - 0.5, glow_w * 2.0, line_h + 1.0), Color(1.0, 0.92, 0.66, 0.55 * alpha))
	# 上下光晕
	draw_rect(Rect2(center.x - half_width * 0.85, line_y - 2.5, half_width * 1.7, 0.8), Color(1.0, 0.86, 0.42, 0.22 * alpha))
	draw_rect(Rect2(center.x - half_width * 0.85, line_y + line_h + 1.5, half_width * 1.7, 0.8), Color(1.0, 0.86, 0.42, 0.22 * alpha))

func _draw_underline_glow_on(canvas: CanvasItem, center: Vector2, half_width: float, alpha: float = 1.0) -> void:
	var line_y := center.y
	var line_h := 1.6
	var grad_steps := 12
	for i in range(grad_steps):
		var t0: float = float(i) / float(grad_steps)
		var t1: float = float(i + 1) / float(grad_steps)
		var x0: float = lerpf(-half_width, half_width, t0)
		var x1: float = lerpf(-half_width, half_width, t1)
		var edge_fade: float = 1.0 - pow(absf((t0 + t1) * 0.5 - 0.5) * 2.0, 1.6)
		var col := Color(0.96, 0.78, 0.36, 0.78 * alpha * edge_fade)
		canvas.draw_rect(Rect2(center.x + x0, line_y, x1 - x0, line_h), col)
	var glow_w: float = half_width * 0.45
	canvas.draw_rect(Rect2(center.x - glow_w, line_y - 0.5, glow_w * 2.0, line_h + 1.0), Color(1.0, 0.92, 0.66, 0.55 * alpha))
	canvas.draw_rect(Rect2(center.x - half_width * 0.85, line_y - 2.5, half_width * 1.7, 0.8), Color(1.0, 0.86, 0.42, 0.22 * alpha))
	canvas.draw_rect(Rect2(center.x - half_width * 0.85, line_y + line_h + 1.5, half_width * 1.7, 0.8), Color(1.0, 0.86, 0.42, 0.22 * alpha))

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
	var panel_tex := _get_texture("res://assets/images/ui/panels/battle_ui_panel_dark_large.png")
	if panel_tex:
		_draw_texture_fit(panel_tex, Rect2(x, y, w, h), opacity)
	else:
		var panel_color := color
		panel_color.a *= opacity
		_draw_rounded_rect(x, y, w, h, 8.0, panel_color)

func _draw_text_with_shadow(text: String, x: float, y: float, color: Color, size: float, bold: bool = false) -> void:
	BattleUIFeedbackScript.draw_text_with_shadow(self, text, x, y, color, size, 200.0, HORIZONTAL_ALIGNMENT_CENTER, bold)

func _draw_text_with_shadow_on(canvas: CanvasItem, text: String, x: float, y: float, color: Color, size: float, bold: bool = false) -> void:
	BattleUIFeedbackScript.draw_text_with_shadow(canvas, text, x, y, color, size, 200.0, HORIZONTAL_ALIGNMENT_CENTER, bold)

func _draw_hp_text_in_bar(text: String, rect: Rect2, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var size: int = int(round(clampf(rect.size.y * 0.36, 3.4, 5.0)))
	var max_width: float = maxf(12.0, rect.size.x - 12.0)
	var safe_text := BattleUIFeedbackScript.fit_text(font, text, max_width, size)
	var center_x := rect.get_center().x
	var baseline_y := rect.position.y + rect.size.y * 0.64
	var left := center_x - max_width * 0.5
	var shadow := Color(0.06, 0.10, 0.13, 0.82)
	draw_string(font, Vector2(left - 0.45, baseline_y), safe_text, HORIZONTAL_ALIGNMENT_CENTER, max_width, size, shadow)
	draw_string(font, Vector2(left + 0.45, baseline_y), safe_text, HORIZONTAL_ALIGNMENT_CENTER, max_width, size, shadow)
	draw_string(font, Vector2(left, baseline_y - 0.45), safe_text, HORIZONTAL_ALIGNMENT_CENTER, max_width, size, shadow)
	draw_string(font, Vector2(left, baseline_y + 0.55), safe_text, HORIZONTAL_ALIGNMENT_CENTER, max_width, size, shadow)
	draw_string(font, Vector2(left, baseline_y), safe_text, HORIZONTAL_ALIGNMENT_CENTER, max_width, size, color)

func _draw_battle_end_text_on(canvas: CanvasItem, text: String, center: Vector2, color: Color, size: float, max_width: float) -> void:
	if text.is_empty():
		return
	var safe_text := BattleUIFeedbackScript.fit_text(FX_ROUND_FONT, text, max_width, size)
	var left := center.x - max_width / 2.0
	var baseline_y := center.y + (FX_ROUND_FONT.get_ascent(size) - FX_ROUND_FONT.get_descent(size)) * 0.5
	canvas.draw_string(FX_ROUND_FONT, Vector2(left, baseline_y), safe_text, HORIZONTAL_ALIGNMENT_CENTER, max_width, size, color)

func _draw_fx_text(canvas: CanvasItem, text: String, x: float, y: float, color: Color, size: float, max_width: float = 190.0, style: String = "normal") -> void:
	if text.is_empty():
		return
	var safe_text := BattleUIFeedbackScript.fit_text(FX_ROUND_FONT, text, max_width, size)
	var left := x - max_width / 2.0
	var palette := _fx_text_palette(style, color)
	var shadow: Color = palette["shadow"]
	var outline: Color = palette["outline"]
	var rim: Color = palette["rim"]
	var fill: Color = palette["fill"]
	var shine: Color = palette["shine"]
	var alpha := color.a
	shadow.a *= alpha
	outline.a *= alpha
	rim.a *= alpha
	fill.a *= alpha
	shine.a *= alpha
	var outline_size := maxf(2.0, size * 0.15)
	var rim_size := maxf(1.0, size * 0.07)
	canvas.draw_string(FX_ROUND_FONT, Vector2(left + 0.0, y + outline_size + 1.4), safe_text, HORIZONTAL_ALIGNMENT_CENTER, max_width, size, shadow)
	var outline_steps := [
		Vector2(-outline_size, 0.0), Vector2(outline_size, 0.0),
		Vector2(0.0, -outline_size), Vector2(0.0, outline_size),
		Vector2(-outline_size * 0.72, -outline_size * 0.72),
		Vector2(outline_size * 0.72, -outline_size * 0.72),
		Vector2(-outline_size * 0.72, outline_size * 0.72),
		Vector2(outline_size * 0.72, outline_size * 0.72)
	]
	for offset: Vector2 in outline_steps:
		canvas.draw_string(FX_ROUND_FONT, Vector2(left + offset.x, y + offset.y), safe_text, HORIZONTAL_ALIGNMENT_CENTER, max_width, size, outline)
	canvas.draw_string(FX_ROUND_FONT, Vector2(left - rim_size, y - rim_size), safe_text, HORIZONTAL_ALIGNMENT_CENTER, max_width, size, rim)
	canvas.draw_string(FX_ROUND_FONT, Vector2(left, y), safe_text, HORIZONTAL_ALIGNMENT_CENTER, max_width, size, fill)
	canvas.draw_string(FX_ROUND_FONT, Vector2(left + 0.8, y), safe_text, HORIZONTAL_ALIGNMENT_CENTER, max_width, size, fill)
	canvas.draw_string(FX_ROUND_FONT, Vector2(left, y - size * 0.13), safe_text, HORIZONTAL_ALIGNMENT_CENTER, max_width, size * 0.92, shine)

func _draw_combo_art_text(canvas: CanvasItem, combo: int, cx: float, cy: float, scale: float, opacity: float) -> void:
	var combo_tex := _get_texture(BATTLE_FX_ASSETS["combo_word"])
	if combo_tex:
		var tex_size := combo_tex.get_size()
		var word_h := 54.0 * scale
		var word_w := word_h * (tex_size.x / maxf(1.0, tex_size.y))
		_draw_texture_fit_on(canvas, combo_tex, Rect2(cx - 112.0 * scale, cy - 42.0 * scale, word_w, word_h), opacity)
	else:
		_draw_fx_text(canvas, "COMBO", cx - 24.0 * scale, cy + 1.0 * scale, Color(1.0, 0.72, 0.22, opacity), 27.0 * scale, 172.0 * scale, "combo_number")
	_draw_digit_fx_text(canvas, "x%d" % combo, cx + 105.0 * scale, cy + 10.0 * scale, 56.0 * scale, opacity, "combo_number")
	var accent := Color(1.0, 0.98, 0.62, 0.54 * opacity)
	canvas.draw_line(Vector2(cx - 96.0 * scale, cy + 20.0 * scale), Vector2(cx + 158.0 * scale, cy + 10.0 * scale), accent, 2.2 * scale)
	canvas.draw_circle(Vector2(cx - 103.0 * scale, cy - 15.0 * scale), 3.2 * scale, Color(1.0, 0.92, 0.35, 0.62 * opacity))
	canvas.draw_circle(Vector2(cx + 178.0 * scale, cy - 18.0 * scale), 2.5 * scale, Color(1.0, 0.76, 0.34, 0.58 * opacity))

func _is_digit_fx_text(text: String) -> bool:
	if text.is_empty():
		return false
	for i in range(text.length()):
		var ch := text.substr(i, 1)
		if not _is_digit_char(ch) and not ["-", "+", "x", "×"].has(ch):
			return false
	return true

func _draw_digit_fx_text(canvas: CanvasItem, text: String, x: float, y: float, size: float, opacity: float, style: String = "damage") -> void:
	var atlas := _get_texture(BATTLE_FX_ASSETS["damage_digits"])
	if atlas == null:
		_draw_fx_text(canvas, text, x, y, Color(1.0, 0.76, 0.22, opacity), size, maxf(80.0, text.length() * size), style)
		return
	var cell_w := 72.0
	var cell_h := 84.0
	var target_h := maxf(24.0, size * 1.92)
	var digit_w := target_h * 0.72
	var sign_w := target_h * 0.42
	var spacing := -target_h * 0.10
	var total_w := 0.0
	for i in range(text.length()):
		var ch := text.substr(i, 1)
		total_w += sign_w if ["-", "+", "x", "×"].has(ch) else digit_w
		if i < text.length() - 1:
			total_w += spacing
	var left := x - total_w / 2.0
	var tint := _digit_fx_tint(style, opacity)
	for i in range(text.length()):
		var ch := text.substr(i, 1)
		var w := sign_w if ["-", "+", "x", "×"].has(ch) else digit_w
		var center := Vector2(left + w / 2.0, y - target_h * 0.40)
		if _is_digit_char(ch):
			var digit := ch.unicode_at(0) - 48
			var src := Rect2(digit * cell_w, 0.0, cell_w, cell_h)
			var dst := Rect2(left, y - target_h * 0.92, digit_w, target_h)
			canvas.draw_texture_rect_region(atlas, dst, src, tint)
		elif ch == "-":
			canvas.draw_line(center - Vector2(w * 0.32, 0.0), center + Vector2(w * 0.32, 0.0), Color(0.58, 0.20, 0.10, 0.82 * opacity), maxf(3.0, target_h * 0.14))
			canvas.draw_line(center - Vector2(w * 0.28, 0.0), center + Vector2(w * 0.28, 0.0), Color(1.0, 0.77, 0.28, opacity), maxf(2.0, target_h * 0.09))
		elif ch == "+":
			var dark := Color(0.58, 0.20, 0.10, 0.82 * opacity)
			var light := Color(1.0, 0.77, 0.28, opacity)
			canvas.draw_line(center - Vector2(w * 0.32, 0.0), center + Vector2(w * 0.32, 0.0), dark, maxf(3.0, target_h * 0.14))
			canvas.draw_line(center - Vector2(0.0, w * 0.32), center + Vector2(0.0, w * 0.32), dark, maxf(3.0, target_h * 0.14))
			canvas.draw_line(center - Vector2(w * 0.28, 0.0), center + Vector2(w * 0.28, 0.0), light, maxf(2.0, target_h * 0.09))
			canvas.draw_line(center - Vector2(0.0, w * 0.28), center + Vector2(0.0, w * 0.28), light, maxf(2.0, target_h * 0.09))
		else:
			_draw_fx_text(canvas, "x", center.x, y - target_h * 0.13, Color(1.0, 0.70, 0.22, opacity), size * 0.95, w + 8.0, "combo_label")
		left += w + spacing

func _is_digit_char(ch: String) -> bool:
	if ch.is_empty():
		return false
	var code := ch.unicode_at(0)
	return code >= 48 and code <= 57

func _digit_fx_tint(style: String, opacity: float) -> Color:
	match style:
		"heal":
			return Color(0.82, 1.0, 0.70, opacity)
		"cool":
			return Color(0.78, 0.94, 1.0, opacity)
		_:
			return Color(1.0, 1.0, 1.0, opacity)

func _fx_text_style(text: String, color: Color) -> String:
	if text.begins_with("+") or color.g > color.r + 0.16:
		return "heal"
	if text.begins_with("-") or color.r > 0.85:
		return "damage"
	if text.find("冰") != -1 or color.b > color.r + 0.20:
		return "cool"
	return "normal"

func _fx_text_palette(style: String, base: Color) -> Dictionary:
	match style:
		"combo_number":
			return {
				"shadow": Color(0.58, 0.20, 0.07, 0.58),
				"outline": Color(0.55, 0.17, 0.05, 0.95),
				"rim": Color(1.0, 0.43, 0.12, 0.88),
				"fill": Color(1.0, 0.93, 0.22, 1.0),
				"shine": Color(1.0, 1.0, 0.86, 0.42)
			}
		"combo_label":
			return {
				"shadow": Color(0.46, 0.16, 0.08, 0.52),
				"outline": Color(0.54, 0.19, 0.08, 0.92),
				"rim": Color(1.0, 0.80, 0.30, 0.72),
				"fill": Color(1.0, 0.58, 0.17, 1.0),
				"shine": Color(1.0, 0.96, 0.68, 0.34)
			}
		"gold":
			return {
				"shadow": Color(0.38, 0.18, 0.05, 0.54),
				"outline": Color(0.55, 0.23, 0.05, 0.92),
				"rim": Color(1.0, 0.92, 0.40, 0.72),
				"fill": Color(1.0, 0.78, 0.15, 1.0),
				"shine": Color(1.0, 1.0, 0.82, 0.32)
			}
		"heal":
			return {
				"shadow": Color(0.04, 0.28, 0.18, 0.46),
				"outline": Color(0.02, 0.36, 0.22, 0.88),
				"rim": Color(0.72, 1.0, 0.62, 0.66),
				"fill": Color(maxf(base.r, 0.36), maxf(base.g, 0.95), maxf(base.b, 0.42), 1.0),
				"shine": Color(0.92, 1.0, 0.76, 0.30)
			}
		"damage":
			return {
				"shadow": Color(0.42, 0.06, 0.06, 0.54),
				"outline": Color(0.58, 0.10, 0.09, 0.90),
				"rim": Color(1.0, 0.67, 0.36, 0.66),
				"fill": Color(maxf(base.r, 1.0), maxf(base.g, 0.30), maxf(base.b, 0.20), 1.0),
				"shine": Color(1.0, 0.90, 0.72, 0.28)
			}
		"cool":
			return {
				"shadow": Color(0.05, 0.20, 0.38, 0.48),
				"outline": Color(0.08, 0.30, 0.58, 0.88),
				"rim": Color(0.70, 0.96, 1.0, 0.66),
				"fill": Color(maxf(base.r, 0.38), maxf(base.g, 0.72), maxf(base.b, 1.0), 1.0),
				"shine": Color(0.94, 1.0, 1.0, 0.30)
			}
		_:
			return {
				"shadow": Color(0.12, 0.14, 0.24, 0.48),
				"outline": Color(0.22, 0.18, 0.34, 0.88),
				"rim": Color(1.0, 0.94, 0.66, 0.52),
				"fill": Color(maxf(base.r, 0.80), maxf(base.g, 0.80), maxf(base.b, 0.86), 1.0),
				"shine": Color(1.0, 1.0, 1.0, 0.24)
			}

func _draw_soft_sparkles(canvas: CanvasItem, center: Vector2, color: Color, opacity: float, strong: bool = false) -> void:
	var count := 4 if strong else 3
	var radius := 28.0 if strong else 22.0
	for i in range(count):
		var angle := _idle_time * 1.5 + float(i) * TAU / float(count)
		var pos := center + Vector2(cos(angle), sin(angle * 1.17)) * radius
		var a := opacity * (0.40 + 0.20 * sin(_idle_time * 4.0 + float(i)))
		var sparkle_color := Color(color.r, color.g, color.b, a)
		canvas.draw_line(pos - Vector2(3.5, 0.0), pos + Vector2(3.5, 0.0), sparkle_color, 1.4)
		canvas.draw_line(pos - Vector2(0.0, 3.5), pos + Vector2(0.0, 3.5), sparkle_color, 1.4)

func _is_turn_message(text: String) -> bool:
	return text == "你的回合" or text == "敌方回合" or text.ends_with("的回合")

func _is_major_battle_message(text: String) -> bool:
	return text.find("释放") != -1 \
		or text.find("充能完毕") != -1 \
		or text.find("效果拔群") != -1 \
		or text.find("十字") != -1 \
		or text.find("范围") != -1 \
		or text.find("虹光") != -1 \
		or text.find("解锁") != -1 \
		or text.find("捕捉") != -1 \
		or text.find("进入激战") != -1 \
		or text.find("蓄力攻击") != -1 \
		or text.find("生成了护盾") != -1

func _message_fx_style(text: String) -> String:
	if _is_turn_message(text):
		return "gold" if text.contains("你的") else "cool"
	if text.find("无法") != -1 or text.find("无效") != -1 or text.find("效果不佳") != -1 or text.find("侵蚀") != -1:
		return "damage"
	if text.find("回复") != -1 or text.find("恢复") != -1 or text.find("散开") != -1:
		return "heal"
	if text.find("冰冻") != -1 or text.find("护盾") != -1:
		return "cool"
	if text.find("效果拔群") != -1 or text.find("释放") != -1 or text.find("虹光") != -1 or text.find("十字") != -1 or text.find("范围") != -1 or text.find("解锁") != -1:
		return "gold"
	return "normal"

func _message_fx_color(text: String, alpha: float) -> Color:
	var style := _message_fx_style(text)
	match style:
		"gold":
			return Color(1.0, 0.86, 0.20, alpha)
		"cool":
			return Color(0.62, 0.88, 1.0, alpha)
		"damage":
			return Color(1.0, 0.48, 0.32, alpha)
		"heal":
			return Color(0.54, 1.0, 0.55, alpha)
		_:
			return Color(1.0, 0.96, 0.82, alpha)

func _draw_hp_bar(x: float, y: float, w: float, h: float, current: float, maximum: float, color: Color, element: String = "", show_orb: bool = false) -> void:
	var radius := h * 0.5
	var ratio: float = clampf(current / maximum, 0.0, 1.0) if maximum > 0 else 0.0
	var frame_base_tex := _get_texture(BATTLE_UI_ASSETS["hp_frame"])
	var frame_tex := _get_texture(BATTLE_UI_ASSETS["hp_frame_overlay"])
	var frame_rect := Rect2(x - 1.5, y - 1.5, w + 3.0, h + 3.0)
	if frame_base_tex:
		_draw_texture_fit(frame_base_tex, frame_rect, 1.0)
	else:
		_draw_rounded_rect(x, y, w, h, radius, Color(0.075, 0.105, 0.16, 1.0))
	if current > 0 and maximum > 0:
		var fill_w := maxf(h - 2.0, floor((w - 2.0) * ratio))
		_draw_rounded_rect(x + 1.0, y + 1.0, fill_w, h - 2.0, maxf(1.0, radius - 1.0), color.darkened(0.20))
		_draw_rounded_rect(x + 2.0, y + 2.0, maxf(fill_w - 2.0, 1.0), h - 4.0, maxf(1.0, radius - 2.0), color)
		_draw_rounded_rect(x + 3.0, y + 2.0, maxf(fill_w - 4.0, 1.0), maxf(h * 0.22, 1.0), maxf(1.0, radius - 2.0), Color(1.0, 1.0, 1.0, 0.28))
	if frame_tex:
		_draw_texture_fit(frame_tex, frame_rect, 1.0)
	else:
		_draw_rounded_rect(x - 1.5, y - 1.5, w + 3.0, h + 3.0, radius + 1.5, Color(1.0, 0.75, 0.32, 1.0))
	if not show_orb:
		return
	var orb_size := h * 2.75
	var orb_rect := Rect2(x - orb_size * 0.68, y + h / 2.0 - orb_size / 2.0, orb_size, orb_size)
	var orb_tex := _get_texture(GEM_IMAGE_PATHS.get(element, ""))
	if orb_tex:
		_draw_texture_contain(orb_tex, orb_rect, 1.0)
	else:
		draw_circle(orb_rect.get_center(), orb_size * 0.42, color)
	var bead_y := y + h + 8.0
	var bead_start_x := x + 18.0
	var active_beads := clampi(int(ceil(ratio * 5.0)), 0, 5)
	for i in range(5):
		var bead_color := color if i < active_beads else Color(0.12, 0.16, 0.22, 1.0)
		var center := Vector2(bead_start_x + i * 14.0, bead_y)
		draw_circle(center, 5.0, Color(1.0, 0.75, 0.32, 1.0))
		draw_circle(center, 3.8, bead_color)
		draw_circle(center - Vector2(1.0, 1.0), 1.1, Color(1.0, 1.0, 1.0, 0.48))

func _floating_text_plate_path(text: String, ft: Dictionary) -> String:
	if text.begins_with("+"):
		return BATTLE_FX_ASSETS["heal_plate"]
	if ft.get("critical", false):
		return BATTLE_FX_ASSETS["critical_plate"]
	if text.begins_with("-") or text.begins_with("护") or text.begins_with("缚") or text in ["爆裂", "轰!", "清屏", "破雾", "解锁", "破链"]:
		return BATTLE_FX_ASSETS["damage_plate"]
	return ""

func _clean_battle_fx_text(text: String) -> String:
	var cleaned := text.strip_edges()
	var replacements := {
		"💫": "",
		"💥": "",
		"💣": "",
		"🌈": "",
		"⚡": "",
		"🛡️": "",
		"💚": "",
		"☠️": "",
		"🧹": "",
		"🔓": "",
		"⛓️": "",
		"🔥": "",
		"❄️": "",
		"💧": "",
		"🌿": "",
		"✨": "",
		"💎": "",
		"十字爆炸": "十字爆裂",
		"炸弹爆炸": "范围弹跳",
		"彩虹消除": "虹光清屏",
		"毒雾扩散了": "毒雾轻轻扩散",
		"毒雾伤害": "毒雾侵蚀",
		"毒雾被清除了": "毒雾散开了",
		"宝石解锁": "宝石解锁",
	}
	for key in replacements.keys():
		cleaned = cleaned.replace(str(key), str(replacements[key]))
	return cleaned.strip_edges()

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
		"item_used": _capture_item_used,
		"window": _capture_window
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
	_item_use_effects.clear()
	_special_elim_phases.clear()
	_defeat_explosions.clear()
	_victory_particles.clear()
	_defeated_enemies.clear()
	# ★ 主人定 2026-06-11：清理攻击者弹性 + 倒下过渡
	_attacker_elastic_anims.clear()
	_defeat_transitions.clear()
	_screen_flash_timer = 0.0
	_rainbow_flash = 0.0
	_board_shake_timer = 0.0
	_board_shake_offset = Vector2.ZERO
	_attack_shake_timer = 0.0
	_attack_flash_timer = 0.0
	_special_transform_anim = {"row": -1, "col": -1, "type": "", "timer": 0.0, "duration": 0.5, "triggered": false}
	_element_ripple = {"active": false, "color": Color(), "timer": 0.0, "duration": 0.6}
	_element_glow = {"type": "", "timer": 0.0, "color": Color()}
	_combo_popup = {"combo": 0, "timer": 0.0, "phase": "", "scale": 0.5, "opacity": 0.0}
	_drag_preview = {"active": false, "direction": Vector2i.ZERO}
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
	_capture_window = {}

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
		if fg["timer"] >= fg.get("duration", FALL_DURATION) + fg.get("delay", 0.0):
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
		_show_message("毒雾轻轻扩散！+%d格" % new_tiles.size())

	var total_fog_damage: int = result.get("total_damage", 0)
	if total_fog_damage <= 0:
		return
	for hit in result.get("hits", []):
		var team_index: int = hit.get("team_index", -1)
		var mx: float = 15.0 + float(team_index) * 120.0 + 55.0
		_floating_texts.append({
			"text": "-%d" % hit.get("damage", 0),
			"x": mx, "y": 195.0,
			"color": STATUS_COLORS.get("poison", C["danger"]),
			"size": 16.0,
			"timer": 0.0,
			"duration": 0.8
		})
	_request_battle_fx({"type": "poison_damage", "hits": result.get("hits", []), "total_damage": total_fog_damage})
	_show_message("毒雾侵蚀！%d格 × 3%% = %d" % [result.get("fog_count", 0), total_fog_damage])

## ============================================
# 消除时的毒雾清除 & 锁定宝石解锁
## ============================================

func _check_poison_fog_clears(matches: Array) -> void:
	"""消除宝石时检查是否清除了毒雾格子"""
	var clears: Array = BattleHazardRulesScript.clear_poison_for_gems(_board, matches)
	for clear in clears:
		clear["timer"] = 0.0
		_floating_texts.append({"text": "破雾", "x": clear["x"], "y": clear["y"] - 15.0, "color": C["success"], "size": 13.0, "timer": 0.0, "duration": 0.8, "critical": true})
	if clears.size() > 0:
		_poison_fog_clear_anims.append_array(clears)
		_request_battle_fx({"type": "poison_clear", "tiles": clears})
		_show_message("毒雾散开了！")

func _check_explosion_poison_fog(gems: Array) -> void:
	"""特殊消除（爆炸/炸弹/彩虹）也检查毒雾清除"""
	var clears: Array = BattleHazardRulesScript.clear_poison_for_gems(_board, gems)
	for clear in clears:
		_floating_texts.append({"text": "散开", "x": clear["x"], "y": clear["y"] - 10.0, "color": C["success"], "size": 11.0, "timer": 0.0, "duration": 0.8})
	if not clears.is_empty():
		_request_battle_fx({"type": "poison_clear_special", "tiles": clears})

func _check_unlock_results(matches: Array, extra_gems: Array = []) -> void:
	"""消除后检查相邻锁定宝石解锁"""
	var unlock_results: Array = BattleHazardRulesScript.check_unlocks(_board, matches, extra_gems)
	for ur in unlock_results:
		if ur.get("fullyUnlocked", false):
			_unlock_animations.append({"row": ur["row"], "col": ur["col"], "timer": 0.0, "maxTimer": 0.6, "phase": "shatter"})
			_floating_texts.append({"text": "解锁", "x": ur["x"], "y": ur["y"] - 15.0, "color": C["gold"], "size": 14.0, "timer": 0.0, "duration": 0.8, "critical": true})
		else:
			_floating_texts.append({"text": "破链×%d" % ur.get("remainingHP", 1), "x": ur["x"], "y": ur["y"] - 10.0, "color": C["text_muted"], "size": 11.0, "timer": 0.0, "duration": 0.8})
	
	if unlock_results.any(func(ur): return ur.get("fullyUnlocked", false)):
		_request_battle_fx({"type": "unlock", "results": unlock_results})
		_show_message("宝石解锁！")
