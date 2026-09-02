class_name MonsterArtDB
extends RefCounted

const MONSTER_ART := {
	# 早期敌人 ID 的兼容肖像。它们仅用于旧存档、旧关卡和回归路径，
	# 复用同元素的正式精灵图，不进入图鉴物种列表。
	"enemy_001": {"battle": "res://assets/images/monsters/monster/monster_001.png"},
	"enemy_002": {"battle": "res://assets/images/monsters/monster/monster_011.png"},
	"enemy_003": {"battle": "res://assets/images/monsters/monster/monster_002.png"},
	"monster_001": {"battle": "res://assets/images/monsters/monster/monster_001.png"},
	"monster_002": {"battle": "res://assets/images/monsters/monster/monster_002.png"},
	"monster_003": {"battle": "res://assets/images/monsters/monster/monster_003.png"},
	"monster_004": {"battle": "res://assets/images/monsters/monster/monster_004.png"},
	"monster_005": {"battle": "res://assets/images/monsters/monster/monster_005.png"},
	"monster_006": {"battle": "res://assets/images/monsters/monster/monster_006.png"},
	"monster_007": {"battle": "res://assets/images/monsters/monster/monster_007.png"},
	"monster_008": {"battle": "res://assets/images/monsters/monster/monster_008.png"},
	"monster_009": {"battle": "res://assets/images/monsters/monster/monster_009.png"},
	"monster_010": {"battle": "res://assets/images/monsters/monster/monster_010.png"},
	"monster_011": {"battle": "res://assets/images/monsters/monster/monster_011.png"},
	"monster_012": {"battle": "res://assets/images/monsters/monster/monster_012.png"},
	"monster_013": {"battle": "res://assets/images/monsters/monster/monster_013.png"},
	"monster_014": {"battle": "res://assets/images/monsters/monster/monster_014.png"},
	"monster_015": {"battle": "res://assets/images/monsters/monster/monster_015.png"},
	"monster_016": {"battle": "res://assets/images/monsters/monster/monster_016.png"},
	"monster_017": {"battle": "res://assets/images/monsters/monster/monster_017.png"},
	"monster_018": {"battle": "res://assets/images/monsters/monster/monster_018.png"},
	"monster_019": {"battle": "res://assets/images/monsters/monster/monster_019.png"},
	"monster_020": {"battle": "res://assets/images/monsters/monster/monster_020.png"},
	"monster_021": {"battle": "res://assets/images/monsters/monster/monster_021.png"},
	"monster_022": {"battle": "res://assets/images/monsters/monster/monster_022.png"},
	"monster_023": {"battle": "res://assets/images/monsters/monster/monster_023.png"},
	"monster_024": {"battle": "res://assets/images/monsters/monster/monster_024.png"},
	"monster_025": {"battle": "res://assets/images/monsters/monster/monster_025.png"},
	"monster_026": {"battle": "res://assets/images/monsters/monster/monster_026.png"},
	"monster_027": {"battle": "res://assets/images/monsters/monster/monster_027.png"},
	"monster_028": {"battle": "res://assets/images/monsters/monster/monster_028.png"},
	"monster_029": {"battle": "res://assets/images/monsters/monster/monster_029.png"},
	"monster_030": {"battle": "res://assets/images/monsters/monster/monster_030.png"},
	"monster_031": {"battle": "res://assets/images/monsters/monster/monster_031.png"},
	"monster_032": {"battle": "res://assets/images/monsters/monster/monster_032.png"},
	"monster_033": {"battle": "res://assets/images/monsters/monster/monster_033.png"},
	"monster_034": {"battle": "res://assets/images/monsters/monster/monster_034.png"},
	"monster_035": {"battle": "res://assets/images/monsters/monster/monster_035.png"},
	"monster_036": {"battle": "res://assets/images/monsters/monster/monster_036.png"},
	"monster_037": {"battle": "res://assets/images/monsters/monster/monster_037.png"},
	"monster_038": {"battle": "res://assets/images/monsters/monster/monster_038.png"},
	"monster_039": {"battle": "res://assets/images/monsters/monster/monster_039.png"},
	"monster_040": {"battle": "res://assets/images/monsters/monster/monster_040.png"},
	"monster_041": {"battle": "res://assets/images/monsters/monster/monster_041.png"},
	"monster_042": {"battle": "res://assets/images/monsters/monster/monster_042.png"},
	"monster_043": {"battle": "res://assets/images/monsters/monster/monster_043.png"},
	"monster_044": {"battle": "res://assets/images/monsters/monster/monster_044.png"},
	"monster_045": {"battle": "res://assets/images/monsters/monster/monster_045.png"},
	"monster_046": {"battle": "res://assets/images/monsters/monster/monster_046.png"},
	"monster_047": {"battle": "res://assets/images/monsters/monster/monster_047.png"},
	"monster_048": {"battle": "res://assets/images/monsters/monster/monster_048.png"},
	"monster_049": {"battle": "res://assets/images/monsters/monster/monster_049.png"},
	"monster_050": {"battle": "res://assets/images/monsters/monster/monster_050.png"},
	"monster_051": {"battle": "res://assets/images/monsters/monster/monster_051.png"},
	"monster_052": {"battle": "res://assets/images/monsters/monster/monster_052.png"},
	"monster_053": {"battle": "res://assets/images/monsters/monster/monster_053.png"},
	"monster_054": {"battle": "res://assets/images/monsters/monster/monster_054.png"},
	"monster_055": {"battle": "res://assets/images/monsters/monster/monster_055.png"},
	"monster_056": {"battle": "res://assets/images/monsters/monster/monster_056.png"},
	"monster_057": {"battle": "res://assets/images/monsters/monster/monster_057.png"},
	"monster_058": {"battle": "res://assets/images/monsters/monster/monster_058.png"},
	"monster_059": {"battle": "res://assets/images/monsters/monster/monster_059.png"},
	"monster_060": {"battle": "res://assets/images/monsters/monster/monster_060.png"},
	"monster_061": {"battle": "res://assets/images/monsters/monster/monster_061.png"},
	"monster_062": {"battle": "res://assets/images/monsters/monster/monster_062.png"},
	"monster_063": {"battle": "res://assets/images/monsters/monster/monster_063.png"},
	"monster_064": {"battle": "res://assets/images/monsters/monster/monster_064.png"},
	"monster_065": {"battle": "res://assets/images/monsters/monster/monster_065.png"},
	"monster_066": {"battle": "res://assets/images/monsters/monster/monster_066.png"},
	"monster_067": {"battle": "res://assets/images/monsters/monster/monster_067.png"},
	"monster_068": {"battle": "res://assets/images/monsters/monster/monster_068.png"},
	"monster_069": {"battle": "res://assets/images/monsters/monster/monster_069.png"},
	"monster_070": {"battle": "res://assets/images/monsters/monster/monster_070.png"},
	"monster_071": {"battle": "res://assets/images/monsters/monster/monster_071.png"},
	"monster_072": {"battle": "res://assets/images/monsters/monster/monster_072.png"},
	"monster_073": {"battle": "res://assets/images/monsters/monster/monster_073.png"},
	"monster_074": {"battle": "res://assets/images/monsters/monster/monster_074.png"},
	"monster_075": {"battle": "res://assets/images/monsters/monster/monster_075.png"},
	"monster_076": {"battle": "res://assets/images/monsters/monster/monster_076.png"},
	"monster_077": {"battle": "res://assets/images/monsters/monster/monster_077.png"},
	"monster_078": {"battle": "res://assets/images/monsters/monster/monster_078.png"},
	"monster_079": {"battle": "res://assets/images/monsters/monster/monster_079.png"},
	"monster_080": {"battle": "res://assets/images/monsters/monster/monster_080.png"},
	"monster_081": {"battle": "res://assets/images/monsters/monster/monster_081.png"},
	"monster_082": {"battle": "res://assets/images/monsters/monster/monster_082.png"},
	"monster_083": {"battle": "res://assets/images/monsters/monster/monster_083.png"},
	"monster_084": {"battle": "res://assets/images/monsters/monster/monster_084.png"},
	"monster_085": {"battle": "res://assets/images/monsters/monster/monster_085.png"},
	"monster_086": {"battle": "res://assets/images/monsters/monster/monster_086.png"},
	"monster_087": {"battle": "res://assets/images/monsters/monster/monster_087.png"},
	"monster_088": {"battle": "res://assets/images/monsters/monster/monster_088.png"},
	"monster_089": {"battle": "res://assets/images/monsters/monster/monster_089.png"},
	"monster_090": {"battle": "res://assets/images/monsters/monster/monster_090.png"},
	"monster_091": {"battle": "res://assets/images/monsters/monster/monster_091.png"},
	"monster_092": {"battle": "res://assets/images/monsters/monster/monster_092.png"},
	"monster_093": {"battle": "res://assets/images/monsters/monster/monster_093.png"},
	"monster_094": {"battle": "res://assets/images/monsters/monster/monster_094.png"},
	"monster_095": {"battle": "res://assets/images/monsters/monster/monster_095.png"},
	"monster_096": {"battle": "res://assets/images/monsters/monster/monster_096.png"},
	"monster_097": {"battle": "res://assets/images/monsters/monster/monster_097.png"},
	"monster_098": {"battle": "res://assets/images/monsters/monster/monster_098.png"},
	"monster_099": {"battle": "res://assets/images/monsters/monster/monster_099.png"},
	"monster_100": {"battle": "res://assets/images/monsters/monster/monster_100.png"},
	"monster_101": {"battle": "res://assets/images/monsters/monster/monster_101.png"},
	"monster_102": {"battle": "res://assets/images/monsters/monster/monster_102.png"},
	"monster_103": {"battle": "res://assets/images/monsters/monster/monster_103.png"},
	"monster_boss_001": {"battle": "res://assets/images/monsters/boss/monster_boss_001.png"},
	"monster_boss_002": {"battle": "res://assets/images/monsters/boss/monster_boss_002.png"},
	"monster_boss_003": {"battle": "res://assets/images/monsters/boss/monster_boss_003.png"},
	"monster_boss_004": {"battle": "res://assets/images/monsters/boss/monster_boss_004.png"},
	"monster_boss_005": {"battle": "res://assets/images/monsters/boss/monster_boss_005.png"},
	"monster_boss_006": {"battle": "res://assets/images/monsters/boss/monster_boss_006.png"},
	"monster_boss_007": {"battle": "res://assets/images/monsters/boss/monster_boss_007.png"},
	"monster_boss_008": {"battle": "res://assets/images/monsters/boss/monster_boss_008.png"}
}

