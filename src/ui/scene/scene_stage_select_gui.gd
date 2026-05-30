# scene_stage_select_gui.gd - 可在 Godot 编辑器中逐章调整的章节大地图界面
# 数据、解锁与扫荡规则沿用 SceneStageSelect；每个大章使用独立的 .tscn 地图文件。
class_name SceneStageSelectGui
extends "res://src/ui/scene/scene_stage_select.gd"

const CHAPTER_MAP_NODES := {
	"chapter_1": "ChapterMaps/Chapter01Grassland",
	"chapter_2": "ChapterMaps/Chapter02FireValley",
	"chapter_3": "ChapterMaps/Chapter03MysticForest",
	"chapter_4": "ChapterMaps/Chapter04EclipseCanopy",
	"chapter_5": "ChapterMaps/Chapter05ThunderTemple",
	"chapter_6": "ChapterMaps/Chapter06FrostThrone",
	"chapter_7": "ChapterMaps/Chapter07VoidDomain",
	"chapter_8": "ChapterMaps/Chapter08TemporalRift",
	"chapter_9": "ChapterMaps/Chapter09StarlitTemple",
	"chapter_10": "ChapterMaps/Chapter10ChaosDomain",
	"chapter_11": "ChapterMaps/Chapter11RadiantTemple",
}
const DOT_PATHS := [
	"Header/Dots/Dot1", "Header/Dots/Dot2", "Header/Dots/Dot3",
	"Header/Dots/Dot4", "Header/Dots/Dot5", "Header/Dots/Dot6",
	"Header/Dots/Dot7", "Header/Dots/Dot8", "Header/Dots/Dot9",
	"Header/Dots/Dot10", "Header/Dots/Dot11",
]
const TEXT_WHITE := Color(1.0, 1.0, 1.0)
const TEXT_MUTED := Color(0.66, 0.75, 0.88)

var _chapter_map: Control = null
var _chapter_map_id: String = ""

func _ready() -> void:
	super._ready()
	_connect_shell_actions()
	_sync_gui()

func _create_ui() -> void:
	_back_btn = get_node("Header/BackButton") as TextureButton
	_prev_chapter_btn = get_node("Header/PreviousButton") as TextureButton
	_next_chapter_btn = get_node("Header/NextButton") as TextureButton
	_chapter_title = get_node("Header/ChapterTitle") as Label
	_chapter_name_label = get_node("Header/ChapterName") as Label
	_star_label = get_node("Header/StarValue") as Label
	_header_panel = get_node("Bindings/HeaderPanel") as PanelContainer
	_stage_container = get_node("ChapterMaps") as Control
	_reward_panel = get_node("Bindings/RewardPanel") as PanelContainer
	_dots_container = get_node("Bindings/DotsContainer") as HBoxContainer
	_sweep_dialog = get_node("PopupLayer/SweepDialog") as Control
	_sweep_title_label = get_node("PopupLayer/SweepDialog/TitleLabel") as Label
	_sweep_gold_label = get_node("PopupLayer/SweepDialog/GoldLabel") as Label
	_sweep_exp_label = get_node("PopupLayer/SweepDialog/ExpLabel") as Label
	_sweep_rule_label = get_node("PopupLayer/SweepDialog/RuleLabel") as Label
	_sweep_confirm_btn = get_node("PopupLayer/SweepDialog/ConfirmBtn") as Button
	_sweep_cancel_btn = get_node("PopupLayer/SweepDialog/CancelBtn") as Button
	_sweep_anim_overlay = get_node("PopupLayer/SweepResult") as Control
	_sweep_anim_title_label = get_node("PopupLayer/SweepResult/TitleLabel") as Label
	_sweep_anim_gold_label = get_node("PopupLayer/SweepResult/GoldLabel") as Label
	_sweep_anim_exp_label = get_node("PopupLayer/SweepResult/ExpLabel") as Label

func _connect_shell_actions() -> void:
	_connect_button(_back_btn, _on_back_btn_pressed)
	_connect_button(_prev_chapter_btn, _on_prev_chapter_btn_pressed)
	_connect_button(_next_chapter_btn, _on_next_chapter_btn_pressed)
	_connect_button(_sweep_confirm_btn, _do_sweep_confirm)
	_connect_button(_sweep_cancel_btn, _on_sweep_cancel_pressed)
	var shade := get_node("PopupLayer/Shade") as ColorRect
	if not shade.gui_input.is_connected(_on_popup_shade_input):
		shade.gui_input.connect(_on_popup_shade_input)

