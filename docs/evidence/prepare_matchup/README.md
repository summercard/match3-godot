# 战斗准备页：属性克制分析

准备页原来在无章节机制提示时回落到「属性无明显克制关系」。现在改为读取现有克制倍率，
按敌方属性 × 每个上阵伙伴属性生成一句克制结论，并接在准备页「关卡机制」提示的第三行；
来源较多时同一句在「；」处折到第四行。

## 口径

- 基线：`893c7a1`（PR #20 合并后的 main）。
- 改动后：`agent/prepare-matchup-analysis-add28b30da9a`。
- 运行环境：Godot `4.7.2.stable`，macOS Apple M1，默认主题。
- 截图口径：`750×1334` 渲染（375×667 逻辑视口），`--fixed-fps 60`，同一截图 harness，
  `--settle-frames=6`，临时 `MATCH3_SAVE_PATH` 保证三只初始伙伴（小火龙 / 水龟仔 / 草苗儿）。
- 强 / 弱 / 中性：`倍率 >= 1.2` 算强，`<= 0.8` 算弱，其余中性。
- 倍率来源：只调用 `MonsterDb.get_element_multiplier`，与 `BattleManager` 的玩家伤害读取
  的是同一张表；本文件没有复制第二张克制表，`monster_db.gd`、`damage_calculator.gd`
  与 `src/data` 均零改动。
- 文案格式：`属性A克属性B：伙伴 +X%` / `属性A被属性B克：伙伴 -X%`；多个来源用「；」
  合成一句。同一敌方属性只展开一次，避免多只同类敌人重复同一句。

## 改动

`src/ui/scene/scene_battle_prepare.gd`

- 新增 `classify_element_matchup`、`_build_element_matchup_report`，按敌方属性 × 上阵伙伴
  逐个读取现有倍率并生成强 / 弱 / 中性条目与一句话文案。
- `_get_element_hint` 在章节机制摘要、关卡提示 / Boss 三层提示之后追加克制结论。
- 补齐 13 个幻想属性的中文名，保证冰、虚空、时空等属性的结论不出现英文键名。

`src/ui/scene/scene_battle_prepare_gui.gd`、`src/ui/scenes/battle_prepare.tscn`

- 「关卡机制」面板增加第三行 `MechanicPanel/Line3` 显示克制结论；来源较多时在同一句的
  「；」处折到第四行 `MechanicPanel/Line4`，避免横向裁切。全中性时用弱化颜色显示
  「属性无明显克制关系」，有强 / 弱来源时用提示色显示。

## 截图

同一关卡、同一视角、同一默认队伍。

| 场景 | 基线 `893c7a1` | 改动后分支 |
| --- | --- | --- |
| 有明显克制：`stage_2_1` | ![before clear](before_clear.png) | ![after clear](after_clear.png) |
| 全中性：`stage_5_2` | ![before neutral](before_neutral.png) | ![after neutral](after_neutral.png) |

- `stage_2_1`（敌方火 × 火 / 水 / 草伙伴）：基线的第三行不存在；改动后显示
  `水克火：水龟仔 +50%；草被火克：草苗儿 -25%`。
- `stage_5_2`（敌方雷 × 火 / 水 / 草伙伴）：全部中性，改动后显示
  `属性无明显克制关系`。

复现命令：

```bash
GODOT=~/Applications/Godot.app/Contents/MacOS/Godot

# 基线：893c7a1 工作树
MATCH3_SAVE_PATH=/tmp/prepare_before_clear.cfg \
  $GODOT --path /tmp/match3-prepare-baseline --fixed-fps 60 \
  --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=battle_prepare --stage-id=stage_2_1 --settle-frames=6 \
  --hide-toast=1 --output=before_clear.png

# 改动后
MATCH3_SAVE_PATH=/tmp/prepare_after_clear.cfg \
  $GODOT --path . --fixed-fps 60 \
  --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=battle_prepare --stage-id=stage_2_1 --settle-frames=6 \
  --hide-toast=1 --output=after_clear.png
```

`stage_5_2` 只需替换 `--stage-id` 与输出文件名。

## 全属性断言

`tests/prepare_matchup_test.gd` 遍历 `MonsterDBScript.ELEMENT_CHART` 的全部 13 个属性，
共 169 组敌方属性 × 伙伴属性：

- 对每组单独渲染准备页文案，断言强 / 弱 / 中性与 `MonsterDb.get_element_multiplier`
  的倍率一致；
- 强来源必须显示 `+X%`，弱来源必须显示 `-X%`，中性来源不得写入文案；
- 再以真实 `battle_prepare.tscn` 校验 `MechanicPanel/Line1`、`Line2`、`Line3`、
  `Line4`：关卡机制与关卡提示保持原样，克制结论写在 `Line3`；两来源不进 `Line4`，
  四来源长句在「；」处折到 `Line3 + Line4`；全中性时 `Line3` 显示
  「属性无明显克制关系」且 `Line4` 为空。

原始输出：[test_output.txt](test_output.txt)

```bash
GODOT=~/Applications/Godot.app/Contents/MacOS/Godot
$GODOT --headless --path . --script res://tests/prepare_matchup_test.gd
```

## 战斗日志与结算逐字节一致

用固定种子 `20261111`、`stage_1_1`、5 级初始三只伙伴跑同一局：

- 基线 `893c7a1` 生成 [battle_before.json](battle_before.json)；
- 改动后生成 [battle_after.json](battle_after.json)；
- `cmp` 无输出，两个文件 SHA-256 均为
  `0d6d3c718332bd2a09e2bf44b9f1116d23d6fd962216cc3fa77fb93153490adb`；
- 同一份基线 JSON 已放入 `tests/fixtures/prepare_matchup_battle_baseline.json`，
  `prepare_matchup_test` 每次运行都会重新生成并逐字节比对，`battle_transcript_identical=true`。

```bash
GODOT=~/Applications/Godot.app/Contents/MacOS/Godot
$GODOT --headless --path . --script res://tests/prepare_matchup_transcript.gd \
  -- --output=/tmp/prepare_matchup_battle_after.json
cmp tests/fixtures/prepare_matchup_battle_baseline.json /tmp/prepare_matchup_battle_after.json
```

## 四条平衡线

基线 `893c7a1` 与改动后分支分别运行：

- `combat_balance_test`
- `boss_break_test`
- `stun_order_test`
- `battle_rules_test`

[balance_lines_before.txt](balance_lines_before.txt) 与
[balance_lines_after.txt](balance_lines_after.txt) 逐字节一致，
[balance_lines.diff](balance_lines.diff) 为空文件。四条平衡线数值未变。

## 本轮跑过的回归（全部 exit 0）

`prepare_matchup_test`、`chapter_mechanic_test`、`battle_prepare_result_gui_scene_test`、
`p1_ch1_slice_test`、`p0_smoke_test`、`p0_contract_test`、`stage_progress_loop_test`、
`battle_gui_scene_test`、`combat_balance_test`、`boss_break_test`、`stun_order_test`、
`battle_rules_test`。

## 约束核对

- `src/data` 零 diff；`monster_db.gd`、`damage_calculator.gd` 零 diff，克制表与倍率未改。
- 没有第二张克制表：判定和百分比都来自 `MonsterDb.get_element_multiplier`。
- 战斗代码、伤害、承伤、回合、随机序列未改；固定种子日志与结算逐字节一致。
- 截图是真实应用运行截图，未使用设计稿或拼图。
