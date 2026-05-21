#!/usr/bin/env python3
from __future__ import annotations

import csv
import os
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
CODEX_HOME = Path(os.environ.get("CODEX_HOME", Path.home() / ".codex"))
IMAGE_GEN = CODEX_HOME / "skills" / ".system" / "imagegen" / "scripts" / "image_gen.py"
MANIFEST = ROOT / "美术开发" / "元素提取" / "monster_catalog" / "monster_image2_request_manifest.csv"
REFERENCE_DIR = ROOT / "美术开发" / "元素提取" / "monster_catalog" / "reference_tiles_not_final"
OUTPUT_DIR = ROOT / "美术开发" / "元素提取" / "monster_catalog" / "image2_outputs"


PROMPT = """Use case: background-extraction
Asset type: transparent monster game sprite for a Godot match-3 monster game
Primary request: Use gpt-image-2 to extract/redraw one clean isolated monster game sprite from the provided reference tile.
Input image role: reference tile only, not final art.
Subject: the single creature shown in the reference tile.
Style: cute fantasy monster, polished 2D game sprite, consistent with the reference pose, colors, element markings, armor/accessories, and silhouette.
Output requirements: one full-body monster only, centered, generous padding, no text, no label, no card frame, no UI, no border, no neighboring creature.
Background requirements: perfectly flat solid #00ff00 chroma-key background for local background removal; no shadows, gradients, floor plane, texture, or lighting variation; do not use #00ff00 in the creature.
Quality constraints: clean edges, no cropped body parts, no watermark, no signature, no extra objects.
"""


def load_rows() -> list[dict[str, str]]:
    with MANIFEST.open("r", encoding="utf-8-sig", newline="") as f:
        return [row for row in csv.DictReader(f) if row.get("image2_output_expected")]


def main() -> int:
    if not IMAGE_GEN.exists():
        print(f"image_gen.py not found: {IMAGE_GEN}", file=sys.stderr)
        return 2
    if not os.environ.get("OPENAI_API_KEY"):
        print("OPENAI_API_KEY is required to run real gpt-image-2 extraction.", file=sys.stderr)
        print("No image-2 call was made.", file=sys.stderr)
        return 3

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    rows = load_rows()
    for row in rows:
        label = row["asset_label"]
        src = REFERENCE_DIR / f"{label}_reference_not_final.png"
        out = OUTPUT_DIR / row["image2_output_expected"]
        if out.exists():
            print(f"skip existing: {out}")
            continue
        if not src.exists():
            print(f"missing reference: {src}", file=sys.stderr)
            continue
        cmd = [
            sys.executable,
            str(IMAGE_GEN),
            "edit",
            "--model",
            "gpt-image-2",
            "--image",
            str(src),
            "--prompt",
            PROMPT,
            "--quality",
            "medium",
            "--size",
            "1024x1024",
            "--out",
            str(out),
        ]
        print(f"image-2 extract: {label}")
        subprocess.run(cmd, cwd=str(ROOT), check=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
