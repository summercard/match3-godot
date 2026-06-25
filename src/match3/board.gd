class_name Match3Board
extends RefCounted
## 三消棋盘核心 - 从 js/match3/board.js 翻译
## 负责棋盘数据结构、障碍物/锁定宝石/毒雾格子、宝石交换与匹配检测
## 强化宝石(4连)/彩虹宝石(5连)/炸弹(L/T形)、重力下落与新宝石生成
##
## 翻译要点：
## - 使用 RefCounted（轻量核心对象，不需要场景节点）
## - 二维数组用 Array 表示：grid[row][col]，每行是一个 Array
## - Math.random() → randi() % N 或 randf()
## - Math.floor() → wrapi() 用于整数（但 Godot 中直接用 int() 截断更直接）
## - 不支持原生 Set，用 Array + .has() 或手动去重
## - 字典用 Dictionary，如 { "type": "rock", "hp": 2 }
## - 匹配检测分四阶段：横向扫描 → 纵向扫描 → 分类(5连→彩虹,4连→强化) → L/T形检测
## - 强化宝石爆炸：上下左右各2格共8格（不含中心）
## - 炸弹爆炸：3×3范围（不含中心）共8格，同时伤害障碍物
## - 毒雾扩散：每N回合随机向1-2个方向扩散1格
## - 重力下落按障碍物/锁定宝石分段处理

# ========== 静态常量 ==========

## 宝石类型列表
const GEM_TYPES: Array = ["fire", "water", "grass", "thunder", "light"]

## 宝石颜色映射（十六进制）
const GEM_COLORS: Dictionary = {
	"fire":    "#ff4444",
	"water":   "#4488ff",
	"grass":   "#44bb44",
	"thunder": "#ffaa00",
	"light":   "#dd44ff"
}

## 宝石 Emoji 映射
const GEM_EMOJI: Dictionary = {
	"fire":    "🔥",
	"water":   "💧",
	"grass":   "🌿",
	"thunder": "⚡",
	"light":   "✨"
}

## 强化宝石类型标识（4连消产生）
const ENHANCED_GEM: String = "enhanced"

## 炸弹宝石类型标识（L/T形消除产生）
const BOMB_GEM: String = "bomb"
const SHUFFLE_MAX_ATTEMPTS: int = 32
const SHUFFLE_REGENERATE_ATTEMPTS: int = 64

# ========== 实例变量 ==========

## 棋盘尺寸
var rows: int = 8
var cols: int = 8

## 棋盘数据：grid[row][col] = gem type string 或 ""
## 注意：GDScript 中 null 不能直接存在 Array 里，用空字符串 "" 代替
var grid: Array = []

## 障碍物数据：obstacles[row][col] = null 或 { type: "rock", hp: 2 }
var obstacles: Array = []
var fountains: Array = []

## 锁定宝石数据：lockedGems[row][col] = null 或 { hp: 1|2 }
## 被锁的宝石不可交换或参与普通消除，但会随重力下落
## 消除相邻同色宝石可触发解锁
var locked_gems: Array = []
var soaked_gems: Array = []
var vine_gems: Array = []
var tide_level: int = 0
var tide_rule: Dictionary = {
	"startLevel": 0,
	"risePerTurn": 1,
	"maxLevel": 3
}

var fountain_rule: Dictionary = {
	"eruptionCount": 1,
	"range": "orthogonal_1",
	"soakTurns": 1,
	"fireVanishes": true
}

## 毒雾数据：poisonFog[row][col] = null 或 { active: true, turnsSinceSpread: 0 }
## 毒雾格子上的宝石可正常参与消除，但每回合造成伤害
## 消除经过毒雾格子可清除毒雾
var poison_fog: Array = []
var poison_fog_spread_interval: int = 3  # 默认扩散间隔（回合数）

## 棋盘布局参数
var cell_size: int = 40       # 每个格子的设计像素尺寸
var offset_x: int = 7           # 棋盘左上角X
var offset_y: int = 230         # 棋盘左上角Y

## 棋盘状态
var locked: bool = false
var cascade_count: int = 0     # 连锁次数

# ========== 初始化 ==========

func _init(p_rows: int = 8, p_cols: int = 8) -> void:
	rows = p_rows
	cols = p_cols
	_init_obstacles()
	_init_fountains()
	_init_locked_gems()
	_init_soaked_gems()
	_init_vine_gems()
	_init_poison_fog()
	_generate_initial_grid()

## 初始化障碍物数组（全部为 null）
func _init_obstacles() -> void:
	obstacles = []
	for r: int in range(rows):
		obstacles.append([])
		for c: int in range(cols):
			obstacles[r].append(null)

func _init_fountains() -> void:
	fountains = []
	for r: int in range(rows):
		fountains.append([])
		for c: int in range(cols):
			fountains[r].append(null)

## 初始化锁定宝石数组（全部为 null）
func _init_locked_gems() -> void:
	locked_gems = []
	for r: int in range(rows):
		locked_gems.append([])
		for c: int in range(cols):
			locked_gems[r].append(null)

func _init_soaked_gems() -> void:
	soaked_gems = []
	for r: int in range(rows):
		soaked_gems.append([])
		for c: int in range(cols):
			soaked_gems[r].append(null)

func _init_vine_gems() -> void:
	vine_gems = []
	for r: int in range(rows):
		vine_gems.append([])
		for c: int in range(cols):
			vine_gems[r].append(null)

