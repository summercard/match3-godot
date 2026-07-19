extends SceneTree

const Renderer := preload("res://src/ui/components/battle_combatant_renderer.gd")

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_expect(not Renderer.uses_featured_single_layout({"isBoss": false, "isElite": false}), "ordinary single enemies should keep the regular layout")
	_expect(Renderer.uses_featured_single_layout({"isElite": true}), "elite single enemies should use the featured layout")
	_expect(Renderer.uses_featured_single_layout({"isBoss": true}), "boss single enemies should use the featured layout")
	_expect(is_equal_approx(Renderer.SINGLE_BOSS_SPRITE_SIZE, 156.0), "single boss sprite should use the finalized 156x156 frame")
	_expect(is_equal_approx(Renderer.SINGLE_ENEMY_SPRITE_SIZE, 156.0), "featured single-enemy fallback should share the finalized 156x156 frame")
	_expect(is_equal_approx(Renderer.MULTI_ENEMY_SPRITE_SIZE, 66.0) and is_equal_approx(Renderer.MULTI_ENEMY_SPRITE_HEIGHT, 60.0), "ordinary enemy fallback should use the finalized 66x60 frame")
	_expect(is_equal_approx(Renderer.STANDARD_ENEMY_CENTER_Y, 151.0), "every enemy layout should share the finalized Y=151 center")

	var regular_slots: Array[Vector2] = Renderer._multi_enemy_slots(1)
	_expect(regular_slots.size() == 1 and is_equal_approx(regular_slots[0].x + 48.0, 187.5) and is_equal_approx(regular_slots[0].y, 84.0), "ordinary single enemy regular slot should produce a centered Rect2(154.5, 121, 66, 60)")
	for enemy_count in [2, 3]:
		for slot: Vector2 in Renderer._multi_enemy_slots(enemy_count):
			_expect(is_equal_approx(slot.y, 84.0), "%d-enemy fallback slots should keep every portrait center at Y=151" % enemy_count)
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[BattleSingleEnemyLayout] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[BattleSingleEnemyLayout] " + failure)
	quit(1)
