#!/usr/bin/env python3
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import math
import shutil

ROOT = Path(__file__).resolve().parents[2]
EXTRACT = ROOT / "美术开发" / "元素提取" / "tutorial"
SPLIT = ROOT / "美术开发" / "正式拆分" / "tutorial"
RUNTIME = ROOT / "assets" / "images" / "tutorial"


def ensure_dirs():
    for path in [
        EXTRACT,
        SPLIT / "ui",
        SPLIT / "effects",
        SPLIT / "icons",
        RUNTIME,
    ]:
        path.mkdir(parents=True, exist_ok=True)


def glow_layer(size, draw_fn, blur=8, color=(255, 214, 94, 180)):
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    draw_fn(d, color)
    return layer.filter(ImageFilter.GaussianBlur(blur))


def plaque(size=(248, 68), fill=(13, 31, 58, 245), outline=(246, 202, 96, 255), leaf=True):
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    w, h = size
    points = [
        (20, 8), (w - 20, 8), (w - 8, 20), (w - 8, h - 18),
        (w - 20, h - 8), (20, h - 8), (8, h - 20), (8, 20),
    ]
    img.alpha_composite(glow_layer(size, lambda d, c: d.line(points + [points[0]], fill=c, width=5), 5))
    d = ImageDraw.Draw(img)
    d.polygon(points, fill=fill)
    for offset, col, width in [(0, outline, 4), (5, (58, 102, 156, 210), 2)]:
        p = [(x + (offset if x < w / 2 else -offset), y + (offset if y < h / 2 else -offset)) for x, y in points]
        d.line(p + [p[0]], fill=col, width=width, joint="curve")
    if leaf:
        for sx in [20, w - 20]:
            side = -1 if sx < w / 2 else 1
            for i in range(3):
                cx = sx + side * (8 + i * 8)
                cy = 30 + i * 5
                d.ellipse((cx - 7, cy - 4, cx + 7, cy + 4), fill=(84, 176, 82, 230), outline=(31, 93, 46, 255))
    return img


def panel(size=(336, 118), parchment=True):
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    w, h = size
    d = ImageDraw.Draw(img)
    radius = 18
    fill = (255, 239, 194, 250) if parchment else (11, 29, 57, 246)
    outline = (248, 204, 106, 255)
    shadow = Image.new("RGBA", size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((8, 8, w - 8, h - 8), radius=radius, fill=(0, 0, 0, 150))
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(7)))
    d.rounded_rectangle((6, 5, w - 6, h - 6), radius=radius, fill=fill, outline=outline, width=4)
    d.rounded_rectangle((13, 12, w - 13, h - 13), radius=radius - 6, outline=(120, 82, 35, 135) if parchment else (72, 119, 176, 180), width=2)
    for x, y in [(14, 15), (w - 24, 15), (14, h - 25), (w - 24, h - 25)]:
        d.polygon([(x, y + 5), (x + 5, y), (x + 10, y + 5), (x + 5, y + 10)], fill=outline)
    return img


def button(size=(158, 60), kind="next"):
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    w, h = size
    if kind == "skip":
        fill1, fill2 = (34, 89, 176, 255), (12, 45, 96, 255)
    else:
        fill1, fill2 = (255, 196, 54, 255), (171, 104, 18, 255)
    outline = (255, 240, 166, 255)
    img.alpha_composite(glow_layer(size, lambda d, c: d.rounded_rectangle((7, 7, w - 7, h - 7), 8, outline=c, width=6), 5))
    d = ImageDraw.Draw(img)
    for y in range(8, h - 8):
        t = (y - 8) / max(1, h - 16)
        col = tuple(int(fill1[i] * (1 - t) + fill2[i] * t) for i in range(4))
        d.line((12, y, w - 12, y), fill=col, width=1)
    d.rounded_rectangle((8, 7, w - 8, h - 8), radius=9, outline=(111, 64, 20, 255), width=5)
    d.rounded_rectangle((12, 11, w - 12, h - 12), radius=6, outline=outline, width=3)
    if kind == "next":
        d.polygon([(w - 39, h / 2 - 12), (w - 19, h / 2), (w - 39, h / 2 + 12)], fill=(255, 248, 210, 255), outline=(126, 78, 23, 255))
    return img


def highlight(size=(238, 70), color=(255, 224, 95, 255)):
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    w, h = size
    def draw_box(d, c):
        d.rounded_rectangle((8, 8, w - 8, h - 8), radius=8, outline=c, width=6)
    img.alpha_composite(glow_layer(size, draw_box, 9, (255, 223, 79, 210)))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((8, 8, w - 8, h - 8), radius=8, outline=color, width=4)
    for x in [8, w - 8]:
        for y in [8, h - 8]:
            d.ellipse((x - 4, y - 4, x + 4, y + 4), fill=(255, 255, 235, 255))
    return img


