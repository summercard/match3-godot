#!/usr/bin/env python3
"""Build and split configured 2x2 monster-idle video batches."""

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
    _sample_video,
    _validate,
)
from build_starter_idle_quad import (
    CELL_SIZE,
    GRID_SIZE,
    GUTTER,
    MAGENTA,
    PROJECT_ROOT,
    _finish_cell,
    _flatten_to_magenta,
)


BATCH_ROOT = ART_ROOT / "monster_idle_quad_batches"
INPUT_FILENAME = "original_characters_quad_2x2.png"
VIDEO_FILENAME = "idle_seedance_2_mini_4s.mp4"


def _monster_source(monster_id: str) -> Path:
    category = "boss" if monster_id.startswith("monster_boss_") else "monster"
    return (
        PROJECT_ROOT
        / "assets/images/monsters"
        / category
        / f"{monster_id}.png"
    )


def _runtime_monster_root(monster_id: str) -> Path:
    if monster_id.startswith("monster_boss_"):
        return PROJECT_ROOT / "assets/images/monsters/boss" / monster_id
    return RUNTIME_ROOT / monster_id


# Groups 01-06 used a bottom-right helper to absorb the watermark. Starting
# with group_07 every cell is a formal target: four unique creatures per batch.
GROUPS = {
    "group_01": (
        ("monster_001", 0, 0, True),
        ("monster_003", 1, 0, True),
        ("monster_004", 0, 1, True),
        ("monster_005", 1, 1, False),
    ),
    "group_02": (
        ("monster_005", 0, 0, True),
        ("monster_006", 1, 0, True),
        ("monster_007", 0, 1, True),
        ("monster_008", 1, 1, False),
    ),
    "group_03": (
        ("monster_008", 0, 0, True),
        ("monster_009", 1, 0, True),
        ("monster_010", 0, 1, True),
        ("monster_011", 1, 1, False),
    ),
    "group_04": (
        ("monster_011", 0, 0, True),
        ("monster_012", 1, 0, True),
        ("monster_013", 0, 1, True),
        ("monster_014", 1, 1, False),
    ),
    "group_05": (
        ("monster_014", 0, 0, True),
        ("monster_015", 1, 0, True),
        ("monster_016", 0, 1, True),
        ("monster_017", 1, 1, False),
    ),
    "group_06": (
        ("monster_018", 0, 0, True),
        ("monster_019", 1, 0, True),
        ("monster_020", 0, 1, True),
        ("monster_021", 1, 1, False),
    ),
    "group_07": (
        ("monster_022", 0, 0, True),
        ("monster_023", 1, 0, True),
        ("monster_024", 0, 1, True),
        ("monster_025", 1, 1, True),
    ),
    "group_08": (
        ("monster_026", 0, 0, True),
        ("monster_027", 1, 0, True),
        ("monster_028", 0, 1, True),
        ("monster_029", 1, 1, True),
    ),
    "group_09": (
        ("monster_030", 0, 0, True),
        ("monster_031", 1, 0, True),
        ("monster_032", 0, 1, True),
        ("monster_033", 1, 1, True),
    ),
    "group_10": (
        ("monster_034", 0, 0, True),
        ("monster_035", 1, 0, True),
        ("monster_036", 0, 1, True),
        ("monster_037", 1, 1, True),
    ),
    "group_11": (
        ("monster_038", 0, 0, True),
        ("monster_039", 1, 0, True),
        ("monster_040", 0, 1, True),
        ("monster_041", 1, 1, True),
    ),
    "group_12": (
        ("monster_042", 0, 0, True),
        ("monster_043", 1, 0, True),
        ("monster_044", 0, 1, True),
        ("monster_045", 1, 1, True),
    ),
   "group_13": (
       ("monster_046", 0, 0, True),
       ("monster_047", 1, 0, True),
       ("monster_048", 0, 1, True),
       ("monster_049", 1, 1, True),
   ),
    "group_14": (
        ("monster_050", 0, 0, True),
        ("monster_051", 1, 0, True),
        ("monster_052", 0, 1, True),
        ("monster_054", 1, 1, True),
    ),
    "group_15": (
        ("monster_055", 0, 0, True),
        ("monster_056", 1, 0, True),
        ("monster_057", 0, 1, True),
        ("monster_058", 1, 1, True),
    ),
    "group_16": (
        ("monster_059", 0, 0, True),
        ("monster_060", 1, 0, True),
        ("monster_061", 0, 1, True),
        ("monster_062", 1, 1, True),
    ),
    "group_17": (
        ("monster_063", 0, 0, True),
        ("monster_064", 1, 0, True),
        ("monster_065", 0, 1, True),
        ("monster_066", 1, 1, True),
    ),
    "group_18": (
        ("monster_067", 0, 0, True),
        ("monster_068", 1, 0, True),
        ("monster_069", 0, 1, True),
        ("monster_070", 1, 1, True),
    ),
    "group_19": (
        ("monster_071", 0, 0, True),
        ("monster_072", 1, 0, True),
        ("monster_073", 0, 1, True),
        ("monster_074", 1, 1, True),
    ),
    "group_20": (
        ("monster_075", 0, 0, True),
        ("monster_076", 1, 0, True),
        ("monster_077", 0, 1, True),
        ("monster_078", 1, 1, True),
    ),
    "group_21": (
        ("monster_079", 0, 0, True),
        ("monster_080", 1, 0, True),
        ("monster_081", 0, 1, True),
        ("monster_082", 1, 1, True),
    ),
    "group_22": (
        ("monster_083", 0, 0, True),
        ("monster_084", 1, 0, True),
        ("monster_085", 0, 1, True),
        ("monster_086", 1, 1, True),
    ),
    "group_23": (
        ("monster_087", 0, 0, True),
        ("monster_088", 1, 0, True),
        ("monster_089", 0, 1, True),
        ("monster_090", 1, 1, True),
    ),
    "group_24": (
        ("monster_091", 0, 0, True),
        ("monster_092", 1, 0, True),
        ("monster_094", 0, 1, True),
        ("monster_095", 1, 1, True),
    ),
    "group_25": (
        ("monster_096", 0, 0, True),
        ("monster_097", 1, 0, True),
        ("monster_098", 0, 1, True),
        ("monster_099", 1, 1, True),
    ),
    "group_26": (
        ("monster_100", 0, 0, True),
        ("monster_101", 1, 0, True),
        ("monster_102", 0, 1, True),
        ("monster_103", 1, 1, True),
    ),
    "group_27": (
        ("monster_boss_001", 0, 0, True),
        ("monster_boss_002", 1, 0, True),
        ("monster_boss_003", 0, 1, True),
        ("monster_boss_004", 1, 1, True),
    ),
    "group_28": (
        ("monster_boss_005", 0, 0, True),
        ("monster_boss_006", 1, 0, True),
        ("monster_boss_007", 0, 1, True),
        ("monster_boss_008", 1, 1, True),
    ),
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--group",
        action="append",
        choices=tuple(GROUPS),
        help="Group to build; repeat for several. Defaults to all groups.",
    )
    parser.add_argument(
        "--input-only",
        action="store_true",
        help="Only build upload images; do not require downloaded videos.",
    )
    return parser.parse_args()


