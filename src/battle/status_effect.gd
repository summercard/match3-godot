# ============================================
# battle/status_effect.gd - C4状态效果系统
# 翻译自: js/battle/battleManager.js 中的 STATUS_DEFS / ELEMENT_TO_STATUS / tryApplyStatusEffects / processStatusEffects
# ============================================
class_name BattleStatusEffect
extends RefCounted

## C4状态效果系统
## 职责：
## - burn: DoT, sourceATK×0.15, 3回合
## - freeze: ATK降低30%, 2回合
## - poison: DoT, sourceATK×0.20, 3回合
## - stun: 成功附加后跳过1次攻击, 1回合
## - 4颗触发50%概率，5颗+触发100%概率
## - Boss抗性：stun概率×50%

## 状态效果定义（静态）
const STATUS_DEFS: Dictionary = {
	"burn": {
		"element": "fire",
		"dot_mult": 0.15,
		"duration": 3,
		"label": "🔥灼烧",
		"dot_label": "灼烧伤害"
	},
	"freeze": {
		"element": "water",
		"atk_reduction": 0.30,
		"duration": 2,
		"label": "❄️冰冻"
	},
	"poison": {
		"element": "grass",
		"dot_mult": 0.20,
		"duration": 3,
		"label": "☠️中毒",
		"dot_label": "中毒伤害"
	},
	"stun": {
		"element": "thunder",
		"duration": 1,
		"label": "⚡眩晕"
	}
}

## 属性 → 状态效果类型映射
const ELEMENT_TO_STATUS: Dictionary = {
	"fire": "burn",
	"water": "freeze",
	"grass": "poison",
	"thunder": "stun"
}

## 状态效果实例数据 { type, source_atk, turns_left, element }
var _effects: Array = []
var _effect_log: Array = []


func _init() -> void:
	pass


## 初始化状态效果数组（战斗开始时调用）
func init_effects(enemy_count: int) -> void:
	_effects = []
	for i in range(enemy_count):
		_effects.append(null)
	_effect_log = []


## 获取状态效果定义（静态）
static func get_status_def(status_type: String) -> Dictionary:
	return STATUS_DEFS.get(status_type, {})


## 检查敌人是否被眩晕（应跳过攻击）
func is_enemy_stunned(enemy_index: int) -> bool:
	if enemy_index < 0 or enemy_index >= _effects.size():
		return false
	var effect = _effects[enemy_index]
	if effect == null or not effect is Dictionary or effect.get("type", "") != "stun":
		return false
	# 附加阶段已经处理触发概率和 Boss 抗性；状态存在时必须稳定生效。
	return true


## 获取敌人的冰冻ATK降低倍率
func get_freeze_atk_multiplier(enemy_index: int) -> float:
	if enemy_index < 0 or enemy_index >= _effects.size():
		return 1.0
	var effect = _effects[enemy_index]
	if effect == null or not effect is Dictionary or effect.get("type", "") != "freeze":
		return 1.0
	var reduction: float = STATUS_DEFS["freeze"].get("atk_reduction", 0.30)
	return 1.0 - reduction


func apply_status(enemy_index: int, status_type: String, source_atk: int, enemy_name: String = "") -> Dictionary:
	if enemy_index < 0 or enemy_index >= _effects.size():
		return {}
	if not STATUS_DEFS.has(status_type):
		return {}
	var def: Dictionary = STATUS_DEFS[status_type]
	var duration: int = int(def.get("duration", 1))
	var element: String = str(def.get("element", ""))
	_effects[enemy_index] = {
		"type": status_type,
		"source_atk": source_atk,
		"turns_left": duration,
		"element": element
	}
	var label: String = str(def.get("label", status_type))
	var log := {
		"type": status_type,
		"enemy_index": enemy_index,
		"enemy_name": enemy_name,
		"message": "%s -> %s" % [label, enemy_name]
	}
	_effect_log.append(log)
	return log


