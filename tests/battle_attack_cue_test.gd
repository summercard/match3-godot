extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://src/ui/scenes/battle_screen.tscn").instantiate() as Control
	root.add_child(scene)
	await process_frame

	scene.call("_start_attack_cue", false, 0, true, 0, "fire", "小火龙 → 训练兽", false)
	var cues: Array = scene.get("_attack_cues")
	var lunges: Array = scene.get("_player_lunge_anims")
	_expect(cues.size() == 1, "player attack should create one observation cue")
	_expect(lunges.is_empty(), "player attack should keep the combatant in place")
	if cues.size() > 0:
		var cue: Dictionary = cues[0]
		_expect(not bool(cue.get("attacker_is_enemy", true)), "player cue attacker should be allied")
		_expect(bool(cue.get("target_is_enemy", false)), "player cue target should be enemy")
		_expect(str(cue.get("label", "")).find("→") >= 0, "player cue label should show direction")
		_expect(float(cue.get("timer", 0.0)) > 0.0, "player cue should have visible duration")

	scene.call("_start_attack_cue", true, 0, false, 1, "dark", "暗蛛 → 水灵兽", true)
	cues = scene.get("_attack_cues")
	lunges = scene.get("_player_lunge_anims")
	_expect(cues.size() == 2, "enemy attack should create an observation cue")
	_expect(lunges.is_empty(), "enemy attack should not create an allied lunge")
	if cues.size() > 1:
		var enemy_cue: Dictionary = cues[1]
		_expect(bool(enemy_cue.get("attacker_is_enemy", false)), "enemy cue attacker should be enemy")
		_expect(not bool(enemy_cue.get("target_is_enemy", true)), "enemy cue target should be allied")
		_expect(bool(enemy_cue.get("charged", false)), "charged enemy cue should preserve charged flag")

	var flashes: Array = scene.get("_hit_flashes")
	flashes.append({"isEnemy": true, "monsterIndex": 0, "timer": 0.12, "maxTimer": 0.12})
	_expect(bool(scene.call("_has_pending_player_resolution_fx")), "hit flash should keep match chain tail pending")
	await scene.call("_wait_for_player_resolution_tail")
	_expect(not bool(scene.call("_has_pending_player_resolution_fx")), "match chain tail should clear before enemy turn handoff")
	
	scene.queue_free()
	await process_frame
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[BattleAttackCue] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[BattleAttackCue] " + failure)
	quit(1)
