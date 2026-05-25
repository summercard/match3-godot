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
		"id": "lock_cleanse",
		"name": "锁链解盘",
		"tagline": "清锁定宝石，避免棋盘被拖进低行动区。",
		"pressure": "锁定宝石",
		"playerPlan": "先解锁关键列，再利用连锁恢复输出节奏。",
		"bossRhythm": "封锁后爆发",
		"boardPressure": "锁定宝石限制可交换空间",
		"breakPoint": "解锁后打断关键意图"
	},
	"chapter_5": {
		"id": "storm_sync",
		"name": "雷锁共鸣",
		"tagline": "用高连锁和共鸣穿过雷系封锁。",
		"pressure": "锁定宝石",
		"playerPlan": "围绕雷/光共鸣做连锁，快速拆掉封锁点。",
		"bossRhythm": "高频压迫",
		"boardPressure": "边角锁定和分区障碍",
		"breakPoint": "共鸣爆发打穿护盾"
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
	var stage_type := str(stage.get("type", "normal"))
	if stage_type == "boss":
		return {
			"id": "boss_three_layers",
			"label": "Boss三层考题",
			"tip": "读主节奏，处理%s，并在%s时反击。" % [chapter_mechanic.get("pressure", "章节压力"), chapter_mechanic.get("breakPoint", "破招窗口")],
			"focus": "break"
		}
	if stage_type == "elite":
		return {
			"id": "elite_pressure",
			"label": "精英压力关",
			"tip": "用更少回合解决%s，别让压力滚大。" % chapter_mechanic.get("pressure", "章节机制"),
			"focus": "efficiency"
		}
	if stage.has("poisonFog"):
		return {
			"id": "fog_control",
			"label": "控雾",
			"tip": "优先清理雾区附近的匹配，减少后续行动税。",
			"focus": "board_control"
		}
	if stage.has("lockedGems"):
		return {
			"id": "unlock_path",
			"label": "解锁",
			"tip": "先解开关键锁定宝石，再追求连锁输出。",
			"focus": "board_control"
		}
	if stage.has("obstacles"):
		return {
			"id": "break_rocks",
			"label": "破障",
			"tip": "先打通岩障密集区，打开掉落和连锁空间。",
			"focus": "board_control"
		}
	return {
		"id": str(stage.get("targetLesson", "chapter_plan")),
		"label": chapter_mechanic.get("name", "章节目标"),
		"tip": chapter_mechanic.get("playerPlan", "观察意图并选择行动。"),
		"focus": "lesson"
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
