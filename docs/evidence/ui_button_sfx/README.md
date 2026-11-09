# 战斗外七个页面主按钮音效

把现有 `BattleSfx` 音效层接到大厅、选关、战斗准备、背包、商店、图鉴、设置七个页面的主按钮：
复用同一个 `src/ui/components/battle_sfx.gd`，没有第二个合成器、没有新增音频文件。
每个页面挂一个 `ButtonSfx` 子节点，页面销毁时连同播放器一起释放；设置页的 `soundOn`
同时控制战斗音效与按钮音效。

## 口径

- 基线：`dc4a037`（PR #22 合并后的 main）。
- 改动后：`agent/ui-button-sfx-656eeaade6a0`。
- 运行环境：Godot `4.7.2.stable`（`ed1daf0bf`），macOS Apple M1。
- 截图使用独立空存档 `MATCH3_SAVE_PATH=/tmp/.../capture_*.cfg`，保证两态玩家等级、金币等一致。
- 听感不判（headless/无音频设备）；本轮验证参数、播放次数、播放器生命周期与战斗数值逐字节一致。

## 按钮点击音

`button_click` 追加在既有七个战斗音之后，既有七个战斗音的 `CONFIG` 一个字段都没改；
`FROZEN_BATTLE_SOUNDS` 在回归里冻结这些参数。

| 参数 | 既有七音 | `button_click` |
| --- | --- | --- |
| 波形 | `sine` / `triangle` / `square` / `noise` / `saw` / `pulse` | `click`（新增窄脉冲波形） |
| 基频 | 110–880 Hz | `1046.5 Hz` |
| 时长 | 0.09–0.60 s | `0.045 s` |
| 起音 | 0.002–0.010 s | `0.001 s` |
| 衰减 | 3.5–35.0 | `60.0` |
| 泛音 | 0.5–3.0 | 无 |

相对任意既有战斗音，波形、频率、时长三项都不同；起音/衰减也不同。

## 页面接入

| 页面 | 场景/脚本 | 接入的主按钮 |
| --- | --- | --- |
| 大厅 | `main_lobby.tscn` / `scene_main.gd` | 冒险之旅、编队、牧场、商店、图鉴、背包、成就、设置、签到 |
| 选关 | `stage_select_map.tscn` / `scene_stage_select_gui.gd` | 返回、上一章、下一章、关卡节点、扫荡、扫荡确认/取消 |
| 战斗准备 | `battle_prepare.tscn` / `scene_battle_prepare_gui.gd` | 返回、开始战斗 |
| 背包 | `inventory.tscn` / `scene_inventory_gui.gd` | 返回、页签、格子、上一页/下一页、使用 |
| 商店 | `shop.tscn` / `scene_shop_gui.gd` | 返回、页签、商品卡、翻页、弹窗关闭/加减/取消/购买 |
| 图鉴 | `album.tscn` / `scene_album_gui.gd` | 返回、筛选、卡片、翻页、详情关闭/进化、底部页签 |
| 设置 | `scene_settings.gd` | 返回、音效/音乐/震动开关、画质/表现分段、重置、恢复默认、确认/取消 |

七个页面都在原生按钮信号的同一入口接一次音效；`_connect_button` 用
`ui_button_sfx_wired` 标记防止重复连接，因此一次点击只发一次 `button_click`。
`ButtonSfx` 是场景子节点，页面 `queue_free()` 后播放器和节点一起释放。

## 开关实测计数

完整原始输出：[test_output.txt](test_output.txt)。

- 开启（`soundOn=true`）：33 次主按钮点击 → `played=33`、`requests=33`，
  每个页面每次点击恰好 +1，没有重复触发；播放器池 8 个。
- 关闭（`soundOn=false`）：同样 33 次点击 → `played=0`、`requests=0`、`players=0`。
- 所有页面关闭后整棵场景树无 `ButtonSfx`、无 `AudioStreamPlayer` 残留。
- 同帧 12 次请求仍只播放 8 次，`dropped_count=4`。

原始分页计数：

- [on_counts.txt](on_counts.txt)
- [off_counts.txt](off_counts.txt)

## 固定种子战局逐字节一致

使用与既有 `prepare_matchup_transcript.gd` 相同的口径：`stage_1_1`、seed `20261111`、
5 级、三只伙伴（`monster_001/002/003`）、最多 40 回合。

