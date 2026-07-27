#!/usr/bin/env python3
"""Split approved image-2 motion sheets into production idle frames.

The image-2 sheets contain genuine pose changes (blinks, ear/limb motion,
secondary accessory motion, and flame deformation). Chroma-key removal is
performed first with the installed imagegen helper; this script then groups
each connected creature with its detached bubbles/flame droplets, applies one
shared scale per creature, aligns a stable foot baseline, and exports RGBA PNGs.
"""

from __future__ import annotations

from dataclasses import dataclass
import math
from pathlib import Path

import cv2
import numpy as np
from PIL import Image


PROJECT_ROOT = Path(__file__).resolve().parents[1]
ART_ROOT = PROJECT_ROOT / "美术开发/元素提取/精灵动画"
MONSTER_ROOT = PROJECT_ROOT / "assets/images/monsters/monster"
FRAME_COUNT = 16
FRAME_SIZE = 256
BASELINE_Y = 244
MAIN_COMPONENT_MIN_AREA = 10_000
AUX_COMPONENT_MIN_AREA = 20
COMPONENT_DILATION_PX = 2


@dataclass(frozen=True)
class IdleSheetSpec:
    chroma_source_path: Path
    sheet_path: Path
    target_long_edge: int
    preserve_pink_details: bool = False


SPECS = {
    monster_id: IdleSheetSpec(
        chroma_source_path=ART_ROOT / monster_id / "idle_image2_animation_sheet_v2.png",
        sheet_path=ART_ROOT / monster_id / "idle_image2_animation_sheet_v2_rgba.png",
        target_long_edge=target_long_edge,
        preserve_pink_details=monster_id == "monster_002",
    )
    for monster_id, target_long_edge in {
        "monster_002": 228,
        "monster_053": 224,
        "monster_093": 228,
    }.items()
}


def _remove_chroma_key_preserve_pinks(source: Image.Image) -> Image.Image:
    """Build a color-distance matte without erasing the rabbit's pink flower."""
    rgb = np.asarray(source.convert("RGB")).astype(np.float32)
    border = np.concatenate(
        (
            rgb[:8].reshape(-1, 3),
            rgb[-8:].reshape(-1, 3),
            rgb[:, :8].reshape(-1, 3),
            rgb[:, -8:].reshape(-1, 3),
        )
    )
    key = np.median(border, axis=0)
    distance = np.linalg.norm(rgb - key, axis=2)
    matte = np.clip((distance - 30.0) / (105.0 - 30.0), 0.0, 1.0)
    matte = matte * matte * (3.0 - 2.0 * matte)
    alpha = matte[:, :, np.newaxis]
    foreground = np.where(
        alpha > 0.02,
        (rgb - key * (1.0 - alpha)) / np.maximum(alpha, 0.02),
        0.0,
    )
    result = np.zeros((*rgb.shape[:2], 4), dtype=np.uint8)
    result[:, :, :3] = np.clip(foreground, 0.0, 255.0).astype(np.uint8)
    result[:, :, 3] = np.rint(matte * 255.0).astype(np.uint8)
    return Image.fromarray(result, "RGBA")


