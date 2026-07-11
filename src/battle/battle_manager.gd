# ============================================
# battle/battle_manager.gd - 战斗管理器核心
# 翻译自 js/battle/battleManager.js
# ============================================
class_name BattleManager
extends Node

const EnemyIntentRulesScript = preload("res://src/battle/enemy_intent_rules.gd")
const BattleObjectiveEvaluatorScript = preload("res://src/battle/battle_objective_evaluator.gd")
const LeaderSkillExecutorScript = preload("res://src/battle/leader_skill_executor.gd")

## 战斗核心逻辑：玩家队伍/敌方精灵初始化、连锁伤害计算、
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
var enemies: Array = []            # 敌方精灵 [{...stats}]
var turn: int = 0
var combo: int = 0                # 当前连锁数
var total_damage_dealt: Dictionary = {}  # 按属性统计伤害
var skill_charges: Dictionary = {}       # 技能充能 { instanceId/monsterId: charge }
var leader_charge_points: Dictionary = {}
var battle_over: bool = false
var battle_result: String = ""     # 'win' | 'lose'
var battle_id: String = ""
var turn_count: int = 0
var max_turns: int = 20
var battle_mode: String = "main"
var tower_buffs: Array = []
var current_player_turn_damage: int = 0
var highest_player_turn_damage: int = 0

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
var player_absorb_shields: Dictionary = {}      # { monsterId: { turns: int } }
var enemy_tempo_mods: Dictionary = {}   # { enemyIndex: { reduction, turns } }
var _next_enemy_attack_index: int = 0
var capture_windows: Dictionary = {}    # { enemyIndex: current tamingWindow }
var capture_window_best: Dictionary = {} # { enemyIndex: best tamingWindow reached this battle }

# 组件委托（由外部抽取后内联持有）
var _status_effect: BattleStatusEffect = BattleStatusEffect.new()
var _phase_handler: PhaseHandler = PhaseHandler.new(self)
var _damage_calc: DamageCalculator = DamageCalculator.new()
var _objective_evaluator = BattleObjectiveEvaluatorScript.new()
var _leader_skill_executor = LeaderSkillExecutorScript.new(self)

# 关卡数据
var stage_data: Variant = null
var stage_id: String = ""

# 等级
var player_level: int = 1
var enemy_level: int = 1

const DEFAULT_RANDOM_ELITE_CHANCE: float = 0.08
const LEADER_CHARGE_MAX: int = 5

# ========== 单例模式 ==========
static var instance: BattleManager

func _enter_tree() -> void:
	instance = self

func _exit_tree() -> void:
	instance = null

# ========== 初始化 ==========
func init(player_monster_ids: Array, enemy_monster_ids: Array, p_level: int = 1, e_level: int = 1, s_data: Variant = null, s_id: String = "") -> void:
	# 玩家ID列表入口：用 StatCalculator + 现有 nature 查表（兼容没传 nature 的旧路径）
	var player_units: Array = player_monster_ids.map(func(id):
		# 如果调用方后续传过来的 player_team_stats 已带 nature，这里会保留 nature
		return StatCalculator.calc(id, p_level)
	)
	init_with_player_team(player_units, enemy_monster_ids, p_level, e_level, s_data, s_id)