- [battle_before.json](battle_before.json)：基线 `dc4a037`
- [battle_after.json](battle_after.json)：本分支
- `cmp` 无差异，两个文件 SHA-256 均为
  `0d6d3c718332bd2a09e2bf44b9f1116d23d6fd962216cc3fa77fb93153490adb`
- 结果见 [battle_compare.txt](battle_compare.txt)。

受保护文件相对 `dc4a037` 的 diff 为 0：

- `src/data`
- `src/battle/damage_calculator.gd`
- `src/battle/enemy_attack_modes.gd`
- `src/battle/battle_manager.gd`
- `tests/combat_balance_test.gd`
- `src/ui/components/battle_bgm.gd`

原始输出：[protected_files_diff.txt](protected_files_diff.txt)。

## 画面不变对照

本轮没有改绘制、布局或动画。用同一场景、同一 750×1334 视口、同一 `--fixed-fps 60`
和空存档，在基线 `dc4a037`（before）与本分支（after）各截 7 张图：

| 页面 | Before（dc4a037） | After（本分支） | SHA-256 |
| --- | --- | --- | --- |
| 大厅 | [before/main.png](before/main.png) | [after/main.png](after/main.png) | 一致 |
| 选关 | [before/stage_select.png](before/stage_select.png) | [after/stage_select.png](after/stage_select.png) | 一致 |
| 战斗准备 | [before/battle_prepare.png](before/battle_prepare.png) | [after/battle_prepare.png](after/battle_prepare.png) | 一致 |
| 背包 | [before/inventory.png](before/inventory.png) | [after/inventory.png](after/inventory.png) | 一致 |
| 商店 | [before/shop.png](before/shop.png) | [after/shop.png](after/shop.png) | 一致 |
| 图鉴 | [before/album.png](before/album.png) | [after/album.png](after/album.png) | 一致 |
| 设置 | [before/settings.png](before/settings.png) | [after/settings.png](after/settings.png) | 一致 |

完整哈希见 [screenshot_hashes.txt](screenshot_hashes.txt)，7 对 PNG 全部逐字节相同。

## 复现

```bash
GODOT=~/Applications/Godot.app/Contents/MacOS/Godot

# 页面按钮音回归（含 on/off 计数、页面释放、同帧上限）
$GODOT --headless --path . --fixed-fps 60 --script res://tests/ui_button_sfx_test.gd

# 既有战斗音效回归（8 音参数冻结、PCM、同帧上限、固定战局）
$GODOT --headless --path . --fixed-fps 60 --script res://tests/battle_sfx_test.gd

# 固定种子战局逐字节比对
$GODOT --headless --path . --script res://tests/prepare_matchup_transcript.gd \
  -- --output=/tmp/battle_after.json
cmp docs/evidence/ui_button_sfx/battle_before.json /tmp/battle_after.json

# 截图（基线/分支各跑一次，独立空存档保证 UI 状态一致）
MATCH3_SAVE_PATH=/tmp/capture_before.cfg $GODOT --path /path/to/dc4a037 \
  --fixed-fps 60 --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=main --stage-id=stage_1_1 --settle-frames=3 --hide-toast=1 \
  --output=/tmp/before_main.png
```

## 本轮回归（全部 exit 0）

`ui_button_sfx_test`、`battle_sfx_test`、`battle_bgm_test`、`lobby_result_bgm_test`、
`main_lobby_scene_test`、`stage_select_gui_scene_test`、
`battle_prepare_result_gui_scene_test`、`inventory_gui_scene_test`、`shop_gui_scene_test`、
`album_gui_scene_test`、`p0_smoke_test`、`p1_ch1_slice_test`、`combat_balance_test`、
`boss_break_test`、`stun_order_test`、`battle_rules_test`、`battle_gui_scene_test`、
`battle_result_stats_test`、`battle_hit_reaction_test`、`combo_chain_test`、
`match_hit_feedback_test`、`vibration_feedback_test`。

## 限制

- 仓库没有 GitHub Actions 工作流，本轮没有可等待的 CI；回归以本地 headless 输出为准。
- headless 环境无法试听音色，只验证合成参数、PCM 可播放性、触发次数和生命周期。
