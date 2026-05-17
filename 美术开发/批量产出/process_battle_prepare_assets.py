from pathlib import Path
from PIL import Image, ImageDraw
import shutil


ROOT = Path(__file__).resolve().parents[2]
CONCEPT_DIR = ROOT / "美术开发" / "概念图"
EXTRACT_DIR = ROOT / "美术开发" / "元素提取" / "battle_prepare"
CROP_DIR = ROOT / "美术开发" / "资产拆分" / "07_battle_prepare"
FORMAL_DIR = ROOT / "美术开发" / "正式拆分" / "battle_prepare"
RUNTIME_DIR = ROOT / "assets" / "images" / "battle_prepare"


def ensure_dirs() -> None:
    for path in (EXTRACT_DIR, CROP_DIR, FORMAL_DIR, RUNTIME_DIR):
        path.mkdir(parents=True, exist_ok=True)


def rounded_panel(size, fill, border, radius=18, border_width=3, inner=None):
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    rect = (border_width // 2, border_width // 2, size[0] - border_width // 2 - 1, size[1] - border_width // 2 - 1)
    d.rounded_rectangle(rect, radius=radius, fill=fill, outline=border, width=border_width)
    if inner:
        inset = border_width + 3
        d.rounded_rectangle((inset, inset, size[0] - inset - 1, size[1] - inset - 1), radius=max(radius - 5, 4), outline=inner, width=1)
    return img


def button(size, fill, border, glow=None):
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if glow:
        d.rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=18, fill=glow)
        inset = 4
    else:
        inset = 0
    d.rounded_rectangle((inset, inset, size[0] - inset - 1, size[1] - inset - 1), radius=14, fill=fill, outline=border, width=3)
    d.rounded_rectangle((inset + 5, inset + 4, size[0] - inset - 6, inset + 18), radius=8, fill=(255, 255, 255, 32))
    return img


def icon_sword(size=(64, 64)):
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    w, h = size
    d.line((18, 48, 47, 19), fill=(255, 230, 122, 255), width=8)
    d.line((18, 48, 47, 19), fill=(110, 190, 255, 255), width=4)
    d.polygon([(44, 15), (54, 10), (49, 21)], fill=(255, 248, 210, 255))
    d.line((16, 33, 31, 49), fill=(255, 135, 78, 255), width=7)
    d.line((14, 31, 33, 50), fill=(80, 42, 82, 255), width=3)
    d.rounded_rectangle((10, 46, 25, 58), radius=4, fill=(70, 40, 75, 255), outline=(255, 217, 110, 255), width=2)
    return img


def make_background():
    source = ROOT / "assets" / "images" / "battle" / "battle_bg_forest_ruins.png"
    bg = Image.open(source).convert("RGBA")
    bg = bg.resize((941, 1672), Image.LANCZOS)
    overlay = Image.new("RGBA", bg.size, (5, 12, 28, 80))
    bg = Image.alpha_composite(bg, overlay)
    bg.save(FORMAL_DIR / "battle_prepare_bg.png")
    bg.save(RUNTIME_DIR / "battle_prepare_bg.png")
    shutil.copy2(bg.filename if hasattr(bg, "filename") and bg.filename else source, EXTRACT_DIR / "battle_prepare_bg_source.png")


def make_ui_assets():
    assets = {
        "ui_prepare_header.png": rounded_panel((296, 64), (18, 39, 80, 238), (87, 120, 178, 255), 14, 3, (130, 166, 220, 120)),
        "ui_team_card.png": rounded_panel((100, 130), (18, 30, 58, 238), (76, 210, 105, 255), 14, 3, (130, 255, 160, 90)),
        "ui_enemy_card.png": rounded_panel((95, 120), (44, 22, 42, 238), (255, 98, 92, 255), 14, 3, (255, 178, 130, 90)),
        "ui_power_panel.png": rounded_panel((345, 62), (15, 28, 58, 238), (112, 145, 210, 255), 16, 3, (255, 230, 124, 80)),
        "ui_info_panel.png": rounded_panel((345, 72), (14, 25, 52, 232), (73, 110, 172, 255), 14, 3, (107, 158, 230, 80)),
        "ui_synergy_panel.png": rounded_panel((345, 58), (15, 31, 50, 232), (95, 185, 128, 255), 14, 3, (150, 240, 170, 80)),
        "ui_alert_panel.png": rounded_panel((260, 86), (63, 24, 42, 242), (255, 92, 92, 255), 14, 3, (255, 180, 150, 90)),
        "ui_reward_slot.png": rounded_panel((38, 38), (25, 32, 72, 238), (109, 90, 210, 255), 8, 2, (255, 255, 255, 80)),
        "ui_chip.png": rounded_panel((74, 24), (25, 39, 75, 235), (92, 130, 190, 255), 10, 2, None),
        "ui_start_button.png": button((200, 54), (35, 111, 230, 255), (154, 207, 255, 255), (55, 145, 255, 45)),
        "ui_start_button_ready.png": button((200, 54), (43, 174, 86, 255), (189, 255, 172, 255), (75, 240, 95, 70)),
        "ui_start_button_disabled.png": button((200, 54), (78, 87, 108, 230), (132, 142, 164, 255), None),
        "icon_sword_cross.png": icon_sword(),
    }
    for name, img in assets.items():
        img.save(FORMAL_DIR / name)
        img.save(RUNTIME_DIR / name)


def copy_shared_assets():
    # 通用图标只在 stage/battle/main 等通用目录维护，战斗准备页代码直接定向引用。
    return


def make_reference_crops():
    concept = CONCEPT_DIR / "07_战斗准备_battle_prepare.png"
    if not concept.exists():
        return
    img = Image.open(concept).convert("RGBA")
    crops = [
        ("01_prepare_header_reference.png", (0, 0, 941, 175)),
        ("02_enemy_preview_reference.png", (50, 235, 890, 595)),
        ("03_player_team_reference.png", (50, 650, 890, 1010)),
        ("04_power_compare_reference.png", (35, 1010, 905, 1180)),
        ("05_reward_start_reference.png", (35, 1200, 905, 1500)),
    ]
    thumbs = []
    for name, box in crops:
        crop = img.crop(box)
        crop.save(CROP_DIR / name)
        thumbs.append((name, crop))
    sheet_w = 480
    y = 10
    sheet_h = sum(max(80, int(c.height * (sheet_w - 20) / c.width)) + 34 for _, c in thumbs) + 10
    sheet = Image.new("RGBA", (sheet_w, sheet_h), (16, 24, 44, 255))
    d = ImageDraw.Draw(sheet)
    for name, crop in thumbs:
        tw = sheet_w - 20
        th = int(crop.height * tw / crop.width)
        resized = crop.resize((tw, th), Image.LANCZOS)
        sheet.paste(resized, (10, y))
        d.text((12, y + th + 6), name, fill=(235, 241, 255, 255))
        y += th + 34
    sheet.save(CROP_DIR / "battle_prepare_contact_sheet.png")


def main():
    ensure_dirs()
    make_background()
    make_ui_assets()
    copy_shared_assets()
    make_reference_crops()
    print(f"generated: {RUNTIME_DIR}")


if __name__ == "__main__":
    main()
