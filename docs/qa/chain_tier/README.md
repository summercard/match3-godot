# T3 连锁升级与同屏预算验收素材

对应「2 连锁环径 ×1.2 / 亮度 +10%，4 连锁加第二圈，轻量环径 ×0.8 且无第二圈，
三档同屏弹体 / 环 / 粒子硬上限」的表现层改动。

- 行为与技术基线：`37b5277`（#29 元素飞行三段式）。
- 视觉 Before 取自 `ddd7a01`（PR base；#30 只把单体血条整体左移 74px，不涉及
  元素飞行 / 环 / 粒子），After 为本分支；两边的战斗 UI 状态一致。
- 实现：只改 `src/ui/components/element_flight_effect.gd`（连锁 / 档位 / 预算参数与
  环绘制）和 `src/ui/scene/scene_battle.gd`（把 `cascade_count` 传成 `chain_level`、
  进入战斗重置预算、暴露预算计数）。
- 不修改：伤害公式、关卡 / 怪物数据、四条平衡线、SFX / BGM、T1 飘字与血条参数、
  T2 三段时长（0.18 / 0.24 / 0.42、拖尾、白闪 0.06）。

## 参数（全部集中在 ElementFlightEffect.CONFIG）

| 参数 | 值 | 说明 |
| --- | --- | --- |
| `chain_ring_min` | 2 | 2 连锁起启用环升级 |
| `chain_ring_radius_scale` | 1.2 | 首圈起止半径 ×1.2 |
| `chain_ring_luminance_scale` | 1.12 | 白环 alpha 0.90→1.00，实测 +11.1%，保证 ≥+10% |
| `second_ring_min_chain` | 4 | 4 连锁起出现第二圈 |
| `second_ring_delay` | 0.06s | 第二圈起点 = 首圈起点 +0.06s |
| `second_ring_peak_ratio` | 0.6 | 第二圈峰值半径 = 首圈 60% |
| `second_ring_grow_duration` | 0.14s | 在命中段 0.25s 内完成扩环并留出可见保持帧 |
| `tier_ring_scale` | lite 0.8 / balanced 1.0 / rich 1.0 | 轻量首圈 = 均衡 ×0.8，且无第二圈 |
| `tier_budgets` | lite 2/1/4，balanced 3/2/8，rich 3/3/12 | 同屏弹体 / 同屏环 / 单次命中粒子 |

原有 `base_particles` 4、`max_particles` 5 与 `effect_density` 0.5 / 1.0 / 1.5 的
粒子口径未改（实测 2 / 4 / 5）。预算只决定是否创建表现节点，不插入等待，不改变
消除 / 下落 / 敌方回合时序。

## 量测（tests/element_flight_chain_tier_test.gd）

原始输出见 [test_chain_tier.txt](test_chain_tier.txt)。

```text
[ElementFlightT3] chain=1 tier=balanced first_peak=23.000px first_lum=0.900 first_start=0.421s second_start=-1.000s second_peak=0.000px second_lum=0.000
[ElementFlightT3] chain=2 tier=balanced first_peak=27.600px first_lum=1.000 first_start=0.421s second_start=-1.000s second_peak=0.000px second_lum=0.000
[ElementFlightT3] chain=4 tier=balanced first_peak=27.600px first_lum=1.000 first_start=0.421s second_start=0.481s second_peak=16.560px second_lum=0.600
[ElementFlightT3] chain_radius_ratio=1.2000x luminance_ratio=1.1111x second_delay=0.060s second_peak_ratio=0.6000
[ElementFlightT3] chain=4 tier=lite first_peak=22.080px first_lum=1.000 first_start=0.421s second_start=-1.000s second_peak=0.000px second_lum=0.000
[ElementFlightT3] chain=4 tier=rich first_peak=27.600px first_lum=1.000 first_start=0.421s second_start=0.481s second_peak=16.560px second_lum=0.600
[ElementFlightT3] tier_ring lite/balanced=0.8000 balanced=27.600px rich=27.600px lite_second=0.000px
[ElementFlightT3] budget tier=lite projectiles=0 dropped=4 rings=1 ring_drops=1 particles<=4
[ElementFlightT3] budget tier=balanced projectiles=0 dropped=3 rings=2 ring_drops=1 particles<=8
[ElementFlightT3] budget tier=rich projectiles=0 dropped=3 rings=3 ring_drops=0 particles<=12
[ElementFlightT3] budget chain4 rings=3 ring_drops=3
[ElementFlightT3] scene wiring chain_level=1/4, budget drops observable, shake_records_from_effect=0
```

