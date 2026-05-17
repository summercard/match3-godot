# Godot界面美术包装状态对照表

更新时间：2026-05-17

## 总览

- Godot 运行入口登记界面：16 个。
- 已完成第一版美术代入：5 个。
- 有概念图但尚未完成 Godot 代入：11 个，其中队伍编成和怪物进化共用一张概念图。
- 暂无独立概念图：0 个。
- 完整执行清单见：`美术开发/界面美术资产提取制作代入总List.md`。

## 状态表

| 序号 | Godot 场景 | 功能模块 | 脚本入口 | 运行时资产接入状态 | 概念图状态 | 拆分/资产状态 | 下一步 |
|---:|---|---|---|---|---|---|---|
| 1 | start | 启动欢迎页 | `src/ui/scene/scene_start.gd` | 已完成第一版包装 | 有：`美术开发/概念图/01_启动欢迎页_start_screen.png` | 已拆分，已导入 `assets/images/start/` | 后续只做精修和动效 |
| 2 | main | 大厅/主界面 | `src/ui/scene/scene_main.gd` | 已完成第一版包装 | 有：`美术开发/概念图/02_主界面_main_lobby.png` | 已拆分，已导入 `assets/images/main/` | 精修队伍展示条、活动入口 |
| 3 | stage_select | 关卡选择/章节地图 | `src/ui/scene/scene_stage_select.gd` | 已完成第一版包装 | 有：`美术开发/概念图/03_关卡地图_stage_select.png` | 已拆分，已导入 `assets/images/stage/` | 精修多章节地图和 Boss 表现 |
| 4 | battle | 三消战斗 | `src/ui/scene/scene_battle.gd` | 已完成核心资产代入，局部仍为色块/emoji | 有：`美术开发/概念图/04_三消战斗_battle_match3.png` | 怪物、宝石、障碍、背景已拆分并导入 `assets/images/battle/` | 补状态图标、技能特效、完整 UI 面板 |
| 5 | album | 怪物图鉴 | `src/ui/scene/scene_album.gd` | 未包装，仍以 Godot 控件/emoji 为主 | 有：`美术开发/概念图/05_怪物图鉴_monster_album.png` | 有概念拆分草稿：`美术开发/资产拆分/05_monster_album_contact_sheet.png` | 可进入专业拆分并代入 |
| 6 | team | 队伍编成 | `src/ui/scene/scene_team.gd` | 未包装，仍以控件样式/emoji 为主 | 有：`美术开发/概念图/06_队伍进化_team_evolve.png` | 有概念拆分草稿：`美术开发/legacy_concept_crops/资产拆分/06_team_evolve/` | 可进入专业拆分并代入 |
| 7 | evolve | 怪物进化 | `src/ui/scene/scene_evolve.gd` | 未包装，仍以控件样式/emoji 为主 | 共用：`美术开发/概念图/06_队伍进化_team_evolve.png` | 有概念拆分草稿，可复用队伍/怪物资产 | 队伍完成后接着做进化 |
| 8 | battle_prepare | 战斗准备 | `src/ui/scene/scene_battle_prepare.gd` | 已完成第一版 image-2 UI 代入，怪物/宝石复用通用资产 | 有：`美术开发/概念图/07_战斗准备_battle_prepare.png` | 已拆分：`美术开发/正式拆分/battle_prepare/`；运行目录：`assets/images/battle_prepare/` | 进入 Godot 运行窗口做视觉验收和布局微调 |
| 9 | result | 战斗结算 | `src/ui/scene/scene_result.gd` | 已完成第一版 image-2 UI/星级/特效代入，怪物/奖励图标复用通用资产 | 有：`美术开发/概念图/08_战斗结算_result.png` | 已拆分：`美术开发/正式拆分/result/`；运行目录：`assets/images/result/` | 进入 Godot 运行窗口做真实胜负结算视觉验收 |
| 10 | ranch | 牧场 | `src/ui/scene/scene_ranch.gd` | 未包装 | 有：`美术开发/概念图/09_怪物牧场_ranch.png` | 待专业拆分，可复用怪物小头像 | 拆分牧场背景、放置槽、收益状态 |
| 11 | shop | 商店 | `src/ui/scene/scene_shop.gd` | 仅接入金币/钻石小图标，主体未包装 | 有：`美术开发/概念图/10_商店_shop.png` | 待专业拆分，可复用货币/按钮/道具 | 与背包一起建立商品/道具体系 |
| 12 | inventory | 背包 | `src/ui/scene/scene_inventory.gd` | 未包装 | 有：`美术开发/概念图/11_背包_inventory.png` | 待专业拆分，需要道具图标体系 | 拆分背包格、分类标签、详情面板 |
| 13 | achievement | 成就 | `src/ui/scene/scene_achievement.gd` | 未包装 | 有：`美术开发/概念图/12_成就_achievement.png` | 待专业拆分，可复用徽章/奖励资产 | 拆分成就卡、进度条、徽章、领取状态 |
| 14 | settings | 设置 | `src/ui/scene/scene_settings.gd` | 未包装 | 有：`美术开发/概念图/13_设置_settings.png` | 待专业拆分，可复用通用 UI | 低优先级，后置包装 |
| 15 | sign_in | 每日签到 | `src/ui/scene/scene_sign_in.gd` | 未包装 | 有：`美术开发/概念图/14_每日签到_sign_in.png` | 待专业拆分，可复用奖励资产 | 拆分签到日历、今日高亮、领取状态 |
| 16 | tutorial | 新手教程 | `src/ui/scene/scene_tutorial.gd` | 未包装 | 有：`美术开发/概念图/15_新手教程_tutorial.png` | 待专业拆分，依赖主流程资产 | 主流程稳定后拆分引导资产 |

## 按状态归类

### 已完成第一版美术代入

1. 启动欢迎页 start
2. 大厅 main
3. 关卡选择 stage_select
4. 三消战斗 battle
5. 战斗结算 result

### 有概念图，可继续专业拆分/代入

1. 怪物图鉴 album
2. 队伍编成 team
3. 怪物进化 evolve
4. 战斗准备 battle_prepare
5. 牧场 ranch
6. 商店 shop
7. 背包 inventory
8. 成就 achievement
9. 设置 settings
10. 每日签到 sign_in
11. 新手教程 tutorial

### 暂无独立概念图

无。当前 16 个 Godot 界面均已有概念图覆盖，其中 team 和 evolve 共用 `06_队伍进化_team_evolve.png`。

## 建议优先级

| 优先级 | 模块 | 原因 |
|---|---|---|
| P0 | 战斗准备 | 主流程从关卡进入战斗的中间页，且可复用 battle/team 资产，成本低 |
| P0 | 战斗结算 | 战斗闭环反馈页，影响胜负、奖励、成长的完成感 |
| P1 | 队伍编成 | 已有概念图，且是怪物养成核心页 |
| P1 | 怪物图鉴 | 已有概念图，可与队伍共用怪物卡和属性标签 |
| P1 | 怪物进化 | 与队伍共用概念图，但需要更多特效资产 |
| P2 | 背包/商店 | 需要先建立道具图标体系，两个界面可成套做 |
| P2 | 签到/成就 | 共享奖励、徽章、进度条资产 |
| P3 | 牧场 | 需要新增场景概念，但可复用怪物小头像 |
| P4 | 设置/教程 | 设置低频；教程依赖主流程界面稳定 |