func init_with_player_team(player_team_stats: Array, enemy_monster_ids: Array, p_level: int = 1, e_level: int = 1, s_data: Variant = null, s_id: String = "") -> void:
	battle_id = _generate_battle_id()
	player_team = []
	for unit in player_team_stats:
		if unit is Dictionary and not (unit as Dictionary).is_empty():
			player_team.append((unit as Dictionary).duplicate(true))

	stage_data = s_data
	stage_id = s_id
	battle_mode = str(s_data.get("mode", "main")) if s_data is Dictionary else "main"
	tower_buffs = (s_data.get("towerBuffs", []) as Array).duplicate(true) if s_data is Dictionary else []

	stage_phases = []
	current_phase = 1
	phase_transition_triggered = {}

	if s_data != null and s_data.has("phases") and s_data.get("phases", []).size() > 0:
		stage_phases = s_data.get("phases")
		_phase_handler.set_phase_configs(stage_phases)
		var phase1: Dictionary = stage_phases[0] if stage_phases.size() > 0 else {}
		if not phase1.is_empty():
			var hp_mult: float = phase1.get("hpMultiplier", 1.0)
			var elite_chance: float = _random_elite_chance(stage_data, phase1)
			enemies = phase1.get("enemies", []).map(func(id):
				return _build_enemy_unit(str(id), e_level, hp_mult, elite_chance)
			)
	else:
		var elite_chance: float = _random_elite_chance(stage_data)
		enemies = enemy_monster_ids.map(func(id):
			return _build_enemy_unit(str(id), e_level, 1.0, elite_chance)
		)

	turn = 0
	combo = 0
	total_damage_dealt = {}
	battle_over = false
	battle_result = ""
	turn_count = 0
	max_turns = _stage_max_turns(s_data)
	current_player_turn_damage = 0
	highest_player_turn_damage = 0
	skill_charges = {}
	leader_charge_points = {}

	player_level = p_level
	enemy_level = e_level

	for m in player_team:
		if m != null:
			skill_charges[m.get("id", "")] = 0
			leader_charge_points[m.get("id", "")] = 0

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
			var hp_mult_ls := LeaderSkillDb.get_leader_hp_boost(skill_data)
			if hp_mult_ls != 1.0:
				for m in player_team:
					if m != null:
						m["maxHP"] = int(m.get("maxHP", 0) * hp_mult_ls)
						m["hp"] = m["maxHP"]
			var combo_start := LeaderSkillDb.get_leader_combo_start(skill_data)
			if combo_start > 0:
				combo = combo_start

	synergy_bonuses = null
	synergy_info = []
	player_guards = {}
	player_absorb_shields = {}
	enemy_tempo_mods = {}
	_next_enemy_attack_index = 0
	capture_windows = {}
	capture_window_best = {}
	_calc_and_apply_element_synergy()

	_status_effect.init_effects(enemies.size())
	_refresh_capture_windows()

	# 敌人技能系统初始化（委托给 EnemySkillSystem）
	if _enemy_skill_system == null:
		_enemy_skill_system = EnemySkillSystem.new()
	_enemy_skill_system.init_skill_state(enemies)

	# 连接 EnemySkillSystem 的特定信号到 BattleManager
	_connect_enemy_skill_signals()


func is_tower_mode() -> bool:
	return battle_mode == "tower"


func begin_player_turn() -> void:
	current_player_turn_damage = 0


func get_tower_continuation() -> Dictionary:
	return {
		"party_snapshot": player_team.map(func(m): return m.duplicate(true) if m != null else null),
		"skill_charges": skill_charges.duplicate(true),
		"leader_charge_points": leader_charge_points.duplicate(true),
		"player_guards": player_guards.duplicate(true),
		"player_absorb_shields": player_absorb_shields.duplicate(true),
		"highest_turn_damage": highest_player_turn_damage,
	}


func restore_tower_continuation(continuation: Dictionary) -> void:
	var saved_party: Array = continuation.get("party_snapshot", [])
	for saved in saved_party:
		if not saved is Dictionary:
			continue
		var saved_unit: Dictionary = saved
		var unit_id := str(saved_unit.get("id", ""))
		var player_idx := _player_index_by_id(unit_id)
		if player_idx < 0 or player_idx >= player_team.size() or player_team[player_idx] == null:
			continue
		var unit: Dictionary = player_team[player_idx]
		unit["hp"] = clampi(int(saved_unit.get("hp", unit.get("hp", 0))), 0, int(unit.get("maxHP", 0)))
		player_team[player_idx] = unit
	skill_charges = (continuation.get("skill_charges", {}) as Dictionary).duplicate(true)
	leader_charge_points = (continuation.get("leader_charge_points", {}) as Dictionary).duplicate(true)
	player_guards = (continuation.get("player_guards", {}) as Dictionary).duplicate(true)
	player_absorb_shields = (continuation.get("player_absorb_shields", {}) as Dictionary).duplicate(true)
	highest_player_turn_damage = maxi(highest_player_turn_damage, int(continuation.get("highest_turn_damage", 0)))


func begin_tower_wave(next_stage: Dictionary) -> void:
	if not is_tower_mode():
		return
	stage_data = next_stage.duplicate(true)
	stage_id = str(stage_data.get("id", stage_id))
	enemy_level = int(stage_data.get("enemyLevel", enemy_level))
	tower_buffs = (stage_data.get("towerBuffs", tower_buffs) as Array).duplicate(true)
	stage_phases = []
	current_phase = 1
	phase_transition_triggered = {}
	var enemy_ids: Array = stage_data.get("enemies", [])
	enemies = enemy_ids.map(func(enemy_id):
		return _build_enemy_unit(str(enemy_id), enemy_level, 1.0, 0.0)
	)
	max_turns = _stage_max_turns(stage_data)
	turn_count = 0
	combo = 0
	current_player_turn_damage = 0
	battle_over = false
	battle_result = ""
	_next_enemy_attack_index = 0
	capture_windows = {}
	capture_window_best = {}
	_status_effect.init_effects(enemies.size())
	if _enemy_skill_system == null:
		_enemy_skill_system = EnemySkillSystem.new()
	_enemy_skill_system.init_skill_state(enemies)
	_refresh_capture_windows()
	_connect_enemy_skill_signals()


