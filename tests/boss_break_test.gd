extends SceneTree

## 1-5「花叶兽的破招」回归：
## 1. 固定种子、全程不破招时，蓄力释放次数与每次伤害等于基线；
## 2. 蓄力回合内挂眩晕 → 本次释放 0 次、伤害 0、蓄力清空、总回合数变长且仍能 win；
## 3. 只有蓄力中的敌人能被破招；普攻怪吃眩晕仍走原眩晕逻辑，不多跳一回合；
## 4. 数据化蓄力（×1.9）同样可被破招；
## 5. 战斗场景在破招瞬间给出「破招」飘字、短震屏与专用音效。

const StageDBScript = preload("res://src/data/stage_db.gd")
const BattleManagerScript = preload("res://src/battle/battle_manager.gd")
const MonsterDbScript = preload("res://src/data/monster_db.gd")

const TEAM := ["monster_001", "monster_002", "monster_003"]
const SEED := 2
# 基线口径：main eddd1ed 上同一脚本、同一固定种子、全程不破招的结果。
# 这些常量只用于断言“未破招时没有任何变化”，不是新的平衡目标。
const BASELINE_TURNS := 43
const BASELINE_RELEASE_DAMAGE := [26, 7, 7, 26, 15, 15, 22, 11, 11, 22, 13, 11, 7]
const LEGACY_CHARGE_MULTIPLIER := 3.75  # 1-5: enemySkills 2.5 × bossCurve 1.5，保持原值

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var baseline := _run_reference_battle(false)
	var broken := _run_reference_battle(true)
	_test_baseline_unchanged(baseline)
	_test_break_cancels_charge(baseline, broken)
	_test_only_charging_enemies_break()
	await _test_scene_feedback()
	_finish()


## 与 combat_balance_test 相同的固定参考策略：草/水/火亲和、技能就绪择机释放。
## break_mode 打开时，在每次“蓄力中”的敌方回合前挂一个眩晕，模拟玩家在蓄力回合打断。
func _run_reference_battle(break_mode: bool) -> Dictionary:
	seed(SEED)
	var stage: Dictionary = StageDBScript.new().get_stage("stage_1_5")
	var battle = BattleManagerScript.new()
	battle.init(TEAM, [], 5, 3, stage, "stage_1_5")
	var releases: Array = []
	var break_actions: Array = []
	var first_break_multiplier := 0.0
	var skill_system = battle.get("_enemy_skill_system")
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

		var charging: bool = skill_system != null and skill_system.is_charging(0)
		if break_mode and charging:
			# 玩家在蓄力回合改消震能来施加眩晕：这一回合不造成伤害，是破招的真实代价。
			if is_zero_approx(first_break_multiplier):
				first_break_multiplier = skill_system.get_charge_damage_multiplier(0)
			battle.process_match_result({"thunder": 5}, 1)
		else:
			var affinity := _best_affinity(battle, lowest)
			var match_result: Dictionary = battle.process_match_result({affinity: 3}, 1)
			if match_result.has("phase_transition"):
				battle.execute_phase_transition(match_result.get("phase_transition", {}))
		if battle.check_battle_end():
			break

		var enemy_result: Dictionary = battle.enemy_action()
		for action: Dictionary in enemy_result.get("actions", []):
			if action.get("is_broken", false):
				break_actions.append(action.duplicate(true))
			elif str(action.get("attack_mode", "")) == "charge_release":
				releases.append({
					"damage": int(action.get("damage", 0)),
					"multiplier": float(action.get("charge_multiplier", 0.0))
				})

	var result: Dictionary = battle.get_battle_result()
	var payload := {
		"turns": turns,
		"result": str(result.get("result", "")),
		"releases": releases,
		"break_actions": break_actions,
		"break_count": int(battle.break_count),
		"result_break_count": int(result.get("breakCount", -1)),
		"first_break_multiplier": first_break_multiplier,
		"final_charging": skill_system != null and skill_system.is_charging(0)
	}
	battle.free()
	return payload


func _test_baseline_unchanged(baseline: Dictionary) -> void:
	_expect(str(baseline["result"]) == "win", "no-break baseline should still win")
	_expect(int(baseline["turns"]) == BASELINE_TURNS, "no-break baseline should stay at %d turns, got %d" % [BASELINE_TURNS, int(baseline["turns"])])
	var release_damage: Array = (baseline["releases"] as Array).map(func(r): return int(r["damage"]))
	_expect(release_damage == BASELINE_RELEASE_DAMAGE,
		"no-break charge releases should match the eddd1ed baseline, got %s" % str(release_damage))
	for release: Dictionary in baseline["releases"]:
		_expect(is_equal_approx(float(release["multiplier"]), LEGACY_CHARGE_MULTIPLIER),
			"un-broken 1-5 release should keep the existing 3.75x multiplier, got %.2f" % float(release["multiplier"]))
	print("[BossBreak] baseline seed=%d turns=%d result=%s releaseDamage=%s breakCount=%d" % [
		SEED, int(baseline["turns"]), str(baseline["result"]),
		str((baseline["releases"] as Array).map(func(r): return int(r["damage"]))),
		int(baseline["break_count"])])
	_expect(int(baseline["break_count"]) == 0, "no-break baseline should record zero breaks")
	_expect((baseline["break_actions"] as Array).is_empty(), "no-break baseline must not emit break actions")
	_expect(int(baseline["result_break_count"]) == 0, "battle result should expose zero breaks on the baseline")


