# ============================================
# battle/battle_manager.gd - 战斗管理器核心
# 翻译自 js/battle/battleManager.js
# ============================================
class_name BattleManager
extends Node

## 战斗核心逻辑：玩家队伍/敌方怪物初始化、连锁伤害计算、
## BOSS多阶段、敌人技能系统、C4状态效果、队长技能、属性协同
## 单例模式：通过 static var instance 访问

# ========== 信号定义 ==========
signal damage_dealt(damage_info: Dictionary)
signal enemy_attacked(action_info: Dictionary)
signal battle_ended(result: String)
signal skill_ready(monster: Dictionary)
signal phase_transition(phase: int, new_enemies: Array)
signal enemy_skill_action(action_info: Dictionary)

# ========== 实例变量 ==========
var player_team: Array = []        # 玩家队伍 [{...stats}]
var enemies: Array = []            # 敌方怪物 [{...stats}]
var turn: int = 0
var combo: int = 0                # 当前连锁数
var total_damage_dealt: Dictionary = {}  # 按属性统计伤害
var skill_charges: Dictionary = {}       # 技能充能 { monsterId: charge }
var battle_over: bool = false
var battle_result: String = ""     # 'win' | 'lose'
var turn_count: int = 0
var max_turns: int = 20

# BOSS多阶段
var current_phase: int = 1
var stage_phases: Array = []       # 关卡阶段配置
var phase_transition_triggered: Dictionary = {}  # { phaseNum: true }

# 敌人技能系统实例
var _enemy_skill_system: EnemySkillSystem = null

func set_enemy_skill_system(system: EnemySkillSystem) -> void:
	_enemy_skill_system = system

# 队长技能状态
var leader_skill_data: Dictionary = {}
var leader_skill_info: Variant = null

# 属性协同状态
var synergy_bonuses: Variant = null
var synergy_info: Array = []

# 组件委托（由外部抽取后内联持有）
var _status_effect: BattleStatusEffect = BattleStatusEffect.new()
var _phase_handler: PhaseHandler = PhaseHandler.new(self)
var _damage_calc: DamageCalculator = DamageCalculator.new()

# 关卡数据
var stage_data: Variant = null
var stage_id: String = ""

# 等级
var player_level: int = 1
var enemy_level: int = 1

# ========== 单例模式 ==========
static var instance: BattleManager

func _enter_tree() -> void:
	instance = self

func _exit_tree() -> void:
	instance = null

# ========== 初始化 ==========
func init(player_monster_ids: Array, enemy_monster_ids: Array, p_level: int = 1, e_level: int = 1, s_data: Variant = null, s_id: String = "") -> void:
	player_team = player_monster_ids.map(func(id): return MonsterDb.get_monster_stats(id, p_level))

	stage_data = s_data
	stage_id = s_id

	stage_phases = []
	current_phase = 1
	phase_transition_triggered = {}

	if s_data != null and s_data.has("phases") and s_data.get("phases", []).size() > 0:
		stage_phases = s_data.get("phases")
		_phase_handler.set_phase_configs(stage_phases)
		var phase1: Dictionary = stage_phases[0] if stage_phases.size() > 0 else {}
		if not phase1.is_empty():
			var hp_mult: float = phase1.get("hpMultiplier", 1.0)
			enemies = phase1.get("enemies", []).map(func(id):
				var monster = MonsterDb.get_monster_stats(id, e_level)
				if monster != null and hp_mult != 1.0:
					monster["maxHP"] = int(monster.get("maxHP", 0) * hp_mult)
					monster["hp"] = monster["maxHP"]
					monster["atk"] = int(monster.get("atk", 0) * hp_mult)
				return monster
			)
	else:
		enemies = enemy_monster_ids.map(func(id): return MonsterDb.get_monster_stats(id, e_level))

	turn = 0
	combo = 0
	total_damage_dealt = {}
	battle_over = false
	battle_result = ""
	turn_count = 0

	player_level = p_level
	enemy_level = e_level

	for m in player_team:
		if m != null:
			skill_charges[m.get("id", "")] = 0

	enemy_skill_states = {}
	for i in range(enemies.size()):
		var enemy = enemies[i]
		var skills: Array = []
		if enemy != null and enemy.get("enemySkills", null) is Array:
			skills = enemy.get("enemySkills", [])
		if not skills.is_empty():
			var state: Dictionary = {}
			for skill in skills:
				if skill.get("type") == "charge":
					state["charge"] = { "turns_since_last": 0, "is_charging": false }
				elif skill.get("type") == "shield":
					state["shield"] = { "current_hp": 0, "max_hp": skill.get("hp", 0), "cooldown_left": 0 }
				elif skill.get("type") == "heal":
					state["heal"] = { "turns_since_last": 0 }
			enemy_skill_states[i] = state

	leader_skill_data = {}
	leader_skill_info = null
	var leader = player_team[0] if player_team.size() > 0 else null
	if leader != null and leader.has("leaderSkill"):
		var skill_data = LeaderSkillDb.get_leader_skill(leader.get("leaderSkill", ""))
		if not skill_data.is_empty():
			leader_skill_data = skill_data
			leader_skill_info = {
				"id": skill_data.get("id", ""),
				"name": skill_data.get("name", ""),
				"desc": skill_data.get("desc", ""),
				"icon": skill_data.get("icon", "")
			}
			if skill_data.get("type") == "hp_boost":
				var hp_mult_ls = skill_data.get("hpMultiplier", 1.2)
				for m in player_team:
					if m != null:
						m["maxHP"] = int(m.get("maxHP", 0) * hp_mult_ls)
						m["hp"] = m["maxHP"]
			if skill_data.get("type") == "combo_start":
				combo = skill_data.get("initialCombo", 1)

	synergy_bonuses = null
	synergy_info = []
	_calc_and_apply_element_synergy()

	_status_effect.init_effects(enemies.size())


