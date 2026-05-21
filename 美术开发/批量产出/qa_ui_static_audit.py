from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SCENE_DIR = ROOT / "src" / "ui" / "scene"
OUT_DIR = ROOT / "美术开发" / "验收"
OUT_FILE = OUT_DIR / "界面最终质量验收表.md"


SCENES = [
    ("开始界面", "scene_start.gd", "P0"),
    ("大厅", "scene_main.gd", "P0"),
    ("关卡选择", "scene_stage_select.gd", "P0"),
    ("战斗准备", "scene_battle_prepare.gd", "P0"),
    ("战斗画面", "scene_battle.gd", "P0"),
    ("战斗结算", "scene_result.gd", "P0"),
    ("队伍编成", "scene_team.gd", "P1"),
    ("怪物图鉴", "scene_album.gd", "P1"),
    ("怪物进化", "scene_evolve.gd", "P2"),
    ("怪物牧场", "scene_ranch.gd", "P1"),
    ("背包", "scene_inventory.gd", "P2"),
    ("商店", "scene_shop.gd", "P2"),
    ("签到", "scene_sign_in.gd", "P2"),
    ("成就", "scene_achievement.gd", "P2"),
    ("设置", "scene_settings.gd", "P3"),
    ("新手教程", "scene_tutorial.gd", "P3"),
]


MANUAL_STATUS = {
    "关卡选择": ("局部通过", "第二章火山地图已生成叠图并通过脚本化对齐；其他章节仍需同标准重做"),
    "设置": ("待复核", "由已有元素拼装，功能完成，但系统文字和按钮细节仍需运行窗口人工验收"),
}


def count(pattern: str, text: str) -> int:
    return len(re.findall(pattern, text))


def status_for(name: str, text: str) -> tuple[str, str, list[str]]:
    stretch_scale = count(r"STRETCH_SCALE", text)
    raw_draw = count(r"draw_texture_rect\(", text)
    fit_calls = count(r"_draw_texture_fit\(", text)
    contain_calls = count(r"_draw_texture_contain\(", text)
    draw_string = count(r"draw_string\(", text)
    font_small = count(r"font_size[^\n=]*[=:]\s*[0-9](?:\.0)?\b", text)
    emoji_fallback = count(r'"[^\"]*[⚡★☆←→✓✕🐾🛒📘⚙][^\"]*"', text)

    notes: list[str] = []
    if stretch_scale:
        notes.append(f"`STRETCH_SCALE` {stretch_scale} 处，需确认背景以外的图标未被拉伸")
    if raw_draw and contain_calls == 0:
        notes.append("存在原始 `draw_texture_rect`，缺少等比 contain 工具")
    elif raw_draw:
        notes.append(f"`draw_texture_rect` {raw_draw} 处，需区分面板拉伸和图标等比")
    if fit_calls > contain_calls * 2 and fit_calls > 8:
        notes.append("fit 绘制明显多于 contain，图标/按钮存在拉伸风险")
    if draw_string:
        notes.append(f"文字绘制 {draw_string} 处，需做宽度、截断、居中和阴影一致性验收")
    if font_small:
        notes.append("检测到偏小字号，需要确认手机端可读性")
    if emoji_fallback:
        notes.append("仍存在符号/emoji 风格文本或兜底，需替换为统一图标资产")

    if name in MANUAL_STATUS:
        base_status, base_note = MANUAL_STATUS[name]
        notes.insert(0, base_note)
        return base_status, "；".join(notes), notes

    if not notes:
        return "待人工终验", "静态扫描未发现明显风险，但仍需运行窗口截图验收", notes

    high_risk = stretch_scale > 1 or emoji_fallback > 0 or (fit_calls > contain_calls * 2 and fit_calls > 8)
    return ("待修正" if high_risk else "待复核"), "；".join(notes), notes


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    lines = [
        "# 界面最终质量验收表",
        "",
        "## 结论",
        "",
        "当前项目没有完成全局最终界面质量验收。此前多数界面状态是“资产代入/冒烟通过”，不等于“终验通过”。本表用于跟踪文字、图标、按钮、布局和概念图还原质量。",
        "",
        "## 终验标准",
        "",
        "| 类别 | 必过标准 |",
        "| --- | --- |",
        "| 文字 | 标题、按钮、数值、长文案居中/左对齐一致；不压边、不溢出、不被图标遮挡；小字号手机端可读 |",
        "| 图标 | 奖励、货币、属性、入口图标等比绘制；不横向/纵向拉伸；同类图标尺寸统一 |",
        "| 布局 | 顶栏、内容区、底栏分区清晰；按钮成组对齐；卡片间距统一；无重叠 |",
        "| 点击 | 点击热区与视觉按钮一致；返回/确认/入口按钮不需要长按；滚动区域不遮挡按钮 |",
        "| 概念图 | 已有概念图的界面按概念重排，不用旧 UI 排布硬套新资产 |",
        "| 运行验收 | 需要至少一张运行叠图或窗口截图；脚本能查的对齐项要通过，脚本查不到的做人工复核 |",
        "",
        "## 界面状态",
        "",
        "| 优先级 | 界面 | 场景文件 | 当前终验状态 | 主要风险/待查项 |",
        "| --- | --- | --- | --- | --- |",
    ]

    for name, file_name, priority in SCENES:
        path = SCENE_DIR / file_name
        if not path.exists():
            lines.append(f"| {priority} | {name} | `{file_name}` | 缺文件 | 场景文件不存在 |")
            continue
        text = path.read_text(encoding="utf-8")
        status, note, _ = status_for(name, text)
        lines.append(f"| {priority} | {name} | `{file_name}` | {status} | {note} |")

    lines.extend([
        "",
        "## 已有脚本化验收",
        "",
        "| 界面 | 验收文件 | 结果 |",
        "| --- | --- | --- |",
        "| 关卡选择/第二章火山地图 | `美术开发/验收/stage_select/chapter_02_fire_layout_qa.md` | 顶部按钮、BOSS 避让、节点、奖励栏、路径间距全部通过 |",
        "",
        "## 下一步处理原则",
        "",
        "1. 先处理 P0 主流程界面：开始界面、大厅、关卡选择、战斗准备、战斗画面、战斗结算。",
        "2. 每个界面先产出或复用一张运行叠图，再做文字和图标对齐修正。",
        "3. 对所有图标类绘制，优先改为 contain 等比绘制；只允许背景和可九宫格面板做填充拉伸。",
        "4. 修完一个界面，就在本表把状态推进到“终验通过”，并附截图/叠图路径。",
    ])

    OUT_FILE.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(OUT_FILE)


if __name__ == "__main__":
    main()
