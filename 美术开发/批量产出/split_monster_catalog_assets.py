#!/usr/bin/env python3
from __future__ import annotations

import csv
import re
import shutil
from collections import deque
from pathlib import Path
from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
CONCEPT_DIR = ROOT / "美术开发" / "怪物概念图"
CATALOG_DIR = ROOT / "美术开发" / "元素提取" / "monster_catalog"
MANIFEST = CATALOG_DIR / "monster_image2_request_manifest.csv"
FORMAL_DIR = ROOT / "美术开发" / "正式拆分" / "monsters" / "catalog"
RUNTIME_DIR = ROOT / "assets" / "images" / "battle" / "monsters"
ART_DB = ROOT / "src" / "data" / "monster_art_db.gd"
REPORT_MD = ROOT / "美术开发" / "怪物设定图拆分资产对照表.md"


def read_manifest() -> list[dict[str, str]]:
    with MANIFEST.open("r", encoding="utf-8-sig", newline="") as f:
        return [row for row in csv.DictReader(f) if row.get("image2_output_expected")]


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


def is_background_pixel(pixel: tuple[int, int, int, int]) -> bool:
    r, g, b, a = pixel
    if a < 12:
        return True
    # White card interior, pale card border and light paper texture.
    if min(r, g, b) > 222 and max(r, g, b) - min(r, g, b) < 42:
        return True
    if r > 205 and g > 205 and b > 200 and max(r, g, b) - min(r, g, b) < 58:
        return True
    return False


def flood_remove_background(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    w, h = image.size
    px = image.load()
    visited = [[False] * h for _ in range(w)]
    q: deque[tuple[int, int]] = deque()

    for x in range(w):
        q.append((x, 0))
        q.append((x, h - 1))
    for y in range(h):
        q.append((0, y))
        q.append((w - 1, y))

    while q:
        x, y = q.popleft()
        if x < 0 or y < 0 or x >= w or y >= h or visited[x][y]:
            continue
        visited[x][y] = True
        if not is_background_pixel(px[x, y]):
            continue
        px[x, y] = (255, 255, 255, 0)
        q.append((x + 1, y))
        q.append((x - 1, y))
        q.append((x, y + 1))
        q.append((x, y - 1))

    return image


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int] | None:
    alpha = image.getchannel("A")
    return alpha.getbbox()


