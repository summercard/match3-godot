#!/usr/bin/env python3
"""Apply the reviewed game glossary to every translation shard."""

from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
TRANSLATION_DIR = ROOT / "localization" / "shards" / "translations"
LOCALES = ("zh_TW", "en", "ja", "ko", "fr", "de", "es_419")
MONSTER_DISPLAY_NAMES = set(
    re.findall(r'"name"\s*:\s*"([^"]+)"', (ROOT / "src" / "data" / "monster_db.gd").read_text(encoding="utf-8"))
)

EXACT = {
	"萌灵消消大冒险": {"zh_TW": "萌靈消消大冒險", "en": "Creature Match Adventure", "ja": "モンスター・マッチ大冒険", "ko": "몬스터 매치 대모험", "fr": "L’Aventure Match des créatures", "de": "Kreaturen-Match-Abenteuer", "es_419": "Aventura Match de criaturas"},
	"自动": {"zh_TW": "自動", "en": "Auto", "ja": "自動", "ko": "자동", "fr": "Auto", "de": "Automatisch", "es_419": "Automático"},
	"游戏设置": {"zh_TW": "遊戲設定", "en": "Game Settings", "ja": "ゲーム設定", "ko": "게임 설정", "fr": "Paramètres du jeu", "de": "Spieleinstellungen", "es_419": "Configuración del juego"},
	"游戏音效": {"zh_TW": "遊戲音效", "en": "Sound Effects", "ja": "効果音", "ko": "효과음", "fr": "Effets sonores", "de": "Soundeffekte", "es_419": "Efectos de sonido"},
	"消除、按钮与奖励反馈": {"zh_TW": "消除、按鈕與獎勵音效", "en": "Match, button & reward sounds", "ja": "マッチ・ボタン・報酬の効果音", "ko": "매치·버튼·보상 효과음", "fr": "Matchs, boutons et récompenses", "de": "Kombis, Tasten und Belohnungen", "es_419": "Combinaciones, botones y premios"},
	"背景音乐": {"zh_TW": "背景音樂", "en": "Background Music", "ja": "BGM", "ko": "배경 음악", "fr": "Musique", "de": "Musik", "es_419": "Música"},
	"大厅、战斗与结算音乐": {"zh_TW": "大廳、戰鬥與結算音樂", "en": "Lobby, battle & results music", "ja": "ロビー・バトル・リザルトのBGM", "ko": "로비·전투·결과 음악", "fr": "Accueil, combats et résultats", "de": "Lobby, Kampf und Ergebnis", "es_419": "Inicio, combate y resultados"},
	"游戏语言": {"zh_TW": "遊戲語言", "en": "Game Language", "ja": "ゲーム言語", "ko": "게임 언어", "fr": "Langue du jeu", "de": "Spielsprache", "es_419": "Idioma del juego"},
	"自动匹配手机系统语言": {"zh_TW": "自動使用手機系統語言", "en": "Use device language", "ja": "端末の言語を自動使用", "ko": "기기 언어 자동 사용", "fr": "Utiliser la langue de l’appareil", "de": "Gerätesprache automatisch verwenden", "es_419": "Usar el idioma del dispositivo"},
	"设置会自动保存，返回大厅后立即生效": {"zh_TW": "設定會自動儲存", "en": "Settings save automatically", "ja": "設定は自動保存されます", "ko": "설정은 자동 저장됩니다", "fr": "Enregistrement automatique", "de": "Wird automatisch gespeichert", "es_419": "Se guarda automáticamente"},
	"恢复默认": {"zh_TW": "恢復預設", "en": "Restore Defaults", "ja": "初期設定に戻す", "ko": "기본값 복원", "fr": "Valeurs par défaut", "de": "Standardwerte", "es_419": "Valores iniciales"},
	"开始冒险": {"zh_TW": "開始冒險", "en": "Start Adventure", "ja": "冒険スタート", "ko": "모험 시작", "fr": "Partir à l’aventure", "de": "Abenteuer starten", "es_419": "Iniciar aventura"},
	"精灵旅馆": {"zh_TW": "精靈旅館", "en": "Creature Inn", "ja": "モンスター宿屋", "ko": "몬스터 여관", "fr": "Auberge", "de": "Kreaturenhaus", "es_419": "Refugio"},
	"精灵课堂": {"zh_TW": "精靈課堂", "en": "Creature Class", "ja": "モンスター教室", "ko": "몬스터 교실", "fr": "École", "de": "Kreaturenschule", "es_419": "Escuela"},
	"共鸣塔": {"zh_TW": "共鳴塔", "en": "Resonance Tower", "ja": "共鳴塔", "ko": "공명탑", "fr": "Tour de résonance", "de": "Resonanzturm", "es_419": "Torre resonante"},
	"商店": {"zh_TW": "商店", "en": "Shop", "ja": "ショップ", "ko": "상점", "fr": "Boutique", "de": "Laden", "es_419": "Tienda"},
	"图鉴": {"zh_TW": "圖鑑", "en": "Bestiary", "ja": "図鑑", "ko": "도감", "fr": "Bestiaire", "de": "Sammlung", "es_419": "Colección"},
	"背包": {"zh_TW": "背包", "en": "Inventory", "ja": "持ち物", "ko": "인벤토리", "fr": "Inventaire", "de": "Inventar", "es_419": "Mochila"},
	"成就": {"zh_TW": "成就", "en": "Achievements", "ja": "実績", "ko": "업적", "fr": "Succès", "de": "Erfolge", "es_419": "Logros"},
	"签到": {"zh_TW": "簽到", "en": "Login", "ja": "ログイン", "ko": "출석", "fr": "Connexion", "de": "Login", "es_419": "Diario"},
	"主人等级": {"zh_TW": "主人等級", "en": "Player Level", "ja": "プレイヤーLv.", "ko": "플레이어 레벨", "fr": "Niveau joueur", "de": "Spielerstufe", "es_419": "Nivel de jugador"},
	"成就分数": {"zh_TW": "成就分數", "en": "Achievement Score", "ja": "実績スコア", "ko": "업적 점수", "fr": "Score de succès", "de": "Erfolgspunkte", "es_419": "Puntos de logros"},
	"主页": {"zh_TW": "主頁", "en": "Home", "ja": "ホーム", "ko": "홈", "fr": "Accueil", "de": "Start", "es_419": "Inicio"},
	"农场": {"zh_TW": "農場", "en": "Farm", "ja": "農場", "ko": "농장", "fr": "Ferme", "de": "Farm", "es_419": "Granja"},
	"战场": {"zh_TW": "戰場", "en": "Battle", "ja": "バトル", "ko": "전장", "fr": "Combat", "de": "Kampf", "es_419": "Batalla"},
	"菜单": {"zh_TW": "選單", "en": "Menu", "ja": "メニュー", "ko": "메뉴", "fr": "Menu", "de": "Menü", "es_419": "Menú"},
	"左位": {"zh_TW": "左側", "en": "Left Slot", "ja": "左枠", "ko": "왼쪽", "fr": "Gauche", "de": "Links", "es_419": "Izquierda"},
	"右位": {"zh_TW": "右側", "en": "Right Slot", "ja": "右枠", "ko": "오른쪽", "fr": "Droite", "de": "Rechts", "es_419": "Derecha"},
	"队长": {"zh_TW": "隊長", "en": "Leader", "ja": "リーダー", "ko": "리더", "fr": "Chef", "de": "Anführer", "es_419": "Líder"},
	"战斗准备": {"zh_TW": "戰鬥準備", "en": "Battle Prep", "ja": "戦闘準備", "ko": "전투 준비", "fr": "Préparation au combat", "de": "Kampfvorbereitung", "es_419": "Preparación de batalla"},
	"敌方信息": {"zh_TW": "敵方資訊", "en": "Enemy Info", "ja": "敵の情報", "ko": "적 정보", "fr": "Infos ennemi", "de": "Feindinfo", "es_419": "Info del enemigo"},
	"我方队伍": {"zh_TW": "我方隊伍", "en": "Our Team", "ja": "味方チーム", "ko": "우리 팀", "fr": "Notre équipe", "de": "Unser Team", "es_419": "Nuestro equipo"},
	"战力对比": {"zh_TW": "戰力對比", "en": "Power Check", "ja": "戦力比較", "ko": "전투력 비교", "fr": "Comparatif de puissance", "de": "Kraftvergleich", "es_419": "Comparar poder"},
	"进入战斗": {"zh_TW": "進入戰鬥", "en": "Enter Battle", "ja": "バトル開始", "ko": "전투 시작", "fr": "Au combat !", "de": "In den Kampf", "es_419": "¡A luchar!"},
	"领先 %d": {"zh_TW": "領先 %d", "en": "Ahead %d", "ja": "%d 優勢", "ko": "%d 우세", "fr": "Avance %d", "de": "Vorsprung %d", "es_419": "Ventaja %d"},
	"落后 %d": {"zh_TW": "落後 %d", "en": "Behind %d", "ja": "%d 劣勢", "ko": "%d 열세", "fr": "Retard %d", "de": "Rückstand %d", "es_419": "Desventaja %d"},
	"%s系": {"zh_TW": "%s系", "en": "%s", "ja": "%s", "ko": "%s", "fr": "%s", "de": "%s", "es_419": "%s"},
	"炽能": {"zh_TW": "熾能", "en": "Blaze Energy", "ja": "炎エネルギー", "ko": "화염 에너지", "fr": "Énergie de flamme", "de": "Flammenenergie", "es_419": "Energía ígnea"},
	"潮能": {"zh_TW": "潮能", "en": "Tide Energy", "ja": "潮エネルギー", "ko": "파도 에너지", "fr": "Énergie de marée", "de": "Gezeitenenergie", "es_419": "Energía de marea"},
	"生能": {"zh_TW": "生能", "en": "Life Energy", "ja": "生命エネルギー", "ko": "생명 에너지", "fr": "Énergie vitale", "de": "Lebensenergie", "es_419": "Energía vital"},
	"震能": {"zh_TW": "震能", "en": "Shock Energy", "ja": "雷エネルギー", "ko": "번개 에너지", "fr": "Énergie de foudre", "de": "Blitzenergie", "es_419": "Energía eléctrica"},
	"辉能": {"zh_TW": "輝能", "en": "Radiant Energy", "ja": "光エネルギー", "ko": "빛 에너지", "fr": "Énergie de lumière", "de": "Lichtenergie", "es_419": "Energía luminosa"},
	"小喷嘴": {"es_419": "Piquito"},
	"信使龟": {"es_419": "Tortuga Mensajera"},
	"火焰犬": {"es_419": "Perrito de Fuego"},
	"草兔兔": {"es_419": "Conejito Verde"},
	"野火虫": {"zh_TW": "野火蟲", "en": "Emberbug", "ja": "ヒノコムシ", "ko": "불씨벌레", "fr": "Flammouche", "de": "Funkenkäfer", "es_419": "Chispabicho"},
	"星级：%d星  等级：Lv.%d": {"zh_TW": "星級：%d星 · 等級：Lv.%d", "en": "%d★ · Lv.%d", "ja": "★%d · Lv.%d", "ko": "★%d · Lv.%d", "fr": "%d★ · Niv.%d", "de": "%d★ · St.%d", "es_419": "%d★ · Nv.%d"},
	"性格：": {"zh_TW": "性格：", "en": "Nature: ", "ja": "性格：", "ko": "성격: ", "fr": "Tempérament : ", "de": "Wesen: ", "es_419": "Personalidad: "},
	"属性：": {"zh_TW": "屬性：", "en": "Element: ", "ja": "属性：", "ko": "속성: ", "fr": "Élément : ", "de": "Element: ", "es_419": "Elemento: "},
	"未知": {"zh_TW": "未知", "en": "Unknown", "ja": "不明", "ko": "알 수 없음", "fr": "Inconnu", "de": "Unbekannt", "es_419": "Desconocido"},
	"看图鉴": {"zh_TW": "看圖鑑", "en": "View Bestiary", "ja": "図鑑を見る", "ko": "도감 보기", "fr": "Voir le bestiaire", "de": "Zur Sammlung", "es_419": "Ver colección"},
    "精灵": {"zh_TW": "精靈", "en": "Creature", "ja": "モンスター", "ko": "몬스터", "fr": "Créature", "de": "Kreatur", "es_419": "Criatura"},
    "金币": {"zh_TW": "金幣", "en": "Coins", "ja": "コイン", "ko": "코인", "fr": "Pièces", "de": "Münzen", "es_419": "Monedas"},
    "战力": {"zh_TW": "戰力", "en": "Power", "ja": "戦力", "ko": "전투력", "fr": "Puissance", "de": "Kampfkraft", "es_419": "Poder"},
    "扫荡": {"zh_TW": "掃蕩", "en": "Sweep", "ja": "スキップ", "ko": "소탕", "fr": "Combat express", "de": "Sofortkampf", "es_419": "Combate rápido"},
    "收服": {"zh_TW": "收服", "en": "Capture", "ja": "捕獲", "ko": "포획", "fr": "Capturer", "de": "Fangen", "es_419": "Capturar"},
    "设置": {"zh_TW": "設定", "en": "Settings", "ja": "設定", "ko": "설정", "fr": "Paramètres", "de": "Einstellungen", "es_419": "Ajustes"},
    "水": {"zh_TW": "水", "en": "Water", "ja": "水", "ko": "물", "fr": "Eau", "de": "Wasser", "es_419": "Agua"},
    "火": {"zh_TW": "火", "en": "Fire", "ja": "火", "ko": "불", "fr": "Feu", "de": "Feuer", "es_419": "Fuego"},
    "草": {"zh_TW": "草", "en": "Grass", "ja": "草", "ko": "풀", "fr": "Plante", "de": "Pflanze", "es_419": "Planta"},
    "雷": {"zh_TW": "雷", "en": "Lightning", "ja": "雷", "ko": "번개", "fr": "Foudre", "de": "Blitz", "es_419": "Rayo"},
    "土": {"zh_TW": "土", "en": "Earth", "ja": "土", "ko": "땅", "fr": "Terre", "de": "Erde", "es_419": "Tierra"},
    "风": {"zh_TW": "風", "en": "Wind", "ja": "風", "ko": "바람", "fr": "Vent", "de": "Wind", "es_419": "Viento"},
    "光": {"zh_TW": "光", "en": "Light", "ja": "光", "ko": "빛", "fr": "Lumière", "de": "Licht", "es_419": "Luz"},
    "暗": {"zh_TW": "暗", "en": "Dark", "ja": "闇", "ko": "어둠", "fr": "Ténèbres", "de": "Dunkelheit", "es_419": "Oscuridad"},
    "冰": {"zh_TW": "冰", "en": "Ice", "ja": "氷", "ko": "얼음", "fr": "Glace", "de": "Eis", "es_419": "Hielo"},
}


