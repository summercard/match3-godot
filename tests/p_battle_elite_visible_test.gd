extends SceneTree

# Verify enemies in battle expose isElite to renderer

const BattleManagerScript = preload("res://src/battle/battle_manager.gd")
const PhaseHandlerScript = preload("res://src/battle/phase_handler.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=".repeat(70))
	print("Battle 渲染层 isElite 可见性验证")
	print("=".repeat(70))

	# 1) BattleManager.init 无 stageData：旧模板标记不再让固定 ID 必定精英
	var bm := BattleManagerScript.new()
	add_root(bm)
	bm.init(["monster_001"], ["enemy_003", "enemy_001"], 5, 5)
	var enemies: Array = bm.get_enemies()
	print("\n[init 无 phases] enemies:")
	for e in enemies:
		print("  %s: isElite=%s _visualScale=%s" % [e.get("id", "?"), str(e.get("isElite", null)), str(e.get("_visualScale", null))])
	assert(bool(enemies[0].get("isElite", false)) == false, "无 stageData 时 enemy_003 不应再因固定 ID 必定精英")
	assert(bool(enemies[1].get("isElite", false)) == false, "enemy_001 应该 isElite=false 或缺失")
	print("  ✓ init 无 phases OK")

	# 2) BattleManager：普通怪可按关卡概率随机升格为精英
	var bm_random := BattleManagerScript.new()
	add_root(bm_random)
	bm_random.init(["monster_001"], ["enemy_001"], 5, 5, {
		"id": "random_elite_test",
		"enemies": ["enemy_001"],
		"enemyLevel": 5,
		"randomEliteChance": 1.0
	}, "random_elite_test")
	var random_enemy: Dictionary = bm_random.get_enemies()[0]
	assert(bool(random_enemy.get("isElite", false)) == true, "randomEliteChance=1 时普通 enemy_001 应随机升格为精英")
	assert(str(random_enemy.get("_eliteSource", "")) == "random", "随机升格精英应标记 _eliteSource=random")
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
	assert(bool(disabled_enemy.get("isElite", false)) == false, "disableRandomElite 应阻止普通怪随机升格")
	bm_disabled.queue_free()
	print("  ✓ random elite roll OK")

	# 3) PhaseHandler 阶段转换：randomEliteChance=1 时精英标记应存在（phase 2 _visualScale 被 1.5 覆盖）
	var ph := PhaseHandlerScript.new(null)
	var new_enemies := ph.execute_phase_transition({
		"phase": 2,
		"trigger": "on_enter",
		"hpMultiplier": 1.3,
		"enemies": ["enemy_003", "enemy_001"],
		"randomEliteChance": 1.0
	}, 5, 0.5)
	print("\n[phase 2 transition] enemies:")
	for e in new_enemies:
		print("  %s: isElite=%s _visualScale=%s" % [e.get("id", "?"), str(e.get("isElite", null)), str(e.get("_visualScale", null))])
	assert(bool(new_enemies[0].get("isElite", false)) == true, "phase2: enemy_003 应有 isElite=true")
	# phase 2 _visualScale = 1.5（覆盖 1.2）
	assert(float(new_enemies[0].get("_visualScale", 1.0)) == 1.5, "phase2: _visualScale 被覆盖为 1.5")
	print("  ✓ phase 2 transition OK")

	bm.queue_free()

	# 4) 真实 battle_screen.tscn：可编辑 GUI 节点层也应显示精英差异
	var scene: Control = load("res://src/ui/scenes/battle_screen.tscn").instantiate()
	get_root().add_child(scene)
	scene.init({
		"stageId": "elite_visible_test",
		"stageData": {
			"id": "elite_visible_test",
			"name": "精英显示测试",
			"enemies": ["enemy_001"],
			"enemyLevel": 5,
			"randomEliteChance": 1.0
		},
		"inputTestOnly": true
	})
	await process_frame
	var name_label := scene.get_node("Combatants/SingleEnemy/Name") as Label
	var portrait := scene.get_node("Combatants/SingleEnemy/Portrait") as TextureRect
	print("\n[battle_screen GUI] name=%s portrait_size=%s" % [name_label.text, str(portrait.size)])
	assert(name_label.text.begins_with("★精英 "), "battle_screen GUI 应在精英怪名字前显示 ★精英")
	assert(name_label.get_theme_color("font_color") != Color.WHITE, "battle_screen GUI 精英标识颜色不应是白色")
	assert(portrait.size.x > 128.0 and portrait.size.y > 128.0, "battle_screen GUI 应放大精英怪 Portrait")
	scene.queue_free()
	await process_frame
	print("  ✓ battle_screen GUI OK")

	print("\n" + "=".repeat(70))
	print("Battle isElite 渲染可见性验证通过 ✓")
	print("=".repeat(70))
	quit()

func add_root(node: Node) -> void:
	get_root().add_child(node)
