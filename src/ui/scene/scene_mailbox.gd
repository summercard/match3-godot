class_name SceneMailbox
extends Control

const MailboxServiceScript = preload("res://src/core/mailbox_service.gd")
const CartoonButtonFeedbackScript = preload("res://src/ui/components/cartoon_button_feedback.gd")
const MonsterArtDBScript = preload("res://src/data/monster_art_db.gd")

signal back_pressed

var _storage: Node = null
var _service: MailboxService = null
var _selected_instance_id := ""
var _selected_mail_id := ""
var _sending := false

@onready var _inbox_panel: Control = %InboxPanel
@onready var _blessing_panel: Control = %BlessingPanel
@onready var _inbox_tab: Button = %InboxTab
@onready var _blessing_tab: Button = %BlessingTab
@onready var _unread_badge: Label = %UnreadBadge
@onready var _mail_rows: Array[Button] = [%Mail0, %Mail1, %Mail2, %Mail3]
@onready var _mail_detail: Label = %MailDetail
@onready var _claim_button: Button = %ClaimButton
@onready var _adventurer_name: Label = %AdventurerName
@onready var _adventurer_portrait: TextureRect = %AdventurerPortrait
@onready var _blessing_status: Label = %BlessingStatus
@onready var _send_button: Button = %SendButton
@onready var _star: Control = %FlyingStar


func _ready() -> void:
	_storage = get_node_or_null("/root/SaveManager")
	_service = MailboxServiceScript.new(_storage) if _storage != null else null
	for button in [_inbox_tab, _blessing_tab, _claim_button, _send_button, %PrevAdventurer, %NextAdventurer, %BackButton]:
		var feedback := CartoonButtonFeedbackScript.new() as CartoonButtonFeedback
		button.add_child(feedback)
		feedback.setup(button, CartoonButtonFeedback.Profile.ENTRY if button == _send_button else CartoonButtonFeedback.Profile.NAV)
	_inbox_tab.pressed.connect(func(): _show_inbox())
	_blessing_tab.pressed.connect(func(): _show_blessing())
	_claim_button.pressed.connect(_claim_selected_mail)
	_send_button.pressed.connect(_send_blessing)
	%PrevAdventurer.pressed.connect(func(): _cycle_adventurer(-1))
	%NextAdventurer.pressed.connect(func(): _cycle_adventurer(1))
	%BackButton.pressed.connect(func(): back_pressed.emit())
	for index in _mail_rows.size():
		_mail_rows[index].pressed.connect(_open_mail_index.bind(index))
	_star.visible = false
	_refresh()


func init(_data: Dictionary = {}) -> void:
	if is_node_ready():
		_refresh()


func _refresh() -> void:
	if _service == null or not is_node_ready():
		return
	var state := _service.get_state()
	var owned: Array = _storage.call("get_owned_monsters") if _storage != null and _storage.has_method("get_owned_monsters") else []
	if _selected_instance_id.is_empty():
		_selected_instance_id = str(state.get("selected_adventurer_id", ""))
	if _selected_instance_id.is_empty() and not owned.is_empty():
		_selected_instance_id = str((owned[0] as Dictionary).get("instanceId", ""))
	if not _selected_instance_id.is_empty():
		_service.select_adventurer(_selected_instance_id)
	_refresh_blessing(owned, state)
	_refresh_inbox(state)


func _show_inbox() -> void:
	_inbox_panel.visible = true
	_blessing_panel.visible = false
	_inbox_tab.button_pressed = true
	_blessing_tab.button_pressed = false


func _show_blessing() -> void:
	_inbox_panel.visible = false
	_blessing_panel.visible = true
	_inbox_tab.button_pressed = false
	_blessing_tab.button_pressed = true


func _refresh_blessing(owned: Array, state: Dictionary) -> void:
	var current: Dictionary = {}
	for raw in owned:
		if raw is Dictionary and str((raw as Dictionary).get("instanceId", "")) == _selected_instance_id:
			current = raw
			break
	if current.is_empty() and not owned.is_empty():
		current = owned[0]
		_selected_instance_id = str(current.get("instanceId", ""))
	if current.is_empty():
		_adventurer_name.text = "暂无可派遣精灵"
		_adventurer_portrait.texture = null
		_adventurer_portrait.visible = false
	else:
		var monster_id := str(current.get("monsterId", ""))
		var monster: Dictionary = MonsterDb.get_monster(monster_id)
		var display_name := str(current.get("name", monster.get("name", monster_id)))
		_adventurer_name.text = "%s  ·  Lv.%d" % [display_name, int(current.get("level", 1))]
		var portrait_path := MonsterArtDBScript.get_art_path(monster_id, "ranch")
		_adventurer_portrait.texture = load(portrait_path) as Texture2D if not portrait_path.is_empty() else null
		_adventurer_portrait.visible = _adventurer_portrait.texture != null
	var daily_count := int(state.get("daily_send_count", 0))
	_blessing_status.text = "今日可送出 %d 次祝福" % maxi(0, 3 - daily_count)
	_send_button.disabled = current.is_empty() or daily_count >= 3 or _sending


