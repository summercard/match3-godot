extends SceneTree

const OUT_RUNTIME := "res://assets/images/battle"
const OUT_FORMAL := "res://美术开发/正式拆分/battle_screen"

func _init() -> void:
	_generate()
	quit(0)

func _generate() -> void:
	_ensure_dir("%s/ui" % OUT_RUNTIME)
	_ensure_dir("%s/fx" % OUT_RUNTIME)
	_ensure_dir("%s/ui" % OUT_FORMAL)
	_ensure_dir("%s/fx" % OUT_FORMAL)

	_save_pair(_panel(128, 32, Color(0.05, 0.12, 0.24, 0.88), Color(0.36, 0.66, 0.96, 0.72), Color(0.9, 0.98, 1.0, 0.20), 8), "ui/ui_battle_toast_panel.png")
	_save_pair(_panel(196, 74, Color(0.08, 0.12, 0.22, 0.86), Color(0.98, 0.74, 0.18, 0.88), Color(1.0, 0.92, 0.40, 0.30), 12), "ui/ui_combo_banner.png")
	_save_pair(_top_scrim(375, 62), "ui/ui_top_scrim.png")
	_save_pair(_turn_badge(82, 54), "ui/ui_turn_badge.png")
	_save_pair(_header_button(46, 54, "speed"), "ui/ui_speed_button.png")
	_save_pair(_header_button(46, 54, "settings"), "ui/ui_settings_button.png")
	_save_pair(_board_frame(336, 336), "ui/ui_board_frame.png")
	_save_pair(_board_cell(40, 40), "ui/ui_board_cell.png")
	_save_pair(_footer_panel(355, 45), "ui/ui_footer_panel.png")
	_save_pair(_toggle_button(76, 19, false), "ui/ui_capture_toggle_off.png")
	_save_pair(_toggle_button(76, 19, true), "ui/ui_capture_toggle_on.png")
	_save_pair(_item_slot(32, false), "ui/ui_item_slot.png")
	_save_pair(_item_slot(32, true), "ui/ui_item_slot_selected.png")
	_save_pair(_item_icon(32, "capture_ball"), "ui/icon_capture_ball.png")
	_save_pair(_item_icon(32, "capture_ball_plus"), "ui/icon_capture_ball_plus.png")
	_save_pair(_item_icon(32, "hp_potion"), "ui/icon_hp_potion.png")
	_save_pair(_intent_chip(128, 28, Color(0.06, 0.13, 0.26, 0.92), Color(0.34, 0.58, 0.90, 0.84)), "ui/ui_intent_normal.png")
	_save_pair(_intent_chip(128, 28, Color(0.24, 0.06, 0.08, 0.94), Color(1.0, 0.35, 0.24, 0.90)), "ui/ui_intent_danger.png")
	_save_pair(_intent_chip(128, 28, Color(0.22, 0.14, 0.04, 0.94), Color(1.0, 0.76, 0.20, 0.90)), "ui/ui_intent_warning.png")
	_save_pair(_intent_chip(128, 28, Color(0.03, 0.16, 0.28, 0.94), Color(0.30, 0.78, 1.0, 0.88)), "ui/ui_intent_shield.png")
	_save_pair(_intent_chip(128, 28, Color(0.03, 0.18, 0.12, 0.94), Color(0.30, 1.0, 0.48, 0.88)), "ui/ui_intent_heal.png")
	_save_pair(_hp_frame(128, 18), "ui/ui_hp_frame.png")
	_save_pair(_hp_fill(128, 18, Color(0.18, 0.88, 0.28), Color(0.78, 1.0, 0.64)), "ui/ui_hp_fill_green.png")
	_save_pair(_hp_fill(128, 18, Color(1.0, 0.16, 0.16), Color(1.0, 0.54, 0.32)), "ui/ui_hp_fill_red.png")
	_save_pair(_hp_fill(128, 18, Color(0.18, 0.45, 1.0), Color(0.64, 0.92, 1.0)), "ui/ui_hp_fill_blue.png")
	_save_pair(_hp_fill(128, 18, Color(1.0, 0.72, 0.08), Color(1.0, 0.95, 0.36)), "ui/ui_hp_fill_gold.png")
	_save_pair(_damage_plate(116, 48, Color(0.1, 0.08, 0.05, 0.76), Color(1.0, 0.52, 0.12, 0.90)), "fx/fx_damage_plate.png")
	_save_pair(_damage_plate(116, 48, Color(0.08, 0.05, 0.10, 0.78), Color(0.95, 0.18, 0.15, 0.95)), "fx/fx_critical_plate.png")
	_save_pair(_damage_plate(108, 40, Color(0.04, 0.12, 0.08, 0.74), Color(0.34, 1.0, 0.45, 0.86)), "fx/fx_heal_plate.png")
	_save_pair(_radial_burst(128, 128, Color(1.0, 0.64, 0.16, 0.92), Color(1.0, 1.0, 0.78, 0.90), 18, 12), "fx/fx_hit_spark.png")
	_save_pair(_radial_burst(128, 128, Color(0.30, 0.75, 1.0, 0.68), Color(0.88, 1.0, 1.0, 0.72), 12, 10), "fx/fx_shield_ring.png")
	_save_pair(_radial_burst(128, 128, Color(0.28, 1.0, 0.48, 0.62), Color(0.86, 1.0, 0.72, 0.68), 10, 8), "fx/fx_heal_ring.png")
	_save_pair(_radial_burst(128, 128, Color(1.0, 0.82, 0.16, 0.72), Color(1.0, 0.96, 0.46, 0.72), 16, 14), "fx/fx_charge_aura.png")
	_save_pair(_stage_ring(192, 78, Color(0.18, 0.80, 1.0, 0.48)), "fx/fx_stage_ring_cyan.png")
	_save_pair(_stage_ring(192, 78, Color(0.40, 1.0, 0.38, 0.48)), "fx/fx_stage_ring_green.png")
	_save_pair(_stage_ring(192, 78, Color(1.0, 0.34, 0.18, 0.48)), "fx/fx_stage_ring_fire.png")
	_save_pair(_stage_ring(192, 78, Color(0.68, 0.50, 1.0, 0.48)), "fx/fx_stage_ring_void.png")
	_save_pair(_selection_glow(72, 72), "fx/fx_selected_cell.png")
	_save_pair(_radial_burst(96, 96, Color(1.0, 0.86, 0.24, 0.72), Color(1.0, 1.0, 0.82, 0.78), 10, 10), "fx/fx_gem_pop.png")

