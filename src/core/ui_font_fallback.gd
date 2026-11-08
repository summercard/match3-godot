# ui_font_fallback.gd - 统一中文字体回退
# 默认字体在部分系统上缺少简体字形（如“敌”“鉴”会显示成十六进制方块）。
# 这里给默认字体追加一条中文系统字体回退链，保证界面文字可读。
extends Node

const CJK_FONT_NAMES := [
	"Hiragino Sans GB",
	"Heiti SC",
	"Microsoft YaHei UI",
	"Microsoft YaHei",
	"Noto Sans CJK SC",
	"PingFang SC",
]

func _ready() -> void:
	var fallback := ThemeDB.fallback_font
	if fallback == null:
		return
	var chain: Array[Font] = []
	for font in fallback.fallbacks:
		chain.append(font)
	if chain.any(func(font): return font is SystemFont):
		return
	var cjk_font := SystemFont.new()
	cjk_font.font_names = PackedStringArray(CJK_FONT_NAMES)
	cjk_font.allow_system_fallback = true
	chain.append(cjk_font)
	fallback.fallbacks = chain
