class_name EnemyAttackModes
extends RefCounted
## 敌人出手模式（数据驱动）
##
## 配置来源（高优先级覆盖低优先级）：
##   1. 关卡数据：stage["enemyAttackModes"][monsterId]
##   2. 怪物数据：MonsterDb 的 "attackModes"
## 未配置的敌人保持 "strike" 直接单体重击，行为与旧版一致。
##
## 支持两种挑选方式：
##   - rotation：按轮次循环 sequence
##   - weight：按 weighted 权重随机
##
## 模式：
##   strike          直接单体重击（现有行为）
##   charge          蓄力回合，不出伤；下一回合自动释放 charge_release
##   charge_release  charge 的下一回合，单体重击 × chargeMultiplier（1.8~2.0）
##   sweep           对全部存活伙伴各造成约半次单体伤害（0.5x）
##
## 注意：本模块只负责“选模式”和“蓄力状态”，伤害结算与 UI 仍由
## BattleManager / EnemyIntentRules / BattleCombatantRenderer 负责。

const MODE_STRIKE := "strike"
const MODE_CHARGE := "charge"
const MODE_CHARGE_RELEASE := "charge_release"
const MODE_SWEEP := "sweep"

const STYLE_STRIKE := "strike"
const STYLE_CHARGE := "charge"
const STYLE_SWEEP := "sweep"

const DEFAULT_CHARGE_MULTIPLIER := 1.9
const DEFAULT_SWEEP_MULTIPLIER := 0.5
const MIN_CHARGE_MULTIPLIER := 1.8
const MAX_CHARGE_MULTIPLIER := 2.0
const MIN_SWEEP_MULTIPLIER := 0.4
const MAX_SWEEP_MULTIPLIER := 0.6

var _configs: Dictionary = {}  # { enemy_idx: {select, sequence, weighted} }
var _states: Dictionary = {}   # { enemy_idx: {step, charging, pending, release_multiplier} }


## 初始化/重置每个敌人的攻击模式状态。波次或 Boss 阶段切换后必须重新调用，
## 避免把上一波敌人的轮次与蓄力状态带到新敌人身上。
func init(enemies: Array, stage_data: Variant = null) -> void:
	_configs.clear()
	_states.clear()
	var stage_overrides: Dictionary = {}
	if stage_data is Dictionary:
		var raw_overrides: Variant = (stage_data as Dictionary).get("enemyAttackModes", {})
		if raw_overrides is Dictionary:
			stage_overrides = raw_overrides

	for i in range(enemies.size()):
		var enemy: Variant = enemies[i]
		if enemy == null or not enemy is Dictionary:
			continue
		var enemy_data: Dictionary = enemy
		var monster_id := str(enemy_data.get("id", ""))
		var raw_config: Variant = null
		if not monster_id.is_empty() and stage_overrides.has(monster_id):
			raw_config = stage_overrides[monster_id]
		elif enemy_data.has("attackModes"):
			raw_config = enemy_data.get("attackModes")
		var config: Dictionary = _normalize_config(raw_config)
		if not config.is_empty():
			_configs[i] = config
		_states[i] = {
			"step": 0,
			"charging": false,
			"pending": {},
			"release_multiplier": 0.0
		}


## 本回合的出手模式（预览）。可安全重复调用；权重随机只在首次预览时抽取并缓存，
## 保证前摇提示与实际结算使用同一个模式。
func peek(enemy_idx: int) -> Dictionary:
	var state: Dictionary = _states.get(enemy_idx, {})
	if state.is_empty():
		return _strike_mode()
	if bool(state.get("charging", false)):
		var multiplier := float(state.get("release_multiplier", DEFAULT_CHARGE_MULTIPLIER))
		return {
			"type": MODE_CHARGE_RELEASE,
			"multiplier": clampf(multiplier, MIN_CHARGE_MULTIPLIER, MAX_CHARGE_MULTIPLIER)
		}
	var pending: Dictionary = state.get("pending", {})
	if not pending.is_empty():
		return pending.duplicate(true)
	var picked := _pick_mode(enemy_idx, state)
	state["pending"] = picked.duplicate(true)
	return picked


