class_name BattleBoardRenderer
extends RefCounted

static func draw_board_background(scene, design_w: float, board = null) -> void:
	var cell_size: float = 39.0
	var board_x: float = (design_w - cell_size * 8.0) / 2.0
	var board_y: float = 296.0
	if board != null:
		cell_size = float(board.cell_size)
		board_x = float(board.offset_x)
		board_y = float(board.offset_y)
	var board_w: float = cell_size * 8.0
	var board_h: float = cell_size * 8.0
	var frame_tex: Texture2D = scene._get_texture("res://assets/images/ui/misc/battle_ui_board_frame.png")
	if frame_tex:
		scene._draw_texture_fit(frame_tex, Rect2(board_x - 12.0, board_y - 12.0, board_w + 24.0, board_h + 24.0), 1.0)
	else:
		scene._draw_rounded_rect(board_x - 7.0, board_y - 7.0, board_w + 14.0, board_h + 14.0, 7.0, Color(0.03, 0.10, 0.22, 0.94))
		scene._draw_stroke_rect(board_x - 5.0, board_y - 5.0, board_w + 10.0, board_h + 10.0, 1.5, Color(0.34, 0.55, 0.86, 0.58))

static func draw_board(scene, board, state: Dictionary) -> void:
	var design_w: float = state.get("design_w", 375.0)
	var board_shake_offset: Vector2 = state.get("board_shake_offset", Vector2.ZERO)
	var cell_size: float = 42.0
	var board_x: float = (design_w - 336.0) / 2.0 + board_shake_offset.x
	var board_y: float = 280.0 + board_shake_offset.y
	if board != null:
		cell_size = float(board.cell_size)
		board_x = float(board.offset_x) + board_shake_offset.x
		board_y = float(board.offset_y) + board_shake_offset.y
	var cell_tex: Texture2D = scene._get_texture("res://assets/images/ui/misc/battle_ui_board_cell.png")

	for row in range(8):
		for col in range(8):
			var x: float = board_x + col * cell_size
			var y: float = board_y + row * cell_size
			if cell_tex:
				scene._draw_texture_fit(cell_tex, Rect2(x + 0.5, y + 0.5, cell_size - 1.0, cell_size - 1.0), 1.0)
			else:
				scene._draw_rounded_rect(x + 1.0, y + 1.0, cell_size - 2.0, cell_size - 2.0, 3.0, Color(0.02, 0.07, 0.16, 0.78))
				scene._draw_stroke_rect(x + 1.0, y + 1.0, cell_size - 2.0, cell_size - 2.0, 1.0, Color(0.10, 0.23, 0.42, 0.82))
			if board == null:
				continue
			if board.has_method("is_ice_tile") and board.is_ice_tile(row, col):
				_draw_ice_tile(scene, x, y, cell_size, state, row, col)
			if board.is_obstacle(row, col) or board.is_fountain(row, col):
				continue
			var gem_type: String = board.grid[row][col]
			if gem_type.is_empty():
				continue
			_draw_gem_cell(scene, board, state, row, col, x, y, cell_size, gem_type)

	draw_locked_gems(scene, board, state)
	draw_vines(scene, board, state)
	draw_obstacles(scene, board, state)
	draw_fountains(scene, board, state)
	draw_poison_fog(scene, board, state)
	draw_soaked_gems(scene, board, state)
	draw_tide(scene, board, state)
	draw_unlock_animations(scene, board, state)
	draw_poison_fog_anims(scene, state)
	draw_fountain_anims(scene, state)
	draw_vine_anims(scene, state)
	draw_tide_anims(scene, state)

