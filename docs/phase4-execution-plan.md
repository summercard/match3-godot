# Phase 4 执行计划

> 创建时间：2026-05-16 11:18
> 方式：手动逐步执行，每步汇报

## 执行步骤

### Step 1: 迁移 `数值平衡设计.md`
- 直迁，无改写
- 源：minigame-1/docs/balance-design.md

### Step 2: 创建 Godot 版 `游戏设计文档.md`
- 改写微信限定 → Godot 4.x
- 源：minigame-1/docs/游戏设计文档.md

### Step 3: 创建 Godot 版 `基础框架文档.md`
- 重写为 Godot 节点树架构
- 源：minigame-1/docs/基础框架文档.md

### Step 4: 创建 Godot 版 `开发目标.md`
- 定义 M1/M2/M3 里程碑
- 源：minigame-1/docs/dev-target.md

### Step 5: 创建 Godot 版 `体验打磨计划.md`
- Canvas 优化 → Godot 打磨方案
- 源：minigame-1/docs/polish-plan.md

### Step 6: 新建 `src/engine/animation_player.gd`
- Tween 动画封装
- 源：minigame-1/js/engine/animation.js

### Step 7: 新建 `src/battle/capture_effect.gd`
- 捕获特效系统
- 源：minigame-1/js/engine/CaptureEffectManager.js

### Step 8: M1 核心可玩验证
- Godot 运行游戏，走完整流程
- 修复合力错误
