class_name SceneMailbox
extends Control

const MailboxServiceScript = preload("res://src/core/mailbox_service.gd")
const MailboxRulesScript = preload("res://src/core/mailbox_rules.gd")
const CartoonButtonFeedbackScript = preload("res://src/ui/components/cartoon_button_feedback.gd")
const MonsterArtDBScript = preload("res://src/data/monster_art_db.gd")
const MailContentDBScript = preload("res://src/data/mail_content_db.gd")
const MonsterIdleAnimatorScript = preload("res://src/ui/components/monster_idle_animator.gd")
const MAIL_PAGE_SIZE := 4

signal back_pressed

var _storage: Node = null
var _service = null
var _selected_instance_id := ""
var _selected_mail_id := ""
var _sending := false
var _switching_adventurer := false
var _mail_page := 0

@onready var _inbox_panel: Control = %InboxPanel
@onready var _blessing_panel: Control = %BlessingPanel
@onready var _inbox_tab: BaseButton = %InboxTab
@onready var _blessing_tab: BaseButton = %BlessingTab
@onready var _inbox_tab_text: Label = %InboxTabText
@onready var _blessing_tab_text: Label = %BlessingTabText
@onready var _unread_badge: Label = %UnreadBadge
@onready var _mail_rows: Array[Button] = [%Mail0, %Mail1, %Mail2, %Mail3]
@onready var _mail_row_statuses: Array[Label] = [%Mail0ReadStatus, %Mail1ReadStatus, %Mail2ReadStatus, %Mail3ReadStatus]
@onready var _mail_detail_scroll: ScrollContainer = %MailDetailScroll
@onready var _mail_detail: Label = %MailDetail
@onready var _prev_mail_page: BaseButton = %PrevMailPage
@onready var _next_mail_page: BaseButton = %NextMailPage
@onready var _mail_page_value: Label = %MailPageValue
@onready var _claim_button: Button = %ClaimButton
@onready var _delete_button: Button = %DeleteButton
@onready var _sender_portrait: TextureRect = %SenderPortrait
@onready var _sender_portrait_frame: Control = %SenderPortraitFrame
@onready var _unlocked_species_total: Label = %SentStarTotal
@onready var _collection_star_total: Label = %ReceivedStarTotal
@onready var _adventurer_name: Label = %AdventurerName
@onready var _adventurer_portrait: TextureRect = %AdventurerPortrait
@onready var _adventurer_frame: Control = get_node("BlessingPanel/Panel/AdventurerFrame")
@onready var _selection_sparkle: Control = %SelectionSparkle
@onready var _blessing_status: Label = %BlessingStatus
@onready var _journey_hint: Label = %JourneyHint
@onready var _daily_remaining: Label = %DailyRemaining
@onready var _send_button: Button = %SendButton
@onready var _star: Control = %FlyingStar
@onready var _blessing_star_trail: Control = %BlessingStarTrail


func _ready() -> void:
	_storage = get_node_or_null("/root/SaveManager")
	_service = MailboxServiceScript.new(_storage) if _storage != null else null
	for button in [_inbox_tab, _blessing_tab, _claim_button, _delete_button, _send_button, %PrevAdventurer, %NextAdventurer, _prev_mail_page, _next_mail_page, %BackButton]:
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
	_prev_mail_page.pressed.connect(func(): _change_mail_page(-1))
	_next_mail_page.pressed.connect(func(): _change_mail_page(1))
	%BackButton.pressed.connect(func(): back_pressed.emit())
	for index in _mail_rows.size():
		_mail_rows[index].pressed.connect(_open_mail_index.bind(index))
	_star.visible = false
	_blessing_star_trail.visible = false
	_show_inbox()
	_refresh()
	call_deferred("_play_entry_animation")


func init(_data: Dictionary = {}) -> void:
	if is_node_ready():
		_refresh()


