## 队长技能特效序列表。
## 每条 sequence 是可编辑的时间轴：start 为相对起播间隔（秒），duration 为播放时长。
## 系统边界：效果块定义视觉；时间轴定义节奏；播放器解析绑定；场景只排程和绘制；战斗只在受击起点结算。
## 新工程若没有层级、绑定、字段和测试入口规则，必须先建立文档与最小框架，不能直接在场景脚本硬编码单个技能。
class_name LeaderSkillVfxSequenceDb
extends RefCounted

const EFFECT_BLOCKS: Dictionary = {
	"release_a": {"layer": "release", "anchor": "caster", "kind": "block_release", "color": "#ffd166", "size": 26.0},
	"flight_b": {"layer": "flight", "anchor": "path", "kind": "block_flight", "color": "#ff7a45", "size": 18.0},
	"link_b": {"layer": "link", "anchor": "path", "kind": "block_link", "color": "#77c8ff", "size": 12.0},
	"hit_c": {"layer": "hit", "anchor": "target", "kind": "block_hit", "color": "#ffffff", "size": 30.0},
	"heal_c": {"layer": "hit", "anchor": "target", "kind": "block_hit", "color": "#63df85", "size": 30.0},
	"guard_c": {"layer": "hit", "anchor": "target", "kind": "block_hit", "color": "#62b7ff", "size": 32.0},
	"shadow_c": {"layer": "hit", "anchor": "target", "kind": "block_hit", "color": "#bc75ff", "size": 31.0},
	"thunder_c": {"layer": "hit", "anchor": "target", "kind": "block_hit", "color": "#73a5ff", "size": 31.0},
	# 火球术原型：两个飞行层共用同一个带朝向的弧线飞行节点。
	"fire_release_a": {"layer": "release", "anchor": "caster", "kind": "block_fire_release", "color": "#ff8a18", "size": 34.0, "particle_count": 7, "particle_spread": 30.0, "particle_seed": 11.0},
	"fireball_sprite_b": {"layer": "flight", "anchor": "path", "kind": "block_fireball_sprite", "color": "#fff0a0", "size": 22.0, "axis": "y_forward", "motion": "arc"},
	"fireball_trail_b": {"layer": "flight", "anchor": "path", "kind": "block_fireball_trail", "color": "#ff5418", "size": 12.0, "particle_mode": "trail_single", "motion": "arc", "particle_count": 8, "particle_step": 0.095, "particle_spread": 22.0, "particle_birth_range": 0.16, "particle_seed": 23.0},
	"fire_impact_c": {"layer": "hit", "anchor": "target", "kind": "block_fire_impact", "color": "#ff6a1a", "size": 38.0, "particle_count": 12, "particle_spread": 48.0, "particle_birth_range": 0.16, "particle_seed": 37.0},
	# 均衡技能改为绿色治疗：没有飞行节点，治疗光柱直接在受击目标上升起。
	"heal_release_a": {"layer": "release", "anchor": "caster", "kind": "block_heal_release", "color": "#54df7c", "size": 30.0, "particle_count": 6, "particle_spread": 26.0, "particle_seed": 51.0},
	"heal_rise_c": {"layer": "hit", "anchor": "target", "kind": "block_heal_rise", "color": "#63df85", "size": 30.0, "bar_height": 70.0, "bar_count": 3, "particle_count": 9, "particle_spread": 30.0, "particle_birth_range": 0.20, "particle_seed": 67.0},
	# 群体治疗：金色祝福从施放者发起，并在对方全体目标上同时落下治疗柱。
	"gold_heal_release_a": {"layer": "release", "anchor": "caster", "kind": "block_gold_heal_release", "color": "#ffd35a", "size": 34.0, "particle_count": 8, "particle_spread": 32.0, "particle_seed": 81.0},
	"gold_heal_all_c": {"layer": "hit", "anchor": "target", "target_scope": "all_targets", "target_group": "opponents", "kind": "block_gold_heal_rise", "color": "#ffd35a", "size": 32.0, "bar_height": 78.0, "bar_count": 2, "particle_count": 12, "particle_spread": 34.0, "particle_birth_range": 0.24, "particle_seed": 97.0},
	# 疾风：不发射飞行物，先锁定一条直线路径，再在直线周围播放持续抖动的闪电曲线。
	"wind_lightning_link_b": {"layer": "link", "anchor": "path", "kind": "block_wind_lightning_link", "color": "#9df5ff", "size": 5.0, "segment_count": 10, "curve_amount": 18.0, "curve_speed": 3.4, "particle_seed": 181.0},
	"wind_lightning_hit_c": {"layer": "hit", "anchor": "target", "kind": "block_wind_lightning_hit", "color": "#d2fbff", "size": 34.0, "particle_count": 7, "particle_spread": 30.0, "particle_seed": 191.0},
	# 潮汐连锁：大水球击中第一目标并散开，再由第一目标弹射小水球到相邻目标。
	"tidal_release_a": {"layer": "release", "anchor": "caster", "kind": "block_tidal_release", "color": "#64d7ff", "size": 34.0, "particle_count": 6, "particle_spread": 24.0, "particle_seed": 111.0},
	"tidal_big_ball_b": {"layer": "flight", "anchor": "path", "target_scope": "selected_target", "kind": "block_tidal_big_ball", "color": "#6cddff", "size": 36.0, "motion": "arc", "axis": "y_forward", "particle_count": 5, "particle_spread": 12.0, "particle_seed": 113.0},
	"tidal_splash_b": {"layer": "hit", "anchor": "target", "target_scope": "selected_target", "kind": "block_tidal_splash", "color": "#5fd8ff", "size": 42.0, "particle_count": 10, "particle_spread": 38.0, "particle_birth_range": 0.14, "particle_seed": 127.0},
	"tidal_small_ball_c": {"layer": "flight", "anchor": "path", "source_scope": "selected_target", "target_scope": "chain_target", "kind": "block_tidal_small_ball", "color": "#b8f4ff", "size": 18.0, "motion": "arc", "axis": "y_forward", "particle_count": 4, "particle_spread": 8.0, "particle_seed": 131.0},
	"tidal_splash_c": {"layer": "hit", "anchor": "target", "target_scope": "chain_target", "kind": "block_tidal_chain_splash", "color": "#8eeaff", "size": 28.0, "particle_count": 7, "particle_spread": 26.0, "particle_birth_range": 0.10, "particle_seed": 137.0},
	# 岩壁连投：每一枚石块共用同一套块配置；实例只改变稳定的弧线、左右方向和翻滚方向。
	"rock_release_a": {"layer": "release", "anchor": "caster", "kind": "block_rock_release", "color": "#b77b45", "size": 42.0, "particle_count": 5, "particle_spread": 24.0, "particle_seed": 151.0},
	"rock_flight_b": {"layer": "flight", "anchor": "path", "target_scope": "selected_target", "kind": "block_rock_flight", "color": "#a56d3e", "size": 48.0, "motion": "arc", "axis": "y_forward", "roll_turns": 2.6, "particle_count": 3, "particle_spread": 12.0, "particle_seed": 157.0},
	"rock_impact_c": {"layer": "hit", "anchor": "target", "target_scope": "selected_target", "kind": "block_rock_impact", "color": "#c28a50", "size": 46.0, "particle_count": 10, "particle_spread": 42.0, "particle_birth_range": 0.12, "particle_seed": 163.0},
}

