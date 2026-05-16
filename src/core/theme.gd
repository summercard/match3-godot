class_name GameTheme
extends RefCounted
## 主题配置常量 - 从 js/engine/theme.js 翻译
## 统一管理游戏的所有颜色、字体、圆角、间距、按钮样式

# ========== 色彩系统 ==========
# JS: THEME.colors
class Colors:
	# === 主色系 ===
	static var primary: Color = Color("#2979ff")
	static var primary_dark: Color = Color("#1565c0")
	static var primary_light: Color = Color("#64b5f6")

	# === 背景色系 ===
	static var bg_dark: Color = Color("#0a0a1a")
	static var bg_medium: Color = Color("#1a1a2e")
	static var bg_card: Color = Color("#16213e")
	static var bg_panel: Color = Color("#1a1a2e")

	# === 文字色系 ===
	static var text_primary: Color = Color("#ffffff")
	static var text_secondary: Color = Color("#cccccc")
	static var text_muted: Color = Color("#888888")
	static var text_dark: Color = Color("#555555")

	# === 属性色 ===
	static var fire: Color = Color("#ff6b35")
	static var water: Color = Color("#4fc3f7")
	static var grass: Color = Color("#66bb6a")
	static var thunder: Color = Color("#ffd54f")
	static var light: Color = Color("#e0e0e0")

	# === 状态色 ===
	static var success: Color = Color("#4caf50")
	static var warning: Color = Color("#ff9800")
	static var danger: Color = Color("#f44336")
	static var gold: Color = Color("#ffd700")

	# === 特效色 ===
	static var white: Color = Color("#ffffff")
	static var black: Color = Color("#000000")
	static var transparent: Color = Color(0, 0, 0, 0)

	# === 战斗场景专用色 ===
	# JS: THEME.colors.battle
	class Battle:
		static var board_bg: Color = Color("#0f3460")       # 棋盘背景深蓝
		static var enemy_turn_bar: Color = Color("#4a1a1a")  # 敌方回合底部栏
		static var hp_bar_bg: Color = Color("#333333")        # HP条背景
		static var skill_charge_bg: Color = Color("#222222")  # 技能充能条背景
		static var enemy_hp_text: Color = Color("#ffaaaa")    # 敌方HP文字
		static var player_hp_text: Color = Color("#aaffaa")   # 我方HP文字
		static var charged_attack: Color = Color("#ff4444")   # 蓄力攻击伤害色
		static var flash_hp_bar: Color = Color("#ff0000")     # 受击闪烁血条色
		static var flash_hit_bar: Color = Color("#ffff00")    # 我方受击闪烁血条色
		static var heal_green: Color = Color("#00ff88")       # 回血飘字色
		static var boss_bg: Color = Color("#3d1a1a")          # Boss卡片背景色

	# === 状态效果色（灼烧/冰冻/中毒/眩晕）===
	class StatusColor:
		static var burn: Color = Color("#ff6622")
		static var freeze: Color = Color("#66ccff")
		static var poison: Color = Color("#44dd44")
		static var stun: Color = Color("#ffdd00")

	# === Boss护盾色 ===
	static var shield: Color = Color("#50b4ff")

	# === 障碍物/锁定色 ===
	# JS: THEME.colors.obstacle
	class Obstacle:
		static var rock: Color = Color("#5a5a6e")         # 石块底色
		static var rock_solid: Color = Color("#6e6e82")    # 完好石块色
		static var rock_cracked: Color = Color("#4a4a5e")  # 裂纹石块色
		static var crack_line: Color = Color("#2a2a3e")    # 裂纹线条色

	# JS: THEME.colors.lock
	class Lock:
		static var chain: Color = Color("#8888aa")      # 锁链色
		static var chain_weak: Color = Color("#7777aa") # 低HP锁链色

	# === 精英关卡专用色 ===
	static var elite: Color = Color("#8B6914")
	static var elite_text: Color = Color("#4a3000")

	# === 结算页专用色 ===
	static var danger_light: Color = Color("#ffaaaa")  # 淡红色（击败敌人文字）
	static var primary_soft: Color = Color("#aaaaff")  # 淡蓝色（存活敌人文字）

	# === 毒雾清除文字色 ===
	static var poison_fog_clear: Color = Color("#88ff88")

	# === 属性数值色（HP/ATK/DEF/SPD 语义色）===
	static var stat_hp: Color = Color("#ff6b6b")
	static var stat_atk: Color = Color("#ffa94d")
	static var stat_def: Color = Color("#69db7c")
	static var stat_spd: Color = Color("#74c0fc")

	# === 签到场景 ===
	class SignIn:
		static var particle_colors: Array = [Color("#FFA500"), Color("#FFFF00"), Color("#FFE135")]

	# === 进化相关 ===
	static var evolve_bg: Color = Color("#6a2d8a")
	static var evolve_ready: Color = Color("#2d7a2d")

	# === 队伍编成 ===
	static var in_team_bg: Color = Color("#1f4068")
	static var slot_border: Color = Color("#3a3a5a")
	static var dialog_bg: Color = Color("#2a2a4a")
	static var disabled_bg: Color = Color("#333333")