def replace_creature(locale: str, value: str) -> str:
    if locale == "en":
        for old, new in (("Sprites", "Creatures"), ("Sprite", "Creature"), ("sprites", "creatures"), ("sprite", "creature"), ("Elves", "Creatures"), ("Elf", "Creature"), ("elves", "creatures"), ("elf", "creature")):
            value = value.replace(old, new)
    elif locale == "ja":
        value = value.replace("エルフ", "モンスター")
        value = re.sub(r"(\d+)\s*人の異なるモンスター", r"\1種類のモンスター", value)
    elif locale == "ko":
        value = value.replace("엘프", "몬스터").replace("정령", "몬스터")
    elif locale == "fr":
        for old, new in (("Un elfe", "Une créature"), ("un elfe", "une créature"), ("L'elfe", "La créature"), ("l'elfe", "la créature"), ("d'elfes", "de créatures"), ("Elfes", "Créatures"), ("elfes", "créatures"), ("Elfe", "Créature"), ("elfe", "créature")):
            value = value.replace(old, new)
    elif locale == "de":
        for old, new in (("Ein Elf", "Eine Kreatur"), ("ein Elf", "eine Kreatur"), ("einen Elf", "eine Kreatur"), ("der Elf", "die Kreatur"), ("den Elf", "die Kreatur"), ("des Elfen", "der Kreatur"), ("Elfen", "Kreaturen"), ("elfen", "kreaturen"), ("Elf", "Kreatur"), ("elf", "kreatur")):
            value = value.replace(old, new)
    elif locale == "es_419":
        for old, new in (("Un elfo", "Una criatura"), ("un elfo", "una criatura"), ("El elfo", "La criatura"), ("el elfo", "la criatura"), ("al elfo", "a la criatura"), ("del elfo", "de la criatura"), ("Los elfos", "Las criaturas"), ("los elfos", "las criaturas"), ("Elfos", "Criaturas"), ("elfos", "criaturas"), ("Elfo", "Criatura"), ("elfo", "criatura"), ("Duende", "Criatura"), ("duende", "criatura")):
            value = value.replace(old, new)
    return value


