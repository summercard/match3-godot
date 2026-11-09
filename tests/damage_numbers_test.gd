extends SceneTree

## 伤害飘字回归：
## - 普通/暴击样式区分（颜色、字号、暴击前缀）
## - 同一目标多段伤害错位，最多同时三层
## - 入场延迟在飘字更新中生效
## - 战斗场景实际生成飘字时使用新的样式与排队

const DamagePopup = preload("res://src/ui/components/battle_animation_controller.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_damage_styles()
	_test_anchors_and_lanes()
	_test_popup_scheduling()
	_test_delayed_entries()
	await _test_battle_scene_popups()
	_finish()


func _test_damage_styles() -> void:
	var normal: Dictionary = DamagePopup.damage_style(false, false)
	var crit: Dictionary = DamagePopup.damage_style(true, false)
	var weak: Dictionary = DamagePopup.damage_style(false, true)
	var heavy: Dictionary = DamagePopup.damage_style(false, false, true)
	_expect(str(normal.get("style", "")) == "normal", "normal damage should use normal style")
	_expect(str(crit.get("style", "")) == "crit", "critical damage should use crit style")
	_expect(str(crit.get("prefix", "")) == "暴击", "critical damage should carry the 暴击 prefix")
	_expect(str(normal.get("prefix", "")) == "", "normal damage should not carry a prefix")
	_expect(float(crit.get("size", 0.0)) > float(normal.get("size", 0.0)), "critical damage should be larger than normal")
	_expect(float(heavy.get("size", 0.0)) > float(normal.get("size", 0.0)), "heavy damage should be larger than normal")
	_expect(str(heavy.get("prefix", "")) == "", "heavy damage should not be labelled as a critical")
	var crit_color: Color = crit.get("color", Color.WHITE)
	var normal_color: Color = normal.get("color", Color.WHITE)
	_expect(crit_color.r >= 0.9 and crit_color.g <= 0.45 and crit_color.b <= 0.2, "critical color should be orange-red")
	_expect(crit_color != normal_color, "normal and critical should use different colors")
	_expect(weak.get("color", Color.WHITE) != normal_color, "weak damage should be visually muted")


func _test_anchors_and_lanes() -> void:
	var single: Vector2 = DamagePopup.enemy_damage_anchor(1, 0)
	var single_fn: Vector2 = DamagePopup.enemy_damage_anchor(1, -1)
	_expect(single == single_fn, "single enemy anchor should tolerate an unknown target index")
	_expect(single.y < 100.0, "single enemy damage should float above the enemy name")

	var two_a: Vector2 = DamagePopup.enemy_damage_anchor(2, 0)
	var two_b: Vector2 = DamagePopup.enemy_damage_anchor(2, 1)
	_expect(two_a != two_b, "two-enemy anchors should differ")
	_expect(two_a.y >= 190.0 and two_a.y <= 214.0, "multi-enemy damage should stay between HP bars and player cards")
	_expect(two_b.y >= 190.0 and two_b.y <= 214.0, "multi-enemy damage should stay between HP bars and player cards")

	var three: Array[Vector2] = [
		DamagePopup.enemy_damage_anchor(3, 0),
		DamagePopup.enemy_damage_anchor(3, 1),
		DamagePopup.enemy_damage_anchor(3, 2),
	]
	_expect(three[0].x < three[1].x and three[1].x < three[2].x, "three-enemy anchors should follow slot order")
	for anchor: Vector2 in three:
		_expect(anchor.y >= 190.0 and anchor.y <= 214.0, "three-enemy damage should stay out of HP bars and portraits")

	for index in range(3):
		var lane_points: Array[Vector2] = []
		for lane in range(3):
			lane_points.append(three[index] + DamagePopup.damage_lane_offset(three[index], lane))
		_expect(lane_points[0].distance_to(lane_points[1]) >= 40.0, "lane 1 should be separated from lane 0")
		_expect(lane_points[0].distance_to(lane_points[2]) >= 40.0, "lane 2 should be separated from lane 1")
		for point in lane_points:
			_expect(point.x >= 40.0 and point.x <= 335.0, "damage lanes should stay inside the screen")

	var player_a: Vector2 = DamagePopup.player_damage_anchor(0)
	var player_c: Vector2 = DamagePopup.player_damage_anchor(2)
	_expect(player_a.x < player_c.x, "player anchors should follow card order")
	_expect(player_a.y >= 190.0 and player_a.y <= 214.0, "player damage should stay above player cards")


func _test_popup_scheduling() -> void:
	var entries: Array = []
	var delays: Array[float] = []
	var lanes: Array[int] = []
	for i in range(4):
		var schedule: Dictionary = DamagePopup.schedule_damage_popup(entries, "enemy:0", 0.0, 0.9)
		delays.append(float(schedule.get("delay", -1.0)))
		lanes.append(int(schedule.get("lane", -1)))
		entries.append({
			"damage_anchor": "enemy:0",
			"timer": 0.0,
			"delay": schedule["delay"],
			"duration": 0.9,
			"lane": schedule["lane"],
		})
	_expect(absf(delays[0] - 0.0) < 0.01, "first hit should appear immediately")
	_expect(absf(delays[1] - 0.12) < 0.01, "second hit should be staggered by 0.12s")
	_expect(absf(delays[2] - 0.24) < 0.01, "third hit should be staggered by another 0.12s")
	_expect(delays[3] >= 0.85, "fourth hit should wait for a free layer")
	_expect(lanes[0] == 0 and lanes[1] == 1 and lanes[2] == 2, "first three hits should use separate lanes")
	_expect(lanes[3] == 0, "fourth hit should reuse the freed first lane")
	_expect(_max_concurrent(entries) <= 3, "at most three damage layers should overlap")

	# 暴击在侧位被占用时优先回到中间，避免普通与暴击互相压住。
	var side_entries: Array = [
		{"damage_anchor": "enemy:0", "timer": 0.0, "delay": 0.0, "duration": 0.9, "lane": 1},
		{"damage_anchor": "enemy:0", "timer": 0.0, "delay": 0.12, "duration": 0.9, "lane": 2},
	]
	var crit_schedule: Dictionary = DamagePopup.schedule_damage_popup(side_entries, "enemy:0", 0.0, 1.0, true)
	_expect(int(crit_schedule.get("lane", -1)) == 0, "critical damage should prefer the free center lane")

	# 不同目标各自排队，互不影响。
	var other: Dictionary = DamagePopup.schedule_damage_popup(entries, "enemy:1", 0.0, 0.9)
	_expect(absf(float(other.get("delay", 1.0))) < 0.01, "another target should start immediately")


func _test_delayed_entries() -> void:
	var texts: Array = [{
		"text": "-12",
		"x": 100.0,
		"y": 196.0,
		"start_y": 196.0,
		"color": Color.WHITE,
		"size": 21.0,
		"timer": 0.0,
		"duration": 0.85,
		"delay": 0.10,
		"damage_style": "normal",
	}]
	var glow: Dictionary = {"timer": 0.0}
	var trail: Array = []
	DamagePopup.update_floating_texts(texts, glow, trail, 0.05)
	_expect(texts.size() == 1 and float(texts[0]["timer"]) == 0.0, "delayed popup should not advance its timer")
	DamagePopup.update_floating_texts(texts, glow, trail, 0.05)
	_expect(texts.size() == 1 and float(texts[0]["delay"]) <= 0.001, "delay should count down")
	DamagePopup.update_floating_texts(texts, glow, trail, 0.10)
	_expect(texts.size() == 1 and float(texts[0]["timer"]) > 0.0, "popup should start after its delay")
	DamagePopup.update_floating_texts(texts, glow, trail, 1.0)
	_expect(texts.is_empty(), "popup should be removed after its duration")


func _test_battle_scene_popups() -> void:
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var stage_db = load("res://src/data/stage_db.gd").new()
	main.switch_scene("battle", {
		"stageId": "stage_1_1",
		"stageData": stage_db.get_stage("stage_1_1"),
		"inputTestOnly": true,
	})
	await process_frame
	await process_frame
	var battle_scene = main.get_current_scene()
	_expect(battle_scene != null and battle_scene.get("_battle") != null, "battle scene should initialize")
	if battle_scene == null or battle_scene.get("_battle") == null:
		main.queue_free()
		await process_frame
		return

	battle_scene.call("_spawn_enemy_damage_popup", "-120", 0, true)
	battle_scene.call("_spawn_enemy_damage_popup", "-80", 0, false)
	battle_scene.call("_spawn_player_damage_popup", "-15", 0, false, false, false)
	await process_frame
	var popups: Array = battle_scene.get("_floating_texts")
	var damage_popups: Array = popups.filter(func(entry): return not str(entry.get("damage_style", "")).is_empty())
	_expect(damage_popups.size() == 3, "battle scene should create three damage popups")
	var crit_popups: Array = damage_popups.filter(func(entry): return str(entry.get("damage_style", "")) == "crit")
	var normal_popups: Array = damage_popups.filter(func(entry): return str(entry.get("damage_style", "")) == "normal")
	_expect(crit_popups.size() == 1, "battle scene should create one critical popup")
	_expect(normal_popups.size() == 2, "battle scene should create normal popups")
	if crit_popups.size() == 1:
		var crit: Dictionary = crit_popups[0]
		_expect(float(crit.get("size", 0.0)) >= 28.0, "critical popup should use the larger size")
		_expect((crit.get("color", Color.WHITE) as Color).r >= 0.9, "critical popup should use the orange-red color")
		_expect(str(crit.get("damage_anchor", "")).begins_with("enemy:"), "enemy critical popup should be anchored to the enemy")
	if normal_popups.size() == 2:
		_expect(absf(float(normal_popups[0].get("delay", 0.0)) - 0.12) < 0.02, "second normal popup should be delayed")
	_expect(battle_scene.get("_fx_time") >= 0.0, "battle scene should track its popup clock")

	main.queue_free()
	await process_frame


func _max_concurrent(entries: Array) -> int:
	var events: Array[Dictionary] = []
	for entry in entries:
		var start: float = float(entry.get("delay", 0.0))
		var finish: float = start + float(entry.get("duration", 0.9))
		events.append({"time": start, "delta": 1})
		events.append({"time": finish, "delta": -1})
	events.sort_custom(func(a, b):
		if absf(float(a["time"]) - float(b["time"])) <= 0.0001:
			return int(a["delta"]) < int(b["delta"])
		return float(a["time"]) < float(b["time"])
	)
	var current := 0
	var peak := 0
	for event in events:
		current += int(event["delta"])
		peak = maxi(peak, current)
	return peak


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[DamageNumbers] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[DamageNumbers] " + failure)
	quit(1)
