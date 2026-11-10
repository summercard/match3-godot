# 伤害飘字与血条扣血升级验收素材

对应「飘字改漫画超粗体 + 描边，血条红条快速落位 / 白段延迟追赶 / 低血脉冲，并带总开关」的改动。
基线：`main` 2f50f09；属性集中在 `src/ui/components/damage_feedback.gd`，总开关为
`DamageFeedback.enabled`。

## 总开关

| 状态 | 飘字 | 血条 | 证据 |
| --- | --- | --- | --- |
| 开启（默认） | Impact → Arial Black → sans-serif 链，字重 900，近黑 #050508 描边，字号 21 / 26 / 32 | 红条 0.08s 落位；白段落旧值停 0.22s，再按 0.55 条/秒追；<30% 时红条 1.2Hz / 8% 脉冲 | `on.gif`、`drain_on.gif` |
| 关闭 | 回到基线 2f50f09：字号 21 / 28 / 28、旧上升、无描边、无调用方随机量 | 回到基线 0.25s 缓降，无白段、无脉冲 | `off.gif`、`drain_off.gif` |

- `off.gif` 与 `before.gif` 字节一致（MD5 `bfba1f6323f5cd4ad57ad319e746bfae`）。
- `drain_off.gif` 与 `drain_before.gif` 字节一致（MD5 `24d72f56ef9236e835cf86dd83f83edb`）。
- 固定战局 `stage_1_1`、seed `20261109`、20 回合脚本的逐回合伤害日志、承伤日志与结算
  JSON，在开关开 / 关两种状态都与基线 2f50f09 逐字节一致（`baseline_combat_log.json`）。

## 证据文件

| 文件 | 说明 |
| --- | --- |
| `before.gif` | 基线 2f50f09 真实三消：旧字号 21/28/28、无描边、血条直接跳到新值。 |
| `on.gif` | 本分支、总开关开启：同一战局的漫画飘字 + 血条白段。暴击 `-50` 用 32px + 「暴击」，重击 `-45` 用 26px。 |
| `off.gif` | 本分支、总开关关闭；与 `before.gif` 字节一致。 |
| `drain_on.gif` | 敌方 1000 HP 一次掉到 250：红条 0.08s 落位、白段停 0.22s 后按 0.55 条/秒追上，<30% 后红条脉冲。 |
| `drain_off.gif` / `drain_before.gif` | 同一掉血的基线表现（0.25s 缓降、无白段）；两者字节一致。 |
| `before_popup_sample.png` / `after_popup_sample.png` | 同一画面三档飘字（普通 / 重击 / 暴击）截图，用于量测字号与描边。 |
| `popup_metrics.png` | 上面两张截图的飘字行放大对照。 |
| `baseline_combat_log.json` | 基线 2f50f09 生成的战斗日志与结算 JSON 基线。 |

## 飘字量测（750×1334 截图，设计尺寸 375×667，2x）

截图冻结在飘字 0.4s（弹出已回落到 1.0 倍、尚未淡出）。用
`tools/measure_damage_popup.gd` 量字身填充色包围盒与近黑描边：

| 样式 | 配置字号（设计 px） | 改动前字身高度（设计 px） | 改动后字身高度（设计 px） | 改动前描边 | 改动后近黑描边（设备 px，中位 / 最大） |
| --- | --- | --- | --- | --- | --- |
| 普通 | 21 | 15.0 | 17.0 | 0（旧版深蓝投影，非近黑） | 2.0 / 8 |
| 重击（伤害>=40） | 26 | 20.0（旧 28） | 21.0 | 0 | 2.5 / 8 |
| 暴击 | 32 | 20.5（旧 28） | 26.0 | 0 | 3.0 / 6 |

- 字体：`SystemFont` 链 `Impact → Arial Black → sans-serif`，`font_weight = 900`，链尾保留泛型族名；
  系统缺字时由 `allow_system_fallback` 回退。
- 描边：`#050508`，普通 2、重击 / 暴击 3 设计像素；`draw_string_outline` 的 size 按光栅像素计，
  绘制时乘 2x 画布缩放，截图里近黑核心中位 2–3 设备像素（含抗锯齿过渡约 4–6）。
- 字号与重击判定：普通 21、伤害 >= 40 用 26、暴击 32；时长 0.85s（暴击 0.95s）。

## 掉血曲线与命中帧检查

`tests/damage_feedback_test.gd` 的输出：

```text
[DamageFeedback] 掉 30%：0.10s 红条=70.00 白段=100.00（要求白段 >= 98）
[DamageFeedback] 掉 30%：1.0s 红条=70.00 白段=70.00（要求白段明显缩短）
[DamageFeedback] 满格到 0：白段追赶 1.817s（1/0.55=1.82s），含 0.22s 停留总时长 2.050s
[DamageFeedback] 命中帧=21 首个伤害飘字帧=21
[DamageFeedback] OK
```

