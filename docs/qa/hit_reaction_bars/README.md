# 受击反应与血条缓降验收素材

对应「伙伴和怪物挨打时给 0.2s 抖动 + 闪白，血条在 0.25s 内缓降到新值，参数集中一处并带总开关」的改动。

- 参数与总开关：`src/ui/components/battle_hit_reaction.gd`（`CONFIG` + `enabled`）。
- 总开关关闭后不产生抖动/闪白，血条立即跳到目标值，表现回到基线 `37d121c`。

| 文件 | 说明 |
| --- | --- |
| `before.gif` | 基线 `37d121c`：敌我同时受击，头像不抖不闪，血条同帧瞬跳。 |
| `on.gif` | 本分支，总开关开启：受击瞬间头像抖动 + 闪白 0.2s，血条在 0.25s 内缓降。 |
| `off.gif` | 本分支，总开关关闭；与 `before.gif` 字节一致（两条 GIF 的 MD5 均为 `482f857f9f2a7616d9a0cecd207aa401`）。 |
| `hit_reaction_compare.png` | 同一帧 Before / After(ON) 对照，上排受击峰值，下排缓降中段。 |

## 参数口径

| 项目 | 值 | 位置 |
| --- | --- | --- |
| 受击抖动 | 0.20s，位移振幅 6px | `CONFIG.hit.shake_duration / shake_amplitude` |
| 受击闪白 | 0.20s，峰值 0.85 | `CONFIG.hit.flash_duration / flash_alpha` |
| 血条缓降 | 0.25s，缓出曲线 | `CONFIG.hp.ease_duration` |

- 抖动位移按受击进度衰减，单帧长度不超过配置振幅；同一目标连续受击时重新计时，不叠加。
- 闪白只作用于头像贴图，不改变场景其他部分；总开关关闭时不挂载闪白材质。
- 血条缓降只改 `BattleHpBar` 的绘制值；血量文本、战斗 HP、伤害/承伤统计仍读真实数值。

## 复现命令（仓库根目录）

```bash
GODOT=~/Applications/Godot.app/Contents/MacOS/Godot

# After / 开关开启
$GODOT --path . --write-movie /tmp/reaction_on.avi --fixed-fps 60 \
  --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=battle --stage-id=stage_1_1 --battle-demo-reaction=1 --record-seconds=1.2

# After / 开关关闭
$GODOT --path . --write-movie /tmp/reaction_off.avi --fixed-fps 60 \
  --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=battle --stage-id=stage_1_1 --battle-demo-reaction=1 \
  --hit-reaction=off --record-seconds=1.2

# Before：在 37d121c 工作树上使用同一份 capture 脚本录制
$GODOT --path /path/to/baseline-37d121c --write-movie /tmp/reaction_before.avi --fixed-fps 60 \
  --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=battle --stage-id=stage_1_1 --battle-demo-reaction=1 --record-seconds=1.2

# 转 GIF（受击从第 4 帧开始，取 0.6s）
ffmpeg -i /tmp/reaction_on.avi -vf "trim=start_frame=4:end_frame=40,setpts=PTS-STARTPTS,\
crop=730:520:10:100,scale=547:390:flags=lanczos,fps=40,\
split[a][b];[a]palettegen=max_colors=128:stats_mode=diff[p];[b][p]paletteuse=dither=none" \
  -loop 0 on.gif
```

三组录像使用同一战局：`stage_1_1`、随机种子 `20261109`、750×1334 视口、60fps 固定帧率。
`--battle-demo-reaction` 在同一帧制造一次敌方与一次我方受击，调用场景现有受击处理入口，
把 0.2s 抖动/闪白与 0.25s 血条缓降放在同一段录像里对照。

## 验证

```bash
$GODOT --headless --path . --fixed-fps 60 --script res://tests/battle_hit_reaction_test.gd
$GODOT --headless --path . --fixed-fps 60 --script res://tests/battle_gui_scene_test.gd
$GODOT --headless --path . --fixed-fps 60 --script res://tests/battle_result_stats_test.gd
$GODOT --headless --path . --fixed-fps 60 --script res://tests/combat_balance_test.gd
$GODOT --headless --path . --fixed-fps 60 --script res://tests/match_hit_feedback_test.gd
```

`tests/battle_hit_reaction_test.gd` 覆盖：0.2s 受击反应生命周期、0.25s 血条缓降过程值、总开关关闭时无反应且血条瞬跳、
真实战斗场景中受击反应/缓降播放时 HP 与承伤统计不变。

### 显示层不影响结算的基线断言

- `baseline_combat_log.json` 由基线 `37d121c` 用固定 `stage_1_1`、随机种子 `20261109`、20 回合脚本生成，
  记录逐回合 `damage_log`、`enemy_attacked` 承伤日志、每个伙伴的结算伤害/承伤与总伤害/总承伤。
- 测试在总开关开启/关闭两种状态下重跑同一战局，把上述日志与基线逐位比较；两种状态都必须与基线完全一致。
- 生成脚本与测试使用同一战斗输入；本次改动没有修改 `monster_db`、`stage_db`、`damage_calculator`、
  `enemy_attack_modes`、波次、前摇、飘字、连锁、命中反馈或结算统计代码。
