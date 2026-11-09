# 主线首通闭环：关卡推进与解锁

本轮只补回归证据：主线首通链路（胜利 → 下一关 → 下一场战斗；关卡选择星级与解锁；失败重打不前进）在基线 `cabcfe1`（PR #10 合并后的 main）已经可用，本分支没有改动 UI 或玩法代码，因此截图是当前实现的运行证据，不涉及前后对比。

## 文件

- `win_result.png`：真实打赢 `stage_1_1` 后的结算页，底部有「返回」「下一关」「再来一次」，星级区 3 星。
- `stage_select_after_clear.png`：从结算页点「返回」回到关卡选择后的第 1 章地图；`stage_1_1` 显示 3 颗点亮星级并出现扫荡入口，`stage_1_2` 已从锁定变为可点（无锁标记，星级为暗色）。
- `lose_result.png`：同一关失败后的结算页，只保留「重打」入口，没有「下一关」。

截图均为真实运行流程，不是静态 mock；除胜负状态不同外，同一 `750×1334` 视口、同一关卡 `stage_1_1`。

> 说明：失败结算页顶部星数仍是战斗评分展示（`calc_battle_stars` 最少返回 1 星），不会写入存档；失败后 `stage_1_1` 的已存星级与 `stage_1_2` 的解锁状态都不前进，由集成测试断言。

## 截图命令

```bash
GODOT=~/Applications/Godot.app/Contents/MacOS/Godot

$GODOT --path . --script res://tests/capture_stage_progress.gd -- \
  --output-dir=docs/evidence/stage_progress
```

## 集成测试

```bash
$GODOT --headless --path . --script res://tests/stage_progress_loop_test.gd
```

`tests/stage_progress_loop_test.gd` 覆盖：

1. `stage_1_1` 胜利 → 结算页「下一关」→ `stage_1_2` 准备页 → 开始战斗进入 `stage_1_2` 战斗，全程有超时断言，中途不卡住；
2. 回到关卡选择后 `stage_1_1` 星级 ≥1、`stage_1_2` 由锁定变可点；随后用 `OS.execute` 拉起一个新的 Godot 进程重新读档，在新进程里再次断言星级、解锁与可点跳转；
3. 失败后只有「重打」，点「重打」回到 `stage_1_1` 准备页并再次进入 `stage_1_1` 战斗，`stage_1_1` 星级、`stage_1_2` / `stage_1_3` 解锁状态与失败前一致。