- 掉 30% 血时 0.10s 白段仍为 100%（要求 >= 原值−2%）。
- 1.0s 时白段已从 100% 缩到 70%，明显缩短。
- 满格到 0 的白段追赶时长 1.817s（1.8s±0.2s；`0.55 条/秒` = 1/0.55 = 1.82s，不含 0.22s 停留）。
- 固定交换下命中帧与首个伤害飘字帧同为第 21 帧，命中前没有任何伤害飘字；飘字 0.04s 快显，
  命中帧当帧不透明度为 0。

## 复现命令（仓库根目录）

```bash
GODOT=~/Applications/Godot.app/Contents/MacOS/Godot

# 截图：三档飘字样张（总开关开启）
$GODOT --path . --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=battle --stage-id=stage_1_1 --battle-popup-sample=1 \
  --settle-frames=2 --output=/tmp/after_popup_sample.png

# 截图：同一张样张在基线 2f50f09 工作树（拷入同一 capture 脚本）
$GODOT --path /path/to/baseline-2f50f09 --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=battle --stage-id=stage_1_1 --battle-popup-sample=1 \
  --settle-frames=2 --output=/tmp/before_popup_sample.png

# 真实三消录像（开 / 关）
$GODOT --path . --write-movie /tmp/match_on.avi --fixed-fps 60 \
  --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=battle --stage-id=stage_1_1 --battle-demo-match=1 --record-seconds=2.6
$GODOT --path . --write-movie /tmp/match_off.avi --fixed-fps 60 \
  --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=battle --stage-id=stage_1_1 --battle-demo-match=1 \
  --damage-feedback=off --record-seconds=2.6

# 血条白段录像（开 / 关）
$GODOT --path . --write-movie /tmp/drain_on.avi --fixed-fps 60 \
  --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=battle --stage-id=stage_1_1 --battle-demo-drain=1 --record-seconds=3.0
$GODOT --path . --write-movie /tmp/drain_off.avi --fixed-fps 60 \
  --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=battle --stage-id=stage_1_1 --battle-demo-drain=1 \
  --damage-feedback=off --record-seconds=3.0

# 转 GIF（与提交文件同参数）
ffmpeg -i /tmp/match_on.avi -vf "trim=start_frame=10:end_frame=140,setpts=PTS-STARTPTS,\
crop=750:430:0:0,scale=562:322:flags=lanczos,fps=40,\
split[a][b];[a]palettegen=max_colors=160:stats_mode=diff[p];[b][p]paletteuse=dither=none" \
  -loop 0 on.gif
ffmpeg -i /tmp/drain_on.avi -vf "trim=start_frame=6:end_frame=160,setpts=PTS-STARTPTS,\
crop=750:340:0:0,scale=562:255:flags=lanczos,fps=40,\
split[a][b];[a]palettegen=max_colors=160:stats_mode=diff[p];[b][p]paletteuse=dither=none" \
  -loop 0 drain_on.gif
```

## 验证

```bash
$GODOT --headless --path . --fixed-fps 60 --script res://tests/damage_feedback_test.gd
$GODOT --headless --path . --fixed-fps 60 --script res://tests/damage_numbers_test.gd
$GODOT --headless --path . --fixed-fps 60 --script res://tests/battle_hit_reaction_test.gd
$GODOT --headless --path . --fixed-fps 60 --script res://tests/battle_gui_scene_test.gd
$GODOT --headless --path . --fixed-fps 60 --script res://tests/battle_result_stats_test.gd
$GODOT --headless --path . --fixed-fps 60 --script res://tests/combat_balance_test.gd
$GODOT --headless --path . --fixed-fps 60 --script res://tests/boss_break_test.gd
$GODOT --headless --path . --fixed-fps 60 --script res://tests/stun_order_test.gd
$GODOT --headless --path . --fixed-fps 60 --script res://tests/battle_rules_test.gd
$GODOT --headless --path . --fixed-fps 60 --script res://tests/match_hit_feedback_test.gd
$GODOT --headless --path . --fixed-fps 60 --script res://tests/combo_chain_test.gd
```

`tests/damage_feedback_test.gd` 覆盖：字体链 / 字重 / 字号 / 描边 / 上升 / 时长 / 快显 / 淡出 / 错峰 / 层数；
调用方随机量范围与同 context 逐位一致；血条红条落位、白段停留与追赶、回血 / 换兵对齐、
<30% 脉冲、总开关关闭的基线路径；开关开 / 关的固定战局日志与结算 JSON 与基线文件逐字节比对；
真实战斗场景中命中帧之前无飘字、命中帧当帧生成飘字。

`tests/battle_hit_reaction_test.gd` 的 0.25s 血条缓降用例显式在 `DamageFeedback.enabled = false`
下运行——0.25s 缓降现在就是伤害反馈总开关关闭时的基线路径。