const ART_USAGES := ["battle", "team", "ranch", "album", "result"]
const MONSTER_ANIMATIONS := {
	"monster_001": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_001/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_002": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_002/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_003": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_003/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_004": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_004/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_005": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_005/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_006": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_006/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_007": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_007/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_008": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_008/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_009": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_009/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_010": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_010/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_011": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_011/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_012": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_012/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_013": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_013/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_014": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_014/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_015": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_015/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_016": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_016/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_018": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_018/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_019": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_019/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_020": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_020/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_022": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_022/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_023": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_023/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_024": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_024/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_025": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_025/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_026": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_026/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_027": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_027/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_028": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_028/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_029": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_029/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_030": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_030/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_031": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_031/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_032": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_032/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_033": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_033/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_034": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_034/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_035": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_035/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_036": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_036/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_037": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_037/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_038": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_038/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_039": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_039/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_040": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_040/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_041": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_041/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_042": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_042/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_043": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_043/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_044": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_044/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_045": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_045/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_046": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_046/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_047": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_047/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_048": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_048/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_049": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_049/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_050": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_050/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_051": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_051/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_052": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_052/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_053": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_053/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_054": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_054/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_055": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_055/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_056": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_056/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_057": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_057/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_058": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_058/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_059": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_059/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_060": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_060/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_061": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_061/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_062": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_062/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_063": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_063/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_064": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_064/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_065": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_065/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_066": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_066/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_067": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_067/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_068": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_068/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_069": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_069/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_070": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_070/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_071": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_071/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_072": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_072/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_073": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_073/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_074": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_074/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_075": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_075/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_076": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_076/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_077": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_077/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_078": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_078/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_079": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_079/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_080": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_080/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_081": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_081/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_082": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_082/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_083": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_083/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_084": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_084/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_085": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_085/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_086": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_086/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_087": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_087/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_088": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_088/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_089": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_089/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_090": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_090/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_091": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_091/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_092": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_092/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_093": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_093/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_094": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_094/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_095": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_095/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_096": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_096/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_097": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_097/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_098": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_098/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_099": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_099/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_100": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_100/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_101": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_101/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_102": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_102/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_103": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/monster/monster_103/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_boss_001": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/boss/monster_boss_001/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_boss_002": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/boss/monster_boss_002/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_boss_003": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/boss/monster_boss_003/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_boss_004": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/boss/monster_boss_004/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_boss_005": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/boss/monster_boss_005/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_boss_006": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/boss/monster_boss_006/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_boss_007": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/boss/monster_boss_007/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
	"monster_boss_008": {
		"idle": {
			"frame_pattern": "res://assets/images/monsters/boss/monster_boss_008/idle/idle_%03d.png",
			"frame_count": 16,
			"fps": 8.0,
			"loop": true,
		},
	},
}
const ANIMATION_ALIASES := {
	"enemy_003": "monster_002",
}