static func _draw_gem_cell(scene, board, state: Dictionary, row: int, col: int, x: float, y: float, cell_size: float, gem_type: String) -> void:
	var colors: Dictionary = state.get("colors", {})
	var gem_colors: Dictionary = state.get("gem_colors", {})
	var eliminating_gems: Array = state.get("eliminating_gems", [])
	var falling_gems: Array = state.get("falling_gems", [])
	var ice_slide_anims: Array = state.get("ice_slide_anims", [])
	var selected_gem: Vector2i = state.get("selected_gem", Vector2i(-1, -1))
	var idle_time: float = state.get("idle_time", 0.0)
	var is_eliminating: bool = false
	var elim_progress: float = 0.0
	for eg in eliminating_gems:
		if eg["row"] == row and eg["col"] == col:
			is_eliminating = true
			elim_progress = eg["timer"] / eg["duration"]
			break

	var gem_color: Color = gem_colors.get(gem_type, colors.get("white", Color.WHITE))
	var cx: float = x + cell_size / 2.0
	var cy: float = y + cell_size / 2.0
	if is_eliminating:
		var scale: float = _eliminate_scale(elim_progress)
		scene._draw_gem_animated(cx, cy, gem_type, gem_color, scale, 1.0, 0.0)
		return

	var slide := _ice_slide_entry_for(ice_slide_anims, row, col, gem_type)
	if not slide.is_empty():
		var slide_t: float = clampf(float(slide.get("timer", 0.0)) / maxf(0.01, float(slide.get("duration", 0.22))), 0.0, 1.0)
		var eased_slide := _ease_out_cubic(slide_t)
		var slide_x := lerpf(float(slide.get("from_x", cx)), float(slide.get("to_x", cx)), eased_slide)
		var slide_y := lerpf(float(slide.get("from_y", cy)), float(slide.get("to_y", cy)), eased_slide)
		var slip_wobble := sin(slide_t * PI) * 0.08
		scene._draw_gem_animated(slide_x, slide_y, gem_type, gem_color, 1.0 + slip_wobble, 1.0)
		return

	var fall := _falling_entry_for(falling_gems, row, col, gem_type)
	if not fall.is_empty():
		var fall_t: float = clampf((float(fall.get("timer", 0.0)) - float(fall.get("delay", 0.0))) / maxf(0.01, float(fall.get("duration", 0.34))), 0.0, 1.0)
		var eased := _ease_out_cubic(fall_t)
		var from_y := float(fall.get("from_y", cy))
		var to_y := float(fall.get("to_y", cy))
		var bounce := 0.0
		if fall_t > 0.72:
			var bp := (fall_t - 0.72) / 0.28
			bounce = -sin(bp * PI) * 5.0 * (1.0 - bp)
		var fall_y := lerpf(from_y, to_y, eased) + bounce
		var fall_scale := 1.0 + sin(fall_t * PI) * 0.055
		var fall_alpha := clampf(fall_t / 0.18, 0.0, 1.0) if bool(fall.get("is_new", false)) else 1.0
		scene._draw_gem_animated(cx, fall_y, gem_type, gem_color, fall_scale, fall_alpha)
		return

	var is_selected: bool = selected_gem.x == col and selected_gem.y == row
	var pulse_opacity: float = 1.0
	if is_selected:
		var t_sel: float = fmod(idle_time, 1.0)
		pulse_opacity = 0.95 + 0.05 * (sin(t_sel * TAU) + 1.0) / 2.0
	else:
		var t_unsel: float = fmod(idle_time, 2.0) / 2.0
		var sine_unsel: float = sin(t_unsel * TAU + row * 0.5 + col * 0.3)
		pulse_opacity = 0.85 + 0.15 * (sine_unsel + 1.0) / 2.0
	var idle_scale: float = 1.0 + 0.02 * sin(idle_time * TAU / 2.0 + row * 0.5 + col * 0.3)
	scene._draw_gem_animated(cx, cy, gem_type, gem_color, idle_scale, pulse_opacity)

static func _draw_ice_tile(scene, x: float, y: float, size: float, state: Dictionary, row: int, col: int) -> void:
	var idle_time: float = state.get("idle_time", 0.0)
	var ice_tex: Texture2D = scene._get_texture("res://assets/images/ui/gems/battle_tile_ice.png")
	var pulse := 0.5 + 0.5 * sin(idle_time * TAU * 0.75 + float(row * 2 + col) * 0.28)
	if ice_tex:
		scene._draw_texture_fit(ice_tex, Rect2(x + 2.0, y + 2.0, size - 4.0, size - 4.0), 0.82 + pulse * 0.10)
		return
	scene._draw_rounded_rect(x + 3.0, y + 3.0, size - 6.0, size - 6.0, 8.0, Color(0.58, 0.88, 1.0, 0.34 + pulse * 0.08))
	scene.draw_line(Vector2(x + 8.0, y + size * 0.62), Vector2(x + size - 8.0, y + size * 0.34), Color(0.93, 1.0, 1.0, 0.42), 1.5)
	scene.draw_line(Vector2(x + size * 0.32, y + 9.0), Vector2(x + size * 0.60, y + size - 8.0), Color(0.72, 0.95, 1.0, 0.34), 1.2)

