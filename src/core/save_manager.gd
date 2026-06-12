extends Node
## 存档管理器 - 从 js/core/storage.js 翻译
## 负责玩家数据、精灵Pokedex、队伍、道具、关卡进度、成就、签到、牧场等持久化
## Godot 单例模式：AutoLoad 注册，或用 static var instance
##
## 翻译要点：
## - 使用 ConfigFile 进行持久化存储（微信用 wx.setStorageSync JSON序列化）
## - ConfigFile 有多个 section：player/team/inventory/stageProgress/achievements/signIn/settings/ranch/tutorial/rewards
## - 经验公式：每级所需 = 80 + level * 10，总经验需计算到 level-1
## - 扫荡奖励 = 关卡基础奖励 × 星级倍率 × 0.8
## - 牧场挂机经验速率 = 5 + level 每5分钟，累计最多8小时
## - 签到连续天数超过7天额外奖励 +20金币 +10经验

const ItemDB = preload("res://src/data/item_db.gd")
const StageDBScript = preload("res://src/data/stage_db.gd")
const AchievementDBScript = preload("res://src/data/achievement_db.gd")
const RewardRulesScript = preload("res://src/battle/reward_rules.gd")
const GrowthRulesScript = preload("res://src/core/growth_rules.gd")
const SocialRulesScript = preload("res://src/core/social_rules.gd")
const EvolutionRulesScript = preload("res://src/core/evolution_rules.gd")
const RanchCareRulesScript = preload("res://src/core/ranch_care_rules.gd")

# ========== 单例模式 ==========
static var instance: Node

func _enter_tree() -> void:
	instance = self

func _exit_tree() -> void:
	instance = null

# ========== ConfigFile 持久化 ==========
## 存储文件路径（相对于用户数据目录）
const SAVE_PATH: String = "user://save_game.cfg"
const RANCH_IDLE_INTERVAL_MS: float = 5.0 * 60.0 * 1000.0
const RANCH_IDLE_MAX_MS: float = 8.0 * 60.0 * 60.0 * 1000.0

var _config: ConfigFile = null
var _dirty: bool = false

func _init() -> void:
	_config = ConfigFile.new()
	_load_config()

## 加载存档文件
func _load_config() -> void:
	var err: int = _config.load(_get_save_path())
	if err != OK:
		# 文件不存在或读取失败，使用默认空配置
		_config = ConfigFile.new()

## 保存到文件
func _save_config() -> void:
	if _dirty:
		var err: int = _config.save(_get_save_path())
		if err == OK:
			_dirty = false
		else:
			push_warning("[SaveManager] 保存失败: %d" % err)

func _get_save_path() -> String:
	var test_path := OS.get_environment("MATCH3_SAVE_PATH")
	if not test_path.is_empty():
		return test_path
	for arg: String in OS.get_cmdline_args():
		if arg.begins_with("res://tests/") or arg.contains("/tests/"):
			return "user://test_save_game.cfg"
	return SAVE_PATH

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
		"monster_pool": [],
		"monsterPoolVersion": 0,
		"stageProgress": { "chapter": 1, "stage": 1 },
		"pokedex": {}
	})

func load_player() -> Dictionary:
	return get_player()

func has_player_data() -> bool:
	return _config.has_section_key("player", "data")

## 保存玩家数据
## JS: savePlayer(playerData)
func save_player(player_data: Dictionary) -> bool:
	_set_value("player", "data", player_data)
	_save_config()
	return true

## 增加金币
## JS: addGold(amount)
func add_gold(amount: int) -> bool:
	var player: Dictionary = get_player()
	player["gold"] = player.get("gold", 0) + amount
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

## 增加玩家经验（使用 get_exp_for_level 递增公式：80 + level * 10）
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

# ========== 精灵池与旧 Pokedex 兼容 ==========

func _ensure_monster_pool_migrated() -> void:
	var player: Dictionary = get_player()
	if int(player.get("monsterPoolVersion", 0)) >= 1 and player.get("monster_pool", []) is Array:
		var normalized_existing := MonsterPool.normalize_pool(player.get("monster_pool", []))
		if normalized_existing != player.get("monster_pool", []):
			player["monster_pool"] = normalized_existing
			save_player(player)
		return

	var pool: Array = []
	var monster_to_instance := {}
	var pokedex: Dictionary = player.get("pokedex", {})
	var captured: Array = player.get("captured", [])
	if captured.is_empty():
		captured = MonsterPool.DEFAULT_STARTERS.duplicate()

	for raw_id in captured:
		var monster_id := str(raw_id)
		if not MonsterDb.has_monster(monster_id):
			continue
		var old_entry: Dictionary = pokedex.get(monster_id, {})
		var instance := MonsterPool.create_instance(monster_id, {
			"level": int(old_entry.get("level", 1)),
			"exp": int(old_entry.get("exp", 0)),
			"nature": str(old_entry.get("nature", NatureDB.random_nature())),
			"source": "migration",
		})
		pool.append(instance)
		if not monster_to_instance.has(monster_id):
			monster_to_instance[monster_id] = instance.get("instanceId", "")

	var old_team: Dictionary = _get_value("team", "data", {
		"leader": "monster_001",
		"member1": "monster_002",
		"member2": "monster_003"
	})
	var new_team := {}
	for slot in ["leader", "member1", "member2"]:
		var ref_id := str(old_team.get(slot, ""))
		new_team[slot] = _migrate_monster_ref_to_instance(ref_id, pool, monster_to_instance)

	var old_ranch: Dictionary = _get_value("ranch", "data", {})
	var old_slots: Array = old_ranch.get("slots", [])
	var new_slots: Array = []
	for slot_data in old_slots:
		if not slot_data is Dictionary:
			new_slots.append({"instance_id": null, "placed_at": null})
			continue
		var slot: Dictionary = slot_data
		var ref_id := str(slot.get("instance_id", slot.get("monster_id", slot.get("monsterId", ""))))
		var instance_id: Variant = _migrate_monster_ref_to_instance(ref_id, pool, monster_to_instance)
		new_slots.append({
			"instance_id": instance_id,
			"placed_at": _normalize_ranch_timestamp_ms(slot.get("placed_at", slot.get("placedAt", null)))
		})
	var unlocked_slots := int(old_ranch.get("unlocked_slots", old_ranch.get("unlockedSlots", 3)))
	while new_slots.size() < unlocked_slots:
		new_slots.append({"instance_id": null, "placed_at": null})

	player["monster_pool"] = MonsterPool.normalize_pool(pool)
	player["monsterPoolVersion"] = 1
	_set_value("player", "data", player)
	_set_value("team", "data", new_team)
	_set_value("ranch", "data", {"slots": new_slots, "unlocked_slots": unlocked_slots})
	_save_config()

