extends SceneTree

## 受击反应与血条缓降回归：
## 1. 参数口径：受击 0.2s、血条缓降 0.25s、总开关关闭时全部回到原表现；
## 2. 血条缓降在 0.25s 内完成且过程值既不是旧值也不是目标值（不瞬跳）；
## 3. 真实战斗场景里受击反应只改表现，战斗伤害/承伤日志与基线 37d121c 逐位一致。

const BattleHitReactionScript = preload("res://src/ui/components/battle_hit_reaction.gd")
const BattleHpBarScript = preload("res://src/ui/components/battle_hp_bar.gd")
const DamageFeedbackScript = preload("res://src/ui/components/damage_feedback.gd")
const BattleManagerScript = preload("res://src/battle/battle_manager.gd")
const StageDBScript = preload("res://src/data/stage_db.gd")
const BASELINE_PATH := "res://docs/qa/hit_reaction_bars/baseline_combat_log.json"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_config()
	_test_reaction_lifecycle()
	_test_hp_easing()
	_test_master_switch_off()
	_test_combat_logs_match_baseline()
	await _test_scene_reaction_is_display_only()
	BattleHitReactionScript.enabled = true
	_finish()


func _test_config() -> void:
	var hit: Dictionary = BattleHitReactionScript.CONFIG["hit"]
	_expect(is_equal_approx(float(hit["shake_duration"]), 0.2), "受击抖动应为 0.2s")
	_expect(is_equal_approx(float(hit["flash_duration"]), 0.2), "受击闪白应为 0.2s")
	_expect(is_equal_approx(BattleHitReactionScript.hp_ease_duration(), 0.25), "血条缓降应为 0.25s")
	_expect(float(hit["shake_amplitude"]) > 0.0, "受击抖动应有可见位移")


func _test_reaction_lifecycle() -> void:
	BattleHitReactionScript.enabled = true
	var entries: Array[Dictionary] = []
	var entry := BattleHitReactionScript.trigger(entries, true, 0)
	_expect(entries.size() == 1, "一次受击应产生一条受击反应")
	_expect(is_equal_approx(float(entry.get("timer", 0.0)), 0.2), "受击反应计时应从 0.2s 开始")
	_expect(BattleHitReactionScript.flash_alpha(entry) > 0.0, "受击瞬间应有闪白")
	_expect(BattleHitReactionScript.shake_offset(entry).length() > 0.0, "受击瞬间应有抖动位移")
	_expect(BattleHitReactionScript.shake_offset(entry).length() <= float(BattleHitReactionScript.CONFIG["hit"]["shake_amplitude"]) + 0.001,
		"抖动位移不应超过配置振幅")
	BattleHitReactionScript.trigger(entries, true, 0)
	_expect(entries.size() == 1, "同一目标连续受击应重置而不是叠加计时")
	BattleHitReactionScript.tick(entries, 0.05)
	var mid: Dictionary = BattleHitReactionScript.find(entries, true, 0)
	_expect(not mid.is_empty(), "0.05s 时受击反应应仍在播放")
	_expect(BattleHitReactionScript.flash_alpha(mid) < BattleHitReactionScript.flash_alpha(entry),
		"闪白应随时间衰减")
	BattleHitReactionScript.tick(entries, 0.16)
	_expect(entries.is_empty(), "超过 0.2s 后受击反应应结束")
	_expect(BattleHitReactionScript.find(entries, true, 0).is_empty(), "结束后不应再找到残留反应")


func _test_hp_easing() -> void:
	BattleHitReactionScript.enabled = true
	# 本轮伤害反馈升级后，0.25s 缓降是「伤害反馈总开关关闭」时的基线表现；
	# 这里显式关掉新开关，继续覆盖旧缓降路径。
	DamageFeedbackScript.enabled = false
	var bar = BattleHpBarScript.new()
	bar.value = 100.0
	bar.maximum = 100.0
	bar._ready()
	bar.set_target_value(40.0)
	_expect(bar.is_easing(), "血条应开始缓降而不是瞬跳")
	_expect(is_equal_approx(bar.value, 100.0), "缓降第一帧不应瞬间变成目标值")
	bar._process(0.10)
	_expect(bar.value < 100.0 and bar.value > 40.0, "0.10s 时血条应处于旧值与目标值之间，实际 %.2f" % bar.value)
	bar._process(0.14)
	_expect(bar.value < 100.0 and bar.value > 40.0, "0.24s 时血条仍未到目标值，实际 %.2f" % bar.value)
	bar._process(0.02)
	_expect(is_equal_approx(bar.value, 40.0), "满 0.25s 时血条应到达目标值，实际 %.2f" % bar.value)
	_expect(not bar.is_easing(), "到达目标值后应结束缓降")
	bar.free()
	DamageFeedbackScript.enabled = true


