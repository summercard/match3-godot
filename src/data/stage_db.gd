class_name StageDB
extends RefCounted
## 关卡数据库 - 从 data/stages.js 翻译
## 包含所有章节与关卡数据，供 BattleManager、SaveManager 引用

const ChapterMechanicRulesScript = preload("res://src/data/chapter_mechanic_rules.gd")
const STAGES_PER_CHAPTER := 12
const NORMAL_STAGES_PER_CHAPTER := 11
const BOSS_STAGE_NO := 12
const STAGE_EXP_REWARD_MULTIPLIER := 1.30

const CHAPTER_ENEMY_POOLS := {
	1: ["monster_001", "monster_002", "monster_003", "monster_005", "monster_006", "monster_007", "monster_009", "monster_011", "monster_012"],
	2: ["monster_014", "monster_015", "monster_017", "monster_018", "monster_020", "monster_021", "monster_023", "monster_024", "monster_026", "monster_027"],
	3: ["monster_029", "monster_030", "monster_031", "monster_032", "monster_034", "monster_035", "monster_036", "monster_037", "monster_039"],
	4: ["monster_040", "monster_041", "monster_042", "monster_043", "monster_045", "monster_046", "monster_047", "monster_048", "monster_049", "monster_050", "monster_051", "monster_052"],
	5: ["monster_053", "monster_054", "monster_055", "monster_056", "monster_057", "monster_058", "monster_059", "monster_060", "monster_061", "monster_062", "monster_063", "monster_064", "monster_065"],
	6: ["monster_067", "monster_068", "monster_070", "monster_071", "monster_073", "monster_074", "monster_076", "monster_077", "monster_079", "monster_080"],
	7: ["monster_081", "monster_082", "monster_084", "monster_085", "monster_087", "monster_088", "monster_090", "monster_091"],
	8: ["monster_093", "monster_094", "monster_095", "monster_096", "monster_097", "monster_098", "monster_099", "monster_100", "monster_101", "monster_102"]
}

const CHAPTER_BOSS_IDS := {
	1: "monster_boss_001",
	2: "monster_boss_002",
	3: "monster_boss_003",
	4: "monster_boss_004",
	5: "monster_boss_005",
	6: "monster_boss_006",
	7: "monster_boss_007",
	8: "monster_boss_008"
}