static func draw_locked_gems(scene, board, state: Dictionary) -> void:
	if board == null:
		return
	var lock_colors: Dictionary = state.get("lock_colors", {})
	var unlock_animations: Array = state.get("unlock_animations", [])
	var falling_gems: Array = state.get("falling_gems", [])
	for row in range(board.rows):
		for col in range(board.cols):
			if not board.is_locked(row, col):
				continue
			var is_shattering: bool = false
			for anim in unlock_animations:
				if anim.get("row") == row and anim.get("col") == col and anim.get("phase") == "shatter":
					is_shattering = true
					break
			if is_shattering:
				continue
			var lock: Dictionary = board.locked_gems[row][col]
			var x: float = float(board.offset_x + col * board.cell_size)
			var y: float = float(board.offset_y + row * board.cell_size)
			var size: float = float(board.cell_size)
			var cy: float = y + size / 2.0
			var gem_type: String = str(board.grid[row][col])
			var fall := _falling_entry_for(falling_gems, row, col, gem_type)
			if not fall.is_empty():
				var animated_y := _fall_center_y(fall, cy)
				y += animated_y - cy
				cy = animated_y
			# Corner chains and a compact lock leave the gem center visible.
			var chain_color: Color = lock_colors.get("chain", Color(0.6, 0.6, 0.7, 0.9)) if lock.get("hp", 1) >= 2 else lock_colors.get("chain_weak", Color(0.5, 0.5, 0.55, 0.7))
			var metal := Color(0.96, 0.83, 0.46, 0.94)
			var inset := maxf(3.0, size * 0.08)
			var arm := maxf(7.0, size * 0.20)
			var left := x + inset
			var right := x + size - inset
			var top := y + inset
			var bottom := y + size - inset
			var width := 2.4 if int(lock.get("hp", 1)) >= 2 else 1.9
			for corner_data in [
				[Vector2(left, top), Vector2(left + arm, top), Vector2(left, top + arm)],
				[Vector2(right, top), Vector2(right - arm, top), Vector2(right, top + arm)],
				[Vector2(left, bottom), Vector2(left + arm, bottom), Vector2(left, bottom - arm)],
				[Vector2(right, bottom), Vector2(right - arm, bottom), Vector2(right, bottom - arm)]
			]:
				var corner: Vector2 = corner_data[0]
				scene.draw_line(corner, corner_data[1], chain_color, width)
				scene.draw_line(corner, corner_data[2], chain_color, width)
				scene.draw_circle(corner, width + 0.8, metal)
				scene.draw_circle(corner, maxf(1.0, width - 0.3), Color(0.22, 0.23, 0.28, 0.9))
			var lock_cx := right - 3.0
			var lock_cy := top + 5.0
			scene.draw_arc(Vector2(lock_cx, lock_cy - 2.0), 4.0, PI, TAU, 10, metal, 1.8)
			scene._draw_rounded_rect(lock_cx - 5.0, lock_cy - 1.5, 10.0, 8.0, 2.0, Color(0.24, 0.25, 0.31, 0.94))
			scene.draw_circle(Vector2(lock_cx, lock_cy + 2.0), 1.2, metal)
			if int(lock.get("hp", 1)) >= 2:
				scene._draw_text_with_shadow("2", right - 3.0, bottom - 1.0, Color.WHITE, 7.0)

static func draw_vines(scene, board, state: Dictionary) -> void:
	if board == null:
		return
	var idle_time: float = state.get("idle_time", 0.0)
	var backlash_anims: Array = state.get("vine_backlash_anims", [])
	var thorn_tex: Texture2D = scene._get_texture("res://assets/images/ui/gems/battle_gem_thorn_vine.png")
	for row in range(board.rows):
		for col in range(board.cols):
			if not board.is_vined(row, col):
				continue
			var x: float = float(board.offset_x + col * board.cell_size)
			var y: float = float(board.offset_y + row * board.cell_size)
			var size: float = float(board.cell_size)
			var sway := sin(idle_time * TAU * 0.7 + float(row + col) * 0.6) * 1.6
			var backlash := _vine_backlash_entry_for(backlash_anims, row, col)
			var jump_y := 0.0
			var red_flash := 0.0
			if not backlash.is_empty():
				var progress := clampf(float(backlash.get("timer", 0.0)) / 0.58, 0.0, 1.0)
				jump_y = -sin(progress * PI) * 6.0
				red_flash = 1.0 - progress
			if thorn_tex:
				var pulse := 1.0 + 0.035 * sin(idle_time * TAU * 0.8 + float(row + col) * 0.4)
				if not backlash.is_empty():
					var progress := clampf(float(backlash.get("timer", 0.0)) / 0.58, 0.0, 1.0)
					pulse += sin(progress * PI) * 0.16
				var draw_size := size * 1.08 * pulse
				var rect := Rect2(
					x + size / 2.0 - draw_size / 2.0 + sway * 0.18,
					y + size / 2.0 - draw_size / 2.0 + jump_y,
					draw_size,
					draw_size
				)
				scene._draw_texture_fit(thorn_tex, rect, 0.96)
				if red_flash > 0.0:
					scene.draw_texture_rect(thorn_tex, rect, false, Color(1.0, 0.04, 0.02, 0.82 * red_flash))
				continue
			var vine_color := Color(0.13, 0.54, 0.20, 0.88)
			if red_flash > 0.0:
				vine_color = vine_color.lerp(Color(1.0, 0.10, 0.05, 0.95), red_flash)
			var leaf_color := Color(0.32, 0.82, 0.30, 0.82)
			var p1 := Vector2(x + 6.0, y + size - 8.0 + jump_y)
			var p2 := Vector2(x + size * 0.30 + sway, y + size * 0.56 + jump_y)
			var p3 := Vector2(x + size * 0.68 - sway, y + size * 0.34 + jump_y)
			var p4 := Vector2(x + size - 6.0, y + 7.0 + jump_y)
			scene.draw_line(p1, p2, vine_color, 2.5)
			scene.draw_line(p2, p3, vine_color, 2.5)
			scene.draw_line(p3, p4, vine_color, 2.5)
			scene.draw_line(Vector2(x + size - 7.0, y + size - 7.0), Vector2(x + 7.0, y + 7.0), Color(0.09, 0.42, 0.15, 0.74), 1.8)
			for leaf in [p2, p3, Vector2(x + size * 0.42, y + size * 0.24)]:
				scene.draw_circle(leaf + Vector2(2.0, -1.0), 3.0, leaf_color)
				scene.draw_circle(leaf + Vector2(-2.0, 1.0), 2.4, Color(0.20, 0.70, 0.24, 0.72))

