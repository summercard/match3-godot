# ============================================
# battle/battle_manager.gd - 战斗管理器核心
# 翻译自 js/battle/battleManager.js
# ============================================
class_name BattleManager
extends Node

const EnemyIntentRulesScript = preload("res://src/battle/enemy_intent_rules.gd")
const EnemyAttackModesScript = preload("res://src/battle/enemy_attack_modes.gd")

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

# 波次配置：首波只出 1 只，之后每波最多 3 只，清空后由界面延迟补下一波
const WAVE_FIRST_SIZE: int = 1
const WAVE_MAX_ON_FIELD: int = 3

# ========== 实例变量 ==========
var player_team: Array = []        # 玩家队伍 [{...stats}]
var enemies: Array = []            # 敌方怪物 [{...stats}]
var turn: int = 0
var combo: int = 0                # 当前连锁数
var total_damage_dealt: Dictionary = {}  # 按属性统计伤害
var skill_charges: Dictionary = {}       # 技能充能 { instanceId/monsterId: charge }
var battle_over: bool = false
var battle_result: String = ""     # 'win' | 'lose'
var turn_count: int = 0
var max_turns: int = 20

# 5 级起步折算：新手保护等级 5 的队伍血量按 75% 计入战斗，
# 让 5 级开局的伙伴约 13 下倒下，同时保留 1 级基准与 Boss 输出不变。
const LEVEL5_OPENING_HP_FACTOR: float = 0.75

# Boss 关卡曲线（stageData.bossCurve，只作用于 isBoss 敌人）
var boss_curve: Dictionary = {}

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
var player_guards: Dictionary = {}      # { monsterId: { reduction, turns } }
var enemy_tempo_mods: Dictionary = {}   # { enemyIndex: { reduction, turns } }
var capture_windows: Dictionary = {}    # { enemyIndex: current tamingWindow }
var capture_window_best: Dictionary = {} # { enemyIndex: best tamingWindow reached this battle }

# 组件委托（由外部抽取后内联持有）
var _status_effect: BattleStatusEffect = BattleStatusEffect.new()
var _phase_handler: PhaseHandler = PhaseHandler.new(self)
var _damage_calc: DamageCalculator = DamageCalculator.new()
## 敌人出手模式（数据驱动：怪物/关卡数据里的 attackModes）
var _attack_modes = EnemyAttackModesScript.new()

# 关卡数据
var stage_data: Variant = null
var stage_id: String = ""

# 波次状态
var wave_index: int = 1                    # 当前波次（从 1 开始）
var wave_total: int = 1                    # 总波次数
var wave_transition_pending: bool = false  # 当前波已清空，等待界面补下一波
var _pending_waves: Array = []             # 后续波次的敌人属性数组
var _wave_enemy_history: Array = []        # 各波敌人列表（结算时展示整场击败情况）

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
	var player_units: Array = player_monster_ids.map(func(id): return MonsterDb.get_monster_stats(id, p_level))
	init_with_player_team(player_units, enemy_monster_ids, p_level, e_level, s_data, s_id)

func init_with_player_team(player_team_stats: Array, enemy_monster_ids: Array, p_level: int = 1, e_level: int = 1, s_data: Variant = null, s_id: String = "") -> void:
	player_team = []
	for unit in player_team_stats:
		if unit is Dictionary and not (unit as Dictionary).is_empty():
			player_team.append((unit as Dictionary).duplicate(true))

	stage_data = s_data
	stage_id = s_id

	stage_phases = []
	current_phase = 1
	phase_transition_triggered = {}
	wave_index = 1
	wave_total = 1
	wave_transition_pending = false
	_pending_waves = []
	_wave_enemy_history = []

	var data: Dictionary = s_data if s_data is Dictionary else {}
	var elite_mult: float = float(data.get("eliteMultiplier", 0.0))

	if not data.is_empty() and data.has("phases") and data.get("phases", []).size() > 0:
		stage_phases = data.get("phases")
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
				if monster != null and elite_mult > 0.0:
					_scale_enemy_stats(monster, elite_mult)
				return monster
			)
	else:
		# 普通/精英关：全部敌人先按波次切分，首波只放出 1 只
		var all_enemies: Array = enemy_monster_ids.map(func(id):
			var monster = MonsterDb.get_monster_stats(id, e_level)
			if monster != null and elite_mult > 0.0:
				_scale_enemy_stats(monster, elite_mult)
			return monster
		)
		_build_enemy_waves(all_enemies)

	boss_curve = s_data.get("bossCurve", {}) if s_data != null and s_data is Dictionary else {}
	_apply_boss_tuning(enemies)

	turn = 0
	combo = 0
	total_damage_dealt = {}
	battle_over = false
	battle_result = ""
	turn_count = 0
	var stage_max_turns: int = int(s_data.get("maxTurns", 0)) if s_data != null else 0
	max_turns = stage_max_turns if stage_max_turns > 0 else 20

	player_level = p_level
	enemy_level = e_level

	for m in player_team:
		if m != null:
			skill_charges[m.get("id", "")] = 0

	# 敌人技能系统（委托给 EnemySkillSystem，不再手动管理）

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
	player_guards = {}
	enemy_tempo_mods = {}
	capture_windows = {}
	capture_window_best = {}
	_calc_and_apply_element_synergy()

	if p_level == 5:
		for m in player_team:
			if m != null:
				m["maxHP"] = maxi(1, int(m.get("maxHP", 1) * LEVEL5_OPENING_HP_FACTOR))
				m["hp"] = m["maxHP"]

	_status_effect.init_effects(enemies.size())
	_refresh_capture_windows()

	# 敌人技能系统初始化（委托给 EnemySkillSystem）
	if _enemy_skill_system == null:
		_enemy_skill_system = EnemySkillSystem.new()
	_enemy_skill_system.init_skill_state(enemies)
	_attack_modes.init(enemies, stage_data)

	# 连接 EnemySkillSystem 的特定信号到 BattleManager
	_connect_enemy_skill_signals()


