extends SceneTree

const BattleManagerScript = preload("res://src/battle/battle_manager.gd")
const PhaseHandlerScript = preload("res://src/battle/phase_handler.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var bm := BattleManagerScript.new()
	add_root(bm)
	bm.init(["monster_001"], ["enemy_003", "enemy_001"], 5, 5)
	var enemies: Array = bm.get_enemies()
	assert(bool(enemies[0].get("isElite", false)) == true, "template elite enemy should expose isElite in battle")
	assert(bool(enemies[1].get("isElite", false)) == false, "normal enemy should not expose isElite without a roll")
	assert(float(enemies[0].get("_visualScale", 1.0)) > 1.0, "template elite enemy should receive elite visual scale")
	bm.queue_free()

	var bm_random := BattleManagerScript.new()
	add_root(bm_random)
	bm_random.init(["monster_001"], ["enemy_001"], 5, 5, {
		"id": "random_elite_test",
		"enemies": ["enemy_001"],
		"enemyLevel": 5,
		"randomEliteChance": 1.0
	}, "random_elite_test")
	var random_enemy: Dictionary = bm_random.get_enemies()[0]
	assert(bool(random_enemy.get("isElite", false)) == true, "randomEliteChance=1 should promote a normal enemy")
	assert(str(random_enemy.get("_eliteSource", "")) == "random", "random elite should mark its source")
	bm_random.queue_free()

	var bm_disabled := BattleManagerScript.new()
	add_root(bm_disabled)
	bm_disabled.init(["monster_001"], ["enemy_001"], 5, 5, {
		"id": "random_elite_disabled_test",
		"enemies": ["enemy_001"],
		"enemyLevel": 5,
		"randomEliteChance": 1.0,
		"disableRandomElite": true
	}, "random_elite_disabled_test")
	var disabled_enemy: Dictionary = bm_disabled.get_enemies()[0]
	assert(bool(disabled_enemy.get("isElite", false)) == false, "disableRandomElite should block random promotion")
	bm_disabled.queue_free()

	var ph := PhaseHandlerScript.new(null)
	var new_enemies := ph.execute_phase_transition({
		"phase": 2,
		"trigger": "on_enter",
		"hpMultiplier": 1.3,
		"enemies": ["enemy_003", "enemy_001"],
		"randomEliteChance": 1.0
	}, 5, 0.5)
	assert(bool(new_enemies[0].get("isElite", false)) == true, "phase transition should preserve elite marker")
	assert(float(new_enemies[0].get("_visualScale", 1.0)) == 1.5, "phase 2 scale should override elite scale")

	print("[BattleEliteVisible] OK")
	quit(0)

func add_root(node: Node) -> void:
	get_root().add_child(node)
