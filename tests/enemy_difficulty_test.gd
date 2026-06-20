extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_assert(StatCalculator.enemy_combat_level("enemy_001", 10) == 15, "ordinary enemy should gain five levels")
	_assert(StatCalculator.enemy_combat_level("monster_boss_001", 10) == 10, "boss should keep its stage level")
	_assert(StatCalculator.enemy_combat_level("enemy_001", StatCalculator.MAX_LEVEL) == StatCalculator.MAX_LEVEL, "enemy level bonus should respect the level cap")

	var boosted := StatCalculator.apply_enemy_difficulty({"hp": 100, "maxHP": 100, "atk": 100})
	_assert(int(boosted.get("hp", 0)) == 200 and int(boosted.get("maxHP", 0)) == 200, "enemy HP should use the two-hundred-percent multiplier")
	_assert(int(boosted.get("atk", 0)) == 200, "enemy attack should use the two-hundred-percent multiplier")

	var ordinary := StatCalculator.calc_enemy("enemy_001", 10)
	var boss := StatCalculator.calc_enemy("monster_boss_001", 10)
	_assert(int(ordinary.get("level", 0)) == 15, "runtime ordinary enemy should use the boosted level")
	_assert(int(boss.get("level", 0)) == 10, "runtime boss should not receive the ordinary level bonus")

	var player_base := StatCalculator.calc("monster_001", 10, "")
	var player_tier := StatCalculator.calc_with_tier("monster_001", 10, "", StatCalculator.EnemyTier.NORMAL)
	_assert(int(player_tier.get("level", 0)) == 10, "captured player monster level should remain unchanged")
	_assert(int(player_tier.get("hp", 0)) == int(player_base.get("hp", 0)) * 2, "captured player tier should not receive global enemy HP scaling")
	_assert(int(player_tier.get("atk", 0)) == int(player_base.get("atk", 0)), "captured player tier should not receive global enemy attack scaling")

	if _failures.is_empty():
		print("[EnemyDifficulty] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[EnemyDifficulty] " + failure)
	quit(1)

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failures.append(message)
