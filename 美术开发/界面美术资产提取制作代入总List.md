# 界面美术资产提取制作代入总List

更新时间：2026-05-17

本表用于统一管理每个 Godot 界面的美术流程：概念图 -> image-2 元素提取 -> 专业资产制作 -> 导入 `assets/images` -> Godot 场景代入 -> 视觉验收。

## 阶段定义

| 阶段 | 状态 | 说明 |
|---:|---|---|
| 0 | 概念图 | 已有界面效果图，可作为风格和布局依据 |
| 1 | 元素提取 | 按怪物、宝石、UI、道具、特效、背景进行 image-2 提取或重绘 |
| 2 | 正式资产 | 透明 PNG、九宫格 UI、状态变体、尺寸变体制作完成 |
| 3 | 导入工程 | 资产复制到 `assets/images/<module>/` 并由 Godot 生成 `.import` |
| 4 | 代码代入 | 对应 `scene_*.gd` 已加载并绘制正式资产 |
| 5 | 视觉验收 | 在 Godot 运行画面中检查完成度、遮挡、适配、交互状态 |

## 总清单

| 优先级 | 界面 | Godot 入口 | 概念图 | 当前阶段 | 提取/制作分类 | 正式资产目录 | 运行目录 | 代入状态 | 下一步 |
|---|---|---|---|---|---|---|---|---|---|
| P0 | 启动欢迎页 | `src/ui/scene/scene_start.gd` | `美术开发/概念图/01_启动欢迎页_start_screen.png` | 5 视觉验收 | 背景、怪物、宝石、Logo、按钮、底栏 UI | `美术开发/正式拆分/start_screen/` | `assets/images/start/` | 已完成第一版代入 | 后续补按钮动效、标题光效、怪物轻动画 |
| P0 | 大厅/主界面 | `src/ui/scene/scene_main.gd` | `美术开发/概念图/02_主界面_main_lobby.png` | 5 视觉验收 | 背景、玩家面板、货币、主入口卡、底部导航、功能图标 | `美术开发/正式拆分/main_lobby/` | `assets/images/main/` | 已完成第一版代入 | 精修当前队伍展示条、活动入口、按钮按下状态 |
| P0 | 关卡选择 | `src/ui/scene/scene_stage_select.gd` | `美术开发/概念图/03_关卡地图_stage_select.png` | 5 视觉验收 | 地图背景、章节栏、节点、Boss、宝箱、星级、奖励栏 | `美术开发/正式拆分/stage_select/` | `assets/images/stage/` | 已完成第一版代入 | 补多章节地图、节点状态、Boss 动态表现 |
| P0 | 三消战斗 | `src/ui/scene/scene_battle.gd` | `美术开发/概念图/04_三消战斗_battle_match3.png` | 4 代码代入 | 怪物、宝石、障碍、战斗背景、HP 条、战斗面板、状态/技能特效 | `美术开发/正式拆分/battle_screen/`, `美术开发/正式拆分/gems/`, `美术开发/正式拆分/monsters/`, `美术开发/正式拆分/ui/` | `assets/images/battle/` | 核心资产已代入，局部仍需精修 | 补状态图标、技能按钮、连击特效、完整战斗 UI 面板 |
| P0 | 战斗准备 | `src/ui/scene/scene_battle_prepare.gd` | `美术开发/概念图/07_战斗准备_battle_prepare.png` | 4 代码代入 | 怪物头像、属性宝石、阵容卡、战力对比、奖励预览、开始按钮 | `美术开发/正式拆分/battle_prepare/` | `assets/images/battle_prepare/` | 已按 image-2 提取 UI 代入；怪物/宝石复用通用资产 | 进入 Godot 运行窗口做视觉验收和布局微调 |
| P0 | 战斗结算 | `src/ui/scene/scene_result.gd` | `美术开发/概念图/08_战斗结算_result.png` | 4 代码代入 | 胜负横幅、星级、奖励槽、怪物展示、经验条、按钮、庆祝特效 | `美术开发/正式拆分/result/` | `assets/images/result/` | 已按 image-2 提取 UI/星级/特效代入；怪物/奖励图标复用通用资产 | 进入 Godot 运行窗口做真实胜负结算视觉验收 |
| P1 | 队伍编成 | `src/ui/scene/scene_team.gd` | `美术开发/概念图/06_队伍进化_team_evolve.png` | 1 元素提取草稿 | 怪物卡、队伍槽、属性标签、战力条、队长技、保存按钮 | `美术开发/资产拆分/06_team_evolve/` -> `美术开发/正式拆分/team/` | `assets/images/team/` | 未代入 | 用已有拆分草稿转专业透明资产，替换控件样式和 emoji |
| P1 | 怪物图鉴 | `src/ui/scene/scene_album.gd` | `美术开发/概念图/05_怪物图鉴_monster_album.png` | 1 元素提取草稿 | 怪物卡、锁定态、属性筛选、详情面板、数值条、进化入口 | `美术开发/资产拆分/05_monster_album/` -> `美术开发/正式拆分/album/` | `assets/images/album/` | 未代入 | 与队伍共用怪物卡规范，先接列表和详情面板 |
| P1 | 怪物进化 | `src/ui/scene/scene_evolve.gd` | `美术开发/概念图/06_队伍进化_team_evolve.png` | 1 元素提取草稿 | 进化舞台、前后怪物、箭头、材料槽、进化按钮、光效 | `美术开发/资产拆分/06_team_evolve/` -> `美术开发/正式拆分/evolve/` | `assets/images/evolve/` | 未代入 | 队伍资产稳定后提取进化专用舞台和特效 |
| P2 | 背包 | `src/ui/scene/scene_inventory.gd` | `美术开发/概念图/11_背包_inventory.png` | 0 概念图 | 道具图标、背包格、分类标签、详情弹窗、数量角标、使用按钮 | `美术开发/资产拆分/11_inventory/` -> `美术开发/正式拆分/inventory/` | `assets/images/inventory/` | 未代入 | 先建立道具图标体系，再接入格子和详情弹窗 |
| P2 | 商店 | `src/ui/scene/scene_shop.gd` | `美术开发/概念图/10_商店_shop.png` | 0 概念图 | 商品卡、价格胶囊、货币、购买按钮、礼包、确认弹窗 | `美术开发/资产拆分/10_shop/` -> `美术开发/正式拆分/shop/` | `assets/images/shop/` | 仅金币/钻石小图标已接入 | 与背包共用道具图标，先制作商品卡和购买弹窗 |
| P2 | 每日签到 | `src/ui/scene/scene_sign_in.gd` | `美术开发/概念图/14_每日签到_sign_in.png` | 0 概念图 | 日历格、今日高亮、已领印章、奖励图标、宝箱、领取按钮 | `美术开发/资产拆分/14_sign_in/` -> `美术开发/正式拆分/sign_in/` | `assets/images/sign_in/` | 未代入 | 复用奖励图标，优先完成 7 日格和领取按钮 |
| P2 | 成就 | `src/ui/scene/scene_achievement.gd` | `美术开发/概念图/12_成就_achievement.png` | 0 概念图 | 成就徽章、成就卡、进度条、奖励槽、领取按钮、完成印章 | `美术开发/资产拆分/12_achievement/` -> `美术开发/正式拆分/achievement/` | `assets/images/achievement/` | 未代入 | 与签到共享奖励/徽章体系，先接列表卡和进度条 |
| P3 | 怪物牧场 | `src/ui/scene/scene_ranch.gd` | `美术开发/概念图/09_怪物牧场_ranch.png` | 0 概念图 | 牧场背景、放置槽、怪物小头像、收益图标、进度条、收获按钮 | `美术开发/资产拆分/09_ranch/` -> `美术开发/正式拆分/ranch/` | `assets/images/ranch/` | 未代入 | 提取牧场背景和放置槽，复用怪物头像 |
| P4 | 设置 | `src/ui/scene/scene_settings.gd` | `美术开发/概念图/13_设置_settings.png` | 0 概念图 | 设置面板、开关、滑杆、下拉、危险按钮、确认弹窗 | `美术开发/资产拆分/13_settings/` -> `美术开发/正式拆分/settings/` | `assets/images/settings/` | 未代入 | 建通用设置 UI 包，最后代入 |
| P4 | 新手教程 | `src/ui/scene/scene_tutorial.gd` | `美术开发/概念图/15_新手教程_tutorial.png` | 0 概念图 | 遮罩、高亮框、手势、箭头、引导头像、提示气泡、步骤按钮 | `美术开发/资产拆分/15_tutorial/` -> `美术开发/正式拆分/tutorial/` | `assets/images/tutorial/` | 未代入 | 主流程 UI 稳定后，拆引导层通用资产 |

