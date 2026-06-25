class_name ChapterMechanicRules
extends RefCounted

const CHAPTER_TEMPLATES := {
	"chapter_1": {
		"id": "starter_break",
		"name": "能量读招",
		"tagline": "用棋盘亲和、守护和束缚学会第一套破招。",
		"pressure": "敌方意图",
		"playerPlan": "读意图后决定输出、守护或束缚。",
		"bossRhythm": "周期蓄力",
		"boardPressure": "低压教学棋盘",
		"breakPoint": "蓄力前束缚或提前守护"
	},
	"chapter_2": {
		"id": "rock_pressure",
		"name": "岩障开路",
		"tagline": "先清岩障，再抓住火系敌人的爆发空窗。",
		"pressure": "岩障",
		"playerPlan": "优先打通障碍密集区，保留爆发处理架盾或蓄力。",
		"bossRhythm": "架盾后强攻",
		"boardPressure": "岩障封锁关键落点",
		"breakPoint": "破盾后集中爆发"
	},
	"chapter_3": {
		"id": "focus_hunt",
		"name": "暗影集火",
		"tagline": "从多目标里挑出真正危险的意图先处理。",
		"pressure": "多目标意图",
		"playerPlan": "根据意图标签切换集火目标，避免平均伤害拖慢节奏。",
		"bossRhythm": "暗影蓄压",
		"boardPressure": "分散敌群压迫行动优先级",
		"breakPoint": "提前压低危险目标"
	},
	"chapter_4": {
		"id": "rock_pressure",
		"name": "沙漠岩障",
		"tagline": "利用消除和爆炸清开岩石，重新打开沙漠棋盘的落点。",
		"pressure": "岩障",
		"playerPlan": "优先打通岩石密集区，保留爆发处理关键堵点。",
		"bossRhythm": "岩障压缩",
		"boardPressure": "岩石封锁关键落点和连线空间",
		"breakPoint": "清开主通路后集中爆发"
	},
	"chapter_5": {
		"id": "island_tide",
		"name": "海岛涨潮",
		"tagline": "每回合海水从底部上涨，水中只有水元素宝石还能正常操作。",
		"pressure": "涨潮水位",
		"playerPlan": "优先在干区建立连线，把水元素留在低位作为退路。",
		"bossRhythm": "高潮线压缩",
		"boardPressure": "底部水位逐步压缩可操作区域",
		"breakPoint": "水位封住底部前完成蓄能爆发"
	},
	"chapter_6": {
		"id": "fog_race",
		"name": "寒雾竞速",
		"tagline": "在毒雾扩散前建立清盘节奏。",
		"pressure": "毒雾",
		"playerPlan": "优先处理雾源附近的匹配，减少后续行动税。",
		"bossRhythm": "雾压下蓄力",
		"boardPressure": "毒雾按回合扩散",
		"breakPoint": "守护承伤并抢在雾满前爆发"
	},
	"chapter_7": {
		"id": "void_split",
		"name": "虚空分割",
		"tagline": "穿过分割棋盘，找回连锁线路。",
		"pressure": "岩障与毒雾",
		"playerPlan": "先恢复棋盘连通，再处理高威胁意图。",
		"bossRhythm": "分割后收割",
		"boardPressure": "岩障和毒雾切断连锁路线",
		"breakPoint": "重连棋盘后集中破招"
	},
	"chapter_8": {
		"id": "time_lock",
		"name": "时序封锁",
		"tagline": "管理角落封锁，等待关键回合爆发。",
		"pressure": "锁定宝石",
		"playerPlan": "保留可爆发的颜色，等解锁窗口一次推进。",
		"bossRhythm": "延迟爆发",
		"boardPressure": "角落锁定限制布局",
		"breakPoint": "在爆发回合前完成蓄能"
	},
	"chapter_9": {
		"id": "star_lane",
		"name": "星轨阵型",
		"tagline": "沿星轨清出通路，避免中心被压死。",
		"pressure": "阵型毒雾",
		"playerPlan": "优先打通中心线，制造跨区连锁。",
		"bossRhythm": "阵型压缩",
		"boardPressure": "星轨形雾区占据中心",
		"breakPoint": "中心线打通后爆发"
	},
	"chapter_10": {
		"id": "chaos_weight",
		"name": "混沌重压",
		"tagline": "同时处理岩障与封锁，选择最少行动的解法。",
		"pressure": "复合障碍",
		"playerPlan": "判断先破岩还是先解锁，避免被复合压力拖死。",
		"bossRhythm": "复合压制",
		"boardPressure": "岩障和锁定宝石叠加",
		"breakPoint": "清出主通路后用控场抢回节奏"
	},
	"chapter_11": {
		"id": "light_trial",
		"name": "光辉试炼",
		"tagline": "在高密度雾区里保持核心连锁。",
		"pressure": "高密度雾区",
		"playerPlan": "围绕安全区建立连锁，不让雾区吞掉中心。",
		"bossRhythm": "净化考验",
		"boardPressure": "大面积雾区压缩安全行动",
		"breakPoint": "稳定安全区后反击"
	}
}

