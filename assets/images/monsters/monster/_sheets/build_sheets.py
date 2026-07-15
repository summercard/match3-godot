#!/usr/bin/env python3
"""将 monster/*.png 每 9 张拼成一张 2048x2048 九宫格图。
- 9 张 = 3x3 layout, 每 cell 约 682.67 px
- 每张精灵等比缩放 (contain) 后居中放置在对应 cell 内
- 留 8% 内边距
- 输出到同目录的 _sheets/ 文件夹
"""
from __future__ import annotations
import math
import os
import sys
from pathlib import Path
from PIL import Image, ImageDraw

SRC = Path("/Users/summercards/WeChatProjects/match3-godot/assets/images/monsters/monster")
DST = SRC / "_sheets"
SHEET_SIZE = 2048
COLS = ROWS = 3
PER_SHEET = COLS * ROWS  # 9
PADDING_RATIO = 0.08      # cell 内边距比例 (相对 cell 较小边)
BG = (0, 0, 0, 0)         # 透明背景
GUIDE_DRAW = False        # 不画宫格线


def list_pngs() -> list[Path]:
    files = sorted(p for p in SRC.glob("*.png") if not p.name.endswith(".import"))
    return files


def make_sheet(images: list[Path], out: Path) -> None:
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
        # contain: 等比缩放, 使最长边贴合 inner box
        scale = min(inner_w / im.width, inner_h / im.height)
        if scale <= 0:
            scale = 1
        new_w = max(1, int(round(im.width * scale)))
        new_h = max(1, int(round(im.height * scale)))
        im_resized = im.resize((new_w, new_h), Image.LANCZOS)
        # 居中: 精灵中心对齐 cell 中心
        x = int(round(cx - new_w / 2))
        y = int(round(cy - new_h / 2))
        sheet.alpha_composite(im_resized, (x, y))

    if GUIDE_DRAW:
        draw = ImageDraw.Draw(sheet)
        for r in range(1, ROWS):
            y = int(r * cell_h)
            draw.line([(0, y), (SHEET_SIZE, y)], fill=(255, 255, 255, 80), width=2)
        for c in range(1, COLS):
            x = int(c * cell_w)
            draw.line([(x, 0), (x, SHEET_SIZE)], fill=(255, 255, 255, 80), width=2)

    sheet.save(out, format="PNG", optimize=True)
    print(f"  ✅  {out.name}  ({len(images)} 张)")


def main() -> int:
    files = list_pngs()
    if not files:
        print("monster/ 下没找到 png")
        return 1
    print(f"共 {len(files)} 张精灵，准备拼 {math.ceil(len(files) / PER_SHEET)} 张九宫格")

    DST.mkdir(parents=True, exist_ok=True)

    sheets = math.ceil(len(files) / PER_SHEET)
    for i in range(sheets):
        chunk = files[i * PER_SHEET:(i + 1) * PER_SHEET]
        out_name = f"monster_sheet_{i + 1:03d}_{len(chunk)}of9.png"
        make_sheet(chunk, DST / out_name)

    print(f"\n输出目录: {DST}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