# ========== 关卡数据库 ==========
const STAGES_DATA: Dictionary = {
	"chapters": [
		{
			"id": "chapter_1",
			"name": "微风平原",
			"element": "grass",
			"stages": [
				{
					"id": "stage_1_1", "name": "能量响应训练", "type": "normal",
					"enemies": ["monster_001"],
					"enemyLevel": 1,
					"rewards": {"gold": 45, "exp": 45},
					"designGoal": "学会棋盘亲和会驱动对应精灵行动与技能充能。",
					"prepareHint": "消除炽能给小火龙充能；留意队伍卡片上的技能条。",
					"battleHint": "先消除小火龙亲和的炽能，观察技能充能。",
					"targetLesson": "board_affinity"
				},
				{
					"id": "stage_1_2", "name": "捕捉窗口练习", "type": "normal",
					"enemies": ["monster_002"],
					"enemyLevel": 2,
					"rewards": {"gold": 65, "exp": 60, "guaranteedItems": [{"id": "capture_ball", "count": 1}]},
					"designGoal": "让玩家第一次看到低血会打开捕捉窗口。",
					"prepareHint": "把目标压到低血会打开捕捉窗口；自动捕捉开启后胜利会尝试收服。",
					"battleHint": "观察底部捕捉窗口，目标越虚弱越稳定。",
					"targetLesson": "capture_window"
				},
				{
					"id": "stage_1_3", "name": "守护与续航", "type": "normal",
					"enemies": ["monster_003", "monster_005"],
					"enemyLevel": 3,
					"rewards": {"gold": 85, "exp": 75},
					"designGoal": "让水龟仔的守护技能有明确价值。",
					"prepareHint": "水龟仔是守护位：潮能充能后可治疗最低血队友并减伤。",
					"battleHint": "队伍受伤后释放水之护盾，守住下一次攻击。",
					"targetLesson": "ward_skill"
				},
				{
					"id": "stage_1_4", "name": "藤蔓束缚", "type": "normal",
					"enemies": ["monster_006", "monster_007"],
					"enemyLevel": 3,
					"rewards": {"gold": 105, "exp": 90},
					"designGoal": "让草苗儿的控场技能为 Boss 前做铺垫。",
					"prepareHint": "草苗儿是控场位：生能充能后可束缚敌人，降低下一次攻击。",
					"battleHint": "在敌人攻击前释放藤蔓束缚，降低压力。",
					"targetLesson": "tempo_skill"
				},
				{
					"id": "stage_1_5", "name": "花叶兽的破招", "type": "boss",
					"phases": [
						{"phase": 1, "enemies": ["monster_boss_001"], "trigger": "on_enter"},
						{"phase": 2, "enemies": ["monster_boss_001"], "trigger": "hp_50", "hpMultiplier": 1.3}
					],
					"enemyLevel": 3,
					"rewards": {"gold": 150, "exp": 120, "guaranteedItems": [{"id": "capture_ball_plus", "count": 1}]},
					"designGoal": "首个 Boss 用蓄力和阶段变化检验输出、守护、控场。",
					"prepareHint": "Boss 会蓄力并在半血进入二阶段；用束缚压低蓄力伤害，用守护保住队伍。",
					"battleHint": "花叶兽蓄力时优先束缚或守护，半血后准备爆发。",
					"targetLesson": "boss_break"
				}
			]
		},
		{
			"id": "chapter_2",
			"name": "瀑布国",
			"element": "fire",
			"stages": [
				{
					"id": "stage_2_1", "name": "火山口", "type": "normal",
					"enemies": ["monster_014", "monster_015"],
					"enemyLevel": 4,
					"rewards": {"gold": 60, "exp": 35}
				},
				{
					"id": "stage_2_2", "name": "岩浆洞窟", "type": "normal",
					"enemies": ["monster_017", "monster_018"],
					"enemyLevel": 5,
					"rewards": {"gold": 80, "exp": 48}
				},
				{
					"id": "stage_2_3", "name": "烈焰荒原", "type": "normal",
					"enemies": ["monster_020", "monster_021"],
					"enemyLevel": 5,
					"rewards": {"gold": 95, "exp": 58}
				},
				{
					"id": "stage_2_4", "name": "火焰池", "type": "normal",
					"enemies": ["monster_023", "monster_024"],
					"enemyLevel": 6,
					"rewards": {"gold": 110, "exp": 65}
				},
				{
					"id": "stage_2_4e", "name": "精英·烈焰守卫", "type": "elite",
					"enemies": ["monster_026"],
					"enemyLevel": 8,
					"eliteMultiplier": 1.5,
					"rewards": {"gold": 165, "exp": 98},
					"obstacles": [
						{"row": 1, "col": 3, "type": "rock", "hp": 2},
						{"row": 1, "col": 4, "type": "rock", "hp": 2},
						{"row": 3, "col": 2, "type": "rock", "hp": 2},
						{"row": 3, "col": 5, "type": "rock", "hp": 2},
						{"row": 4, "col": 3, "type": "rock", "hp": 2},
						{"row": 4, "col": 4, "type": "rock", "hp": 2},
						{"row": 6, "col": 3, "type": "rock", "hp": 2},
						{"row": 6, "col": 4, "type": "rock", "hp": 2}
					]
				},
				{
					"id": "stage_2_5", "name": "烈焰龙之巢", "type": "boss",
					"phases": [
						{"phase": 1, "enemies": ["monster_boss_002"], "trigger": "on_enter"},
						{"phase": 2, "enemies": ["monster_boss_002"], "trigger": "hp_50", "hpMultiplier": 1.5}
					],
					"enemyLevel": 6,
					"rewards": {"gold": 150, "exp": 75},
					"obstacles": [
						{"row": 1, "col": 2, "type": "rock", "hp": 2},
						{"row": 1, "col": 5, "type": "rock", "hp": 2},
						{"row": 3, "col": 1, "type": "rock", "hp": 2},
						{"row": 3, "col": 6, "type": "rock", "hp": 2},
						{"row": 5, "col": 3, "type": "rock", "hp": 2},
						{"row": 5, "col": 4, "type": "rock", "hp": 2},
						{"row": 4, "col": 0, "type": "rock", "hp": 2},
						{"row": 4, "col": 7, "type": "rock", "hp": 2}
					]
				}
			]
		},
		{
			"id": "chapter_3",
			"name": "幻羽森林",
			"element": "dark",
			"stages": [
				{
					"id": "stage_3_1", "name": "暗影小径", "type": "normal",
					"enemies": ["monster_029", "monster_030"],
					"enemyLevel": 7,
					"rewards": {"gold": 80, "exp": 45}
				},
				{
					"id": "stage_3_2", "name": "迷雾沼泽", "type": "normal",
					"enemies": ["monster_031", "monster_032", "monster_034"],
					"enemyLevel": 8,
					"rewards": {"gold": 100, "exp": 55}
				},
				{
					"id": "stage_3_3", "name": "暗礁深谷", "type": "normal",
					"enemies": ["monster_035", "monster_036", "monster_037"],
					"enemyLevel": 9,
					"rewards": {"gold": 120, "exp": 70}
				},
				{
					"id": "stage_3_3e", "name": "精英·暗影猎手", "type": "elite",
					"enemies": ["monster_039"],
					"enemyLevel": 11,
					"eliteMultiplier": 1.5,
					"rewards": {"gold": 180, "exp": 105},
					"obstacles": [
						{"row": 0, "col": 0, "type": "rock", "hp": 2},
						{"row": 1, "col": 1, "type": "rock", "hp": 2},
						{"row": 2, "col": 2, "type": "rock", "hp": 2},
						{"row": 3, "col": 3, "type": "rock", "hp": 2},
						{"row": 4, "col": 4, "type": "rock", "hp": 2},
						{"row": 5, "col": 5, "type": "rock", "hp": 2},
						{"row": 6, "col": 6, "type": "rock", "hp": 2},
						{"row": 7, "col": 7, "type": "rock", "hp": 2}
					]
				},
				{
					"id": "stage_3_4", "name": "幽灵池塘", "type": "normal",
					"enemies": ["monster_029", "monster_030"],
					"enemyLevel": 10,
					"rewards": {"gold": 140, "exp": 85}
				},
				{
					"id": "stage_3_5", "name": "暗影巨兽", "type": "boss",
					"phases": [
						{"phase": 1, "enemies": ["monster_boss_003"], "trigger": "on_enter"},
						{"phase": 2, "enemies": ["monster_boss_003"], "trigger": "hp_50", "hpMultiplier": 1.4}
					],
					"enemyLevel": 10,
					"rewards": {"gold": 200, "exp": 120}
				}
			]
		},
		{
			"id": "chapter_4",
			"name": "热情沙漠",
			"element": "dark",
			"stages": [
				{
					"id": "stage_4_1", "name": "幽暗入口", "type": "normal",
					"enemies": ["monster_040", "monster_041"],
					"enemyLevel": 11,
					"rewards": {"gold": 90, "exp": 55}
				},
				{
					"id": "stage_4_2", "name": "毒蛛巢穴", "type": "normal",
					"enemies": ["monster_042", "monster_043"],
					"enemyLevel": 12,
					"rewards": {"gold": 110, "exp": 65},
					"lockedGems": [
						{"row": 2, "col": 3, "hp": 1},
						{"row": 5, "col": 5, "hp": 1}
					]
				},
				{
					"id": "stage_4_3", "name": "暗翼盘旋", "type": "normal",
					"enemies": ["monster_045", "monster_046", "monster_047"],
					"enemyLevel": 13,
					"rewards": {"gold": 130, "exp": 80},
					"lockedGems": [
						{"row": 1, "col": 2, "hp": 1},
						{"row": 4, "col": 5, "hp": 1},
						{"row": 6, "col": 3, "hp": 1}
					]
				},
				{
					"id": "stage_4_4", "name": "幽灵徘徊", "type": "normal",
					"enemies": ["monster_048", "monster_049"],
					"enemyLevel": 14,
					"rewards": {"gold": 150, "exp": 95},
					"lockedGems": [
						{"row": 1, "col": 1, "hp": 1},
						{"row": 3, "col": 4, "hp": 1},
						{"row": 5, "col": 2, "hp": 1},
						{"row": 6, "col": 6, "hp": 1}
					]
				},
				{
					"id": "stage_4_3e", "name": "精英·沙漠蜃影", "type": "elite",
					"enemies": ["monster_050", "monster_051"],
					"enemyLevel": 15,
					"eliteMultiplier": 1.5,
					"rewards": {"gold": 220, "exp": 130},
					"obstacles": [
						{"row": 0, "col": 2, "type": "rock", "hp": 2},
						{"row": 0, "col": 5, "type": "rock", "hp": 2},
						{"row": 2, "col": 0, "type": "rock", "hp": 2},
						{"row": 2, "col": 3, "type": "rock", "hp": 2},
						{"row": 2, "col": 4, "type": "rock", "hp": 2},
						{"row": 2, "col": 7, "type": "rock", "hp": 2},
						{"row": 4, "col": 2, "type": "rock", "hp": 2},
						{"row": 4, "col": 5, "type": "rock", "hp": 2},
						{"row": 6, "col": 0, "type": "rock", "hp": 2},
						{"row": 6, "col": 7, "type": "rock", "hp": 2}
					],
					"poisonFog": {
						"tiles": [{"row": 3, "col": 1}, {"row": 5, "col": 6}],
						"spreadInterval": 5
					}
				},
				{
					"id": "stage_4_5", "name": "暗影巨龙", "type": "boss",
					"phases": [
						{"phase": 1, "enemies": ["monster_boss_004"], "trigger": "on_enter"},
						{"phase": 2, "enemies": ["monster_boss_004"], "trigger": "hp_50", "hpMultiplier": 1.5}
					],
					"enemyLevel": 15,
					"rewards": {"gold": 250, "exp": 150},
					"lockedGems": [
						{"row": 1, "col": 1, "hp": 2},
						{"row": 1, "col": 6, "hp": 2},
						{"row": 3, "col": 3, "hp": 2},
						{"row": 3, "col": 4, "hp": 2},
						{"row": 6, "col": 2, "hp": 2},
						{"row": 6, "col": 5, "hp": 2}
					]
				}
			]
		},
		{
			"id": "chapter_5",
			"name": "南国海",
			"element": "thunder",
			"stages": [
				{
					"id": "stage_5_1", "name": "雷霆入口", "type": "normal",
					"enemies": ["monster_053", "monster_054"],
					"enemyLevel": 16,
					"rewards": {"gold": 100, "exp": 60}
				},
				{
					"id": "stage_5_2", "name": "雷鹰巢穴", "type": "normal",
					"enemies": ["monster_055", "monster_056"],
					"enemyLevel": 17,
					"rewards": {"gold": 120, "exp": 75}
				},
				{
					"id": "stage_5_3", "name": "光蝶谷", "type": "normal",
					"enemies": ["monster_057", "monster_058", "monster_059"],
					"enemyLevel": 18,
					"rewards": {"gold": 140, "exp": 90}
				},
				{
					"id": "stage_5_4", "name": "元素风暴", "type": "normal",
					"enemies": ["monster_060", "monster_061", "monster_062"],
					"enemyLevel": 19,
					"rewards": {"gold": 160, "exp": 105}
				},
				{
					"id": "stage_5_3e", "name": "精英·雷暴守卫", "type": "elite",
					"enemies": ["monster_063", "monster_064"],
					"enemyLevel": 20,
					"eliteMultiplier": 1.5,
					"rewards": {"gold": 260, "exp": 155},
					"lockedGems": [
						{"row": 0, "col": 1, "hp": 2},
						{"row": 0, "col": 6, "hp": 2},
						{"row": 2, "col": 0, "hp": 2},
						{"row": 2, "col": 3, "hp": 2},
						{"row": 2, "col": 4, "hp": 2},
						{"row": 2, "col": 7, "hp": 2},
						{"row": 4, "col": 1, "hp": 2},
						{"row": 4, "col": 6, "hp": 2},
						{"row": 6, "col": 0, "hp": 2},
						{"row": 6, "col": 7, "hp": 2}
					]
				},
				{
					"id": "stage_5_5", "name": "雷霆巨兽", "type": "boss",
					"phases": [
						{"phase": 1, "enemies": ["monster_boss_005"], "trigger": "on_enter"},
						{"phase": 2, "enemies": ["monster_boss_005"], "trigger": "hp_50", "hpMultiplier": 1.5}
					],
					"enemyLevel": 20,
					"rewards": {"gold": 300, "exp": 180}
				}
			]
		},
		{
			"id": "chapter_6",
			"name": "冰之国",
			"element": "ice",
			"stages": [
				{
					"id": "stage_6_1", "name": "寒冰入口", "type": "normal",
					"enemies": ["monster_067", "monster_068"],
					"enemyLevel": 21,
					"rewards": {"gold": 110, "exp": 65}
				},
				{
					"id": "stage_6_2", "name": "霜狼巢穴", "type": "normal",
					"enemies": ["monster_070", "monster_071"],
					"enemyLevel": 22,
					"rewards": {"gold": 130, "exp": 80},
					"poisonFog": {
						"tiles": [{"row": 2, "col": 3}, {"row": 5, "col": 5}],
						"spreadInterval": 999
					}
				},
				{
					"id": "stage_6_3", "name": "极地冰原", "type": "normal",
					"enemies": ["monster_073", "monster_074", "monster_076"],
					"enemyLevel": 23,
					"rewards": {"gold": 150, "exp": 95},
					"poisonFog": {
						"tiles": [{"row": 1, "col": 2}, {"row": 4, "col": 5}, {"row": 6, "col": 3}],
						"spreadInterval": 4
					}
				},
				{
					"id": "stage_6_4", "name": "冰晶洞穴", "type": "normal",
					"enemies": ["monster_077", "monster_079", "monster_080"],
					"enemyLevel": 24,
					"rewards": {"gold": 170, "exp": 110},
					"poisonFog": {
						"tiles": [{"row": 1, "col": 1}, {"row": 3, "col": 4}, {"row": 5, "col": 2}, {"row": 6, "col": 6}],
						"spreadInterval": 3
					}
				},
				{
					"id": "stage_6_3e", "name": "精英·深渊使者", "type": "elite",
					"enemies": ["monster_067", "monster_068"],
					"enemyLevel": 25,
					"eliteMultiplier": 1.5,
					"rewards": {"gold": 300, "exp": 175},
					"obstacles": [
						{"row": 1, "col": 1, "type": "rock", "hp": 2},
						{"row": 1, "col": 6, "type": "rock", "hp": 2},
						{"row": 3, "col": 2, "type": "rock", "hp": 2},
						{"row": 3, "col": 5, "type": "rock", "hp": 2},
						{"row": 5, "col": 1, "type": "rock", "hp": 2},
						{"row": 5, "col": 6, "type": "rock", "hp": 2}
					],
					"lockedGems": [
						{"row": 2, "col": 3, "hp": 2},
						{"row": 2, "col": 4, "hp": 2},
						{"row": 4, "col": 3, "hp": 2},
						{"row": 4, "col": 4, "hp": 2}
					],
					"poisonFog": {
						"tiles": [{"row": 0, "col": 0}, {"row": 0, "col": 7}, {"row": 7, "col": 0}, {"row": 7, "col": 7}],
						"spreadInterval": 3
					}
				},
				{
					"id": "stage_6_5", "name": "冰霜巨龙", "type": "boss",
					"phases": [
						{"phase": 1, "enemies": ["monster_boss_006"], "trigger": "on_enter"},
						{"phase": 2, "enemies": ["monster_boss_006"], "trigger": "hp_50", "hpMultiplier": 1.5}
					],
					"enemyLevel": 25,
					"rewards": {"gold": 350, "exp": 200},
					"poisonFog": {
						"tiles": [{"row": 0, "col": 2}, {"row": 2, "col": 6}, {"row": 3, "col": 1}, {"row": 5, "col": 4}, {"row": 6, "col": 0}, {"row": 7, "col": 5}],
						"spreadInterval": 2
					}
				}
			]
		},
		{
			"id": "chapter_7",
			"name": "精灵虚空",
			"element": "void",
			"stages": [
				{
					"id": "stage_7_1", "name": "虚空入口", "type": "normal",
					"enemies": ["monster_081", "monster_082"],
					"enemyLevel": 26,
					"rewards": {"gold": 120, "exp": 70}
				},
				{
					"id": "stage_7_2", "name": "噬魂巢穴", "type": "normal",
					"enemies": ["monster_084", "monster_085"],
					"enemyLevel": 27,
					"rewards": {"gold": 140, "exp": 85}
				},
				{
					"id": "stage_7_3", "name": "虚空裂隙", "type": "normal",
					"enemies": ["monster_087", "monster_088", "monster_090"],
					"enemyLevel": 28,
					"rewards": {"gold": 160, "exp": 100}
				},
				{
					"id": "stage_7_3e", "name": "精英·虚空裂隙", "type": "elite",
					"enemies": ["monster_091", "monster_081"],
					"enemyLevel": 30,
					"eliteMultiplier": 1.5,
					"rewards": {"gold": 270, "exp": 155},
					"obstacles": [
						{"row": 1, "col": 4, "type": "rock", "hp": 2},
						{"row": 2, "col": 3, "type": "rock", "hp": 2},
						{"row": 2, "col": 5, "type": "rock", "hp": 2},
						{"row": 3, "col": 2, "type": "rock", "hp": 2},
						{"row": 3, "col": 6, "type": "rock", "hp": 2},
						{"row": 4, "col": 3, "type": "rock", "hp": 2},
						{"row": 4, "col": 5, "type": "rock", "hp": 2},
						{"row": 5, "col": 4, "type": "rock", "hp": 2}
					],
					"poisonFog": {
						"tiles": [
							{"row": 0, "col": 0},
							{"row": 0, "col": 7},
							{"row": 7, "col": 0},
							{"row": 7, "col": 7}
						],
						"spreadInterval": 3
					}
				},
				{
					"id": "stage_7_4", "name": "暗蚀深渊", "type": "normal",
					"enemies": ["monster_082", "monster_084", "monster_085"],
					"enemyLevel": 29,
					"rewards": {"gold": 180, "exp": 115}
				},
				{
					"id": "stage_7_5", "name": "虚空巨龙", "type": "boss",
					"phases": [
						{"phase": 1, "enemies": ["monster_boss_007"], "trigger": "on_enter"},
						{"phase": 2, "enemies": ["monster_boss_007"], "trigger": "hp_50", "hpMultiplier": 1.5}
					],
					"enemyLevel": 30,
					"rewards": {"gold": 400, "exp": 220}
				}
			]
		},
		{
			"id": "chapter_8",
			"name": "烧烤岩",
			"element": "temporal",
			"stages": [
				{
					"id": "stage_8_1", "name": "时空入口", "type": "normal",
					"enemies": ["monster_093", "monster_094"],
					"enemyLevel": 31,
					"rewards": {"gold": 130, "exp": 80}
				},
				{
					"id": "stage_8_2", "name": "时间乱流", "type": "normal",
					"enemies": ["monster_095", "monster_096"],
					"enemyLevel": 32,
					"rewards": {"gold": 150, "exp": 95}
				},
				{
					"id": "stage_8_3", "name": "时空漩涡", "type": "normal",
					"enemies": ["monster_097", "monster_098", "monster_099"],
					"enemyLevel": 33,
					"rewards": {"gold": 170, "exp": 110}
				},
				{
					"id": "stage_8_3e", "name": "精英·时空漩涡", "type": "elite",
					"enemies": ["monster_100", "monster_101"],
					"enemyLevel": 35,
					"eliteMultiplier": 1.5,
					"rewards": {"gold": 320, "exp": 180},
					"obstacles": [
						{"row": 3, "col": 3, "type": "rock", "hp": 2},
						{"row": 3, "col": 4, "type": "rock", "hp": 2},
						{"row": 4, "col": 3, "type": "rock", "hp": 2},
						{"row": 4, "col": 4, "type": "rock", "hp": 2}
					],
					"lockedGems": [
						{"row": 0, "col": 0, "hp": 2},
						{"row": 0, "col": 7, "hp": 2},
						{"row": 7, "col": 0, "hp": 2},
						{"row": 7, "col": 7, "hp": 2}
					]
				},
				{
					"id": "stage_8_4", "name": "时空迷宫", "type": "normal",
					"enemies": ["monster_102", "monster_093", "monster_094"],
					"enemyLevel": 34,
					"rewards": {"gold": 190, "exp": 125}
				},
				{
					"id": "stage_8_5", "name": "时空巨龙", "type": "boss",
					"phases": [
						{"phase": 1, "enemies": ["monster_boss_008"], "trigger": "on_enter"},
						{"phase": 2, "enemies": ["monster_boss_008"], "trigger": "hp_50", "hpMultiplier": 1.5}
					],
					"enemyLevel": 35,
					"rewards": {"gold": 450, "exp": 250}
				}
			]
		},
		{
			"id": "chapter_9",
			"name": "星耀圣殿",
			"element": "star",
			"stages": [
				{
					"id": "stage_9_1", "name": "星耀入口", "type": "normal",
					"enemies": ["monster_093", "monster_094"],
					"enemyLevel": 36,
					"rewards": {"gold": 140, "exp": 90}
				},
				{
					"id": "stage_9_2", "name": "星光回廊", "type": "normal",
					"enemies": ["monster_095", "monster_096"],
					"enemyLevel": 37,
					"rewards": {"gold": 160, "exp": 105}
				},
				{
					"id": "stage_9_3", "name": "星耀祭坛", "type": "normal",
					"enemies": ["monster_097", "monster_098", "monster_099"],
					"enemyLevel": 38,
					"rewards": {"gold": 180, "exp": 120}
				},
				{
					"id": "stage_9_3e", "name": "精英·星耀祭坛", "type": "elite",
					"enemies": ["monster_100", "monster_101"],
					"enemyLevel": 40,
					"eliteMultiplier": 1.5,
					"rewards": {"gold": 370, "exp": 200},
					"obstacles": [
						{"row": 0, "col": 2, "type": "rock", "hp": 2},
						{"row": 0, "col": 5, "type": "rock", "hp": 2},
						{"row": 1, "col": 0, "type": "rock", "hp": 2},
						{"row": 1, "col": 7, "type": "rock", "hp": 2},
						{"row": 6, "col": 0, "type": "rock", "hp": 2},
						{"row": 6, "col": 7, "type": "rock", "hp": 2},
						{"row": 7, "col": 2, "type": "rock", "hp": 2},
						{"row": 7, "col": 5, "type": "rock", "hp": 2}
					],
					"poisonFog": {
						"tiles": [
							{"row": 2, "col": 3},
							{"row": 3, "col": 3},
							{"row": 4, "col": 3},
							{"row": 5, "col": 3},
							{"row": 3, "col": 1},
							{"row": 3, "col": 2},
							{"row": 3, "col": 5},
							{"row": 3, "col": 6},
							{"row": 4, "col": 4},
							{"row": 4, "col": 5},
							{"row": 4, "col": 6}
						],
						"spreadInterval": 4
					}
				},
				{
					"id": "stage_9_4", "name": "星辰迷宫", "type": "normal",
					"enemies": ["monster_102", "monster_093", "monster_094"],
					"enemyLevel": 39,
					"rewards": {"gold": 200, "exp": 135}
				},
				{
					"id": "stage_9_5", "name": "星耀巨龙", "type": "boss",
					"phases": [
						{"phase": 1, "enemies": ["monster_boss_009"], "trigger": "on_enter"},
						{"phase": 2, "enemies": ["monster_boss_009"], "trigger": "hp_50", "hpMultiplier": 1.5}
					],
					"enemyLevel": 40,
					"rewards": {"gold": 500, "exp": 280}
				}
			]
		},
		{
			"id": "chapter_10",
			"name": "混沌领域",
			"element": "chaos",
			"stages": [
				{
					"id": "stage_10_1", "name": "混沌入口", "type": "normal",
					"enemies": ["monster_093", "monster_094"],
					"enemyLevel": 41,
					"rewards": {"gold": 145, "exp": 95}
				},
				{
					"id": "stage_10_2", "name": "混沌回廊", "type": "normal",
					"enemies": ["monster_095", "monster_096"],
					"enemyLevel": 42,
					"rewards": {"gold": 165, "exp": 110}
				},
				{
					"id": "stage_10_3", "name": "混沌祭坛", "type": "normal",
					"enemies": ["monster_097", "monster_098", "monster_099"],
					"enemyLevel": 43,
					"rewards": {"gold": 185, "exp": 125}
				},
				{
					"id": "stage_10_4", "name": "混沌迷宫", "type": "normal",
					"enemies": ["monster_100", "monster_101", "monster_102"],
					"enemyLevel": 44,
					"rewards": {"gold": 205, "exp": 140}
				},
				{
					"id": "stage_10_4e", "name": "精英·混沌祭坛", "type": "elite",
					"enemies": ["monster_093", "monster_094", "monster_095"],
					"enemyLevel": 43,
					"eliteMultiplier": 1.5,
					"rewards": {"gold": 350, "exp": 195},
					"obstacles": [
						{"row": 2, "col": 3, "type": "rock", "hp": 3},
						{"row": 2, "col": 4, "type": "rock", "hp": 3},
						{"row": 3, "col": 3, "type": "rock", "hp": 3},
						{"row": 3, "col": 4, "type": "rock", "hp": 3},
						{"row": 4, "col": 3, "type": "rock", "hp": 3},
						{"row": 4, "col": 4, "type": "rock", "hp": 3},
						{"row": 5, "col": 3, "type": "rock", "hp": 3},
						{"row": 5, "col": 4, "type": "rock", "hp": 3}
					],
					"lockedGems": [
						{"row": 0, "col": 0, "hp": 2},
						{"row": 0, "col": 7, "hp": 2},
						{"row": 1, "col": 0, "hp": 2},
						{"row": 1, "col": 7, "hp": 2},
						{"row": 6, "col": 0, "hp": 2},
						{"row": 6, "col": 7, "hp": 2},
						{"row": 7, "col": 0, "hp": 2},
						{"row": 7, "col": 7, "hp": 2}
					]
				},
				{
					"id": "stage_10_5", "name": "混沌兽神", "type": "boss",
					"phases": [
						{"phase": 1, "enemies": ["monster_boss_010"], "trigger": "on_enter"},
						{"phase": 2, "enemies": ["monster_boss_010"], "trigger": "hp_50", "hpMultiplier": 1.5}
					],
					"enemyLevel": 45,
					"rewards": {"gold": 550, "exp": 300}
				}
			]
		},
		{
			"id": "chapter_11",
			"name": "光耀圣殿",
			"element": "light",
			"stages": [
				{
					"id": "stage_11_1", "name": "光耀入口", "type": "normal",
					"enemies": ["monster_093", "monster_094"],
					"enemyLevel": 46,
					"rewards": {"gold": 150, "exp": 100}
				},
				{
					"id": "stage_11_2", "name": "光耀回廊", "type": "normal",
					"enemies": ["monster_095", "monster_096"],
					"enemyLevel": 47,
					"rewards": {"gold": 170, "exp": 115}
				},
				{
					"id": "stage_11_3", "name": "光耀祭坛", "type": "normal",
					"enemies": ["monster_097", "monster_098", "monster_099"],
					"enemyLevel": 48,
					"rewards": {"gold": 190, "exp": 130}
				},
				{
					"id": "stage_11_4", "name": "光耀迷宫", "type": "normal",
					"enemies": ["monster_100", "monster_101", "monster_102"],
					"enemyLevel": 49,
					"rewards": {"gold": 210, "exp": 145}
				},
				{
					"id": "stage_11_4e", "name": "精英·光耀祭坛", "type": "elite",
					"enemies": ["monster_093", "monster_094", "monster_095"],
					"enemyLevel": 48,
					"eliteMultiplier": 1.5,
					"rewards": {"gold": 380, "exp": 220},
					"obstacles": [
						{"row": 2, "col": 2, "type": "rock", "hp": 3},
						{"row": 2, "col": 5, "type": "rock", "hp": 3},
						{"row": 5, "col": 2, "type": "rock", "hp": 3},
						{"row": 5, "col": 5, "type": "rock", "hp": 3}
					],
					"poisonFog": {
						"tiles": [
							{"row": 0, "col": 0},
							{"row": 0, "col": 1},
							{"row": 0, "col": 6},
							{"row": 0, "col": 7},
							{"row": 1, "col": 0},
							{"row": 1, "col": 7},
							{"row": 1, "col": 2},
							{"row": 1, "col": 5},
							{"row": 2, "col": 3},
							{"row": 2, "col": 4},
							{"row": 5, "col": 3},
							{"row": 5, "col": 4},
							{"row": 6, "col": 2},
							{"row": 6, "col": 5},
							{"row": 7, "col": 0},
							{"row": 7, "col": 7}
						],
						"spreadInterval": 3
					}
				},
				{
					"id": "stage_11_5", "name": "光耀天使长", "type": "boss",
					"phases": [
						{"phase": 1, "enemies": ["monster_boss_011"], "trigger": "on_enter"},
						{"phase": 2, "enemies": ["monster_boss_011"], "trigger": "hp_50", "hpMultiplier": 1.5}
					],
					"enemyLevel": 50,
					"rewards": {"gold": 600, "exp": 350}
				}
			]
		}
	]
}


