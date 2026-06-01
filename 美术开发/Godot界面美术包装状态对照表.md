# Godot界面美术包装状态对照表

更新时间：2026-05-26

## 总览

- Godot 运行入口登记界面：16 个。
- 已完成第一版美术代入：14 个。
- 有概念图但尚未完成 Godot 代入：2 个，其中怪物进化与队伍编成共用一张概念图。
- 暂无独立概念图：0 个。
- 完整执行清单见：`美术开发/界面美术资产提取制作代入总List.md`。

## 状态表

| 序号 | Godot 场景 | 功能模块 | 脚本入口 | 运行时资产接入状态 | 概念图状态 | 拆分/资产状态 | 下一步 |
|---:|---|---|---|---|---|---|---|
| 1 | start | 启动欢迎页 | `src/ui/scenes/start_screen.tscn` + `src/ui/scene/scene_start.gd` | 2026-05-31 已替换为明亮童话 Q 版萌宠新风格；纯背景、Logo、火水草萌宠和进入游戏按钮均为独立节点；保留按下即进入和教程分流 | 有：`美术开发/新美术风格/ChatGPT Image 2026年5月31日 22_12_10.png` | 已用 image-2 独立重绘并透明拆分，导入 `assets/images/start/`；概念整图不参与运行 | 后续按同一风格推进大厅和战斗页 |
| 2 | main | 大厅/主界面 | `src/ui/scenes/main_lobby.tscn`, `src/ui/scene/scene_main.gd` | 已按新大厅概念图重制 V2；背景、头像框、货币条、段位面板、4 个建筑入口、底部 5 导航和红点提示均已迁移为可编辑 Godot 2D 节点；脚本仅保留数值刷新、粒子和跳转；已修正经验条纹理撑宽与冒险入口按下响应 | 新概念图：`美术开发/概念图/大厅.png`；旧概念图：`美术开发/概念图/02_主界面_main_lobby.png` | 已拆分：`美术开发/正式拆分/main_lobby_v2/`；运行目录：`assets/images/main/`；旧版备份：`美术开发/备份/main_lobby_tscn_2026-05-25/` | 编辑器内可继续精调节点尺寸与替换资产 |
| 3 | stage_select | 关卡选择/章节地图 | `src/ui/scenes/stage_select_map.tscn` + `src/ui/scenes/stage_select/chapter_maps/*.tscn` + `src/ui/scene/scene_stage_select_gui.gd` | 已迁移为可编辑 Godot GUI 场景；主场景复用顶部栏、章节切换按钮、奖励栏和扫荡弹层；11 个大章地图拆为独立 `.tscn`，每章内有 `Background`、`PathDecorations`、`StageNodes`、`BossStage` 可单独手调；第八/九章主题台座继续生效，锁态不再退回通用台子 | 有：`美术开发/概念图/03_关卡地图_stage_select.png`；章节扩展概念已补到第九章 | 已拆分并导入 `assets/images/stage/`；GUI 验收：`美术开发/验收/stage_select/chapter_09_starlit_temple_gui_runtime.png` | 在编辑器内打开对应章节 `.tscn` 继续微调节点与 Boss 区位置 |
| 4 | battle | 三消战斗 | `src/ui/scenes/battle_screen.tscn` + `src/ui/scene/scene_battle_gui.gd` + `src/ui/scene/scene_battle.gd` | 2026-06-01 已迁移为可编辑 Godot GUI 混合场景：背景、顶部 HUD、敌我精灵槽、血条、底部捕捉开关和道具槽均为节点；棋盘与瞬态特效保留代码绘制 | 有：用户提供的 2026-06-01 战局内新风格概念图；旧概念：`美术开发/概念图/04_三消战斗_battle_match3.png` | image-2 独立重绘资产已导入 `assets/images/battle/`；GUI 验收：`美术开发/验收/battle/battle_runtime_editable_ui_v1.png`, `battle_runtime_editable_ui_v1_multi3.png`, `battle_runtime_editable_ui_v1_fx.png` | 后续在编辑器调整静态 UI；棋盘与战斗特效继续由代码层维护 |
| 5 | album | 怪物图鉴 | `src/ui/scenes/album.tscn` + `src/ui/scene/scene_album_gui.gd` | 已迁移为可编辑 Godot GUI 场景；列表取消滑动，改为 6 张卡/页的翻页结构；属性筛选、图鉴卡、详情面板、进化入口、羁绊页、目标页和底部页签均为节点并保留功能绑定 | 有：`美术开发/概念图/05_怪物图鉴_monster_album.png` | 已拆分：`美术开发/正式拆分/album/`；运行目录：`assets/images/album/`；GUI 验收：`美术开发/验收/album/album_gui_paged_runtime.png` | 编辑器内可继续微调卡片、筛选与详情面板位置 |
| 6 | team | 队伍编成 | `src/ui/scene/scene_team.gd`, `src/core/scene_manager.gd` | 已完成移动端成品精修：三槽/列表/操作字号和触控区重排，说明/筛选/排序交互闭环，撤下无效分解入口；已修复首次进入全黑慢转场并降低静态重绘开销 | 有：`美术开发/概念图/06_队伍进化_team_evolve.png` | 已拆分：`美术开发/正式拆分/team/`；运行目录：`assets/images/team/`；验收：`美术开发/验收/team/2026-05-25-polish/team_final.png` | 已验收，后续只随玩法新增扩展操作 |
| 7 | evolve | 怪物进化 | `src/ui/scene/scene_evolve.gd` | 未包装，仍以控件样式/emoji 为主 | 共用：`美术开发/概念图/06_队伍进化_team_evolve.png` | 有概念拆分草稿，可复用队伍/怪物资产 | 队伍完成后接着做进化 |
| 8 | battle_prepare | 战斗准备 | `src/ui/scenes/battle_prepare.tscn` + `src/ui/scene/scene_battle_prepare_gui.gd` | 已迁移为可编辑 Godot GUI 场景；背景、顶部栏、敌方卡、战力对比、我方卡、机制提示、协同、奖励预览、开始按钮和空队伍弹窗均为节点；脚本只刷新数据和保留开始/返回功能 | 有：`美术开发/概念图/07_战斗准备_battle_prepare.png` | 已拆分：`美术开发/正式拆分/battle_prepare/`；运行目录：`assets/images/battle_prepare/`；GUI 验收：`美术开发/验收/battle_prepare/battle_prepare_gui_runtime.png` | GUI 迁移验收通过；后续可在编辑器继续微调卡片间距 |
| 9 | result | 战斗结算/捕捉结果 | `src/ui/scenes/battle_result.tscn` + `src/ui/scenes/capture_result_panel.tscn` + `src/ui/scene/scene_result_gui.gd` | 已迁移为可编辑 Godot GUI 场景；胜负横幅、星级、战斗信息、奖励、队伍经验、按钮均为节点；捕捉宠物结果拆成独立 `capture_result_panel.tscn` 可单独编辑，并保留下一关/返回/重试功能 | 有：`美术开发/概念图/08_战斗结算_result.png`；过场源：`美术开发/元素提取/battle_result_overlay/battle_result_overlay_ui_effects_image2_sheet.png` | 已拆分：`美术开发/正式拆分/result/`, `美术开发/正式拆分/battle_result_overlay/`；运行目录：`assets/images/result/`, `assets/images/battle/result_overlay/`；GUI 验收：`美术开发/验收/result/battle_result_capture_gui_runtime.png` | GUI 迁移验收通过；战斗内胜负过场仍沿用现有局内表现 |
| 10 | ranch | 牧场 | `src/ui/scenes/ranch_hub.tscn` + `src/ui/scene/scene_ranch_gui.gd` | 已完成手机端资产化与可编辑 GUI 迁移：三页均为场景树节点；复用背景原生五石台并校准精灵着台；主页名单复用课堂/社交木框且移除旧标题与独立收益底板；收获、培养、进化与社交功能已重新绑定节点按钮 | 有：`美术开发/概念图/09_怪物牧场_ranch.png` | 精修源：`美术开发/元素提取/ranch/ui_polish_v2/`；正式拆分：`美术开发/正式拆分/ranch/`；运行目录：`assets/images/ranch/`；GUI 验收：`美术开发/验收/ranch/2026-05-26-gui/ranch_gui_main.png` | GUI 场景迁移终验通过；金币若需成为实际收益，再补结算规则 |
| 11 | shop | 商店 | `src/ui/scenes/shop.tscn` + `src/ui/scene/scene_shop_gui.gd` | 已迁移为可编辑 Godot GUI 场景；顶部货币、三分类、9 张商品卡/页、翻页按钮、底部栏、购买确认弹窗和 Toast 均为节点；新手超值礼包已隐藏并露出背景；商品卡去掉独立购买按钮，点击商品卡/图标即可进入购买确认；购买反馈已改为商人旁可编辑漫画对话框 | 有：`美术开发/概念图/10_商店_shop.png` | 已拆分：`美术开发/正式拆分/shop/`；运行目录：`assets/images/shop/`；通用道具：`assets/images/items/`；GUI 验收：`美术开发/验收/shop/shop_gui_runtime.png`, `美术开发/验收/shop/shop_gui_popup_runtime.png`, `美术开发/验收/shop/shop_gui_toast_runtime.png` | GUI 迁移验收通过；编辑器内可继续微调商品卡、弹窗与商人对话框节点 |
| 12 | inventory | 背包 | `src/ui/scenes/inventory.tscn` + `src/ui/scene/scene_inventory_gui.gd` | 已迁移为可编辑 Godot GUI 场景；旧滚动列表改为 15 格/页的翻页结构；顶部货币、四分类、物品格、详情面板、使用/装备按钮和 Toast 均为节点；已精修去除格内小字、旧滚动底纹和多余锁位 | 有：`美术开发/概念图/11_背包_inventory.png` | 已拆分：`美术开发/正式拆分/inventory/`；运行目录：`assets/images/inventory/`；道具/进化石通用目录：`assets/images/items/`；GUI 验收：`美术开发/验收/inventory/inventory_gui_paged_runtime.png` | 编辑器内可继续微调物品格间距与详情面板内容 |
| 13 | achievement | 成就 | `src/ui/scene/scene_achievement.gd` | 保持 Canvas 版本，不迁 GUI；已基于概念图完成成就 UI/徽章资产代入；本轮修复滚动列表越界覆盖顶部 UI，列表只绘制完整落在列表窗口内的卡片，顶部固定 UI 不再被遮挡 | 有：`美术开发/概念图/12_成就_achievement.png` | 已拆分：`美术开发/正式拆分/achievement/`；运行目录：`assets/images/achievement/`；金币复用 `assets/images/main/`；奖励槽复用 `assets/images/inventory/`；滚动验收：`美术开发/验收/achievement/achievement_scroll_clip_runtime.png` | Canvas 版本滚动遮挡验收通过；后续只做视觉细节精修 |
| 14 | settings | 设置 | `src/ui/scene/scene_settings.gd` | 已按“直接用已有元素拼起来”完成第一版包装；背景、返回、标题、面板、设置行、按钮、弹窗全部复用已有运行资产；保留音效/音乐/重置并新增震动、画质、战斗表现、恢复默认 | 有：`美术开发/概念图/13_设置_settings.png` | 不新增 settings 运行资产；详见 `美术开发/设置界面资产代入表.md` | 进入 Godot 运行窗口验收设置保存、弹窗、命中区和文字对齐 |
| 15 | sign_in | 每日签到 | `src/ui/scene/scene_sign_in.gd` | 已基于概念图完成 image-2 UI/奖励提取、正式拆分、运行目录导入和 Canvas 代码代入；7 日奖励卡、今日高亮、月累计宝箱、领取按钮和成功反馈已包装 | 有：`美术开发/概念图/14_每日签到_sign_in.png` | 已拆分：`美术开发/正式拆分/sign_in/`；运行目录：`assets/images/sign_in/` | 进入 Godot 运行窗口验收真实签到流程 |
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
8. 战斗准备 battle_prepare
9. 怪物牧场 ranch
10. 商店 shop
11. 背包 inventory
12. 成就 achievement
13. 每日签到 sign_in
14. 设置 settings

### 有概念图，可继续专业拆分/代入

1. 怪物进化 evolve
2. 新手教程 tutorial

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