func _migrate_monster_ref_to_instance(ref_id: String, pool: Array, monster_to_instance: Dictionary) -> Variant:
	if ref_id.is_empty():
		return null
	if MonsterPool.find_index(pool, ref_id) >= 0:
		return ref_id
	if monster_to_instance.has(ref_id):
		return monster_to_instance[ref_id]
	if MonsterDb.has_monster(ref_id):
		var instance := MonsterPool.create_instance(ref_id, {"source": "migration"})
		pool.append(instance)
		monster_to_instance[ref_id] = instance.get("instanceId", "")
		return instance.get("instanceId", "")
	return null

func get_monster_pool() -> Array:
	_ensure_monster_pool_migrated()
	var player: Dictionary = get_player()
	return MonsterPool.normalize_pool(player.get("monster_pool", [])).duplicate(true)

func save_monster_pool(pool: Array) -> bool:
	var player: Dictionary = get_player()
	player["monster_pool"] = MonsterPool.normalize_pool(pool)
	player["monsterPoolVersion"] = 1
	_sync_legacy_monster_fields(player)
	return save_player(player)

func add_monster_instance(monster_id: String, options: Dictionary = {}) -> Dictionary:
	if not MonsterDb.has_monster(monster_id):
		return {}
	var pool := get_monster_pool()
	var instance := MonsterPool.create_instance(monster_id, options)
	pool.append(instance)
	save_monster_pool(pool)
	return instance.duplicate(true)

func get_monster_instance(instance_id: String) -> Dictionary:
	var pool := get_monster_pool()
	return MonsterPool.get_instance(pool, instance_id)

func update_monster_instance(instance_id: String, patch: Dictionary) -> bool:
	var pool := get_monster_pool()
	if not MonsterPool.update_instance(pool, instance_id, patch):
		return false
	return save_monster_pool(pool)

func remove_monster_instance(instance_id: String) -> bool:
	var pool := get_monster_pool()
	if not MonsterPool.remove_instance(pool, instance_id):
		return false
	var team := load_team()
	for slot in ["leader", "member1", "member2"]:
		if team.get(slot) == instance_id:
			team[slot] = null
	save_team(team)
	var ranch := get_ranch_state()
	for slot: Dictionary in ranch.get("slots", []):
		if slot.get("instance_id") == instance_id:
			slot["instance_id"] = null
			slot["placed_at"] = null
	set_ranch_state(ranch)
	return save_monster_pool(pool)

func get_owned_monsters(filters: Dictionary = {}) -> Array:
	var pool := get_monster_pool()
	var result: Array = []
	for instance: Dictionary in pool:
		if filters.has("monsterId") and str(instance.get("monsterId", "")) != str(filters.get("monsterId", "")):
			continue
		if filters.has("nature") and str(instance.get("nature", "")) != str(filters.get("nature", "")):
			continue
		if filters.has("minLevel") and int(instance.get("level", 1)) < int(filters.get("minLevel", 1)):
			continue
		result.append(instance.duplicate(true))
	return result

func get_owned_species_ids() -> Array:
	return MonsterPool.get_owned_species_ids(get_monster_pool())

func get_instances_by_monster_id(monster_id: String) -> Array:
	return MonsterPool.get_instances_by_monster_id(get_monster_pool(), monster_id)

func get_instance_level(instance_id: String) -> int:
	return int(get_monster_instance(instance_id).get("level", 1))

func get_instance_exp(instance_id: String) -> int:
	return int(get_monster_instance(instance_id).get("exp", 0))

func get_instance_nature(instance_id: String) -> String:
	return str(get_monster_instance(instance_id).get("nature", ""))

func get_instance_stats(instance_id: String) -> Dictionary:
	return MonsterPool.get_instance_stats(get_monster_instance(instance_id))

func add_instance_exp(instance_id: String, exp_gained: int) -> Dictionary:
	var pool := get_monster_pool()
	var idx := MonsterPool.find_index(pool, instance_id)
	if idx < 0:
		return {"leveledUp": false, "newLevel": 1, "oldLevel": 1, "expGained": exp_gained, "currentExp": 0}
	var instance: Dictionary = pool[idx]
	var result := MonsterPool.add_instance_exp(instance, exp_gained)
	pool[idx] = instance
	save_monster_pool(pool)
	return result

func get_team_reference_level() -> int:
	var team_instances := get_team_instances()
	var highest := 1
	for instance: Dictionary in team_instances:
		highest = maxi(highest, int(instance.get("level", 1)))
	return highest

