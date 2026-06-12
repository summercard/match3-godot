extends SceneTree

# stage_portrait_test.gd - 验证"未通关的关卡（已解锁但 stars==0）"在台子中心显示原色怪物画像
# 规则（依据最新需求）：
#   - 已锁定（enabled=false）：不显示画像
#   - 已解锁 + 未通关（enabled=true && stars==0）：显示原色画像，位置 = 图片底部对准台子中心
#   - 已解锁 + 已通关（enabled=true && stars>0）：不显示画像

var _failures: Array[String] = []

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var save_manager := root.get_node_or_null("SaveManager")
	await process_frame
	await process_frame

	# 清空旧存档，保证从干净状态开始（避免前序测试留下的 stars>0 影响规则验证）
	if save_manager != null and save_manager.has_method("clear_all_data"):
		save_manager.call("clear_all_data")
		await process_frame

	var scene_path := "res://src/ui/scenes/stage_select_map.tscn"
	if not ResourceLoader.exists(scene_path):
		_failures.append("stage_select.tscn not found")
		_report_and_quit()
		return
	var scene: Control = load(scene_path).instantiate()
	root.add_child(scene)
	scene.init({"chapterIndex": 0})
	await process_frame
	await process_frame

	var stage_nodes: Node = scene.get_node_or_null("MapScroll/ChapterMaps/Chapter01Grassland/StageNodes")
	if stage_nodes == null:
		_failures.append("Chapter01Grassland/StageNodes not found")
		_report_and_quit()
		return

	var stage_buttons: Array[TextureButton] = []
	for child: Node in stage_nodes.get_children():
		if child is TextureButton and str(child.name).begins_with("Stage"):
			stage_buttons.append(child as TextureButton)
	if stage_buttons.size() < 2:
		_failures.append("Need at least 2 stage buttons for portrait test, got %d" % stage_buttons.size())
		_report_and_quit()
		return

	var first_button := stage_buttons[0]
	var second_button := stage_buttons[1]

	# MonsterPortrait 节点应已被创建（即使不可见）
	var portrait1 := first_button.get_node_or_null("MonsterPortrait")
	var portrait2 := second_button.get_node_or_null("MonsterPortrait")
	_check(portrait1 != null, "First stage should have MonsterPortrait node")
	_check(portrait2 != null, "Second stage should have MonsterPortrait node")
	if portrait1 == null or portrait2 == null:
		_report_and_quit()
		return

	# === 规则 1：默认状态 stage 1 解锁且 stars==0 → 应显示画像 ===
	_check((portrait1 as TextureRect).visible, "Default: unlocked + stars=0 stage 1 should show monster portrait")
	_check((portrait1 as TextureRect).texture != null, "Default: stage 1 portrait should have a texture")

	# === 规则 2：画像保留原色（不染灰）===
	var mod1: Color = (portrait1 as TextureRect).modulate
	_check(mod1.r > 0.9 and mod1.g > 0.9 and mod1.b > 0.9, "Stage 1 portrait should keep original colors (modulate=%s)" % str(mod1))

	# === 规则 3：图片底部对准台子中心 ===
	var btn_size: Vector2 = first_button.size
	var port_size: Vector2 = (portrait1 as TextureRect).size
	var port_pos: Vector2 = (portrait1 as TextureRect).position
	# bottom-of-portrait at vertical-midline: pos.y + size.y == btn.y * 0.5
	var portrait_bottom: float = port_pos.y + port_size.y
	var expected_bottom: float = btn_size.y * 0.5
	_check(absf(portrait_bottom - expected_bottom) < 0.5, "Stage 1 portrait bottom should be at button vertical center (got %f, expected %f)" % [portrait_bottom, expected_bottom])
	# 水平居中（容差 0.5）
	var expected_x: float = (btn_size.x - port_size.x) * 0.5
	_check(absf(port_pos.x - expected_x) < 0.5, "Stage 1 portrait should be horizontally centered (got x=%f, expected %f)" % [port_pos.x, expected_x])

	# === 规则 4：默认 stage 2 锁定 → 不显示画像 ===
	# 默认 unlocked_card: enabled=true, stars=0
	# 锁定卡: enabled=false, stars=0
	var locked_card := {
		"enabled": false,
		"stage_no": 2,
		"stars": 0,
		"can_sweep": false,
		"stage_data": {"enemies": ["enemy_003"]},
		"unlock_state": {"unlocked": false, "requiredStageName": "第 1 关"}
	}
	scene.call("_sync_stage_button", second_button, locked_card)
	await process_frame
	_check(not (portrait2 as TextureRect).visible, "Locked stage 2 should hide monster portrait (new rule)")

	# === 规则 5：解锁后（enabled=true, stars=0）→ 显示画像 ===
	var unlocked_card := locked_card.duplicate()
	unlocked_card["enabled"] = true
	unlocked_card["stars"] = 0
	scene.call("_sync_stage_button", second_button, unlocked_card)
	await process_frame
	_check((portrait2 as TextureRect).visible, "Unlocked + stars=0 stage 2 should show monster portrait (new rule)")

	# === 规则 6：通关后（stars>0）→ 隐藏画像 ===
	var cleared_card := unlocked_card.duplicate()
	cleared_card["stars"] = 3
	scene.call("_sync_stage_button", second_button, cleared_card)
	await process_frame
	_check(not (portrait2 as TextureRect).visible, "Cleared (stars=3) stage 2 should hide monster portrait")

	# 还原为 unlocked + stars=0
	scene.call("_sync_stage_button", second_button, unlocked_card)
	await process_frame
	_check((portrait2 as TextureRect).visible, "Revert: should re-show portrait")

	# 画像应是怪物资源
	var portrait2_tex: Texture2D = (portrait2 as TextureRect).texture
	_check(portrait2_tex != null, "Stage 2 portrait should have a texture loaded")
	if portrait2_tex != null:
		var path: String = portrait2_tex.resource_path
		_check(path.begins_with("res://assets/images/monsters/"), "Stage 2 portrait should be a monster image (got %s)" % path)

	# 保留原色
	var mod2: Color = (portrait2 as TextureRect).modulate
	_check(mod2.r > 0.9 and mod2.g > 0.9 and mod2.b > 0.9, "Stage 2 portrait should keep original colors (modulate=%s)" % str(mod2))

	# 位置：底部对准台子中心
	var btn2_size: Vector2 = second_button.size
	var port2_pos: Vector2 = (portrait2 as TextureRect).position
	var port2_size: Vector2 = (portrait2 as TextureRect).size
	var port2_bottom: float = port2_pos.y + port2_size.y
	_check(absf(port2_bottom - btn2_size.y * 0.5) < 0.5, "Stage 2 portrait bottom should be at button center (got %f, expected %f)" % [port2_bottom, btn2_size.y * 0.5])

	# === 规则 7：locked + 没 stars → 不显示（验证明确规则）===
	scene.call("_sync_stage_button", second_button, locked_card)
	await process_frame
	_check(not (portrait2 as TextureRect).visible, "Locked stage (enabled=false) should hide portrait regardless of stars")

	# === 规则 8：没有 enemies 时的回退 ===
	var no_enemies_card := {"enabled": true, "stage_no": 3, "stars": 0, "stage_data": {}}
	scene.call("_sync_stage_button", second_button, no_enemies_card)
	await process_frame
	_check(not (portrait2 as TextureRect).visible, "Unlocked stage with no enemy data should hide portrait (no crash)")

	# === 规则 9：portrait 资源不存在时回退 ===
	var missing_card := {
		"enabled": true,
		"stage_no": 4,
		"stars": 0,
		"stage_data": {"enemies": ["nonexistent_monster_999"]}
	}
	scene.call("_sync_stage_button", second_button, missing_card)
	await process_frame
	_check(not (portrait2 as TextureRect).visible, "Unlocked stage with missing portrait should hide portrait (no crash)")

	# === BossStage 也应支持新规则 ===
	var boss_button: TextureButton = scene.get_node_or_null("MapScroll/ChapterMaps/Chapter01Grassland/BossStage") as TextureButton
	if boss_button != null:
		var boss_portrait: TextureRect = boss_button.get_node_or_null("MonsterPortrait") as TextureRect
		_check(boss_portrait != null, "BossStage should also have MonsterPortrait node")

	scene.queue_free()
	_report_and_quit()

func _report_and_quit() -> void:
	if _failures.is_empty():
		print("[StagePortrait] OK")
		quit(0)
	else:
		for msg: String in _failures:
			push_error("[StagePortrait] " + msg)
		quit(1)
