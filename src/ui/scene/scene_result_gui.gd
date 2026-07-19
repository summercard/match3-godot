# scene_result_gui.gd - 可在 Godot 编辑器中调整的战斗结算与捕捉结果界面
class_name SceneResultGui
extends "res://src/ui/controllers/result_logic.gd"

const CartoonButtonFeedbackScript := preload("res://src/ui/components/cartoon_button_feedback.gd")
const CartoonTypographyScript := preload("res://src/ui/components/cartoon_typography.gd")
const ResultConfettiLayerScript := preload("res://src/ui/components/result_confetti_layer.gd")

const STAR_PATHS := ["StarRow/Star1", "StarRow/Star2", "StarRow/Star3"]
const REWARD_SLOT_PATHS := [
	"RewardPanel/Slots/RewardSlot1",
	"RewardPanel/Slots/RewardSlot2",
	"RewardPanel/Slots/RewardSlot3",
	"RewardPanel/Slots/RewardSlot4",
]
const EXP_CARD_PATHS := [
	"ExpPanel/Cards/ExpCard1",
	"ExpPanel/Cards/ExpCard2",
	"ExpPanel/Cards/ExpCard3",
]
const NORMAL_RESULT_NODES := [
	"WinFx",
	"Banner",
	"StarRow",
	"BattleInfo",
	"CaptureResultPanel",
	"RewardPanel",
	"ExpPanel",
	"LevelUpPanel",
	"Buttons",
]

var _capture_success_time := 0.0
var _capture_success_last_visible := false
var _win_confetti_layer: Control = null

# === 胜利结算入场动画状态 ===
const STAR_ENTRY_SCALE := 1.7
const STAR_ENTRY_DURATION := 0.22
const STAR_ENTRY_STAGGER := 0.16
const STAR_ENTRY_START := 0.20
const SLOT_ENTRY_START := 0.55
const SLOT_ENTRY_STAGGER := 0.10
const EXP_ENTRY_START := 0.85
const EXP_ENTRY_STAGGER := 0.10
const BUTTONS_ENTRY_START := 1.10
const BANNER_DURATION := 0.22
const SLOT_DURATION := 0.18
var _normal_entry_played: bool = false
var _normal_entry_phase: int = 0  # 0=未开始 1=横幅 2=战斗信息 3=星星 4=奖励 5=经验 6=按钮 7=完成

func _ready() -> void:
	name = "SceneResult"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)
	_setup_win_confetti_fx()
	CartoonTypographyScript.apply(self, "lobby")
	_apply_result_compact_text()
	_connect_gui_actions()
	_sync_gui()

func init(data: Dictionary = {}) -> void:
	initialize(get_node_or_null("/root/GameManager"), data)

func initialize(game: Node, battle_result: Dictionary) -> void:
	super.initialize(game, battle_result)
	_sync_gui()

func _process(delta: float) -> void:
	super._process(delta)
	_update_capture_success_animation(delta)
	_sync_gui()

func _draw() -> void:
	pass

func _gui_input(_event: InputEvent) -> void:
	pass

func _connect_gui_actions() -> void:
	_connect_button("Buttons/BackButton", _on_result_back_pressed)
	_connect_button("Buttons/NextButton", _on_result_next_pressed)
	_connect_button("Buttons/RetryButton", _on_result_retry_pressed)
	_connect_button("CaptureSuccessLayer/Buttons/ConfirmButton", _on_capture_confirm_pressed)
	_connect_button("CaptureSuccessLayer/Buttons/ViewDexButton", _on_capture_dex_pressed)
	_attach_gui_feedback()

func _setup_win_confetti_fx() -> void:
	var win_fx := get_node_or_null("WinFx") as Control
	if win_fx == null:
		return
	for path in ["ConfettiLeft", "ConfettiRight"]:
		var legacy := win_fx.get_node_or_null(path) as CanvasItem
		if legacy != null:
			legacy.visible = false
	_win_confetti_layer = ResultConfettiLayerScript.new()
	_win_confetti_layer.name = "ConfettiFx"
	_win_confetti_layer.z_index = 3
	_win_confetti_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_win_confetti_layer.offset_left = 0.0
	_win_confetti_layer.offset_top = 0.0
	_win_confetti_layer.offset_right = 0.0
	_win_confetti_layer.offset_bottom = 0.0
	win_fx.add_child(_win_confetti_layer)

