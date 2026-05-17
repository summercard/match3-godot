#!/usr/bin/env python3
"""Create start button runtime states from the current art-approved base button."""

from pathlib import Path
from PIL import Image, ImageEnhance, ImageOps

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "assets/images/start/ui_btn_start.png"
FORMAL_DIR = ROOT / "美术开发/正式拆分/start_screen"
RUNTIME_DIR = ROOT / "assets/images/start"


def save_both(img: Image.Image, filename: str):
    FORMAL_DIR.mkdir(parents=True, exist_ok=True)
    RUNTIME_DIR.mkdir(parents=True, exist_ok=True)
    img.save(FORMAL_DIR / filename)
    img.save(RUNTIME_DIR / filename)
    print(f"{filename}: {img.size[0]}x{img.size[1]}")


def main():
    base = Image.open(BASE).convert("RGBA")
    rgb = base.convert("RGB")
    alpha = base.getchannel("A")

    normal = base

    pressed_rgb = ImageEnhance.Brightness(rgb).enhance(0.78)
    pressed_rgb = ImageEnhance.Contrast(pressed_rgb).enhance(1.08)
    pressed = pressed_rgb.convert("RGBA")
    pressed.putalpha(alpha)

    gray = ImageOps.grayscale(rgb).convert("RGB")
    disabled_rgb = ImageEnhance.Brightness(gray).enhance(0.92)
    disabled_rgb = ImageEnhance.Contrast(disabled_rgb).enhance(0.82)
    disabled = disabled_rgb.convert("RGBA")
    disabled.putalpha(alpha.point(lambda value: int(value * 0.78)))

    save_both(normal, "ui_btn_start_normal.png")
    save_both(pressed, "ui_btn_start_pressed.png")
    save_both(disabled, "ui_btn_start_disabled.png")


if __name__ == "__main__":
    main()
