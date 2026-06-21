extends SceneTree

const Renderer := preload("res://src/ui/components/battle_combatant_renderer.gd")

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_expect(not Renderer.uses_featured_single_layout({"isBoss": false, "isElite": false}), "ordinary single enemies should keep the regular layout")
	_expect(Renderer.uses_featured_single_layout({"isElite": true}), "elite single enemies should use the featured layout")
	_expect(Renderer.uses_featured_single_layout({"isBoss": true}), "boss single enemies should use the featured layout")
	_expect(is_equal_approx(Renderer.SINGLE_BOSS_SPRITE_SIZE, 192.0), "single boss sprite should use the reduced 1.5x featured size")

	var regular_slots: Array[Vector2] = Renderer._multi_enemy_slots(1)
	_expect(regular_slots.size() == 1 and is_equal_approx(regular_slots[0].x + 48.0, 187.5), "ordinary single enemy regular slot should be horizontally centered")
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
