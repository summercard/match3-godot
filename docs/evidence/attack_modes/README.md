# 敌人出手模式与前摇差异验收素材

本轮素材对应「数据化敌人出手模式（strike / charge / sweep）+ 蓄力专属前摇」。

## 对比口径

- 基线：`ae39d11`（PR #6 合并后的 main，前摇只有普通红色箭头）。
- 改动后：本 PR 分支。
- 同一关卡 `stage_3_3`、同一 750×1334 视口、同一随机种子 `20261109`、同一队伍与满血状态。
- 前摇帧均在敌方结算前 0.2 秒截取；`before_windup.png` 是基线在同一关卡、同一满血状态的普通前摇。
- 为单独验证前摇视觉，`after_*` 三张用 capture harness 固定为对应模式；实际模式由 `stage_3_3` / `enemy_006` 的轮次数据（strike → charge → sweep）触发，`after_charge_rotation.png` 与 `after_sweep_rotation.png` 是未强制模式的真实轮次截图。

## 文件

- `comparison.png`：四格并排对比图（基线 / 单体重击 / 蓄力 / 全体）。
- `before_windup.png`：基线普通前摇（红色箭头）。
- `after_strike.png`：直接单体重击前摇，保持红色箭头。
- `after_charge.png`：蓄力前摇，紫色箭头 + 紫色圆牌金色闪电。
- `after_sweep.png`：全体攻击前摇，青色箭头 + 青色圆牌三箭头。
- `after_charge_rotation.png`：真实轮次第 2 回合，蓄力前摇（队伍已被第 1 回合普攻压血）。
- `after_sweep_rotation.png`：真实轮次第 4 回合，全体攻击前摇（蓄力回合未出伤，释放后进入全体轮次）。

## 截图命令

```bash
GODOT=~/Applications/Godot.app/Contents/MacOS/Godot

# 改动后：三种前摇（同一满血状态，强制模式隔离视觉）
$GODOT --path . --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=battle --stage-id=stage_3_3 --battle-demo-windup=1 \
  --battle-demo-attack-mode=strike --hold-seconds=0.2 --hide-toast=1 \
  --output=docs/evidence/attack_modes/after_strike.png
$GODOT --path . --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=battle --stage-id=stage_3_3 --battle-demo-windup=1 \
  --battle-demo-attack-mode=charge --hold-seconds=0.2 --hide-toast=1 \
  --output=docs/evidence/attack_modes/after_charge.png
$GODOT --path . --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=battle --stage-id=stage_3_3 --battle-demo-windup=1 \
  --battle-demo-attack-mode=sweep --hold-seconds=0.2 --hide-toast=1 \
  --output=docs/evidence/attack_modes/after_sweep.png

# 改动后：真实轮次（第 2 回合蓄力、第 4 回合全体）
$GODOT --path . --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=battle --stage-id=stage_3_3 --battle-demo-windup=1 \
  --battle-demo-enemy-turns=1 --hold-seconds=0.2 --hide-toast=1 \
  --output=docs/evidence/attack_modes/after_charge_rotation.png
$GODOT --path . --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=battle --stage-id=stage_3_3 --battle-demo-windup=1 \
  --battle-demo-enemy-turns=3 --hold-seconds=0.2 --hide-toast=1 \
  --output=docs/evidence/attack_modes/after_sweep_rotation.png
```

基线 `before_windup.png` 在 `ae39d11` 工作树上用同一 capture harness 的普通前摇分支生成；基线没有攻击模式数据，因此三次敌方行动都是普通红色箭头。
