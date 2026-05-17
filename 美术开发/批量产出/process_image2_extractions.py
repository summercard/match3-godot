#!/usr/bin/env python3
from __future__ import annotations

import csv
import json
from collections import deque
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "美术开发" / "元素提取" / "image2_source"
OUT = ROOT / "美术开发" / "正式拆分"
DOC = ROOT / "美术开发"


def remove_key(im: Image.Image, key: tuple[int, int, int], hard=52, soft=118) -> Image.Image:
    im = im.convert("RGBA")
    px = im.load()
    kr, kg, kb = key
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            d = ((r - kr) ** 2 + (g - kg) ** 2 + (b - kb) ** 2) ** 0.5
            if d <= hard:
                px[x, y] = (r, g, b, 0)
            elif d < soft:
                na = int(a * (d - hard) / (soft - hard))
                px[x, y] = (r, g, b, na)
    return im


def alpha_bbox(im: Image.Image, pad=10) -> tuple[int, int, int, int]:
    alpha = im.getchannel("A")
    box = alpha.getbbox()
    if not box:
        return 0, 0, im.width, im.height
    l, t, r, b = box
    return max(0, l - pad), max(0, t - pad), min(im.width, r + pad), min(im.height, b + pad)


def crop_trim(im: Image.Image, box: tuple[int, int, int, int] | None = None, pad=10) -> Image.Image:
    if box is not None:
        im = im.crop(box)
    l, t, r, b = alpha_bbox(im, pad)
    return im.crop((l, t, r, b))


