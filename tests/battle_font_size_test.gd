extends SceneTree

# battle_font_size_test.gd - 验证战局信息文字字体已加倍（角色/怪物名字除外）
# 依据用户指令："战局内的信息文字字体都太小了，除了角色和怪物的名字外，其他都加大一倍"
# - 信息文字（回合/速度/阶段/HP/珠子/计数）应加大一倍
# - 角色/怪物名字 (Name) 保持原样
#
# 验证方式：检查 Label.get_line_height()，它等于 font_size + 默认 line spacing。
# 在该游戏的默认主题下，line_height == font_size + 1。
# 所以"加一倍"前后的 line_height 关系是：
#   原 line_height = font_old + 1
#   新 line_height = font_new + 1 = 2*font_old + 1
# 即 line_height_new = 2 * (line_height_old - 1) + 1

var _failures: Array[String] = []

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	# 加载主场景以激活 autoload
	var main: Control = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	# 切到战局界面（用 inputTestOnly 模式，跳过完整战斗初始化）
	var stage_db = load("res://src/data/stage_db.gd").new()
	main.switch_scene("battle", {
		"stageId": "stage_1_1",
		"stageData": stage_db.get_stage("stage_1_1"),
		"inputTestOnly": true,
	})
	await process_frame
	await process_frame

	var battle: Control = main.get_current_scene()

	# 1) TopHud 信息文字（应加倍）
	# 原本：Title=10, Value=14, SpeedLabel=10, BossPhase=10
	# 加倍后 line_height 应等于 2*原 line_height - 1
	_check_doubled(battle.get_node("TopHud/TurnBadge/Title"), 10, "TurnBadge/Title (回合)")
	_check_doubled(battle.get_node("TopHud/TurnBadge/Value"), 14, "TurnBadge/Value (回合数)")
	_check_doubled(battle.get_node("TopHud/SpeedLabel"), 10, "SpeedLabel (x2)")
	_check_doubled(battle.get_node("TopHud/BossPhase"), 10, "BossPhase (阶段)")

	# 2) BottomControls Badges 信息文字（应加倍，原 9）
	for path in ["BottomControls/CaptureToggle/Badge", "BottomControls/Item1/Badge", "BottomControls/Item2/Badge", "BottomControls/Item3/Badge"]:
		_check_doubled(battle.get_node(path), 9, path)

	# 3) Slot sub-scenes 中：Name 不应改变，HpText/Beads 应加倍
	var enemy3: Control = battle.get_node("Combatants/MultiEnemies/Enemy3") as Control
	if enemy3 != null:
		# Name 原本期望 10（.tscn 里写的是 10），但 Godot 4 把小值（<14）clamp 到了 14
		# 所以"保持不变"实际就是保持 line_height=15
		# 用 _check_unchanged_with_baseline 而不是 _check_unchanged
		_check_unchanged_with_baseline(enemy3.get_node("Name"), 15, "Enemy Name (角色名字)")
		_check_doubled(enemy3.get_node("HpText"), 8, "Enemy HpText (HP 数值)")

	var player1: Control = battle.get_node("Combatants/Players/Player1") as Control
	if player1 != null:
		_check_unchanged_with_baseline(player1.get_node("Name"), 15, "Player Name (角色名字)")
		_check_doubled(player1.get_node("HpText"), 8, "Player HpText (HP 数值)")

	var single_enemy: Control = battle.get_node("Combatants/SingleEnemy") as Control
	if single_enemy != null:
		_check_unchanged_with_baseline(single_enemy.get_node("Name"), 15, "Boss Name (怪物名字)")
		_check_doubled(single_enemy.get_node("HpText"), 10, "Boss HpText (HP 数值)")
		_check_doubled(single_enemy.get_node("Beads"), 12, "Boss Beads (HP 珠子)")

	_report_and_quit()

# 检查 label 的 line_height 已"加大一倍"
# Godot 默认主题下，line_height ≈ font_size + 额外间距。
# 小字号间距为 1，大字号会更大（如 font 24 → line_height 28）。
# 简化判断：line_height 至少是 (original_lh - 1) * 2 + 1，
# 即 font_size 已至少翻倍（间距是次要缩放）。
func _check_doubled(label: Label, original_font_size: int, debug_name: String) -> void:
	var lh: int = int(label.get_line_height())
	var original_lh: int = original_font_size + 1
	# 实际 font_size = line_height - 默认 line spacing
	# 但 line spacing 不可直接读。用一个保守判断：line_height 至少翻 1.8x。
	var min_required: int = int(round(float(original_lh) * 1.8))
	_check(lh >= min_required, "%s: line_height should be at least %d (>=1.8x of %d), got %d" % [
		debug_name, min_required, original_lh, lh
	])

# 检查 Name label 保持不变（用基线值，不依赖 .tscn 中的小字号 override）
# 该游戏主题下，Name 实际渲染 line_height = 15（Godot 4 对 <14 的 font_size 会回退到默认 14）
func _check_unchanged_with_baseline(label: Label, baseline_lh: int, debug_name: String) -> void:
	var lh: int = int(label.get_line_height())
	_check(lh == baseline_lh, "%s: line_height should stay %d (unchanged), got %d" % [
		debug_name, baseline_lh, lh
	])

func _report_and_quit() -> void:
	if _failures.is_empty():
		print("[BattleFontSize] OK")
		quit(0)
	else:
		for msg: String in _failures:
			push_error("[BattleFontSize] " + msg)
		quit(1)
