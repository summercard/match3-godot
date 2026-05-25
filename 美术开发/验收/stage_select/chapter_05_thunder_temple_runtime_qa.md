# 第五章雷电圣殿地图运行验收

## 本轮范围

| 项目 | 文件 |
| --- | --- |
| 概念图 | `美术开发/概念图/03_关卡地图_chapter_05_thunder_temple_concept.png` |
| 背景提取源 | `美术开发/元素提取/stage_select/chapter_05_thunder_temple/bg_thunder_temple_image2_source.png` |
| 正式背景 | `美术开发/正式拆分/stage_select/backgrounds/stage_map_bg_thunder_temple.png` |
| 运行背景 | `assets/images/stage/stage_map_bg_chapter_05_thunder_temple.png` |
| 运行截图 | `美术开发/验收/stage_select/chapter_05_thunder_temple_godot_runtime.png` |

## 设计判断

| 方向 | 处理 |
| --- | --- |
| 与通用雷属性底图区分 | 通用 `thunder` 底图仍是草原河谷；第五章改成高空雷电神殿、风暴云海和金蓝导雷结构 |
| 关卡题材进入场景 | 雷霆入口用下层神殿门庭表达，雷鹰巢穴与元素风暴用高空台阶、雷晶和电弧裂谷表达 |
| Boss 区 | 概念图保留雷兽圣坛方向，运行背景保持空终点平台，由现有雷属性 Boss 立绘覆盖 |

## 运行检查

| 检查项 | 结果 | 说明 |
| --- | --- | --- |
| 第五章专属底图加载 | 通过 | 运行截图显示雷电圣殿平台、云海风暴和导雷晶柱，不再回落到通用草地图 |
| 同雷属性章节隔离 | 通过 | `chapter_5` 使用章节 override，通用 `stage_map_bg_thunder.png` 保留给其他雷属性章节 |
| 通用资产复用 | 通过 | 节点、精英水晶、路径点、奖励栏、宝石、箭头和雷属性 Boss 立绘继续复用 |
| 资源导入 | 通过 | Godot import 已生成第五章概念、提取源、正式背景、运行背景和验收截图导入链路 |
| 运行尺寸链路 | 通过 | 抓图日志为逻辑视口 `375x667`、窗口 `750x1334`、framebuffer `750x1334` |
| 节点与奖励栏同屏 | 通过 | 第五章 5 个关卡节点、Boss 节点和底部奖励栏均在运行截图内 |

## 后续精修

- 本轮只新增第五章章节专属地图背景，不重复制作节点、奖励栏和箭头 UI。
- 若第五章继续升格，可补雷属性节点底座、导雷电弧前景特效和雷兽 Boss 节点框变体。
