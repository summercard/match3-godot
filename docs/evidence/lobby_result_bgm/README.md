# 大厅与结算页背景音乐：复用战斗 BGM 层

设置页文案写的是「大厅、战斗与结算音乐」，此前只有战斗场景挂 BGM。本轮把同一套运行时合成器
（`src/ui/components/battle_bgm.gd`）扩展成四条轨道，并接到大厅与两种结算页：

- `lobby`：大厅主菜单；
- `battle`：战斗，沿用原 `CONFIG`，参数与 PCM 均未变；
- `result_win`：胜利结算；
- `result_loss`：失败结算。

没有第二个合成器，也没有新增外部/二进制音频文件；每条轨道的 PCM 仍在运行时写入
`AudioStreamWAV`，按轨道各缓存一份。`musicOn` 仍是独立于 `soundOn` 的总开关，
关闭时任何场景都不会创建 `AudioStreamPlayer`。

## 口径

- 基线：`d0f9a12`（PR #21 合并后的 main）。
- 改动后：`agent/lobby-result-bgm-9523688ceab7`。
- 运行环境：Godot `4.7.2.stable`（`ed1daf0bf`），macOS Apple M1，headless。
- 播放器计数口径：把 `soundOn` 设为 `false`，场上 `AudioStreamPlayer` 只可能来自 BGM 层；
  BGM 本身只受 `musicOn` 控制。大厅、战斗、结算各断「恰好 1 个播放器且 `is_playing`」。
- 固定战局口径：`stage_1_1`、seed `20261111`、5 级初始三只伙伴、最多 40 回合，
  与 `prepare_matchup_transcript.gd` 的转录完全一致。
- 听觉不判；本轮没有界面视觉改动，不附截图。

## 轨道参数表

四条轨道共用同一套合成器与 `sample_rate=22050`、16-bit PCM、单声道、
`loop_mode=LOOP_FORWARD`、`loop_begin=0`、`loop_end=循环帧数`。

### 全局参数

| 参数 | `battle` | `lobby` | `result_win` | `result_loss` |
| --- | --- | --- | --- | --- |
| `root_midi` | `45`（A2，110.00 Hz） | `48`（C3，130.81 Hz） | `48`（C3，130.81 Hz） | `45`（A2，110.00 Hz） |
| `scale_name` | `minor_pentatonic` | `major_pentatonic` | `major_pentatonic` | `minor_pentatonic` |
| `scale_degrees` | `[0, 3, 5, 7, 10]` | `[0, 2, 4, 7, 9]` | `[0, 2, 4, 7, 9]` | `[0, 3, 5, 7, 10]` |
| `bpm` | `100.0` | `76.0` | `112.0` | `66.0` |
| `beats_per_bar` | `4` | `4` | `4` | `4` |
| `bars` | `2` | `4` | `2` | `2` |
| 循环时长 | `4.800 s` | `12.632 s` | `4.286 s` | `7.273 s` |
| 循环帧数 | `105840` | `278526` | `94500` | `160364` |
| PCM 字节数 | `211680` | `557052` | `189000` | `320728` |
| `master_gain` | `0.72` | `0.68` | `0.72` | `0.62` |
| 峰值 | `23592` | `22281` | `23592` | `20315` |
| 首样本 / 末样本 | `0` / `-123` | `0` / `-229` | `0` / `-119` | `0` / `-100` |
| 首尾接缝跳变 | `123` | `229` | `119` | `100` |
| 首/尾 50 ms RMS | `10583.8` / `2353.6` | `9762.9` / `2678.0` | `9597.3` / `1977.4` | `9025.7` / `2895.7` |

`battle` 一列与基线 `d0f9a12` 的 `battle_bgm_test` 输出逐项相同，`CONFIG` 未改。

### 声部参数

