# 第四章月蚀树冠地图运行验收

## 本轮范围

| 项目 | 文件 |
| --- | --- |
| 概念图 | `美术开发/概念图/03_关卡地图_chapter_04_eclipse_canopy_concept.png` |
| 背景提取源 | `美术开发/元素提取/stage_select/chapter_04_eclipse_canopy/bg_eclipse_canopy_image2_source.png` |
| 正式背景 | `美术开发/正式拆分/stage_select/backgrounds/stage_map_bg_eclipse_canopy.png` |
| 运行背景 | `assets/images/stage/stage_map_bg_chapter_04_eclipse_canopy.png` |
| 运行截图 | `美术开发/验收/stage_select/chapter_04_eclipse_canopy_godot_runtime.png` |

## 设计判断

| 方向 | 处理 |
| --- | --- |
| 与第三章区分 | 第三章是暗影沼泽与裂隙池塘；第四章改成悬空树冠圣堂、蛛网桥和月蚀观测遗迹 |
| 关卡题材进入场景 | 毒蛛巢穴用蛛丝桥和茧袋表达，暗翼盘旋用高空树冠与月蚀天井表达，幽灵徘徊用蓝色幽灯河表达 |
| Boss 区 | 概念图允许暗影巨龙占位，运行背景只保留空巢台和月蚀舞台，避免与 Godot Boss 立绘重复 |

## 运行检查

| 检查项 | 结果 | 说明 |
| --- | --- | --- |
| 第四章专属底图加载 | 通过 | 运行截图显示月蚀树冠、蛛网桥、观测仪与幽蓝深谷 |
| 同暗属性章节隔离 | 通过 | `chapter_4` 走章节 override，不覆盖第三章神秘森林和通用暗属性底图 |
| 通用资产复用 | 通过 | 节点、精英水晶、路径点、奖励栏、宝石、箭头和暗属性 Boss 立绘继续复用 |
| 运行尺寸链路 | 通过 | 抓图日志为逻辑视口 `375x667`、窗口 `750x1334`、framebuffer `750x1334` |
| 资源导入 | 通过 | 第四章新 PNG 经 Godot import 后可被 `ResourceLoader` 加载 |

## 后续精修

- 若继续放大第四章表现，可为暗属性章节做一套不发绿的关卡节点顶面或月蚀色星级托底，进一步减轻草地节点的跨主题感。
- 当前 Boss 立绘仍复用暗属性通用 Boss，若第四章地图继续升格，可再补章节 Boss 徽章框和暗影巨龙专属摆位。
