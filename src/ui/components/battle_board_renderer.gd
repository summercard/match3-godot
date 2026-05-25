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
	var frame_tex: Texture2D = scene._get_texture("res://assets/images/battle/ui/ui_board_frame.png")
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
	var cell_tex: Texture2D = scene._get_texture("res://assets/images/battle/ui/ui_board_cell.png")

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
	var selected_gem: Vector2i = state.get("selected_gem", Vector2i(-1, -1))
	var idle_time: float = state.get("idle_time", 0.0)
	var eliminate_duration: float = state.get("eliminate_duration", 0.25)
	var eliminate_phase1: float = state.get("eliminate_phase1", 0.1)
	var eliminate_phase2: float = state.get("eliminate_phase2", 0.15)
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
		var scale: float = 1.0
		var alpha: float = 1.0
		var brightness: float = 0.0
		if elim_progress * eliminate_duration <= eliminate_phase1:
			var p1: float = (elim_progress * eliminate_duration) / eliminate_phase1
			scale = 1.0 + 0.2 * p1
			brightness = p1
		else:
			var p2: float = ((elim_progress * eliminate_duration) - eliminate_phase1) / eliminate_phase2
			scale = 1.2 * (1.0 - p2)
			alpha = 1.0 - p2
			brightness = 1.0 - p2
		scene._draw_gem_animated(cx, cy, gem_type, gem_color, scale, alpha, brightness)
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
			var cx: float = x + size / 2.0
			var cy: float = y + size / 2.0
			var lock_tex: Texture2D = scene._get_texture("res://assets/images/battle/gems/gem_locked_tile.png")
			if lock_tex:
				scene._draw_texture_fit(lock_tex, Rect2(x + 2.0, y + 2.0, size - 4.0, size - 4.0), 0.96)
				continue
			var chain_color: Color = lock_colors.get("chain", Color(0.6, 0.6, 0.7, 0.9)) if lock.get("hp", 1) >= 2 else lock_colors.get("chain_weak", Color(0.5, 0.5, 0.55, 0.7))
			var corners: Array[Vector2] = [
				Vector2(x + 3.0, y + 3.0), Vector2(x + size - 3.0, y + 3.0),
				Vector2(x + 3.0, y + size - 3.0), Vector2(x + size - 3.0, y + size - 3.0)
			]
			for i in range(4):
				scene.draw_line(corners[i], corners[(i + 1) % 4], chain_color, 2.5)
			var icon_color: Color = Color(0.78, 0.78, 0.86, 0.9)
			for corner in corners:
				scene._draw_text_with_shadow("⛓", corner.x, corner.y, icon_color, 8.0)
			if lock.get("hp", 1) >= 2:
				scene._draw_text_with_shadow("🔒", cx, cy - 4.0, Color(1.0, 1.0, 1.0, 0.7), 8.0)
			else:
				scene._draw_text_with_shadow("×1", cx, cy + 4.0, Color(1.0, 1.0, 1.0, 0.8), 8.0)

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
			var rock_path := "res://assets/images/battle/gems/obstacle_rock_full.png" if ob.get("hp", 2) >= 2 else "res://assets/images/battle/gems/obstacle_rock_cracked.png"
			var rock_tex: Texture2D = scene._get_texture(rock_path)
			if rock_tex:
				scene._draw_texture_fit(rock_tex, Rect2(x + 2.0, y + 2.0, size - 4.0, size - 4.0), 0.98)
				continue
			if ob.get("hp", 2) >= 2:
				scene._draw_rounded_rect(x + 2.0, y + 2.0, size - 4.0, size - 4.0, 4.0, obstacle_colors.get("rock", Color(0.35, 0.3, 0.25, 1.0)))
				scene._draw_rounded_rect(x + 4.0, y + 4.0, size - 8.0, size - 8.0, 3.0, obstacle_colors.get("rock_solid", Color(0.42, 0.38, 0.32, 1.0)))
				scene._draw_rounded_rect(x + 6.0, y + 6.0, size - 16.0, (size - 8.0) / 3.0, 2.0, obstacle_colors.get("highlight", Color(1.0, 1.0, 1.0, 0.15)))
				scene._draw_text_with_shadow("🪨", cx, cy, Color(1.0, 1.0, 1.0, 0.7), 12.0)
			else:
				scene._draw_rounded_rect(x + 2.0, y + 2.0, size - 4.0, size - 4.0, 4.0, obstacle_colors.get("rock", Color(0.35, 0.3, 0.25, 1.0)))
				scene._draw_rounded_rect(x + 4.0, y + 4.0, size - 8.0, size - 8.0, 3.0, obstacle_colors.get("rock_cracked", Color(0.28, 0.24, 0.2, 1.0)))
				scene._draw_stroke_rect(x + 4.0, y + 4.0, size - 8.0, size - 8.0, 1.0, obstacle_colors.get("crack_line", Color(0.2, 0.18, 0.15, 0.9)))
				scene.draw_line(Vector2(cx - 6.0, cy - 4.0), Vector2(cx, cy + 2.0), obstacle_colors.get("crack_line", Color(0.2, 0.18, 0.15, 0.9)), 1.5)
				scene.draw_line(Vector2(cx, cy + 2.0), Vector2(cx + 5.0, cy - 6.0), obstacle_colors.get("crack_line", Color(0.2, 0.18, 0.15, 0.9)), 1.5)
				scene.draw_line(Vector2(cx - 3.0, cy + 1.0), Vector2(cx + 2.0, cy + 6.0), obstacle_colors.get("crack_line", Color(0.2, 0.18, 0.15, 0.9)), 1.5)
				scene._draw_text_with_shadow("🪨", cx, cy, Color(1.0, 1.0, 1.0, 0.5), 14.0)

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
			scene.draw_rect(Rect2(x + 1.0, y + 1.0, size - 2.0, size - 2.0), Color(0.31, 0.78, 0.31, pulse_opacity))
			scene._draw_text_with_shadow("💀", x + size / 2.0, y + size / 2.0, Color(1.0, 1.0, 1.0, 0.5 + pulse_opacity), 10.0)

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
			scene._draw_text_with_shadow("⛓", cx + d[0] * dist, cy + d[1] * dist, Color(0.6, 0.6, 0.7, alpha), 10.0)

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
			scene._draw_text_with_shadow("☁️", cx + d[0] * dist, cy + d[1] * dist, Color(0.31, 0.78, 0.31, alpha), 10.0)

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
