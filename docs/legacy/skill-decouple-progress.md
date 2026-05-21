# 技能解耦进度记录

## Phase 5 完成 - 2026-05-19 14:22

### 目标
battle_manager.gd 只负责战斗流程调度，技能系统完全独立。

### 已完成工作

#### 1. init() 技能状态初始化委托
- 移除了手动构建 `enemy_skill_states` 的循环逻辑
- 改为在 init() 末尾调用 `_enemy_skill_system.init_skill_state(enemies)`
- EnemySkillSystem 内部管理所有 charge/shield/heal 状态

#### 2. process_match_result() 护盾减伤委托
- 移除了护盾 HP 检查和手动吸收逻辑
- 改为调用 `_enemy_skill_system.execute_shield_before_damage(target_idx, total_damage)`

#### 3. use_active_skill() 护盾减伤委托
- 同样委托护盾减伤给 EnemySkillSystem

#### 4. enemy_action() 技能执行委托
- **护盾检查**：委托给 `check_and_activate_shield(i, enemy)`
- **回血检查**：委托给 `execute_heal(i, enemy)`
- **蓄力检查**：委托给 `check_and_release_charge(i)` 和 `update_and_check_charge_start(i)`
- `has_skills` 判断改为通过 `_enemy_skill_system.has_skill_type()` 接口

#### 5. get_status() enemy_skill_states 输出
- 改为通过 lambda 收集 `_enemy_skill_system.get_enemy_state(idx)` 的结果

### 验证结果
- 原代码约 644 行，清理后约 590 行
- 删除了约 50 行手动技能状态管理代码
- `enemy_skill_states` 变量声明已完全移除
- 所有技能逻辑均通过 `_enemy_skill_system` 调用

### 扩展新技能类型验证
扩展新技能类型只需在 `enemy_skill_system.gd` 中：
1. 在 `init_skill_state()` 添加新类型的解析
2. 添加新技能的执行方法（如 `execute_new_skill()`）
3. 在 `enemy_action()` 中调用新方法

示例（添加"中毒"技能）：
```gdscript
# 在 enemy_skill_system.gd 添加
func execute_poison(enemy_idx: int, enemy: Dictionary) -> Dictionary:
    # 实现逻辑
    pass

# 在 battle_manager.gd 的 enemy_action() 中
if _enemy_skill_system != null:
    _enemy_skill_system.execute_poison(i, enemy)
```

### 待解决
- 无 Godot headless 环境，未做运行时语法验证
- 建议在 Godot 编辑器中打开项目进行实际测试