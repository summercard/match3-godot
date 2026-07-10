# ============================================
# battle/phase_handler.gd - BOSS阶段切换处理器
# 翻译自: js/battle/battleManager.js 中的 _checkPhaseTransition() / _executePhaseTransition()
# ============================================
class_name PhaseHandler
extends RefCounted

## BOSS阶段切换处理器
## 职责：
## - 阶段切换触发检查（on_enter / hp_50）
## - HP倍率应用（hpMultiplier）
## - 敌人重新初始化
## - 护盾/蓄力/回血状态重置
## - 阶段切换信号通知UI

# 引用（通过外部注入或 BattleManager 设置）
var battle_manager: Node = null

# 当前阶段配置
var _current_phase: int = 1
var _phase_configs: Array = []
var _triggered_phases: Dictionary = {}  # { phaseNum: true }

const DEFAULT_RANDOM_ELITE_CHANCE: float = 0.08
const PHASE_TWO_VISUAL_SCALE_MULT: float = 1.5


func _init(bm: Node = null) -> void:
	battle_manager = bm


## 设置阶段配置（从 stageData.phases 传入）
func set_phase_configs(configs: Array) -> void:
	_phase_configs = configs
	_current_phase = 1
	_triggered_phases = {}


## 获取当前阶段号
func get_current_phase() -> int:
	return _current_phase


## 检查是否应该触发阶段转换
## trigger 类型：
##   - "on_enter": 进入即触发
##   - "hp_50": Boss血量降至50%时触发
func check_phase_transition() -> Dictionary:
	if _phase_configs.is_empty():
		return {}

	var next_phase_num: int = _current_phase + 1
	var next_phase: Dictionary = _find_phase_config(next_phase_num)
	if next_phase.is_empty():
		return {}
	if _triggered_phases.has(next_phase_num):
		return {}

	var trigger_type: String = next_phase.get("trigger", "")

	if trigger_type == "on_enter":
		_triggered_phases[next_phase_num] = true
		return next_phase

	if trigger_type == "hp_50":
		var boss = _find_alive_boss()
		if boss != null and boss.get("hp", 0) <= boss.get("maxHP", 1) * 0.5:
			_triggered_phases[next_phase_num] = true
			return next_phase

	return {}


## 执行阶段转换
## 返回新敌人列表
## hp_ratio: 旧敌人当前 HP 比例（0.0~1.0），主人定 2026-06-10：进入二阶段不拉满血
func execute_phase_transition(phase_config: Dictionary, enemy_level: int = 1, hp_ratio: float = 0.0) -> Array:
	_current_phase += 1

	var hp_mult: float = phase_config.get("hpMultiplier", 1.3)
	var new_enemy_ids: Array = phase_config.get("enemies", [])
	var random_elite_chance := _random_elite_chance(phase_config)
	var new_enemies: Array = []

	for enemy_id in new_enemy_ids:
		var enemy_id_str := str(enemy_id)
		var is_elite := _should_spawn_elite(enemy_id_str, random_elite_chance)
		var tier := StatCalculator.EnemyTier.ELITE if is_elite else StatCalculator.EnemyTier.NORMAL
		var monster: Dictionary = StatCalculator.calc_enemy(enemy_id_str, enemy_level, tier)
		if not monster.is_empty():
			var new_max_hp := int(monster.get("maxHP", 0) * hp_mult)
			monster["maxHP"] = new_max_hp
			# ★ 主人定 A：保留旧血量比例，不再“回满血”
			# hp_ratio=0 表示传参人没提供，则兑底拉满（保持旧默认行为）
			if hp_ratio > 0.0:
				monster["hp"] = maxi(1, int(new_max_hp * hp_ratio))
			else:
				monster["hp"] = new_max_hp
			monster["atk"] = int(monster.get("atk", 0) * hp_mult)
			monster["def"] = int(monster.get("def", 0) * hp_mult)
			if bool(monster.get("isElite", false)):
				monster["isElite"] = true
				monster["_visualScale"] = StatCalculator.visual_scale_for_stats(monster)
			if is_elite:
				monster["_eliteSource"] = "random"
			# ★ 主人定 2026-06-10：二阶段体型变大 50%
			# Current species retain their rarity silhouette before the phase-two
			# enlargement. The retained legacy enemy IDs used a fixed 1.5x state,
			# so keep that visual contract for old saves and replay data.
			if enemy_id_str in MonsterDb.LEGACY_ENEMY_IDS:
				monster["_visualScale"] = PHASE_TWO_VISUAL_SCALE_MULT
			else:
				monster["_visualScale"] = StatCalculator.visual_scale_for_stats(monster) * PHASE_TWO_VISUAL_SCALE_MULT
		new_enemies.append(monster)

	# 重置敌人技能状态
	var enemy_skill_states: Dictionary = {}
	var status_effects: Array = []

	for i in range(new_enemies.size()):
		var enemy: Dictionary = new_enemies[i]
		if enemy.is_empty():
			continue
		var skills: Array = []
		if enemy.get("enemySkills", null) is Array:
			skills = enemy.get("enemySkills", [])
		if skills.is_empty():
			continue

		var state: Dictionary = {}
		for skill in skills:
			var skill_type: String = skill.get("type", "")
			if skill_type == "charge":
				state["charge"] = {"turns_since_last": 0, "is_charging": false}
			elif skill_type == "shield":
				state["shield"] = {"current_hp": 0, "max_hp": skill.get("hp", 0), "cooldown_left": 0}
			elif skill_type == "heal":
				state["heal"] = {"turns_since_last": 0}
		enemy_skill_states[i] = state

	status_effects = []
	for i in range(new_enemies.size()):
		status_effects.append(null)

	# 通知外部（BattleManager）
	if battle_manager and battle_manager.has_signal("phase_transitioned"):
		battle_manager.emit_signal("phase_transitioned", _current_phase, new_enemies)

	return new_enemies


func _should_spawn_elite(enemy_id: String, random_elite_chance: float) -> bool:
	var data: Dictionary = MonsterDb.MONSTER_DB.get(enemy_id, {})
	if data.is_empty():
		return false
	if bool(data.get("isBoss", false)):
		return false
	return randf() < clampf(random_elite_chance, 0.0, 1.0)


func _random_elite_chance(phase_config: Dictionary) -> float:
	if bool(phase_config.get("disableRandomElite", false)):
		return 0.0
	if phase_config.has("randomEliteChance"):
		return clampf(float(phase_config.get("randomEliteChance", 0.0)), 0.0, 1.0)
	if phase_config.has("eliteChance"):
		return clampf(float(phase_config.get("eliteChance", 0.0)), 0.0, 1.0)
	return DEFAULT_RANDOM_ELITE_CHANCE


## 根据阶段号查找配置
func _find_phase_config(phase_num: int) -> Dictionary:
	for config in _phase_configs:
		if config.get("phase", 0) == phase_num:
			return config
	return {}


## 查找活着的Boss
func _find_alive_boss() -> Dictionary:
	if battle_manager == null:
		return {}

	var enemies: Array = []
	if battle_manager.has_method("get_enemies"):
		enemies = battle_manager.get_enemies()

	for enemy in enemies:
		if enemy.is_empty():
			continue
		if enemy.get("hp", 0) <= 0:
			continue
		if enemy.get("isBoss", false):
			return enemy
	return {}