## 敌人真正行动时调用：返回本回合模式，并推进轮次/进入蓄力状态。
func consume_turn(enemy_idx: int) -> Dictionary:
	var mode := peek(enemy_idx)
	var state: Dictionary = _states.get(enemy_idx, {})
	if state.is_empty():
		return mode

	if str(mode.get("type", MODE_STRIKE)) == MODE_CHARGE_RELEASE:
		state["charging"] = false
		state["pending"] = {}
		state["release_multiplier"] = 0.0
		return mode

	var step := int(state.get("step", 0)) + 1
	state["step"] = step
	state["pending"] = {}
	if str(mode.get("type", MODE_STRIKE)) == MODE_CHARGE:
		state["charging"] = true
		state["release_multiplier"] = float(mode.get("multiplier", DEFAULT_CHARGE_MULTIPLIER))
	return mode


## 仅用于前摇/截图/测试：强制指定下一次出手模式。
## mode_type 支持 strike / charge / charge_release / sweep。
func force_next_mode(enemy_idx: int, mode_type: String, multiplier: float = 0.0) -> bool:
	if not _states.has(enemy_idx):
		_states[enemy_idx] = {
			"step": 0,
			"charging": false,
			"pending": {},
			"release_multiplier": 0.0
		}
	var state: Dictionary = _states[enemy_idx]
	var normalized := mode_type.to_lower()
	match normalized:
		MODE_CHARGE_RELEASE:
			var release_multiplier := multiplier if multiplier > 0.0 else DEFAULT_CHARGE_MULTIPLIER
			state["charging"] = true
			state["pending"] = {}
			state["release_multiplier"] = clampf(release_multiplier, MIN_CHARGE_MULTIPLIER, MAX_CHARGE_MULTIPLIER)
			return true
		MODE_CHARGE:
			var charge_multiplier := multiplier if multiplier > 0.0 else DEFAULT_CHARGE_MULTIPLIER
			state["charging"] = false
			state["pending"] = {
				"type": MODE_CHARGE,
				"multiplier": clampf(charge_multiplier, MIN_CHARGE_MULTIPLIER, MAX_CHARGE_MULTIPLIER)
			}
			return true
		MODE_STRIKE, MODE_SWEEP:
			state["charging"] = false
			state["pending"] = {
				"type": normalized,
				"multiplier": _mode_multiplier(normalized, multiplier)
			}
			return true
	return false


func has_config(enemy_idx: int) -> bool:
	return _configs.has(enemy_idx)


func get_config(enemy_idx: int) -> Dictionary:
	return (_configs.get(enemy_idx, {}) as Dictionary).duplicate(true)


## 前摇视觉分档：普通红箭头 / 蓄力紫电 / 全体青色扇形。
static func windup_style(mode_type: String) -> String:
	match mode_type:
		MODE_CHARGE, MODE_CHARGE_RELEASE:
			return STYLE_CHARGE
		MODE_SWEEP:
			return STYLE_SWEEP
		_:
			return STYLE_STRIKE


static func mode_label(mode_type: String) -> String:
	match mode_type:
		MODE_CHARGE:
			return "蓄力"
		MODE_CHARGE_RELEASE:
			return "蓄力释放"
		MODE_SWEEP:
			return "全体攻击"
		_:
			return "普攻"


func _pick_mode(enemy_idx: int, state: Dictionary) -> Dictionary:
	var config: Dictionary = _configs.get(enemy_idx, {})
	if config.is_empty():
		return _strike_mode()

	var select := str(config.get("select", "rotation"))
	if select == "weight":
		var weighted: Array = config.get("weighted", [])
		return _pick_weighted(weighted)

	var sequence: Array = config.get("sequence", [])
	if sequence.is_empty():
		return _strike_mode()
	var step := int(state.get("step", 0))
	var entry: Variant = sequence[step % sequence.size()]
	if entry is Dictionary:
		return (entry as Dictionary).duplicate(true)
	return _strike_mode()


func _pick_weighted(weighted: Array) -> Dictionary:
	var total_weight := 0.0
	for entry: Variant in weighted:
		if entry is Dictionary:
			total_weight += maxf(0.0, float((entry as Dictionary).get("weight", 1.0)))
	if total_weight <= 0.0:
		return _strike_mode()

	var roll := randf() * total_weight
	var last: Dictionary = {}
	for entry: Variant in weighted:
		if not entry is Dictionary:
			continue
		var mode: Dictionary = entry
		last = mode
		roll -= maxf(0.0, float(mode.get("weight", 1.0)))
		if roll <= 0.0:
			return _mode_copy(mode)
	return _mode_copy(last)