## 初始化毒雾数组（全部为 null）
func _init_poison_fog() -> void:
	poison_fog = []
	for r: int in range(rows):
		poison_fog.append([])
		for c: int in range(cols):
			poison_fog[r].append(null)

## 初始化棋盘
func _generate_initial_grid() -> void:
	# 生成初始棋盘，确保没有初始匹配
	for r: int in range(rows):
		grid.append([])
		for c: int in range(cols):
			if is_blocked_cell(r, c):
				grid[r].append("")
				continue
			var type: String = ""
			var attempts: int = 0
			while attempts < 100:
				type = _random_gem_type()
				if not _would_match(r, c, type):
					break
				attempts += 1
			grid[r].append(type)

## 随机获取一个宝石类型
func _random_gem_type() -> String:
	return GEM_TYPES[randi() % GEM_TYPES.size()]

# ========== 棋盘重置 ==========

## 公开的棋盘重置入口：保留当前障碍/锁链/毒雾布局，只重新生成宝石
func init_board() -> void:
	grid = []
	cascade_count = 0
	_generate_initial_grid()

# ========== 辅助检查方法 ==========

## 检查某个格子是否有障碍物
func is_obstacle(row: int, col: int) -> bool:
	if row < 0 or row >= rows or col < 0 or col >= cols:
		return false
	return obstacles[row][col] != null

func is_fountain(row: int, col: int) -> bool:
	if row < 0 or row >= rows or col < 0 or col >= cols:
		return false
	return fountains[row][col] != null

func is_blocked_cell(row: int, col: int) -> bool:
	return is_obstacle(row, col) or is_fountain(row, col)

## 检查某个格子是否被锁定
func is_locked(row: int, col: int) -> bool:
	if row < 0 or row >= rows or col < 0 or col >= cols:
		return false
	var lock = locked_gems[row][col]
	if lock == null or not lock is Dictionary:
		return false
	return lock.get("hp", 0) > 0

func is_soaked(row: int, col: int) -> bool:
	if row < 0 or row >= rows or col < 0 or col >= cols:
		return false
	var soak = soaked_gems[row][col]
	if soak == null or not soak is Dictionary:
		return false
	return int(soak.get("turns", 0)) > 0

func is_vined(row: int, col: int) -> bool:
	if row < 0 or row >= rows or col < 0 or col >= cols:
		return false
	var vine = vine_gems[row][col]
	if vine == null or not vine is Dictionary:
		return false
	return bool(vine.get("active", true))

func has_tide() -> bool:
	return int(tide_rule.get("maxLevel", 0)) > 0

func is_tide_flooded(row: int, col: int) -> bool:
	if row < 0 or row >= rows or col < 0 or col >= cols:
		return false
	return tide_level > 0 and row >= rows - tide_level

func is_tide_restricted(row: int, col: int) -> bool:
	if not is_tide_flooded(row, col):
		return false
	return str(grid[row][col]) != "water"

func is_gem_playable(row: int, col: int) -> bool:
	if is_locked(row, col) or is_soaked(row, col):
		return false
	return not is_tide_restricted(row, col)

## 检查某个格子是否有毒雾
func is_poison_fog(row: int, col: int) -> bool:
	if row < 0 or row >= rows or col < 0 or col >= cols:
		return false
	var fog = poison_fog[row][col]
	if fog == null or not fog is Dictionary:
		return false
	return fog.get("active", false)

## 检查放置 type 在 (r,c) 是否会立即形成匹配
func _would_match(row: int, col: int, type: String) -> bool:
	# 横向检查：左边2个相同（跳过障碍物格子）
	if col >= 2 and not is_blocked_cell(row, col - 1) and not is_blocked_cell(row, col - 2):
		if grid[row][col - 1] == type and grid[row][col - 2] == type:
			return true
	# 纵向检查：上面2个相同（跳过障碍物格子）
	if row >= 2 and not is_blocked_cell(row - 1, col) and not is_blocked_cell(row - 2, col):
		if grid[row - 1][col] == type and grid[row - 2][col] == type:
			return true
	return false

## 将屏幕坐标转换为棋盘格子坐标
func screen_to_grid(x: float, y: float) -> Dictionary:
	var local_x := x - float(offset_x)
	var local_y := y - float(offset_y)
	if local_x < 0.0 or local_y < 0.0:
		return {}
	var col: int = floori(local_x / float(cell_size))
	var row: int = floori(local_y / float(cell_size))
	if row >= 0 and row < rows and col >= 0 and col < cols:
		return { "row": row, "col": col }
	return {}

## 检查某个格子是否为空（无宝石）
func is_empty(row: int, col: int) -> bool:
	if row < 0 or row >= rows or col < 0 or col >= cols:
		return true
	return grid[row][col] == "" or grid[row][col] == null

# ========== 障碍物相关 ==========

## 设置障碍物布局（从关卡配置读取）
## layout: [{ row, col, type: 'rock', hp?: 2 }] or null
func set_obstacles(layout: Array) -> void:
	_init_obstacles()
	if layout == null or layout.size() == 0:
		return
	for ob: Dictionary in layout:
		var r: int = ob.get("row", -1)
		var c: int = ob.get("col", -1)
		if r >= 0 and r < rows and c >= 0 and c < cols:
			obstacles[r][c] = {
				"type": ob.get("type", "rock"),
				"hp": ob.get("hp", 2)
			}
			if vine_gems.size() == rows and vine_gems[r].size() == cols:
				vine_gems[r][c] = null

