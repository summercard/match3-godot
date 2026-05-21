# 第三章神秘森林地图运行验收

## 本轮范围

| 项目 | 文件 |
| --- | --- |
| 概念图 | `美术开发/概念图/03_关卡地图_chapter_03_mystic_forest_concept.png` |
| 背景提取源 | `美术开发/元素提取/stage_select/chapter_03_mystic_forest/bg_mystic_forest_image2_source.png` |
| 正式背景 | `美术开发/正式拆分/stage_select/backgrounds/stage_map_bg_mystic_forest.png` |
| 运行背景 | `assets/images/stage/stage_map_bg_chapter_03_mystic_forest.png` |
| 运行截图 | `美术开发/验收/stage_select/chapter_03_mystic_forest_godot_runtime.png` |

## 运行检查

| 检查项 | 结果 | 说明 |
| --- | --- | --- |
| 第三章专属底图加载 | 通过 | 运行截图已显示神秘森林沼泽、紫色裂隙 Boss 区，不再回落到草原底图 |
| 同暗属性章节隔离 | 通过 | `chapter_3` 使用章节 override，通用 `dark` 背景路径保留给其他暗属性章节 |
| 通用资产复用 | 通过 | 节点、路径点、星级、奖励栏、奖励图标与暗属性 BOSS 引用现有通用资产 |
| 运行尺寸链路 | 通过 | 抓图日志为逻辑视口 `375x667`、窗口 `750x1334`、framebuffer `750x1334` |
| 节点与奖励栏同屏 | 通过 | 第三章 5 个普通/精英节点、Boss 节点和底部奖励栏均在运行截图内 |

## 后续精修

- 第三章本轮只新增章节专属地图背景，不重复制作节点、奖励栏和箭头 UI。
- 若后续按每章继续深修，可再为第三章补专属暗影节点底座、暗属性奖励强调色和章节 Boss 节点徽章变体。
