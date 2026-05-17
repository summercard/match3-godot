extends Node
## 存档管理器 - 从 js/core/storage.js 翻译
## 负责玩家数据、怪物Pokedex、队伍、道具、关卡进度、成就、签到、牧场等持久化
## Godot 单例模式：AutoLoad 注册，或用 static var instance
##
## 翻译要点：
## - 使用 ConfigFile 进行持久化存储（微信用 wx.setStorageSync JSON序列化）
## - ConfigFile 有多个 section：player/team/inventory/stageProgress/achievements/signIn/settings/ranch/tutorial/rewards
## - 经验公式：每级所需 = 100 + level * 20，总经验需计算到 level-1
## - 扫荡奖励 = (100 + 3*50)*0.8 = 160 金币，(100 + 3*20)*0.8 = 72 经验
## - 牧场挂机经验速率 = 2 + level * 0.5 每5分钟
## - 签到连续天数超过7天额外奖励 +20金币 +10经验

const ItemDB = preload("res://src/data/item_db.gd")
const StageDBScript = preload("res://src/data/stage_db.gd")
const AchievementDBScript = preload("res://src/data/achievement_db.gd")

# ========== 单例模式 ==========
static var instance: Node

func _enter_tree() -> void:
	instance = self

func _exit_tree() -> void:
	instance = null

# ========== ConfigFile 持久化 ==========
## 存储文件路径（相对于用户数据目录）
const SAVE_PATH: String = "user://save_game.cfg"

var _config: ConfigFile = null
var _dirty: bool = false

func _init() -> void:
	_config = ConfigFile.new()
	_load_config()

## 加载存档文件
func _load_config() -> void:
	var err: int = _config.load(SAVE_PATH)
	if err != OK:
		# 文件不存在或读取失败，使用默认空配置
		_config = ConfigFile.new()

## 保存到文件
func _save_config() -> void:
	if _dirty:
		var err: int = _config.save(SAVE_PATH)
		if err == OK:
			_dirty = false
		else:
			push_warning("[SaveManager] 保存失败: %d" % err)

## 标记为脏，等待批量保存
func _mark_dirty() -> void:
	_dirty = true

## 通用 set_value（自动脏标记）
func _set_value(section: String, key: String, value) -> void:
	_config.set_value(section, key, value)
	_mark_dirty()

## 通用 get_value（带默认值）
func _get_value(section: String, key: String, default_val = null):
	if _config.has_section_key(section, key):
		return _config.get_value(section, key)
	return default_val

## 通用 erase
func _erase_key(section: String, key: String) -> void:
	_config.erase(section, key)
	_mark_dirty()

## 立即保存（外部调用）
func flush() -> void:
	_save_config()

func clear_all_data() -> bool:
	_config = ConfigFile.new()
	_dirty = true
	_save_config()
	return true

# ========== 玩家数据（section: player） ==========

## 获取玩家数据（带默认值）
## JS: loadPlayer()
func get_player() -> Dictionary:
	return _get_value("player", "data", {
		"level": 1,
		"gold": 0,
		"gems": 0,
		"exp": 0,
		"team": ["monster_001", "monster_002", "monster_003"],
		"captured": ["monster_001", "monster_002", "monster_003"],
		"stageProgress": { "chapter": 1, "stage": 1 },
		"pokedex": {}
	})

func load_player() -> Dictionary:
	return get_player()

## 保存玩家数据
## JS: savePlayer(playerData)
func save_player(player_data: Dictionary) -> bool:
	_set_value("player", "data", player_data)
	_save_config()
	return true

## 增加金币
## JS: addGold(amount)
func add_gold(amount: int) -> bool:
	print("[SaveManager] add_gold called: amount=", amount)
	var player: Dictionary = get_player()
	print("[SaveManager] player before: gold=", player.get("gold", 0))
	player["gold"] = player.get("gold", 0) + amount
	print("[SaveManager] player after: gold=", player.get("gold", 0))
	save_player(player)
	return true

## 花费金币（返回是否成功）
## JS: spendGold(amount)
func spend_gold(amount: int) -> bool:
	var player: Dictionary = get_player()
	if player.get("gold", 0) < amount:
		return false
	player["gold"] = player.get("gold", 0) - amount
	save_player(player)
	return true