func _test_master_switch_off() -> void:
	BattleHitReactionScript.enabled = false
	var entries: Array[Dictionary] = []
	BattleHitReactionScript.trigger(entries, true, 0)
	_expect(entries.is_empty(), "总开关关闭时不应产生受击反应")
	var bar = BattleHpBarScript.new()
	bar.value = 100.0
	bar.maximum = 100.0
	bar._ready()
	bar.set_target_value(40.0)
	_expect(not bar.is_easing(), "总开关关闭时血条不应缓动")
	_expect(is_equal_approx(bar.value, 40.0), "总开关关闭时血条应立即到目标值")
	bar.free()
	BattleHitReactionScript.enabled = true


## 固定的 20 回合战斗（seed 20261109）与基线 37d121c 的伤害/承伤日志逐位比较。
func _test_combat_logs_match_baseline() -> void:
	var file := FileAccess.open(BASELINE_PATH, FileAccess.READ)
	if file == null:
		_failures.append("缺少基线战斗日志：%s" % BASELINE_PATH)
		return
	var expected_text := file.get_as_text()
	file.close()
	var expected: Variant = JSON.parse_string(expected_text)
	if not expected is Dictionary:
		_failures.append("基线战斗日志无法解析")
		return

	var expected_canonical := _canonical_json(expected)
	BattleHitReactionScript.enabled = true
	var enabled_payload := _run_deterministic_battle()
	_expect(
		_canonical_json(enabled_payload) == expected_canonical,
		"开启受击反应后伤害/承伤日志应与基线 37d121c 逐位一致"
	)

	BattleHitReactionScript.enabled = false
	var disabled_payload := _run_deterministic_battle()
	_expect(
		_canonical_json(disabled_payload) == expected_canonical,
		"关闭受击反应后伤害/承伤日志应与基线 37d121c 逐位一致"
	)
	BattleHitReactionScript.enabled = true


## JSON 解析会把整数读成浮点；统一再走一遍解析/序列化，只比较内容。
func _canonical_json(value: Variant) -> String:
	var text := JSON.stringify(value, "\t")
	var parsed: Variant = JSON.parse_string(text)
	return JSON.stringify(parsed, "\t")


func _run_deterministic_battle() -> Dictionary:
	seed(20261109)
	var stage: Dictionary = StageDBScript.new().get_stage("stage_1_1")
	var battle = BattleManagerScript.new()
	battle.init(["monster_001", "monster_002", "monster_003"], ["enemy_001"], 5, 1, stage, "stage_1_1")
	battle.enemies[0]["maxHP"] = 900
	battle.enemies[0]["hp"] = 900
	battle.max_turns = 50

	var damage_logs: Array = []
	var taken_logs: Array = []
	battle.damage_dealt.connect(func(info: Dictionary): damage_logs.append(info.duplicate(true)))
	battle.enemy_attacked.connect(func(info: Dictionary): taken_logs.append(info.duplicate(true)))

	var combos: Array = [4, 3, 2, 1]
	var turns: Array = []
	for turn in range(1, 21):
		battle.turn_count = turn
		var combo := int(combos[(turn - 1) % combos.size()])
		var result: Dictionary = battle.process_match_result({"fire": 3, "water": 3, "grass": 3}, combo)
		turns.append({
			"turn": turn,
			"combo": combo,
			"damage_log": result.get("damage_log", [])
		})
		if battle.check_battle_end():
			break
		var enemy: Dictionary = battle.enemy_action()
		turns[turns.size() - 1]["actions"] = enemy.get("actions", [])
		if battle.battle_over:
			break

	var result: Dictionary = battle.get_battle_result()
	var payload := {
		"source_commit": "37d121c",
		"seed": 20261109,
		"stage_id": "stage_1_1",
		"player_level": 5,
		"enemy_level": 1,
		"turns": turns,
		"damage_dealt_log": damage_logs,
		"damage_taken_log": taken_logs,
		"ally_stats": result.get("ally_stats", []),
		"total_damage": int(result.get("total_damage", 0)),
		"total_damage_taken": int(result.get("total_damage_taken", 0)),
		"battle_result": str(result.get("result", "")),
		"turn_count": int(result.get("turn_count", 0)),
		"max_combo": int(result.get("max_combo", 0))
	}
	battle.free()
	return payload


