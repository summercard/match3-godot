#!/usr/bin/env python3
"""Import image-2 start-screen extractions into formal and runtime folders."""

from __future__ import annotations

from pathlib import Path
from shutil import copy2

from PIL import Image, ImageEnhance, ImageOps


ROOT = Path(__file__).resolve().parents[2]
EXTRACT_DIR = ROOT / "美术开发/元素提取/start_screen_new_style"
ALPHA_DIR = EXTRACT_DIR / "image2_alpha"
RAW_DIR = EXTRACT_DIR / "image2_raw"
FORMAL_DIR = ROOT / "美术开发/正式拆分/start_screen_new_style"
RUNTIME_DIR = ROOT / "assets/images/start"


def save_both(image: Image.Image, filename: str) -> None:
    FORMAL_DIR.mkdir(parents=True, exist_ok=True)
    RUNTIME_DIR.mkdir(parents=True, exist_ok=True)
    image.save(FORMAL_DIR / filename)
    image.save(RUNTIME_DIR / filename)
    print(f"{filename}: {image.width}x{image.height}")


def trim_alpha(image: Image.Image, pad: int = 12) -> Image.Image:
    image = image.convert("RGBA")
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise RuntimeError("Cannot trim an entirely transparent asset")
    left, top, right, bottom = bbox
    return image.crop((
        max(0, left - pad),
        max(0, top - pad),
        min(image.width, right + pad),
        min(image.height, bottom + pad),
    ))


def make_button_states(button: Image.Image) -> None:
    save_both(button, "ui_btn_enter_game.png")
    save_both(button, "ui_btn_start_normal.png")

    rgb = button.convert("RGB")
    alpha = button.getchannel("A")

    pressed = ImageEnhance.Brightness(rgb).enhance(0.82).convert("RGBA")
    pressed.putalpha(alpha)
    save_both(pressed, "ui_btn_start_pressed.png")

    disabled_rgb = ImageEnhance.Brightness(ImageOps.grayscale(rgb).convert("RGB")).enhance(0.96)
    disabled = disabled_rgb.convert("RGBA")
    disabled.putalpha(alpha.point(lambda value: int(value * 0.74)))
    save_both(disabled, "ui_btn_start_disabled.png")


def main() -> None:
    background_source = RAW_DIR / "start_bg_village_fountain_image2.png"
    background = Image.open(background_source).convert("RGB")
    save_both(background, "start_bg_grassland.png")

    assets = {
        "start_logo.png": "start_title_logo.png",
        "monster_fire_village.png": "monster_fire_lizard.png",
        "monster_water_village.png": "monster_water_cub.png",
        "monster_grass_village.png": "monster_grass_leaf.png",
    }
    for source_name, target_name in assets.items():
        save_both(trim_alpha(Image.open(ALPHA_DIR / source_name)), target_name)

    button = trim_alpha(Image.open(ALPHA_DIR / "ui_btn_enter_game.png"))
    make_button_states(button)

    copy2(background_source, FORMAL_DIR / "start_bg_village_fountain_image2_source.png")
    print("Imported start-screen image-2 assets.")


if __name__ == "__main__":
    main()
