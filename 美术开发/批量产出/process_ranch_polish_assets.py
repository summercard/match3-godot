#!/usr/bin/env python3
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "美术开发" / "元素提取" / "ranch" / "ui_polish_v2"
FORMAL = ROOT / "美术开发" / "正式拆分" / "ranch" / "ui"
RUNTIME = ROOT / "assets" / "images" / "ranch"

ASSETS = {
    "ui_roster_card_ranch": (192, 224),
    "ui_roster_card_ranch_selected": (192, 224),
    "ui_classroom_detail_panel": (702, 388),
    "ui_care_roster_panel": (710, 508),
    "ui_social_place_panel": (702, 388),
    "ui_social_slot_frame": (212, 188),
    "ui_social_result_panel": (650, 784),
    "ui_relationship_ribbon": (678, 84),
}


def trim_alpha(image: Image.Image, padding: int = 6) -> Image.Image:
    bbox = image.getbbox()
    if bbox is None:
        raise ValueError("asset has no visible pixels")
    left, top, right, bottom = bbox
    left = max(0, left - padding)
    top = max(0, top - padding)
    right = min(image.width, right + padding)
    bottom = min(image.height, bottom + padding)
    return image.crop((left, top, right, bottom))


def main() -> None:
    FORMAL.mkdir(parents=True, exist_ok=True)
    RUNTIME.mkdir(parents=True, exist_ok=True)
    for name, target_size in ASSETS.items():
        source = SRC / f"{name}_alpha.png"
        if not source.exists():
            raise FileNotFoundError(source)
        final = trim_alpha(Image.open(source).convert("RGBA"))
        final = final.resize(target_size, Image.Resampling.LANCZOS)
        final.save(FORMAL / f"{name}.png")
        final.save(RUNTIME / f"{name}.png")
        print(f"{name}: {final.width}x{final.height}")


if __name__ == "__main__":
    main()
