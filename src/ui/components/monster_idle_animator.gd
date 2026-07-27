class_name MonsterIdleAnimator
extends Node

const MonsterArtDBScript := preload("res://src/data/monster_art_db.gd")
const CONTROLLER_NODE_NAME := "MonsterIdleAnimator"

static var _frame_cache: Dictionary = {}

var _target: TextureRect = null
var _frames: Array = []
var _monster_id := ""
var _animation_name := "idle"
var _elapsed := 0.0
const DEFAULT_IDLE_FPS := 8.0

var _fps := DEFAULT_IDLE_FPS
var _frame_index := 0


static func bind(target: TextureRect, monster_id: String, animation_name: String = "idle"):
	if target == null or not is_instance_valid(target):
		return null
	if not MonsterArtDBScript.has_animation(monster_id, animation_name):
		unbind(target)
		return null
	var controller := target.get_node_or_null(CONTROLLER_NODE_NAME)
	if controller == null:
		controller = MonsterIdleAnimator.new()
		controller.name = CONTROLLER_NODE_NAME
		target.add_child(controller)
	controller.setup_idle(target, monster_id, animation_name)
	return controller


static func unbind(target: TextureRect) -> void:
	if target == null or not is_instance_valid(target):
		return
	var controller := target.get_node_or_null(CONTROLLER_NODE_NAME)
	if controller != null:
		controller.free()


static func random_start_frame(monster_id: String, animation_name: String = "idle") -> int:
	var info := MonsterArtDBScript.get_animation_info(monster_id, animation_name)
	var frame_count := int(info.get("frame_count", 0))
	return randi_range(0, frame_count - 1) if frame_count > 0 else 0


static func texture_at_time(monster_id: String, elapsed: float, animation_name: String = "idle", start_frame: int = 0) -> Texture2D:
	var frames := _load_frames(monster_id, animation_name)
	if frames.is_empty():
		var fallback_path := MonsterArtDBScript.get_battle_portrait_path(monster_id)
		return load(fallback_path) as Texture2D if not fallback_path.is_empty() else null
	var info := MonsterArtDBScript.get_animation_info(monster_id, animation_name)
	var fps := maxf(0.01, float(info.get("fps", DEFAULT_IDLE_FPS)))
	var elapsed_frames := int(floor(maxf(0.0, elapsed) * fps))
	var index := posmod(start_frame + elapsed_frames, frames.size())
	return frames[index] as Texture2D


static func _load_frames(monster_id: String, animation_name: String) -> Array:
	var cache_key := "%s:%s" % [monster_id, animation_name]
	if _frame_cache.has(cache_key):
		return _frame_cache[cache_key]
	var frames: Array = []
	for path in MonsterArtDBScript.get_animation_frame_paths(monster_id, animation_name):
		var texture := load(path) as Texture2D
		if texture == null:
			frames.clear()
			break
		frames.append(texture)
	_frame_cache[cache_key] = frames
	return frames


func setup_idle(target: TextureRect, monster_id: String, animation_name: String = "idle") -> void:
	if _monster_id == monster_id and _animation_name == animation_name and not _frames.is_empty():
		_target = target
		_apply_current_frame()
		return
	_target = target
	_monster_id = monster_id
	_animation_name = animation_name
	_frames = _load_frames(monster_id, animation_name)
	var info := MonsterArtDBScript.get_animation_info(monster_id, animation_name)
	_fps = maxf(0.01, float(info.get("fps", DEFAULT_IDLE_FPS)))
	_frame_index = random_start_frame(monster_id, animation_name)
	_elapsed = float(_frame_index) / _fps
	_apply_current_frame()
	set_process(not _frames.is_empty())


func get_frame_index() -> int:
	return _frame_index


func seek_frame(frame_index: int) -> void:
	if _frames.is_empty():
		return
	_frame_index = posmod(frame_index, _frames.size())
	_elapsed = float(_frame_index) / _fps
	_apply_current_frame()


func _process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target) or _frames.is_empty():
		set_process(false)
		return
	var cycle_seconds := float(_frames.size()) / _fps
	_elapsed = fmod(_elapsed + maxf(0.0, delta), cycle_seconds)
	var next_frame := posmod(int(floor(_elapsed * _fps)), _frames.size())
	if next_frame == _frame_index:
		return
	_frame_index = next_frame
	_apply_current_frame()


func _apply_current_frame() -> void:
	if _target != null and is_instance_valid(_target) and not _frames.is_empty():
		_target.texture = _frames[_frame_index] as Texture2D
