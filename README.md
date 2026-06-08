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

The full regression list and the 2026-06-01 repository cleanup record are documented in `docs/archive/2026-06-01-version-cleanup/README.md`.
