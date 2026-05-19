# enemy_skill_system.gd
# 敌人技能系统 - 独立模块
# 从 battle_manager.gd 解耦，负责管理敌人的蓄力/护盾/治疗技能
# 解耦进度：Phase 1 - 基础框架

class_name EnemySkillSystem
## 敌人技能系统
##
## 技能配置结构 (skill_config):
##   charge:  { "type": "charge", "interval": int, "damageMultiplier": float }
##   shield:  { "type": "shield", "hp": int, "cooldown": int }
##   heal:    { "type": "heal", "percent": float, "interval": int }
##
## 技能状态结构 (skill_state):
##   charge:  { "turns_since_last": int, "is_charging": bool }
##   shield:  { "current_hp": int, "max_hp": int, "cooldown_left": int }
##   heal:    { "turns_since_last": int }


# 信号定义
signal skill_charge_start(enemy_idx: int, damage_multiplier: float)
signal skill_charge_release(enemy_idx: int, damage_multiplier: float)
signal skill_shield_appear(enemy_idx: int, shield_hp: int)
signal skill_shield_broken(enemy_idx: int)
signal skill_heal_triggered(enemy_idx: int, heal_amount: int)
signal enemy_skill_action(enemy_idx: int, skill_type: String, params: Dictionary)


# 常量定义
const SKILL_TYPE_CHARGE := "charge"
const SKILL_TYPE_SHIELD := "shield"
const SKILL_TYPE_HEAL := "heal"


# 内部状态（外部访问通过 getter）
var _skill_states: Dictionary = {}  # { enemy_idx: { "charge": {...}, "shield": {...}, "heal": {...} } }


# ==================== Phase 1: 基础框架 ====================

## 初始化技能状态
## 解析 skills 配置数组，构建每个敌人的技能状态
## 返回: Dictionary { enemy_idx: { skill_type: state_dict } }
func init_skill_state(enemies: Array) -> Dictionary:
	_skill_states.clear()
	
	for i in range(enemies.size()):
		var enemy = enemies[i]
		if enemy == null:
			continue
		
		var skills: Array = enemy.get("enemySkills", [])
		if skills.is_empty():
			continue
		
		var state: Dictionary = {}
		
		for skill in skills:
			var skill_type = skill.get("type", "")
			
			match skill_type:
				"charge":
					state["charge"] = {
						"turns_since_last": 0,
						"is_charging": false,
						"interval": skill.get("interval", 3),
						"damage_multiplier": skill.get("damageMultiplier", 2.0)
					}
				"shield":
					state["shield"] = {
						"current_hp": 0,
						"max_hp": skill.get("hp", 50),
						"cooldown_left": 0,
						"cooldown": skill.get("cooldown", 4)
					}
				"heal":
					state["heal"] = {
						"turns_since_last": 0,
						"percent": skill.get("percent", 0.1),
						"interval": skill.get("interval", 4)
					}
		
		if not state.is_empty():
			_skill_states[i] = state
	
	return _skill_states


## 获取敌人的技能状态
func get_enemy_state(enemy_idx: int) -> Dictionary:
	return _skill_states.get(enemy_idx, {})


## 获取特定技能状态
func get_skill_state(enemy_idx: int, skill_type: String) -> Dictionary:
	var enemy_state = get_enemy_state(enemy_idx)
	return enemy_state.get(skill_type, {})


## 检查敌人是否有某类技能
func has_skill_type(enemy_idx: int, skill_type: String) -> bool:
	var state = get_enemy_state(enemy_idx)
	return state.has(skill_type)


# ==================== Phase 2: 蓄力技能解耦 ====================

## 敌人回合开始时：检查并释放蓄力
## 调用时机：敌人回合开始时（攻击之前）
## 返回：如果应该释放蓄力，返回 damage_multiplier；否则返回 null
func check_and_release_charge(enemy_idx: int) -> float:
	var state = get_skill_state(enemy_idx, "charge")
	if state.is_empty() or not state.get("is_charging", false):
		return 1.0
	
	var damage_multiplier: float = state.get("damage_multiplier", 2.0)
	state["is_charging"] = false
	state["turns_since_last"] = 0
	
	skill_charge_release.emit(enemy_idx, damage_multiplier)
	enemy_skill_action.emit({
		"type": "charge_release",
		"enemy_index": enemy_idx,
		"damage_multiplier": damage_multiplier
	})
	
	return damage_multiplier


## 敌人回合结束时：更新蓄力计时器并检查是否应开始蓄力
## 调用时机：敌人回合结束时（攻击之后）
## 返回：是否开始了蓄力
func update_and_check_charge_start(enemy_idx: int) -> bool:
	var state = get_skill_state(enemy_idx, "charge")
	if state.is_empty() or state.get("is_charging", false):
		return false
	
	state["turns_since_last"] += 1
	var interval: int = state.get("interval", 3)
	
	if state["turns_since_last"] >= interval:
		state["is_charging"] = true
		state["turns_since_last"] = 0
		
		skill_charge_start.emit(enemy_idx, state.get("damage_multiplier", 2.0))
		enemy_skill_action.emit({
			"type": "charge_start",
			"enemy_index": enemy_idx
		})
		return true
	
	return false


## 获取蓄力伤害倍率（外部调用，用于伤害计算）
func get_charge_damage_multiplier(enemy_idx: int) -> float:
	var state = get_skill_state(enemy_idx, "charge")
	if state.is_empty() or not state.get("is_charging", false):
		return 1.0
	return state.get("damage_multiplier", 2.0)


## 检查蓄力状态（是否正在蓄力）
func is_charging(enemy_idx: int) -> bool:
	var state = get_skill_state(enemy_idx, "charge")
	return state.get("is_charging", false)


# ==================== Phase 3: 护盾技能解耦（占位符） ====================


## 执行护盾技能（Phase 3 实现）
func execute_shield_before_damage(enemy_idx: int) -> Dictionary:
	var state = get_skill_state(enemy_idx, "shield")
	if state.is_empty() or state.get("current_hp", 0) <= 0:
		return { "absorbed": 0, "remaining": 0 }
	
	# 占位：实际逻辑在 Phase 3
	return { "absorbed": 0, "remaining": state.get("current_hp", 0) }


## 检查并激活护盾（Phase 3 实现）
func check_and_activate_shield(enemy_idx: int, enemy: Dictionary) -> bool:
	var state = get_skill_state(enemy_idx, "shield")
	if state.is_empty():
		return false
	
	# 占位：实际逻辑在 Phase 3
	return false


## 执行治疗技能（Phase 4 实现）
func execute_heal(enemy_idx: int, enemy: Dictionary) -> Dictionary:
	var state = get_skill_state(enemy_idx, "heal")
	if state.is_empty():
		return {}
	
	# 占位：实际逻辑在 Phase 4
	return { "triggered": false }


## 每个敌人回合开始时调用，更新技能冷却/计时
func on_enemy_turn_start(enemy_idx: int, enemy: Dictionary) -> void:
	pass  # 占位


## 每个敌人回合结束时调用，处理技能触发
func on_enemy_turn_end(enemy_idx: int, enemy: Dictionary) -> void:
	pass  # 占位


## 重置所有技能状态（战斗重新开始时调用）
func reset() -> void:
	_skill_states.clear()