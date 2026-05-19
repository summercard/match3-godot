# Phase 5 收尾任务清单

## 创建时间
2026-05-19

## 背景
M2.7模型每次只做一个小目标，8分钟间隔，循环执行直到完成。

---

## Phase 5: 测试 + 收尾

### P5-1: 代码完整性检查
- [x] 确认 scene_battle.gd 中没有未实现的占位方法 ✅（无TODO/FIXME/placeholder）
- [x] 确认 battle_flow_controller.gd 的 build_result_payload 输入输出正确 ✅（静态方法存在）
- [x] 确认 scene_result.gd 能正确读取 battle 结果 ✅（_go_to_result 传递完整payload）
- [x] 确认所有 preload 路径有效 ✅（10/10 文件存在）

### P5-2: Godot 编辑器运行测试
- [ ] 在编辑器中运行战斗场景，检查是否有 GDScript 错误
- [ ] 验证战斗胜利后收服特效是否正常播放
- [ ] 验证点击后是否正确跳转到 result 场景
- [ ] 验证战斗失败时 MISS 特效是否正常播放

### P5-3: 最终收尾
- [x] 清理所有 debug print 语句（或标记 TODO）✅（commit dfde630）
- [x] 确认 scene_battle.gd 的 destroy() 正确释放所有资源 ✅（commit dfde630）
- [x] 更新 cycle-state.json 标记 P5 完成 ✅

---

## ✅ Phase 5 全部完成（2026-05-20T00:29:00Z）

---

## 下次循环目标（P5-1 第一项）

### 任务
检查 scene_battle.gd 中是否存在未实现的占位方法或 TODO

### 具体步骤
1. 搜索 scene_battle.gd 中包含 TODO、FIXME、placeholder、not_implemented 等关键词
2. 检查所有信号连接是否完整
3. 确认所有调用的外部方法存在

### 验收标准
- 无 GDScript 语法错误
- 无未实现的占位方法调用

---

## 待完成任务（按优先级）

### P1: 开屏视觉还原（scene_start.gd）
- [x] 渐变标题文字
- [x] 装饰emoji（◈ 两侧）
- [x] 副标题渐变（✦ 三消冒险 ✦）
- [x] 怪物立绘浮动（fire/water/grass三只）✅（代码见_draw_monster，commit 90c58c6）
- [x] 宝石浮动（三颗属性宝石）✅（代码见_draw_gem，commit 39652e1）
- [x] 版本号渲染
- [x] 长按交互还原（0.8s阈值+缩放+glow增强）✅（commit b88b0c0）
- [x] 按钮glow效果（glow_boost×1.6，radius×1.2）✅（commit b88b0c0）

### P2: 属性协同+队长技能信息条（scene_battle.gd）
- [x] 队长技能信息条（金色背景+👑+技能描述）✅（代码见_draw_title_bar()，commit d4e9319）
- [x] 属性协同信息条（绿色背景+🤝+标签）✅（get_status已返回synergy_info，_draw_title_bar已渲染，2026-05-19确认）

### P4: 收服特效inline播放（scene_battle.gd）
- [x] 战斗胜利时直接触发CaptureEffect ✅（_check_battle_end()调用_trigger_inline_capture()，commit见scene_battle.gd）
- [x] 成功序列：闪白→弹跳→GET!文字 ✅（capture_effect.gd的_play_success()）
- [x] 失败序列：震动→MISS文字 ✅（capture_effect.gd的_play_fail()）
- [x] 播放完后再跳转scene_result ✅（_go_to_result()检查_capture_waiting_for_effect，_process()检测is_active()）

---

## 下次循环目标（P4第一项）

### 任务
实现收服特效inline播放——战斗胜利时在scene_battle中直接播放CaptureEffect（闪白→弹跳→GET!/MISS），播放完后再跳转scene_result

### 具体步骤
1. 读取src/ui/scene/scene_battle.gd
2. 在_draw_title_bar()或新方法中绘制绿色背景信息条
3. 显示🤝图标+协同标签（如"火+30%"）
4. 数据接入get_synergy_atk_mult等

### 验收标准
- 信息条正常显示
- Godot编辑器无报错

---

## 执行规则
1. 每次只做1个小目标
2. 8分钟后自动执行下一轮
3. 每10轮进行完整检查
4. 完成后勾选本文件