func set_fountains(layout: Array, rule: Dictionary = {}) -> void:
	_init_fountains()
	clear_soaked_gems()
	if rule != null and not rule.is_empty():
		for key in rule:
			fountain_rule[key] = rule[key]
	if layout == null or layout.size() == 0:
		return
	for fountain: Dictionary in layout:
		var r: int = fountain.get("row", -1)
		var c: int = fountain.get("col", -1)
		if r >= 0 and r < rows and c >= 0 and c < cols:
			fountains[r][c] = {"type": fountain.get("type", "fountain")}
			if grid.size() == rows and grid[r].size() == cols:
				grid[r][c] = ""
			if locked_gems.size() == rows and locked_gems[r].size() == cols:
				locked_gems[r][c] = null
			if vine_gems.size() == rows and vine_gems[r].size() == cols:
				vine_gems[r][c] = null

func set_tide(rule: Dictionary = {}) -> void:
	tide_rule = {
		"startLevel": int(rule.get("startLevel", 0)),
		"risePerTurn": maxi(1, int(rule.get("risePerTurn", 1))),
		"maxLevel": clampi(int(rule.get("maxLevel", 3)), 0, rows)
	}
	tide_level = clampi(int(tide_rule.get("startLevel", 0)), 0, int(tide_rule.get("maxLevel", 0)))

func process_tide_rise() -> Dictionary:
	var old_level := tide_level
	var max_level := clampi(int(tide_rule.get("maxLevel", 0)), 0, rows)
	if max_level <= 0 or tide_level >= max_level:
		return {"old_level": old_level, "new_level": tide_level, "risen_rows": []}
	var rise := maxi(1, int(tide_rule.get("risePerTurn", 1)))
	tide_level = mini(max_level, tide_level + rise)
	var risen_rows: Array = []
	for row in range(rows - tide_level, rows - old_level):
		if row >= 0 and row < rows:
			risen_rows.append(row)
	return {"old_level": old_level, "new_level": tide_level, "risen_rows": risen_rows}

func clear_soaked_gems() -> void:
	if soaked_gems.is_empty():
		_init_soaked_gems()
		return
	for row in range(rows):
		for col in range(cols):
			soaked_gems[row][col] = null

func get_fountain_positions() -> Array:
	var result: Array = []
	for row in range(rows):
		for col in range(cols):
			if is_fountain(row, col):
				result.append({"row": row, "col": col})
	return result

func process_fountain_eruption() -> Dictionary:
	clear_soaked_gems()
	var fountain_positions := get_fountain_positions()
	if fountain_positions.is_empty():
		return {"erupted": [], "soaked": [], "extinguished": []}

	var pool := fountain_positions.duplicate(true)
	_shuffle_array(pool)
	var eruption_count := clampi(int(fountain_rule.get("eruptionCount", 1)), 1, pool.size())
	var erupted: Array = []
	for i in range(eruption_count):
		erupted.append(pool[i])

	var affected: Dictionary = {}
	for source: Dictionary in erupted:
		for pos: Dictionary in _fountain_affected_positions(int(source["row"]), int(source["col"])):
			affected["%d,%d" % [pos["row"], pos["col"]]] = pos

	var soaked: Array = []
	var extinguished: Array = []
	for key in affected.keys():
		var pos: Dictionary = affected[key]
		var row := int(pos["row"])
		var col := int(pos["col"])
		if is_blocked_cell(row, col) or is_empty(row, col):
			continue
		var gem_type := str(grid[row][col])
		if gem_type == "fire" and bool(fountain_rule.get("fireVanishes", true)):
			grid[row][col] = ""
			locked_gems[row][col] = null
			soaked_gems[row][col] = null
			extinguished.append({"row": row, "col": col, "type": gem_type})
		else:
			soaked_gems[row][col] = {"turns": int(fountain_rule.get("soakTurns", 1))}
			soaked.append({"row": row, "col": col, "type": gem_type})

	return {"erupted": erupted, "soaked": soaked, "extinguished": extinguished}

func _fountain_affected_positions(row: int, col: int) -> Array:
	var positions: Array = []
	var offsets: Array = [[-1, 0], [1, 0], [0, -1], [0, 1]]
	var range_type := str(fountain_rule.get("range", "orthogonal_1"))
	if range_type == "square_1":
		offsets = []
		for dr in range(-1, 2):
			for dc in range(-1, 2):
				if dr != 0 or dc != 0:
					offsets.append([dr, dc])
	elif range_type == "cross_2":
		offsets = [[-2, 0], [-1, 0], [1, 0], [2, 0], [0, -2], [0, -1], [0, 1], [0, 2]]
	for offset: Array in offsets:
		var nr := row + int(offset[0])
		var nc := col + int(offset[1])
		if nr >= 0 and nr < rows and nc >= 0 and nc < cols:
			positions.append({"row": nr, "col": nc})
	return positions

func set_vines(layout: Array) -> void:
	_init_vine_gems()
	if layout == null or layout.size() == 0:
		return
	for vine in layout:
		var r := -1
		var c := -1
		if vine is Dictionary:
			r = int(vine.get("row", -1))
			c = int(vine.get("col", -1))
		elif vine is Array and vine.size() >= 2:
			r = int(vine[0])
			c = int(vine[1])
		if r >= 0 and r < rows and c >= 0 and c < cols and not is_blocked_cell(r, c):
			vine_gems[r][c] = {"active": true}

