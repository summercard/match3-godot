# Concept Art Direction

This folder contains first-pass module effect images for the current WeChat mini game.

## Project Positioning

- Genre: vertical mobile match-3 battle + original monster collection + adventure stages.
- Core loop: stage selection -> battle match-3 -> capture/collect -> team setup -> evolution/progression.
- Rendering target: Canvas-first mini game UI, designed around the existing 375x667 logical layout.

## Visual Style

- Cute pixel-art inspired 2D, with chibi original monsters.
- Bright elemental gems over dark navy panels.
- Main UI colors follow `js/engine/theme.js`: `#1a1a2e`, `#16213e`, `#2979ff`, gold highlights.
- Element colors: fire, water, grass, thunder, light, with later support for earth, wind, dark.
- Avoid direct references to existing monster IP; all creatures should remain original.

## Files

- `module-01-start-screen.png`: startup / welcome screen.
- `module-02-main-lobby.png`: main lobby and feature grid.
- `module-03-stage-select.png`: adventure chapter map.
- `module-04-battle-match3.png`: match-3 battle interface.
- `module-05-monster-album.png`: monster album / detail / evolution entry.
- `module-06-team-evolve.png`: team setup and evolution preview.
