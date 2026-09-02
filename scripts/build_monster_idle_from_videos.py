#!/usr/bin/env python3
"""Build the three starter idle sequences from downloaded Doubao videos.

Each source is a square four-second Seedance 2.0 Mini clip generated from an
image-2 creature portrait on a magenta backdrop. The script samples exactly
16 frames across the clip, removes only magenta regions connected to the
canvas border, clears Doubao's small disconnected bottom watermark residue,
and resizes the whole fixed-camera frame to 256x256. It never re-centers or
independently scales the creature between frames.
"""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path
import sys

import cv2
import numpy as np
from PIL import Image


PROJECT_ROOT = Path(__file__).resolve().parents[1]
ART_ROOT = PROJECT_ROOT / "美术开发/元素提取/精灵动画"
RUNTIME_ROOT = PROJECT_ROOT / "assets/images/monsters/monster"
FRAME_COUNT = 16
OUTPUT_SIZE = 256
VIDEO_FILENAME = "idle_seedance_2_mini_4s.mp4"

STARTER_IDS = ("monster_002", "monster_053", "monster_093")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "monster_ids",
        nargs="*",
        choices=STARTER_IDS,
        default=list(STARTER_IDS),
        help="Starter IDs to rebuild; defaults to all three.",
    )
    return parser.parse_args()


def _sample_video(video_path: Path) -> list[np.ndarray]:
    capture = cv2.VideoCapture(str(video_path))
    if not capture.isOpened():
        raise RuntimeError(f"Cannot open video: {video_path}")
    frame_total = int(capture.get(cv2.CAP_PROP_FRAME_COUNT))
    if frame_total < FRAME_COUNT:
        capture.release()
        raise RuntimeError(
            f"{video_path} has only {frame_total} frames; need at least {FRAME_COUNT}"
        )
    indices = np.floor(
        np.linspace(0, frame_total, FRAME_COUNT, endpoint=False)
    ).astype(int)
    frames: list[np.ndarray] = []
    for frame_index in indices:
        capture.set(cv2.CAP_PROP_POS_FRAMES, int(frame_index))
        ok, frame_bgr = capture.read()
        if not ok:
            capture.release()
            raise RuntimeError(f"Cannot read frame {frame_index} from {video_path}")
        frames.append(cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2RGB))
    capture.release()
    return frames


def _border_connected(mask: np.ndarray) -> np.ndarray:
    """Return mask components that touch at least one canvas edge."""

    component_count, labels = cv2.connectedComponents(mask.astype(np.uint8), 8)
    if component_count <= 1:
        return np.zeros_like(mask, dtype=bool)
    border_labels = set(
        np.unique(
            np.concatenate(
                (labels[0, :], labels[-1, :], labels[:, 0], labels[:, -1])
            )
        )
    )
    border_labels.discard(0)
    if not border_labels:
        return np.zeros_like(mask, dtype=bool)
    return np.isin(labels, tuple(border_labels))


