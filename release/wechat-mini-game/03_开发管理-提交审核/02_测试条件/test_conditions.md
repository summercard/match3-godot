# 测试条件

| 项目 | 当前结论 | 说明 |
|---|---|---|
| 测试账号 | 未提供 | 当前工程未检测到登录/账号系统；不得编造测试账号。 |
| 验证码 | 不适用 | 未检测到短信、邮箱或微信登录验证码流程。 |
| 网络条件 | 当前本地运行不依赖网络 | 未检测到外链、HTTP 请求或在线服务入口；正式微信端需再次确认。 |
| 支付 | 未检测到真实支付 | 项目有游戏内商店和金币/宝石消耗，但未检测到微信支付/IAP SDK。 |
| 广告 | 未检测到 | 未检测到激励视频、插屏或 banner 广告 SDK/入口。 |
| 关卡前置 | 第一关可作为审核入口 | 路径建议从启动页进入主大厅，再进入章节和战斗。 |
| 存档 | 本次采集使用隔离测试存档 | 环境变量 `MATCH3_SAVE_PATH=release/wechat-mini-game/90_交付报告与追溯/capture_save.cfg`。 |
| 设备方向 | 竖屏 | `project.godot` 和实际采集为竖屏；微信端导出设置需人工确认。 |

## 本次运行命令

```powershell
& 'I:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --path . --script res://tests/capture_runtime_scene.gd -- --scene-name=<scene> --output=<png> --settle-frames=30
```

Godot 版本：4.6.3.stable.official.7d41c59c4。

## 已知运行警告

截图采集时，关卡地图和商店场景报告了缺失资源引用：

- `res://assets/images/ui/panels/stage_ui_reward_panel_clean.png`
- `res://assets/images/ui/icons/battle_flow_new_icon_exp_badge.png`
- `res://assets/images/maps/nodes/stage_selection_ring_pink.png`
- `res://assets/images/monsters/monster/monster_002_water_cub.png`

截图仍成功保存且未出现错误弹窗，但这些资源警告应在正式构建/提审前修复或确认。
