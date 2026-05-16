# ============================================
# growth/growth_system.gd - 成长系统（经验/等级/进化）
# 来源: js/core/storage.js 中的成长相关方法
# ============================================
class_name GrowthSystem
extends Node

# 单例访问
static var instance: GrowthSystem

func _init() -> void:
	instance = self

# ============================================
# 经验需求计算
# ============================================
# 每级基础100 + 等级×20
static func get_exp_for_level(level: int) -> int:
	return 100 + level * 20

# 获取升到指定等级所需总经验
static func get_total_exp_for_level(level: int) -> int:
	var total := 0
	for l in range(1, level):
		total += get_exp_for_level(l)
	return total

# 获取当前等级到下一级所需经验
static func get_exp_to_next_level(current_level: int, current_exp: int) -> int:
	var needed := get_exp_for_level(current_level)
	return maxi(0, needed - current_exp)

# ============================================
# 经验处理（增加经验，触发升级）
# ============================================
# pokedex_entry 格式: { level: int, exp: int, nature: String }
# 返回: { leveledUp: bool, newLevel: int, oldLevel: int, expGained: int, currentExp: int, levelsGained: int }
static func process_exp(pokedex_entry: Dictionary, exp_gained: int) -> Dictionary:
	var old_level: int = pokedex_entry.get("level", 1)
	var old_exp: int = pokedex_entry.get("exp", 0)
	
	pokedex_entry["exp"] = old_exp + exp_gained
	
	var levels_gained := 0
	# 检查升级循环
	while true:
		var needed: int = get_exp_for_level(pokedex_entry["level"])
		if pokedex_entry["exp"] >= needed:
			pokedex_entry["exp"] -= needed
			pokedex_entry["level"] += 1
			levels_gained += 1
		else:
			break
	
	return {
		"leveledUp": pokedex_entry["level"] > old_level,
		"newLevel": pokedex_entry["level"],
		"oldLevel": old_level,
		"expGained": exp_gained,
		"currentExp": pokedex_entry["exp"],
		"levelsGained": levels_gained
	}

# ============================================
# 进化阶段判断
# ============================================
# 进化链: 幼年期(1) → 成长期(2) → 完全体(3)
# 对应 JS: evolution.level 和 evolution.target
static func get_evolution_stage(monster_id: String, current_level: int) -> Dictionary:
	# 获取怪物数据
	var monster_data = MonsterDB.get_monster(monster_id)
	if not monster_data.has("evolution"):
		return { "stage": 1, "can_evolve": false, "next_stage": 2, "evolve_level": -1, "target_id": "" }
	
	var evo = monster_data["evolution"]
	var evolve_level: int = evo.get("level", 16)
	var target_id: String = evo.get("target", "")
	
	# 判断当前阶段
	var stage := 1  # 幼年期
	if current_level >= evolve_level and target_id != "":
		stage = 2  # 成长期(可进化)
	
	var can_evolve := current_level >= evolve_level and target_id != ""
	
	return {
		"stage": stage,
		"can_evolve": can_evolve,
		"next_stage": 3,  # 完全体
		"evolve_level": evolve_level,
		"target_id": target_id,
		"evolved": current_level > evolve_level  # 已进化标志
	}

# 获取进化后怪物ID
static func get_evolution_target(monster_id: String) -> String:
	var monster_data = MonsterDB.get_monster(monster_id)
	if monster_data.has("evolution"):
		return monster_data["evolution"].get("target", "")
	return ""

# 检查是否可以进化
static func can_evolve(monster_id: String, current_level: int) -> bool:
	var evo_data = get_evolution_stage(monster_id, current_level)
	return evo_data["can_evolve"]

# 执行进化（返回新怪物ID）
static func do_evolve(monster_id: String) -> String:
	return get_evolution_target(monster_id)

# ============================================
# 经验条显示计算
# ============================================
# 计算当前经验在经验条中的百分比 (0.0 ~ 1.0)
static func get_exp_progress(level: int, exp: int) -> float:
	var total_for_level := get_exp_for_level(level)
	var exp_in_level := exp
	# 当前等级已消耗的经验
	var consumed := get_total_exp_for_level(level)
	# 经验条进度
	return clampf(float(exp_in_level) / float(total_for_level), 0.0, 1.0)

# ============================================
# 升级后属性重算
# ============================================
# 升级时属性成长由 MonsterDB.get_monster_stats() 自动处理
# 此函数用于通知系统刷新（如果需要）
static func on_level_up(monster_id: String, new_level: int) -> void:
	# 通知相关系统刷新显示
	# 在 Godot 中通过信号机制处理
	pass

# ============================================
# 获取战力估算
# ============================================
static func calc_power(monster_id: String, level: int) -> int:
	var stats = MonsterDB.get_monster_stats(monster_id, level)
	if stats.is_empty():
		return 0
	return int(stats.get("hp", 0)) + int(stats.get("atk", 0)) + int(stats.get("def", 0)) + int(stats.get("spd", 0))