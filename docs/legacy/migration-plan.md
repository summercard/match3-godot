# 🎮 Godot 移植计划 — 三消宝可梦 (Match-3 Monster Adventure)

> 从微信小游戏 (Canvas/JS) → Godot 4.x (GDScript)
> 创建时间：2026-05-15
> 项目仓库：https://github.com/summercard/match3-monster-adventure

---

## 一、项目概况

### 当前版本（微信小游戏）

| 维度 | 数据 |
|------|------|
| 代码量 | 34 个 JS 文件，16,436 行代码 |
| 代码结构 | 自建引擎（scene/renderer/input/animation） + 16 个 UI 场景 |
| 数据文件 | 5 个（stages/monsters/achievements/leader-skills/items） |
| 美术资产 | ~120 个 PNG（概念图拆分 + 正式资产） |
| 游戏类型 | 三消 + 宝可梦收集养成 |
| 画面比例 | 竖屏 375×667（设计尺寸），390×844（实际） |
| 渲染方式 | 纯 Canvas 2D 手绘（emoji + 几何图形 + PNG 图片） |

### 已实现功能清单

| 系统 | 功能 | 复杂度 |
|------|------|--------|
| **棋盘引擎** | 7×7 三消、滑动交换、重力下落、连锁消除 | 🔴 高 |
| **特殊宝石** | 4连强化、5连彩虹、L/T炸弹、3×3爆炸 | 🔴 高 |
| **障碍物** | 石块、冰块、锁定、毒雾 | 🟡 中 |
| **战斗系统** | 回合制、属性克制、技能蓄力、Boss AI | 🔴 高 |
| **状态效果** | 灼烧/冰冻/中毒/眩晕 + DoT | 🟡 中 |
| **收服系统** | 概率计算、新手保底、收服特效 | 🟡 中 |
| **宠物成长** | 经验升级、8种性格、属性修正、pokedex | 🟡 中 |
| **牧场系统** | 3槽位挂机、气泡反馈、收取经验 | 🟡 中 |
| **进化系统** | 等级条件、进化动画、数据迁移 | 🟢 低 |
| **队伍编成** | 3槽位、队长技能、战力计算 | 🟡 中 |
| **关卡系统** | 11章普通 + 10个精英关卡 | 🟡 中 |
| **怪物数据** | 46+ 怪物、11章敌人配置 | 🟢 低（纯数据） |
| **商店/背包/签到/成就/设置** | 各自独立系统 | 🟢 低 |
| **新手引导** | 5步引导流程 | 🟢 低 |
| **主题系统** | THEME/COLORS/FONT/按钮统一 | 🟢 低 |

### 场景清单（16 个 UI 场景）

| # | 场景 | 代码行数 | 复杂度 | Godot 对应 |
|---|------|---------|--------|-----------|
| 1 | sceneStart（启动画面） | 774 | 🟡 | Control 节点 + AnimationPlayer |
| 2 | sceneMain（主菜单） | 772 | 🟡 | Control 节点 |
| 3 | sceneStageSelect（关卡选择） | 774 | 🔴 | ScrollContainer + 自定义节点 |
| 4 | sceneBattlePrepare（战斗准备） | 506 | 🟡 | Control + Resource 预览 |
| 5 | sceneBattle（战斗主场景） | 2101 | 🔴 | Node2D + 自定义棋盘 Control |
| 6 | sceneResult（结算） | 709 | 🟡 | Control + AnimationPlayer |
| 7 | sceneTeamSetup（队伍编成） | 738 | 🟡 | Control + 拖拽 |
| 8 | sceneAlbum（图鉴） | 411 | 🟢 | GridContainer + 详情面板 |
| 9 | sceneEvolve（进化） | 398 | 🟡 | Control + 特效 |
| 10 | sceneRanch（牧场） | 638 | 🟡 | Node2D + Control 混合 |
| 11 | sceneShop（商店） | 319 | 🟢 | ItemList + 弹窗 |
| 12 | sceneInventory（背包） | 343 | 🟢 | GridContainer |
| 13 | sceneAchievement（成就） | 266 | 🟢 | ScrollContainer |
| 14 | sceneSettings（设置） | ~200 | 🟢 | Control |
| 15 | sceneSignIn（签到） | 286 | 🟢 | Control + 动画 |
| 16 | sceneTutorial（新手引导） | ~300 | 🟢 | Control + 遮罩 |

---

## 二、移植策略

