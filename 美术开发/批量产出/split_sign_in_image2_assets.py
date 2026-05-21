#!/usr/bin/env python3
from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
SRC_DIR = ROOT / "美术开发" / "元素提取" / "sign_in"
SPLIT_DIR = ROOT / "美术开发" / "正式拆分" / "sign_in"
RUNTIME_DIR = ROOT / "assets" / "images" / "sign_in"

UI_SRC = SRC_DIR / "sign_in_ui_image2_sheet.png"
REWARD_SRC = SRC_DIR / "sign_in_rewards_image2_sheet.png"

UI_CROPS = {
    "ui/header_bar.png": (170, 35, 910, 190),
    "ui/back_button.png": (25, 168, 175, 314),
    "ui/day_card.png": (25, 335, 252, 715),
    "ui/day_card_alt.png": (285, 335, 505, 715),
    "ui/day_card_today.png": (512, 322, 763, 720),
    "ui/day_card_locked.png": (778, 335, 1002, 715),
    "ui/month_panel.png": (24, 748, 1000, 1002),
    "ui/month_ribbon.png": (220, 1030, 815, 1128),
    "ui/claim_button.png": (245, 1135, 826, 1248),
    "ui/stamp_claimed.png": (18, 1268, 205, 1398),
    "ui/today_tag.png": (278, 1302, 432, 1382),
    "ui/progress_bar.png": (485, 1308, 1000, 1368),
    "ui/warning_badge.png": (448, 1405, 538, 1496),
}

REWARD_CROPS = {
    "rewards/icon_gold_coin.png": (82, 34, 315, 230),
    "rewards/icon_exp_badge.png": (425, 48, 610, 235),
    "rewards/icon_gem_water.png": (700, 28, 880, 240),
    "rewards/icon_gem_fire.png": (955, 38, 1125, 242),
    "rewards/icon_potion_heart.png": (1225, 38, 1410, 238),
    "rewards/icon_chest_large.png": (62, 300, 360, 540),
    "rewards/icon_chest_7.png": (420, 320, 595, 512),
    "rewards/icon_chest_14.png": (682, 320, 865, 512),
    "rewards/icon_chest_21.png": (950, 312, 1132, 515),
    "rewards/icon_chest_28.png": (1205, 305, 1470, 545),
    "rewards/icon_diamond.png": (108, 575, 300, 750),
    "rewards/icon_gem_pile.png": (382, 585, 604, 750),
    "rewards/icon_coin_pile.png": (705, 535, 940, 710),
    "rewards/mascot_leaf.png": (1085, 512, 1440, 895),
    "rewards/icon_calendar_star.png": (70, 748, 318, 1012),
    "effects/fx_sparkles.png": (495, 746, 826, 965),
    "rewards/icon_check_badge.png": (925, 755, 1088, 920),
}


def is_checker_pixel(px):
    r, g, b = px[:3]
    if max(r, g, b) - min(r, g, b) > 10:
        return False
    return (r + g + b) / 3 >= 218


def remove_edge_checker(img):
    rgba = img.convert("RGBA")
    pix = rgba.load()
    w, h = rgba.size
    visited = set()
    q = deque()
    for x in range(w):
        q.append((x, 0))
        q.append((x, h - 1))
    for y in range(h):
        q.append((0, y))
        q.append((w - 1, y))
    while q:
        x, y = q.popleft()
        if x < 0 or y < 0 or x >= w or y >= h or (x, y) in visited:
            continue
        visited.add((x, y))
        if not is_checker_pixel(pix[x, y]):
            continue
        pix[x, y] = (255, 255, 255, 0)
        q.append((x + 1, y))
        q.append((x - 1, y))
        q.append((x, y + 1))
        q.append((x, y - 1))
    return trim_alpha(rgba)


def trim_alpha(img, pad=4):
    bbox = img.getbbox()
    if bbox is None:
        return img
    x1, y1, x2, y2 = bbox
    x1 = max(0, x1 - pad)
    y1 = max(0, y1 - pad)
    x2 = min(img.size[0], x2 + pad)
    y2 = min(img.size[1], y2 + pad)
    return img.crop((x1, y1, x2, y2))


