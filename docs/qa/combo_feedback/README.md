# 三消连锁反馈验收素材

本轮素材对应「第 2 连锁起的 N 连锁提示 + 逐级升高的音效 + 连锁伤害加成」。截图只验证表现层；伤害系数最终平衡档为每级 +4%、第 3 连锁封顶（见 PR 平衡输出）。

- `before_2chain.png`：rebase 后基线 `main`（`9fa85bf`）的旧连击表现。旧版只在连锁结束（断链）时弹出一次「2连击！」，连锁过程中没有常驻提示。
- `after_2chain.png`：改动后同一战局、同一棋盘、同一连锁等级，棋盘中部常驻显示「2 连锁」。
- `before_4chain.png`：rebase 后基线 `9fa85bf` 的旧版断链弹窗「4连击！」。
- `after_4chain.png`：改动后同一战局、同一棋盘、同一连锁等级，棋盘中部显示「4 连锁」。

两张 After 截图都带一条敌方伤害飘字与一条我方伤害飘字，用来确认连锁提示落在棋盘中部，不遮挡血条、头像和伤害飘字。Before/After 使用相同随机种子 `20261109`、相同关卡 `stage_1_1`、相同 750×1334 视口，并固定同一组敌我血量（我方 135/165/127，敌方 150/150）；Before 展示旧版断链瞬间的弹窗，After 展示新版本连锁进行中的常驻提示。

截图命令（在仓库根目录执行）：

```bash
GODOT=~/Applications/Godot.app/Contents/MacOS/Godot
# After：2 / 4 连锁
$GODOT --path . --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=battle --stage-id=stage_1_1 --battle-demo-chain=2 \
  --settle-frames=3 --output=/tmp/chain2_after.png
$GODOT --path . --script res://tests/capture_runtime_scene.gd -- \
  --scene-name=battle --stage-id=stage_1_1 --battle-demo-chain=4 \
  --settle-frames=3 --output=/tmp/chain4_after.png
# Before：在 9fa85bf 基线工作树上用临时脚本复现旧版 _combo_popup（脚本未提交）
# 该工作树需先去掉 main 里 PR #4 遗留的 _damage_popup_queue.clear() 无效引用才能加载战斗场景
$GODOT --path /path/to/main-9fa85bf --script res://tests/capture_chain_baseline.gd -- \
  --level=2 --output=/tmp/chain2_before.png
$GODOT --path /path/to/main-9fa85bf --script res://tests/capture_chain_baseline.gd -- \
  --level=4 --output=/tmp/chain4_before.png
```
