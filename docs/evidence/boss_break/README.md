# 1-5「花叶兽的破招」验收素材

本轮实现：蓄力中的敌人若在敌方回合开始前带着眩晕，则本次蓄力作废（不释放、0 伤害、清空蓄力）；
破招瞬间给「破招」飘字 + 0.2s 短震屏 + 专用破招音效；结算页统计本场破招次数。
未破招时，1-5 仍按既有 `enemySkills.charge` 释放（2.5 × bossCurve 1.5 = 3.75x）。

## 对比口径

- 基线：`eddd1ed`（PR #14 合并后的 main）。
- 改动后：本 PR 分支。
- 同一关卡 `stage_1_5`、同一 750×1334 视口、同一主题、同一截图 harness。
- 战斗截图为同一场景：花叶兽处于蓄力、玩家已施加眩晕、敌方回合结算后 0.12s。
  基线仍释放蓄力（水龟仔受击 -41），改动后显示「破招」且无伤害。
- 结算页截图为同一 payload：胜利、52/70 回合、12 次破招；基线版本忽略未知的 `breakCount` 字段，
  因此只展示原有三列。

## 文件

- `before_break.png`：基线 `eddd1ed`，蓄力 + 眩晕后仍释放，出现 `-41` 伤害与眩晕结束提示。
- `after_break.png`：本分支，同一场景触发「破招」飘字与「破招！花叶兽 的蓄力被打断」。
- `before_result.png`：基线 `eddd1ed` 结算页，只有总伤害 / 已打回合 / 最高连锁三列。
- `after_result.png`：本分支结算页，新增「破招次数 12 次」。
- `test_output.txt`：本次改动后关键回归测试的原始输出。

## 截图命令

```bash
GODOT=~/Applications/Godot.app/Contents/MacOS/Godot

# 改动后：破招瞬间
$GODOT --path . --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=battle --stage-id=stage_1_5 --battle-demo-break=1 \
  --hold-seconds=0.72 --hide-toast=1 \
  --output=docs/evidence/boss_break/after_break.png

# 改动后：带破招次数的结算页
$GODOT --path . --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=result --result-mode=win --result-break-count=12 \
  --result-turns=52 --result-max-turns=70 --result-stage-id=stage_1_5 \
  --output=docs/evidence/boss_break/after_result.png

# 基线：在 eddd1ed 工作树用同一 harness 重跑上面两条命令，输出到 before_*.png。
```

## 破招口径

- 游戏内没有独立的「束缚」状态；破招直接用既有 `stun`（眩晕）实现，并在战斗提示里写明。
- 只有“正在蓄力”的敌人能被破招；普通敌人吃眩晕仍走既有路径，不额外跳过回合。
- 现有 `BattleStatusEffect.process_status_effects` 会在眩晕判定前消耗 1 回合眩晕，因此普通敌人的眩晕
  跳行动本来就未真正生效。本 PR 不改这条既有链路，只在状态消耗前记录蓄力破招，测试断言普攻怪
  动作与未眩晕时逐位一致。
- 未破招时本次蓄力仍按原倍率释放；本 PR 未改 `stage_1_5` / `monster_boss_001` / `bossCurve` 数据。

## 测试

```bash
GODOT=~/Applications/Godot.app/Contents/MacOS/Godot
$GODOT --headless --path . --script res://tests/boss_break_test.gd
$GODOT --headless --path . --script res://tests/battle_sfx_test.gd
$GODOT --headless --path . --script res://tests/battle_result_stats_test.gd
$GODOT --headless --path . --script res://tests/enemy_attack_modes_test.gd
$GODOT --headless --path . --script res://tests/p1_ch1_slice_test.gd
$GODOT --headless --path . --script res://tests/combat_balance_test.gd
```

`tests/boss_break_test.gd` 用固定种子 `2` 跑两条完整 1-5：

1. 全程不破招：43 回合 win，13 次蓄力释放，伤害逐次等于 `eddd1ed` 基线（见 `test_output.txt`）。
2. 蓄力回合改消震能施加眩晕：52 回合 win，0 次释放，12 次破招，总回合数变长。

另外断言：普通怪吃眩晕动作与未眩晕逐位一致、数据化蓄力（×1.9）同样可破、未蓄力 Boss 不触发破招、
战斗场景真实产生「破招」飘字 / 0.2s 震屏 / `break` 音效并写入结算计数。