# ========== 辅助函数 ==========

## 按 chapter_id 获取章节数据，未找到返回空字典
func get_chapter(chapter_id: String) -> Dictionary:
	for ch: Dictionary in STAGES_DATA["chapters"]:
		if ch["id"] == chapter_id:
			return ChapterMechanicRulesScript.enrich_chapter(_expanded_chapter(ch))
	return {}

## 按 stage_id 获取关卡数据（遍历所有章节），未找到返回空字典
func get_stage(stage_id: String) -> Dictionary:
	for ch: Dictionary in STAGES_DATA["chapters"]:
		var chapter := _expanded_chapter(ch)
		for st: Dictionary in chapter["stages"]:
			if st["id"] == stage_id:
				return ChapterMechanicRulesScript.enrich_stage(st, ChapterMechanicRulesScript.enrich_chapter(chapter))
	return {}

## 获取章节总数
func get_chapter_count() -> int:
	return STAGES_DATA["chapters"].size()

## 获取指定章节的关卡列表
func get_stages_in_chapter(chapter_id: String) -> Array:
	var chapter: Dictionary = get_chapter(chapter_id)
	if chapter.is_empty():
		return []
	return chapter.get("stages", [])

## 获取所有章节（JS: export const chapters = STAGES_DATA.chapters）
func get_chapters() -> Array:
	var chapters: Array = []
	for ch: Dictionary in STAGES_DATA["chapters"]:
		chapters.append(ChapterMechanicRulesScript.enrich_chapter(_expanded_chapter(ch)))
	return chapters

