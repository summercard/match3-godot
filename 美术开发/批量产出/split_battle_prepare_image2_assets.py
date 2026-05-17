from pathlib import Path
from PIL import Image
import shutil


ROOT = Path(__file__).resolve().parents[2]
EXTRACT_DIR = ROOT / "美术开发" / "元素提取" / "battle_prepare"
FORMAL_DIR = ROOT / "美术开发" / "正式拆分" / "battle_prepare"
RUNTIME_DIR = ROOT / "assets" / "images" / "battle_prepare"

MAGENTA = (255, 0, 255)


def ensure_dirs() -> None:
    for path in [
        FORMAL_DIR / "monsters",
        FORMAL_DIR / "gems",
        FORMAL_DIR / "ui",
        RUNTIME_DIR,
    ]:
        path.mkdir(parents=True, exist_ok=True)


def chroma_to_alpha(img: Image.Image, tolerance: int = 38) -> Image.Image:
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if abs(r - MAGENTA[0]) <= tolerance and abs(g - MAGENTA[1]) <= tolerance and abs(b - MAGENTA[2]) <= tolerance:
                px[x, y] = (r, g, b, 0)
    return img


def trim_alpha(img: Image.Image, pad: int = 10) -> Image.Image:
    bbox = img.getbbox()
    if not bbox:
        return img
    left = max(bbox[0] - pad, 0)
    top = max(bbox[1] - pad, 0)
    right = min(bbox[2] + pad, img.size[0])
    bottom = min(bbox[3] + pad, img.size[1])
    return img.crop((left, top, right, bottom))


def save_asset(img: Image.Image, formal_subdir: str, name: str, runtime: bool = False) -> None:
    out = trim_alpha(chroma_to_alpha(img))
    formal_path = FORMAL_DIR / formal_subdir / name
    formal_path.parent.mkdir(parents=True, exist_ok=True)
    out.save(formal_path)
    if runtime:
        out.save(RUNTIME_DIR / name)


def split_grid(sheet_path: Path, cols: int, rows: int, names: list[str], formal_subdir: str, runtime_names: set[str] | None = None) -> None:
    sheet = Image.open(sheet_path).convert("RGBA")
    cell_w = sheet.width / cols
    cell_h = sheet.height / rows
    runtime_names = runtime_names or set()
    for idx, name in enumerate(names):
        col = idx % cols
        row = idx // cols
        box = (
            int(round(col * cell_w)),
            int(round(row * cell_h)),
            int(round((col + 1) * cell_w)),
            int(round((row + 1) * cell_h)),
        )
        crop = sheet.crop(box)
        save_asset(crop, formal_subdir, name, name in runtime_names)


def split_ui_sheet() -> None:
    sheet = Image.open(EXTRACT_DIR / "battle_prepare_ui_image2_sheet.png").convert("RGBA")
    boxes = {
        "ui_back_button.png": (40, 95, 225, 245),
        "ui_prepare_header.png": (270, 105, 680, 230),
        "ui_chapter_banner.png": (715, 110, 1220, 250),
        "ui_panel_large.png": (35, 310, 610, 680),
        "ui_team_card.png": (635, 300, 895, 680),
        "ui_enemy_card.png": (945, 300, 1205, 680),
        "ui_power_panel.png": (50, 735, 610, 905),
        "ui_reward_panel.png": (640, 730, 1205, 910),
        "ui_stamina_panel.png": (50, 970, 330, 1155),
        "ui_start_button.png": (390, 970, 920, 1145),
        "ui_edit_button.png": (980, 960, 1190, 1070),
        "ui_reward_slot.png": (1005, 1065, 1135, 1195),
    }
    runtime_aliases = {
        "ui_back_button.png": "ui_back_button.png",
        "ui_prepare_header.png": "ui_prepare_header.png",
        "ui_team_card.png": "ui_team_card.png",
        "ui_enemy_card.png": "ui_enemy_card.png",
        "ui_power_panel.png": "ui_power_panel.png",
        "ui_panel_large.png": "ui_info_panel.png",
        "ui_reward_slot.png": "ui_reward_slot.png",
        "ui_start_button.png": "ui_start_button.png",
        "ui_reward_panel.png": "ui_synergy_panel.png",
    }
    for name, box in boxes.items():
        crop = sheet.crop(box)
        out = trim_alpha(chroma_to_alpha(crop))
        out.save(FORMAL_DIR / "ui" / name)
        if name in runtime_aliases:
            out.save(RUNTIME_DIR / runtime_aliases[name])
    # Use the same image-2 start button as state variants until dedicated pressed/disabled variants are generated.
    shutil.copy2(RUNTIME_DIR / "ui_start_button.png", RUNTIME_DIR / "ui_start_button_ready.png")
    shutil.copy2(RUNTIME_DIR / "ui_start_button.png", RUNTIME_DIR / "ui_start_button_disabled.png")


def copy_background_runtime_asset() -> None:
	bg = ROOT / "assets/images/battle/battle_bg_forest_ruins.png"
	if bg.exists():
		shutil.copy2(bg, RUNTIME_DIR / "battle_prepare_bg.png")


def main() -> None:
    ensure_dirs()
    split_grid(
        EXTRACT_DIR / "battle_prepare_monsters_image2_sheet.png",
        3,
        2,
        [
            "monster_boss_001_flower_candidate.png",
            "enemy_stone_golem_candidate.png",
            "enemy_fire_boar_candidate.png",
            "monster_003_grass_leaf_candidate.png",
            "monster_002_water_cub_candidate.png",
            "monster_fire_fox_candidate.png",
        ],
        "monsters",
    )
    split_grid(
        EXTRACT_DIR / "battle_prepare_gems_uiicons_image2_sheet.png",
        5,
        2,
        [
            "gem_fire_candidate.png",
            "gem_water_candidate.png",
            "gem_grass_candidate.png",
            "gem_thunder_candidate.png",
            "gem_light_candidate.png",
            "icon_gold_candidate.png",
            "icon_exp_candidate.png",
            "icon_stamina_candidate.png",
            "icon_capture_ball_candidate.png",
            "icon_star_candidate.png",
        ],
        "gems",
    )
    split_ui_sheet()
	copy_background_runtime_asset()
    print(f"split image-2 battle_prepare assets into {FORMAL_DIR}")


if __name__ == "__main__":
    main()
