# UI 场景结构约定

运行时界面入口统一使用 `src/ui/scenes/*.tscn`。除战局 `battle` 可保留较重脚本控制外，界面可视组件应优先放在 `.tscn` 节点树里，方便在 Godot 编辑器中直接调整。

## 目录职责

- `src/ui/scenes/`: 可编辑 PackedScene，是界面布局和组件的唯一入口。
- `src/ui/scene/`: `.tscn` 根节点挂载的控制脚本，负责绑定节点、同步数据和处理交互。
- `src/ui/controllers/`: 从旧脚本场景拆出来的纯逻辑父类，只放数据、规则和兼容逻辑；不要在这里继续新增界面组件。

## 修改规则

- 修改按钮、面板、图标、布局位置、可见状态默认值时，优先改 `.tscn`。
- 修改列表数据、存档读写、战斗/奖励/养成规则时，改 `controllers` 或系统逻辑。
- 新增非战局界面组件时，先在 `.tscn` 建节点，再在对应 `scene_*_gui.gd` 里绑定。
- 不要重新把整屏 UI 写回 `scene_*.gd` 或 `controllers/*_logic.gd`。

## 当前遗留

- `stage_select_logic.gd` 仍保留旧的动态节点创建作为兼容层；章节地图主布局已经由 `stage_select_map.tscn` 和 `stage_select/chapter_maps/*.tscn` 承担。
- `scene_evolve.gd` 还是纯代码界面，后续需要单独迁移到 `evolve.tscn`。
- 战局 `scene_battle.gd` 允许继续保留重脚本控制。
