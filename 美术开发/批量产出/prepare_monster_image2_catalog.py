#!/usr/bin/env python3
from __future__ import annotations

import csv
from pathlib import Path
from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
CSV_PATH = ROOT / "docs" / "怪物数据总表.csv"
CONCEPT_DIR = ROOT / "美术开发" / "怪物概念图"
OUT_DIR = ROOT / "美术开发" / "元素提取" / "monster_catalog"
REFERENCE_DIR = OUT_DIR / "reference_tiles_not_final"
IMAGE2_OUTPUT_DIR = OUT_DIR / "image2_outputs"


SHEET_LABELS = {
    "ChatGPT Image 2026年5月20日 18_15_02 (1).png": [
        "enemy_001_fire", "enemy_002_water", "enemy_003_grass", "enemy_004_water",
        "enemy_005_earth", "enemy_006_wind", "enemy_007_dark", "enemy_008_light",
        "enemy_009_dark", "enemy_010_dark", "enemy_011_dark", "enemy_012_thunder",
        "enemy_013_light", "enemy_014_thunder", "enemy_015_light", "enemy_016_thunder",
        "enemy_017_ice", "enemy_018_ice", "enemy_019_ice", "enemy_020_ice",
        "enemy_021_ice",
    ],
    "ChatGPT Image 2026年5月20日 18_13_53 (3).png": [
        "enemy_043_light", "enemy_044_light", "enemy_045_light", "enemy_046_light",
        "monster_008_grass", "monster_009_thunder", "monster_010_light", "monster_011_water",
        "monster_012_water", "monster_013_earth", "monster_014_earth", "monster_015_wind",
        "monster_016_wind", "monster_018_dark", "monster_019_light", "monster_020_light",
        "monster_021_dark", "monster_022_dark", "monster_023_dark", "monster_024_dark",
        "monster_025_thunder",
    ],
    "ChatGPT Image 2026年5月20日 18_13_53 (4).png": [
        "monster_026_thunder", "monster_027_light", "monster_028_light", "monster_029_thunder",
        "monster_030_thunder", "monster_031_light", "monster_032_light", "monster_033_ice",
        "monster_034_ice", "monster_035_ice", "monster_036_ice", "monster_037_ice",
        "monster_038_ice", "monster_039_ice", "monster_040_ice", "monster_041_ice",
        "monster_042_ice", "monster_043_void", "monster_044_void", "monster_045_void",
        "monster_046_void",
    ],
    "ChatGPT Image 2026年5月20日 18_13_53 (5).png": [
        "monster_047_void", "monster_048_void", "monster_049_temporal", "monster_050_temporal",
        "monster_051_temporal", "monster_052_temporal", "monster_053_temporal", "monster_054_temporal",
        "monster_055_star", "monster_056_star", "monster_057_star", "monster_058_star",
        "monster_059_star", "monster_060_star", "monster_061_chaos", "monster_062_chaos",
        "monster_063_chaos", "monster_064_chaos", "monster_065_chaos", "monster_066_chaos",
    ],
    "ChatGPT Image 2026年5月20日 18_15_02 (6).png": [
        "monster_067_light", "monster_068_light", "monster_069_light", "monster_070_light",
        "monster_071_light", "monster_072_light", "monster_073_light", "monster_074_light",
        "monster_075_light", "monster_076_light", "monster_boss_002_fire", "monster_boss_003_water",
        "monster_boss_004_dark", "monster_boss_005_thunder", "monster_boss_006_ice", "monster_boss_007_void",
        "monster_boss_008_temporal", "monster_boss_009_star", "monster_boss_010_chaos", "monster_boss_011_light",
    ],
    "ChatGPT Image 2026年5月20日 18_13_54 (6).png": [
        # Duplicate of 18_15_02 (6). Keep listed for audit, skip in request manifest.
    ],
}


def read_monsters() -> dict[str, dict[str, str]]:
    with CSV_PATH.open("r", encoding="utf-8-sig", newline="") as f:
        return {row["id"]: row for row in csv.DictReader(f)}


def id_from_label(label: str) -> str:
    if label.startswith("monster_boss_"):
        return "_".join(label.split("_")[:3])
    return "_".join(label.split("_")[:2])