func _generate_battle_id() -> String:
	var random_suffix := Crypto.new().generate_random_bytes(16).hex_encode()
	return "%d-%s" % [int(Time.get_unix_time_from_system()), random_suffix]


func _build_enemy_unit(enemy_id: String, level: int, hp_mult: float = 1.0, random_elite_chance: float = 0.0) -> Dictionary:
	var is_elite := _should_spawn_elite(enemy_id, random_elite_chance)
	var tier := StatCalculator.EnemyTier.ELITE if is_elite else StatCalculator.EnemyTier.NORMAL
	var monster := StatCalculator.calc_enemy(enemy_id, level, tier)
	if monster.is_empty():
		return monster
	if hp_mult != 1.0:
		monster["maxHP"] = int(monster.get("maxHP", 0) * hp_mult)
		monster["hp"] = monster["maxHP"]
		monster["atk"] = int(monster.get("atk", 0) * hp_mult)
	if bool(monster.get("isElite", false)):
		monster["isElite"] = true
		monster["_visualScale"] = StatCalculator.visual_scale_for_stats(monster)
	if is_tower_mode():
		monster["_towerVisualScale"] = 1.30
		monster["_visualScale"] = float(monster.get("_visualScale", 1.0)) * float(monster.get("_towerVisualScale", 1.0))
	if is_elite:
		monster["_eliteSource"] = "random"
	return monster


func _should_spawn_elite(enemy_id: String, random_elite_chance: float) -> bool:
	var data: Dictionary = MonsterDb.MONSTER_DB.get(enemy_id, {})
	if data.is_empty():
		return false
	if bool(data.get("isBoss", false)):
		return false
	return randf() < clampf(random_elite_chance, 0.0, 1.0)


