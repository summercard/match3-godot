# 美术资产代入 List 表

更新时间：2026-05-19

本表用于后续逐步推进美术资产制作和 Godot 代入。阶段口径：`0 概念图` -> `1 image-2 提取` -> `2 正式拆分` -> `3 导入工程` -> `4 代码代入` -> `5 视觉验收`。`完成` 列用 `[x]` / `[ ]` 记录是否已完成到可验收口径。

| 顺序 | 完成 | 优先级 | 界面/模块 | Godot 入口 | 当前阶段 | 已有资产/概念 | 运行目录 | 通用资产复用 | 当前代入结论 | 下一步 |
|---:|---|---|---|---|---|---|---|---|---|---|
| 1 | [x] | P0 | 启动欢迎页 | `src/ui/scene/scene_start.gd` | 5 视觉验收 | `美术开发/正式拆分/start_screen/` | `assets/images/start/` | 初始怪物/宝石可继续并入通用体系 | 已完成第一版代入；已修正旧标题叠字、五元素宝石排列和按下即进入 | 补标题光效、按钮状态、怪物轻动画 |
| 2 | [x] | P0 | 大厅/主界面 | `src/ui/scene/scene_main.gd` | 5 待实机视觉验收 | `美术开发/元素提取/main_lobby_v2/`, `美术开发/正式拆分/main_lobby_v2/` | `assets/images/main/` | 主界面专属入口和顶栏资源留在 main；具体功能图标只在大厅入口使用 | 已按新 `大厅.png` 概念图完成 image-2 背景/UI 提取、拆分、导入和 V2 布局代入；已修正入口按钮压缩、红点重复和冒险入口点击响应 | 真实运行窗口验收按钮贴合、顶部数字、红点和图标清晰度 |
| 3 | [x] | P0 | 关卡选择 | `src/ui/scene/scene_stage_select.gd` | 5 视觉验收 | `美术开发/正式拆分/stage_select/` | `assets/images/stage/` | 星级、奖励、金币、EXP、捕获球作为通用奖励体系 | 已完成第一版代入 | 补多章节地图、节点状态、Boss 动态 |
| 4 | [ ] | P0 | 三消战斗 | `src/ui/scene/scene_battle.gd` | 4 代码代入 | `美术开发/正式拆分/battle_screen/`, `gems/`, `monsters/`, `ui/` | `assets/images/battle/` | 怪物头像、棋盘宝石、战斗背景为核心通用资产 | 核心资产已代入，局部仍需精修 | 补技能按钮、状态图标、连击/技能特效 |
| 5 | [ ] | P0 | 战斗准备 | `src/ui/scene/scene_battle_prepare.gd` | 4 代码代入 | `美术开发/正式拆分/battle_prepare/` | `assets/images/battle_prepare/` | 怪物头像复用 `battle/monsters`；奖励/元素复用 `stage` | 已代入 UI，怪物/宝石走通用目录；已修正顶栏、按钮、卡片、图标拉伸和纵向排布 | 真实运行窗口验收布局和按钮命中区 |
| 6 | [x] | P0 | 战斗结算 | `src/ui/scene/scene_result.gd`, `src/ui/scene/scene_battle.gd` | 5 待实机视觉验收 | `美术开发/正式拆分/result/`, `美术开发/正式拆分/battle_result_overlay/` | `assets/images/result/`, `assets/images/battle/result_overlay/` | 怪物头像复用 `battle/monsters`；金币/EXP/捕获球复用 `stage`；战斗内过场独立于完整结算页 | 完整结算页和战斗内胜负过场均已完成 image-2 拆分、导入和代码代入 | 真实胜负流程验收过场节奏、收服展示、奖励、经验卡展示 |
| 7 | [ ] | P1 | 队伍编成 | `src/ui/scene/scene_team.gd` | 4 代码代入 | `美术开发/正式拆分/team/` | `assets/images/team/` | 怪物头像补入/复用 `battle/monsters`；元素图标复用 `stage` | 已代入三槽队伍卡、战力栏、队长技、筛选条、列表卡、按钮 | 运行窗口验收滚动列表、槽位点击、保存/取消交互 |
| 8 | [x] | P1 | 怪物图鉴 | `src/ui/scene/scene_album.gd` | 5 待实机视觉验收 | `美术开发/元素提取/album/`, `美术开发/正式拆分/album/` | `assets/images/album/` | 怪物头像复用 `assets/images/battle/monsters/`；属性筛选、星级、图鉴 UI 放入 album 专属目录 | 已完成 image-2 提取、正式拆分、运行目录导入和 Canvas 代码代入 | 真实运行窗口验收列表滚动、详情抽屉、进化入口与锁定态 |
| 9 | [ ] | P1 | 怪物进化 | `src/ui/scene/scene_evolve.gd` | 1 元素提取草稿 | `美术开发/概念图/06_队伍进化_team_evolve.png` | `assets/images/evolve/` | 复用队伍怪物卡、怪物头像、材料/元素图标 | 未代入 | 从共用概念图提取进化舞台、材料槽、进化按钮、光效 |
| 10 | [x] | P2 | 背包 | `src/ui/scene/scene_inventory.gd` | 5 待实机视觉验收 | `美术开发/元素提取/inventory/`, `美术开发/正式拆分/inventory/` | `assets/images/inventory/`, `assets/images/items/` | 道具/进化石图标已提升为 `assets/images/items/`，与商店共用；金币/钻石复用 `assets/images/main/` | 已基于背包概念图用 image-2 生成 UI 提取源，完成拆分、导入和 Canvas 代码代入 | 真实运行窗口验收滚动、分类、选中态、详情面板和使用逻辑 |
| 11 | [x] | P2 | 商店 | `src/ui/scene/scene_shop.gd` | 5 待实机视觉验收 | `美术开发/元素提取/shop/`, `美术开发/正式拆分/shop/` | `assets/images/shop/`, `assets/images/items/` | 金币/钻石复用 `assets/images/main/`；商品道具/进化石图标与背包共用 `assets/images/items/`；卡框、按钮、弹窗为 shop 专属 | 已基于概念图用 image-2 生成 UI/道具/宝石提取源，再拆分、导入和代码代入；商品区已改成四列结构 | 真实运行窗口验收分页、滚动、购买弹窗和扣款入库 |
| 12 | [ ] | P2 | 每日签到 | `src/ui/scene/scene_sign_in.gd` | 0 概念图 | `美术开发/概念图/14_每日签到_sign_in.png` | `assets/images/sign_in/` | 复用奖励图标、宝箱、领取按钮状态 | 未代入 | 拆 7 日格、今日高亮、已领印章、领取按钮 |
| 13 | [x] | P2 | 成就 | `src/ui/scene/scene_achievement.gd` | 5 待实机视觉验收 | `美术开发/元素提取/achievement/`, `美术开发/正式拆分/achievement/` | `assets/images/achievement/`, `assets/images/main/`, `assets/images/inventory/` | 金币复用 `assets/images/main/`；奖励槽复用 `assets/images/inventory/ui_slot.png`；成就徽章/UI 为 achievement 专属 | 已基于成就概念图用 image-2 生成 UI/徽章提取源，完成拆分、导入和 Canvas 代码代入；新增质量约束：等比图标、固定卡片坐标、文字宽度截断、点击区与视觉区一致 | 真实运行窗口验收滚动、领取、长文本和分类切换 |
| 14 | [x] | P3 | 怪物牧场 | `src/ui/scene/scene_ranch.gd` | 5 待实机视觉验收 | `美术开发/元素提取/ranch/`, `美术开发/正式拆分/ranch/` | `assets/images/ranch/` | 怪物头像复用 `assets/images/battle/monsters/`；收益图标/放置台/背景为牧场专属 | 已按概念图重排并完成 image-2 背景/UI 提取、拆分、导入、代码代入 | 真实运行窗口对照概念图微调 5 个槽位和底部面板 |
| 15 | [ ] | P4 | 设置 | `src/ui/scene/scene_settings.gd` | 0 概念图 | `美术开发/概念图/13_设置_settings.png` | `assets/images/settings/` | 可沉淀通用开关、滑杆、弹窗按钮 | 未代入 | 建设置 UI 包，后置代入 |
| 16 | [ ] | P4 | 新手教程 | `src/ui/scene/scene_tutorial.gd` | 0 概念图 | `美术开发/概念图/15_新手教程_tutorial.png` | `assets/images/tutorial/` | 复用主流程按钮/面板，新增遮罩、箭头、手势 | 未代入 | 主流程稳定后拆引导层通用资产 |

