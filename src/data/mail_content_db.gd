class_name MailContentDB
extends RefCounted

const DAILY_SEND_LIMIT := 3
const MAX_INBOX_SIZE := 30

const BLESSING_TEMPLATES := [
	{"sender": "云岚", "sender_monster_id": "monster_093", "title": "一份勇气祝福", "body": "远方的冒险者托精灵捎来一句话：愿你在下一场战斗中保持勇气。"},
	{"sender": "星芽", "sender_monster_id": "monster_053", "title": "一封温暖来信", "body": "一只小精灵飞过你的营地，留下了陌生旅人的温柔祝福。"},
	{"sender": "潮汐旅人", "sender_monster_id": "monster_002", "title": "来自远方的问候", "body": "远方的冒险者听说了你的旅途，愿你的伙伴始终陪在身边。"},
	{"sender": "林间邮差", "sender_monster_id": "monster_001", "title": "精灵的祝福", "body": "一颗带着叶香的星星落进信箱，里面装着陌生人的小小心意。"},
	{"sender": "远岭观星人", "sender_monster_id": "monster_005", "title": "月光下的旅记", "body": "夜色里的营火替远方旅人捎来问候：愿你和伙伴都能找到下一段风景。"},
	{"sender": "晴空信使", "sender_monster_id": "monster_006", "title": "沿途的小补给", "body": "一只信使精灵越过云层，把旅行途中收集的小补给轻轻放进了你的信箱。"},
]

## Stranger blessings only grant light, early-game supplies. The complete package
## is selected before it enters the pending queue, so reopening the game cannot
## reroll its contents.
const BLESSING_ATTACHMENT_PACKAGES := [
	{"attachments": [{"kind": "gold", "amount": 60}], "weight": 28},
	{"attachments": [{"kind": "shared_exp", "amount": 45}], "weight": 24},
	{"attachments": [{"kind": "gold", "amount": 35}, {"kind": "shared_exp", "amount": 25}], "weight": 20},
	{"attachments": [{"kind": "item", "item_id": "hp_potion", "count": 1}], "weight": 13},
	{"attachments": [{"kind": "item", "item_id": "capture_ball", "count": 1}], "weight": 8},
	{"attachments": [{"kind": "item", "item_id": "rock_hammer", "count": 1}], "weight": 7},
]


static func get_blessing_template(seed: int) -> Dictionary:
	return BLESSING_TEMPLATES[posmod(seed, BLESSING_TEMPLATES.size())].duplicate(true)


static func get_blessing_attachments(seed: int) -> Array:
	var total := 0
	for entry: Dictionary in BLESSING_ATTACHMENT_PACKAGES:
		total += int(entry.get("weight", 0))
	var roll := posmod(seed, maxi(1, total))
	for entry: Dictionary in BLESSING_ATTACHMENT_PACKAGES:
		roll -= int(entry.get("weight", 0))
		if roll < 0:
			return (entry.get("attachments", []) as Array).duplicate(true)
	return (BLESSING_ATTACHMENT_PACKAGES[0].get("attachments", []) as Array).duplicate(true)


static func get_blessing_attachment(seed: int) -> Dictionary:
	var attachments := get_blessing_attachments(seed)
	return attachments[0].duplicate(true) if not attachments.is_empty() else {}
