## main.gd — 项目入口
## 管理场景切换；已迁移界面使用可编辑 PackedScene。
extends Control

const DESIGN_SIZE: Vector2 = Vector2(375.0, 667.0)
const TARGET_FPS: int = 60
const CartoonTypographyScript := preload("res://src/ui/components/cartoon_typography.gd")

# 场景映射：场景名 → 脚本路径
const PACKED_SCENE_MAP: Dictionary = {
	"start": "res://src/ui/scenes/start_screen.tscn",
	"main": "res://src/ui/scenes/main_lobby.tscn",
	"ranch": "res://src/ui/scenes/ranch_hub.tscn",
	"stage_select": "res://src/ui/scenes/stage_select_map.tscn",
	"battle_prepare": "res://src/ui/scenes/battle_prepare.tscn",
	"battle": "res://src/ui/scenes/battle_screen.tscn",
	"tower_battle": "res://src/ui/scenes/tower_battle.tscn",
	"result": "res://src/ui/scenes/battle_result.tscn",
	"team": "res://src/ui/scenes/team.tscn",
	"album": "res://src/ui/scenes/album.tscn",
	"inventory": "res://src/ui/scenes/inventory.tscn",
	"shop": "res://src/ui/scenes/shop.tscn",
	"achievement": "res://src/ui/scenes/achievement.tscn",
	"settings": "res://src/ui/scenes/settings.tscn",
	"sign_in": "res://src/ui/scenes/sign_in.tscn",
	"tutorial": "res://src/ui/scenes/tutorial.tscn",
	"leader_skill_test": "res://src/ui/scenes/leader_skill_test.tscn",
	"tower": "res://src/ui/scenes/tower.tscn",
	"mailbox": "res://src/ui/scenes/mailbox.tscn",
}

var _current_scene: Control = null
var _current_scene_name: String = ""
var _letterbox_bg: ColorRect = null

func _ready() -> void:
	_apply_runtime_performance_defaults()
	_configure_debug_window()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_create_letterbox_background()
	var localization := get_node_or_null("/root/Localization")
	if localization != null and localization.has_signal("locale_changed"):
		localization.locale_changed.connect(_on_locale_changed)
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
func switch_scene(scene_name: String, data: Dictionary = {}, _mode: String = "") -> bool:
	# Load scenes only from PackedScene files.
	if not PACKED_SCENE_MAP.has(scene_name):
		push_warning("Scene not found: " + scene_name)
		return false
	
	var scene_node: Control = null
	var packed_path: String = PACKED_SCENE_MAP[scene_name]
	var packed_scene: PackedScene = load(packed_path) as PackedScene
	if packed_scene == null:
		push_warning("Cannot load scene: " + packed_path)
		return false
	scene_node = packed_scene.instantiate() as Control

	if scene_node == null:
		push_warning("Cannot instantiate scene: " + scene_name)
		return false

	scene_node.anchor_left = 0.0
	scene_node.anchor_top = 0.0
	scene_node.anchor_right = 0.0
	scene_node.anchor_bottom = 0.0
	scene_node.size = DESIGN_SIZE
	scene_node.custom_minimum_size = DESIGN_SIZE
	scene_node.clip_contents = true
	scene_node.mouse_filter = Control.MOUSE_FILTER_STOP
	scene_node.name = scene_name.capitalize().replace(" ", "")
	
	var previous_scene := _current_scene
	add_child(scene_node)
	_current_scene = scene_node
	_current_scene_name = scene_name
	var typography_profile := "lobby" if scene_name in ["main", "result"] else scene_name
	_layout_current_scene()
	_initialize_scene(scene_node, scene_name, data)
	CartoonTypographyScript.apply(scene_node, typography_profile)
	if previous_scene != null:
		previous_scene.queue_free()
	return true


func _on_locale_changed(_locale: String, _preference: String) -> void:
	if _current_scene == null:
		return
	var typography_profile := "lobby" if _current_scene_name in ["main", "result"] else _current_scene_name
	CartoonTypographyScript.apply(_current_scene, typography_profile)
	_queue_redraw_tree(_current_scene)


func _queue_redraw_tree(node: Node) -> void:
	if node is CanvasItem:
		(node as CanvasItem).queue_redraw()
	for child in node.get_children():
		_queue_redraw_tree(child)

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
	if scene_node.has_signal("shop_pressed"):
		scene_node.shop_pressed.connect(func(): _request_scene_switch("shop"))
	if scene_node.has_signal("inventory_pressed"):
		scene_node.inventory_pressed.connect(func(): _request_scene_switch("inventory"))
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
		"settings": "settings",
		"tower": "tower",
		"mailbox": "mailbox",
		"test_tool": "leader_skill_test"
	}
	if not targets.has(btn_id):
		return
	var data: Dictionary = {}
	if btn_id == "start":
		data = _resolve_latest_stage()
	elif btn_id == "ranch":
		data = {"page": "classroom"}
	_request_scene_switch(targets[btn_id], data)

## 计算用户当前可玩的"最新关卡"：
## 找到第一个 unlocked 且未 cleared 的关卡；都打完则回退到第一章第一关。
## 返回 Dictionary { "chapterIndex": int, "focusStageId": String }。
func _resolve_latest_stage() -> Dictionary:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null:
		return {"chapterIndex": 0, "focusStageId": ""}
	if not save_manager.has_method("get_stage_chapters"):
		return {"chapterIndex": 0, "focusStageId": ""}
	var chapters: Array = save_manager.call("get_stage_chapters")
	if chapters.is_empty():
		return {"chapterIndex": 0, "focusStageId": ""}
	for ci in chapters.size():
		var chapter: Dictionary = chapters[ci]
		var stages: Array = chapter.get("stages", [])
		for si in stages.size():
			var stage: Dictionary = stages[si]
			var stage_id: String = str(stage.get("id", ""))
			var unlocked: bool = bool(save_manager.call("is_stage_unlocked", stage_id))
			var cleared: bool = bool(save_manager.call("is_stage_cleared", stage_id))
			if unlocked and not cleared:
				return {"chapterIndex": ci, "focusStageId": stage_id}
	# 全部通关或无存档：回到第一章第一关，让 stage_select 自己用默认滚动
	return {"chapterIndex": 0, "focusStageId": ""}

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
