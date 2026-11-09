extends SceneTree

## 战斗准备页属性克制分析回归：
## 1. 阈值：倍率 >=1.2 强、<=0.8 弱、其余中性；
## 2. 遍历所有敌方属性 × 所有伙伴属性，逐对比对准备页文案与 MonsterDb 克制倍率；
## 3. 多个来源合成一句话，顺序覆盖每个上阵伙伴，中性来源不写入文案；
## 4. 同一固定种子战局与基线 893c7a1 的转录逐字节一致。
##
## 用法：
##   Godot --headless --path . --script res://tests/prepare_matchup_test.gd

const MonsterDBScript = preload("res://src/data/monster_db.gd")
const PrepareScript = preload("res://src/ui/scene/scene_battle_prepare.gd")
const TranscriptScript = preload("res://tests/prepare_matchup_transcript.gd")

const BASELINE_BATTLE_PATH := "res://tests/fixtures/prepare_matchup_battle_baseline.json"
const NEUTRAL_TEXT := "属性无明显克制关系"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_thresholds()
	var prepare: Control = PrepareScript.new()
	root.add_child(prepare)
	prepare.set("_stage_data", {})
	_test_all_element_pairs(prepare)
	_test_multi_source_sentence(prepare)
	prepare.queue_free()
	await process_frame
	await _test_gui_labels()
	_test_battle_transcript_identical()
	_finish()


func _test_thresholds() -> void:
	_expect(PrepareScript.classify_element_matchup(1.5) == "strong", "1.5 应判强")
	_expect(PrepareScript.classify_element_matchup(1.2) == "strong", "阈值 1.2 应判强")
	_expect(PrepareScript.classify_element_matchup(1.19) == "neutral", "1.19 应判中性")
	_expect(PrepareScript.classify_element_matchup(1.0) == "neutral", "1.0 应判中性")
	_expect(PrepareScript.classify_element_matchup(0.81) == "neutral", "0.81 应判中性")
	_expect(PrepareScript.classify_element_matchup(0.8) == "weak", "阈值 0.8 应判弱")
	_expect(PrepareScript.classify_element_matchup(0.75) == "weak", "0.75 应判弱")


func _test_all_element_pairs(prepare: Control) -> void:
	var elements: Array = MonsterDBScript.ELEMENT_CHART.keys()
	elements.sort()
	var checked := 0
	for enemy_element: String in elements:
		for ally_element: String in elements:
			var enemies: Array[Dictionary] = [{"name": "敌方", "element": enemy_element}]
			var allies: Array[Dictionary] = [{"name": "伙伴", "element": ally_element}]
			prepare.set("_enemy_team", enemies)
			prepare.set("_player_team", allies)
			var shown := str(prepare.call("_get_element_hint"))
			var multiplier: float = MonsterDBScript.get_element_multiplier(ally_element, enemy_element)
			var verdict := PrepareScript.classify_element_matchup(multiplier)
			_expect((verdict == "strong") == (multiplier >= 1.2),
				"%s×%s 强弱判定应与表里倍率 %.2f 一致" % [enemy_element, ally_element, multiplier])
			_expect((verdict == "weak") == (multiplier <= 0.8),
				"%s×%s 弱判定应与表里倍率 %.2f 一致" % [enemy_element, ally_element, multiplier])
			var expected := _expected_text(prepare, enemy_element, ally_element, multiplier, verdict)
			_expect(shown == expected,
				"敌方 %s × 伙伴 %s：预期「%s」，实际「%s」" % [enemy_element, ally_element, expected, shown])
			checked += 1
	print("[PrepareMatchup] pairs=%d elements=%d" % [checked, elements.size()])
	_expect(checked == elements.size() * elements.size(), "应遍历所有敌方属性 × 所有伙伴属性")


func _expected_text(prepare: Control, enemy_element: String, ally_element: String, multiplier: float, verdict: String) -> String:
	if verdict == "strong":
		return "%s克%s：伙伴 +%d%%" % [
			str(prepare.call("_get_element_name", ally_element)),
			str(prepare.call("_get_element_name", enemy_element)),
			int(round((multiplier - 1.0) * 100.0)),
		]
	if verdict == "weak":
		return "%s被%s克：伙伴 -%d%%" % [
			str(prepare.call("_get_element_name", ally_element)),
			str(prepare.call("_get_element_name", enemy_element)),
			int(round((1.0 - multiplier) * 100.0)),
		]
	return NEUTRAL_TEXT


