#!/usr/bin/env python3
"""Build and split the 2x2 Doubao starter-creature animation workflow.

The generated input grid keeps the three starter portraits unchanged and uses
monster_003 as a fourth, sacrificial cell. The helper cell gives the video
model four visibly different original game creatures and also keeps Doubao's
bottom-right watermark away from the three runtime cells.

After the 1:1 four-second Seedance 2.0 Mini clip is downloaded, the script:

1. samples exactly 16 fixed-camera frames;
2. splits the top-left, top-right, and bottom-left grid cells;
3. converts border-connected magenta to alpha;
4. clears small bottom artifacts and resizes each cell to 256x256;
5. validates real per-frame pose changes before replacing runtime idle frames.
"""

from __future__ import annotations

import argparse
from pathlib import Path
import sys

import cv2
import numpy as np
from PIL import Image

from build_monster_idle_from_videos import (
    ART_ROOT,
    FRAME_COUNT,
    RUNTIME_ROOT,
    _border_connected,
    _cleanup_bottom_artifacts,
    _remove_magenta,
    _resize_fixed_camera,
    _sample_video,
    _validate,
)


PROJECT_ROOT = Path(__file__).resolve().parents[1]
QUAD_ROOT = ART_ROOT / "starter_idle_quad_2x2"
QUAD_INPUT = QUAD_ROOT / "image2_original_characters_quad_2x2.png"
QUAD_VIDEO = QUAD_ROOT / "idle_seedance_2_mini_4s.mp4"

CELL_SIZE = 1024
GUTTER = 16
GRID_SIZE = CELL_SIZE * 2 + GUTTER
MAGENTA = (255, 0, 255, 255)

# The bottom-right helper is intentionally not exported to runtime frames.
CELLS = (
    (
        "monster_002",
        ART_ROOT / "monster_002/doubao_video/image2_magenta_input_flat.png",
        0,
        0,
        True,
    ),
    (
        "monster_053",
        ART_ROOT / "monster_053/doubao_video/image2_magenta_input_flat.png",
        1,
        0,
        True,
    ),
    (
        "monster_093",
        ART_ROOT / "monster_093/doubao_video/image2_magenta_input_flat.png",
        0,
        1,
        True,
    ),
    (
        "monster_003",
        PROJECT_ROOT / "assets/images/monsters/monster/monster_003.png",
        1,
        1,
        False,
    ),
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--input-only",
        action="store_true",
        help="Only build the 2x2 upload image; do not require a video.",
    )
    return parser.parse_args()


def _flatten_to_magenta(source_path: Path) -> Image.Image:
    if not source_path.exists():
        raise FileNotFoundError(source_path)
    source = Image.open(source_path).convert("RGBA")
    source = source.resize((CELL_SIZE, CELL_SIZE), Image.Resampling.LANCZOS)
    cell = Image.new("RGBA", (CELL_SIZE, CELL_SIZE), MAGENTA)
    cell.alpha_composite(source)
    return cell


def build_quad_input() -> None:
    canvas = Image.new("RGBA", (GRID_SIZE, GRID_SIZE), MAGENTA)
    for _, source_path, column, row, _ in CELLS:
        cell = _flatten_to_magenta(source_path)
        x = column * (CELL_SIZE + GUTTER)
        y = row * (CELL_SIZE + GUTTER)
        canvas.alpha_composite(cell, (x, y))
    QUAD_ROOT.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(QUAD_INPUT, optimize=True)
    print(f"2x2 input: wrote {QUAD_INPUT} ({GRID_SIZE}x{GRID_SIZE})")


def _find_center_gutter(scores: np.ndarray) -> tuple[int, int]:
    """Find the model-rendered white separator band nearest frame center."""

    axis_size = scores.shape[0]
    center_min = round(axis_size * 0.35)
    center_max = round(axis_size * 0.65)
    candidates = np.flatnonzero(scores > 0.68)
    candidates = candidates[
        (candidates >= center_min) & (candidates < center_max)
    ]
    if candidates.size == 0:
        fallback_start = round(CELL_SIZE / GRID_SIZE * axis_size)
        fallback_end = round((CELL_SIZE + GUTTER) / GRID_SIZE * axis_size)
        return fallback_start, fallback_end

    groups = np.split(candidates, np.where(np.diff(candidates) != 1)[0] + 1)
    center = axis_size / 2.0
    best = max(
        groups,
        key=lambda group: (
            len(group),
            -abs(float(group.mean()) - center),
        ),
    )
    return int(best[0]), int(best[-1] + 1)


def _detect_grid_gutters(frame: np.ndarray) -> tuple[int, int, int, int]:
    minimum = frame.min(axis=2)
    spread = frame.max(axis=2) - minimum
    near_white = (minimum > 205) & (spread < 62)
    x_start, x_end = _find_center_gutter(near_white.mean(axis=0))
    y_start, y_end = _find_center_gutter(near_white.mean(axis=1))
    return x_start, x_end, y_start, y_end


def _cell_bounds(
    frame: np.ndarray, column: int, row: int
) -> tuple[int, int, int, int]:
    height, width = frame.shape[:2]
    x_gutter_start, x_gutter_end, y_gutter_start, y_gutter_end = (
        _detect_grid_gutters(frame)
    )
    x0, x1 = (
        (0, x_gutter_start)
        if column == 0
        else (x_gutter_end, width)
    )
    y0, y1 = (
        (0, y_gutter_start)
        if row == 0
        else (y_gutter_end, height)
    )
    return x0, y0, x1, y1