func _test_break_cancels_charge(baseline: Dictionary, broken: Dictionary) -> void:
	_expect(str(broken["result"]) == "win", "a battle that breaks charges should still win")
	_expect((broken["releases"] as Array).is_empty(), "broken charges must never release, got %s" % str(broken["releases"]))
	_expect((broken["break_actions"] as Array).size() > 0, "breaking a charge should emit break actions")
	_expect(int(broken["break_count"]) == (broken["break_actions"] as Array).size(),
		"break counter should match the number of break actions")
	_expect(int(broken["result_break_count"]) == int(broken["break_count"]),
		"battle result should expose the same break count")
	print("[BossBreak] break seed=%d turns=%d result=%s releases=%d breakCount=%d" % [
		SEED, int(broken["turns"]), str(broken["result"]),
		(broken["releases"] as Array).size(), int(broken["break_count"])])
	_expect(int(broken["turns"]) > int(baseline["turns"]),
		"breaking charges should lengthen the battle (%d vs baseline %d)" % [int(broken["turns"]), int(baseline["turns"])])
	for action: Dictionary in broken["break_actions"]:
		_expect(int(action.get("damage", -1)) == 0, "break action must deal zero damage")
		_expect(action.get("target", "missing") == null, "break action must not pick a target")
		_expect(str(action.get("attack_mode", "")) == "break", "break action should report break mode")
		_expect(is_equal_approx(float(action.get("charge_multiplier", 0.0)), LEGACY_CHARGE_MULTIPLIER),
			"break action should carry the cancelled 3.75x charge multiplier")
	_expect(is_equal_approx(float(broken["first_break_multiplier"]), LEGACY_CHARGE_MULTIPLIER),
		"the cancelled legacy charge should be the existing 3.75x multiplier")
	_expect(not bool(broken["final_charging"]), "cancelled charge must clear the charging state")


func _test_only_charging_enemies_break() -> void:
	# 普攻怪：眩晕前后走完全相同的原逻辑（不多跳一回合、不产生破招）。
	var normal_before := _run_single_enemy_action(["enemy_001"], "stage_1_1", false)
	var normal_with_stun := _run_single_enemy_action(["enemy_001"], "stage_1_1", true)
	_expect(JSON.stringify(normal_before["actions"]) == JSON.stringify(normal_with_stun["actions"]),
		"ordinary enemy should keep its existing stun behaviour, before=%s after=%s" % [str(normal_before["actions"]), str(normal_with_stun["actions"])])
	print("[BossBreak] ordinary enemy identical=%s damage=%d" % [
		JSON.stringify(normal_before["actions"]) == JSON.stringify(normal_with_stun["actions"]),
		int(normal_with_stun["damage"])])
	_expect(int(normal_with_stun["break_count"]) == 0, "ordinary enemy must not be broken")
	_expect(not _has_break_action(normal_with_stun["actions"]), "ordinary enemy action must not be a break")
	_expect(int(normal_with_stun["damage"]) > 0, "ordinary enemy should still attack after stun as before")

	# 数据化蓄力：enemy_006 轮次 strike → charge → 释放；打断后按轮次进入 sweep。
	var modes_battle = _build_attack_mode_battle()
	var modes = modes_battle.get("_attack_modes")
	modes.consume_turn(0)
	modes.consume_turn(0)
	_expect(modes.is_charging(0), "enemy_006 should be charging before the break")
	modes_battle.get("_status_effect").apply_status_effect(0, "stun")
	var mode_result: Dictionary = modes_battle.enemy_action()
	var mode_actions: Array = mode_result.get("actions", [])
	_expect(mode_actions.size() == 1, "break should produce one action entry, got %d" % mode_actions.size())
	if mode_actions.size() == 1:
		_expect(bool(mode_actions[0].get("is_broken", false)), "data-driven charge should be breakable")
		_expect(int(mode_actions[0].get("damage", -1)) == 0, "data-driven break should deal zero damage")
		_expect(is_equal_approx(float(mode_actions[0].get("charge_multiplier", 0.0)), 1.9),
			"data-driven break should cancel the configured 1.9x release")
	_expect(not modes.is_charging(0), "data-driven break should clear the charging state")
	_expect(int(modes_battle.break_count) == 1, "data-driven break should count once")
	var next_mode: Dictionary = modes.consume_turn(0)
	_expect(str(next_mode.get("type", "")) == "sweep", "after a broken charge the rotation should advance to sweep, got %s" % str(next_mode))
	modes_battle.free()

	# 未蓄力的 Boss 吃眩晕不算破招，仍走原有动作。
	var boss_not_charging := _run_single_enemy_action(["monster_boss_001"], "stage_1_5", true)
	print("[BossBreak] data-charge break=1.9x, non-charging boss breakCount=%d" % int(boss_not_charging["break_count"]))
	_expect(int(boss_not_charging["break_count"]) == 0, "a non-charging boss must not be broken")
	_expect(not _has_break_action(boss_not_charging["actions"]), "a non-charging boss must not emit a break action")