func _refresh() -> void:
	if _service == null or not is_node_ready():
		return
	var state: Dictionary = _service.get_state()
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
	_inbox_tab.self_modulate = Color.WHITE if inbox_active else Color(0.66, 0.79, 0.92, 0.84)
	_blessing_tab.self_modulate = Color(0.66, 0.79, 0.92, 0.84) if inbox_active else Color.WHITE
	_inbox_tab_text.add_theme_color_override("font_color", Color.WHITE if inbox_active else Color(0.75, 0.88, 0.98))
	_blessing_tab_text.add_theme_color_override("font_color", Color(0.75, 0.88, 0.98) if inbox_active else Color.WHITE)


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
		MonsterIdleAnimatorScript.unbind(_adventurer_portrait)
		_adventurer_portrait.texture = null
		_adventurer_portrait.visible = false
	else:
		var monster_id := str(current.get("monsterId", ""))
		var monster: Dictionary = MonsterDb.get_monster(monster_id)
		var display_name := str(current.get("name", monster.get("name", monster_id)))
		_adventurer_name.text = "%s  ·  Lv.%d" % [TranslationServer.translate(display_name), int(current.get("level", 1))]
		var portrait_path := MonsterArtDBScript.get_art_path(monster_id, "ranch")
		_adventurer_portrait.texture = load(portrait_path) as Texture2D if not portrait_path.is_empty() else null
		MonsterIdleAnimatorScript.bind(_adventurer_portrait, monster_id)
		_adventurer_portrait.visible = _adventurer_portrait.texture != null
	var daily_count := int(state.get("daily_send_count", 0))
	_blessing_status.text = TranslationServer.translate("图鉴星星：%d") % MailboxRulesScript.collection_star_total(state)
	var remaining := maxi(0, MailContentDBScript.DAILY_SEND_LIMIT - daily_count)
	_send_button.disabled = current.is_empty() or remaining <= 0 or _sending
	_send_button.tooltip_text = "今日已送出上限" if remaining <= 0 else TranslationServer.translate("今日还可送出 %d 次") % remaining
	_daily_remaining.text = TranslationServer.translate("今日还可送出 %d 次") % remaining
	var has_pending := not (state.get("pending_blessings", []) as Array).is_empty()
	_journey_hint.text = "祝福已乘着星光启程。\n\n每日独立的陌生来信会在\n合适的时候悄悄抵达邮箱。" if has_pending else "送出后，星光会穿过云层。\n\n陌生旅人的祝福每天都会\n在不同时间抵达邮箱。"


func _refresh_inbox(state: Dictionary) -> void:
	var inbox: Array = state.get("inbox", [])
	var page_count := maxi(1, ceili(float(inbox.size()) / float(MAIL_PAGE_SIZE)))
	_mail_page = clampi(_mail_page, 0, page_count - 1)
	var page_start := _mail_page * MAIL_PAGE_SIZE
	var unread := int(state.get("unread_count", 0))
	_unlocked_species_total.text = str((state.get("collection_star_species_ids", []) as Array).size())
	_collection_star_total.text = str(MailboxRulesScript.collection_star_total(state))
	_unread_badge.visible = unread > 0
	_unread_badge.text = str(unread)
	_mail_page_value.text = "%d / %d" % [_mail_page + 1, page_count]
	_prev_mail_page.disabled = _mail_page <= 0
	_next_mail_page.disabled = _mail_page >= page_count - 1
	for index in _mail_rows.size():
		var button := _mail_rows[index]
		var read_status := _mail_row_statuses[index]
		var inbox_index := page_start + index
		if inbox_index >= inbox.size():
			button.visible = false
			continue
		button.visible = true
		var mail: Dictionary = inbox[inbox_index]
		var unread_mail := mail.get("read_at", null) == null
		read_status.text = "未读" if unread_mail else "已读"
		read_status.add_theme_color_override("font_color", Color(0.90, 0.36, 0.10, 1.0) if unread_mail else Color(0.33, 0.51, 0.68, 1.0))
		button.text = "%s\n%s" % [
			TranslationServer.translate(str(mail.get("title", "新邮件"))),
			TranslationServer.translate(str(mail.get("sender_name", "远方的冒险者"))),
		]
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
	MonsterIdleAnimatorScript.bind(_sender_portrait, sender_monster_id)
	_sender_portrait_frame.visible = _sender_portrait.texture != null