def replace_capture(locale: str, value: str) -> str:
    replacements = {
        "en": (("Conquering", "Capturing"), ("conquering", "capturing"), ("Conquered", "Captured"), ("conquered", "captured"), ("Conquer", "Capture"), ("conquer", "capture")),
        "ja": (("征服", "捕獲"), ("Victory は捕獲", "勝利時に捕獲")),
        "ko": (("정복", "포획"), ("Victory는 포획", "승리 시 포획")),
        "fr": (("Conquérir", "Capturer"), ("conquérir", "capturer"), ("Conquis", "Capturé"), ("conquis", "capturé"), ("Conquête", "Capture"), ("conquête", "capture")),
        "de": (("Eroberungswahrscheinlichkeit", "Fangchance"), ("Eroberung", "Fang"), ("Erobere", "Fange"), ("Erobern", "Fangen"), ("erobern", "fangen"), ("erobert", "gefangen")),
        "es_419": (("Conquistando", "Capturando"), ("conquistando", "capturando"), ("Conquistar", "Capturar"), ("conquistar", "capturar"), ("Conquista", "Captura"), ("conquista", "captura"), ("Conquistado", "Capturado"), ("conquistado", "capturado")),
    }
    for old, new in replacements.get(locale, ()):
        value = value.replace(old, new)
    return value