# ========== 属性协同加成 ==========

func _calc_and_apply_element_synergy() -> void:
	var element_counts: Dictionary = {}
	for m in player_team:
		if m == null:
			continue
		var elem = m.get("element", "")
		element_counts[elem] = element_counts.get(elem, 0) + 1

	synergy_bonuses = {}
	var elem_names: Dictionary = { "fire": "火", "water": "水", "grass": "草", "thunder": "雷", "light": "光" }
	var elem_emojis: Dictionary = { "fire": "🔥", "water": "💧", "grass": "🌿", "thunder": "⚡", "light": "✨" }

	for elem in element_counts.keys():
		var count = element_counts[elem]
		if count < 2:
			continue

		var atk_mult: float = 1.15 if count == 2 else 1.30
		var def_mult: float = 1.10 if count == 2 else 1.20
		var hp_mult: float = 1.10 if count == 2 else 1.20

		synergy_bonuses[elem] = { "count": count, "atk_mult": atk_mult, "def_mult": def_mult, "hp_mult": hp_mult }

		var pct_label = "+15%ATK/+10%DEF" if count == 2 else "+30%ATK/+20%DEF"
		var elem_emoji = elem_emojis.get(elem, "")
		var elem_name = elem_names.get(elem, elem)
		synergy_info.append({
			"element": elem,
			"count": count,
			"label": "%s×%d %s属性共鸣 %s" % [elem_emoji, count, elem_name, pct_label]
		})

		for m in player_team:
			if m != null and m.get("element", "") == elem:
				m["maxHP"] = int(m.get("maxHP", 0) * hp_mult)
				m["hp"] = m["maxHP"]


func get_synergy_atk_mult(element: String) -> float:
	if synergy_bonuses == null or not synergy_bonuses.has(element):
		return 1.0
	return synergy_bonuses[element].get("atk_mult", 1.0)


func get_synergy_def_mult(element: String) -> float:
	if synergy_bonuses == null or not synergy_bonuses.has(element):
		return 1.0
	return synergy_bonuses[element].get("def_mult", 1.0)


# ========== 消除结果处理 ==========

