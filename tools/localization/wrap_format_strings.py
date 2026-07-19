#!/usr/bin/env python3
"""Wrap localized GDScript format fragments before interpolation.

Godot Controls translate exact source strings automatically, but a formatted
string must translate its template before `%` or concatenation changes it.
This mechanical migration only touches Chinese literals adjacent to a format
or concatenation operator and leaves constants/comments/docstrings intact.
"""

from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
HAN_RE = re.compile(r"[\u3400-\u9fff]")
QUOTED_RE = re.compile(r'"(?:\\.|[^"\\])*"')
ALREADY_WRAPPED_RE = re.compile(r"(?:TranslationServer\.translate|tr|_localized)\s*\(\s*$")


def strip_comment_index(line: str) -> int:
    escaped = False
    in_string = False
    for index, char in enumerate(line):
        if escaped:
            escaped = False
            continue
        if char == "\\" and in_string:
            escaped = True
            continue
        if char == '"':
            in_string = not in_string
            continue
        if char == "#" and not in_string:
            return index
    return len(line)


def transform_line(line: str) -> tuple[str, int]:
    code_end = strip_comment_index(line)
    code = line[:code_end]
    if code.lstrip().startswith("const "):
        return line, 0
    replacements: list[tuple[int, int, str]] = []
    for match in QUOTED_RE.finditer(code):
        token = match.group(0)
        if not HAN_RE.search(token):
            continue
        before = code[: match.start()].rstrip()
        after = code[match.end() :].lstrip()
        if ALREADY_WRAPPED_RE.search(before):
            continue
        adjacent = (
            after.startswith("%")
            or after.startswith("+")
            or after.startswith(".format(")
            or before.endswith("+")
        )
        if not adjacent:
            continue
        replacements.append(
            (match.start(), match.end(), f"TranslationServer.translate({token})")
        )
    if not replacements:
        return line, 0
    for start, end, replacement in reversed(replacements):
        line = line[:start] + replacement + line[end:]
    return line, len(replacements)


def transform_file(path: Path) -> int:
    source = path.read_text(encoding="utf-8")
    lines = source.splitlines(keepends=True)
    in_triple = False
    changed = 0
    output: list[str] = []
    for line in lines:
        triple_count = line.count('"""')
        if in_triple:
            output.append(line)
            if triple_count % 2 == 1:
                in_triple = False
            continue
        if triple_count:
            output.append(line)
            if triple_count % 2 == 1:
                in_triple = True
            continue
        transformed, count = transform_line(line)
        output.append(transformed)
        changed += count
    if changed:
        path.write_text("".join(output), encoding="utf-8")
    return changed


def main() -> None:
    paths = sorted((ROOT / "src").rglob("*.gd")) + [ROOT / "main.gd"]
    total = 0
    changed_files = 0
    for path in paths:
        count = transform_file(path)
        if count:
            changed_files += 1
            total += count
            print(f"{path.relative_to(ROOT)}: {count}")
    print(f"Wrapped {total} format fragments in {changed_files} files")


if __name__ == "__main__":
    main()
