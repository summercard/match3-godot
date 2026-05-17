#!/usr/bin/env python3
"""Split main-lobby image-2 sheets into named runtime assets."""

from pathlib import Path
from collections import deque
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
FORMAL_DIR = ROOT / "美术开发/正式拆分/main_lobby"
RUNTIME_DIR = ROOT / "assets/images/main"
ICON_SHEET = FORMAL_DIR / "main_lobby_icon_sheet_alpha.png"
UI_SHEET = FORMAL_DIR / "main_lobby_ui_sheet_alpha.png"

ICON_ROWS = [
    ["icon_start_adventure.png", "icon_team.png", "icon_album.png", "icon_signin.png"],
    ["icon_shop.png", "icon_inventory.png", "icon_ranch.png", "icon_achievement.png"],
    ["icon_settings.png", "icon_avatar.png", "icon_gold.png", "icon_diamond.png"],
    ["icon_exp_star.png"],
]


def find_components(img: Image.Image, min_pixels=500):
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


def crop(img: Image.Image, bbox, pad=12):
    w, h = img.size
    left, top, right, bottom = bbox
    return img.crop((
        max(0, left - pad),
        max(0, top - pad),
        min(w, right + pad),
        min(h, bottom + pad),
    ))


def save_asset(img: Image.Image, name: str):
    FORMAL_DIR.mkdir(parents=True, exist_ok=True)
    RUNTIME_DIR.mkdir(parents=True, exist_ok=True)
    formal = FORMAL_DIR / name
    runtime = RUNTIME_DIR / name
    img.save(formal)
    img.save(runtime)
    print(f"{name}: {img.size[0]}x{img.size[1]}")


def split_icons():
    sheet = Image.open(ICON_SHEET).convert("RGBA")
    components = find_components(sheet)
    if len(components) != 13:
        raise RuntimeError(f"Expected 13 lobby icons, got {len(components)}")

    rows = [
        sorted([c for c in components if c["center"][1] < 400], key=lambda c: c["center"][0]),
        sorted([c for c in components if 400 <= c["center"][1] < 700], key=lambda c: c["center"][0]),
        sorted([c for c in components if 700 <= c["center"][1] < 1000], key=lambda c: c["center"][0]),
        sorted([c for c in components if c["center"][1] >= 1000], key=lambda c: c["center"][0]),
    ]

    for expected, actual in zip(ICON_ROWS, rows):
        if len(expected) != len(actual):
            raise RuntimeError("Unexpected lobby icon row layout")
        for name, comp in zip(expected, actual):
            save_asset(crop(sheet, comp["bbox"], 10), name)


def split_ui():
    sheet = Image.open(UI_SHEET).convert("RGBA")
    components = find_components(sheet)
    if len(components) != 9:
        raise RuntimeError(f"Expected 9 lobby UI components, got {len(components)}")

    big_cards = sorted([c for c in components if c["count"] > 120000], key=lambda c: c["center"][0])
    navs = sorted([c for c in components if 20000 < c["count"] < 32000 and c["center"][1] > 700], key=lambda c: c["center"][0])
    wide = sorted([c for c in components if c not in big_cards and c not in navs], key=lambda c: c["count"], reverse=True)

    if len(big_cards) != 2 or len(navs) != 4 or len(wide) != 3:
        raise RuntimeError("Unexpected lobby UI component groups")

    assignments = [
        ("ui_card_primary.png", big_cards[0]),
        ("ui_card_primary_pressed.png", big_cards[1]),
        ("ui_nav_frame.png", navs[0]),
        ("ui_nav_frame_pressed.png", navs[1]),
        ("ui_nav_frame_disabled.png", navs[2]),
        ("ui_nav_frame_alt.png", navs[3]),
        ("ui_info_panel.png", wide[0]),
        ("ui_title_plaque.png", wide[1]),
        ("ui_currency_capsule.png", wide[2]),
    ]

    for name, comp in assignments:
        save_asset(crop(sheet, comp["bbox"], 12), name)


def make_contact_sheet():
    assets = sorted([p for p in FORMAL_DIR.glob("*.png") if p.name.startswith(("icon_", "ui_"))])
    thumb_w, thumb_h = 140, 120
    cols = 5
    rows = (len(assets) + cols - 1) // cols
    out = Image.new("RGBA", (cols * 180, rows * 160), (18, 24, 42, 255))
    draw = ImageDraw.Draw(out)
    font = ImageFont.load_default()

    for i, path in enumerate(assets):
        img = Image.open(path).convert("RGBA")
        img.thumbnail((thumb_w, thumb_h), Image.LANCZOS)
        x = (i % cols) * 180 + (180 - img.width) // 2
        y = (i // cols) * 160 + 8
        out.alpha_composite(img, (x, y))
        draw.text(((i % cols) * 180 + 8, (i // cols) * 160 + 132), path.stem[:22], fill=(255, 255, 255, 230), font=font)

    out.save(FORMAL_DIR / "main_lobby_contact_sheet.png")


def main():
    split_icons()
    split_ui()
    make_contact_sheet()


if __name__ == "__main__":
    main()
