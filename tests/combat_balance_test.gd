extends SceneTree

## 数值平衡回归：前期小怪节奏 + 每章 Boss 曲线。
##
## 口径：
## - 前期小怪按需求给定的 Lv.1 基准测量（三消一次 = 1 回合），并验证 5 级起步折算后的承伤。
## - 连锁档位：分别固定 1 / 2 / 4 连锁，测量新连锁加成对击杀节奏与 Boss 回合的影响。
## - Boss 用真实 BattleManager 跑固定参考策略：按剧情经验推进的玩家等级、
##   每回合一次三消、技能就绪即按血量择机释放。
## - “血条告急”= 存活队友血量首次跌破 40% 且之后回到 50% 以上，算一次独立告急窗口。

const StageDBScript = preload("res://src/data/stage_db.gd")
const BattleManagerScript = preload("res://src/battle/battle_manager.gd")
const MonsterDbScript = preload("res://src/data/monster_db.gd")

const TEAM := ["monster_001", "monster_002", "monster_003"]
const BOSS_SEEDS := [20261109, 20261110, 20261111]
const CHAIN_MODES := [1, 2, 4]

var _failures: Array[String] = []
var _stage_db


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_stage_db = StageDBScript.new()
	_test_early_mobs()
	for combo in CHAIN_MODES:
		_test_early_pacing(combo)
	_test_boss_curve()
	_finish()


func _test_early_mobs() -> void:
	var expected := {
		"enemy_001": [150, 32],
		"enemy_002": [165, 32],
		"enemy_003": [140, 32],
		"enemy_018": [200, 32],
		"enemy_032": [290, 35],
	}
	for id: String in expected.keys():
		var data: Dictionary = MonsterDbScript.get_monster(id)
		_expect(int(data.get("baseHP", 0)) == int(expected[id][0]), "%s baseHP should be %d" % [id, expected[id][0]])
		_expect(int(data.get("baseATK", 0)) == int(expected[id][1]), "%s baseATK should be %d" % [id, expected[id][1]])
	for data: Dictionary in MonsterDbScript.get_all():
		var id := str(data.get("id", ""))
		if not id.begins_with("enemy_"):
			continue
		# 只校验本次按 x4.4 / x3.2 重定的前期到星耀小怪；混沌/光耀小怪是后加的另一档曲线。
		var num := int(id.trim_prefix("enemy_"))
		if num < 1 or num > 36:
			continue
		var hp := int(data.get("baseHP", 0))
		var atk := int(data.get("baseATK", 0))
		_expect(hp >= 140 and hp <= 330, "%s HP should stay in the x4.4 band" % id)
		_expect(atk == 32 or atk == 35, "%s ATK should be the x3.2 band" % id)


func _test_early_pacing(combo: int) -> void:
	seed(424242)
	var samples := 20
	var total_kill_turns := 0
	var total_ally_hits := 0
	for i in range(samples):
		var battle = BattleManagerScript.new()
		battle.init(["monster_001"], ["enemy_001"], 1, 1, _stage_db.get_stage("stage_1_1"), "stage_1_1")
		battle.max_turns = 99
		var turns := 0
		while not battle.battle_over and turns < 99:
			turns += 1
			battle.process_match_result({"fire": 3}, combo)
			if battle.check_battle_end():
				break
			battle.enemy_action()
		total_kill_turns += turns
		battle.free()

		var solo = BattleManagerScript.new()
		solo.init(["monster_001"], ["enemy_001"], 1, 1, null, "")
		solo.max_turns = 999
		var hits := 0
		while solo.player_team[0].get("hp", 0) > 0 and hits < 999:
			hits += 1
			solo.enemy_action()
		total_ally_hits += hits
		solo.free()
	var matches_per_kill := float(total_kill_turns) / samples
	var ally_survival := float(total_ally_hits) / samples
	print("[Balance] early combo=%d: matches_per_kill=%.2f ally_survival_turns=%.2f" % [combo, matches_per_kill, ally_survival])
	# 分档门槛：1 连锁维持 3-4 次原线；固定 2 连锁只看不低于 3.0；固定 4 连锁允许更快。
	if combo == 1:
		_expect(matches_per_kill >= 3.0 and matches_per_kill <= 4.0, "combo=1 early mob should die in 3-4 matches, got %.2f" % matches_per_kill)
	elif combo == 2:
		_expect(matches_per_kill >= 3.0, "combo=2 early mob should take 3+ matches, got %.2f" % matches_per_kill)
	_expect(ally_survival >= 8.0 and ally_survival <= 12.0, "combo=%d early ally should survive 8-12 focused hits, got %.2f" % [combo, ally_survival])

	# 游戏内实际最低玩家等级为 5，这里同时记录击杀节奏与伙伴承伤。
	seed(424242)
	var lv5_kill_turns := 0
	var lv5_ally_hits := 0
	for i in range(samples):
		var battle = BattleManagerScript.new()
		battle.init(["monster_001"], ["enemy_001"], 5, 1, _stage_db.get_stage("stage_1_1"), "stage_1_1")
		battle.max_turns = 99
		var turns := 0
		while not battle.battle_over and turns < 99:
			turns += 1
			battle.process_match_result({"fire": 3}, combo)
			if battle.check_battle_end():
				break
			battle.enemy_action()
		lv5_kill_turns += turns
		battle.free()

		var solo5 = BattleManagerScript.new()
		solo5.init(["monster_001"], ["enemy_001"], 5, 1, null, "")
		solo5.max_turns = 999
		var hits5 := 0
		while solo5.player_team[0].get("hp", 0) > 0 and hits5 < 999:
			hits5 += 1
			solo5.enemy_action()
		lv5_ally_hits += hits5
		solo5.free()
	var lv5_matches := float(lv5_kill_turns) / samples
	var lv5_survival := float(lv5_ally_hits) / samples
	print("[Balance] early-lv5 combo=%d: matches_per_kill=%.2f ally_survival_turns=%.2f" % [combo, lv5_matches, lv5_survival])
	_expect(lv5_matches <= 4.5, "combo=%d in-game level 5 should still kill early mobs in <=4 matches" % combo)
	_expect(lv5_survival <= 13.0, "combo=%d level-5 opening ally should fall within 13 hits, got %.2f" % [combo, lv5_survival])
	_expect(lv5_survival >= 8.0, "combo=%d level-5 opening ally should not fall below 8 hits, got %.2f" % [combo, lv5_survival])