func _test_multi_source_sentence(prepare: Control) -> void:
	var enemies: Array[Dictionary] = [
		{"name": "野火虫", "element": "fire"},
		{"name": "水泡泡", "element": "water"},
		{"name": "野火虫二", "element": "fire"},
	]
	var allies: Array[Dictionary] = [
		{"name": "小火龙", "element": "fire"},
		{"name": "水龟仔", "element": "water"},
		{"name": "草苗儿", "element": "grass"},
	]
	prepare.set("_enemy_team", enemies)
	prepare.set("_player_team", allies)
	var shown := str(prepare.call("_get_element_hint"))
	var expected := "水克火：水龟仔 +50%；草被火克：草苗儿 -25%；火被水克：小火龙 -25%；草克水：草苗儿 +50%"
	_expect(shown.replace("\n", "；") == expected,
		"多来源应合成一句话且去重敌方属性：预期「%s」，实际「%s」" % [expected, shown])
	print("[PrepareMatchup] sentence=%s" % shown.replace("\n", " / "))

	var neutral_enemies: Array[Dictionary] = [{"name": "雷球", "element": "thunder"}]
	prepare.set("_enemy_team", neutral_enemies)
	_expect(str(prepare.call("_get_element_hint")) == NEUTRAL_TEXT, "全中性时应回落到无克制文案")
	print("[PrepareMatchup] neutral_sentence=%s" % str(prepare.call("_get_element_hint")))


func _test_gui_labels() -> void:
	var prepare: Control = load("res://src/ui/scenes/battle_prepare.tscn").instantiate()
	root.add_child(prepare)
	prepare.init({"stageId": "stage_2_1"})
	var allies: Array[Dictionary] = [
		{"name": "小火龙", "element": "fire"},
		{"name": "水龟仔", "element": "water"},
		{"name": "草苗儿", "element": "grass"},
	]
	var clear_enemies: Array[Dictionary] = [{"name": "野火虫", "element": "fire"}]
	prepare.set("_enemy_team", clear_enemies)
	prepare.set("_player_team", allies)
	prepare.call("_sync_mechanic_hint")
	print("[PrepareMatchup] gui_clear_line1=%s line2=%s line3=%s" % [
		str((prepare.get_node("MechanicPanel/Line1") as Label).text),
		str((prepare.get_node("MechanicPanel/Line2") as Label).text),
		str((prepare.get_node("MechanicPanel/Line3") as Label).text),
	])
	var clear_expected := "水克火：水龟仔 +50%；草被火克：草苗儿 -25%"
	_expect((prepare.get_node("MechanicPanel/Line3") as Label).text == clear_expected,
		"准备页 Line3 应显示克制结论：预期「%s」" % clear_expected)
	_expect((prepare.get_node("MechanicPanel/Line4") as Label).text == "",
		"两来源克制结论只占 Line3")
	_expect((prepare.get_node("MechanicPanel/Line1") as Label).text.contains("岩障开路"),
		"准备页 Line1 应继续显示关卡机制摘要")
	_expect(not (prepare.get_node("MechanicPanel/Line2") as Label).text.is_empty(),
		"准备页 Line2 应继续显示关卡提示")

	var neutral_enemies: Array[Dictionary] = [{"name": "雷球", "element": "thunder"}]
	prepare.set("_enemy_team", neutral_enemies)
	prepare.call("_sync_mechanic_hint")
	_expect((prepare.get_node("MechanicPanel/Line3") as Label).text == NEUTRAL_TEXT,
		"准备页全中性时应显示无克制文案")
	_expect((prepare.get_node("MechanicPanel/Line4") as Label).text == "",
		"全中性不应占用 Line4")

	prepare.init({"stageId": "stage_1_4"})
	var complex_enemies: Array[Dictionary] = [
		{"name": "水泡泡", "element": "water"},
		{"name": "草精灵", "element": "grass"},
	]
	prepare.set("_enemy_team", complex_enemies)
	prepare.set("_player_team", allies)
	prepare.call("_sync_mechanic_hint")
	var line3 := (prepare.get_node("MechanicPanel/Line3") as Label).text
	var line4 := (prepare.get_node("MechanicPanel/Line4") as Label).text
	var complex_expected := "火被水克：小火龙 -25%；草克水：草苗儿 +50%；火克草：小火龙 +50%；水被草克：水龟仔 -25%"
	_expect(not line4.is_empty(), "四来源长句应折成 Line3 + Line4 两行")
	_expect("%s；%s" % [line3, line4] == complex_expected,
		"折行后应保持同一克制结论：预期「%s」，实际「%s；%s」" % [complex_expected, line3, line4])
	prepare.queue_free()
	await process_frame


func _test_battle_transcript_identical() -> void:
	var baseline := FileAccess.get_file_as_string(BASELINE_BATTLE_PATH).strip_edges()
	_expect(not baseline.is_empty(), "应存在基线战斗转录 %s" % BASELINE_BATTLE_PATH)
	var live := TranscriptScript.build_payload_json()
	_expect(live == baseline, "同一固定种子战局的日志与结算应与基线逐字节一致")
	print("[PrepareMatchup] battle_transcript_identical=%s bytes=%d" % [str(live == baseline), live.to_utf8_buffer().size()])


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[PrepareMatchup] OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("[PrepareMatchup] " + failure)
	quit(1)