func _ensure_dir(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))

func _save_pair(img: Image, rel_path: String) -> void:
	var runtime_path := "%s/%s" % [OUT_RUNTIME, rel_path]
	var formal_path := "%s/%s" % [OUT_FORMAL, rel_path]
	img.save_png(runtime_path)
	img.save_png(formal_path)
	print("[BattleFeedbackAssets] %s" % runtime_path)

func _new_image(w: int, h: int) -> Image:
	return Image.create(w, h, false, Image.FORMAT_RGBA8)

func _panel(w: int, h: int, bg: Color, border: Color, glow: Color, radius: int) -> Image:
	var img := _new_image(w, h)
	var center := Vector2(w / 2.0, h / 2.0)
	var max_dist := center.length()
	for y in range(h):
		for x in range(w):
			var a := _rounded_alpha(Vector2(x, y), Vector2(w, h), radius)
			if a <= 0.0:
				continue
			var d := Vector2(x, y).distance_to(center) / max_dist
			var c := bg.lerp(glow, clampf(1.0 - d * 1.7, 0.0, 1.0) * 0.35)
			c.a *= a
			if x < 3 or x >= w - 3 or y < 3 or y >= h - 3:
				c = border
				c.a *= a
			elif y < h * 0.35:
				c = c.lerp(Color(1, 1, 1, c.a), 0.12)
			img.set_pixel(x, y, c)
	return img

func _hp_frame(w: int, h: int) -> Image:
	var img := _new_image(w, h)
	var bg := Color(0.03, 0.05, 0.10, 0.84)
	for y in range(h):
		for x in range(w):
			var a := _rounded_alpha(Vector2(x, y), Vector2(w, h), 5)
			if a <= 0.0:
				continue
			var c := bg
			if x < 3 or x >= w - 3 or y < 3 or y >= h - 3:
				c = Color(0.78, 0.92, 1.0, 0.72)
			elif y < 7:
				c = Color(0.22, 0.35, 0.56, 0.42)
			img.set_pixel(x, y, Color(c.r, c.g, c.b, c.a * a))
	return img

