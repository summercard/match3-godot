extends SceneTree

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: Control = load("res://src/ui/scene/scene_battle.gd").new() as Control
	_expect(scene != null, "scene_battle.gd should load")
	if scene != null:
		scene.call("_start_leader_burst_showcase", {
			"leader_index": 1,
			"skill_name": "Leader Burst QA",
			"element": "fire"
		})
		var showcase: Dictionary = scene.call("get_leader_burst_showcase_test_profile")
		_expect(bool(showcase.get("active", false)), "battle should expose an active leader burst showcase")
		_expect(int(showcase.get("leader_index", -1)) == 1, "leader burst showcase should track the promoted leader index")
		_expect(str(showcase.get("skill_name", "")) == "Leader Burst QA", "leader burst showcase should keep the skill name visible")
		_expect(is_equal_approx(float(showcase.get("scale", 0.0)), 1.5), "leader burst showcase should enlarge the portrait to 1.5x")
		_expect(float(showcase.get("scale_in", 0.0)) >= 1.0, "leader burst portrait scale-in should take 1s")
		_expect(float(showcase.get("banner", 0.0)) >= 1.0, "leader burst skill name banner should take 1s")
		_expect(float(showcase.get("banner_text_size", 0.0)) >= 40.0, "leader burst skill name should render at 2x text size")
		_expect(str(showcase.get("text_rendering", "")) == "crisp_outline", "leader burst text should use crisp single-pass outline rendering")
		_expect(float(showcase.get("scale_out", 0.0)) >= 0.5, "leader burst portrait scale-out should take 0.5s")
		_expect(float(showcase.get("effect_hold", 0.0)) >= 2.0, "leader burst effects should hold text for 2s")
		_expect(float(showcase.get("restore", 0.0)) >= 0.5, "leader burst dark overlay should restore for 0.5s")
		scene.queue_free()
	_expect(ResourceLoader.exists("res://assets/images/ui/leader_skills/particles/leader_fx_mote.png"), "leader mote texture should exist")
	_expect(ResourceLoader.exists("res://assets/images/ui/leader_skills/particles/leader_fx_shard.png"), "leader shard texture should exist")
	_expect(ResourceLoader.exists("res://assets/images/ui/leader_skills/particles/leader_fx_fire_particle.png"), "leader fire particle texture should exist")
	for tone in ["fire", "balanced", "heal", "speed", "guard", "bulwark", "siphon", "chain"]:
		var profile := LeaderSkillVisualDb.get_profile(tone)
		_expect(str(profile.get("id", "")) == tone, "%s visual profile should resolve" % tone)
		var asset_path := str(profile.get("asset", ""))
		_expect(ResourceLoader.exists(asset_path), "%s visual VFX texture should exist" % tone)
		_expect(str(profile.get("motion", "")).length() > 0, "%s visual profile should expose motion timing" % tone)
		_expect(int(profile.get("particleBudget", 0)) > 0 and int(profile.get("particleBudget", 0)) <= 8, "%s particle budget should stay bounded" % tone)
		_check_asset_alpha(tone, asset_path)
	_check_motion_curves()
	_finish()


func _check_asset_alpha(tone: String, asset_path: String) -> void:
	var image := Image.new()
	var err := image.load(ProjectSettings.globalize_path(asset_path))
	_expect(err == OK, "%s VFX PNG should be readable for art QA" % tone)
	if err != OK:
		return
	_expect(image.get_width() == 512 and image.get_height() == 512, "%s VFX texture should be 512x512 1:1" % tone)
	var corners := [
		image.get_pixel(0, 0).a,
		image.get_pixel(image.get_width() - 1, 0).a,
		image.get_pixel(0, image.get_height() - 1).a,
		image.get_pixel(image.get_width() - 1, image.get_height() - 1).a
	]
	for a in corners:
		_expect(a <= 0.02, "%s VFX texture corners should be transparent" % tone)
	var opaque_count := 0
	var solid_count := 0
	var soft_count := 0
	var white_opaque_count := 0
	var total := image.get_width() * image.get_height()
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var c := image.get_pixel(x, y)
			if c.a > 0.08:
				opaque_count += 1
			if c.a > 0.94:
				solid_count += 1
			elif c.a > 0.12:
				soft_count += 1
			if c.a > 0.86 and c.r > 0.94 and c.g > 0.94 and c.b > 0.94:
				white_opaque_count += 1
	var coverage := float(opaque_count) / float(total)
	var solid_ratio := float(solid_count) / maxf(1.0, float(opaque_count))
	var soft_ratio := float(soft_count) / maxf(1.0, float(opaque_count))
	var white_ratio := float(white_opaque_count) / float(total)
	if tone == "fire":
		_expect(coverage > 0.16 and coverage < 0.34, "fire VFX texture should be a particle sheet, not a thin ring or full background")
		_expect(str(LeaderSkillVisualDb.get_dispatch("fire")) == "fire_burst", "fire visual should dispatch through the particle burst renderer")
		_expect(str(LeaderSkillVisualDb.get_asset_path("fire")).contains("leader_fx_fire_particle"), "fire visual should use the dedicated flame particle texture")
	else:
		_expect(coverage > 0.035 and coverage < 0.18, "%s VFX texture should have ring coverage, not blank or full background" % tone)
	_expect(solid_ratio > 0.82, "%s VFX texture body should be solid, not mostly semi-transparent" % tone)
	_expect(soft_ratio < 0.18, "%s VFX texture should keep semitransparency only on antialiasing edges" % tone)
	_expect(white_ratio < 0.012, "%s VFX texture should not contain a white opaque background" % tone)


func _check_motion_curves() -> void:
	_expect(LeaderSkillVisualDb.get_motion_scale("balanced", 0.85, "impact") >= LeaderSkillVisualDb.get_motion_scale("balanced", 0.30, "impact"), "attack motion should not shrink after impact")
	_expect(LeaderSkillVisualDb.get_motion_scale("fire", 0.45, "impact") > LeaderSkillVisualDb.get_motion_scale("balanced", 0.45, "impact"), "fire motion should hit harder than balanced impact")
	_expect(LeaderSkillVisualDb.get_motion_scale("chain", 0.55, "impact") > LeaderSkillVisualDb.get_motion_scale("chain", 0.10, "impact"), "chain motion should snap outward quickly")
	_expect(LeaderSkillVisualDb.get_motion_scale("heal", 0.50, "ally") > LeaderSkillVisualDb.get_motion_scale("heal", 0.05, "ally"), "heal motion should bloom softly")
	_expect(LeaderSkillVisualDb.get_motion_scale("guard", 0.45, "shell") < LeaderSkillVisualDb.get_motion_scale("chain", 0.45, "impact"), "guard motion should be steadier than chain attack")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[LeaderSkillVisualAsset] OK")
		quit(0)
	for failure: String in _failures:
		push_error("[LeaderSkillVisualAsset] " + failure)
	quit(1)
