extends SceneTree


func _init() -> void:
	var font := load("res://assets/fonts/noto-cjk/NotoSansCJK-Regular.ttc") as FontFile
	if font == null:
		push_error("Noto CJK font failed to load")
		quit(1)
		return
	print("font=%s caches=%d" % [font.get_font_name(), font.get_cache_count()])
	for cache_index in range(font.get_cache_count()):
		print("cache=%d face=%d" % [cache_index, font.get_face_index(cache_index)])
	for face_index in range(5):
		var face_font := font.duplicate(true) as FontFile
		face_font.set_face_index(0, face_index)
		print("face=%d name=%s korean=%s" % [face_index, face_font.get_font_name(), str(face_font.has_char("한".unicode_at(0)))])
	for sample in ["龙", "龍", "日", "한", "é", "ñ", "ß"]:
		print("char=%s supported=%s" % [sample, str(font.has_char(sample.unicode_at(0)))])
	quit(0)