static func _normalize_config(raw_config: Variant) -> Dictionary:
	if not raw_config is Dictionary:
		return {}
	var raw: Dictionary = raw_config
	var charge_multiplier := clampf(
		float(raw.get("chargeMultiplier", DEFAULT_CHARGE_MULTIPLIER)),
		MIN_CHARGE_MULTIPLIER,
		MAX_CHARGE_MULTIPLIER
	)
	var sweep_multiplier := clampf(
		float(raw.get("sweepMultiplier", DEFAULT_SWEEP_MULTIPLIER)),
		MIN_SWEEP_MULTIPLIER,
		MAX_SWEEP_MULTIPLIER
	)

	var sequence: Array = []
	var raw_sequence: Variant = raw.get("sequence", [])
	if raw_sequence is Array:
		for entry: Variant in raw_sequence:
			var mode := _normalize_entry(entry, charge_multiplier, sweep_multiplier)
			if not mode.is_empty():
				sequence.append(mode)

	var weighted: Array = []
	var raw_weighted: Variant = raw.get("weighted", [])
	if raw_weighted is Array:
		for entry: Variant in raw_weighted:
			var mode := _normalize_entry(entry, charge_multiplier, sweep_multiplier)
			if mode.is_empty():
				continue
			var weight := float((entry as Dictionary).get("weight", 1.0)) if entry is Dictionary else 1.0
			mode["weight"] = maxf(0.0, weight)
			weighted.append(mode)

	if sequence.is_empty() and weighted.is_empty():
		return {}

	var select := str(raw.get("select", ""))
	if select != "rotation" and select != "weight":
		select = "weight" if not weighted.is_empty() else "rotation"
	if select == "rotation" and sequence.is_empty():
		for mode: Dictionary in weighted:
			sequence.append(mode.duplicate(true))
	if select == "weight" and weighted.is_empty():
		for mode: Dictionary in sequence:
			var weighted_mode := mode.duplicate(true)
			weighted_mode["weight"] = 1.0
			weighted.append(weighted_mode)

	return {
		"select": select,
		"sequence": sequence,
		"weighted": weighted,
		"chargeMultiplier": charge_multiplier,
		"sweepMultiplier": sweep_multiplier
	}


static func _normalize_entry(entry: Variant, charge_multiplier: float, sweep_multiplier: float) -> Dictionary:
	var source: Dictionary = {}
	if entry is String:
		source = {"type": entry}
	elif entry is Dictionary:
		source = entry
	else:
		return {}

	var mode_type := str(source.get("type", "")).to_lower()
	if mode_type != MODE_STRIKE and mode_type != MODE_CHARGE and mode_type != MODE_SWEEP:
		return {}

	var multiplier := 1.0
	if mode_type == MODE_CHARGE:
		multiplier = clampf(float(source.get("multiplier", charge_multiplier)), MIN_CHARGE_MULTIPLIER, MAX_CHARGE_MULTIPLIER)
	elif mode_type == MODE_SWEEP:
		multiplier = clampf(float(source.get("multiplier", sweep_multiplier)), MIN_SWEEP_MULTIPLIER, MAX_SWEEP_MULTIPLIER)
	return {
		"type": mode_type,
		"multiplier": multiplier
	}


static func _mode_multiplier(mode_type: String, multiplier: float) -> float:
	if mode_type == MODE_SWEEP:
		if multiplier <= 0.0:
			return DEFAULT_SWEEP_MULTIPLIER
		return clampf(multiplier, MIN_SWEEP_MULTIPLIER, MAX_SWEEP_MULTIPLIER)
	if mode_type == MODE_CHARGE:
		if multiplier <= 0.0:
			return DEFAULT_CHARGE_MULTIPLIER
		return clampf(multiplier, MIN_CHARGE_MULTIPLIER, MAX_CHARGE_MULTIPLIER)
	return 1.0


static func _mode_copy(mode: Dictionary) -> Dictionary:
	return {
		"type": str(mode.get("type", MODE_STRIKE)),
		"multiplier": float(mode.get("multiplier", 1.0)),
		"weight": float(mode.get("weight", 1.0))
	}


static func _strike_mode() -> Dictionary:
	return {
		"type": MODE_STRIKE,
		"multiplier": 1.0
	}
