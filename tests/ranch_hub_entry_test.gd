extends SceneTree

# ranch_hub_entry_test.gd - 验证精灵旅馆 hub 级首次入场动画
# 动画规则（_play_hub_entry，仅首次进入旅馆时播放）：
#   1) Header：从顶部滑下 + 淡入（0.22s）
#   2) PetFarmResourceBar：从顶部滑下 + 淡入（延迟 0.05s，0.22s）
#   3) PetFarmBottomNav 5 个 Nav 按钮：scale 0.7→1.08→1.0 + 淡入（延迟 0.18s 起，stagger 0.04s，0.18s）
#   4) _hub_entry_played 设为 true，再次进入不重复播放

var _failures: Array[String] = []

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.switch_scene("ranch")
	# 注意：不能立即 await 很多帧，否则 hub_entry 已经推进，初始态会被打破
	await process_frame

	var ranch: Control = main.get_current_scene()
	_expect(ranch != null, "ranch scene should instantiate")
	if ranch == null:
		_finish()
		return

	# === 测试 1: _hub_entry_played 标记已置位 ===
	_expect(bool(ranch.get("_hub_entry_played")), "_hub_entry_played should be true after _ready")

	# === 测试 2: Header / PetFarmResourceBar 都已设置入场态（modulate.a < 1.0） ===
	# 经过 1 个 process_frame，Header 已经开始 fade，所以 modulate.a 应该 < 1（但 > 0）
	var header := ranch.get_node_or_null("Header") as Control
	_expect(header != null, "Header should exist")
	if header != null:
		# 一帧后 modulate.a 应已开始上升，但应仍在 (0, 1)
		_expect(header.modulate.a < 1.0, "Header modulate.a should be in fade-in window, got %f" % header.modulate.a)

	var resource_bar := ranch.get_node_or_null("PetFarmResourceBar") as Control
	_expect(resource_bar != null, "PetFarmResourceBar should exist")
	if resource_bar != null:
		_expect(resource_bar.modulate.a < 1.0, "PetFarmResourceBar should be in fade-in window, got %f" % resource_bar.modulate.a)

	# === 测试 3: PetFarmBottomNav 5 个 nav 都应在入场态 ===
	var nav := ranch.get_node_or_null("PetFarmBottomNav") as Control
	_expect(nav != null, "PetFarmBottomNav should exist")
	if nav != null:
		for i in 5:
			var btn := nav.get_node_or_null("Nav%d" % (i + 1)) as Control
			if btn == null or not btn.visible:
				continue
			_expect(btn.scale.x < 0.9, "Nav%d scale.x should be < 0.9 at entry start, got %f" % [i + 1, btn.scale.x])
			_expect(btn.modulate.a < 0.5, "Nav%d modulate.a should be ~0 at entry start, got %f" % [i + 1, btn.modulate.a])
			var expected_pivot := btn.size * 0.5
			_expect(btn.pivot_offset.distance_to(expected_pivot) < 0.5, "Nav%d pivot should be center, got %s" % [i + 1, str(btn.pivot_offset)])

	# === 测试 4: 等待 hub 入场动画完成（最长 0.18+5*0.04+0.18+0.08 = 0.64s） ===
	for _i in 60:
		await process_frame

	if header != null:
		_expect(absf(header.modulate.a - 1.0) < 0.01, "Header modulate.a should be 1.0 after hub entry, got %f" % header.modulate.a)
	if resource_bar != null:
		_expect(absf(resource_bar.modulate.a - 1.0) < 0.01, "PetFarmResourceBar modulate.a should be 1.0 after hub entry, got %f" % resource_bar.modulate.a)
	if nav != null:
		for i in 5:
			var btn := nav.get_node_or_null("Nav%d" % (i + 1)) as Control
			if btn == null or not btn.visible:
				continue
			_expect(absf(btn.scale.x - 1.0) < 0.01, "Nav%d scale.x should be 1.0 after hub entry, got %f" % [i + 1, btn.scale.x])
			_expect(absf(btn.modulate.a - 1.0) < 0.01, "Nav%d modulate.a should be 1.0 after hub entry, got %f" % [i + 1, btn.modulate.a])

	# === 测试 5: 再次调用 _play_hub_entry 不应重置（只播放一次） ===
	# 设置一个明显的 sentinel 然后调用，验证 hub entry 不会再次置 Header alpha 为 0
	if header != null:
		header.modulate.a = 1.0
		ranch.call("_play_hub_entry")
		await process_frame
		_expect(absf(header.modulate.a - 1.0) < 0.01, "Header modulate.a should stay at 1.0 on second _play_hub_entry call, got %f" % header.modulate.a)

	# === 测试 6: 子页面专属面板入场（ranch 页面的 Slots / CollectRow） ===
	# 准备 6 只精灵，让 ranch 卡片可见
	var captured: Array = []
	for i in 6:
		captured.append({
			"instanceId": "hub_entry_%02d" % i,
			"monsterId": "monster_%03d" % ((i % 6) + 1),
			"level": 3,
			"nature": "brave",
		})
	ranch.set("_storage", null)
	ranch.set("_captured_monsters", captured)
	ranch.call("_sync_gui")
	await process_frame

	# 手动触发 ranch 子页面入场
	ranch.call("_play_subpage_entry", "ranch")

	# 立即检查 Slots 是否处于入场态
	var any_slot_animated := false
	for i in 5:
		var slot := ranch.get_node_or_null("Pages/RanchPage/Slots/Slot%d" % (i + 1)) as Control
		if slot == null or not slot.visible:
			continue
		if slot.scale.x < 0.9 and slot.modulate.a < 0.5:
			any_slot_animated = true
			var expected_pivot := slot.size * 0.5
			_expect(slot.pivot_offset.distance_to(expected_pivot) < 0.5, "Slot%d pivot should be center" % (i + 1))
	_expect(any_slot_animated, "at least one visible Slot should be in entry state")

	# CollectRow 入场态
	var collect_row := ranch.get_node_or_null("Pages/RanchPage/CollectRow") as Control
	if collect_row != null and collect_row.visible:
		_expect(collect_row.modulate.a < 0.5, "CollectRow modulate.a should be ~0 at entry start, got %f" % collect_row.modulate.a)

	# 等待 ranch 子页面入场完成（最长 0.22+0.20 = 0.42s）
	for _i in 60:
		await process_frame

	for i in 5:
		var slot := ranch.get_node_or_null("Pages/RanchPage/Slots/Slot%d" % (i + 1)) as Control
		if slot == null or not slot.visible:
			continue
		_expect(absf(slot.scale.x - 1.0) < 0.01, "Slot%d scale.x should be 1.0 after entry, got %f" % [i + 1, slot.scale.x])
		_expect(absf(slot.modulate.a - 1.0) < 0.01, "Slot%d modulate.a should be 1.0 after entry, got %f" % [i + 1, slot.modulate.a])
	if collect_row != null and collect_row.visible:
		_expect(absf(collect_row.modulate.a - 1.0) < 0.01, "CollectRow modulate.a should be 1.0 after entry, got %f" % collect_row.modulate.a)

	# === 测试 7: 切换到 classroom 验证 DetailPanel 入场（如果 visible） ===
	ranch.call("_switch_to_classroom")
	# 立即检查初始态
	var detail := ranch.get_node_or_null("Pages/ClassroomPage/DetailPanel") as Control
	if detail != null and detail.visible:
		_expect(detail.modulate.a < 0.5, "DetailPanel modulate.a should be ~0 at entry start, got %f" % detail.modulate.a)

	for _i in 60:
		await process_frame
	if detail != null and detail.visible:
		_expect(absf(detail.modulate.a - 1.0) < 0.01, "DetailPanel modulate.a should be 1.0 after entry, got %f" % detail.modulate.a)

	# === 测试 8: 切换到 social 验证 PlacePanel / BondPanel 入场 ===
	ranch.call("_switch_to_social")
	var place := ranch.get_node_or_null("Pages/SocialPage/PlacePanel") as Control
	if place != null and place.visible:
		_expect(place.modulate.a < 0.5, "PlacePanel modulate.a should be ~0 at entry start, got %f" % place.modulate.a)
	var bond := ranch.get_node_or_null("Pages/SocialPage/BondPanel") as Control
	if bond != null and bond.visible:
		_expect(bond.modulate.a < 0.5, "BondPanel modulate.a should be ~0 at entry start, got %f" % bond.modulate.a)

	for _i in 60:
		await process_frame
	if place != null and place.visible:
		_expect(absf(place.modulate.a - 1.0) < 0.01, "PlacePanel modulate.a should be 1.0 after entry, got %f" % place.modulate.a)
	if bond != null and bond.visible:
		_expect(absf(bond.modulate.a - 1.0) < 0.01, "BondPanel modulate.a should be 1.0 after entry, got %f" % bond.modulate.a)

	main.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if _failures.is_empty():
		print("[RanchHubEntry] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[RanchHubEntry] " + failure)
	quit(1)
