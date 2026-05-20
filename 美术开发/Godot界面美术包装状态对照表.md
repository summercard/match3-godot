# Godot界面美术包装状态对照表

更新时间：2026-05-19

## 总览

- Godot 运行入口登记界面：16 个。
- 已完成第一版美术代入：11 个。
- 有概念图但尚未完成 Godot 代入：5 个，其中队伍编成和怪物进化共用一张概念图。
- 暂无独立概念图：0 个。
- 完整执行清单见：`美术开发/界面美术资产提取制作代入总List.md`。

## 状态表

| 序号 | Godot 场景 | 功能模块 | 脚本入口 | 运行时资产接入状态 | 概念图状态 | 拆分/资产状态 | 下一步 |
|---:|---|---|---|---|---|---|---|
| 1 | start | 启动欢迎页 | `src/ui/scene/scene_start.gd` | 已完成第一版包装 | 有：`美术开发/概念图/01_启动欢迎页_start_screen.png` | 已拆分，已导入 `assets/images/start/` | 后续只做精修和动效 |
| 2 | main | 大厅/主界面 | `src/ui/scene/scene_main.gd` | 已按新大厅概念图重制 V2；背景、头像框、货币条、段位面板、4 个建筑入口、底部 5 导航和红点提示已改为 Canvas 绘制资产；加入等比图标、固定 Rect、文字截断和点击区同源约束 | 新概念图：`美术开发/概念图/大厅.png`；旧概念图：`美术开发/概念图/02_主界面_main_lobby.png` | 已拆分：`美术开发/正式拆分/main_lobby_v2/`；运行目录：`assets/images/main/` | 进入 Godot 运行窗口对照新概念图做视觉验收 |
| 3 | stage_select | 关卡选择/章节地图 | `src/ui/scene/scene_stage_select.gd` | 已完成第一版包装 | 有：`美术开发/概念图/03_关卡地图_stage_select.png` | 已拆分，已导入 `assets/images/stage/` | 精修多章节地图和 Boss 表现 |
| 4 | battle | 三消战斗 | `src/ui/scene/scene_battle.gd` | 已完成核心资产代入，局部仍为色块/emoji | 有：`美术开发/概念图/04_三消战斗_battle_match3.png` | 怪物、宝石、障碍、背景已拆分并导入 `assets/images/battle/` | 补状态图标、技能特效、完整 UI 面板 |
| 5 | album | 怪物图鉴 | `src/ui/scene/scene_album.gd` | 已完成第一版 image-2 UI/属性图标代入；列表、筛选、详情、锁定态、进化入口已改为 Canvas 绘制资产 | 有：`美术开发/概念图/05_怪物图鉴_monster_album.png` | 已拆分：`美术开发/正式拆分/album/`；运行目录：`assets/images/album/` | 进入 Godot 运行窗口做真实图鉴视觉验收 |
| 6 | team | 队伍编成 | `src/ui/scene/scene_team.gd` | 已完成第一版 image-2 UI/图标代入，怪物头像复用/补入通用怪物目录 | 有：`美术开发/概念图/06_队伍进化_team_evolve.png` | 已拆分：`美术开发/正式拆分/team/`；运行目录：`assets/images/team/` | 进入 Godot 运行窗口做真实队伍编成视觉验收 |
| 7 | evolve | 怪物进化 | `src/ui/scene/scene_evolve.gd` | 未包装，仍以控件样式/emoji 为主 | 共用：`美术开发/概念图/06_队伍进化_team_evolve.png` | 有概念拆分草稿，可复用队伍/怪物资产 | 队伍完成后接着做进化 |
| 8 | battle_prepare | 战斗准备 | `src/ui/scene/scene_battle_prepare.gd` | 已完成第一版 image-2 UI 代入，怪物/宝石复用通用资产；已修正顶栏/开始按钮重复叠图、图标拉伸、卡片描边和纵向排布 | 有：`美术开发/概念图/07_战斗准备_battle_prepare.png` | 已拆分：`美术开发/正式拆分/battle_prepare/`；运行目录：`assets/images/battle_prepare/` | 进入 Godot 运行窗口做视觉验收和布局微调 |
| 9 | result | 战斗结算 | `src/ui/scene/scene_result.gd`, `src/ui/scene/scene_battle.gd` | 已完成完整结算页和战斗内胜负过场 image-2 拆分、运行目录导入、代码代入；过场动画已改为独立计时并加跳转锁 | 有：`美术开发/概念图/08_战斗结算_result.png`；过场源：`美术开发/元素提取/battle_result_overlay/battle_result_overlay_ui_effects_image2_sheet.png` | 已拆分：`美术开发/正式拆分/result/`, `美术开发/正式拆分/battle_result_overlay/`；运行目录：`assets/images/result/`, `assets/images/battle/result_overlay/` | 进入 Godot 运行窗口做真实胜负流程视觉验收 |
| 10 | ranch | 牧场 | `src/ui/scene/scene_ranch.gd` | 已按概念图完成第一版 image-2 牧场背景/UI 代入；5 个放置台、收益面板、怪物列表均改为 Canvas 绘制资产 | 有：`美术开发/概念图/09_怪物牧场_ranch.png` | 已拆分：`美术开发/正式拆分/ranch/`；运行目录：`assets/images/ranch/` | 进入 Godot 运行窗口做概念图对照微调 |
| 11 | shop | 商店 | `src/ui/scene/scene_shop.gd` | 已基于概念图用 image-2 生成 UI/背景/魔法师、道具、宝石提取源；分页、四列商品卡、礼包横幅、购买确认弹窗已改为 Canvas 绘制资产 | 有：`美术开发/概念图/10_商店_shop.png` | 已拆分：`美术开发/正式拆分/shop/`；运行目录：`assets/images/shop/` | 进入 Godot 运行窗口做真实购买流程和滚动视觉验收 |
| 12 | inventory | 背包 | `src/ui/scene/scene_inventory.gd` | 已基于概念图用 image-2 生成背包 UI 提取源；顶部栏、四分类、5 列道具格、选中/锁定态、滚动条、底部详情面板和使用按钮已改为 Canvas 绘制资产 | 有：`美术开发/概念图/11_背包_inventory.png` | 已拆分：`美术开发/正式拆分/inventory/`；运行目录：`assets/images/inventory/`；道具/进化石通用目录：`assets/images/items/` | 进入 Godot 运行窗口做真实背包视觉验收 |
| 13 | achievement | 成就 | `src/ui/scene/scene_achievement.gd` | 已基于概念图用 image-2 生成成就 UI/徽章提取源；奖杯总览、五分类标签、成就卡、徽章、奖励槽、进度条、领取/已完成/锁定态已改为 Canvas 绘制资产，并加入等比图标、固定坐标、文字宽度和点击区一致性约束 | 有：`美术开发/概念图/12_成就_achievement.png` | 已拆分：`美术开发/正式拆分/achievement/`；运行目录：`assets/images/achievement/`；金币复用 `assets/images/main/`；奖励槽复用 `assets/images/inventory/` | 进入 Godot 运行窗口做真实成就视觉验收 |
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
6. 队伍编成 team
7. 怪物图鉴 album
8. 怪物牧场 ranch
9. 商店 shop
10. 背包 inventory
11. 成就 achievement

### 有概念图，可继续专业拆分/代入

1. 怪物进化 evolve
2. 战斗准备 battle_prepare
3. 设置 settings
4. 每日签到 sign_in
5. 新手教程 tutorial

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
