#!/usr/bin/env python3
from __future__ import annotations

import shutil
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
EXTRACT_DIR = ROOT / "美术开发" / "元素提取" / "team"
FORMAL_DIR = ROOT / "美术开发" / "正式拆分" / "team"
RUNTIME_DIR = ROOT / "assets" / "images" / "team"
COMMON_MONSTER_DIR = ROOT / "assets" / "images" / "battle" / "monsters"
KEY = (255, 0, 255)


def ensure_dirs() -> None:
    for path in [
        EXTRACT_DIR,
        FORMAL_DIR / "ui",
        FORMAL_DIR / "monsters",
        FORMAL_DIR / "icons",
        RUNTIME_DIR,
        COMMON_MONSTER_DIR,
    ]:
        path.mkdir(parents=True, exist_ok=True)


def chroma_to_alpha(img: Image.Image) -> Image.Image:
    rgba = img.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            dist = abs(r - KEY[0]) + abs(g - KEY[1]) + abs(b - KEY[2])
            if dist < 70:
                pixels[x, y] = (r, g, b, 0)
            elif dist < 155:
                pixels[x, y] = (r, g, b, int(a * (dist - 70) / 85))
    return rgba


def trim_alpha(img: Image.Image, padding: int = 3) -> Image.Image:
    bbox = img.getchannel("A").getbbox()
    if bbox is None:
        return img
    left = max(0, bbox[0] - padding)
    top = max(0, bbox[1] - padding)
    right = min(img.width, bbox[2] + padding)
    bottom = min(img.height, bbox[3] + padding)
    return img.crop((left, top, right, bottom))


def crop_save(sheet: Image.Image, box: tuple[int, int, int, int], out_path: Path) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    asset = trim_alpha(chroma_to_alpha(sheet.crop(box)))
    asset.save(out_path)


def split_ui() -> None:
    sheet = Image.open(EXTRACT_DIR / "team_ui_image2_sheet.png")
    boxes = {
        "ui_back_button.png": (55, 40, 215, 175),
        "ui_header_bar.png": (315, 35, 1165, 165),
        "ui_help_button.png": (1310, 40, 1435, 170),
        "ui_leader_card.png": (60, 175, 525, 635),
        "ui_member_card.png": (545, 195, 855, 630),
        "ui_member_card_alt.png": (890, 195, 1205, 630),
        "ui_power_banner.png": (45, 655, 505, 770),
        "ui_leader_skill_banner.png": (520, 655, 1010, 770),
        "ui_filter_tab_selected.png": (1030, 685, 1235, 780),
        "ui_filter_tab_normal.png": (1270, 690, 1470, 780),
        "ui_sort_dropdown.png": (45, 815, 255, 905),
        "ui_roster_card.png": (280, 790, 445, 985),
        "ui_roster_card_selected.png": (460, 790, 630, 985),
        "ui_empty_slot.png": (640, 790, 790, 985),
        "ui_btn_cancel.png": (805, 825, 1075, 940),
        "ui_btn_save.png": (1095, 825, 1370, 940),
        "ui_btn_disassemble.png": (1375, 825, 1495, 940),
    }
    for name, box in boxes.items():
        crop_save(sheet, box, FORMAL_DIR / "ui" / name)
        shutil.copy2(FORMAL_DIR / "ui" / name, RUNTIME_DIR / name)


def split_icons() -> None:
    names = [
        "icon_power_swords.png",
        "icon_leader_crown.png",
        "icon_stat_hp.png",
        "icon_stat_atk.png",
        "icon_stat_def.png",
        "icon_stat_spd.png",
        "icon_element_fire_candidate.png",
        "icon_element_water_candidate.png",
        "icon_element_grass_candidate.png",
        "icon_check.png",
    ]
    sheet = Image.open(EXTRACT_DIR / "team_icons_image2_sheet.png")
    cell_w = sheet.width / 5.0
    cell_h = sheet.height / 2.0
    for i, name in enumerate(names):
        col = i % 5
        row = i // 5
        box = (
            int(col * cell_w),
            int(row * cell_h),
            int((col + 1) * cell_w),
            int((row + 1) * cell_h),
        )
        crop_save(sheet, box, FORMAL_DIR / "icons" / name)
        if not name.startswith("icon_element_"):
            shutil.copy2(FORMAL_DIR / "icons" / name, RUNTIME_DIR / name)


def split_monsters() -> None:
    runtime_common = {
        "monster_004_thunder_rodent_candidate.png": "monster_004_thunder_rodent.png",
        "monster_005_light_sprite_candidate.png": "monster_005_light_sprite.png",
        "monster_006_fire_dragon_candidate.png": "monster_006_fire_dragon.png",
        "monster_007_water_dragon_candidate.png": "monster_007_water_dragon.png",
        "monster_017_dark_cat_candidate.png": "monster_017_dark_cat.png",
    }
    names = [
        "monster_001_fire_lizard_candidate.png",
        "monster_002_water_turtle_candidate.png",
        "monster_003_grass_leaf_candidate.png",
        "monster_004_thunder_rodent_candidate.png",
        "monster_005_light_sprite_candidate.png",
        "monster_006_fire_dragon_candidate.png",
        "monster_007_water_dragon_candidate.png",
        "monster_017_dark_cat_candidate.png",
    ]
    sheet = Image.open(EXTRACT_DIR / "team_monsters_image2_sheet.png")
    cell_w = sheet.width / 4.0
    cell_h = sheet.height / 2.0
    for i, name in enumerate(names):
        col = i % 4
        row = i // 4
        box = (
            int(col * cell_w),
            int(row * cell_h),
            int((col + 1) * cell_w),
            int((row + 1) * cell_h),
        )
        formal_path = FORMAL_DIR / "monsters" / name
        crop_save(sheet, box, formal_path)
        if name in runtime_common:
            shutil.copy2(formal_path, COMMON_MONSTER_DIR / runtime_common[name])


def main() -> int:
    ensure_dirs()
    split_ui()
    split_icons()
    split_monsters()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
