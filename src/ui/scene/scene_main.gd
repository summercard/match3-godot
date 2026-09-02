# ============================================
# ui/scene/scene_main.gd - 主菜单可编辑场景控制器
# 静态视觉与按钮布局由 src/ui/scenes/main_lobby.tscn 管理。
# ============================================

class_name SceneMain
extends Control

signal button_pressed(btn_id: String)

const CartoonButtonFeedbackScript := preload("res://src/ui/components/cartoon_button_feedback.gd")
const CartoonTypographyScript := preload("res://src/ui/components/cartoon_typography.gd")
const MailboxRulesScript := preload("res://src/core/mailbox_rules.gd")

# === 大厅入场动画时间线 ===
const ENTRY_HEADER_DELAY := 0.00
const ENTRY_PRIMARY_DELAY := 0.22
const ENTRY_NAV_DELAY := 0.38
const ENTRY_HEADER_DURATION := 0.34
const ENTRY_PRIMARY_DURATION := 0.30
const ENTRY_NAV_DURATION := 0.34
var _entry_played: bool = false
var _mailbox_arrival_played: bool = false
const BUTTON_DESCRIPTIONS := {
	"start": "选择关卡，开始三消冒险战斗！",
	"team": "编队你的精灵伙伴，打造最强阵容",
	"album": "查看已收服的精灵图鉴",
	"signin": "每日签到领取奖励",
	"shop": "购买道具和装备",
	"inventory": "查看和管理你的物品",
	"ranch": "进入精灵课堂，培养并进化精灵",
	"achievement": "查看冒险成就进度",
	"tower": "挑战共鸣塔，验证后期精灵培养",
	"mailbox": "查看远方冒险者的祝福",
	"settings": "游戏设置和选项",
	"test_tool": "打开队长技能类型与表现测试"
}

const BUTTON_IDS := {
	"StartButton": "start",
	"TeamButton": "team",
	"RanchButton": "ranch",
	"ShopButton": "shop",
	"AlbumButton": "album",
	"InventoryButton": "inventory",
	"AchievementButton": "achievement",
	"SettingsButton": "settings",
	"SigninButton": "signin",
	"TowerButton": "tower",
	"MailboxButton": "mailbox",
	"TestToolButton": "test_tool"
}
static var instance: SceneMain

var _storage: Node = null
var _navigation_queued := false
var _player: Dictionary = {
	"name": "冒险者小帅",
	"level": 1,
	"gold": 0,
	"gems": 0,
	"stamina": 5,
	"achievement_score": 0,
	"exp": 0,
	"exp_to_level": 100
}

@onready var _player_name: Label = %PlayerName
@onready var _level_value: Label = %LevelValue
@onready var _exp_fill: Control = %ExperienceFill
@onready var _exp_value: Label = %ExpValue
@onready var _gold_value: Label = %GoldValue
@onready var _diamond_value: Label = %DiamondValue
@onready var _stamina_value: Label = %StaminaValue
@onready var _rank_score: Label = %RankScore
@onready var _mailbox_badge: TextureRect = %MailboxBadge
@onready var _mailbox_arrival_star: TextureRect = %MailboxArrivalStar
@onready var _mailbox_arrival_burst: Control = %MailboxArrivalBurst
@onready var _blessing_arrival_message: Label = %BlessingArrivalMessage

func _ready() -> void:
	instance = self
	CartoonTypographyScript.apply(self, "lobby")
	# 大厅 BGM
	var am := get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("play_bgm"):
		am.call("play_bgm", "bgm_town")
	for button_name in BUTTON_IDS:
		var button := get_node("%" + button_name) as BaseButton
		if button == null:
			continue
		var button_id: String = BUTTON_IDS[button_name]
		_attach_button_feedback(button, _feedback_profile(button_id))
		button.pressed.connect(_queue_button_pressed.bind(button_id))
		button.tooltip_text = str(BUTTON_DESCRIPTIONS.get(button_id, "测试队长技能表现"))
	for plus_path in ["Header/GoldPlus", "Header/DiamondPlus", "Header/StaminaPlus"]:
		var plus_button := get_node_or_null(plus_path) as TextureButton
		if plus_button != null:
			_attach_button_feedback(plus_button, CartoonButtonFeedback.Profile.ICON)
			plus_button.pressed.connect(_queue_button_pressed.bind("shop"))
			plus_button.tooltip_text = BUTTON_DESCRIPTIONS["shop"]
	_update_player_display()
	_maybe_play_entry()
	_mailbox_arrival_star.visible = false
	_blessing_arrival_message.visible = false
	call_deferred("_play_mailbox_blessing_arrival_if_needed")

func init(_data: Dictionary = {}) -> void:
	_load_player_data()
	if is_node_ready():
		_update_player_display()