func get_instance_catchup_state(instance_id: String, reference_level: int = -1) -> Dictionary:
	var instance := get_monster_instance(instance_id)
	if instance.is_empty():
		return GrowthRulesScript.get_catchup_state(1, 1)
	var ref_level := get_team_reference_level() if reference_level < 0 else reference_level
	return GrowthRulesScript.get_catchup_state(int(instance.get("level", 1)), ref_level)

func calc_instance_battle_exp(instance_id: String, base_exp: int, reference_level: int = -1) -> int:
	var instance := get_monster_instance(instance_id)
	if instance.is_empty():
		return maxi(0, base_exp)
	var ref_level := get_team_reference_level() if reference_level < 0 else reference_level
	return GrowthRulesScript.calc_catchup_exp(base_exp, int(instance.get("level", 1)), ref_level)

func evolve_instance(instance_id: String) -> Dictionary:
	var pool := get_monster_pool()
	var idx := MonsterPool.find_index(pool, instance_id)
	if idx < 0:
		return {"ok": false, "reason": "not_found"}
	var instance: Dictionary = pool[idx]
	var before := instance.duplicate(true)
	var result := MonsterPool.evolve_instance(instance)
	if bool(result.get("ok", false)):
		var report := EvolutionRulesScript.build_report(before, instance)
		var history: Array = instance.get("evolutionHistory", [])
		history.append(EvolutionRulesScript.make_history_entry(report))
		instance["evolutionHistory"] = history.slice(maxi(0, history.size() - 8), history.size())
		instance["evolutionInsight"] = {}
		instance["evolutionCount"] = int(instance.get("evolutionCount", 0)) + 1
		result["evolutionReport"] = report
	pool[idx] = instance
	save_monster_pool(pool)
	return result

func get_team_instances() -> Array:
	var team := load_team()
	var result: Array = []
	for slot in ["leader", "member1", "member2"]:
		var instance_id := str(team.get(slot, ""))
		if instance_id.is_empty():
			continue
		var instance := get_monster_instance(instance_id)
		if not instance.is_empty():
			result.append(instance)
	return result

func get_team_battle_stats() -> Array:
	var team := load_team()
	var result: Array = []
	for slot in ["leader", "member1", "member2"]:
		var instance_id := str(team.get(slot, ""))
		if instance_id.is_empty():
			continue
		var unit := MonsterService.get_battle_unit_from_instance(instance_id, self)
		if not unit.is_empty():
			result.append(unit)
	return result

func _resolve_instance_id(ref_id: String) -> String:
	if ref_id.is_empty():
		return ""
	var pool := get_monster_pool()
	if MonsterPool.find_index(pool, ref_id) >= 0:
		return ref_id
	var instance := MonsterPool.get_first_instance_by_monster_id(pool, ref_id)
	return str(instance.get("instanceId", ""))

func _sync_legacy_monster_fields(player: Dictionary) -> void:
	var pool: Array = player.get("monster_pool", [])
	var captured := MonsterPool.get_owned_species_ids(pool)
	var pokedex := {}
	for monster_id in captured:
		var instance := MonsterPool.get_first_instance_by_monster_id(pool, str(monster_id))
		if not instance.is_empty():
			pokedex[str(monster_id)] = {
				"level": int(instance.get("level", 1)),
				"exp": int(instance.get("exp", 0)),
				"nature": str(instance.get("nature", ""))
			}
	player["captured"] = captured
	player["pokedex"] = pokedex

## 初始化精灵的兼容 pokedex 数据（新逻辑会保证至少有一个实例）
func init_monster_pokedex(monster_id: String, nature_id: String = "") -> Dictionary:
	var instance := MonsterPool.get_first_instance_by_monster_id(get_monster_pool(), monster_id)
	if instance.is_empty():
		instance = add_monster_instance(monster_id, {"nature": nature_id if nature_id != "" else NatureDB.random_nature(), "source": "legacy"})
	elif nature_id != "" and str(instance.get("nature", "")).is_empty():
		update_monster_instance(str(instance.get("instanceId", "")), {"nature": nature_id})
		instance = get_monster_instance(str(instance.get("instanceId", "")))
	return {"level": int(instance.get("level", 1)), "exp": int(instance.get("exp", 0)), "nature": str(instance.get("nature", ""))}

func get_monster_level(monster_id: String) -> int:
	var instance_id := _resolve_instance_id(monster_id)
	return get_instance_level(instance_id) if not instance_id.is_empty() else 1

func get_monster_exp(monster_id: String) -> int:
	var instance_id := _resolve_instance_id(monster_id)
	return get_instance_exp(instance_id) if not instance_id.is_empty() else 0

func get_monster_nature(monster_id: String) -> String:
	var instance_id := _resolve_instance_id(monster_id)
	return get_instance_nature(instance_id) if not instance_id.is_empty() else ""

func get_monster_pokedex(monster_id: String) -> Dictionary:
	return init_monster_pokedex(monster_id) if MonsterDb.has_monster(monster_id) else {}

func get_captured_monsters() -> Array:
	return get_owned_species_ids()

## 计算升级所需经验（每级所需经验递增）
## JS: _getExpForLevel(level)
## 公式: 80 + level * 10
static func get_exp_for_level(level: int) -> int:
	return 80 + level * 10

## 获取当前等级总经验要求（用于经验条显示）
## JS: _getTotalExpForLevel(level)
static func get_total_exp_for_level(level: int) -> int:
	var total: int = 0
	for l: int in range(1, level):
		total += get_exp_for_level(l)
	return total

