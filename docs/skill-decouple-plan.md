# 技能解耦开发计划

## 创建时间
2026-05-19 11:47

## 当前循环：1

## 目标
将 Boss 技能系统（蓄力/护盾/治疗）从 battle_manager.gd 中解耦，提取为独立的 `enemy_skill_system.gd` 模块，实现技能可独立开发和测试。

---

## 当前代码分析

### 问题定位
`battle_manager.gd`（644行）中技能逻辑散落：
- 第116-126行：初始化技能状态（charge/shield/heal）
- 第248-261行：护盾减伤逻辑（耦合在伤害计算中）
- 第443-485行：敌人回合技能执行（散落各处）

### 技能配置（已解耦的数据）
```gdscript
"enemySkills": [
    { "type": "charge", "interval": 3, "damageMultiplier": 2.5 },
    { "type": "shield", "hp": 80, "cooldown": 4 },
    { "type": "heal", "percent": 0.10, "interval": 4 }
]
```

---

## 解耦架构设计

```
src/battle/
├── enemy_skill_system.gd    # 新建：独立技能系统
├── skill_charge.gd          # 新建：蓄力技能模块
├── skill_shield.gd          # 新建：护盾技能模块
└── skill_heal.gd            # 新建：治疗技能模块
```

---

## Phase 1: 提取技能配置结构（验证数据解耦）

**目标**：创建 `enemy_skill_system.gd` 基础结构，验证技能配置可独立管理

**任务**：
- [ ] 新建 `src/battle/enemy_skill_system.gd`
- [ ] 定义技能配置数据结构（skill_config）
- [ ] 定义技能状态数据结构（skill_state）
- [ ] 创建初始化方法 `init_skill_state(skills) -> Dictionary`
- [ ] 保留原 battle_manager.gd 中的初始化逻辑（双重运行验证）

**验收标准**：
- 新模块能正确解析 enemySkills 配置
- 初始化后的 skill_state 结构与原代码兼容
- Godot headless 运行无报错

---

## Phase 2: 蓄力技能解耦（验证蓄力逻辑）

**目标**：将蓄力(charge)技能提取为独立模块

**任务**：
- [ ] 在 `enemy_skill_system.gd` 中实现 `execute_charge(skill_state, enemy)`
- [ ] 提取 `charge_start` 逻辑：设置 is_charging = true
- [ ] 提取 `charge_release` 逻辑：返回 damage_multiplier
- [ ] 更新 battle_manager.gd 的 enemy_action() 调用新模块
- [ ] 对比验证：原逻辑 vs 新逻辑输出完全一致

**验收标准**：
- 蓄力触发时机不变（interval 回合）
- 蓄力释放伤害倍率不变
- enemy_skill_action 信号发出时机和内容不变

---

## Phase 3: 护盾技能解耦（验证护盾逻辑）

**目标**：将护盾(shield)技能提取为独立模块

**任务**：
- [ ] 实现 `execute_shield_before_damage(skill_state)` -> {absorbed, remaining}
- [ ] 实现 `check_and_activate_shield(skill_state, enemy, skills)` -> bool
- [ ] 更新 battle_manager.gd 的护盾相关调用
- [ ] 验证护盾激活时机、HP扣除、冷却逻辑不变

**验收标准**：
- shield_appear 信号发出时机不变
- 护盾 HP 消耗逻辑不变
- 冷却重置逻辑不变

---

## Phase 4: 治疗技能解耦（验证治疗逻辑）

**目标**：将治疗(heal)技能提取为独立模块

**任务**：
- [ ] 实现 `execute_heal(skill_state, enemy, skills)` -> {heal_amount, triggered}
- [ ] 更新 battle_manager.gd 的治疗相关调用
- [ ] 验证回血时机、回血量逻辑不变

**验收标准**：
- heal 信号发出时机不变
- 回血量计算（maxHP * percent）不变
- interval 触发逻辑不变

---

## Phase 5: 完整重构验证

**目标**：battle_manager.gd 只负责战斗流程调度，技能系统完全独立

**任务**：
- [ ] 移除 battle_manager.gd 中的技能执行逻辑（只剩调用）
- [ ] 确保所有功能正常工作（对比测试）
- [ ] 验证新增技能类型方便性（尝试添加一个新技能类型验证）

**验收标准**：
- 所有原有功能（charge/shield/heal）正常工作
- 战斗流程完整（玩家攻击→敌人行动→伤害判定→状态检查→战斗结束）
- 扩展新技能类型只需在 enemy_skill_system.gd 添加新方法

---

## 循环验证机制

每个 Phase 完成后：
1. Godot headless 语法验证：`godot --headless --script-check`
2. 对比原逻辑输出（通过 print 或信号比对）
3. 记录验证结果到 `docs/skill-decouple-progress.md`
4. 发现问题立即回滚或修正

---

## 涉及文件

| 操作 | 文件路径 |
|------|----------|
| 新建 | `src/battle/enemy_skill_system.gd` |
| 新建 | `src/battle/skill_decouple_validation.gd`（验证工具） |
| 修改 | `src/battle/battle_manager.gd` |

---

## 技术约束

- 保持向后兼容：不改变任何外部接口
- 验证驱动：每个阶段必须有验证结果才能进入下一阶段
- 可单独测试：每个技能模块可独立实例化和测试