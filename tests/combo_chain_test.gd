extends SceneTree

## 连锁反馈回归：
## - 第 2 连锁起伤害加成 8%/级，最多吃到第 5 连锁
## - 连锁音效每级升高音高，音色在运行时生成
## - 战斗场景中部连锁提示的显隐与安全区域

const DamageCalculatorScript = preload("res://src/battle/damage_calculator.gd")
const ComboSfxScript = preload("res://src/ui/components/combo_sfx.gd")
const BattleAnimationControllerScript = preload("res://src/ui/components/battle_animation_controller.gd")

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_chain_damage_bonus()
	_test_chain_audio()
	await _test_battle_scene_chain_display()
	_finish()

func _test_chain_damage_bonus() -> void:
	var expected := {1: 1.0, 2: 1.04, 3: 1.08, 4: 1.08, 5: 1.08, 6: 1.08}
	for level: int in expected.keys():
		var multiplier: float = DamageCalculatorScript.chain_damage_multiplier(level)
		_expect(is_equal_approx(multiplier, expected[level]),
			"chain %d damage multiplier should be %.2f, got %.4f" % [level, expected[level], multiplier])

	seed(20261109)
	var chain1 := DamageCalculatorScript.calc_player_damage(100.0, "fire", 0.0, 3, 1)
	seed(20261109)
	var chain2 := DamageCalculatorScript.calc_player_damage(100.0, "fire", 0.0, 3, 2)
	seed(20261109)
	var chain4 := DamageCalculatorScript.calc_player_damage(100.0, "fire", 0.0, 3, 4)
	_expect(chain2 > chain1, "second chain should deal more damage than a single match")
	_expect(chain4 > chain2, "fourth chain should deal more damage than the second chain")
	_expect(DamageCalculatorScript.chain_damage_multiplier(7) == DamageCalculatorScript.chain_damage_multiplier(5),
		"chain damage bonus should stop growing after the third chain")


func _test_chain_audio() -> void:
	var sfx = ComboSfxScript.new()
	root.add_child(sfx)
	_expect(is_equal_approx(ComboSfxScript.pitch_scale_for_chain(2), 1.0),
		"second chain should use the base pitch")
	var pitch2 := ComboSfxScript.pitch_scale_for_chain(2)
	var pitch3 := ComboSfxScript.pitch_scale_for_chain(3)
	var pitch4 := ComboSfxScript.pitch_scale_for_chain(4)
	var pitch5 := ComboSfxScript.pitch_scale_for_chain(5)
	_expect(pitch3 > pitch2 and pitch4 > pitch3 and pitch5 > pitch4,
		"each chain level should raise the pitch")
	var stream = sfx.get_tone_stream()
	_expect(stream is AudioStreamWAV, "combo sfx should generate an AudioStreamWAV")
	if stream is AudioStreamWAV:
		_expect(stream.data.size() > 1000, "combo sfx should contain audible samples")
		_expect(stream.format == AudioStreamWAV.FORMAT_16_BITS, "combo sfx should use 16-bit PCM")
	sfx.play_chain(3)
	sfx.stop_all()
	sfx.free()


func _test_battle_scene_chain_display() -> void:
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
	var battle: Control = main.get_current_scene()
	_expect(battle != null, "battle scene should be available")

	if battle != null:
		battle.call("_show_chain_combo", 2)
		_expect(int(battle.get("_chain_display").get("level", 0)) == 2, "second chain should show 2 连锁")
		battle.call("_show_chain_combo", 4)
		_expect(int(battle.get("_chain_display").get("level", 0)) == 4, "fourth chain should update the label")

		var rect: Rect2 = battle.call("get_chain_display_rect", 1.14)
		_expect(rect.position.y > 284.0, "chain display should stay below player portraits and HP bars")
		_expect(rect.end.y < 622.0, "chain display should stay above bottom controls")
		_expect(rect.position.x > 0.0 and rect.end.x < 375.0, "chain display should stay inside the screen")
		var damage_points: Array[Vector2] = [
			BattleAnimationControllerScript.enemy_damage_anchor(1, 0),
			BattleAnimationControllerScript.player_damage_anchor(0),
			BattleAnimationControllerScript.player_damage_anchor(2),
		]
		for point: Vector2 in damage_points:
			_expect(not rect.has_point(point), "chain display should not cover damage numbers at %s" % str(point))

		battle.call("_clear_chain_combo")
		_expect(int(battle.get("_chain_display").get("level", 0)) == 0, "broken chain should hide the display")

	main.queue_free()
	await process_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[ComboChain] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[ComboChain] " + failure)
	quit(1)