func _load_player_data() -> void:
	if _storage == null:
		_storage = get_node_or_null("/root/SaveManager")

	if _storage != null and _storage.has_method("get_player"):
		var player: Dictionary = _storage.get_player()
		var level: int = player.get("level", 1)
		_player = {
			"name": player.get("name", "冒险者小帅"),
			"level": level,
			"gold": player.get("gold", 0),
			"gems": player.get("gems", 0),
			"stamina": player.get("stamina", player.get("energy", 5)),
			"achievement_score": _calc_achievement_score(),
			"exp": player.get("exp", 0),
			"exp_to_level": _storage.get_exp_for_level(level) if _storage.has_method("get_exp_for_level") else 100
		}

func _update_player_display() -> void:
	_player_name.text = _ellipsize(str(_player.get("name", "冒险者小帅")), 6)
	_level_value.text = str(int(_player.get("level", 1)))
	var exp_target: float = maxf(float(_player.get("exp_to_level", 100)), 1.0)
	var exp_value: float = clampf(float(_player.get("exp", 0)), 0.0, exp_target)
	_exp_fill.set("value", exp_value / exp_target * 100.0)
	_exp_value.text = "%s/%s" % [_format_number(int(exp_value)), _format_number(int(exp_target))]
	_gold_value.text = _format_number(int(_player.get("gold", 0)))
	_diamond_value.text = _format_number(int(_player.get("gems", 0)))
	_stamina_value.text = "%d/5" % int(_player.get("stamina", 5))
	if _rank_score != null:
		_rank_score.text = ""
	if _storage != null and _storage.has_method("get_mailbox_state"):
		var mailbox_state := _storage.call("get_mailbox_state") as Dictionary
		_mailbox_badge.visible = MailboxRulesScript.count_unread_blessings(mailbox_state.get("inbox", [])) > 0


