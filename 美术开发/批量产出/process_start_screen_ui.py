#!/usr/bin/env python3
"""Split the start-screen UI component sheet into runtime-ready assets."""

from pathlib import Path
from collections import deque
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SHEET = ROOT / "美术开发/正式拆分/start_screen/start_ui_sheet_alpha.png"
OUT_DIR = ROOT / "美术开发/正式拆分/start_screen"
RUNTIME_DIR = ROOT / "assets/images/start"

ASSET_NAMES = [
    "ui_btn_start_normal.png",
    "ui_btn_start_pressed.png",
    "ui_btn_start_disabled.png",
    "ui_hint_ribbon.png",
    "ui_version_plaque.png",
]


def find_components(img: Image.Image):
    alpha = img.getchannel("A")
    w, h = img.size
    pix = alpha.load()
    seen = set()
    components = []

    for y in range(h):
        for x in range(w):
            if pix[x, y] <= 20 or (x, y) in seen:
                continue

            queue = deque([(x, y)])
            seen.add((x, y))
            min_x = max_x = x
            min_y = max_y = y
            count = 0

            while queue:
                cx, cy = queue.pop()
                count += 1
                min_x = min(min_x, cx)
                max_x = max(max_x, cx)
                min_y = min(min_y, cy)
                max_y = max(max_y, cy)

                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if (
                        0 <= nx < w
                        and 0 <= ny < h
                        and (nx, ny) not in seen
                        and pix[nx, ny] > 20
                    ):
                        seen.add((nx, ny))
                        queue.append((nx, ny))

            if count > 200:
                components.append({
                    "count": count,
                    "bbox": (min_x, min_y, max_x + 1, max_y + 1),
                    "center": ((min_x + max_x) / 2, (min_y + max_y) / 2),
                })

    return components


def crop_with_padding(img: Image.Image, bbox, pad=10):
    w, h = img.size
    left, top, right, bottom = bbox
    left = max(0, left - pad)
    top = max(0, top - pad)
    right = min(w, right + pad)
    bottom = min(h, bottom + pad)
    return img.crop((left, top, right, bottom))


def assign_components(components, sheet_width):
    top = [c for c in components if c["center"][1] < 600]
    lower = [c for c in components if c["center"][1] >= 600]

    if len(top) != 2 or len(lower) != 3:
        raise RuntimeError("Unexpected start UI sheet layout")

    normal = min(top, key=lambda c: c["center"][0])
    pressed = max(top, key=lambda c: c["center"][0])
    disabled = min(lower, key=lambda c: c["center"][0])

    right_lower = [c for c in lower if c["center"][0] >= sheet_width / 2]
    if len(right_lower) != 2:
        raise RuntimeError("Unexpected right-side UI component count")

    hint = min(right_lower, key=lambda c: c["center"][1])
    version = max(right_lower, key=lambda c: c["center"][1])

    return {
        "ui_btn_start_normal.png": normal,
        "ui_btn_start_pressed.png": pressed,
        "ui_btn_start_disabled.png": disabled,
        "ui_hint_ribbon.png": hint,
        "ui_version_plaque.png": version,
    }


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    RUNTIME_DIR.mkdir(parents=True, exist_ok=True)

    sheet = Image.open(SHEET).convert("RGBA")
    components = find_components(sheet)

    if len(components) != 5:
        raise RuntimeError(f"Expected 5 UI components, got {len(components)}")

    assigned = assign_components(components, sheet.size[0])
    for name in ASSET_NAMES:
        comp = assigned[name]
        asset = crop_with_padding(sheet, comp["bbox"], pad=12)
        formal_path = OUT_DIR / name
        runtime_path = RUNTIME_DIR / name
        asset.save(formal_path)
        asset.save(runtime_path)
        print(f"{name}: {asset.size[0]}x{asset.size[1]} -> {runtime_path}")


if __name__ == "__main__":
    main()
