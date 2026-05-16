class_name StageDB
extends RefCounted
## 关卡数据库 - 从 data/stages.js 翻译
## 包含所有章节与关卡数据，供 BattleManager、SaveManager 引用

# ========== 关卡数据库 ==========
const STAGES_DATA: Dictionary = {
	"chapters": [
		{
			"id": "chapter_1",
			"name": "草原之旅",
			"element": "grass",
			"stages": [
				{
					"id": "stage_1_1", "name": "新手训练", "type": "normal",
					"enemies": ["enemy_001"],
					"enemyLevel": 1,
					"rewards": {"gold": 30, "exp": 15}
				},
				{
					"id": "stage_1_2", "name": "草原小径", "type": "normal",
					"enemies": ["enemy_003", "enemy_003"],
					"enemyLevel": 2,
					"rewards": {"gold": 50, "exp": 25}
				},
				{
					"id": "stage_1_3", "name": "草原深处", "type": "normal",
					"enemies": ["enemy_001", "enemy_003"],
					"enemyLevel": 3,
					"rewards": {"gold": 70, "exp": 38}
				},
				{
					"id": "stage_1_4", "name": "灌木迷宫", "type": "normal",
					"enemies": ["enemy_002", "enemy_003"],
					"enemyLevel": 3,
					"rewards": {"gold": 85, "exp": 45}
				},
				{
					"id": "stage_1_5", "name": "花叶兽的领地", "type": "boss",
					"phases": [
						{"phase": 1, "enemies": ["monster_boss_001"], "trigger": "on_enter"},
						{"phase": 2, "enemies": ["monster_boss_001"], "trigger": "hp_50", "hpMultiplier": 1.3}
					],
					"enemyLevel": 3,
					"rewards": {"gold": 100, "exp": 50}
				}
			]
		},
		{
			"id": "chapter_2",
			"name": "烈焰山谷",
			"element": "fire",
			"stages": [
				{
					"id": "stage_2_1", "name": "火山口", "type": "normal",
					"enemies": ["enemy_001", "enemy_001"],
					"enemyLevel": 4,
					"rewards": {"gold": 60, "exp": 35}
				},
				{
					"id": "stage_2_2", "name": "岩浆洞窟", "type": "normal",
					"enemies": ["enemy_001", "enemy_003"],
					"enemyLevel": 5,
					"rewards": {"gold": 80, "exp": 48}
				},
				{
					"id": "stage_2_3", "name": "烈焰荒原", "type": "normal",
					"enemies": ["enemy_002", "enemy_001"],
					"enemyLevel": 5,
					"rewards": {"gold": 95, "exp": 58}
				},
				{
					"id": "stage_2_4", "name": "火焰池", "type": "normal",
					"enemies": ["enemy_003", "enemy_002"],
					"enemyLevel": 6,
					"rewards": {"gold": 110, "exp": 65}
				},
				{
					"id": "stage_2_4e", "name": "精英·烈焰守卫", "type": "elite",
					"enemies": ["enemy_003"],
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
			"name": "神秘森林",
			"element": "dark",
			"stages": [
				{
					"id": "stage_3_1", "name": "暗影小径", "type": "normal",
					"enemies": ["enemy_004", "enemy_006"],
					"enemyLevel": 7,
					"rewards": {"gold": 80, "exp": 45}
				},
				{
					"id": "stage_3_2", "name": "迷雾沼泽", "type": "normal",
					"enemies": ["enemy_004", "enemy_005", "enemy_005"],
					"enemyLevel": 8,
					"rewards": {"gold": 100, "exp": 55}
				},
				{
					"id": "stage_3_3", "name": "暗礁深谷", "type": "normal",
					"enemies": ["enemy_006", "enemy_007", "enemy_008"],
					"enemyLevel": 9,
					"rewards": {"gold": 120, "exp": 70}
				},
				{
					"id": "stage_3_3e", "name": "精英·暗影猎手", "type": "elite",
					"enemies": ["enemy_007"],
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
					"enemies": ["enemy_004", "enemy_007"],
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
			"name": "幽暗森林",
			"element": "dark",
			"stages": [
				{
					"id": "stage_4_1", "name": "幽暗入口", "type": "normal",
					"enemies": ["enemy_009", "enemy_011"],
					"enemyLevel": 11,
					"rewards": {"gold": 90, "exp": 55}
				},
				{
					"id": "stage_4_2", "name": "毒蛛巢穴", "type": "normal",
					"enemies": ["enemy_010", "enemy_010"],
					"enemyLevel": 12,
					"rewards": {"gold": 110, "exp": 65},
					"lockedGems": [
						{"row": 2, "col": 3, "hp": 1},
						{"row": 5, "col": 5, "hp": 1}
					]
				},
				{
					"id": "stage_4_3", "name": "暗翼盘旋", "type": "normal",
					"enemies": ["enemy_009", "enemy_011", "enemy_009"],
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
					"enemies": ["enemy_010", "enemy_011"],
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
					"enemies": ["enemy_011", "enemy_011"],
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
			"name": "雷电圣殿",
			"element": "thunder",
			"stages": [
				{
					"id": "stage_5_1", "name": "雷霆入口", "type": "normal",
					"enemies": ["enemy_012", "enemy_013"],
					"enemyLevel": 16,
					"rewards": {"gold": 100, "exp": 60}
				},
				{
					"id": "stage_5_2", "name": "雷鹰巢穴", "type": "normal",
					"enemies": ["enemy_014", "enemy_014"],
					"enemyLevel": 17,
					"rewards": {"gold": 120, "exp": 75}
				},
				{
					"id": "stage_5_3", "name": "光蝶谷", "type": "normal",
					"enemies": ["enemy_015", "enemy_015", "enemy_016"],
					"enemyLevel": 18,
					"rewards": {"gold": 140, "exp": 90}
				},
				{
					"id": "stage_5_4", "name": "元素风暴", "type": "normal",
					"enemies": ["enemy_012", "enemy_016", "enemy_013"],
					"enemyLevel": 19,
					"rewards": {"gold": 160, "exp": 105}
				},
				{
					"id": "stage_5_3e", "name": "精英·雷暴守卫", "type": "elite",
					"enemies": ["enemy_014", "enemy_016"],
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
			"name": "冰雪王座",
			"element": "ice",
			"stages": [
				{
					"id": "stage_6_1", "name": "寒冰入口", "type": "normal",
					"enemies": ["enemy_017", "enemy_018"],
					"enemyLevel": 21,
					"rewards": {"gold": 110, "exp": 65}
				},
				{
					"id": "stage_6_2", "name": "霜狼巢穴", "type": "normal",
					"enemies": ["enemy_018", "enemy_019"],
					"enemyLevel": 22,
					"rewards": {"gold": 130, "exp": 80},
					"poisonFog": {
						"tiles": [{"row": 2, "col": 3}, {"row": 5, "col": 5}],
						"spreadInterval": 999
					}
				},
				{
					"id": "stage_6_3", "name": "极地冰原", "type": "normal",
					"enemies": ["enemy_019", "enemy_020", "enemy_021"],
					"enemyLevel": 23,
					"rewards": {"gold": 150, "exp": 95},
					"poisonFog": {
						"tiles": [{"row": 1, "col": 2}, {"row": 4, "col": 5}, {"row": 6, "col": 3}],
						"spreadInterval": 4
					}
				},
				{
					"id": "stage_6_4", "name": "冰晶洞穴", "type": "normal",
					"enemies": ["enemy_017", "enemy_021", "enemy_020"],
					"enemyLevel": 24,
					"rewards": {"gold": 170, "exp": 110},
					"poisonFog": {
						"tiles": [{"row": 1, "col": 1}, {"row": 3, "col": 4}, {"row": 5, "col": 2}, {"row": 6, "col": 6}],
						"spreadInterval": 3
					}
				},
				{
					"id": "stage_6_3e", "name": "精英·深渊使者", "type": "elite",
					"enemies": ["enemy_020", "enemy_021"],
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
			"name": "虚空领域",
			"element": "void",
			"stages": [
				{
					"id": "stage_7_1", "name": "虚空入口", "type": "normal",
					"enemies": ["enemy_022", "enemy_023"],
					"enemyLevel": 26,
					"rewards": {"gold": 120, "exp": 70}
				},
				{
					"id": "stage_7_2", "name": "噬魂巢穴", "type": "normal",
					"enemies": ["enemy_023", "enemy_024"],
					"enemyLevel": 27,
					"rewards": {"gold": 140, "exp": 85}
				},
				{
					"id": "stage_7_3", "name": "虚空裂隙", "type": "normal",
					"enemies": ["enemy_024", "enemy_025", "enemy_026"],
					"enemyLevel": 28,
					"rewards": {"gold": 160, "exp": 100}
				},
				{
					"id": "stage_7_3e", "name": "精英·虚空裂隙", "type": "elite",
					"enemies": ["enemy_025", "enemy_026"],
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
					"enemies": ["enemy_022", "enemy_026", "enemy_025"],
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
			"name": "时空裂隙",
			"element": "temporal",
			"stages": [
				{
					"id": "stage_8_1", "name": "时空入口", "type": "normal",
					"enemies": ["enemy_027", "enemy_028"],
					"enemyLevel": 31,
					"rewards": {"gold": 130, "exp": 80}
				},
				{
					"id": "stage_8_2", "name": "时间乱流", "type": "normal",
					"enemies": ["enemy_028", "enemy_029"],
					"enemyLevel": 32,
					"rewards": {"gold": 150, "exp": 95}
				},
				{
					"id": "stage_8_3", "name": "时空漩涡", "type": "normal",
					"enemies": ["enemy_029", "enemy_030", "enemy_031"],
					"enemyLevel": 33,
					"rewards": {"gold": 170, "exp": 110}
				},
				{
					"id": "stage_8_3e", "name": "精英·时空漩涡", "type": "elite",
					"enemies": ["enemy_030", "enemy_031"],
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
					"enemies": ["enemy_027", "enemy_031", "enemy_030"],
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
					"enemies": ["enemy_032", "enemy_033"],
					"enemyLevel": 36,
					"rewards": {"gold": 140, "exp": 90}
				},
				{
					"id": "stage_9_2", "name": "星光回廊", "type": "normal",
					"enemies": ["enemy_033", "enemy_034"],
					"enemyLevel": 37,
					"rewards": {"gold": 160, "exp": 105}
				},
				{
					"id": "stage_9_3", "name": "星耀祭坛", "type": "normal",
					"enemies": ["enemy_034", "enemy_035", "enemy_036"],
					"enemyLevel": 38,
					"rewards": {"gold": 180, "exp": 120}
				},
				{
					"id": "stage_9_3e", "name": "精英·星耀祭坛", "type": "elite",
					"enemies": ["enemy_035", "enemy_036"],
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
					"enemies": ["enemy_032", "enemy_036", "enemy_035"],
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
					"enemies": ["enemy_037", "enemy_038"],
					"enemyLevel": 41,
					"rewards": {"gold": 145, "exp": 95}
				},
				{
					"id": "stage_10_2", "name": "混沌回廊", "type": "normal",
					"enemies": ["enemy_038", "enemy_039"],
					"enemyLevel": 42,
					"rewards": {"gold": 165, "exp": 110}
				},
				{
					"id": "stage_10_3", "name": "混沌祭坛", "type": "normal",
					"enemies": ["enemy_039", "enemy_040", "enemy_041"],
					"enemyLevel": 43,
					"rewards": {"gold": 185, "exp": 125}
				},
				{
					"id": "stage_10_4", "name": "混沌迷宫", "type": "normal",
					"enemies": ["enemy_037", "enemy_041", "enemy_040"],
					"enemyLevel": 44,
					"rewards": {"gold": 205, "exp": 140}
				},
				{
					"id": "stage_10_4e", "name": "精英·混沌祭坛", "type": "elite",
					"enemies": ["enemy_039", "enemy_040", "enemy_041"],
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
					"enemies": ["enemy_042", "enemy_043"],
					"enemyLevel": 46,
					"rewards": {"gold": 150, "exp": 100}
				},
				{
					"id": "stage_11_2", "name": "光耀回廊", "type": "normal",
					"enemies": ["enemy_043", "enemy_044"],
					"enemyLevel": 47,
					"rewards": {"gold": 170, "exp": 115}
				},
				{
					"id": "stage_11_3", "name": "光耀祭坛", "type": "normal",
					"enemies": ["enemy_044", "enemy_045", "enemy_046"],
					"enemyLevel": 48,
					"rewards": {"gold": 190, "exp": 130}
				},
				{
					"id": "stage_11_4", "name": "光耀迷宫", "type": "normal",
					"enemies": ["enemy_042", "enemy_046", "enemy_045"],
					"enemyLevel": 49,
					"rewards": {"gold": 210, "exp": 145}
				},
				{
					"id": "stage_11_4e", "name": "精英·光耀祭坛", "type": "elite",
					"enemies": ["enemy_044", "enemy_045", "enemy_046"],
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
			return ch
	return {}

## 按 stage_id 获取关卡数据（遍历所有章节），未找到返回空字典
func get_stage(stage_id: String) -> Dictionary:
	for ch: Dictionary in STAGES_DATA["chapters"]:
		for st: Dictionary in ch["stages"]:
			if st["id"] == stage_id:
				return st
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
	return STAGES_DATA["chapters"]
