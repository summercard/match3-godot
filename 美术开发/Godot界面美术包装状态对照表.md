# Godot界面美术包装状态对照表

更新时间：2026-05-17

## 总览

- Godot 运行入口登记界面：16 个。
- 已完成第一版美术代入：4 个。
- 有概念图但尚未完成 Godot 代入：3 个，其中队伍编成和怪物进化共用一张概念图。
- 暂无独立概念图：9 个。

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
| 8 | battle_prepare | 战斗准备 | `src/ui/scene/scene_battle_prepare.gd` | 仅接入战斗背景，主体仍为色块/emoji | 无独立概念图 | 无独立拆分包，可复用 battle/team/ui | 需要补战前确认概念图或先用通用 UI 包制作 |
| 9 | result | 战斗结算 | `src/ui/scene/scene_result.gd` | 未包装 | 无独立概念图 | 无独立拆分包，可复用奖励/星级/按钮 | 需要制作胜负结算概念图 |
| 10 | ranch | 牧场 | `src/ui/scene/scene_ranch.gd` | 未包装 | 无独立概念图 | 无独立拆分包，可复用怪物小头像 | 需要制作牧场放置页概念图 |
| 11 | shop | 商店 | `src/ui/scene/scene_shop.gd` | 仅接入金币/钻石小图标，主体未包装 | 无独立概念图 | 无独立拆分包，可复用货币/按钮/道具 | 需要制作商店概念图或套用通用商店 UI |
| 12 | inventory | 背包 | `src/ui/scene/scene_inventory.gd` | 未包装 | 无独立概念图 | 无独立拆分包，需要道具图标体系 | 需要制作背包概念图和道具图标包 |
| 13 | achievement | 成就 | `src/ui/scene/scene_achievement.gd` | 未包装 | 无独立概念图 | 无独立拆分包，可复用徽章/奖励资产 | 需要制作成就列表概念图 |
| 14 | settings | 设置 | `src/ui/scene/scene_settings.gd` | 未包装 | 无独立概念图 | 无独立拆分包，可复用通用 UI | 低优先级，后置包装 |
| 15 | sign_in | 每日签到 | `src/ui/scene/scene_sign_in.gd` | 未包装 | 无独立概念图 | 无独立拆分包，可复用奖励资产 | 需要制作签到日历概念图 |
| 16 | tutorial | 新手教程 | `src/ui/scene/scene_tutorial.gd` | 未包装 | 无独立概念图 | 无独立拆分包，依赖主流程资产 | 主流程稳定后制作引导资产 |

## 按状态归类

### 已完成第一版美术代入

1. 启动欢迎页 start
2. 大厅 main
3. 关卡选择 stage_select
4. 三消战斗 battle

### 有概念图，可继续专业拆分/代入

1. 怪物图鉴 album
2. 队伍编成 team
3. 怪物进化 evolve

### 暂无独立概念图

1. 战斗准备 battle_prepare
2. 战斗结算 result
3. 牧场 ranch
4. 商店 shop
5. 背包 inventory
6. 成就 achievement
7. 设置 settings
8. 每日签到 sign_in
9. 新手教程 tutorial

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
