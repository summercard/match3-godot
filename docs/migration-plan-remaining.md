# 🎮 Godot 移植收尾计划

> 创建时间：2026-05-16
> 状态：Phase 1-3 已完成，进入收尾阶段

---

## 一、当前完成度

### 代码移植 ✅ 91%
- 微信版 34 个 JS 文件 → Godot 35 个 GDScript 文件
- 16,436 行 JS → 15,007 行 GDScript
- 数据层 100%、核心逻辑 100%、UI场景 16/16
- Phase 3 核心审查完成（13个问题修复）

### 资产转移 ✅ 100%
- 所有 PNG 图片已同步（main/start/stage/battle/concepts 目录完整）
- Godot 已自动生成 .import 文件

---

## 二、待完成工作清单

### A. 缺失代码模块（3个 JS 文件无 GDScript 对应）

| 微信源文件 | 行数 | Godot 对应方案 | 优先级 |
|-----------|------|--------------|--------|
| `engine/renderer.js` | 289 | 不需要移植（Godot 内置渲染）| N/A |
| `engine/animation.js` | 256 | **需要新建** `src/engine/animation_player.gd` | P1 |
| `engine/CaptureEffectManager.js` | 248 | **需要新建** `src/battle/capture_effect.gd` | P2 |

#### A1. animation_player.gd — 动画系统（P1）
微信版 `animation.js` 提供的能力：
- 通用 Tween 动画封装（移动、缩放、淡入淡出、弹跳）
- 宝石消除特效（闪烁 → 缩小 → 消失）
- 连击特效（combo 数字弹出）
- 伤害数字飘字（已有 floating_text.gd 基础版，需增强）
- 宝石下落弹跳效果
- 按钮点击缩放反馈

Godot 方案：
- 使用 Godot 内置 `Tween` / `SceneTreeTween` API
- 封装 `AnimationHelper` autoload 提供常用动画
- 调用方：`board.gd`、各 `scene_*.gd`

#### A2. capture_effect.gd — 捕获特效（P2）
微信版 `CaptureEffectManager.js` 提供的能力：
- 捕获球抛出动画
- 捕获球摇晃判定（0-3次）
- 成功/失败闪光特效
- 粒子散射效果

Godot 方案：
- 使用 `GpuParticles2D` + `Tween` 实现
- 在 `capture_system.gd` 中触发

---

### B. 文档迁移（5个文档需迁移/改写）

| 微信文档 | 状态 | 改写方案 |
|---------|------|---------|
| `游戏设计文档.md` | 需改写 | 去掉微信平台限定，改为 Godot 4.x 目标 |
| `基础框架文档.md` | 需重写 | 微信 Canvas 架构 → Godot 节点树架构 |
| `dev-target.md` | 需重写 | 微信开发目标 → Godot 开发目标 |
| `balance-design.md` | 可直迁 | 数值设计平台无关 |
| `polish-plan.md` | 需改写 | Canvas 渲染优化 → Godot 打磨方案 |

#### B1. 游戏设计文档 — 改写要点
- ~~目标平台：微信小游戏~~ → 目标平台：Godot 4.x（PC/Mobile）
- ~~wx.getSystemInfoSync~~ → Godot Viewport/DisplayServer
- ~~Canvas 绘制~~ → Godot Control 节点树
- ~~wx.setStorageSync~~ → Godot ConfigFile / JSON 文件存储
- ~~requestAnimationFrame~~ → Godot _process() / _physics_process()
- 新增：Godot 场景树结构说明
- 新增：Autoload 单例说明（SceneManager, GameManager, SaveManager）
- 新增：信号系统替代 EventBus

#### B2. 基础框架文档 — 重写为 Godot 架构
```
match3-godot/
├── project.godot          # 项目配置（Autoload 注册）
├── main.gd                # 主入口（挂 main.tscn）
├── main.tscn              # 唯一场景（容器）
│
├── src/
│   ├── core/              # 核心 Autoload
│   │   ├── scene_manager.gd   # 场景切换（替代 scene.js + eventBus）
│   │   ├── game_manager.gd    # 全局状态（替代 gameManager.js）
│   │   ├── save_manager.gd    # 存档系统（替代 storage.js）
│   │   └── theme.gd           # 主题/样式（替代 theme.js）
│   │
│   ├── data/              # 数据层（JS data/ 翻译）
│   │   ├── monster_db.gd      # 怪物数据
│   │   ├── stage_db.gd        # 关卡数据
│   │   ├── nature_db.gd       # 性格数据
│   │   ├── item_db.gd         # 道具数据
│   │   ├── leader_skill_db.gd # 队长技能
│   │   └── achievement_db.gd  # 成就数据
│   │
│   ├── match3/            # 三消核心
│   │   └── board.gd            # 棋盘逻辑（替代 board.js + gem.js + matcher.js + gravity.js）
│   │
│   ├── battle/            # 战斗系统
│   │   ├── battle_manager.gd   # 战斗管理（替代 battleManager.js）
│   │   ├── damage_calculator.gd # 伤害计算（从 battleManager 拆出）
│   │   ├── phase_handler.gd    # 回合处理（从 battleManager 拆出）
│   │   ├── status_effect.gd    # 状态效果（从 battleManager 拆出）
│   │   └── capture_system.gd   # 捕获系统（替代 capture.js）
│   │
│   ├── growth/            # 成长系统
│   │   └── growth_system.gd    # 经验/升级（Godot 新增模块）
│   │
│   ├── engine/            # 引擎层（需新建）
│   │   └── animation_player.gd # 动画封装（替代 animation.js）
│   │
│   └── ui/
│       ├── components/    # UI 组件
│       │   ├── toast.gd        # Toast 提示（替代 ToastManager.js）
│       │   └── floating_text.gd # 飘字（替代 FloatingTextManager.js）
│       │
│       └── scene/         # 场景 UI（16个，全部纯代码）
│           ├── scene_start.gd
│           ├── scene_main.gd
│           ├── scene_stage_select.gd
│           ├── scene_battle_prepare.gd
│           ├── scene_battle.gd
│           ├── scene_result.gd
│           ├── scene_team.gd
│           ├── scene_evolve.gd
│           ├── scene_album.gd
│           ├── scene_shop.gd
│           ├── scene_inventory.gd
│           ├── scene_ranch.gd
│           ├── scene_achievement.gd
│           ├── scene_settings.gd
│           ├── scene_sign_in.gd
│           └── scene_tutorial.gd
│
├── assets/                # 美术资源
│   └── images/            # PNG 图片（已全部同步）
│       ├── start/         # 启动页资源
│       ├── main/          # 主界面资源
│       ├── stage/         # 关卡地图资源
│       ├── battle/        # 战斗资源
│       │   ├── gems/      # 宝石
│       │   ├── monsters/  # 怪物立绘
│       │   └── ui/        # 战斗 UI
│       └── concepts/      # 概念图
│
└── docs/                  # 开发文档
    ├── migration-plan.md           # 移植总计划
    ├── migration-plan-remaining.md # 本文件（收尾计划）
    ├── full-replica-plan.md        # 完整复刻计划
    ├── 游戏设计文档.md              # 待创建
    ├── 基础框架文档.md              # 待创建
    ├── 数值平衡设计.md              # 待迁移
    ├── 开发目标.md                  # 待创建
    └── 体验打磨计划.md              # 待创建
```

