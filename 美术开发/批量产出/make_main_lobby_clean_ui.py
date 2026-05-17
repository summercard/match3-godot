#!/usr/bin/env python3
"""Create clean supplemental UI assets for the main lobby top bar."""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
FORMAL_DIR = ROOT / "美术开发/正式拆分/main_lobby"
RUNTIME_DIR = ROOT / "assets/images/main"


def rounded(draw, box, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def make_player_panel():
    scale = 3
    w, h = 720, 210
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Soft outer glow.
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    rounded(gd, (48, 34, w - 32, h - 34), 48, (34, 142, 255, 90))
    glow = glow.filter(ImageFilter.GaussianBlur(14))
    img.alpha_composite(glow)

    # Gold frame and enamel body.
    rounded(draw, (52, 34, w - 34, h - 34), 42, (245, 178, 45, 255))
    rounded(draw, (64, 46, w - 46, h - 46), 34, (104, 57, 10, 255))
    rounded(draw, (72, 54, w - 54, h - 54), 28, (7, 94, 205, 255))
    rounded(draw, (82, 64, w - 64, h - 104), 22, (18, 152, 255, 210))

    # Left avatar medallion.
    draw.ellipse((6, 16, 186, 196), fill=(247, 188, 55, 255))
    draw.ellipse((20, 30, 172, 182), fill=(101, 55, 11, 255))
    draw.ellipse((30, 40, 162, 172), fill=(9, 98, 205, 255))

    # Gem accents.
    draw.polygon([(96, 0), (128, 34), (96, 70), (64, 34)], fill=(79, 211, 255, 255))
    draw.polygon([(96, 10), (118, 34), (96, 58), (74, 34)], fill=(17, 130, 243, 255))
    draw.polygon([(w - 82, 74), (w - 52, 104), (w - 82, 134), (w - 112, 104)], fill=(79, 211, 255, 255))
    draw.polygon([(w - 82, 84), (w - 62, 104), (w - 82, 124), (w - 102, 104)], fill=(17, 130, 243, 255))

    # EXP track inset.
    rounded(draw, (210, 142, w - 104, 168), 13, (5, 24, 62, 220))
    rounded(draw, (218, 148, w - 112, 162), 7, (20, 86, 170, 180))

    img = img.resize((w // scale, h // scale), Image.LANCZOS)
    return img


def main():
    FORMAL_DIR.mkdir(parents=True, exist_ok=True)
    RUNTIME_DIR.mkdir(parents=True, exist_ok=True)
    panel = make_player_panel()
    for folder in (FORMAL_DIR, RUNTIME_DIR):
      panel.save(folder / "ui_player_panel.png")
    print(f"ui_player_panel.png: {panel.size[0]}x{panel.size[1]}")


if __name__ == "__main__":
    main()