def tile_rect(index: int, image_size: tuple[int, int]) -> tuple[int, int, int, int]:
    w, h = image_size
    col = index % 4
    row = index // 4
    margin_x = 18
    margin_y = 12
    gap_x = 12
    gap_y = 9
    tile_w = (w - margin_x * 2 - gap_x * 3) // 4
    tile_h = 270
    x0 = margin_x + col * (tile_w + gap_x)
    y0 = margin_y + row * (tile_h + gap_y)
    return x0, y0, min(w, x0 + tile_w), min(h, y0 + tile_h)


def make_reference_tiles() -> None:
    REFERENCE_DIR.mkdir(parents=True, exist_ok=True)
    for sheet_name, labels in SHEET_LABELS.items():
        if not labels:
            continue
        src = CONCEPT_DIR / sheet_name
        image = Image.open(src).convert("RGBA")
        for idx, label in enumerate(labels):
            crop = image.crop(tile_rect(idx, image.size))
            crop.save(REFERENCE_DIR / f"{label}_reference_not_final.png")


def write_manifest() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    IMAGE2_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    monsters = read_monsters()
    rows = []
    for sheet_name, labels in SHEET_LABELS.items():
        duplicate = not labels
        for idx, label in enumerate(labels):
            monster_id = id_from_label(label)
            data = monsters.get(monster_id, {})
            rows.append({
                "monster_id": monster_id,
                "asset_label": label,
                "csv_name": data.get("name", ""),
                "csv_element": data.get("element", ""),
                "csv_rarity": data.get("rarity", ""),
                "is_boss": data.get("isBoss", ""),
                "source_sheet": sheet_name,
                "tile_index": idx,
                "image2_output_expected": f"{label}.png",
                "final_runtime_path": f"assets/images/battle/monsters/{label}.png",
                "status": "awaiting_image2_output",
                "note": "image-2 需输出透明背景单体怪物；reference_not_final 仅作提示参考，不可直接接入。",
            })
        if duplicate:
            rows.append({
                "monster_id": "",
                "asset_label": "",
                "csv_name": "",
                "csv_element": "",
                "csv_rarity": "",
                "is_boss": "",
                "source_sheet": sheet_name,
                "tile_index": "",
                "image2_output_expected": "",
                "final_runtime_path": "",
                "status": "duplicate_sheet_skipped",
                "note": "与 ChatGPT Image 2026年5月20日 18_15_02 (6).png 内容重复。",
            })
    with (OUT_DIR / "monster_image2_request_manifest.csv").open("w", encoding="utf-8-sig", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)


def write_prompt_doc() -> None:
    text = """# 怪物设定图 image-2 提取任务说明

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
"""
    (OUT_DIR / "monster_image2_prompt.md").write_text(text, encoding="utf-8")


def make_contact_sheet() -> None:
    refs = sorted(REFERENCE_DIR.glob("*_reference_not_final.png"))
    if not refs:
        return
    thumb_w, thumb_h = 120, 146
    cols = 6
    rows = (len(refs) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * thumb_w, rows * thumb_h), (24, 32, 42))
    d = ImageDraw.Draw(sheet)
    for i, path in enumerate(refs):
        im = Image.open(path).convert("RGB")
        im.thumbnail((112, 112))
        x = (i % cols) * thumb_w
        y = (i // cols) * thumb_h
        sheet.paste(im, (x + (thumb_w - im.width) // 2, y + 4))
        label = path.name.replace("_reference_not_final.png", "")
        d.text((x + 4, y + 119), label[:19], fill=(235, 240, 248))
    sheet.save(OUT_DIR / "monster_reference_contact_sheet_not_final.png")


def main() -> None:
    make_reference_tiles()
    write_manifest()
    write_prompt_doc()
    make_contact_sheet()
    print(f"manifest: {OUT_DIR / 'monster_image2_request_manifest.csv'}")
    print(f"prompt: {OUT_DIR / 'monster_image2_prompt.md'}")
    print(f"reference tiles: {REFERENCE_DIR}")


if __name__ == "__main__":
    main()
