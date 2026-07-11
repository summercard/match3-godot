extends Control

const CartoonButtonFeedbackScript = preload("res://src/ui/components/cartoon_button_feedback.gd")

signal retry_pressed
signal return_pressed

var _result := "lose"
var _checkpoint_floor := 1
var _consolation: Dictionary = {}
var _locked := false

@onready var _reason_label: Label = %ReasonLabel
@onready var _checkpoint_label: Label = %CheckpointLabel
@onready var _reward_title: Label = %RewardTitle
@onready var _reward_cards: Control = %RewardCards
@onready var _gold_value: Label = _reward_cards.get_node("GoldCard/Value") as Label
@onready var _exp_value: Label = _reward_cards.get_node("ExpCard/Value") as Label
@onready var _reward_notice: Label = %RewardNotice
@onready var _retry_button: BaseButton = %RetryButton
@onready var _return_button: BaseButton = %ReturnButton
@onready var _panel: Control = $Panel


func _ready() -> void:
	_retry_button.pressed.connect(_on_retry_pressed)
	_return_button.pressed.connect(_on_return_pressed)
	for button in [_retry_button, _return_button]:
		var feedback := CartoonButtonFeedbackScript.new() as CartoonButtonFeedback
		button.add_child(feedback)
		feedback.setup(button, CartoonButtonFeedback.Profile.PRIMARY if button == _retry_button else CartoonButtonFeedback.Profile.NAV)
	_panel.pivot_offset = _panel.size * 0.5
	_panel.scale = Vector2(0.92, 0.92)
	_panel.modulate.a = 0.0
	var entry_tween := create_tween().set_parallel(true)
	entry_tween.tween_property(_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	entry_tween.tween_property(_panel, "modulate:a", 1.0, 0.18)
	_refresh()


func configure(result: String, checkpoint_floor: int, consolation: Dictionary = {}) -> void:
	_result = result
	_checkpoint_floor = maxi(1, checkpoint_floor)
	_consolation = consolation.duplicate(true)
	if is_node_ready():
		_refresh()


func _refresh() -> void:
	if not is_node_ready():
		return
	_reason_label.text = "三只精灵先去休息一下" if _result == "lose" else "本波回合已经用完啦"
	_checkpoint_label.text = "会从第 %d 层安全点重新出发" % _checkpoint_floor
	var delivered := bool(_consolation.get("delivered", false))
	_reward_cards.visible = delivered
	if delivered:
		var reward: Dictionary = _consolation.get("reward", {})
		_reward_title.text = "旅行精灵送来一份鼓励"
		_gold_value.text = "+%d" % int(reward.get("gold", 0))
		_exp_value.text = "+%d" % int(reward.get("shared_exp", 0))
		_reward_notice.text = "补给已寄到远行信箱"
	else:
		_reward_title.text = "这一安全点的鼓励已经寄出"
		_reward_notice.text = "先整理队伍，下一次突破还有新惊喜"
	_retry_button.disabled = _locked
	_return_button.disabled = _locked


func _on_retry_pressed() -> void:
	if _locked:
		return
	_locked = true
	_refresh()
	retry_pressed.emit()


func _on_return_pressed() -> void:
	if _locked:
		return
	_locked = true
	_refresh()
	return_pressed.emit()