def replace_sweep(locale: str, value: str) -> str:
    replacements = {
        "ja": (("掃討", "スキップ"),),
        "fr": (("Raid", "Combat express"), ("raid", "combat express")),
        "es_419": (("Barrido", "Combate rápido"), ("barrido", "combate rápido")),
    }
    for old, new in replacements.get(locale, ()):
        value = value.replace(old, new)
    return value


def replace_energy(locale: str, value: str) -> str:
    replacements = {
        "en": (("Physical strength", "Energy"), ("physical strength", "energy"), ("Stamina", "Energy"), ("stamina", "energy")),
        "ja": (("体力", "スタミナ"),),
        "ko": (("체력", "스태미나"),),
        "fr": (("Force physique", "Énergie"), ("force physique", "énergie"), ("Endurance", "Énergie"), ("endurance", "énergie")),
        "de": (("Körperliche Stärke", "Ausdauer"), ("körperliche Stärke", "Ausdauer")),
        "es_419": (("Fuerza física", "Energía"), ("fuerza física", "energía"), ("Resistencia", "Energía"), ("resistencia", "energía")),
    }
    for old, new in replacements.get(locale, ()):
        value = value.replace(old, new)
    return value


def postedit(locale: str, source: str, value: str) -> str:
    if "精灵" in source or (locale == "en" and ("Sprite" in value or "sprite" in value)):
        value = replace_creature(locale, value)
    if any(term in source for term in ("收服", "捕捉", "捕获")):
        value = replace_capture(locale, value)
    if "扫荡" in source:
        value = replace_sweep(locale, value)
    if "体力" in source:
        value = replace_energy(locale, value)
    if locale == "ko":
        value = value.replace("Captain's Burst", "리더 버스트").replace("Rock Wall Front", "암벽 전선")
    if locale == "es_419":
        for old, new in (("boquilla pequeña", "Piquito"), ("tortuga mensajera", "Tortuga Mensajera"), ("perro de fuego", "Perrito de Fuego"), ("conejito de hierba", "Conejito Verde")):
            value = value.replace(old, new)
    value = EXACT.get(source, {}).get(locale, value)
    if source in MONSTER_DISPLAY_NAMES and locale in {"en", "fr", "de", "es_419"} and value:
        value = value[0].upper() + value[1:]
    return value


def main() -> None:
    for locale in LOCALES:
        changed = 0
        for path in sorted((TRANSLATION_DIR / locale).glob("*.json")):
            catalog = json.loads(path.read_text(encoding="utf-8"))
            for source, value in list(catalog.items()):
                edited = postedit(locale, source, str(value))
                if edited != value:
                    catalog[source] = edited
                    changed += 1
            path.write_text(json.dumps(dict(sorted(catalog.items())), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"{locale}: {changed} terminology edits")


if __name__ == "__main__":
    main()
