# 成就列表滚动遮挡验收

日期：2026-05-27

## 结论

成就系统保持 Canvas 绘制，不迁移为 GUI 场景。本轮只修复下滑时成就列表越界覆盖顶部 UI 的问题。

## 修正

| 问题 | 处理 |
|---|---|
| 成就卡片滚动到 `LIST_TOP` 以上后仍继续绘制，覆盖总览和分类栏 | `_draw()` 改为先绘制列表，再重绘顶部背景、标题、总览和分类栏 |
| 半截卡片在分类栏下方透出，视觉不干净 | `_draw_list()` 只绘制完整落在 `LIST_TOP` 到 `LIST_BOTTOM` 内的卡片 |
| 不可见半截卡仍可能响应点击 | 点击处理增加完整可见判断，不可见半截卡不响应 |

## 验收

| 项目 | 结果 |
|---|---|
| 滚动截图 | `美术开发/验收/achievement/achievement_scroll_clip_runtime.png` |
| 脚本检查 | `godot --headless --path . --check-only --script res://src/ui/scene/scene_achievement.gd` 通过 |
| 主流程冒烟 | `godot --headless --path . --script res://tests/p0_smoke_test.gd` 通过 |
