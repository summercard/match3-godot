#!/usr/bin/env python3
"""Extract player-facing Simplified Chinese source strings.

The game uses Chinese source text as the stable translation message id. This
extractor intentionally ignores comments, debug logging, resource paths and
scene-node paths while retaining authored Control text and gameplay data.
"""

from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "localization" / "source_strings.json"
HAN_RE = re.compile(r"[\u3400-\u9fff]")
QUOTED_RE = re.compile(r'"(?:\\.|[^"\\])*"')
SCENE_TEXT_PROPERTIES = {
    "text",
    "placeholder_text",
    "tooltip_text",
    "dialog_text",
    "title",
    "description",
}
ASCII_DISPLAY_SOURCES = {
    "MISS", "MAX", "GUARD", "DOWN", "BURN", "COMBO", "LEADER BURST",
    "BOSS", "EXP", "UP", "ON", "OFF", "GET!", "Team Power", "Choose Pets",
    "Vines backlash, spirits take damage", "Fire burned the vines",
    "Verdant Mend", "Tide Shell", "Stone Bulwark", "Star Calling",
    "Night Siphon", "Siphon Heal", "Thunder Pin", "Gale Break",
    "Leader Strike", "Leader Heal", "Leader Lifesteal", "Leader Convert",
    "Leader Guard", "Leader Shield", "Leader Status", "Leader Weaken",
    "Stage %d-01", "Stage %d-%02d", "Boss %d-%02d",
    "Chapter %d boss: test the full chapter mechanic with a two-phase pressure spike.",
    "Read the boss intent, keep guard/control skills ready, and save burst for the phase change.",
    "Chapter %d stage %02d: scale enemy count, board pressure, and reward pacing toward the boss.",
    "Use this stage to read enemy intent and build stable matches before spending skills.",
    "Check the board pressure first, then decide whether to clear hazards or focus damage.",
    "Pre-boss stage: preserve HP and enter the next fight with a clear skill plan.",
}
DEBUG_CALL_RE = re.compile(
    r"\b(?:print|prints|print_rich|printerr|push_warning|push_error|assert)\s*\("
)
NODE_LOOKUP_RE = re.compile(
    r"\b(?:get_node|get_node_or_null|has_node|find_child|preload|load)\s*\("
)


def strip_comment(line: str) -> str:
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
            return line[:index]
    return line


def decode_literal(token: str) -> str:
    value = token[1:-1]
    result: list[str] = []
    index = 0
    escapes = {"n": "\n", "r": "\r", "t": "\t", '"': '"', "\\": "\\"}
    while index < len(value):
        if value[index] == "\\" and index + 1 < len(value):
            key = value[index + 1]
            if key in escapes:
                result.append(escapes[key])
                index += 2
                continue
        result.append(value[index])
        index += 1
    return "".join(result)


def is_internal(value: str, line: str, match_start: int) -> bool:
    lowered = value.lower()
    if any(marker in lowered for marker in ("res://", "user://", ".png", ".tscn", ".tres", ".gd")):
        return True
    if re.match(r"^\[[A-Z][A-Za-z0-9_]+\]", value):
        return True
    if "ui底图" in value:
        return True
    if "/" in value and "%" not in value and not any(char.isspace() for char in value):
        return True
    if DEBUG_CALL_RE.search(line):
        return True
    # Only the literal passed directly to a node/resource lookup is internal.
    # A common UI line contains both get_node("Path") and a later .text value.
    prefix = line[:match_start]
    if NODE_LOOKUP_RE.search(prefix) and re.search(
        r"(?:get_node|get_node_or_null|has_node|find_child|preload|load)\s*\([^()]*$",
        prefix,
    ):
        return True
    return False


def add_message(messages: dict[str, set[str]], value: str, location: str) -> None:
    if not value or (not HAN_RE.search(value) and value not in ASCII_DISPLAY_SOURCES):
        return
    messages.setdefault(value, set()).add(location)


def scan_gd(path: Path, messages: dict[str, set[str]]) -> None:
    relative = path.relative_to(ROOT).as_posix()
    in_triple = False
    for line_number, raw_line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        triple_count = raw_line.count('"""')
        if in_triple:
            if triple_count % 2 == 1:
                in_triple = False
            continue
        if triple_count:
            if triple_count % 2 == 1:
                in_triple = True
            continue
        line = strip_comment(raw_line)
        if not line.strip():
            continue
        for match in QUOTED_RE.finditer(line):
            value = decode_literal(match.group(0))
            if is_internal(value, line, match.start()):
                continue
            add_message(messages, value, f"{relative}:{line_number}")


def scan_tscn(path: Path, messages: dict[str, set[str]]) -> None:
    relative = path.relative_to(ROOT).as_posix()
    for line_number, raw_line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = raw_line.strip()
        if "=" not in line:
            continue
        property_name = line.split("=", 1)[0].strip()
        if property_name not in SCENE_TEXT_PROPERTIES:
            continue
        for match in QUOTED_RE.finditer(line):
            value = decode_literal(match.group(0))
            add_message(messages, value, f"{relative}:{line_number}")


def main() -> None:
    messages: dict[str, set[str]] = {}
    for entry in (ROOT / "src").rglob("*"):
        if entry.suffix == ".gd":
            scan_gd(entry, messages)
        elif entry.suffix == ".tscn":
            scan_tscn(entry, messages)
    scan_gd(ROOT / "main.gd", messages)
    scan_tscn(ROOT / "main.tscn", messages)

    payload = {
        "source_locale": "zh_CN",
        "message_count": len(messages),
        "messages": {
            key: {"locations": sorted(locations)}
            for key, locations in sorted(messages.items(), key=lambda item: item[0])
        },
    }
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {len(messages)} messages to {OUTPUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