### 策略选择：自底向上分层移植

```
第1层：数据层（纯数据，直接翻译）
第2层：核心逻辑（棋盘/战斗/收服）
第3层：存档系统（适配 Godot 存储）
第4层：UI 场景（Godot 编辑器可视化搭建）
第5层：动画/特效（Godot Tween/粒子/Shader）
第6层：美术资产整合（PNG → Sprite）
```

### Godot 项目结构规划

```
match3-godot/
├── project.godot
├── export_presets.cfg
├── src/
│   ├── core/                    # 核心系统
│   │   ├── game_manager.gd      # 全局管理（单例 Autoload）
│   │   ├── save_manager.gd      # 存档系统
│   │   ├── theme.gd             # 主题/颜色/字体常量
│   │   └── audio_manager.gd     # 音频管理
│   ├── data/                    # 数据定义
│   │   ├── monster_db.gd        # 怪物数据库（Resource）
│   │   ├── stage_db.gd          # 关卡数据库
│   │   ├── item_db.gd           # 道具数据库
│   │   ├── nature_db.gd         # 性格数据库
│   │   ├── leader_skill_db.gd   # 队长技能
│   │   └── achievement_db.gd    # 成就数据
│   ├── match3/                  # 三消引擎
│   │   ├── board.gd             # 棋盘逻辑（核心）
│   │   ├── gem.gd               # 宝石节点
│   │   ├── board_view.gd        # 棋盘渲染
│   │   └── board_input.gd       # 棋盘输入处理
│   ├── battle/                  # 战斗系统
│   │   ├── battle_manager.gd    # 战斗流程控制
│   │   ├── battle_unit.gd       # 战斗单位（怪物）
│   │   ├── damage_calculator.gd # 伤害计算
│   │   ├── status_effect.gd     # 状态效果
│   │   └── capture_system.gd    # 收服系统
│   ├── ranch/                   # 牧场系统
│   │   ├── ranch_manager.gd     # 牧场逻辑
│   │   └── idle_system.gd       # 挂机系统
│   ├── growth/                  # 成长系统
│   │   ├── growth_system.gd     # 经验/等级
│   │   ├── bond_system.gd       # 亲密度
│   │   └── potential_system.gd  # 潜能
│   └── ui/                      # UI 场景
│       ├── scenes/
│       │   ├── start_screen.tscn
│       │   ├── main_menu.tscn
│       │   ├── stage_select.tscn
│       │   ├── battle_prepare.tscn
│       │   ├── battle_screen.tscn
│       │   ├── result_screen.tscn
│       │   ├── team_setup.tscn
│       │   ├── album.tscn
│       │   ├── evolve.tscn
│       │   ├── ranch.tscn
│       │   ├── shop.tscn
│       │   ├── inventory.tscn
│       │   ├── achievement.tscn
│       │   ├── settings.tscn
│       │   ├── sign_in.tscn
│       │   └── tutorial.tscn
│       └── components/
│           ├── gem_cell.tscn        # 宝石组件
│           ├── monster_card.tscn    # 怪物卡片
│           ├── hp_bar.tscn          # 血条
│           ├── toast.tscn           # Toast 提示
│           ├── floating_text.tscn   # 飘字
│           └── confirm_dialog.tscn  # 确认弹窗
├── resources/
│   ├── monsters/                # 怪物数据资源
│   ├── stages/                  # 关卡数据资源
│   └── themes/                  # 主题资源
├── assets/
│   ├── sprites/                 # 精灵图
│   │   ├── gems/                # 宝石
│   │   ├── monsters/            # 怪物
│   │   ├── ui/                  # UI 元素
│   │   └── backgrounds/         # 背景
│   ├── fonts/                   # 字体
│   ├── audio/                   # 音效/BGM
│   └── shaders/                 # 着色器（发光、特效）
└── docs/
    └── migration-log.md         # 移植日志
```

---

## 三、详细移植步骤

### 阶段 1：环境搭建 + 数据层（1-2 天）

#### 1.1 Godot 项目初始化
- [ ] 安装 Godot 4.x（.NET 版或标准版）
- [ ] 创建新项目 `match3-godot`
- [ ] 设置项目参数（竖屏 390×844、像素完美、拉伸模式）
- [ ] 配置 Autoload 单例：GameManager、SaveManager、ThemeManager

