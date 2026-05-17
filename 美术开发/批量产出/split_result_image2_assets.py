#!/usr/bin/env python3
from __future__ import annotations

import shutil
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
EXTRACT_DIR = ROOT / "美术开发" / "元素提取" / "result"
FORMAL_DIR = ROOT / "美术开发" / "正式拆分" / "result"
RUNTIME_DIR = ROOT / "assets" / "images" / "result"
KEY = (255, 0, 255)


def ensure_dirs() -> None:
    for path in [
        EXTRACT_DIR,
        FORMAL_DIR / "ui",
        FORMAL_DIR / "gems",
        FORMAL_DIR / "monsters",
        FORMAL_DIR / "effects",
        RUNTIME_DIR,
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
            elif dist < 150:
                pixels[x, y] = (r, g, b, int(a * (dist - 70) / 80))
    return rgba


def trim_alpha(img: Image.Image, padding: int = 3) -> Image.Image:
    alpha = img.getchannel("A")
    bbox = alpha.getbbox()
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
    sheet = Image.open(EXTRACT_DIR / "result_ui_image2_sheet.png")
    boxes = {
        "ui_victory_banner.png": (45, 35, 760, 320),
        "ui_defeat_banner.png": (785, 45, 1490, 300),
        "ui_reward_panel.png": (35, 345, 565, 665),
        "ui_team_exp_panel.png": (570, 350, 1085, 635),
        "ui_reward_slot.png": (1085, 360, 1285, 625),
        "ui_monster_exp_card.png": (1300, 355, 1495, 640),
        "ui_btn_next.png": (55, 695, 455, 835),
        "ui_btn_secondary.png": (485, 690, 825, 825),
        "ui_btn_retry.png": (830, 695, 1155, 820),
        "ui_capture_plaque.png": (1160, 685, 1490, 835),
        "fx_levelup_glow.png": (160, 815, 805, 910),
        "ui_info_chip.png": (955, 835, 1325, 950),
    }
    for name, box in boxes.items():
        crop_save(sheet, box, FORMAL_DIR / "ui" / name)

    runtime_names = {
        "ui_victory_banner.png",
        "ui_defeat_banner.png",
        "ui_reward_panel.png",
        "ui_team_exp_panel.png",
        "ui_reward_slot.png",
        "ui_monster_exp_card.png",
        "ui_btn_next.png",
        "ui_btn_secondary.png",
        "ui_btn_retry.png",
        "ui_capture_plaque.png",
        "ui_info_chip.png",
    }
    for name in runtime_names:
        shutil.copy2(FORMAL_DIR / "ui" / name, RUNTIME_DIR / name)
    shutil.copy2(FORMAL_DIR / "ui" / "fx_levelup_glow.png", FORMAL_DIR / "effects" / "fx_levelup_glow.png")
    shutil.copy2(FORMAL_DIR / "ui" / "fx_levelup_glow.png", RUNTIME_DIR / "fx_levelup_glow.png")


def split_rewards() -> None:
    sheet = Image.open(EXTRACT_DIR / "result_gems_rewards_image2_sheet.png")
    boxes = {
        "icon_gold_crown_coin_candidate.png": (70, 120, 285, 335),
        "icon_exp_badge_candidate.png": (435, 120, 650, 335),
        "icon_blue_diamond_candidate.png": (760, 120, 1025, 350),
        "gem_fire_candidate.png": (1120, 110, 1340, 350),
        "gem_grass_candidate.png": (1465, 100, 1700, 350),
        "icon_capture_potion_candidate.png": (70, 485, 350, 765),
        "icon_star_lit_large.png": (460, 495, 705, 755),
        "icon_star_dim_large.png": (745, 485, 990, 765),
        "fx_confetti_cluster.png": (1085, 500, 1375, 735),
        "icon_sweep_badge.png": (1440, 470, 1710, 750),
    }
    for name, box in boxes.items():
        target_dir = "effects" if name.startswith("fx_") else "gems"
        crop_save(sheet, box, FORMAL_DIR / target_dir / name)

    for name in ["icon_star_lit_large.png", "icon_star_dim_large.png", "icon_sweep_badge.png"]:
        shutil.copy2(FORMAL_DIR / "gems" / name, RUNTIME_DIR / name)
    shutil.copy2(FORMAL_DIR / "effects" / "fx_confetti_cluster.png", RUNTIME_DIR / "fx_confetti_cluster.png")


def split_monsters_fx() -> None:
    sheet = Image.open(EXTRACT_DIR / "result_monsters_fx_image2_sheet.png")
    boxes = {
        "monster_boss_001_flower_result_candidate.png": (175, 35, 625, 395),
        "fx_victory_burst.png": (790, 35, 1340, 395),
        "monster_001_fire_lizard_result_candidate.png": (75, 425, 380, 690),
        "monster_002_water_cub_result_candidate.png": (465, 425, 740, 690),
        "monster_003_grass_leaf_result_candidate.png": (790, 425, 1040, 690),
        "monster_thunder_fox_result_candidate.png": (1130, 425, 1425, 705),
        "monster_dark_cat_result_candidate.png": (340, 720, 650, 1005),
        "fx_capture_ring.png": (760, 715, 1245, 965),
    }
    for name, box in boxes.items():
        target_dir = "effects" if name.startswith("fx_") else "monsters"
        crop_save(sheet, box, FORMAL_DIR / target_dir / name)

    for name in ["fx_victory_burst.png", "fx_capture_ring.png"]:
        shutil.copy2(FORMAL_DIR / "effects" / name, RUNTIME_DIR / name)


def main() -> int:
    ensure_dirs()
    split_ui()
    split_rewards()
    split_monsters_fx()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
