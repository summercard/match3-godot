# 第八章时空裂隙地图运行验收

## 本轮范围

| 项目 | 文件 |
| --- | --- |
| 概念图 | `美术开发/概念图/03_关卡地图_chapter_08_temporal_rift_concept.png` |
| 背景提取源 | `美术开发/元素提取/stage_select/chapter_08_temporal_rift/bg_temporal_rift_image2_source.png` |
| 节点提取源 | `美术开发/元素提取/stage_select/chapter_08_temporal_rift/nodes/` |
| 正式背景 | `美术开发/正式拆分/stage_select/backgrounds/stage_map_bg_temporal_rift.png` |
| 正式节点 | `美术开发/正式拆分/stage_select/nodes/chapter_08_temporal/` |
| 运行背景 | `assets/images/stage/stage_map_bg_chapter_08_temporal_rift.png` |
| 运行节点 | `assets/images/stage/chapter_08_temporal/` |
| 运行截图 | `美术开发/验收/stage_select/chapter_08_temporal_rift_godot_runtime.png` |

## 设计判断

| 方向 | 处理 |
| --- | --- |
| 大 Boss 区 | 背景把时空门与 Boss 圆场放到地图上段，视觉面积约占整张地图 1/3，普通节点路线向其收束 |
| Boss 魄力 | `chapter_8` 使用专属 Boss 布局，放大 Boss 立绘盒、点击盒和时空 Boss 台座 |
| 章节台子一致性 | 普通、选中、精英和 Boss 台子全部替换为时空主题，不再引用草地普通节点与森林 Boss 台座 |
| 关卡题材进入场景 | 时空入口、时间乱流、时空漩涡和时空迷宫用钟环、时流瀑布、时序圆台和裂隙桥表达 |

## 运行检查

| 检查项 | 结果 | 说明 |
| --- | --- | --- |
| 第八章专属底图加载 | 通过 | 运行截图显示时空门、时流瀑布、钟环裂隙和大 Boss 圆场 |
| Boss 区占比 | 通过 | 地图上段保留大 Boss 场，运行 Boss 台座落在该场景内，不再是小角落终点 |
| Boss 立绘放大 | 通过 | 第八章使用章节级 Boss 布局覆盖，Boss 立绘和台座均明显大于旧通用规格 |
| 小台子主题一致 | 通过 | 普通、选中和精英节点均走 `chapter_08_temporal` 时空台子资源 |
| 顶部遮挡控制 | 通过 | 章节标题条在节点和 Boss 之上绘制，放大 Boss 不覆盖标题信息 |
| 资源导入 | 通过 | Godot import 已生成第八章背景、节点透明 PNG 和源图导入链路 |
| 运行尺寸链路 | 通过 | 抓图日志为逻辑视口 `375x667`、窗口 `750x1334`、framebuffer `750x1334` |

## 后续精修

- 第八章把大 Boss 区和章节台子映射做成了新标准，后续章节可直接沿用章节专属节点族能力。
- 第三至第七章背景已经专属化，但普通/精英/Boss 台子仍可按本轮标准回填各章主题资产。