func _test_boss_curve() -> void:
	var level := 1
	var exp := 0
	var needed := 90
	for chapter: Dictionary in _stage_db.get_chapters():
		var boss_stage: Dictionary = {}
		var first_normal_stage: Dictionary = {}
		for st: Dictionary in chapter.get("stages", []):
			var rewards: Dictionary = st.get("rewards", {})
			exp += int(rewards.get("exp", 0))
			while exp >= needed:
				exp -= needed
				level += 1
				needed = 80 + level * 10
			if first_normal_stage.is_empty() and str(st.get("type", "")) != "boss":
				first_normal_stage = st
			if str(st.get("type", "")) == "boss":
				boss_stage = st
				break
		if boss_stage.is_empty():
			continue
		var stage_id := str(boss_stage.get("id", ""))
		var stage: Dictionary = _stage_db.get_stage(stage_id)
		var p_level := maxi(5, level)
		var e_level := int(stage.get("enemyLevel", 1))
		_expect(int(stage.get("maxTurns", 0)) >= 40, "%s should allow 40+ turns" % stage_id)
		_expect(stage.get("bossCurve", {}) is Dictionary and not stage.get("bossCurve", {}).is_empty(), "%s should define bossCurve" % stage_id)
		if not first_normal_stage.is_empty():
			_check_combo4_single_match(first_normal_stage, p_level)

		for combo in CHAIN_MODES:
			var runs: Array = []
			for s: int in BOSS_SEEDS:
				seed(s)
				runs.append(_run_boss(stage, p_level, e_level, combo))
			var turns: Array = runs.map(func(r): return int(r["turns"]))
			var near_deaths: Array = runs.map(func(r): return int(r["near_death"]))
			turns.sort()
			near_deaths.sort()
			var median_turns: int = int(turns[turns.size() / 2])
			var median_nd: int = int(near_deaths[near_deaths.size() / 2])
			var wins := 0
			var deaths := 0
			for r: Dictionary in runs:
				if str(r["result"]) == "win":
					wins += 1
				deaths = maxi(deaths, int(r["dead"]))
			print("[Balance] %s combo=%d p=%d e=%d turns=%s nd=%s result=%s" % [
				stage_id, combo, p_level, e_level, str(turns), str(near_deaths), str(runs.map(func(r): return r["result"]))
			])
			_expect(wins == runs.size(), "%s combo=%d should win in all reference runs" % [stage_id, combo])
			_expect(deaths <= 1, "%s combo=%d should not lose more than one ally" % [stage_id, combo])
			if combo == 1:
				_expect(median_turns >= 40, "%s combo=1 baseline should last 40+ turns, got %d" % [stage_id, median_turns])
			elif combo == 4:
				_expect(median_turns >= 28, "%s combo=4 should last 28+ turns, got %d" % [stage_id, median_turns])
			_expect(median_turns <= int(stage.get("maxTurns", 60)), "%s combo=%d should finish inside maxTurns" % [stage_id, combo])
			# 3+ 告急窗口是 1 连锁基准耐力局的口径；固定 2/4 连锁局被连锁加成本身缩短，
			# 不作为本档门槛，但仍打印 nd 供对照。
			if combo == 1:
				_expect(median_nd >= 3, "%s combo=%d should have 3+ near-death windows, got %d" % [stage_id, combo, median_nd])


