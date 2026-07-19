#!/usr/bin/env python3
"""Validate locale coverage and formatting-token compatibility."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SOURCE_PATH = ROOT / "localization" / "source_strings.json"
LOCALES_DIR = ROOT / "localization" / "locales"
TARGET_LOCALES = ("zh_TW", "en", "ja", "ko", "fr", "de", "es_419")
FORMAT_TOKEN_RE = re.compile(r"%(?:\d+\$)?(?:\.\d+)?[sdifxX]|%%")
BBCODE_TAG_RE = re.compile(r"\[/?[A-Za-z][^\]]*\]")
HAN_RE = re.compile(r"[\u3400-\u9fff]")
HANGUL_RE = re.compile(r"[\uac00-\ud7af]")
KANA_RE = re.compile(r"[\u3040-\u30ff]")
ALLOWED_UNCHANGED = {"BOSS", "EXP"}


def format_signature(value: str) -> list[str]:
    return [token for token in FORMAT_TOKEN_RE.findall(value) if token != "%%"]


def main() -> int:
    source_payload = json.loads(SOURCE_PATH.read_text(encoding="utf-8"))
    source_messages = source_payload.get("messages", {})
    source_keys = set(source_messages)
    failures: list[str] = []

    for locale in TARGET_LOCALES:
        path = LOCALES_DIR / f"{locale}.json"
        if not path.exists():
            failures.append(f"{locale}: catalog is missing")
            continue
        try:
            catalog = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            failures.append(f"{locale}: invalid JSON ({error})")
            continue
        if not isinstance(catalog, dict):
            failures.append(f"{locale}: top level must be an object")
            continue

        keys = set(catalog)
        missing = sorted(source_keys - keys)
        extra = sorted(keys - source_keys)
        empty = sorted(key for key in source_keys & keys if not str(catalog[key]).strip())
        if missing:
            failures.append(f"{locale}: {len(missing)} missing messages (first: {missing[:3]})")
        if empty:
            failures.append(f"{locale}: {len(empty)} empty messages (first: {empty[:3]})")
        if extra:
            failures.append(f"{locale}: {len(extra)} stale messages (first: {extra[:3]})")

        for source in sorted(source_keys & keys):
            value = str(catalog[source])
            expected = format_signature(source)
            actual = format_signature(value)
            if expected != actual:
                failures.append(
                    f"{locale}: placeholder mismatch for {source!r}: {expected} != {actual}"
                )
            if BBCODE_TAG_RE.findall(source) != BBCODE_TAG_RE.findall(value):
                failures.append(f"{locale}: BBCode tag mismatch for {source!r}")
            if locale in {"en", "ko", "fr", "de", "es_419"} and HAN_RE.search(value):
                failures.append(f"{locale}: untranslated Han characters for {source!r}: {value!r}")
            if locale != "ko" and HANGUL_RE.search(value):
                failures.append(f"{locale}: unexpected Hangul for {source!r}: {value!r}")
            if locale != "ja" and KANA_RE.search(value):
                failures.append(f"{locale}: unexpected kana for {source!r}: {value!r}")
            if locale in {"en", "ko", "fr", "de", "es_419"} and value == source and source not in ALLOWED_UNCHANGED:
                failures.append(f"{locale}: source text was not translated for {source!r}")

    if failures:
        print("Localization audit failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1
    print(f"Localization audit OK: {len(source_keys)} messages x {len(TARGET_LOCALES) + 1} locales")
    return 0


if __name__ == "__main__":
    sys.exit(main())