static func _expanded_chapter(raw_chapter: Dictionary) -> Dictionary:
	var chapter := raw_chapter.duplicate(true)
	chapter["stages"] = _build_chapter_stages(chapter)
	return chapter

static func _build_chapter_stages(chapter: Dictionary) -> Array:
	var chapter_num := _chapter_number(chapter)
	var normal_seeds: Array = []
	var boss_seed: Dictionary = {}
	for raw_stage: Dictionary in chapter.get("stages", []):
		var stage_type := str(raw_stage.get("type", "normal"))
		if stage_type == "boss":
			boss_seed = raw_stage
		elif stage_type != "elite":
			normal_seeds.append(raw_stage)
	if normal_seeds.is_empty():
		normal_seeds.append({
			"id": "stage_%d_1" % chapter_num,
			"name": TranslationServer.translate("第%d章·%02d") % [chapter_num, 1],
			"type": "normal",
			"enemies": [_fallback_enemy_id(chapter_num)],
			"enemyLevel": _normal_enemy_level(chapter_num, 1),
			"rewards": _normal_rewards(chapter_num, 1)
		})

	var enemy_pool := _enemy_pool_from_seeds(normal_seeds, chapter_num)
	var stages: Array = []
	for stage_no in range(1, NORMAL_STAGES_PER_CHAPTER + 1):
		var seed: Dictionary = normal_seeds[(stage_no - 1) % normal_seeds.size()]
		var stage := seed.duplicate(true)
		stage["id"] = "stage_%d_%d" % [chapter_num, stage_no]
		stage["type"] = "normal"
		stage["stageNo"] = stage_no
		if stage_no > normal_seeds.size():
			stage["name"] = TranslationServer.translate("第%d章·%02d") % [chapter_num, stage_no]
		stage["enemies"] = _enemy_group_for_stage(enemy_pool, stage_no)
		stage["enemyLevel"] = _normal_enemy_level(chapter_num, stage_no)
		stage["maxTurns"] = _normal_max_turns(chapter_num, stage_no)
		stage["rewards"] = _merge_rewards(stage.get("rewards", {}), _normal_rewards(chapter_num, stage_no), chapter_num, stage_no, false)
		stage["designGoal"] = _normal_design_goal(chapter_num, stage_no)
		stage["prepareHint"] = _normal_prepare_hint(chapter_num, stage_no)
		stage["battleHint"] = _normal_battle_hint(chapter_num, stage_no) if chapter_num == 2 else ""
		if stage_no > normal_seeds.size():
			stage["targetLesson"] = _normal_target_lesson(stage_no)
		elif not stage.has("targetLesson"):
			stage["targetLesson"] = _normal_target_lesson(stage_no)
		_clear_generated_pressure(stage)
		_apply_stage_pressure(stage, chapter_num, stage_no, false)
		stages.append(stage)

	stages.append(_build_boss_stage(chapter, boss_seed, enemy_pool))
	return stages

