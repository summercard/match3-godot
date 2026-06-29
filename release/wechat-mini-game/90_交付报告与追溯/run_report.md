# 运行报告

## 运行环境

- 日期：2026-06-29
- Godot：4.6.3.stable.official.7d41c59c4
- 渲染：Vulkan / Forward Mobile / NVIDIA GeForce RTX 4060 Ti
- 工作目录：`I:\工作项目\match3-godot`
- 命令入口：`tests/capture_runtime_scene.gd`
- 隔离存档：`release/wechat-mini-game/90_交付报告与追溯/capture_save.cfg`

## 截图命令模板

```powershell
& 'I:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --path . --script res://tests/capture_runtime_scene.gd -- --scene-name=<scene> --output=<png> --settle-frames=30
```

## 已采集场景

| 场景 | 母版文件 | 状态 |
|---|---|---|
| start | `04_source_masters/00_start.png` | 成功 |
| main | `04_source_masters/01_main_lobby.png` | 成功 |
| stage_select | `04_source_masters/02_stage_select.png` | 成功，有缺失资源警告 |
| battle_prepare | `04_source_masters/03_battle_prepare.png` | 成功 |
| battle | `04_source_masters/04_battle.png` | 成功 |
| team | `04_source_masters/05_team.png` | 成功 |
| album | `04_source_masters/06_album.png` | 成功 |
| ranch | `04_source_masters/07_ranch_classroom.png` | 成功 |
| shop | `04_source_masters/08_shop.png` | 成功，有缺失资源警告 |
| result | `04_source_masters/09_result.png` | 成功 |

## 已知警告

Godot 输出中出现缺失资源引用：

- `res://assets/images/ui/panels/stage_ui_reward_panel_clean.png`
- `res://assets/images/ui/icons/battle_flow_new_icon_exp_badge.png`
- `res://assets/images/maps/nodes/stage_selection_ring_pink.png`
- `res://assets/images/monsters/monster/monster_002_water_cub.png`

这些警告未阻止截图保存，也未在本次导出图中表现为错误弹窗；但它们是正式构建前应处理的资源完整性风险。

## 交付前验证

- 资料包关键文件检查：通过，必需目录、文案、图片和追溯文件均已生成。
- JSON 解析检查：通过，`game_metadata.json`、`submission_spec.json`、`basic_info.json`、`version_metadata.json`、`capture_manifest.json`、`image_inventory.generated.json`、`quality_metrics.generated.json` 均可解析。
- 图片规格检查：通过，核心截图为 1080×1920 JPG，分享图为 1000×800 JPG，头像源图为 1024×1024 PNG。
- 正式场景资源检查：未通过。`tools/check_formal_scene_resources.ps1` 报告 `src/ui/scenes/shop.tscn:23` 缺失 `res://assets/images/monsters/monster/monster_002_water_cub.png`。
- P0 冒烟测试：未通过。测试流程在资源完整性检查阶段停止，未进入完整交互路径验证。

P0 冒烟测试报告的缺失资源列表：

- `src/ui/scenes/shop.tscn:23` 缺失 `res://assets/images/monsters/monster/monster_002_water_cub.png`
- `src/ui/scenes/stage_map_boss_node.tscn:4` 缺失 `res://assets/images/monsters/boss/boss_flower.png`
- `src/ui/scenes/stage_select_map.tscn:7` 缺失 `res://assets/images/ui/panels/stage_ui_reward_panel_clean.png`
- `src/ui/scenes/stage_select_map.tscn:10` 缺失 `res://assets/images/ui/icons/battle_flow_new_icon_exp_badge.png`
- `src/ui/scenes/stage_select/chapter_maps/chapter_01_breeze_plain.tscn:6` 缺失 `res://assets/images/maps/nodes/stage_selection_ring_pink.png`
- `src/ui/scenes/stage_select/chapter_maps/chapter_09_starlit_temple.tscn:7` 缺失 `res://assets/images/monsters/boss/boss_star_dragon.png`
- `src/ui/scenes/stage_select/chapter_maps/chapter_10_chaos_domain.tscn:4` 缺失 `res://assets/images/maps/backgrounds/stage_map_bg_chaos.png`
- `src/ui/scenes/stage_select/chapter_maps/chapter_10_chaos_domain.tscn:13` 缺失 `res://assets/images/monsters/boss/monster_boss_010_chaos.png`
- `src/ui/scenes/stage_select/chapter_maps/chapter_11_radiant_temple.tscn:4` 缺失 `res://assets/images/maps/backgrounds/stage_map_bg_light.png`
- `src/ui/scenes/stage_select/chapter_maps/chapter_11_radiant_temple.tscn:13` 缺失 `res://assets/images/monsters/boss/monster_boss_011_light.png`

结论：素材包已可用于后台字段核对与人工确认；正式提审前建议先修复上述资源缺失，并在微信开发者工具或目标导出环境中重新跑审核路径。

## 工作区状态备注

生成前工作区已有未提交修改与删除项。本次操作新增 `release/wechat-mini-game/` 资料包，没有回滚或覆盖用户已有改动。