func process_match_result(gem_counts: Dictionary, combo_count: int) -> Dictionary:
	self.combo = combo_count
	var damage_log: Array = []

	for monster in player_team:
		if monster == null or monster.get("hp", 0) <= 0:
			continue

		var gem_count = gem_counts.get(monster.get("element", ""), 0)
		if gem_count == 0:
			continue

		var element_mult = 1.0
		var target = _get_weakest_enemy()
		if target == null:
			continue

		element_mult = MonsterDb.get_element_multiplier(monster.get("element", ""), target.get("element", ""))

		var leader_atk_boost = LeaderSkillDb.get_leader_atk_boost(leader_skill_data, monster.get("element", ""))
		var synergy_atk_mult = get_synergy_atk_mult(monster.get("element", ""))

		# 委托给 DamageCalculator
		var total_damage = _damage_calc.calc_player_damage(
			monster.get("atk", 10),
			monster.get("element", ""),
			target.get("def", 0),
			gem_count,
			combo_count,
			element_mult,
			leader_atk_boost,
			synergy_atk_mult
		)

		var mon_id = monster.get("id", "")
		var skill_cost: int = int(monster.get("skill", {}).get("cost", 999))
		var prev_charge: int = int(skill_charges.get(mon_id, 0))
		var next_charge: int = mini(prev_charge + gem_count, skill_cost)
		skill_charges[mon_id] = next_charge
		if prev_charge < skill_cost and next_charge >= skill_cost:
			skill_ready.emit(monster)

		var target_idx = enemies.find(target)
		var skill_state = enemy_skill_states.get(target_idx, {})

		# 护盾吸收
		if skill_state.has("shield") and skill_state["shield"].get("current_hp", 0) > 0:
			var shield_result = _damage_calc.apply_shield(total_damage, skill_state["shield"]["current_hp"])
			skill_state["shield"]["current_hp"] -= shield_result["absorbed"]
			var remaining_damage = shield_result["remaining"]
			target["hp"] = target.get("hp", 0) - remaining_damage
		else:
			target["hp"] = target.get("hp", 0) - total_damage

		total_damage_dealt[mon_id] = total_damage_dealt.get(mon_id, 0) + total_damage

		damage_log.append({
			"attacker": monster.get("name", ""),
			"attacker_emoji": monster.get("emoji", ""),
			"target": target.get("name", ""),
			"target_emoji": target.get("emoji", ""),
			"damage": total_damage,
			"element": monster.get("element", ""),
			"combo": combo_count,
			"is_effective": element_mult > 1.0,
			"is_weak": element_mult < 1.0,
			"target_died": target.get("hp", 0) <= 0
		})

		damage_dealt.emit(damage_log[damage_log.size() - 1])

	# 阶段转换检查
	var phase_to_trigger = _phase_handler.check_phase_transition()
	if not phase_to_trigger.is_empty():
		return { "damage_log": damage_log, "phase_transition": phase_to_trigger }

	# 状态效果（委托给 BattleStatusEffect）
	_status_effect.try_apply_status_effects(gem_counts, player_team, enemies)

	return { "damage_log": damage_log, "status_effect_log": _status_effect.get_effect_log() }


func use_active_skill(monster_id: String) -> Dictionary:
	if battle_over:
		return { "success": false, "reason": "battle_over" }

	var monster: Dictionary = _get_player_monster(monster_id)
	if monster.is_empty() or monster.get("hp", 0) <= 0:
		return { "success": false, "reason": "monster_unavailable" }

	var skill: Dictionary = monster.get("skill", {})
	if skill.is_empty():
		return { "success": false, "reason": "no_skill" }

	var cost: int = int(skill.get("cost", 999))
	var charge: int = int(skill_charges.get(monster_id, 0))
	if charge < cost:
		return {
			"success": false,
			"reason": "not_ready",
			"charge": charge,
			"cost": cost
		}

	var target = _get_weakest_enemy()
	if target == null:
		return { "success": false, "reason": "no_target" }

	var element: String = monster.get("element", "")
	var target_idx: int = enemies.find(target)
	var element_mult: float = MonsterDb.get_element_multiplier(element, target.get("element", ""))
	var leader_atk_boost: float = LeaderSkillDb.get_leader_atk_boost(leader_skill_data, element)
	var synergy_atk_mult: float = get_synergy_atk_mult(element)
	var skill_mult: float = float(skill.get("multiplier", 1.0))
	var total_damage: int = _damage_calc.calc_player_damage(
		monster.get("atk", 10),
		element,
		target.get("def", 0),
		3,
		1,
		element_mult,
		leader_atk_boost,
		synergy_atk_mult
	)
	total_damage = maxi(1, int(round(total_damage * skill_mult)))

	var shield_absorbed: int = 0
	var remaining_damage: int = total_damage
	var skill_state = enemy_skill_states.get(target_idx, {})
	if skill_state is Dictionary and skill_state.has("shield") and skill_state["shield"].get("current_hp", 0) > 0:
		var shield_result: Dictionary = _damage_calc.apply_shield(total_damage, skill_state["shield"]["current_hp"])
		shield_absorbed = shield_result.get("absorbed", 0)
		remaining_damage = shield_result.get("remaining", 0)
		skill_state["shield"]["current_hp"] -= shield_absorbed

	target["hp"] = target.get("hp", 0) - remaining_damage
	skill_charges[monster_id] = maxi(0, charge - cost)
	total_damage_dealt[monster_id] = total_damage_dealt.get(monster_id, 0) + total_damage

	var target_died: bool = target.get("hp", 0) <= 0
	var result := {
		"success": true,
		"type": "active_skill",
		"attacker": monster.get("name", ""),
		"attacker_id": monster_id,
		"attackerId": monster_id,
		"attacker_emoji": monster.get("emoji", ""),
		"skill": skill.duplicate(true),
		"skill_name": skill.get("name", "技能"),
		"skillName": skill.get("name", "技能"),
		"target": target.get("name", ""),
		"target_emoji": target.get("emoji", ""),
		"target_index": target_idx,
		"targetIndex": target_idx,
		"damage": total_damage,
		"remaining_damage": remaining_damage,
		"remainingDamage": remaining_damage,
		"shield_absorbed": shield_absorbed,
		"shieldAbsorbed": shield_absorbed,
		"element": element,
		"is_effective": element_mult > 1.0,
		"isEffective": element_mult > 1.0,
		"is_weak": element_mult < 1.0,
		"isWeak": element_mult < 1.0,
		"target_died": target_died,
		"targetDied": target_died,
		"battle_ended": false,
		"battleEnded": false
	}
	damage_dealt.emit(result)

	if check_battle_end():
		result["battle_ended"] = true
		result["battleEnded"] = true

	return result