def save_asset(src, box, rel):
    out_split = SPLIT_DIR / rel
    out_run = RUNTIME_DIR / Path(rel).name
    out_split.parent.mkdir(parents=True, exist_ok=True)
    RUNTIME_DIR.mkdir(parents=True, exist_ok=True)
    img = Image.open(src).crop(box)
    img = remove_edge_checker(img)
    img.save(out_split)
    img.save(out_run)
    return out_split, out_run


def make_disabled_button():
    src = SPLIT_DIR / "ui" / "claim_button.png"
    if not src.exists():
        return
    img = Image.open(src).convert("RGBA")
    gray = ImageEnhance.Color(img).enhance(0.15)
    gray = ImageEnhance.Brightness(gray).enhance(0.62)
    gray.save(SPLIT_DIR / "ui" / "claim_button_disabled.png")
    gray.save(RUNTIME_DIR / "claim_button_disabled.png")


def make_background():
    w, h = 375, 667
    bg = Image.new("RGBA", (w, h), (0, 0, 0, 255))
    draw = ImageDraw.Draw(bg)
    for y in range(h):
        t = y / h
        if y < 270:
            r = int(28 + 22 * t)
            g = int(78 + 75 * t)
            b = int(152 + 68 * t)
        else:
            k = (y - 270) / (h - 270)
            r = int(29 - 13 * k)
            g = int(86 - 42 * k)
            b = int(90 - 42 * k)
        draw.line((0, y, w, y), fill=(r, g, b, 255))
    # distant hills and trees
    draw.polygon([(0, 188), (55, 145), (118, 190), (190, 136), (270, 194), (375, 150), (375, 305), (0, 305)], fill=(40, 98, 104, 190))
    draw.polygon([(0, 238), (60, 206), (150, 226), (230, 204), (375, 242), (375, 360), (0, 360)], fill=(42, 122, 72, 210))
    for x in range(-20, 390, 34):
        draw.polygon([(x, 310), (x + 18, 248), (x + 36, 310)], fill=(26, 92, 60, 210))
        draw.rectangle((x + 15, 306, x + 21, 342), fill=(42, 65, 44, 220))
    # soft card backdrop vignette
    vignette = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    vd.rectangle((0, 0, w, 115), fill=(5, 18, 42, 150))
    vd.rectangle((0, 450, w, h), fill=(5, 18, 42, 135))
    vd.rectangle((0, 0, 18, h), fill=(5, 18, 42, 145))
    vd.rectangle((w - 18, 0, w, h), fill=(5, 18, 42, 145))
    bg = Image.alpha_composite(bg, vignette)
    # sparse sparkles
    for x, y, c in [(292, 126, (255, 232, 120)), (318, 160, (255, 255, 210)), (48, 178, (180, 230, 255)), (335, 84, (255, 220, 120))]:
        draw = ImageDraw.Draw(bg)
        draw.line((x - 5, y, x + 5, y), fill=(*c, 210), width=1)
        draw.line((x, y - 5, x, y + 5), fill=(*c, 210), width=1)
    bg = bg.filter(ImageFilter.GaussianBlur(0.15))
    (SPLIT_DIR / "ui").mkdir(parents=True, exist_ok=True)
    RUNTIME_DIR.mkdir(parents=True, exist_ok=True)
    bg.save(SPLIT_DIR / "ui" / "bg_sign_in.png")
    bg.save(RUNTIME_DIR / "bg_sign_in.png")


def main():
    for folder in [SPLIT_DIR / "ui", SPLIT_DIR / "rewards", SPLIT_DIR / "effects", RUNTIME_DIR]:
        folder.mkdir(parents=True, exist_ok=True)
    for rel, box in UI_CROPS.items():
        save_asset(UI_SRC, box, rel)
    for rel, box in REWARD_CROPS.items():
        save_asset(REWARD_SRC, box, rel)
    make_disabled_button()
    make_background()
    print(f"sign_in assets split to {SPLIT_DIR} and {RUNTIME_DIR}")


if __name__ == "__main__":
    main()