static func get_battle_portrait_path(monster_id: String) -> String:
	return get_art_path(monster_id, "battle")

static func has_battle_portrait(monster_id: String) -> bool:
	var path := get_battle_portrait_path(monster_id)
	return not path.is_empty() and ResourceLoader.exists(path)

static func get_animation_info(monster_id: String, animation_name: String = "idle") -> Dictionary:
	var owner_id := str(ANIMATION_ALIASES.get(monster_id, monster_id))
	var animations: Dictionary = MONSTER_ANIMATIONS.get(owner_id, {})
	var info: Dictionary = animations.get(animation_name, {})
	return info.duplicate(true)

static func has_animation(monster_id: String, animation_name: String = "idle") -> bool:
	var info := get_animation_info(monster_id, animation_name)
	if info.is_empty():
		return false
	var frame_count := int(info.get("frame_count", 0))
	var frame_pattern := str(info.get("frame_pattern", ""))
	return frame_count > 0 and not frame_pattern.is_empty() and ResourceLoader.exists(frame_pattern % 0)

static func get_animation_frame_path(monster_id: String, animation_name: String = "idle", frame_index: int = 0) -> String:
	var info := get_animation_info(monster_id, animation_name)
	var frame_count := int(info.get("frame_count", 0))
	if frame_count <= 0:
		return ""
	var frame_pattern := str(info.get("frame_pattern", ""))
	if frame_pattern.is_empty():
		return ""
	var safe_index := posmod(frame_index, frame_count)
	var path := frame_pattern % safe_index
	return path if ResourceLoader.exists(path) or FileAccess.file_exists(path) else ""

