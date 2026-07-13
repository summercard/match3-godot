class_name FeatureUnlockRules
extends RefCounted

## A single source of truth for player-level feature gates.
const CLASSROOM_REQUIRED_LEVEL := 1
const RANCH_REQUIRED_LEVEL := 10
const SOCIAL_REQUIRED_LEVEL := 25

const FEATURE_CONFIG := {
	"classroom": {"required_level": CLASSROOM_REQUIRED_LEVEL, "label": "精灵课堂"},
	"ranch": {"required_level": RANCH_REQUIRED_LEVEL, "label": "精灵农场"},
	"social": {"required_level": SOCIAL_REQUIRED_LEVEL, "label": "社交广场"},
}

static func get_unlock_state(feature_id: String, player_level: int) -> Dictionary:
	var config: Dictionary = FEATURE_CONFIG.get(feature_id, {})
	var required_level := maxi(1, int(config.get("required_level", 1)))
	var label := str(config.get("label", feature_id))
	var level := maxi(1, player_level)
	return {
		"feature_id": feature_id,
		"label": label,
		"required_level": required_level,
		"player_level": level,
		"unlocked": level >= required_level,
	}


static func locked_message(feature_id: String, player_level: int) -> String:
	var state := get_unlock_state(feature_id, player_level)
	if bool(state.get("unlocked", false)):
		return ""
	return "%s将在玩家达到 Lv.%d 后解锁" % [str(state.get("label", "该功能")), int(state.get("required_level", 1))]
