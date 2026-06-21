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
			if board.is_obstacle(row, col):
				continue
			var gem_type: String = board.grid[row][col]
			if gem_type.is_empty():
				continue
			_draw_gem_cell(scene, board, state, row, col, x, y, cell_size, gem_type)

	draw_locked_gems(scene, board, state)
	draw_obstacles(scene, board, state)
	draw_poison_fog(scene, board, state)
	draw_unlock_animations(scene, board, state)
	draw_poison_fog_anims(scene, state)

static func _draw_gem_cell(scene, board, state: Dictionary, row: int, col: int, x: float, y: float, cell_size: float, gem_type: String) -> void:
	var colors: Dictionary = state.get("colors", {})
	var gem_colors: Dictionary = state.get("gem_colors", {})
	var eliminating_gems: Array = state.get("eliminating_gems", [])
	var falling_gems: Array = state.get("falling_gems", [])
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
