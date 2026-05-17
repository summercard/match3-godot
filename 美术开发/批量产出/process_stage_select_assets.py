#!/usr/bin/env python3
"""Split stage-select concept sheets and create supplemental map UI assets."""

from pathlib import Path
from collections import deque
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
FORMAL_DIR = ROOT / "美术开发/正式拆分/stage_select"
RUNTIME_DIR = ROOT / "assets/images/stage"
UI_SHEET = FORMAL_DIR / "stage_map_ui_sheet_alpha.png"
ICON_SHEET = FORMAL_DIR / "stage_map_icon_sheet_alpha.png"

ICON_ROWS = [
    ["icon_star_lit.png", "icon_star_dim.png", "icon_path_dot.png", "icon_chapter_badge.png"],
    ["icon_gold_coin.png", "icon_exp_badge.png", "icon_capture_ball.png", "icon_gem_fire.png"],
    ["icon_gem_water.png", "icon_gem_grass.png", "icon_gem_thunder.png", "icon_gem_light.png"],
]


def find_components(img: Image.Image, min_pixels=300):
    alpha = img.getchannel("A")
    w, h = img.size
    pix = alpha.load()
    seen = set()
    components = []

    for y in range(h):
        for x in range(w):
            if pix[x, y] <= 20 or (x, y) in seen:
                continue
            queue = deque([(x, y)])
            seen.add((x, y))
            min_x = max_x = x
            min_y = max_y = y
            count = 0

            while queue:
                cx, cy = queue.pop()
                count += 1
                min_x = min(min_x, cx)
                max_x = max(max_x, cx)
                min_y = min(min_y, cy)
                max_y = max(max_y, cy)
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if (
                        0 <= nx < w
                        and 0 <= ny < h
                        and (nx, ny) not in seen
                        and pix[nx, ny] > 20
                    ):
                        seen.add((nx, ny))
                        queue.append((nx, ny))

            if count > min_pixels:
                components.append({
                    "count": count,
                    "bbox": (min_x, min_y, max_x + 1, max_y + 1),
                    "center": ((min_x + max_x) / 2, (min_y + max_y) / 2),
                })
    return components


def crop(img: Image.Image, bbox, pad=10):
    w, h = img.size
    left, top, right, bottom = bbox
    return img.crop((
        max(0, left - pad),
        max(0, top - pad),
        min(w, right + pad),
        min(h, bottom + pad),
    ))


def save(img: Image.Image, name: str):
    FORMAL_DIR.mkdir(parents=True, exist_ok=True)
    RUNTIME_DIR.mkdir(parents=True, exist_ok=True)
    img.save(FORMAL_DIR / name)
    img.save(RUNTIME_DIR / name)
    print(f"{name}: {img.size[0]}x{img.size[1]}")


def split_icons():
    sheet = Image.open(ICON_SHEET).convert("RGBA")
    comps = find_components(sheet)
    if len(comps) != 12:
        raise RuntimeError(f"Expected 12 stage icons, got {len(comps)}")

    rows = [
        sorted([c for c in comps if c["center"][1] < 340], key=lambda c: c["center"][0]),
        sorted([c for c in comps if 340 <= c["center"][1] < 660], key=lambda c: c["center"][0]),
        sorted([c for c in comps if c["center"][1] >= 660], key=lambda c: c["center"][0]),
    ]
    for expected, actual in zip(ICON_ROWS, rows):
        if len(expected) != len(actual):
            raise RuntimeError("Unexpected icon row layout")
        for name, comp in zip(expected, actual):
            save(crop(sheet, comp["bbox"], 10), name)


def split_ui():
    sheet = Image.open(UI_SHEET).convert("RGBA")
    comps = find_components(sheet)
    if len(comps) != 10:
        raise RuntimeError(f"Expected 10 stage UI components, got {len(comps)}")

    assigned = {}
    assigned["ui_header_bar.png"] = max(comps, key=lambda c: c["count"])

    small_top = sorted([c for c in comps if c["center"][1] < 260 and c is not assigned["ui_header_bar.png"]], key=lambda c: c["center"][0])
    assigned["ui_back_button.png"] = small_top[0]
    assigned["ui_arrow_button.png"] = small_top[1]

    nodes = sorted([c for c in comps if 280 < c["center"][1] < 580], key=lambda c: c["center"][0])
    if len(nodes) != 5:
        raise RuntimeError("Unexpected stage node count")
    assigned["node_normal.png"] = nodes[0]
    assigned["node_selected.png"] = nodes[1]
    assigned["node_locked.png"] = nodes[2]
    assigned["node_chest.png"] = nodes[3]
    assigned["node_crystal.png"] = nodes[4]

    low = sorted([c for c in comps if c["center"][1] >= 580], key=lambda c: c["center"][0])
    assigned["boss_badge.png"] = low[0]
    assigned["ui_reward_panel.png"] = low[1]

    for name, comp in assigned.items():
        save(crop(sheet, comp["bbox"], 12), name)


def make_arrow(name: str, direction: str):
    img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle((16, 16, 112, 112), radius=18, fill=(12, 31, 64, 255), outline=(95, 132, 170, 255), width=5)
    draw.rounded_rectangle((23, 23, 105, 105), radius=14, outline=(3, 12, 28, 180), width=3)
    fill = (255, 239, 205, 255)
    shadow = (49, 31, 18, 150)
    if direction == "left":
        pts = [(78, 34), (42, 64), (78, 94), (78, 73), (98, 73), (98, 55), (78, 55)]
    elif direction == "right":
        pts = [(50, 34), (86, 64), (50, 94), (50, 73), (30, 73), (30, 55), (50, 55)]
    else:
        pts = [(78, 34), (42, 64), (78, 94), (78, 73), (98, 73), (98, 55), (78, 55)]
    draw.polygon([(x + 2, y + 3) for x, y in pts], fill=shadow)
    draw.polygon(pts, fill=fill)
    save(img, name)


def make_contact_sheet():
    assets = sorted([p for p in FORMAL_DIR.glob("*.png") if p.name.startswith(("icon_", "node_", "ui_", "boss_"))])
    cols = 5
    cell_w, cell_h = 180, 150
    rows = (len(assets) + cols - 1) // cols
    out = Image.new("RGBA", (cols * cell_w, rows * cell_h), (18, 24, 42, 255))
    draw = ImageDraw.Draw(out)
    font = ImageFont.load_default()

    for i, path in enumerate(assets):
        img = Image.open(path).convert("RGBA")
        img.thumbnail((140, 105), Image.LANCZOS)
        x = (i % cols) * cell_w + (cell_w - img.width) // 2
        y = (i // cols) * cell_h + 8
        out.alpha_composite(img, (x, y))
        draw.text(((i % cols) * cell_w + 8, (i // cols) * cell_h + 122), path.stem[:22], fill=(255, 255, 255, 230), font=font)

    out.save(FORMAL_DIR / "stage_select_contact_sheet.png")


def main():
    split_icons()
    split_ui()
    make_arrow("icon_back_arrow.png", "left")
    make_arrow("icon_prev_arrow.png", "left")
    make_arrow("icon_next_arrow.png", "right")
    make_contact_sheet()


if __name__ == "__main__":
    main()
