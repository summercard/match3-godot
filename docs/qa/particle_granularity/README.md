# 命中粒子加大加饱满（方形像素块）验收素材

对应「同一次命中更饱满，不是更多更碎」的表现层调整：

- 单颗粒子从 2.0–3.4px 的圆形改为 **6.0–10.0px 的实心方形像素块**，整数边长、
  硬边缘，不抗锯齿、不圆角；只淡出，不再缩小成碎点；
- 一次命中粒子数改为 **轻量 2 / 均衡 4 / 华丽 6**，仍受 T3 的
  单次命中粒子上限 4 / 8 / 12 约束；
- 寿命 0.22s、速度 86–138 保持；不改变施法 0.18s / 飞行 0.24s / 总 0.42s、
  命中 0.25s、环上限 1 / 2 / 3、弹体上限 `max(档位, 本波格数)`、连锁参数、
  伤害公式与 `src/data`。

实现只改 `src/ui/components/element_flight_effect.gd` 的粒子参数与命中段绘制，
量测/采集脚本见 `tests/element_flight_effect_test.gd`、
`tests/particle_granularity_capture.gd`。

## 参数

| 参数 | 旧值 | 新值 |
| --- | --- | --- |
| `particle_size_min` / `particle_size_max` | 2.0 / 3.4px | **6.0 / 10.0px** |
| 绘制形状 | `draw_circle`（圆） | `draw_rect(..., antialiased=false)`（实心方块） |
| 单次命中粒子数 | 轻量 2 / 均衡 4 / 华丽 5（按 `effect_density` 缩放） | **轻量 2 / 均衡 4 / 华丽 6**（按表现档位直接取） |
| `particle_life` | 0.22s | 0.22s（未改） |
| `particle_speed_min` / `max` | 86 / 138 | 86 / 138（未改） |
| T3 `tier_budgets.particles` | 4 / 8 / 12 | 4 / 8 / 12（未改，作为硬上限） |

粒子数取 `min(档位粒子数, tier_budgets.particles)`；本档实际 2 / 4 / 6 均低于
硬上限 4 / 8 / 12，因此三档都不会触发粒子预算丢弃。

## 量测

### 单次命中数量与单颗尺寸

采集条件：`stage_1_1`、seed `20261109`、750×1334 窗口（375×667 视口，2× 渲染）、
画质精细、1 个弹体命中、命中后 0.10s（`t=0.52s`）冻结。三档同种子、同坐标。

| 档位 | before 数量 | after 数量 | before 尺寸（`particle_size`） | after 尺寸（`particle_size`） |
| --- | ---: | ---: | --- | --- |
| 轻量 | 2 | **2** | 2.71 / 2.10 | 8.02 / 6.28 |
| 均衡 | 4 | **4** | 2.71 / 2.10 / 2.09 / 2.87 | 8.02 / 6.28 / 6.26 / 8.47 |
| 华丽 | 5 | **6** | 2.71 / 2.10 / 2.09 / 2.87 / 2.85 | 8.02 / 6.28 / 6.26 / 8.47 / 8.43 / 6.42 |

`particle_size` 是方块边长。上面是本次随机到的边长；可配范围为 6.0–10.0px，
绘制时取整为 6–10px。均衡档同帧的实际像素量测：

| 粒子 | before 包围盒（视口 px） | after 包围盒（视口 px） |
| --- | ---: | ---: |
| 1 | 3.5 × 3.5 | **8 × 8** |
| 2 | 2.5 × 3.0 | **6 × 6** |
| 3 | 2.5 × 3.0 | **6 × 6** |
| 4 | 3.5 × 4.0 | **8 × 8** |

（截图 2× 渲染，上表已换算回视口 px；对应截图像素 7×7 / 5×6 / 5×6 / 7×8 →
16×16 / 12×12 / 12×12 / 16×16。）方块的硬边缘在 2× 截图中是整像素台阶，
没有抗锯齿羽化。

### 覆盖率倍数

口径：`count × size²`，三档分别计算。取最保守的边界（新粒子用最小 6.0px，
旧粒子用最大 3.4px）仍满足 ≥1.2×：

| 档位 | 旧 count×size² | 新 count×size² | 最保守倍数 |
| --- | ---: | ---: | ---: |
| 轻量 | 2 × 3.4² = 23.12 | 2 × 6.0² = 72.0 | **3.11×** |
| 均衡 | 4 × 3.4² = 46.24 | 4 × 6.0² = 144.0 | **3.11×** |
| 华丽 | 5 × 3.4² = 57.80 | 6 × 6.0² = 216.0 | **3.74×** |

按尺寸中值（旧 2.7px、新 8.0px）计算则为 **8.78× / 8.78× / 10.53×**；
三档合计（旧 11 粒、新 12 粒）为 **9.58×**。两种口径都远高于 1.2×。

同帧实际彩色像素面积（均衡档，2× 截图）：before 134px² → after 800px²，
**5.97×**（旧粒子是圆，`size` 作为半径；方块按边长覆盖，所以实际面积倍数
高于 `size²` 口径的保守倍数）。