static func _build_boss_stage(chapter: Dictionary, boss_seed: Dictionary, enemy_pool: Array) -> Dictionary:
	var chapter_num := _chapter_number(chapter)
	var boss := boss_seed.duplicate(true) if not boss_seed.is_empty() else {}
	var boss_id := _boss_monster_id(chapter_num)
	boss["id"] = "stage_%d_%d" % [chapter_num, BOSS_STAGE_NO]
	boss["name"] = TranslationServer.translate("第%d章·首领%02d") % [chapter_num, BOSS_STAGE_NO]
	boss["type"] = "boss"
	boss["stageNo"] = BOSS_STAGE_NO
	boss["enemyLevel"] = _boss_enemy_level(chapter_num)
	boss["maxTurns"] = _boss_max_turns(chapter_num)
	if not boss.has("phases") or (boss.get("phases", []) as Array).is_empty():
		boss["phases"] = [
			{"phase": 1, "enemies": [boss_id], "trigger": "on_enter", "hpMultiplier": 1.08 + chapter_num * 0.02},
			{"phase": 2, "enemies": [boss_id], "trigger": "hp_50", "hpMultiplier": 1.32 + chapter_num * 0.03}
		]
	else:
		var phases: Array = []
		for phase: Dictionary in boss.get("phases", []):
			var phase_copy := phase.duplicate(true)
			phase_copy["enemies"] = [boss_id]
			if int(phase_copy.get("phase", 1)) == 1:
				phase_copy["hpMultiplier"] = maxf(float(phase_copy.get("hpMultiplier", 1.0)), 1.08 + chapter_num * 0.02)
			elif int(phase_copy.get("phase", 1)) == 2:
				phase_copy["hpMultiplier"] = maxf(float(phase_copy.get("hpMultiplier", 1.3)), 1.32 + chapter_num * 0.03)
			phases.append(phase_copy)
		boss["phases"] = phases
	boss["enemies"] = [boss_id] if MonsterDb.has_monster(boss_id) else _enemy_group_for_stage(enemy_pool, BOSS_STAGE_NO)
	boss["rewards"] = _merge_rewards(boss.get("rewards", {}), _boss_rewards(chapter_num), chapter_num, BOSS_STAGE_NO, true)
	boss["designGoal"] = TranslationServer.translate("第%d章首领战：在双阶段压力下综合检验本章机制。") % chapter_num
	boss["prepareHint"] = "观察首领意图，保留守护和控制技能，并将爆发留到阶段转换时。"
	boss["battleHint"] = "喷泉旁实际消除水宝石可触发水击；雨区只允许水宝石参与交换与匹配。" if chapter_num == 2 else ""
	boss["targetLesson"] = "boss_break"
	_clear_generated_pressure(boss)
	_apply_stage_pressure(boss, chapter_num, BOSS_STAGE_NO, true)
	return boss