func _connect_button(path: String, action: Callable) -> void:
	var button := get_node_or_null(path) as BaseButton
	if button != null and not button.pressed.is_connected(action):
		button.pressed.connect(action)

func _attach_gui_feedback() -> void:
	for path in [
		"Buttons/BackButton",
		"Buttons/NextButton",
		"Buttons/RetryButton",
		"CaptureSuccessLayer/Buttons/ConfirmButton",
		"CaptureSuccessLayer/Buttons/ViewDexButton",
	]:
		var button := get_node_or_null(path) as BaseButton
		if button == null or button.has_node("CartoonFeedback"):
			continue
		var feedback := CartoonButtonFeedbackScript.new() as CartoonButtonFeedback
		button.add_child(feedback)
		var profile := CartoonButtonFeedback.Profile.PRIMARY if path.begins_with("Buttons/") or path.contains("CaptureSuccessLayer") else CartoonButtonFeedback.Profile.NAV
		feedback.setup(button, profile)

func _should_show_capture_success() -> bool:
	return _is_win and _captured and not _capture_target.is_empty()

func _sync_capture_success_layer() -> void:
	var layer := get_node_or_null("CaptureSuccessLayer") as Control
	if layer == null:
		return
	var show_success := _should_show_capture_success()
	layer.visible = show_success
	for path in NORMAL_RESULT_NODES:
		var node := get_node_or_null(path) as CanvasItem
		if node != null:
			node.visible = not show_success
	if show_success and not _capture_success_last_visible:
		_capture_success_time = 0.0
		_restart_capture_success_entry()
	_capture_success_last_visible = show_success
	if not show_success:
		return
	_sync_capture_success_data(layer)

func _sync_capture_success_data(layer: Control) -> void:
	var portrait := layer.get_node_or_null("Stage/MonsterPortrait") as TextureRect
	if portrait != null:
		portrait.texture = _monster_texture(_capture_target, "result")
	var name_label := layer.get_node_or_null("InfoPlaque/Badge") as Label
	if name_label != null:
		name_label.text = _capture_monster_name()
	var summary_label := layer.get_node_or_null("InfoPlaque/PetName") as Label
	if summary_label != null:
		summary_label.text = _capture_summary_label()
	var element_label := layer.get_node_or_null("InfoPlaque/ElementLabel") as Label
	if element_label != null:
		element_label.text = TranslationServer.translate("性格：") + TranslationServer.translate(_capture_nature_label())
	var star_label := layer.get_node_or_null("InfoPlaque/StarLabel") as Label
	if star_label != null:
		star_label.text = TranslationServer.translate("属性：") + TranslationServer.translate(_capture_element_label())
	_fit_capture_label(name_label, 24, 11)
	_fit_capture_label(summary_label, 21, 9)
	_fit_capture_label(element_label, 20, 8)
	_fit_capture_label(star_label, 20, 8)
	_fit_capture_label(layer.get_node_or_null("Buttons/ConfirmButton/Text") as Label, 24, 10)
	_fit_capture_label(layer.get_node_or_null("Buttons/ViewDexButton/Text") as Label, 23, 9)


func _fit_capture_label(label: Label, preferred_size: int, minimum_size: int) -> void:
	if label == null:
		return
	var font := label.get_theme_font("font")
	var available_width := maxf(1.0, label.size.x - 8.0)
	var display_text := TranslationServer.translate(label.text).replace("\n", " ")
	var fitted := preferred_size
	while fitted > minimum_size and font.get_string_size(display_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fitted).x > available_width:
		fitted -= 1
	label.add_theme_font_size_override("font_size", fitted)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true

