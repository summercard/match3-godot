#!/usr/bin/env python3
"""Split the image-2 gold-groove HP sheet into formal and runtime assets."""

from __future__ import annotations

from collections import deque
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
RAW_SOURCE = ROOT / "美术开发/元素提取/battle_screen_new_style/image2_raw/ui_hp_capsule_gold_groove_image2_chroma.png"
ALPHA_SOURCE = ROOT / "美术开发/元素提取/battle_screen_new_style/image2_alpha/ui_hp_capsule_gold_groove.png"
FORMAL_DIR = ROOT / "美术开发/正式拆分/battle_screen_new_style/ui"
RUNTIME_DIR = ROOT / "assets/images/battle/ui"


def remove_connected_background(image: Image.Image, threshold: int = 80) -> Image.Image:
    """Remove only chroma pixels connected to the border, preserving the green HP fill."""
    image = image.convert("RGBA")
    pixels = image.load()
    width, height = image.size
    samples = [
        pixels[0, 0][:3],
        pixels[width - 1, 0][:3],
        pixels[0, height - 1][:3],
        pixels[width - 1, height - 1][:3],
    ]
    key = tuple(sum(sample[i] for sample in samples) // len(samples) for i in range(3))
    seen = bytearray(width * height)
    queue: deque[tuple[int, int]] = deque()

    def close_to_key(x: int, y: int) -> bool:
        r, g, b, _ = pixels[x, y]
        return ((r - key[0]) ** 2 + (g - key[1]) ** 2 + (b - key[2]) ** 2) ** 0.5 <= threshold

    def push(x: int, y: int) -> None:
        index = y * width + x
        if seen[index] or not close_to_key(x, y):
            return
        seen[index] = 1
        queue.append((x, y))

    for x in range(width):
        push(x, 0)
        push(x, height - 1)
    for y in range(height):
        push(0, y)
        push(width - 1, y)
    while queue:
        x, y = queue.popleft()
        pixels[x, y] = (0, 0, 0, 0)
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < width and 0 <= ny < height:
                push(nx, ny)
    return image


def component_boxes(image: Image.Image, min_area: int = 12000) -> list[tuple[int, int, int, int]]:
    alpha = image.getchannel("A")
    pixels = alpha.load()
    width, height = image.size
    seen = bytearray(width * height)
    boxes: list[tuple[int, int, int, int]] = []
    for y in range(height):
        for x in range(width):
            index = y * width + x
            if seen[index] or pixels[x, y] < 24:
                continue
            queue = deque([(x, y)])
            seen[index] = 1
            min_x = max_x = x
            min_y = max_y = y
            area = 0
            while queue:
                cx, cy = queue.popleft()
                area += 1
                min_x = min(min_x, cx)
                max_x = max(max_x, cx)
                min_y = min(min_y, cy)
                max_y = max(max_y, cy)
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if nx < 0 or ny < 0 or nx >= width or ny >= height:
                        continue
                    next_index = ny * width + nx
                    if seen[next_index] or pixels[nx, ny] < 24:
                        continue
                    seen[next_index] = 1
                    queue.append((nx, ny))
            if area >= min_area:
                boxes.append((min_x, min_y, max_x + 1, max_y + 1))
    return boxes


def crop(image: Image.Image, box: tuple[int, int, int, int], pad: int = 8) -> Image.Image:
    left, top, right, bottom = box
    return image.crop((
        max(0, left - pad),
        max(0, top - pad),
        min(image.width, right + pad),
        min(image.height, bottom + pad),
    ))


def save(image: Image.Image, name: str) -> None:
    FORMAL_DIR.mkdir(parents=True, exist_ok=True)
    RUNTIME_DIR.mkdir(parents=True, exist_ok=True)
    image.save(FORMAL_DIR / name)
    image.save(RUNTIME_DIR / name)
    print(f"{name}: {image.width}x{image.height}")


def make_frame_overlay(frame: Image.Image) -> Image.Image:
    """Clear the connected navy track so the decorative frame can sit above a dynamic bar."""
    overlay = frame.convert("RGBA").copy()
    pixels = overlay.load()
    width, height = overlay.size
    seen = bytearray(width * height)
    queue = deque([(width // 2, height // 2)])

    def is_track_pixel(x: int, y: int) -> bool:
        r, g, b, a = pixels[x, y]
        return a > 0 and max(r, g, b) < 145

    while queue:
        x, y = queue.popleft()
        index = y * width + x
        if seen[index] or not is_track_pixel(x, y):
            continue
        seen[index] = 1
        pixels[x, y] = (0, 0, 0, 0)
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < width and 0 <= ny < height:
                queue.append((nx, ny))
    return overlay


def main() -> None:
    sheet = remove_connected_background(Image.open(RAW_SOURCE))
    ALPHA_SOURCE.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(ALPHA_SOURCE)
    boxes = sorted(component_boxes(sheet), key=lambda box: box[0])
    if len(boxes) != 5:
        raise RuntimeError(f"Expected 5 HP components, found {len(boxes)}")
    names = [
        "ui_hp_frame.png",
        "ui_hp_fill_red.png",
        "ui_hp_fill_green.png",
        "ui_hp_fill_blue.png",
        "ui_hp_fill_gold.png",
    ]
    for box, name in zip(boxes, names):
        asset = crop(sheet, box)
        save(asset, name)
        if name == "ui_hp_frame.png":
            save(make_frame_overlay(asset), "ui_hp_frame_overlay.png")


if __name__ == "__main__":
    main()