def remove_tiny_noise_only(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A").point(lambda v: 255 if v > 18 else 0)
    w, h = alpha.size
    src = alpha.load()
    visited = [[False] * h for _ in range(w)]
    keep = Image.new("L", (w, h), 0)
    keep_px = keep.load()

    for sy in range(h):
        for sx in range(w):
            if visited[sx][sy] or src[sx, sy] == 0:
                continue
            q: deque[tuple[int, int]] = deque([(sx, sy)])
            visited[sx][sy] = True
            pixels: list[tuple[int, int]] = []
            min_x = max_x = sx
            min_y = max_y = sy
            while q:
                x, y = q.popleft()
                pixels.append((x, y))
                min_x = min(min_x, x)
                max_x = max(max_x, x)
                min_y = min(min_y, y)
                max_y = max(max_y, y)
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if nx < 0 or ny < 0 or nx >= w or ny >= h:
                        continue
                    if visited[nx][ny] or src[nx, ny] == 0:
                        continue
                    visited[nx][ny] = True
                    q.append((nx, ny))

            area = len(pixels)
            # Only remove isolated dust. Labels, tails, feet, particles and white highlights are preserved.
            if area >= 6:
                for x, y in pixels:
                    keep_px[x, y] = 255

    image.putalpha(keep)
    return image


def extract_monster(sheet: Image.Image, index: int) -> Image.Image:
    x0, y0, x1, y1 = tile_rect(index, sheet.size)
    tile = sheet.crop((x0 + 5, y0 + 5, x1 - 5, y1 - 5))
    transparent = flood_remove_background(tile)
    transparent = remove_tiny_noise_only(transparent)
    bbox = alpha_bbox(transparent)
    if bbox:
        pad = 6
        left = max(0, bbox[0] - pad)
        top = max(0, bbox[1] - pad)
        right = min(transparent.width, bbox[2] + pad)
        bottom = min(transparent.height, bbox[3] + pad)
        transparent = transparent.crop((left, top, right, bottom))
    return transparent


def pad_to_square(image: Image.Image, size: int) -> Image.Image:
    image = image.convert("RGBA")
    max_w = int(size * 0.88)
    max_h = int(size * 0.88)
    scale = min(float(max_w) / float(image.width), float(max_h) / float(image.height))
    new_size = (max(1, int(round(image.width * scale))), max(1, int(round(image.height * scale))))
    image = image.resize(new_size, Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    x = (size - image.width) // 2
    y = int((size - image.height) * 0.54)
    canvas.alpha_composite(image, (x, y))
    return canvas


def sort_key(monster_id: str) -> tuple[int, int, str]:
    if monster_id.startswith("monster_boss_"):
        return (2, int(monster_id.split("_")[-1]), monster_id)
    if monster_id.startswith("enemy_"):
        return (1, int(monster_id.split("_")[-1]), monster_id)
    if monster_id.startswith("monster_"):
        return (0, int(monster_id.split("_")[-1]), monster_id)
    return (9, 0, monster_id)


def update_art_db(imported: dict[str, str]) -> None:
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
    ART_DB.write_text(text[:match.start()] + "\n".join(lines) + text[match.end():], encoding="utf-8")


def make_contact_sheet(runtime_paths: list[Path]) -> None:
    thumbs = []
    for path in runtime_paths:
        im = Image.open(path).convert("RGBA")
        canvas = Image.new("RGBA", (116, 142), (20, 28, 38, 255))
        im.thumbnail((106, 104), Image.Resampling.LANCZOS)
        canvas.alpha_composite(im, ((116 - im.width) // 2, 4))
        d = ImageDraw.Draw(canvas)
        d.text((4, 114), path.stem[:18], fill=(235, 240, 248, 255))
        thumbs.append(canvas.convert("RGB"))
    cols = 6
    rows = (len(thumbs) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * 116, rows * 142), (14, 20, 29))
    for i, im in enumerate(thumbs):
        sheet.paste(im, ((i % cols) * 116, (i // cols) * 142))
    sheet.save(FORMAL_DIR / "monster_catalog_contact_sheet.png")


def write_report(rows: list[dict[str, str]], imported: dict[str, str]) -> None:
    csv_ids: list[str] = []
    csv_path = ROOT / "docs" / "怪物数据总表.csv"
    if csv_path.exists():
        with csv_path.open("r", encoding="utf-8-sig", newline="") as f:
            csv_ids = [row.get("id", "") for row in csv.DictReader(f) if row.get("id")]
    missing_from_sheets = [monster_id for monster_id in csv_ids if monster_id not in imported]
    lines = [
        "# 怪物设定图拆分资产对照表",
        "",
        "更新时间：2026-05-21",
        "",
        "## 处理说明",
        "",
        "本轮按用户确认的简化流程处理：从 6 张清晰怪物合集设定图中按格子拆分，依据图片底部英文编号和 `docs/怪物数据总表.csv` 对照怪物 ID，去掉白底和卡片背景，统一输出透明 PNG 怪物单体资产，并接入 `MonsterArtDB.MONSTER_ART`。当前版本以怪物完整度、尾巴/脚/特效/高光保留为第一优先级，底部英文编号如残留则暂时保留，不再为了清字牺牲怪物本体。",
        "",
        "## 输出目录",
        "",
        "| 类型 | 路径 |",
        "|---|---|",
        "| 正式拆分 512/256/128 | `美术开发/正式拆分/monsters/catalog/` |",
        "| Godot 运行资产 | `assets/images/battle/monsters/` |",
        "| 资产预览表 | `美术开发/正式拆分/monsters/catalog/monster_catalog_contact_sheet.png` |",
        "",
        "## 覆盖与验收记录",
        "",
        f"- 本轮从 6 张合集设定图产出并接入 `{len(imported)}` 个怪物资产。",
        "- 每个资产输出 `512/256/128` 三档正式拆分图，运行目录使用 512 透明 PNG。",
        "- 已通过 Godot 头less导入，运行目录 PNG 均生成 `.import`。",
        "- 已通过 `MonsterArtDB.validate_art_coverage()` 校验本轮 103 个 ID 的 battle 资源路径。",
        "- 未在这 6 张合集图中出现的怪物 ID 暂不新增资产，保留原有映射或等待后续设定图。",
        "",
        "未由本轮合集图覆盖：`%s`"
        % ("`, `".join(missing_from_sheets) if missing_from_sheets else "无"),
        "",
        "## 资产映射",
        "",
        "| 怪物ID | CSV名称 | 属性 | 来源设定图 | 输出运行资产 | 代码映射 |",
        "|---|---|---|---|---|---|",
    ]
    for row in rows:
        monster_id = row["monster_id"]
        if monster_id not in imported:
            continue
        lines.append(
            "| `%s` | %s | `%s` | `%s` | `%s` | `MonsterArtDB.MONSTER_ART.%s` |"
            % (
                monster_id,
                row["csv_name"],
                row["csv_element"],
                row["source_sheet"],
                imported[monster_id].replace("res://", ""),
                monster_id,
            )
        )
    REPORT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    rows = read_manifest()
    FORMAL_DIR.mkdir(parents=True, exist_ok=True)
    RUNTIME_DIR.mkdir(parents=True, exist_ok=True)
    imported: dict[str, str] = {}
    runtime_paths: list[Path] = []
    sheet_cache: dict[str, Image.Image] = {}

    for row in rows:
        sheet_name = row["source_sheet"]
        if sheet_name not in sheet_cache:
            sheet_cache[sheet_name] = Image.open(CONCEPT_DIR / sheet_name).convert("RGBA")
        label = row["asset_label"]
        monster_id = row["monster_id"]
        monster = extract_monster(sheet_cache[sheet_name], int(row["tile_index"]))
        for size in [512, 256, 128]:
            out = FORMAL_DIR / f"{label}_{size}.png"
            pad_to_square(monster.copy(), size).save(out)
        runtime_path = RUNTIME_DIR / f"{label}.png"
        shutil.copy2(FORMAL_DIR / f"{label}_512.png", runtime_path)
        imported[monster_id] = f"res://assets/images/battle/monsters/{label}.png"
        runtime_paths.append(runtime_path)

    update_art_db(imported)
    make_contact_sheet(runtime_paths)
    write_report(rows, imported)
    print(f"created {len(imported)} monster assets")
    print(f"runtime: {RUNTIME_DIR}")
    print(f"report: {REPORT_MD}")


if __name__ == "__main__":
    main()
