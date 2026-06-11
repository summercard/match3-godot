extends SceneTree

# Verify enemies in battle expose isElite to renderer

const BattleManagerScript = preload("res://src/battle/battle_manager.gd")
const PhaseHandlerScript = preload("res://src/battle/phase_handler.gd")

func _init() -> void:
	print("=".repeat(70))
	print("Battle 渲染层 isElite 可见性验证")
	print("=".repeat(70))

	# 1) BattleManager.init 无 phases：精英怪应有 isElite=true
	var bm := BattleManagerScript.new()
	add_root(bm)
	bm.init(["monster_001"], ["enemy_003", "enemy_001"], 5, 5)
	var enemies: Array = bm.get_enemies()
	print("\n[init 无 phases] enemies:")
	for e in enemies:
		print("  %s: isElite=%s _visualScale=%s" % [e.get("id", "?"), str(e.get("isElite", null)), str(e.get("_visualScale", null))])
	# enemy_003 是精英
	assert(bool(enemies[0].get("isElite", false)) == true, "enemy_003 应有 isElite=true")
	assert(float(enemies[0].get("_visualScale", 1.0)) == 1.2, "enemy_003 应有 _visualScale=1.2")
	# enemy_001 不是精英
	assert(bool(enemies[1].get("isElite", false)) == false, "enemy_001 应该 isElite=false 或缺失")
	print("  ✓ init 无 phases OK")

	# 2) PhaseHandler 阶段转换：精英怪应有 isElite=true（phase 2 _visualScale 被 1.5 覆盖）
	var ph := PhaseHandlerScript.new(null)
	var new_enemies := ph.execute_phase_transition({
		"phase": 2,
		"trigger": "on_enter",
		"hpMultiplier": 1.3,
		"enemies": ["enemy_003", "enemy_001"]
	}, 5, 0.5)
	print("\n[phase 2 transition] enemies:")
	for e in new_enemies:
		print("  %s: isElite=%s _visualScale=%s" % [e.get("id", "?"), str(e.get("isElite", null)), str(e.get("_visualScale", null))])
	assert(bool(new_enemies[0].get("isElite", false)) == true, "phase2: enemy_003 应有 isElite=true")
	# phase 2 _visualScale = 1.5（覆盖 1.2）
	assert(float(new_enemies[0].get("_visualScale", 1.0)) == 1.5, "phase2: _visualScale 被覆盖为 1.5")
	print("  ✓ phase 2 transition OK")

	bm.queue_free()

	print("\n" + "=".repeat(70))
	print("Battle isElite 渲染可见性验证通过 ✓")
	print("=".repeat(70))
	quit()

func add_root(node: Node) -> void:
	get_root().add_child(node)
