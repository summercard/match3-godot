#!/usr/bin/env python3
"""Plot before/after peak envelopes exported by tests/audio_mix_bus_test.gd.

Reads the two CSV files written by the test and renders a PNG comparison chart.

Usage:
    python3 tools/plot_peak_curves.py \
        --before docs/evidence/audio_mix_bus/peak_before.csv \
        --after docs/evidence/audio_mix_bus/peak_after.csv \
        --output docs/evidence/audio_mix_bus/peak_curves.png
"""

from __future__ import annotations

import argparse
import csv
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

WIDTH = 1400
HEIGHT = 720
MARGIN_LEFT = 88
MARGIN_RIGHT = 36
MARGIN_TOP = 82
MARGIN_BOTTOM = 72

BG = (14, 20, 32)
PANEL = (22, 31, 48)
GRID = (52, 66, 92)
TEXT = (226, 233, 245)
MUTED = (148, 163, 186)
BEFORE = (255, 104, 104)
AFTER = (74, 222, 158)
ZERO_LINE = (255, 190, 80)
LIMIT_LINE = (120, 220, 255)


def load_peaks(path: Path) -> tuple[list[float], list[float]]:
    times: list[float] = []
    peaks: list[float] = []
    with path.open(newline="", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            times.append(float(row["time_s"]))
            peaks.append(float(row["peak_dbfs"]))
    if not times:
        raise SystemExit(f"no data rows in {path}")
    return times, peaks


def font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/Library/Fonts/Arial.ttf",
    ]
    for candidate in candidates:
        if Path(candidate).exists():
            try:
                return ImageFont.truetype(candidate, size)
            except OSError:
                continue
    return ImageFont.load_default()


def db_to_y(db: float, y_min: float, y_max: float) -> float:
    plot_height = HEIGHT - MARGIN_TOP - MARGIN_BOTTOM
    clipped = min(max(db, y_min), y_max)
    return MARGIN_TOP + (y_max - clipped) / (y_max - y_min) * plot_height


def sec_to_x(sec: float, duration: float) -> float:
    return MARGIN_LEFT + sec / duration * (WIDTH - MARGIN_LEFT - MARGIN_RIGHT)


def label_box(
    draw: ImageDraw.ImageDraw,
    position: tuple[int, int],
    text: str,
    color,
    text_font,
) -> None:
    left, top = position
    right, bottom = draw.textbbox((left, top), text, font=text_font)[2:]
    draw.rectangle([left - 5, top - 3, right + 5, bottom + 3], fill=(17, 24, 38))
    draw.text((left, top), text, fill=color, font=text_font)


def draw_dashed_line(draw: ImageDraw.ImageDraw, xy, fill, width=2, dash=12, gap=8) -> None:
    x1, y1, x2, y2 = xy
    length = math.hypot(x2 - x1, y2 - y1)
    if length == 0:
        return
    dx = (x2 - x1) / length
    dy = (y2 - y1) / length
    position = 0.0
    while position < length:
        end = min(position + dash, length)
        draw.line(
            [(x1 + dx * position, y1 + dy * position), (x1 + dx * end, y1 + dy * end)],
            fill=fill,
            width=width,
        )
        position += dash + gap


def plot(before: Path, after: Path, output: Path, limit_db: float) -> None:
    b_times, b_peaks = load_peaks(before)
    a_times, a_peaks = load_peaks(after)
    duration = max(b_times[-1], a_times[-1]) + 0.01
    y_min = min(-60.0, math.floor(min(min(b_peaks), min(a_peaks)) / 10.0) * 10.0)
    y_max = max(6.0, math.ceil(max(max(b_peaks), max(a_peaks)) / 6.0) * 6.0 + 2.0)

    image = Image.new("RGB", (WIDTH, HEIGHT), BG)
    draw = ImageDraw.Draw(image)
    draw.rectangle(
        [MARGIN_LEFT, MARGIN_TOP, WIDTH - MARGIN_RIGHT, HEIGHT - MARGIN_BOTTOM],
        fill=PANEL,
    )

    title_font = font(28)
    label_font = font(18)
    small_font = font(15)
    draw.text((MARGIN_LEFT, 26), "10 s BGM + 7 SFX mix — 10 ms peak envelope", fill=TEXT, font=title_font)
    draw.text(
        (MARGIN_LEFT, 57),
        f"Before limiting: max {max(b_peaks):+.2f} dBFS · After limiting: max {max(a_peaks):+.2f} dBFS · limit {limit_db:.1f} dBFS",
        fill=MUTED,
        font=small_font,
    )

    # Horizontal grid every 10 dB plus the 0 dB and limiter reference lines.
    grid_db = math.ceil(y_min / 10.0) * 10.0
    while grid_db <= y_max:
        y = db_to_y(grid_db, y_min, y_max)
        draw.line([(MARGIN_LEFT, y), (WIDTH - MARGIN_RIGHT, y)], fill=GRID, width=1)
        draw.text((18, y - 9), f"{grid_db:+.0f}", fill=MUTED, font=small_font)
        grid_db += 10.0

    x = MARGIN_LEFT
    while x <= WIDTH - MARGIN_RIGHT + 0.1:
        draw.line([(x, MARGIN_TOP), (x, HEIGHT - MARGIN_BOTTOM)], fill=GRID, width=1)
        x += (WIDTH - MARGIN_LEFT - MARGIN_RIGHT) / 10.0
    for second in range(0, int(math.ceil(duration)) + 1):
        draw.text(
            (sec_to_x(second, duration) - 8, HEIGHT - MARGIN_BOTTOM + 12),
            f"{second}s",
            fill=MUTED,
            font=small_font,
        )

    zero_y = db_to_y(0.0, y_min, y_max)
    draw_dashed_line(draw, (MARGIN_LEFT, zero_y, WIDTH - MARGIN_RIGHT, zero_y), ZERO_LINE, width=2)
    limit_y = db_to_y(limit_db, y_min, y_max)
    draw_dashed_line(draw, (MARGIN_LEFT, limit_y, WIDTH - MARGIN_RIGHT, limit_y), LIMIT_LINE, width=2)

    def series(times: list[float], peaks: list[float], color, width: int) -> None:
        points = [(sec_to_x(t, duration), db_to_y(p, y_min, y_max)) for t, p in zip(times, peaks)]
        if len(points) > 1:
            draw.line(points, fill=color, width=width)

    series(b_times, b_peaks, BEFORE, 2)
    series(a_times, a_peaks, AFTER, 2)

    label_box(draw, (MARGIN_LEFT + 12, zero_y + 8), "0 dBFS", ZERO_LINE, small_font)
    label_box(
        draw,
        (MARGIN_LEFT + 12, limit_y + 8),
        f"{limit_db:.1f} dBFS limit",
        LIMIT_LINE,
        small_font,
    )
    label_box(draw, (MARGIN_LEFT + 16, MARGIN_TOP + 14), "before limiter", BEFORE, label_font)
    label_box(draw, (MARGIN_LEFT + 16, MARGIN_TOP + 44), "after limiter", AFTER, label_font)
    draw.text((MARGIN_LEFT + 16, HEIGHT - MARGIN_BOTTOM + 38), "time (s)", fill=MUTED, font=small_font)

    output.parent.mkdir(parents=True, exist_ok=True)
    image.save(output)
    print(f"[PeakCurves] wrote {output} ({WIDTH}x{HEIGHT})")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--before", type=Path, required=True)
    parser.add_argument("--after", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--limit-db", type=float, default=-3.0)
    args = parser.parse_args()
    plot(args.before, args.after, args.output, args.limit_db)


if __name__ == "__main__":
    main()
