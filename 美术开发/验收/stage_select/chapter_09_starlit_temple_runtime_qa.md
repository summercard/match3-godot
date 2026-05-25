# 第九章星耀圣殿地图运行验收

## 本轮范围

| 项目 | 文件 |
| --- | --- |
| 概念图 | `美术开发/概念图/03_关卡地图_chapter_09_starlit_temple_concept.png` |
| 背景提取源 | `美术开发/元素提取/stage_select/chapter_09_starlit_temple/bg_starlit_temple_image2_source.png` |
| 节点提取源 | `美术开发/元素提取/stage_select/chapter_09_starlit_temple/nodes/` |
| 正式背景 | `美术开发/正式拆分/stage_select/backgrounds/stage_map_bg_starlit_temple.png` |
| 正式节点 | `美术开发/正式拆分/stage_select/nodes/chapter_09_star/` |
| 运行背景 | `assets/images/stage/stage_map_bg_chapter_09_starlit_temple.png` |
| 运行节点 | `assets/images/stage/chapter_09_star/` |
| 运行截图 | `美术开发/验收/stage_select/chapter_09_starlit_temple_godot_runtime.png` |

## 设计判断

| 方向 | 处理 |
| --- | --- |
| 风格修正 | 第九章改为开阔、明亮、可探索的星耀浮岛路线，避免暗黑圣殿和压迫阴影 |
| 大 Boss 区 | 背景上段使用星耀广场承接 Boss，视觉面积约占整张地图 1/3 |
| Boss 魄力 | `chapter_9` 使用章节级放大 Boss 布局，星耀广场台座和无字星耀巨龙立绘共同放大 |
| 章节台子一致性 | 普通、选中、精英和 Boss 台子全部替换为星耀主题，不引用草地节点 |

## 运行检查

| 检查项 | 结果 | 说明 |
| --- | --- | --- |
| 第九章专属底图加载 | 通过 | 运行截图显示星耀浮岛路线、星桥和大 Boss 广场 |
| 明亮幻想冒险风格 | 通过 | 运行画面保留天空、光照、晶体和路线探索感，未回落到暗黑语义 |
| Boss 区占比 | 通过 | Boss 星耀广场占据地图上段主视觉区，Boss 不再是普通终点小节点 |
| Boss 立绘放大 | 通过 | 第九章使用章节级 Boss 布局覆盖，并换成无字星耀巨龙立绘 |
| 小台子主题一致 | 通过 | 普通、选中和精英节点均走 `chapter_09_star` 星耀台子资源 |
| 资源导入 | 通过 | Godot import 已生成第九章背景、节点透明 PNG 和源图导入链路 |
| 运行尺寸链路 | 通过 | 抓图日志为逻辑视口 `375x667`、窗口 `750x1334`、framebuffer `750x1334` |