func _connect_button(button: BaseButton, action: Callable) -> void:
	if not button.pressed.is_connected(action):
		button.pressed.connect(action)

func _gui_input(_event: InputEvent) -> void:
	# The editable chapter map buttons own all touch input.
	pass

func _draw() -> void:
	# Formal map display is provided by chapter .tscn files, not Canvas drawing.
	pass

func _refresh_stage_nodes() -> void:
	_sync_map_nodes()

func _update_header() -> void:
	if _chapters.is_empty() or _current_chapter_index >= _chapters.size():
		return
	_ensure_chapter_map()
	var chapter: Dictionary = _chapters[_current_chapter_index]
	var chapter_stars := _get_chapter_stars(chapter)
	var total_stars: int = maxi((chapter.get("stages", []).size() as int) * 3, 1)
	var theme_color: Color = CHAPTER_THEME_TINTS.get(_current_chapter_element(), Color(0.30, 0.95, 0.34))
	_chapter_title.text = "第%d章" % (_current_chapter_index + 1)
	_chapter_title.add_theme_color_override("font_color", theme_color)
	_chapter_name_label.text = str(chapter.get("name", ""))
	_star_label.text = "%d/%d" % [chapter_stars, total_stars]
	(get_node("Header/Badge/Number") as Label).text = str(_current_chapter_index + 1)
	_sync_map_nodes()

func _update_chapter_buttons() -> void:
	_prev_chapter_btn.visible = _current_chapter_index > 0
	_prev_chapter_btn.disabled = _current_chapter_index <= 0
	_next_chapter_btn.visible = _current_chapter_index < _chapters.size() - 1
	_next_chapter_btn.disabled = _current_chapter_index >= _chapters.size() - 1

func _update_page_dots() -> void:
	for i in DOT_PATHS.size():
		var dot := get_node(DOT_PATHS[i]) as ColorRect
		dot.visible = i < _chapters.size()
		dot.color = Color(1.0, 0.82, 0.18, 1.0) if i == _current_chapter_index else Color(1.0, 1.0, 1.0, 0.34)
		dot.size = Vector2(10.0, 6.0) if i == _current_chapter_index else Vector2(5.0, 5.0)

func _sync_gui() -> void:
	if not is_inside_tree() or not has_node("ChapterMaps"):
		return
	_ensure_chapter_map()
	_sync_map_nodes()
	_sync_popup_visibility()

func _ensure_chapter_map() -> void:
	var chapter_id := str(_current_chapter().get("id", ""))
	if chapter_id.is_empty() or chapter_id == _chapter_map_id:
		return
	var map_path := str(CHAPTER_MAP_NODES.get(chapter_id, ""))
	if map_path.is_empty() or not has_node(map_path):
		push_error("Cannot find chapter map node: " + map_path)
		return
	for path: String in CHAPTER_MAP_NODES.values():
		(get_node(path) as Control).visible = path == map_path
	_chapter_map = get_node(map_path) as Control
	_chapter_map_id = chapter_id
	_connect_chapter_map_actions()

func _connect_chapter_map_actions() -> void:
	for index in _stage_buttons().size():
		var stage_button := _stage_buttons()[index]
		_connect_button(stage_button, _on_stage_pressed.bind(index))
		_connect_button(stage_button.get_node("SweepButton") as BaseButton, _on_sweep_pressed.bind(index))
	var boss_button := _boss_button()
	if boss_button != null:
		_connect_button(boss_button, _on_boss_pressed)

func _stage_buttons() -> Array[TextureButton]:
	var result: Array[TextureButton] = []
	if _chapter_map == null:
		return result
	for index in 5:
		var path := "StageNodes/Stage%02d" % (index + 1)
		if _chapter_map.has_node(path):
			result.append(_chapter_map.get_node(path) as TextureButton)
	return result

func _boss_button() -> TextureButton:
	if _chapter_map != null and _chapter_map.has_node("BossStage"):
		return _chapter_map.get_node("BossStage") as TextureButton
	return null

