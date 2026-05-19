from collections import deque
from pathlib import Path
from PIL import Image, ImageDraw
import shutil

ROOT = Path(__file__).resolve().parents[2]
GEN = Path("/Users/summercards/.codex/generated_images/019e2a8a-0ff4-7150-a41e-34a0060d270b")
UI_SRC = GEN / "ig_00cee9ab9674795b016a0b524b68048191bc0908dddcfaadd3.png"
EXTRACT = ROOT / "美术开发" / "元素提取" / "inventory"
FORMAL = ROOT / "美术开发" / "正式拆分" / "inventory"
RUNTIME = ROOT / "assets" / "images" / "inventory"
UI_DIR = FORMAL / "ui"

for path in [EXTRACT, UI_DIR, RUNTIME]:
    path.mkdir(parents=True, exist_ok=True)


def rgba(hex_color, alpha=255):
    hex_color = hex_color.lstrip("#")
    return tuple(int(hex_color[i:i + 2], 16) for i in (0, 2, 4)) + (alpha,)


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


def crop(src, box, size=None):
    im = remove_checker_bg(src.crop(box))
    if size:
        im = im.resize(size, Image.Resampling.LANCZOS)
    return im


def save(im, name):
    im.save(UI_DIR / name)
    im.save(RUNTIME / name)


def build_bg():
    im = Image.new("RGBA", (375, 667), rgba("#07182c"))
    d = ImageDraw.Draw(im)
    for y in range(667):
        d.line((0, y, 375, y), fill=(4, 17 + min(18, y // 34), 38 + min(32, y // 25), 255))
    d.rectangle((0, 220, 375, 667), fill=rgba("#071f38", 245))
    save(im, "bg_inventory.png")


def main():
    src = Image.open(UI_SRC).convert("RGBA")
    shutil.copy2(UI_SRC, EXTRACT / "inventory_ui_image2_sheet.png")
    build_bg()
    save(crop(src, (24, 24, 171, 151), (58, 58)), "ui_back_button.png")
    save(crop(src, (220, 28, 350, 142), (56, 52)), "icon_backpack.png")
    save(crop(src, (398, 42, 688, 125), (118, 34)), "ui_currency_chip.png")
    save(crop(src, (28, 186, 350, 260), (94, 42)), "ui_tab_active.png")
    save(crop(src, (370, 190, 668, 260), (94, 42)), "ui_tab_inactive.png")
    save(crop(src, (18, 282, 690, 914), (357, 368)), "ui_grid_panel.png")
    save(crop(src, (58, 322, 166, 423), (60, 60)), "ui_slot_selected.png")
    save(crop(src, (180, 322, 282, 423), (60, 60)), "ui_slot.png")
    save(crop(src, (62, 780, 166, 880), (60, 60)), "ui_slot_locked.png")
    save(crop(src, (948, 516, 990, 912), (12, 252)), "ui_scrollbar.png")
    save(crop(src, (27, 940, 682, 1316), (357, 188)), "ui_detail_panel.png")
    save(crop(src, (710, 948, 965, 1183), (120, 112)), "ui_detail_icon_frame.png")
    save(crop(src, (703, 1195, 968, 1272), (120, 34)), "ui_rarity_ribbon.png")
    save(crop(src, (35, 1372, 376, 1477), (110, 42)), "ui_btn_use.png")
    save(crop(src, (420, 1375, 995, 1468), (250, 42)), "ui_toast_strip.png")
    print("split inventory image-2 assets")


if __name__ == "__main__":
    main()