func clear_vine(row: int, col: int) -> bool:
	if not is_vined(row, col):
		return false
	vine_gems[row][col] = null
	return true

## 对障碍物造成1点伤害，返回是否被破坏
func damage_obstacle(row: int, col: int) -> bool:
	if not is_obstacle(row, col):
		return false
	var ob: Dictionary = obstacles[row][col]
	ob["hp"] -= 1
	if ob["hp"] <= 0:
		obstacles[row][col] = null
		return true  # 被破坏
	return false

## 消除宝石后，对相邻障碍物造成伤害
func _damage_adjacent_obstacles(row: int, col: int) -> Array:
	return damage_obstacles_for_resolution([{"row": row, "col": col}])


## 一次消除结算的统一障碍伤害入口。
## 普通、十字、彩虹按被移除宝石的四邻域收集；炸弹额外覆盖中心3×3。
## 同一坐标先去重，再统一造成1点伤害。
func damage_obstacles_for_resolution(gem_positions: Array, bomb_centers: Array = []) -> Array:
	var affected: Dictionary = {}
	var dirs: Array = [[-1, 0], [1, 0], [0, -1], [0, 1]]
	for gem in gem_positions:
		if not gem is Dictionary:
			continue
		var row := int(gem.get("row", -1))
		var col := int(gem.get("col", -1))
		for d: Array in dirs:
			_add_obstacle_if_valid(affected, row + int(d[0]), col + int(d[1]))
	for bomb in bomb_centers:
		if not bomb is Dictionary:
			continue
		var center_row := int(bomb.get("row", -1))
		var center_col := int(bomb.get("col", -1))
		for dr in range(-1, 2):
			for dc in range(-1, 2):
				if dr == 0 and dc == 0:
					continue
				_add_obstacle_if_valid(affected, center_row + dr, center_col + dc)

	var results: Array = []
	for key in affected.keys():
		var pos: Dictionary = affected[key]
		var row := int(pos["row"])
		var col := int(pos["col"])
		var destroyed := damage_obstacle(row, col)
		results.append({
			"row": row,
			"col": col,
			"destroyed": destroyed,
			"remainingHP": 0 if destroyed else int(obstacles[row][col].get("hp", 0))
		})
	return results


func _add_obstacle_if_valid(affected: Dictionary, row: int, col: int) -> void:
	if row < 0 or row >= rows or col < 0 or col >= cols or not is_obstacle(row, col):
		return
	affected["%d,%d" % [row, col]] = {"row": row, "col": col}

# ========== 锁定宝石相关 ==========

## 设置锁定宝石布局（从关卡配置读取）
## layout: [{ row, col, hp: 1|2 }] or null
func set_locked_gems(layout: Array) -> void:
	_init_locked_gems()
	if layout == null or layout.size() == 0:
		return
	for lk: Dictionary in layout:
		var r: int = lk.get("row", -1)
		var c: int = lk.get("col", -1)
		if r >= 0 and r < rows and c >= 0 and c < cols:
			locked_gems[r][c] = { "hp": lk.get("hp", 1) }

## 对锁定宝石减少1点锁链HP，返回解锁信息
func unlock_gem(row: int, col: int) -> Dictionary:
	if not is_locked(row, col):
		return {}
	var lock: Dictionary = locked_gems[row][col]
	lock["hp"] -= 1
	if lock["hp"] <= 0:
		locked_gems[row][col] = null
		return { "row": row, "col": col, "fullyUnlocked": true }
	return { "row": row, "col": col, "fullyUnlocked": false, "remainingHP": lock["hp"] }

## 消除宝石后，检查相邻锁定宝石是否同色，同色则触发解锁
## 返回 [{ row, col, fullyUnlocked, remainingHP? }]
func check_adjacent_unlocks(row: int, col: int, gem_type: String) -> Array:
	var unlock_results: Array = []
	var dirs: Array = [[-1, 0], [1, 0], [0, -1], [0, 1]]
	for d: Array in dirs:
		var nr: int = row + d[0]
		var nc: int = col + d[1]
		if nr < 0 or nr >= rows or nc < 0 or nc >= cols:
			continue
		if not is_locked(nr, nc):
			continue
		# 检查锁定宝石是否与消除宝石同色
		if grid[nr][nc] == gem_type:
			var result: Dictionary = unlock_gem(nr, nc)
			if not result.is_empty():
				unlock_results.append(result)
	return unlock_results

# ========== 毒雾相关 ==========

## 设置毒雾布局（从关卡配置读取）
## config: { tiles: [{ row, col }], spreadInterval?: number } or null
func set_poison_fog(config: Dictionary) -> void:
	_init_poison_fog()
	var tiles: Array = config.get("tiles", [])
	if config == null or tiles == null or tiles.size() == 0:
		return
	if config.has("spreadInterval"):
		poison_fog_spread_interval = config["spreadInterval"]
	for t: Dictionary in tiles:
		var r: int = t.get("row", -1)
		var c: int = t.get("col", -1)
		if r >= 0 and r < rows and c >= 0 and c < cols:
			# 不在障碍物格子上放毒雾
			if not is_blocked_cell(r, c):
				poison_fog[r][c] = { "active": true, "turnsSinceSpread": 0 }

