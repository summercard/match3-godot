#!/usr/bin/env python3
from __future__ import annotations

import csv
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
CONCEPT_DIR = ROOT / "美术开发" / "概念图"
OUT_DIR = ROOT / "美术开发" / "资产拆分"
DOC_DIR = ROOT / "美术开发"


ASSETS = [
    {
        "module": "01_start_screen",
        "module_name": "启动欢迎页",
        "source": "01_启动欢迎页_start_screen.png",
        "scene_file": "js/ui/sceneStart.js",
        "items": [
            ("start_bg_full", "全屏启动页背景参考", (0, 0, 941, 1672), "启动页整屏背景/气氛参考", "可作为重绘背景或首屏静态底图"),
            ("start_logo_title", "标题Logo区", (70, 55, 805, 470), "标题/Logo", "后续建议重绘为透明PNG或矢量化字形"),
            ("start_monster_trio", "三只初始怪物组合", (70, 640, 825, 430), "初始怪物展示", "拆正式资源时再分火/水/草三只透明立绘"),
            ("start_element_gems", "五元素宝石组合", (245, 1000, 450, 240), "三消元素展示", "和board宝石资源保持同一造型"),
            ("start_primary_button", "开始冒险主按钮", (185, 1300, 575, 175), "进入游戏按钮", "可拆九宫格按钮底+文字层"),
            ("start_bottom_version_panel", "底部版本栏", (0, 1510, 941, 162), "版本信息/装饰底栏", "可复用为深色底部装饰条"),
        ],
    },
    {
        "module": "02_main_lobby",
        "module_name": "主界面",
        "source": "02_主界面_main_lobby.png",
        "scene_file": "js/ui/sceneMain.js",
        "items": [
            ("main_top_player_bar", "顶部玩家信息栏", (20, 15, 900, 185), "玩家头像/等级/货币区", "对应SceneMain信息栏，可拆头像框/经验条/货币按钮"),
            ("main_card_adventure", "冒险入口卡片", (30, 270, 420, 365), "开始冒险按钮", "sceneMain start按钮视觉升级"),
            ("main_card_team", "队伍编成卡片", (470, 270, 435, 365), "队伍编成入口", "sceneMain team按钮视觉升级"),
            ("main_card_album", "怪物图鉴卡片", (30, 645, 420, 365), "怪物图鉴入口", "sceneMain album按钮视觉升级"),
            ("main_card_signin", "每日签到卡片", (470, 645, 435, 365), "每日签到入口", "sceneMain signIn按钮视觉升级"),
            ("main_current_team_strip", "当前队伍面板", (30, 1010, 885, 340), "当前队伍展示", "可拆队伍槽/怪物卡/调整按钮"),
            ("main_bottom_nav", "底部功能导航", (35, 1360, 875, 210), "商店/背包/成就/设置", "替换底部小按钮emoji"),
            ("main_element_footer", "底部元素装饰条", (70, 1570, 800, 90), "元素图标装饰", "可拆五元素小图标"),
        ],
    },
    {
        "module": "03_stage_select",
        "module_name": "关卡地图",
        "source": "03_关卡地图_stage_select.png",
        "scene_file": "js/ui/sceneStageSelect.js",
        "items": [
            ("stage_top_header", "章节顶部栏", (0, 0, 941, 165), "章节标题/返回/星数", "替换当前简单标题栏"),
            ("stage_map_full", "草原章节地图", (0, 150, 941, 1185), "章节地图底图", "后续按章节出多张地图背景"),
            ("stage_boss_node", "Boss关卡节点", (645, 185, 270, 290), "Boss关卡入口", "可拆Boss章节点徽章"),
            ("stage_treasure_node", "宝箱关卡节点", (465, 180, 170, 175), "宝箱关卡入口", "奖励关卡节点"),
            ("stage_elite_crystal_node", "精英水晶节点", (355, 625, 170, 210), "精英关卡入口", "elite关卡节点"),
            ("stage_normal_node_sample", "普通关卡节点样例", (70, 1010, 145, 155), "普通关卡入口", "普通节点/星级样式"),
            ("stage_reward_panel", "通关奖励面板", (15, 1335, 910, 305), "关卡奖励预览", "可拆奖励卡槽和物品图标"),
        ],
    },
    {
        "module": "04_battle_match3",
        "module_name": "三消战斗",
        "source": "04_三消战斗_battle_match3.png",
        "scene_file": "js/ui/sceneBattle.js + js/match3/board.js",
        "items": [
            ("battle_top_status", "顶部战斗状态栏", (15, 20, 910, 210), "回合/敌方HP/设置", "对应SceneBattle顶部UI"),
            ("battle_enemy_area", "敌方Boss战斗区", (145, 120, 660, 390), "敌方怪物展示", "Boss立绘需重绘透明Sprite"),
            ("battle_player_cards", "我方队伍状态卡", (20, 515, 900, 230), "我方怪物HP/技能", "替换队伍卡片emoji"),
            ("battle_board_full", "8x8三消棋盘", (20, 740, 900, 670), "三消棋盘整体", "对应Board渲染区；后续拆格子/宝石/特效"),
            ("battle_combo_effect", "连击消除特效", (255, 845, 265, 465), "消除特效", "可作为火属性连击动效参考"),
            ("battle_locked_gem", "锁定宝石样例", (140, 1200, 110, 110), "锁定宝石", "对应Board lockedGems"),
            ("battle_rock_obstacle", "石块障碍样例", (690, 980, 110, 110), "障碍物", "对应Board obstacles"),
            ("battle_footer_score", "底部得分能量栏", (20, 1425, 900, 215), "奖励/得分/能量", "战斗底部信息区"),
            ("gem_fire_sample", "火宝石样例", (30, 760, 100, 100), "fire gem", "对应GEM_TYPES fire"),
            ("gem_water_sample", "水宝石样例", (140, 760, 100, 100), "water gem", "对应GEM_TYPES water"),
            ("gem_grass_sample", "草宝石样例", (250, 760, 100, 100), "grass gem", "对应GEM_TYPES grass"),
            ("gem_thunder_sample", "雷宝石样例", (360, 760, 100, 100), "thunder gem", "对应GEM_TYPES thunder"),
            ("gem_light_sample", "光宝石样例", (580, 760, 100, 100), "light gem", "对应GEM_TYPES light"),
        ],
    },
    {
        "module": "05_monster_album",
        "module_name": "怪物图鉴",
        "source": "05_怪物图鉴_monster_album.png",
        "scene_file": "js/ui/sceneAlbum.js",
        "items": [
            ("album_top_tabs", "标题与属性筛选栏", (20, 15, 900, 175), "图鉴标题/属性筛选", "替换当前筛选标签"),
            ("album_monster_grid", "怪物卡片网格", (25, 180, 890, 730), "怪物列表", "3列卡片布局参考"),
            ("album_card_grass_sample", "草系怪物卡样例", (30, 190, 280, 230), "怪物卡", "可作为怪物卡模板"),
            ("album_card_locked_sample", "锁定怪物卡样例", (610, 685, 285, 230), "未解锁怪物卡", "锁定态样式"),
            ("album_detail_panel", "怪物详情面板", (20, 915, 900, 585), "详情弹层", "对应state=detail"),
            ("album_selected_portrait", "选中怪物立绘区", (50, 990, 355, 345), "怪物立绘", "后续需透明立绘"),
            ("album_stats_block", "属性数值条区域", (430, 1010, 430, 310), "HP/ATK/DEF/SPD", "对应怪物详情数值"),
            ("album_evolution_preview", "进化预览条", (425, 1340, 430, 130), "进化链预览", "对应sceneEvolve入口"),
            ("album_bottom_nav", "底部页签栏", (20, 1510, 900, 135), "图鉴/羁绊/收藏", "后续如保留多页签使用"),
        ],
    },
    {
        "module": "06_team_evolve",
        "module_name": "队伍编成与进化",
        "source": "06_队伍进化_team_evolve.png",
        "scene_file": "js/ui/sceneTeamSetup.js + js/ui/sceneEvolve.js",
        "items": [
            ("team_top_header", "队伍标题栏", (20, 20, 900, 95), "返回/标题/帮助", "队伍页标题"),
            ("team_leader_card", "队长卡", (25, 105, 305, 505), "队长槽位", "对应leader slot"),
            ("team_member1_card", "成员1卡", (350, 130, 265, 480), "成员槽位1", "对应member1 slot"),
            ("team_member2_card", "成员2卡", (630, 130, 280, 480), "成员槽位2", "对应member2 slot"),
            ("team_power_banner", "队伍战力与队长技能栏", (25, 620, 895, 120), "队伍总战力/队长技能", "对应_calcTeamPower与leaderSkill"),
            ("team_evolution_preview", "进化预览区域", (20, 735, 900, 365), "进化预览", "对应sceneEvolve主视觉"),
            ("team_roster_filter", "属性筛选与排序栏", (20, 1110, 900, 100), "怪物筛选", "可扩展sceneTeamSetup"),
            ("team_roster_grid", "怪物列表网格", (20, 1200, 900, 330), "已收服怪物列表", "替换emoji列表卡片"),
            ("team_bottom_buttons", "底部操作按钮", (20, 1535, 900, 125), "取消/保存/分解", "保存/取消按钮样式参考"),
        ],
    },
]