## 增加玩家经验（使用 get_exp_for_level 递增公式：100 + level * 20）
## JS: addPlayerExp(amount)
func add_player_exp(amount: int) -> bool:
	var player: Dictionary = get_player()
	player["exp"] = player.get("exp", 0) + amount
	var current_level: int = player.get("level", 1)
	while player["exp"] >= get_exp_for_level(current_level):
		player["exp"] -= get_exp_for_level(current_level)
		current_level += 1
	player["level"] = current_level
	save_player(player)
	return true

## 增加钻石（gems）
func add_gems(amount: int) -> bool:
	var player: Dictionary = get_player()
	player["gems"] = player.get("gems", 0) + amount
	save_player(player)
	return true

# ========== 怪物成长系统 Pokedex（section: player.data.pokedex） ==========
## pokedex 结构: { [monsterId]: { level: 1, exp: 0, nature: "brave" }, ... }

## 初始化怪物的pokedex数据（收服/获得新怪物时调用）
## JS: initMonsterPokedex(monsterId, natureId)
func init_monster_pokedex(monster_id: String, nature_id: String = "") -> Dictionary:
	var player: Dictionary = get_player()
	if not player.has("pokedex"):
		player["pokedex"] = {}

	if not player["pokedex"].has(monster_id):
		player["pokedex"][monster_id] = {
			"level": 1,
			"exp": 0,
			"nature": nature_id if nature_id != "" else NatureDB.random_nature()
		}
		save_player(player)
	elif nature_id != "" and not player["pokedex"][monster_id].has("nature"):
		# 补丁：为旧数据补充性格
		player["pokedex"][monster_id]["nature"] = nature_id
		save_player(player)

	return player["pokedex"][monster_id]

## 获取怪物当前等级
## JS: getMonsterLevel(monsterId)
func get_monster_level(monster_id: String) -> int:
	var player: Dictionary = get_player()
	var entry: Dictionary = player.get("pokedex", {}).get(monster_id, {})
	return entry.get("level", 1)

## 获取怪物当前经验值
## JS: getMonsterExp(monsterId)
func get_monster_exp(monster_id: String) -> int:
	var player: Dictionary = get_player()
	var entry: Dictionary = player.get("pokedex", {}).get(monster_id, {})
	return entry.get("exp", 0)

## 获取怪物性格ID
## JS: getMonsterNature(monsterId)
func get_monster_nature(monster_id: String) -> String:
	var player: Dictionary = get_player()
	var entry: Dictionary = player.get("pokedex", {}).get(monster_id, {})
	return entry.get("nature", "")

## 获取怪物pokedex完整数据
## JS: getMonsterPokedex(monsterId)
func get_monster_pokedex(monster_id: String) -> Dictionary:
	var player: Dictionary = get_player()
	var pokedex: Dictionary = player.get("pokedex", {})
	return pokedex.get(monster_id, {})

## 获取已收服的怪物ID列表
## JS: getCapturedMonsters()
func get_captured_monsters() -> Array:
	var player: Dictionary = get_player()
	return player.get("captured", [])

## 计算升级所需经验（每级所需经验递增）
## JS: _getExpForLevel(level)
## 公式: 100 + level * 20
static func get_exp_for_level(level: int) -> int:
	return 100 + level * 20

## 获取当前等级总经验要求（用于经验条显示）
## JS: _getTotalExpForLevel(level)
static func get_total_exp_for_level(level: int) -> int:
	var total: int = 0
	for l: int in range(1, level):
		total += get_exp_for_level(l)
	return total