## 增加精灵经验，可触发升级
## JS: addMonsterExp(monsterId, expGained)
## 返回: { leveledUp: bool, newLevel: int, oldLevel: int, expGained: int, currentExp: int }
func add_monster_exp(monster_id: String, exp_gained: int) -> Dictionary:
	var instance_id := _resolve_instance_id(monster_id)
	if instance_id.is_empty() and MonsterDb.has_monster(monster_id):
		var instance := add_monster_instance(monster_id, {"source": "legacy"})
		instance_id = str(instance.get("instanceId", ""))
	if instance_id.is_empty():
		return {"leveledUp": false, "newLevel": 1, "oldLevel": 1, "expGained": exp_gained, "currentExp": 0}
	return add_instance_exp(instance_id, exp_gained)

# ========== 队伍编成（section: team） ==========
## 队伍数据结构: { leader: 'monster_001', member1: 'monster_002', member2: 'monster_003' }

## 默认初始队伍
func _get_default_team() -> Dictionary:
	_ensure_monster_pool_migrated()
	var pool := get_monster_pool()
	return {
		"leader": str(pool[0].get("instanceId", "")) if pool.size() > 0 else null,
		"member1": str(pool[1].get("instanceId", "")) if pool.size() > 1 else null,
		"member2": str(pool[2].get("instanceId", "")) if pool.size() > 2 else null
	}

## 保存队伍
## JS: saveTeam(teamData)
func save_team(team_data: Dictionary) -> bool:
	_ensure_monster_pool_migrated()
	_set_value("team", "data", {
		"leader": _resolve_team_ref(team_data.get("leader", null)),
		"member1": _resolve_team_ref(team_data.get("member1", null)),
		"member2": _resolve_team_ref(team_data.get("member2", null))
	})
	_save_config()
	return true

## 加载队伍
## JS: loadTeam()
func load_team() -> Dictionary:
	_ensure_monster_pool_migrated()
	var team: Variant = _get_value("team", "data", null)
	if not (team is Dictionary):
		var default_team: Dictionary = _get_default_team()
		save_team(default_team)
		return default_team.duplicate(true)
	var normalized := {
		"leader": _resolve_team_ref((team as Dictionary).get("leader", null)),
		"member1": _resolve_team_ref((team as Dictionary).get("member1", null)),
		"member2": _resolve_team_ref((team as Dictionary).get("member2", null))
	}
	if normalized != team:
		save_team(normalized)
	return normalized.duplicate(true)

func _resolve_team_ref(value: Variant) -> Variant:
	if value == null:
		return null
	var ref_id := str(value)
	if ref_id.is_empty():
		return null
	var instance_id := _resolve_instance_id(ref_id)
	return instance_id if not instance_id.is_empty() else null

## 检查精灵是否在队伍中
## JS: isMonsterInTeam(monsterId)
func is_monster_in_team(monster_id: String) -> bool:
	var team: Dictionary = load_team()
	if team.values().has(monster_id):
		return true
	for instance_id in team.values():
		if instance_id == null:
			continue
		var instance := get_monster_instance(str(instance_id))
		if str(instance.get("monsterId", "")) == monster_id:
			return true
	return false

func is_instance_in_team(instance_id: String) -> bool:
	return load_team().values().has(instance_id)

## 计算队伍总战力
## JS: calcTeamPower()
func calc_team_power() -> int:
	var team: Dictionary = load_team()
	var power: int = 0

	for slot: String in ["leader", "member1", "member2"]:
		var id: String = str(team.get(slot, ""))
		if id.is_empty():
			continue
		var stats: Dictionary = get_instance_stats(id)
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
	var progress: Dictionary = _normalize_stage_progress(_get_value("stageProgress", "data", {}))
	var legacy_progress := _stage_progress_from_legacy_player()
	var changed := false
	for stage_id: String in legacy_progress.keys():
		if not progress.has(stage_id):
			progress[stage_id] = legacy_progress[stage_id]
			changed = true
	if changed:
		_set_value("stageProgress", "data", progress)
		_save_config()
	return progress

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

func is_stage_cleared(stage_id: String) -> bool:
	var all: Dictionary = load_stage_progress()
	var data: Dictionary = all.get(stage_id, {})
	return bool(data.get("cleared", false)) or int(data.get("stars", 0)) > 0

func is_stage_unlocked(stage_id: String) -> bool:
	return bool(get_stage_unlock_state(stage_id).get("unlocked", false))

func get_stage_unlock_state(stage_id: String) -> Dictionary:
	var required_id := _required_stage_for_unlock(stage_id)
	if required_id == "__missing__":
		return {
			"unlocked": false,
			"requiredStageId": "",
			"requiredStageName": "",
			"reason": "stage_not_found"
		}
	if required_id.is_empty() or is_stage_cleared(required_id):
		return {
			"unlocked": true,
			"requiredStageId": required_id,
			"requiredStageName": _stage_name(required_id),
			"reason": ""
		}
	return {
		"unlocked": false,
		"requiredStageId": required_id,
		"requiredStageName": _stage_name(required_id),
		"reason": "clear_required_stage"
	}

## 检查是否解锁扫荡（3星通关）
## JS: canSweep(stageId)
func can_sweep(stage_id: String) -> bool:
	return get_stage_stars(stage_id) >= 3

## 获取扫荡奖励（金币+经验）
## JS: getSweepReward(stageId)
## 扫荡奖励 = 正常战斗胜利奖励的80%
func get_sweep_reward(stage_id: String) -> Dictionary:
	var stage: Dictionary = get_stage(stage_id)
	var stage_rewards: Dictionary = stage.get("rewards", {})
	return RewardRulesScript.calc_sweep_rewards(stage_rewards, get_stage_stars(stage_id))

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

