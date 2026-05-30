# 背包与图鉴 GUI 成品化验收

日期：2026-05-27

## 验收范围

| 界面 | 场景 | 验收截图 |
|---|---|---|
| 怪物图鉴 | `src/ui/scenes/album.tscn` + `src/ui/scene/scene_album_gui.gd` | `美术开发/验收/album/album_gui_paged_runtime.png` |
| 背包 | `src/ui/scenes/inventory.tscn` + `src/ui/scene/scene_inventory_gui.gd` | `美术开发/验收/inventory/inventory_gui_paged_runtime.png` |

## 修正记录

| 界面 | 问题 | 处理 |
|---|---|---|
| 怪物图鉴 | 旧 Canvas 滑动列表不方便编辑 | 已迁移为 GUI 场景，6 张卡/页，筛选、卡片、详情和底部页签均为节点 |
| 怪物图鉴 | 贴图可能按源尺寸撑开 | 所有核心贴图节点使用按节点框显示，运行图无源图裁切/撑爆 |
| 背包 | 格内文字太小且拥挤 | 物品格去掉小名称，仅保留图标和数量，详情区负责完整文字 |
| 背包 | 旧滚动槽、锁位和分页节点叠加 | 面板换为干净底板，保留 15 个实际物品格和独立翻页控制 |
| 背包 | 仍是拖拽滚动，不方便手机端稳定布局 | 改为 15 格/页的翻页结构，按钮热区独立 |

## 自动验收

| 命令 | 结果 |
|---|---|
| `godot --headless --path . --script res://tests/album_gui_scene_test.gd` | 通过 |
| `godot --headless --path . --script res://tests/inventory_gui_scene_test.gd` | 通过 |
| `godot --headless --path . --script res://tests/p0_smoke_test.gd` | 通过 |
