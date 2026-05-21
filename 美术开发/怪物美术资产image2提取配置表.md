# 怪物美术资产 image-2 提取配置表

更新时间：2026-05-20

## 当前结论

已读取 `docs/怪物数据总表.csv`，并核对 `美术开发/怪物概念图/` 下 6 张怪物设定图。当前可从设定图识别并建立 image-2 提取任务的怪物资产共 103 个；其中 `ChatGPT Image 2026年5月20日 18_13_54 (6).png` 与 `ChatGPT Image 2026年5月20日 18_15_02 (6).png` 内容重复，已在 manifest 中标记为重复跳过。

本轮未把参考切片作为正式资产接入。参考切片只用于 image-2 输入核对，目录名已标注 `reference_tiles_not_final`。

## 文件位置

| 文件/目录 | 用途 |
|---|---|
| `美术开发/元素提取/monster_catalog/monster_image2_request_manifest.csv` | 每个怪物的编号、CSV 名称、来源图、期望 image-2 输出文件名、最终运行路径 |
| `美术开发/元素提取/monster_catalog/monster_image2_prompt.md` | image-2 提取/重绘提示词和输出规格 |
| `美术开发/元素提取/monster_catalog/reference_tiles_not_final/` | 参考切片，仅供 image-2 输入，不可作为正式资产 |
| `美术开发/元素提取/monster_catalog/image2_outputs/` | 真实 image-2 透明 PNG 输出应放入这里 |
| `美术开发/批量产出/import_monster_image2_outputs.py` | 导入 image-2 输出、生成 512/256/128、复制运行目录并更新 `MonsterArtDB` |

## image-2 输出规范

| 项目 | 规范 |
|---|---|
| 文件名 | 与 manifest 的 `image2_output_expected` 完全一致，例如 `monster_008_grass.png` |
| 画布 | 建议 1024x1024，透明背景 PNG |
| 主体 | 单只完整怪物，居中，保留设定图的元素、装备、颜色和轮廓 |
| 禁止 | 白底卡片、文字标签、边框、阴影底、相邻怪物、直接裁切痕迹 |
| 后处理 | 导入脚本会统一生成 `512/256/128` 三档正式资产 |

## 导入方式

当 image-2 输出已放入 `美术开发/元素提取/monster_catalog/image2_outputs/` 后运行：

```bash
python3 美术开发/批量产出/import_monster_image2_outputs.py
```

脚本会输出：

| 输出 | 位置 |
|---|---|
| 正式拆分资产 | `美术开发/正式拆分/monsters/catalog/<asset_label>_512.png` 等 |
| Godot 运行资产 | `assets/images/battle/monsters/<asset_label>.png` |
| 代码配置 | 更新 `src/data/monster_art_db.gd` 的 `MONSTER_ART` 映射 |

## 已建立任务数量

| 来源设定图 | image-2 任务数 | 备注 |
|---|---:|---|
| `ChatGPT Image 2026年5月20日 18_15_02 (1).png` | 21 | enemy_001 到 enemy_021 |
| `ChatGPT Image 2026年5月20日 18_13_53 (3).png` | 21 | enemy_043 到 enemy_046、monster_008 到 monster_025 |
| `ChatGPT Image 2026年5月20日 18_13_53 (4).png` | 21 | monster_026 到 monster_046 |
| `ChatGPT Image 2026年5月20日 18_13_53 (5).png` | 20 | monster_047 到 monster_066 |
| `ChatGPT Image 2026年5月20日 18_15_02 (6).png` | 20 | monster_067 到 monster_076、boss_002 到 boss_011 |
| `ChatGPT Image 2026年5月20日 18_13_54 (6).png` | 0 | 重复图，跳过 |

## 不能直接完成的原因

当前本地环境没有可调用 OpenAI image-2 并自动写回工程目录的接口或 API key。我已经完成 image-2 前置清单、输入参考、命名规范和导入脚本；真实透明怪物单体图需要由 image-2 生成后放入 `image2_outputs/`，再执行导入脚本完成配置。
