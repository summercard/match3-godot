#!/usr/bin/env python3
from __future__ import annotations

import csv
import re
import shutil
from pathlib import Path
from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "美术开发" / "元素提取" / "monster_catalog"
IMAGE2_OUTPUT_DIR = OUT_DIR / "image2_outputs"
MANIFEST = OUT_DIR / "monster_image2_request_manifest.csv"
FORMAL_DIR = ROOT / "美术开发" / "正式拆分" / "monsters" / "catalog"
RUNTIME_DIR = ROOT / "assets" / "images" / "battle" / "monsters"
ART_DB = ROOT / "src" / "data" / "monster_art_db.gd"


def load_manifest() -> list[dict[str, str]]:
    with MANIFEST.open("r", encoding="utf-8-sig", newline="") as f:
        return [row for row in csv.DictReader(f) if row.get("image2_output_expected")]


def trim_alpha(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    bbox = image.getbbox()
    return image.crop(bbox) if bbox else image


def pad_to_square(image: Image.Image, size: int) -> Image.Image:
    image = trim_alpha(image)
    image.thumbnail((int(size * 0.86), int(size * 0.86)), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    pos = ((size - image.width) // 2, int((size - image.height) * 0.54))
    canvas.alpha_composite(image, pos)
    return canvas


def process_outputs(rows: list[dict[str, str]]) -> dict[str, str]:
    FORMAL_DIR.mkdir(parents=True, exist_ok=True)
    RUNTIME_DIR.mkdir(parents=True, exist_ok=True)
    imported: dict[str, str] = {}
    missing: list[str] = []
    for row in rows:
        label = row["asset_label"]
        src = IMAGE2_OUTPUT_DIR / row["image2_output_expected"]
        if not src.exists():
            missing.append(row["image2_output_expected"])
            continue
        image = Image.open(src).convert("RGBA")
        for size in [512, 256, 128]:
            out = FORMAL_DIR / f"{label}_{size}.png"
            pad_to_square(image.copy(), size).save(out)
        runtime = RUNTIME_DIR / f"{label}.png"
        shutil.copy2(FORMAL_DIR / f"{label}_512.png", runtime)
        imported[row["monster_id"]] = f"res://assets/images/battle/monsters/{label}.png"
    if missing:
        (OUT_DIR / "missing_image2_outputs.txt").write_text("\n".join(missing), encoding="utf-8")
    return imported


def update_art_db(imported: dict[str, str]) -> None:
    if not imported:
        return
    text = ART_DB.read_text(encoding="utf-8")
    pattern = re.compile(r"const MONSTER_ART := \{.*?\n\}", re.S)
    match = pattern.search(text)
    if not match:
        raise RuntimeError("Cannot find MONSTER_ART block")

    existing: dict[str, str] = {}
    for monster_id, path in re.findall(r'"([^"]+)": \{"battle": "([^"]+)"\}', match.group(0)):
        existing[monster_id] = path
    existing.update(imported)

    lines = ["const MONSTER_ART := {"]
    for i, monster_id in enumerate(sorted(existing.keys(), key=sort_key)):
        comma = "," if i < len(existing) - 1 else ""
        lines.append(f'\t"{monster_id}": {{"battle": "{existing[monster_id]}"}}{comma}')
    lines.append("}")
    text = text[:match.start()] + "\n".join(lines) + text[match.end():]
    ART_DB.write_text(text, encoding="utf-8")


def sort_key(monster_id: str) -> tuple[int, int, str]:
    if monster_id.startswith("monster_boss_"):
        return (2, int(monster_id.split("_")[-1]), monster_id)
    if monster_id.startswith("enemy_"):
        return (1, int(monster_id.split("_")[-1]), monster_id)
    if monster_id.startswith("monster_"):
        return (0, int(monster_id.split("_")[-1]), monster_id)
    return (9, 0, monster_id)


def main() -> None:
    rows = load_manifest()
    imported = process_outputs(rows)
    update_art_db(imported)
    print(f"imported {len(imported)} image-2 monster outputs")
    if len(imported) < len(rows):
        print(f"missing list: {OUT_DIR / 'missing_image2_outputs.txt'}")


if __name__ == "__main__":
    main()
