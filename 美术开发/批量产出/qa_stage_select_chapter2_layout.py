from pathlib import Path
from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
DESIGN_W = 375
DESIGN_H = 667
MAP_REWARD_TOP = 566
OUT_DIR = ROOT / "美术开发" / "验收" / "stage_select"
HEADER_BAR_RECT = (76, 12, 286, 66)
HEADER_BADGE_RECT = (84, 21, 38, 42)
HEADER_TITLE_RECT = (126, 23, 190, 22)
HEADER_STAR_RECT = (147, 52, 18, 18)
HEADER_STAR_TEXT_RECT = (169, 50, 74, 22)
HEADER_PREV_RECT = (DESIGN_W - 89, 30, 34, 34)
HEADER_NEXT_RECT = (DESIGN_W - 49, 30, 34, 34)
REWARD_RECT = (17, MAP_REWARD_TOP, DESIGN_W - 34, 84)
REWARD_SLOT_SIZE = (32, 34)
REWARD_SLOT_GAP = 7


def open_rgba(path: Path) -> Image.Image | None:
    if not path.exists():
        return None
    return Image.open(path).convert("RGBA")


def cover(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    iw, ih = image.size
    sw, sh = size
    scale = max(sw / iw, sh / ih)
    nw, nh = int(iw * scale + 0.5), int(ih * scale + 0.5)
    resized = image.resize((nw, nh), Image.Resampling.LANCZOS)
    left = (nw - sw) // 2
    top = (nh - sh) // 2
    return resized.crop((left, top, left + sw, top + sh))


def contain(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    iw, ih = image.size
    sw, sh = size
    scale = min(sw / iw, sh / ih)
    nw, nh = max(1, int(iw * scale + 0.5)), max(1, int(ih * scale + 0.5))
    return image.resize((nw, nh), Image.Resampling.LANCZOS)


def paste_contain(canvas: Image.Image, image: Image.Image | None, rect: tuple[float, float, float, float]) -> tuple[int, int, int, int]:
    x, y, w, h = rect
    box = (int(x), int(y), int(w), int(h))
    if image is None:
        return box
    fitted = contain(image, (box[2], box[3]))
    px = box[0] + (box[2] - fitted.size[0]) // 2
    py = box[1] + (box[3] - fitted.size[1]) // 2
    canvas.alpha_composite(fitted, (px, py))
    return (px, py, fitted.size[0], fitted.size[1])


def rect_bounds(rect: tuple[float, float, float, float]) -> tuple[float, float, float, float]:
    x, y, w, h = rect
    return (x, y, x + w, y + h)


def rect_xy(rect: tuple[float, float, float, float]) -> tuple[float, float, float, float]:
    return rect_bounds(rect)


def overlaps(a: tuple[float, float, float, float], b: tuple[float, float, float, float]) -> bool:
    ax1, ay1, ax2, ay2 = rect_bounds(a)
    bx1, by1, bx2, by2 = rect_bounds(b)
    return ax1 < bx2 and ax2 > bx1 and ay1 < by2 and ay2 > by1


def render_case(case_key: str, bg_name: str, points: list[tuple[int, int]], boss_path: str, show_prev: bool, show_next: bool) -> tuple[Path, Path, list[tuple[str, bool, str]]]:
    stage_dir = ROOT / "assets" / "images" / "stage"
    monster_dir = ROOT / "assets" / "images" / "battle" / "monsters"
    battle_gem_dir = ROOT / "assets" / "images" / "battle" / "gems"
    item_dir = ROOT / "assets" / "images" / "items"
    main_dir = ROOT / "assets" / "images" / "main"
    bg = open_rgba(stage_dir / bg_name)
    if bg is None:
        raise FileNotFoundError(stage_dir / bg_name)

    canvas = cover(bg, (DESIGN_W, DESIGN_H))
    draw = ImageDraw.Draw(canvas)

    assets = {
        "back_button": open_rgba(stage_dir / "ui_back_button.png"),
        "back_arrow": open_rgba(stage_dir / "icon_back_arrow.png"),
        "header": open_rgba(stage_dir / "ui_header_bar.png"),
        "badge": open_rgba(stage_dir / "icon_chapter_badge.png"),
        "arrow_button": open_rgba(stage_dir / "ui_arrow_button.png"),
        "prev_arrow": open_rgba(stage_dir / "icon_prev_arrow.png"),
        "next_arrow": open_rgba(stage_dir / "icon_next_arrow.png"),
        "node": open_rgba(stage_dir / "node_normal.png"),
        "boss_badge": open_rgba(stage_dir / "boss_badge.png"),
        "boss": open_rgba(ROOT / boss_path),
        "star_dim": open_rgba(stage_dir / "icon_star_dim.png"),
        "star_lit": open_rgba(stage_dir / "icon_star_lit.png"),
        "dot": open_rgba(stage_dir / "icon_path_dot.png"),
        "reward_panel": open_rgba(stage_dir / "ui_reward_panel_clean.png"),
        "reward_slot": open_rgba(ROOT / "assets" / "images" / "battle_prepare" / "ui_reward_slot.png"),
    }
    reward_keys = [
        "gold_coin", "exp_badge", "capture_ball", "gem_fire",
        "gem_water", "gem_grass", "gem_thunder", "gem_light",
    ]
    reward_paths = {
        "gold_coin": main_dir / "icon_gold_v2.png",
        "exp_badge": main_dir / "icon_exp_star.png",
        "capture_ball": item_dir / "icon_item_capture_ball.png",
        "gem_fire": battle_gem_dir / "gem_fire.png",
        "gem_water": battle_gem_dir / "gem_water.png",
        "gem_grass": battle_gem_dir / "gem_grass.png",
        "gem_thunder": battle_gem_dir / "gem_thunder.png",
        "gem_light": battle_gem_dir / "gem_light.png",
    }
    for key, path in reward_paths.items():
        assets[key] = open_rgba(path)

    back_rect = (9, 12, 56, 56)
    paste_contain(canvas, assets["back_button"], back_rect)
    paste_contain(canvas, assets["back_arrow"], (21, 24, 32, 32))
    paste_contain(canvas, assets["header"], HEADER_BAR_RECT)
    paste_contain(canvas, assets["badge"], HEADER_BADGE_RECT)
    if show_prev:
        paste_contain(canvas, assets["arrow_button"], HEADER_PREV_RECT)
        paste_contain(canvas, assets["prev_arrow"], (HEADER_PREV_RECT[0] + 6, HEADER_PREV_RECT[1] + 6, 22, 22))
    if show_next:
        paste_contain(canvas, assets["arrow_button"], HEADER_NEXT_RECT)
        paste_contain(canvas, assets["next_arrow"], (HEADER_NEXT_RECT[0] + 6, HEADER_NEXT_RECT[1] + 6, 22, 22))
    draw.rectangle(rect_xy(HEADER_TITLE_RECT), outline=(32, 255, 96, 210), width=1)
    draw.rectangle(rect_xy(HEADER_STAR_TEXT_RECT), outline=(255, 255, 255, 160), width=1)
    paste_contain(canvas, assets["star_lit"], HEADER_STAR_RECT)

    full_points = points + [(292, 158)]
    for a, b in zip(full_points, full_points[1:]):
        ax, ay = a
        bx, by = b
        dist = ((bx - ax) ** 2 + (by - ay) ** 2) ** 0.5
        steps = max(1, int(dist // 16))
        for i in range(1, steps):
            t = i / steps
            x = ax + (bx - ax) * t
            y = ay + (by - ay) * t
            paste_contain(canvas, assets["dot"], (x - 4, y - 4, 8, 8))

    node_rects = []
    for index, (cx, cy) in enumerate(points, start=1):
        rect = (cx - 30, cy - 25, 60, 50)
        node_rects.append(rect)
        paste_contain(canvas, assets["node"], rect)
        draw.text((cx - 5, cy - 10), str(index), fill=(255, 255, 255, 255))
        for s in range(3):
            paste_contain(canvas, assets["star_dim"], (cx - 21 + s * 16, cy + 21, 14, 14))

    boss_rect = (292 - 63, 158 - 11, 126, 142)
    paste_contain(canvas, assets["boss_badge"], boss_rect)
    paste_contain(canvas, assets["boss"], (292 - 57, 158 - 34, 114, 102))

    reward_rect = REWARD_RECT
    paste_contain(canvas, assets["reward_panel"], reward_rect)
    slot_w = REWARD_SLOT_SIZE[0]
    gap = REWARD_SLOT_GAP
    total_w = slot_w * len(reward_keys) + gap * (len(reward_keys) - 1)
    start_x = reward_rect[0] + (reward_rect[2] - total_w) / 2
    reward_slot_rects = []
    reward_icon_rects = []
    for i, key in enumerate(reward_keys):
        rect = (start_x + i * (slot_w + gap), reward_rect[1] + 38, slot_w, REWARD_SLOT_SIZE[1])
        reward_slot_rects.append(rect)
        paste_contain(canvas, assets["reward_slot"], rect)
        icon_rect = (rect[0] + 5, rect[1] + 5, rect[2] - 10, rect[3] - 10)
        reward_icon_rects.append(icon_rect)
        paste_contain(canvas, assets[key], icon_rect)

    checks: list[tuple[str, bool, str]] = []
    if show_prev:
        checks.append(("顶部左翻页按钮不压标题文字", not overlaps(HEADER_PREV_RECT, HEADER_TITLE_RECT), f"prev={HEADER_PREV_RECT}, title={HEADER_TITLE_RECT}"))
    checks.append(("顶部标题不压章节徽章", not overlaps(HEADER_TITLE_RECT, HEADER_BADGE_RECT), f"title={HEADER_TITLE_RECT}, badge={HEADER_BADGE_RECT}"))
    if show_next:
        checks.append(("顶部右翻页按钮不压标题文字", not overlaps(HEADER_NEXT_RECT, HEADER_TITLE_RECT), f"next={HEADER_NEXT_RECT}, title={HEADER_TITLE_RECT}"))
        checks.append(("顶部右翻页按钮在标题条内", rect_bounds(HEADER_NEXT_RECT)[2] <= rect_bounds(HEADER_BAR_RECT)[2], f"next={HEADER_NEXT_RECT}, header={HEADER_BAR_RECT}"))
    checks.append(("星级文字区不压标题", not overlaps(HEADER_STAR_TEXT_RECT, HEADER_TITLE_RECT), f"star_text={HEADER_STAR_TEXT_RECT}, title={HEADER_TITLE_RECT}"))
    checks.append(("BOSS 节点不压顶部标题", rect_bounds(boss_rect)[1] >= 78, f"boss={boss_rect}"))
    checks.append(("全部普通节点高于奖励栏", all(rect_bounds(r)[3] < MAP_REWARD_TOP for r in node_rects), str(node_rects)))
    checks.append(("奖励图标全部在奖励面板内", all(rect_bounds(r)[0] >= rect_bounds(reward_rect)[0] and rect_bounds(r)[2] <= rect_bounds(reward_rect)[2] for r in reward_slot_rects), str(reward_slot_rects)))
    checks.append(("奖励图标视觉盒尺寸统一", all(r[2:] == reward_icon_rects[0][2:] for r in reward_icon_rects), str(reward_icon_rects)))
    min_dist = min(((full_points[i + 1][0] - full_points[i][0]) ** 2 + (full_points[i + 1][1] - full_points[i][1]) ** 2) ** 0.5 for i in range(len(full_points) - 1))
    checks.append(("路径相邻节点距离合格", min_dist >= 72, f"min_dist={min_dist:.1f}"))

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    preview = OUT_DIR / f"{case_key}_layout_qa.png"
    report = OUT_DIR / f"{case_key}_layout_qa.md"
    canvas.save(preview)
    rows = [f"# {case_key} Layout QA", "", "| 检查项 | 结果 | 说明 |", "|---|---|---|"]
    for name, ok, detail in checks:
        rows.append(f"| {name} | {'通过' if ok else '需修正'} | `{detail}` |")
    report.write_text("\n".join(rows) + "\n", encoding="utf-8")
    print(preview)
    print(report)
    return preview, report, checks


def main() -> None:
    cases = [
        ("chapter_01_grass", "stage_map_bg_grass.png", [(74, 500), (134, 385), (278, 366), (194, 282)], "assets/images/stage/boss_flower.png", False, True),
        ("chapter_02_fire", "stage_map_bg_fire.png", [(78, 500), (118, 418), (176, 326), (276, 346), (168, 218)], "assets/images/battle/monsters/monster_boss_002_fire.png", True, True),
    ]
    all_checks: list[tuple[str, bool, str]] = []
    for case in cases:
        _, _, checks = render_case(*case)
        all_checks.extend((f"{case[0]} {name}", ok, detail) for name, ok, detail in checks)
    if not all(ok for _, ok, _ in all_checks):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
