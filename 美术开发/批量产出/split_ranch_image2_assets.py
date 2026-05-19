#!/usr/bin/env python3
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SRC_DIR = ROOT / "美术开发" / "元素提取" / "ranch"
FORMAL = ROOT / "美术开发" / "正式拆分" / "ranch"
RUNTIME = ROOT / "assets" / "images" / "ranch"

UI_SHEET = SRC_DIR / "ranch_ui_icons_image2_sheet.png"
BG_SRC = SRC_DIR / "ranch_background_image2.png"

MAGENTA = (255, 0, 255)


def chroma_alpha(img: Image.Image) -> Image.Image:
    rgba = img.convert("RGBA")
    px = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, a = px[x, y]
            if abs(r - MAGENTA[0]) < 18 and g < 32 and abs(b - MAGENTA[2]) < 18:
                px[x, y] = (255, 0, 255, 0)
    return rgba


def trim_alpha(img: Image.Image, pad: int = 4) -> Image.Image:
    bbox = img.getbbox()
    if not bbox:
        return img
    l, t, r, b = bbox
    l = max(0, l - pad)
    t = max(0, t - pad)
    r = min(img.width, r + pad)
    b = min(img.height, b + pad)
    return img.crop((l, t, r, b))


def crop_asset(sheet: Image.Image, name: str, box: tuple[int, int, int, int], category: str, runtime: bool = True) -> None:
    out = trim_alpha(chroma_alpha(sheet.crop(box)))
    formal_path = FORMAL / category / f"{name}.png"
    formal_path.parent.mkdir(parents=True, exist_ok=True)
    out.save(formal_path)
    if runtime:
        runtime_path = RUNTIME / f"{name}.png"
        runtime_path.parent.mkdir(parents=True, exist_ok=True)
        out.save(runtime_path)


def save_background() -> None:
    bg = Image.open(BG_SRC).convert("RGBA")
    formal_path = FORMAL / "background" / "bg_ranch_pasture.png"
    runtime_path = RUNTIME / "bg_ranch_pasture.png"
    formal_path.parent.mkdir(parents=True, exist_ok=True)
    runtime_path.parent.mkdir(parents=True, exist_ok=True)
    bg.save(formal_path)
    bg.save(runtime_path)


def main() -> None:
    sheet = Image.open(UI_SHEET)
    assets = [
        ("ui_header_plaque", (125, 38, 828, 207), "ui"),
        ("ui_back_button", (940, 45, 1128, 190), "ui"),
        ("ui_slot_occupied", (95, 230, 645, 505), "ui"),
        ("ui_slot_empty", (742, 235, 1235, 535), "ui"),
        ("ui_income_panel", (84, 545, 700, 675), "ui"),
        ("ui_monster_list_panel", (754, 538, 1370, 733), "ui"),
        ("ui_btn_collect_gold", (75, 703, 365, 824), "ui"),
        ("ui_status_ribbon_green", (407, 719, 721, 807), "ui"),
        ("ui_reward_strip_dark", (758, 739, 1103, 818), "ui"),
        ("icon_exp_badge", (88, 835, 228, 974), "icons"),
        ("icon_gold_coin", (301, 843, 436, 964), "icons"),
        ("icon_check_badge", (505, 844, 638, 976), "icons"),
        ("ui_banner_small", (699, 840, 817, 975), "ui"),
        ("ui_banner_fringe", (850, 839, 976, 980), "ui"),
        ("fx_leaf_sparkle_cluster", (997, 805, 1393, 970), "effects"),
    ]
    for name, box, category in assets:
        crop_asset(sheet, name, box, category)
    save_background()
    print(f"split ranch assets -> {RUNTIME}")


if __name__ == "__main__":
    main()