def _group_root(group_name: str) -> Path:
    return BATCH_ROOT / group_name


def _read_video_frame(video_path: Path, frame_index: int) -> np.ndarray:
    capture = cv2.VideoCapture(str(video_path))
    if not capture.isOpened():
        raise RuntimeError(f"Cannot open video: {video_path}")
    capture.set(cv2.CAP_PROP_POS_FRAMES, frame_index)
    ok, frame_bgr = capture.read()
    capture.release()
    if not ok:
        raise RuntimeError(f"Cannot read frame {frame_index} from {video_path}")
    return cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2RGB)


def _make_watermark_safe_cell(cell: Image.Image) -> Image.Image:
    """Reserve clean bottom-right space when that cell is a formal target."""

    scale = 0.86
    target_size = int(round(CELL_SIZE * scale))
    resized = cell.resize(
        (target_size, target_size),
        Image.Resampling.LANCZOS,
    )
    safe_cell = Image.new("RGBA", (CELL_SIZE, CELL_SIZE), MAGENTA)
    x = (CELL_SIZE - target_size) // 2 - 18
    y = (CELL_SIZE - target_size) // 2 - 38
    safe_cell.alpha_composite(resized, (x, y))
    return safe_cell


def _make_subject_margin_cell(cell: Image.Image) -> Image.Image:
    """Keep large silhouettes away from the video frame and grid edges."""

    scale = 0.94
    target_size = int(round(CELL_SIZE * scale))
    resized = cell.resize(
        (target_size, target_size),
        Image.Resampling.LANCZOS,
    )
    safe_cell = Image.new("RGBA", (CELL_SIZE, CELL_SIZE), MAGENTA)
    offset = (CELL_SIZE - target_size) // 2
    safe_cell.alpha_composite(resized, (offset, offset))
    return safe_cell


def _erase_bottom_right_source_watermark(cell: Image.Image) -> Image.Image:
    """Remove a legacy generator mark that sits outside the subject."""

    cleaned = cell.copy()
    cleaned.paste(MAGENTA, (780, 930, CELL_SIZE, CELL_SIZE))
    return cleaned