func _sync_map_nodes() -> void:
	if _chapter_map == null or _cards.is_empty():
		return
	var stage_cards: Array = _cards.filter(func(card): return not bool(card.get("is_boss", false)))
	var buttons := _stage_buttons()
	for i in buttons.size():
		var button := buttons[i]
		button.visible = i < stage_cards.size()
		if button.visible:
			_sync_stage_button(button, stage_cards[i])
	var boss_card := _boss_card()
	var boss_button := _boss_button()
	if boss_button != null and not boss_card.is_empty():
		_sync_boss_button(boss_button, boss_card)

func _sync_stage_button(button: TextureButton, card: Dictionary) -> void:
	var enabled := bool(card.get("enabled", true))
	button.disabled = not enabled
	button.modulate.a = 1.0 if enabled else 0.80
	(button.get_node("StageNumber") as Label).text = str(card.get("stage_no", ""))
	(button.get_node("StageNumber") as Label).modulate = TEXT_WHITE if enabled else TEXT_MUTED
	var lock_state := button.get_node("LockState") as Label
	lock_state.visible = not enabled
	_sync_stars(button.get_node("Stars") as Control, int(card.get("stars", 0)), enabled)
	(button.get_node("SweepButton") as Button).visible = enabled and bool(card.get("can_sweep", false))

func _sync_boss_button(button: TextureButton, card: Dictionary) -> void:
	var enabled := bool(card.get("enabled", true))
	button.disabled = not enabled
	button.modulate.a = 1.0 if enabled else 0.82
	_sync_stars(button.get_node("Stars") as Control, int(card.get("stars", 0)), enabled)
	(button.get_node("LockState") as Label).visible = not enabled

func _sync_stars(container: Control, count: int, enabled: bool) -> void:
	for i in 3:
		var star := container.get_node("Star%02d" % (i + 1)) as TextureRect
		var path := "res://assets/images/stage/icon_star_lit.png" if i < count else "res://assets/images/stage/icon_star_dim.png"
		star.texture = _get_texture(path)
		star.modulate.a = 1.0 if enabled and i < count else 0.45

func _boss_card() -> Dictionary:
	for card: Dictionary in _cards:
		if bool(card.get("is_boss", false)):
			return card
	return {}

func _active_stage_cards() -> Array:
	return _cards.filter(func(card): return not bool(card.get("is_boss", false)))

func _on_stage_pressed(index: int) -> void:
	var cards := _active_stage_cards()
	if index < cards.size() and bool(cards[index].get("enabled", false)):
		stage_selected.emit(str(cards[index].get("id", "")), cards[index].get("stage_data", {}), _current_chapter_index)

func _on_sweep_pressed(index: int) -> void:
	var cards := _active_stage_cards()
	if index < cards.size() and bool(cards[index].get("enabled", false)) and bool(cards[index].get("can_sweep", false)):
		_show_sweep_dialog(str(cards[index].get("id", "")), str(cards[index].get("text", "")))

func _on_boss_pressed() -> void:
	var card := _boss_card()
	if not card.is_empty() and bool(card.get("enabled", false)):
		stage_selected.emit(str(card.get("id", "")), card.get("stage_data", {}), _current_chapter_index)

func _on_popup_shade_input(event: InputEvent) -> void:
	if not _sweep_dialog_active:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_sweep_cancel_pressed()
	elif event is InputEventScreenTouch and event.pressed:
		_on_sweep_cancel_pressed()

func _switch_chapter(direction: int) -> void:
	super._switch_chapter(direction)
	_sync_gui()

func _show_sweep_dialog(stage_id: String, stage_name: String) -> void:
	super._show_sweep_dialog(stage_id, stage_name)
	_sync_popup_visibility()

func _on_sweep_cancel_pressed() -> void:
	super._on_sweep_cancel_pressed()
	_sync_popup_visibility()

func _do_sweep_confirm() -> void:
	super._do_sweep_confirm()
	_sync_popup_visibility()

func _update_sweep_animation(delta: float) -> void:
	super._update_sweep_animation(delta)
	_sync_popup_visibility()

func _sync_popup_visibility() -> void:
	(get_node("PopupLayer/Shade") as ColorRect).visible = _sweep_dialog_active or _sweep_anim_active
	_sweep_dialog.visible = _sweep_dialog_active
	_sweep_anim_overlay.visible = _sweep_anim_active
