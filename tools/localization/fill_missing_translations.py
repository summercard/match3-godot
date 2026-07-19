#!/usr/bin/env python3
"""Fill missing localization shard values through batched machine translation.

Existing reviewed values are never overwritten. Format placeholders are hidden
from the translation service and restored afterwards, while leading/trailing
whitespace from the source message is kept exactly.
"""

from __future__ import annotations

import argparse
import json
import re
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SOURCE_DIR = ROOT / "localization" / "shards" / "source"
TRANSLATION_DIR = ROOT / "localization" / "shards" / "translations"
LOCALE_TARGETS = {
    "zh_TW": "zh-TW",
    "en": "en",
    "ja": "ja",
    "ko": "ko",
    "fr": "fr",
    "de": "de",
    "es_419": "es",
}
FORMAT_TOKEN_RE = re.compile(r"%(?:\d+\$)?(?:\.\d+)?[sdifxX]|%%")
MARKER_RE = re.compile(r"<<<L10N(\d{4})>>>")
MAX_BATCH_CHARS = 1400


def protect_message(source: str) -> tuple[str, list[str], str, str]:
    prefix_match = re.match(r"^\s*", source)
    suffix_match = re.search(r"\s*$", source)
    prefix = prefix_match.group(0) if prefix_match else ""
    suffix = suffix_match.group(0) if suffix_match else ""
    core_end = len(source) - len(suffix) if suffix else len(source)
    core = source[len(prefix) : core_end]
    tokens: list[str] = []

    def replace_token(match: re.Match[str]) -> str:
        tokens.append(match.group(0))
        return f"__FMT{len(tokens) - 1:03d}__"

    return FORMAT_TOKEN_RE.sub(replace_token, core), tokens, prefix, suffix


def restore_message(translated: str, tokens: list[str], prefix: str, suffix: str) -> str:
    value = translated.strip()
    for index, token in enumerate(tokens):
        marker = f"__FMT{index:03d}__"
        if value.count(marker) != 1:
            raise ValueError(f"format marker {marker} was changed in {value!r}")
        value = value.replace(marker, token)
    if re.search(r"__FMT\d{3}__", value):
        raise ValueError(f"unexpected format marker in {value!r}")
    return prefix + value + suffix


def make_batches(messages: list[str]) -> list[list[str]]:
    batches: list[list[str]] = []
    current: list[str] = []
    size = 0
    for message in messages:
        estimated = len(message) + 24
        if current and size + estimated > MAX_BATCH_CHARS:
            batches.append(current)
            current = []
            size = 0
        current.append(message)
        size += estimated
    if current:
        batches.append(current)
    return batches


def request_translation(messages: list[str], target: str) -> list[str]:
    protected: list[tuple[str, list[str], str, str]] = [protect_message(value) for value in messages]
    body = "\n".join(
        f"<<<L10N{index:04d}>>>\n{parts[0]}" for index, parts in enumerate(protected)
    )
    last_error: Exception | None = None
    output = ""
    for backend in ("google", "lingva"):
        try:
            if backend == "google":
                payload = urllib.parse.urlencode(
                    {"client": "gtx", "sl": "zh-CN", "tl": target, "dt": "t", "q": body}
                ).encode("utf-8")
                request = urllib.request.Request(
                    "https://translate.googleapis.com/translate_a/single",
                    data=payload,
                    headers={"User-Agent": "match3-godot-localization/1.0"},
                )
                with urllib.request.urlopen(request, timeout=30) as response:
                    result = json.load(response)
                output = "".join(part[0] for part in result[0])
            else:
                lingva_target = "zh_HANT" if target == "zh-TW" else target
                graphql_payload = json.dumps(
                    {
                        "query": "query Translate($source: String, $target: String, $query: String!) { translation(source: $source, target: $target, query: $query) { target { text } } }",
                        "variables": {"source": "zh", "target": lingva_target, "query": body},
                    }
                ).encode("utf-8")
                request = urllib.request.Request(
                    "https://lingva.ml/api/graphql",
                    data=graphql_payload,
                    headers={
                        "Content-Type": "application/json",
                        "User-Agent": "match3-godot-localization/1.0",
                    },
                )
                with urllib.request.urlopen(request, timeout=45) as response:
                    result = json.load(response)
                output = str(result["data"]["translation"]["target"]["text"])
            break
        except (OSError, ValueError, KeyError, IndexError, json.JSONDecodeError) as error:
            last_error = error
    if not output:
        raise RuntimeError(f"translation request failed on all backends: {last_error}")

    matches = list(MARKER_RE.finditer(output))
    if len(matches) != len(messages):
        raise RuntimeError(f"expected {len(messages)} markers, received {len(matches)}")
    translated: list[str] = []
    for index, match in enumerate(matches):
        if int(match.group(1)) != index:
            raise RuntimeError(f"unexpected marker order at {index}: {match.group(0)}")
        start = match.end()
        end = matches[index + 1].start() if index + 1 < len(matches) else len(output)
        raw_value = output[start:end].lstrip("\r\n").rstrip("\r\n")
        _, tokens, prefix, suffix = protected[index]
        translated.append(restore_message(raw_value, tokens, prefix, suffix))
    return translated


def fill_locale(locale: str) -> None:
    locale_dir = TRANSLATION_DIR / locale
    locale_dir.mkdir(parents=True, exist_ok=True)
    target = LOCALE_TARGETS[locale]
    for source_path in sorted(SOURCE_DIR.glob("*.json")):
        source_payload = json.loads(source_path.read_text(encoding="utf-8"))
        source_messages = list(source_payload["messages"])
        output_path = locale_dir / source_path.name
        catalog = json.loads(output_path.read_text(encoding="utf-8")) if output_path.exists() else {}
        catalog = {str(key): str(value) for key, value in catalog.items() if key in source_messages}
        missing = [source for source in source_messages if not catalog.get(source, "").strip()]
        batches = make_batches(missing)
        for batch_index, batch in enumerate(batches, 1):
            values = request_translation(batch, target)
            catalog.update(zip(batch, values, strict=True))
            output_path.write_text(
                json.dumps(dict(sorted(catalog.items())), ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
            print(
                f"{locale}/{source_path.stem}: batch {batch_index}/{len(batches)} "
                f"({len(catalog)}/{len(source_messages)})",
                flush=True,
            )
            time.sleep(0.15)
        if not batches:
            print(f"{locale}/{source_path.stem}: already complete", flush=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("locales", nargs="*", choices=tuple(LOCALE_TARGETS), default=tuple(LOCALE_TARGETS))
    args = parser.parse_args()
    for locale in args.locales:
        fill_locale(locale)


if __name__ == "__main__":
    main()