func _required_stage_for_unlock(stage_id: String) -> String:
	var chapters := get_stage_chapters()
	var previous_chapter_gate := ""
	for chapter: Dictionary in chapters:
		var previous_main_stage := previous_chapter_gate
		for stage: Dictionary in chapter.get("stages", []):
			var current_id := str(stage.get("id", ""))
			if current_id == stage_id:
				return previous_main_stage
			if str(stage.get("type", "normal")) != "elite":
				previous_main_stage = current_id
		if not previous_main_stage.is_empty():
			previous_chapter_gate = previous_main_stage
	return "__missing__"

func _stage_name(stage_id: String) -> String:
	if stage_id.is_empty():
		return ""
	var stage := get_stage(stage_id)
	return str(stage.get("name", stage_id))

func _normalize_stage_progress(raw_progress) -> Dictionary:
	var normalized: Dictionary = {}
	if not raw_progress is Dictionary:
		return normalized
	var raw: Dictionary = raw_progress
	for raw_stage_id in raw.keys():
		var stage_id := str(raw_stage_id)
		var raw_entry = raw.get(raw_stage_id, {})
		if raw_entry is Dictionary:
			var entry: Dictionary = raw_entry
			var stars := clampi(int(entry.get("stars", 0)), 0, 3)
			normalized[stage_id] = entry.duplicate(true)
			normalized[stage_id]["stars"] = stars
			normalized[stage_id]["cleared"] = bool(entry.get("cleared", false)) or stars > 0
		elif raw_entry is bool and bool(raw_entry):
			normalized[stage_id] = {"stars": 1, "cleared": true}
		elif raw_entry is int or raw_entry is float:
			var stars := clampi(int(raw_entry), 0, 3)
			normalized[stage_id] = {"stars": stars, "cleared": stars > 0}
	return normalized

func _stage_progress_from_legacy_player() -> Dictionary:
	if not _config.has_section_key("player", "data"):
		return {}
	var player: Dictionary = _get_value("player", "data", {})
	var legacy = player.get("stageProgress", {})
	if not legacy is Dictionary:
		return {}
	var chapter_num := int(legacy.get("chapter", 1))
	var next_stage_num := int(legacy.get("stage", 1))
	if chapter_num <= 1 and next_stage_num <= 1:
		return {}

	var migrated: Dictionary = {}
	var chapters := get_stage_chapters()
	for chapter_index: int in range(chapters.size()):
		var chapter_no := chapter_index + 1
		var chapter: Dictionary = chapters[chapter_index]
		for stage: Dictionary in chapter.get("stages", []):
			if str(stage.get("type", "normal")) == "elite":
				continue
			var stage_no := _stage_number_from_id(str(stage.get("id", "")))
			if chapter_no < chapter_num or (chapter_no == chapter_num and stage_no > 0 and stage_no < next_stage_num):
				migrated[str(stage.get("id", ""))] = {"stars": 1, "cleared": true}
	return migrated

func _stage_number_from_id(stage_id: String) -> int:
	var parts := stage_id.split("_")
	if parts.size() < 3:
		return 0
	var number_text := str(parts[2])
	var digits := ""
	for i: int in range(number_text.length()):
		var ch := number_text.substr(i, 1)
		if ch.is_valid_int():
			digits += ch
		else:
			break
	return int(digits) if not digits.is_empty() else 0

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
	# 通知 AudioManager 同步 soundOn / musicOn
	var am := get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("_sync_with_settings"):
		am.call("_sync_with_settings")
	return true

## 加载设置
## JS: loadSettings()
func load_settings() -> Dictionary:
	return _get_value("settings", "data", {
		"soundOn": true,
		"musicOn": true,
		"capture": {
			"autoCapture": false,
			"equippedItem": "",
			"equippedBattleItems": []
		},
		"version": "v0.1.0"
	})

func load_capture_settings() -> Dictionary:
	var settings: Dictionary = load_settings()
	var capture: Dictionary = settings.get("capture", {})
	return {
		"autoCapture": bool(capture.get("autoCapture", false)),
		"equippedItem": str(capture.get("equippedItem", "")),
		"equippedBattleItems": capture.get("equippedBattleItems", [])
	}

func save_capture_settings(capture_settings: Dictionary) -> bool:
	var settings: Dictionary = load_settings()
	var capture: Dictionary = settings.get("capture", {})
	if capture_settings.has("autoCapture"):
		capture["autoCapture"] = bool(capture_settings.get("autoCapture", false))
	if capture_settings.has("equippedItem"):
		capture["equippedItem"] = str(capture_settings.get("equippedItem", ""))
	if capture_settings.has("equippedBattleItems"):
		capture["equippedBattleItems"] = capture_settings.get("equippedBattleItems", [])
	settings["capture"] = capture
	return save_settings(settings)

# ========== 牧场系统（section: ranch） ==========
## 牧场数据结构: { slots: [{ instance_id, placed_at }, ...], unlocked_slots: 5, care_focus_instance_id, social_places: [{ slot_a, slot_b, started_at, last_result }] }

## 获取牧场状态
## JS: getRanchState()
func get_ranch_state() -> Dictionary:
	_ensure_monster_pool_migrated()
	var state: Dictionary = _get_value("ranch", "data", {
		"slots": [
			{ "instance_id": null, "placed_at": null },
			{ "instance_id": null, "placed_at": null },
			{ "instance_id": null, "placed_at": null },
			{ "instance_id": null, "placed_at": null },
			{ "instance_id": null, "placed_at": null }
			],
			"unlocked_slots": 5,
		"social_places": [
			{ "slot_a": null, "slot_b": null, "started_at": null, "last_result": {} }
		],
		"care_focus_instance_id": null
	})
	var normalized := _normalize_ranch_state(state)
	if normalized != state:
		set_ranch_state(normalized)
	return normalized

## 设置牧场状态
## JS: setRanchState(state)
func set_ranch_state(state: Dictionary) -> bool:
	_ensure_monster_pool_migrated()
	_set_value("ranch", "data", _normalize_ranch_state(state))
	_save_config()
	return true