- 2 连锁首圈 27.600 / 1 连锁 23.000 = **1.2000×**（验收 1.20±0.02）。
- 环亮度 0.900→1.000，**+11.1%**（验收 ≥10%；用白环 alpha 量测，不受背景明暗与
  8bit 量化影响）。
- 4 连锁首圈同 2 连锁；第二圈起点 0.421→0.481s，**+0.060s**（±1 帧 = 0.0167s）；
  峰值 16.560 / 27.600 = **60.0%**（验收 60%±5%）。
- 轻量 4 连锁首圈 22.080 / 均衡 27.600 = **0.8000×**（验收 0.80±0.02），
  `second_start=-1`、`second_peak=0`，确认无第二圈；华丽与均衡同径。
- 三档预算：弹体峰值 2 / 3 / 3，环峰值 1 / 2 / 3，单次命中粒子 2 / 4 / 5 均不超
  4 / 8 / 12；超限丢弃数在 `get_element_flight_budget_stats()` 可查（上表
  `dropped` / `ring_drops`），4 连锁华丽档占满 3 个环后第二圈全部丢弃且不超预算。
- 元素飞行（含第二圈）不写任何命中 / 棋盘震屏字段；4 连锁命中震屏仍只由
  `MatchHitFeedback` 的连锁档产生，条数不变。

## 证据

同战局 `stage_1_1`、seed `20261109`、750×1334 视口、`--fixed-fps 60`，
画质精细、战斗表现均衡。三张连锁 GIF 在命中环附近裁剪到 430×300，30fps。
Before 帧在 `ddd7a01` 的两个实现文件上录制（与 After 同一套 #30 血条 UI），
随后恢复本分支代码；Before / After 只差 T3 的两个文件。

| 文件 | 说明 | md5 |
| --- | --- | --- |
| [gifs/chain1.gif](gifs/chain1.gif) | 1 连锁：首圈 23.0px 半径 | `b08aaae0c8969fef37b90c81f9f15fff` |
| [gifs/chain2.gif](gifs/chain2.gif) | 2 连锁：首圈 ×1.2 = 27.6px，亮度 +11.1% | `07f7df722972fdcd239f0489cedcfc36` |
| [gifs/chain4.gif](gifs/chain4.gif) | 4 连锁：27.6px + 第二圈 16.56px（+0.06s） | `70172873c954e61028183afee5e58626` |
| [tier_compare.png](tier_compare.png) | Before / After 三行对照：2 连锁、4 连锁第二圈、轻量无第二圈 | `7a067a71380d221ad3e81836a4d4c21d` |
| [before_chain2.png](before_chain2.png) | ddd7a01，chain=2（基线不识别连锁，环 46px 直径） | `da6c6bab25a3484dbebf47284282ff7a` |
| [after_chain2.png](after_chain2.png) | 本分支，chain=2（首圈 ×1.2） | `c2fa831992f78b0f9eb567af6cfaceab` |
| [before_chain4.png](before_chain4.png) | ddd7a01，chain=4（单圈） | `da6c6bab25a3484dbebf47284282ff7a` |
| [after_chain4.png](after_chain4.png) | 本分支，chain=4（首圈 + 第二圈） | `0a403157f00568e28f7073a6616147fc` |
| [after_chain4_lite.png](after_chain4_lite.png) | 本分支，轻量 4 连锁（×0.8，无第二圈） | `1bbf47a3cc75a77c9322134df9fa59f1` |
| [before_on.gif](before_on.gif) | ddd7a01，总开关开启，同一交换 | `50e7163582ff3dcd98246680fe02fb29` |
| [after_on.gif](after_on.gif) | 本分支，总开关开启，同一交换 | `04d81ca82a1f8b5e13a38deb681d0a66` |
| [off.gif](off.gif) | 本分支，总开关关闭 | `cf782b205496704489e8400175ae26f0` |

