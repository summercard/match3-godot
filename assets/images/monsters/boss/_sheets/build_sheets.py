#!/usr/bin/env python3
"""将 boss/*.png 每 9 张拼成一张 2048x2048 九宫格图。
- 不够 9 张时只填实际数量, 其余 cell 留空(透明)
- 精灵中心对齐 cell 中心, 等比 contain + 8% 内边距
"""
from __future__ import annotations
import math
import sys
from pathlib import Path
from PIL import Image

SRC = Path("/Users/summercards/WeChatProjects/match3-godot/assets/images/monsters/boss")
DST = SRC / "_sheets"
SHEET_SIZE = 2048
COLS = ROWS = 3
PER_SHEET = COLS * ROWS  # 9
PADDING_RATIO = 0.08
BG = (0, 0, 0, 0)


def make_sheet(images, out):
    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE), BG)
    cell_w = SHEET_SIZE / COLS
    cell_h = SHEET_SIZE / ROWS
    pad = min(cell_w, cell_h) * PADDING_RATIO
    inner_w = cell_w - pad * 2
    inner_h = cell_h - pad * 2
    for idx, img_path in enumerate(images):
        r, c = divmod(idx, COLS)
        cx = r * cell_w + cell_w / 2
        cy = c * cell_h + cell_h / 2
        try:
            im = Image.open(img_path).convert("RGBA")
        except Exception as e:
            print(f"  ⚠️  跳过 {img_path.name}: {e}")
            continue
        scale = min(inner_w / im.width, inner_h / im.height)
        if scale <= 0:
            scale = 1
        new_w = max(1, int(round(im.width * scale)))
        new_h = max(1, int(round(im.height * scale)))
        im_resized = im.resize((new_w, new_h), Image.LANCZOS)
        x = int(round(cx - new_w / 2))
        y = int(round(cy - new_h / 2))
        sheet.alpha_composite(im_resized, (x, y))
    sheet.save(out, format="PNG", optimize=True)
    print(f"  ✅  {out.name}  ({len(images)} 张)")


def main():
    files = sorted(p for p in SRC.glob("*.png") if not p.name.endswith(".import"))
    if not files:
        print("boss/ 下没找到 png")
        return 1
    print(f"共 {len(files)} 张 boss")
    DST.mkdir(parents=True, exist_ok=True)
    # 只有 8 张, 不够 9, 一张 8/9 的 sheet 即可
    if len(files) <= PER_SHEET:
        sheets = 1
    else:
        sheets = math.ceil(len(files) / PER_SHEET)
    for i in range(sheets):
        chunk = files[i * PER_SHEET:(i + 1) * PER_SHEET]
        out_name = f"boss_sheet_{i + 1:03d}_{len(chunk)}of9.png"
        make_sheet(chunk, DST / out_name)
    print(f"\n输出目录: {DST}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