func _capture_monster_name() -> String:
	var name_text := str(_capture_target.get("name", ""))
	if name_text.is_empty():
		name_text = str(_capture_target.get("monsterId", _capture_target.get("id", "新精灵")))
	return TranslationServer.translate(name_text)

func _capture_summary_label() -> String:
	var rarity := clampi(int(_capture_target.get("rarity", 1)), 1, 5)
	var level := maxi(1, int(_capture_target.get("level", _battle_result.get("enemyLevel", 1))))
	return TranslationServer.translate("星级：%d星  等级：Lv.%d") % [rarity, level]

func _capture_nature_label() -> String:
	var nature_id := str(_capture_target.get("nature", ""))
	if nature_id.is_empty():
		return "未知"
	var nature := NatureDB.get_nature(nature_id)
	return str(nature.get("name", nature_id)) if not nature.is_empty() else nature_id

func _capture_element_label() -> String:
	var raw := str(_capture_target.get("element", _capture_target.get("type", _capture_target.get("boardAffinity", ""))))
	if raw.is_empty():
		var monster_id := str(_capture_target.get("monsterId", _capture_target.get("id", ""))).to_lower()
		var art_path := MonsterArtDBScript.get_art_path(monster_id, "result").to_lower()
		for key in ["fire", "water", "grass", "thunder", "earth", "wind", "light", "dark", "ice"]:
			if monster_id.contains(key) or art_path.contains("_%s" % key):
				raw = key
				break
	if raw.is_empty():
		var tags: Array = CaptureSystemScript.get_target_value_tags(_capture_target)
		if not tags.is_empty():
			for tag in tags:
				var tag_text := str(tag)
				if tag_text in ["火", "水", "草", "雷", "土", "风", "光", "暗", "冰"]:
					raw = tag_text
					break
	var map := {
		"water": "水",
		"fire": "火",
		"grass": "草",
		"leaf": "草",
		"thunder": "雷",
		"earth": "土",
		"wind": "风",
		"light": "光",
		"dark": "暗",
		"ice": "冰",
	}
	return str(map.get(raw, raw if not raw.is_empty() else "未知"))