def _estimate_magenta_key(rgb: np.ndarray) -> np.ndarray:
    height, width = rgb.shape[:2]
    thickness = max(2, min(height, width) // 40)
    border = np.concatenate(
        (
            rgb[:thickness].reshape(-1, 3),
            rgb[-thickness:].reshape(-1, 3),
            rgb[:, :thickness].reshape(-1, 3),
            rgb[:, -thickness:].reshape(-1, 3),
        )
    ).astype(np.float32)
    magenta_score = border[:, 0] + border[:, 2] - 2.0 * border[:, 1]
    likely_key = border[magenta_score >= np.percentile(magenta_score, 40)]
    return np.median(likely_key, axis=0)


def _remove_magenta(rgb: np.ndarray) -> np.ndarray:
    key_rgb = _estimate_magenta_key(rgb)
    key_pixel = np.uint8([[np.clip(key_rgb, 0, 255)]])
    key_lab = cv2.cvtColor(key_pixel, cv2.COLOR_RGB2LAB)[0, 0].astype(np.float32)
    lab = cv2.cvtColor(rgb, cv2.COLOR_RGB2LAB).astype(np.float32)
    distance = np.linalg.norm(lab - key_lab, axis=2)

    rgb_i16 = rgb.astype(np.int16)
    magenta_like = (
        (rgb_i16[..., 0] - rgb_i16[..., 1] > 35)
        & (rgb_i16[..., 2] - rgb_i16[..., 1] > 25)
        & (rgb_i16[..., 0] > 130)
        & (rgb_i16[..., 2] > 105)
    )
    # Remove near-key pixels even when a limb, branch, or accessory encloses
    # the background. Only the high-confidence key range is global; the loose
    # compression range must still connect to the canvas edge so character
    # colors close to magenta remain protected.
    core_background = (distance < 50.0) & magenta_like
    loose_background = _border_connected((distance < 92.0) & magenta_like)
    loose_background = cv2.morphologyEx(
        loose_background.astype(np.uint8),
        cv2.MORPH_CLOSE,
        np.ones((3, 3), np.uint8),
    ).astype(bool)
    keyed_background = core_background | loose_background

    alpha = np.full(distance.shape, 255.0, dtype=np.float32)
    matte = np.clip((distance - 10.0) / (64.0 - 10.0), 0.0, 1.0)
    alpha[keyed_background] = matte[keyed_background] * 255.0
    alpha[core_background] = 0.0
    alpha[alpha < 3.0] = 0.0

    output_rgb = rgb.astype(np.float32)
    fractional = (alpha > 0.0) & (alpha < 255.0)
    if np.any(fractional):
        edge_rgb = output_rgb[fractional]
        spill = np.maximum(
            np.minimum(edge_rgb[:, 0], edge_rgb[:, 2]) - edge_rgb[:, 1],
            0.0,
        )
        edge_rgb[:, 0] -= spill
        edge_rgb[:, 2] -= spill
        output_rgb[fractional] = np.clip(edge_rgb, 0.0, 255.0)
    output_rgb[alpha == 0.0] = 0.0
    return np.dstack((output_rgb.astype(np.uint8), alpha.astype(np.uint8)))


def _cleanup_bottom_artifacts(rgba: np.ndarray) -> np.ndarray:
    """Clear magenta ground residue and Doubao's isolated bottom watermark."""

    height, width = rgba.shape[:2]
    cleaned = rgba.copy()
    rgb_i16 = cleaned[..., :3].astype(np.int16)
    bottom_band = np.indices((height, width))[0] >= int(round(height * 0.72))
    magenta_like = (
        (rgb_i16[..., 0] - rgb_i16[..., 1] > 18)
        & (rgb_i16[..., 2] - rgb_i16[..., 1] > 12)
        & (np.minimum(rgb_i16[..., 0], rgb_i16[..., 2]) > 45)
    )
    magenta_ground = bottom_band & _border_connected(magenta_like)
    cleaned[magenta_ground] = 0

    foreground = (cleaned[..., 3] > 0).astype(np.uint8)
    component_count, labels, stats, _ = cv2.connectedComponentsWithStats(
        foreground, 8
    )
    if component_count <= 1:
        return cleaned

    bottom_band_y = int(round(height * 0.82))
    max_island_area = int(round(height * width * 0.02))
    for component_id in range(1, component_count):
        x, y, component_width, component_height, area = stats[component_id]
        if (
            y < bottom_band_y
            or x < int(round(width * 0.50))
            or area > max_island_area
        ):
            continue
        cleaned[labels == component_id] = 0
    return cleaned


def _resize_fixed_camera(rgba: np.ndarray) -> np.ndarray:
    interpolation = (
        cv2.INTER_AREA
        if max(rgba.shape[:2]) > OUTPUT_SIZE
        else cv2.INTER_LANCZOS4
    )
    return cv2.resize(
        rgba,
        (OUTPUT_SIZE, OUTPUT_SIZE),
        interpolation=interpolation,
    )


def _normalized_pose_hash(rgba: np.ndarray) -> str:
    alpha = rgba[..., 3]
    points = cv2.findNonZero((alpha > 8).astype(np.uint8))
    if points is None:
        return ""
    x, y, width, height = cv2.boundingRect(points)
    pose = rgba[y : y + height, x : x + width]
    pose = cv2.resize(pose, (96, 96), interpolation=cv2.INTER_AREA)
    return hashlib.sha256(pose.tobytes()).hexdigest()


def _validate(frames: list[np.ndarray], monster_id: str) -> None:
    if len(frames) != FRAME_COUNT:
        raise RuntimeError(f"{monster_id}: expected {FRAME_COUNT} frames")
    raw_hashes = {hashlib.sha256(frame.tobytes()).hexdigest() for frame in frames}
    pose_hashes = {_normalized_pose_hash(frame) for frame in frames}
    if len(raw_hashes) != FRAME_COUNT:
        raise RuntimeError(f"{monster_id}: sampled frames are not all distinct")
    if len(pose_hashes) < 12:
        raise RuntimeError(
            f"{monster_id}: only {len(pose_hashes)} normalized poses; "
            "the clip lacks enough internal animation"
        )
    for index, frame in enumerate(frames):
        if frame.shape != (OUTPUT_SIZE, OUTPUT_SIZE, 4):
            raise RuntimeError(f"{monster_id} frame {index}: invalid shape {frame.shape}")
        if any(frame[y, x, 3] != 0 for x, y in ((0, 0), (255, 0), (0, 255), (255, 255))):
            raise RuntimeError(
                f"{monster_id} frame {index}: canvas corner is not transparent"
            )


def build_monster(monster_id: str) -> None:
    video_path = ART_ROOT / monster_id / "doubao_video" / VIDEO_FILENAME
    if not video_path.exists():
        raise FileNotFoundError(video_path)
    sampled = _sample_video(video_path)
    finished = [
        _resize_fixed_camera(_cleanup_bottom_artifacts(_remove_magenta(frame)))
        for frame in sampled
    ]
    _validate(finished, monster_id)

    output_dir = RUNTIME_ROOT / monster_id / "idle"
    output_dir.mkdir(parents=True, exist_ok=True)
    for index, frame in enumerate(finished):
        Image.fromarray(frame, "RGBA").save(
            output_dir / f"idle_{index:03d}.png",
            optimize=True,
        )
    print(f"{monster_id}: wrote {FRAME_COUNT} video-derived idle frames")


def main() -> int:
    args = parse_args()
    try:
        for monster_id in args.monster_ids:
            build_monster(monster_id)
    except (FileNotFoundError, RuntimeError) as error:
        print(f"[build_monster_idle_from_videos] {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