func _set_mail_detail(content: String) -> void:
	_mail_detail.text = content
	call_deferred("_reset_mail_detail_scroll")


func _reset_mail_detail_scroll() -> void:
	_mail_detail_scroll.scroll_vertical = 0


func _open_mail_index(index: int) -> void:
	var inbox: Array = _service.get_state().get("inbox", [])
	var inbox_index := _mail_page * MAIL_PAGE_SIZE + index
	if inbox_index < 0 or inbox_index >= inbox.size():
		return
	_selected_mail_id = str((inbox[inbox_index] as Dictionary).get("id", ""))
	_service.mark_read(_selected_mail_id)
	_refresh()


func _change_mail_page(direction: int) -> void:
	var inbox: Array = _service.get_state().get("inbox", [])
	var page_count := maxi(1, ceili(float(inbox.size()) / float(MAIL_PAGE_SIZE)))
	var next_page := clampi(_mail_page + direction, 0, page_count - 1)
	if next_page == _mail_page:
		return
	_mail_page = next_page
	var page_start := _mail_page * MAIL_PAGE_SIZE
	_selected_mail_id = str((inbox[page_start] as Dictionary).get("id", "")) if page_start < inbox.size() else ""
	_refresh()


func _claim_selected_mail() -> void:
	if _selected_mail_id.is_empty():
		return
	var result: Dictionary = _service.claim_mail(_selected_mail_id)
	if bool(result.get("ok", false)):
		_set_mail_detail(_mail_detail.text + TranslationServer.translate("\n\n附件已收入背包。"))
	_refresh()


func _delete_selected_mail() -> void:
	if _selected_mail_id.is_empty():
		return
	var result: Dictionary = _service.delete_mail(_selected_mail_id)
	if not bool(result.get("ok", false)):
		_set_mail_detail(_mail_detail.text + TranslationServer.translate("\n\n请先领取附件后再删除。"))
		return
	_selected_mail_id = ""
	_refresh()


