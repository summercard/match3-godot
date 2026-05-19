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
##   burn:    { "type": "burn", "damage": int, "interval": int, "duration": int }
##   thunder_strike: { "type": "thunder_strike", "damage": int, "cooldown": int }
##   reflect: { "type": "reflect", "percent": float, "duration": int }
##
## 技能状态结构 (skill_state):
##   charge:  { "turns_since_last": int, "is_charging": bool }
##   shield:  { "current_hp": int, "max_hp": int, "cooldown_left": int }
##   heal:    { "turns_since_last": int }
##   burn:    { "damage": int, "duration_left": int }
##   thunder_strike: { "damage": int, "cooldown": int, "turns_since_last": int }
##   reflect: { "percent": float, "duration": int, "duration_left": int, "is_active": bool }
##   freeze:  { "chance": float, "duration": int, "duration_left": int }


# 信号定义
signal skill_charge_start(enemy_idx: int, damage_multiplier: float)
signal skill_charge_release(enemy_idx: int, damage_multiplier: float)
signal skill_shield_appear(enemy_idx: int, shield_hp: int)
signal skill_shield_broken(enemy_idx: int)
signal skill_shield_plus_appear(enemy_idx: int, shield_hp: int, reflect_percent: float)
signal skill_shield_plus_broken(enemy_idx: int)
signal skill_shield_plus_reflect(enemy_idx: int, target_idx: int, reflected_damage: int)
signal skill_heal_triggered(enemy_idx: int, heal_amount: int)
signal skill_burn_apply(enemy_idx: int, target_idx: int, damage: int, duration: int)
signal skill_burn_damage(enemy_idx: int, target_idx: int, damage: int)
signal skill_burn_expire(enemy_idx: int, target_idx: int)
signal skill_reflect_activate(enemy_idx: int, percent: float, duration: int)
signal skill_reflect_trigger(enemy_idx: int, target_idx: int, reflected_damage: int)
signal skill_reflect_expire(enemy_idx: int)
signal skill_thunder_strike_triggered(enemy_idx: int, damage: int)
signal skill_freeze_activate(enemy_idx: int, target_idx: int, chance: float, duration: int)
signal skill_freeze_expire(enemy_idx: int, target_idx: int)
signal skill_poison_apply(enemy_idx: int, target_idx: int, stacks: int, damage_per_stack: int, max_stacks: int)
signal skill_poison_damage(enemy_idx: int, target_idx: int, total_damage: int, stacks: int)
signal skill_poison_expire(enemy_idx: int, target_idx: int)
signal skill_poison_stack_increase(enemy_idx: int, target_idx: int, new_stacks: int, max_stacks: int)
signal skill_life_drain_triggered(enemy_idx: int, target_idx: int, drain_amount: int, heal_amount: int)
signal skill_surge_damage(enemy_idx: int, target_idx: int, damage: int, turn_number: int)
signal skill_surge_expire(enemy_idx: int, target_idx: int)
signal skill_confuse_activate(enemy_idx: int, target_idx: int, chance: float, duration: int)
signal skill_confuse_expire(enemy_idx: int, target_idx: int)
signal enemy_skill_action(enemy_idx: int, skill_type: String, params: Dictionary)


# 常量定义
const SKILL_TYPE_CHARGE := "charge"
const SKILL_TYPE_SHIELD := "shield"
const SKILL_TYPE_SHIELD_PLUS := "shield_plus"
const SKILL_TYPE_HEAL := "heal"
const SKILL_TYPE_BURN := "burn"
const SKILL_TYPE_THUNDER_STRIKE := "thunder_strike"
const SKILL_TYPE_REFLECT := "reflect"
const SKILL_TYPE_FREEZE := "freeze"
const SKILL_TYPE_POISON := "poison"
const SKILL_TYPE_LIFE_DRAIN := "life_drain"
const SKILL_TYPE_SURGE := "surge"
const SKILL_TYPE_CONFUSE := "confuse"