#### B3. 开发目标 — Godot 版
微信版 `dev-target.md` 记录的是循环 173 轮后的按钮样式统一任务。
Godot 版应重新定义：

**M1 核心可玩（P0）**
- [ ] 启动场景正常显示（scene_start.gd）
- [ ] 场景切换链路畅通（start → main → 各子页面）
- [ ] 三消棋盘可交互（board.gd 滑动交换 + 消除）
- [ ] 战斗流程完整（battle_manager 一场完整战斗）
- [ ] 存档读写正常（save_manager 加载/保存）

**M2 功能闭环（P1）**
- [ ] 关卡推进（stage_select 选择 → 战斗 → 结算 → 解锁下一关）
- [ ] 怪物收服（capture_system 捕获判定 + 特效）
- [ ] 队伍编辑（scene_team 编队 + 保存）
- [ ] 进化系统（scene_evolve 进化条件判定）
- [ ] 商店购买（scene_shop 货币扣除 + 物品获取）
- [ ] 牧场挂机（scene_ranch 时间计算 + 收益）
- [ ] 签到系统（scene_sign_in 每日判定）

**M3 打磨发布（P2）**
- [ ] 动画系统完善（animation_player.gd 补齐特效）
- [ ] 捕获特效（capture_effect.gd）
- [ ] 全场景视觉打磨
- [ ] 音效接入
- [ ] 多分辨率适配
- [ ] 性能优化

---

### C. 微信特有文件 — 不需要移植

| 文件 | 原因 |
|------|------|
| `game.js` | 微信小游戏入口，Godot 用 `main.gd` |
| `game.json` | 微信配置，Godot 用 `project.godot` |
| `project.config.json` | 微信开发者工具配置 |
| `js/engine/input.js` | 微信触摸事件，Godot 内置 Input |
| `js/engine/scene.js` | 微信场景管理，Godot 用 SceneManager |
| `js/core/eventBus.js` | 微信事件总线，Godot 用 Signal |
| `js/core/resource.js` | 微信资源加载，Godot 内置 |
| `docs/cron-tasks.md` | 微信开发循环模板，Godot 不需要 |
| `docs/fix-fonts.js/sh` | 微信字体修复脚本 |

---

## 三、执行计划

### Phase 4：收尾（按优先级排序）

| 编号 | 任务 | 类型 | 预计耗时 |
|------|------|------|---------|
| 4-1 | 创建 Godot 版 `游戏设计文档.md` | 文档 | 10min |
| 4-2 | 创建 Godot 版 `基础框架文档.md` | 文档 | 10min |
| 4-3 | 迁移 `数值平衡设计.md` | 文档 | 5min |
| 4-4 | 创建 Godot 版 `开发目标.md` | 文档 | 10min |
| 4-5 | 创建 Godot 版 `体验打磨计划.md` | 文档 | 10min |
| 4-6 | 新建 `src/engine/animation_player.gd` | 代码 | 20min |
| 4-7 | 新建 `src/battle/capture_effect.gd` | 代码 | 15min |
| 4-8 | M1 核心可玩验证 + 修复 | 集成测试 | 30min |

**总计：约 2 小时**

### Phase 5：M1 可玩性验证（在 Phase 4 之后）
- 用 Godot 编辑器实际运行游戏
- 走一遍完整流程：启动 → 主菜单 → 选关 → 战斗 → 结算
- 修复合力错误和运行时崩溃
- 确保 save/load 正常

---

## 四、风险点

1. **场景切换链路未实测** — 16 个场景都是纯代码生成 UI，Godot headless 验证只检查语法，不检查运行时逻辑
2. **board.gd 三消交互** — 触摸/鼠标输入处理可能需要调整（微信用 touch 事件，Godot 用 Input 事件）
3. **资产路径引用** — GDScript 中 `preload("res://...")` 路径需与实际文件一致
4. **纯代码 UI 布局** — 没有可视化编辑器辅助，位置/大小可能需要大量调试