## 增加怪物经验，可触发升级
## JS: addMonsterExp(monsterId, expGained)
## 返回: { leveledUp: bool, newLevel: int, oldLevel: int, expGained: int, currentExp: int }
func add_monster_exp(monster_id: String, exp_gained: int) -> Dictionary:
	var player: Dictionary = get_player()
	if not player.has("pokedex"):
		player["pokedex"] = {}
	if not player["pokedex"].has(monster_id):
		player["pokedex"][monster_id] = { "level": 1, "exp": 0 }

	var entry: Dictionary = player["pokedex"][monster_id]
	var old_level: int = entry.get("level", 1)
	var old_exp: int = entry.get("exp", 0)

	entry["exp"] = old_exp + exp_gained

	# 检查升级
	while true:
		var needed: int = get_exp_for_level(entry.get("level", 1))
		if entry["exp"] >= needed:
			entry["exp"] -= needed
			entry["level"] = entry.get("level", 1) + 1
		else:
			break

	save_player(player)

	return {
		"leveledUp": entry.get("level", 1) > old_level,
		"newLevel": entry.get("level", 1),
		"oldLevel": old_level,
		"expGained": exp_gained,
		"currentExp": entry.get("exp", 0)
	}

# ========== 队伍编成（section: team） ==========
## 队伍数据结构: { leader: 'monster_001', member1: 'monster_002', member2: 'monster_003' }

## 默认初始队伍
func _get_default_team() -> Dictionary:
	return {
		"leader": "monster_001",
		"member1": "monster_002",
		"member2": "monster_003"
	}

## 保存队伍
## JS: saveTeam(teamData)
func save_team(team_data: Dictionary) -> bool:
	_set_value("team", "data", {
		"leader": team_data.get("leader", null),
		"member1": team_data.get("member1", null),
		"member2": team_data.get("member2", null)
	})
	_save_config()
	return true

## 加载队伍
## JS: loadTeam()
func load_team() -> Dictionary:
	var team: Variant = _get_value("team", "data", null)
	if not (team is Dictionary):
		var default_team: Dictionary = _get_default_team()
		save_team(default_team)
		return default_team.duplicate(true)
	return (team as Dictionary).duplicate(true)

## 检查怪物是否在队伍中
## JS: isMonsterInTeam(monsterId)
func is_monster_in_team(monster_id: String) -> bool:
	var team: Dictionary = load_team()
	return team.get("leader") == monster_id or team.get("member1") == monster_id or team.get("member2") == monster_id

## 计算队伍总战力
## JS: calcTeamPower()
func calc_team_power() -> int:
	var team: Dictionary = load_team()
	var power: int = 0

	for slot: String in ["leader", "member1", "member2"]:
		var id: String = team.get(slot, "")
		if id != "" and MonsterDb.has_monster(id):
			var level: int = get_monster_level(id) if get_monster_pokedex(id).size() > 0 else 1
			var stats: Dictionary = MonsterDb.get_monster_stats(id, level)
			if not stats.is_empty():
				power += stats.get("hp", 0) + stats.get("atk", 0) + stats.get("def", 0) + stats.get("spd", 0)

	return power

# ========== 道具背包（section: inventory） ==========
## 背包数据结构: { 'capture_ball': 3, 'exp_potion': 1, ... }

## 保存背包
## JS: saveInventory(inventory)
func save_inventory(inventory: Dictionary) -> bool:
	_set_value("inventory", "data", inventory)
	_save_config()
	return true

## 加载背包
## JS: loadInventory()
func load_inventory() -> Dictionary:
	return _get_value("inventory", "data", {})

## 增加道具
## JS: addItem(itemId, count)
func add_item(item_id: String, count: int = 1) -> bool:
	var inv: Dictionary = load_inventory()
	inv[item_id] = inv.get(item_id, 0) + count
	return save_inventory(inv)

## 使用道具（返回是否成功）
## JS: useItem(itemId, count)
func use_item(item_id: String, count: int = 1) -> bool:
	var inv: Dictionary = load_inventory()
	if not inv.has(item_id) or inv[item_id] < count:
		return false
	inv[item_id] -= count
	if inv[item_id] <= 0:
		inv.erase(item_id)
	return save_inventory(inv)

## 获取道具数量
## JS: getItemCount(itemId)
func get_item_count(item_id: String) -> int:
	var inv: Dictionary = load_inventory()
	return inv.get(item_id, 0)

# ========== 关卡进度与扫荡（section: stageProgress） ==========
## 关卡进度数据结构: { 'stage_1_1': { stars: 2, cleared: true }, ... }