def clamp_box(box: tuple[int, int, int, int], image: Image.Image) -> tuple[int, int, int, int]:
    x, y, w, h = box
    x = max(0, min(x, image.width - 1))
    y = max(0, min(y, image.height - 1))
    w = max(1, min(w, image.width - x))
    h = max(1, min(h, image.height - y))
    return x, y, w, h


def crop_assets() -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    for module in ASSETS:
        src_path = CONCEPT_DIR / module["source"]
        image = Image.open(src_path).convert("RGBA")
        module_dir = OUT_DIR / module["module"]
        module_dir.mkdir(parents=True, exist_ok=True)

        for index, (asset_id, asset_name, box, game_usage, note) in enumerate(module["items"], start=1):
            x, y, w, h = clamp_box(box, image)
            crop = image.crop((x, y, x + w, y + h))
            filename = f"{index:02d}_{asset_id}.png"
            out_path = module_dir / filename
            crop.save(out_path)

            rows.append({
                "module": module["module_name"],
                "module_id": module["module"],
                "asset_id": asset_id,
                "asset_name": asset_name,
                "source_concept": str(src_path.relative_to(ROOT)),
                "source_bbox_xywh": f"{x},{y},{w},{h}",
                "output_file": str(out_path.relative_to(ROOT)),
                "size_px": f"{w}x{h}",
                "game_usage": game_usage,
                "code_entry": module["scene_file"],
                "status": "concept_crop_v1",
                "note": note,
            })

    return rows