func _play_mailbox_blessing_arrival_if_needed() -> void:
	if _mailbox_arrival_played or _storage == null or not _storage.has_method("get_mailbox_state"):
		return
	var state := _storage.call("get_mailbox_state") as Dictionary
	var mail_id := MailboxRulesScript.next_lobby_arrival_blessing_id(state)
	if mail_id.is_empty():
		return
	_mailbox_arrival_played = true
	await get_tree().create_timer(0.30).timeout
	if not is_inside_tree():
		return
	if not _mark_mailbox_blessing_arrival_shown(mail_id):
		return
	var target_center: Vector2 = _mailbox_badge.get_global_rect().get_center() - get_global_rect().position
	var star_half_size := _mailbox_arrival_star.size * 0.5
	_mailbox_arrival_star.position = Vector2(308.0, -42.0)
	_mailbox_arrival_star.pivot_offset = star_half_size
	_mailbox_arrival_star.scale = Vector2(0.35, 0.35)
	_mailbox_arrival_star.rotation = -0.45
	_mailbox_arrival_star.modulate = Color(1.0, 0.94, 0.42, 1.0)
	_mailbox_arrival_star.visible = true
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_mailbox_arrival_star, "position", target_center - star_half_size, 1.05).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tween.tween_property(_mailbox_arrival_star, "scale", Vector2(1.08, 1.08), 0.78).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_mailbox_arrival_star, "rotation", TAU * 1.2, 1.05)
	tween.tween_property(_mailbox_arrival_star, "modulate:a", 0.0, 0.28).set_delay(0.86)
	await tween.finished
	_mailbox_arrival_star.visible = false
	_mailbox_arrival_star.scale = Vector2.ONE
	_mailbox_arrival_star.rotation = 0.0
	_mailbox_arrival_burst.call("play", target_center)
	_mailbox_badge.pivot_offset = _mailbox_badge.size * 0.5
	var badge_tween := create_tween()
	badge_tween.tween_property(_mailbox_badge, "scale", Vector2(1.38, 1.38), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	badge_tween.tween_property(_mailbox_badge, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_blessing_arrival_message.modulate.a = 0.0
	_blessing_arrival_message.visible = true
	var message_tween := create_tween()
	message_tween.tween_property(_blessing_arrival_message, "modulate:a", 1.0, 0.12)
	message_tween.tween_interval(1.0)
	message_tween.tween_property(_blessing_arrival_message, "modulate:a", 0.0, 0.16)
	await message_tween.finished
	_blessing_arrival_message.visible = false


func _mark_mailbox_blessing_arrival_shown(mail_id: String) -> bool:
	if _storage == null or not _storage.has_method("get_mailbox_state") or not _storage.has_method("save_mailbox_state"):
		return false
	var state := _storage.call("get_mailbox_state") as Dictionary
	var next := MailboxRulesScript.mark_lobby_arrival_shown(state, mail_id)
	return bool(_storage.call("save_mailbox_state", next))

func _calc_achievement_score() -> int:
	if _storage == null or not _storage.has_method("load_achievements"):
		return 0
	var data: Dictionary = _storage.load_achievements()
	var unlocked: Array = data.get("unlockedIds", [])
	var claimed: Array = data.get("claimedIds", [])
	return unlocked.size() * 100 + claimed.size() * 50

func _on_button_pressed(button_id: String) -> void:
	button_pressed.emit(button_id)

# 大厅入场序列：Header 从上方 → PrimaryButtons 弹入（StartButton 从大到小）→ BottomNav 从下方
func _maybe_play_entry() -> void:
	if _entry_played:
		return
	_entry_played = true
	_play_entry()

func _play_entry() -> void:
	# 1) Header：上方 30px 滑入 + 淡入
	var header := get_node_or_null("Header") as Control
	if header != null:
		var header_rest_y := header.position.y
		header.position.y = header_rest_y - 30.0
		header.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_interval(ENTRY_HEADER_DELAY)
		tween.tween_property(header, "modulate:a", 1.0, ENTRY_HEADER_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(header, "position:y", header_rest_y, ENTRY_HEADER_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 2) PrimaryButtons 容器：scale 弹缩 + 淡入（除 StartButton 外的按钮保持这个）
	var primary := get_node_or_null("PrimaryButtons") as Control
	if primary != null:
		primary.pivot_offset = Vector2(primary.size.x * 0.5, primary.size.y * 0.5)
		primary.scale = Vector2(0.85, 0.85)
		primary.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_interval(ENTRY_PRIMARY_DELAY)
		tween.tween_property(primary, "modulate:a", 1.0, ENTRY_PRIMARY_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(primary, "scale", Vector2(1.06, 1.06), ENTRY_PRIMARY_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(primary, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 3) StartButton：从大到小弹入（独立于 PrimaryButtons 的 pop）
	var start := get_node_or_null("PrimaryButtons/StartButton") as Control
	if start != null:
		start.pivot_offset = start.size * 0.5
		start.scale = Vector2(1.25, 1.25)
		start.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_interval(ENTRY_PRIMARY_DELAY + 0.08)
		tween.tween_property(start, "modulate:a", 1.0, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(start, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# 4) BottomNav：下方 30px 滑入 + 淡入
	var nav := get_node_or_null("BottomNav") as Control
	if nav != null:
		var nav_rest_y := nav.position.y
		nav.position.y = nav_rest_y + 30.0
		nav.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_interval(ENTRY_NAV_DELAY)
		tween.tween_property(nav, "modulate:a", 1.0, ENTRY_NAV_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(nav, "position:y", nav_rest_y, ENTRY_NAV_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _queue_button_pressed(button_id: String) -> void:
	if _navigation_queued:
		return
	_navigation_queued = true
	get_tree().create_timer(_navigation_feedback_delay(button_id)).timeout.connect(_dispatch_button_pressed.bind(button_id))

func _dispatch_button_pressed(button_id: String) -> void:
	_navigation_queued = false
	_on_button_pressed(button_id)

func _attach_button_feedback(button: BaseButton, profile: int) -> void:
	var feedback := CartoonButtonFeedbackScript.new() as CartoonButtonFeedback
	button.add_child(feedback)
	feedback.setup(button, profile)
	feedback.set_touch_feedback(true)
	feedback.set_burst_enabled(false)

func _feedback_profile(button_id: String) -> int:
	if button_id == "start":
		return CartoonButtonFeedback.Profile.PRIMARY
	if button_id in ["team", "ranch", "shop", "tower", "mailbox"]:
		return CartoonButtonFeedback.Profile.ENTRY
	return CartoonButtonFeedback.Profile.NAV

func _navigation_feedback_delay(button_id: String) -> float:
	return 0.20 if button_id == "start" else 0.14

func _on_start_pressed() -> void:
	_on_button_pressed("start")

func _on_team_pressed() -> void:
	_on_button_pressed("team")

func _on_album_pressed() -> void:
	_on_button_pressed("album")

func _on_signin_pressed() -> void:
	_on_button_pressed("signin")

func _on_shop_pressed() -> void:
	_on_button_pressed("shop")

func _on_inventory_pressed() -> void:
	_on_button_pressed("inventory")

func _on_ranch_pressed() -> void:
	_on_button_pressed("ranch")

func _on_achievement_pressed() -> void:
	_on_button_pressed("achievement")

func _on_settings_pressed() -> void:
	_on_button_pressed("settings")

func _ellipsize(text: String, max_chars: int) -> String:
	if text.length() <= max_chars:
		return text
	return text.substr(0, maxi(1, max_chars - 1)) + "..."

func _format_number(num: int) -> String:
	var digits := str(absi(num))
	var formatted := ""
	while digits.length() > 3:
		formatted = "," + digits.substr(digits.length() - 3) + formatted
		digits = digits.substr(0, digits.length() - 3)
	formatted = digits + formatted
	return "-" + formatted if num < 0 else formatted

func destroy() -> void:
	if instance == self:
		instance = null