## 证据

同种子、同棋盘、同交换、同帧；before 取自基线 `7585b9b` 工作树，after 为本分支。
主对照为均衡档 `t=0.52s`（命中后 0.10s，白闪已过、粒子已展开）。

| 文件 | 说明 | md5 |
| --- | --- | --- |
| [compare_balanced.png](compare_balanced.png) | **Before / After / Overlay 三联对照** | `4f33ca1759d08d38682d8b3f55dc92d2` |
| [tier_compare.png](tier_compare.png) | 轻量 2 / 均衡 4 / 华丽 5→6 三档对照 | `0b91d8ab3bf91542a8bd35474c31695e` |
| [compare_balanced_hit.png](compare_balanced_hit.png) | 命中后 0.04s 的即时饱满度对照 | `98cf4ae1915dcad0767371bd5341da8a` |
| [before_balanced.png](before_balanced.png) | 基线全帧 | `c74ddfaffe41ce81271ee8e4ae35c74c` |
| [after_balanced.png](after_balanced.png) | 本分支全帧 | `cd1a904b438ae18be1953c8d84a98f2c` |
| [overlay_balanced.png](overlay_balanced.png) | Before 50% + After 50% 叠图（无文字版） | `702ef4d56bb35798b9d8e1e3aa9086b2` |
| [before_balanced_crop.png](before_balanced_crop.png) | 基线局部 4× 放大 | `9bb0369cc0b04d601138d1537196681e` |
| [after_balanced_crop.png](after_balanced_crop.png) | 本分支局部 4× 放大 | `f9dc4805f8871742cd28efd10d857f9a` |

叠图直接使用同一帧的 50/50 混合：叠图中大号浅绿方块来自 after，里面仍能
看到 before 的小点，因此能同时读出「位置不变、单颗变大、数量不变」。
before / after 全帧的像素差异只出现在命中点 52×52 的范围内（679 个像素），
其余战斗 UI 逐像素一致。

## 回归

- `tests/element_flight_effect_test.gd`：三段时序、10→46px 扩环、白闪 0.06s、
  拖尾、粒子 2/4/6、6–10px、覆盖率 ≥1.2×、开 / 关固定战局日志逐字节一致，全部通过。
- `tests/element_flight_chain_tier_test.gd`：T3 连锁环 1.2× / +11.1% / 第二圈
  +0.06s / 60%、轻量环 ×0.8 无第二圈、弹体 6/0/6、环峰值 1/2/3、
  粒子硬上限 4/8/12、震屏记录 0，全部通过。
- 相关回归：`battle_presentation_test`、`match_hit_feedback_test`、
  `combat_balance_test`、`presentation_settings_restart_test`（write → read）、
  `p0_smoke_test` 均 exit 0。
- 固定种子战斗日志 / 结算 JSON 与基线逐字节一致（17434 字节，
  `baseline identical=true on_off_identical=true`）。
- 相对 `7585b9b` 的实现 / 测试改动为
  `src/ui/components/element_flight_effect.gd`、`tests/element_flight_effect_test.gd`
  与本采集脚本；另在 `docs/qa/element_flight/README.md`、`docs/qa/chain_tier/README.md`
  顶部加了指向本文的提示。`src/data`、伤害公式、环 / 弹体上限、连锁参数零改动。

## 复现

```bash
GODOT=~/Applications/Godot.app/Contents/MacOS/Godot

# 参数 / 覆盖率 / T3 回归
MATCH3_SAVE_PATH=/tmp/particle_flight.cfg \
  $GODOT --headless --path . --fixed-fps 60 \
  --script res://tests/element_flight_effect_test.gd
MATCH3_SAVE_PATH=/tmp/particle_t3.cfg \
  $GODOT --headless --path . --fixed-fps 60 \
  --script res://tests/element_flight_chain_tier_test.gd

# 三档同种子采集（after）
for tier in lite balanced rich; do
  MATCH3_SAVE_PATH=/tmp/particle_${tier}.cfg \
    $GODOT --path . --fixed-fps 60 \
    --script res://tests/particle_granularity_capture.gd -- \
    --performance-mode=${tier} --quality-level=high --chain=1 \
    --projectiles=1 --gem-type=grass --at=0.52 \
    --output=/tmp/after_${tier}.png
done

# before：在 7585b9b 工作树放入同一采集脚本后运行
$GODOT --path /path/to/7585b9b --fixed-fps 60 \
  --script res://tests/particle_granularity_capture.gd -- \
  --performance-mode=balanced --quality-level=high --chain=1 \
  --projectiles=1 --gem-type=grass --at=0.52 \
  --output=/tmp/before_balanced.png
```

采集脚本只读取现有的 `ElementFlightEffect` 接口，因此同一份脚本既能在基线
工作树录 before，也能在本分支录 after；两边使用同一个 `--seed=20261109`。
