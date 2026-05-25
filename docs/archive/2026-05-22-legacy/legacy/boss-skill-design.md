# Boss 技能设计文档

## 创建时间
2026-05-19

## 背景

技能系统解耦后（enemy_skill_system.gd），新增技能只需：
1. 在 `enemy_skill_system.gd` 添加新技能处理方法
2. 在 `monster_db.gd` 的 `enemySkills` 数组中配置即可

---

## 当前已有技能（3种）

| 技能 | 类型 | 效果 |
|------|------|------|
| **charge** | 蓄力 | 蓄力N回合后，伤害翻倍 |
| **shield** | 护盾 | 抵挡X点伤害，冷却Y回合 |
| **heal** | 治疗 | 每Y回合回复X%最大HP |

---

## 新设计技能（10种）

### 1. 🔥 灼烧 (burn)
```javascript
{ "type": "burn", "damage": 15, "interval": 1, "duration": 3 }
```
**效果**：每回合对攻击者造成固定伤害，持续3回合

**设计思路**：
- 玩家攻击Boss后，Boss反击时附加灼烧效果
- 灼烧伤害无视防御，计算简单
- 增加"持续伤害"维度，让玩家需要考虑击杀速度

**应用场景**：适合"燃烧"主题Boss（如火焰巨龙）

---

### 2. ❄️ 冰封 (freeze)
```javascript
{ "type": "freeze", "chance": 0.3, "duration": 1 }
```
**效果**：30%概率冻结玩家一回合，被冻结的玩家无法行动

**设计思路**：
- 控制类技能，增加战斗变数
- 概率触发，不是每次都生效（有风险）
- 持续时间短（1回合），避免过度控场

**应用场景**：冰系Boss专属技能

---

### 3. ⚡ 雷击 (thunder_strike)
```javascript
{ "type": "thunder_strike", "damage": 50, "cooldown": 3, "targetRandom": false }
```
**效果**：每3回合对玩家释放雷击，造成固定伤害

**设计思路**：
- 稳定的周期性高伤害
- `targetRandom: false` 可锁定血量最低目标
- 让玩家有预期："下回合要掉血，提前回血"

**应用场景**：雷电系Boss

---

### 4. 🛡️ 反弹 (reflect)
```javascript
{ "type": "reflect", "percent": 0.3, "duration": 2 }
```
**效果**：反弹30%受到的伤害给攻击者，持续2回合

**设计思路**：
- 惩罚高频攻击玩家
- 高连锁打法会有风险
- 持续时间适中，给玩家调整空间

**应用场景**：反伤系Boss

---

### 5. 💀 中毒 (poison)
```javascript
{ "type": "poison", "maxStacks": 3, "damagePerStack": 10, "interval": 1 }
```
**效果**：最多叠加3层，每层每回合掉10血

**设计思路**：
- 叠层机制，鼓励玩家"快速击杀"或"清除状态"
- 长时间战斗叠加层数会很高
- 可被清除（未来可扩展驱散机制）

**应用场景**：虫系、毒系Boss

---

### 6. ✨ 技能封印 (skill_seal)
```javascript
{ "type": "skill_seal", "chance": 0.25, "duration": 2 }
```
**效果**：25%概率封印玩家技能2回合

**设计思路**：
- 玩家无法释放主动技能（充能技）
- 高随机性，高风险高回报
- 配合其他技能使用更有效

**应用场景**：暗系、魔法系Boss

---

### 7. 🔮 护盾强化 (shield_plus)
```javascript
{ "type": "shield_plus", "hp": 100, "cooldown": 5, "reflectDamage": true, "reflectPercent": 0.5 }
```
**效果**：护盾激活时，反弹50%近战伤害

**设计思路**：
- 强化版护盾，不仅挡伤还能反弹
- 让玩家需要"破盾"而不是"硬抗"
- 配合 charge 使用效果更佳

**应用场景**：综合性Boss