## 清除某个格子的毒雾（消除宝石时调用）
func clear_poison_fog(row: int, col: int) -> bool:
	if not is_poison_fog(row, col):
		return false
	poison_fog[row][col] = null
	return true

## 扩散毒雾（每N回合调用一次）
## 返回新扩散的格子列表 [{ row, col }]
func spread_poison_fog() -> Array:
	var new_tiles: Array = []
	var dirs: Array = [[-1, 0], [1, 0], [0, -1], [0, 1]]
	
	# 收集所有当前有毒雾的格子
	var active_fog_tiles: Array = []
	for r: int in range(rows):
		for c: int in range(cols):
			if is_poison_fog(r, c):
				active_fog_tiles.append({ "row": r, "col": c })
	
	# 从每个毒雾格子尝试向随机1-2个方向扩散
	for tile: Dictionary in active_fog_tiles:
		var tr: int = tile["row"]
		var tc: int = tile["col"]
		
		# 递增回合计数
		poison_fog[tr][tc]["turnsSinceSpread"] += 1
		
		# 检查是否到达扩散间隔
		if poison_fog[tr][tc]["turnsSinceSpread"] < poison_fog_spread_interval:
			continue
		
		# 重置计数
		poison_fog[tr][tc]["turnsSinceSpread"] = 0
		
		# 随机选1-2个方向扩散
		var shuffled: Array = dirs.duplicate()
		_shuffle_array(shuffled)
		var spread_count: int = 1 if randf() < 0.5 else 2
		
		for i: int in range(min(spread_count, shuffled.size())):
			var d: Array = shuffled[i]
			var nr: int = tr + d[0]
			var nc: int = tc + d[1]
			if nr < 0 or nr >= rows or nc < 0 or nc >= cols:
				continue
			if is_blocked_cell(nr, nc):
				continue
			if is_poison_fog(nr, nc):
				continue  # 已有毒雾不重复
			
			poison_fog[nr][nc] = { "active": true, "turnsSinceSpread": 0 }
			new_tiles.append({ "row": nr, "col": nc })
	
	return new_tiles

## 获取当前回合毒雾伤害格子数（毒雾覆盖且有宝石的格子数）
func get_poison_fog_damage_count() -> int:
	var count: int = 0
	for r: int in range(rows):
		for c: int in range(cols):
			if is_poison_fog(r, c) and not is_empty(r, c):
				count += 1
	return count

## Fisher-Yates 洗牌
func _shuffle_array(arr: Array) -> void:
	for i: int in range(arr.size() - 1, 0, -1):
		var j: int = randi() % (i + 1)
		var tmp: Variant = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp

# ========== 宝石交换 ==========

## 尝试交换两个相邻格子
func swap(r1: int, c1: int, r2: int, c2: int) -> bool:
	# 检查是否相邻
	var dr: int = abs(r1 - r2)
	var dc: int = abs(c1 - c2)
	if dr + dc != 1:
		return false
	
	# 检查是否有障碍物（任一格子有障碍物则拒绝交换）
	if is_blocked_cell(r1, c1) or is_blocked_cell(r2, c2):
		return false
	
	# 检查是否有锁定宝石（任一格子被锁定则拒绝交换）
	if not is_gem_playable(r1, c1) or not is_gem_playable(r2, c2):
		return false
	
	# 交换
	var temp: String = grid[r1][c1]
	grid[r1][c1] = grid[r2][c2]
	grid[r2][c2] = temp
	
	return true

# ========== 匹配检测（核心算法） ==========