func _normalize_ranch_state(state: Dictionary) -> Dictionary:
	var normalized: Dictionary = {
		"slots": [],
		"unlocked_slots": int(state.get("unlocked_slots", state.get("unlockedSlots", 3))),
		"social_places": SocialRulesScript.normalize_places(state.get("social_places", state.get("socialPlaces", [])), 1),
		"care_focus_instance_id": null
	}
	var slots: Array = state.get("slots", [])
	var focus_ref := str(state.get("care_focus_instance_id", state.get("careFocusInstanceId", "")))
	var focus_id := _resolve_instance_id(focus_ref)
	for slot_data in slots:
		normalized["slots"].append(_normalize_ranch_slot(slot_data))
	while normalized["slots"].size() < normalized["unlocked_slots"]:
		normalized["slots"].append({ "instance_id": null, "placed_at": null })
	var normalized_places: Array = normalized["social_places"]
	for place_index in normalized_places.size():
		var place: Dictionary = normalized_places[place_index]
		var removed_ranch_monster := false
		for social_slot in ["slot_a", "slot_b"]:
			var instance_id := str(place.get(social_slot, ""))
			if _ranch_slots_contain_instance(normalized["slots"], instance_id):
				place[social_slot] = null
				removed_ranch_monster = true
		if removed_ranch_monster:
			place["started_at"] = null
		normalized_places[place_index] = place
	normalized["social_places"] = normalized_places
	if _ranch_slots_contain_instance(normalized["slots"], focus_id):
		normalized["care_focus_instance_id"] = focus_id
	return normalized

func is_instance_in_ranch(instance_id: String) -> bool:
	return _ranch_slots_contain_instance(get_ranch_state().get("slots", []), instance_id)

func _ranch_slots_contain_instance(slots: Array, instance_id: String) -> bool:
	if instance_id.is_empty():
		return false
	for slot: Dictionary in slots:
		if slot.get("instance_id") == instance_id:
			return true
	return false

func _social_places_contain_instance(places: Array, instance_id: String) -> bool:
	if instance_id.is_empty():
		return false
	for place: Dictionary in places:
		if place.get("slot_a") == instance_id or place.get("slot_b") == instance_id:
			return true
	return false

func _normalize_ranch_slot(slot_data: Variant) -> Dictionary:
	if not slot_data is Dictionary:
		return { "instance_id": null, "placed_at": null }
	var slot: Dictionary = slot_data
	var ref_id := str(slot.get("instance_id", slot.get("monster_id", slot.get("monsterId", ""))))
	var instance_id := _resolve_instance_id(ref_id)
	return {
		"instance_id": instance_id if not instance_id.is_empty() else null,
		"placed_at": _normalize_ranch_timestamp_ms(slot.get("placed_at", slot.get("placedAt", null)))
	}

func _normalize_ranch_timestamp_ms(value: Variant) -> Variant:
	if value == null:
		return null
	var timestamp := float(value)
	if timestamp <= 0.0:
		return null
	if timestamp < 100000000000.0:
		return timestamp * 1000.0
	return timestamp

## 计算挂机经验速率（每5分钟）
## JS: getIdleExpRate(monsterId)
## 公式: 5 + level，保证前期挂机也有可见成长反馈
func get_idle_exp_rate(monster_id: String) -> float:
	var instance_id := _resolve_instance_id(monster_id)
	if instance_id.is_empty():
		return RanchCareRulesScript.calc_base_rate(1)
	return float(get_ranch_care_state(instance_id).get("rate", RanchCareRulesScript.calc_base_rate(get_instance_level(instance_id))))

func get_idle_exp_rate_for_instance(instance_id: String) -> float:
	return get_idle_exp_rate(instance_id)

func get_ranch_care_focus() -> String:
	return str(get_ranch_state().get("care_focus_instance_id", ""))

func set_ranch_care_focus(instance_id: String) -> bool:
	if get_monster_instance(instance_id).is_empty():
		return false
	var ranch := get_ranch_state()
	var slots: Array = ranch.get("slots", [])
	if not _ranch_slots_contain_instance(slots, instance_id):
		return false
	ranch["care_focus_instance_id"] = instance_id
	return set_ranch_state(ranch)

func clear_ranch_care_focus() -> bool:
	var ranch := get_ranch_state()
	ranch["care_focus_instance_id"] = null
	return set_ranch_state(ranch)

func get_ranch_care_state(instance_id: String) -> Dictionary:
	var instance := get_monster_instance(instance_id)
	if instance.is_empty():
		return RanchCareRulesScript.calc_state(1, 1, 0, false)
	var ranch := get_ranch_state()
	var occupied_count := 0
	for slot: Dictionary in ranch.get("slots", []):
		if slot.get("instance_id", null) != null:
			occupied_count += 1
	var focus_id := str(ranch.get("care_focus_instance_id", ""))
	return RanchCareRulesScript.calc_state(
		int(instance.get("level", 1)),
		get_team_reference_level(),
		occupied_count,
		focus_id == instance_id
	)

## 收取单只精灵的挂机经验
## JS: collectIdleExp(monsterId)
func collect_idle_exp(monster_id: String) -> float:
	var instance_id := _resolve_instance_id(monster_id)
	if instance_id.is_empty():
		return 0.0
	return collect_idle_exp_for_instance(instance_id)