# 内部状态（外部访问通过 getter）
var _skill_states: Dictionary = {}  # { enemy_idx: { "charge": {...}, "shield": {...}, "heal": {...}, "burn": {...}, "thunder_strike": {...}, "reflect": {...}, "freeze": {...}, "poison": {...}, "life_drain": {...}, "surge": {...}, "shield_plus": {...} } }
var _burn_targets: Dictionary = {}  # { enemy_idx: { "target_idx": int, "damage": int, "duration_left": int } }
var _reflect_targets: Dictionary = {}  # { enemy_idx: { "target_idx": int, "percent": float, "duration_left": int } }
var _freeze_targets: Dictionary = {}  # { enemy_idx: { "target_idx": int, "chance": float, "duration_left": int } }
var _poison_targets: Dictionary = {}  # { enemy_idx: { "target_idx": int, "stacks": int, "max_stacks": int, "damage_per_stack": int, "duration_left": int } }
var _surge_targets: Dictionary = {}  # { enemy_idx: { "target_idx": int, "base_damage": int, "increment": int, "current_damage": int, "max_damage": int, "turn_number": int } }
var _confuse_targets: Dictionary = {}  # { enemy_idx: { "target_idx": int, "chance": float, "duration_left": int } }


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
		
		var skills_raw = enemy.get("enemySkills", null)
		if skills_raw == null or skills_raw.is_empty():
			continue
		var skills: Array = skills_raw
		
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
				"shield_plus":
					state["shield_plus"] = {
						"current_hp": 0,
						"max_hp": skill.get("hp", 100),
						"cooldown": skill.get("cooldown", 5),
						"cooldown_left": 0,
						"reflect_damage": skill.get("reflectDamage", true),
						"reflect_percent": skill.get("reflectPercent", 0.5)
					}
				"heal":
					state["heal"] = {
						"turns_since_last": 0,
						"percent": skill.get("percent", 0.1),
						"interval": skill.get("interval", 4)
					}
				"burn":
					state["burn"] = {
						"damage": skill.get("damage", 15),
						"interval": skill.get("interval", 1),
						"duration": skill.get("duration", 3),
						"turns_since_last": 0
					}
				"thunder_strike":
					state["thunder_strike"] = {
						"damage": skill.get("damage", 50),
						"cooldown": skill.get("cooldown", 3),
						"turns_since_last": 0
					}
				"reflect":
					state["reflect"] = {
						"percent": skill.get("percent", 0.3),
						"duration": skill.get("duration", 2),
						"duration_left": 0,
						"is_active": false
					}
				"freeze":
					state["freeze"] = {
						"chance": skill.get("chance", 0.3),
						"duration": skill.get("duration", 1),
						"duration_left": 0
					}
				"poison":
					state["poison"] = {
						"max_stacks": skill.get("maxStacks", 3),
						"damage_per_stack": skill.get("damagePerStack", 10),
						"interval": skill.get("interval", 1),
						"turns_since_last": 0
					}
				"life_drain":
					state["life_drain"] = {
						"percent": skill.get("percent", 0.15),
						"cooldown": skill.get("cooldown", 4),
						"turns_since_last": 0
					}
				"surge":
					state["surge"] = {
						"base_damage": skill.get("baseDamage", 30),
						"increment_per_turn": skill.get("incrementPerTurn", 10),
						"max_damage": skill.get("maxDamage", 100)
					}
				"confuse":
					state["confuse"] = {
						"chance": skill.get("chance", 0.2),
						"duration": skill.get("duration", 1),
						"duration_left": 0
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


# ==================== Phase 3: 护盾技能解耦 ====================

## 护盾减伤计算
## 在伤害结算前调用，将伤害分为护盾吸收部分和穿透部分
## 返回: { "absorbed": int, "remaining": int }
func execute_shield_before_damage(enemy_idx: int, damage: int) -> Dictionary:
	var state = get_skill_state(enemy_idx, "shield")
	if state.is_empty():
		return { "absorbed": 0, "remaining": damage }
	
	var shield_hp: int = state.get("current_hp", 0)
	if shield_hp <= 0:
		return { "absorbed": 0, "remaining": damage }
	
	# 使用 DamageCalculator 计算护盾吸收
	var absorbed := mini(shield_hp, damage)
	var remaining := damage - absorbed
	state["current_hp"] -= absorbed
	
	# 如果护盾被打破，发出信号
	if state["current_hp"] <= 0:
		skill_shield_broken.emit(enemy_idx)
		enemy_skill_action.emit({
			"type": "shield_broken",
			"enemy_index": enemy_idx
		})
	
	return { "absorbed": absorbed, "remaining": remaining }


## 检查并激活护盾
## 在敌人回合开始时调用，检查护盾是否应该激活
## 返回: bool - 是否成功激活护盾
func check_and_activate_shield(enemy_idx: int, enemy: Dictionary) -> bool:
	var state = get_skill_state(enemy_idx, "shield")
	if state.is_empty():
		return false
	
	var skills: Array = enemy.get("enemySkills", [])
	var shield_config = skills.filter(func(s): return s.get("type") == "shield")
	if shield_config.is_empty():
		return false
	
	var shield_hp: int = shield_config[0].get("hp", 0)
	var cooldown: int = shield_config[0].get("cooldown", 4)
	
	# 检查护盾是否需要激活：current_hp <= 0 且 cooldown_left <= 0
	if state.get("current_hp", 0) <= 0 and state.get("cooldown_left", 0) <= 0:
		state["current_hp"] = shield_hp
		state["max_hp"] = shield_hp
		state["cooldown_left"] = cooldown
		
		skill_shield_appear.emit(enemy_idx, shield_hp)
		enemy_skill_action.emit({
			"type": "shield_appear",
			"enemy_index": enemy_idx,
			"enemy": enemy,
			"shield_hp": shield_hp,
			"shield_max_hp": shield_hp
		})
		return true
	
	# 冷却递减
	if state.get("cooldown_left", 0) > 0:
		state["cooldown_left"] -= 1
	
	return false


## 检查护盾状态（是否有效）
func is_shield_active(enemy_idx: int) -> bool:
	var state = get_skill_state(enemy_idx, "shield")
	return state.get("current_hp", 0) > 0


## 获取护盾当前HP
func get_shield_hp(enemy_idx: int) -> int:
	var state = get_skill_state(enemy_idx, "shield")
	return state.get("current_hp", 0)


## 获取护盾剩余冷却
func get_shield_cooldown(enemy_idx: int) -> int:
	var state = get_skill_state(enemy_idx, "shield")
	return state.get("cooldown_left", 0)


# ==================== 占位符（Phase 4-5） ====================

## 执行治疗技能
## 在敌人回合结束时调用，检查是否应触发治疗
## 返回: { "heal_amount": int, "triggered": bool }
func execute_heal(enemy_idx: int, enemy: Dictionary) -> Dictionary:
	var state = get_skill_state(enemy_idx, "heal")
	if state.is_empty():
		return { "triggered": false, "heal_amount": 0 }
	
	var skills: Array = enemy.get("enemySkills", [])
	var heal_config = skills.filter(func(s): return s.get("type") == "heal")
	if heal_config.is_empty():
		return { "triggered": false, "heal_amount": 0 }
	
	state["turns_since_last"] += 1
	var interval: int = state.get("interval", 4)
	
	if state["turns_since_last"] >= interval:
		state["turns_since_last"] = 0
		
		var max_hp: int = enemy.get("maxHP", 0)
		var percent: float = state.get("percent", 0.1)
		var heal_amount: int = int(max_hp * percent)
		var current_hp: int = enemy.get("hp", 0)
		var new_hp: int = mini(max_hp, current_hp + heal_amount)
		
		# 更新敌人HP（通过引用）
		enemy["hp"] = new_hp
		
		skill_heal_triggered.emit(enemy_idx, heal_amount)
		enemy_skill_action.emit({
			"type": "heal",
			"enemy_index": enemy_idx,
			"enemy": enemy,
			"heal_amount": heal_amount
		})
		
		return { "triggered": true, "heal_amount": heal_amount }
	
	return { "triggered": false, "heal_amount": 0 }


# ==================== Phase 4: 灼烧技能 ====================

## 尝试对攻击者施加灼烧效果
## 在敌人攻击造成伤害后调用（check_and_release_charge 之后）
## target_idx: 攻击者的索引（通常是玩家队伍中的某个宠物）
## 返回: { "applied": bool, "damage": int, "duration": int }
func try_apply_burn(enemy_idx: int, target_idx: int, source_damage: int = 0) -> Dictionary:
	var state = get_skill_state(enemy_idx, "burn")
	if state.is_empty():
		return { "applied": false, "damage": 0, "duration": 0 }
	
	# 如果已经有灼烧目标，不重复施加（除非超时或已结束）
	if _burn_targets.has(enemy_idx) and _burn_targets[enemy_idx].get("duration_left", 0) > 0:
		return { "applied": false, "damage": 0, "duration": 0 }
	
	var burn_damage: int = state.get("damage", 15)
	var burn_duration: int = state.get("duration", 3)
	
	_burn_targets[enemy_idx] = {
		"target_idx": target_idx,
		"damage": burn_damage,
		"duration_left": burn_duration
	}
	
	skill_burn_apply.emit(enemy_idx, target_idx, burn_damage, burn_duration)
	enemy_skill_action.emit({
		"type": "burn_apply",
		"enemy_index": enemy_idx,
		"target_index": target_idx,
		"damage": burn_damage,
		"duration": burn_duration
	})
	
	return { "applied": true, "damage": burn_damage, "duration": burn_duration }


# ==================== Phase 5: 反弹技能 ====================

## 尝试激活反弹效果
## 在敌人攻击造成伤害后调用（当敌人被攻击时）
## target_idx: 攻击者的索引（通常是玩家队伍中的某个宠物）
## 返回: { "activated": bool, "percent": float, "duration": int }
func try_activate_reflect(enemy_idx: int, target_idx: int) -> Dictionary:
	var state = get_skill_state(enemy_idx, "reflect")
	if state.is_empty():
		return { "activated": false, "percent": 0.0, "duration": 0 }
	
	# 如果反弹已经激活，不重复激活
	if _reflect_targets.has(enemy_idx) and _reflect_targets[enemy_idx].get("duration_left", 0) > 0:
		return { "activated": false, "percent": 0.0, "duration": 0 }
	
	var reflect_percent: float = state.get("percent", 0.3)
	var reflect_duration: int = state.get("duration", 2)
	
	_reflect_targets[enemy_idx] = {
		"target_idx": target_idx,
		"percent": reflect_percent,
		"duration_left": reflect_duration
	}
	
	# 标记技能状态为激活
	state["is_active"] = true
	state["duration_left"] = reflect_duration
	
	skill_reflect_activate.emit(enemy_idx, reflect_percent, reflect_duration)
	enemy_skill_action.emit({
		"type": "reflect_activate",
		"enemy_index": enemy_idx,
		"target_index": target_idx,
		"percent": reflect_percent,
		"duration": reflect_duration
	})
	
	return { "activated": true, "percent": reflect_percent, "duration": reflect_duration }


## 计算反弹伤害
## 在玩家攻击造成伤害后调用，计算并返回应反弹的伤害
## 返回: { "reflected": bool, "damage": int, "target_idx": int }
func calculate_reflect_damage(enemy_idx: int, incoming_damage: int) -> Dictionary:
	if not _reflect_targets.has(enemy_idx):
		return { "reflected": false, "damage": 0, "target_idx": -1 }
	
	var reflect_info: Dictionary = _reflect_targets[enemy_idx]
	var target_idx: int = reflect_info.get("target_idx", -1)
	var percent: float = reflect_info.get("percent", 0.3)
	var duration_left: int = reflect_info.get("duration_left", 0)
	
	if target_idx < 0 or duration_left <= 0:
		_reflect_targets.erase(enemy_idx)
		return { "reflected": false, "damage": 0, "target_idx": -1 }
	
	var reflected_damage: int = int(incoming_damage * percent)
	
	skill_reflect_trigger.emit(enemy_idx, target_idx, reflected_damage)
	enemy_skill_action.emit({
		"type": "reflect_damage",
		"enemy_index": enemy_idx,
		"target_index": target_idx,
		"damage": reflected_damage
	})
	
	return { "reflected": true, "damage": reflected_damage, "target_idx": target_idx }


## 处理反弹效果持续时间
## 在敌人回合开始时调用，更新反弹持续时间
## 返回: { "target_idx": int, "expired": bool }
func process_reflect_duration(enemy_idx: int) -> Dictionary:
	if not _reflect_targets.has(enemy_idx):
		return { "target_idx": -1, "expired": false }
	
	var reflect_info: Dictionary = _reflect_targets[enemy_idx]
	var target_idx: int = reflect_info.get("target_idx", -1)
	var duration_left: int = reflect_info.get("duration_left", 0)
	
	if duration_left <= 0:
		return { "target_idx": target_idx, "expired": false }
	
	# 持续时间减少
	duration_left -= 1
	reflect_info["duration_left"] = duration_left
	
	var expired: bool = false
	if duration_left <= 0:
		_reflect_targets.erase(enemy_idx)
		expired = true
		# 重置技能状态
		var state = get_skill_state(enemy_idx, "reflect")
		if not state.is_empty():
			state["is_active"] = false
			state["duration_left"] = 0
		skill_reflect_expire.emit(enemy_idx)
		enemy_skill_action.emit({
			"type": "reflect_expire",
			"enemy_index": enemy_idx
		})
	
	return { "target_idx": target_idx, "expired": expired }


## 获取当前反弹目标
func get_reflect_target(enemy_idx: int) -> Dictionary:
	return _reflect_targets.get(enemy_idx, {})


## 检查敌人是否有激活的反弹效果
func has_reflect_target(enemy_idx: int) -> bool:
	if not _reflect_targets.has(enemy_idx):
		return false
	return _reflect_targets[enemy_idx].get("duration_left", 0) > 0


## 处理灼烧伤害
## 在敌人回合开始时调用，对玩家目标造成灼烧伤害
## 返回: { "target_idx": int, "damage": int, "expired": bool }
func process_burn_damage(enemy_idx: int) -> Dictionary:
	if not _burn_targets.has(enemy_idx):
		return { "target_idx": -1, "damage": 0, "expired": false }
	
	var burn_info: Dictionary = _burn_targets[enemy_idx]
	var target_idx: int = burn_info.get("target_idx", -1)
	var damage: int = burn_info.get("damage", 0)
	var duration_left: int = burn_info.get("duration_left", 0)
	
	if target_idx < 0 or duration_left <= 0:
		_burn_targets.erase(enemy_idx)
		return { "target_idx": target_idx, "damage": 0, "expired": false }
	
	# 造成灼烧伤害
	skill_burn_damage.emit(enemy_idx, target_idx, damage)
	enemy_skill_action.emit({
		"type": "burn_damage",
		"enemy_index": enemy_idx,
		"target_index": target_idx,
		"damage": damage
	})
	
	# 持续时间减少
	duration_left -= 1
	burn_info["duration_left"] = duration_left
	
	var expired: bool = false
	if duration_left <= 0:
		_burn_targets.erase(enemy_idx)
		expired = true
		skill_burn_expire.emit(enemy_idx, target_idx)
		enemy_skill_action.emit({
			"type": "burn_expire",
			"enemy_index": enemy_idx,
			"target_index": target_idx
		})
	
	return { "target_idx": target_idx, "damage": damage, "expired": expired }


## 获取当前灼烧目标
func get_burn_target(enemy_idx: int) -> Dictionary:
	return _burn_targets.get(enemy_idx, {})


## 检查敌人是否有激活的灼烧效果
func has_burn_target(enemy_idx: int) -> bool:
	if not _burn_targets.has(enemy_idx):
		return false
	return _burn_targets[enemy_idx].get("duration_left", 0) > 0


# ==================== Phase 6: 冰封技能 ====================

## 尝试激活冰封效果
## 在敌人攻击造成伤害后调用（概率触发）
## target_idx: 攻击者的索引（通常是玩家队伍中的某个宠物）
## 返回: { "activated": bool, "chance": float, "duration": int }
func try_activate_freeze(enemy_idx: int, target_idx: int) -> Dictionary:
	var state = get_skill_state(enemy_idx, "freeze")
	if state.is_empty():
		return { "activated": false, "chance": 0.0, "duration": 0 }
	
	# 如果已经存在冰封效果，不重复激活
	if _freeze_targets.has(enemy_idx) and _freeze_targets[enemy_idx].get("duration_left", 0) > 0:
		return { "activated": false, "chance": 0.0, "duration": 0 }
	
	var freeze_chance: float = state.get("chance", 0.3)
	var freeze_duration: int = state.get("duration", 1)
	
	# 概率判定
	if randf() > freeze_chance:
		return { "activated": false, "chance": freeze_chance, "duration": 0 }
	
	_freeze_targets[enemy_idx] = {
		"target_idx": target_idx,
		"chance": freeze_chance,
		"duration_left": freeze_duration
	}
	
	skill_freeze_activate.emit(enemy_idx, target_idx, freeze_chance, freeze_duration)
	enemy_skill_action.emit({
		"type": "freeze_activate",
		"enemy_index": enemy_idx,
		"target_index": target_idx,
		"chance": freeze_chance,
		"duration": freeze_duration
	})
	
	return { "activated": true, "chance": freeze_chance, "duration": freeze_duration }


## 检查目标是否处于冰封状态
## 返回: bool - 是否被冰封
func is_target_frozen(enemy_idx: int) -> bool:
	if not _freeze_targets.has(enemy_idx):
		return false
	return _freeze_targets[enemy_idx].get("duration_left", 0) > 0


## 获取冰封信息
func get_freeze_info(enemy_idx: int) -> Dictionary:
	return _freeze_targets.get(enemy_idx, {})


## 处理冰封效果持续时间
## 在玩家回合开始时调用，更新冰封持续时间并返回是否仍处于冰封状态
## 返回: { "target_idx": int, "is_frozen": bool, "expired": bool }
func process_freeze_duration(enemy_idx: int) -> Dictionary:
	if not _freeze_targets.has(enemy_idx):
		return { "target_idx": -1, "is_frozen": false, "expired": false }
	
	var freeze_info: Dictionary = _freeze_targets[enemy_idx]
	var target_idx: int = freeze_info.get("target_idx", -1)
	var duration_left: int = freeze_info.get("duration_left", 0)
	
	if target_idx < 0:
		_freeze_targets.erase(enemy_idx)
		return { "target_idx": -1, "is_frozen": false, "expired": false }
	
	var is_frozen: bool = duration_left > 0
	var expired: bool = false
	
	# 持续时间减少
	duration_left -= 1
	freeze_info["duration_left"] = duration_left
	
	if duration_left <= 0:
		_freeze_targets.erase(enemy_idx)
		expired = true
		skill_freeze_expire.emit(enemy_idx, target_idx)
		enemy_skill_action.emit({
			"type": "freeze_expire",
			"enemy_index": enemy_idx,
			"target_index": target_idx
		})
	
	return { "target_idx": target_idx, "is_frozen": is_frozen, "expired": expired }


## 获取当前冰封目标
func get_freeze_target(enemy_idx: int) -> Dictionary:
	return _freeze_targets.get(enemy_idx, {})


# ==================== Phase 7: 中毒技能 ====================

## 尝试对攻击者施加中毒效果
## 在敌人攻击造成伤害后调用（叠层机制）
## target_idx: 攻击者的索引（通常是玩家队伍中的某个宠物）
## 返回: { "applied": bool, "stacks": int, "max_stacks": int, "damage_per_stack": int }
func try_apply_poison(enemy_idx: int, target_idx: int) -> Dictionary:
	var state = get_skill_state(enemy_idx, "poison")
	if state.is_empty():
		return { "applied": false, "stacks": 0, "max_stacks": 0, "damage_per_stack": 0 }
	
	var max_stacks: int = state.get("max_stacks", 3)
	var damage_per_stack: int = state.get("damage_per_stack", 10)
	
	# 如果目标已有中毒效果，增加层数
	if _poison_targets.has(enemy_idx):
		var poison_info: Dictionary = _poison_targets[enemy_idx]
		var current_stacks: int = poison_info.get("stacks", 0)
		var current_target: int = poison_info.get("target_idx", -1)
		
		# 如果是同一个目标，增加层数
		if current_target == target_idx and current_stacks < max_stacks:
			current_stacks += 1
			poison_info["stacks"] = current_stacks
			poison_info["duration_left"] = state.get("interval", 1)  # 重置持续时间
			
			skill_poison_stack_increase.emit(enemy_idx, target_idx, current_stacks, max_stacks)
			enemy_skill_action.emit({
				"type": "poison_stack_increase",
				"enemy_index": enemy_idx,
				"target_index": target_idx,
				"stacks": current_stacks,
				"max_stacks": max_stacks
			})
			
			return { "applied": true, "stacks": current_stacks, "max_stacks": max_stacks, "damage_per_stack": damage_per_stack }
		# 如果是不同目标，覆盖
		elif current_target != target_idx:
			_poison_targets[enemy_idx] = {
				"target_idx": target_idx,
				"stacks": 1,
				"max_stacks": max_stacks,
				"damage_per_stack": damage_per_stack,
				"duration_left": state.get("interval", 1)
			}
			
			skill_poison_apply.emit(enemy_idx, target_idx, 1, damage_per_stack, max_stacks)
			enemy_skill_action.emit({
				"type": "poison_apply",
				"enemy_index": enemy_idx,
				"target_index": target_idx,
				"stacks": 1,
				"max_stacks": max_stacks
			})
			
			return { "applied": true, "stacks": 1, "max_stacks": max_stacks, "damage_per_stack": damage_per_stack }
	# 新目标
	else:
		_poison_targets[enemy_idx] = {
			"target_idx": target_idx,
			"stacks": 1,
			"max_stacks": max_stacks,
			"damage_per_stack": damage_per_stack,
			"duration_left": state.get("interval", 1)
		}
		
		skill_poison_apply.emit(enemy_idx, target_idx, 1, damage_per_stack, max_stacks)
		enemy_skill_action.emit({
			"type": "poison_apply",
			"enemy_index": enemy_idx,
			"target_index": target_idx,
			"stacks": 1,
			"max_stacks": max_stacks
		})
		
		return { "applied": true, "stacks": 1, "max_stacks": max_stacks, "damage_per_stack": damage_per_stack }
	
	return { "applied": false, "stacks": 0, "max_stacks": 0, "damage_per_stack": 0 }


## 处理中毒伤害
## 在敌人回合开始时调用，对玩家目标造成中毒伤害（每层每回合掉血）
## 返回: { "target_idx": int, "total_damage": int, "stacks": int, "expired": bool }
func process_poison_damage(enemy_idx: int) -> Dictionary:
	if not _poison_targets.has(enemy_idx):
		return { "target_idx": -1, "total_damage": 0, "stacks": 0, "expired": false }
	
	var poison_info: Dictionary = _poison_targets[enemy_idx]
	var target_idx: int = poison_info.get("target_idx", -1)
	var stacks: int = poison_info.get("stacks", 0)
	var damage_per_stack: int = poison_info.get("damage_per_stack", 10)
	var duration_left: int = poison_info.get("duration_left", 0)
	
	if target_idx < 0 or stacks <= 0:
		_poison_targets.erase(enemy_idx)
		return { "target_idx": target_idx, "total_damage": 0, "stacks": 0, "expired": false }
	
	# 计算总伤害 = 层数 * 每层伤害
	var total_damage: int = stacks * damage_per_stack
	
	# 造成中毒伤害
	skill_poison_damage.emit(enemy_idx, target_idx, total_damage, stacks)
	enemy_skill_action.emit({
		"type": "poison_damage",
		"enemy_index": enemy_idx,
		"target_index": target_idx,
		"damage": total_damage,
		"stacks": stacks
	})
	
	# 持续时间减少
	duration_left -= 1
	poison_info["duration_left"] = duration_left
	
	var expired: bool = false
	if duration_left <= 0:
		_poison_targets.erase(enemy_idx)
		expired = true
		skill_poison_expire.emit(enemy_idx, target_idx)
		enemy_skill_action.emit({
			"type": "poison_expire",
			"enemy_index": enemy_idx,
			"target_index": target_idx
		})
	
	return { "target_idx": target_idx, "total_damage": total_damage, "stacks": stacks, "expired": expired }


## 获取当前中毒目标信息
func get_poison_target(enemy_idx: int) -> Dictionary:
	return _poison_targets.get(enemy_idx, {})


## 检查敌人是否有激活的中毒效果
func has_poison_target(enemy_idx: int) -> bool:
	if not _poison_targets.has(enemy_idx):
		return false
	return _poison_targets[enemy_idx].get("stacks", 0) > 0


## 获取中毒层数
func get_poison_stacks(enemy_idx: int) -> int:
	if not _poison_targets.has(enemy_idx):
		return 0
	return _poison_targets[enemy_idx].get("stacks", 0)


## 每个敌人回合开始时调用，更新技能冷却/计时
func on_enemy_turn_start(enemy_idx: int, enemy: Dictionary) -> void:
	# 处理反弹效果持续时间（先减少）
	process_reflect_duration(enemy_idx)
	# 处理灼烧伤害（对玩家目标）
	process_burn_damage(enemy_idx)
	# 处理中毒伤害（叠层机制）
	process_poison_damage(enemy_idx)
	# 处理浪涌伤害（每回合递增）
	process_surge_damage(enemy_idx)


## 处理雷击技能
## 在敌人回合结束时调用，检查是否应触发雷击
## 返回: { "triggered": bool, "damage": int }
func execute_thunder_strike(enemy_idx: int, enemy: Dictionary) -> Dictionary:
	var state = get_skill_state(enemy_idx, "thunder_strike")
	if state.is_empty():
		return { "triggered": false, "damage": 0 }
	
	state["turns_since_last"] += 1
	var cooldown: int = state.get("cooldown", 3)
	
	if state["turns_since_last"] >= cooldown:
		state["turns_since_last"] = 0
		
		var damage: int = state.get("damage", 50)
		
		skill_thunder_strike_triggered.emit(enemy_idx, damage)
		enemy_skill_action.emit({
			"type": "thunder_strike",
			"enemy_index": enemy_idx,
			"enemy": enemy,
			"damage": damage
		})
		
		return { "triggered": true, "damage": damage }
	
	return { "triggered": false, "damage": 0 }


## 每个敌人回合结束时调用，处理技能触发
func on_enemy_turn_end(enemy_idx: int, enemy: Dictionary) -> void:
	# 检查灼烧是否应该触发（基于interval）
	var burn_state = get_skill_state(enemy_idx, "burn")
	if not burn_state.is_empty():
		burn_state["turns_since_last"] += 1
		# interval控制的是"触发灼烧的频率"，目前burn是立即施加，不需要interval检查
	
	# 处理雷击
	execute_thunder_strike(enemy_idx, enemy)
	# 处理灵魂吸取
	execute_life_drain(enemy_idx, enemy)


# ==================== Phase 8: 灵魂吸取技能 ====================

## 处理灵魂吸取技能
## 在敌人回合结束时调用，检查是否应触发灵魂吸取
## 吸取玩家当前HP的一定百分比并回复自己
## 返回: { "triggered": bool, "drain_amount": int, "heal_amount": int, "target_idx": int }
func execute_life_drain(enemy_idx: int, enemy: Dictionary) -> Dictionary:
	var state = get_skill_state(enemy_idx, "life_drain")
	if state.is_empty():
		return { "triggered": false, "drain_amount": 0, "heal_amount": 0, "target_idx": -1 }
	
	state["turns_since_last"] += 1
	var cooldown: int = state.get("cooldown", 4)
	
	if state["turns_since_last"] >= cooldown:
		state["turns_since_last"] = 0
		
		var percent: float = state.get("percent", 0.15)
		var target_idx: int = -1
		
		# 寻找玩家队伍中HP最高的单位作为吸取目标
		# 玩家队伍存储在 enemy["player_party"] 中
		var player_party: Array = enemy.get("player_party", [])
		if not player_party.is_empty():
			var max_hp: int = 0
			for pet in player_party:
				var hp: int = pet.get("hp", 0)
				if hp > max_hp:
					max_hp = hp
					target_idx = pet.get("idx", -1)
		
		if target_idx < 0:
			return { "triggered": false, "drain_amount": 0, "heal_amount": 0, "target_idx": -1 }
		
		# 计算吸取量：基于目标当前HP
		var target_hp: int = 0
		for pet in player_party:
			if pet.get("idx", -1) == target_idx:
				target_hp = pet.get("hp", 0)
				break
		
		var drain_amount: int = int(target_hp * percent)
		var heal_amount: int = drain_amount  # 回复量等于吸取量
		
		skill_life_drain_triggered.emit(enemy_idx, target_idx, drain_amount, heal_amount)
		enemy_skill_action.emit({
			"type": "life_drain",
			"enemy_index": enemy_idx,
			"enemy": enemy,
			"target_index": target_idx,
			"drain_amount": drain_amount,
			"heal_amount": heal_amount
		})
		
		return { "triggered": true, "drain_amount": drain_amount, "heal_amount": heal_amount, "target_idx": target_idx }
	
	return { "triggered": false, "drain_amount": 0, "heal_amount": 0, "target_idx": -1 }


## 重置所有技能状态（战斗重新开始时调用）
func reset() -> void:
	_skill_states.clear()
	_burn_targets.clear()
	_reflect_targets.clear()
	_freeze_targets.clear()
	_poison_targets.clear()
	_surge_targets.clear()
	_confuse_targets.clear()


# ==================== Phase 9: 浪涌技能 ====================

## 尝试对攻击者施加浪涌效果
## 在敌人攻击造成伤害后调用（每回合伤害递增）
## target_idx: 攻击者的索引（通常是玩家队伍中的某个宠物）
## 返回: { "applied": bool, "base_damage": int, "current_damage": int, "max_damage": int, "increment": int }
func try_apply_surge(enemy_idx: int, target_idx: int) -> Dictionary:
	var state = get_skill_state(enemy_idx, "surge")
	if state.is_empty():
		return { "applied": false, "base_damage": 0, "current_damage": 0, "max_damage": 0, "increment": 0 }
	
	var base_damage: int = state.get("base_damage", 30)
	var increment: int = state.get("increment_per_turn", 10)
	var max_damage: int = state.get("max_damage", 100)
	
	# 如果目标已有浪涌效果，增加伤害
	if _surge_targets.has(enemy_idx):
		var surge_info: Dictionary = _surge_targets[enemy_idx]
		surge_info["turn_number"] += 1
		surge_info["current_damage"] = mini(surge_info["current_damage"] + increment, max_damage)
		
		skill_surge_damage.emit(enemy_idx, target_idx, surge_info["current_damage"], surge_info["turn_number"])
		enemy_skill_action.emit({
			"type": "surge_damage",
			"enemy_index": enemy_idx,
			"target_index": target_idx,
			"damage": surge_info["current_damage"],
			"turn_number": surge_info["turn_number"]
		})
		
		return { "applied": true, "base_damage": base_damage, "current_damage": surge_info["current_damage"], "max_damage": max_damage, "increment": increment }
	# 新目标
	else:
		_surge_targets[enemy_idx] = {
			"target_idx": target_idx,
			"base_damage": base_damage,
			"increment": increment,
			"current_damage": base_damage,
			"max_damage": max_damage,
			"turn_number": 1
		}
		
		skill_surge_damage.emit(enemy_idx, target_idx, base_damage, 1)
		enemy_skill_action.emit({
			"type": "surge_damage",
			"enemy_index": enemy_idx,
			"target_index": target_idx,
			"damage": base_damage,
			"turn_number": 1
		})
		
		return { "applied": true, "base_damage": base_damage, "current_damage": base_damage, "max_damage": max_damage, "increment": increment }


## 处理浪涌伤害
## 在敌人回合开始时调用，对玩家目标造成浪涌伤害
## 返回: { "target_idx": int, "damage": int, "turn_number": int, "expired": bool }
func process_surge_damage(enemy_idx: int) -> Dictionary:
	if not _surge_targets.has(enemy_idx):
		return { "target_idx": -1, "damage": 0, "turn_number": 0, "expired": false }
	
	var surge_info: Dictionary = _surge_targets[enemy_idx]
	var target_idx: int = surge_info.get("target_idx", -1)
	var damage: int = surge_info.get("current_damage", 0)
	var turn_number: int = surge_info.get("turn_number", 0)
	
	if target_idx < 0 or damage <= 0:
		_surge_targets.erase(enemy_idx)
		return { "target_idx": target_idx, "damage": 0, "turn_number": 0, "expired": false }
	
	# 造成浪涌伤害
	skill_surge_damage.emit(enemy_idx, target_idx, damage, turn_number)
	enemy_skill_action.emit({
		"type": "surge_damage",
		"enemy_index": enemy_idx,
		"target_index": target_idx,
		"damage": damage,
		"turn_number": turn_number
	})
	
	# 增加伤害（每回合递增）
	var increment: int = surge_info.get("increment", 10)
	var max_damage: int = surge_info.get("max_damage", 100)
	var current_damage: int = surge_info.get("current_damage", 0)
	surge_info["current_damage"] = mini(current_damage + increment, max_damage)
	surge_info["turn_number"] += 1
	
	return { "target_idx": target_idx, "damage": damage, "turn_number": turn_number, "expired": false }


## 获取当前浪涌目标信息
func get_surge_target(enemy_idx: int) -> Dictionary:
	return _surge_targets.get(enemy_idx, {})


## 检查敌人是否有激活的浪涌效果
func has_surge_target(enemy_idx: int) -> bool:
	if not _surge_targets.has(enemy_idx):
		return false
	return _surge_targets[enemy_idx].get("current_damage", 0) > 0


## 获取浪涌当前伤害
func get_surge_current_damage(enemy_idx: int) -> int:
	if not _surge_targets.has(enemy_idx):
		return 0
	return _surge_targets[enemy_idx].get("current_damage", 0)


# ==================== Phase 10: shield_plus 强化护盾 ====================
# 护盾期间反弹近战伤害
# 配置：{ "type": "shield_plus", "hp": 100, "cooldown": 5, "reflectDamage": true, "reflectPercent": 0.5 }

## 检查并激活强化护盾
## 在敌人回合开始时调用，检查强化护盾是否应该激活
## 返回: bool - 是否成功激活护盾
func check_and_activate_shield_plus(enemy_idx: int, enemy: Dictionary) -> bool:
	var state = get_skill_state(enemy_idx, "shield_plus")
	if state.is_empty():
		return false
	
	var skills: Array = enemy.get("enemySkills", [])
	var shield_config = skills.filter(func(s): return s.get("type") == "shield_plus")
	if shield_config.is_empty():
		return false
	
	var shield_hp: int = shield_config[0].get("hp", 100)
	var cooldown: int = shield_config[0].get("cooldown", 5)
	var reflect_percent: float = shield_config[0].get("reflectPercent", 0.5)
	
	# 检查护盾是否需要激活：current_hp <= 0 且 cooldown_left <= 0
	if state.get("current_hp", 0) <= 0 and state.get("cooldown_left", 0) <= 0:
		state["current_hp"] = shield_hp
		state["max_hp"] = shield_hp
		state["cooldown_left"] = cooldown
		
		skill_shield_plus_appear.emit(enemy_idx, shield_hp, reflect_percent)
		enemy_skill_action.emit({
			"type": "shield_plus_appear",
			"enemy_index": enemy_idx,
			"enemy": enemy,
			"shield_hp": shield_hp,
			"shield_max_hp": shield_hp,
			"reflect_percent": reflect_percent
		})
		return true
	
	# 冷却递减
	if state.get("cooldown_left", 0) > 0:
		state["cooldown_left"] -= 1
	
	return false


## 强化护盾减伤计算
## 在伤害结算前调用，将伤害分为护盾吸收部分和穿透部分，并处理反弹
## 返回: { "absorbed": int, "remaining": int, "reflected": bool, "reflect_damage": int, "reflect_target_idx": int }
func execute_shield_plus_before_damage(enemy_idx: int, damage: int, attacker_idx: int = -1) -> Dictionary:
	var state = get_skill_state(enemy_idx, "shield_plus")
	if state.is_empty():
		return { "absorbed": 0, "remaining": damage, "reflected": false, "reflect_damage": 0, "reflect_target_idx": -1 }
	
	var shield_hp: int = state.get("current_hp", 0)
	if shield_hp <= 0:
		return { "absorbed": 0, "remaining": damage, "reflected": false, "reflect_damage": 0, "reflect_target_idx": -1 }
	
	# 使用 DamageCalculator 计算护盾吸收
	var absorbed := mini(shield_hp, damage)
	var remaining := damage - absorbed
	state["current_hp"] -= absorbed
	
	# 检查是否需要反弹伤害
	var reflect_damage: int = 0
	var reflected: bool = false
	var reflect_target_idx: int = -1
	if state.get("reflect_damage", true) and attacker_idx >= 0:
		var reflect_percent: float = state.get("reflect_percent", 0.5)
		reflect_damage = int(absorbed * reflect_percent)
		reflected = true
		reflect_target_idx = attacker_idx
		
		skill_shield_plus_reflect.emit(enemy_idx, attacker_idx, reflect_damage)
		enemy_skill_action.emit({
			"type": "shield_plus_reflect",
			"enemy_index": enemy_idx,
			"target_index": attacker_idx,
			"reflected_damage": reflect_damage,
			"reflect_percent": reflect_percent
		})
	
	# 如果护盾被打破，发出信号
	if state["current_hp"] <= 0:
		skill_shield_plus_broken.emit(enemy_idx)
		enemy_skill_action.emit({
			"type": "shield_plus_broken",
			"enemy_index": enemy_idx
		})
	
	return { "absorbed": absorbed, "remaining": remaining, "reflected": reflected, "reflect_damage": reflect_damage, "reflect_target_idx": reflect_target_idx }


## 检查强化护盾状态（是否有效）
func is_shield_plus_active(enemy_idx: int) -> bool:
	var state = get_skill_state(enemy_idx, "shield_plus")
	return state.get("current_hp", 0) > 0


## 获取强化护盾当前HP
func get_shield_plus_hp(enemy_idx: int) -> int:
	var state = get_skill_state(enemy_idx, "shield_plus")
	return state.get("current_hp", 0)


## 获取强化护盾剩余冷却
func get_shield_plus_cooldown(enemy_idx: int) -> int:
	var state = get_skill_state(enemy_idx, "shield_plus")
	return state.get("cooldown_left", 0)


# ==================== Phase 11: 混乱技能 ====================
# 概率让玩家攻击自己人，持续1回合
# 配置：{ "type": "confuse", "chance": 0.2, "duration": 1 }

## 尝试激活混乱效果
## 在敌人攻击造成伤害后调用（概率触发）
## target_idx: 攻击者的索引（通常是玩家队伍中的某个宠物）
## 返回: { "activated": bool, "chance": float, "duration": int }
func try_activate_confuse(enemy_idx: int, target_idx: int) -> Dictionary:
	var state = get_skill_state(enemy_idx, "confuse")
	if state.is_empty():
		return { "activated": false, "chance": 0.0, "duration": 0 }
	
	# 如果已经存在混乱效果，不重复激活
	if _confuse_targets.has(enemy_idx) and _confuse_targets[enemy_idx].get("duration_left", 0) > 0:
		return { "activated": false, "chance": 0.0, "duration": 0 }
	
	var confuse_chance: float = state.get("chance", 0.2)
	var confuse_duration: int = state.get("duration", 1)
	
	# 概率判定
	if randf() > confuse_chance:
		return { "activated": false, "chance": confuse_chance, "duration": 0 }
	
	_confuse_targets[enemy_idx] = {
		"target_idx": target_idx,
		"chance": confuse_chance,
		"duration_left": confuse_duration
	}
	
	skill_confuse_activate.emit(enemy_idx, target_idx, confuse_chance, confuse_duration)
	enemy_skill_action.emit({
		"type": "confuse_activate",
		"enemy_index": enemy_idx,
		"target_index": target_idx,
		"chance": confuse_chance,
		"duration": confuse_duration
	})
	
	return { "activated": true, "chance": confuse_chance, "duration": confuse_duration }


## 检查目标是否处于混乱状态
## 返回: bool - 是否被混乱
func is_target_confused(enemy_idx: int) -> bool:
	if not _confuse_targets.has(enemy_idx):
		return false
	return _confuse_targets[enemy_idx].get("duration_left", 0) > 0


## 获取混乱信息
func get_confuse_info(enemy_idx: int) -> Dictionary:
	return _confuse_targets.get(enemy_idx, {})


## 处理混乱效果持续时间
## 在玩家回合开始时调用，更新混乱持续时间并返回是否仍处于混乱状态
## 返回: { "target_idx": int, "is_confused": bool, "expired": bool }
func process_confuse_duration(enemy_idx: int) -> Dictionary:
	if not _confuse_targets.has(enemy_idx):
		return { "target_idx": -1, "is_confused": false, "expired": false }
	
	var confuse_info: Dictionary = _confuse_targets[enemy_idx]
	var target_idx: int = confuse_info.get("target_idx", -1)
	var duration_left: int = confuse_info.get("duration_left", 0)
	
	if target_idx < 0:
		_confuse_targets.erase(enemy_idx)
		return { "target_idx": -1, "is_confused": false, "expired": false }
	
	var is_confused: bool = duration_left > 0
	var expired: bool = false
	
	# 持续时间减少
	duration_left -= 1
	confuse_info["duration_left"] = duration_left
	
	if duration_left <= 0:
		_confuse_targets.erase(enemy_idx)
		expired = true
		skill_confuse_expire.emit(enemy_idx, target_idx)
		enemy_skill_action.emit({
			"type": "confuse_expire",
			"enemy_index": enemy_idx,
			"target_index": target_idx
		})
	
	return { "target_idx": target_idx, "is_confused": is_confused, "expired": expired }


## 获取当前混乱目标
func get_confuse_target(enemy_idx: int) -> Dictionary:
	return _confuse_targets.get(enemy_idx, {})