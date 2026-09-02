extends SceneTree

const SequenceDb := preload("res://src/data/leader_skill_vfx_sequence_db.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var caster := Vector2(100.0, 500.0)
	var target := Vector2(250.0, 140.0)
	var fire := SequenceDb.build_playback("fire", caster, target)
	_expect(fire.size() == 4, "fireball should compose release, sprite, trail, and hit")
	_expect(str(fire[0].get("anchor", "")) == "caster" and fire[0].get("center") == caster, "release block should bind to caster center")
	_expect(float(fire[0].get("duration", 0.0)) == 0.50, "fire release should hold for 0.5 seconds")
	_expect(str(fire[1].get("anchor", "")) == "path" and fire[1].get("from") == caster and fire[1].get("to") == target, "fireball sprite should bind to both endpoints")
	_expect(str(fire[2].get("kind", "")) == "block_fireball_trail" and float(fire[2].get("delay", 0.0)) == 0.20, "trail should start with the fireball node after the configured delay")
	_expect(float(fire[1].get("duration", 0.0)) == 1.00 and float(fire[1].get("arc_degrees", 0.0)) == 15.0, "fireball should fly for one second on a 15 degree arc")
	_expect(int(fire[0].get("particle_count", 0)) == 7, "fire release should expose configurable random sparks")
	_expect(int(fire[2].get("particle_count", 0)) == 8 and float(fire[2].get("particle_birth_range", 0.0)) == 0.16, "trail should expose randomized birth parameters")
	_expect(int(fire[3].get("particle_count", 0)) == 12 and float(fire[3].get("particle_spread", 0.0)) == 48.0, "impact should expose configurable random explosion parameters")
	_expect(SequenceDb.stable_noise(23.0, 5.0) == SequenceDb.stable_noise(23.0, 5.0), "particle noise should stay stable between redraws")
	var mid_motion := SequenceDb.sample_flight_motion(fire[1], 0.5)
	var midpoint := caster.lerp(target, 0.5)
	var sampled_midpoint: Vector2 = mid_motion.get("position", midpoint)
	_expect(sampled_midpoint.distance_to(midpoint) > 10.0, "fireball midpoint should bow away from the straight line")
	var start_motion := SequenceDb.sample_flight_motion(fire[1], 0.0)
	var end_motion := SequenceDb.sample_flight_motion(fire[1], 1.0)
	var sampled_start: Vector2 = start_motion.get("position", Vector2.ZERO)
	var sampled_end: Vector2 = end_motion.get("position", Vector2.ZERO)
	_expect(sampled_start.distance_to(caster) < 0.01 and sampled_end.distance_to(target) < 0.01, "arc should begin at caster and end at target")
	var forward: Vector2 = start_motion.get("direction", Vector2.UP)
	var y_axis := Vector2.DOWN.rotated(float(start_motion.get("rotation", 0.0)))
	_expect(y_axis.dot(forward) > 0.999, "fireball local Y axis should face its flight tangent")
	_expect(str(fire[3].get("anchor", "")) == "target" and float(fire[3].get("delay", 0.0)) == 1.20, "impact should start on target when the flight arrives")
	_expect(SequenceDb.get_impact_start("fire") == 1.20, "battle hit timing should follow the fireball arrival")
	_expect(SequenceDb.get_total_duration("fire") == 1.58, "fireball total duration should include the impact burst")
	var balanced := SequenceDb.build_playback("balanced", caster, target)
	_expect(balanced.size() == 2, "balanced should only compose release and heal hit")
	_expect(str(balanced[0].get("kind", "")) == "block_heal_release" and str(balanced[0].get("anchor", "")) == "caster", "balanced should release green healing from caster")
	_expect(str(balanced[1].get("kind", "")) == "block_heal_rise" and str(balanced[1].get("anchor", "")) == "target", "balanced should raise heal bars on target")
	_expect(float(balanced[1].get("delay", 0.0)) == 0.18 and float(balanced[1].get("bar_height", 0.0)) == 70.0, "balanced heal bars should use the configured rise timing and height")
	_expect(not str(balanced[0].get("layer", "")) in ["flight", "link"] and not str(balanced[1].get("layer", "")) in ["flight", "link"], "balanced should not use a flight or link layer")
	var speed := SequenceDb.build_playback("speed", caster, target)
	_expect(speed.size() == 3, "wind should compose release, persistent lightning link, and hit")
	_expect(str(speed[1].get("kind", "")) == "block_wind_lightning_link" and str(speed[1].get("layer", "")) == "link", "wind should use a dedicated path-bound lightning link")
	_expect(str(speed[2].get("kind", "")) == "block_wind_lightning_hit" and str(speed[2].get("anchor", "")) == "target", "wind should use a dedicated target-bound lightning hit")
	_expect(is_equal_approx(float(speed[1].get("delay", 0.0)), 0.10) and is_equal_approx(float(speed[2].get("delay", 0.0)), 0.10), "wind link and hit should begin together after the release")
	_expect(is_equal_approx(float(speed[1].get("duration", 0.0)), 1.00) and is_equal_approx(float(speed[2].get("duration", 0.0)), 1.00), "wind link and hit should remain visible for one second")
	var lightning_points := SequenceDb.sample_lightning_link(speed[1], 0.5)
	_expect(lightning_points.size() == 11 and lightning_points[0].distance_to(caster) < 0.01 and lightning_points[lightning_points.size() - 1].distance_to(target) < 0.01, "lightning curve should preserve the caster and target endpoints")
	_expect(lightning_points[5].distance_to(caster.lerp(target, 0.5)) > 1.0, "lightning link should bend around its fixed baseline")
	_expect(is_equal_approx(SequenceDb.get_total_duration("speed"), 1.10), "wind total duration should include one second of sustained link and hit")
	var group_targets: Array[Vector2] = [target, Vector2(120.0, 160.0), Vector2(360.0, 170.0)]
	var heal := SequenceDb.build_playback_for_targets("heal", caster, target, group_targets)
	_expect(heal.size() == 4, "group heal should compose one release and one hit for every target")
	_expect(str(heal[0].get("kind", "")) == "block_gold_heal_release", "group heal should start with a gold release")
	var gold_hit_count := 0
	for entry: Dictionary in heal:
		if str(entry.get("kind", "")) == "block_gold_heal_rise":
			gold_hit_count += 1
			_expect(str(entry.get("target_scope", "")) == "all_targets", "gold heal hits should retain the all-target scope")
	_expect(gold_hit_count == group_targets.size(), "group heal should create a gold target effect for every target")
	_expect(not SequenceDb.uses_target_scope("heal", "flight") and SequenceDb.uses_target_scope("heal", "all_targets"), "group heal should have all-target scope without a flight layer")
	var chain_target := Vector2(120.0, 160.0)
	var tidal := SequenceDb.build_playback_for_chain("guard", caster, target, chain_target)
	_expect(tidal.size() == 5, "tidal should compose release, large ball, splash, small ball, and chain splash")
	_expect(str(tidal[1].get("kind", "")) == "block_tidal_big_ball" and tidal[1].get("from") == caster and tidal[1].get("to") == target, "large tidal ball should fly from caster A to first target B")
	_expect(float(tidal[1].get("duration", 0.0)) == 0.64 and float(tidal[1].get("duration", 0.0)) < float(fire[1].get("duration", 0.0)), "large tidal ball should fly faster than fireball")
	_expect(str(tidal[2].get("kind", "")) == "block_tidal_splash" and tidal[2].get("center") == target, "first tidal splash should occur on B")
	_expect(str(tidal[3].get("kind", "")) == "block_tidal_small_ball" and tidal[3].get("from") == target and tidal[3].get("to") == chain_target, "small tidal ball should use B as the new flight origin and travel to C")
	_expect(str(tidal[4].get("kind", "")) == "block_tidal_chain_splash" and tidal[4].get("center") == chain_target, "chain splash should occur on C")
	var bulwark := SequenceDb.build_playback("bulwark", caster, target)
	_expect(bulwark.size() == 9, "bulwark should expand three release, flight, and impact passes")
	var rock_releases: Array = []
	var rock_flights: Array = []
	var rock_impacts: Array = []
	for entry: Dictionary in bulwark:
		match str(entry.get("kind", "")):
			"block_rock_release":
				rock_releases.append(entry)
			"block_rock_flight":
				rock_flights.append(entry)
			"block_rock_impact":
				rock_impacts.append(entry)
	_expect(rock_releases.size() == 3 and rock_flights.size() == 3 and rock_impacts.size() == 3, "bulwark should keep three instances of every rock presentation step")
	for i in range(3):
		_expect(is_equal_approx(float(rock_releases[i].get("delay", -1.0)), float(i) * 0.30), "each rock release should be spaced by 0.3 seconds")
		_expect(is_equal_approx(float(rock_flights[i].get("delay", -1.0)), 0.08 + float(i) * 0.30), "each rock flight should retain its 0.08 second release overlap")
		_expect(is_equal_approx(float(rock_impacts[i].get("delay", -1.0)), 0.80 + float(i) * 0.30), "each rock should impact when its flight reaches B")
		_expect(int(rock_flights[i].get("repeat_index", -1)) == i and float(rock_flights[i].get("size", 0.0)) == 48.0, "repeated rocks should share their configured body while retaining an instance index")
		_expect(float(rock_flights[i].get("arc_degrees", 0.0)) >= 8.0 and float(rock_flights[i].get("arc_degrees", 0.0)) <= 22.0, "every rock arc should stay in the configured random angle range")
		_expect(absf(float(rock_flights[i].get("arc_direction", 0.0))) == 1.0 and absf(float(rock_flights[i].get("roll_direction", 0.0))) == 1.0, "rock arc and rolling direction should be resolved once per instance")
	_expect(is_equal_approx(SequenceDb.get_total_duration("bulwark"), 1.72), "bulwark total duration should include the third impact")
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[LeaderSkillVfxSequence] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[LeaderSkillVfxSequence] " + failure)
	quit(1)