func _get_player_monster(monster_id: String) -> Dictionary:
	for monster in player_team:
		if monster != null and monster.get("id", "") == monster_id:
			return monster
	return {}


# ========== 敌方行动 ==========

func enemy_action() -> Dictionary:
	if battle_over:
		return {}
	var actions: Array = []

	# 状态效果处理（委托给 BattleStatusEffect）
	var status_logs = _status_effect.process_status_effects(enemies)

	var dot_kills: Array = []
	for i in range(enemies.size()):
		var enemy = enemies[i]
		if enemy != null and enemy.get("hp", 0) <= 0:
			dot_kills.append({ "enemy_index": i, "enemy_name": enemy.get("name", "") })

	for i in range(enemies.size()):
		var enemy = enemies[i]
		if enemy == null or enemy.get("hp", 0) <= 0:
			continue

		var alive_team = player_team.filter(func(m): return m != null and m.get("hp", 0) > 0)
		if alive_team.is_empty():
			continue

		# 眩晕检查（委托给 BattleStatusEffect）
		if _status_effect.is_enemy_stunned(i):
			actions.append({
				"attacker": enemy.get("name", ""),
				"attacker_emoji": enemy.get("emoji", ""),
				"target": null,
				"target_emoji": null,
				"damage": 0,
				"element": enemy.get("element", ""),
				"target_died": false,
				"is_stunned": true
			})
			continue

		var skill_state = enemy_skill_states.get(i, {})
		var skills: Array = []
		if enemy.get("enemySkills", null) is Array:
			skills = enemy.get("enemySkills", [])
		var has_skills = not skill_state.is_empty() and not skills.is_empty()

		# 护盾检查
		if has_skills and skill_state.has("shield"):
			var shield_config = skills.filter(func(s): return s.get("type") == "shield")
			if not shield_config.is_empty() and skill_state["shield"].get("current_hp", 0) <= 0 and skill_state["shield"].get("cooldown_left", 0) <= 0:
				var shield_hp = shield_config[0].get("hp", 0)
				skill_state["shield"]["current_hp"] = shield_hp
				skill_state["shield"]["max_hp"] = shield_hp
				skill_state["shield"]["cooldown_left"] = shield_config[0].get("cooldown", 5)
				enemy_skill_action.emit({
						"type": "shield_appear",
						"enemy_index": i,
						"enemy": enemy,
						"shield_hp": shield_hp,
						"shield_max_hp": shield_hp
				})
			if skill_state["shield"].get("cooldown_left", 0) > 0:
				skill_state["shield"]["cooldown_left"] -= 1

		# 回血检查（委托给 EnemySkillSystem）
		if _enemy_skill_system != null and has_skills and skill_state.has("heal"):
			_enemy_skill_system.execute_heal(i, enemy)

		# 蓄力检查（委托给 EnemySkillSystem）
		var skip_attack = false
		var damage_multiplier = 1.0

		if _enemy_skill_system != null and has_skills and skill_state.has("charge"):
			damage_multiplier = _enemy_skill_system.check_and_release_charge(i)
			if _enemy_skill_system.is_charging(i):
				skip_attack = true
			else:
				_enemy_skill_system.update_and_check_charge_start(i)

		if skip_attack:
			actions.append({
				"attacker": enemy.get("name", ""),
				"attacker_emoji": enemy.get("emoji", ""),
				"target": null,
				"target_emoji": null,
				"damage": 0,
				"element": enemy.get("element", ""),
				"target_died": false,
				"is_charging": true
			})
			continue

		# 普通攻击
		var target = alive_team[randi() % alive_team.size()]

		# 冰冻ATK降低（委托给 BattleStatusEffect）
		var freeze_mult = _status_effect.get_freeze_atk_multiplier(i)

		# 队长DEF加成
		var leader_def_boost = LeaderSkillDb.get_leader_def_boost(leader_skill_data)

		# 属性协同DEF
		var synergy_def_mult = get_synergy_def_mult(target.get("element", ""))

		# 委托给 DamageCalculator
		var damage = _damage_calc.calc_enemy_damage(
			enemy.get("atk", 10),
			enemy.get("element", ""),
			target.get("def", 0),
			target.get("element", ""),
			freeze_mult,
			leader_def_boost,
			synergy_def_mult
		)

		damage = int(damage * damage_multiplier)

		target["hp"] = target.get("hp", 0) - damage

		actions.append({
			"attacker": enemy.get("name", ""),
			"attacker_emoji": enemy.get("emoji", ""),
			"target": target.get("name", ""),
			"target_emoji": target.get("emoji", ""),
			"damage": damage,
			"element": enemy.get("element", ""),
			"target_died": target.get("hp", 0) <= 0,
			"is_charged": damage_multiplier > 1.0,
			"charge_multiplier": damage_multiplier
		})

	for a in actions:
		enemy_attacked.emit(a)

	if player_team.all(func(m): return m == null or m.get("hp", 0) <= 0):
		battle_over = true
		battle_result = "lose"
		battle_ended.emit("lose")
		return { "actions": actions, "status_logs": status_logs, "dot_kills": dot_kills }

	# 回合超时强制结束
	if turn_count >= max_turns:
		battle_over = true
		battle_result = "draw"
		battle_ended.emit("draw")

	return { "actions": actions, "status_logs": status_logs, "dot_kills": dot_kills }