def _component_masks(sheet: Image.Image) -> list[np.ndarray]:
    rgba = np.asarray(sheet)
    alpha = rgba[:, :, 3]
    binary = (alpha >= 32).astype(np.uint8)
    count, labels, stats, centroids = cv2.connectedComponentsWithStats(binary, 8)

    main_labels = [
        label
        for label in range(1, count)
        if int(stats[label, cv2.CC_STAT_AREA]) >= MAIN_COMPONENT_MIN_AREA
    ]
    if len(main_labels) != FRAME_COUNT:
        raise ValueError(f"Expected {FRAME_COUNT} creature components, found {len(main_labels)}")

    sheet_height, sheet_width = alpha.shape
    main_labels.sort(
        key=lambda label: (
            min(3, int(float(centroids[label][1]) / (sheet_height / 4.0))),
            float(centroids[label][0]),
        )
    )

    assigned_labels: list[list[int]] = [[label] for label in main_labels]
    for label in range(1, count):
        if label in main_labels:
            continue
        area = int(stats[label, cv2.CC_STAT_AREA])
        if area < AUX_COMPONENT_MIN_AREA:
            continue
        center = centroids[label]
        nearest_index = min(
            range(FRAME_COUNT),
            key=lambda index: float(np.linalg.norm(center - centroids[main_labels[index]])),
        )
        assigned_labels[nearest_index].append(label)

    kernel = np.ones((3, 3), dtype=np.uint8)
    masks: list[np.ndarray] = []
    for group in assigned_labels:
        mask = np.isin(labels, group).astype(np.uint8)
        mask = cv2.dilate(mask, kernel, iterations=COMPONENT_DILATION_PX)
        masks.append(mask.astype(bool))
    return masks


def _extract_sprites(sheet: Image.Image) -> list[Image.Image]:
    rgba = np.asarray(sheet).copy()
    sprites: list[Image.Image] = []
    for mask in _component_masks(sheet):
        isolated = rgba.copy()
        isolated[~mask] = 0
        image = Image.fromarray(isolated, "RGBA")
        bbox = image.getchannel("A").point(lambda value: 255 if value >= 8 else 0).getbbox()
        if bbox is None:
            raise ValueError("Extracted an empty idle frame")
        sprites.append(image.crop(bbox))
    return sprites


def _render_frames(sprites: list[Image.Image], target_long_edge: int) -> list[Image.Image]:
    visible_areas = [
        float(np.asarray(sprite.getchannel("A"), dtype=np.float32).sum() / 255.0)
        for sprite in sprites
    ]
    target_visible_area = min(
        area * (target_long_edge / float(max(sprite.size))) ** 2
        for sprite, area in zip(sprites, visible_areas, strict=True)
    )
    frames: list[Image.Image] = []
    for sprite, visible_area in zip(sprites, visible_areas, strict=True):
        # image-2 may draw later cells slightly smaller even when the pose is
        # correct. Equalizing opaque area removes that unwanted sheet-layout
        # scale drift while retaining the true ear, eye, paw, tail, and flame
        # shape changes inside each frame.
        frame_scale = math.sqrt(target_visible_area / visible_area)
        size = (
            max(1, round(sprite.width * frame_scale)),
            max(1, round(sprite.height * frame_scale)),
        )
        resized = sprite.resize(size, Image.Resampling.LANCZOS)
        x = (FRAME_SIZE - resized.width) // 2
        y = BASELINE_Y - resized.height
        canvas = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
        canvas.alpha_composite(resized, (x, y))
        frames.append(canvas)
    return frames


def build_starter_idle_frames() -> None:
    for monster_id, spec in SPECS.items():
        if not spec.sheet_path.exists():
            raise FileNotFoundError(
                f"Missing transparent image-2 sheet: {spec.sheet_path}\n"
                "Run remove_chroma_key.py on idle_image2_animation_sheet_v2.png first."
            )
        if spec.preserve_pink_details:
            if not spec.chroma_source_path.exists():
                raise FileNotFoundError(f"Missing image-2 chroma source: {spec.chroma_source_path}")
            sheet = _remove_chroma_key_preserve_pinks(Image.open(spec.chroma_source_path))
        else:
            sheet = Image.open(spec.sheet_path).convert("RGBA")
        sprites = _extract_sprites(sheet)
        frames = _render_frames(sprites, spec.target_long_edge)
        output_dir = MONSTER_ROOT / monster_id / "idle"
        output_dir.mkdir(parents=True, exist_ok=True)
        for frame_index, frame in enumerate(frames):
            frame.save(output_dir / f"idle_{frame_index:03d}.png", format="PNG", optimize=True)
        print(f"{monster_id}: {len(frames)} animated idle frames -> {output_dir}")


if __name__ == "__main__":
    build_starter_idle_frames()
