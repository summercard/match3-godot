extends SceneTree

const GHOST_PATH := "res://assets/images/effects/battle_fx_defeated_ghost.png"

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var renderer := load("res://src/ui/components/battle_combatant_renderer.gd")
	_expect(renderer.DEFEATED_GHOST_ASSET == GHOST_PATH, "custom battle renderer should use ghost art")

	var scene := load("res://src/ui/scenes/battle_screen.tscn").instantiate() as Control
	root.add_child(scene)
	await process_frame

	var slot := scene.get_node("Combatants/Players/Player1") as Control
	var defeated := {
		"id": "monster_001",
		"name": "火苗蜥",
		"hp": 0,
		"maxHP": 100,
	}
	scene.call("_set_combatant", slot, defeated, "green")

	var portrait := slot.get_node("Portrait") as TextureRect
	_expect(portrait.texture != null, "defeated portrait should have a texture")
	if portrait.texture != null:
		_expect(portrait.texture.resource_path == GHOST_PATH, "defeated portrait should use ghost art")
	_expect(is_equal_approx(portrait.modulate.a, 1.0), "defeated portrait should not be semi-transparent")

	var enemy_path := NodePath("Combatants/SingleEnemy/Portrait")
	var enemy_portrait := scene.get_node(enemy_path) as TextureRect
	var enemy_id := enemy_portrait.get_instance_id()
	var base_pos := enemy_portrait.position
	var base_pos_cache: Dictionary = scene.get("_portrait_base_pos_cache")
	base_pos_cache[enemy_id] = base_pos
	scene.set("_portrait_base_pos_cache", base_pos_cache)
	var base_center: Vector2 = scene.call("_get_portrait_effect_center", enemy_path, true, 0)
	var transitions: Array = scene.get("_defeat_transitions")
	transitions.append({"isEnemy": true, "index": 0, "timer": 0.5, "duration": 0.7, "maxDuration": 0.7})
	scene.set("_defeat_transitions", transitions)
	enemy_portrait.position = base_pos + Vector2(0.0, 28.0)
	var locked_center: Vector2 = scene.call("_get_portrait_effect_center", enemy_path, true, 0)
	_expect(locked_center.distance_to(base_center) < 0.01, "hit effect center should stay at defeated enemy base position")

	scene.queue_free()
	await process_frame
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[BattleDefeatedGhost] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[BattleDefeatedGhost] " + failure)
	quit(1)