## 查找所有匹配
## 返回 { gems, enhanced, rainbow, bomb }
## enhanced: 4连（十字爆炸），rainbow: 5+连（全屏同色），bomb: L/T形（3×3炸弹）
## 优先级：5连(彩虹) > L/T形(炸弹) > 4连(十字) > 3连(普通)
func find_matches() -> Dictionary:
	# 使用 Array + String key 来模拟 Set
	var matches_keys: Array = []
	var enhanced_matches: Array = []
	var rainbow_matches: Array = []
	var bomb_matches: Array = []
	
	# ===== 第一阶段：收集横向匹配分组 =====
	var h_groups: Array = []
	for r: int in range(rows):
		var c: int = 0
		while c < cols - 2:
			var gem_type: String = grid[r][c]
			if gem_type == "" or gem_type == null or is_blocked_cell(r, c) or not is_gem_playable(r, c):
				c += 1
				continue
			if not is_blocked_cell(r, c + 1) and not is_blocked_cell(r, c + 2) and is_gem_playable(r, c + 1) and is_gem_playable(r, c + 2) and grid[r][c + 1] == gem_type and grid[r][c + 2] == gem_type:
				var end: int = c + 2
				while end + 1 < cols and not is_blocked_cell(r, end + 1) and is_gem_playable(r, end + 1) and grid[r][end + 1] == gem_type:
					end += 1
				var length: int = end - c + 1
				var cells: Array = []
				for i: int in range(c, end + 1):
					cells.append({ "row": r, "col": i })
				h_groups.append({ "type": gem_type, "cells": cells, "length": length })
				for i: int in range(c, end + 1):
					_add_to_set(matches_keys, "%d,%d" % [r, i])
				c = end + 1
			else:
				c += 1
	
	# ===== 第二阶段：收集纵向匹配分组 =====
	var v_groups: Array = []
	for c: int in range(cols):
		var r: int = 0
		while r < rows - 2:
			var gem_type: String = grid[r][c]
			if gem_type == "" or gem_type == null or is_blocked_cell(r, c) or not is_gem_playable(r, c):
				r += 1
				continue
			if not is_blocked_cell(r + 1, c) and not is_blocked_cell(r + 2, c) and is_gem_playable(r + 1, c) and is_gem_playable(r + 2, c) and grid[r + 1][c] == gem_type and grid[r + 2][c] == gem_type:
				var end: int = r + 2
				while end + 1 < rows and not is_blocked_cell(end + 1, c) and is_gem_playable(end + 1, c) and grid[end + 1][c] == gem_type:
					end += 1
				var length: int = end - r + 1
				var cells: Array = []
				for i: int in range(r, end + 1):
					cells.append({ "row": i, "col": c })
				v_groups.append({ "type": gem_type, "cells": cells, "length": length })
				for i: int in range(r, end + 1):
					_add_to_set(matches_keys, "%d,%d" % [i, c])
				r = end + 1
			else:
				r += 1
	
	# ===== 第三阶段：分类 —— 5连→彩虹，4连→强化 =====
	for g: Dictionary in h_groups:
		if g["length"] >= 5:
			rainbow_matches.append({
				"type": g["type"],
				"direction": "horizontal",
				"length": g["length"],
				"matchCells": g["cells"]
			})
		elif g["length"] >= 4:
			var mid_col: int = (g["cells"][0]["col"] + g["cells"][g["cells"].size() - 1]["col"]) / 2
			enhanced_matches.append({
				"row": g["cells"][0]["row"],
				"col": mid_col,
				"type": g["type"],
				"direction": "horizontal",
				"length": g["length"],
				"allCells": g["cells"]
			})
	
	for g: Dictionary in v_groups:
		if g["length"] >= 5:
			rainbow_matches.append({
				"type": g["type"],
				"direction": "vertical",
				"length": g["length"],
				"matchCells": g["cells"]
			})
		elif g["length"] >= 4:
			var mid_row: int = (g["cells"][0]["row"] + g["cells"][g["cells"].size() - 1]["row"]) / 2
			enhanced_matches.append({
				"row": mid_row,
				"col": g["cells"][0]["col"],
				"type": g["type"],
				"direction": "vertical",
				"length": g["length"],
				"allCells": g["cells"]
			})
	
	# ===== 第四阶段：L/T形检测 —— 3连横+3连纵交叉同色 =====
	var h3: Array = []
	var v3: Array = []
	for g: Dictionary in h_groups:
		if g["length"] == 3:
			h3.append(g)
	for g: Dictionary in v_groups:
		if g["length"] == 3:
			v3.append(g)
	
	for hg: Dictionary in h3:
		for vg: Dictionary in v3:
			if hg["type"] != vg["type"]:
				continue
			# 找交叉点
			var h_set: Array = []
			for cell: Dictionary in hg["cells"]:
				h_set.append("%d,%d" % [cell["row"], cell["col"]])
			
			var intersection: Variant = null
			for vc: Dictionary in vg["cells"]:
				var key: String = "%d,%d" % [vc["row"], vc["col"]]
				if _set_has(h_set, key):
					intersection = vc
					break
			
			if intersection == null:
				continue
			
			# 判断 L形 或 T形
			var h_idx: int = -1
			var v_idx: int = -1
			for i: int in range(hg["cells"].size()):
				var cell: Dictionary = hg["cells"][i]
				if cell["row"] == intersection["row"] and cell["col"] == intersection["col"]:
					h_idx = i
					break
			for i: int in range(vg["cells"].size()):
				var cell: Dictionary = vg["cells"][i]
				if cell["row"] == intersection["row"] and cell["col"] == intersection["col"]:
					v_idx = i
					break
			
			# L形：交叉点在横纵两臂的端点（index 0 或 2）
			# T形：交叉点在其中一臂的端点、另一臂的中间（index 1）
			var shape: String
			if (h_idx == 0 or h_idx == 2) and (v_idx == 0 or v_idx == 2):
				shape = "L"
			else:
				shape = "T"
			
			# 合并所有格子（去重）
			var all_cells: Array = hg["cells"].duplicate(true)
			for vc: Dictionary in vg["cells"]:
				var key: String = "%d,%d" % [vc["row"], vc["col"]]
				if not _set_has(h_set, key):
					all_cells.append(vc)
			
			bomb_matches.append({
				"row": intersection["row"],
				"col": intersection["col"],
				"type": hg["type"],
				"shape": shape,
				"matchCells": all_cells
			})
	
	# ===== 转换为统一结果 =====
	var result: Array = []
	for key: String in matches_keys:
		var parts: Array = key.split(",")
		var rr: int = parts[0].to_int()
		var cc: int = parts[1].to_int()
		result.append({ "row": rr, "col": cc, "type": grid[rr][cc] })
	
	return {
		"gems": result,
		"enhanced": enhanced_matches,
		"rainbow": rainbow_matches,
		"bomb": bomb_matches
	}

## 兼容旧调用：返回纯宝石数组
func find_matches_flat() -> Array:
	return find_matches()["gems"]

## 将字符串添加到模拟 Set（Array）
func _add_to_set(set_arr: Array, key: String) -> void:
	if not _set_has(set_arr, key):
		set_arr.append(key)