## 近期执行顺序

| 顺序 | 模块 | 本轮目标 | 依赖/备注 |
|---:|---|---|---|
| 1 | 怪物图鉴 | 完成 image-2 提取、正式拆分、列表/详情代入 | 直接复用队伍编成的怪物卡、筛选条和通用怪物头像 |
| 2 | 怪物进化 | 完成进化舞台、材料槽、按钮、光效代入 | 复用队伍编成与怪物图鉴稳定后的怪物卡体系 |
| 3 | 背包 + 商店 | 建道具图标体系并代入两个界面 | 两个模块共享商品、货币、道具、购买/使用按钮 |
| 4 | 签到 + 成就 | 建奖励、徽章、进度条体系 | 复用奖励图标和领取按钮状态 |
| 5 | 牧场 | 代入放置槽、收益、怪物头像 | 依赖通用怪物头像稳定 |
| 6 | 设置 + 教程 | 低频设置和通用引导层 | 设置后置；教程依赖主流程视觉稳定 |

## 复用规则

| 资产类型 | 归属策略 | 说明 |
|---|---|---|
| 怪物头像/立绘 | `assets/images/battle/monsters/` | 队伍、图鉴、进化、牧场、战斗都引用同一套，避免多份同怪物资源 |
| 元素宝石/属性图标 | `assets/images/stage/` 或 `assets/images/battle/gems/` | UI 角标用 stage，棋盘宝石用 battle/gems |
| 金币/EXP/捕获球/奖励 | 优先 `assets/images/stage/` | 关卡、准备、结算、签到、成就统一奖励语义 |
| 模块专属面板/按钮 | `assets/images/<module>/` | 只服务单个界面的框架、布局、状态变体留在模块目录 |
| 被 3 个以上界面复用的 UI | 后续提升为通用 UI 目录 | 比如怪物卡、筛选标签、奖励槽可在复用稳定后提升 |
