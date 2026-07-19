#!/usr/bin/env python3
"""Merge reviewed translation shards into runtime locale catalogs."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SOURCE_DIR = ROOT / "localization" / "shards" / "source"
TRANSLATION_DIR = ROOT / "localization" / "shards" / "translations"
OUTPUT_DIR = ROOT / "localization" / "locales"
LOCALES = ("zh_TW", "en", "ja", "ko", "fr", "de", "es_419")


def main() -> None:
    shard_names = sorted(path.stem for path in SOURCE_DIR.glob("*.json"))
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    for locale in LOCALES:
        merged: dict[str, str] = {}
        for shard_name in shard_names:
            path = TRANSLATION_DIR / locale / f"{shard_name}.json"
            if not path.exists():
                raise SystemExit(f"Missing translation shard: {path.relative_to(ROOT)}")
            payload = json.loads(path.read_text(encoding="utf-8"))
            if not isinstance(payload, dict):
                raise SystemExit(f"Translation shard must be an object: {path.relative_to(ROOT)}")
            overlap = set(merged) & set(payload)
            if overlap:
                raise SystemExit(f"Duplicate keys in {locale}/{shard_name}: {sorted(overlap)[:3]}")
            merged.update({str(key): str(value) for key, value in payload.items()})
        output = OUTPUT_DIR / f"{locale}.json"
        output.write_text(json.dumps(dict(sorted(merged.items())), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"{locale}: {len(merged)}")


if __name__ == "__main__":
    main()