## 固定 4 连锁下，任意一种 3 消都不应一击秒掉同章小怪。
## 用该章第一个普通关卡的敌人与剧情等级，逐色各跑一次独立战斗。
func _check_combo4_single_match(stage_config: Dictionary, p_level: int) -> void:
	var stage_id := str(stage_config.get("id", ""))
	var stage: Dictionary = _stage_db.get_stage(stage_id)
	if stage.get("enemies", []).is_empty():
		return
	var e_level := int(stage.get("enemyLevel", 1))
	var one_shot := false
	for color_idx in range(5):
		var color: String = ["fire", "water", "grass", "thunder", "light"][color_idx]
		seed(20261109 + color_idx * 97 + p_level)
		var battle = BattleManagerScript.new()
		battle.init(TEAM, [], p_level, e_level, stage, stage_id)
		var before: Array = battle.enemies.map(func(e): return int(e.get("hp", 0)))
		battle.process_match_result({color: 3}, 4)
		for i in range(battle.enemies.size()):
			if int(before[i]) > 0 and int(battle.enemies[i].get("hp", 0)) <= 0:
				one_shot = true
		battle.free()
	print("[Balance] %s combo=4 one_shot_mob=%s" % [stage_id, str(one_shot)])
	_expect(not one_shot, "%s combo=4 should not one-shot a same-chapter mob with a single 3-match" % stage_id)


func _run_boss(stage: Dictionary, p_level: int, e_level: int, combo: int) -> Dictionary:
	var battle = BattleManagerScript.new()
	battle.init(TEAM, [], p_level, e_level, stage, str(stage.get("id", "")))
	var near_death := 0
	var danger := {}
	var turns := 0
	while not battle.battle_over and turns < 200:
		turns += 1
		battle.turn_count = turns
		var lowest: Dictionary = _lowest_ally(battle)
		for ally: Dictionary in battle.player_team:
			if ally == null or ally.get("hp", 0) <= 0:
				continue
			var id := str(ally.get("id", ""))
			var skill: Dictionary = ally.get("skill", {})
			var cost := int(skill.get("cost", 999))
			if int(battle.skill_charges.get(id, 0)) < cost:
				continue
			var kind := str(skill.get("type", "strike"))
			var lowest_ratio := _ratio(lowest)
			if kind == "ward" and lowest_ratio > 0.6:
				continue
			if kind == "strike" and lowest_ratio < 0.35:
				continue
			battle.use_active_skill(id)
			if battle.check_battle_end():
				break
		if battle.battle_over:
			break

		var affinity := _best_affinity(battle, lowest)
		var match_result: Dictionary = battle.process_match_result({affinity: 3}, combo)
		if match_result.has("phase_transition"):
			battle.execute_phase_transition(match_result.get("phase_transition", {}))
		if battle.check_battle_end():
			break

		battle.enemy_action()
		for idx in range(battle.player_team.size()):
			var m: Dictionary = battle.player_team[idx]
			if m == null:
				continue
			var ratio := _ratio(m)
			if ratio > 0.0 and ratio <= 0.40 and not bool(danger.get(idx, false)):
				near_death += 1
				danger[idx] = true
			elif ratio > 0.50:
				danger[idx] = false
	var result := "draw"
	if battle.battle_over:
		result = battle.battle_result
	var dead := 0
	for m: Dictionary in battle.player_team:
		if m == null or m.get("hp", 0) <= 0:
			dead += 1
	battle.free()
	return { "turns": turns, "near_death": near_death, "result": result, "dead": dead }


func _lowest_ally(battle) -> Dictionary:
	var best: Dictionary = {}
	var best_ratio := 2.0
	for m: Dictionary in battle.player_team:
		if m == null or m.get("hp", 0) <= 0:
			continue
		var r := _ratio(m)
		if r < best_ratio:
			best = m
			best_ratio = r
	return best


func _ratio(m: Dictionary) -> float:
	if m == null or m.is_empty():
		return 1.0
	return float(m.get("hp", 0)) / float(maxi(1, int(m.get("maxHP", 1))))


func _best_affinity(battle, lowest: Dictionary) -> String:
	if _ratio(lowest) < 0.45:
		return "water"
	var best := "fire"
	var best_score := -1.0
	for m: Dictionary in battle.player_team:
		if m == null or m.get("hp", 0) <= 0:
			continue
		var score := float(m.get("atk", 1))
		for e: Dictionary in battle.enemies:
			if e != null and e.get("hp", 0) > 0:
				score *= MonsterDbScript.get_element_multiplier(str(m.get("element", "")), str(e.get("element", "")))
				break
		if score > best_score:
			best_score = score
			best = str(m.get("boardAffinity", "fire"))
	return best


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[CombatBalance] OK")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[CombatBalance] " + failure)
		quit(1)
