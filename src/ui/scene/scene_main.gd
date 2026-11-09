# ============================================
# ui/scene/scene_main.gd - 主菜单可编辑场景控制器
# 静态视觉与按钮布局由 src/ui/scenes/main_lobby.tscn 管理。
# ============================================

class_name SceneMain
extends Control

signal button_pressed(btn_id: String)

const BattleBgmScript = preload("res://src/ui/components/battle_bgm.gd")

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
const EXP_BAR_WIDTH := 108.0

static var instance: SceneMain

## 大厅背景音乐：复用战斗 BGM 的合成器与全局单播放器约束，只切换轨道参数。
var _lobby_bgm: Node = null

## 大厅按钮音效：复用 battle_sfx.gd；场景销毁时连同播放器一起释放。
var _button_sfx: BattleSfx = null

var _storage: Node = null
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
@onready var _exp_fill: TextureRect = %ExperienceFill
@onready var _exp_value: Label = %ExpValue
@onready var _gold_value: Label = %GoldValue
@onready var _diamond_value: Label = %DiamondValue

func _ready() -> void:
	instance = self
	_button_sfx = BattleSfx.new()
	_button_sfx.name = "ButtonSfx"
	add_child(_button_sfx)
	_lobby_bgm = BattleBgmScript.new()
	_lobby_bgm.name = "LobbyBgm"
	_lobby_bgm.set_track("lobby")
	add_child(_lobby_bgm)
	for button_name in BUTTON_IDS:
		var button := get_node("%" + button_name) as TextureButton
		var button_id: String = BUTTON_IDS[button_name]
		if button_id == "start":
			button.button_down.connect(_on_button_pressed.bind(button_id))
		else:
			button.pressed.connect(_on_button_pressed.bind(button_id))
		button.tooltip_text = BUTTON_DESCRIPTIONS[button_id]
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
	_exp_fill.size.x = EXP_BAR_WIDTH * exp_value / exp_target
	_exp_value.text = "%d/%d" % [int(exp_value), int(exp_target)]
	_gold_value.text = _format_number(int(_player.get("gold", 0)))
	_diamond_value.text = _format_number(int(_player.get("gems", 0)))

func _on_button_pressed(button_id: String) -> void:
	_play_button_click()
	button_pressed.emit(button_id)


func _play_button_click() -> void:
	# soundOn=false 时不向音效层发请求；按钮正常导航，只是没有声音。
	if _button_sfx != null and _button_sfx.enabled:
		_button_sfx.play("button_click")

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
	return str(num)

func destroy() -> void:
	if instance == self:
		instance = null