def _remove_border_white(rgba: np.ndarray) -> np.ndarray:
    """Remove white grid separators/rounded corners connected to cell edges."""

    rgb = rgba[..., :3]
    minimum = rgb.min(axis=2)
    spread = rgb.max(axis=2) - minimum
    near_white = (minimum > 165) & (spread < 72)
    border_white = _border_connected(near_white)
    cleaned = rgba.copy()
    cleaned[border_white] = 0
    return cleaned


def _remove_border_magenta_residue(rgba: np.ndarray) -> np.ndarray:
    """Clear pale/gradient magenta that video compression moved off key color."""

    rgb_i16 = rgba[..., :3].astype(np.int16)
    magenta_like = (
        (rgb_i16[..., 0] - rgb_i16[..., 1] > 12)
        & (rgb_i16[..., 2] - rgb_i16[..., 1] > 10)
        & (np.minimum(rgb_i16[..., 0], rgb_i16[..., 2]) > 65)
    )
    border_magenta = _border_connected(magenta_like)
    cleaned = rgba.copy()
    cleaned[border_magenta] = 0
    return cleaned


def _refine_foreground(cell_rgb: np.ndarray, rgba: np.ndarray) -> np.ndarray:
    """Use chroma-derived foreground seeds to reject model-added gray shadows."""

    rgb_i16 = cell_rgb.astype(np.int16)
    minimum = rgb_i16.min(axis=2)
    maximum = rgb_i16.max(axis=2)
    spread = maximum - minimum
    magenta_like = (
        (rgb_i16[..., 0] - rgb_i16[..., 1] > 12)
        & (rgb_i16[..., 2] - rgb_i16[..., 1] > 10)
        & (np.minimum(rgb_i16[..., 0], rgb_i16[..., 2]) > 65)
    )
    colorful_subject = (spread > 36) & ~magenta_like
    bright_neutral_subject = (minimum > 150) & (spread < 58)
    opaque = rgba[..., 3] > 210
    subject_seed = opaque & (colorful_subject | bright_neutral_subject)

    mask = np.full(cell_rgb.shape[:2], cv2.GC_PR_BGD, dtype=np.uint8)
    mask[rgba[..., 3] == 0] = cv2.GC_BGD
    mask[subject_seed] = cv2.GC_FGD
    if not np.any(mask == cv2.GC_FGD) or not np.any(mask == cv2.GC_BGD):
        return rgba

    background_model = np.zeros((1, 65), np.float64)
    foreground_model = np.zeros((1, 65), np.float64)
    cv2.grabCut(
        cv2.cvtColor(cell_rgb, cv2.COLOR_RGB2BGR),
        mask,
        None,
        background_model,
        foreground_model,
        4,
        cv2.GC_INIT_WITH_MASK,
    )
    foreground = np.isin(mask, (cv2.GC_FGD, cv2.GC_PR_FGD)).astype(np.uint8)
    foreground = cv2.morphologyEx(
        foreground,
        cv2.MORPH_CLOSE,
        np.ones((3, 3), np.uint8),
    )
    soft_foreground = cv2.GaussianBlur(
        foreground.astype(np.float32),
        (3, 3),
        0.55,
    )
    cleaned = rgba.copy()
    cleaned[..., 3] = np.minimum(
        cleaned[..., 3].astype(np.float32),
        soft_foreground * 255.0,
    ).astype(np.uint8)
    cleaned[cleaned[..., 3] == 0, :3] = 0
    return cleaned


def _finish_cell(
    frame: np.ndarray,
    column: int,
    row: int,
    refine_foreground: bool = True,
) -> np.ndarray:
    x0, y0, x1, y1 = _cell_bounds(frame, column, row)
    cell_rgb = frame[y0:y1, x0:x1]
    if cell_rgb.size == 0:
        raise RuntimeError(
            f"Empty grid cell at column={column}, row={row}: "
            f"bounds={(x0, y0, x1, y1)}"
        )
    rgba = _remove_magenta(cell_rgb)
    rgba = _remove_border_magenta_residue(rgba)
    rgba = _remove_border_white(rgba)
    if refine_foreground:
        rgba = _refine_foreground(cell_rgb, rgba)
    rgba = _cleanup_bottom_artifacts(rgba)
    finished = _resize_fixed_camera(rgba)
    finished[:2, :] = 0
    finished[-2:, :] = 0
    finished[:, :2] = 0
    finished[:, -2:] = 0
    return finished


def build_runtime_frames() -> None:
    if not QUAD_VIDEO.exists():
        raise FileNotFoundError(QUAD_VIDEO)
    sampled = _sample_video(QUAD_VIDEO)
    for monster_id, _, column, row, export_runtime in CELLS:
        if not export_runtime:
            continue
        finished = [_finish_cell(frame, column, row) for frame in sampled]
        _validate(finished, monster_id)
        output_dir = RUNTIME_ROOT / monster_id / "idle"
        output_dir.mkdir(parents=True, exist_ok=True)
        for index, frame in enumerate(finished):
            Image.fromarray(frame, "RGBA").save(
                output_dir / f"idle_{index:03d}.png",
                optimize=True,
            )
        print(
            f"{monster_id}: wrote {FRAME_COUNT} quad-video-derived idle frames"
        )


def main() -> int:
    args = parse_args()
    try:
        build_quad_input()
        if not args.input_only:
            build_runtime_frames()
    except (FileNotFoundError, RuntimeError) as error:
        print(f"[build_starter_idle_quad] {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