func _cycle_adventurer(direction: int) -> void:
	if _switching_adventurer:
		return
	var owned: Array = _storage.call("get_owned_monsters") if _storage != null and _storage.has_method("get_owned_monsters") else []
	if owned.size() <= 1:
		return
	_switching_adventurer = true
	(%PrevAdventurer as BaseButton).disabled = true
	(%NextAdventurer as BaseButton).disabled = true
	var frame_rest := _adventurer_frame.position
	var name_rest := _adventurer_name.position
	var outgoing := create_tween().set_parallel(true)
	outgoing.tween_property(_adventurer_frame, "position", frame_rest + Vector2(-direction * 22.0, -8.0), 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	outgoing.tween_property(_adventurer_frame, "modulate:a", 0.0, 0.12)
	outgoing.tween_property(_adventurer_name, "position", name_rest + Vector2(-direction * 14.0, -4.0), 0.13)
	outgoing.tween_property(_adventurer_name, "modulate:a", 0.0, 0.12)
	await outgoing.finished
	var current_index := 0
	for index in owned.size():
		if str((owned[index] as Dictionary).get("instanceId", "")) == _selected_instance_id:
			current_index = index
			break
	var next_index := posmod(current_index + direction, owned.size())
	_selected_instance_id = str((owned[next_index] as Dictionary).get("instanceId", ""))
	_service.select_adventurer(_selected_instance_id)
	_refresh()
	_adventurer_frame.position = frame_rest + Vector2(direction * 25.0, 9.0)
	_adventurer_frame.scale = Vector2(0.92, 0.92)
	_adventurer_frame.modulate.a = 0.0
	_adventurer_name.position = name_rest + Vector2(direction * 16.0, 5.0)
	_adventurer_name.modulate.a = 0.0
	_selection_sparkle.visible = true
	_selection_sparkle.scale = Vector2(0.72, 0.72)
	_selection_sparkle.modulate.a = 0.0
	var incoming := create_tween().set_parallel(true)
	incoming.tween_property(_adventurer_frame, "position", frame_rest, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	incoming.tween_property(_adventurer_frame, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	incoming.tween_property(_adventurer_frame, "modulate:a", 1.0, 0.12)
	incoming.tween_property(_adventurer_name, "position", name_rest, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	incoming.tween_property(_adventurer_name, "modulate:a", 1.0, 0.12)
	incoming.tween_property(_selection_sparkle, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	incoming.tween_property(_selection_sparkle, "modulate:a", 0.72, 0.08)
	incoming.tween_property(_selection_sparkle, "modulate:a", 0.0, 0.14).set_delay(0.12)
	await incoming.finished
	_selection_sparkle.visible = false
	(%PrevAdventurer as BaseButton).disabled = false
	(%NextAdventurer as BaseButton).disabled = false
	_switching_adventurer = false


func _play_entry_animation() -> void:
	_play_entry_group([get_node("HeaderPlaque"), get_node("Title"), get_node("TitleTrail"), %BackButton], 0.0, 12.0, 0.96)
	_play_entry_group([_inbox_tab, _blessing_tab], 0.06, 8.0, 0.94)
	_play_entry_group([get_node("InboxPanel/ListPanel")], 0.12, 14.0, 0.96)
	_play_entry_group([get_node("InboxPanel/MailboxTotals"), get_node("InboxPanel/DetailPanel")], 0.18, -14.0, 0.96)
	_play_entry_group([get_node("BlessingPanel/Panel/TravelCard"), get_node("BlessingPanel/Panel/Prompt"), get_node("BlessingPanel/Panel/TravelLine"), _adventurer_frame, _adventurer_name, %PrevAdventurer, %NextAdventurer, _journey_hint], 0.12, 14.0, 0.96)
	_play_entry_group([get_node("BlessingPanel/Panel/ActionRail"), _blessing_status, _send_button, _daily_remaining], 0.18, -14.0, 0.96)


func _play_entry_group(nodes: Array, delay: float, x_offset: float, start_scale: float) -> void:
	for candidate in nodes:
		var control := candidate as Control
		if control == null:
			continue
		var rest_position := control.position
		control.pivot_offset = control.size * 0.5
		control.position = rest_position + Vector2(x_offset, 0.0)
		control.scale = Vector2.ONE * start_scale
		control.modulate.a = 0.0
		var tween := create_tween().set_parallel(true)
		tween.tween_property(control, "modulate:a", 1.0, 0.18).set_delay(delay)
		tween.tween_property(control, "position", rest_position, 0.22).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(control, "scale", Vector2.ONE, 0.22).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _send_blessing() -> void:
	if _sending or _selected_instance_id.is_empty():
		return
	_service.select_adventurer(_selected_instance_id)
	var result: Dictionary = _service.send_blessing()
	if not bool(result.get("ok", false)):
		_blessing_status.text = "暂时无法送出祝福。"
		return
	# 1.3.2：主动祝福只记录寄送历史，不再制造回信或奖励。
	var latest_state: Dictionary = _service.get_state()
	_refresh_inbox(latest_state)
	_blessing_status.text = "祝福已送出。陌生来信会在每日 09:00—21:00 独立抵达。"
	_sending = true
	_send_button.disabled = true
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
			"gold": labels.append(TranslationServer.translate("金币 ×%d") % int(data.get("amount", 0)))
			"shared_exp": labels.append(TranslationServer.translate("共享经验 ×%d") % int(data.get("amount", 0)))
			"item": labels.append("%s ×%d" % [str(data.get("item_id", "道具")), int(data.get("count", 1))])
	return TranslationServer.translate("附件：") + " / ".join(labels)
