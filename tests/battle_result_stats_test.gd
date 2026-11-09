extends SceneTree

## 战斗结算页回归：
## 1. 真实战斗里，结算结果的「总伤害 = 各伙伴伤害之和」，并与 damage_dealt 战斗日志逐条对得上；
## 2. 各伙伴承伤与 enemy_attacked 战斗日志对得上；
## 3. 结算页展示总伤害、每伙伴伤害/承伤、金币经验、回合数、最高连锁；
## 4. 失败只给「重打」，胜利才给「下一关」。

const BattleManagerScript = preload("res://src/battle/battle_manager.gd")
const StageDBScript = preload("res://src/data/stage_db.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_real_battle_stats()
	_test_result_screen_win()
	_test_result_screen_loss()
	_finish()


func _test_real_battle_stats() -> void:
	seed(20261109)
	var stage_db := StageDBScript.new()
	var stage: Dictionary = stage_db.get_stage("stage_1_1")
	var battle = BattleManagerScript.new()
	battle.init(["monster_001", "monster_002", "monster_003"], ["enemy_001"], 5, 1, stage, "stage_1_1")
	# 拉长这一场真实战斗，确保至少经历数次敌方回合，承伤统计不是全 0。
	battle.enemies[0]["maxHP"] = 900
	battle.enemies[0]["hp"] = 900
	battle.max_turns = 50

	var dealt_log: Dictionary = {}
	var taken_log: Dictionary = {}
	battle.damage_dealt.connect(func(info: Dictionary):
		var attacker_id := str(info.get("attacker_id", info.get("attackerId", "")))
		if attacker_id.is_empty():
			attacker_id = str(info.get("attacker", ""))
		dealt_log[attacker_id] = int(dealt_log.get(attacker_id, 0)) + int(info.get("damage", 0))
	)
	battle.enemy_attacked.connect(func(action: Dictionary):
		var target_index := int(action.get("target_index", -1))
		var damage := int(action.get("damage", 0))
		if target_index >= 0 and damage > 0:
			taken_log[target_index] = int(taken_log.get(target_index, 0)) + damage
	)

	var combos: Array = [4, 3, 2, 1]
	var turns := 0
	while not battle.battle_over and turns < 20:
		turns += 1
		battle.turn_count = turns
		battle.process_match_result({"fire": 3, "water": 3, "grass": 3}, int(combos[(turns - 1) % combos.size()]))
		if battle.check_battle_end():
			break
		battle.enemy_action()

	var result: Dictionary = battle.get_battle_result()
	_expect(str(result.get("result", "")) == "win", "real stage_1_1 battle should end in a win")
	_expect(int(result.get("maxCombo", 0)) == 4, "battle result should keep the highest chain tier, got %d" % int(result.get("maxCombo", 0)))

	var ally_stats: Array = result.get("allyStats", [])
	_expect(ally_stats.size() == 3, "battle result should carry one stat row per ally")
	var per_ally_total := 0
	var per_ally_taken := 0
	var log_dealt_total := 0
	var log_taken_total := 0
	for value in dealt_log.values():
		log_dealt_total += int(value)
	for value in taken_log.values():
		log_taken_total += int(value)
	for i in range(ally_stats.size()):
		var stat: Dictionary = ally_stats[i]
		var monster_id := str(stat.get("id", ""))
		var dealt := int(stat.get("damageDealt", 0))
		var taken := int(stat.get("damageTaken", 0))
		per_ally_total += dealt
		per_ally_taken += taken
		_expect(dealt == int(dealt_log.get(monster_id, 0)), "ally %s damage should match the battle log" % monster_id)
		_expect(taken == int(taken_log.get(i, 0)), "ally %s damage taken should match the battle log" % monster_id)
	_expect(per_ally_total == log_dealt_total, "sum over allies should equal the damage log total")
	_expect(per_ally_taken == log_taken_total, "sum over allies should equal the damage-taken log total")
	_expect(int(result.get("totalDamage", -1)) == per_ally_total, "total damage should equal the sum over allies")
	_expect(int(result.get("totalDamage", -1)) == log_dealt_total, "total damage should match the battle log")
	_expect(int(result.get("totalDamageTaken", -1)) == per_ally_taken, "total damage taken should equal the sum over allies")
	_expect(int(result.get("totalDamageTaken", 0)) > 0, "real battle should record some damage taken")
	var dealt_map_total := 0
	for value in result.get("totalDamageDealt", {}).values():
		dealt_map_total += int(value)
	_expect(dealt_map_total == int(result.get("totalDamage", -1)), "legacy damage map should stay consistent with total damage")
	battle.free()


func _test_result_screen_win() -> void:
	var screen: Control = load("res://src/ui/scenes/battle_result.tscn").instantiate()
	root.add_child(screen)
	screen.init(_result_payload("win"))
	screen.call("_sync_gui")
	_expect(_label(screen, "StatsPanel/TotalDamage/Value") == "2830", "win screen should show the battle total damage")
	_expect(_label(screen, "StatsPanel/Turns/Value") == "7 / 20", "win screen should show turns played")
	_expect(_label(screen, "StatsPanel/MaxChain/Value") == "4 连锁", "win screen should show the highest chain tier")
	_expect(_label(screen, "StatsPanel/BreakCount/Value") == "3 次", "win screen should show the battle break count")
	_expect(_label(screen, "StatsPanel/TeamRows/Row1/Dealt") == "1240", "win screen should show per-ally damage dealt")
	_expect(_label(screen, "StatsPanel/TeamRows/Row1/Taken") == "310", "win screen should show per-ally damage taken")
	_expect((screen.get_node("Buttons/NextButton") as Control).visible, "win screen should offer the next stage")
	_expect((screen.get_node("Buttons/RetryButton") as Control).visible, "win screen should keep the retry entry")
	_expect(_label(screen, "Buttons/RetryButton/Text") == "再来一次", "win retry button should read 再来一次")
	_expect((screen.get_node("Buttons/BackButton") as Control).visible, "win screen should keep the back entry")
	screen.queue_free()


func _test_result_screen_loss() -> void:
	var screen: Control = load("res://src/ui/scenes/battle_result.tscn").instantiate()
	root.add_child(screen)
	screen.init(_result_payload("lose"))
	screen.call("_sync_gui")
	_expect(_label(screen, "StatsPanel/TotalDamage/Value") == "2830", "loss screen should show the battle total damage")
	_expect(_label(screen, "StatsPanel/Turns/Value") == "9 / 20", "loss screen should show turns played")
	_expect(_label(screen, "StatsPanel/MaxChain/Value") == "3 连锁", "loss screen should show the highest chain tier")
	_expect(_label(screen, "StatsPanel/BreakCount/Value") == "1 次", "loss screen should show the battle break count")
	_expect(not (screen.get_node("Buttons/NextButton") as Control).visible, "loss screen must not offer the next stage")
	_expect(not (screen.get_node("Buttons/BackButton") as Control).visible, "loss screen should only expose retry")
	_expect((screen.get_node("Buttons/RetryButton") as Control).visible, "loss screen should offer retry")
	_expect(_label(screen, "Buttons/RetryButton/Text") == "重打", "loss retry button should read 重打")
	_expect(not (screen.get_node("CaptureResultPanel") as Control).visible, "loss screen should not show a capture result")
	screen.queue_free()


func _result_payload(mode: String) -> Dictionary:
	var is_win := mode == "win"
	return {
		"result": "win" if is_win else "lose",
		"stageId": "stage_1_1",
		"turnCount": 7 if is_win else 9,
		"maxTurns": 20,
		"playerLevel": 5,
		"enemyLevel": 3,
		"stageRewards": {"gold": 45, "exp": 45, "guaranteedItems": [{"id": "capture_ball", "count": 1}]},
		"totalDamage": 2830,
		"totalDamageTaken": 805,
		"maxCombo": 4 if is_win else 3,
		"highestChain": 4 if is_win else 3,
		"breakCount": 3 if is_win else 1,
		"break_count": 3 if is_win else 1,
		"allyStats": [
			{"id": "monster_001", "monsterId": "monster_001", "name": "小火龙", "level": 5, "damageDealt": 1240, "damageTaken": 310},
			{"id": "monster_002", "monsterId": "monster_002", "name": "水龟仔", "level": 4, "damageDealt": 860, "damageTaken": 270},
			{"id": "monster_003", "monsterId": "monster_003", "name": "草苗儿", "level": 5, "damageDealt": 730, "damageTaken": 225},
		],
		"totalDamageDealt": {"monster_001": 1240, "monster_002": 860, "monster_003": 730},
		"playerTeam": [
			{"id": "monster_001", "monsterId": "monster_001", "name": "小火龙", "level": 5, "hp": 210, "maxHP": 520},
			{"id": "monster_002", "monsterId": "monster_002", "name": "水龟仔", "level": 4, "hp": 160, "maxHP": 430},
			{"id": "monster_003", "monsterId": "monster_003", "name": "草苗儿", "level": 5, "hp": 185, "maxHP": 410},
		],
		"enemies": [
			{"id": "enemy_001", "monsterId": "enemy_001", "name": "野火虫", "hp": 0 if is_win else 180, "maxHP": 300}
		],
		"capture_played_inline": is_win,
		"captured": is_win,
		"capture_target": {"id": "enemy_001", "monsterId": "enemy_001", "name": "野火虫", "rarity": 1},
		"capture_result_text": {"title": "收服成功", "reason": "窗口稳定"} if is_win else {},
		"capture_item_used": {"name": "捕捉球"} if is_win else {},
		"capture_window": {"label": "稳定", "stability": 0.82} if is_win else {},
	}


func _label(screen: Control, path: String) -> String:
	return (screen.get_node(path) as Label).text


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[BattleResultStats] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[BattleResultStats] " + failure)
	quit(1)