## 尝试根据消除宝石数量附加状态效果
func try_apply_status_effects(gem_counts: Dictionary, player_team: Array, enemies: Array) -> void:
	_effect_log = []

	var weakest_enemy = _get_weakest_enemy(enemies)
	if weakest_enemy == null:
		return
	var target_idx: int = enemies.find(weakest_enemy)

	for element in gem_counts:
		var count: int = gem_counts[element]
		if count < 4:
			continue

		var status_type: String = ELEMENT_TO_STATUS.get(element, "")
		if status_type.is_empty():
			continue

		var trigger_chance: float = 1.0 if count >= 5 else 0.5

		if status_type == "stun" and bool(weakest_enemy.get("isBoss", weakest_enemy.get("is_boss", false))):
			trigger_chance *= 0.5

		if randf() > trigger_chance:
			continue

		var source_atk: int = 10
		for m in player_team:
			if m == null or m.get("hp", 0) <= 0:
				continue
			if MonsterDb.get_board_affinity(m) == element:
				source_atk = m.get("atk", 10)
				break

		var duration: int = STATUS_DEFS[status_type].get("duration", 2)
		_effects[target_idx] = {
			"type": status_type,
			"source_atk": source_atk,
			"turns_left": duration,
			"element": element
		}

		var label: String = STATUS_DEFS[status_type].get("label", status_type)
		_effect_log.append({
			"type": status_type,
			"enemy_index": target_idx,
			"enemy_name": weakest_enemy.get("name", ""),
			"message": "%s! → %s" % [label, weakest_enemy.get("name", "")]
		})


## 敌方回合开始：结算 DOT 并生成当前状态提示，但不扣除持续回合。
## 控制判断和冰冻倍率会在本轮行动阶段读取仍然有效的状态。
func begin_enemy_turn(enemies: Array) -> Array:
	var logs: Array = []

	for i in range(enemies.size()):
		var enemy: Dictionary = enemies[i]
		if enemy == null or enemy.get("hp", 0) <= 0:
			continue
		var effect = _effects[i]
		if effect == null or not effect is Dictionary:
			continue
			
		var def: Dictionary = STATUS_DEFS.get(effect.get("type", ""), {})

		if effect.get("type") == "burn" or effect.get("type") == "poison":
			var dot_mult: float = def.get("dot_mult", 0.15)
			var dot_damage: int = maxi(1, int(effect.get("source_atk", 10) * dot_mult))
			enemy["hp"] -= dot_damage
			var dot_label: String = def.get("dot_label", "伤害")
			var label: String = def.get("label", "")
			logs.append({
				"type": effect.get("type"),
				"enemy_index": i,
				"enemy_name": enemy.get("name", ""),
				"damage": dot_damage,
				"message": "%s %s 受到 %d %s！" % [label, enemy.get("name", ""), dot_damage, dot_label]
			})
		elif effect.get("type") == "freeze":
			logs.append({
				"type": "freeze",
				"enemy_index": i,
				"enemy_name": enemy.get("name", ""),
				"message": "❄️%s 冰冻中，ATK降低30%%！" % enemy.get("name", "")
			})
		elif effect.get("type") == "stun":
			logs.append({
				"type": "stun",
				"enemy_index": i,
				"enemy_name": enemy.get("name", ""),
				"message": "⚡%s 眩晕中！" % enemy.get("name", "")
			})

	return logs


## 敌方回合结束：所有仍存活状态统一扣除一次持续回合并清理到期效果。
func end_enemy_turn(enemies: Array) -> Array:
	var logs: Array = []
	for i in range(_effects.size()):
		var effect = _effects[i]
		if effect == null or not effect is Dictionary:
			continue
		var enemy: Dictionary = enemies[i] if i < enemies.size() and enemies[i] is Dictionary else {}
		if enemy.is_empty() or int(enemy.get("hp", 0)) <= 0:
			_effects[i] = null
			continue
		var turns_left := int(effect.get("turns_left", 1)) - 1
		effect["turns_left"] = turns_left
		if turns_left > 0:
			continue
		_effects[i] = null
		var status_type := str(effect.get("type", ""))
		var def: Dictionary = STATUS_DEFS.get(status_type, {})
		var label := str(def.get("label", status_type))
		logs.append({
			"type": status_type + "_end",
			"enemy_index": i,
			"enemy_name": enemy.get("name", ""),
			"message": "%s 的%s效果消失了" % [enemy.get("name", ""), label]
		})
	return logs


## 兼容旧调用：只执行回合开始阶段，持续时间必须由 end_enemy_turn() 消费。
func process_status_effects(enemies: Array) -> Array:
	return begin_enemy_turn(enemies)


## 获取状态效果列表（快照）
func get_effects_snapshot() -> Array:
	return _effects.map(func(e): return e if e == null else e.duplicate())


## 获取效果日志
func get_effect_log() -> Array:
	return _effect_log


## 找到血量最低的敌人
func _get_weakest_enemy(enemies: Array) -> Dictionary:
	var weakest: Dictionary = {}
	var min_hp: int = 999999999
	var found: bool = false

	for enemy in enemies:
		if enemy == null or not enemy is Dictionary or enemy.get("hp", 0) <= 0:
			continue
		var hp: int = enemy.get("hp", 0)
		if hp < min_hp:
			min_hp = hp
			weakest = enemy
			found = true

	if not found:
		return {}

	return weakest