def build_group_input(group_name: str) -> None:
    canvas = Image.new("RGBA", (GRID_SIZE, GRID_SIZE), MAGENTA)
    for monster_id, column, row, _ in GROUPS[group_name]:
        cell = _flatten_to_magenta(_monster_source(monster_id))
        if monster_id in ("monster_095", "monster_boss_007"):
            cell = _erase_bottom_right_source_watermark(cell)
        if group_name in (
            "group_23", "group_24", "group_25", "group_26",
            "group_27", "group_28",
        ) and not (column == 1 and row == 1):
            cell = _make_subject_margin_cell(cell)
        if group_name in (
           "group_07", "group_08", "group_09",
            "group_10", "group_11", "group_12", "group_13",
            "group_14", "group_15", "group_16", "group_17",
            "group_18", "group_19", "group_20", "group_21", "group_22",
            "group_23", "group_24", "group_25", "group_26",
            "group_27", "group_28",
        ) and column == 1 and row == 1:
            cell = _make_watermark_safe_cell(cell)
        x = column * (CELL_SIZE + GUTTER)
        y = row * (CELL_SIZE + GUTTER)
        canvas.alpha_composite(cell, (x, y))
    group_root = _group_root(group_name)
    group_root.mkdir(parents=True, exist_ok=True)
    output_path = group_root / INPUT_FILENAME
    canvas.convert("RGB").save(output_path, optimize=True)
    print(f"{group_name}: wrote {output_path} ({GRID_SIZE}x{GRID_SIZE})")


def _clean_temporal_edge_artifacts(frames: list[np.ndarray]) -> list[np.ndarray]:
    """Replace flickering neutral watermark fragments with the temporal median."""

    stack = np.stack(frames)
    median = np.median(stack.astype(np.float32), axis=0).astype(np.uint8)
    yy, xx = np.indices(stack.shape[1:3])
    cleanup_region = ((xx > 200) & (yy > 110)) | (yy > 195)
    cleaned_frames: list[np.ndarray] = []

    for frame in stack:
        rgb = frame[..., :3].astype(np.int16)
        median_rgb = median[..., :3].astype(np.int16)
        spread = rgb.max(axis=2) - rgb.min(axis=2)
        color_delta = np.linalg.norm(rgb - median_rgb, axis=2)
        alpha_delta = np.abs(
            frame[..., 3].astype(np.int16) - median[..., 3].astype(np.int16)
        )
        neutral = spread < 42
        extreme = (
            (rgb.max(axis=2) < 115)
            | (rgb.min(axis=2) > 215)
            | (alpha_delta > 80)
        )
        suspect = cleanup_region & neutral & extreme & (color_delta > 42)
        suspect = cv2.dilate(
            suspect.astype(np.uint8),
            np.ones((3, 3), np.uint8),
        ).astype(bool)
        cleaned = frame.copy()
        cleaned[suspect] = median[suspect]
        cleaned_frames.append(cleaned)

    cleaned_stack = np.stack(cleaned_frames)
    cleaned_median = np.median(
        cleaned_stack.astype(np.float32),
        axis=0,
    ).astype(np.uint8)
    final_frames: list[np.ndarray] = []
    for frame in cleaned_stack:
        rgb = frame[..., :3].astype(np.int16)
        spread = rgb.max(axis=2) - rgb.min(axis=2)
        right_dark = (
            (xx > 205)
            & (yy > 105)
            & (frame[..., 3] > 15)
            & (spread < 45)
            & (rgb.max(axis=2) < 125)
        )
        right_dark = cv2.dilate(
            right_dark.astype(np.uint8),
            np.ones((3, 3), np.uint8),
        ).astype(bool)
        cleaned = frame.copy()
        cleaned[right_dark] = cleaned_median[right_dark]
        final_frames.append(cleaned)
    return final_frames


def _keep_largest_alpha_component(frame: np.ndarray) -> np.ndarray:
    """Remove detached model trails while retaining the main antialiased sprite."""

    component_count, labels, stats, _ = cv2.connectedComponentsWithStats(
        (frame[..., 3] > 8).astype(np.uint8),
        8,
    )
    if component_count <= 2:
        return frame
    largest_component = 1 + int(np.argmax(stats[1:, cv2.CC_STAT_AREA]))
    keep = cv2.dilate(
        (labels == largest_component).astype(np.uint8),
        np.ones((3, 3), np.uint8),
    ).astype(bool)
    cleaned = frame.copy()
    cleaned[~keep] = 0
    return cleaned