def arrow(size=(130, 58)):
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    w, h = size
    pts = [(12, h / 2 - 11), (w - 45, h / 2 - 11), (w - 45, h / 2 - 23), (w - 12, h / 2), (w - 45, h / 2 + 23), (w - 45, h / 2 + 11), (12, h / 2 + 11)]
    img.alpha_composite(glow_layer(size, lambda d, c: d.polygon(pts, fill=c), 8, (255, 228, 107, 190)))
    d = ImageDraw.Draw(img)
    d.polygon(pts, fill=(255, 238, 160, 255), outline=(181, 113, 30, 255))
    d.line((20, h / 2 - 2, w - 52, h / 2 - 2), fill=(255, 255, 255, 210), width=4)
    return img


def hand(size=(104, 122)):
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    skin = (255, 230, 184, 255)
    shade = (187, 132, 76, 255)
    d.ellipse((30, 30, 76, 84), fill=skin, outline=shade, width=3)
    d.rounded_rectangle((55, 12, 76, 70), radius=10, fill=skin, outline=shade, width=3)
    d.rounded_rectangle((42, 40, 60, 94), radius=9, fill=skin, outline=shade, width=2)
    d.rounded_rectangle((25, 48, 44, 92), radius=9, fill=skin, outline=shade, width=2)
    d.rounded_rectangle((12, 60, 32, 96), radius=9, fill=skin, outline=shade, width=2)
    d.rounded_rectangle((43, 86, 88, 112), radius=12, fill=(227, 177, 93, 255), outline=(117, 71, 30, 255), width=3)
    d.arc((48, 90, 84, 112), 0, 180, fill=(255, 236, 152, 255), width=3)
    return img.filter(ImageFilter.GaussianBlur(0.2))


def target_card(size=(104, 140)):
    img = plaque(size, fill=(10, 28, 56, 248), outline=(236, 181, 92, 255), leaf=False)
    d = ImageDraw.Draw(img)
    w, h = size
    d.line((24, 44, w - 24, 44), fill=(118, 139, 170, 210), width=2)
    return img


def dot(active=True, size=(22, 22)):
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    col = (255, 207, 68, 255) if active else (164, 151, 118, 255)
    d.ellipse((3, 3, size[0] - 3, size[1] - 3), fill=col, outline=(51, 42, 30, 255), width=2)
    if active:
        d.ellipse((7, 6, 12, 11), fill=(255, 255, 230, 230))
    return img


def dotted_path(size=(116, 82)):
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for i in range(13):
        t = i / 12
        x = 10 + t * 96
        y = 60 - math.sin(t * math.pi) * 45
        r = 3 + 2 * t
        d.ellipse((x - r, y - r, x + r, y + r), fill=(255, 218, 93, 235))
    return img.filter(ImageFilter.GaussianBlur(0.15))


def save_assets():
    assets = {
        "ui/ui_tutorial_header.png": plaque((260, 72)),
        "ui/ui_tutorial_prompt_panel.png": panel((336, 124), True),
        "ui/ui_tutorial_prompt_dark.png": panel((232, 70), False),
        "ui/ui_next_button.png": button((160, 62), "next"),
        "ui/ui_skip_button.png": button((92, 44), "skip"),
        "ui/ui_target_card.png": target_card((104, 140)),
        "ui/ui_step_dot_active.png": dot(True),
        "ui/ui_step_dot_inactive.png": dot(False),
        "effects/fx_highlight_frame.png": highlight((238, 70)),
        "effects/fx_swipe_arrow.png": arrow((132, 60)),
        "effects/fx_dotted_path.png": dotted_path((118, 84)),
        "icons/icon_hand_pointer.png": hand((104, 122)),
    }
    for rel, img in assets.items():
        out = SPLIT / rel
        out.parent.mkdir(parents=True, exist_ok=True)
        img.save(out)
        shutil.copy2(out, RUNTIME / out.name)

    sheet = Image.new("RGBA", (760, 700), (36, 86, 82, 255))
    d = ImageDraw.Draw(sheet)
    x, y = 24, 24
    for rel, img in assets.items():
        if x + img.width > sheet.width - 24:
            x = 24
            y += 150
        sheet.alpha_composite(img, (x, y))
        d.text((x, y + img.height + 4), Path(rel).stem, fill=(235, 246, 255, 255))
        x += img.width + 28
    sheet.save(EXTRACT / "tutorial_ui_effects_image2_sheet.png")


def main():
    ensure_dirs()
    save_assets()


if __name__ == "__main__":
    main()