## 保存关卡进度
## JS: saveStageProgress(stageId, stageData)
func save_stage_progress(stage_id: String, stage_data: Dictionary) -> bool:
	var all: Dictionary = load_stage_progress()
	all[stage_id] = stage_data
	_set_value("stageProgress", "data", all)
	_save_config()
	return true

## 加载所有关卡进度
## JS: loadStageProgress()
func load_stage_progress() -> Dictionary:
	return _get_value("stageProgress", "data", {})

## 保存关卡星级（只保留最高星级）
## JS: saveStageStars(stageId, stars)
func save_stage_stars(stage_id: String, stars: int) -> bool:
	var all: Dictionary = load_stage_progress()
	var prev: Dictionary = all.get(stage_id, {})
	var prev_stars: int = prev.get("stars", 0)
	all[stage_id] = {
		"stars": max(prev_stars, stars),
		"cleared": true
	}
	_set_value("stageProgress", "data", all)
	_save_config()
	return true

## 获取关卡星级
## JS: getStageStars(stageId)
func get_stage_stars(stage_id: String) -> int:
	var all: Dictionary = load_stage_progress()
	return all.get(stage_id, {}).get("stars", 0)

## 检查是否解锁扫荡（3星通关）
## JS: canSweep(stageId)
func can_sweep(stage_id: String) -> bool:
	return get_stage_stars(stage_id) >= 3

## 获取扫荡奖励（金币+经验）
## JS: getSweepReward(stageId)
## 扫荡奖励 = 正常战斗胜利奖励的80%
## 基础金币100 + 3星加成150，金币: (100 + 3*50) * 0.8 = 160
## 基础经验100 + 3星加成60，经验: (100 + 3*20) * 0.8 = 72
func get_sweep_reward(_stage_id: String) -> Dictionary:
	var gold: int = int((100 + 3 * 50) * 0.8)
	var exp: int = int((100 + 3 * 20) * 0.8)
	return { "gold": gold, "exp": exp }

## 执行扫荡
## JS: doSweep(stageId)
func do_sweep(stage_id: String) -> Dictionary:
	if not can_sweep(stage_id):
		return {}

	var reward: Dictionary = get_sweep_reward(stage_id)
	add_gold(reward["gold"])
	add_player_exp(reward["exp"])

	# 更新奖励统计
	var rewards: Dictionary = load_rewards()
	rewards["totalGoldEarned"] = rewards.get("totalGoldEarned", 0) + reward["gold"]
	rewards["totalItemsGained"] = rewards.get("totalItemsGained", 0)
	save_rewards(rewards)

	return reward

func get_stage_chapters() -> Array:
	var db := StageDBScript.new()
	return db.get_chapters()

func get_stage(stage_id: String) -> Dictionary:
	var db := StageDBScript.new()
	return db.get_stage(stage_id)

func roll_drop() -> String:
	return ItemDB.roll_drop()

# ========== 奖励记录（section: rewards） ==========
## 奖励数据结构: { lastRewardTime: timestamp, totalGoldEarned: 0, totalItemsGained: 0 }

## 保存奖励记录
## JS: saveRewards(rewardsData)
func save_rewards(rewards_data: Dictionary) -> bool:
	_set_value("rewards", "data", rewards_data)
	_save_config()
	return true

## 加载奖励记录
## JS: loadRewards()
func load_rewards() -> Dictionary:
	return _get_value("rewards", "data", {
		"totalGoldEarned": 0,
		"totalItemsGained": 0,
		"battleCount": 0,
		"captureCount": 0
	})

# ========== 成就系统（section: achievements） ==========
## 成就数据结构: { unlockedIds: [], unlockedDates: {}, stats: {} }

## 保存成就
## JS: saveAchievements(data)
func save_achievements(data: Dictionary) -> bool:
	_set_value("achievements", "data", data)
	_save_config()
	return true

## 加载成就
## JS: loadAchievements()
func load_achievements() -> Dictionary:
	return _get_value("achievements", "data", {
		"unlockedIds": [],
		"unlockedDates": {},
		"stats": {}
	})

func add_achievement_progress(progress_key: String, amount: int = 1) -> Dictionary:
	var data: Dictionary = load_achievements()
	var stats: Dictionary = data.get("stats", {})
	stats[progress_key] = int(stats.get(progress_key, 0)) + amount
	data["stats"] = stats
	_refresh_achievement_unlocks(data)
	save_achievements(data)
	return data