func _top_scrim(w: int, h: int) -> Image:
	var img := _new_image(w, h)
	for y in range(h):
		var a := lerpf(0.72, 0.0, float(y) / float(h - 1))
		for x in range(w):
			img.set_pixel(x, y, Color(0.02, 0.05, 0.14, a))
	return img

func _turn_badge(w: int, h: int) -> Image:
	var img := _panel(w, h, Color(0.04, 0.10, 0.23, 0.94), Color(0.28, 0.49, 0.82, 0.94), Color(0.21, 0.42, 0.70, 0.28), 5)
	for x in range(10, w - 10):
		_blend_pixel(img, x, h - 7, Color(0.99, 0.74, 0.18, 0.50))
		if x % 2 == 0:
			_blend_pixel(img, x, h - 6, Color(0.99, 0.74, 0.18, 0.26))
	return img

func _header_button(w: int, h: int, kind: String) -> Image:
	var img := _panel(w, h, Color(0.05, 0.13, 0.28, 0.96), Color(0.34, 0.54, 0.82, 0.92), Color(0.32, 0.63, 1.0, 0.24), 5)
	if kind == "speed":
		for y in range(10, 26):
			var span := mini(y - 10, 25 - y)
			for x in range(11, 11 + span + 2):
				_blend_pixel(img, x, y, Color(0.86, 0.94, 1.0, 0.95))
				_blend_pixel(img, x + 11, y, Color(0.86, 0.94, 1.0, 0.95))
	else:
		var center := Vector2(w / 2.0, 19.0)
		for y in range(7, 31):
			for x in range(11, 35):
				var dist := Vector2(x, y).distance_to(center)
				if (dist >= 7.0 and dist <= 10.0) or (dist <= 4.0):
					_blend_pixel(img, x, y, Color(0.88, 0.94, 1.0, 0.92))
		for p in [Vector2i(22, 6), Vector2i(22, 31), Vector2i(10, 18), Vector2i(35, 18)]:
			img.fill_rect(Rect2i(p.x, p.y, 3, 3), Color(0.88, 0.94, 1.0, 0.92))
	return img

func _board_frame(w: int, h: int) -> Image:
	var img := _new_image(w, h)
	var center := Vector2(w / 2.0, h / 2.0)
	for y in range(h):
		for x in range(w):
			var a := _rounded_alpha(Vector2(x, y), Vector2(w, h), 8)
			if a <= 0.0:
				continue
			var edge := minf(minf(x, w - 1 - x), minf(y, h - 1 - y))
			var d := Vector2(x, y).distance_to(center) / center.length()
			var c := Color(0.018, 0.055, 0.13, 0.98).lerp(Color(0.03, 0.11, 0.22, 0.98), clampf(1.0 - d, 0.0, 1.0) * 0.35)
			if edge < 3.0:
				c = Color(0.20, 0.38, 0.65, 0.96)
			elif edge < 6.0:
				c = Color(0.06, 0.19, 0.37, 0.98)
			elif edge < 8.0:
				c = Color(0.34, 0.58, 0.88, 0.40)
			c.a *= a
			img.set_pixel(x, y, c)
	for corner in [Vector2i(9, 9), Vector2i(w - 10, 9), Vector2i(9, h - 10), Vector2i(w - 10, h - 10)]:
		for y in range(corner.y - 2, corner.y + 3):
			for x in range(corner.x - 2, corner.x + 3):
				if Vector2(x, y).distance_to(Vector2(corner)) <= 2.4:
					_blend_pixel(img, x, y, Color(0.69, 0.88, 1.0, 0.60))
	return img

func _board_cell(w: int, h: int) -> Image:
	var img := _new_image(w, h)
	for y in range(h):
		for x in range(w):
			var a := _rounded_alpha(Vector2(x, y), Vector2(w, h), 3)
			if a <= 0.0:
				continue
			var edge := minf(minf(x, w - 1 - x), minf(y, h - 1 - y))
			var c := Color(0.018, 0.055, 0.13, 0.90)
			if edge < 1.5:
				c = Color(0.10, 0.25, 0.47, 0.90)
			elif y < 5:
				c = Color(0.05, 0.14, 0.28, 0.94)
			img.set_pixel(x, y, Color(c.r, c.g, c.b, c.a * a))
	return img