static func draw_obstacles(scene, board, state: Dictionary) -> void:
	if board == null:
		return
	var obstacle_colors: Dictionary = state.get("obstacle_colors", {})
	for row in range(board.rows):
		for col in range(board.cols):
			if not board.is_obstacle(row, col):
				continue
			var ob: Dictionary = board.obstacles[row][col]
			var x: float = float(board.offset_x + col * board.cell_size)
			var y: float = float(board.offset_y + row * board.cell_size)
			var size: float = float(board.cell_size)
			var cx: float = x + size / 2.0
			var cy: float = y + size / 2.0
			var rock_path := "res://assets/images/ui/gems/obstacles_obstacle_rock_full.png" if ob.get("hp", 2) >= 2 else "res://assets/images/ui/gems/obstacles_obstacle_rock_cracked.png"
			var rock_tex: Texture2D = scene._get_texture(rock_path)
			if rock_tex:
				scene._draw_texture_fit(rock_tex, Rect2(x + 2.0, y + 2.0, size - 4.0, size - 4.0), 0.98)
				continue
			if ob.get("hp", 2) >= 2:
				scene._draw_rounded_rect(x + 2.0, y + 2.0, size - 4.0, size - 4.0, 4.0, obstacle_colors.get("rock", Color(0.35, 0.3, 0.25, 1.0)))
				scene._draw_rounded_rect(x + 4.0, y + 4.0, size - 8.0, size - 8.0, 3.0, obstacle_colors.get("rock_solid", Color(0.42, 0.38, 0.32, 1.0)))
				scene._draw_rounded_rect(x + 6.0, y + 6.0, size - 16.0, (size - 8.0) / 3.0, 2.0, obstacle_colors.get("highlight", Color(1.0, 1.0, 1.0, 0.15)))
				scene.draw_line(Vector2(cx - 7.0, cy - 4.0), Vector2(cx + 6.0, cy + 5.0), obstacle_colors.get("highlight", Color(1.0, 1.0, 1.0, 0.22)), 1.6)
				scene.draw_line(Vector2(cx - 4.0, cy + 5.0), Vector2(cx + 7.0, cy - 5.0), obstacle_colors.get("highlight", Color(1.0, 1.0, 1.0, 0.16)), 1.2)
			else:
				scene._draw_rounded_rect(x + 2.0, y + 2.0, size - 4.0, size - 4.0, 4.0, obstacle_colors.get("rock", Color(0.35, 0.3, 0.25, 1.0)))
				scene._draw_rounded_rect(x + 4.0, y + 4.0, size - 8.0, size - 8.0, 3.0, obstacle_colors.get("rock_cracked", Color(0.28, 0.24, 0.2, 1.0)))
				scene._draw_stroke_rect(x + 4.0, y + 4.0, size - 8.0, size - 8.0, 1.0, obstacle_colors.get("crack_line", Color(0.2, 0.18, 0.15, 0.9)))
				scene.draw_line(Vector2(cx - 6.0, cy - 4.0), Vector2(cx, cy + 2.0), obstacle_colors.get("crack_line", Color(0.2, 0.18, 0.15, 0.9)), 1.5)
				scene.draw_line(Vector2(cx, cy + 2.0), Vector2(cx + 5.0, cy - 6.0), obstacle_colors.get("crack_line", Color(0.2, 0.18, 0.15, 0.9)), 1.5)
				scene.draw_line(Vector2(cx - 3.0, cy + 1.0), Vector2(cx + 2.0, cy + 6.0), obstacle_colors.get("crack_line", Color(0.2, 0.18, 0.15, 0.9)), 1.5)
				scene.draw_line(Vector2(cx - 8.0, cy - 5.0), Vector2(cx - 1.0, cy + 2.0), obstacle_colors.get("crack_line", Color(0.2, 0.18, 0.15, 0.9)), 1.8)
				scene.draw_line(Vector2(cx - 1.0, cy + 2.0), Vector2(cx + 8.0, cy - 6.0), obstacle_colors.get("crack_line", Color(0.2, 0.18, 0.15, 0.9)), 1.8)

