# 战斗背景音乐层：运行时合成循环

本轮把设置页里原本空置的 `musicOn` 接到战斗场景：进入战斗时起播一段运行时合成的循环 BGM，
离开战斗或进入胜负结算时停止；`musicOn` 是独立于 `soundOn` 的开关，关闭时不创建任何 BGM 播放器。
没有引入外部或二进制音频文件，所有 PCM 都在运行时生成。

## 对比口径

- 基线：`0f828cb`（PR #16 合并后的 main）。
- 改动后：本 PR 分支。
- 运行环境：Godot `4.7.2.stable`，macOS Apple M1。
- 画面口径：`stage_1_1`、750×1334 窗口（375×667 逻辑视口）、默认主题、同一截图 harness。
- 原始输出口径：与 `battle_sfx_test` 相同的固定战局（`stage_1_1`、seed `20261109`、20 回合脚本）。
- 播放器计数口径：原始输出把 `soundOn` 也设为 `false`，让场上 `AudioStreamPlayer` 只可能是 BGM 层，
  避免连锁音效池 / 战斗音效播放器混入计数。BGM 本身只受 `musicOn` 控制。

## 循环参数表

所有参数集中在 `src/ui/components/battle_bgm.gd` 的 `CONFIG`。

| 参数 | 值 | 说明 |
| --- | --- | --- |
| `sample_rate` | `22050` | 16-bit PCM 单声道，与既有合成音效同采样率 |
| `root_midi` | `45`（A2，110.00 Hz） | 调式根音 |
| `scale_name` | `minor_pentatonic` | A 小调五声音阶 |
| `scale_degrees` | `[0, 3, 5, 7, 10]` | 相对根音的半音偏移：A、C、D、E、G |
| `bpm` | `100.0` | 速度 |
| `beats_per_bar` | `4` | 4/4 拍 |
| `bars` | `2` | A → C 两小节循环 |
| 循环时长 | `4.800 s` | `60 / 100 × 4 × 2` |
| 循环帧数 | `105840` | `4.800 × 22050`，也是 `loop_end` |
| `master_gain` | `0.72` | 合成后统一峰值归一化 |
| `loop_mode` | `LOOP_FORWARD` | `loop_begin=0`，`loop_end=105840` |
| `bed` | `sine`，谐波 2.0×0.12，增益 0.12 | 持续低音垫；根音吸附到循环内整数周期，颤音 2 周期/循环、深度 0.35 |
| `bass` | `sine`，octave 0，增益 0.38 | 每小节第 1、3 拍；`pattern=[0,-1,7,-1]`，`bar_roots=[0,3]`；note 1.75 拍，attack 0.012 s，decay 2.4，release 0.06 s |
| `pad` | `sine`，octave 0，增益 0.08 | 每小节强力和弦 `[0,7,12]`；attack 0.06 s，release 0.12 s，时值 1 小节 |
| `lead` | `triangle`，octave 12，增益 0.24 | 两小节 16 个八分音符槽位；`pattern=[0,-1,2,4,3,-1,2,1,0,-1,4,3,2,-1,1,0]`；note 0.85 槽，attack 0.006 s，decay 5.0，release 0.05 s |
| `kick` | `sine`，92→44 Hz，增益 0.30 | 每小节第 1、3 拍；时值 0.16 s，attack 0.002 s，decay 18 |
| 输出格式 | 211680 bytes | `105840 帧 × 2 bytes` |

循环接缝处理：

- `bed` 的频率吸附到 `round(110 × 4.8) = 528` 个周期，首尾相位一致；
- 其余声部的最后一个音符都在循环结束前收尾到 0；
- 实测首样本 `0`、末样本 `-123`（峰值 `23592`），接缝跳变 `123`，约峰值的 0.5%；
- 开头/结尾各 50 ms 的 RMS 分别为 `10583.8` / `2353.6`，循环回绕处没有空白段。

## 开关两态原始输出

| 状态 | BGM 节点 | `music_player_count` | `music_playing` | 场上 `AudioStreamPlayer` |
| --- | --- | --- | --- | --- |
| `musicOn=true`（`soundOn=false`） | 存在，`enabled=true` | `1` | `true` | `1` |
| `musicOn=false`（`soundOn=false`） | 存在，`enabled=false` | `0` | `false` | `0` |

原始文件（完整 `raw_json`，包含两份固定战局的回合、伤害日志、承伤日志与结算结果）：

