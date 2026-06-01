#!/usr/bin/env python3
"""Import image-2 battle-screen art while preserving the current battle layout."""

from __future__ import annotations

from collections import deque
from pathlib import Path
from shutil import copy2

from PIL import Image, ImageEnhance


ROOT = Path(__file__).resolve().parents[2]
RAW_DIR = ROOT / "美术开发/元素提取/battle_screen_new_style/image2_raw"
ALPHA_DIR = ROOT / "美术开发/元素提取/battle_screen_new_style/image2_alpha"
FORMAL_DIR = ROOT / "美术开发/正式拆分/battle_screen_new_style"
RUNTIME_DIR = ROOT / "assets/images/battle"


def remove_border_key(image: Image.Image, transparent: int = 14, opaque: int = 190) -> Image.Image:
    image = image.convert("RGBA")
    samples = [
        image.getpixel((0, 0))[:3],
        image.getpixel((image.width - 1, 0))[:3],
        image.getpixel((0, image.height - 1))[:3],
        image.getpixel((image.width - 1, image.height - 1))[:3],
    ]
    key = tuple(sum(sample[i] for sample in samples) // len(samples) for i in range(3))
    pixels = image.load()
    kr, kg, kb = key
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, _ = pixels[x, y]
            distance = ((r - kr) ** 2 + (g - kg) ** 2 + (b - kb) ** 2) ** 0.5
            if distance <= transparent:
                alpha = 0
            elif distance >= opaque:
                alpha = 255
            else:
                alpha = int(255 * (distance - transparent) / (opaque - transparent))
            pixels[x, y] = (r, g, b, alpha)
    return image


def remove_green_chroma(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, _ = pixels[x, y]
            green_strength = g - max(r, b)
            if g > 120 and green_strength > 36:
                alpha = 0
            elif g > 100 and green_strength > 20:
                alpha = int(255 * (36 - green_strength) / 16)
            else:
                alpha = 255
            pixels[x, y] = (r, g, b, alpha)
    return image


def trim_alpha(image: Image.Image, pad: int = 12) -> Image.Image:
    image = image.convert("RGBA")
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise RuntimeError("Cannot trim an entirely transparent asset")
    left, top, right, bottom = bbox
    return image.crop((
        max(0, left - pad),
        max(0, top - pad),
        min(image.width, right + pad),
        min(image.height, bottom + pad),
    ))


def component_boxes(image: Image.Image, min_area: int = 900) -> list[tuple[int, int, int, int]]:
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


def crop_box(image: Image.Image, box: tuple[int, int, int, int], pad: int = 12) -> Image.Image:
    left, top, right, bottom = box
    return trim_alpha(image.crop((
        max(0, left - pad),
        max(0, top - pad),
        min(image.width, right + pad),
        min(image.height, bottom + pad),
    )), pad=4)


def save_asset(image: Image.Image, relative_path: str) -> None:
    formal = FORMAL_DIR / relative_path
    runtime = RUNTIME_DIR / relative_path
    formal.parent.mkdir(parents=True, exist_ok=True)
    runtime.parent.mkdir(parents=True, exist_ok=True)
    image.save(formal)
    image.save(runtime)
    print(f"{relative_path}: {image.width}x{image.height}")


def save_formal_candidate(image: Image.Image, relative_path: str) -> None:
    formal = FORMAL_DIR / relative_path
    formal.parent.mkdir(parents=True, exist_ok=True)
    image.save(formal)
    print(f"{relative_path}: {image.width}x{image.height} formal candidate")


def save_alpha_source(image: Image.Image, name: str) -> None:
    ALPHA_DIR.mkdir(parents=True, exist_ok=True)
    image.save(ALPHA_DIR / name)


def import_background() -> None:
    background = Image.open(RAW_DIR / "battle_bg_garden_arena_image2.png").convert("RGB")
    save_asset(background, "battle_bg_forest_ruins.png")


def import_board() -> None:
    board = remove_green_chroma(Image.open(RAW_DIR / "ui_board_frame_light_groove_image2_chroma.png"))
    save_alpha_source(board, "ui_board_frame.png")
    save_asset(trim_alpha(board), "ui/ui_board_frame.png")


def import_gems() -> None:
    sheet = remove_border_key(Image.open(RAW_DIR / "gems_image2_chroma.png"))
    save_alpha_source(sheet, "gems.png")
    boxes = sorted(component_boxes(sheet, min_area=3000), key=lambda box: box[0])
    if len(boxes) != 7:
        raise RuntimeError(f"Expected 7 gem components, found {len(boxes)}")
    names = [
        "gem_water.png",
        "gem_fire.png",
        "gem_grass.png",
        "gem_thunder.png",
        "obstacle_rock_full.png",
        "gem_light.png",
        "candidate_gem_heart.png",
    ]
    for box, name in zip(boxes, names):
        gem = crop_box(sheet, box)
        if name.startswith("candidate_"):
            save_formal_candidate(gem, f"gems/{name}")
        else:
            save_asset(gem, f"gems/{name}")
    rainbow = remove_border_key(Image.open(RAW_DIR / "gem_rainbow_special_image2_chroma.png"))
    save_alpha_source(rainbow, "gem_rainbow_special.png")
    save_asset(trim_alpha(rainbow), "gems/gem_rainbow_special.png")


def import_hud() -> None:
    sheet = remove_border_key(Image.open(RAW_DIR / "hud_ui_image2_chroma.png"))
    save_alpha_source(sheet, "hud_ui.png")
    configs = {
        "ui_top_scrim.png": (28, 96, 996, 492),
        "ui_turn_badge.png": (34, 558, 350, 870),
        "ui_settings_button.png": (126, 924, 394, 1196),
        "ui_footer_panel.png": (70, 1252, 970, 1450),
    }
    for name, box in configs.items():
        save_asset(crop_box(sheet, box), f"ui/{name}")
    refinements = {
        "ui_top_scrim.png": "ui_top_scrim_slim_image2_chroma.png",
        "ui_footer_panel.png": "ui_footer_panel_slim_image2_chroma.png",
    }
    for name, source_name in refinements.items():
        source = remove_green_chroma(Image.open(RAW_DIR / source_name))
        save_alpha_source(source, name)
        save_asset(trim_alpha(source), f"ui/{name}")
    # HP capsules are maintained separately so the green fill survives chroma removal.
    # Run import_battle_hp_capsule_image2.py after refreshing this HUD sheet.


def import_bottom_controls() -> None:
    controls = remove_green_chroma(Image.open(RAW_DIR / "ui_bottom_controls_image2_chroma.png"))
    save_alpha_source(controls, "ui_bottom_controls.png")
    control_boxes = sorted(component_boxes(controls, min_area=7000), key=lambda box: box[0])
    if len(control_boxes) != 4:
        raise RuntimeError(f"Expected 4 bottom control components, found {len(control_boxes)}")
    capture_toggle = crop_box(controls, control_boxes[0])
    muted_toggle = ImageEnhance.Color(capture_toggle).enhance(0.16)
    muted_toggle = ImageEnhance.Brightness(muted_toggle).enhance(0.76)
    save_asset(capture_toggle, "ui/ui_capture_toggle_on.png")
    save_asset(muted_toggle, "ui/ui_capture_toggle_off.png")
    for box, name in zip(control_boxes[1:], ["candidate_swap.png", "candidate_star.png", "candidate_rainbow.png"]):
        save_formal_candidate(crop_box(controls, box), f"ui/{name}")

    items = remove_green_chroma(Image.open(RAW_DIR / "ui_hotbar_items_image2_chroma.png"))
    save_alpha_source(items, "ui_hotbar_items.png")
    item_boxes = sorted(component_boxes(items, min_area=7000), key=lambda box: box[0])
    if len(item_boxes) != 3:
        raise RuntimeError(f"Expected 3 hotbar item components, found {len(item_boxes)}")
    for box, name in zip(item_boxes, ["icon_capture_ball.png", "icon_capture_ball_plus.png", "icon_hp_potion.png"]):
        save_asset(crop_box(items, box), f"ui/{name}")


def import_fx() -> None:
    sheet = remove_border_key(Image.open(RAW_DIR / "fx_image2_chroma.png"))
    save_alpha_source(sheet, "fx.png")
    configs = {
        "fx_hit_spark.png": (30, 25, 505, 490),
        "fx_gem_pop.png": (515, 25, 1024, 490),
        "fx_stage_ring_cyan.png": (1030, 25, 1530, 490),
        "fx_stage_ring_fire.png": (30, 510, 505, 1010),
        "fx_stage_ring_green.png": (515, 510, 1024, 1010),
        "fx_selected_cell.png": (1030, 510, 1530, 1010),
    }
    for name, box in configs.items():
        save_asset(crop_box(sheet, box), f"fx/{name}")


def main() -> None:
    FORMAL_DIR.mkdir(parents=True, exist_ok=True)
    import_background()
    import_board()
    import_gems()
    import_hud()
    import_bottom_controls()
    import_fx()
    copy2(RAW_DIR / "battle_bg_garden_arena_image2.png", FORMAL_DIR / "battle_bg_garden_arena_image2_source.png")
    print("Imported battle-screen image-2 assets without changing layout coordinates.")


if __name__ == "__main__":
    main()
