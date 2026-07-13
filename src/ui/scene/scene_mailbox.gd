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
var _tab_inactive_style: StyleBox
var _tab_active_style: StyleBox

@onready var _inbox_panel: Control = %InboxPanel
@onready var _blessing_panel: Control = %BlessingPanel
@onready var _inbox_tab: Button = %InboxTab
@onready var _blessing_tab: Button = %BlessingTab
@onready var _unread_badge: Label = %UnreadBadge
@onready var _mail_rows: Array[Button] = [%Mail0, %Mail1, %Mail2, %Mail3]
@onready var _mail_detail_scroll: ScrollContainer = %MailDetailScroll
@onready var _mail_detail: Label = %MailDetail
@onready var _claim_button: Button = %ClaimButton
@onready var _delete_button: Button = %DeleteButton
@onready var _sender_portrait: TextureRect = %SenderPortrait
@onready var _sender_portrait_frame: Control = %SenderPortraitFrame
@onready var _sent_star_total: Label = %SentStarTotal
@onready var _received_star_total: Label = %ReceivedStarTotal
@onready var _adventurer_name: Label = %AdventurerName
@onready var _adventurer_portrait: TextureRect = %AdventurerPortrait
@onready var _blessing_status: Label = %BlessingStatus
@onready var _send_button: Button = %SendButton
@onready var _star: Control = %FlyingStar
@onready var _blessing_star_trail: Control = %BlessingStarTrail


func _ready() -> void:
	_storage = get_node_or_null("/root/SaveManager")
	_service = MailboxServiceScript.new(_storage) if _storage != null else null
	_tab_inactive_style = _inbox_tab.get_theme_stylebox("normal")
	_tab_active_style = _inbox_tab.get_theme_stylebox("pressed")
	for button in [_inbox_tab, _blessing_tab, _claim_button, _delete_button, _send_button, %PrevAdventurer, %NextAdventurer, %BackButton]:
		var feedback := CartoonButtonFeedbackScript.new() as CartoonButtonFeedback
		button.add_child(feedback)
		feedback.setup(button, CartoonButtonFeedback.Profile.ENTRY if button == _send_button else CartoonButtonFeedback.Profile.NAV)
	_inbox_tab.pressed.connect(func(): _show_inbox())
	_blessing_tab.pressed.connect(func(): _show_blessing())
	_claim_button.pressed.connect(_claim_selected_mail)
	_delete_button.pressed.connect(_delete_selected_mail)
	_send_button.pressed.connect(_send_blessing)
	%PrevAdventurer.pressed.connect(func(): _cycle_adventurer(-1))
	%NextAdventurer.pressed.connect(func(): _cycle_adventurer(1))
	%BackButton.pressed.connect(func(): back_pressed.emit())
	for index in _mail_rows.size():
		_mail_rows[index].pressed.connect(_open_mail_index.bind(index))
	_star.visible = false
	_blessing_star_trail.visible = false
	_show_inbox()
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
	_update_tab_visuals(true)


func _show_blessing() -> void:
	_inbox_panel.visible = false
	_blessing_panel.visible = true
	_inbox_tab.button_pressed = false
	_blessing_tab.button_pressed = true
	_update_tab_visuals(false)


func _update_tab_visuals(inbox_active: bool) -> void:
	if _tab_inactive_style == null or _tab_active_style == null:
		return
	_inbox_tab.add_theme_stylebox_override("normal", _tab_active_style if inbox_active else _tab_inactive_style)
	_blessing_tab.add_theme_stylebox_override("normal", _tab_inactive_style if inbox_active else _tab_active_style)
	_inbox_tab.add_theme_color_override("font_color", Color.WHITE if inbox_active else Color(0.14, 0.34, 0.60, 1))
	_blessing_tab.add_theme_color_override("font_color", Color(0.14, 0.34, 0.60, 1) if inbox_active else Color.WHITE)


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
	_sent_star_total.text = str(int(state.get("sent_blessing_stars", 0)))
	_received_star_total.text = str(int(state.get("received_blessing_stars", 0)))
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
		_set_mail_detail("还没有邮件。\n\n选择一只冒险精灵，送出一颗祝福星星吧。")
		_claim_button.disabled = true
		_delete_button.disabled = true
		_sender_portrait_frame.visible = false
		return
	_set_mail_detail("%s\n\n%s\n\n%s" % [str(mail.get("sender_name", "远方的冒险者")), str(mail.get("body", "")), _attachment_label(mail.get("attachments", []))])
	_claim_button.disabled = mail.get("claimed_at", null) != null
	_claim_button.text = "已领取" if mail.get("claimed_at", null) != null else "领取附件"
	var can_delete := mail.get("claimed_at", null) != null or (mail.get("attachments", []) as Array).is_empty()
	_delete_button.disabled = not can_delete
	_delete_button.tooltip_text = "请先领取附件" if not can_delete else "删除这封邮件"
	var sender_monster_id := str(mail.get("sender_monster_id", ""))
	var portrait_path := MonsterArtDBScript.get_art_path(sender_monster_id, "ranch")
	_sender_portrait.texture = load(portrait_path) as Texture2D if not portrait_path.is_empty() else null
	_sender_portrait_frame.visible = _sender_portrait.texture != null


func _set_mail_detail(content: String) -> void:
	_mail_detail.text = content
	call_deferred("_reset_mail_detail_scroll")


func _reset_mail_detail_scroll() -> void:
	_mail_detail_scroll.scroll_vertical = 0


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
		_set_mail_detail(_mail_detail.text + "\n\n附件已收入背包。")
	_refresh()


func _delete_selected_mail() -> void:
	if _selected_mail_id.is_empty():
		return
	var result := _service.delete_mail(_selected_mail_id)
	if not bool(result.get("ok", false)):
		_set_mail_detail(_mail_detail.text + "\n\n请先领取附件后再删除。")
		return
	_selected_mail_id = ""
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
	# 新回信在星星起飞时就已经抵达收件箱；无需等待完整仪式动画结束。
	_refresh_inbox(_service.get_state())
	_sending = true
	_send_button.disabled = true
	_blessing_status.text = "祝福星星正在飞往远方…"
	_star.position = Vector2(238.0, 356.0)
	_star.scale = Vector2(0.56, 0.56)
	_star.rotation = 0.0
	_star.modulate = Color(1.0, 0.92, 0.36, 1.0)
	_star.visible = true
	_blessing_star_trail.position = Vector2(207.0, 292.0)
	_blessing_star_trail.scale = Vector2(0.65, 0.65)
	_blessing_star_trail.modulate = Color(1.0, 0.78, 0.22, 0.0)
	_blessing_star_trail.visible = true
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_star, "position", Vector2(245.0, -136.0), 1.60).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_star, "scale", Vector2(1.58, 1.58), 0.82).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_star, "rotation", TAU * 2.2, 1.60)
	tween.tween_property(_star, "modulate:a", 0.0, 0.48).set_delay(1.12)
	tween.tween_property(_blessing_star_trail, "position", Vector2(214.0, -96.0), 1.52).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_blessing_star_trail, "scale", Vector2(1.40, 1.40), 1.05)
	tween.tween_property(_blessing_star_trail, "modulate:a", 0.74, 0.22)
	tween.tween_property(_blessing_star_trail, "modulate:a", 0.0, 0.44).set_delay(1.06)
	await tween.finished
	_star.visible = false
	_blessing_star_trail.visible = false
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