#### 1.2 数据层翻译（最简单，直接搬）
- [ ] **monster_db.gd** — 翻译 `monsterData.js`（2309 行）
  - 在 Godot 中用 Resource 或 JSON
  - 每个怪物 → `MonsterData` Resource
  - `getMonsterStats()` → `MonsterData.get_stats(level)`
  - `RARITY_GROWTH_RATE` → 常量字典
  - `ELEMENT_CHART` → 属性克制表
  - 46 个怪物数据迁移
- [ ] **stage_db.gd** — 翻译 `stages.js`
  - 每个关卡 → `StageData` Resource
  - 11 章 × 每章 3-5 关 + 10 个精英关卡
- [ ] **item_db.gd** — 翻译 `items.js`
- [ ] **nature_db.gd** — 翻译 `natures.js`（8 种性格）
- [ ] **leader_skill_db.gd** — 翻译 `leader-skills.js`
- [ ] **achievement_db.gd** — 翻译 `achievements.js`

**翻译示例：**
```javascript
// JS (monsterData.js)
export const MONSTER_DB = {
  monster_001: {
    id: 'monster_001', name: '火蜥蜴', element: 'fire',
    rarity: 1, emoji: '🦎', baseHP: 120, baseATK: 35, ...
  }
}
```
```gdscript
# GDScript (monster_db.gd)
class_name MonsterDB

const MONSTERS: Dictionary = {
  "monster_001": {
    "id": "monster_001", "name": "火蜥蜴", "element": "fire",
    "rarity": 1, "emoji": "🦎", "base_hp": 120, "base_atk": 35, ...
  }
}
```

#### 1.3 主题系统
- [ ] **theme.gd** — 翻译 `theme.js`
  - COLORS → 静态常量
  - FONT → 动态字体加载
  - THEME → 全局主题配置
  - 按钮预设 → StyleBox 资源

---

### 阶段 2：核心三消引擎（3-4 天）🔴 最关键

#### 2.1 棋盘逻辑（board.gd）
- [ ] 翻译 `board.js`（687 行）核心逻辑：
  - 7×7 棋盘数据结构（二维数组）
  - 滑动交换检测
  - 三消匹配算法（横向/纵向扫描）
  - 特殊宝石检测（4连/5连/L-T形）
  - 重力下落 + 填充
  - 连锁消除（递归）
  - 障碍物逻辑（石块/冰块/锁定/毒雾）
- [ ] 棋盘逻辑与渲染**分离**（逻辑在 board.gd，渲染在 board_view.gd）
- [ ] 单元测试：匹配/交换/下落/特殊宝石

#### 2.2 棋盘渲染（board_view.gd）
- [ ] 用 Godot Control/Node2D 实现棋盘可视化
  - 每个宝石 → `TextureRect` 或 `Sprite2D`
  - 交换动画 → Tween（比 JS 手动算帧简单很多）
  - 消除动画 → Tween（缩放 + 透明度）
  - 下落动画 → Tween（位移）
  - 特殊宝石特效 → 粒子/Shader

#### 2.3 棋盘输入（board_input.gd）
- [ ] 翻译 `input.js` 的滑动检测
  - `InputEventScreenTouch` + `InputEventScreenDrag`
  - 滑动方向判断
  - 最小距离阈值

---

### 阶段 3：战斗系统（3-4 天）🔴 高复杂度

#### 3.1 战斗管理器（battle_manager.gd）
- [ ] 翻译 `battleManager.js`（827 行）：
  - 回合流程：玩家消除 → 伤害计算 → 敌人行动 → 状态更新
  - 属性克制伤害加成
  - 技能蓄力系统
  - Boss AI（蓄力/护盾/回血/召唤）
  - 胜负判定

#### 3.2 伤害计算（damage_calculator.gd）
- [ ] 从 battleManager 中抽离伤害公式
- [ ] 翻译 balance-design.md 中的数值公式
- [ ] 属性克制表 + 连击加成 + 技能倍率

#### 3.3 状态效果（status_effect.gd）
- [ ] 翻译 C4 状态效果系统
  - 灼烧（DoT）/ 冰冻（减攻+跳过回合）/ 中毒（DoT）/ 眩晕（跳过回合）
  - Boss 抗性

#### 3.4 收服系统（capture_system.gd）
- [ ] 翻译 `capture.js`
  - 收服概率计算
  - 新手保底机制
  - 收服特效

---

### 阶段 4：存档系统（1 天）

