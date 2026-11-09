# 战斗音效层

对应「六个程序化合成战斗音效、参数集中一处、总开关接设置页 soundOn、同帧最多 8 个播放实例」的改动。

- 参数与总开关：`src/ui/components/battle_sfx.gd`（`CONFIG` + `enabled`）。
- 六个音效在运行时写入 `AudioStreamWAV`（16-bit PCM，22050Hz，单声道），仓库不新增任何外部或二进制音频文件。
- 总开关关闭时不创建任何 `AudioStreamPlayer`；战斗场景同时跳过连锁音效节点，场上播放器数为 0。
- 同一引擎帧最多触发 8 个实例，超出的请求丢弃并累加 `dropped_count`；播放器池固定 8 个，不随请求增长。

## 画面不变对照

音效层不修改任何绘制、布局或动画；同一战局、同一起始随机种子、同一 750×1334 视口下：

| 文件 | 版本 | 说明 |
| --- | --- | --- |
| `before.png` | 基线 `02c69fd`（main） | 战斗画面：`stage_1_1`，伤害演示帧 |
| `after.png` | 本分支 | 同场景、同帧；与 `before.png` 字节一致 |

两张 PNG 的 SHA-256 均为 `87fcd66a7b46cf22474ae6c7ec13ad939810baaf296aad58dd990aefa3cd32ae`，证明音效接入没有改变画面。

```bash
# Before：基线 02c69fd 工作树
$GODOT --path /path/to/baseline-02c69fd --fixed-fps 60 \
  --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=battle --stage-id=stage_1_1 --battle-demo-damage=1 \
  --hide-toast=1 --output=/tmp/battle_sfx_before.png

# After：本分支
$GODOT --path . --fixed-fps 60 \
  --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=battle --stage-id=stage_1_1 --battle-demo-damage=1 \
  --hide-toast=1 --output=/tmp/battle_sfx_after.png
```

## 参数口径

| 音效 | 触发点 | 基频 | 结束频率 | 时长 | 波形 | 起音 | 衰减 | 泛音 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `match_clear` 消除 | 每次消除结算 | 880Hz | 880Hz | 0.120s | sine | 0.004s | 30.0 | 2.0× / 25% |
| `hit` 普通打击 | 普通伤害（非克制） | 220Hz | 220Hz | 0.090s | triangle | 0.002s | 35.0 | 3.0× / 15% |
| `crit` 暴击 | 克制伤害（`isEffective`） | 520Hz | 520Hz | 0.220s | square | 0.002s | 14.0 | 1.5× / 30% |
| `take_damage` 受击 | 敌方命中伙伴 | 110Hz | 110Hz | 0.180s | noise | 0.003s | 18.0 | — |
| `victory` 胜利 | 战斗胜利结算 | 660Hz | 990Hz | 0.500s | saw | 0.010s | 3.5 | 2.0× / 20% |
| `defeat` 失败 | 战斗失败结算 | 300Hz | 120Hz | 0.600s | pulse | 0.005s | 4.0 | 0.5× / 20% |

- 六种音效使用六种不同波形，且频率、时长、起音、衰减均两两不同；任意两项至少 3 项参数不同。
- `victory` 上滑、`defeat` 下滑；`take_damage` 用确定性噪声，保证每次生成的数据一致。
- 生成后按峰值统一归一化，避免不同波形叠加削波；末端 20ms 淡出，避免爆音。

## 触发与边界

| 事件 | 音效 | 代码入口 |
| --- | --- | --- |
| 三消消除成功 | `match_clear` | `scene_battle.gd` → `_process_matches` |
| 普通/克制伤害 | `hit` / `crit` | `_process_matches` 伤害循环、`_apply_skill_result_visuals` |
| 敌方命中伙伴 | `take_damage` | `_on_enemy_attacked` |
| 战斗结束 | `victory` / `defeat` | `_begin_battle_end_overlay` |

- 全部音效只读取现有事件数据，不写战斗状态、伤害日志或结算统计。
- 关闭总开关时 `play()` 直接返回，不生成/保留播放器；重新打开后按需创建。
- 播放器池 8 个，同一帧第 9 次请求开始丢弃并计数。

## 验证

```bash
GODOT=~/Applications/Godot.app/Contents/MacOS/Godot

$GODOT --headless --path . --fixed-fps 60 --script res://tests/battle_sfx_test.gd
$GODOT --headless --path . --fixed-fps 60 --script res://tests/combat_balance_test.gd
$GODOT --headless --path . --fixed-fps 60 --script res://tests/battle_hit_reaction_test.gd
$GODOT --headless --path . --fixed-fps 60 --script res://tests/combo_chain_test.gd
```

`tests/battle_sfx_test.gd` 覆盖：

1. 六个音效参数两两至少 3 项不同，波形互不相同；
2. 六段 PCM 均可播放且数据互不相同；
3. `soundOn=false` 时播放器数为 0，不播放；运行中关闭会立即释放播放器；
4. 同一帧 12 次请求只播放 8 次、丢弃 4 次；下一帧重新获得 8 次额度，播放器池不超过 8；
5. 音效开/关两种状态下，`stage_1_1` + 固定种子 `20261109` 的固定回合脚本（最多 20 回合，本次 4 回合结束），伤害日志、承伤日志与完整结算统计逐位一致；
6. 战斗场景按 `soundOn` 同步总开关；关闭设置时整场 `AudioStreamPlayer` 数为 0（含连锁音效池）；
7. 敌方命中触发 `take_damage`，胜利/失败结算分别触发 `victory` / `defeat`。

### 测试输出原文

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[BattleSfx] match_clear freq=880.0Hz end=880.0Hz dur=0.120s wave=sine attack=0.004s decay=30.0
[BattleSfx] hit         freq=220.0Hz end=220.0Hz dur=0.090s wave=triangle attack=0.002s decay=35.0
[BattleSfx] crit        freq=520.0Hz end=520.0Hz dur=0.220s wave=square attack=0.002s decay=14.0
[BattleSfx] take_damage freq=110.0Hz end=110.0Hz dur=0.180s wave=noise attack=0.003s decay=18.0
[BattleSfx] victory     freq=660.0Hz end=990.0Hz dur=0.500s wave=saw attack=0.010s decay=3.5
[BattleSfx] defeat      freq=300.0Hz end=120.0Hz dur=0.600s wave=pulse attack=0.005s decay=4.0
[BattleSfx] frame cap: frame1 played=8 dropped=4, frame2 played=8 dropped=5, players=8
[BattleSfx] combat log: damage=12 taken=3 turns=4 result=win
[BattleSfx] on/off identical=true on_played=8 off_played=0 off_players=0
[BattleSfx] OK
```

## 未改动范围

本次没有修改 `monster_db`、`stage_db`、`damage_calculator`、`enemy_attack_modes`、波次、前摇、飘字、连锁伤害、命中反馈、受击反应或结算页数值；画面与操作时序不因音效改变。连锁音效仅在 `soundOn` 关闭时跳过节点创建，开启时仍使用原组件与原先听感。
