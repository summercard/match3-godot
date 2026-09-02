extends SceneTree

const MonsterArtDBScript := preload("res://src/data/monster_art_db.gd")
const MonsterIdleAnimatorScript := preload("res://src/ui/components/monster_idle_animator.gd")
const ANIMATED_IDS: Array[String] = [
	"monster_001",
	"monster_002",
	"monster_003",
	"monster_004",
	"monster_005",
	"monster_006",
	"monster_007",
	"monster_008",
	"monster_009",
	"monster_010",
	"monster_011",
	"monster_012",
	"monster_013",
	"monster_014",
	"monster_015",
	"monster_016",
	"monster_018",
	"monster_019",
	"monster_020",
	"monster_022",
	"monster_023",
	"monster_024",
	"monster_025",
	"monster_026",
	"monster_027",
	"monster_028",
	"monster_029",
	"monster_030",
	"monster_031",
	"monster_032",
	"monster_033",
	"monster_034",
	"monster_035",
	"monster_036",
	"monster_037",
	"monster_038",
	"monster_039",
	"monster_040",
	"monster_041",
	"monster_042",
	"monster_043",
	"monster_044",
	"monster_045",
	"monster_046",
	"monster_047",
	"monster_048",
	"monster_049",
	"monster_050",
	"monster_051",
	"monster_052",
	"monster_053",
	"monster_054",
	"monster_055",
	"monster_056",
	"monster_057",
	"monster_058",
	"monster_059",
	"monster_060",
	"monster_061",
	"monster_062",
	"monster_063",
	"monster_064",
	"monster_065",
	"monster_066",
	"monster_067",
	"monster_068",
	"monster_069",
	"monster_070",
	"monster_071",
	"monster_072",
	"monster_073",
	"monster_074",
	"monster_075",
	"monster_076",
	"monster_077",
	"monster_078",
	"monster_079",
	"monster_080",
	"monster_081",
	"monster_082",
	"monster_083",
	"monster_084",
	"monster_085",
	"monster_086",
	"monster_087",
	"monster_088",
	"monster_089",
	"monster_090",
	"monster_091",
	"monster_092",
	"monster_093",
	"monster_094",
	"monster_095",
	"monster_096",
	"monster_097",
	"monster_098",
	"monster_099",
	"monster_100",
	"monster_101",
	"monster_102",
	"monster_103",
	"monster_boss_001",
	"monster_boss_002",
	"monster_boss_003",
	"monster_boss_004",
	"monster_boss_005",
	"monster_boss_006",
	"monster_boss_007",
	"monster_boss_008",
]
const FRAME_COUNT := 16
const FPS := 8.0
const FRAME_DURATION_SECONDS := 1.0 / FPS

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	seed(0x13579)
	var random_start_frames := {}
	for monster_id in ANIMATED_IDS:
		var fallback_path := MonsterArtDBScript.get_battle_portrait_path(monster_id)
		_expect(fallback_path.ends_with("/%s.png" % monster_id), "%s should retain its static fallback portrait" % monster_id)
		_expect(MonsterArtDBScript.has_animation(monster_id), "%s should register an idle animation" % monster_id)
		var info := MonsterArtDBScript.get_animation_info(monster_id)
		_expect(int(info.get("frame_count", 0)) == FRAME_COUNT, "%s idle animation should register 16 frames" % monster_id)
		_expect(is_equal_approx(float(info.get("fps", 0.0)), FPS), "%s idle animation should use the normal 8 FPS playback rate" % monster_id)
		_expect(bool(info.get("loop", false)), "%s idle animation should be marked as looping" % monster_id)
		var paths := MonsterArtDBScript.get_animation_frame_paths(monster_id)
		_expect(paths.size() == FRAME_COUNT, "%s should resolve all 16 idle frame paths" % monster_id)
		var raw_frame_hashes := {}
		var normalized_pose_hashes := {}
		for frame_index in paths.size():
			var path := paths[frame_index]
			_expect(path.ends_with("/idle/idle_%03d.png" % frame_index), "%s frame %d should follow idle_000 naming" % [monster_id, frame_index])
			var frame := load(path) as Texture2D
			_expect(frame != null, "%s idle_%03d should load" % [monster_id, frame_index])
			if frame != null:
				_expect(frame.get_size() == Vector2(256.0, 256.0), "%s idle_%03d should be 256x256" % [monster_id, frame_index])
				var image := frame.get_image()
				raw_frame_hashes[hash(image.get_data())] = true
				var used_rect := image.get_used_rect()
				var normalized_pose := image.get_region(used_rect)
				normalized_pose.resize(96, 96, Image.INTERPOLATE_LANCZOS)
				normalized_pose_hashes[hash(normalized_pose.get_data())] = true
		_expect(raw_frame_hashes.size() == FRAME_COUNT, "%s should contain 16 distinct rendered frames" % monster_id)
		_expect(normalized_pose_hashes.size() >= 12, "%s should contain genuine internal pose changes after position/size normalization" % monster_id)
		_expect(MonsterArtDBScript.get_animation_frame_path(monster_id, "idle", FRAME_COUNT).ends_with("idle_000.png"), "%s frame 16 should wrap to frame 0" % monster_id)
		_expect(MonsterArtDBScript.get_animation_frame_path(monster_id, "idle", -1).ends_with("idle_015.png"), "%s frame -1 should wrap to frame 15" % monster_id)
		var preview := TextureRect.new()
		preview.size = Vector2(256.0, 256.0)
		root.add_child(preview)
		var controller = MonsterIdleAnimatorScript.bind(preview, monster_id)
		_expect(controller != null, "%s should bind a runtime idle controller" % monster_id)
		if controller == null:
			preview.queue_free()
			continue
		var initial_frame := int(controller.get_frame_index())
		_expect(initial_frame >= 0 and initial_frame < FRAME_COUNT, "%s controller should choose a valid random start frame" % monster_id)
		random_start_frames[initial_frame] = true
		var offset_preview := MonsterIdleAnimatorScript.texture_at_time(monster_id, 0.0, "idle", 5)
		var frame_five := load(paths[5]) as Texture2D
		_expect(offset_preview == frame_five, "%s time-based drawing should honor a randomized start-frame offset" % monster_id)
		controller.seek_frame(FRAME_COUNT - 1)
		controller.set_process(false)
		controller._process(FRAME_DURATION_SECONDS * 1.01)
		_expect(controller.get_frame_index() == 0, "%s idle animation should loop from idle_015 to idle_000" % monster_id)
		var frame_zero := load(paths[0]) as Texture2D
		_expect(preview.texture == frame_zero, "%s loop should display idle_000 after wrapping" % monster_id)
		preview.queue_free()

	_expect(random_start_frames.size() > 1, "runtime controllers should not all start on the same fixed frame")
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[MonsterIdleAnimation] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[MonsterIdleAnimation] " + failure)
	quit(1)
