# 三消元素飞行三段式验收素材

对应「被消除宝石先亮起 → 沿二次贝塞尔飞向怪物锚点 → 白闪 / 扩环 / 粒子爆散」的表现层改动。
基线 `main` a322404；新代码集中在 `src/ui/components/element_flight_effect.gd`，
`src/ui/scene/scene_battle.gd` 只增加一个 preload、一个无等待的生成调用和一个取目标锚点的小函数。

## 开关与参数

`ElementFlightEffect.enabled` 是总开关，默认开启；关闭时不创建节点、不绘制、不推进计时，
也不插入任何 `await`，因此消除 / 下落 / 敌方回合时序与基线一致。所有参数集中在
`ElementFlightEffect.CONFIG`：

| 参数 | 值 | 说明 |
| --- | --- | --- |
| `cast_duration` | 0.18s | 施法段：宝石中心亮起，元素 1.0→1.25，光晕递增 |
| `flight_duration` | 0.24s | 飞行段：二次贝塞尔，控制点抬高 50px，ease-out（前快后慢） |
| `total_duration` | 0.42s | 出生 → 落点总时长（= 施法 + 飞行） |
| `hit_duration` | 0.25s | 落点后的命中段，独立于前面的 0.42s |
| `flash_peak_time` | 0.06s | 白闪在落点后 0.06s 达峰 |
| `ring_start_diameter` / `ring_end_diameter` | 10 / 46px | 扩环直径 |
| `ring_grow_duration` | 0.22s | 在命中段 0.25s 内完成，剩余时间保持 46px |
| `control_raise_px` | 50px | 在需求 40–60px 内 |
| `base_particles` / `max_particles` | 4 / 5 | 单次效果硬上限 5 |

口径说明：验收线里的「总时长 0.42s」指施法 + 飞行（出生到落点）；命中段 0.25s 从落点开始，
因此节点完整生命周期为 0.67s。否则「白闪峰值不早于落点」与「总时长 0.42s」无法同时成立。

## 三段时序与坐标量测

`tests/element_flight_effect_test.gd` 以 1ms 步长采样，原始输出见
[test_output.txt](test_output.txt)：

```text
[ElementFlight] cast=0.180s flight=0.240s total=0.420s flight_ratio=57.1%
[ElementFlight] origin=(192.5,475.5) anchor=(187.5,66.0) spawn_error=0.000px landing_error=0.000px
[ElementFlight] control_raise=50.0px first_half=325.9px second_half=83.6px
[ElementFlight] ring=10.0->46.0px in 0.190s flash_peak=0.480s landing=0.420s peak_frame=29 landing_frame=26
[ElementFlight] particles_at_landing=4
[ElementFlight] particle_tier counts={"balanced":4,"lite":2,"rich":5} screen_peak_6_effects={"balanced":24,"lite":12,"rich":30}
[ElementFlight] baseline identical=true bytes=17434 on_off_identical=true
[ElementFlight] scene effects=6 spawn_error_max=0.000px landing_error_max=0.000px anchor=(187.5,66.0)
[ElementFlight] OK
```

- 总时长 0.420s（要求 0.42±0.05s）；飞行占比 57.1%（要求 55%±10%）。
- 出生点 (192.5,475.5) 与被消除格中心误差 0.000px；落点 (187.5,66.0) 与怪物锚点误差 0.000px。
- 真实战斗场景一次双三消生成 6 个特效，出生点 / 落点最大误差均为 0.000px。
- 控制点比起点与落点中点高 50.0px；飞行前半程 325.9px、后半程 83.6px，符合前快后慢。
- 扩环 10→46px 在落点后 0.190s 完成（≤0.25s）；60fps 下白闪峰值帧 29 晚于落点帧 26。
- 均衡档单次 4 枚粒子（3–5 枚），华丽档 5 枚（≤5）；轻量 2 枚，轻量/华丽 = 0.4 ≤ 0.5。
  同屏 6 个效果峰值为轻量 12、均衡 24、华丽 30；三档系数来自设置页的
  `performanceMode`（0.5 / 1.0 / 1.5），单次上限 5 使华丽档不会超过 5。

## 开 / 关 / 基线证据

同一战局：`stage_1_1`、seed `20261109`、750×1334 视口、`--fixed-fps 60`，棋盘
`(4,3)↔(4,4)` 交换形成水 3 消 + 火 3 消。画质精细、战斗表现均衡。