## 检查模拟 Set 是否包含 key
func _set_has(set_arr: Array, key: String) -> bool:
	return set_arr.has(key)

# ========== 特殊爆炸范围计算 ==========

## 计算十字爆炸范围（以强化宝石为中心，上下左右各延伸到边界或2格，共5格核心）
## 返回 [{ row, col, type }] 会被十字爆炸波及的格子（不含强化宝石本身）
## 注意：原JS注释说"共5格核心"，但代码中 offsets 是8个方向（上下左右各2格）
func get_cross_explosion_positions(center_row: int, center_col: int) -> Array:
	var positions: Array = []
	# 注意：原JS是上下左右各2格，共8格（不含中心）
	# 不是上下左右各1格的5格
	var offsets: Array = [
		[-2, 0], [-1, 0], [1, 0], [2, 0],  # 上下（各2格）
		[0, -2], [0, -1], [0, 1], [0, 2]   # 左右（各2格）
	]
	for offset: Array in offsets:
		var nr: int = center_row + offset[0]
		var nc: int = center_col + offset[1]
		if nr >= 0 and nr < rows and nc >= 0 and nc < cols:
			if is_blocked_cell(nr, nc) or not is_gem_playable(nr, nc):
				continue
			var gem_type: String = grid[nr][nc]
			if gem_type != "" and gem_type != null:
				positions.append({ "row": nr, "col": nc, "type": gem_type })
	return positions

## 计算3×3炸弹爆炸范围（以炸弹宝石为中心，不含中心点本身）
## 返回 [{ row, col, type }] 会被炸弹波及的格子
func get_bomb_explosion_positions(center_row: int, center_col: int) -> Array:
	var positions: Array = []
	for dr: int in range(-1, 2):
		for dc: int in range(-1, 2):
			if dr == 0 and dc == 0:
				continue  # 中心点由普通消除处理
			var nr: int = center_row + dr
			var nc: int = center_col + dc
			if nr >= 0 and nr < rows and nc >= 0 and nc < cols:
				if is_blocked_cell(nr, nc) or not is_gem_playable(nr, nc):
					continue
				var gem_type: String = grid[nr][nc]
				if gem_type != "" and gem_type != null:
					positions.append({ "row": nr, "col": nc, "type": gem_type })
	return positions

## 对炸弹范围内障碍物造成一次伤害
func damage_bomb_obstacles(center_row: int, center_col: int) -> Array:
	return damage_obstacles_for_resolution([], [{"row": center_row, "col": center_col}])

## 获取棋盘上所有指定类型宝石的位置（用于彩虹消除）
## exclude_set: Array of "row,col" 字符串，这些位置的宝石已在普通消除中移除，不再重复
func get_rainbow_positions(match_type: String, exclude_set: Array) -> Array:
	var positions: Array = []
	for r: int in range(rows):
		for c: int in range(cols):
			var key: String = "%d,%d" % [r, c]
			if grid[r][c] == match_type and is_gem_playable(r, c) and not _set_has(exclude_set, key):
				positions.append({ "row": r, "col": c, "type": match_type })
	return positions

# ========== 消除处理 ==========

## 消除匹配的宝石，返回按类型统计的消除数
func remove_matches(matches: Array, damage_adjacent_obstacles: bool = true) -> Dictionary:
	var counts: Dictionary = {}
	for m: Dictionary in matches:
		var gem_type: String = m.get("type", "")
		if gem_type == "" or gem_type == null:
			continue
		if not counts.has(gem_type):
			counts[gem_type] = 0
		counts[gem_type] += 1
		grid[m["row"]][m["col"]] = ""
	if damage_adjacent_obstacles:
		damage_obstacles_for_resolution(matches)
	return counts

## 消除十字爆炸波及的格子（设置grid为null），返回按类型统计
func remove_explosion_gems(positions: Array, damage_adjacent_obstacles: bool = true) -> Dictionary:
	var counts: Dictionary = {}
	for p: Dictionary in positions:
		var gem_type: String = grid[p["row"]][p["col"]]
		if gem_type == "" or gem_type == null:
			continue
		if not counts.has(gem_type):
			counts[gem_type] = 0
		counts[gem_type] += 1
		grid[p["row"]][p["col"]] = ""
	if damage_adjacent_obstacles:
		damage_obstacles_for_resolution(positions)
	return counts

# ========== 重力下落 ==========