static func _chapter_number(chapter: Dictionary) -> int:
	var chapter_id := str(chapter.get("id", "chapter_1"))
	var parts := chapter_id.split("_")
	if parts.size() >= 2:
		return maxi(1, int(parts[1]))
	return 1

static func _normal_enemy_level(chapter_num: int, stage_no: int) -> int:
	# 难度调整：第一章使用 +1 教学章节加成，第二章起使用 +3。
	var base_level := 5 + (chapter_num - 1) * 5 + floori(float(stage_no - 1) * 5.0 / 10.0)
	var chapter_bonus := 1 if chapter_num == 1 else 3
	return base_level + (0 if chapter_num == 1 and stage_no == 1 else chapter_bonus)

static func _boss_enemy_level(chapter_num: int) -> int:
	var chapter_bonus := 1 if chapter_num == 1 else 3
	return 10 + (chapter_num - 1) * 5 + chapter_bonus

static func _normal_max_turns(chapter_num: int, stage_no: int) -> int:
	# 普通关仍保持短节奏；中后期机制关给少量读盘/清障空间。
	return 22 + int(floor(float(chapter_num - 1) * 0.6)) + int(floor(float(stage_no - 1) / 4.0))

static func _boss_max_turns(chapter_num: int) -> int:
	# Boss 不削血量，用回合预算承载两阶段厚度；后期额外给认真玩家试错空间。
	var late_extra := maxi(0, chapter_num - 6) * 12
	if chapter_num >= 10:
		late_extra += 12
	return 48 + (chapter_num - 1) * 9 + late_extra

static func _chapter_reward_multiplier(chapter_num: int) -> float:
	# Ch1-Ch2 保持新手节奏；从 Ch3 起逐章抬高成长，避免中后期只靠重复扫荡补等级。
	return 1.0 + float(maxi(0, chapter_num - 2)) * 0.06

static func _normal_rewards(chapter_num: int, stage_no: int) -> Dictionary:
	var mult := _chapter_reward_multiplier(chapter_num)
	return {
		"gold": int(round(float(45 + (chapter_num - 1) * 18 + (stage_no - 1) * 12) * mult)),
		"exp": int(round(float(45 + (chapter_num - 1) * 12 + (stage_no - 1) * 9) * mult))
	}

static func _boss_rewards(chapter_num: int) -> Dictionary:
	var last_normal := _normal_rewards(chapter_num, NORMAL_STAGES_PER_CHAPTER)
	return {
		"gold": int(last_normal.get("gold", 0)) + 120 + chapter_num * 18,
		"exp": int(last_normal.get("exp", 0)) + 90 + chapter_num * 14
	}

static func _merge_rewards(seed_rewards: Dictionary, target_rewards: Dictionary, chapter_num: int, stage_no: int, is_boss: bool) -> Dictionary:
	var rewards := target_rewards.duplicate(true)
	rewards["exp"] = _boost_stage_exp(int(rewards.get("exp", 0)))
	if seed_rewards.has("guaranteedItems"):
		rewards["guaranteedItems"] = seed_rewards.get("guaranteedItems", []).duplicate(true)
	if chapter_num == 1 and stage_no == 1:
		rewards["guaranteedItems"] = [{"id": "capture_ball", "count": 1}]
	if chapter_num == 1 and stage_no == 2:
		rewards["guaranteedItems"] = [{"id": "capture_ball", "count": 1}]
	if chapter_num == 1 and is_boss:
		rewards["guaranteedItems"] = [{"id": "capture_ball_plus", "count": 1}]
	return rewards

static func _boost_stage_exp(exp: int) -> int:
	if exp <= 0:
		return 0
	return int(round(float(exp) * STAGE_EXP_REWARD_MULTIPLIER))