# 配置格式：effect = 效果块 ID；start = 从技能开始算起的播放间隔；duration = 本步骤持续时间。
const SKILL_SEQUENCES: Dictionary = {
	"fire": [
		{"effect": "fire_release_a", "start": 0.00, "duration": 0.50},
		{"effect": "fireball_sprite_b", "start": 0.20, "duration": 1.00, "arc_degrees": 15.0},
		{"effect": "fireball_trail_b", "start": 0.20, "duration": 1.00, "arc_degrees": 15.0},
		{"effect": "fire_impact_c", "start": 1.20, "duration": 0.38},
	],
	"balanced": [
		{"effect": "heal_release_a", "start": 0.00, "duration": 0.34},
		{"effect": "heal_rise_c", "start": 0.18, "duration": 0.72},
	],
	"heal": [{"effect": "gold_heal_release_a", "start": 0.00, "duration": 0.40}, {"effect": "gold_heal_all_c", "start": 0.22, "duration": 0.74}],
	"speed": [{"effect": "release_a", "start": 0.00, "duration": 0.16}, {"effect": "wind_lightning_link_b", "start": 0.10, "duration": 1.00}, {"effect": "wind_lightning_hit_c", "start": 0.10, "duration": 1.00}],
	"guard": [
		{"effect": "tidal_release_a", "start": 0.00, "duration": 0.28},
		{"effect": "tidal_big_ball_b", "start": 0.12, "duration": 0.64, "arc_degrees": 6.0},
		{"effect": "tidal_splash_b", "start": 0.76, "duration": 0.30},
		{"effect": "tidal_small_ball_c", "start": 0.92, "duration": 0.42, "arc_degrees": 10.0},
		{"effect": "tidal_splash_c", "start": 1.34, "duration": 0.30},
	],
	"bulwark": [
		{"effect": "rock_release_a", "start": 0.00, "duration": 0.22, "repeat_count": 3, "repeat_interval": 0.30},
		{"effect": "rock_flight_b", "start": 0.08, "duration": 0.72, "repeat_count": 3, "repeat_interval": 0.30, "random_arc_min": 8.0, "random_arc_max": 22.0, "random_arc_direction": true, "random_arc_seed": 167.0},
		{"effect": "rock_impact_c", "start": 0.80, "duration": 0.32, "repeat_count": 3, "repeat_interval": 0.30},
	],
	"siphon": [{"effect": "release_a", "start": 0.00, "duration": 0.20}, {"effect": "link_b", "start": 0.12, "duration": 0.32}, {"effect": "shadow_c", "start": 0.38, "duration": 0.30}],
	"chain": [{"effect": "release_a", "start": 0.00, "duration": 0.16}, {"effect": "link_b", "start": 0.10, "duration": 0.32}, {"effect": "thunder_c", "start": 0.34, "duration": 0.28}],
}

