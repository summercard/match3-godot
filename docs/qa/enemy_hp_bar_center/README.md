# 敌方单体血条居中

改动只移动单体怪血条控件组的锚点位置：`src/ui/scenes/battle/enemy_stage_slot.tscn` 中
`HpBar` / `HpFrame` / `HpText` / `Orb` / `Beads` 五个节点整体左移 74px，让控件组水平居中于 375 设计宽度。
血条尺寸、字号、`battle_hp_bar.gd` 的 0.08/0.22/0.55 缓降与低血脉冲均未触碰；多敌卡片的血条本来就居中，未改。

| 版本 | 提交 | 说明 |
| --- | --- | --- |
| before | `37b5277`（main） | 血条控件组中心在 261.5，偏右 74px |
| after | `0c7f003`（本分支） | 控件组整体左移 74px，中心回到 187.5 |

## 画面证据

- `before.png` / `after.png`：同一战局 `stage_1_1`、同一种子 `20261109`、同一 750×1334 视口、fixed-fps 60 的整屏截图。
- `comparison.png`：同一区域上下对照；白虚线为设计中心 x=187.5（2x 渲染下 375px），蓝框为血条控件组外接框（元素球左边到血条边框右边）。

| 项目 | before | after | 变化 |
| --- | --- | --- | --- |
| 元素球 `Orb` | x 174–213 | x 100–139 | −74 |
| 血条 `HpBar` | x 199–343 | x 125–269 | −74 |
| 血条边框 `HpFrame` | x 193–349 | x 119–275 | −74 |
| 血量文字 `HpText` | x 221–321 | x 147–247 | −74 |
| 血珠 `Beads` | x 209–298 | x 135–224 | −74 |
| 控件组外接框中心 | 261.5 | 187.5 | −74 |
| 血条（`HpBar`）尺寸 | 144×14 | 144×14 | 不变 |
| 边框（`HpFrame`）宽 | 156 | 156 | 不变 |
| 血量文字字号 | 10 | 10 | 不变 |
| 血珠字号 | 12 | 12 | 不变 |

逐像素对比：before 与 after 只有 y=156–240（血条控件组所在条带）不同，棋盘、HUD、立绘、我方血条等其余像素一致。

## 复现与校验

```bash
GODOT=~/Applications/Godot.app/Contents/MacOS/Godot

# 截图（同一命令分别在工作树 37b5277 与 0c7f003 执行）
$GODOT --path . --fixed-fps 60 --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=battle --stage-id=stage_1_1 --hide-toast=1 --output=/tmp/enemy_hp_bar.png

# 回归测试
$GODOT --headless --path . --fixed-fps 60 --script res://tests/battle_gui_scene_test.gd
$GODOT --headless --path . --fixed-fps 60 --script res://tests/damage_feedback_test.gd
$GODOT --headless --path . --fixed-fps 60 --script res://tests/battle_hit_reaction_test.gd
```

测试输出：

```text
[BattleGuiScene] OK
[DamageFeedback] 掉 30%：0.10s 红条=70.00 白段=100.00（要求白段 >= 98）
[DamageFeedback] 满格到 0：白段追赶 1.817s（1/0.55=1.82s），含 0.22s 停留总时长 2.050s
[DamageFeedback] OK
[BattleHitReaction] OK
```

`tests/battle_gui_scene_test.gd` 新增断言：单体血条控件组外接框中心为 187.5；血条保持 144×14、边框宽 156、血量文字字号 10。

## 未改动范围

- 未改 `battle_hp_bar.gd` / `damage_feedback.gd` / `battle_hit_reaction.gd`，0.08/0.22/0.55 缓降与低血脉冲参数原样。
- 未改多敌卡片血条（`enemy_slot.tscn`）、我方血条、棋盘、HUD、战斗数值与流程。
- 未改字号、描边、颜色与血条尺寸。