#### 4.1 存档管理器（save_manager.gd）
- [ ] 翻译 `storage.js`（550 行）
  - 用 Godot 的 `JSON` + `FileAccess` 替代微信 Storage
  - 玩家数据：等级/金币/钻石/队伍/背包
  - pokedex：每只怪物的等级/经验/性格/亲密度
  - 关卡进度
  - 牧场状态（挂机时间/槽位）
  - 成就/签到数据
- [ ] 数据迁移工具：旧存档格式 → 新格式

---

### 阶段 5：UI 场景搭建（5-7 天）🔴 工作量最大

#### 5.0 通用组件（先做，所有场景复用）
- [ ] **gem_cell.tscn** — 宝石单元格（精灵 + 动画）
- [ ] **monster_card.tscn** — 怪物卡片（头像 + 属性 + 等级 + 性格）
- [ ] **hp_bar.tscn** — 血条（TextureProgress + 动画）
- [ ] **toast.tscn** — Toast 提示（弹出 → 停留 → 淡出）
- [ ] **floating_text.tscn** — 飘字动画
- [ ] **confirm_dialog.tscn** — 确认弹窗
- [ ] **按钮样式** — StyleBox 统一（primary/secondary/danger/gold）

#### 5.1 启动画面（start_screen.tscn）
- [ ] 翻译 `sceneStart.js`（774 行）
- [ ] 标题 + 粒子背景 + "进入游戏"按钮
- [ ] 用 AnimationPlayer 替代手动帧动画

#### 5.2 主菜单（main_menu.tscn）
- [ ] 翻译 `sceneMain.js`（772 行）
- [ ] 玩家信息栏 + 功能按钮网格 + 底部导航
- [ ] 功能入口：冒险/队伍/图鉴/牧场/签到/商店/背包/设置/成就

#### 5.3 关卡选择（stage_select.tscn）🔴 复杂
- [ ] 翻译 `sceneStageSelect.js`（774 行）
- [ ] 章节导航 + 路径式关卡节点
- [ ] 滚动 + 关卡详情弹窗
- [ ] 精英关卡标识

#### 5.4 战斗准备（battle_prepare.tscn）
- [ ] 翻译 `sceneBattlePrepare.js`（506 行）
- [ ] 队伍展示 + 敌人预览 + 属性克制提示
- [ ] 开始战斗按钮

#### 5.5 战斗主场景（battle_screen.tscn）🔴 最复杂
- [ ] 翻译 `sceneBattle.js`（2101 行）— 全项目最大文件
- [ ] 敌方区域（怪物 + 血条 + 状态图标）
- [ ] 棋盘区域（board_view 嵌入）
- [ ] 我方区域（3个怪物卡片 + 血条 + 技能条）
- [ ] 顶部信息栏（关卡名 + 回合数 + 暂停）
- [ ] 底部信息条（combo + 提示文字）
- [ ] 收服流程（判定 → 特效 → 结果）

#### 5.6 结算画面（result_screen.tscn）
- [ ] 翻译 `sceneResult.js`（709 行）
- [ ] 胜利/失败分色
- [ ] 星星动画 + 奖励展示 + 经验获取 + 升级提示
- [ ] 收服结果展示

#### 5.7 队伍编成（team_setup.tscn）
- [ ] 翻译 `sceneTeamSetup.js`（738 行）
- [ ] 3 槽位 + 怪物列表 + 拖拽分配
- [ ] 队长技能展示 + 战力计算

#### 5.8 图鉴（album.tscn）
- [ ] 翻译 `sceneAlbum.js`（411 行）
- [ ] 属性筛选 + 网格展示 + 详情面板

#### 5.9 进化（evolve.tscn）
- [ ] 翻译 `sceneEvolve.js`（398 行）
- [ ] 进化条件展示 + 进化动画 + 结果

#### 5.10 牧场（ranch.tscn）
- [ ] 翻译 `sceneRanch.js`（638 行）
- [ ] 怪物展示 + 信息面板 + 挂机气泡 + 收取

#### 5.11 其他场景（较简单）
- [ ] 商店（shop.tscn）— 319 行
- [ ] 背包（inventory.tscn）— 343 行
- [ ] 成就（achievement.tscn）— 266 行
- [ ] 设置（settings.tscn）— ~200 行
- [ ] 签到（sign_in.tscn）— 286 行
- [ ] 新手引导（tutorial.tscn）— ~300 行

---

### 阶段 6：动画与特效（2-3 天）

