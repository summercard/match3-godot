# Godot 完整复刻计划

> 目标：将微信小游戏「三消宝可梦」完整复刻到 Godot 4.x，实现与微信开发者工具中一致的效果。

## 项目路径
- **源（微信）：** `/Users/summercards/WeChatProjects/minigame-1`
- **目标（Godot）：** `/Users/summercards/WeChatProjects/match3-godot`
- **Godot CLI：** `/Users/summercards/Applications/Godot.app/Contents/MacOS/Godot`

## 源项目规模
- 40 个 JS 文件，17,969 行
- 93 个美术 PNG（33MB）
- 0 音频

---

## Phase 1 — 美术资产转移 ✅
- [x] 复制 assets/images/ 全部 93 个 PNG
- [x] 保持目录结构：battle/ main/ stage/ start/ concepts/

## Phase 2 — 纯代码重构 🔄
把所有场景脚本改为动态创建 UI 节点，不依赖 .tscn。

### 优先级（有 @onready 的先做）
- [ ] scene_start.gd — 253行, 6个@onready
- [ ] scene_achievement.gd — 366行, 9个@onready
- [ ] scene_album.gd — 451行, 9个@onready
- [ ] scene_evolve.gd — 499行, 10个@onready
- [ ] scene_ranch.gd — 601行, 8个@onready
- [ ] scene_result.gd — 602行, 11个@onready
- [ ] scene_stage_select.gd — 556行, 12个@onready
- [ ] scene_team.gd — 612行, 11个@onready
- [ ] 其余 8 个场景（纯代码检查+修正）

## Phase 3 — 逻辑校准
逐场景对比 JS 源码，确保：
- UI 布局尺寸位置完全一致
- 交互逻辑（按钮、滑动、长按）一致
- 颜色/字体/间距用 theme.gd 统一
- 数据流（GameManager→场景→子组件）正确

### 对照清单
- [ ] scene_start ← sceneStart.js
- [ ] scene_main ← sceneMain.js
- [ ] scene_stage_select ← sceneStageSelect.js
- [ ] scene_battle_prepare ← sceneBattlePrepare.js
- [ ] scene_battle ← sceneBattle.js
- [ ] scene_result ← sceneResult.js
- [ ] scene_team ← sceneTeamSetup.js
- [ ] scene_album ← sceneAlbum.js
- [ ] scene_evolve ← sceneEvolve.js
- [ ] scene_ranch ← sceneRanch.js
- [ ] scene_shop ← sceneShop.js
- [ ] scene_inventory ← sceneInventory.js
- [ ] scene_achievement ← sceneAchievement.js
- [ ] scene_settings ← sceneSettings.js
- [ ] scene_sign_in ← sceneSignIn.js
- [ ] scene_tutorial ← sceneTutorial.js

## Phase 4 — 集成测试
- [ ] 场景切换链路：开始→主界面→选关→战斗→结算
- [ ] 存档/读档验证（save_manager.gd）
- [ ] 三消核心逻辑（board.gd 匹配/消除/下落/连锁）
- [ ] 战斗数值验证（damage_calculator + monster_db）
- [ ] 宠物系统（捕捉/进化/牧场）

## Phase 5 — 最终打磨
- [ ] 动画/特效迁移（animation.js → Godot Tween/AnimationPlayer）
- [ ] 触控输入适配（input.js → Godot InputEvent）
- [ ] 390×844 竖屏布局微调
- [ ] 渲染效果（主题色、透明度、粒子）
- [ ] `--headless` 零错误 + 截图验证

---

## 自检机制
每轮循环结束必须：
1. `Godot --headless --path ... --quit` 零错误
2. 更新 refactor-progress.json
3. 记录完成/未完成项

## 预估工时
| Phase | 轮次 | 时间 |
|-------|------|------|
| Phase 2 重构 | ~10轮 | 1.5h |
| Phase 3 校准 | ~10轮 | 1.5h |
| Phase 4 测试 | ~5轮 | 1h |
| Phase 5 打磨 | ~5轮 | 1h |
| **总计** | **~30轮** | **~5h** |