| 轨道.声部 | 启用 | 波形 | 增益 | 音高/编曲 | 包络与其他 |
| --- | --- | --- | --- | --- | --- |
| `battle.bed` | 是 | `sine` | `0.12` | 根音持续音，谐波 `2.0×0.12` | 颤音 2 周期/循环、深度 `0.35` |
| `battle.bass` | 是 | `sine` | `0.38` | octave 0；`pattern=[0,-1,7,-1]`、`bar_roots=[0,3]` | attack `0.012 s`、decay `2.4`、release `0.06 s`、note `1.75` 拍 |
| `battle.pad` | 是 | `sine` | `0.08` | 每小节和弦 `[0,7,12]`、`bar_roots=[0,3]` | attack `0.06 s`、release `0.12 s`、时值 1 小节 |
| `battle.lead` | 是 | `triangle` | `0.24` | octave 12；16 槽位 `pattern=[0,-1,2,4,3,-1,2,1,0,-1,4,3,2,-1,1,0]`、`bar_roots=[0,3]` | attack `0.006 s`、decay `5.0`、release `0.05 s`、note `0.85` 槽 |
| `battle.kick` | 是 | `sine` | `0.30` | `92→44 Hz`，每小节第 1、3 拍 | 时值 `0.16 s`、attack `0.002 s`、decay `18.0` |
| `lobby.bed` | 是 | `sine` | `0.10` | 根音持续音 | 颤音 2 周期/循环、深度 `0.30` |
| `lobby.bass` | 是 | `sine` | `0.26` | octave 0；`pattern=[0,-1,7,-1]`、`bar_roots=[0,5,7,9]` | decay `2.0`、note `1.8` 拍 |
| `lobby.pad` | 是 | `sine` | `0.07` | 每小节和弦 `[0,4,7]`、`bar_roots=[0,5,7,9]` | attack `0.12 s`、release `0.30 s`、`note_ratio=0.98` |
| `lobby.lead` | 是 | `triangle` | `0.16` | octave 12；32 槽位（A/B/C/D 四小节各 8 槽）、`bar_roots=[0,5,7,9]`、跟随小节根音 | decay `3.5`、note `0.95` 槽 |
| `lobby.kick` | 否 | — | — | — | 大厅不铺鼓点 |
| `result_win.bed` | 是 | `sine` | `0.09` | 根音持续音 | 颤音深度 `0.20` |
| `result_win.bass` | 是 | `sine` | `0.30` | octave 0；`pattern=[0,-1,7,-1]`、`bar_roots=[0,7]` | attack `0.008 s`、decay `3.0`、note `1.6` 拍 |
| `result_win.pad` | 是 | `sine` | `0.09` | 每小节和弦 `[0,4,7]`、`bar_roots=[0,7]` | attack `0.05 s`、release `0.15 s` |
| `result_win.lead` | 是 | `triangle` | `0.26` | octave 12；16 槽位 `pattern=[0,2,4,4,3,4,2,0,1,2,3,4,2,4,1,0]`、`bar_roots=[0,7]`、跟随小节根音 | decay `4.0` |
| `result_win.kick` | 是 | `sine` | `0.22` | `100→50 Hz`，每小节第 1、3 拍 | 时值 `0.14 s`、decay `15.0` |
| `result_loss.bed` | 是 | `sine` | `0.13` | 根音持续音 | 颤音深度 `0.42` |
| `result_loss.bass` | 是 | `sine` | `0.28` | octave 0；`pattern=[0,-1,3,-1]`、`bar_roots=[0,3]` | decay `1.8`、note `1.9` 拍 |
| `result_loss.pad` | 是 | `sine` | `0.08` | 每小节和弦 `[0,3,7]`、`bar_roots=[0,3]` | attack `0.15 s`、release `0.35 s` |
| `result_loss.lead` | 是 | `triangle` | `0.15` | octave 12；16 槽位 `pattern=[0,-1,-1,2,-1,1,-1,-1,0,-1,-1,3,-1,2,-1,-1]`、`bar_roots=[0,3]`、跟随小节根音 | decay `2.2`、note `1.25` 槽 |
| `result_loss.kick` | 否 | — | — | — | 失败结算不铺鼓点 |

循环接缝处理沿用原合成器：`bed` 频率吸附到循环内整数个周期；其余声部在循环结束前收尾到 0。
四条轨道实测首样本均为 `0`，末样本与接缝跳变都在峰值的 1% 以内，首尾 50 ms 均无空白。

## 播放器计数输出

原始输出（完整 JSON，含逐场景与 5 轮循环的播放器计数）：

- `music_on.txt`：`musicOn=true`、`soundOn=false`；
- `music_off.txt`：`musicOn=false`、`soundOn=false`；
- `test_output.txt`：`lobby_result_bgm_test` 完整断言输出。

| 状态 | 大厅 | 战斗 | 胜利结算 | 失败结算 | 来回切 5 次 |
| --- | --- | --- | --- | --- | --- |
| `musicOn=true`，BGM 播放器数 | `1` | `1` | `1` | `1` | 每步 `1` |
| `musicOn=true`，播放中 | `true` | `true` | `true` | `true` | 每步 `true` |
| `musicOn=true`，整棵场景树播放器数 | `1` | `1` | `1` | `1` | 最大 `1` |
| `musicOn=false`，BGM 播放器数 | `0` | `0` | `0` | `0` | 每步 `0` |
| `musicOn=false`，播放中 | `false` | `false` | `false` | `false` | 每步 `false` |
| `musicOn=false`，整棵场景树播放器数 | `0` | `0` | `0` | `0` | 最大 `0` |

- 唯一播放器始终属于当前场景：5 轮循环的每一步都断言 `total_playing_players == 1`，
  且该播放器就是当前场景 BGM 节点的 `BgmPlayer`。
- 运行中切换 `musicOn`：大厅打开后下一帧恢复到 `1` 个播放器，关闭后下一帧回到 `0`。
- 换轨顺序：`lobby → battle → result_win → lobby`、`lobby → battle → result_loss → lobby`
  各 5 轮；新轨道起播前先 `stop()` 上一个，旧播放器不会与新播放器同时播放。

