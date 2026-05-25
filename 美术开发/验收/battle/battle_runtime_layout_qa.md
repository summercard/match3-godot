# 局内战斗画面对照概念图优化验收

## 对照目标

| 概念图区域 | 本轮处理 |
| --- | --- |
| 顶部回合、Boss 名称、Boss HP、速度/设置按钮 | 顶部 HUD 改为紧凑回合牌、居中敌方名称和 HP、右侧功能按钮 |
| 上半屏 Boss/敌人舞台 | 单敌人时使用大舞台展示，不再用小敌方卡片占位 |
| 我方三张卡牌 | 卡牌改为怪物半身展示，HP 条放在怪物下方，能量条在更下层 |
| 主体 8x8 棋盘 | 棋盘整体下移并保留清晰包边，避免与我方卡牌重叠 |
| 底部奖励/得分/能量区 | 本项目当前功能是状态、捕捉、道具，已按同样三段底栏思路压缩布局 |

## 验收结果

| 检查项 | 结果 | 说明 |
| --- | --- | --- |
| 我方 HP 层级 | 通过 | HP 位于怪物下方，未盖在怪物主体上 |
| 我方怪物裁切 | 通过 | 怪物使用半身展示，不强行露出全身 |
| 敌方意图层级 | 通过 | 单体敌人的意图提示移到右侧，不压住敌人/Boss 主体 |
| 多敌人同台 | 通过 | 2-3 敌人分支已去除旧卡框，改为同台站位、元素弧光、小血条和轻量意图提示 |
| Boss 体量 | 通过 | Boss 关使用更大立绘与元素弧光舞台，主体压迫感更接近概念图 |
| 底栏裁切 | 通过 | 捕捉开关与道具图标收进底栏，没有贴边裁切 |
| 棋盘点击区 | 通过 | `battle_input_test.gd` 通过 |
| 主流程冒烟 | 通过 | `p0_smoke_test.gd` 通过 |
| 普通关运行截图 | 通过 | `美术开发/验收/battle/battle_runtime_final_opt.png` |
| Boss 关运行截图 | 通过 | `美术开发/验收/battle/battle_runtime_boss_final_opt.png` |
| 第三章2敌截图 | 通过 | `美术开发/验收/battle/battle_runtime_ch3_multi2_opt.png` |
| 第三章3敌截图 | 通过 | `美术开发/验收/battle/battle_runtime_ch3_multi3_opt.png` |
| 局内 UI 资产化 | 通过 | 血条、toast、连击牌、选中格已接入 PNG 资源 |
| 战斗反馈资产化 | 通过 | 伤害、暴击、治疗、命中、护盾、蓄力、消除爆点已有 PNG 反馈资产 |
| 反馈层级 | 通过 | 连击牌位于棋盘中段，伤害/治疗在怪物附近，不遮挡 Boss 主体信息 |
| 反馈验收截图 | 通过 | `美术开发/验收/battle/battle_runtime_feedback_fx_opt.png` |
| 三敌反馈验收截图 | 通过 | `美术开发/验收/battle/battle_runtime_feedback_multi_opt.png` |

## 2026-05-25 常驻 UI 正式资产替换验收

| 检查项 | 结果 | 说明 / 证据 |
| --- | --- | --- |
| 棋盘背板与格槽 | 通过 | `ui_board_frame.png` 与 `ui_board_cell.png` 已接入；`battle_runtime_formal_ui_normal.png` 可见厚边框和独立槽底 |
| 回合提示牌 | 通过 | 顶部使用 `ui_top_scrim.png` 与 `ui_turn_badge.png`，仅保留动态回合数字文字层 |
| 加速/设置按钮 | 通过 | `ui_speed_button.png` 与 `ui_settings_button.png` 已接入，设置图标不再依赖系统字符 |
| 下方功能按钮 | 通过 | `ui_footer_panel.png`、捕捉开关、道具槽与捕捉球/药水图标均由正式资源渲染 |
| 敌方行动牌 | 通过 | 单体与多敌的行动提示使用五种状态 PNG；见 `battle_runtime_formal_ui_normal.png` 与 `battle_runtime_formal_ui_multi3.png` |
| 怪物拉伸修复 | 通过 | 敌方走等比 contain、我方走等比 cover 半身裁切；非方形素材专项图 `battle_runtime_formal_ui_aspect_qa.png` 未见压扁或横向拉宽 |
| Boss 特效叠层 | 通过 | `battle_runtime_formal_ui_boss_fx.png` 中 Boss、伤害、连击、棋盘和操作台层级互不遮挡关键读数 |
| 输入回归 | 通过 | `tests/battle_input_test.gd` 通过，底栏点击区域与新贴图位置同步 |
| 流程回归 | 通过 | `tests/p0_smoke_test.gd` 通过 |

### 本轮验收图

- `美术开发/验收/battle/battle_runtime_formal_ui_normal.png`
- `美术开发/验收/battle/battle_runtime_formal_ui_boss_fx.png`
- `美术开发/验收/battle/battle_runtime_formal_ui_multi3.png`
- `美术开发/验收/battle/battle_runtime_formal_ui_aspect_qa.png`