func set_achievement_stat(progress_key: String, value: int) -> Dictionary:
	var data: Dictionary = load_achievements()
	var stats: Dictionary = data.get("stats", {})
	stats[progress_key] = maxi(int(stats.get(progress_key, 0)), value)
	data["stats"] = stats
	_refresh_achievement_unlocks(data)
	save_achievements(data)
	return data

func _refresh_achievement_unlocks(data: Dictionary) -> void:
	var stats: Dictionary = data.get("stats", {})
	var unlocked_ids: Array = data.get("unlockedIds", [])
	var unlocked_dates: Dictionary = data.get("unlockedDates", {})
	var today := Time.get_date_string_from_system()

	for ach: Dictionary in AchievementDBScript.ACHIEVEMENTS:
		var ach_id: String = ach.get("id", "")
		var progress_key: String = ach.get("progressKey", "")
		var target: int = int(ach.get("target", 1))
		if ach_id.is_empty() or progress_key.is_empty():
			continue
		if int(stats.get(progress_key, 0)) >= target and not unlocked_ids.has(ach_id):
			unlocked_ids.append(ach_id)
			unlocked_dates[ach_id] = today

	data["unlockedIds"] = unlocked_ids
	data["unlockedDates"] = unlocked_dates

# ========== 每日签到（section: signIn） ==========
## 签到数据结构: { lastSignInDate: '2026-05-13', consecutiveDays: 3, totalDays: 10 }

## 保存签到数据
## JS: saveSignInData(data)
func save_sign_in_data(data: Dictionary) -> bool:
	_set_value("signIn", "data", data)
	_save_config()
	return true

## 加载签到数据
## JS: loadSignInData()
func load_sign_in_data() -> Dictionary:
	return _get_value("signIn", "data", {
		"lastSignInDate": null,
		"consecutiveDays": 0,
		"totalDays": 0
	})

## 检查今天是否已签到
## JS: canSignInToday()
func can_sign_in_today() -> bool:
	var data: Dictionary = load_sign_in_data()
	if data.get("lastSignInDate", null) == null:
		return true
	var today: String = _get_date_string(Time.get_date_string_from_system())
	return data["lastSignInDate"] != today

## 执行签到，返回奖励
## JS: doSignIn()
func do_sign_in() -> Dictionary:
	if not can_sign_in_today():
		return {}

	var data: Dictionary = load_sign_in_data()
	var today: String = _get_date_string(Time.get_date_string_from_system())
	var yesterday: String = _get_date_string(_get_date_minus_days(1))

	# 检查是否连续
	if data.get("lastSignInDate", "") == yesterday:
		data["consecutiveDays"] = data.get("consecutiveDays", 0) + 1
	else:
		data["consecutiveDays"] = 1

	data["lastSignInDate"] = today
	data["totalDays"] = data.get("totalDays", 0) + 1
	save_sign_in_data(data)

	# 发放奖励
	var reward: Dictionary = get_sign_in_reward(data["consecutiveDays"])
	add_gold(reward["gold"])
	add_player_exp(reward["exp"])

	return reward

## 获取签到奖励（根据连续签到天数）
## JS: getSignInReward(consecutiveDays)
## 连续天数超过7天额外奖励 +20金币 +10经验
func get_sign_in_reward(consecutive_days: int) -> Dictionary:
	var base_gold: int = 50
	var base_exp: int = 30

	# 连续7天重置循环，但给予额外奖励
	if consecutive_days > 7:
		return {
			"gold": base_gold + consecutive_days * 5 + 20,
			"exp": base_exp + consecutive_days * 2 + 10
		}

	return {
		"gold": base_gold + consecutive_days * 5,
		"exp": base_exp + consecutive_days * 2
	}

## 获取当前日期字符串
## JS: _getDateString(date)
func _get_date_string(date_str: String) -> String:
	# date_str 格式: "2026-05-16" (YYYY-MM-DD)
	var parts: Array = date_str.split("-")
	if parts.size() >= 3:
		return "%s-%s-%s" % [parts[0], parts[1], parts[2]]
	return date_str

