# 伤害飘字验收素材

本轮验收素材对应「普通/暴击分开显示 + 同一次三消多段伤害错位」改动。

- `before_3hit.png`：基线 `main`（62fdda6）同一次三消三段伤害的旧表现，三段数字共用同一位置与时间，仅最上层可见。
- `after_3hit.png`：改动后同一场景，普通/暴击颜色、字号与「暴击」标签分开，三段错位显示。
- `after_multi_3hit.png`：三敌人布局下，三段伤害落在敌方血条与玩家卡片之间的空档。
- `damage_demo.gif` / `damage_demo.mp4`：实机战斗界面录屏，先用一次三消打出普通伤害，再打出暴击，可直接看到两种样式。

截图命令（在仓库根目录执行）：

```bash
GODOT=~/Applications/Godot.app/Contents/MacOS/Godot
# 真实对局：固定棋盘，交换 (0,0)/(0,1)，同时形成水 3 消（对火敌人暴击）与火 3 消（普通）
$GODOT --path . --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=battle --stage-id=stage_1_1 --battle-demo-match=1 \
  --settle-frames=33 --output=/tmp/damage_match.png
# 三段伤害演示（同一目标）
$GODOT --path . --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=battle --stage-id=stage_1_1 --battle-demo-damage=1 \
  --settle-frames=22 --output=/tmp/damage_three_hit.png
# 录屏
$GODOT --path . --write-movie /tmp/damage_demo.avi --fixed-fps 30 \
  --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=battle --stage-id=stage_1_1 --battle-demo-match=1 --record-seconds=3.0
```

`before_3hit.png` 在基线工作树中以旧版 `_floating_texts` 数据结构复现同一组三段伤害（同一位置、同一时间、带旧伤害底板），渲染路径与旧版本一致。