#### 6.1 用 Godot 原生替代手动动画

| 当前 JS 实现 | Godot 替代方案 |
|-------------|---------------|
| 手动 requestAnimationFrame 帧循环 | Tween / AnimationPlayer |
| 手动计算缩放/位移/透明度 | Tween 属性动画 |
| 手动粒子系统 | GPUParticles2D |
| shadowBlur 发光 | Shader / Light2D |
| 手动震动效果 | Tween + 随机偏移 |

#### 6.2 特效列表
- [ ] 宝石消除动画（放大 → 闪白 → 缩小消失）
- [ ] 连锁消除延迟（100ms 递增）
- [ ] 伤害飘字（弹出 → 上飘 → 淡出）
- [ ] 收服特效（闪白 → 弹跳 → "GET!"）
- [ ] 升级特效（光圈 + 数字弹出）
- [ ] 进化特效（白光扩散 → 弹跳 → 光芒）
- [ ] 画面震动（攻击命中时）
- [ ] 怪物 idle 浮动
- [ ] 按钮按压反馈（scale 0.95）

---

### 阶段 7：美术资产整合（1-2 天）

#### 7.1 现有 PNG 导入
- [ ] 宝石精灵（fire/water/grass/thunder/light + 特殊宝石 + 障碍物）
- [ ] 怪物头像（已有 4 个，后续补充）
- [ ] UI 元素（按钮/面板/图标/徽章）
- [ ] 背景图（草原/森林/关卡地图）

#### 7.2 精灵图设置
- [ ] 导入为 Texture2D
- [ ] 设置过滤模式（Nearest 或 Linear）
- [ ] 创建 AtlasTexture 切片（如需要）
- [ ] 占位：emoji → Sprite 方案（用 Label 节点渲染 emoji 或用精灵图替代）

---

### 阶段 8：音效系统（1 天）

- [ ] BGM 列表（主菜单/战斗/结算）
- [ ] 音效列表（消除/连击/攻击/收服/升级/按钮点击）
- [ ] audio_manager.gd（AudioStreamPlayer 管理）
- [ ] 音量控制（设置页面联动）

---

### 阶段 9：测试与优化（2-3 天）

#### 9.1 功能测试
- [ ] 全流程走查：启动 → 引导 → 主菜单 → 各功能页 → 战斗 → 结算
- [ ] 三消引擎测试（各种匹配场景）
- [ ] 战斗平衡验证（移植后数值是否一致）
- [ ] 存档读写测试

#### 9.2 性能优化
- [ ] 帧率监控（目标稳定 60fps）
- [ ] 内存优化（纹理压缩、资源预加载）
- [ ] 粒子数量控制

#### 9.3 跨平台测试
- [ ] Windows/Mac 桌面版
- [ ] Android 导出测试
- [ ] iOS 导出测试（需 Mac）
- [ ] Web 导出测试

---

## 四、工作量与时间估算

### 总体估算

| 阶段 | 工作量 | 天数 | 优先级 |
|------|--------|------|--------|
| 1. 环境搭建 + 数据层 | 🟢 低 | 1-2 天 | P0 |
| 2. 三消引擎 | 🔴 高 | 3-4 天 | P0 |
| 3. 战斗系统 | 🔴 高 | 3-4 天 | P0 |
| 4. 存档系统 | 🟢 低 | 1 天 | P0 |
| 5. UI 场景 | 🔴 高 | 5-7 天 | P1 |
| 6. 动画特效 | 🟡 中 | 2-3 天 | P1 |
| 7. 美术整合 | 🟡 中 | 1-2 天 | P2 |
| 8. 音效系统 | 🟢 低 | 1 天 | P2 |
| 9. 测试优化 | 🟡 中 | 2-3 天 | P1 |
| **总计** | | **19-27 天** | |

### 里程碑

| 里程碑 | 预计天数 | 交付物 |
|--------|---------|--------|
| **M1: 核心可玩** | 7-10 天 | 三消引擎 + 战斗 + 数据层，能打一关 |
| **M2: 完整循环** | 14-18 天 | 所有 UI 场景 + 存档 + 主线流程跑通 |
| **M3: 打磨发布** | 19-27 天 | 动画/美术/音效/优化/跨平台导出 |

---

## 五、JS → GDScript 对照表

### 语法对照

