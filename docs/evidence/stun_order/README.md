# 眩晕结算顺序修复验收素材

本轮实现：敌方回合开始时先记录眩晕、再结算状态，最后执行行动。蓄力中的敌人仍走既有破招链路；
普通敌人被眩晕时，当回合整次行动跳过（0 伤害、不选目标、不产生破招），不再在状态被消耗后
二次判定 50% 概率。未改动 `src/data` 下任何数值表。

## 对比口径

- 基线：`54f51a8`（PR #15 合并后的 main）。
- 改动后：本 PR 分支。
- 同一关卡 `stage_1_1`、同一 750×1334 视口、同一主题、同一截图 harness。
- 截图场景：野火虫带 1 回合眩晕，走真实敌方回合，前摇 0.6s 后 0.12s 截图。

| 文件 | 版本 | 说明 |
| --- | --- | --- |
| `before_stun.png` | 基线 `54f51a8` | 眩晕在判定前被消耗，野火虫仍普攻：水龟仔 `-8`、血量 142/150。 |
| `after_stun.png` | 本 PR | 同一场景：野火虫不行动、无伤害飘字，水龟仔保持 150/150。 |

两张图都存在「眩晕效果消失了」的收尾提示，因为 1 回合眩晕在敌方回合开始结算时被消耗；
基线右侧多出 `-8` 伤害与下降的血条，改动后没有伤害，这是本轮修复的可见差异。

## 行为对照

同一固定种子 `424242`、同一队伍、只差敌方是否带眩晕：

| 断言 | 基线 `54f51a8` | 改动后 |
| --- | --- | --- |
| 普攻怪当回合伤害 | 7 | 0 |
| 行动数据 | `attack_mode=strike`，目标水龟仔 | `is_stunned=true`，`target=null` |
| 破招计数 | 0 | 0（普通怪仍不产生破招） |
| 真实 5 雷宝石施加后的当回合伤害 | 38 | 0 |
| 10 点血生存局结束回合 | 10 回合，lose | 11 回合，lose |
| 眩晕命中后二次 50% 判定 | 存在（本次随机未跳过） | 不存在（命中即跳过） |

原始输出：

- `baseline_stun_order.txt`：基线运行 `tests/stun_order_test.gd`，按预期断言失败（exit 1），
  证明修复前「直接挂眩晕仍造成 7 点伤害、5 雷宝石施加后仍造成 38 点伤害、回合数不变」。
- `after_stun_order.txt`：本分支同一脚本全部断言通过（exit 0）。

## 四条平衡线

基线、改动后分别运行 `tests/combat_balance_test.gd` 与 `tests/boss_break_test.gd`，数字逐项一致。

| 指标 | 基线 `54f51a8` | 改动后 | 口径 |
| --- | --- | --- | --- |
| 1 级击杀次数 | 4.00 次三消 | 4.00 次三消 | `stage_1_1` combo=1，20 样本平均 |
| Lv5 承伤 | 12.65 次集中普攻 | 12.65 次集中普攻 | 5 级起步 ×0.75；设计文档口径为 ≤13 |
| Boss 4 连锁回合中位 | `stage_1_5` = 34 | `stage_1_5` = 34 | 3 个固定种子取中位 |
| 1-5 未破招释放伤害 | `[26, 7, 7, 26, 15, 15, 22, 11, 11, 22, 13, 11, 7]` | 同左 | 43 回合 win、13 次释放、倍率 3.75× |

补充：1 级基准的伙伴承伤为 11.25 次，仍在 8-12 窗口内；Lv5 的 12.65 次沿用既有「5 级开局
≤13 次」验收口径，且与基线完全相同。本轮没有改数据表，也没有出现需要调数值的偏差。

各章 Boss combo=4 回合中位（基线 = 改动后）：

| 关卡 | 回合样本 | 中位 |
| --- | --- | --- |
| `stage_1_5` | `[34, 34, 37]` | 34 |
| `stage_2_5` | `[26, 26, 27]` | 26 |
| `stage_3_5` | `[25, 26, 28]` | 26 |
| `stage_4_5` | `[25, 25, 27]` | 25 |
| `stage_5_5` | `[27, 30, 31]` | 30 |
| `stage_6_5` | `[22, 23, 25]` | 23 |
| `stage_7_5` | `[24, 30, 31]` | 30 |
| `stage_8_5` | `[22, 22, 23]` | 22 |
| `stage_9_5` | `[22, 25, 25]` | 25 |
| `stage_10_5` | `[22, 23, 24]` | 23 |
| `stage_11_5` | `[20, 22, 22]` | 22 |

原始输出：`baseline_combat_balance.txt` / `after_combat_balance.txt`；
`baseline_boss_break.txt` / `after_boss_break.txt`。

## 测试

```bash
GODOT=~/Applications/Godot.app/Contents/MacOS/Godot

# 本轮新增的眩晕顺序回归
$GODOT --headless --path . --script res://tests/stun_order_test.gd

# 破招链路未回归（1-5 baseline 43 回合 / 13 次释放；破招局 52 回合 / 12 次破招）
$GODOT --headless --path . --script res://tests/boss_break_test.gd

# 四条平衡线
$GODOT --headless --path . --script res://tests/combat_balance_test.gd
```

基线对照：在 `54f51a8` 工作树放入同一份 `tests/stun_order_test.gd` 后运行即可复现
`baseline_stun_order.txt`（exit 1）；截图使用：

```bash
# 基线：54f51a8 工作树，放入支持 --battle-demo-stun 的采集脚本
$GODOT --path /path/to/baseline-54f51a8 --fixed-fps 60 \
  --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=battle --stage-id=stage_1_1 --battle-demo-stun=1 \
  --hold-seconds=0.72 --hide-toast=1 --output=/tmp/before_stun.png

# 改动后
$GODOT --path . --fixed-fps 60 --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=battle --stage-id=stage_1_1 --battle-demo-stun=1 \
  --hold-seconds=0.72 --hide-toast=1 --output=/tmp/after_stun.png
```

回归测试（全部 exit=0）：`stun_order_test`、`boss_break_test`、`combat_balance_test`、
`enemy_attack_modes_test`、`enemy_windup_test`、`p1_ch1_slice_test`、`battle_rules_test`、
`active_skill_test`、`enemy_intent_test`、`wave_entry_test`、`battle_gui_scene_test`、
`battle_prepare_result_gui_scene_test`、`battle_result_stats_test`、`battle_sfx_test`、
`battle_input_test`、`damage_numbers_test`、`combo_chain_test`、`p0_smoke_test`、
`p0_contract_test`、`stage_progress_loop_test`、`chapter_mechanic_test`。