---

### 8. 🌊 浪涌 (surge)
```javascript
{ "type": "surge", "baseDamage": 30, "incrementPerTurn": 10, "maxDamage": 100 }
```
**效果**：每回合伤害递增（30→40→50→...上限100）

**设计思路**：
- "时间压力"机制，战斗拖得越久越危险
- 玩家需要权衡：快速击杀 vs 稳定输出
- 适合作为战斗阶段性机制

**应用场景**：海系、自然Boss

---

### 9. 👻 灵魂吸取 (life_drain)
```javascript
{ "type": "life_drain", "percent": 0.15, "cooldown": 4 }
```
**效果**：每4回合吸取玩家15%当前HP，并回复自己

**设计思路**：
- 针对高HP玩家特别有效
- 让Boss有持续作战能力
- 时间拖得越久，Boss回血越多

**应用场景**：亡灵系、吸血鬼系Boss

---

### 10. 🌀 混乱 (confuse)
```javascript
{ "type": "confuse", "chance": 0.2, "duration": 1, "damageToSelf": true }
```
**效果**：20%概率让玩家攻击自己人，持续1回合

**设计思路**：
- 最有趣的的心理技能
- 高连锁combo时触发会打断节奏
- 概率低但效果戏剧性

**应用场景**：精神系、混沌Boss

---

## 技能组合设计（预设Boss配置）

### Boss 1：熔岩领主（中等难度）
```javascript
"enemySkills": [
    { "type": "burn", "damage": 10, "interval": 1, "duration": 3 },
    { "type": "charge", "interval": 4, "damageMultiplier": 2.5 }
]
```
- 灼烧持续消耗
- 蓄力高伤害威胁

### Boss 2：寒冰女王（控制型）
```javascript
"enemySkills": [
    { "type": "freeze", "chance": 0.3, "duration": 1 },
    { "type": "shield_plus", "hp": 80, "cooldown": 5, "reflectDamage": true, "reflectPercent": 0.4 }
]
```
- 冰封打断玩家节奏
- 强化护盾反弹近战

### Boss 3：虚空毁灭者（高难度）
```javascript
"enemySkills": [
    { "type": "poison", "maxStacks": 3, "damagePerStack": 10, "interval": 1 },
    { "type": "life_drain", "percent": 0.15, "cooldown": 4 },
    { "type": "charge", "interval": 3, "damageMultiplier": 3.0 }
]
```
- 毒层叠加
- 生命吸取
- 强力蓄力

### Boss 4：混沌之眼（随机性Boss）
```javascript
"enemySkills": [
    { "type": "confuse", "chance": 0.25, "duration": 1 },
    { "type": "surge", "baseDamage": 20, "incrementPerTurn": 15, "maxDamage": 100 },
    { "type": "skill_seal", "chance": 0.2, "duration": 2 }
]
```
- 混乱打断combo
- 浪涌时间压力
- 封印限制技能

---

## 技能优先级建议

**Phase 1 实现推荐**（简单顺序）：
1. `burn` - 最简单，固定伤害
2. `thunder_strike` - 稳定周期性伤害
3. `reflect` - 简单反弹

**Phase 2 实现推荐**（中等复杂度）：
4. `freeze` - 概率+控制
5. `poison` - 叠层机制
6. `life_drain` - 吸血

**Phase 3 实现推荐**（高复杂度）：
7. `surge` - 递增伤害
8. `confuse` - 心理技能
9. `shield_plus` - 强化护盾
10. `skill_seal` - 封印

---

## 扩展方向

### 群体技能（未来）
```javascript
{ "type": "area_damage", "damage": 30, "targetAll": true }
```

### 召唤技能（未来）
```javascript
{ "type": "summon", "monsterId": "enemy_001", "count": 2, "cooldown": 5 }
```

### 驱散技能（未来）
```javascript
{ "type": "cleanse", "effectType": "buff", "cooldown": 4 }
```