static func _enemy_pool_from_seeds(normal_seeds: Array, chapter_num: int) -> Array:
	var configured: Array = CHAPTER_ENEMY_POOLS.get(chapter_num, [])
	if configured.is_empty() and chapter_num > 8:
		configured = CHAPTER_ENEMY_POOLS.get(8, [])
	if not configured.is_empty():
		return configured.duplicate()
	return [_fallback_enemy_id(chapter_num)]

static func _enemy_group_for_stage(pool: Array, stage_no: int) -> Array:
	var count := 1
	if stage_no >= 3 and stage_no <= 5:
		count = 2
	elif stage_no >= 6:
		count = 3
	var group: Array = []
	var candidates := pool.duplicate()
	for _i in count:
		if candidates.is_empty():
			candidates = pool.duplicate()
		var pick_index := randi() % candidates.size()
		group.append(candidates[pick_index])
		candidates.remove_at(pick_index)
	return group

static func _fallback_enemy_id(chapter_num: int) -> String:
	var configured: Array = CHAPTER_ENEMY_POOLS.get(chapter_num, [])
	if configured.is_empty() and chapter_num > 8:
		configured = CHAPTER_ENEMY_POOLS.get(8, [])
	if not configured.is_empty():
		return str(configured[0])
	return "monster_001"

static func _boss_monster_id(chapter_num: int) -> String:
	var boss_id := str(CHAPTER_BOSS_IDS.get(chapter_num, ""))
	if boss_id.is_empty() and chapter_num > 8:
		boss_id = str(CHAPTER_BOSS_IDS.get(8, ""))
	if boss_id.is_empty():
		boss_id = "monster_boss_001"
	return boss_id

static func _normal_target_lesson(stage_no: int) -> String:
	if stage_no <= 2:
		return "basic_flow"
	if stage_no <= 5:
		return "mechanic_intro"
	if stage_no <= 8:
		return "mechanic_combo"
	return "boss_setup"

static func _normal_design_goal(chapter_num: int, stage_no: int) -> String:
	return TranslationServer.translate("第%d章第%02d关：逐步提高敌人数、棋盘压力和奖励节奏，迎接首领战。") % [chapter_num, stage_no]

static func _normal_prepare_hint(chapter_num: int, stage_no: int) -> String:
	if stage_no <= 3:
		return "先读懂敌方意图，稳定完成消除，再决定是否使用技能。"
	if stage_no <= 8:
		return "先判断棋盘压力，再决定清除障碍还是集中输出。"
	return "首领战前哨：保留生命值，并带着明确的技能计划进入下一战。"

static func _normal_battle_hint(chapter_num: int, stage_no: int) -> String:
	if chapter_num == 2 and stage_no >= 2:
		return "喷泉旁实际消除水宝石可触发水击；雨区只允许水宝石参与交换与匹配。"
	return ""

static func _clear_generated_pressure(stage: Dictionary) -> void:
	stage.erase("obstacles")
	stage.erase("fountains")
	stage.erase("fountainRule")
	stage.erase("tideRule")
	stage.erase("iceTiles")
	stage.erase("vines")
	stage.erase("vineRule")
	stage.erase("lockedGems")
	stage.erase("poisonFog")
	stage.erase("eliteMultiplier")
	stage.erase("bossLayers")

static func _apply_stage_pressure(stage: Dictionary, chapter_num: int, stage_no: int, is_boss: bool) -> void:
	if chapter_num == 2 and stage_no >= 2:
		stage["fountains"] = _fountain_pattern(stage_no, is_boss)
		stage["fountainRule"] = _fountain_rule(stage_no, is_boss)
	if chapter_num == 3 and stage_no >= 2:
		stage["vines"] = _vine_pattern(stage_no, is_boss)
		stage["vineRule"] = _vine_rule(stage_no, is_boss)
	if chapter_num == 4 and stage_no >= 2:
		stage["obstacles"] = _rock_pattern(stage_no, is_boss)
	if chapter_num == 5 and stage_no >= 2:
		stage["tideRule"] = _tide_rule(stage_no, is_boss)
	if chapter_num == 6 and stage_no >= 2:
		stage["iceTiles"] = _ice_pattern(stage_no, is_boss)
	if chapter_num in [7, 10] and stage_no >= 5:
		stage["obstacles"] = _rock_pattern(stage_no, is_boss)
	if chapter_num in [8, 10] and stage_no >= 5:
		stage["lockedGems"] = _locked_pattern(stage_no, is_boss)
	if chapter_num in [7, 9, 11] and stage_no >= 5:
		stage["poisonFog"] = _fog_pattern(stage_no, is_boss)

static func _fountain_pattern(stage_no: int, is_boss: bool) -> Array:
	if is_boss:
		return _fountain_positions([[1, 1], [1, 6], [3, 3]])
	var patterns := {
		2: [[3, 3]],
		3: [[2, 2], [5, 5]],
		4: [[1, 1], [1, 6]],
		5: [[1, 1], [1, 6], [3, 3]],
		6: [[2, 2], [5, 5], [3, 3]],
		7: [[1, 1], [1, 6], [5, 5]],
		8: [[2, 2], [5, 5], [1, 6]],
		9: [[1, 1], [1, 6], [2, 2]],
		10: [[1, 1], [3, 3], [5, 5]],
		11: [[1, 6], [3, 3], [5, 5]]
	}
	return _fountain_positions(patterns.get(stage_no, [[2, 2], [5, 5]]))

static func _fountain_positions(coords: Array) -> Array:
	var result: Array = []
	for coord in coords:
		if not coord is Array or coord.size() < 2:
			continue
		result.append({"row": int(coord[0]), "col": int(coord[1])})
	return result

static func _fountain_rule(stage_no: int, is_boss: bool) -> Dictionary:
	return {
		"eruptionCount": 1,
		"range": "orthogonal_1",
		"soakTurns": 1,
		"fireVanishes": false
	}

static func _vine_pattern(stage_no: int, is_boss: bool) -> Array:
	if is_boss:
		return _vine_positions(_vine_unique_positions(_vine_frame(1, 6, 1, 6) + _vine_cross(1, 6)))
	var patterns := {
		2: _vine_side_columns(0, 7),
		3: _vine_diagonal_down(0, 0, 7),
		4: _vine_cross(0, 7),
		5: _vine_frame(1, 6, 1, 6),
		6: _vine_unique_positions(_vine_side_columns(1, 6) + _vine_diagonal_down(0, 0, 7)),
		7: _vine_unique_positions(_vine_frame(1, 6, 1, 6) + _vine_diagonal_up(7, 0, 7)),
		8: _vine_frame(0, 7, 0, 7),
		9: _vine_unique_positions(_vine_frame(1, 6, 1, 6) + _vine_cross(0, 7)),
		10: _vine_unique_positions(_vine_side_columns(0, 7) + _vine_frame(2, 5, 2, 5)),
		11: _vine_unique_positions(_vine_frame(0, 7, 0, 7) + _vine_cross(1, 6))
	}
	var fallback := _vine_unique_positions(_vine_side_columns(0, 7) + _vine_diagonal_down(0, 0, 7))
	return _vine_positions(patterns.get(stage_no, fallback))

static func _vine_side_columns(left_col: int, right_col: int) -> Array:
	var coords: Array = []
	for row in range(8):
		coords.append([row, left_col])
		coords.append([row, right_col])
	return coords

static func _vine_diagonal_down(start_row: int, start_col: int, length: int) -> Array:
	var coords: Array = []
	for i in range(length + 1):
		coords.append([start_row + i, start_col + i])
	return coords

static func _vine_diagonal_up(start_row: int, start_col: int, length: int) -> Array:
	var coords: Array = []
	for i in range(length + 1):
		coords.append([start_row - i, start_col + i])
	return coords

