# 三消消除命中反馈验收素材

对应「普通消除：顿帧 60–90ms、棋盘位移 ≤6px、整段 ≤0.15s；4 连锁及以上：顿帧 120–160ms、位移 ≤10px；参数集中一处并带总开关」的命中反馈改动。

- 参数与总开关：`src/ui/components/match_hit_feedback.gd`（`CONFIG` + `enabled`）。
- 总开关关闭后不插入额外等待、不产生震屏/光斑/爆散，消除时序回到旧版。

| 文件 | 说明 |
| --- | --- |
| `before.gif` | 基线 `868a887`，命中瞬间没有顿帧、震屏或爆散，消除动画在交换同帧直接开始。 |
| `on.gif` | 本 PR 分支，总开关开启：命中瞬间冻帧，命中格出现元素爆散光斑与粒子并微震屏，随后才进入原消除动画。 |
| `off.gif` | 本 PR 分支，总开关关闭；与 `before.gif` 逐帧一致（两条录像 MD5 均为 `71bb91c8404e82dc7925049e2f508a4f`，GIF 也字节一致）。 |
| `hit_compare.png` | 同一帧 Before / After(ON) 对照：左侧基线已进入消除动画，右侧停在顿帧并显示元素爆散。 |

## 参数口径

| 档位 | 顿帧 | 棋盘位移 | 整段（顿帧 + 震屏 / 光斑） |
| --- | --- | --- | --- |
| 普通消除（1–3 连锁） | 75ms（60–90ms） | 5px（≤6px） | 140ms（≤150ms） |
| 4 连锁及以上 | 140ms（120–160ms） | 9px（≤10px） | 240ms |

- 位移按设计像素计；每帧位移长度不超过配置振幅。
- 顿帧期间画面动画冻结，只让命中震屏与爆散粒子/光斑继续播放。
- 普通档「整段」取 `max(顿帧 + 震屏, 光斑时长 = 0.14s)`，即 0.14s。

## 复现命令（仓库根目录）

```bash
GODOT=~/Applications/Godot.app/Contents/MacOS/Godot

# After / 开关开启
$GODOT --path . --write-movie /tmp/hit_on.avi --fixed-fps 60 \
  --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=battle --stage-id=stage_1_1 --battle-demo-hit=1 --record-seconds=1.2

# After / 开关关闭
$GODOT --path . --write-movie /tmp/hit_off.avi --fixed-fps 60 \
  --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=battle --stage-id=stage_1_1 --battle-demo-hit=1 \
  --match-hit-feedback=off --record-seconds=1.2

# Before：在 868a887 工作树上用同一份 capture 脚本录制（基线没有命中反馈，无需开关参数）
$GODOT --path /path/to/baseline-868a887 --write-movie /tmp/hit_before.avi --fixed-fps 60 \
  --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=battle --stage-id=stage_1_1 --battle-demo-hit=1 --record-seconds=1.2

# 转 GIF（截取命中前后第 6–46 帧，0.67s）
ffmpeg -i /tmp/hit_on.avi -vf "trim=start_frame=6:end_frame=46,setpts=PTS-STARTPTS,\
crop=660:680:50:570,scale=440:453:flags=lanczos,fps=40,\
split[a][b];[a]palettegen=max_colors=128:stats_mode=diff[p];[b][p]paletteuse=dither=none" \
  -loop 0 on.gif
```

三组录像使用同一战局：`stage_1_1`、随机种子 `20261109`、750×1334 视口、60fps 固定帧率；
`--battle-demo-hit` 交换 (4,3)/(4,4)，在棋盘中部形成水 3 消（第 4 行）与火 3 消（第 3 列）。

## 验证

```bash
$GODOT --headless --path . --fixed-fps 60 --script res://tests/match_hit_feedback_test.gd
$GODOT --headless --path . --script res://tests/combat_balance_test.gd
```

`tests/match_hit_feedback_test.gd` 覆盖：两档参数区间、总开关关闭时无额外等待/震屏/光斑、真实战斗场景中关闭档的消除动画时长与基线一致、开启档只增加一个顿帧时长、第 4 连锁命中连锁档。
