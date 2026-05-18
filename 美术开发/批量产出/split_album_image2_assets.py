from pathlib import Path
from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
EXTRACT = ROOT / "美术开发" / "元素提取" / "album"
FORMAL = ROOT / "美术开发" / "正式拆分" / "album"
RUNTIME = ROOT / "assets" / "images" / "album"

KEY = (255, 0, 255)

UI_SHEET = EXTRACT / "album_ui_image2_sheet.png"
ICON_SHEET = EXTRACT / "album_icons_monsters_image2_sheet.png"

UI_ASSETS = [
    ("ui", "ui_header_plaque.png", (116, 38, 764, 160)),
    ("ui", "ui_back_button.png", (798, 49, 922, 160)),
    ("ui", "ui_detail_panel.png", (987, 57, 1495, 322)),
    ("ui", "ui_filter_tab_selected.png", (82, 186, 310, 264)),
    ("ui", "ui_filter_tab_normal.png", (342, 186, 570, 264)),
    ("ui", "ui_filter_tab_disabled.png", (606, 186, 839, 264)),
    ("ui", "ui_roster_card_green.png", (64, 293, 331, 547)),
    ("ui", "ui_roster_card_blue.png", (358, 293, 642, 547)),
    ("ui", "ui_roster_card_locked.png", (689, 293, 946, 547)),
    ("ui", "ui_portrait_stage.png", (1044, 367, 1454, 846)),
    ("ui", "ui_stat_row.png", (59, 580, 971, 656)),
    ("ui", "ui_skill_panel.png", (58, 684, 447, 808)),
    ("ui", "ui_evolution_strip.png", (468, 683, 974, 808)),
    ("ui", "ui_btn_primary_gold.png", (91, 829, 443, 898)),
    ("ui", "ui_btn_secondary_blue.png", (458, 829, 792, 898)),
    ("ui", "ui_bottom_tab_selected.png", (67, 916, 520, 990)),
    ("ui", "ui_bottom_tab_normal.png", (525, 916, 980, 990)),
]

ICON_ASSETS = [
    ("icons", "icon_element_fire.png", (64, 92, 205, 230)),
    ("icons", "icon_element_water.png", (255, 92, 396, 230)),
    ("icons", "icon_element_grass.png", (445, 92, 586, 230)),
    ("icons", "icon_element_thunder.png", (638, 92, 779, 230)),
    ("icons", "icon_element_light.png", (796, 92, 937, 230)),
    ("icons", "icon_element_earth.png", (971, 92, 1112, 230)),
    ("icons", "icon_element_wind.png", (1160, 92, 1301, 230)),
    ("icons", "icon_element_dark.png", (1344, 92, 1485, 230)),
    ("icons", "icon_star_lit.png", (48, 342, 172, 468)),
    ("icons", "icon_star_dim.png", (202, 342, 326, 468)),
    ("icons", "icon_lock.png", (352, 338, 474, 470)),
    ("icons", "icon_album_book.png", (526, 333, 684, 486)),
    ("icons", "icon_paw.png", (726, 336, 872, 476)),
    ("icons", "icon_favorite.png", (898, 342, 1032, 468)),
    ("icons", "icon_source_scroll.png", (1058, 340, 1205, 472)),
    ("icons", "icon_evolution_arrows.png", (1228, 354, 1362, 466)),
    ("icons", "fx_sparkle_cluster.png", (1368, 318, 1502, 474)),
]

MONSTER_ASSETS = [
    ("monsters", "monster_leaf_fox_candidate.png", (35, 568, 270, 900)),
    ("monsters", "monster_fire_lizard_candidate.png", (280, 590, 510, 900)),
    ("monsters", "monster_water_cub_candidate.png", (545, 598, 770, 900)),
    ("monsters", "monster_thunder_rodent_candidate.png", (790, 568, 1020, 900)),
    ("monsters", "monster_light_cat_candidate.png", (1040, 568, 1260, 900)),
    ("monsters", "monster_dark_cat_candidate.png", (1280, 568, 1510, 900)),
]


def chroma_to_alpha(img: Image.Image) -> Image.Image:
    rgba = img.convert("RGBA")
    px = rgba.load()
    w, h = rgba.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            dist = abs(r - KEY[0]) + abs(g - KEY[1]) + abs(b - KEY[2])
            if dist < 54:
                px[x, y] = (r, g, b, 0)
            elif dist < 150:
                px[x, y] = (r, g, b, int(a * (dist - 54) / 96))
    return rgba


def trim_alpha(img: Image.Image, padding: int = 6) -> Image.Image:
    bbox = img.getchannel("A").getbbox()
    if bbox is None:
        return img
    left, top, right, bottom = bbox
    return img.crop((
        max(0, left - padding),
        max(0, top - padding),
        min(img.width, right + padding),
        min(img.height, bottom + padding),
    ))


def export_assets(sheet_path: Path, assets: list[tuple[str, str, tuple[int, int, int, int]]], copy_runtime: bool) -> None:
    sheet = Image.open(sheet_path)
    for category, name, box in assets:
        out_dir = FORMAL / category
        out_dir.mkdir(parents=True, exist_ok=True)
        asset = trim_alpha(chroma_to_alpha(sheet.crop(box)))
        asset.save(out_dir / name)
        if copy_runtime:
            RUNTIME.mkdir(parents=True, exist_ok=True)
            asset.save(RUNTIME / name)
        print(f"{category}/{name}: {asset.size}")


def main() -> None:
    export_assets(UI_SHEET, UI_ASSETS, True)
    export_assets(ICON_SHEET, ICON_ASSETS, True)
    export_assets(ICON_SHEET, MONSTER_ASSETS, False)


if __name__ == "__main__":
    main()