# ========== 波次 ==========

## 把整场敌人按波次切分：首波 1 只，其余每波最多 3 只
func _build_enemy_waves(all_enemies: Array) -> void:
	_pending_waves = []
	wave_index = 1
	wave_transition_pending = false
	if all_enemies.is_empty():
		enemies = []
		wave_total = 1
		return
	var waves: Array = [all_enemies.slice(0, WAVE_FIRST_SIZE)]
	var cursor: int = WAVE_FIRST_SIZE
	while cursor < all_enemies.size():
		waves.append(all_enemies.slice(cursor, cursor + WAVE_MAX_ON_FIELD))
		cursor += WAVE_MAX_ON_FIELD
	enemies = waves[0]
	_pending_waves = waves.slice(1)
	_wave_enemy_history = waves.duplicate()
	wave_total = waves.size()


func _scale_enemy_stats(enemy: Dictionary, mult: float) -> void:
	enemy["maxHP"] = int(enemy.get("maxHP", 0) * mult)
	enemy["hp"] = enemy["maxHP"]
	enemy["atk"] = int(enemy.get("atk", 0) * mult)
	enemy["def"] = int(enemy.get("def", 0) * mult)


func has_next_wave() -> bool:
	return not _pending_waves.is_empty()


## 补下一波敌人，返回新的敌人列表；没有后续波次时返回空数组
func start_next_wave() -> Array:
	if _pending_waves.is_empty():
		return []
	enemies = _pending_waves.pop_front()
	wave_index += 1
	wave_transition_pending = false
	enemy_tempo_mods = {}
	capture_windows = {}
	capture_window_best = {}
	_status_effect.init_effects(enemies.size())
	_refresh_capture_windows()
	if _enemy_skill_system == null:
		_enemy_skill_system = EnemySkillSystem.new()
	_enemy_skill_system.reset()
	_enemy_skill_system.init_skill_state(enemies)
	_attack_modes.init(enemies, stage_data)
	_connect_enemy_skill_signals()
	return enemies


# ========== 属性协同加成 ==========

func _fantasy_element(unit: Dictionary) -> String:
	return str(unit.get("element", ""))


func _board_affinity(unit: Dictionary) -> String:
	return MonsterDb.get_board_affinity(unit)