func _random_elite_chance(stage: Variant, phase: Dictionary = {}) -> float:
	if stage == null or not (stage is Dictionary):
		return 0.0
	var stage_dict: Dictionary = stage
	if bool(stage_dict.get("disableRandomElite", false)) or bool(phase.get("disableRandomElite", false)):
		return 0.0
	if phase.has("randomEliteChance"):
		return clampf(float(phase.get("randomEliteChance", 0.0)), 0.0, 1.0)
	if phase.has("eliteChance"):
		return clampf(float(phase.get("eliteChance", 0.0)), 0.0, 1.0)
	if stage_dict.has("randomEliteChance"):
		return clampf(float(stage_dict.get("randomEliteChance", 0.0)), 0.0, 1.0)
	if stage_dict.has("eliteChance"):
		return clampf(float(stage_dict.get("eliteChance", 0.0)), 0.0, 1.0)
	return DEFAULT_RANDOM_ELITE_CHANCE


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
	var leader_charge_events: Array = []

	for monster in player_team:
		if monster == null or monster.get("hp", 0) <= 0:
			continue

		var board_affinity := _board_affinity(monster)
		var element := _fantasy_element(monster)
		var gem_count = gem_counts.get(board_affinity, 0)
		if gem_count == 0:
			continue
		_add_leader_charge(monster, 1, leader_charge_events)

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
		total_damage = _apply_tower_player_damage(total_damage)

		var mon_id = monster.get("id", "")
		var skill_cost: int = int(monster.get("skill", {}).get("cost", 999))
		var prev_charge: int = int(skill_charges.get(mon_id, 0))
		var next_charge: int = mini(prev_charge + gem_count + _tower_bonus_charge_per_match(), skill_cost)
		skill_charges[mon_id] = next_charge
		if prev_charge < skill_cost and next_charge >= skill_cost:
			skill_ready.emit(monster)

		var target_idx = enemies.find(target)

		# 护盾减伤（委托给 EnemySkillSystem）
		var shield_result: Dictionary = _enemy_skill_system.execute_shield_before_damage(target_idx, total_damage)
		var shield_absorbed := int(shield_result.get("absorbed", 0))
		var hp_damage := int(shield_result.get("remaining", total_damage))
		target["hp"] = target.get("hp", 0) - hp_damage
		_update_capture_window(target_idx)

		total_damage_dealt[mon_id] = total_damage_dealt.get(mon_id, 0) + hp_damage
		_record_player_turn_damage(hp_damage)

		var attacker_idx := _player_index_by_id(mon_id)
		damage_log.append({
			"attacker": monster.get("name", ""),
			"attacker_id": mon_id,
			"attackerId": mon_id,
			"attacker_index": attacker_idx,
			"attackerIndex": attacker_idx,
			"attacker_emoji": monster.get("emoji", ""),
			"target": target.get("name", ""),
			"target_index": target_idx,
			"targetIndex": target_idx,
			"target_emoji": target.get("emoji", ""),
			"damage": hp_damage,
			"raw_damage": total_damage,
			"rawDamage": total_damage,
			"shield_absorbed": shield_absorbed,
			"shieldAbsorbed": shield_absorbed,
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
		return {
			"damage_log": damage_log,
			"leader_charge_events": leader_charge_events,
			"leader_skill_pending": is_leader_burst_ready(),
			"phase_transition": phase_to_trigger
		}

	# 状态效果（委托给 BattleStatusEffect）
	_status_effect.try_apply_status_effects(gem_counts, player_team, enemies)
	_refresh_capture_windows()

	return {
		"damage_log": damage_log,
		"leader_charge_events": leader_charge_events,
		"leader_skill_pending": is_leader_burst_ready(),
		"status_effect_log": _status_effect.get_effect_log()
	}


func consume_ready_leader_burst() -> Dictionary:
	if not _all_leader_charges_ready() or _get_weakest_enemy() == null:
		return {}
	var leader_skill_log := _execute_leader_burst()
	if leader_skill_log.is_empty():
		return {}
	_reset_leader_charges()
	var result := {
		"leader_skill_log": leader_skill_log
	}
	var phase_to_trigger = _phase_handler.check_phase_transition()
	if not phase_to_trigger.is_empty():
		result["phase_transition"] = phase_to_trigger
	_refresh_capture_windows()
	return result


func use_active_skill(monster_id: String) -> Dictionary:
	if battle_over:
		return { "success": false, "reason": "battle_over" }

	var monster: Dictionary = _get_player_monster(monster_id)
	if monster.is_empty():
		return { "success": false, "reason": "monster_unavailable" }
	if monster.get("hp", 0) <= 0:
		return { "success": false, "reason": "dead" }

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
			effect_damage = _apply_tower_player_damage(effect_damage)
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
	if remaining_damage > 0:
		total_damage_dealt[monster_id] = total_damage_dealt.get(monster_id, 0) + remaining_damage
		_record_player_turn_damage(remaining_damage)

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


func is_leader_burst_ready() -> bool:
	return _all_leader_charges_ready() and _get_weakest_enemy() != null


func get_ready_leader_burst_preview() -> Dictionary:
	if not is_leader_burst_ready():
		return {}
	var leader_idx := _active_leader_index()
	if leader_idx < 0:
		return {}
	var leader: Dictionary = player_team[leader_idx]
	var skill_data := _leader_skill_data_for(leader)
	if skill_data.is_empty():
		return {}
	var element := str(_fantasy_element(leader))
	return {
		"leader_index": leader_idx,
		"leader": str(leader.get("name", "")),
		"leader_id": str(leader.get("id", "")),
		"skill_id": str(skill_data.get("id", "")),
		"skill_name": str(skill_data.get("name", "")),
		"element": element,
		"visual": skill_data.get("visual", {}).duplicate(true) if skill_data.get("visual", {}) is Dictionary else {}
	}


func _add_leader_charge(monster: Dictionary, amount: int, events: Array) -> void:
	var monster_id := str(monster.get("id", ""))
	if monster_id.is_empty() or amount <= 0:
		return
	var prev := int(leader_charge_points.get(monster_id, 0))
	var next := clampi(prev + amount, 0, LEADER_CHARGE_MAX)
	leader_charge_points[monster_id] = next
	if next == prev:
		return
	events.append({
		"monster_id": monster_id,
		"monster_name": str(monster.get("name", "")),
		"index": _player_index_by_id(monster_id),
		"amount": amount,
		"value": next,
		"max": LEADER_CHARGE_MAX,
		"filled": next >= LEADER_CHARGE_MAX
	})


func _all_leader_charges_ready() -> bool:
	var alive_count := 0
	for monster in player_team:
		if monster == null or int(monster.get("hp", 0)) <= 0:
			continue
		alive_count += 1
		var monster_id := str(monster.get("id", ""))
		if monster_id.is_empty():
			return false
		if int(leader_charge_points.get(monster_id, 0)) < LEADER_CHARGE_MAX:
			return false
	return alive_count > 0


func _active_leader_index() -> int:
	for i in range(player_team.size()):
		var monster = player_team[i]
		if monster != null and int(monster.get("hp", 0)) > 0:
			return i
	return -1


func _active_leader() -> Dictionary:
	var idx := _active_leader_index()
	if idx < 0:
		return {}
	var leader: Dictionary = player_team[idx]
	return leader


func _leader_skill_data_for(leader: Dictionary) -> Dictionary:
	if leader.is_empty() or not leader.has("leaderSkill"):
		return {}
	var skill_data := LeaderSkillDb.get_leader_skill(leader.get("leaderSkill", ""))
	return skill_data if not skill_data.is_empty() else {}


func _active_leader_skill_info() -> Variant:
	var leader := _active_leader()
	var skill_data := _leader_skill_data_for(leader)
	if skill_data.is_empty():
		return null
	return {
		"id": skill_data.get("id", ""),
		"name": skill_data.get("name", ""),
		"desc": skill_data.get("desc", ""),
		"icon": skill_data.get("icon", ""),
		"leader_id": str(leader.get("id", "")),
		"leader_index": _active_leader_index()
	}


func _reset_leader_charges() -> void:
	for monster in player_team:
		if monster == null:
			continue
		var monster_id := str(monster.get("id", ""))
		if not monster_id.is_empty():
			leader_charge_points[monster_id] = 0


func _execute_leader_burst() -> Dictionary:
	var leader_idx := _active_leader_index()
	if leader_idx < 0:
		return {}
	var leader: Dictionary = player_team[leader_idx]
	var skill_data := _leader_skill_data_for(leader)
	var log: Dictionary = _leader_skill_executor.execute_burst(leader, skill_data)
	if log.is_empty():
		return {}
	log["leader_index"] = leader_idx
	return log


func _player_index_by_id(monster_id: String) -> int:
	for i in range(player_team.size()):
		var monster = player_team[i]
		if monster != null and str(monster.get("id", "")) == monster_id:
			return i
	return -1


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


func _apply_absorb_shield_to_damage(target: Dictionary, damage: int) -> Dictionary:
	# 一次性抵消下一次伤害（区别于 player_guards 的减伤 N 回合）
	var target_id := str(target.get("id", ""))
	if target_id.is_empty() or not player_absorb_shields.has(target_id):
		return { "damage": damage, "absorbed": false }
	var shield: Dictionary = player_absorb_shields.get(target_id, {})
	if not shield.has("current_hp") and not shield.has("hp"):
		player_absorb_shields.erase(target_id)
		return { "damage": 0, "absorbed": true }
	var shield_hp := maxi(0, int(shield.get("current_hp", shield.get("hp", 0))))
	var absorbed := mini(shield_hp, maxi(0, damage))
	var remaining := maxi(0, damage - absorbed)
	shield_hp -= absorbed
	if shield_hp <= 0:
		player_absorb_shields.erase(target_id)
	else:
		shield["current_hp"] = shield_hp
		shield["hp"] = shield_hp
		player_absorb_shields[target_id] = shield
	return {
		"damage": remaining,
		"absorbed": absorbed > 0,
		"shield_absorbed": absorbed
	}


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
	if not CaptureSystem.can_capture(enemy, stage_data if stage_data is Dictionary else {}):
		capture_windows.erase(enemy_idx)
		capture_window_best.erase(enemy_idx)
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
		if not CaptureSystem.can_capture(enemy, stage_data if stage_data is Dictionary else {}):
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


func _stage_max_turns(s_data: Variant) -> int:
	if s_data != null and s_data is Dictionary:
		var stage: Dictionary = s_data
		var value := int(stage.get("maxTurns", stage.get("max_turns", 20)))
		return clampi(value, 1, 999)
	return 20


func configure_objective(board) -> Dictionary:
	var stage: Dictionary = stage_data if stage_data is Dictionary else {}
	return _objective_evaluator.configure(stage, board, enemies)


func get_objective_state(board = null) -> Dictionary:
	return _objective_evaluator.evaluate(board, enemies, turn_count, max_turns)


func _next_enemy_actor_index() -> int:
	if enemies.is_empty():
		return -1
	var start := clampi(_next_enemy_attack_index, 0, maxi(enemies.size() - 1, 0))
	for offset in range(enemies.size()):
		var idx := (start + offset) % enemies.size()
		var enemy = enemies[idx]
		if enemy != null and int(enemy.get("hp", 0)) > 0:
			return idx
	return -1


func _advance_enemy_attack_index(current_idx: int) -> void:
	if enemies.is_empty():
		_next_enemy_attack_index = 0
		return
	_next_enemy_attack_index = posmod(current_idx + 1, enemies.size())


# ========== 敌方行动 ==========

func enemy_action() -> Dictionary:
	if battle_over:
		return {}
	var actions: Array = []
	var active_enemy_idx := _next_enemy_actor_index()
	var active_enemy_indices: Array = []
	if active_enemy_idx >= 0:
		active_enemy_indices.append(active_enemy_idx)

	# 回合开始先结算 DOT；控制状态保持有效直到本轮敌方行动结束。
	var status_logs: Array = _status_effect.begin_enemy_turn_for(enemies, active_enemy_indices)

	var dot_kills: Array = []
	for i in range(enemies.size()):
		var enemy = enemies[i]
		if enemy != null and enemy.get("hp", 0) <= 0:
			dot_kills.append({ "enemy_index": i, "enemy_name": enemy.get("name", "") })

	for i in range(enemies.size()):
		if i != active_enemy_idx:
			continue
		var enemy = enemies[i]
		if enemy == null or enemy.get("hp", 0) <= 0:
			_advance_enemy_attack_index(i)
			continue

		if _enemy_skill_system != null:
			enemy["player_party"] = _build_player_party_skill_snapshot()
			var turn_start_events: Array = _enemy_skill_system.on_enemy_turn_start(i, enemy)
			_apply_enemy_skill_events(i, enemy, turn_start_events, actions)

		var alive_team = player_team.filter(func(m): return m != null and m.get("hp", 0) > 0)
		if alive_team.is_empty():
			_advance_enemy_attack_index(i)
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
			_advance_enemy_attack_index(i)
			continue

		# 检查敌人是否有技能
		var has_skills = false
		if _enemy_skill_system != null:
			has_skills = not _enemy_skill_system.get_enemy_state(i).is_empty()

		# 护盾检查（委托给 EnemySkillSystem）
		if _enemy_skill_system != null and has_skills:
			_enemy_skill_system.check_and_activate_shield(i, enemy)
			_enemy_skill_system.check_and_activate_shield_plus(i, enemy)

		# 回血检查（委托给 EnemySkillSystem）
		if _enemy_skill_system != null and has_skills:
			_enemy_skill_system.execute_heal(i, enemy)

		# 蓄力检查（委托给 EnemySkillSystem）
		var skip_attack = false
		var damage_multiplier = 1.0

		if _enemy_skill_system != null:
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
			_advance_enemy_attack_index(i)
			continue

		# 普通攻击
		var target = alive_team[randi() % alive_team.size()]
		var target_idx := _player_index_by_id(str(target.get("id", "")))
		if target_idx < 0:
			target_idx = player_team.find(target)

		# 冰冻ATK降低（委托给 BattleStatusEffect）
		var freeze_mult = _status_effect.get_freeze_atk_multiplier(i)
		var tempo_mod := _consume_enemy_tempo_multiplier(i)
		var tempo_mult := float(tempo_mod.get("multiplier", 1.0))

		# 队长DEF加成
		var leader_def_boost = LeaderSkillDb.get_leader_def_boost(leader_skill_data)

		# 属性协同DEF
		var target_affinity := _board_affinity(target)
		var synergy_def_mult = get_synergy_def_mult(target_affinity)

		# 委托给 DamageCalculator
		var damage = _damage_calc.calc_enemy_damage(
			enemy.get("atk", 10),
			enemy.get("element", ""),
			target.get("def", 0),
			target.get("element", ""),
			freeze_mult * tempo_mult,
			leader_def_boost,
			synergy_def_mult
		)

		damage = int(damage * damage_multiplier * _tower_enemy_damage_multiplier())
		var guard_result := _apply_guard_to_damage(target, damage)
		damage = int(guard_result.get("damage", damage))
		var guard_absorbed := int(guard_result.get("guard_absorbed", 0))
		var absorb_result := _apply_absorb_shield_to_damage(target, damage)
		var shield_absorbed := bool(absorb_result.get("absorbed", false))
		if shield_absorbed:
			damage = 0

		target["hp"] = target.get("hp", 0) - damage
		_refresh_capture_windows()

		var attack_action := {
			"attacker": enemy.get("name", ""),
			"attacker_emoji": enemy.get("emoji", ""),
			"target": target.get("name", ""),
			"target_id": target.get("id", ""),
			"target_index": target_idx,
			"targetId": target.get("id", ""),
			"targetIndex": target_idx,
			"target_emoji": target.get("emoji", ""),
			"damage": damage,
			"element": enemy.get("element", ""),
			"target_died": target.get("hp", 0) <= 0,
			"is_charged": damage_multiplier > 1.0,
			"charge_multiplier": damage_multiplier,
			"is_weakened": tempo_mult < 1.0,
			"weaken_reduction": tempo_mod.get("reduction", 0.0),
			"guard_absorbed": guard_absorbed,
			"shield_absorbed": shield_absorbed,
			"enemy_index": i
		}
		actions.append(attack_action)

		if _enemy_skill_system != null and target_idx >= 0 and damage > 0:
			var after_attack_events: Array = _enemy_skill_system.on_enemy_after_attack(i, target_idx, damage)
			_apply_enemy_skill_events(i, enemy, after_attack_events, actions)
		_advance_enemy_attack_index(i)

	# 所有敌人完成行动或跳过行动后，再统一消费一次状态持续回合。
	status_logs.append_array(_status_effect.end_enemy_turn_for(enemies, active_enemy_indices))

	if _enemy_skill_system != null:
		for raw_i in active_enemy_indices:
			var i := int(raw_i)
			var enemy = enemies[i]
			if enemy == null or int(enemy.get("hp", 0)) <= 0:
				continue
			enemy["player_party"] = _build_player_party_skill_snapshot()
			var turn_end_events: Array = _enemy_skill_system.on_enemy_turn_end(i, enemy)
			_apply_enemy_skill_events(i, enemy, turn_end_events, actions)

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


func _build_player_party_skill_snapshot() -> Array:
	var snapshot: Array = []
	for idx in range(player_team.size()):
		var unit = player_team[idx]
		if unit == null:
			continue
		snapshot.append({
			"idx": idx,
			"id": unit.get("id", ""),
			"name": unit.get("name", ""),
			"hp": int(unit.get("hp", 0)),
			"maxHP": int(unit.get("maxHP", 0))
		})
	return snapshot


func _choose_enemy_skill_target_idx() -> int:
	var best_idx := -1
	var best_hp := -1
	for idx in range(player_team.size()):
		var unit = player_team[idx]
		if unit == null:
			continue
		var hp := int(unit.get("hp", 0))
		if hp > best_hp:
			best_hp = hp
			best_idx = idx
	return best_idx


func _apply_direct_player_damage(target_idx: int, damage: int) -> Dictionary:
	if target_idx < 0 or target_idx >= player_team.size():
		return {}
	var target = player_team[target_idx]
	if target == null or int(target.get("hp", 0)) <= 0:
		return {}
	damage = maxi(0, damage)
	var guard_result := _apply_guard_to_damage(target, damage)
	damage = int(guard_result.get("damage", damage))
	var guard_absorbed := int(guard_result.get("guard_absorbed", 0))
	var absorb_result := _apply_absorb_shield_to_damage(target, damage)
	var shield_absorbed := bool(absorb_result.get("absorbed", false))
	if shield_absorbed:
		damage = 0
	target["hp"] = int(target.get("hp", 0)) - damage
	return {
		"target": target,
		"damage": damage,
		"guard_absorbed": guard_absorbed,
		"shield_absorbed": shield_absorbed
	}


func _apply_enemy_skill_events(enemy_idx: int, enemy: Dictionary, events: Array, actions: Array) -> void:
	for event in events:
		if not (event is Dictionary):
			continue
		var event_type := str(event.get("type", ""))
		var target_idx := int(event.get("target_idx", event.get("target_index", -1)))
		var damage := int(event.get("damage", 0))
		var is_damage_event := event_type in ["burn_damage", "poison_damage", "surge_damage", "thunder_strike", "life_drain"]
		if is_damage_event:
			if target_idx < 0:
				target_idx = _choose_enemy_skill_target_idx()
			var damage_result := _apply_direct_player_damage(target_idx, damage)
			if damage_result.is_empty():
				continue
			if event_type == "life_drain":
				var heal_amount := int(event.get("heal_amount", damage_result.get("damage", 0)))
				var prev_hp := int(enemy.get("hp", 0))
				enemy["hp"] = mini(int(enemy.get("maxHP", prev_hp)), prev_hp + heal_amount)
			var target: Dictionary = damage_result.get("target", {})
			actions.append({
				"attacker": enemy.get("name", ""),
				"attacker_emoji": enemy.get("emoji", ""),
				"target": target.get("name", ""),
				"target_id": target.get("id", ""),
				"target_index": target_idx,
				"target_emoji": target.get("emoji", ""),
				"damage": int(damage_result.get("damage", 0)),
				"element": enemy.get("element", ""),
				"target_died": int(target.get("hp", 0)) <= 0,
				"is_enemy_skill": true,
				"skill_type": event_type,
				"enemy_index": enemy_idx,
				"guard_absorbed": int(damage_result.get("guard_absorbed", 0)),
				"shield_absorbed": bool(damage_result.get("shield_absorbed", false)),
				"heal_amount": int(event.get("heal_amount", 0))
			})
		elif event_type.ends_with("_apply") or event_type.ends_with("_activate") or event_type.ends_with("_expire"):
			var target = player_team[target_idx] if target_idx >= 0 and target_idx < player_team.size() else {}
			actions.append({
				"attacker": enemy.get("name", ""),
				"attacker_emoji": enemy.get("emoji", ""),
				"target": target.get("name", ""),
				"target_id": target.get("id", ""),
				"target_index": target_idx,
				"target_emoji": target.get("emoji", ""),
				"damage": 0,
				"element": enemy.get("element", ""),
				"target_died": false,
				"is_enemy_skill": true,
				"skill_type": event_type,
				"enemy_index": enemy_idx
			})


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

func check_battle_end(board = null) -> bool:
	if battle_over:
		return true
	var all_dead = enemies.all(func(e): return e == null or e.get("hp", 0) <= 0)
	if all_dead:
		_objective_evaluator.evaluate(board, enemies, turn_count, max_turns)
		battle_over = true
		battle_result = "win"
		battle_ended.emit("win")
		return true
	return false


func _apply_tower_player_damage(amount: int) -> int:
	if not is_tower_mode():
		return amount
	var multiplier := 1.0
	for raw_buff in tower_buffs:
		if raw_buff is Dictionary:
			multiplier += float((raw_buff as Dictionary).get("damage_bonus", 0.0))
	return maxi(1, int(round(float(amount) * multiplier)))


func _tower_enemy_damage_multiplier() -> float:
	if not is_tower_mode():
		return 1.0
	var multiplier := 1.0
	for raw_buff in tower_buffs:
		if raw_buff is Dictionary:
			multiplier -= float((raw_buff as Dictionary).get("enemy_damage_reduction", 0.0))
	return clampf(multiplier, 0.35, 1.0)


func _tower_bonus_charge_per_match() -> int:
	if not is_tower_mode():
		return 0
	var bonus := 0
	for raw_buff in tower_buffs:
		if raw_buff is Dictionary:
			bonus += int((raw_buff as Dictionary).get("bonus_charge_per_match", 0))
	return bonus


func _record_player_turn_damage(amount: int) -> void:
	if amount <= 0:
		return
	current_player_turn_damage += amount
	highest_player_turn_damage = maxi(highest_player_turn_damage, current_player_turn_damage)


# ========== 辅助函数 ==========

func get_enemies() -> Array:
	return enemies


func execute_phase_transition(phase_config: Dictionary) -> Array:
	# ★ 主人定 A：计算旧怪血量比例，进阶段后保留比例，不再“回满血”
	var hp_ratio := 0.0
	if not enemies.is_empty():
		var total_old_hp := 0
		var total_old_max_hp := 0
		for e: Dictionary in enemies:
			total_old_hp += int(e.get("hp", 0))
			total_old_max_hp += int(e.get("maxHP", 0))
		if total_old_max_hp > 0:
			hp_ratio = clampf(float(total_old_hp) / float(total_old_max_hp), 0.0, 1.0)
	var new_enemies: Array = _phase_handler.execute_phase_transition(phase_config, enemy_level, hp_ratio)
	if new_enemies.is_empty():
		return []

	enemies = new_enemies
	current_phase = _phase_handler.get_current_phase()
	enemy_tempo_mods = {}
	_next_enemy_attack_index = 0
	capture_windows = {}
	capture_window_best = {}
	_status_effect.init_effects(enemies.size())
	_refresh_capture_windows()
	if _enemy_skill_system == null:
		_enemy_skill_system = EnemySkillSystem.new()
	_enemy_skill_system.init_skill_state(enemies)
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
		_status_effect.get_effects_snapshot()
	)


# ========== 获取状态摘要 ==========

func get_status() -> Dictionary:
	return {
		"turn_count": turn_count,
		"mode": battle_mode,
		"current_player_turn_damage": current_player_turn_damage,
		"highest_player_turn_damage": highest_player_turn_damage,
		"combo": combo,
		"player_team": player_team.map(func(m): return m.duplicate(true) if m != null else null),
		"enemies": enemies.map(func(e): return e.duplicate(true) if e != null else null),
		"skill_charges": skill_charges.duplicate(),
		"leader_charge_points": leader_charge_points.duplicate(),
		"leader_charge_max": LEADER_CHARGE_MAX,
		"battle_over": battle_over,
		"battle_result": battle_result,
		"current_phase": current_phase,
		"total_phases": stage_phases.size() if not stage_phases.is_empty() else 1,
		"is_boss_battle": not stage_phases.is_empty(),
		"enemy_skill_states": _build_enemy_skill_states_dict(),
		"enemy_intents": get_enemy_intents(),
		"objective": _objective_evaluator.get_state(),
		"leader_skill_info": _active_leader_skill_info(),
		"synergy_info": synergy_info,
		"synergy_bonuses": synergy_bonuses.duplicate(true) if synergy_bonuses != null else null,
		"player_guards": player_guards.duplicate(true),
		"player_absorb_shields": player_absorb_shields.duplicate(true),
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
	var objective_state := _objective_evaluator.evaluate(null, enemies, turn_count, max_turns)
	var reward_receipt_id := "battle_reward:%s" % battle_id
	return {
		"result": battle_result,
		"battle_id": battle_id,
		"battleId": battle_id,
		"reward_receipt_id": reward_receipt_id,
		"rewardReceiptId": reward_receipt_id,
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
		"capture_windows": capture_windows.duplicate(true),
		"capture_window_best": capture_window_best.duplicate(true),
		"best_capture_window": get_best_capture_candidate().get("window", {}),
		"stageRewards": stage_data.get("rewards", null) if stage_data != null else null,
		"stage_rewards": stage_data.get("rewards", null) if stage_data != null else null,
		"stageGoal": stage_data.get("stageGoal", {}) if stage_data != null else {},
		"objectiveState": objective_state,
		"objectiveCompleted": bool(objective_state.get("completed", false))
	}
