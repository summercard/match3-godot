extends SceneTree

## 数值体系回归测试
##
## 覆盖三件事：
## 1. 属性克制只有 MonsterDb.ELEMENT_CHART 一个公式源，玩家和敌方共用 1.5x / 0.75x。
## 2. 敌方等级成长有封顶，后期 Boss 不会因稀有度成长而无限膨胀。
## 3. 关键关卡在固定随机种子下仍落在设计包线内：Ch1 普通关 2-4 回合、
##    Ch1 Boss 6-10 回合、中后期 Boss 8-15 回合且可通关。

const StageDBScript = preload("res://src/data/stage_db.gd")
const MonsterDbScript = preload("res://src/data/monster_db.gd")
const DamageCalcScript = preload("res://src/battle/damage_calculator.gd")
const BattleManagerScript = preload("res://src/battle/battle_manager.gd")
const RewardRulesScript = preload("res://src/battle/reward_rules.gd")

const TEAM_IDS := ["monster_001", "monster_002", "monster_003"]
const RUNS := 8

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_single_element_source()
	_test_enemy_level_caps()
	_test_elite_multiplier_applied_once()
	_test_boss_rewards_at_least_elite()
	_test_key_stage_pacing()
	_finish()


# ========== 1. 属性克制唯一公式源 ==========

func _test_single_element_source() -> void:
	var calc_script: GDScript = load("res://src/battle/damage_calculator.gd")
	var constants: Dictionary = calc_script.get_script_constant_map()
	_expect(not constants.has("ELEMENT_CHART"), "DamageCalculator should not keep a second element chart")

	_expect(DamageCalcScript.get_element_multiplier("fire", "grass") == 1.5, "player fire should hit grass at 1.5x")
	_expect(DamageCalcScript.get_element_multiplier("fire", "water") == 0.75, "player fire should hit water at 0.75x")
	_expect(DamageCalcScript.get_element_multiplier("dark", "light") == 1.5, "enemy dark should use the shared chart against light")
	_expect(DamageCalcScript.get_element_multiplier("earth", "wind") == 1.5, "enemy earth should use the shared chart against wind")
	_expect(DamageCalcScript.get_element_multiplier("chaos", "light") == 0.75, "chaos should keep its designed weakness")

	for monster: Dictionary in MonsterDbScript.get_all():
		var element := str(monster.get("element", ""))
		_expect(MonsterDbScript.ELEMENT_CHART.has(element), "element %s should have a chart entry" % element)


# ========== 2. 敌方等级成长封顶 ==========

func _test_enemy_level_caps() -> void:
	var boss := MonsterDbScript.get_monster_stats("monster_boss_011", 50, "", true)
	var boss_template := MonsterDbScript.get_monster("monster_boss_011")
	var boss_cap: float = MonsterDbScript.ENEMY_BOSS_MAX_LEVEL_MULT
	_expect(int(boss.get("maxHP", 0)) <= int(float(boss_template.get("baseHP", 0)) * boss_cap) + 1, "boss hp should respect the boss level cap")
	_expect(int(boss.get("def", 0)) <= int(float(boss_template.get("baseDEF", 0)) * boss_cap) + 1, "boss def should respect the boss level cap")

	var enemy := MonsterDbScript.get_monster_stats("enemy_046", 50, "", true)
	var enemy_template := MonsterDbScript.get_monster("enemy_046")
	var enemy_cap: float = MonsterDbScript.ENEMY_NORMAL_MAX_LEVEL_MULT
	_expect(int(enemy.get("maxHP", 0)) <= int(float(enemy_template.get("baseHP", 0)) * enemy_cap) + 1, "normal enemy hp should respect the normal level cap")

	var player := MonsterDbScript.get_monster_stats("monster_001", 50)
	var player_template := MonsterDbScript.get_monster("monster_001")
	_expect(int(player.get("maxHP", 0)) > int(float(player_template.get("baseHP", 0)) * 3.0), "playable monsters should keep uncapped growth")

	# 被捕获的敌人进入队伍后按可玩怪物口径成长，不再套用敌方封顶。
	var captured := MonsterDbScript.get_monster_stats("enemy_003", 50)
	var captured_template := MonsterDbScript.get_monster("enemy_003")
	_expect(int(captured.get("maxHP", 0)) > int(float(captured_template.get("baseHP", 0)) * enemy_cap) + 1, "captured enemies should use playable growth after joining the team")