static func _vine_cross(min_index: int, max_index: int) -> Array:
	return _vine_unique_positions(_vine_diagonal_down(min_index, min_index, max_index - min_index) + _vine_diagonal_up(max_index, min_index, max_index - min_index))

static func _vine_frame(top: int, bottom: int, left: int, right: int) -> Array:
	var coords: Array = []
	for col in range(left, right + 1):
		coords.append([top, col])
		coords.append([bottom, col])
	for row in range(top + 1, bottom):
		coords.append([row, left])
		coords.append([row, right])
	return _vine_unique_positions(coords)

static func _vine_unique_positions(coords: Array) -> Array:
	var seen := {}
	var result: Array = []
	for coord in coords:
		if not coord is Array or coord.size() < 2:
			continue
		var key := "%d,%d" % [int(coord[0]), int(coord[1])]
		if seen.has(key):
			continue
		seen[key] = true
		result.append([int(coord[0]), int(coord[1])])
	return result

static func _vine_positions(coords: Array) -> Array:
	var result: Array = []
	for coord in coords:
		if not coord is Array or coord.size() < 2:
			continue
		result.append({"row": int(coord[0]), "col": int(coord[1])})
	return result

static func _vine_rule(stage_no: int, is_boss: bool) -> Dictionary:
	return {
		"backlashPercent": 0.06 if is_boss else 0.04,
		"burnedByAdjacentFire": true,
		"pattern": "thorn_cage" if is_boss else "chapter3_stage_%02d" % stage_no
	}

static func _tide_rule(stage_no: int, is_boss: bool) -> Dictionary:
	if is_boss:
		return {
			"startLevel": 1,
			"risePerTurn": 1,
			"ebbPerTurn": 1,
			"maxLevel": 4,
			"pattern": "island_boss_high_tide"
		}
	var max_level := 1
	var start_level := 0
	if stage_no >= 3:
		max_level = 2
	if stage_no >= 6:
		max_level = 3
	if stage_no >= 9:
		start_level = 1
	return {
		"startLevel": start_level,
		"risePerTurn": 1,
		"ebbPerTurn": 1,
		"maxLevel": max_level,
		"pattern": "island_tide_stage_%02d" % stage_no
	}

static func _ice_pattern(stage_no: int, is_boss: bool) -> Array:
	if is_boss:
		return _ice_positions(_unique_coords([[1, 2], [1, 5], [2, 3], [2, 6], [3, 1], [3, 4], [4, 3], [4, 6], [5, 1], [5, 4], [6, 2], [6, 5]]))
	var patterns := {
		2: [[3, 3], [4, 4]],
		3: [[3, 2], [3, 4], [3, 6]],
		4: [[2, 4], [4, 4], [6, 4]],
		5: [[2, 2], [2, 5], [5, 2], [5, 5]],
		6: [[2, 3], [3, 4], [4, 3], [5, 4]],
		7: [[1, 2], [2, 3], [4, 5], [5, 6], [6, 1]],
		8: [[1, 4], [3, 1], [3, 4], [3, 6], [5, 4], [6, 2]],
		9: [[2, 1], [2, 4], [2, 6], [4, 2], [4, 5], [6, 1], [6, 4], [6, 6]],
		10: [[1, 1], [1, 3], [1, 6], [3, 1], [3, 6], [5, 1], [5, 6], [6, 2], [6, 4]],
		11: [[1, 2], [1, 5], [2, 4], [3, 1], [3, 6], [4, 2], [4, 5], [5, 3], [6, 1], [6, 6]]
	}
	return _ice_positions(patterns.get(stage_no, [[3, 2], [3, 4], [3, 6]]))

static func _line_h(row: int, col_from: int, col_to: int) -> Array:
	var coords: Array = []
	for col in range(col_from, col_to + 1):
		coords.append([row, col])
	return coords

static func _line_v(col: int, row_from: int, row_to: int) -> Array:
	var coords: Array = []
	for row in range(row_from, row_to + 1):
		coords.append([row, col])
	return coords

static func _diagonal_down_coords(row: int, col: int, length: int) -> Array:
	var coords: Array = []
	for i in range(length + 1):
		coords.append([row + i, col + i])
	return coords

static func _diagonal_up_coords(row: int, col: int, length: int) -> Array:
	var coords: Array = []
	for i in range(length + 1):
		coords.append([row - i, col + i])
	return coords

static func _ice_frame(top: int, bottom: int, left: int, right: int) -> Array:
	var coords: Array = []
	for col in range(left, right + 1):
		coords.append([top, col])
		coords.append([bottom, col])
	for row in range(top + 1, bottom):
		coords.append([row, left])
		coords.append([row, right])
	return coords

static func _unique_coords(coords: Array) -> Array:
	var seen := {}
	var result: Array = []
	for coord in coords:
		if not coord is Array or coord.size() < 2:
			continue
		var key := "%d,%d" % [int(coord[0]), int(coord[1])]
		if seen.has(key):
			continue
		seen[key] = true
		result.append([int(coord[0]), int(coord[1])])
	return result

static func _ice_positions(coords: Array) -> Array:
	var result: Array = []
	for coord in coords:
		if not coord is Array or coord.size() < 2:
			continue
		result.append({"row": int(coord[0]), "col": int(coord[1])})
	return result

static func _rock_pattern(stage_no: int, is_boss: bool) -> Array:
	var hp := 3 if is_boss or stage_no >= 10 else 2
	var positions := [
		{"row": 1, "col": 2}, {"row": 1, "col": 5},
		{"row": 3, "col": 1}, {"row": 3, "col": 6},
		{"row": 5, "col": 2}, {"row": 5, "col": 5}
	]
	if is_boss:
		positions.append_array([{"row": 2, "col": 3}, {"row": 2, "col": 4}, {"row": 4, "col": 3}, {"row": 4, "col": 4}])
	var result: Array = []
	var take := mini(positions.size(), 3 + int(stage_no / 2))
	for i in take:
		var pos: Dictionary = positions[i]
		result.append({"row": pos["row"], "col": pos["col"], "type": "rock", "hp": hp})
	return result

static func _locked_pattern(stage_no: int, is_boss: bool) -> Array:
	var hp := 2 if is_boss or stage_no >= 9 else 1
	var positions := [
		{"row": 0, "col": 1}, {"row": 0, "col": 6},
		{"row": 2, "col": 3}, {"row": 2, "col": 4},
		{"row": 5, "col": 3}, {"row": 5, "col": 4},
		{"row": 7, "col": 1}, {"row": 7, "col": 6}
	]
	var result: Array = []
	var take := mini(positions.size(), 2 + int(stage_no / 2))
	for i in take:
		var pos: Dictionary = positions[i]
		result.append({"row": pos["row"], "col": pos["col"], "hp": hp})
	return result

static func _fog_pattern(stage_no: int, is_boss: bool) -> Dictionary:
	var positions := [
		{"row": 1, "col": 1}, {"row": 1, "col": 6},
		{"row": 3, "col": 2}, {"row": 3, "col": 5},
		{"row": 5, "col": 1}, {"row": 5, "col": 6},
		{"row": 6, "col": 3}, {"row": 6, "col": 4}
	]
	var take := mini(positions.size(), 2 + int(stage_no / 2))
	var tiles: Array = []
	for i in take:
		tiles.append((positions[i] as Dictionary).duplicate(true))
	return {
		"tiles": tiles,
		"spreadInterval": 2 if is_boss else maxi(3, 7 - int(stage_no / 2))
	}
