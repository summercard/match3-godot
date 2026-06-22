# 萌灵消消大冒险

Godot 4.6 vertical mobile match-3 battle game with spirit collection, team building, capture windows, stage mechanics, growth, evolution, ranch, shop, inventory, achievements, sign-in, and tutorial flows.

## Runtime Layout

- `main.tscn` and `main.gd`: application entry and scene routing
- `src/`: runtime code and editable UI scenes
- `assets/`: runtime images only
- `tests/`: headless Godot regression scripts
- `docs/`: current design source and archived handover notes

## Verification

Use Godot 4.6.x:

```powershell
godot --headless --path . --script res://tests/p0_smoke_test.gd
```

Full local gate:

```powershell
.\tools\check_formal_scene_resources.ps1
.\tools\run_godot_tests.ps1 -GodotBin "C:\path\to\Godot_v4.6.3-stable_win64.exe"
```

`run_godot_tests.ps1` also reads `GODOT_BIN`, PATH, or a currently running Godot process. It gives every test an isolated `MATCH3_SAVE_PATH` and fails on timeouts, engine errors, script errors, missing resources, and leak reports.

The full regression list and the 2026-06-01 repository cleanup record are documented in `docs/archive/2026-06-01-version-cleanup/README.md`.
