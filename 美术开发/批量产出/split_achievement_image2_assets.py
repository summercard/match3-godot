from collections import deque
from pathlib import Path
from PIL import Image, ImageDraw
import shutil

ROOT = Path(__file__).resolve().parents[2]
GEN = Path("/Users/summercards/.codex/generated_images/019e2a8a-0ff4-7150-a41e-34a0060d270b")
UI_SRC = GEN / "ig_0d73b4a9e5599b9e016a0bbf9c3c8c8191982c068a871585cc.png"
EXTRACT = ROOT / "美术开发" / "元素提取" / "achievement"
FORMAL = ROOT / "美术开发" / "正式拆分" / "achievement"
RUNTIME = ROOT / "assets" / "images" / "achievement"
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


def build_bg():
    im = Image.new("RGBA", (375, 667), rgba("#061325"))
    d = ImageDraw.Draw(im)
    for y in range(667):
        r = 3
        g = 14 + min(22, y // 28)
        b = 34 + min(42, y // 20)
        d.line((0, y, 375, y), fill=(r, g, b, 255))
    d.rectangle((0, 0, 375, 667), outline=rgba("#16365d", 180), width=2)
    d.rectangle((8, 206, 367, 660), fill=rgba("#061a31", 130))
    save(im, "bg_achievement.png")


def main():
    src = Image.open(UI_SRC).convert("RGBA")
    shutil.copy2(UI_SRC, EXTRACT / "achievement_ui_image2_sheet.png")
    build_bg()
    save(crop(src, (480, 54, 596, 163), (58, 58)), "ui_back_button.png")
    save(crop(src, (738, 56, 1289, 161), (260, 50)), "ui_header_bar.png")
    save(crop(src, (462, 190, 1123, 392), (357, 104)), "ui_summary_panel.png")
    save(crop(src, (515, 213, 721, 360), (118, 92)), "icon_trophy.png")
    save(crop(src, (461, 413, 674, 516), (68, 42)), "ui_tab_all.png")
    save(crop(src, (700, 416, 920, 516), (68, 42)), "ui_tab_battle.png")
    save(crop(src, (946, 416, 1158, 516), (68, 42)), "ui_tab_collect.png")
    save(crop(src, (1194, 416, 1405, 516), (68, 42)), "ui_tab_growth.png")
    save(crop(src, (45, 554, 889, 667), (357, 92)), "ui_card_frame.png")
    save(crop(src, (1012, 559, 1230, 612), (128, 30)), "ui_title_ribbon.png")
    save(crop(src, (47, 688, 413, 736), (170, 18)), "ui_progress_empty.png")
    save(crop(src, (445, 688, 848, 737), (170, 18)), "ui_progress_fill.png")
    save(crop(src, (919, 647, 1177, 732), (104, 40)), "ui_btn_claim.png")
    save(crop(src, (1210, 647, 1459, 732), (104, 40)), "ui_btn_disabled.png")
    save(crop(src, (61, 796, 354, 893), (102, 36)), "ui_stamp_completed.png")
    save(crop(src, (386, 794, 471, 902), (42, 48)), "icon_lock.png")
    save(crop(src, (526, 775, 673, 932), (74, 78)), "badge_star.png")
    save(crop(src, (717, 775, 862, 932), (74, 78)), "badge_battle.png")
    save(crop(src, (904, 775, 1053, 932), (74, 78)), "badge_collect.png")
    save(crop(src, (1097, 775, 1248, 932), (74, 78)), "badge_growth.png")
    save(crop(src, (1314, 771, 1456, 935), (74, 78)), "badge_locked.png")
    print("split achievement image-2 assets")


if __name__ == "__main__":
    main()