| 文件 | 说明 | 字节校验 |
| --- | --- | --- |
| [before.gif](before.gif) | 基线 a322404，真实同一战局、同一交换 | md5 `231da7d2d6806142237ab5ea0faed716` |
| [off.gif](off.gif) | 本分支，总开关关闭 | 与 before.gif 逐字节一致 |
| [on.gif](on.gif) | 本分支，总开关开启：施法 → 飞行 → 命中 | md5 `fc056ddd411289bf73e9241dcbc67a1a` |
| [stage_compare.png](stage_compare.png) | 同帧 Before / After 三行对照（施法 / 飞行 / 命中） | 见 [screenshot_hashes.txt](screenshot_hashes.txt) |

关闭总开关录制的 AVI 与基线 AVI 也逐字节一致（md5 均为
`f1db482639ea76564e326510a1933c38`）；GIF 由同一 ffmpeg 命令生成，因此同样逐字节一致。
开启总开关后只有特效像素不同，战斗日志与结算不受影响。

固定种子 20 回合脚本（stage_1_1、seed `20261109`、Lv.5）的战斗日志与结算 JSON
在总开关开 / 关两种状态都与 a322404 基线逐字节一致，基线文件为
[baseline_combat_log.json](baseline_combat_log.json)（17434 字节）。

## 硬约束核对

`git diff --name-only a322404` 只包含：

- `src/ui/scene/scene_battle.gd`（新增 preload、生成调用、目标锚点小函数）
- `src/ui/components/element_flight_effect.gd`（新文件）
- `tests/element_flight_*`（测试 / 采集 / 基线脚本）
- `docs/qa/element_flight/*`（证据）

`damage_feedback.gd`、字体链 / 字号 / 描边 / 时长 / 节奏、血条参数、伤害公式、
关卡 / 怪物数据、四条平衡线、SFX / BGM 均未改动；`combat_balance_test`、
`battle_sfx_test`、`battle_bgm_test` 等回归通过。

## 复现命令

```bash
GODOT=~/Applications/Godot.app/Contents/MacOS/Godot

# 测试与量测
MATCH3_SAVE_PATH=/tmp/element_test.cfg \
  $GODOT --headless --path . --fixed-fps 60 \
  --script res://tests/element_flight_effect_test.gd

# 录制开启 / 关闭（同一棋盘、同一交换；关闭用 --effect=off）
MATCH3_SAVE_PATH=/tmp/element_capture.cfg \
  $GODOT --path . --fixed-fps 60 --write-movie /tmp/element_on.avi \
  --script res://tests/element_flight_capture.gd -- \
  --effect=on --record-seconds=1.1

MATCH3_SAVE_PATH=/tmp/element_capture.cfg \
  $GODOT --path . --fixed-fps 60 --write-movie /tmp/element_off.avi \
  --script res://tests/element_flight_capture.gd -- \
  --effect=off --record-seconds=1.1

# 基线 before：在 a322404 工作树中临时放入同一 capture 脚本后录制
$GODOT --path /tmp/match3-a322404 --fixed-fps 60 \
  --write-movie /tmp/element_before.avi \
  --script res://tests/element_flight_capture.gd -- \
  --effect=on --record-seconds=1.1

# 三段对照截图
for n in before off on; do
  ffmpeg -y -i /tmp/element_${n}.avi -vf \
    "crop=750:1230:0:0,scale=375:615:flags=lanczos,fps=30,\
split[a][b];[a]palettegen=max_colors=128:stats_mode=diff[p];\
[b][p]paletteuse=dither=none" -loop 0 ${n}.gif
done
```

`element_flight_capture.gd` 用 `ResourceLoader.exists` 检查特效脚本，因此在 a322404 工作树
（没有新文件）里也能直接跑出 before，不依赖新代码。

## 回归

见 [regression.txt](regression.txt)。本次改动相关的
`element_flight_effect_test`、`match_hit_feedback_test`、`damage_feedback_test`、
`combat_balance_test`、`p0_smoke_test`、`presentation_settings_restart_test`（write→read）
以及战斗 / 音效 / BGM / 震动 / 连锁 / 破招 / 眩晕 / 结果等回归均通过。
`battle_speed_test` 的计时器断言在 a322404 基线同样失败（环境性抖动），
固定种子日志与结算仍为 `identical=true`。
