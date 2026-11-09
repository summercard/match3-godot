extends SceneTree

## 波次入场规则：首波 1 只、在场最多 3 只、清空后由界面补下一波

const BattleManagerScript = preload("res://src/battle/battle_manager.gd")
const StageDBScript = preload("res://src/data/stage_db.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage_db := StageDBScript.new()

	# stage_3_2 有 3 个敌人：首波 1 只，第二波 2 只
	var battle = BattleManagerScript.new()
	var stage_enemies: Array = stage_db.get_stage("stage_3_2").get("enemies", [])
	battle.init(["monster_001", "monster_002", "monster_003"], stage_enemies, 5, 8, stage_db.get_stage("stage_3_2"), "stage_3_2")
	_expect(battle.wave_index == 1, "battle should start on wave 1")
	_expect(battle.wave_total == 2, "three enemies should split into two waves")
	_expect(battle.enemies.size() == 1, "first wave should only contain one enemy")
	_expect(battle.has_next_wave(), "battle should report a pending next wave")

	for enemy: Dictionary in battle.enemies:
		enemy["hp"] = 0
	_expect(not battle.check_battle_end(), "battle should not end while more waves are pending")
	_expect(battle.wave_transition_pending, "clearing a wave should mark a pending wave transition")
	_expect(not battle.battle_over, "clearing a non-final wave should not finish the battle")

	var next_enemies: Array = battle.start_next_wave()
	_expect(battle.wave_index == 2, "starting the next wave should advance the wave index")
	_expect(next_enemies.size() == 2, "the second wave should bring the remaining two enemies")
	_expect(battle.enemies.size() <= BattleManagerScript.WAVE_MAX_ON_FIELD, "on-field enemies should never exceed 3")
	_expect(not battle.wave_transition_pending, "starting the next wave should clear the transition flag")
	_expect(battle.get_status().get("wave_index", 0) == 2, "battle status should expose the current wave")

	for enemy: Dictionary in battle.enemies:
		enemy["hp"] = 0
	_expect(battle.check_battle_end(), "battle should end when the final wave is cleared")
	_expect(battle.battle_over and battle.battle_result == "win", "clearing all waves should win the battle")
	_expect(battle.get_battle_result().get("enemies", []).size() == 3, "battle result should keep all waves for the result screen")
	battle.free()

	# 合成 7 个敌人：波次应为 1 / 3 / 3，且每波不超过 3 只
	var many = BattleManagerScript.new()
	var enemy_ids: Array = []
	for i in range(7):
		enemy_ids.append("enemy_001")
	many.init(["monster_001"], enemy_ids, 5, 3)
	_expect(many.wave_total == 3, "seven enemies should split into three waves")
	var wave_sizes: Array = [many.enemies.size()]
	while many.has_next_wave():
		var wave: Array = many.start_next_wave()
		_expect(wave.size() <= BattleManagerScript.WAVE_MAX_ON_FIELD, "each wave should stay within the 3-enemy cap")
		wave_sizes.append(wave.size())
	_expect(wave_sizes == [1, 3, 3], "waves should be split as 1 / 3 / 3")
	many.free()

	# 精英倍率对首波与后续波次都应生效
	var elite_stage: Dictionary = stage_db.get_stage("stage_4_3e")
	var elite_ids: Array = elite_stage.get("enemies", [])
	var elite = BattleManagerScript.new()
	elite.init(["monster_001"], elite_ids, 5, 15, elite_stage, "stage_4_3e")
	var base_atk: int = int(MonsterDb.get_monster_stats(elite_ids[0], 15).get("atk", 0))
	var elite_atk: int = int(base_atk * float(elite_stage.get("eliteMultiplier", 1.0)))
	_expect(int(elite.enemies[0].get("atk", 0)) == elite_atk, "elite multiplier should apply to the first wave")
	elite.start_next_wave()
	_expect(int(elite.enemies[0].get("atk", 0)) == elite_atk, "elite multiplier should apply to later waves")
	elite.free()

	# Boss 关沿用阶段切换，不做波次切分
	var boss = BattleManagerScript.new()
	boss.init(["monster_001"], [], 5, 3, stage_db.get_stage("stage_1_5"), "stage_1_5")
	_expect(boss.wave_total == 1, "boss battle should keep a single wave")
	_expect(not boss.has_next_wave(), "boss battle should not queue extra waves")
	boss.free()

	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[WaveEntry] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[WaveEntry] " + failure)
	quit(1)
