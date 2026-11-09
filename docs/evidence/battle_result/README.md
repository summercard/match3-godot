# 战斗结算页：胜负统计与入口

本轮素材对应「胜利/失败结算页一屏展示本场战绩」改动。

## 对比口径

- 基线：`8c0a56d`（PR #9 合并后的 main）。
- 改动后：本 PR 分支。
- 同一关卡 `stage_1_1`、同一 750×1334 视口、同一份结算数据（小火龙/水龟仔/草苗儿，总伤害 2830，承伤 310/270/225，胜利 7 回合 / 最高 4 连锁，失败 9 回合 / 最高 3 连锁，奖励 45 金币/经验）。
- `before_*` 在基线工作树用同一结算 payload 截图；`after_*` 在改动后截图。

## 文件

- `before_win.png`：基线胜利结算，只有回合、星级、收服、奖励与队伍经验，没有本场伤害/承伤/连锁统计；奖励与队伍经验标题互相压住。
- `after_win.png`：改动后胜利结算，一屏显示本场总伤害、已打回合、最高连锁、每伙伴伤害/承伤、金币经验，并提供「下一关」。
- `before_lose.png`：基线失败结算，只有「重试」入口，页面中段大片留白，没有战斗统计。
- `after_lose.png`：改动后失败结算，同样显示完整战斗统计；入口只保留居中的红色「重打」，不出现「下一关」。

## 截图命令

```bash
GODOT=~/Applications/Godot.app/Contents/MacOS/Godot

# 改动后：胜利 / 失败
$GODOT --path . --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=result --result-mode=win --settle-frames=6 \
  --output=docs/evidence/battle_result/after_win.png
$GODOT --path . --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=result --result-mode=lose --settle-frames=6 \
  --output=docs/evidence/battle_result/after_lose.png

# 基线：在 8c0a56d 工作树上用同一 capture harness 与同一 payload 生成
# （基线场景会忽略新增的统计字段，因此 before 只显示旧版结算内容）。
$GODOT --path /path/to/main-8c0a56d --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=result --result-mode=win --settle-frames=6 --output=/tmp/before_win.png
$GODOT --path /path/to/main-8c0a56d --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=result --result-mode=lose --settle-frames=6 --output=/tmp/before_lose.png
```