def write_csv(rows: list[dict[str, str]]) -> None:
    csv_path = DOC_DIR / "美术资产_游戏对照表.csv"
    fields = [
        "module",
        "module_id",
        "asset_id",
        "asset_name",
        "source_concept",
        "source_bbox_xywh",
        "output_file",
        "size_px",
        "game_usage",
        "code_entry",
        "status",
        "note",
    ]
    with csv_path.open("w", newline="", encoding="utf-8-sig") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)


def write_json(rows: list[dict[str, str]]) -> None:
    json_path = DOC_DIR / "art_asset_manifest.json"
    manifest: dict[str, dict[str, dict[str, str]]] = {}
    for row in rows:
        module = row["module_id"]
        manifest.setdefault(module, {})
        manifest[module][row["asset_id"]] = {
            "name": row["asset_name"],
            "file": row["output_file"],
            "source": row["source_concept"],
            "bbox": row["source_bbox_xywh"],
            "size": row["size_px"],
            "usage": row["game_usage"],
            "codeEntry": row["code_entry"],
            "status": row["status"],
            "note": row["note"],
        }
    json_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")


def write_contact_sheets(rows: list[dict[str, str]]) -> None:
    sheet_dir = DOC_DIR / "资产拆分"
    for module in ASSETS:
        module_rows = [r for r in rows if r["module_id"] == module["module"]]
        thumbs = []
        for row in module_rows:
            path = ROOT / row["output_file"]
            img = Image.open(path).convert("RGBA")
            img.thumbnail((180, 180))
            thumbs.append((row, img.copy()))

        cols = 3
        cell_w, cell_h = 260, 245
        title_h = 70
        rows_count = (len(thumbs) + cols - 1) // cols
        sheet = Image.new("RGBA", (cols * cell_w, title_h + rows_count * cell_h), (18, 22, 40, 255))
        draw = ImageDraw.Draw(sheet)
        try:
            font_title = ImageFont.truetype("/System/Library/Fonts/PingFang.ttc", 24)
            font_small = ImageFont.truetype("/System/Library/Fonts/PingFang.ttc", 13)
        except Exception:
            font_title = ImageFont.load_default()
            font_small = ImageFont.load_default()

        draw.text((18, 18), f"{module['module_name']} - 资产拆分预览", fill=(255, 255, 255), font=font_title)
        for i, (row, img) in enumerate(thumbs):
            cx = (i % cols) * cell_w
            cy = title_h + (i // cols) * cell_h
            draw.rounded_rectangle((cx + 10, cy + 10, cx + cell_w - 10, cy + cell_h - 10), radius=10, fill=(28, 33, 62), outline=(72, 102, 170))
            ix = cx + (cell_w - img.width) // 2
            iy = cy + 20
            sheet.alpha_composite(img, (ix, iy))
            draw.text((cx + 16, cy + 205), row["asset_id"], fill=(255, 215, 0), font=font_small)
            draw.text((cx + 16, cy + 224), row["size_px"], fill=(190, 200, 220), font=font_small)

        sheet.save(sheet_dir / f"{module['module']}_contact_sheet.png")


def write_markdown(rows: list[dict[str, str]]) -> None:
    md_path = DOC_DIR / "美术资产拆分与游戏对照表.md"
    lines: list[str] = []
    lines.append("# 美术资产拆分与游戏对照表")
    lines.append("")
    lines.append("## 交付说明")
    lines.append("")
    lines.append("- 本表基于 `美术开发/概念图` 下 6 张模块概念图拆分。")
    lines.append("- 当前产物状态为 `concept_crop_v1`：可用于UI接入占位、动线验证、正式资产重绘参考。")
    lines.append("- 正式上线资产建议继续输出透明怪物立绘、独立宝石sprite、九宫格UI面板、多状态按钮与序列帧特效。")
    lines.append("- 所有坐标均为源概念图像素坐标 `x,y,w,h`，便于后续重跑或修正裁切。")
    lines.append("")

    for module in ASSETS:
        module_rows = [r for r in rows if r["module_id"] == module["module"]]
        lines.append(f"## {module['module_name']}")
        lines.append("")
        lines.append(f"- 源图：`美术开发/概念图/{module['source']}`")
        lines.append(f"- 主要代码入口：`{module['scene_file']}`")
        lines.append(f"- 拆分预览：`美术开发/资产拆分/{module['module']}_contact_sheet.png`")
        lines.append("")
        lines.append("| 资产ID | 资产名称 | 输出文件 | 尺寸 | 源坐标 | 游戏内对应 | 接入/修正备注 |")
        lines.append("| --- | --- | --- | --- | --- | --- | --- |")
        for row in module_rows:
            lines.append(
                f"| `{row['asset_id']}` | {row['asset_name']} | `{row['output_file']}` | "
                f"{row['size_px']} | `{row['source_bbox_xywh']}` | {row['game_usage']} | {row['note']} |"
            )
        lines.append("")

    md_path.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    rows = crop_assets()
    write_csv(rows)
    write_json(rows)
    write_contact_sheets(rows)
    write_markdown(rows)
    print(f"created {len(rows)} cropped assets")
    print(f"output: {OUT_DIR}")
    print(f"table: {DOC_DIR / '美术资产拆分与游戏对照表.md'}")


if __name__ == "__main__":
    main()