static func draw_fountains(scene, board, state: Dictionary) -> void:
	if board == null:
		return
	var idle_time: float = state.get("idle_time", 0.0)
	var fountain_tex: Texture2D = scene._get_texture("res://assets/images/ui/gems/battle_gem_fountain.png")
	for row in range(board.rows):
		for col in range(board.cols):
			if not board.is_fountain(row, col):
				continue
			var x: float = float(board.offset_x + col * board.cell_size)
			var y: float = float(board.offset_y + row * board.cell_size)
			var size: float = float(board.cell_size)
			var cx := x + size / 2.0
			var cy := y + size / 2.0
			var pulse := 0.5 + 0.5 * sin(idle_time * TAU * 0.9 + float(row + col))
			if fountain_tex:
				var draw_size := size * (1.08 + pulse * 0.04)
				scene._draw_texture_fit(
					fountain_tex,
					Rect2(cx - draw_size / 2.0, cy - draw_size / 2.0 - size * 0.04, draw_size, draw_size),
					0.98
				)
				continue
			scene._draw_rounded_rect(x + 4.0, y + 5.0, size - 8.0, size - 9.0, 8.0, Color(0.05, 0.22, 0.45, 0.96))
			scene._draw_rounded_rect(x + 7.0, y + 8.0, size - 14.0, size - 15.0, 6.0, Color(0.10, 0.46, 0.78, 0.95))
			scene.draw_arc(Vector2(cx, cy + 1.0), size * 0.26, PI * 0.12, PI * 0.88, 20, Color(0.74, 0.94, 1.0, 0.82), 2.2)
			scene.draw_circle(Vector2(cx, cy + 3.0), size * 0.16, Color(0.35, 0.80, 1.0, 0.70 + pulse * 0.18))
			scene.draw_circle(Vector2(cx - size * 0.12, cy - size * 0.04), 2.2, Color(0.88, 1.0, 1.0, 0.74))
			scene.draw_line(Vector2(cx, y + 8.0), Vector2(cx, y + 2.0 - pulse * 3.0), Color(0.65, 0.93, 1.0, 0.55 + pulse * 0.25), 2.0)

static func draw_soaked_gems(scene, board, state: Dictionary) -> void:
	if board == null:
		return
	var idle_time: float = state.get("idle_time", 0.0)
	var shimmer := 0.5 + 0.5 * sin(idle_time * TAU * 1.2)
	var drop_tex: Texture2D = scene._get_texture("res://assets/images/ui/gems/battle_fx_water_drop.png")
	for row in range(board.rows):
		for col in range(board.cols):
			if not board.is_soaked(row, col):
				continue
			var x: float = float(board.offset_x + col * board.cell_size)
			var y: float = float(board.offset_y + row * board.cell_size)
			var size: float = float(board.cell_size)
			var alpha := 0.30 + shimmer * 0.12
			scene._draw_rounded_rect(x + 3.0, y + 3.0, size - 6.0, size - 6.0, 9.0, Color(0.19, 0.64, 1.0, alpha))
			scene.draw_arc(Vector2(x + size / 2.0, y + size / 2.0), size * 0.35, 0.0, TAU, 30, Color(0.82, 0.96, 1.0, 0.52), 1.8)
			# Keep rain readable and cheap: three droplets per affected tile.
			for i in range(3):
				var drop_x := x + size * (0.28 + float(i) * 0.20)
				var phase := fmod(idle_time * 0.95 + float(i) * 0.31 + float(row + col) * 0.07, 1.0)
				var drop_y := y + size * (0.08 + phase * 0.72)
				var drop_alpha := 0.72 * (1.0 - maxf(0.0, phase - 0.75) / 0.25)
				if drop_tex:
					var drop_size := size * (0.26 + 0.06 * float(i % 2))
					scene._draw_texture_fit(drop_tex, Rect2(drop_x - drop_size / 2.0, drop_y - drop_size / 2.0, drop_size, drop_size), drop_alpha)
				else:
					scene.draw_line(Vector2(drop_x, drop_y - 3.0), Vector2(drop_x - 1.5, drop_y + 4.0), Color(0.90, 0.98, 1.0, drop_alpha), 1.4)

static func draw_tide(scene, board, state: Dictionary) -> void:
	if board == null or not board.has_method("has_tide") or not board.has_tide() or int(board.tide_level) <= 0:
		return
	var idle_time: float = state.get("idle_time", 0.0)
	var size: float = float(board.cell_size)
	var board_x: float = float(board.offset_x)
	var board_y: float = float(board.offset_y)
	var water_top_row := maxi(0, board.rows - int(board.tide_level))
	var water_top_y := board_y + float(water_top_row) * size
	var board_w := float(board.cols) * size
	var board_h := float(board.rows) * size
	var water_h := board_y + board_h - water_top_y
	var wave := sin(idle_time * TAU * 0.8) * 2.0
	scene._draw_rounded_rect(board_x + 1.5, water_top_y + wave, board_w - 3.0, water_h - wave - 1.5, 8.0, Color(0.05, 0.38, 0.74, 0.34))
	scene._draw_rounded_rect(board_x + 3.0, water_top_y + size * 0.12 + wave, board_w - 6.0, maxf(0.0, water_h - size * 0.12 - 3.0), 7.0, Color(0.12, 0.66, 0.92, 0.22))
	_draw_tide_wave_line(scene, board_x, water_top_y + wave, board_w, idle_time)
	for row in range(water_top_row, board.rows):
		for col in range(board.cols):
			var x := board_x + float(col) * size
			var y := board_y + float(row) * size
			var gem_type := str(board.grid[row][col])
			var is_water := gem_type == "water"
			var tint := Color(0.10, 0.48, 0.82, 0.18) if is_water else Color(0.02, 0.18, 0.36, 0.38)
			scene._draw_rounded_rect(x + 3.0, y + 3.0, size - 6.0, size - 6.0, 8.0, tint)
			if not is_water and not gem_type.is_empty():
				scene.draw_line(Vector2(x + 9.0, y + size - 9.0), Vector2(x + size - 9.0, y + 9.0), Color(0.78, 0.94, 1.0, 0.38), 2.0)
			if (row + col) % 3 == 0:
				var bubble_phase := fmod(idle_time * 0.65 + float(row * 3 + col) * 0.11, 1.0)
				var bubble_y := y + size * (0.78 - bubble_phase * 0.55)
				var bubble_x := x + size * (0.26 + 0.42 * fmod(float(row + col) * 0.37, 1.0))
				scene.draw_circle(Vector2(bubble_x, bubble_y), 1.8 + bubble_phase * 1.4, Color(0.82, 0.96, 1.0, 0.38 * (1.0 - bubble_phase)))