def square_pad(im: Image.Image, size: int | None = None) -> Image.Image:
    side = max(im.width, im.height) if size is None else size
    result = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    if im.width > side or im.height > side:
        temp = im.copy()
        temp.thumbnail((side, side), Image.Resampling.LANCZOS)
        im = temp
    result.alpha_composite(im, ((side - im.width) // 2, (side - im.height) // 2))
    return result


def save_asset(im: Image.Image, rel: str, row: dict, variants: list[int] | None = None) -> None:
    path = ROOT / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path)
    row["file"] = rel
    row["size_px"] = f"{im.width}x{im.height}"
    if variants:
        for size in variants:
            v = square_pad(im, size)
            v_rel = str(path.with_name(path.stem + f"_{size}.png").relative_to(ROOT))
            v.save(ROOT / v_rel)
            row.setdefault("variants", []).append(v_rel)


def component_boxes(im: Image.Image, min_area=2000) -> list[tuple[int, int, int, int]]:
    alpha = im.getchannel("A")
    w, h = im.size
    data = alpha.load()
    seen = bytearray(w * h)
    boxes = []
    for y in range(h):
        for x in range(w):
            idx = y * w + x
            if seen[idx] or data[x, y] < 16:
                continue
            q = deque([(x, y)])
            seen[idx] = 1
            minx = maxx = x
            miny = maxy = y
            area = 0
            while q:
                cx, cy = q.popleft()
                area += 1
                minx = min(minx, cx); maxx = max(maxx, cx)
                miny = min(miny, cy); maxy = max(maxy, cy)
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if nx < 0 or ny < 0 or nx >= w or ny >= h:
                        continue
                    nidx = ny * w + nx
                    if seen[nidx] or data[nx, ny] < 16:
                        continue
                    seen[nidx] = 1
                    q.append((nx, ny))
            if area >= min_area:
                boxes.append((minx, miny, maxx + 1, maxy + 1))
    return boxes


def process_monsters(rows: list[dict]) -> None:
    configs = [
        ("monster_fire_lizard_source.png", "monster_001_fire_lizard", "小火龙/火系初始怪", "fire", "monster_001", "js/battle/monsterData.js"),
        ("monster_water_cub_source.png", "monster_002_water_cub", "水龟仔/水系初始怪", "water", "monster_002", "js/battle/monsterData.js"),
        ("monster_grass_leaf_source.png", "monster_003_grass_leaf", "草苗儿/草系初始怪", "grass", "monster_003", "js/battle/monsterData.js"),
    ]
    for src_name, asset_id, cn_name, element, monster_id, code in configs:
        source = SRC / src_name
        keyed = Image.open(source)
        alpha = remove_key(keyed, (255, 0, 255))
        sprite = square_pad(crop_trim(alpha, pad=18))
        rel = f"美术开发/正式拆分/monsters/{asset_id}_battle.png"
        row = {
            "category": "monster",
            "asset_id": asset_id,
            "asset_name": cn_name,
            "element": element,
            "game_id": monster_id,
            "source_file": str(source.relative_to(ROOT)),
            "code_entry": code,
            "usage": "怪物战斗立绘/图鉴立绘/队伍卡头像源",
            "status": "image2_extracted_alpha_v1",
            "note": "image-2根据概念图重绘提取，已透明化；建议后续补idle/attack/hit序列帧。",
            "variants": [],
        }
        save_asset(sprite, rel, row, variants=[512, 256, 128])
        rows.append(row)


def process_gems(rows: list[dict]) -> None:
    source = SRC / "gems_element_sheet_source.png"
    sheet = remove_key(Image.open(source), (255, 0, 255))
    boxes = sorted(component_boxes(sheet, min_area=8000), key=lambda b: b[0])[:5]
    configs = [
        ("gem_fire", "火宝石", "fire", "GEM_TYPES fire"),
        ("gem_water", "水宝石", "water", "GEM_TYPES water"),
        ("gem_grass", "草宝石", "grass", "GEM_TYPES grass"),
        ("gem_thunder", "雷宝石", "thunder", "GEM_TYPES thunder"),
        ("gem_light", "光宝石", "light", "GEM_TYPES light"),
    ]
    for box, (asset_id, name, element, game_id) in zip(boxes, configs):
        sprite = square_pad(crop_trim(sheet, box, pad=8))
        rel = f"美术开发/正式拆分/gems/{asset_id}.png"
        row = {
            "category": "gem",
            "asset_id": asset_id,
            "asset_name": name,
            "element": element,
            "game_id": game_id,
            "source_file": str(source.relative_to(ROOT)),
            "source_bbox_xyxy": ",".join(map(str, box)),
            "code_entry": "js/match3/board.js",
            "usage": "三消棋盘普通宝石sprite",
            "status": "image2_extracted_alpha_v1",
            "note": "替换GEM_EMOJI；运行时建议绘制为cellSize内80%-90%。",
            "variants": [],
        }
        save_asset(sprite, rel, row, variants=[256, 128, 96])
        rows.append(row)

    source2 = SRC / "gems_obstacle_sheet_source.png"
    sheet2 = remove_key(Image.open(source2), (255, 0, 255))
    boxes2 = sorted(component_boxes(sheet2, min_area=9000), key=lambda b: b[0])[:4]
    configs2 = [
        ("gem_locked_tile", "锁定宝石底", "none", "Board lockedGems"),
        ("obstacle_rock_full", "石块障碍完整", "none", "Board obstacles hp=2"),
        ("obstacle_rock_cracked", "石块障碍破损", "none", "Board obstacles hp=1"),
        ("gem_rainbow_special", "彩虹特殊宝石", "rainbow", "enhanced/special gem"),
    ]
    for box, (asset_id, name, element, game_id) in zip(boxes2, configs2):
        sprite = square_pad(crop_trim(sheet2, box, pad=8))
        rel = f"美术开发/正式拆分/gems/{asset_id}.png"
        row = {
            "category": "gem",
            "asset_id": asset_id,
            "asset_name": name,
            "element": element,
            "game_id": game_id,
            "source_file": str(source2.relative_to(ROOT)),
            "source_bbox_xyxy": ",".join(map(str, box)),
            "code_entry": "js/match3/board.js",
            "usage": "棋盘特殊格/障碍物/特殊宝石sprite",
            "status": "image2_extracted_alpha_v1",
            "note": "透明独立资产；锁定层建议作为叠加层覆盖普通宝石。",
            "variants": [],
        }
        save_asset(sprite, rel, row, variants=[256, 128, 96])
        rows.append(row)


def process_ui(rows: list[dict]) -> None:
    source = SRC / "ui_component_sheet_source.png"
    sheet = remove_key(Image.open(source), (0, 255, 0))
    configs = [
        ("ui_btn_blue_primary", "蓝色主按钮底", (35, 185, 505, 375), "通用主按钮 normal", "THEME.buttons.primary / sceneStart / sceneMain"),
        ("ui_btn_gold_action", "金色行动按钮底", (545, 185, 1030, 375), "保存/进化/确认按钮", "sceneTeamSetup / sceneEvolve / sceneResult"),
        ("ui_panel_dark_large", "深蓝大面板", (1080, 120, 1510, 430), "通用面板背景", "THEME.colors.bgCard/bgPanel"),
        ("ui_icon_frame_square", "方形图标框", (35, 610, 290, 855), "底部导航/图标按钮", "sceneMain / sceneShop / sceneSettings"),
        ("ui_monster_card_frame", "怪物卡框", (300, 515, 635, 900), "图鉴/队伍怪物卡", "sceneAlbum / sceneTeamSetup"),
        ("ui_header_bar", "顶部标题条", (650, 535, 1245, 705), "标题栏/章节栏", "sceneStageSelect / sceneBattle"),
        ("ui_hp_bar_green", "HP条组件", (660, 740, 1265, 865), "HP/经验/技能充能条", "sceneBattle / sceneTeamSetup"),
        ("ui_reward_slot_frame", "奖励槽框", (1270, 610, 1485, 855), "奖励/物品格", "sceneResult / sceneInventory / sceneShop"),
    ]
    for asset_id, name, box, usage, code in configs:
        sprite = crop_trim(sheet, box, pad=8)
        rel = f"美术开发/正式拆分/ui/{asset_id}.png"
        row = {
            "category": "ui",
            "asset_id": asset_id,
            "asset_name": name,
            "element": "ui",
            "game_id": asset_id,
            "source_file": str(source.relative_to(ROOT)),
            "source_bbox_xyxy": ",".join(map(str, box)),
            "code_entry": code,
            "usage": usage,
            "status": "image2_extracted_alpha_v1",
            "note": "UI组件已去绿幕；正式接入建议进一步拆九宫格和normal/pressed/disabled状态。",
            "variants": [],
        }
        save_asset(sprite, rel, row)
        rows.append(row)


def write_tables(rows: list[dict]) -> None:
    md = ["# 专业美术资产拆分对照表", ""]
    md.append("本表为 image-2 元素提取后得到的专业拆分资产，不再使用整屏概念图直接裁切作为正式资产。")
    md.append("")
    for category in ["monster", "gem", "ui"]:
        md.append(f"## {category}")
        md.append("")
        md.append("| 资产ID | 名称 | 游戏ID/代码对应 | 文件 | 尺寸 | 用途 | 状态 | 备注 |")
        md.append("| --- | --- | --- | --- | --- | --- | --- | --- |")
        for r in [x for x in rows if x["category"] == category]:
            variants = ", ".join(r.get("variants", []))
            note = r["note"] + (f" 变体：{variants}" if variants else "")
            md.append(f"| `{r['asset_id']}` | {r['asset_name']} | `{r['game_id']}` / `{r['code_entry']}` | `{r['file']}` | {r['size_px']} | {r['usage']} | {r['status']} | {note} |")
        md.append("")
    (DOC / "专业美术资产拆分对照表.md").write_text("\n".join(md), encoding="utf-8")

    fields = ["category", "asset_id", "asset_name", "element", "game_id", "file", "size_px", "source_file", "source_bbox_xyxy", "code_entry", "usage", "status", "note", "variants"]
    with (DOC / "专业美术资产拆分对照表.csv").open("w", newline="", encoding="utf-8-sig") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        for r in rows:
            rr = {k: r.get(k, "") for k in fields}
            rr["variants"] = ";".join(r.get("variants", []))
            writer.writerow(rr)

    manifest = {}
    for r in rows:
        manifest[r["asset_id"]] = {
            "category": r["category"],
            "name": r["asset_name"],
            "element": r["element"],
            "gameId": r["game_id"],
            "file": r["file"],
            "variants": r.get("variants", []),
            "source": r["source_file"],
            "codeEntry": r["code_entry"],
            "usage": r["usage"],
            "status": r["status"],
            "note": r["note"],
        }
    (DOC / "professional_art_asset_manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")


def write_contact_sheet(rows: list[dict]) -> None:
    for category in ["monster", "gem", "ui"]:
        items = [r for r in rows if r["category"] == category]
        cols = 4 if category != "monster" else 3
        cell_w, cell_h = 260, 255
        title_h = 64
        sheet = Image.new("RGBA", (cols * cell_w, title_h + ((len(items) + cols - 1) // cols) * cell_h), (18, 22, 40, 255))
        draw = ImageDraw.Draw(sheet)
        try:
            font_title = ImageFont.truetype("/System/Library/Fonts/PingFang.ttc", 24)
            font_small = ImageFont.truetype("/System/Library/Fonts/PingFang.ttc", 13)
        except Exception:
            font_title = ImageFont.load_default()
            font_small = ImageFont.load_default()
        draw.text((18, 18), f"{category} image-2 extracted assets", fill=(255, 255, 255), font=font_title)
        for i, r in enumerate(items):
            img = Image.open(ROOT / r["file"]).convert("RGBA")
            img.thumbnail((180, 170), Image.Resampling.LANCZOS)
            cx, cy = (i % cols) * cell_w, title_h + (i // cols) * cell_h
            draw.rounded_rectangle((cx + 10, cy + 10, cx + cell_w - 10, cy + cell_h - 10), radius=10, fill=(28, 33, 62), outline=(72, 102, 170))
            sheet.alpha_composite(img, (cx + (cell_w - img.width) // 2, cy + 20))
            draw.text((cx + 16, cy + 205), r["asset_id"], fill=(255, 215, 0), font=font_small)
            draw.text((cx + 16, cy + 225), r["size_px"], fill=(190, 200, 220), font=font_small)
        out = OUT / f"{category}_contact_sheet.png"
        sheet.save(out)


def main() -> None:
    rows: list[dict] = []
    process_monsters(rows)
    process_gems(rows)
    process_ui(rows)
    write_tables(rows)
    write_contact_sheet(rows)
    print(f"processed {len(rows)} professional assets")
    print(f"output root: {OUT}")
    print(f"table: {DOC / '专业美术资产拆分对照表.md'}")


if __name__ == "__main__":
    main()
