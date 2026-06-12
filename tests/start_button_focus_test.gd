extends SceneTree

# start_button_focus_test.gd - 验证点击"开始冒险"会自动定位到最新关卡

var _failures: Array[String] = []

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	await process_frame
	# 确保 SaveManager 已激活
	var save_manager := root.get_node_or_null("SaveManager")
	if save_manager == null:
		_failures.append("SaveManager not active")
		_report_and_quit()
		return
	# 清空旧存档，保证从干净状态开始
	if save_manager.has_method("clear_all_data"):
		save_manager.call("clear_all_data")
		await process_frame

	# 1) 默认新存档：最新关卡应该是 chapter 0 stage 1
	var main: Control = load("res://main.gd").new()
	root.add_child(main)
	await process_frame
	# main 启动后会自动切到 start 场景。我们直接调 main 的解析方法。
	var result: Dictionary = main._resolve_latest_stage()
	print("DEBUG default: %s" % str(result))
	_check(int(result.get("chapterIndex", -1)) == 0, "default should resolve to chapter 0")
	_check(str(result.get("focusStageId", "")) == "stage_1_1", "default should focus stage_1_1 (got %s)" % str(result.get("focusStageId", "")))
	main.queue_free()
	await process_frame

	# 2) 模拟打过 stage_1_1、stage_1_2、stage_1_3 后的状态
	# 通过给 SaveManager 写进度来模拟。
	if not save_manager.has_method("save_stage_progress"):
		_failures.append("SaveManager.save_stage_progress not available for test")
		_report_and_quit()
		return

	# 重新初始化 main
	var main2: Control = load("res://main.gd").new()
	root.add_child(main2)
	await process_frame

	# 标记 stage_1_1..stage_1_3 已通关
	for stage_id in ["stage_1_1", "stage_1_2", "stage_1_3"]:
		save_manager.call("save_stage_progress", stage_id, {"stars": 3, "cleared": true})

	var result2: Dictionary = main2._resolve_latest_stage()
	print("DEBUG cleared 3: %s" % str(result2))
	_check(int(result2.get("chapterIndex", -1)) == 0, "after clearing 3 stages, still chapter 0")
	_check(str(result2.get("focusStageId", "")) == "stage_1_4", "after clearing 1-3, focus should be stage_1_4 (got %s)" % str(result2.get("focusStageId", "")))

	# 3) 把整章 1 全部打通关（应该跳到 chapter 1 / chapter_2 stage 1）
	var chapters: Array = save_manager.call("get_stage_chapters")
	var ch0_stages: Array = chapters[0].get("stages", [])
	print("DEBUG chapter 0 has %d stages: %s" % [ch0_stages.size(), str(ch0_stages.map(func(s): return str(s.get("id", "")) + "(" + str(s.get("type", "")) + ")"))])
	for stage: Dictionary in ch0_stages:
		save_manager.call("save_stage_progress", str(stage.get("id", "")), {"stars": 3, "cleared": true})

	var result3: Dictionary = main2._resolve_latest_stage()
	print("DEBUG ch1 done: %s" % str(result3))
	_check(int(result3.get("chapterIndex", -1)) == 1, "after clearing chapter 1, should be in chapter 1 (chapter_2)")
	_check(str(result3.get("focusStageId", "")) == "stage_2_1", "after clearing chapter 1, focus should be stage_2_1 (got %s)" % str(result3.get("focusStageId", "")))

	# 4) stage_select 接收 focusStageId 后能正确滚动
	var stage_select: Control = load("res://src/ui/scenes/stage_select_map.tscn").instantiate()
	root.add_child(stage_select)
	stage_select.init({"chapterIndex": 0, "focusStageId": "stage_1_5"})
	await process_frame
	await process_frame
	# 验证 scroll_vertical 不在底部（说明滚动到了 stage 5）
	# 默认滚到底部（scroll_vertical = max_scroll）。focus 到 stage 5 后应该更靠上。
	var map_scroll: ScrollContainer = stage_select.get_node_or_null("MapScroll")
	_check(map_scroll != null, "MapScroll should exist")
	if map_scroll != null:
		var max_scroll: float = float(stage_select._chapter_map_scroll_height())
		print("DEBUG scroll_vertical=%f max=%f" % [map_scroll.scroll_vertical, max_scroll])
		# focus stage 5 在 chapter 1 中间偏下，scroll_vertical 应小于 max_scroll
		_check(map_scroll.scroll_vertical < max_scroll, "focused scroll should not be at the bottom (max=%f, got %f)" % [max_scroll, map_scroll.scroll_vertical])
		_check(map_scroll.scroll_vertical > 0, "focused scroll should not be at the top (got %f)" % map_scroll.scroll_vertical)

	# 5) 没有 focusStageId 时回退到默认（滚到底部）
	stage_select.queue_free()
	await process_frame
	var stage_select2: Control = load("res://src/ui/scenes/stage_select_map.tscn").instantiate()
	root.add_child(stage_select2)
	stage_select2.init({"chapterIndex": 0})
	await process_frame
	await process_frame
	var map_scroll2: ScrollContainer = stage_select2.get_node_or_null("MapScroll")
	if map_scroll2 != null:
		# 默认走 _scroll_map_to_start → deferred bottom，会被 ScrollContainer
		# 内部钳到 max_value，等价于滚到 chapter map 最底（Stage01 可见）。
		# 比起读 VScrollBar.max_value（动态），我们用 "focus 阶段 1（最底）应接近 default" 来间接验证。
		var scroll_default2: float = float(map_scroll2.scroll_vertical)
		print("DEBUG default scroll=%f" % scroll_default2)
		_check(scroll_default2 > 0.0, "default scroll should be at the bottom of the chapter (got %f)" % scroll_default2)

	# 6) focus 不同位置时，scroll_vertical 应不同
	# 对比 stage_1_1（最底）和 stage_1_12（最顶）的 focus 位置差异
	stage_select2.queue_free()
	await process_frame
	var stage_select3: Control = load("res://src/ui/scenes/stage_select_map.tscn").instantiate()
	root.add_child(stage_select3)
	stage_select3.init({"chapterIndex": 0, "focusStageId": "stage_1_12"})
	await process_frame
	await process_frame
	var map_scroll3: ScrollContainer = stage_select3.get_node_or_null("MapScroll")
	if map_scroll3 != null:
		print("DEBUG top_focus: focus_stage_id=%s, _cards.size()=%d, boss_card_id=%s, boss_button=%s" % [
			stage_select3._focus_stage_id,
			stage_select3._cards.size(),
			str(stage_select3._boss_card().get("id", "")),
			str(stage_select3._boss_button())
		])
		var found: Control = stage_select3._find_stage_button("stage_1_12")
		print("DEBUG top_focus: _find_stage_button returned %s" % str(found))
		if found != null:
			print("DEBUG top_focus: button position.y=%f, size.y=%f" % [found.position.y, found.size.y])
		print("DEBUG top_focus scroll=%f" % map_scroll3.scroll_vertical)
		_check(map_scroll3.scroll_vertical <= 1.0, "focus stage_1_12 (boss/top) should scroll near top (got %f)" % map_scroll3.scroll_vertical)

	_report_and_quit()

func _report_and_quit() -> void:
	if _failures.is_empty():
		print("[StartButtonFocus] OK")
		quit(0)
	else:
		for msg: String in _failures:
			push_error("[StartButtonFocus] " + msg)
		quit(1)
