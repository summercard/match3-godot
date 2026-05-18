from pathlib import Path
from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
SHEET = ROOT / "美术开发" / "元素提取" / "battle_result_overlay" / "battle_result_overlay_ui_effects_image2_sheet.png"
FORMAL = ROOT / "美术开发" / "正式拆分" / "battle_result_overlay"
RUNTIME = ROOT / "assets" / "images" / "battle" / "result_overlay"

KEY = (255, 0, 255)

ASSETS = [
    ("ui", "ui_overlay_victory_banner.png", (52, 42, 610, 292)),
    ("ui", "ui_overlay_defeat_banner.png", (645, 38, 1162, 295)),
    ("effects", "fx_overlay_victory_burst.png", (1168, 32, 1605, 332)),
    ("ui", "ui_overlay_panel.png", (66, 336, 690, 665)),
    ("ui", "ui_overlay_button_continue.png", (798, 382, 1135, 512)),
    ("ui", "ui_overlay_capture_plaque.png", (785, 548, 1135, 665)),
    ("effects", "fx_overlay_confetti.png", (1180, 410, 1584, 690)),
    ("effects", "fx_overlay_defeat_smoke.png", (45, 698, 690, 908)),
    ("effects", "fx_overlay_underline.png", (718, 782, 1182, 865)),
    ("ui", "ui_overlay_tap_strip.png", (1218, 772, 1618, 902)),
]


def chroma_to_alpha(img: Image.Image) -> Image.Image:
    rgba = img.convert("RGBA")
    px = rgba.load()
    w, h = rgba.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            dist = abs(r - KEY[0]) + abs(g - KEY[1]) + abs(b - KEY[2])
            if dist < 60:
                px[x, y] = (r, g, b, 0)
            elif dist < 150:
                alpha = int(a * (dist - 60) / 90)
                px[x, y] = (r, g, b, alpha)
    return rgba


def trim_alpha(img: Image.Image, padding: int = 8) -> Image.Image:
    alpha = img.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        return img
    left, top, right, bottom = bbox
    left = max(0, left - padding)
    top = max(0, top - padding)
    right = min(img.width, right + padding)
    bottom = min(img.height, bottom + padding)
    return img.crop((left, top, right, bottom))


def main() -> None:
    sheet = Image.open(SHEET)
    RUNTIME.mkdir(parents=True, exist_ok=True)
    for category, name, box in ASSETS:
        formal_dir = FORMAL / category
        formal_dir.mkdir(parents=True, exist_ok=True)
        asset = trim_alpha(chroma_to_alpha(sheet.crop(box)))
        asset.save(formal_dir / name)
        asset.save(RUNTIME / name)
        print(f"{name}: {asset.size}")


if __name__ == "__main__":
    main()