| JavaScript | GDScript | 说明 |
|-----------|----------|------|
| `const x = 1` | `const x = 1` | 常量 |
| `let x = 1` | `var x = 1` | 变量 |
| `{ key: value }` | `{ "key": value }` | 字典 |
| `[1, 2, 3]` | `[1, 2, 3]` | 数组 |
| `class Foo { constructor() {} }` | `class_name Foo; func _init(): pass` | 类 |
| `import { X } from 'y'` | `const X = preload("y.gd")` | 导入 |
| `export function foo()` | `func foo()` | 函数 |
| `Math.floor(x)` | `int(x)` / `floori(x)` | 取整 |
| `Math.random()` | `randf()` | 随机数 |
| `array.forEach()` | `for item in array:` | 遍历 |
| `array.map()` | `array.map()` | 映射 |
| `array.filter()` | `array.filter()` | 过滤 |
| `array.find()` | `array.find()` | 查找 |
| `JSON.stringify()` | `JSON.stringify()` | 序列化 |
| `JSON.parse()` | `JSON.parse_string()` | 反序列化 |
| `localStorage.setItem()` | `FileAccess.open()` + 写入 | 存储 |
| `canvas.getContext('2d')` | Control/Node2D 绘制 | 渲染 |
| `requestAnimationFrame()` | `_process(delta)` | 帧循环 |
| `Promise` / `async/await` | 信号 + `await` | 异步 |

### 关键差异

| 维度 | JS (微信小游戏) | Godot |
|------|----------------|-------|
| 渲染 | Canvas 2D 手绘 | 节点树 + 场景编辑器 |
| UI 布局 | 手动计算坐标 | Container 自动布局 + 锚点 |
| 动画 | 手动帧计算 | Tween + AnimationPlayer |
| 输入 | onTouchStart/Move/End | InputEvent 回调 |
| 场景管理 | 自写 SceneManager | SceneTree + change_scene() |
| 存储 | wx.setStorageSync | FileAccess + JSON |
| 音频 | wx.createInnerAudioContext | AudioStreamPlayer |

---

## 六、Godot 移植的优势

### 相比微信小游戏版本的提升

| 维度 | 当前 (Canvas/JS) | 移植后 (Godot) |
|------|-----------------|---------------|
| **画面质量** | emoji + 几何图形 | 精灵图 + Shader + 粒子 |
| **动画流畅度** | 手动帧计算，30fps | Tween 60fps |
| **UI 系统** | 手绘坐标 | 可视化编辑 + 自适应布局 |
| **跨平台** | 仅微信小游戏 | PC/Mac/iOS/Android/Web |
| **性能** | Canvas 2D 受限 | GPU 加速渲染 |
| **音效** | 基础 | 完整音频引擎 |
| **开发效率** | 纯代码 | 编辑器 + 代码混合 |
| **发布** | 微信生态 | Steam/App Store/Google Play |

---

## 七、风险与应对

| 风险 | 概率 | 影响 | 应对 |
|------|------|------|------|
| 三消引擎逻辑复杂，移植后行为不一致 | 🟡 中 | 🔴 高 | 先写单元测试，对照 JS 版本逐项验证 |
| UI 场景工作量比预期大 | 🟡 中 | 🟡 中 | 先做核心 5 个场景，其余后续迭代 |
| GDScript 性能问题 | 🟢 低 | 🟡 中 | 核心逻辑用 C# 补充（如需要） |
| 美术资产不够（只有 4 个怪物） | 🟡 中 | 🟡 中 | 先用 emoji/占位图，逐步替换 |
| 跨平台兼容问题 | 🟢 低 | 🟢 低 | Godot 跨平台成熟，风险低 |

---

## 八、建议执行顺序

### 第一周：核心可玩
```
Day 1-2: 阶段1（环境+数据层）
Day 3-5: 阶段2（三消引擎）
Day 6-7: 阶段3（战斗系统）+ 阶段4（存档）
→ 里程碑 M1：能打一关完整战斗
```

### 第二周：完整循环
```
Day 8-9: 阶段5 前半（start/main/stageSelect/battlePrepare）
Day 10-11: 阶段5 后半（battleScreen/result/teamSetup）
Day 12-13: 阶段5 剩余（album/evolve/ranch/shop 等）
Day 14: 阶段6（动画特效）
→ 里程碑 M2：完整游戏循环
```

### 第三周：打磨发布
```
Day 15-16: 阶段6（剩余动画）+ 阶段7（美术整合）
Day 17: 阶段8（音效）
Day 18-20: 阶段9（测试+优化+导出）
→ 里程碑 M3：可发布版本
```

