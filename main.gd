## main.gd — 项目入口
## 管理场景切换；大厅使用可编辑 PackedScene，其余页面维持动态脚本加载。
extends Control

const DESIGN_SIZE: Vector2 = Vector2(375.0, 667.0)
const TARGET_FPS: int = 60

# 场景映射：场景名 → 脚本路径
const SCENE_MAP: Dictionary = {
	"start": "res://src/ui/scene/scene_start.gd",
	"main": "res://src/ui/scene/scene_main.gd",
	"stage_select": "res://src/ui/scene/scene_stage_select.gd",
	"battle_prepare": "res://src/ui/scene/scene_battle_prepare.gd",
	"battle": "res://src/ui/scene/scene_battle.gd",
	"result": "res://src/ui/scene/scene_result.gd",
	"team": "res://src/ui/scene/scene_team.gd",
	"album": "res://src/ui/scene/scene_album.gd",
	"evolve": "res://src/ui/scene/scene_evolve.gd",
	"ranch": "res://src/ui/scene/scene_ranch.gd",
	"shop": "res://src/ui/scene/scene_shop.gd",
	"inventory": "res://src/ui/scene/scene_inventory.gd",
	"achievement": "res://src/ui/scene/scene_achievement.gd",
	"settings": "res://src/ui/scene/scene_settings.gd",
	"sign_in": "res://src/ui/scene/scene_sign_in.gd",
	"tutorial": "res://src/ui/scene/scene_tutorial.gd",
}

const PACKED_SCENE_MAP: Dictionary = {
	"main": "res://src/ui/scenes/main_lobby.tscn",
}

var _current_scene: Control = null
var _current_scene_name: String = ""
var _letterbox_bg: ColorRect = null

func _ready() -> void:
	_apply_runtime_performance_defaults()
	_configure_debug_window()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_create_letterbox_background()
	# 启动时加载开始画面
	switch_scene("start")

func _apply_runtime_performance_defaults() -> void:
	if Engine.max_fps <= 0 or Engine.max_fps > TARGET_FPS:
		Engine.max_fps = TARGET_FPS
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)

func _configure_debug_window() -> void:
	if DisplayServer.get_name() == "headless" or OS.has_feature("mobile"):
		return
	var override_w := int(ProjectSettings.get_setting("display/window/size/window_width_override", 0))
	var override_h := int(ProjectSettings.get_setting("display/window/size/window_height_override", 0))
	var window_size := Vector2i(override_w, override_h)
	if window_size.x <= 0 or window_size.y <= 0:
		window_size = Vector2i(int(DESIGN_SIZE.x), int(DESIGN_SIZE.y))
	DisplayServer.window_set_min_size(Vector2i(int(DESIGN_SIZE.x), int(DESIGN_SIZE.y)))
	var screen_rect := DisplayServer.screen_get_usable_rect()
	var centered_pos := screen_rect.position + (screen_rect.size - window_size) / 2
	DisplayServer.window_set_position(centered_pos)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_current_scene()

func _create_letterbox_background() -> void:
	_letterbox_bg = ColorRect.new()
	_letterbox_bg.name = "LetterboxBackground"
	_letterbox_bg.color = Color(0.03, 0.05, 0.10, 1.0)
	_letterbox_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_letterbox_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_letterbox_bg.z_index = -100
	add_child(_letterbox_bg)