func _footer_panel(w: int, h: int) -> Image:
	var img := _panel(w, h, Color(0.035, 0.08, 0.18, 0.97), Color(0.24, 0.44, 0.73, 0.92), Color(0.18, 0.34, 0.62, 0.28), 5)
	for split_x in [98, 207]:
		for y in range(7, h - 6):
			_blend_pixel(img, split_x, y, Color(0.24, 0.44, 0.70, 0.48))
			_blend_pixel(img, split_x + 1, y, Color(0.04, 0.08, 0.16, 0.60))
	return img

func _toggle_button(w: int, h: int, active: bool) -> Image:
	var bg := Color(0.04, 0.17, 0.22, 0.98) if active else Color(0.07, 0.12, 0.23, 0.98)
	var border := Color(0.26, 0.86, 0.51, 0.92) if active else Color(0.28, 0.42, 0.62, 0.90)
	var glow := Color(0.32, 1.0, 0.52, 0.30) if active else Color(0.26, 0.50, 0.82, 0.18)
	var img := _panel(w, h, bg, border, glow, 4)
	var lamp := Color(0.34, 1.0, 0.54, 1.0) if active else Color(0.36, 0.48, 0.66, 0.88)
	for y in range(6, 13):
		for x in range(8, 15):
			if Vector2(x, y).distance_to(Vector2(11, 9)) <= 3.2:
				_blend_pixel(img, x, y, lamp)
	return img

func _item_slot(size: int, selected: bool) -> Image:
	var border := Color(0.98, 0.75, 0.20, 0.96) if selected else Color(0.28, 0.47, 0.73, 0.84)
	var glow := Color(1.0, 0.80, 0.28, 0.32) if selected else Color(0.26, 0.50, 0.86, 0.18)
	return _panel(size, size, Color(0.03, 0.08, 0.17, 0.94), border, glow, 5)

func _item_icon(size: int, kind: String) -> Image:
	var img := _new_image(size, size)
	var center := Vector2(size / 2.0, size / 2.0)
	if kind == "hp_potion":
		for y in range(7, 27):
			for x in range(10, 22):
				var body := (y >= 13 and y <= 25 and x >= 9 and x <= 23) or (y >= 8 and y <= 13 and x >= 13 and x <= 19)
				if body:
					var c := Color(0.28, 0.88, 0.58, 1.0) if y > 16 else Color(0.82, 1.0, 0.94, 0.92)
					_blend_pixel(img, x, y, c)
		return img
	var core := Color(0.96, 0.25, 0.18, 1.0) if kind == "capture_ball" else Color(0.96, 0.61, 0.16, 1.0)
	for y in range(size):
		for x in range(size):
			var dist := Vector2(x, y).distance_to(center)
			if dist <= 12.0:
				var c := core if y < center.y else Color(0.88, 0.93, 0.98, 1.0)
				if absf(float(y) - center.y) < 1.5:
					c = Color(0.05, 0.08, 0.15, 1.0)
				if dist > 10.5:
					c = Color(0.86, 0.94, 1.0, 0.82)
				_blend_pixel(img, x, y, c)
	for y in range(13, 19):
		for x in range(13, 19):
			if Vector2(x, y).distance_to(center) <= 3.2:
				_blend_pixel(img, x, y, Color(1.0, 1.0, 1.0, 1.0))
	return img

func _intent_chip(w: int, h: int, bg: Color, edge: Color) -> Image:
	var img := _panel(w, h, bg, edge, edge * Color(1.0, 1.0, 1.0, 0.32), 5)
	for x in range(8, 17):
		var span := 4 - absi(x - 12)
		for y in range(int(h / 2) - span, int(h / 2) + span + 1):
			_blend_pixel(img, x, y, edge)
	return img

func _hp_fill(w: int, h: int, c1: Color, c2: Color) -> Image:
	var img := _new_image(w, h)
	for y in range(h):
		for x in range(w):
			var a := _rounded_alpha(Vector2(x, y), Vector2(w, h), 5)
			if a <= 0.0:
				continue
			var t := float(y) / maxf(1.0, h - 1.0)
			var c := c2.lerp(c1, t)
			if y < h * 0.28:
				c = c.lerp(Color(1, 1, 1, 1), 0.32)
			img.set_pixel(x, y, Color(c.r, c.g, c.b, c.a * a))
	return img