## 推荐执行顺序

| 顺序 | 界面 | 本轮目标 | 原因 |
|---:|---|---|---|
| 1 | 战斗准备 | 完成提取、正式资产、运行目录、Godot 代入 | 主流程缺口，且能复用战斗怪物和 UI 包 |
| 2 | 战斗结算 | 完成胜负、星级、奖励、按钮代入 | 形成完整战斗闭环 |
| 3 | 队伍编成 | 完成怪物卡、队伍槽、战力栏代入 | 养成核心，复用图鉴/进化资产 |
| 4 | 怪物图鉴 | 完成列表卡、详情面板、锁定态代入 | 与队伍共享怪物卡体系 |
| 5 | 怪物进化 | 完成进化舞台、材料槽、按钮、光效 | 依赖队伍/怪物体系稳定 |
| 6 | 背包 + 商店 | 建立道具图标体系并代入两个界面 | 两个界面共享道具、货币、商品卡 |
| 7 | 签到 + 成就 | 建立奖励、徽章、进度条体系 | 两个界面共享奖励表现 |
| 8 | 牧场 | 代入放置槽、收益、怪物头像 | 养成外循环，依赖怪物头像 |
| 9 | 设置 + 教程 | 代入低频设置和通用引导层 | 设置低频；教程依赖主流程界面稳定 |

## 每个界面交付标准

1. `美术开发/元素提取/<module>/` 保存 image-2 提取源和中间图。
2. `美术开发/资产拆分/<module>/` 保存概念拆分参考和 contact sheet。
3. `美术开发/正式拆分/<module>/` 保存透明正式 PNG、状态变体和尺寸变体。
4. `assets/images/<module>/` 保存 Godot 实际运行资源。
5. 对应 `scene_*.gd` 只引用 `assets/images/<module>/` 或通用目录。
6. 更新单界面资产代入表，记录资产名、用途、运行路径、代码位置。
7. Godot 启动检查通过，并在界面里确认无明显遮挡、错位、缺图。
