# 怪物设定图 image-2 提取任务说明

更新时间：2026-05-20

## 重要要求

这些参考切片只用于喂给 image-2 或人工核对，不允许作为最终运行资产直接接入。每个怪物必须由 image-2 根据参考图重新提取/重绘为透明背景单体 PNG。

## image-2 输出规格

- 输出目录：`美术开发/元素提取/monster_catalog/image2_outputs/`
- 文件名：使用 manifest 的 `image2_output_expected`，例如 `monster_008_grass.png`
- 画布：建议 1024x1024 透明背景 PNG
- 主体：单只怪物完整身体，保留原设定的轮廓、色彩、装备和元素特征
- 禁止：白底卡片、文字标签、阴影底框、裁切边缘、合并多只怪物
- 风格：保持现有 Q 版像素幻想怪物风格，适配战斗、图鉴、队伍、牧场界面

## 单体 prompt 模板

Use image-2 to extract/redraw one clean isolated monster game sprite from the provided reference tile. Preserve the creature identity, pose, colors, element markings, armor/accessories, and cute fantasy pixel-art style. Remove the card frame, white background, label text, shadows, and any neighboring creatures. Output a single full-body transparent PNG, centered, with clean alpha edges, no text, no border, no UI, no background.

中文约束：从参考切片中提取/重绘一只完整怪物，透明背景，保留设定特征，不要卡片边框和文字，不要直接裁切白底图。

## 后续导入

image-2 输出放入 `image2_outputs/` 后，运行：

```bash
python3 美术开发/批量产出/import_monster_image2_outputs.py
```

脚本会生成正式拆分图、128/256/512 多尺寸图，复制到 `assets/images/battle/monsters/`，并更新 `MonsterArtDB.MONSTER_ART`。
