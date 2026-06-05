# ============================================
# ui/scene/scene_main.gd - 主菜单可编辑场景控制器
# 静态视觉与按钮布局由 src/ui/scenes/main_lobby.tscn 管理。
# ============================================

class_name SceneMain
extends Control

signal button_pressed(btn_id: String)

const CartoonButtonFeedbackScript := preload("res://src/ui/components/cartoon_button_feedback.gd")
const CartoonTypographyScript := preload("res://src/ui/components/cartoon_typography.gd")
const BUTTON_DESCRIPTIONS := {
	"start": "选择关卡，开始三消冒险战斗！",
	"team": "编队你的怪物伙伴，打造最强阵容",
	"album": "查看已收服的怪物图鉴",
	"signin": "每日签到领取奖励",
	"shop": "购买道具和装备",
	"inventory": "查看和管理你的物品",
	"ranch": "牧场挂机培养，怪物自动获得经验",
	"achievement": "查看冒险成就进度",
	"settings": "游戏设置和选项"
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
	"SigninButton": "signin"
}
static var instance: SceneMain

var _storage: Node = null
var _navigation_queued := false
var _player: Dictionary = {
	"name": "冒险者小帅",
	"level": 1,
	"gold": 0,
	"gems": 0,
	"exp": 0,
	"exp_to_level": 100
}

@onready var _player_name: Label = %PlayerName
@onready var _level_value: Label = %LevelValue
@onready var _exp_fill: Control = %ExperienceFill
@onready var _exp_value: Label = %ExpValue
@onready var _gold_value: Label = %GoldValue
@onready var _diamond_value: Label = %DiamondValue

func _ready() -> void:
	instance = self
	CartoonTypographyScript.apply(self, "lobby")
	for button_name in BUTTON_IDS:
		var button := get_node("%" + button_name) as TextureButton
		var button_id: String = BUTTON_IDS[button_name]
		_attach_button_feedback(button, _feedback_profile(button_id))
		button.pressed.connect(_queue_button_pressed.bind(button_id))
		button.tooltip_text = BUTTON_DESCRIPTIONS[button_id]
	var settings_top_button := get_node_or_null("Header/SettingsTopButton") as TextureButton
	if settings_top_button != null:
		_attach_button_feedback(settings_top_button, CartoonButtonFeedback.Profile.ICON)
		settings_top_button.pressed.connect(_queue_button_pressed.bind("settings"))
		settings_top_button.tooltip_text = BUTTON_DESCRIPTIONS["settings"]
	for plus_path in ["Header/GoldPlus", "Header/DiamondPlus"]:
		var plus_button := get_node_or_null(plus_path) as TextureButton
		if plus_button != null:
			_attach_button_feedback(plus_button, CartoonButtonFeedback.Profile.ICON)
			plus_button.pressed.connect(_queue_button_pressed.bind("shop"))
			plus_button.tooltip_text = BUTTON_DESCRIPTIONS["shop"]
	_update_player_display()

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

func _on_button_pressed(button_id: String) -> void:
	button_pressed.emit(button_id)

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

func _feedback_profile(button_id: String) -> int:
	if button_id == "start":
		return CartoonButtonFeedback.Profile.PRIMARY
	if button_id in ["team", "ranch", "shop"]:
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
