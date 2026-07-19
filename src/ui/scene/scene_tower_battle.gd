class_name SceneTowerBattle
extends SceneBattleGui

@onready var _tower_title: Label = get_node_or_null("TowerHud/Title") as Label
@onready var _tower_progress: Label = get_node_or_null("TowerHud/Progress") as Label


func init(data: Dictionary = {}) -> void:
	var tower_data := data.duplicate(true)
	tower_data["towerMode"] = true
	super.init(tower_data)
	call_deferred("_refresh_tower_hud")


func _ready() -> void:
	super._ready()
	_refresh_tower_hud()


func _refresh_tower_hud() -> void:
	if _tower_title == null or _tower_progress == null:
		return
	var floor := int(_stage_data.get("towerFloor", 1))
	var wave := int(_stage_data.get("towerWave", 1))
	var wave_count := int(_stage_data.get("towerWaveCount", 5))
	var theme := str(_stage_data.get("towerTheme", "共鸣塔"))
	_tower_title.text = TranslationServer.translate("共鸣远征  ·  %02dF") % floor
	_tower_progress.text = TranslationServer.translate("%s  ·  第 %d/%d 波") % [theme, wave, wave_count]