static func _draw_tide_wave_line(scene, x: float, y: float, width: float, idle_time: float) -> void:
	var segments := 10
	var last := Vector2(x, y)
	for i in range(1, segments + 1):
		var px := x + width * float(i) / float(segments)
		var py := y + sin(idle_time * TAU * 1.15 + float(i) * 0.9) * 2.6
		var current := Vector2(px, py)
		scene.draw_line(last, current, Color(0.76, 0.95, 1.0, 0.82), 2.2)
		last = current
	scene.draw_line(Vector2(x, y + 4.0), Vector2(x + width, y + 4.0), Color(0.18, 0.76, 1.0, 0.36), 2.4)

static func draw_tide_anims(scene, state: Dictionary) -> void:
	for anim: Dictionary in state.get("tide_rise_anims", []):
		var progress := clampf(float(anim.get("timer", 0.0)) / 0.7, 0.0, 1.0)
		if progress >= 1.0:
			continue
		var alpha := 1.0 - progress
		var x := float(anim.get("x", 0.0))
		var y := float(anim.get("y", 0.0))
		var size := float(anim.get("size", 39.0))
		var mode := str(anim.get("mode", "rise"))
		var ring_color := Color(0.52, 0.88, 1.0, alpha * 0.70) if mode == "rise" else Color(0.86, 0.98, 1.0, alpha * 0.52)
		var line_y := y + size * 0.18 - progress * 9.0 if mode == "rise" else y - size * 0.18 + progress * 9.0
		scene.draw_arc(Vector2(x, y), size * (0.25 + progress * 0.55), 0.0, TAU, 28, ring_color, 2.0)
		scene.draw_line(Vector2(x - size * 0.35, line_y), Vector2(x + size * 0.35, line_y), Color(0.85, 0.98, 1.0, alpha * 0.58), 2.0)

static func draw_fountain_anims(scene, state: Dictionary) -> void:
	var drop_tex: Texture2D = scene._get_texture("res://assets/images/ui/gems/battle_fx_water_drop.png")
	for anim: Dictionary in state.get("fountain_erupt_anims", []):
		var progress: float = anim["timer"] / 0.62
		if progress >= 1.0:
			continue
		var alpha := 1.0 - progress
		var cx := float(anim.get("x", 0.0))
		var cy := float(anim.get("y", 0.0))
		var radius := 9.0 + progress * 30.0
		scene.draw_arc(Vector2(cx, cy), radius, 0.0, TAU, 36, Color(0.55, 0.88, 1.0, alpha * 0.72), 2.4)
		if drop_tex:
			for i in range(5):
				var angle := -PI * 0.5 + (float(i) - 2.0) * 0.22
				var lift := sin(progress * PI) * (16.0 + float(i % 2) * 5.0)
				var spread := progress * 8.0
				var drop_size := 8.0 + sin(progress * PI) * (5.0 + float(i % 2) * 2.0)
				var pos := Vector2(cx + cos(angle) * spread, cy - 5.0 + sin(angle) * lift)
				scene._draw_texture_fit(drop_tex, Rect2(pos.x - drop_size / 2.0, pos.y - drop_size / 2.0, drop_size, drop_size), alpha * 0.86)
		else:
			scene.draw_line(Vector2(cx, cy + 10.0), Vector2(cx, cy - 20.0 * (1.0 - progress * 0.2)), Color(0.80, 0.97, 1.0, alpha * 0.82), 3.0)
			scene.draw_circle(Vector2(cx, cy - 18.0 * (1.0 - progress)), 4.0 * alpha, Color(0.92, 1.0, 1.0, alpha))
	for anim: Dictionary in state.get("fountain_splash_anims", []):
		var progress: float = anim["timer"] / 0.52
		if progress >= 1.0:
			continue
		var alpha := 1.0 - progress
		var cx := float(anim.get("x", 0.0))
		var cy := float(anim.get("y", 0.0))
		var color := Color(0.68, 0.90, 1.0, alpha * 0.76)
		if bool(anim.get("extinguished", false)):
			color = Color(0.58, 0.78, 1.0, alpha * 0.88)
		for i in range(3):
			var offset_x := (float(i) - 1.0) * 7.0
			var fall := progress * 18.0
			var pos := Vector2(cx + offset_x, cy - 12.0 + fall)
			if drop_tex:
				var drop_size := 7.0 * alpha + 4.0
				scene._draw_texture_fit(drop_tex, Rect2(pos.x - drop_size / 2.0, pos.y - drop_size / 2.0, drop_size, drop_size), alpha * 0.76)
			else:
				scene.draw_circle(pos, 3.2 * alpha, color)

