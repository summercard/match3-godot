# 视觉效果移植计划

## 创建时间
2026-05-16 20:15

## 背景
微信版 sceneBattle.js 包含大量视觉效果，Godot 版当前只完成了约 30%。
本计划目标：将所有战斗界面视觉效果 100% 移植到 Godot 4.x。

## 阶段划分（共 10 阶段）

### Phase 1: 棋盘特殊元素渲染
- [ ] 锁定宝石渲染（四角锁链 + 中心锁标记 + HP 显示）
- [ ] 障碍物石块渲染（完好/裂纹两种状态 + 高光 + 裂纹线条）
- [ ] 毒雾格子渲染（绿色脉动覆盖 + 💀 图标）
- **涉及文件**: `src/ui/scene/scene_battle.gd`
- **源参考**: 微信 `_renderLockedGems` / `_renderObstacles` / `_renderPoisonFog`

### Phase 2: 宝石消除动画增强
- [ ] 消除闪白效果（brightness 白色叠加）
- [ ] 选中宝石快脉动（周期1s，0.95↔1.0）
- [ ] 未选中宝石慢脉动（周期2s，0.85↔1.0）
- **涉及文件**: `src/ui/scene/scene_battle.gd`
- **源参考**: 微信 `_renderBoard` 中的 pulseOpacity / eliminatingGems._visual

### Phase 3: 特殊消除特效（十字/炸弹/彩虹）
- [ ] 十字爆炸特效（延迟100ms，十字方向闪光）
- [ ] 炸弹消除特效（延迟150ms，3x3范围闪光）
- [ ] 彩虹消除特效（延迟200ms，全屏闪光0.4s）
- [ ] 特殊消除弹出文字（💥💣🌈 emoji）
- **涉及文件**: `src/ui/scene/scene_battle.gd`
- **源参考**: 微信 `_processMatches` 中 explosionGems/bombGems/rainbowGems 分时播放

### Phase 4: 收服特效接入
- [ ] battle 中调用 CaptureEffect（成功/失败序列）
- [ ] 闪白 + 弹跳 + GET! 文字（成功）
- [ ] 震动 + MISS 文字（失败）
- [ ] 浮动文字弹出收服概率提示
- **涉及文件**: `src/ui/scene/scene_battle.gd`, `src/battle/capture_effect.gd`
- **源参考**: 微信 `CaptureEffectManager` + `sceneBattle` 收服逻辑

### Phase 5: 状态效果视觉反馈
- [ ] burn DoT 弹出（🔥 + 红色伤害数字）
- [ ] poison DoT 弹出（☠️ + 紫色伤害数字）
- [ ] freeze 标记（❄️ 冰冻指示器在敌人卡片上）
- [ ] stun 跳过提示（⚡ 眩晕消息）
- [ ] 效果消失提示文字
- **涉及文件**: `src/ui/scene/scene_battle.gd`
- **源参考**: 微信 `_startEnemyTurn` 中 C4 状态效果视觉部分

### Phase 6: BOSS 技能视觉
- [ ] 蓄力回合提示（⚡ 正在蓄力...）
- [ ] 蓄力充能指示器（enemy card 上显示）
- [ ] Boss 护盾显示（shield HP bar）
- [ ] Boss 治疗浮动文字
- [ ] Boss 蓄力攻击放大伤害数字（28px + 特殊颜色）
- **涉及文件**: `src/ui/scene/scene_battle.gd`
- **源参考**: 微信 `bossSkillVisuals` + 蓄力/护盾/治疗渲染

### Phase 7: 队长技能 + 属性协同信息条
- [ ] 标题栏下方队长技能信息条（金色背景 + 👑 图标）
- [ ] 属性协同信息条（绿色背景 + 🤝 图标 + 标签列表）
- [ ] BOSS 阶段指示器（阶段 x/total）
- **涉及文件**: `src/ui/scene/scene_battle.gd`
- **源参考**: 微信 `render` 中 leaderSkillInfo / synergyInfo / isBossBattle

### Phase 8: 解锁碎裂 + 毒雾扩散/清除动画
- [ ] 锁定宝石解锁碎裂动画（⛓ 碎片四散 + 淡出）
- [ ] 毒雾扩散动画（绿色光圈从小到大 0.6s）
- [ ] 毒雾清除动画（☁️ 碎片四散 + 淡出 0.5s）
- [ ] 解锁提示浮动文字（🔓解锁!）
- **涉及文件**: `src/ui/scene/scene_battle.gd`
- **源参考**: 微信 `unlockAnimations` / `poisonFogSpreadAnims` / `poisonFogClearAnims`

### Phase 9: 敌方回合完整动画链优化
- [ ] 敌方回合等待 500ms（当前立即执行）
- [ ] DoT 击杀提示（☠️ xxx 被状态效果击杀！）
- [ ] 倒下提示消息（💢 xxx 倒下了！）
- [ ] 我方受击 HP 渐变动画触发
- [ ] 蓄力攻击特殊颜色（chargedAttack 色）
- **涉及文件**: `src/ui/scene/scene_battle.gd`
- **源参考**: 微信 `_startEnemyTurn` 完整动画时序

### Phase 10: 整体验收 + 修复
- [ ] 全流程视觉走查（start → main → stage_select → battle → result）
- [ ] 修复所有遗漏的视觉差异
- [ ] 性能检查（确保 60fps）
- [ ] Godot headless 验证通过
- **涉及文件**: 所有 scene_*.gd

## 验收标准
- 微信版 sceneBattle.js 的所有视觉效果在 Godot 版中都有对应实现
- 每个特效的时序、颜色、动画参数与微信版一致
- Godot headless 验证无报错
- 游戏可完整运行一轮战斗
