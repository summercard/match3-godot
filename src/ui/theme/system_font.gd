class_name ProjectSystemFont
extends RefCounted


static func regular() -> Font:
	return SystemFont.new()


static func emboldened(amount: float = 0.45) -> Font:
	var font := FontVariation.new()
	font.base_font = regular()
	font.set("variation_embolden", amount)
	return font
