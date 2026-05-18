class_name BattleUIFeedback
extends RefCounted

static func shake_offset(timer: float, duration: float = 0.2, amplitude: float = 4.0) -> Vector2:
	if timer <= 0.0 or duration <= 0.0:
		return Vector2.ZERO
	var intensity: float = clampf(timer / duration, 0.0, 1.0)
	var wave: float = sin(timer * TAU / 0.05)
	return Vector2(wave * amplitude * intensity, 0.0)

static func fit_text(font: Font, text: String, max_width: float, size: float) -> String:
	if text.is_empty() or max_width <= 0.0:
		return text
	if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x <= max_width:
		return text
	var ellipsis := "..."
	var fitted := ""
	for i in range(text.length()):
		var candidate := fitted + text.substr(i, 1) + ellipsis
		if font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x > max_width:
			return fitted + ellipsis if not fitted.is_empty() else ellipsis
		fitted += text.substr(i, 1)
	return fitted

static func wrap_text(font: Font, text: String, max_width: float, size: float) -> Array[String]:
	if text.is_empty():
		return []
	var lines: Array[String] = []
	for raw_line in text.split("\n"):
		var line := ""
		for i in range(raw_line.length()):
			var ch: String = raw_line.substr(i, 1)
			var candidate := line + ch
			if not line.is_empty() and font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x > max_width:
				lines.append(line)
				line = ch
			else:
				line = candidate
		if not line.is_empty():
			lines.append(line)
	return lines

static func draw_text_with_shadow(canvas: CanvasItem, text: String, x: float, y: float, color: Color, size: float, max_width: float = 200.0, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> void:
	var font := ThemeDB.fallback_font
	var safe_text := fit_text(font, text, max_width, size)
	var shadow_color := Color(0.0, 0.0, 0.0, 0.55)
	var left := x - max_width / 2.0 if alignment == HORIZONTAL_ALIGNMENT_CENTER else x
	canvas.draw_string(font, Vector2(left + 1.0, y + 2.0), safe_text, alignment, max_width, size, shadow_color)
	canvas.draw_string(font, Vector2(left, y), safe_text, alignment, max_width, size, color)