func _restart_capture_success_entry() -> void:
	var layer := get_node_or_null("CaptureSuccessLayer") as Control
	if layer == null:
		return
	for path in ["TitlePlaque", "Stage", "InfoPlaque", "Buttons"]:
		var node := layer.get_node_or_null(path) as Control
		if node == null:
			continue
		node.pivot_offset = node.size * 0.5
		node.scale = Vector2(0.88, 0.88)
		node.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_interval(0.04 * float(["TitlePlaque", "Stage", "InfoPlaque", "Buttons"].find(path)))
		tween.tween_property(node, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(node, "scale", Vector2(1.04, 1.04), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(node, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

# 胜利结算（无捕获成功）入场序列：横幅 → 战斗信息 → 星星依次弹跳 → 奖励槽 → 经验卡 → 按钮
func _maybe_play_normal_entry() -> void:
	if _normal_entry_played:
		return
	if not _is_win or _should_show_capture_success():
		return
	if not is_inside_tree():
		return
	_normal_entry_played = true
	_normal_entry_phase = 1
	_play_normal_entry()

func _play_normal_entry() -> void:
	# 1) 横幅：从小放大 + 淡入
	var banner := get_node_or_null("Banner") as Control
	if banner != null:
		banner.pivot_offset = banner.size * 0.5
		banner.scale = Vector2(0.85, 0.85)
		banner.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(banner, "modulate:a", 1.0, BANNER_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(banner, "scale", Vector2(1.05, 1.05), BANNER_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(banner, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	_normal_entry_phase = 2
	# 2) 战斗信息条：上浮 + 淡入
	var info := get_node_or_null("BattleInfo") as Control
	if info != null:
		var info_rest_y := info.position.y
		info.position.y = info_rest_y + 12.0
		info.modulate.a = 0.0
		var info_tween := create_tween()
		info_tween.tween_interval(0.18)
		info_tween.tween_property(info, "modulate:a", 1.0, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		info_tween.parallel().tween_property(info, "position:y", info_rest_y, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	_normal_entry_phase = 3
	# 3) 星星：从大变到正常，依次延迟启动
	for i in STAR_PATHS.size():
		var star := get_node_or_null(STAR_PATHS[i]) as TextureRect
		if star == null:
			continue
		star.pivot_offset = star.size * 0.5
		var is_lit := i < _stars
		if is_lit:
			star.scale = Vector2.ONE * STAR_ENTRY_SCALE
		else:
			star.scale = Vector2.ONE
		star.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_interval(STAR_ENTRY_START + float(i) * STAR_ENTRY_STAGGER)
		if is_lit:
			tween.tween_property(star, "modulate:a", 1.0, STAR_ENTRY_DURATION * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(star, "scale", Vector2.ONE * 1.15, STAR_ENTRY_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(star, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			if i == 0:
				var on_first_pop := func() -> void:
					var am := get_node_or_null("/root/AudioManager")
					if am != null and am.has_method("play_sfx"):
						am.call("play_sfx", "powerup_created_star")
				tween.tween_callback(on_first_pop)
		else:
			tween.tween_property(star, "modulate:a", 0.55, STAR_ENTRY_DURATION * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	_normal_entry_phase = 4
	# 4) 奖励槽：从下方弹入 + 淡入（仅可见槽位）
	for i in REWARD_SLOT_PATHS.size():
		var slot := _node(REWARD_SLOT_PATHS[i])
		if not slot.visible:
			continue
		slot.pivot_offset = Vector2(slot.size.x * 0.5, slot.size.y)
		slot.scale = Vector2(0.6, 0.6)
		slot.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_interval(SLOT_ENTRY_START + float(i) * SLOT_ENTRY_STAGGER)
		tween.tween_property(slot, "modulate:a", 1.0, SLOT_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(slot, "scale", Vector2(1.08, 1.08), SLOT_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(slot, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	_normal_entry_phase = 5
	# 5) 经验卡：同奖励槽节奏
	for i in EXP_CARD_PATHS.size():
		var card := _node(EXP_CARD_PATHS[i])
		if not card.visible:
			continue
		card.pivot_offset = Vector2(card.size.x * 0.5, card.size.y)
		card.scale = Vector2(0.6, 0.6)
		card.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_interval(EXP_ENTRY_START + float(i) * EXP_ENTRY_STAGGER)
		tween.tween_property(card, "modulate:a", 1.0, SLOT_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(card, "scale", Vector2(1.08, 1.08), SLOT_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(card, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	_normal_entry_phase = 6
	# 6) 按钮组：上滑 + 淡入
	var buttons := get_node_or_null("Buttons") as Control
	if buttons != null:
		var buttons_rest_y := buttons.position.y
		buttons.position.y = buttons_rest_y + 22.0
		buttons.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_interval(BUTTONS_ENTRY_START)
		tween.tween_property(buttons, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(buttons, "position:y", buttons_rest_y, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	_normal_entry_phase = 7

func _update_capture_success_animation(delta: float) -> void:
	if not _should_show_capture_success():
		return
	_capture_success_time += delta
	var layer := get_node_or_null("CaptureSuccessLayer") as Control
	if layer == null:
		return
	var t := _capture_success_time
	_set_fx_node(layer, "Stage/MagicCircle", 0.96 + sin(t * 2.2) * 0.035, 0.0, 1.0)
	_set_fx_node(layer, "Stage/MonsterPortrait", 1.0 + sin(t * 2.8) * 0.018, 0.0, 1.0)
	_set_fx_node(layer, "SparklesA", 1.0 + sin(t * 3.8) * 0.04, 0.0, 0.62 + sin(t * 4.3) * 0.22)
	_set_fx_node(layer, "SparklesB", 1.0 + sin(t * 3.0 + 1.3) * 0.04, 0.0, 0.44 + sin(t * 4.1 + 0.8) * 0.18)
	var confetti := layer.get_node_or_null("ConfettiTop") as Control
	if confetti != null:
		confetti.position.y = 13.0 + sin(t * 1.6) * 4.0
		confetti.modulate.a = 0.72 + sin(t * 2.4) * 0.08
	var title := layer.get_node_or_null("TitlePlaque") as Control
	if title != null:
		title.position.y = 60.0 + sin(t * 2.0) * 1.6

func _set_fx_node(root: Node, path: NodePath, scale_value: float, rotation_value: float, alpha: float) -> void:
	var node := root.get_node_or_null(path) as Control
	if node == null:
		return
	node.pivot_offset = node.size * 0.5
	node.scale = Vector2.ONE * scale_value
	node.rotation = rotation_value
	node.modulate.a = clampf(alpha, 0.0, 1.0)

func _sync_gui() -> void:
	if not is_inside_tree() or not has_node("Banner"):
		return
	_sync_background()
	_sync_capture_success_layer()
	_sync_banner()
	_sync_stars()
	_sync_battle_info()
	_sync_capture_panel()
	_sync_rewards()
	_sync_exp_panel()
	_sync_levelups()
	_sync_buttons()
	_sync_capture_success_layer()
	_maybe_play_normal_entry()

func _sync_background() -> void:
	var background := get_node_or_null("Background") as TextureRect
	if background == null:
		return
	var stage_id := str(_battle_result.get("stageId", _battle_result.get("stage_id", "")))
	background.texture = _get_texture(StageWarBackgroundsScript.path_for(stage_id, {}, _battle_result))

func _sync_banner() -> void:
	var banner_key := "victory_banner" if _is_win else "defeat_banner"
	(get_node("Banner/Frame") as TextureRect).texture = _result_texture(banner_key)
	_label("Banner/Title").text = "战斗胜利" if _is_win else "战斗失败"
	_node("WinFx").visible = _is_win

func _sync_stars() -> void:
	for i in STAR_PATHS.size():
		var key := "star_lit" if i < _stars else "star_dim"
		(get_node(STAR_PATHS[i]) as TextureRect).texture = _result_texture(key)

func _sync_battle_info() -> void:
	var turn_count := int(_battle_result.get("turnCount", 0))
	var max_turns := int(_battle_result.get("maxTurns", 20))
	_label("BattleInfo/TurnLabel").text = TranslationServer.translate("回合 %d / %d") % [turn_count, max_turns]
	var enemy_label := _label("BattleInfo/EnemyLabel")
	enemy_label.text = ""
	enemy_label.visible = false

func _sync_capture_panel() -> void:
	var panel := _node("CaptureResultPanel")
	panel.visible = _is_win and not _captured and not _capture_result.is_empty()
	if not panel.visible:
		return
	(panel.get_node("Ring") as TextureRect).visible = false
	(panel.get_node("MonsterPortrait") as TextureRect).visible = false
	(panel.get_node("Plaque") as TextureRect).texture = _result_texture("capture_plaque")
	(panel.get_node("Title") as Label).text = "未捕捉"
	for path in ["Line1", "Line2", "Line3"]:
		var line := panel.get_node(path) as Label
		line.text = ""
		line.visible = false

func _capture_lines() -> Array[String]:
	var lines: Array[String] = []
	if not _capture_target.is_empty():
		var target_tags: Array = _capture_result.get("target_tags", [])
		if target_tags.is_empty():
			target_tags = CaptureSystemScript.get_target_value_tags(_capture_target)
		var localized_tags: Array[String] = []
		for tag in target_tags.slice(0, 3):
			localized_tags.append(TranslationServer.translate(str(tag)))
		lines.append(TranslationServer.translate("目标: %s  %s") % [TranslationServer.translate(str(_capture_target.get("name", ""))), " / ".join(localized_tags)])
	if not _capture_item_used.is_empty():
		lines.append(TranslationServer.translate("消耗: %s") % TranslationServer.translate(str(_capture_item_used.get("name", ""))))
	var reason := str(_capture_result.get("reason", ""))
	if reason.is_empty() and not _capture_window.is_empty():
		reason = TranslationServer.translate("窗口: %s %d%%") % [TranslationServer.translate(str(_capture_window.get("label", ""))), int(round(float(_capture_window.get("stability", 0.0)) * 100.0))]
	if not reason.is_empty():
		lines.append(reason)
	var advice := str(_capture_result.get("advice", ""))
	if not advice.is_empty() and not _captured:
		lines.append(advice)
	return lines.slice(0, 3)

func _sync_rewards() -> void:
	var progress := clampf(_reward_anim_progress, 0.0, 1.0)
	var number_progress := 1.0 - pow(1.0 - progress, 3.0)
	var animated_gold := roundi(int(_rewards.get("gold", 0)) * number_progress)
	var animated_gems := roundi(int(_rewards.get("gems", 0)) * number_progress)
	var shared: Dictionary = _monster_exp_awards.get("shared", {})
	var gained_exp := int(shared.get("added", _rewards.get("exp", 0)))
	var total_exp := int(shared.get("current", gained_exp))
	var old_total_exp := maxi(0, total_exp - gained_exp)
	var animated_gained_exp := roundi(gained_exp * number_progress)
	var animated_total_exp := roundi(lerpf(float(old_total_exp), float(total_exp), number_progress))
	var reward_items: Array[Dictionary] = [
		{"icon": "gold", "amount": "+%d" % animated_gold},
		{"icon": "exp", "amount": TranslationServer.translate("总槽 %d\n获得 +%d") % [animated_total_exp, animated_gained_exp], "compact": true},
	]
	if int(_rewards.get("gems", 0)) > 0:
		reward_items.append({"icon": "diamond", "amount": "+%d" % animated_gems})
	if _rewards.get("item", null):
		var animated_item_count := roundi(maxi(1, int(_rewards.get("item_count", 1))) * number_progress)
		reward_items.append({
			"icon": _get_reward_item_icon_key(str(_rewards.get("item", ""))),
			"amount": "%s x%d" % [str(_rewards.get("item_name", _rewards.get("item", "道具"))), animated_item_count]
		})
	var visible_count := mini(reward_items.size(), REWARD_SLOT_PATHS.size())
	var slot_width := 72.0
	var slot_gap := 10.0
	var slots_width := visible_count * slot_width + maxi(0, visible_count - 1) * slot_gap
	var start_x := (343.0 - slots_width) * 0.5
	for i in REWARD_SLOT_PATHS.size():
		var slot := _node(REWARD_SLOT_PATHS[i])
		slot.visible = i < reward_items.size()
		if i >= reward_items.size():
			continue
		slot.position.x = start_x + i * (slot_width + slot_gap)
		var item := reward_items[i]
		(slot.get_node("Icon") as TextureRect).texture = _result_texture(str(item.get("icon", "")))
		(slot.get_node("Amount") as Label).text = str(item.get("amount", ""))
		_style_compact_label(slot.get_node("Amount") as Label, 8 if bool(item.get("compact", false)) else 11, 2)

func _sync_exp_panel() -> void:
	_label("ExpPanel/Title").text = "共享经验槽"
	var shared: Dictionary = _monster_exp_awards.get("shared", {})
	var added := int(shared.get("added", _rewards.get("exp", 0)))
	var current := int(shared.get("current", 0))
	var capacity := int(shared.get("capacity", 0))
	var desc := TranslationServer.translate("本次 +%d · 经验槽 %d/%d") % [added, current, capacity]
	if int(shared.get("overflow", 0)) > 0:
		desc += "（已满）"
	_label("ExpPanel/Desc").text = desc
	var team: Array = _battle_result.get("playerTeam", [])
	var display_team := team.filter(func(m): return m != null).slice(0, EXP_CARD_PATHS.size())
	for i in EXP_CARD_PATHS.size():
		var card := _node(EXP_CARD_PATHS[i])
		card.visible = i < display_team.size()
		if i >= display_team.size():
			continue
		var monster: Dictionary = display_team[i]
		(card.get_node("Portrait") as TextureRect).texture = _monster_texture(monster, "result")
		(card.get_node("Level") as Label).visible = false
		(card.get_node("Exp") as Label).visible = false

func _apply_result_compact_text() -> void:
	for path in REWARD_SLOT_PATHS:
		var slot := get_node_or_null(path) as Control
		if slot == null:
			continue
		_style_compact_label(slot.get_node_or_null("Amount") as Label, 11, 2)
	for path in EXP_CARD_PATHS:
		var card := get_node_or_null(path) as Control
		if card == null:
			continue
		_style_compact_label(card.get_node_or_null("Level") as Label, 8, 1)
		_style_compact_label(card.get_node_or_null("Exp") as Label, 8, 1)

func _style_compact_label(label: Label, font_size: int, outline_size: int) -> void:
	if label == null:
		return
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("outline_size", outline_size)
	label.clip_text = true

func _sync_levelups() -> void:
	_node("LevelUpPanel").visible = false
	var sweep_unlocked := get_node_or_null("SweepUnlocked") as Control
	if sweep_unlocked != null:
		sweep_unlocked.visible = false

func _sync_buttons() -> void:
	_node("Buttons/BackButton").visible = true
	_node("Buttons/NextButton").visible = (not _is_win) or _has_next_stage
	_node("Buttons/RetryButton").visible = true
	_label("Buttons/BackButton/Text").text = "返回" if _has_next_stage else ("返回关卡" if _is_win else "重试")
	_label("Buttons/NextButton/Text").text = "下一关"
	_label("Buttons/RetryButton/Text").text = "课堂升级精灵" if _is_win else "重试"
	_style_compact_label(_label("Buttons/RetryButton/Text"), 10 if _is_win else 13, 2)

	if not _is_win:
		_label("Buttons/BackButton/Text").text = "返回庄园"
		_label("Buttons/NextButton/Text").text = "回精灵课堂升级"
		_style_compact_label(_label("Buttons/NextButton/Text"), 9, 2)

func _on_result_back_pressed() -> void:
	_run_after_result_button_feedback(func(): _on_back_btn_pressed())

func _on_result_next_pressed() -> void:
	_run_after_result_button_feedback(func():
		if _is_win:
			_on_next_btn_pressed()
		else:
			_on_classroom_btn_pressed()
	)

func _on_result_retry_pressed() -> void:
	_run_after_result_button_feedback(func():
		if _is_win:
			_on_classroom_btn_pressed()
		else:
			_on_retry_btn_pressed()
	)

func _on_capture_confirm_pressed() -> void:
	_run_after_capture_button_feedback(func():
		if _is_win and _has_next_stage:
			_on_next_btn_pressed()
		else:
			_on_back_btn_pressed()
	)

func _on_capture_dex_pressed() -> void:
	var monster_id := str(_capture_target.get("monsterId", _capture_target.get("id", "")))
	_run_after_capture_button_feedback(func():
		_go_to_scene("album", {
			"selectedMonsterId": monster_id,
			"monsterId": monster_id,
			"tab": "album",
		})
	)

func _run_after_capture_button_feedback(action: Callable) -> void:
	_run_after_result_button_feedback(action)

func _run_after_result_button_feedback(action: Callable) -> void:
	var tree := get_tree()
	if tree == null:
		action.call()
		return
	tree.create_timer(0.14).timeout.connect(action)

func _result_texture(key: String) -> Texture2D:
	var path := str(RESULT_ASSETS.get(key, COMMON_ASSETS.get(key, "")))
	return _get_texture(path)

func _monster_texture(monster: Dictionary, variant: String) -> Texture2D:
	if monster.is_empty():
		return null
	var monster_id := str(monster.get("monsterId", monster.get("id", "")))
	return _get_texture(MonsterArtDBScript.get_art_path(monster_id, variant))

func _node(path: String) -> Control:
	return get_node(path) as Control

func _label(path: NodePath) -> Label:
	return get_node(path) as Label