static func draw_vine_anims(scene, state: Dictionary) -> void:
	for anim: Dictionary in state.get("vine_burn_anims", []):
		var progress: float = anim["timer"] / 0.56
		if progress >= 1.0:
			continue
		var alpha := 1.0 - progress
		var cx := float(anim.get("x", 0.0))
		var cy := float(anim.get("y", 0.0))
		var flame := Color(1.0, 0.46, 0.10, alpha)
		var smoke := Color(0.18, 0.18, 0.16, alpha * 0.38)
		for i in range(5):
			var angle := TAU * float(i) / 5.0 + progress * 1.4
			var dist := 5.0 + progress * 18.0
			scene.draw_circle(Vector2(cx + cos(angle) * dist, cy + sin(angle) * dist), 4.0 * alpha, flame)
		scene.draw_arc(Vector2(cx, cy), 10.0 + progress * 20.0, 0.0, TAU, 32, smoke, 3.0)

static func _vine_backlash_entry_for(anims: Array, row: int, col: int) -> Dictionary:
	for anim in anims:
		if not anim is Dictionary:
			continue
		if int(anim.get("row", -1)) == row and int(anim.get("col", -1)) == col:
			return anim
	return {}

static func draw_poison_fog(scene, board, state: Dictionary) -> void:
	if board == null:
		return
	var idle_time: float = state.get("idle_time", 0.0)
	var t: float = fmod(idle_time, 1.5) / 1.5
	var pulse_opacity: float = 0.2 + (0.4 - 0.2) * (sin(t * TAU) + 1.0) / 2.0
	for row in range(board.rows):
		for col in range(board.cols):
			if not board.is_poison_fog(row, col):
				continue
			var x: float = float(board.offset_x + col * board.cell_size)
			var y: float = float(board.offset_y + row * board.cell_size)
			var size: float = float(board.cell_size)
			var fog_color := Color(0.23, 0.74, 0.38, pulse_opacity * 0.72)
			scene._draw_rounded_rect(x + 2.0, y + 2.0, size - 4.0, size - 4.0, 7.0, fog_color)
			scene.draw_arc(Vector2(x + size / 2.0, y + size / 2.0), size * (0.24 + pulse_opacity * 0.08), 0.0, TAU, 24, Color(0.82, 1.0, 0.62, pulse_opacity * 0.60), 1.8)
			for i in range(3):
				var angle := idle_time * 1.8 + float(i) * TAU / 3.0 + float(row + col) * 0.23
				var mote_pos := Vector2(x + size / 2.0, y + size / 2.0) + Vector2(cos(angle), sin(angle * 0.9)) * (size * 0.18)
				scene.draw_circle(mote_pos, 1.6 + float(i) * 0.35, Color(0.88, 1.0, 0.62, pulse_opacity * 0.58))

static func draw_unlock_animations(scene, board, state: Dictionary) -> void:
	var unlock_animations: Array = state.get("unlock_animations", [])
	for i in range(unlock_animations.size() - 1, -1, -1):
		var anim: Dictionary = unlock_animations[i]
		var progress: float = anim["timer"] / anim.get("maxTimer", 0.6)
		if progress >= 1.0:
			continue
		var alpha: float = 1.0 - progress
		var dist: float = progress * 20.0
		var row: int = anim["row"]
		var col: int = anim["col"]
		var cell_size: float = 42.0
		var board_x: float = (float(state.get("design_w", 375.0)) - 336.0) / 2.0
		var board_y: float = 280.0
		if board != null:
			cell_size = float(board.cell_size)
			board_x = float(board.offset_x)
			board_y = float(board.offset_y)
		var cx: float = board_x + col * cell_size + cell_size / 2.0
		var cy: float = board_y + row * cell_size + cell_size / 2.0
		var dirs: Array = [[-1, -1], [1, -1], [-1, 1], [1, 1]]
		for d: Array in dirs:
			var start := Vector2(cx + d[0] * dist * 0.35, cy + d[1] * dist * 0.35)
			var finish := Vector2(cx + d[0] * (dist + 8.0), cy + d[1] * (dist + 8.0))
			scene.draw_line(start, finish, Color(0.95, 0.86, 0.62, alpha), 2.2)
			scene.draw_circle(finish, 2.6, Color(0.40, 0.36, 0.45, alpha))