# ========== 字体规范 ==========
# JS: THEME.font
class FontDef:
	# 标题
	static var title: Dictionary = {"size": 24, "weight": "bold"}
	# 副标题
	static var subtitle: Dictionary = {"size": 18, "weight": "bold"}
	# 正文
	static var body: Dictionary = {"size": 14, "weight": "normal"}
	# 小字
	static var small: Dictionary = {"size": 12, "weight": "normal"}
	# 极小
	static var tiny: Dictionary = {"size": 11, "weight": "normal"}
	# 数字
	static var number: Dictionary = {"size": 16, "weight": "bold"}
	# 大数字
	static var big_num: Dictionary = {"size": 20, "weight": "bold"}
	# 大号emoji图标
	static var display: Dictionary = {"size": 36, "weight": "normal"}
	# 中号emoji/头像图标
	static var icon: Dictionary = {"size": 28, "weight": "normal"}

# ========== 圆角半径 ==========
# JS: THEME.radius
class Radius:
	static var sm: int = 6
	static var md: int = 10
	static var lg: int = 16
	static var xl: int = 20

# ========== 间距 ==========
# JS: THEME.spacing
class Spacing:
	static var xs: int = 4
	static var sm: int = 8
	static var md: int = 16
	static var lg: int = 24
	static var xl: int = 32

# ========== 按钮样式预设 ==========
# JS: THEME.buttons
class Buttons:
	# 主要按钮
	static var primary: Dictionary = {
		"bgColor": Color("#2979ff"), "textColor": Color("#ffffff"),
		"fontSize": 16, "fontWeight": "bold",
		"radius": 10, "pressScale": 0.95
	}
	# 次要按钮
	static var secondary: Dictionary = {
		"bgColor": Color("#16213e"), "textColor": Color("#ffffff"),
		"fontSize": 14, "fontWeight": "normal",
		"radius": 8, "pressScale": 0.95
	}
	# 危险按钮
	static var danger: Dictionary = {
		"bgColor": Color("#f44336"), "textColor": Color("#ffffff"),
		"fontSize": 14, "fontWeight": "normal",
		"radius": 8, "pressScale": 0.95
	}
	# 金色按钮
	static var gold: Dictionary = {
		"bgColor": Color("#ffd700"), "textColor": Color("#1a1a2e"),
		"fontSize": 18, "fontWeight": "bold",
		"radius": 16, "pressScale": 0.95
	}

# ========== 动画时长 (秒) ==========
# JS: THEME.anim
class Anim:
	static var fast: float = 0.1
	static var normal: float = 0.3
	static var slow: float = 0.5
	static var very_slow: float = 0.8

# ========== 属性色映射 ==========
# JS: THEME.elementColors
const ELEMENT_COLORS: Dictionary = {
	"fire":    Color("#ff6b35"),
	"water":   Color("#4fc3f7"),
	"grass":   Color("#66bb6a"),
	"thunder": Color("#ffd54f"),
	"light":   Color("#e0e0e0"),
	"earth":   Color("#a0522d"),
	"wind":    Color("#20b2aa"),
	"dark":    Color("#7c3aed"),
}

# ========== 便利访问别名（兼容旧调用）==========
# JS: THEME.primary / THEME.success / ...
static func get_primary() -> Color:
	return Colors.primary

static func get_success() -> Color:
	return Colors.success

static func get_warning() -> Color:
	return Colors.warning

static func get_danger() -> Color:
	return Colors.danger

static func get_gold() -> Color:
	return Colors.gold

func get_theme_data() -> Dictionary:
	return {
		"bg_dark": Colors.bg_dark,
		"bg_medium": Colors.bg_medium,
		"bg_card": Colors.bg_card,
		"text_primary": Colors.text_primary,
		"text_secondary": Colors.text_secondary,
		"text_muted": Colors.text_muted,
		"text_dark": Colors.text_dark,
		"primary": Colors.primary,
		"gold": Colors.gold,
		"success": Colors.success,
		"danger": Colors.danger,
		"warning": Colors.warning,
		"white": Colors.white,
		"font": {
			"title": {"size": FontDef.title["size"], "weight": 700},
			"subtitle": {"size": FontDef.subtitle["size"], "weight": 600},
			"body": {"size": FontDef.body["size"], "weight": 400},
			"small": {"size": FontDef.small["size"], "weight": 400},
			"tiny": {"size": FontDef.tiny["size"], "weight": 400}
		},
		"buttons": {
			"primary": {"bg_color": Buttons.primary["bgColor"], "text_color": Buttons.primary["textColor"], "font_size": Buttons.primary["fontSize"], "font_weight": 700},
			"secondary": {"bg_color": Buttons.secondary["bgColor"], "text_color": Buttons.secondary["textColor"], "font_size": Buttons.secondary["fontSize"], "font_weight": 400},
			"danger": {"bg_color": Buttons.danger["bgColor"], "text_color": Buttons.danger["textColor"], "font_size": Buttons.danger["fontSize"], "font_weight": 600},
			"gold": {"bg_color": Buttons.gold["bgColor"], "text_color": Buttons.gold["textColor"], "font_size": Buttons.gold["fontSize"], "font_weight": 700}
		},
		"radius": {"sm": Radius.sm, "md": Radius.md, "lg": Radius.lg, "xl": Radius.xl}
	}
