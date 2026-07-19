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
	"Lv.%d · %s\n性格 %s · 性别 %s\n%d★ · 精英 %s\nHP %d · ATK %d\nDEF %d · SPD %d\n战力 %d": {"zh_TW": "Lv.%d · %s\n性格 %s · 性別 %s\n%d★ · 菁英 %s\nHP %d · ATK %d\nDEF %d · SPD %d\n戰力 %d", "en": "Lv.%d · %s\nNature %s · Gender %s\n%d★ · Elite %s\nHP %d · ATK %d\nDEF %d · SPD %d\nPower %d", "ja": "Lv.%d · %s\n性格 %s · 性別 %s\n%d★ · エリート %s\nHP %d · ATK %d\nDEF %d · SPD %d\n戦力 %d", "ko": "Lv.%d · %s\n성격 %s · 성별 %s\n%d★ · 엘리트 %s\nHP %d · ATK %d\nDEF %d · SPD %d\n전투력 %d", "fr": "Niv.%d · %s\nNature %s · Genre %s\n%d★ · Élite %s\nPV %d · ATQ %d\nDÉF %d · VIT %d\nPuissance %d", "de": "St.%d · %s\nWesen %s · Geschl. %s\n%d★ · Elite %s\nLP %d · ANG %d\nABW %d · TMP %d\nKraft %d", "es_419": "Nv.%d · %s\nCarácter %s · Género %s\n%d★ · Élite %s\nPV %d · ATQ %d\nDEF %d · VEL %d\nPoder %d"},
	"升级": {"zh_TW": "升級", "en": "Upgrade", "ja": "強化", "ko": "강화", "fr": "Améliorer", "de": "Aufwerten", "es_419": "Mejorar"},
	"进化": {"zh_TW": "進化", "en": "Evolve", "ja": "進化", "ko": "진화", "fr": "Évoluer", "de": "Entwickeln", "es_419": "Evolucionar"},
	"出售": {"zh_TW": "出售", "en": "Sell", "ja": "売却", "ko": "판매", "fr": "Vendre", "de": "Verkaufen", "es_419": "Vender"},
	"上一章": {"zh_TW": "上一章", "en": "Previous", "ja": "前章", "ko": "이전", "fr": "Préc.", "de": "Zurück", "es_419": "Anterior"},
	"开启远征": {"zh_TW": "開始遠征", "en": "Start", "ja": "遠征開始", "ko": "원정 시작", "fr": "Partir", "de": "Starten", "es_419": "Iniciar"},
	"登塔榜": {"zh_TW": "登塔榜", "en": "Climb", "ja": "登塔", "ko": "등반", "fr": "Ascension", "de": "Aufstieg", "es_419": "Ascenso"},
	"捕获道具": {"zh_TW": "捕獲", "en": "Capture", "ja": "捕獲", "ko": "포획", "fr": "Capture", "de": "Fangen", "es_419": "Captura"},
	"战场道具": {"zh_TW": "戰鬥", "en": "Battle", "ja": "バトル", "ko": "전투", "fr": "Combat", "de": "Kampf", "es_419": "Combate"},
	"其他道具": {"zh_TW": "其他", "en": "Other", "ja": "その他", "ko": "기타", "fr": "Autres", "de": "Sonstiges", "es_419": "Otros"},
	"每日限购 %d/%d": {"zh_TW": "今日 %d/%d", "en": "Daily %d/%d", "ja": "本日 %d/%d", "ko": "오늘 %d/%d", "fr": "Jour %d/%d", "de": "Heute %d/%d", "es_419": "Hoy %d/%d"},
	"送出祝福": {"zh_TW": "送出祝福", "en": "Send Wish", "ja": "祝福送信", "ko": "축복 보내기", "fr": "Bénir", "de": "Segen", "es_419": "Bendecir"},
	"领取附件": {"zh_TW": "領取", "en": "Claim", "ja": "受取", "ko": "수령", "fr": "Réclamer", "de": "Abholen", "es_419": "Recoger"},
	"删除": {"zh_TW": "刪除", "en": "Delete", "ja": "削除", "ko": "삭제", "fr": "Suppr.", "de": "Löschen", "es_419": "Borrar"},
	"未读": {"zh_TW": "未讀", "en": "Unread", "ja": "未読", "ko": "읽지 않음", "fr": "Non lu", "de": "Neu", "es_419": "Sin leer"},
	"已读": {"zh_TW": "已讀", "en": "Read", "ja": "既読", "ko": "읽음", "fr": "Lu", "de": "Gelesen", "es_419": "Leído"},
	"远行信箱": {"zh_TW": "遠行信箱", "en": "Traveler Mail", "ja": "旅のポスト", "ko": "여행 우편함", "fr": "Courrier voyageur", "de": "Reisepost", "es_419": "Correo viajero"},
	"精灵带回的远方回音": {"zh_TW": "精靈帶回的遠方回音", "en": "Echoes from afar", "ja": "遠方からの便り", "ko": "먼 곳의 메아리", "fr": "Échos du lointain", "de": "Echos aus der Ferne", "es_419": "Ecos lejanos"},
	"远方来信": {"zh_TW": "遠方來信", "en": "Letters", "ja": "手紙", "ko": "편지", "fr": "Courrier", "de": "Briefe", "es_419": "Cartas"},
	"图鉴星星总量": {"zh_TW": "圖鑑星星總量", "en": "Bestiary Stars", "ja": "図鑑スター", "ko": "도감 별", "fr": "Étoiles du bestiaire", "de": "Bestiarium-Sterne", "es_419": "Estrellas del bestiario"},
	"解锁精灵": {"zh_TW": "解鎖精靈", "en": "Species", "ja": "発見数", "ko": "발견 수", "fr": "Espèces", "de": "Arten", "es_419": "Especies"},
	"获得星星": {"zh_TW": "獲得星星", "en": "Stars", "ja": "スター", "ko": "별", "fr": "Étoiles", "de": "Sterne", "es_419": "Estrellas"},
	"本轮远征": {"zh_TW": "本輪遠征", "en": "Current Expedition", "ja": "今回の遠征", "ko": "이번 원정", "fr": "Expédition en cours", "de": "Diese Expedition", "es_419": "Expedición actual"},
	"远行者记录": {"zh_TW": "遠行者紀錄", "en": "Traveler Rankings", "ja": "旅人ランキング", "ko": "여행자 순위", "fr": "Classement", "de": "Rangliste", "es_419": "Clasificación"},
	"爆发榜": {"zh_TW": "爆發榜", "en": "Burst", "ja": "瞬発", "ko": "폭발력", "fr": "Exploit", "de": "Burst", "es_419": "Ráfaga"},
	"第 %d 层": {"zh_TW": "第 %d 層", "en": "Floor %d", "ja": "%d階", "ko": "%d층", "fr": "Étage %d", "de": "Ebene %d", "es_419": "Piso %d"},
	"第 %d 层 · %d 回合": {"zh_TW": "第 %d 層 · %d 回合", "en": "Floor %d · Turn %d", "ja": "%d階 · %dターン", "ko": "%d층 · %d턴", "fr": "Étage %d · Tour %d", "de": "Ebene %d · Runde %d", "es_419": "Piso %d · Turno %d"},
	"单回合 %d": {"zh_TW": "單回合 %d", "en": "One Turn %d", "ja": "1ターン %d", "ko": "1턴 %d", "fr": "Un tour %d", "de": "Eine Runde %d", "es_419": "Un turno %d"},
	"最高 %d 层  ·  单回合 %d": {"zh_TW": "最高 %d 層 · 單回合 %d", "en": "Best Floor %d · Turn %d", "ja": "最高%d階 · 1ターン%d", "ko": "최고 %d층 · 1턴 %d", "fr": "Étage max. %d · Tour %d", "de": "Beste Ebene %d · Runde %d", "es_419": "Piso máx. %d · Turno %d"},
	"最高 0 层  ·  单回合 0": {"zh_TW": "最高 0 層 · 單回合 0", "en": "Best Floor 0 · Turn 0", "ja": "最高0階 · 1ターン0", "ko": "최고 0층 · 1턴 0", "fr": "Étage max. 0 · Tour 0", "de": "Beste Ebene 0 · Runde 0", "es_419": "Piso máx. 0 · Turno 0"},
	"捕获球": {"zh_TW": "捕獲球", "en": "Capture Orb", "ja": "捕獲ボール", "ko": "포획볼", "fr": "Orbe de capture", "de": "Fangball", "es_419": "Esfera de captura"},
	"超级捕获球": {"zh_TW": "超級捕獲球", "en": "Super Capture Orb", "ja": "上級捕獲ボール", "ko": "고급 포획볼", "fr": "Orbe de capture +", "de": "Super-Fangball", "es_419": "Superesfera"},
	"大师捕获球": {"zh_TW": "大師捕獲球", "en": "Master Capture Orb", "ja": "マスター捕獲ボール", "ko": "마스터 포획볼", "fr": "Orbe maîtresse", "de": "Meister-Fangball", "es_419": "Esfera maestra"},
	"经验药水": {"zh_TW": "經驗藥水", "en": "EXP Potion", "ja": "EXPポーション", "ko": "경험치 물약", "fr": "Potion d'EXP", "de": "EP-Trank", "es_419": "Poción de EXP"},
	"经验水晶": {"zh_TW": "經驗水晶", "en": "EXP Crystal", "ja": "EXPクリスタル", "ko": "경험치 수정", "fr": "Cristal d'EXP", "de": "EP-Kristall", "es_419": "Cristal de EXP"},
	"金币袋": {"zh_TW": "金幣袋", "en": "Coin Pouch", "ja": "コイン袋", "ko": "골드 주머니", "fr": "Bourse d'or", "de": "Goldbeutel", "es_419": "Bolsa de oro"},
	"金币箱": {"zh_TW": "金幣箱", "en": "Coin Chest", "ja": "コイン箱", "ko": "골드 상자", "fr": "Coffre d'or", "de": "Goldtruhe", "es_419": "Cofre de oro"},
	"HP药水": {"zh_TW": "HP藥水", "en": "HP Potion", "ja": "HPポーション", "ko": "HP 물약", "fr": "Potion de PV", "de": "LP-Trank", "es_419": "Poción de PV"},
	"高级HP药水": {"zh_TW": "高級HP藥水", "en": "Greater HP Potion", "ja": "上級HPポーション", "ko": "상급 HP 물약", "fr": "Grande potion de PV", "de": "Großer LP-Trank", "es_419": "Poción de PV grande"},
	"守护护符": {"zh_TW": "守護護符", "en": "Guard Charm", "ja": "守護のお守り", "ko": "수호 부적", "fr": "Talisman gardien", "de": "Schutztalisman", "es_419": "Talismán guardián"},
	"破岩锤": {"zh_TW": "破岩錘", "en": "Rock Hammer", "ja": "岩砕きハンマー", "ko": "바위 망치", "fr": "Marteau brise-roche", "de": "Felshammer", "es_419": "Martillo rompe-rocas"},
	"高级破岩锤": {"zh_TW": "高級破岩錘", "en": "Greater Rock Hammer", "ja": "上級岩砕きハンマー", "ko": "상급 바위 망치", "fr": "Grand brise-roche", "de": "Großer Felshammer", "es_419": "Martillo rompe-rocas +"},
	"解锁钥匙": {"zh_TW": "解鎖鑰匙", "en": "Unlock Key", "ja": "開錠の鍵", "ko": "해제 열쇠", "fr": "Clé de déverrouillage", "de": "Entsperrschlüssel", "es_419": "Llave maestra"},
	"净雾露": {"zh_TW": "淨霧露", "en": "Mist Cleanser", "ja": "霧払いの雫", "ko": "안개 정화수", "fr": "Rosée purifiante", "de": "Nebelreiniger", "es_419": "Rocío purificador"},
	"专注水晶": {"zh_TW": "專注水晶", "en": "Focus Crystal", "ja": "集中のクリスタル", "ko": "집중 수정", "fr": "Cristal de concentration", "de": "Fokus-Kristall", "es_419": "Cristal de enfoque"},
	"棋盘重置": {"zh_TW": "棋盤重置", "en": "Board Reset", "ja": "ボードリセット", "ko": "보드 리셋", "fr": "Réinitialisation", "de": "Spielfeld-Reset", "es_419": "Reiniciar tablero"},
	"强能护盾": {"zh_TW": "強能護盾", "en": "Power Shield", "ja": "強化シールド", "ko": "강화 방패", "fr": "Bouclier renforcé", "de": "Kraftschild", "es_419": "Escudo reforzado"},
	"属性易形": {"zh_TW": "屬性易形", "en": "Element Shift", "ja": "属性変換", "ko": "속성 변환", "fr": "Transmutation", "de": "Elementwechsel", "es_419": "Cambio elemental"},
	"共享经验槽": {"zh_TW": "共享經驗槽", "en": "Shared EXP", "ja": "共有EXP", "ko": "공유 EXP", "fr": "Réserve d'EXP", "de": "EP-Pool", "es_419": "EXP compartida"},
	"广场": {"zh_TW": "廣場", "en": "Plaza", "ja": "広場", "ko": "광장", "fr": "Place", "de": "Platz", "es_419": "Plaza"},
	"%s %d级": {"zh_TW": "%s Lv.%d", "en": "%s Lv.%d", "ja": "%s Lv.%d", "ko": "%s Lv.%d", "fr": "%s niv. %d", "de": "%s St. %d", "es_419": "%s niv. %d"},
	"金币  %s": {"zh_TW": "金幣 %s", "en": "Coins %s", "ja": "コイン %s", "ko": "골드 %s", "fr": "Or %s", "de": "Gold %s", "es_419": "Oro %s"},
	"钻石  %s": {"zh_TW": "鑽石 %s", "en": "Diamonds %s", "ja": "ジェム %s", "ko": "다이아 %s", "fr": "Gemmes %s", "de": "Diamanten %s", "es_419": "Gemas %s"},
	"体力  %d/5": {"zh_TW": "體力 %d/5", "en": "Energy %d/5", "ja": "スタミナ %d/5", "ko": "행동력 %d/5", "fr": "Énergie %d/5", "de": "Ausdauer %d/5", "es_419": "Energía %d/5"},
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
    "扫荡": {"zh_TW": "掃蕩", "en": "Sweep", "ja": "スキップ", "ko": "소탕", "fr": "Express", "de": "Sofort", "es_419": "Rápido"},
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