## 获取多少天前的日期字符串（正确处理跨月）
func _get_date_minus_days(days: int) -> String:
	var dt: Dictionary = Time.get_datetime_dict_from_system()
	var unix_now: int = Time.get_unix_time_from_datetime_dict(dt)
	var unix_past: int = unix_now - (days * 24 * 60 * 60)
	var dt_past: Dictionary = Time.get_datetime_dict_from_unix_time(unix_past)
	return "%04d-%02d-%02d" % [dt_past["year"], dt_past["month"], dt_past["day"]]

# ========== 设置（section: settings） ==========
## 设置数据结构: { soundOn: true, musicOn: true, version: 'v0.1.0' }

## 保存设置
## JS: saveSettings(data)
func save_settings(data: Dictionary) -> bool:
	_set_value("settings", "data", data)
	_save_config()
	return true

## 加载设置
## JS: loadSettings()
func load_settings() -> Dictionary:
	return _get_value("settings", "data", {
		"soundOn": true,
		"musicOn": true,
		"version": "v0.1.0"
	})

# ========== 牧场系统（section: ranch） ==========
## 牧场数据结构: { slots: [{ monsterId, placedAt }, ...], unlockedSlots: 3 }

## 获取牧场状态
## JS: getRanchState()
func get_ranch_state() -> Dictionary:
	return _get_value("ranch", "data", {
		"slots": [
			{ "monsterId": null, "placedAt": null },
			{ "monsterId": null, "placedAt": null },
			{ "monsterId": null, "placedAt": null }
		],
		"unlockedSlots": 3
	})

## 设置牧场状态
## JS: setRanchState(state)
func set_ranch_state(state: Dictionary) -> bool:
	_set_value("ranch", "data", state)
	_save_config()
	return true

## 计算挂机经验速率（每5分钟）
## JS: getIdleExpRate(monsterId)
## 公式: 2 + level * 0.5
func get_idle_exp_rate(monster_id: String) -> float:
	var level: int = get_monster_level(monster_id) if get_monster_pokedex(monster_id).size() > 0 else 1
	return 2.0 + level * 0.5

## 收取单只怪物的挂机经验
## JS: collectIdleExp(monsterId)
func collect_idle_exp(monster_id: String) -> float:
	var ranch: Dictionary = get_ranch_state()
	var slot: Variant = null

	for s: Dictionary in ranch.get("slots", []):
		if s.get("monsterId") == monster_id:
			slot = s
			break

	if slot == null or slot.get("placedAt", 0.0) == 0.0:
		return 0.0

	var now_ts: float = Time.get_unix_time_from_system()
	var elapsed_sec: float = now_ts - slot.get("placedAt", 0.0)
	var intervals: int = int(elapsed_sec / (5.0 * 60.0))
	if intervals <= 0:
		return 0.0

	var rate: float = get_idle_exp_rate(monster_id)
	var exp: float = intervals * rate

	# 增加经验
	add_monster_exp(monster_id, int(exp))

	# 重置放置时间（使用 Unix 时间戳）
	slot["placedAt"] = now_ts
	set_ranch_state(ranch)

	return exp

# ========== 新手引导（section: tutorial） ==========
## 引导进度数据结构: { completed: bool, currentStep: int }

## 保存引导进度
## JS: saveTutorialProgress(step)
func save_tutorial_progress(step: int) -> bool:
	_set_value("tutorial", "data", {
		"completed": step >= 5,
		"currentStep": step
	})
	_save_config()
	return true

## 加载引导进度
## JS: loadTutorialProgress()
func load_tutorial_progress() -> Dictionary:
	return _get_value("tutorial", "data", {
		"completed": false,
		"currentStep": 0
	})

# ========== 静态工具方法 ==========

## 获取玩家当前等级
static func get_player_level() -> int:
	if instance != null:
		return instance.get_player().get("level", 1)
	return 1

## 获取玩家金币
static func get_player_gold() -> int:
	if instance != null:
		return instance.get_player().get("gold", 0)
	return 0

## 获取玩家钻石
static func get_player_gems() -> int:
	if instance != null:
		return instance.get_player().get("gems", 0)
	return 0
