class_name LeaderSkillVisualDb
extends RefCounted

const ASSET_DIR := "res://assets/images/ui/leader_skills/effects"
const PARTICLE_DIR := "res://assets/images/ui/leader_skills/particles"

const TYPES: Dictionary = {
	"fire": {
		"id": "fire",
		"name": "烈焰攻势型",
		"dispatch": "fire_burst",
		"asset": PARTICLE_DIR + "/leader_fx_fire_particle.png",
		"motion": "fire_impact",
		"particleBudget": 8,
		"summary": "饱和火焰环向外爆发，适合火属性攻击、灼烧和强打击队长技表现。"
	},
	"balanced": {
		"id": "balanced",
		"name": "均衡号令型",
		"dispatch": "crest_beam",
		"asset": ASSET_DIR + "/leader_skill_vfx_balanced.png",
		"motion": "impact",
		"particleBudget": 5,
		"summary": "草金聚能、叶片与暖光爆发，适合稳定伤害和通用增益的队长技表现。"
	},
	"heal": {
		"id": "heal",
		"name": "生命回响型",
		"dispatch": "ally_bloom",
		"asset": ASSET_DIR + "/leader_skill_vfx_heal.png",
		"motion": "soft_bloom",
		"particleBudget": 5,
		"summary": "柔和花瓣、泡泡与生命光点绽放，适合治疗和生命加成表现。"
	},
	"speed": {
		"id": "speed",
		"name": "疾风先手型",
		"dispatch": "enemy_mark",
		"asset": ASSET_DIR + "/leader_skill_vfx_speed.png",
		"motion": "quick_swirl",
		"particleBudget": 4,
		"summary": "圆润旋风与羽刃轨迹快速扫过，适合Combo、风伤和削弱表现。"
	},
	"guard": {
		"id": "guard",
		"name": "潮汐守护型",
		"dispatch": "ally_shell",
		"asset": ASSET_DIR + "/leader_skill_vfx_guard.png",
		"motion": "steady_shell",
		"particleBudget": 5,
		"summary": "水波护体、泡泡与蓝色光环包裹队友，适合水系护盾和生命加成表现。"
	},
	"bulwark": {
		"id": "bulwark",
		"name": "岩壁阵线型",
		"dispatch": "ally_shell",
		"asset": ASSET_DIR + "/leader_skill_vfx_bulwark.png",
		"motion": "heavy_shell",
		"particleBudget": 6,
		"summary": "圆润碎石、暖尘与地面冲击环撑起防线，适合土系减伤和守护表现。"
	},
	"siphon": {
		"id": "siphon",
		"name": "暗影追击型",
		"dispatch": "beam_lifesteal",
		"asset": ASSET_DIR + "/leader_skill_vfx_siphon.png",
		"motion": "impact",
		"particleBudget": 5,
		"summary": "紫黑影雾命中后带回粉紫生命回流，适合暗伤和吸血表现。"
	},
	"chain": {
		"id": "chain",
		"name": "雷鸣连锁型",
		"dispatch": "beam_status",
		"asset": ASSET_DIR + "/leader_skill_vfx_chain.png",
		"motion": "snap_chain",
		"particleBudget": 5,
		"summary": "蓝金雷链与弹跳火花连锁穿击，适合雷伤和控制标记表现。"
	}
}


static func get_profile(tone: String) -> Dictionary:
	return TYPES.get(tone, TYPES["balanced"]).duplicate(true)


static func get_asset_path(tone: String) -> String:
	return str(get_profile(tone).get("asset", ""))


static func get_dispatch(tone: String) -> String:
	return str(get_profile(tone).get("dispatch", "crest_beam"))


static func get_particle_budget(tone: String) -> int:
	return int(get_profile(tone).get("particleBudget", 4))


static func get_motion(tone: String) -> String:
	return str(get_profile(tone).get("motion", "impact"))


static func get_motion_scale(tone: String, progress: float, phase: String = "burst") -> float:
	var p := clampf(progress, 0.0, 1.0)
	match get_motion(tone):
		"fire_impact":
			var fire_snap := 1.0 - pow(1.0 - clampf(p / 0.34, 0.0, 1.0), 3.0)
			return 1.04 + fire_snap * (0.76 if phase != "mark" else 0.52)
		"soft_bloom":
			var bloom := smoothstep(0.0, 1.0, p)
			return 0.72 + bloom * 0.56 + sin(p * PI) * 0.06
		"quick_swirl":
			var snap := 1.0 - pow(1.0 - clampf(p / 0.42, 0.0, 1.0), 3.0)
			return 0.82 + snap * 0.62 + sin(p * TAU * 1.35) * 0.04
		"steady_shell":
			return 0.90 + sin(clampf(p / 0.72, 0.0, 1.0) * PI) * 0.26
		"heavy_shell":
			var rise := 1.0 - pow(1.0 - clampf(p / 0.48, 0.0, 1.0), 2.0)
			return 0.96 + rise * 0.28
		"snap_chain":
			var snap_chain := 1.0 - pow(1.0 - clampf(p / 0.36, 0.0, 1.0), 3.0)
			return 1.00 + snap_chain * 0.70
		_:
			var impact := 1.0 - pow(1.0 - clampf(p / 0.46, 0.0, 1.0), 3.0)
			return 1.00 + impact * (0.42 if phase == "mark" else 0.56)


static func get_motion_alpha(tone: String, progress: float, base_alpha: float) -> float:
	var p := clampf(progress, 0.0, 1.0)
	var fade_start := 0.80
	match get_motion(tone):
		"fire_impact", "impact", "snap_chain", "quick_swirl":
			fade_start = 0.62
		"soft_bloom":
			fade_start = 0.84
		"steady_shell", "heavy_shell":
			fade_start = 0.78
	var fade := 1.0 - smoothstep(fade_start, 1.0, p)
	return clampf(base_alpha * fade, 0.0, 1.0)