func collect_idle_exp_for_instance(instance_id: String) -> float:
	var ranch: Dictionary = get_ranch_state()
	var slot: Variant = null

	for s: Dictionary in ranch.get("slots", []):
		if s.get("instance_id") == instance_id:
			slot = s
			break

	if slot == null or slot.get("placed_at", 0.0) == 0.0:
		return 0.0

	var now_ms: float = Time.get_unix_time_from_system() * 1000.0
	var elapsed_ms: float = minf(now_ms - float(slot.get("placed_at", 0.0)), RANCH_IDLE_MAX_MS)
	var intervals: int = int(elapsed_ms / RANCH_IDLE_INTERVAL_MS)
	if intervals <= 0:
		return 0.0

	var rate: float = get_idle_exp_rate_for_instance(instance_id)
	var exp: float = intervals * rate

	# 增加经验
	add_instance_exp(instance_id, int(exp))

	# 重置放置时间（毫秒时间戳）
	slot["placed_at"] = now_ms
	set_ranch_state(ranch)

	return exp

func place_instance_in_ranch(instance_id: String, slot_index: int) -> bool:
	var ranch := get_ranch_state()
	var slots: Array = ranch.get("slots", [])
	if slot_index < 0 or slot_index >= slots.size() or get_monster_instance(instance_id).is_empty():
		return false
	if _social_places_contain_instance(ranch.get("social_places", []), instance_id):
		return false
	for slot: Dictionary in slots:
		if slot.get("instance_id") == instance_id:
			slot["instance_id"] = null
			slot["placed_at"] = null
	var target: Dictionary = slots[slot_index]
	target["instance_id"] = instance_id
	target["placed_at"] = Time.get_unix_time_from_system() * 1000.0
	ranch["slots"] = slots
	return set_ranch_state(ranch)

func remove_instance_from_ranch(instance_id: String) -> bool:
	var ranch := get_ranch_state()
	var changed := false
	for slot: Dictionary in ranch.get("slots", []):
		if slot.get("instance_id") == instance_id:
			slot["instance_id"] = null
			slot["placed_at"] = null
			changed = true
	for place: Dictionary in ranch.get("social_places", []):
		if place.get("slot_a") == instance_id:
			place["slot_a"] = null
			place["started_at"] = null
			changed = true
		if place.get("slot_b") == instance_id:
			place["slot_b"] = null
			place["started_at"] = null
			changed = true
	if ranch.get("care_focus_instance_id", null) == instance_id:
		ranch["care_focus_instance_id"] = null
		changed = true
	return set_ranch_state(ranch) if changed else true

func assign_social_slot(place_index: int, social_slot: String, instance_id: String) -> bool:
	var ranch := get_ranch_state()
	var places: Array = ranch.get("social_places", [])
	if place_index < 0 or place_index >= places.size() or get_monster_instance(instance_id).is_empty():
		return false
	if social_slot != "slot_a" and social_slot != "slot_b":
		return false
	if _ranch_slots_contain_instance(ranch.get("slots", []), instance_id):
		return false
	var place: Dictionary = places[place_index]
	if place.get("started_at", null) != null:
		return false
	if place.get("slot_a") == instance_id:
		place["slot_a"] = null
	if place.get("slot_b") == instance_id:
		place["slot_b"] = null
	place[social_slot] = instance_id
	places[place_index] = place
	ranch["social_places"] = places
	return set_ranch_state(ranch)

func clear_social_slot(place_index: int, social_slot: String) -> bool:
	var ranch := get_ranch_state()
	var places: Array = ranch.get("social_places", [])
	if place_index < 0 or place_index >= places.size():
		return false
	if social_slot != "slot_a" and social_slot != "slot_b":
		return false
	var place: Dictionary = places[place_index]
	if place.get("started_at", null) != null:
		return false
	place[social_slot] = null
	places[place_index] = place
	ranch["social_places"] = places
	return set_ranch_state(ranch)

func cycle_social_place(place_index: int) -> bool:
	var ranch := get_ranch_state()
	var places: Array = ranch.get("social_places", [])
	if place_index < 0 or place_index >= places.size():
		return false
	var place: Dictionary = places[place_index]
	if place.get("started_at", null) != null:
		return false
	place["place_id"] = SocialRulesScript.next_place_id(str(place.get("place_id", "meadow_yard")))
	place["last_result"] = {}
	places[place_index] = place
	ranch["social_places"] = places
	return set_ranch_state(ranch)

func start_social(place_index: int) -> Dictionary:
	var ranch := get_ranch_state()
	var places: Array = ranch.get("social_places", [])
	if place_index < 0 or place_index >= places.size():
		return {"ok": false, "reason": "place_not_found"}
	var place: Dictionary = places[place_index]
	if not SocialRulesScript.can_start(place):
		return {"ok": false, "reason": "need_two_monsters"}
	place["started_at"] = Time.get_unix_time_from_system() * 1000.0
	place["last_result"] = {}
	places[place_index] = place
	ranch["social_places"] = places
	set_ranch_state(ranch)
	return {"ok": true, "place": place}