def _remove_small_right_islands(frame: np.ndarray) -> np.ndarray:
    """Remove tiny detached model flecks without touching intended accessories."""

    component_count, labels, stats, _ = cv2.connectedComponentsWithStats(
        (frame[..., 3] > 8).astype(np.uint8),
        8,
    )
    cleaned = frame.copy()
    for component_id in range(1, component_count):
        x, y, width, height, area = stats[component_id]
        if x <= 220 or area >= 64:
            continue
        x0 = max(0, x - 2)
        y0 = max(0, y - 2)
        x1 = min(frame.shape[1], x + width + 2)
        y1 = min(frame.shape[0], y + height + 2)
        cleaned[y0:y1, x0:x1] = 0
    return cleaned


def _write_qa_assets(
    group_name: str,
    monster_id: str,
    frames: list[np.ndarray],
) -> None:
    """Write a 4x4 contact sheet and runtime-speed looping preview."""

    qa_dir = _group_root(group_name) / "qa"
    qa_dir.mkdir(parents=True, exist_ok=True)
    pil_frames = [Image.fromarray(frame, "RGBA") for frame in frames]
    contact_sheet = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    for index, frame in enumerate(pil_frames):
        x = (index % 4) * 256
        y = (index // 4) * 256
        contact_sheet.alpha_composite(frame, (x, y))
    contact_sheet.save(
        qa_dir / f"{monster_id}_contact_sheet.png",
        optimize=True,
    )
    pil_frames[0].save(
        qa_dir / f"{monster_id}_idle_8fps.gif",
        save_all=True,
        append_images=pil_frames[1:],
        # GIF stores delay in 10 ms units. Alternate 120/130 ms so the
        # 16-frame preview averages the runtime's exact 125 ms (8 FPS).
        duration=[120 if index % 2 == 0 else 130 for index in range(FRAME_COUNT)],
        loop=0,
        disposal=2,
        optimize=False,
    )


def build_group_runtime(group_name: str) -> None:
    video_path = _group_root(group_name) / VIDEO_FILENAME
    if not video_path.exists():
        raise FileNotFoundError(video_path)
    sampled = _sample_video(video_path)
    # The normally selected video frame 60 in these clips contains a
    # one-frame red/green color-separation glitch. Frame 61 is the adjacent
    # clean instant and preserves continuous motion without duplicating a frame.
    if group_name in (
        "group_05",
        "group_06",
        "group_07",
        "group_08",
        "group_09",
    ):
        sampled[10] = _read_video_frame(video_path, 61)
    # The normally selected frame 12 briefly corrupts the left bird's feet.
    # Frame 13 is the adjacent intact blink pose.
    if group_name == "group_06":
        sampled[2] = _read_video_frame(video_path, 13)
    for monster_id, column, row, export_runtime in GROUPS[group_name]:
        if not export_runtime:
            continue
        finished = [
            _finish_cell(
                frame,
                column,
                row,
            )
            for frame in sampled
        ]
        # monster_010's source PNG contains neutral streak residue around its
        # silhouette. The video model makes that residue flicker; clean only
        # those unstable edge pixels without touching the animated face/body.
        if monster_id == "monster_010":
            finished = _clean_temporal_edge_artifacts(finished)
        if monster_id in ("monster_018", "monster_019"):
            finished = [
                _keep_largest_alpha_component(frame)
                for frame in finished
            ]
        if monster_id == "monster_022":
            finished = [
                _remove_small_right_islands(frame)
                for frame in finished
            ]
            # Seedance briefly turns the rolled bedroll/cup at the backpack's
            # far-right edge into a tiny face. The camera is locked, so keep
            # that original-looking accessory region stable across the loop.
            reference_region = finished[0][48:105, 224:256].copy()
            for frame in finished:
                frame[48:105, 224:256] = reference_region
        if monster_id == "monster_029":
            # Remove a one-frame detached purple line at the left canvas edge.
            finished = [
                _keep_largest_alpha_component(frame)
                for frame in finished
            ]
        _validate(finished, monster_id)
        output_dir = _runtime_monster_root(monster_id) / "idle"
        output_dir.mkdir(parents=True, exist_ok=True)
        for index, frame in enumerate(finished):
            Image.fromarray(frame, "RGBA").save(
                output_dir / f"idle_{index:03d}.png",
                optimize=True,
            )
        _write_qa_assets(group_name, monster_id, finished)
        print(
            f"{group_name}/{monster_id}: wrote {FRAME_COUNT} idle frames"
        )


def main() -> int:
    args = parse_args()
    selected_groups = args.group or list(GROUPS)
    try:
        for group_name in selected_groups:
            build_group_input(group_name)
            if not args.input_only:
                build_group_runtime(group_name)
    except (FileNotFoundError, RuntimeError) as error:
        print(f"[build_monster_idle_quad_batches] {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