# 每次构建播放数据时递增；只用于生成一次性的稳定随机布局，绝不在逐帧绘制中使用。
static var _playback_serial := 0


static func get_sequence(tone: String) -> Array:
	return SKILL_SEQUENCES.get(tone, SKILL_SEQUENCES["balanced"]).duplicate(true)


static func get_effect_block(effect_id: String) -> Dictionary:
	return EFFECT_BLOCKS.get(effect_id, {}).duplicate(true)


static func build_playback(tone: String, caster_center: Vector2, target_center: Vector2) -> Array:
	return _build_playback(tone, caster_center, {"selected_target": [target_center], "chain_target": [target_center], "all_targets": [target_center]})


## 对具有 target_scope = all_targets 的步骤，为每一个候选目标各创建一条播放数据。
static func build_playback_for_targets(tone: String, caster_center: Vector2, target_center: Vector2, all_target_centers: Array) -> Array:
	return _build_playback(tone, caster_center, {"selected_target": [target_center], "chain_target": [target_center], "all_targets": all_target_centers})


## 对连锁技能，chain_target 是后续飞行段的目标；其 source_scope 可引用 selected_target。
static func build_playback_for_chain(tone: String, caster_center: Vector2, target_center: Vector2, chain_target_center: Vector2, all_target_centers: Array = []) -> Array:
	return _build_playback(tone, caster_center, {"selected_target": [target_center], "chain_target": [chain_target_center], "all_targets": all_target_centers})


static func _build_playback(tone: String, caster_center: Vector2, target_plan: Dictionary) -> Array:
	var playback: Array = []
	_playback_serial += 1
	var playback_seed := float(_playback_serial) * 97.0
	for step in get_sequence(tone):
		var block := get_effect_block(str(step.get("effect", "")))
		if block.is_empty():
			continue
		block.merge(step, true)
		var target_scope := str(block.get("target_scope", "selected_target"))
		var centers: Array = target_plan.get(target_scope, target_plan.get("selected_target", []))
		if centers.is_empty():
			centers = [caster_center]
		if str(block.get("anchor", "")) == "caster":
			centers = [caster_center]
		var source_scope := str(block.get("source_scope", "caster"))
		var source_center := caster_center
		if source_scope != "caster":
			var sources: Array = target_plan.get(source_scope, [])
			if not sources.is_empty():
				source_center = sources[0]
		var repeat_count := maxi(1, int(step.get("repeat_count", 1)))
		var repeat_interval := maxf(0.0, float(step.get("repeat_interval", 0.0)))
		for repeat_index in range(repeat_count):
			for center: Vector2 in centers:
				var entry := block.duplicate(true)
				entry["tone"] = tone
				entry["repeat_index"] = repeat_index
				entry["delay"] = float(step.get("start", 0.0)) + float(repeat_index) * repeat_interval
				entry["duration"] = float(step.get("duration", 0.25))
				entry["center"] = center
				entry["from"] = source_center
				entry["to"] = center
				_apply_repeat_motion_variation(entry, repeat_index, playback_seed)
				playback.append(entry)
	return playback


static func uses_target_scope(tone: String, target_scope: String) -> bool:
	for step in get_sequence(tone):
		var block := get_effect_block(str(step.get("effect", "")))
		if str(block.get("target_scope", "selected_target")) == target_scope:
			return true
	return false


static func get_total_duration(tone: String) -> float:
	var total := 0.0
	for step in get_sequence(tone):
		var repeat_count := maxi(1, int(step.get("repeat_count", 1)))
		var repeat_interval := maxf(0.0, float(step.get("repeat_interval", 0.0)))
		total = maxf(total, float(step.get("start", 0.0)) + float(step.get("duration", 0.0)) + float(repeat_count - 1) * repeat_interval)
	return total


