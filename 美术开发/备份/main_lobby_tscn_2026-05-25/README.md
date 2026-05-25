# 大厅 TSCN 迁移前备份

备份时间：2026-05-25

## 备份内容

| 文件 | 内容 |
|---|---|
| `scene_main_legacy_draw.gd.bak` | 迁移前大厅完整 `_draw()` 与手工点击区实现 |
| `main_lobby_before.png` | 迁移前 Godot 运行画面基线 |
| `main_lobby_after_exp_fix.png` | TSCN 迁移及经验条校正后的运行画面 |

## 本轮迁移范围

- 新大厅场景：`res://src/ui/scenes/main_lobby.tscn`
- 控制脚本：`res://src/ui/scene/scene_main.gd`
- 粒子层脚本：`res://src/ui/components/lobby_particle_layer.gd`
- 场景加载入口：`res://main.gd` 仅将 `main` 指向 PackedScene
- 战斗、关卡及其余功能界面不在本轮改动范围内。

旧绘制版源文件保留为 `.gd.bak`，不会被 Godot 注册为同名 `class_name` 脚本。