func _get_weakest_enemy() -> Variant:
	var weakest: Dictionary = {}
	var min_hp: int = 999999999
	for enemy in enemies:
		if enemy == null or enemy.get("hp", 0) <= 0:
			continue
		var hp: int = enemy.get("hp", 0)
		if hp < min_hp:
			min_hp = hp
			weakest = enemy
	return weakest if not weakest.is_empty() else null


# ========== 战斗结束检查 ==========

func check_battle_end() -> bool:
	var all_dead = enemies.all(func(e): return e == null or e.get("hp", 0) <= 0)
	if all_dead:
		battle_over = true
		battle_result = "win"
		battle_ended.emit("win")
		return true
	return false


# ========== 获取状态摘要 ==========

func get_status() -> Dictionary:
	return {
		"turn_count": turn_count,
		"combo": combo,
		"player_team": player_team.map(func(m): return m.duplicate(true) if m != null else null),
		"enemies": enemies.map(func(e): return e.duplicate(true) if e != null else null),
		"skill_charges": skill_charges.duplicate(),
		"battle_over": battle_over,
		"battle_result": battle_result,
		"current_phase": current_phase,
		"total_phases": stage_phases.size() if not stage_phases.is_empty() else 1,
		"is_boss_battle": not stage_phases.is_empty(),
		"enemy_skill_states": enemy_skill_states.duplicate(true),
		"leader_skill_info": leader_skill_info,
		"synergy_info": synergy_info,
		"synergy_bonuses": synergy_bonuses.duplicate(true) if synergy_bonuses != null else null,
		"status_effects": _status_effect.get_effects_snapshot(),
		"status_effect_log": _status_effect.get_effect_log()
	}


# ========== 获取战斗结果（用于结算） ==========

func get_battle_result() -> Dictionary:
	return {
		"result": battle_result,
		"turn_count": turn_count,
		"max_turns": max_turns,
		"player_team": player_team.map(func(m): return m.duplicate(true) if m != null else null),
		"enemies": enemies.map(func(e): return e.duplicate(true) if e != null else null),
		"total_damage_dealt": total_damage_dealt.duplicate(),
		"totalDamageDealt": total_damage_dealt.duplicate(),
		"player_level": player_level,
		"playerLevel": player_level,
		"enemy_level": enemy_level,
		"enemyLevel": enemy_level,
		"stage_id": stage_id,
		"stageId": stage_id,
		"turnCount": turn_count,
		"maxTurns": max_turns,
		"playerTeam": player_team.map(func(m): return m.duplicate(true) if m != null else null),
		"stageRewards": stage_data.get("rewards", null) if stage_data != null else null,
		"stage_rewards": stage_data.get("rewards", null) if stage_data != null else null
	}
