from pathlib import Path
from collections import deque
from PIL import Image, ImageDraw
import shutil

ROOT = Path(__file__).resolve().parents[2]
GEN = Path("/Users/summercards/.codex/generated_images/019e2a8a-0ff4-7150-a41e-34a0060d270b")
UI_SRC = GEN / "ig_00cee9ab9674795b016a0b49c5c6488191ad2fd371cdfe2344.png"
ITEM_SRC = GEN / "ig_00cee9ab9674795b016a0b4a3221988191936e52f5428b3a30.png"
GEM_SRC = GEN / "ig_00cee9ab9674795b016a0b4a7fc81c81919dc2e2dae6a0d746.png"

EXTRACT = ROOT / "美术开发" / "元素提取" / "shop"
FORMAL = ROOT / "美术开发" / "正式拆分" / "shop"
RUNTIME = ROOT / "assets" / "images" / "shop"
UI_DIR = FORMAL / "ui"
ITEM_DIR = FORMAL / "items"
GEM_DIR = FORMAL / "gems"

for path in [EXTRACT, UI_DIR, ITEM_DIR, GEM_DIR, RUNTIME]:
    path.mkdir(parents=True, exist_ok=True)


def rgba(hex_color, alpha=255):
    hex_color = hex_color.lstrip("#")
    return tuple(int(hex_color[i:i + 2], 16) for i in (0, 2, 4)) + (alpha,)


def crop(src, box, size=None):
    im = src.crop(box)
    im = remove_checker_bg(im)
    if size:
        im = im.resize(size, Image.Resampling.LANCZOS)
    return im


def _is_checker_pixel(px):
    r, g, b, a = px
    if a == 0:
        return True
    return r > 185 and g > 185 and b > 185 and max(r, g, b) - min(r, g, b) < 28


def remove_checker_bg(im):
    im = im.convert("RGBA")
    w, h = im.size
    pix = im.load()
    seen = set()
    q = deque()
    for x in range(w):
        q.append((x, 0))
        q.append((x, h - 1))
    for y in range(h):
        q.append((0, y))
        q.append((w - 1, y))
    while q:
        x, y = q.popleft()
        if x < 0 or x >= w or y < 0 or y >= h or (x, y) in seen:
            continue
        if not _is_checker_pixel(pix[x, y]):
            continue
        seen.add((x, y))
        pix[x, y] = (255, 255, 255, 0)
        q.append((x + 1, y))
        q.append((x - 1, y))
        q.append((x, y + 1))
        q.append((x, y - 1))
    return im


def save(im, folder, name, runtime=True):
    path = folder / name
    im.save(path)
    if runtime:
        im.save(RUNTIME / name)


def copy_sources():
    shutil.copy2(UI_SRC, EXTRACT / "shop_ui_image2_sheet.png")
    shutil.copy2(ITEM_SRC, EXTRACT / "shop_items_image2_sheet.png")
    shutil.copy2(GEM_SRC, EXTRACT / "shop_gems_image2_sheet.png")