func _calc_and_apply_element_synergy() -> void:
	var affinity_counts: Dictionary = {}
	for m in player_team:
		if m == null:
			continue
		var affinity := _board_affinity(m)
		affinity_counts[affinity] = affinity_counts.get(affinity, 0) + 1

	synergy_bonuses = {}
	var affinity_names: Dictionary = MonsterDb.BOARD_AFFINITY_NAMES
	var affinity_emojis: Dictionary = { "fire": "🔥", "water": "💧", "grass": "🌿", "thunder": "⚡", "light": "✨" }

	for affinity in affinity_counts.keys():
		var count = affinity_counts[affinity]
		if count < 2:
			continue

		var atk_mult: float = 1.15 if count == 2 else 1.30
		var def_mult: float = 1.10 if count == 2 else 1.20
		var hp_mult: float = 1.10 if count == 2 else 1.20

		synergy_bonuses[affinity] = { "count": count, "atk_mult": atk_mult, "def_mult": def_mult, "hp_mult": hp_mult }

		var pct_label = "+15%ATK/+10%DEF" if count == 2 else "+30%ATK/+20%DEF"
		var affinity_emoji = affinity_emojis.get(affinity, "")
		var affinity_name = affinity_names.get(affinity, affinity)
		synergy_info.append({
			"element": affinity,
			"boardAffinity": affinity,
			"count": count,
			"label": "%s×%d %s共鸣 %s" % [affinity_emoji, count, affinity_name, pct_label]
		})

		for m in player_team:
			if m != null and _board_affinity(m) == affinity:
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

		var board_affinity := _board_affinity(monster)
		var element := _fantasy_element(monster)
		var gem_count = gem_counts.get(board_affinity, 0)
		if gem_count == 0:
			continue

		var element_mult = 1.0
		var target = _get_weakest_enemy()
		if target == null:
			continue

		element_mult = MonsterDb.get_element_multiplier(element, target.get("element", ""))

		var leader_atk_boost = LeaderSkillDb.get_leader_atk_boost(leader_skill_data, element)
		var synergy_atk_mult = get_synergy_atk_mult(board_affinity)

		# 委托给 DamageCalculator
		var total_damage = _damage_calc.calc_player_damage(
			monster.get("atk", 10),
			element,
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

		# 护盾减伤（委托给 EnemySkillSystem）
		var shield_result = _enemy_skill_system.execute_shield_before_damage(target_idx, total_damage)
		target["hp"] = target.get("hp", 0) - shield_result["remaining"]
		_update_capture_window(target_idx)

		total_damage_dealt[mon_id] = total_damage_dealt.get(mon_id, 0) + total_damage

		damage_log.append({
			"attacker": monster.get("name", ""),
			"attacker_emoji": monster.get("emoji", ""),
			"target": target.get("name", ""),
			"target_emoji": target.get("emoji", ""),
			"damage": total_damage,
			"element": element,
			"boardAffinity": board_affinity,
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
	_refresh_capture_windows()

	return { "damage_log": damage_log, "status_effect_log": _status_effect.get_effect_log() }


func use_active_skill(monster_id: String) -> Dictionary:
	if battle_over:
		return { "success": false, "reason": "battle_over" }

	var monster: Dictionary = _get_player_monster(monster_id)
	if monster.is_empty() or monster.get("hp", 0) <= 0:
		return { "success": false, "reason": "monster_unavailable" }

	var skill: Dictionary = MonsterDb.normalize_skill(monster.get("skill", {}))
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

	var element := _fantasy_element(monster)
	var board_affinity := _board_affinity(monster)
	var skill_type := str(skill.get("type", "strike"))
	var target = _get_weakest_enemy()
	var target_idx: int = enemies.find(target) if target != null else -1
	var total_damage: int = 0
	var remaining_damage: int = 0
	var shield_absorbed: int = 0
	var element_mult: float = 1.0
	var effect_logs: Array = []
	var acted: bool = false
	var last_ally: Dictionary = {}

	for effect: Dictionary in skill.get("effects", []):
		var kind := str(effect.get("kind", "damage"))
		if kind == "damage":
			if target == null:
				continue
			element_mult = MonsterDb.get_element_multiplier(element, target.get("element", ""))
			var leader_atk_boost: float = LeaderSkillDb.get_leader_atk_boost(leader_skill_data, element)
			var synergy_atk_mult: float = get_synergy_atk_mult(board_affinity)
			var effect_mult := float(effect.get("multiplier", skill.get("multiplier", 1.0)))
			var effect_damage: int = _damage_calc.calc_player_damage(
				monster.get("atk", 10),
				element,
				target.get("def", 0),
				3,
				1,
				element_mult,
				leader_atk_boost,
				synergy_atk_mult
			)
			effect_damage = maxi(1, int(round(effect_damage * effect_mult)))
			var effect_remaining := effect_damage
			var effect_absorbed := 0
			if _enemy_skill_system != null and target_idx >= 0:
				var shield_result: Dictionary = _enemy_skill_system.execute_shield_before_damage(target_idx, effect_damage)
				effect_absorbed = shield_result.get("absorbed", 0)
				effect_remaining = shield_result.get("remaining", 0)
				_enemy_skill_system.get_skill_state(target_idx, "shield")
			target["hp"] = target.get("hp", 0) - effect_remaining
			_update_capture_window(target_idx)
			total_damage += effect_damage
			remaining_damage += effect_remaining
			shield_absorbed += effect_absorbed
			acted = true
			effect_logs.append({
				"kind": "damage",
				"target": target.get("name", ""),
				"target_index": target_idx,
				"amount": effect_damage,
				"remaining": effect_remaining,
				"shield_absorbed": effect_absorbed
			})
		elif kind == "heal":
			var ally := _get_lowest_hp_ally()
			if ally.is_empty():
				continue
			var heal_ratio := float(effect.get("ratio", 0.25))
			var min_heal := int(effect.get("min", 0))
			var heal_amount := maxi(min_heal, int(round(float(ally.get("maxHP", 0)) * heal_ratio)))
			var prev_hp := int(ally.get("hp", 0))
			ally["hp"] = mini(int(ally.get("maxHP", prev_hp)), prev_hp + heal_amount)
			var actual_heal := int(ally.get("hp", 0)) - prev_hp
			last_ally = ally
			acted = true
			effect_logs.append({
				"kind": "heal",
				"target": ally.get("name", ""),
				"target_id": ally.get("id", ""),
				"amount": actual_heal
			})
		elif kind == "guard":
			var guard_ally := last_ally if not last_ally.is_empty() else _get_lowest_hp_ally()
			if guard_ally.is_empty():
				continue
			var reduction := clampf(float(effect.get("reduction", 0.25)), 0.0, 0.8)
			var turns := maxi(1, int(effect.get("turns", 1)))
			_apply_player_guard(guard_ally, reduction, turns)
			acted = true
			effect_logs.append({
				"kind": "guard",
				"target": guard_ally.get("name", ""),
				"target_id": guard_ally.get("id", ""),
				"reduction": reduction,
				"turns": turns
			})
		elif kind == "weaken":
			if target == null or target_idx < 0:
				continue
			var weaken_reduction := clampf(float(effect.get("reduction", 0.35)), 0.0, 0.8)
			var weaken_turns := maxi(1, int(effect.get("turns", 1)))
			_apply_enemy_tempo_mod(target_idx, weaken_reduction, weaken_turns)
			acted = true
			effect_logs.append({
				"kind": "weaken",
				"target": target.get("name", ""),
				"target_index": target_idx,
				"reduction": weaken_reduction,
				"turns": weaken_turns
			})

	if not acted:
		return { "success": false, "reason": "no_valid_effect" }

	skill_charges[monster_id] = maxi(0, charge - cost)
	if total_damage > 0:
		total_damage_dealt[monster_id] = total_damage_dealt.get(monster_id, 0) + total_damage

	var target_died: bool = target != null and target.get("hp", 0) <= 0
	var result := {
		"success": true,
		"type": "active_skill",
		"skill_type": skill_type,
		"skillType": skill_type,
		"attacker": monster.get("name", ""),
		"attacker_id": monster_id,
		"attackerId": monster_id,
		"attacker_emoji": monster.get("emoji", ""),
		"skill": skill.duplicate(true),
		"skill_name": skill.get("name", "技能"),
		"skillName": skill.get("name", "技能"),
		"target": target.get("name", "") if target != null else "",
		"target_emoji": target.get("emoji", "") if target != null else "",
		"target_index": target_idx,
		"targetIndex": target_idx,
		"damage": total_damage,
		"remaining_damage": remaining_damage,
		"remainingDamage": remaining_damage,
		"shield_absorbed": shield_absorbed,
		"shieldAbsorbed": shield_absorbed,
		"element": element,
		"boardAffinity": board_affinity,
		"is_effective": element_mult > 1.0,
		"isEffective": element_mult > 1.0,
		"is_weak": element_mult < 1.0,
		"isWeak": element_mult < 1.0,
		"target_died": target_died,
		"targetDied": target_died,
		"effect_logs": effect_logs,
		"effectLogs": effect_logs,
		"battle_ended": false,
		"battleEnded": false
	}
	damage_dealt.emit(result)

	if check_battle_end():
		result["battle_ended"] = true
		result["battleEnded"] = true

	return result


func _get_lowest_hp_ally() -> Dictionary:
	var best: Dictionary = {}
	var best_ratio := 999.0
	for ally in player_team:
		if ally == null or ally.get("hp", 0) <= 0:
			continue
		var max_hp := maxi(1, int(ally.get("maxHP", 1)))
		var ratio := float(ally.get("hp", 0)) / float(max_hp)
		if best.is_empty() or ratio < best_ratio:
			best = ally
			best_ratio = ratio
	return best


func _apply_player_guard(ally: Dictionary, reduction: float, turns: int) -> void:
	var ally_id := str(ally.get("id", ""))
	if ally_id.is_empty():
		return
	player_guards[ally_id] = {
		"reduction": clampf(reduction, 0.0, 0.8),
		"turns": maxi(1, turns)
	}


func _apply_guard_to_damage(target: Dictionary, damage: int) -> Dictionary:
	var target_id := str(target.get("id", ""))
	if target_id.is_empty() or not player_guards.has(target_id):
		return { "damage": damage, "guard_absorbed": 0 }
	var guard: Dictionary = player_guards[target_id]
	var reduction := clampf(float(guard.get("reduction", 0.0)), 0.0, 0.8)
	var guard_absorbed := int(round(float(damage) * reduction))
	var final_damage := maxi(1, damage - guard_absorbed)
	guard["turns"] = int(guard.get("turns", 1)) - 1
	if int(guard.get("turns", 0)) <= 0:
		player_guards.erase(target_id)
	else:
		player_guards[target_id] = guard
	return { "damage": final_damage, "guard_absorbed": guard_absorbed }


func _apply_enemy_tempo_mod(enemy_idx: int, reduction: float, turns: int) -> void:
	if enemy_idx < 0:
		return
	enemy_tempo_mods[enemy_idx] = {
		"reduction": clampf(reduction, 0.0, 0.8),
		"turns": maxi(1, turns)
	}


func _consume_enemy_tempo_multiplier(enemy_idx: int) -> Dictionary:
	if not enemy_tempo_mods.has(enemy_idx):
		return { "multiplier": 1.0, "reduction": 0.0 }
	var mod: Dictionary = enemy_tempo_mods[enemy_idx]
	var reduction := clampf(float(mod.get("reduction", 0.0)), 0.0, 0.8)
	mod["turns"] = int(mod.get("turns", 1)) - 1
	if int(mod.get("turns", 0)) <= 0:
		enemy_tempo_mods.erase(enemy_idx)
	else:
		enemy_tempo_mods[enemy_idx] = mod
	return { "multiplier": 1.0 - reduction, "reduction": reduction }


func _refresh_capture_windows() -> void:
	for idx in range(enemies.size()):
		_update_capture_window(idx)


func _is_enemy_suppressed(enemy_idx: int) -> bool:
	if enemy_tempo_mods.has(enemy_idx):
		return true
	var effects := _status_effect.get_effects_snapshot()
	if enemy_idx < 0 or enemy_idx >= effects.size():
		return false
	var effect = effects[enemy_idx]
	if effect == null or not effect is Dictionary:
		return false
	return ["burn", "freeze", "poison", "stun"].has(str(effect.get("type", "")))


func _update_capture_window(enemy_idx: int) -> void:
	if enemy_idx < 0 or enemy_idx >= enemies.size():
		return
	var enemy: Dictionary = enemies[enemy_idx]
	if enemy == null or enemy.is_empty() or not enemy.has("id"):
		return
	var window := CaptureSystem.calc_taming_window(
		float(enemy.get("hp", 0)),
		float(enemy.get("maxHP", 1)),
		{"suppressed": _is_enemy_suppressed(enemy_idx)}
	)
	window["enemy_index"] = enemy_idx
	window["enemy_id"] = str(enemy.get("id", ""))
	window["enemy_name"] = str(enemy.get("name", ""))
	capture_windows[enemy_idx] = window
	var best: Dictionary = capture_window_best.get(enemy_idx, {})
	if best.is_empty() or float(window.get("score", 0.0)) > float(best.get("score", 0.0)):
		capture_window_best[enemy_idx] = window.duplicate(true)


func get_best_capture_candidate() -> Dictionary:
	_refresh_capture_windows()
	var best_idx := -1
	var best_window: Dictionary = {}
	for idx in range(enemies.size()):
		var enemy: Dictionary = enemies[idx]
		if enemy == null or enemy.is_empty() or not enemy.has("id"):
			continue
		var window: Dictionary = capture_window_best.get(idx, capture_windows.get(idx, {}))
		if window.is_empty():
			continue
		if best_window.is_empty() or float(window.get("score", 0.0)) > float(best_window.get("score", 0.0)):
			best_window = window
			best_idx = idx
	if best_idx < 0:
		return {}
	return {
		"enemy": enemies[best_idx],
		"enemy_index": best_idx,
		"window": best_window
	}


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

		# 检查敌人是否有技能
		var has_skills = false
		if _enemy_skill_system != null:
			has_skills = _enemy_skill_system.has_skill_type(i, "charge") or _enemy_skill_system.has_skill_type(i, "shield") or _enemy_skill_system.has_skill_type(i, "heal")

		# 护盾检查（委托给 EnemySkillSystem）
		if _enemy_skill_system != null and has_skills:
			_enemy_skill_system.check_and_activate_shield(i, enemy)

		# 回血检查（委托给 EnemySkillSystem）
		if _enemy_skill_system != null and has_skills:
			_enemy_skill_system.execute_heal(i, enemy)

		# 蓄力检查（旧版 enemySkills.charge 链路；带该配置的 Boss 保持原行为）
		var skip_attack = false
		var damage_multiplier = 1.0
		var attack_mode := EnemyAttackModesScript.MODE_STRIKE
		var attack_mode_multiplier := 1.0
		var legacy_charge := _enemy_skill_system != null and _enemy_skill_system.has_skill_type(i, "charge")

		if legacy_charge:
			var was_charging := _enemy_skill_system.is_charging(i)
			damage_multiplier = _enemy_skill_system.check_and_release_charge(i)
			if _enemy_skill_system.is_charging(i):
				skip_attack = true
				attack_mode = EnemyAttackModesScript.MODE_CHARGE
			else:
				_enemy_skill_system.update_and_check_charge_start(i)
				if was_charging:
					attack_mode = EnemyAttackModesScript.MODE_CHARGE_RELEASE
		elif _attack_modes != null:
			# 新链路：模式完全由怪物/关卡数据决定，BattleManager 不再硬编码轮次。
			var mode: Dictionary = _attack_modes.consume_turn(i)
			attack_mode = str(mode.get("type", EnemyAttackModesScript.MODE_STRIKE))
			attack_mode_multiplier = float(mode.get("multiplier", 1.0))
			match attack_mode:
				EnemyAttackModesScript.MODE_CHARGE:
					skip_attack = true
				EnemyAttackModesScript.MODE_CHARGE_RELEASE:
					damage_multiplier = attack_mode_multiplier
				EnemyAttackModesScript.MODE_SWEEP:
					pass
				_:
					attack_mode = EnemyAttackModesScript.MODE_STRIKE

		if skip_attack:
			var shown_multiplier := attack_mode_multiplier
			if legacy_charge:
				shown_multiplier = _enemy_skill_system.get_charge_damage_multiplier(i)
			actions.append({
				"attacker": enemy.get("name", ""),
				"attacker_emoji": enemy.get("emoji", ""),
				"target": null,
				"target_emoji": null,
				"damage": 0,
				"element": enemy.get("element", ""),
				"target_died": false,
				"is_charging": true,
				"attack_mode": attack_mode,
				"charge_multiplier": shown_multiplier
			})
			continue

		# 冰冻ATK降低（委托给 BattleStatusEffect）
		var freeze_mult = _status_effect.get_freeze_atk_multiplier(i)
		var tempo_mod := _consume_enemy_tempo_multiplier(i)
		var tempo_mult := float(tempo_mod.get("multiplier", 1.0))

		if attack_mode == EnemyAttackModesScript.MODE_SWEEP:
			# 全体攻击：对每个存活伙伴分别走防御/协同/护盾结算，倍率约单体一半。
			for sweep_target in alive_team:
				var sweep_hit := _resolve_enemy_hit(enemy, sweep_target, attack_mode_multiplier, freeze_mult, tempo_mult)
				sweep_target["hp"] = sweep_target.get("hp", 0) - int(sweep_hit.get("damage", 0))
				actions.append({
					"attacker": enemy.get("name", ""),
					"attacker_emoji": enemy.get("emoji", ""),
					"target": sweep_target.get("name", ""),
					"target_emoji": sweep_target.get("emoji", ""),
					"target_index": player_team.find(sweep_target),
					"damage": int(sweep_hit.get("damage", 0)),
					"element": enemy.get("element", ""),
					"target_died": sweep_target.get("hp", 0) <= 0,
					"is_charged": false,
					"charge_multiplier": 1.0,
					"is_aoe": true,
					"attack_mode": EnemyAttackModesScript.MODE_SWEEP,
					"sweep_multiplier": attack_mode_multiplier,
					"is_weakened": tempo_mult < 1.0,
					"weaken_reduction": tempo_mod.get("reduction", 0.0),
					"guard_absorbed": int(sweep_hit.get("guard_absorbed", 0))
				})
			_refresh_capture_windows()
			continue

		# 普通攻击 / 蓄力释放：单体目标
		var target = alive_team[randi() % alive_team.size()]
		var hit := _resolve_enemy_hit(enemy, target, damage_multiplier, freeze_mult, tempo_mult)
		var damage := int(hit.get("damage", 0))
		var guard_absorbed := int(hit.get("guard_absorbed", 0))

		target["hp"] = target.get("hp", 0) - damage
		_refresh_capture_windows()

		actions.append({
			"attacker": enemy.get("name", ""),
			"attacker_emoji": enemy.get("emoji", ""),
			"target": target.get("name", ""),
			"target_emoji": target.get("emoji", ""),
			"target_index": player_team.find(target),
			"damage": damage,
			"element": enemy.get("element", ""),
			"target_died": target.get("hp", 0) <= 0,
			"is_charged": damage_multiplier > 1.0,
			"charge_multiplier": damage_multiplier,
			"attack_mode": attack_mode,
			"is_weakened": tempo_mult < 1.0,
			"weaken_reduction": tempo_mod.get("reduction", 0.0),
			"guard_absorbed": guard_absorbed
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

	# 敌方回合结束后检查 — 玩家可能通过 DoT / 反射 / 吸血等在攻击链中全灭
	if not battle_over:
		check_battle_end()

	return { "actions": actions, "status_logs": status_logs, "dot_kills": dot_kills }


## 单个目标的敌方伤害结算：防御、属性协同、冰冻/束缚、护盾/守护都在这里统一处理。
func _resolve_enemy_hit(enemy: Dictionary, target: Dictionary, multiplier: float, freeze_mult: float, tempo_mult: float) -> Dictionary:
	var leader_def_boost = LeaderSkillDb.get_leader_def_boost(leader_skill_data)
	var target_affinity := _board_affinity(target)
	var synergy_def_mult = get_synergy_def_mult(target_affinity)
	var damage = _damage_calc.calc_enemy_damage(
		enemy.get("atk", 10),
		enemy.get("element", ""),
		target.get("def", 0),
		target.get("element", ""),
		freeze_mult * tempo_mult,
		leader_def_boost,
		synergy_def_mult
	)
	damage = int(float(damage) * multiplier)
	var guard_result := _apply_guard_to_damage(target, damage)
	return {
		"damage": int(guard_result.get("damage", damage)),
		"guard_absorbed": int(guard_result.get("guard_absorbed", 0))
	}


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
		# 还有后续波次：不结算胜利，交给界面播放波次切换
		if has_next_wave():
			wave_transition_pending = true
			return false
		battle_over = true
		battle_result = "win"
		battle_ended.emit("win")
		return true
	return false


# ========== 辅助函数 ==========

func get_enemies() -> Array:
	return enemies


## 只对 Boss 应用关卡曲线倍率，避免影响普通敌人与捕捉后的 Boss 基础数据。
## bossCurve 支持 hp / atk / def / charge / shield / heal 六项倍率。
func _apply_boss_tuning(list: Array) -> void:
	if boss_curve.is_empty():
		return
	var hp_mult := float(boss_curve.get("hp", 1.0))
	var atk_mult := float(boss_curve.get("atk", 1.0))
	var def_mult := float(boss_curve.get("def", 1.0))
	var charge_mult := float(boss_curve.get("charge", 1.0))
	var shield_mult := float(boss_curve.get("shield", 1.0))
	var heal_mult := float(boss_curve.get("heal", 1.0))
	if is_equal_approx(hp_mult, 1.0) and is_equal_approx(atk_mult, 1.0) and is_equal_approx(def_mult, 1.0) \
			and is_equal_approx(charge_mult, 1.0) and is_equal_approx(shield_mult, 1.0) and is_equal_approx(heal_mult, 1.0):
		return
	for enemy in list:
		if enemy == null or not enemy is Dictionary or (enemy as Dictionary).is_empty():
			continue
		if not bool((enemy as Dictionary).get("isBoss", false)):
			continue
		if not is_equal_approx(hp_mult, 1.0):
			enemy["maxHP"] = maxi(1, int(enemy.get("maxHP", 0) * hp_mult))
			enemy["hp"] = enemy["maxHP"]
		if not is_equal_approx(atk_mult, 1.0):
			enemy["atk"] = maxi(1, int(enemy.get("atk", 0) * atk_mult))
		if not is_equal_approx(def_mult, 1.0):
			enemy["def"] = maxi(0, int(enemy.get("def", 0) * def_mult))
		var skills: Variant = enemy.get("enemySkills", null)
		if skills is Array:
			for skill in skills:
				if not skill is Dictionary:
					continue
				match str(skill.get("type", "")):
					"charge":
						if not is_equal_approx(charge_mult, 1.0):
							skill["damageMultiplier"] = float(skill.get("damageMultiplier", 1.0)) * charge_mult
					"shield":
						if not is_equal_approx(shield_mult, 1.0):
							skill["hp"] = maxi(1, int(int(skill.get("hp", 1)) * shield_mult))
					"heal":
						if not is_equal_approx(heal_mult, 1.0):
							skill["percent"] = clampf(float(skill.get("percent", 0.1)) * heal_mult, 0.0, 1.0)


func execute_phase_transition(phase_config: Dictionary) -> Array:
	var new_enemies: Array = _phase_handler.execute_phase_transition(phase_config, enemy_level)
	if new_enemies.is_empty():
		return []

	_apply_boss_tuning(new_enemies)
	enemies = new_enemies
	current_phase = _phase_handler.get_current_phase()
	enemy_tempo_mods = {}
	capture_windows = {}
	capture_window_best = {}
	_status_effect.init_effects(enemies.size())
	_refresh_capture_windows()
	if _enemy_skill_system == null:
		_enemy_skill_system = EnemySkillSystem.new()
	_enemy_skill_system.init_skill_state(enemies)
	_attack_modes.init(enemies, stage_data)
	_connect_enemy_skill_signals()
	phase_transition.emit(current_phase, enemies)
	return enemies


func _build_enemy_skill_states_dict() -> Dictionary:
	var result = {}
	if _enemy_skill_system == null:
		return result
	for idx in range(enemies.size()):
		result[idx] = _enemy_skill_system.get_enemy_state(idx)
	return result

func get_enemy_intents() -> Dictionary:
	return EnemyIntentRulesScript.build_enemy_intents(
		enemies,
		_build_enemy_skill_states_dict(),
		_status_effect.get_effects_snapshot(),
		_build_attack_mode_previews()
	)

## 数据化出手模式的预览：只返回会改变意图文案的模式（蓄力/全体）。
## 普通 strike 继续交给 EnemyIntentRules 的既有逻辑，保持 Boss 蓄力文本不变。
func _build_attack_mode_previews() -> Dictionary:
	var previews: Dictionary = {}
	if _attack_modes == null:
		return previews
	for i in range(enemies.size()):
		var enemy = enemies[i]
		if enemy == null or not enemy is Dictionary or int(enemy.get("hp", 0)) <= 0:
			continue
		# 带旧版 enemySkills.charge 的敌人继续走既有蓄力链路，避免双重蓄力。
		if _enemy_skill_system != null and _enemy_skill_system.has_skill_type(i, "charge"):
			continue
		var mode: Dictionary = _attack_modes.peek(i)
		var mode_type := str(mode.get("type", EnemyAttackModesScript.MODE_STRIKE))
		if mode_type != EnemyAttackModesScript.MODE_STRIKE:
			previews[i] = mode
	return previews

## 本回合会出手的敌人索引（供战斗界面做出手前摇预警）。
## 存活敌人都会在敌方回合行动；蓄力中的敌人会在本回合释放蓄力并攻击。
func get_upcoming_attackers() -> Array:
	var attackers: Array = []
	if battle_over:
		return attackers
	for i in range(enemies.size()):
		var enemy = enemies[i]
		if enemy == null or not enemy is Dictionary:
			continue
		if int(enemy.get("hp", 0)) <= 0:
			continue
		attackers.append(i)
	return attackers

## 前摇视觉数据：{ enemy_idx: { mode, style, label, multiplier } }。
## 普通出招为红色箭头；蓄力/蓄力释放为紫色闪电；全体攻击为青色扇形。
func get_enemy_windup_cues() -> Dictionary:
	var cues: Dictionary = {}
	if battle_over:
		return cues
	for i in range(enemies.size()):
		var enemy = enemies[i]
		if enemy == null or not enemy is Dictionary or int(enemy.get("hp", 0)) <= 0:
			continue
		var mode_type := EnemyAttackModesScript.MODE_STRIKE
		var multiplier := 1.0
		if _enemy_skill_system != null and _enemy_skill_system.has_skill_type(i, "charge"):
			if _enemy_skill_system.is_charging(i):
				mode_type = EnemyAttackModesScript.MODE_CHARGE_RELEASE
				multiplier = _enemy_skill_system.get_charge_damage_multiplier(i)
		elif _attack_modes != null:
			var mode: Dictionary = _attack_modes.peek(i)
			mode_type = str(mode.get("type", EnemyAttackModesScript.MODE_STRIKE))
			multiplier = float(mode.get("multiplier", 1.0))
		cues[i] = {
			"mode": mode_type,
			"style": EnemyAttackModesScript.windup_style(mode_type),
			"label": EnemyAttackModesScript.mode_label(mode_type),
			"multiplier": multiplier
		}
	return cues


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
		"wave_index": wave_index,
		"wave_total": wave_total,
		"wave_pending": has_next_wave(),
		"enemy_skill_states": _build_enemy_skill_states_dict(),
		"enemy_intents": get_enemy_intents(),
		"enemy_attack_modes": _build_attack_mode_previews(),
		"leader_skill_info": leader_skill_info,
		"synergy_info": synergy_info,
		"synergy_bonuses": synergy_bonuses.duplicate(true) if synergy_bonuses != null else null,
		"player_guards": player_guards.duplicate(true),
		"enemy_tempo_mods": enemy_tempo_mods.duplicate(true),
		"capture_windows": capture_windows.duplicate(true),
		"capture_window_best": capture_window_best.duplicate(true),
		"best_capture_window": get_best_capture_candidate().get("window", {}),
		"status_effects": _status_effect.get_effects_snapshot(),
		"status_effect_log": _status_effect.get_effect_log()
	}


# ========== EnemySkillSystem 信号连接 ==========

func _connect_enemy_skill_signals() -> void:
	if _enemy_skill_system == null:
		return
	# 蓄力开始信号
	if not _enemy_skill_system.skill_charge_start.is_connected(_on_enemy_skill_charge_start):
		_enemy_skill_system.skill_charge_start.connect(_on_enemy_skill_charge_start)
	# 蓄力释放信号
	if not _enemy_skill_system.skill_charge_release.is_connected(_on_enemy_skill_charge_release):
		_enemy_skill_system.skill_charge_release.connect(_on_enemy_skill_charge_release)
	# 护盾出现信号
	if not _enemy_skill_system.skill_shield_appear.is_connected(_on_enemy_skill_shield_appear):
		_enemy_skill_system.skill_shield_appear.connect(_on_enemy_skill_shield_appear)
	# 护盾破碎信号
	if not _enemy_skill_system.skill_shield_broken.is_connected(_on_enemy_skill_shield_broken):
		_enemy_skill_system.skill_shield_broken.connect(_on_enemy_skill_shield_broken)
	# 治疗触发信号
	if not _enemy_skill_system.skill_heal_triggered.is_connected(_on_enemy_skill_heal_triggered):
		_enemy_skill_system.skill_heal_triggered.connect(_on_enemy_skill_heal_triggered)
	# 强化护盾出现/破碎/反弹信号
	if not _enemy_skill_system.skill_shield_plus_appear.is_connected(_on_enemy_skill_shield_plus_appear):
		_enemy_skill_system.skill_shield_plus_appear.connect(_on_enemy_skill_shield_plus_appear)
	if not _enemy_skill_system.skill_shield_plus_broken.is_connected(_on_enemy_skill_shield_plus_broken):
		_enemy_skill_system.skill_shield_plus_broken.connect(_on_enemy_skill_shield_plus_broken)
	if not _enemy_skill_system.skill_shield_plus_reflect.is_connected(_on_enemy_skill_shield_plus_reflect):
		_enemy_skill_system.skill_shield_plus_reflect.connect(_on_enemy_skill_shield_plus_reflect)
	# 灼烧/反弹/冰封/中毒信号
	if not _enemy_skill_system.skill_burn_apply.is_connected(_on_enemy_skill_burn_apply):
		_enemy_skill_system.skill_burn_apply.connect(_on_enemy_skill_burn_apply)
	if not _enemy_skill_system.skill_reflect_activate.is_connected(_on_enemy_skill_reflect_activate):
		_enemy_skill_system.skill_reflect_activate.connect(_on_enemy_skill_reflect_activate)
	if not _enemy_skill_system.skill_freeze_activate.is_connected(_on_enemy_skill_freeze_activate):
		_enemy_skill_system.skill_freeze_activate.connect(_on_enemy_skill_freeze_activate)
	if not _enemy_skill_system.skill_poison_apply.is_connected(_on_enemy_skill_poison_apply):
		_enemy_skill_system.skill_poison_apply.connect(_on_enemy_skill_poison_apply)
	# 雷击/灵魂吸取/浪涌/混乱/技能封印信号
	if not _enemy_skill_system.skill_thunder_strike_triggered.is_connected(_on_enemy_skill_thunder_strike):
		_enemy_skill_system.skill_thunder_strike_triggered.connect(_on_enemy_skill_thunder_strike)
	if not _enemy_skill_system.skill_life_drain_triggered.is_connected(_on_enemy_skill_life_drain):
		_enemy_skill_system.skill_life_drain_triggered.connect(_on_enemy_skill_life_drain)
	if not _enemy_skill_system.skill_confuse_activate.is_connected(_on_enemy_skill_confuse):
		_enemy_skill_system.skill_confuse_activate.connect(_on_enemy_skill_confuse)
	if not _enemy_skill_system.skill_skill_seal_activate.is_connected(_on_enemy_skill_skill_seal):
		_enemy_skill_system.skill_skill_seal_activate.connect(_on_enemy_skill_skill_seal)


func _on_enemy_skill_charge_start(enemy_idx: int, damage_multiplier: float) -> void:
	enemy_skill_action.emit({
		"type": "charge_start",
		"enemy_index": enemy_idx,
		"damage_multiplier": damage_multiplier
	})


func _on_enemy_skill_charge_release(enemy_idx: int, damage_multiplier: float) -> void:
	enemy_skill_action.emit({
		"type": "charge_release",
		"enemy_index": enemy_idx,
		"damage_multiplier": damage_multiplier
	})


func _on_enemy_skill_shield_appear(enemy_idx: int, shield_hp: int) -> void:
	var enemy = enemies[enemy_idx] if enemy_idx < enemies.size() else {}
	enemy_skill_action.emit({
		"type": "shield_appear",
		"enemy_index": enemy_idx,
		"enemy": enemy,
		"shield_hp": shield_hp,
		"shield_max_hp": shield_hp
	})


func _on_enemy_skill_shield_broken(enemy_idx: int) -> void:
	enemy_skill_action.emit({
		"type": "shield_broken",
		"enemy_index": enemy_idx
	})


func _on_enemy_skill_heal_triggered(enemy_idx: int, heal_amount: int) -> void:
	var enemy = enemies[enemy_idx] if enemy_idx < enemies.size() else {}
	enemy_skill_action.emit({
		"type": "heal",
		"enemy_index": enemy_idx,
		"enemy": enemy,
		"heal_amount": heal_amount
	})


func _on_enemy_skill_shield_plus_appear(enemy_idx: int, shield_hp: int, reflect_percent: float) -> void:
	var enemy = enemies[enemy_idx] if enemy_idx < enemies.size() else {}
	enemy_skill_action.emit({
		"type": "shield_plus_appear",
		"enemy_index": enemy_idx,
		"enemy": enemy,
		"shield_hp": shield_hp,
		"shield_max_hp": shield_hp,
		"reflect_percent": reflect_percent
	})


func _on_enemy_skill_shield_plus_broken(enemy_idx: int) -> void:
	enemy_skill_action.emit({
		"type": "shield_plus_broken",
		"enemy_index": enemy_idx
	})


func _on_enemy_skill_shield_plus_reflect(enemy_idx: int, target_idx: int, reflected_damage: int) -> void:
	enemy_skill_action.emit({
		"type": "shield_plus_reflect",
		"enemy_index": enemy_idx,
		"target_index": target_idx,
		"reflected_damage": reflected_damage
	})


func _on_enemy_skill_burn_apply(enemy_idx: int, target_idx: int, damage: int, duration: int) -> void:
	enemy_skill_action.emit({
		"type": "burn_apply",
		"enemy_index": enemy_idx,
		"target_index": target_idx,
		"damage": damage,
		"duration": duration
	})


func _on_enemy_skill_reflect_activate(enemy_idx: int, percent: float, duration: int) -> void:
	enemy_skill_action.emit({
		"type": "reflect_activate",
		"enemy_index": enemy_idx,
		"percent": percent,
		"duration": duration
	})


func _on_enemy_skill_freeze_activate(enemy_idx: int, target_idx: int, chance: float, duration: int) -> void:
	enemy_skill_action.emit({
		"type": "freeze_activate",
		"enemy_index": enemy_idx,
		"target_index": target_idx,
		"chance": chance,
		"duration": duration
	})


func _on_enemy_skill_poison_apply(enemy_idx: int, target_idx: int, stacks: int, damage_per_stack: int, max_stacks: int) -> void:
	enemy_skill_action.emit({
		"type": "poison_apply",
		"enemy_index": enemy_idx,
		"target_index": target_idx,
		"stacks": stacks,
		"damage_per_stack": damage_per_stack,
		"max_stacks": max_stacks
	})


func _on_enemy_skill_thunder_strike(enemy_idx: int, damage: int) -> void:
	var enemy = enemies[enemy_idx] if enemy_idx < enemies.size() else {}
	enemy_skill_action.emit({
		"type": "thunder_strike",
		"enemy_index": enemy_idx,
		"enemy": enemy,
		"damage": damage
	})


func _on_enemy_skill_life_drain(enemy_idx: int, target_idx: int, drain_amount: int, heal_amount: int) -> void:
	var enemy = enemies[enemy_idx] if enemy_idx < enemies.size() else {}
	enemy_skill_action.emit({
		"type": "life_drain",
		"enemy_index": enemy_idx,
		"enemy": enemy,
		"target_index": target_idx,
		"drain_amount": drain_amount,
		"heal_amount": heal_amount
	})


func _on_enemy_skill_confuse(enemy_idx: int, target_idx: int, chance: float, duration: int) -> void:
	enemy_skill_action.emit({
		"type": "confuse_activate",
		"enemy_index": enemy_idx,
		"target_index": target_idx,
		"chance": chance,
		"duration": duration
	})


func _on_enemy_skill_skill_seal(enemy_idx: int, target_idx: int, chance: float, duration: int) -> void:
	enemy_skill_action.emit({
		"type": "skill_seal_activate",
		"enemy_index": enemy_idx,
		"target_index": target_idx,
		"chance": chance,
		"duration": duration
	})


# ========== 获取战斗结果（用于结算） ==========

func get_battle_result() -> Dictionary:
	var result_enemies: Array = enemies
	if not _wave_enemy_history.is_empty():
		result_enemies = []
		for wave_enemies: Array in _wave_enemy_history:
			result_enemies.append_array(wave_enemies)
	return {
		"result": battle_result,
		"turn_count": turn_count,
		"max_turns": max_turns,
		"player_team": player_team.map(func(m): return m.duplicate(true) if m != null else null),
		"enemies": result_enemies.map(func(e): return e.duplicate(true) if e != null else null),
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
		"capture_windows": capture_windows.duplicate(true),
		"capture_window_best": capture_window_best.duplicate(true),
		"best_capture_window": get_best_capture_candidate().get("window", {}),
		"stageRewards": stage_data.get("rewards", null) if stage_data != null else null,
		"stage_rewards": stage_data.get("rewards", null) if stage_data != null else null
	}