static func enrich_chapter(raw_chapter: Dictionary) -> Dictionary:
	var chapter := raw_chapter.duplicate(true)
	var template := get_chapter_mechanic(chapter)
	chapter["chapterMechanic"] = template
	var stages: Array = []
	for raw_stage: Dictionary in chapter.get("stages", []):
		stages.append(enrich_stage(raw_stage, chapter))
	chapter["stages"] = stages
	return chapter

static func enrich_stage(raw_stage: Dictionary, chapter: Dictionary) -> Dictionary:
	var stage := raw_stage.duplicate(true)
	var chapter_mechanic: Dictionary = chapter.get("chapterMechanic", get_chapter_mechanic(chapter))
	stage["chapterId"] = chapter.get("id", "")
	stage["chapterName"] = chapter.get("name", "")
	stage["chapterElement"] = chapter.get("element", "")
	stage["chapterMechanic"] = chapter_mechanic
	stage["stageGoal"] = build_stage_goal(stage, chapter_mechanic)
	if stage.get("type", "normal") == "boss":
		stage["bossLayers"] = build_boss_layers(stage, chapter_mechanic)
	return stage

static func get_chapter_mechanic(chapter: Dictionary) -> Dictionary:
	var chapter_id := str(chapter.get("id", ""))
	var fallback := {
		"id": "generic_read",
		"name": "意图应对",
		"tagline": "观察敌方意图，选择输出、守护或控场。",
		"pressure": "敌方意图",
		"playerPlan": "先处理最高威胁目标。",
		"bossRhythm": "周期压迫",
		"boardPressure": "常规棋盘压力",
		"breakPoint": "关键意图前完成反制"
	}
	var template: Dictionary = CHAPTER_TEMPLATES.get(chapter_id, fallback)
	return template.duplicate(true)

static func build_stage_goal(stage: Dictionary, chapter_mechanic: Dictionary) -> Dictionary:
	return {
		"id": "defeat_enemies",
		"label": "击败敌人",
		"tip": "击败全部敌方精灵即可过关。",
		"focus": "combat"
	}

static func build_boss_layers(stage: Dictionary, chapter_mechanic: Dictionary) -> Array:
	return [
		{
			"id": "rhythm",
			"label": "主节奏",
			"text": chapter_mechanic.get("bossRhythm", "周期压迫")
		},
		{
			"id": "board_pressure",
			"label": "棋盘压力",
			"text": chapter_mechanic.get("boardPressure", chapter_mechanic.get("pressure", "章节机制"))
		},
		{
			"id": "break_point",
			"label": "破招点",
			"text": chapter_mechanic.get("breakPoint", "关键意图前完成反制")
		}
	]

static func build_prepare_summary(stage: Dictionary) -> String:
	var mechanic: Dictionary = stage.get("chapterMechanic", {})
	var goal: Dictionary = stage.get("stageGoal", {})
	if mechanic.is_empty() and goal.is_empty():
		return ""
	var mechanic_name := str(mechanic.get("name", "章节机制"))
	var goal_label := str(goal.get("label", "关卡目标"))
	return "%s：%s" % [mechanic_name, goal_label]