# ========== 3. 精英加成只在战斗初始化应用一次 ==========

func _test_elite_multiplier_applied_once() -> void:
	var stage_db = StageDBScript.new()
	var stage: Dictionary = stage_db.get_stage("stage_2_4e")
	var battle = BattleManagerScript.new()
	battle.init(TEAM_IDS, stage.get("enemies", []), 6, int(stage.get("enemyLevel", 1)), stage, "stage_2_4e")
	var enemy: Dictionary = battle.enemies[0]
	var base_stats: Dictionary = MonsterDbScript.get_monster_stats("enemy_003", int(stage.get("enemyLevel", 1)), "", true)
	var expected_hp := int(float(base_stats.get("maxHP", 0)) * float(stage.get("eliteMultiplier", 1.0)))
	_expect(int(enemy.get("maxHP", 0)) == expected_hp, "elite multiplier should be applied by BattleManager exactly once")
	battle.free()


# ========== 4. Boss 奖励不低于同章精英 ==========

func _test_boss_rewards_at_least_elite() -> void:
	var stage_db = StageDBScript.new()
	for chapter: Dictionary in stage_db.get_chapters():
		var elite_rewards := {"gold": 0, "exp": 0}
		var boss_rewards := {"gold": 0, "exp": 0}
		for stage: Dictionary in chapter.get("stages", []):
			var rewards: Dictionary = stage.get("rewards", {})
			if str(stage.get("type", "")) == "elite":
				elite_rewards["gold"] = maxi(int(elite_rewards["gold"]), int(rewards.get("gold", 0)))
				elite_rewards["exp"] = maxi(int(elite_rewards["exp"]), int(rewards.get("exp", 0)))
			elif str(stage.get("type", "")) == "boss":
				boss_rewards["gold"] = maxi(int(boss_rewards["gold"]), int(rewards.get("gold", 0)))
				boss_rewards["exp"] = maxi(int(boss_rewards["exp"]), int(rewards.get("exp", 0)))
		_expect(boss_rewards["gold"] >= elite_rewards["gold"], "%s boss gold should not be below the chapter elite" % chapter.get("id", ""))
		_expect(boss_rewards["exp"] >= elite_rewards["exp"], "%s boss exp should not be below the chapter elite" % chapter.get("id", ""))


# ========== 5. 关键关卡节奏 ==========

func _test_key_stage_pacing() -> void:
	var stage_db = StageDBScript.new()
	var chapter_targets := {
		"stage_1_3": {"type": "normal", "turns": Vector2(2, 4), "min_wins": RUNS - 1, "seed": 1100},
		"stage_1_5": {"type": "boss", "turns": Vector2(6, 10), "min_wins": RUNS - 1, "seed": 1200},
		"stage_2_5": {"type": "boss", "turns": Vector2(8, 14), "min_wins": RUNS - 1, "seed": 1300},
		"stage_5_5": {"type": "boss", "turns": Vector2(8, 14), "min_wins": RUNS - 2, "seed": 1400},
		"stage_11_5": {"type": "boss", "turns": Vector2(8, 15), "min_wins": RUNS - 2, "seed": 1500},
	}
	var team_exp := 0
	for chapter: Dictionary in stage_db.get_chapters():
		for stage: Dictionary in chapter.get("stages", []):
			var stage_id := str(stage.get("id", ""))
			if chapter_targets.has(stage_id):
				var target: Dictionary = chapter_targets[stage_id]
				var level := _level_from_exp(team_exp)
				var summary := _simulate_stage(stage, level, int(target.get("seed", 1000)))
				var label := "%s %s" % [stage_id, target["type"]]
				_expect(summary["wins"] >= int(target["min_wins"]), "%s should be winnable (%d/%d)" % [label, summary["wins"], RUNS])
				_expect(summary["avg_turns"] >= target["turns"].x, "%s average turns %.1f should be >= %.0f" % [label, summary["avg_turns"], target["turns"].x])
				_expect(summary["avg_turns"] <= target["turns"].y, "%s average turns %.1f should be <= %.0f" % [label, summary["avg_turns"], target["turns"].y])
			team_exp += int(stage.get("rewards", {}).get("exp", 0))

	# 所有 Boss 至少要被验证为可通关，防止再次出现数学上打不过的墙。
	var boss_index := 0
	for chapter: Dictionary in stage_db.get_chapters():
		for stage: Dictionary in chapter.get("stages", []):
			if str(stage.get("type", "")) != "boss":
				continue
			var level := _level_from_exp(_total_exp_before(stage_db, str(stage.get("id", ""))))
			var summary := _simulate_stage(stage, level, 2000 + boss_index * 37)
			boss_index += 1
			_expect(summary["wins"] >= RUNS / 2, "%s boss should be reliably winnable (%d/%d)" % [stage.get("id", ""), summary["wins"], RUNS])


