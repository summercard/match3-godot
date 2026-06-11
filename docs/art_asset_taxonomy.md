# 美术资产分类目录约定

本项目运行时图片统一放在 `assets/images/` 下，按资产类别优先分类。目录只表达资源类型，不再按场景继续拆子文件夹；如果不同场景里有同名文件，把来源写进文件名前缀，例如 `shop_ui_back_button.png`。

## 顶层分类

- `ui/`: UI 资源。
- `monsters/`: 怪物、敌人、Boss 图像。
- `maps/`: 地图背景、关卡节点、Boss 节点底座等地图资源。
- `effects/`: 特效贴图。

## UI 子类

- `ui/buttons/`: 按钮、箭头、入口按钮、下拉按钮。
- `ui/icons/`: 普通图标、导航图标、徽章、金币、经验、锁、星星等。
- `ui/gems/`: 宝石、元素图标、进化石、棋盘障碍。
- `ui/backgrounds/`: UI 界面底图。
- `ui/panels/`: 面板、牌匾、胶囊、提示框、toast、横幅、边框。
- `ui/cards/`: 卡片类资源。
- `ui/slots/`: 槽位、格子、奖励槽。
- `ui/bars/`: Header、进度条、血条等横条资源。
- `ui/misc/`: 少量无法稳定归类的 UI 资源。

## 怪物分类

- `monsters/monster/`: 普通怪物图，包含战斗图、头像和展示图。
- `monsters/enemy/`: 敌人图，包含战斗图和头像。
- `monsters/boss/`: Boss 图，包含战斗图、头像和地图展示图。

## 地图和特效

- `maps/backgrounds/`: 地图背景。
- `maps/nodes/`: 关卡节点、选择光圈、路径点等。
- `maps/boss/`: 地图 Boss 节点底座、徽章等。
- `effects/`: 特效贴图直接放在这一层，用来源前缀区分同名文件。

新增图片时优先选择现有类别；只有无法归类时才新增子目录。
