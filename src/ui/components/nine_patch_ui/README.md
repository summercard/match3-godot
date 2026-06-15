# Nine-Patch UI Components

These PackedScene components wrap the UI textures from `assets/新美术资产/ui` as scalable `Control` nodes with one child named `NinePatch`.

- `black_panel.tscn`: large cream panel, four-side nine-patch.
- `black2_pill_panel.tscn`: cream pill panel, four-side nine-patch.
- `black3_tall_panel.tscn`: tall cream panel, four-side nine-patch.
- `butter01_gold_button.tscn`: gold pill/button base, four-side nine-patch.
- `butter02_blue_button.tscn`: blue pill/button base, four-side nine-patch.
- `ribbon_side_stretch.tscn`: red ribbon, left/right stretch only; top and bottom margins are intentionally unset.

Each wrapper can be resized to change the nine-patch shape without distorting the corners. Scale the wrapper node itself when you need proportional zoom in or zoom out.

`ui_nine_patch_library.tscn` contains all components in one scene. Use these child wrapper names for lookup/replacement:

- `black`
- `black2`
- `black3`
- `butter01`
- `butter02`
- `花边01`
- `ui底图`
- `蓝色花边`
- `黄色底部`

The three split panel parts were redrawn with image generation from the provided reference, chroma-key cleaned into transparent PNGs, and added to the library:

- `assets/images/ui/generated_panel_parts/panel_base.png`
- `assets/images/ui/generated_panel_parts/panel_top_blue_trim.png`
- `assets/images/ui/generated_panel_parts/panel_bottom_yellow_bar.png`