## 固定种子战局逐字节一致

用 `d0f9a12` 工作树与改动后分支分别跑同一份固定种子转录：

- [battle_before.json](battle_before.json)：基线 `d0f9a12`；
- [battle_after.json](battle_after.json)：改动后分支；
- `cmp` 无输出，两个文件 SHA-256 均为
  `0d6d3c718332bd2a09e2bf44b9f1116d23d6fd962216cc3fa77fb93153490adb`；
- 同一份基线 JSON 已放入 `tests/fixtures/lobby_result_bgm_battle_baseline.json`，
  `lobby_result_bgm_test` 每次运行都会重新生成并逐字节比对。

```bash
GODOT=~/Applications/Godot.app/Contents/MacOS/Godot
$GODOT --headless --path /tmp/match3-lobby-result-bgm-baseline \
  --script res://tests/prepare_matchup_transcript.gd \
  -- --output=/tmp/lobby_result_bgm_battle_before.json
$GODOT --headless --path . --script res://tests/prepare_matchup_transcript.gd \
  -- --output=/tmp/lobby_result_bgm_battle_after.json
cmp /tmp/lobby_result_bgm_battle_before.json /tmp/lobby_result_bgm_battle_after.json
```

`src/data`、`src/battle`、`src/match3` 相对 `d0f9a12` 的 diff 行数为 `0`，因此任意固定种子的
战斗日志与结算 JSON 都不会变化；上面的转录是其中一局的逐字节留档。

## 四条平衡线

基线 `d0f9a12` 与改动后分支分别运行：

- `combat_balance_test`
- `boss_break_test`
- `stun_order_test`
- `battle_rules_test`

[balance_lines_before.txt](balance_lines_before.txt) 与
[balance_lines_after.txt](balance_lines_after.txt) 逐字节一致（SHA-256 均为
`7e87980b7d688f14365a5075d1d7d210dc3abac470ddb5b00373f9910b9cf723`），四条平衡线数值未变。

## 改动

- `src/ui/components/battle_bgm.gd`
  - `CONFIG` 保持为战斗轨道与其余轨道的基准，新增 `TRACKS` 覆盖表；
  - `track_config()` 合并参数，`set_track()` 选择轨道；
  - 缓存按 `stream_<track>` 分开，仍复用同一合成器与同一份 PCM 写入逻辑；
  - `_synthesize()` 支持按声部 `enabled=false` 关闭某个声部（大厅/失败结算不用鼓点）。
- `src/ui/scene/scene_main.gd`
  - 大厅 `_ready()` 创建 `LobbyBgm` 并选择 `lobby` 轨道。
- `src/ui/scene/scene_result.gd`
  - `initialize()` 按 `_is_win` 选择 `result_win` / `result_loss`，重复初始化只换轨不叠播放器。
- `tests/battle_bgm_test.gd`
  - 更新「结算页不挂 BGM」的旧断言：结算页现在挂 `ResultBgm`，但场上仍只有 1 个播放器。
- `tests/lobby_result_bgm_test.gd`、`tests/fixtures/lobby_result_bgm_battle_baseline.json`
  - 新增四条轨道参数、循环、单播放器、5 轮切换与固定战局基线回归。

## 复现命令

```bash
GODOT=~/Applications/Godot.app/Contents/MacOS/Godot

# 完整回归（参数表 + 循环 + 单播放器 + 5 轮循环 + musicOn 开关 + 固定战局）
$GODOT --headless --path . --script res://tests/lobby_result_bgm_test.gd

# 两种开关状态的原始 JSON
$GODOT --headless --path . --script res://tests/lobby_result_bgm_test.gd -- --evidence=on
$GODOT --headless --path . --script res://tests/lobby_result_bgm_test.gd -- --evidence=off

# 既有战斗 BGM 回归（战斗 PCM 指标与基线一致）
$GODOT --headless --path . --script res://tests/battle_bgm_test.gd
```

## 本轮跑过的回归（全部 exit 0）

`lobby_result_bgm_test`、`battle_bgm_test`、`battle_sfx_test`、`main_lobby_scene_test`、
`battle_prepare_result_gui_scene_test`、`stage_progress_loop_test`、`p0_smoke_test`、
`p1_ch1_slice_test`、`battle_gui_scene_test`、`battle_result_stats_test`、
`combat_balance_test`、`boss_break_test`、`stun_order_test`、`battle_rules_test`。

## 约束核对

- 复用 `BattleBgm`，没有第二个合成器；没有新增外部/二进制音频。
- `src/data` 零 diff；四条平衡线输出逐字节一致。
- 既有战斗 BGM 的 `CONFIG`、PCM 指标、战斗音效/受击/飘字/震屏参数均未改。
- 同一时刻最多 1 个 BGM 播放器；新轨道起播前先停旧的。
- `musicOn=false` 时大厅、战斗、结算三处播放器数均为 0。