def build_background(ui):
    bg = Image.new("RGBA", (375, 667), rgba("#07182c"))
    d = ImageDraw.Draw(bg)
    for y in range(667):
        d.line((0, y, 375, y), fill=(4, 18 + min(18, y // 34), 39 + min(30, y // 26), 255))
    room = crop(ui, (35, 430, 630, 748), (375, 200))
    bg.alpha_composite(room, (0, 88))
    wizard = crop(ui, (55, 18, 548, 395), (195, 148))
    shelf = crop(ui, (635, 18, 990, 390), (94, 145))
    bg.alpha_composite(wizard, (-48, 103))
    bg.alpha_composite(shelf, (292, 96))
    d.rectangle((0, 238, 375, 596), fill=rgba("#05213a", 230))
    d.rectangle((0, 596, 375, 667), fill=rgba("#071529", 244))
    save(bg, UI_DIR, "bg_shop_room.png")


def build_ui(ui):
    top = Image.new("RGBA", (375, 60), rgba("#07182e"))
    ImageDraw.Draw(top).rectangle((2, 2, 373, 56), outline=rgba("#26466c"), width=3)
    save(top, UI_DIR, "ui_top_bar.png")
    save(crop(ui, (718, 420, 876, 577), (58, 58)), UI_DIR, "ui_back_button.png")
    save(crop(ui, (650, 602, 1016, 695), (118, 34)), UI_DIR, "ui_currency_chip.png")
    save(crop(ui, (33, 800, 325, 884), (98, 42)), UI_DIR, "ui_tab_active.png")
    save(crop(ui, (370, 810, 675, 884), (98, 42)), UI_DIR, "ui_tab_inactive.png")
    save(crop(ui, (25, 900, 735, 1105), (351, 126)), UI_DIR, "ui_feature_banner.png")
    save(crop(ui, (765, 755, 985, 1110), (82, 142)), UI_DIR, "ui_product_card.png")
    save(crop(ui, (760, 1175, 1030, 1258), (68, 27)), UI_DIR, "ui_buy_button.png")
    disabled = crop(ui, (760, 1175, 1030, 1258), (68, 27)).convert("LA").convert("RGBA")
    save(disabled, UI_DIR, "ui_buy_button_disabled.png")
    save(crop(ui, (760, 1330, 1015, 1403), (68, 24)), UI_DIR, "ui_price_plate.png")
    save(crop(ui, (26, 1132, 738, 1492), (300, 190)), UI_DIR, "ui_popup_panel.png")
    save(crop(ui, (760, 1330, 1015, 1403), (42, 34)), UI_DIR, "ui_qty_button.png")
    nav = Image.new("RGBA", (375, 71), rgba("#08172d", 245))
    nd = ImageDraw.Draw(nav)
    nd.rectangle((0, 0, 375, 70), outline=rgba("#304f7a"), width=3)
    nd.line((0, 8, 375, 8), fill=rgba("#5a78a8"), width=1)
    save(nav, UI_DIR, "ui_bottom_nav.png")


def split_items(items):
    boxes = {
        "icon_item_hp_potion.png": (70, 65, 320, 320),
        "icon_item_exp_potion.png": (455, 70, 700, 325),
        "icon_item_capture_ball.png": (805, 85, 1078, 320),
        "icon_item_capture_ball_plus.png": (1165, 72, 1430, 320),
        "icon_item_starter_chest.png": (70, 395, 340, 635),
        "icon_item_gold_bag.png": (452, 390, 728, 640),
        "icon_item_gold_chest.png": (805, 410, 1088, 620),
        "icon_item_strength_stone.png": (1180, 395, 1435, 645),
        "icon_item_ticket.png": (70, 720, 338, 910),
    }
    for name, box in boxes.items():
        save(crop(items, box, (84, 84)), ITEM_DIR, name)


def split_gems(gems):
    boxes = {
        "icon_stone_fire.png": (105, 70, 350, 460),
        "icon_stone_water.png": (455, 70, 700, 460),
        "icon_stone_grass.png": (810, 70, 1055, 460),
        "icon_stone_thunder.png": (1165, 70, 1410, 460),
        "icon_stone_light.png": (105, 515, 350, 915),
        "icon_stone_earth.png": (455, 515, 700, 915),
        "icon_stone_wind.png": (810, 515, 1055, 915),
        "icon_stone_dark.png": (1165, 515, 1410, 915),
    }
    for name, box in boxes.items():
        save(crop(gems, box, (84, 84)), GEM_DIR, name)


def main():
    copy_sources()
    ui = Image.open(UI_SRC).convert("RGBA")
    items = Image.open(ITEM_SRC).convert("RGBA")
    gems = Image.open(GEM_SRC).convert("RGBA")
    build_background(ui)
    build_ui(ui)
    split_items(items)
    split_gems(gems)
    print("split shop assets from image-2 sheets")


if __name__ == "__main__":
    main()