## 切换场景（淡入淡出过渡）
func switch_scene(scene_name: String, data: Dictionary = {}, _mode: String = "") -> void:
	# 移除当前场景
	if _current_scene != null:
		_current_scene.queue_free()
		_current_scene = null
	
	# 加载新场景
	if not SCENE_MAP.has(scene_name) and not PACKED_SCENE_MAP.has(scene_name):
		push_error("场景不存在: " + scene_name)
		return
	
	var scene_node: Control = null
	if PACKED_SCENE_MAP.has(scene_name):
		var packed_path: String = PACKED_SCENE_MAP[scene_name]
		var packed_scene: PackedScene = load(packed_path) as PackedScene
		if packed_scene == null:
			push_error("无法加载场景: " + packed_path)
			return
		scene_node = packed_scene.instantiate() as Control
	else:
		var script_path: String = SCENE_MAP[scene_name]
		var script: GDScript = load(script_path) as GDScript
		if script == null:
			push_error("无法加载脚本: " + script_path)
			return
		scene_node = Control.new()
		scene_node.set_script(script)

	if scene_node == null:
		push_error("无法实例化场景: " + scene_name)
		return

	scene_node.anchor_left = 0.0
	scene_node.anchor_top = 0.0
	scene_node.anchor_right = 0.0
	scene_node.anchor_bottom = 0.0
	scene_node.size = DESIGN_SIZE
	scene_node.custom_minimum_size = DESIGN_SIZE
	scene_node.clip_contents = true
	scene_node.mouse_filter = Control.MOUSE_FILTER_STOP
	scene_node.name = scene_name.capitalize().replace(" ", "")
	
	# 添加为子节点
	add_child(scene_node)
	_current_scene = scene_node
	_current_scene_name = scene_name
	_layout_current_scene()
	_initialize_scene(scene_node, scene_name, data)

func _layout_current_scene() -> void:
	if _current_scene == null:
		return
	var viewport_size := size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = DESIGN_SIZE
	_current_scene.anchor_left = 0.0
	_current_scene.anchor_top = 0.0
	_current_scene.anchor_right = 0.0
	_current_scene.anchor_bottom = 0.0
	_current_scene.scale = Vector2.ONE
	_current_scene.position = (viewport_size - DESIGN_SIZE) * 0.5
	_current_scene.size = DESIGN_SIZE

func _initialize_scene(scene_node: Control, scene_name: String, data: Dictionary) -> void:
	if scene_node.has_method("init"):
		scene_node.init(data)
	if scene_node.has_signal("button_pressed"):
		scene_node.button_pressed.connect(_on_scene_button_pressed)
	if scene_node.has_signal("stage_selected"):
		scene_node.stage_selected.connect(_on_stage_selected)
	if scene_node.has_signal("battle_started"):
		scene_node.battle_started.connect(_on_battle_started)
	if scene_node.has_signal("back_pressed"):
		scene_node.back_pressed.connect(func(): _request_scene_switch("main"))
	if scene_node.has_signal("tutorial_completed"):
		scene_node.tutorial_completed.connect(func(): _request_scene_switch("main"))

func _request_scene_switch(scene_name: String, data: Dictionary = {}, mode: String = "") -> void:
	var scene_manager := get_node_or_null("/root/SceneManager")
	if scene_manager and scene_manager.has_method("switch_scene"):
		scene_manager.switch_scene(scene_name, data, mode)
	else:
		switch_scene(scene_name, data, mode)

func _on_scene_button_pressed(btn_id: String) -> void:
	var targets: Dictionary = {
		"start": "stage_select",
		"team": "team",
		"album": "album",
		"signin": "sign_in",
		"shop": "shop",
		"inventory": "inventory",
		"ranch": "ranch",
		"achievement": "achievement",
		"settings": "settings"
	}
	if targets.has(btn_id):
		_request_scene_switch(targets[btn_id])

func _on_stage_selected(stage_id: String, stage_data: Dictionary, chapter_index: int) -> void:
	_request_scene_switch("battle_prepare", {
		"stageId": stage_id,
		"stageData": stage_data,
		"chapterIndex": chapter_index
	})

func _on_battle_started(stage_id: String, stage_data: Dictionary) -> void:
	_request_scene_switch("battle", {
		"stageId": stage_id,
		"stageData": stage_data
	})

## 获取当前场景名
func get_current_scene_name() -> String:
	return _current_scene_name

## 获取当前场景节点
func get_current_scene() -> Control:
	return _current_scene
