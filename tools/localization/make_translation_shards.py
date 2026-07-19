#!/usr/bin/env python3
"""Split the localization source manifest into context-friendly review shards."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "localization" / "source_strings.json"
OUTPUT_DIR = ROOT / "localization" / "shards" / "source"


def choose_group(locations: list[str]) -> str:
    joined = " ".join(locations)
    if any(
        marker in joined
        for marker in (
            "monster_db.gd",
            "monster_ecology_db.gd",
            "nature_db.gd",
            "monster_art_db.gd",
            "evolution_rules.gd",
            "ecology_bond_rules.gd",
        )
    ):
        return "monster"
    if any(
        marker in joined
        for marker in (
            "scene_battle.gd",
            "scene_battle_gui.gd",
            "scene_battle_prepare.gd",
            "battle_prepare_logic.gd",
            "scene_result_gui.gd",
            "result_logic.gd",
            "scene_tutorial.gd",
            "tower",
            "battle_",
            "/battle/",
        )
    ):
        return "battle_ui"
    if any(marker in joined for marker in ("src/data/", "src/core/", "src/battle/", "src/match3/")):
        return "gameplay"
    return "meta_ui"


def write_shard(name: str, messages: dict[str, dict[str, list[str]]]) -> None:
    payload = {"shard": name, "message_count": len(messages), "messages": messages}
    path = OUTPUT_DIR / f"{name}.json"
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"{name}: {len(messages)}")


def main() -> None:
    payload = json.loads(SOURCE.read_text(encoding="utf-8"))
    grouped: dict[str, dict[str, dict[str, list[str]]]] = {
        "monster": {},
        "gameplay": {},
        "battle_ui": {},
        "meta_ui": {},
    }
    for source, metadata in payload["messages"].items():
        grouped[choose_group(metadata["locations"])][source] = metadata

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    monster_items = list(grouped["monster"].items())
    midpoint = (len(monster_items) + 1) // 2
    write_shard("monster_a", dict(monster_items[:midpoint]))
    write_shard("monster_b", dict(monster_items[midpoint:]))
    write_shard("gameplay", grouped["gameplay"])
    write_shard("battle_ui", grouped["battle_ui"])
    write_shard("meta_ui", grouped["meta_ui"])


if __name__ == "__main__":
    main()
