#!/usr/bin/env python3
from __future__ import annotations

import csv
import colorsys
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
REPORT_MD = ROOT / "美术开发" / "怪物设定图拆分资产对照表.md"

SHEET_NAME = "ChatGPT Image 2026年5月20日 18_15_02 (1).png"
PREVIEW_PATH = FORMAL_DIR / "monster_sheet_01_refined_contact_sheet.png"


def read_rows() -> list[dict[str, str]]:
    with MANIFEST.open("r", encoding="utf-8-sig", newline="") as f:
        return [
            row for row in csv.DictReader(f)
            if row.get("source_sheet") == SHEET_NAME and row.get("monster_id", "").startswith("enemy_")
        ]


def tile_rect(index: int, image_size: tuple[int, int]) -> tuple[int, int, int, int]:
    w, h = image_size
    col = index % 4
    row = index // 4
    x_positions = [18, 275, 532, 789]
    y_positions = [10, 288, 554, 813, 1071, 1291]
    y_ends = [281, 542, 807, 1060, 1285, 1480]
    tile_w = 245
    x0 = x_positions[col]
    y0 = y_positions[row]
    return x0, y0, min(w, x0 + tile_w), min(h, y_ends[row])


def is_bg(px: tuple[int, int, int, int]) -> bool:
    r, g, b, a = px
    if a < 8:
        return True
    if min(r, g, b) > 230 and max(r, g, b) - min(r, g, b) < 36:
        return True
    if r > 215 and g > 215 and b > 210 and max(r, g, b) - min(r, g, b) < 54:
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
        if not is_bg(px[x, y]):
            continue
        px[x, y] = (255, 255, 255, 0)
        q.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))

    return image


def _component_stats(image: Image.Image, pixels: list[tuple[int, int]]) -> tuple[float, float]:
    px = image.load()
    sat_sum = 0.0
    val_sum = 0.0
    count = 0
    for x, y in pixels[::max(1, len(pixels) // 128)]:
        r, g, b, a = px[x, y]
        if a < 18:
            continue
        _, sat, val = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
        sat_sum += sat
        val_sum += val
        count += 1
    if count == 0:
        return 0.0, 0.0
    return sat_sum / count, val_sum / count


def remove_obvious_label_dust(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A").point(lambda v: 255 if v > 18 else 0)
    w, h = alpha.size
    src = alpha.load()
    keep = Image.new("L", (w, h), 0)
    keep_px = keep.load()
    visited = [[False] * h for _ in range(w)]

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
            comp_w = max_x - min_x + 1
            comp_h = max_y - min_y + 1
            avg_sat, avg_val = _component_stats(image, pixels)
            is_tiny_noise = area < 5
            is_label_like = (
                min_y > h * 0.79
                and area < 900
                and comp_h < 24
                and comp_w < 160
                and avg_sat < 0.22
                and avg_val < 0.78
            )
            if not is_tiny_noise and not is_label_like:
                for x, y in pixels:
                    keep_px[x, y] = 255

    image.putalpha(keep)
    return image


def crop_asset(sheet: Image.Image, tile_index: int) -> Image.Image:
    x0, y0, x1, y1 = tile_rect(tile_index, sheet.size)
    # Work inside the card border, but keep the full vertical tile so tails/effects are not clipped.
    tile = sheet.crop((x0 + 10, y0 + 10, x1 - 10, y1 - 10))
    image = flood_remove_background(tile)
    image = remove_obvious_label_dust(image)
    bbox = image.getchannel("A").getbbox()
    if bbox:
        pad = 8
        image = image.crop((
            max(0, bbox[0] - pad),
            max(0, bbox[1] - pad),
            min(image.width, bbox[2] + pad),
            min(image.height, bbox[3] + pad),
        ))
    return image


def pad_to_square(image: Image.Image, size: int) -> Image.Image:
    image = image.convert("RGBA")
    max_w = int(size * 0.86)
    max_h = int(size * 0.86)
    scale = min(float(max_w) / float(image.width), float(max_h) / float(image.height))
    image = image.resize((max(1, round(image.width * scale)), max(1, round(image.height * scale))), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.alpha_composite(image, ((size - image.width) // 2, int((size - image.height) * 0.54)))
    return canvas


def make_preview(paths: list[Path]) -> None:
    thumbs: list[Image.Image] = []
    for path in paths:
        im = Image.open(path).convert("RGBA")
        canvas = Image.new("RGBA", (140, 164), (18, 26, 36, 255))
        im.thumbnail((124, 122), Image.Resampling.LANCZOS)
        canvas.alpha_composite(im, ((140 - im.width) // 2, 4))
        ImageDraw.Draw(canvas).text((6, 138), path.stem[:20], fill=(230, 236, 244, 255))
        thumbs.append(canvas.convert("RGB"))

    cols = 4
    rows = (len(thumbs) + cols - 1) // cols
    preview = Image.new("RGB", (cols * 140, rows * 164), (13, 19, 28))
    for i, thumb in enumerate(thumbs):
        preview.paste(thumb, ((i % cols) * 140, (i // cols) * 164))
    preview.save(PREVIEW_PATH)


def patch_report(rows: list[dict[str, str]]) -> None:
    if not REPORT_MD.exists():
        return
    text = REPORT_MD.read_text(encoding="utf-8")
    marker = "## 资产映射"
    note = (
        "## 第一张合集精修记录\n\n"
        "- 精修范围：`enemy_001` 至 `enemy_021`。\n"
        "- 处理原则：怪物完整度和比例优先，只去背景和明确文字/噪点，不再为了去字牺牲本体。\n"
        f"- 精修预览：`{PREVIEW_PATH.relative_to(ROOT)}`。\n\n"
    )
    if "## 第一张合集精修记录" in text:
        start = text.index("## 第一张合集精修记录")
        end = text.index(marker)
        text = text[:start] + note + text[end:]
    elif marker in text:
        text = text.replace(marker, note + marker)
    REPORT_MD.write_text(text, encoding="utf-8")


def main() -> None:
    FORMAL_DIR.mkdir(parents=True, exist_ok=True)
    RUNTIME_DIR.mkdir(parents=True, exist_ok=True)
    sheet = Image.open(CONCEPT_DIR / SHEET_NAME).convert("RGBA")
    rows = read_rows()
    runtime_paths: list[Path] = []

    for row in rows:
        label = row["image2_output_expected"].replace(".png", "")
        image = crop_asset(sheet, int(row["tile_index"]))
        for size in (512, 256, 128):
            out = FORMAL_DIR / f"{label}_{size}.png"
            pad_to_square(image, size).save(out)
        runtime = RUNTIME_DIR / f"{label}.png"
        shutil.copyfile(FORMAL_DIR / f"{label}_512.png", runtime)
        runtime_paths.append(runtime)

    make_preview(runtime_paths)
    patch_report(rows)
    print(f"refined {len(runtime_paths)} assets from {SHEET_NAME}")
    print(f"preview: {PREVIEW_PATH}")


if __name__ == "__main__":
    main()
