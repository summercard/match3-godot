# 战斗内暂停面板

右上角设置按钮终于有了命中判定：点击后在棋盘上打开暂停浮层，含「继续」、
音效 / 音乐 / 震动三个开关和「退出战斗」。暂停把战斗时间尺度冻结为 0，
回合数、敌方前摇计时、倍速计时和所有 `await` 的消除/敌方回合计时一起停在原处；
继续恢复暂停前的 1x/2x 倍速，从原处接着走。

## 对比口径

- 基线：`59181c5`（PR #23 合并后的 main）。
- 改动后：`agent/battle-pause-panel-d2c8b8be2997`。
- 运行环境：Godot `4.7.2.stable`（`ed1daf0bf`），macOS Apple M1。
- 截图使用独立空存档 `MATCH3_SAVE_PATH=/tmp/.../capture_*.cfg`，
  同一 `stage_1_1`、同一 750×1334 视口、同一 `--fixed-fps 60`、同一截图 harness。
- 固定种子口径沿用 `prepare_matchup_transcript.gd`：`stage_1_1`、seed `20261111`、
  5 级、三只伙伴、最多 40 回合。

## 暂停前后画面

| 状态 | 截图 | SHA-256 |
| --- | --- | --- |
| Before：基线 `59181c5`，未暂停 | [before_unpaused.png](before_unpaused.png) | `6b556b7a…be2b4f` |
| After：本分支，未暂停（与基线逐字节相同） | [after_unpaused.png](after_unpaused.png) | `6b556b7a…be2b4f` |
| After：本分支，暂停浮层打开 | [after_paused.png](after_paused.png) | `a2e0c9a3…9e870d` |

`before_unpaused.png` 与 `after_unpaused.png` 用 `cmp` 比对完全一致，说明不打开暂停时
战斗画面没有任何变化；`after_paused.png` 是同一战局点击右上角设置后的浮层。

原始哈希：[screenshot_hashes.txt](screenshot_hashes.txt)。

## 冻结口径

暂停不改任何战斗数据，只把全局时间尺度从当前倍速（1x/2x）保存后置为 `0.0`：

- `_process` 在暂停时直接返回，表现计时、HP 缓降、飘字、粒子全部不推进；
- `SceneTreeTimer` 同样受 `Engine.time_scale` 影响，因此消除、前摇、敌方回合、
  波次间隔等所有 `await` 都停在原处；
- 继续时恢复暂停前的倍速，不会重新结算已经发生的消除或敌方行动；
- 暂停期间点倍速按钮不会落到棋盘；即使从代码切换档位，也只记录目标倍速，继续时再生效。

3 秒冻结实测（`battle_pause_test` 原始输出）：

```text
[BattlePause] freeze 3000ms turn=1->1 damage_logs=1->1 windup=0.600->0.600 state=4->4 timer_fired=false
[BattlePause] resume_continue turn=1 damage_logs=1 timer_fired=true
```

- 回合数 `1 → 1`，伤害日志 `1 → 1`；
- 敌方前摇计时 `0.600 → 0.600`，前摇目标与战斗状态不变；
- 暂停前启动的 0.2s 计时器在 3 秒内未触发，继续后正常触发；
- 继续后仍为 1 回合、1 条伤害日志，没有重复结算。

整场固定种子对照：同一场战斗分别「不暂停」与「第 2 回合进行中暂停 3 秒」，
伤害日志、承伤日志与结算 JSON 逐字节一致：

```text
[BattlePause] full_run identical=true turns=7 damage_logs=11 taken_logs=6 result=win
```

结算 JSON 含带时间戳的怪物实例 ID，跨进程哈希会变化，因此这里断言的是同一进程内
「暂停 / 不暂停」两份 JSON 逐字节相等；完整输出见 [test_output.txt](test_output.txt)。

## 开关互通与点击音

三个开关直接读写 `SaveManager.load_settings()/save_settings()` 的同一份设置，
并与设置页的 `SETTINGS_ROWS` 使用同一个键名：`soundOn` / `musicOn` / `vibrationOn`。
点击后同时立即驱动场上节点，不等下一帧轮询：

| 开关 | 写回键 | 立即生效 |
| --- | --- | --- |
| 游戏音效 | `soundOn` | `BattleSfx.apply_settings()`，关闭时释放全部播放器 |
| 背景音乐 | `musicOn` | `BattleBgm.apply_settings()`，关闭时释放 BGM 播放器 |
| 震动反馈 | `vibrationOn` | `VibrationFeedback.apply_settings()`，后续请求只累计丢弃 |

实测输出：

```text
[BattlePause] open settings_click played=1 last=button_click time_scale=0.00
[BattlePause] toggle soundOff saved=false enabled=false players=0
[BattlePause] toggle musicOff saved=false enabled=false players=0
[BattlePause] toggle vibrationOff saved=false enabled=false requests=3->3 dropped=1->2
[BattlePause] toggles restored sound=true music=true vibration=true bgm_players=1
[BattlePause] resume time_scale=2.00 played=5 last=button_click
```

