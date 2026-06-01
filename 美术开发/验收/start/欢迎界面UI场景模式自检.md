# 欢迎界面 UI 场景模式自检

更新时间：2026-05-31

## 迁移结果

| 检查项 | 状态 | 说明 |
| --- | --- | --- |
| PackedScene 接入 | 完成 | `main.gd` 已将 `start` 映射到 `src/ui/scenes/start_screen.tscn` |
| 静态视觉节点化 | 完成 | 背景、Logo、三只怪物、五颗宝石、按钮、提示旗帜、版本牌均可在编辑器独立调整 |
| Canvas 手绘移除 | 完成 | `scene_start.gd` 不再承担整屏 `_draw()` |
| 动效职责拆分 | 完成 | 怪物、宝石、按钮轻动画保留在控制器；怪物和宝石动画基准位置从场景节点读取；星点装饰独立为 `start_particle_layer.gd` |
| 单击进入 | 完成 | `StartButton.button_down` 直接进入，不需要长按 |
| 教程分流 | 完成 | 未完成教程进入 `tutorial`；已完成教程进入 `main` |

## 自动验证

| 命令 | 结果 |
| --- | --- |
| `godot --headless --path /Users/summercards/WeChatProjects/match3-godot --quit-after 5` | 通过 |
| `godot --headless --path /Users/summercards/WeChatProjects/match3-godot --script res://tests/start_gui_scene_test.gd` | 通过 |
| `godot --headless --path /Users/summercards/WeChatProjects/match3-godot --script res://tests/p0_smoke_test.gd` | 通过 |
| `godot --headless --path /Users/summercards/WeChatProjects/match3-godot --script res://tests/tutorial_flow_test.gd` | 通过 |

## 视觉验收

运行截图输出到 `美术开发/验收/start/start_screen_ui_scene_runtime.png`。

| 检查项 | 状态 |
| --- | --- |
| Logo 比例与顶部居中 | 通过 |
| 三只怪物遮挡关系与比例 | 通过 |
| 五颗宝石浅弧线排列 | 通过 |
| 开始按钮比例与文字居中 | 通过 |
| 提示文字、版本牌纵向对齐 | 通过 |
