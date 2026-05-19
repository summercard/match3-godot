# Boss技能实现清单

## 创建时间
2026-05-20

## 背景
从 boss-skill-design.md 实现10种新技能到 enemy_skill_system.gd。M2.7模型每次只做一个技能，8分钟间隔。

---

## 待实现技能（按优先级）

### Skill 1: burn 灼烧
- [x] 每回合对攻击者造成固定伤害
- [x] 持续3回合
- [x] 配置：{ "type": "burn", "damage": 15, "interval": 1, "duration": 3 }

### Skill 2: thunder_strike 雷击
- [ ] 周期性高伤害
- [ ] 冷却3回合
- [ ] 配置：{ "type": "thunder_strike", "damage": 50, "cooldown": 3 }

### Skill 3: reflect 反弹
- [ ] 反弹部分受到伤害给攻击者
- [ ] 持续2回合
- [ ] 配置：{ "type": "reflect", "percent": 0.3, "duration": 2 }

### Skill 4: freeze 冰封
- [x] 概率冻结玩家一回合
- [x] 持续1回合
- [x] 配置：{ "type": "freeze", "chance": 0.3, "duration": 1 }

### Skill 5: poison 中毒
- [ ] 叠层机制，每层掉血
- [ ] 最多3层
- [ ] 配置：{ "type": "poison", "maxStacks": 3, "damagePerStack": 10, "interval": 1 }

### Skill 6: life_drain 灵魂吸取
- [x] 吸取玩家当前HP并回复自己
- [x] 冷却4回合
- [x] 配置：{ "type": "life_drain", "percent": 0.15, "cooldown": 4 }

### Skill 7: surge 浪涌
- [x] 每回合伤害递增
- [x] 上限100
- [x] 配置：{ "type": "surge", "baseDamage": 30, "incrementPerTurn": 10, "maxDamage": 100 }

### Skill 8: confuse 混乱

### Skill 9: shield_plus 强化护盾
- [x] 护盾期间反弹近战伤害
- [x] 配置：{ "type": "shield_plus", "hp": 100, "cooldown": 5, "reflectDamage": true, "reflectPercent": 0.5 }

### Skill 10: skill_seal 技能封印
- [ ] 概率封印玩家技能
- [ ] 持续2回合
- [ ] 配置：{ "type": "skill_seal", "chance": 0.25, "duration": 2 }

---

## 执行规则
1. 每次只实现1个技能
2. 先实现最简再复杂（burn → freeze → thunder_strike → reflect）
3. 8分钟后自动下一轮
4. 每5轮完整检查
5. 每个技能完成后更新 monster_db.gd 配置