- 打开暂停与点击继续都播放既有 `button_click`，`last_sound_id=button_click`；
- `soundOn=false` 后播放器数为 `0`；
- `vibrationOn=false` 后 `request_count` 从 `3` 到 `3`，只增加 `dropped_count`。

## 退出战斗

「退出战斗」直接切回对应章节的选关页，不经过 `scene_result`，因此不会写星级、
不会结算金币/经验/道具。退出前会把时间尺度恢复为 `1.0`，避免转场计时器被冻结；
旧战斗协程由 `_exiting_battle` 标记拦在结算/波次切换之外。

实测：战前 `gold=1234`、`gems=56`、`stage_1_1` 2 星、`stage_1_2` 1 星。

```text
[BattlePause] exit scene=stage_select time_scale=1.00 player_equal=true progress_equal=true stars=2
```

`load_player()` 与 `load_stage_progress()` 的 JSON 在退出前后完全相等。

## 固定种子逐字节一致

- [battle_before.json](battle_before.json)：基线 `59181c5` 的转录（复用
  `docs/evidence/ui_button_sfx/battle_before.json`）。
- [battle_after.json](battle_after.json)：本分支同口径输出。
- `cmp` 无差异，两份 SHA-256 均为
  `0d6d3c718332bd2a09e2bf44b9f1116d23d6fd962216cc3fa77fb93153490adb`。

原始比对：[battle_compare.txt](battle_compare.txt)。

受保护文件相对 `59181c5` 的 diff 为 0：

- `src/data`
- `src/battle/damage_calculator.gd`
- `src/battle/enemy_attack_modes.gd`
- `src/battle/battle_manager.gd`
- `tests/combat_balance_test.gd`

原始输出：[protected_files_diff.txt](protected_files_diff.txt)。

## 实现位置

- `src/ui/components/battle_pause_overlay.gd`：浮层绘制与命中区域（与绘制共用常量）。
- `src/ui/scene/scene_battle.gd`：设置按钮命中、暂停/继续、三个开关、退出与协程保护。
- `src/ui/scene/scene_battle_gui.gd`：从 `TopHud/SettingsButton` 读取设置按钮矩形。
- `tests/capture_runtime_scene.gd`：新增 `--open-pause=1` 截图开关。
- `tests/battle_pause_test.gd`：本轮回归。

## 复现

```bash
GODOT=~/Applications/Godot.app/Contents/MacOS/Godot

# 暂停/冻结/开关/退出/固定种子回归
$GODOT --headless --path . --fixed-fps 60 --script res://tests/battle_pause_test.gd

# 固定种子转录逐字节比对
$GODOT --headless --path . --script res://tests/prepare_matchup_transcript.gd \
  -- --output=docs/evidence/battle_pause/battle_after.json
cmp docs/evidence/battle_pause/battle_before.json docs/evidence/battle_pause/battle_after.json

# 暂停后截图（基线 Worktree 用同一命令、去掉 --open-pause=1）
MATCH3_SAVE_PATH=/tmp/capture_pause.cfg $GODOT --path . \
  --fixed-fps 60 --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=battle --stage-id=stage_1_1 --hide-toast=1 --open-pause=1 \
  --settle-frames=8 --output=docs/evidence/battle_pause/after_paused.png
```

## 回归

本轮相关回归逐项退出码与说明见 [regression.txt](regression.txt)；完整暂停回归日志见
[test_output.txt](test_output.txt)。

- `battle_pause_test`、`battle_input_test`、`battle_gui_scene_test`、`enemy_windup_test`、
  `battle_sfx_test`、`battle_bgm_test`、`vibration_feedback_test`、`ui_button_sfx_test`、
  `combat_balance_test`、`boss_break_test`、`stun_order_test`、`battle_rules_test`、
  `battle_hit_reaction_test`、`combo_chain_test`、`match_hit_feedback_test`、
  `p0_smoke_test`、`p1_ch1_slice_test`、`stage_progress_loop_test`、
  `battle_result_stats_test`、两阶段 `presentation_settings_restart_test`：全部 exit 0。
- `battle_speed_test` 的墙钟 0.2s 计时器断言在基线 `59181c5` 与本分支同样失败
  （32–33ms，期望 60–180ms），属于 `--fixed-fps` headless 的既有环境口径问题；
  该测试的战斗 JSON 一致性、倍速比例与回合断言均通过，与本轮改动无关。

## 限制

- 仓库没有 GitHub Actions 工作流，本轮没有可等待的 CI；回归以本地 headless 输出为准。
- headless/无音频设备环境无法试听点击音，只验证 `button_click` 的触发次数与播放器生命周期。
- 浮层使用自绘圆角面板与既有 `ui_settings_button.png` 齿轮，没有新增图片资源。