---

## 九、附录

### A. 文件翻译映射表

| JS 源文件 | GDScript 目标 | 行数 | 翻译难度 |
|-----------|-------------|------|---------|
| `js/battle/monsterData.js` | `data/monster_db.gd` + Resource | 2309 | 🟡 数据量大 |
| `js/match3/board.js` | `match3/board.gd` | 687 | 🔴 核心逻辑 |
| `js/battle/battleManager.js` | `battle/battle_manager.gd` | 827 | 🔴 核心逻辑 |
| `js/core/storage.js` | `core/save_manager.gd` | 550 | 🟡 API 替换 |
| `js/ui/sceneBattle.js` | `ui/battle_screen.tscn + .gd` | 2101 | 🔴 最大场景 |
| `js/ui/sceneStart.js` | `ui/start_screen.tscn + .gd` | 774 | 🟡 |
| `js/ui/sceneStageSelect.js` | `ui/stage_select.tscn + .gd` | 774 | 🟡 |
| `js/ui/sceneMain.js` | `ui/main_menu.tscn + .gd` | 772 | 🟡 |
| `js/ui/sceneTeamSetup.js` | `ui/team_setup.tscn + .gd` | 738 | 🟡 |
| `js/ui/sceneResult.js` | `ui/result_screen.tscn + .gd` | 709 | 🟡 |
| `js/ui/sceneRanch.js` | `ui/ranch.tscn + .gd` | 638 | 🟡 |
| `js/ui/sceneBattlePrepare.js` | `ui/battle_prepare.tscn + .gd` | 506 | 🟡 |
| `js/ui/sceneAlbum.js` | `ui/album.tscn + .gd` | 411 | 🟢 |
| `js/ui/sceneEvolve.js` | `ui/evolve.tscn + .gd` | 398 | 🟡 |
| `js/ui/sceneInventory.js` | `ui/inventory.tscn + .gd` | 343 | 🟢 |
| `js/ui/sceneShop.js` | `ui/shop.tscn + .gd` | 319 | 🟢 |
| `js/engine/renderer.js` | （被 Godot 渲染引擎替代） | 289 | — |
| `js/ui/sceneSignIn.js` | `ui/sign_in.tscn + .gd` | 286 | 🟢 |
| `js/ui/sceneAchievement.js` | `ui/achievement.tscn + .gd` | 266 | 🟢 |
| `js/engine/scene.js` | （被 SceneTree 替代） | ~200 | — |
| `js/engine/animation.js` | （被 Tween 替代） | ~150 | — |
| `js/engine/input.js` | （被 InputEvent 替代） | ~120 | — |
| `js/engine/theme.js` | `core/theme.gd` + StyleBox | ~100 | 🟢 |
| `js/engine/FloatingTextManager.js` | `ui/components/floating_text.tscn` | ~100 | 🟢 |
| `js/engine/ToastManager.js` | `ui/components/toast.tscn` | ~100 | 🟢 |
| `js/engine/CaptureEffectManager.js` | 特效场景 | ~100 | 🟢 |
| `js/core/eventBus.js` | （用 Godot Signal 替代） | ~50 | — |
| `js/core/gameManager.js` | `core/game_manager.gd`（Autoload） | ~100 | 🟡 |
| `js/core/achievementManager.js` | 集成到 game_manager | ~80 | 🟢 |
| `js/collection/capture.js` | `battle/capture_system.gd` | ~100 | 🟡 |
| `js/data/items.js` | `data/item_db.gd` | ~50 | 🟢 |
| `js/data/natures.js` | `data/nature_db.gd` | ~60 | 🟢 |
| `data/stages.js` | `data/stage_db.gd` | ~300 | 🟡 数据量大 |
| `data/leader-skills.js` | `data/leader_skill_db.gd` | ~80 | 🟢 |
| `data/achievements.js` | `data/achievement_db.gd` | ~60 | 🟢 |

### B. 不需要移植的文件
- `js/engine/renderer.js` → Godot 渲染引擎替代
- `js/engine/scene.js` → SceneTree 替代
- `js/engine/animation.js` → Tween 替代
- `js/engine/input.js` → InputEvent 替代
- `js/core/eventBus.js` → Signal 替代
- `game.js` / `game.json` / `project.config.json` → Godot 项目配置
- `docs/fix-fonts.js` / `docs/fix-fonts.sh` → 不需要
