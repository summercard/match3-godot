extends SceneTree

# shop_entry_test.gd - 验证商店界面入场动画
# 动画规则（_play_enter_animation）：
#   1) TitlePlaque：scale 0.94 → 1.04 → 1.0 弹跳
#   2) Header 三个货币 chip（Gold/Diamond/Energy）：依次淡入 + 下滑（stagger 0.05s）
#   3) Tabs 5 个标签：scale 0.82 → 1.08 → 1.0 弹跳（stagger 0.04s，延迟 0.10s）
#   4) ProductGrid 9 张卡片：保留原 stagger scale 0.96 → 1.0
#   5) PageControls：scale 0.88 → 1.05 → 1.0 + 淡入（延迟 0.26s）
#   6) BottomNav/HomeButton：上滑 + 淡入（延迟 0.30s）

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
	main.switch_scene("shop")
	await process_frame
	await process_frame
	var shop: Control = main.get_current_scene()
	_expect(shop != null, "shop scene should instantiate")
	if shop == null:
		_finish()
		return

	# 因为 _ready 时 call_deferred 已经触发过一次动画，再主动 sync 后重新播放，确保初始态可见
	shop.call("_sync_gui")
	await process_frame
	shop.call("_play_enter_animation")
	# 注意：不能在 _play_enter_animation 后立即 await，否则 tween 已经开始推进，初始态会被打破

	# === 测试 1: TitlePlaque 已开始动画（scale 在 0.94 附近 或 已经向 1 移动）===
	var plaque := shop.get_node_or_null("TitlePlaque") as Control
	_expect(plaque != null, "TitlePlaque should exist")
	if plaque != null:
		_expect(plaque.scale.x >= 0.93 and plaque.scale.x <= 1.06, "TitlePlaque scale.x should be in entry range, got %f" % plaque.scale.x)

	# === 测试 2: Header 三个 chip 应处于入场态（modulate.a 应该被设为 0，position 已上移） ===
	for chip_path in ["Header/GoldChip", "Header/DiamondChip", "Header/EnergyChip"]:
		var chip := shop.get_node_or_null(chip_path) as Control
		_expect(chip != null, "%s should exist" % chip_path)
		if chip == null or not chip.visible:
			continue
		_expect(chip.modulate.a < 0.5, "%s modulate.a should be ~0 at entry start, got %f" % [chip_path, chip.modulate.a])

	# === 测试 3: Tabs 5 个标签初始 scale 应小于 1（入场态） ===
	for tab_path in ["Tabs/Gems", "Tabs/Coins", "Tabs/Hearts", "Tabs/Boosters", "Tabs/Chest"]:
		var tab := shop.get_node_or_null(tab_path) as Control
		_expect(tab != null, "%s should exist" % tab_path)
		if tab == null or not tab.visible:
			continue
		_expect(tab.scale.x < 0.9, "%s scale.x should be < 0.9 at entry start, got %f" % [tab_path, tab.scale.x])
		# pivot 应居中
		var expected_pivot := tab.size * 0.5
		_expect(tab.pivot_offset.distance_to(expected_pivot) < 0.5, "%s pivot should be center, got %s" % [tab_path, str(tab.pivot_offset)])

	# === 测试 4: PageControls 入场态 modulate.a < 1 ===
	var page_ctrl := shop.get_node_or_null("ProductGrid/PageControls") as Control
	if page_ctrl != null and page_ctrl.visible:
		_expect(page_ctrl.modulate.a < 0.5, "PageControls should start hidden (modulate.a=%f)" % page_ctrl.modulate.a)
		_expect(page_ctrl.scale.x < 0.95, "PageControls scale should be small (scale.x=%f)" % page_ctrl.scale.x)

	# === 测试 5: BottomNav/HomeButton 入场态 modulate.a 0 + 下移 ===
	var home := shop.get_node_or_null("BottomNav/HomeButton") as Control
	if home != null and home.visible:
		_expect(home.modulate.a < 0.5, "HomeButton should start hidden (modulate.a=%f)" % home.modulate.a)

	# === 测试 6: 卡片初始 scale < 1 (入场态)，如果有可见卡片 ===
	var cards_seen := 0
	var cards_animated := 0
	for i in 9:
		var card := shop.get_node_or_null("ProductGrid/Cards/Card%d" % (i + 1)) as Control
		if card == null or not card.visible:
			continue
		cards_seen += 1
		if card.scale.x < 0.99:
			cards_animated += 1
	if cards_seen > 0:
		_expect(cards_animated > 0, "at least one of %d visible cards should be in entry state" % cards_seen)

	# === 测试 7: 等待动画完成（PageControls 延迟 0.26 + 0.16+0.08 = 0.50；HomeButton 0.30+0.18 = 0.48） ===
	for _i in 80:
		await process_frame

	# Header chips 归位
	for chip_path in ["Header/GoldChip", "Header/DiamondChip", "Header/EnergyChip"]:
		var chip := shop.get_node_or_null(chip_path) as Control
		if chip == null or not chip.visible:
			continue
		_expect(absf(chip.modulate.a - 1.0) < 0.01, "%s modulate.a should be 1.0 after entry, got %f" % [chip_path, chip.modulate.a])

	# Tabs 归位
	for tab_path in ["Tabs/Gems", "Tabs/Coins", "Tabs/Hearts", "Tabs/Boosters", "Tabs/Chest"]:
		var tab := shop.get_node_or_null(tab_path) as Control
		if tab == null or not tab.visible:
			continue
		_expect(absf(tab.scale.x - 1.0) < 0.01, "%s scale.x should be 1.0 after entry, got %f" % [tab_path, tab.scale.x])
		_expect(absf(tab.scale.y - 1.0) < 0.01, "%s scale.y should be 1.0 after entry, got %f" % [tab_path, tab.scale.y])

	# PageControls 归位
	if page_ctrl != null and page_ctrl.visible:
		_expect(absf(page_ctrl.modulate.a - 1.0) < 0.01, "PageControls modulate.a should be 1.0, got %f" % page_ctrl.modulate.a)
		_expect(absf(page_ctrl.scale.x - 1.0) < 0.01, "PageControls scale should return to 1.0, got %f" % page_ctrl.scale.x)

	# HomeButton 归位
	if home != null and home.visible:
		_expect(absf(home.modulate.a - 1.0) < 0.01, "HomeButton modulate.a should be 1.0, got %f" % home.modulate.a)

	# 卡片归位
	for i in 9:
		var card := shop.get_node_or_null("ProductGrid/Cards/Card%d" % (i + 1)) as Control
		if card == null or not card.visible:
			continue
		_expect(absf(card.scale.x - 1.0) < 0.01, "Card%d scale.x should be 1.0 after entry, got %f" % [i + 1, card.scale.x])

	main.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if _failures.is_empty():
		print("[ShopEntry] OK")
		quit(0)
		return
	for failure in _failures:
		push_error("[ShopEntry] " + failure)
	quit(1)
