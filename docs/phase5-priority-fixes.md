# Phase 5 优先修复计划

## 创建时间
2026-05-17 00:41

## 背景
深度检查发现 5 项 P0/P1 优先修复，需逐一完成。

## 阶段划分（共 5 阶段）

### Phase 1: sceneStart 开屏视觉还原
- [ ] 渐变标题文字（微信版 _drawGradientText：主色→金色渐变）
- [ ] 装饰 emoji（◈ 两侧装饰符号）
- [ ] 副标题渐变（✦ 三消冒险 ✦）
- [ ] 怪物立绘浮动（_drawStartMonster：fire/water/grass 三只怪物 sin 浮动）
- [ ] 宝石浮动（_drawStartGem：三颗属性宝石上下浮动）
- [ ] 版本号渲染（_drawStartVersion）
- [ ] 长按交互还原（长按光晕渐强→触发进入，而非简单 Button.pressed）
- [ ] 按钮 glow 效果（_drawGlowButton：径向渐变光晕 + 按压缩放）
- **涉及文件**: `src/ui/scene/scene_start.gd`
- **源参考**: 微信 `sceneStart.js` 的 `_renderArtStartScreen` / `_drawGlowButton` / `_onLongPress`

### Phase 2: 属性协同 + 队长技能信息条
- [ ] 标题栏下方新增队长技能信息条（金色背景 + 👑 + 技能描述）
- [ ] 标题栏下方新增属性协同信息条（绿色背景 + 🤝 + 协同标签如"火×2 ATK+15%"）
- [ ] 从 _battle 获取协同数据（get_synergy_atk_mult / get_synergy_def_mult）
- [ ] 从 team 数据获取队长技能信息
- **涉及文件**: `src/ui/scene/scene_battle.gd`
- **源参考**: 微信 `sceneBattle.js` render 中 leaderSkillInfo / synergyInfo 渲染

### Phase 3: 特殊消除动画链时序修正
- [x] explosionGems（十字爆炸）：延迟 100ms 后播放，十字方向闪光
- [x] bombGems（炸弹消除）：延迟 150ms 后播放，3×3 范围闪光
- [x] rainbowGems（彩虹消除）：延迟 200ms 后播放，全屏闪光 0.4s
- [x] 四阶段分时播放，每阶段有独立消除动画 + 浮动文字（💥💣🌈）
- [x] 确保在 _process_matches 中按序触发，不并行
- **涉及文件**: `src/ui/scene/scene_battle.gd`
- **源参考**: 微信 `sceneBattle.js` _processMatches 中 804-830 行的四段 setTimeout 链
- **修改摘要**: 将特殊消除视觉特效（emoji浮动、消息提示、震屏、彩虹闪光）从 _process_matches 第4步的立即触发改为由 _trigger_special_elim 在正确延迟时触发，匹配微信版 setTimeout(0/100/150/200ms) 时序

### Phase 4: 收服特效移回 battle inline
- [ ] 战斗胜利时在 scene_battle 中直接触发 CaptureEffect（而非跳转到 result 后才播放）
- [ ] 成功序列：闪白 → 弹跳 → GET! 文字
- [ ] 失败序列：震动 → MISS 文字
- [ ] 播放完成后再跳转 scene_result
- **涉及文件**: `src/ui/scene/scene_battle.gd`, `src/battle/capture_effect.gd`
- **源参考**: 微信 `sceneBattle.js` 战斗结束时调用 CaptureEffectManager

### Phase 5: BOSS 蓄力系统与 battle_manager 联动
- [ ] battle_manager.enemy_action() 中识别蓄力回合（isCharging）
- [ ] 蓄力时更新 _boss_skill_visuals[attackerIdx].chargeTimer
- [ ] 蓄力完成后 isCharged=true，伤害翻倍+特殊颜色
- [ ] Boss 护盾系统：shield_hp 在 enemy_card 上渲染
- [ ] Boss 治疗浮动文字
- **涉及文件**: `src/ui/scene/scene_battle.gd`, `src/battle/battle_manager.gd`
- **源参考**: 微信 `sceneBattle.js` _startEnemyTurn 中蓄力/护盾/治疗逻辑

## 验收标准
- 开屏视觉效果与微信版接近（渐变文字+装饰+怪物浮动）
- 战斗界面显示队长技能和属性协同信息条
- 特殊消除有分时动画链
- 收服特效在战斗结束时 inline 播放
- BOSS 蓄力/护盾视觉完整