func _run_single_enemy_action(enemy_ids: Array, stage_id: String, with_stun: bool) -> Dictionary:
	var stage: Dictionary = StageDBScript.new().get_stage(stage_id)
	var battle = BattleManagerScript.new()
	battle.init(TEAM, enemy_ids, 5, int(stage.get("enemyLevel", 1)), stage, stage_id)
	for monster: Dictionary in battle.player_team:
		monster["maxHP"] = 99999
		monster["hp"] = 99999
	seed(424242)
	if with_stun:
		battle.get("_status_effect").apply_status_effect(0, "stun")
	var result: Dictionary = battle.enemy_action()
	var actions: Array = result.get("actions", [])
	var damage := 0
	for action: Dictionary in actions:
		damage += int(action.get("damage", 0))
	var payload := {
		"actions": actions,
		"damage": damage,
		"break_count": int(battle.break_count)
	}
	battle.free()
	return payload


func _build_attack_mode_battle():
	var stage: Dictionary = StageDBScript.new().get_stage("stage_3_3")
	var battle = BattleManagerScript.new()
	battle.init(TEAM, ["enemy_006"], 5, 20, stage, "stage_3_3")
	for monster: Dictionary in battle.player_team:
		monster["maxHP"] = 99999
		monster["hp"] = 99999
	return battle


func _has_break_action(actions: Array) -> bool:
	for action: Dictionary in actions:
		if action.get("is_broken", false):
			return true
	return false


func _test_scene_feedback() -> void:
	var battle_sfx = load("res://src/ui/components/battle_sfx.gd")
	battle_sfx.enabled = true
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var stage_db := StageDBScript.new()
	main.switch_scene("battle", {
		"stageId": "stage_1_5",
		"stageData": stage_db.get_stage("stage_1_5"),
		"inputTestOnly": true,
	})
	await process_frame
	await process_frame
	var battle_scene: Control = main.get_current_scene()
	if battle_scene == null:
		_expect(false, "battle scene should load for break feedback")
		main.queue_free()
		return
	var battle = battle_scene.get("_battle")
	var skill_system = battle.get("_enemy_skill_system") if battle != null else null
	if battle == null or skill_system == null:
		_expect(false, "battle should expose the enemy skill system")
		main.queue_free()
		return
	var charge_state = skill_system.get_skill_state(0, "charge")
	charge_state["is_charging"] = true
	charge_state["turns_since_last"] = 0
	battle.get("_status_effect").apply_status_effect(0, "stun")
	battle_scene.set("_floating_texts", [])
	battle_scene.set("_message_text", "")
	battle_scene.set("_message_timer", 0.0)
	var sfx = battle_scene.get("_battle_sfx")
	if sfx != null:
		sfx.set_enabled(true)
		sfx.reset_counters()
	battle_scene.call("_start_enemy_turn")

	var saw_popup := false
	for _i in range(180):
		await process_frame
		for ft: Dictionary in battle_scene.get("_floating_texts"):
			if str(ft.get("text", "")) == "破招":
				saw_popup = true
				break
		if saw_popup:
			break
	_expect(saw_popup, "break should spawn a 破招 popup")
	var shake_timer := float(battle_scene.get("_attack_shake_timer"))
	print("[BossBreak] scene popup=%s shake=%.2f sfx=%s message=%s" % [
		str(saw_popup), shake_timer, str(sfx.last_sound_id if sfx != null else ""),
		str(battle_scene.get("_message_text"))])
	_expect(shake_timer > 0.0, "break should trigger a short screen shake")
	_expect(str(battle_scene.get("_message_text")).contains("破招"), "break should show a 破招 battle message")
	if sfx != null:
		_expect(str(sfx.last_sound_id) == "break", "break should play the dedicated break sound, got %s" % str(sfx.last_sound_id))
		_expect(int(sfx.played_count) >= 1, "break should actually play a sound")
	var visuals: Dictionary = battle_scene.get("_boss_skill_visuals")
	_expect(float(visuals.get(0, {}).get("charge_timer", -1.0)) == 0.0, "break should clear the charge aura")
	_expect(int(battle.break_count) == 1, "scene break should increment the battle break counter")
	await create_timer(0.9).timeout
	main.queue_free()
	await process_frame
	battle_sfx.enabled = true


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
		print("[BossBreak] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[BossBreak] " + failure)
	quit(1)
