# 商店 GUI 成品化验收

日期：2026-05-27

## 范围

| 界面 | 场景 | 验收截图 |
|---|---|---|
| 商店主界面 | `src/ui/scenes/shop.tscn` + `src/ui/scene/scene_shop_gui.gd` | `美术开发/验收/shop/shop_gui_runtime.png` |
| 购买确认弹窗 | `src/ui/scenes/shop.tscn` + `src/ui/scene/scene_shop_gui.gd` | `美术开发/验收/shop/shop_gui_popup_runtime.png` |
| 购买获得提示 | `src/ui/scenes/shop.tscn/Toast` + `src/ui/scene/scene_shop_gui.gd` | `美术开发/验收/shop/shop_gui_toast_runtime.png` |

## 修正记录

| 问题 | 处理 |
|---|---|
| 原商店为 Canvas 绘制，不方便手动调按钮和资产 | 迁移为可编辑 Godot GUI 场景 |
| 商品四列滚动在手机端偏密 | 改为 9 张商品卡/页，使用翻页按钮 |
| 新手超值礼包暂时不需要 | 隐藏 `FeatureBanner` 节点，让后方商店背景露出 |
| 手机端不需要二次购买按钮 | 去掉商品卡内独立购买按钮，点击商品卡/图标直接进入购买确认 |
| 购买弹窗贴近底部导航 | 弹窗整体上移并加高，按钮组重新排布 |
| 数量 `+10` 按钮贴边 | 数量按钮组向内收，避免视觉溢出 |
| 获得物品提示压在商品区底部 | 改为商人旁的暖色漫画对话框，`Toast/Frame` 与 `Toast/Tail` 可在编辑器中直接调整；提示自动收起且不遮挡商品卡 |

## 自动验收

| 命令 | 结果 |
|---|---|
| `godot --headless --path . --script res://tests/shop_gui_scene_test.gd` | 通过 |
| `godot --headless --path . --script res://tests/p0_smoke_test.gd` | 通过 |