## 重力下落 + 填充新宝石
## 返回 movements[] 记录移动信息，用于动画
func apply_gravity() -> Array:
	var movements: Array = []

	for c: int in range(cols):
		# Rocks split a column into independent gravity segments. A lock belongs
		# to its gem, so it moves with the gem instead of acting as a barrier.
		var segment_bottom: int = rows - 1
		while segment_bottom >= 0:
			if is_blocked_cell(segment_bottom, c):
				segment_bottom -= 1
				continue

			var segment_top: int = segment_bottom
			while segment_top >= 0 and not is_blocked_cell(segment_top, c):
				segment_top -= 1

			var gems: Array[Dictionary] = []
			for r: int in range(segment_bottom, segment_top, -1):
				if grid[r][c] == "" or grid[r][c] == null:
					continue
				var lock_data = null
				if is_locked(r, c):
					lock_data = locked_gems[r][c].duplicate(true)
				gems.append({"type": str(grid[r][c]), "fromRow": r, "lock": lock_data})

			for r: int in range(segment_top + 1, segment_bottom + 1):
				grid[r][c] = ""
				locked_gems[r][c] = null

			var write_pos: int = segment_bottom
			for gem: Dictionary in gems:
				grid[write_pos][c] = gem["type"]
				locked_gems[write_pos][c] = gem["lock"]
				var from_row: int = int(gem["fromRow"])
				if from_row != write_pos:
					movements.append({
						"type": gem["type"], "fromRow": from_row, "toRow": write_pos,
						"col": c, "locked": gem["lock"] != null
					})
				write_pos -= 1

			# Only the top-open segment can receive new gems; rocks block refill below.
			if segment_top < 0:
				var empty_count: int = write_pos - segment_top
				for r: int in range(write_pos, segment_top, -1):
					var new_type: String = _random_gem_type()
					grid[r][c] = new_type
					locked_gems[r][c] = null
					movements.append({
						"type": new_type, "fromRow": r - empty_count, "toRow": r,
						"col": c, "isNew": true, "locked": false
					})

			segment_bottom = segment_top - 1

	return movements

# ========== 死局检测与洗牌 ==========

## 检查棋盘是否有可用移动（死局检测）
func has_valid_moves() -> bool:
	for r: int in range(rows):
		for c: int in range(cols):
			# 跳过障碍物格子、空格子和锁定宝石
			if is_blocked_cell(r, c) or is_empty(r, c) or not is_gem_playable(r, c):
				continue
			
			# 尝试向右交换（目标格子也不能是锁定的）
			if c + 1 < cols and not is_blocked_cell(r, c + 1) and is_gem_playable(r, c + 1):
				swap(r, c, r, c + 1)
				if find_matches()["gems"].size() > 0:
					swap(r, c, r, c + 1)  # 换回来
					return true
				swap(r, c, r, c + 1)  # 换回来
			
			# 尝试向下交换（目标格子也不能是锁定的）
			if r + 1 < rows and not is_blocked_cell(r + 1, c) and is_gem_playable(r + 1, c):
				swap(r, c, r + 1, c)
				if find_matches()["gems"].size() > 0:
					swap(r, c, r + 1, c)
					return true
				swap(r, c, r + 1, c)
	return false

## 重新洗牌。优先保留当前宝石集合；无法得到合法棋盘时再有界重建。
## 返回 { success, attempts, regenerated }，任何路径都不会递归。
func shuffle() -> Dictionary:
	var types: Array = []
	var positions: Array = []
	
	for r: int in range(rows):
		for c: int in range(cols):
			if not is_blocked_cell(r, c) and is_gem_playable(r, c) and grid[r][c] != "" and grid[r][c] != null:
				types.append(grid[r][c])
				positions.append({ "r": r, "c": c })
	
	if positions.size() < 2:
		return {"success": false, "attempts": 0, "regenerated": false}

	var original_types := types.duplicate()
	for attempt in range(1, SHUFFLE_MAX_ATTEMPTS + 1):
		var candidate := original_types.duplicate()
		_shuffle_array(candidate)
		_place_types(positions, candidate)
		if _is_playable_grid():
			return {"success": true, "attempts": attempt, "regenerated": false}

	# 当前颜色分布可能不可能同时满足“无现成匹配”和“存在合法移动”。
	# 使用新颜色有界重建；仍失败时恢复原棋盘并显式返回失败。
	for regenerate_attempt in range(1, SHUFFLE_REGENERATE_ATTEMPTS + 1):
		_regenerate_positions_without_matches(positions)
		if _is_playable_grid():
			return {
				"success": true,
				"attempts": SHUFFLE_MAX_ATTEMPTS + regenerate_attempt,
				"regenerated": true
			}

	_place_types(positions, original_types)
	return {
		"success": false,
		"attempts": SHUFFLE_MAX_ATTEMPTS + SHUFFLE_REGENERATE_ATTEMPTS,
		"regenerated": true
	}


func _place_types(positions: Array, types: Array) -> void:
	for i in range(mini(positions.size(), types.size())):
		grid[positions[i]["r"]][positions[i]["c"]] = types[i]


func _regenerate_positions_without_matches(positions: Array) -> void:
	for pos: Dictionary in positions:
		var row := int(pos["r"])
		var col := int(pos["c"])
		var gem_type := _random_gem_type()
		for _attempt in range(100):
			gem_type = _random_gem_type()
			if not _would_match(row, col, gem_type):
				break
		grid[row][col] = gem_type


func _is_playable_grid() -> bool:
	return find_matches().get("gems", []).is_empty() and has_valid_moves()

# ========== 调试/工具方法 ==========

## 打印棋盘状态（调试用）
func print_board() -> void:
	var lines: Array = []
	for r: int in range(rows):
		var row_str: String = ""
		for c: int in range(cols):
			var gem: String = grid[r][c]
			if gem == "" or gem == null:
				row_str += "null "
			else:
				row_str += gem.substr(0, 3) + " "
		lines.append(row_str)
	print("\n".join(lines))

## 获取棋盘数据副本（用于调试/存档）
func get_grid_copy() -> Array:
	var copy: Array = []
	for r: int in range(rows):
		copy.append(grid[r].duplicate())
	return copy

## 设置棋盘数据（用于加载存档）
func set_grid_from_copy(copy: Array) -> void:
	grid = []
	for r: int in range(copy.size()):
		grid.append(copy[r].duplicate())