static func draw_poison_fog_anims(scene, state: Dictionary) -> void:
	for anim: Dictionary in state.get("poison_fog_spread_anims", []):
		var progress: float = anim["timer"] / 0.6
		if progress >= 1.0:
			continue
		var alpha: float = (1.0 - progress) * 0.6
		var radius: float = 42.0 * 0.3 * progress * 2.0
		var cx: float = anim["x"] + 21.0
		var cy: float = anim["y"] + 21.0
		var ring_color: Color = Color(0.31, 0.78, 0.31, alpha)
		var points: int = maxi(32, int(radius * 2.0))
		for p in range(points):
			var angle1: float = TAU * p / points
			var angle2: float = TAU * (p + 1) / points
			scene.draw_line(Vector2(cx + cos(angle1) * radius, cy + sin(angle1) * radius), Vector2(cx + cos(angle2) * radius, cy + sin(angle2) * radius), ring_color, 2.0)
	for anim: Dictionary in state.get("poison_fog_clear_anims", []):
		var progress: float = anim["timer"] / 0.5
		if progress >= 1.0:
			continue
		var alpha: float = 1.0 - progress
		var dist: float = progress * 15.0
		var cx: float = anim["x"] + 21.0
		var cy: float = anim["y"] + 21.0
		var dirs: Array = [[-1, -1], [1, -1], [-1, 1], [1, 1]]
		for d: Array in dirs:
			var pos := Vector2(cx + d[0] * dist, cy + d[1] * dist)
			scene.draw_circle(pos, 4.0 * (1.0 - progress), Color(0.82, 1.0, 0.62, alpha * 0.55))
			scene.draw_line(pos - Vector2(4.0, 0.0), pos + Vector2(4.0, 0.0), Color(0.42, 0.90, 0.48, alpha), 1.4)

static func draw_special_transform(scene, board, state: Dictionary) -> void:
	var anim: Dictionary = state.get("special_transform_anim", {})
	if anim.get("timer", 0.0) <= 0.0 or anim.get("triggered", false):
		return
	var duration: float = anim.get("duration", 0.5)
	var timer: float = anim.get("timer", 0.0)
	var progress: float = 1.0 - timer / duration
	var cell_size: float = float(board.cell_size) if board != null else 42.0
	var board_x: float = float(board.offset_x) if board != null else (state.get("design_w", 375.0) - 336.0) / 2.0
	var board_y: float = float(board.offset_y) if board != null else 280.0
	var row: int = anim.get("row", -1)
	var col: int = anim.get("col", -1)
	if row < 0 or col < 0:
		return
	var cx: float = board_x + col * cell_size + cell_size / 2.0
	var cy: float = board_y + row * cell_size + cell_size / 2.0
	if progress < 0.3:
		var flash_progress: float = progress / 0.3
		scene._draw_circle(cx, cy, cell_size * 1.5 * flash_progress, Color(1.0, 1.0, 1.0, 0.8 * (1.0 - flash_progress)))
	var gem_scale: float = 1.0
	if progress < 0.4:
		gem_scale = lerp(0.5, 1.2, progress / 0.4)
	else:
		gem_scale = lerp(1.2, 1.0, (progress - 0.4) / 0.6)
	var gem_type: String = anim.get("type", "fire")
	var gem_color: Color = state.get("gem_colors", {}).get(gem_type, state.get("colors", {}).get("white", Color.WHITE))
	scene._draw_gem_animated(cx, cy, gem_type, gem_color, gem_scale, 1.0)

static func _eliminate_scale(progress: float) -> float:
	# Q 弹两段：轻微弹出 → 一口气缩没
	var p := clampf(progress, 0.0, 1.0)
	if p < 0.45:
		return lerpf(1.0, 1.20, _ease_out_cubic(p / 0.45))
	return lerpf(1.20, 0.0, _ease_in_cubic((p - 0.45) / 0.55))

static func _falling_entry_for(falling_gems: Array, row: int, col: int, gem_type: String) -> Dictionary:
	for entry in falling_gems:
		if int(entry.get("row", -999)) == row and int(entry.get("col", -999)) == col and str(entry.get("type", "")) == gem_type:
			return entry
	return {}

static func _ice_slide_entry_for(slide_anims: Array, row: int, col: int, gem_type: String) -> Dictionary:
	for entry in slide_anims:
		if int(entry.get("row", -999)) == row and int(entry.get("col", -999)) == col and str(entry.get("type", "")) == gem_type:
			return entry
	return {}

static func _fall_center_y(fall: Dictionary, fallback_y: float) -> float:
	var fall_t: float = clampf((float(fall.get("timer", 0.0)) - float(fall.get("delay", 0.0))) / maxf(0.01, float(fall.get("duration", 0.34))), 0.0, 1.0)
	var eased := _ease_out_cubic(fall_t)
	var bounce := 0.0
	if fall_t > 0.72:
		var bp := (fall_t - 0.72) / 0.28
		bounce = -sin(bp * PI) * 5.0 * (1.0 - bp)
	return lerpf(float(fall.get("from_y", fallback_y)), float(fall.get("to_y", fallback_y)), eased) + bounce

static func _ease_out_cubic(t: float) -> float:
	var p := clampf(t, 0.0, 1.0)
	return 1.0 - pow(1.0 - p, 3.0)

static func _ease_in_cubic(t: float) -> float:
	var p := clampf(t, 0.0, 1.0)
	return p * p * p

static func _ease_out_back(t: float) -> float:
	var p := clampf(t, 0.0, 1.0)
	var c1 := 1.70158
	var c3 := c1 + 1.0
	return 1.0 + c3 * pow(p - 1.0, 3.0) + c1 * pow(p - 1.0, 2.0)
