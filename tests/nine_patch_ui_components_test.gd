extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scenes := {
		"black_panel": "res://src/ui/components/nine_patch_ui/black_panel.tscn",
		"black2_pill_panel": "res://src/ui/components/nine_patch_ui/black2_pill_panel.tscn",
		"black3_tall_panel": "res://src/ui/components/nine_patch_ui/black3_tall_panel.tscn",
		"butter01_gold_button": "res://src/ui/components/nine_patch_ui/butter01_gold_button.tscn",
		"butter02_blue_button": "res://src/ui/components/nine_patch_ui/butter02_blue_button.tscn",
		"ribbon_side_stretch": "res://src/ui/components/nine_patch_ui/ribbon_side_stretch.tscn",
	}
	for key: String in scenes.keys():
		var packed := load(scenes[key]) as PackedScene
		_expect(packed != null, "%s should load as PackedScene" % key)
		if packed == null:
			continue
		var node := packed.instantiate()
		_expect(node is Control, "%s root should be a scalable Control wrapper" % key)
		if node is Control:
			var wrapper := node as Control
			var nine := wrapper.get_node_or_null("NinePatch") as NinePatchRect
			_expect(nine != null, "%s should contain a NinePatch child" % key)
			_expect(wrapper.size.x > 0.0 and wrapper.size.y > 0.0, "%s wrapper should have editable size" % key)
			if nine == null:
				node.queue_free()
				continue
			_expect(nine.texture != null, "%s should have texture" % key)
			_expect(nine.anchor_right == 1.0 and nine.anchor_bottom == 1.0, "%s NinePatch should fill wrapper" % key)
			_expect(nine.patch_margin_left > 0 and nine.patch_margin_right > 0, "%s should keep left/right margins" % key)
			if key == "ribbon_side_stretch":
				_expect(nine.patch_margin_top == 0 and nine.patch_margin_bottom == 0, "ribbon should only use left/right margins")
			else:
				_expect(nine.patch_margin_top > 0 and nine.patch_margin_bottom > 0, "%s should keep top/bottom margins" % key)
		node.queue_free()
	_test_library_scene()
	await process_frame
	_finish()

func _test_library_scene() -> void:
	var packed := load("res://src/ui/components/nine_patch_ui/ui_nine_patch_library.tscn") as PackedScene
	_expect(packed != null, "library scene should load as PackedScene")
	if packed == null:
		return
	var library := packed.instantiate()
	var names := ["black", "black2", "black3", "butter01", "butter02", "花边01", "ui底图", "蓝色花边", "黄色底部"]
	for node_name: String in names:
		_expect(library.has_node(node_name), "library should contain wrapper %s" % node_name)
		var wrapper := library.get_node_or_null(node_name) as Control
		_expect(wrapper != null, "%s should be a Control wrapper in library" % node_name)
		if wrapper != null:
			var nine := wrapper.get_node_or_null("NinePatch") as NinePatchRect
			_expect(nine != null, "%s should contain a NinePatch child" % node_name)
			_expect(wrapper.size.x > 0.0 and wrapper.size.y > 0.0, "%s wrapper should have editable size" % node_name)
			if nine == null:
				continue
			_expect(nine.texture != null, "%s should have texture in library" % node_name)
			_expect(nine.anchor_right == 1.0 and nine.anchor_bottom == 1.0, "%s NinePatch should fill wrapper" % node_name)
			_expect(nine.patch_margin_left > 0 and nine.patch_margin_right > 0, "%s should keep left/right margins in library" % node_name)
			if ["花边01", "蓝色花边"].has(node_name):
				_expect(nine.patch_margin_top == 0 and nine.patch_margin_bottom == 0, "%s should only use left/right margins in library" % node_name)
			else:
				_expect(nine.patch_margin_top > 0 and nine.patch_margin_bottom > 0, "%s should keep top/bottom margins in library" % node_name)
	library.queue_free()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("[NinePatchUIComponents] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[NinePatchUIComponents] " + failure)
	quit(1)