## 返回最早受击步骤的起播时间，用于将战斗结算与飞行节点抵达时刻对齐。
static func get_impact_start(tone: String) -> float:
	for step in get_sequence(tone):
		var block := get_effect_block(str(step.get("effect", "")))
		if str(block.get("layer", "")) == "hit":
			return float(step.get("start", 0.0))
	return 0.0


## 二次贝塞尔弧线。arc_degrees 表示飞行节点相对直线的起飞/落下角度。
## 返回 pos、direction 和 rotation；rotation 让本地 Y 轴指向飞行前方。
static func sample_flight_motion(step: Dictionary, progress: float) -> Dictionary:
	var start: Vector2 = step.get("from", Vector2.ZERO)
	var finish: Vector2 = step.get("to", Vector2.ZERO)
	var direction := finish - start
	if direction.length() <= 0.001:
		return {"position": start, "direction": Vector2.UP, "rotation": 0.0}
	var t := clampf(progress, 0.0, 1.0)
	var normal := direction.normalized().orthogonal()
	# 默认向上拱起；重复投射可以为每次飞行写入稳定的左右弧线方向。
	var arc_direction := float(step.get("arc_direction", 0.0))
	if absf(arc_direction) > 0.001:
		normal *= signf(arc_direction)
	elif normal.y > 0.0:
		normal = -normal
	var arc_height := direction.length() * 0.5 * tan(deg_to_rad(float(step.get("arc_degrees", 0.0))))
	var control := start.lerp(finish, 0.5) + normal * arc_height
	var inverse_t := 1.0 - t
	var position := inverse_t * inverse_t * start + 2.0 * inverse_t * t * control + t * t * finish
	var tangent := 2.0 * inverse_t * (control - start) + 2.0 * t * (finish - control)
	if tangent.length() <= 0.001:
		tangent = direction
	var forward := tangent.normalized()
	return {"position": position, "direction": forward, "rotation": forward.angle() - PI * 0.5}


## 持续连线的闪电折线。端点固定在施放者与目标，中段曲线按播放进度流动。
static func sample_lightning_link(step: Dictionary, progress: float) -> PackedVector2Array:
	var start: Vector2 = step.get("from", Vector2.ZERO)
	var finish: Vector2 = step.get("to", Vector2.ZERO)
	var direction := finish - start
	if direction.length() <= 0.001:
		return PackedVector2Array([start, finish])
	var normal := direction.normalized().orthogonal()
	var segments := maxi(2, int(step.get("segment_count", 8)))
	var amplitude := float(step.get("curve_amount", 14.0))
	var speed := float(step.get("curve_speed", 3.0))
	var seed := float(step.get("particle_seed", 0.0))
	var phase := progress * TAU * speed
	var points := PackedVector2Array()
	for i in range(segments + 1):
		var ratio := float(i) / float(segments)
		var edge_fade := sin(ratio * PI)
		var wave := sin(phase + float(i) * 2.37) * 0.60 + sin(phase * 1.43 + float(i) * 5.11) * 0.22
		var bend := (stable_noise(seed, float(i) * 2.0) - 0.5) * 0.78
		points.append(start.lerp(finish, ratio) + normal * (wave + bend) * amplitude * edge_fade)
	return points


## 重复步骤只在这里生成实例差异，避免渲染时重抽随机数造成轨迹跳变。
static func _apply_repeat_motion_variation(entry: Dictionary, repeat_index: int, playback_seed: float) -> void:
	if not entry.has("random_arc_min") and not entry.has("random_arc_max"):
		return
	var seed := float(entry.get("random_arc_seed", 0.0)) + playback_seed
	var min_arc := float(entry.get("random_arc_min", entry.get("arc_degrees", 0.0)))
	var max_arc := float(entry.get("random_arc_max", entry.get("arc_degrees", min_arc)))
	entry["arc_degrees"] = lerpf(min_arc, max_arc, stable_noise(seed, float(repeat_index) * 3.0))
	if bool(entry.get("random_arc_direction", false)):
		entry["arc_direction"] = -1.0 if stable_noise(seed, float(repeat_index) * 3.0 + 1.0) < 0.5 else 1.0
	entry["roll_direction"] = -1.0 if stable_noise(seed, float(repeat_index) * 3.0 + 2.0) < 0.5 else 1.0


## 稳定伪随机值。渲染层用它做随机出生/扩散，避免每帧重抽随机数造成闪烁。
static func stable_noise(seed: float, channel: float = 0.0) -> float:
	return fposmod(sin(seed * 12.9898 + channel * 78.233) * 43758.5453, 1.0)
