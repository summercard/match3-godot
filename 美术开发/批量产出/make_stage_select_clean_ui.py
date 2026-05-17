#!/usr/bin/env python3
"""Create stable supplemental UI assets for the stage-map concept layout."""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
FORMAL_DIR = ROOT / "美术开发/正式拆分/stage_select"
RUNTIME_DIR = ROOT / "assets/images/stage"


def make_reward_panel():
    w, h = 700, 216
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.rounded_rectangle((18, 20, w - 18, h - 18), radius=28, fill=(29, 85, 165, 120))
    glow = glow.filter(ImageFilter.GaussianBlur(10))
    img.alpha_composite(glow)

    draw.rounded_rectangle((18, 20, w - 18, h - 18), radius=28, fill=(13, 31, 67, 245), outline=(73, 102, 150, 255), width=5)
    draw.rounded_rectangle((30, 32, w - 30, h - 30), radius=20, outline=(4, 13, 31, 180), width=4)
    draw.line((112, 58, 270, 58), fill=(92, 122, 174, 150), width=3)
    draw.line((w - 270, 58, w - 112, 58), fill=(92, 122, 174, 150), width=3)
    draw.polygon([(w / 2, 46), (w / 2 + 12, 58), (w / 2, 70), (w / 2 - 12, 58)], fill=(111, 159, 225, 220))

    slot_w, slot_h = 70, 96
    start_x = 50
    gap = 12
    for i in range(8):
        x = start_x + i * (slot_w + gap)
        draw.rounded_rectangle((x, 84, x + slot_w, 84 + slot_h), radius=10, fill=(34, 36, 88, 238), outline=(94, 77, 178, 230), width=4)

    return img.resize((350, 108), Image.LANCZOS)


def main():
    FORMAL_DIR.mkdir(parents=True, exist_ok=True)
    RUNTIME_DIR.mkdir(parents=True, exist_ok=True)
    panel = make_reward_panel()
    for folder in (FORMAL_DIR, RUNTIME_DIR):
        panel.save(folder / "ui_reward_panel_clean.png")
    print(f"ui_reward_panel_clean.png: {panel.size[0]}x{panel.size[1]}")


if __name__ == "__main__":
    main()