- `music_on.txt`：`musicOn=true`。
- `music_off.txt`：`musicOn=false`。
- `test_output.txt`：`battle_bgm_test` 完整输出，含上面的循环参数表、接缝指标与开关断言。

关键 JSON：

```json
// music_on.txt
"scene": {
  "bgm_enabled": true,
  "bgm_node": true,
  "bgm_player_nodes": 1,
  "loop": {
    "bytes": 211680,
    "format_16_bits": true,
    "frames": 105840,
    "loop_begin": 0,
    "loop_end": 105840,
    "loop_mode": 1,
    "mix_rate": 22050
  },
  "music_player_count": 1,
  "music_playing": true,
  "total_player_nodes": 1
}

// music_off.txt
"scene": {
  "bgm_enabled": false,
  "bgm_node": true,
  "bgm_player_nodes": 0,
  "music_player_count": 0,
  "music_playing": false,
  "total_player_nodes": 0
}
```

## 音乐不影响战斗

同一固定种子、同一脚本分别跑 `musicOn=true` 与 `musicOn=false`：

- `turns`、`damage_dealt_log`、`damage_taken_log`、`result` 四个字段 JSON 逐位一致；
- 结算结果均为 `win`、4 回合、总伤害 `908`、总承伤 `49`；
- `battle_bgm_test` 额外断言合成过程不消耗全局随机数，避免 BGM 影响固定种子的战斗。

## 运行中切换与结算停止

- 进入战斗：场景 `_ready` 挂载 `BattleBgm`，`musicOn=true` 时立即创建 1 个播放器并播放。
- 运行中切 `musicOn=false`：下一帧释放播放器，播放器数回 0；切回 `true` 后下一帧恢复为 1，不叠音。
- 进入胜负结算：`_begin_battle_end_overlay` 立即停止 BGM，避免与胜利/失败音效叠音。
- 离开战斗 / `destroy()`：再次兜底停止；场景销毁时播放器随节点释放。
- 新战斗开始前会停掉上一个 BGM 节点，避免快速切场景时两个播放器短暂叠音。

## 战斗截图

`after_battle.png`：改动后 `stage_1_1` 战斗首屏，默认主题、750×1334 视口。
本轮只增加音频层，没有改 UI，截图用于确认战斗画面与既有表现一致。

```bash
GODOT=~/Applications/Godot.app/Contents/MacOS/Godot
$GODOT --path . --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=battle --stage-id=stage_1_1 --hide-toast=1 --settle-frames=6 \
  --output=docs/evidence/battle_bgm/after_battle.png
```

## 测试

```bash
GODOT=~/Applications/Godot.app/Contents/MacOS/Godot

# 本轮新增回归：CONFIG、PCM/循环接缝、开关、场景生命周期、战斗日志逐位一致
$GODOT --headless --path . --script res://tests/battle_bgm_test.gd

# 两态原始输出
$GODOT --headless --path . --script res://tests/battle_bgm_test.gd -- --music-state=on  > music_on.txt
$GODOT --headless --path . --script res://tests/battle_bgm_test.gd -- --music-state=off > music_off.txt
```

回归套件（全部 exit 0）：

`battle_bgm_test`、`battle_sfx_test`、`stun_order_test`、`boss_break_test`、`combat_balance_test`、
`enemy_attack_modes_test`、`enemy_windup_test`、`p1_ch1_slice_test`、`battle_rules_test`、
`active_skill_test`、`enemy_intent_test`、`wave_entry_test`、`battle_gui_scene_test`、
`battle_prepare_result_gui_scene_test`、`battle_result_stats_test`、`battle_input_test`、
`damage_numbers_test`、`combo_chain_test`、`p0_smoke_test`、`p0_contract_test`、
`stage_progress_loop_test`、`chapter_mechanic_test`。

## 约束核对

- 未改动四条平衡线：`combat_balance_test` 与 `boss_break_test` 均通过。
- 未改动 `src/data`：本 PR 对 `src/data` 零 diff。
- 未改动既有音效参数与表现：`battle_sfx.gd` / `combo_sfx.gd` 未修改；`battle_sfx_test` 仅把
  `musicOn` 隔离为 `false`，避免 BGM 播放器混入其 `soundOn` 播放器计数。
- 未新增外部/二进制音频文件：BGM 只在运行时写入 `AudioStreamWAV`。
