class_name TowerCardOverlay
extends Control

const CartoonButtonFeedbackScript = preload("res://src/ui/components/cartoon_button_feedback.gd")

signal card_selected(card_id: String)

var _cards: Array = []
var _locked := false

@onready var _title: Label = %Title
@onready var _buttons: Array[Button] = [%Card0, %Card1, %Card2]


func _ready() -> void:
	for index in _buttons.size():
		var button := _buttons[index]
		button.pressed.connect(_select_index.bind(index))
		var feedback := CartoonButtonFeedbackScript.new() as CartoonButtonFeedback
		button.add_child(feedback)
		feedback.setup(button, CartoonButtonFeedback.Profile.PRIMARY)
	_refresh()


func configure(cards: Array, floor: int) -> void:
	_cards = cards.duplicate(true)
	if is_node_ready():
		_title.text = TranslationServer.translate("第 %d 层突破 · 选择一张共鸣卡") % floor
		_refresh()


func _refresh() -> void:
	if not is_node_ready():
		return
	for index in _buttons.size():
		var button := _buttons[index]
		var card: Dictionary = _cards[index] if index < _cards.size() and _cards[index] is Dictionary else {}
		button.disabled = _locked or card.is_empty()
		button.visible = not card.is_empty()
		if card.is_empty():
			continue
		var kind := str(card.get("kind", "resonance"))
		button.get_node("Kind").text = _kind_label(kind)
		var card_name := button.get_node("Name") as Label
		card_name.text = TranslationServer.translate(str(card.get("name", "共鸣卡")))
		CartoonTypography.fit_label(card_name, 14, 7)
		button.get_node("Desc").text = str(card.get("desc", ""))


func _select_index(index: int) -> void:
	if _locked or index < 0 or index >= _cards.size():
		return
	var card: Dictionary = _cards[index]
	var card_id := str(card.get("id", ""))
	if card_id.is_empty():
		return
	_locked = true
	_refresh()
	card_selected.emit(card_id)


func _kind_label(kind: String) -> String:
	match kind:
		"supply": return "塔内补给"
		"pact": return "风险契约"
		_: return "共鸣增益"
