#!/usr/bin/env python3
"""Regression tests for magenta-only monster idle transparency cleanup."""

from __future__ import annotations

from pathlib import Path
import sys
import unittest

import cv2
import numpy as np


PROJECT_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PROJECT_ROOT / "scripts"))

from build_monster_idle_from_videos import _remove_magenta  # noqa: E402
from build_starter_idle_quad import (  # noqa: E402
    _finish_cell,
    _remove_outer_grid_white,
)


class MonsterIdleChromaKeyTest(unittest.TestCase):
    def test_white_character_details_remain_opaque(self) -> None:
        rgb = np.full((96, 96, 3), (255, 0, 255), dtype=np.uint8)
        cv2.circle(rgb, (48, 50), 30, (60, 145, 210), thickness=-1)
        cv2.circle(rgb, (38, 42), 7, (255, 255, 255), thickness=-1)
        cv2.circle(rgb, (58, 42), 7, (255, 255, 255), thickness=-1)
        cv2.ellipse(rgb, (48, 61), (13, 10), 0, 0, 360, (250, 250, 250), -1)

        rgba = _remove_magenta(rgb)

        self.assertEqual(int(rgba[0, 0, 3]), 0)
        self.assertTrue(np.all(rgba[42, 38] == (255, 255, 255, 255)))
        self.assertTrue(np.all(rgba[42, 58] == (255, 255, 255, 255)))
        self.assertGreater(int(rgba[61, 48, 3]), 250)

    def test_enclosed_key_color_background_is_removed(self) -> None:
        rgb = np.full((96, 96, 3), (255, 0, 255), dtype=np.uint8)
        cv2.circle(rgb, (48, 48), 32, (40, 165, 90), thickness=10)

        rgba = _remove_magenta(rgb)

        self.assertEqual(int(rgba[48, 48, 3]), 0)
        self.assertGreater(int(rgba[48, 18, 3]), 245)

    def test_full_grid_split_preserves_white_features(self) -> None:
        frame = np.full((132, 132, 3), (255, 0, 255), dtype=np.uint8)
        frame[:, 64:68] = 255
        frame[64:68, :] = 255
        cv2.circle(frame, (32, 34), 25, (65, 150, 215), thickness=-1)
        cv2.circle(frame, (24, 28), 6, (255, 255, 255), thickness=-1)
        cv2.circle(frame, (40, 28), 6, (255, 255, 255), thickness=-1)
        cv2.ellipse(frame, (32, 43), (11, 9), 0, 0, 360, (250, 250, 250), -1)

        finished = _finish_cell(frame, 0, 0)
        white_opaque = (
            (finished[..., :3].min(axis=2) > 235)
            & (finished[..., 3] > 245)
        )

        self.assertEqual(finished.shape, (256, 256, 4))
        self.assertEqual(int(finished[0, 0, 3]), 0)
        self.assertGreater(int(white_opaque.sum()), 1000)

    def test_white_grid_frame_is_limited_to_outer_safe_band(self) -> None:
        rgba = np.zeros((96, 96, 4), dtype=np.uint8)
        rgba[..., :3] = (45, 150, 205)
        rgba[..., 3] = 255
        rgba[2:7, :] = 255
        rgba[:, 2:7] = 255
        rgba[42:54, 42:54] = 255

        cleaned = _remove_outer_grid_white(rgba)

        self.assertEqual(int(cleaned[3, 30, 3]), 0)
        self.assertEqual(int(cleaned[30, 3, 3]), 0)
        self.assertEqual(int(cleaned[48, 48, 3]), 255)


if __name__ == "__main__":
    unittest.main()