## 真实场景里触发一次敌方/我方受击：受击反应与血条缓动都在播放，但战斗 HP、承伤统计不变。
func _test_scene_reaction_is_display_only() -> void:
	BattleHitReactionScript.enabled = true
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var stage_db = StageDBScript.new()
	main.switch_scene("battle", {
		"stageId": "stage_1_1",
		"stageData": stage_db.get_stage("stage_1_1")
	})
	await process_frame
	await process_frame
	var battle_scene: Control = main.get_current_scene()
	if battle_scene == null or not battle_scene.has_method("_sync_gui"):
		_failures.append("战斗场景应加载可编辑 GUI")
		main.queue_free()
		await process_frame
		return
	var battle = battle_scene.get("_battle")
	if battle == null or battle.enemies.is_empty() or battle.player_team.is_empty():
		_failures.append("战斗场景应生成敌我单位")
		main.queue_free()
		await process_frame
		return

	var enemy: Dictionary = battle.enemies[0]
	var enemy_max := maxi(int(enemy.get("maxHP", 1)), 1)
	var enemy_damage := maxi(int(float(enemy_max) * 0.45), 1)
	enemy["hp"] = maxi(enemy_max - enemy_damage, 1)
	var enemy_hp_after_damage := int(enemy.get("hp", 0))
	var enemy_bar: Control = battle_scene.get_node("Combatants/SingleEnemy/HpBar")

	var player: Dictionary = battle.player_team[0]
	var player_max := maxi(int(player.get("maxHP", 1)), 1)
	var player_damage := maxi(int(float(player_max) * 0.35), 1)
	player["hp"] = maxi(player_max - player_damage, 1)
	var player_hp_after_damage := int(player.get("hp", 0))
	var player_bar: Control = battle_scene.get_node("Combatants/Players/Player1/HpBar")
	var taken_before := int(battle.total_damage_taken)

	battle_scene.call("_on_damage_dealt", {
		"damage": enemy_damage,
		"target": enemy.get("name", "敌人"),
		"attacker": "test",
		"type": "match"
	})
	battle_scene.call("_on_enemy_attacked", {
		"damage": player_damage,
		"target": player.get("name", "伙伴"),
		"is_charged": false
	})
	battle_scene.call("_sync_gui")

	var reactions: Array = battle_scene.get("_hit_reactions")
	_expect(reactions.size() == 2, "敌我各挨一次应各有一条受击反应，实际 %d" % reactions.size())
	_expect(enemy_bar.call("is_easing"), "敌方血条应开始缓降")
	_expect(player_bar.call("is_easing"), "我方血条应开始缓降")
	_expect(not is_equal_approx(float(enemy_bar.get("value")), float(enemy_hp_after_damage) / float(enemy_max) * 100.0),
		"缓降过程中血条绘制值不应等于目标值（不瞬跳）")
	_expect(int(enemy.get("hp", 0)) == enemy_hp_after_damage, "受击反应不应改动敌方 HP")
	_expect(int(player.get("hp", 0)) == player_hp_after_damage, "受击反应不应改动我方 HP")
	_expect(int(battle.total_damage_taken) == taken_before, "受击反应不应改动承伤统计")

	var enemy_portrait: TextureRect = battle_scene.get_node("Combatants/SingleEnemy/Portrait")
	_expect(enemy_portrait.material is ShaderMaterial, "开启闪白时头像应挂上闪白材质")
	if enemy_portrait.material is ShaderMaterial:
		_expect(float((enemy_portrait.material as ShaderMaterial).get_shader_parameter("flash_amount")) > 0.0,
			"受击瞬间头像闪白强度应大于 0")

	# 等反应结束后，血量与绘制值都应回到真实值，且没有残留位移/闪白。
	await create_timer(0.35).timeout
	await process_frame
	_expect(not enemy_bar.call("is_easing") and not player_bar.call("is_easing"), "0.35s 后血条缓降应结束")
	var remaining_reactions: Array = battle_scene.get("_hit_reactions")
	_expect(remaining_reactions.is_empty(), "0.35s 后不应残留受击反应")
	_expect((enemy_portrait.material as ShaderMaterial).get_shader_parameter("flash_amount") == 0.0,
		"受击结束后闪白强度应归零")
	_expect(int(enemy.get("hp", 0)) == enemy_hp_after_damage, "整个表现过程都不应改动敌方 HP")
	_expect(int(player.get("hp", 0)) == player_hp_after_damage, "整个表现过程都不应改动我方 HP")

	main.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[BattleHitReaction] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[BattleHitReaction] " + failure)
	quit(1)
