from collections import deque
from pathlib import Path
from PIL import Image
import shutil

ROOT = Path(__file__).resolve().parents[2]
GEN = Path("/Users/summercards/.codex/generated_images/019e2a8a-0ff4-7150-a41e-34a0060d270b")
BG_SRC = GEN / "ig_0d73b4a9e5599b9e016a0bd02ad11481918225a3f4f7213fa6.png"
UI_SRC = GEN / "ig_0d73b4a9e5599b9e016a0bd095b75081919c977b974ebca31e.png"
EXTRACT = ROOT / "美术开发" / "元素提取" / "main_lobby_v2"
FORMAL = ROOT / "美术开发" / "正式拆分" / "main_lobby_v2"
RUNTIME = ROOT / "assets" / "images" / "main"
UI_DIR = FORMAL / "ui"

for path in [EXTRACT, UI_DIR, RUNTIME]:
    path.mkdir(parents=True, exist_ok=True)


def _is_checker_pixel(px):
    r, g, b, a = px
    if a == 0:
        return True
    return r > 185 and g > 185 and b > 185 and max(r, g, b) - min(r, g, b) < 30


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


def save_bg():
    shutil.copy2(BG_SRC, EXTRACT / "main_lobby_v2_bg_image2.png")
    src = Image.open(BG_SRC).convert("RGBA")
    bg = src.resize((375, 667), Image.Resampling.LANCZOS)
    bg.save(UI_DIR / "main_lobby_bg_v2.png")
    bg.save(RUNTIME / "main_lobby_bg_v2.png")


def main():
    shutil.copy2(UI_SRC, EXTRACT / "main_lobby_v2_ui_image2_sheet.png")
    save_bg()
    src = Image.open(UI_SRC).convert("RGBA")

    save(crop(src, (52, 49, 318, 320), (76, 76)), "ui_avatar_frame_v2.png")
    save(crop(src, (356, 67, 806, 163), (126, 32)), "ui_player_name_plate_v2.png")
    save(crop(src, (357, 189, 473, 321), (42, 46)), "ui_level_shield_v2.png")
    save(crop(src, (507, 209, 862, 255), (128, 17)), "ui_exp_bar_empty_v2.png")
    save(crop(src, (507, 289, 862, 339), (128, 17)), "ui_exp_bar_fill_v2.png")
    save(crop(src, (945, 75, 1444, 168), (100, 30)), "ui_gold_capsule_v2.png")
    save(crop(src, (947, 208, 1444, 302), (100, 30)), "ui_diamond_capsule_v2.png")
    save(crop(src, (946, 336, 1459, 537), (126, 48)), "ui_rank_panel_v2.png")
    save(crop(src, (39, 379, 484, 517), (136, 42)), "ui_entry_button_v2.png")
    save(crop(src, (535, 366, 705, 536), (68, 68)), "ui_bottom_nav_frame_v2.png")
    save(crop(src, (741, 366, 909, 536), (68, 68)), "ui_bottom_nav_frame_pressed_v2.png")

    save(crop(src, (51, 587, 273, 744), (48, 42)), "icon_album_book_v2.png")
    save(crop(src, (351, 575, 563, 747), (48, 44)), "icon_inventory_bag_v2.png")
    save(crop(src, (627, 569, 843, 748), (50, 48)), "icon_achievement_medal_v2.png")
    save(crop(src, (923, 578, 1106, 744), (46, 46)), "icon_settings_gear_v2.png")
    save(crop(src, (1218, 572, 1448, 747), (50, 46)), "icon_signin_calendar_v2.png")

    save(crop(src, (75, 811, 182, 924), (30, 30)), "icon_paw_v2.png")
    save(crop(src, (264, 811, 370, 924), (30, 30)), "icon_swords_v2.png")
    save(crop(src, (448, 811, 557, 924), (30, 30)), "icon_leaf_v2.png")
    save(crop(src, (640, 811, 747, 924), (30, 30)), "icon_cart_v2.png")
    save(crop(src, (866, 808, 962, 925), (24, 24)), "icon_edit_v2.png")
    save(crop(src, (1036, 808, 1132, 920), (28, 28)), "icon_gold_v2.png")
    save(crop(src, (1195, 808, 1306, 920), (28, 28)), "icon_diamond_v2.png")
    save(crop(src, (1370, 824, 1449, 903), (18, 18)), "ui_notification_dot_v2.png")
    print("split main lobby v2 image-2 assets")


if __name__ == "__main__":
    main()