func _refresh_inbox(state: Dictionary) -> void:
	var inbox: Array = state.get("inbox", [])
	var unread := int(state.get("unread_count", 0))
	_unread_badge.visible = unread > 0
	_unread_badge.text = str(unread)
	for index in _mail_rows.size():
		var button := _mail_rows[index]
		if index >= inbox.size():
			button.visible = false
			continue
		button.visible = true
		var mail: Dictionary = inbox[index]
		var prefix := "● " if mail.get("read_at", null) == null else ""
		button.text = "%s%s\n%s" % [prefix, str(mail.get("title", "新邮件")), str(mail.get("sender_name", "远方的冒险者"))]
	if _selected_mail_id.is_empty() and not inbox.is_empty():
		_selected_mail_id = str((inbox[0] as Dictionary).get("id", ""))
	_show_selected_mail(inbox)


func _show_selected_mail(inbox: Array) -> void:
	var mail: Dictionary = {}
	for raw in inbox:
		if raw is Dictionary and str((raw as Dictionary).get("id", "")) == _selected_mail_id:
			mail = raw
			break
	if mail.is_empty():
		_mail_detail.text = "还没有邮件。\n\n选择一只冒险精灵，送出一颗祝福星星吧。"
		_claim_button.disabled = true
		return
	_mail_detail.text = "%s\n\n%s\n\n%s" % [str(mail.get("sender_name", "远方的冒险者")), str(mail.get("body", "")), _attachment_label(mail.get("attachments", []))]
	_claim_button.disabled = mail.get("claimed_at", null) != null
	_claim_button.text = "已领取" if mail.get("claimed_at", null) != null else "领取附件"


func _open_mail_index(index: int) -> void:
	var inbox: Array = _service.get_state().get("inbox", [])
	if index < 0 or index >= inbox.size():
		return
	_selected_mail_id = str((inbox[index] as Dictionary).get("id", ""))
	_service.mark_read(_selected_mail_id)
	_refresh()


func _claim_selected_mail() -> void:
	if _selected_mail_id.is_empty():
		return
	var result := _service.claim_mail(_selected_mail_id)
	if bool(result.get("ok", false)):
		_mail_detail.text += "\n\n附件已收入背包。"
	_refresh()


func _cycle_adventurer(direction: int) -> void:
	var owned: Array = _storage.call("get_owned_monsters") if _storage != null and _storage.has_method("get_owned_monsters") else []
	if owned.is_empty():
		return
	var current_index := 0
	for index in owned.size():
		if str((owned[index] as Dictionary).get("instanceId", "")) == _selected_instance_id:
			current_index = index
			break
	var next_index := posmod(current_index + direction, owned.size())
	_selected_instance_id = str((owned[next_index] as Dictionary).get("instanceId", ""))
	_service.select_adventurer(_selected_instance_id)
	_refresh()


func _send_blessing() -> void:
	if _sending or _selected_instance_id.is_empty():
		return
	_service.select_adventurer(_selected_instance_id)
	var result := _service.send_blessing()
	if not bool(result.get("ok", false)):
		_blessing_status.text = "暂时无法送出祝福。"
		return
	_sending = true
	_send_button.disabled = true
	_blessing_status.text = "祝福星星正在飞往远方…"
	_star.position = Vector2(170.0, 344.0)
	_star.rotation = 0.0
	_star.modulate = Color(1.0, 0.92, 0.36, 1.0)
	_star.visible = true
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_star, "position", Vector2(303.0, 126.0), 0.78).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_star, "scale", Vector2(0.42, 0.42), 0.78)
	tween.tween_property(_star, "rotation", TAU * 0.7, 0.78)
	tween.tween_property(_star, "modulate:a", 0.0, 0.78)
	await tween.finished
	_star.visible = false
	_star.scale = Vector2.ONE
	_star.rotation = 0.0
	_sending = false
	_blessing_status.text = "祝福已飞向远方。信箱收到了新的回应。"
	_refresh()


func _attachment_label(attachments: Array) -> String:
	if attachments.is_empty():
		return "没有附件"
	var labels: Array[String] = []
	for raw in attachments:
		if not raw is Dictionary:
			continue
		var data: Dictionary = raw
		match str(data.get("kind", "")):
			"gold": labels.append("金币 ×%d" % int(data.get("amount", 0)))
			"shared_exp": labels.append("共享经验 ×%d" % int(data.get("amount", 0)))
			"item": labels.append("%s ×%d" % [str(data.get("item_id", "道具")), int(data.get("count", 1))])
	return "附件：" + " / ".join(labels)