func _total_exp_before(stage_db, stage_id: String) -> int:
	var total := 0
	for chapter: Dictionary in stage_db.get_chapters():
		for stage: Dictionary in chapter.get("stages", []):
			if str(stage.get("id", "")) == stage_id:
				return total
			total += int(stage.get("rewards", {}).get("exp", 0))
	return total


func _level_from_exp(total_exp: int) -> int:
	var level := 1
	var remaining := total_exp
	while remaining >= 80 + level * 10:
		remaining -= 80 + level * 10
		level += 1
	return level


func _simulate_stage(stage: Dictionary, team_level: int, seed_value: int) -> Dictionary:
	var wins := 0
	var turns_sum := 0
	for i in range(RUNS):
		var result := _simulate_once(stage, team_level, seed_value + i * 31)
		if bool(result["win"]):
			wins += 1
		turns_sum += int(result["turns"])
	return {"wins": wins, "avg_turns": float(turns_sum) / float(RUNS)}


func _simulate_once(stage: Dictionary, team_level: int, seed_value: int) -> Dictionary:
	seed(seed_value)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var battle = BattleManagerScript.new()
	var enemy_ids: Array = stage.get("enemies", [])
	if stage.has("phases") and stage.get("phases", []).size() > 0:
		enemy_ids = stage.get("phases")[0].get("enemies", [])
	battle.init(TEAM_IDS, enemy_ids, team_level, int(stage.get("enemyLevel", 1)), stage, str(stage.get("id", "")))
	var max_turns := int(battle.max_turns)
	var guard := 0
	while not battle.battle_over and guard < max_turns + 3:
		guard += 1
		var counts := _simulated_gem_counts(battle.player_team, rng)
		var result: Dictionary = battle.process_match_result(counts, 1)
		var phase: Dictionary = result.get("phase_transition", {})
		if not phase.is_empty():
			battle.execute_phase_transition(phase)
		for member in battle.player_team:
			if member.get("hp", 0) <= 0:
				continue
			var member_id := str(member.get("id", ""))
			var cost := int(member.get("skill", {}).get("cost", 999))
			while int(battle.skill_charges.get(member_id, 0)) >= cost:
				var skill_result: Dictionary = battle.use_active_skill(member_id)
				if not skill_result.get("success", false):
					break
		battle.turn_count += 1
		if battle.check_battle_end():
			break
		battle.enemy_action()
		if battle.battle_over:
			break
	var out := {
		"win": battle.battle_result == "win",
		"turns": battle.turn_count,
	}
	battle.free()
	return out


## 模拟一个“普通玩家回合”：优先消队伍亲和色，偶尔带出第二色。
## 不模拟特殊宝石和连锁，作为偏保守的下限基准。
func _simulated_gem_counts(team: Array, rng: RandomNumberGenerator) -> Dictionary:
	var colors := ["fire", "water", "grass", "thunder", "light"]
	var team_colors: Array = []
	for member in team:
		var affinity := str(member.get("boardAffinity", ""))
		if not team_colors.has(affinity):
			team_colors.append(affinity)
	if team_colors.is_empty():
		team_colors.append("fire")
	var counts := {}
	var primary := str(team_colors[rng.randi_range(0, team_colors.size() - 1)])
	counts[primary] = rng.randi_range(3, 4)
	if rng.randf() < 0.25:
		var secondary := str(colors[rng.randi_range(0, colors.size() - 1)])
		counts[secondary] = counts.get(secondary, 0) + rng.randi_range(1, 2)
	return counts


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[NumberBalance] OK")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[NumberBalance] " + failure)
		quit(1)