func _damage_plate(w: int, h: int, bg: Color, edge: Color) -> Image:
	var img := _new_image(w, h)
	var center := Vector2(w / 2.0, h / 2.0)
	for y in range(h):
		for x in range(w):
			var p := Vector2(x, y)
			var nx: float = abs((float(x) - center.x) / (float(w) / 2.0))
			var ny: float = abs((float(y) - center.y) / (float(h) / 2.0))
			var shape := clampf(1.0 - pow(maxf(nx, ny * 1.35), 2.1), 0.0, 1.0)
			if shape <= 0.0:
				continue
			var ring := clampf(1.0 - abs(shape - 0.35) * 4.2, 0.0, 1.0)
			var c := bg.lerp(edge, ring * 0.65)
			c.a *= shape
			if p.distance_to(center) < minf(w, h) * 0.18:
				c = c.lerp(Color(1, 1, 1, c.a), 0.18)
			img.set_pixel(x, y, c)
	return img

func _radial_burst(w: int, h: int, outer: Color, inner: Color, rays: int, ring_width: int) -> Image:
	var img := _new_image(w, h)
	var center := Vector2(w / 2.0, h / 2.0)
	var max_r := minf(w, h) * 0.48
	for y in range(h):
		for x in range(w):
			var p := Vector2(x + 0.5, y + 0.5)
			var v := p - center
			var r := v.length()
			if r > max_r:
				continue
			var angle := atan2(v.y, v.x)
			var ray := pow(maxf(0.0, cos(angle * rays)), 5.0)
			var ring := clampf(1.0 - abs(r - max_r * 0.55) / maxf(1.0, ring_width), 0.0, 1.0)
			var core := clampf(1.0 - r / (max_r * 0.42), 0.0, 1.0)
			var alpha := maxf(maxf(core * 0.9, ring * 0.58), ray * (1.0 - r / max_r) * 0.75)
			if alpha <= 0.01:
				continue
			var c := outer.lerp(inner, core)
			c.a *= alpha
			img.set_pixel(x, y, c)
	return img

func _stage_ring(w: int, h: int, color: Color) -> Image:
	var img := _new_image(w, h)
	var center := Vector2(w / 2.0, h * 0.70)
	var rx := w * 0.44
	var ry := h * 0.28
	for y in range(h):
		for x in range(w):
			var nx := (x - center.x) / rx
			var ny := (y - center.y) / ry
			var d := nx * nx + ny * ny
			var ring := clampf(1.0 - abs(d - 1.0) * 8.0, 0.0, 1.0)
			var fill := clampf(1.0 - d, 0.0, 1.0) * 0.22
			var a := maxf(ring * 0.72, fill)
			if a <= 0.01:
				continue
			var c := color
			c.a *= a
			if y > center.y:
				c.a *= 0.45
			img.set_pixel(x, y, c)
	return img

func _selection_glow(w: int, h: int) -> Image:
	var img := _new_image(w, h)
	var center := Vector2(w / 2.0, h / 2.0)
	for y in range(h):
		for x in range(w):
			var p := Vector2(x, y)
			var edge := minf(minf(x, w - 1 - x), minf(y, h - 1 - y))
			var border := clampf(1.0 - abs(edge - 7.0) / 7.0, 0.0, 1.0)
			var radial := clampf(1.0 - p.distance_to(center) / (w * 0.52), 0.0, 1.0)
			var a := maxf(border * 0.82, radial * 0.20)
			if a <= 0.01:
				continue
			img.set_pixel(x, y, Color(1.0, 0.86, 0.22, a))
	return img

func _rounded_alpha(p: Vector2, size: Vector2, radius: int) -> float:
	var q := Vector2(
		maxf(abs(p.x - size.x / 2.0) - size.x / 2.0 + radius, 0.0),
		maxf(abs(p.y - size.y / 2.0) - size.y / 2.0 + radius, 0.0)
	)
	var dist := q.length()
	return clampf(float(radius) - dist + 1.0, 0.0, 1.0)

func _blend_pixel(img: Image, x: int, y: int, color: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	var base := img.get_pixel(x, y)
	img.set_pixel(x, y, base.lerp(color, color.a))