func collect_social(place_index: int) -> Dictionary:
	var ranch := get_ranch_state()
	var places: Array = ranch.get("social_places", [])
	if place_index < 0 or place_index >= places.size():
		return {"ok": false, "reason": "place_not_found"}
	var place: Dictionary = places[place_index]
	if not SocialRulesScript.is_ready(place):
		return {"ok": false, "reason": "not_ready", "progress": SocialRulesScript.progress(place)}
	var a_id := str(place.get("slot_a", ""))
	var b_id := str(place.get("slot_b", ""))
	var a := get_monster_instance(a_id)
	var b := get_monster_instance(b_id)
	if a.is_empty() or b.is_empty():
		return {"ok": false, "reason": "monster_not_found"}
	var result := SocialRulesScript.resolve(a, b, place)
	var exp_each := int(result.get("exp_each", 0))
	if exp_each > 0:
		add_instance_exp(a_id, exp_each)
		add_instance_exp(b_id, exp_each)
	_apply_social_memory(a_id, b_id, result)
	_apply_social_evolution_insight(a_id, result)
	_apply_social_memory(b_id, a_id, result)
	_apply_social_evolution_insight(b_id, result)
	var gold := int(result.get("gold", 0))
	if gold > 0:
		add_gold(gold)
	for item: Dictionary in result.get("items", []):
		add_item(str(item.get("id", "")), int(item.get("count", 1)))
	var applied_major := _apply_social_major_outcome(result)
	if not applied_major.is_empty():
		result["majorOutcome"] = applied_major
		if str(applied_major.get("type", "none")) == "erosion" and bool(applied_major.get("victimRemoved", false)):
			var victim_id := str(applied_major.get("victimInstanceId", ""))
			if str(place.get("slot_a", "")) == victim_id:
				place["slot_a"] = null
			if str(place.get("slot_b", "")) == victim_id:
				place["slot_b"] = null
	place["started_at"] = null
	place["last_result"] = result
	places[place_index] = place
	ranch["social_places"] = places
	set_ranch_state(ranch)
	return {"ok": true, "result": result}

func _apply_social_major_outcome(social_result: Dictionary) -> Dictionary:
	var major: Dictionary = social_result.get("majorOutcome", {})
	match str(major.get("type", "none")):
		"birth":
			return _apply_social_birth(major)
		"erosion":
			return _apply_social_erosion(major)
		_:
			return major

func _apply_social_birth(major: Dictionary) -> Dictionary:
	var applied := major.duplicate(true)
	var created: Array = []
	for raw_plan in major.get("childPlans", []):
		if not raw_plan is Dictionary:
			continue
		var plan: Dictionary = raw_plan
		var monster_id := str(plan.get("monsterId", ""))
		if monster_id.is_empty() or not MonsterDb.has_monster(monster_id):
			continue
		var child := add_monster_instance(monster_id, {
			"name": str(plan.get("name", "")),
			"level": 1,
			"exp": 0,
			"nature": str(plan.get("nature", "brave")),
			"gender": str(plan.get("gender", "")),
			"source": "social_birth",
			"lineage": plan.get("lineage", {}),
			"mutationTraits": plan.get("mutationTraits", [])
		})
		if not child.is_empty():
			created.append(child)
	applied["createdInstances"] = created
	applied["applied"] = not created.is_empty()
	return applied

func _apply_social_erosion(major: Dictionary) -> Dictionary:
	var applied := major.duplicate(true)
	applied["summary"] = "检测到侵蚀风险；默认保护已阻止自动吞噬。"
	applied["protected"] = true
	applied["requiresConfirmation"] = true
	applied["victimRemoved"] = false
	applied["applied"] = false
	return applied

func _apply_social_evolution_insight(instance_id: String, social_result: Dictionary) -> void:
	var instance := get_monster_instance(instance_id)
	if instance.is_empty():
		return
	var insight := EvolutionRulesScript.make_social_insight(instance, social_result)
	if insight.is_empty():
		return
	update_monster_instance(instance_id, {"evolutionInsight": insight})

func _apply_social_memory(instance_id: String, partner_id: String, social_result: Dictionary) -> void:
	var instance := get_monster_instance(instance_id)
	if instance.is_empty():
		return
	var profile: Dictionary = instance.get("socialProfile", {})
	profile["socialExp"] = int(profile.get("socialExp", 0)) + int(social_result.get("score", 0))
	profile["bondExp"] = int(profile.get("bondExp", 0)) + int(round(float(social_result.get("score", 0)) * 0.5))
	profile["lastPartnerId"] = partner_id
	profile["lastSocialTags"] = social_result.get("tags", []).duplicate(true)
	var memory: Dictionary = instance.get("bondMemory", {})
	var partners: Dictionary = memory.get("partners", {})
	var partner_memory: Dictionary = partners.get(partner_id, {})
	partner_memory["count"] = int(partner_memory.get("count", 0)) + 1
	partner_memory["bestScore"] = maxi(int(partner_memory.get("bestScore", 0)), int(social_result.get("score", 0)))
	partner_memory["lastLabel"] = str(social_result.get("label", "社交"))
	partner_memory["lastTags"] = social_result.get("tags", []).duplicate(true)
	partner_memory["relationLevel"] = int(social_result.get("relation_level", 1))
	partner_memory["relationLabel"] = str(social_result.get("relation_label", "初识"))
	partner_memory["placeId"] = str(social_result.get("place_id", "meadow_yard"))
	partner_memory["placeName"] = str(social_result.get("place_name", "草坪庭院"))
	var event: Dictionary = social_result.get("event", {})
	partner_memory["lastEventId"] = str(event.get("id", ""))
	partner_memory["lastEventName"] = str(event.get("name", ""))
	partner_memory["lastEventSummary"] = str(event.get("summary", ""))
	partner_memory["lastEventFlavor"] = str(event.get("flavor", ""))
	partner_memory["lastEventOutcome"] = str(event.get("outcome", event.get("impact", "")))
	partner_memory["lastEventHook"] = str(event.get("hook", ""))
	partners[partner_id] = partner_memory
	memory["partners"] = partners
	update_monster_instance(instance_id, {
		"socialProfile": profile,
		"bondMemory": memory
	})

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

func reset_tutorial_progress() -> bool:
	return save_tutorial_progress(0)

## 加载引导进度
## JS: loadTutorialProgress()
func load_tutorial_progress() -> Dictionary:
	return _get_value("tutorial", "data", {
		"completed": false,
		"currentStep": 0
	})

func has_tutorial_progress() -> bool:
	return _config.has_section_key("tutorial", "data")

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
