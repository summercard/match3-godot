# 界面美术资产提取制作代入总List

更新时间：2026-05-20

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
| P0 | 启动欢迎页 | `src/ui/scenes/start_screen.tscn` + `src/ui/scene/scene_start.gd` | 用户提供的 2026-06-01 村庄喷泉欢迎页概念图 | 5 视觉验收 | image-2 村庄喷泉纯背景、透明 Logo、透明水火草首屏萌宠、透明进入游戏按钮 | `美术开发/正式拆分/start_screen_new_style/` | `assets/images/start/` | 2026-06-01 已按新版概念图独立重绘村庄喷泉底图和水火草萌宠，透明拆分后按左水、中火、右草分层代入；概念整图不作为运行资产；保留按下即进入和教程分流 | 后续按同一风格推进大厅和战斗页 |
| P0 | 大厅/主界面 | `src/ui/scene/scene_main.gd` | `美术开发/概念图/大厅.png` | 5 待实机视觉验收 | 新大厅背景、头像框、玩家名牌、货币条、段位面板、4 个场景入口、底部 5 导航、红点提示 | `美术开发/元素提取/main_lobby_v2/`, `美术开发/正式拆分/main_lobby_v2/` | `assets/images/main/` | 已按新概念图用 image-2 重制背景和 UI 提取源；2026-05-20 已修正入口按钮压缩、红点重复叠加，并改为冒险入口按下即进入 | 进入 Godot 运行窗口对照新概念图验收按钮贴合、顶部大数字和红点位置 |
| P0 | 关卡选择 | `src/ui/scene/scene_stage_select.gd` | `美术开发/概念图/03_关卡地图_stage_select.png` | 5 视觉验收 | 地图背景、章节栏、节点、Boss、宝箱、星级、奖励栏 | `美术开发/正式拆分/stage_select/` | `assets/images/stage/` | 第一章/第二章已验收；第三章至第九章已补章节背景；第八章起补章节专属普通/精英/Boss 台座和大 Boss 区标准，第九章校准为明亮幻想冒险风格 | 继续补后续章节地图，并按新标准回填前章节点台子 |
| P0 | 三消战斗 | `src/ui/scenes/battle_screen.tscn` + `src/ui/scene/scene_battle_gui.gd` + `src/ui/scene/scene_battle.gd` | 用户提供的 2026-06-01 战局内新风格概念图 | 5 视觉验收 | 明亮花园竞技场背景、浅蓝沟边 8x8 棋盘托盘、独立回合/倍速/设置按钮、元素图标金边胶囊血条、粗描边休闲字体、独立捕捉开关与精灵球按钮、宝石 | `美术开发/正式拆分/battle_screen_new_style/`, `美术开发/正式拆分/monsters/` | `assets/images/battle/` | 2026-06-01 已按 image-2 独立重绘并代入；棋盘保持下置；敌人站背景中央空地且移除脚下舞台环；我方精灵下移，敌我血条加粗对齐；顶部和底部整块背板移除，必要按钮独立保留；同日迁移为可编辑 GUI 混合场景，静态 UI 可在 `.tscn` 中调整，棋盘和瞬态特效继续由代码绘制 | 后续按同一风格补怪物战斗立绘和技能大招序列帧 |
| P0 | 战斗准备 | `src/ui/scene/scene_battle_prepare.gd` | `美术开发/概念图/07_战斗准备_battle_prepare.png` | 4 代码代入 | 怪物头像、属性宝石、阵容卡、战力对比、奖励预览、开始按钮 | `美术开发/正式拆分/battle_prepare/` | `assets/images/battle_prepare/` | 已按 image-2 提取 UI 代入；怪物/宝石复用通用资产；2026-05-20 已修正顶栏/按钮重复叠图、卡片描边、图标拉伸和纵向间距 | 进入 Godot 运行窗口做视觉验收和布局微调 |
| P0 | 战斗结算 | `src/ui/scene/scene_result.gd`, `src/ui/scene/scene_battle.gd` | `美术开发/概念图/08_战斗结算_result.png`; `美术开发/元素提取/battle_result_overlay/battle_result_overlay_ui_effects_image2_sheet.png` | 5 待实机视觉验收 | 完整结算页胜负横幅、星级、奖励槽、怪物展示、经验条、按钮、庆祝特效；战斗内胜负过场覆盖层 | `美术开发/正式拆分/result/`, `美术开发/正式拆分/battle_result_overlay/` | `assets/images/result/`, `assets/images/battle/result_overlay/` | 完整结算页和战斗内胜负过场均已按 image-2 拆分并代入；过场动画已拆出独立计时和跳转锁 | 进入 Godot 运行窗口做真实胜负流程视觉验收 |
| P1 | 队伍编成 | `src/ui/scene/scene_team.gd` | `美术开发/概念图/06_队伍进化_team_evolve.png` | 5 视觉验收 | 怪物卡、队伍槽、属性标签、战力条、队长技、保存按钮 | `美术开发/正式拆分/team/` | `assets/images/team/` | 已复用既有 image-2 拆分资产按概念图重排；底部精灵选择区已改为 8 卡翻页，通用怪物头像和关卡箭头继续复用 | 继续在真实编辑流程复核三槽赋值、保存/取消和翻页按钮命中区，并提炼给图鉴复用的怪物卡规范 |
| P1 | 怪物图鉴 | `src/ui/scene/scene_album.gd` | `美术开发/概念图/05_怪物图鉴_monster_album.png` | 5 待实机视觉验收 | 怪物卡、锁定态、属性筛选、详情面板、数值条、技能面板、进化入口、底部页签 | `美术开发/正式拆分/album/` | `assets/images/album/` | 已按 image-2 完成 UI/属性图标/怪物候选提取；Godot 运行目录和 `scene_album.gd` 已代入 | 进入 Godot 运行窗口做真实图鉴视觉验收，并决定星级/返回按钮是否提升通用 |
| P1 | 怪物进化 | `src/ui/scene/scene_evolve.gd` | `美术开发/概念图/06_队伍进化_team_evolve.png` | 1 元素提取草稿 | 进化舞台、前后怪物、箭头、材料槽、进化按钮、光效 | `美术开发/资产拆分/06_team_evolve/` -> `美术开发/正式拆分/evolve/` | `assets/images/evolve/` | 未代入 | 队伍资产稳定后提取进化专用舞台和特效 |
| P2 | 背包 | `src/ui/scene/scene_inventory.gd` | `美术开发/概念图/11_背包_inventory.png` | 5 待实机视觉验收 | 背包背景、顶部栏、货币条、分类标签、5 列道具格、选中/锁定态、滚动条、详情面板、使用按钮、Toast | `美术开发/元素提取/inventory/`, `美术开发/正式拆分/inventory/` | `assets/images/inventory/`, `assets/images/items/` | 已基于概念图用 image-2 生成 UI 提取源，再拆分并代入；道具/进化石图标提升到通用 `assets/images/items/`，商店和背包共用 | 进入 Godot 运行窗口验收背包列表滚动、分类切换、详情面板和使用按钮 |
| P2 | 商店 | `src/ui/scene/scene_shop.gd` | `美术开发/概念图/10_商店_shop.png` | 5 待实机视觉验收 | 商店背景、魔法师/货架氛围、商品卡、价格胶囊、货币、购买按钮、礼包、确认弹窗、分页、底部栏 | `美术开发/正式拆分/shop/` | `assets/images/shop/` | 已基于概念图用 image-2 生成 UI/道具/宝石提取源，再拆分并代入；商品区已调整为概念图四列结构；金币/钻石复用 main 通用资产 | 进入 Godot 运行窗口验收商品列表、分页、购买弹窗和滚动手感 |
| P2 | 每日签到 | `src/ui/scene/scene_sign_in.gd` | `美术开发/概念图/14_每日签到_sign_in.png` | 5 待实机视觉验收 | 日历格、今日高亮、已领印章、奖励图标、宝箱、领取按钮、月累计进度 | `美术开发/元素提取/sign_in/`, `美术开发/正式拆分/sign_in/` | `assets/images/sign_in/` | 已基于概念图用 image-2 生成 UI/奖励提取源，完成拆分、导入和 Canvas 代码代入；保留签到、发奖、成就统计和返回功能 | 真实运行窗口验收 7 日卡密度、月奖励宝箱、领取按钮和成功反馈 |
| P2 | 成就 | `src/ui/scene/scene_achievement.gd` | `美术开发/概念图/12_成就_achievement.png` | 5 待实机视觉验收 | 成就背景、奖杯总览、分类标签、成就徽章、成就卡、标题飘带、进度条、奖励槽、领取按钮、完成印章、锁定态 | `美术开发/元素提取/achievement/`, `美术开发/正式拆分/achievement/` | `assets/images/achievement/`, `assets/images/main/`, `assets/images/inventory/` | 已基于概念图用 image-2 生成 UI/徽章提取源，再拆分并代入；金币复用 main，奖励槽复用 inventory，界面改为统一 Canvas 绘制以控制重叠/对齐/拉伸 | 进入 Godot 运行窗口验收滚动、领取、文本截断和不同分类下的卡片密度 |
| P3 | 怪物牧场 | `src/ui/scene/scene_ranch.gd` | `美术开发/概念图/09_怪物牧场_ranch.png` | 5 待实机视觉验收 | 牧场背景、5 个放置台、收益图标、收获按钮、怪物列表、已放置标记、叶片特效 | `美术开发/正式拆分/ranch/` | `assets/images/ranch/` | 已按概念图重排为 Canvas 绘制；完成 image-2 背景/UI 提取、拆分、导入和代码代入 | 进入 Godot 运行窗口对照概念图做槽位、按钮、列表像素级微调 |
| P4 | 设置 | `src/ui/scene/scene_settings.gd` | `美术开发/概念图/13_设置_settings.png` | 5 待实机视觉验收 | 本轮按需求直接复用现有 UI：背景、返回、标题条、面板、设置行、开关、分段标签、按钮、确认弹窗 | 不新增正式拆分目录；详见 `美术开发/设置界面资产代入表.md` | 不新增 `assets/images/settings/`；复用 `achievement/`, `inventory/`, `shop/`, `main/` | 已完成 Canvas 资产拼装代入；音效/音乐/重置功能保留，新增震动、画质、战斗表现、恢复默认 | 进入 Godot 运行窗口验收设置保存、重置确认弹窗、文字对齐和按钮命中区 |
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