static func get_animation_frame_paths(monster_id: String, animation_name: String = "idle") -> PackedStringArray:
	var result := PackedStringArray()
	var info := get_animation_info(monster_id, animation_name)
	var frame_count := int(info.get("frame_count", 0))
	for frame_index in range(frame_count):
		var path := get_animation_frame_path(monster_id, animation_name, frame_index)
		if path.is_empty():
			return PackedStringArray()
		result.append(path)
	return result

static func get_art_path(monster_id: String, usage: String = "battle") -> String:
	var info: Dictionary = MONSTER_ART.get(monster_id, {})
	if info.is_empty():
		return ""
	if info.has(usage):
		var usage_path := str(info[usage])
		if not usage_path.is_empty() and (ResourceLoader.exists(usage_path) or FileAccess.file_exists(usage_path)):
			return usage_path
	var battle_path := str(info.get("battle", ""))
	if not battle_path.is_empty() and (ResourceLoader.exists(battle_path) or FileAccess.file_exists(battle_path)):
		return battle_path
	return ""

static func get_art_bundle(monster_id: String) -> Dictionary:
	var result := {}
	for usage in ART_USAGES:
		result[usage] = get_art_path(monster_id, usage)
	return result

static func has_art(monster_id: String, usage: String = "battle") -> bool:
	return not get_art_path(monster_id, usage).is_empty()

static func validate_art_coverage(monster_ids: Array) -> Dictionary:
	var missing := []
	for monster_id in monster_ids:
		if not has_art(str(monster_id), "battle"):
			missing.append(str(monster_id))
	return {"missingBattle": missing, "ok": missing.is_empty()}

static func get_album_thumb_path(monster_id: String) -> String:
	return get_battle_portrait_path(monster_id)

static func get_available_usages(monster_id: String) -> Array:
	var info: Dictionary = MONSTER_ART.get(monster_id, {})
	return info.keys()

static func has_monster(monster_id: String) -> bool:
	return MONSTER_ART.has(monster_id)

static func get_all_monster_ids() -> Array:
	return MONSTER_ART.keys()