对照结论：

- `before_chain2/4.png` 的 md5 完全相同（`da6c6bab…`），说明基线不识别连锁；
  `after_chain1.png` 也与该 md5 相同，说明 1 连锁画面完全保持基线。
- `after_chain4.png` 与 `after_chain4_rich.png` 相同（华丽首圈倍率 1.0），
  `after_chain4_lite.png` 与 `after_chain2_lite.png` 相同（轻量无第二圈，且
  2/4 连锁首圈同径），与参数口径一致。
- 总开关关闭的录像与 `ddd7a01` 基线录像逐字节一致（md5 均为
  `1c0cbd3094dbbcb833e885582a65058c`）；关闭状态下不创建任何表现节点，
  也没有任何额外等待。相对 37b5277 的旧基线 AVI md5 `f1db4826…` 仅因 #30
  血条位置变化而不同，元素飞行路径本身未变。

## 回归与硬约束

- `tests/element_flight_chain_tier_test.gd`：以上连锁 / 档位 / 预算 / 震屏 /
  总开关断言全部通过。
- `tests/element_flight_effect_test.gd`：T2 三段时长、10→46px 扩环、白闪 0.06s、
  拖尾 14 点、2/4/5 粒子口径全部保持；一次双三消 6 格在均衡档只生成 3 个节点，
  另 3 个计入 `dropped_projectiles`（T3 预算生效）。
- 固定种子 20 回合（`stage_1_1`、seed `20261109`、Lv.5）开 / 关两态日志与结算
  JSON 与 37b5277 基线逐字节一致（17434 字节，
  [test_element_flight.txt](test_element_flight.txt) 中
  `baseline identical=true on_off_identical=true`）。
- `damage_feedback.gd`、`src/data`、`damage_calculator.gd`、
  `enemy_attack_modes.gd`、`battle_manager.gd`、`combat_balance_test.gd`
  相对 37b5277 零 diff。
- 相关回归：`match_hit_feedback_test`、`combat_balance_test`、
  `battle_presentation_test`、`combo_chain_test`、`p0_smoke_test`、
  `presentation_settings_restart_test`（write→read）通过。

## 复现命令

```bash
GODOT=~/Applications/Godot.app/Contents/MacOS/Godot

# 三档连锁量测 + 预算
MATCH3_SAVE_PATH=/tmp/t3_measure.cfg \
  $GODOT --headless --path . --fixed-fps 60 \
  --script res://tests/element_flight_chain_tier_test.gd

# 三张连锁 GIF（先生成 AVI，再裁成 430×300 / 30fps）
for chain in 1 2 4; do
  MATCH3_SAVE_PATH=/tmp/t3_chain_${chain}.cfg \
    $GODOT --path . --fixed-fps 60 \
    --write-movie /tmp/t3_chain${chain}.avi \
    --script res://tests/element_flight_chain_capture.gd -- \
    --chain=${chain} --performance-mode=balanced --record-seconds=2.0
  ffmpeg -y -i /tmp/t3_chain${chain}.avi -vf \
    "trim=start_frame=6:end_frame=46,setpts=PTS-STARTPTS,\
crop=430:300:160:0,fps=30,split[a][b];\
[a]palettegen=max_colors=128:stats_mode=diff[p];\
[b][p]paletteuse=dither=none" -loop 0 chain${chain}.gif
done

# Before 帧：在 ddd7a01 工作树（或临时切回 ddd7a01 的两个实现文件）用同一脚本
$GODOT --path /path/to/ddd7a01 --fixed-fps 60 \
  --script res://tests/element_flight_chain_capture.gd -- \
  --chain=2 --performance-mode=balanced --phase=ring --output=before_chain2.png
```
