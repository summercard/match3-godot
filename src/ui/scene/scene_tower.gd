class_name SceneTower
extends Control

const TowerRunControllerScript = preload("res://src/core/tower_run_controller.gd")
const TowerRulesScript = preload("res://src/core/tower_rules.gd")
const TowerRankProviderScript = preload("res://src/core/tower_rank_provider.gd")
const CartoonButtonFeedbackScript = preload("res://src/ui/components/cartoon_button_feedback.gd")

signal back_pressed

var _storage: Node = null
var _controller: TowerRunController = null
var _show_burst := false

@onready var _unlock_pill: Panel = %UnlockPill
@onready var _unlock_text: Label = %UnlockText
@onready var _status_panel: Panel = %StatusPanel
@onready var _floor_value: Label = %FloorValue
@onready var _wave_value: Label = %WaveValue
@onready var _theme_value: Label = %ThemeValue
@onready var _record_value: Label = %RecordValue
@onready var _start_button: BaseButton = %StartButton
@onready var _start_button_text: Label = %StartButtonText
@onready var _climb_tab: Button = %ClimbTab
@onready var _burst_tab: Button = %BurstTab
@onready var _node_labels: Array[Label] = [%Node1, %Node2, %Node3, %Node4, %Node5]
@onready var _rank_rows: Array[Label] = [%Rank0, %Rank1, %Rank2, %Rank3, %Rank4, %Rank5, %Rank6]


func _ready() -> void:
	_storage = get_node_or_null("/root/SaveManager")
	_controller = TowerRunControllerScript.new(_storage) if _storage != null else null
	for button in [_start_button, _climb_tab, _burst_tab, %BackButton]:
		var feedback := CartoonButtonFeedbackScript.new() as CartoonButtonFeedback
		button.add_child(feedback)
		feedback.setup(button, CartoonButtonFeedback.Profile.ENTRY if button == _start_button else CartoonButtonFeedback.Profile.NAV)
		feedback.set_touch_feedback(true)
		feedback.set_burst_enabled(false)
	_start_button.pressed.connect(_start_or_continue)
	_climb_tab.pressed.connect(func(): _show_burst = false; _refresh())
	_burst_tab.pressed.connect(func(): _show_burst = true; _refresh())
	%BackButton.pressed.connect(func(): back_pressed.emit())
	_refresh()


func init(_data: Dictionary = {}) -> void:
	if is_node_ready():
		_refresh()


func _refresh() -> void:
	if not is_node_ready() or _controller == null:
		return
	var unlocked := _controller.is_unlocked()
	var state := _controller.get_state()
	var floor := TowerRulesScript.current_floor_data(state)
	_unlock_pill.visible = not unlocked
	_unlock_text.text = "未解锁：通关主线第 8 关后开放"
	_unlock_text.modulate = Color(1.0, 0.70, 0.50)
	_status_panel.position.y = 138.0 if unlocked else 122.0
	_floor_value.text = "第 %d 层" % int(state.get("current_floor", 1))
	_wave_value.text = "第 %d/%d 波" % [int(floor.get("towerWave", 1)), int(floor.get("towerWaveCount", 5))]
	_theme_value.text = str(floor.get("towerTheme", "共鸣塔"))
	_record_value.text = "最高 %d 层  ·  单回合 %d" % [int(state.get("highest_floor", 0)), int(state.get("highest_turn_damage", 0))]
	_start_button.disabled = not unlocked
	_start_button_text.text = "继续远征" if bool(state.get("active", false)) else "开启远征"
	for index in _node_labels.size():
		var label := _node_labels[index]
		var global_floor := int(floor.get("current_floor", state.get("current_floor", 1))) - int(floor.get("towerWave", 1)) + index + 1
		if global_floor > 99:
			label.visible = false
			continue
		label.visible = true
		var boss := bool(TowerRulesScript.current_floor_data({"current_floor": global_floor}).get("isBoss", false))
		label.text = "BOSS" if boss else str(index + 1)
		label.modulate = Color(1.0, 0.81, 0.32) if global_floor == int(state.get("current_floor", 1)) else Color(0.78, 0.88, 1.0)
	_climb_tab.button_pressed = not _show_burst
	_burst_tab.button_pressed = _show_burst
	_refresh_rank_rows(state)


func _refresh_rank_rows(state: Dictionary) -> void:
	var player_name := "冒险者"
	if _storage != null and _storage.has_method("get_player"):
		player_name = str((_storage.call("get_player") as Dictionary).get("name", player_name))
	var entries: Array = TowerRankProviderScript.get_burst_entries(player_name, state) if _show_burst else TowerRankProviderScript.get_climb_entries(player_name, state)
	for index in _rank_rows.size():
		var row := _rank_rows[index]
		if index >= entries.size():
			row.text = ""
			continue
		var entry: Dictionary = entries[index]
		var suffix := "单回合 %d" % int(entry.get("damage", 0)) if _show_burst else "第 %d 层 · %d 回合" % [int(entry.get("floor", 0)), int(entry.get("turns", 0))]
		row.text = "%d  %s    %s" % [int(entry.get("rank", index + 1)), str(entry.get("name", "旅行者")), suffix]
		row.modulate = Color(1.0, 0.89, 0.50) if bool(entry.get("is_player", false)) else Color(0.89, 0.94, 1.0)


func _start_or_continue() -> void:
	if _controller == null or not _controller.is_unlocked():
		return
	var state := _controller.get_state()
	if not bool(state.get("active", false)):
		var started := _controller.start_new_run()
		if not bool(started.get("ok", false)):
			_unlock_text.text = "远征启动失败，请检查队伍。"
			return
		state = started.get("state", {})
	var stage := TowerRulesScript.current_floor_data(state)
	stage["towerBuffs"] = state.get("buffs", []).duplicate(true)
	var scene_manager := get_node_or_null("/root/SceneManager")
	if scene_manager != null:
		scene_manager.switch_scene("tower_battle", {
			"stageId": str(stage.get("id", "tower_floor_001")),
			"stageData": stage,
			"towerMode": true,
			"towerState": state
		})
