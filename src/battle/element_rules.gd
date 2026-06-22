class_name ElementRules
extends RefCounted

## 战斗幻想属性的唯一规则源。
## 棋盘仍使用五种 boardAffinity；这里仅处理攻击属性与防御属性的克制倍率。

const STRONG_MULTIPLIER: float = 1.5
const WEAK_MULTIPLIER: float = 0.75
const NEUTRAL_MULTIPLIER: float = 1.0

const ELEMENTS: Array[String] = [
	"fire",
	"water",
	"grass",
	"thunder",
	"light",
	"earth",
	"wind",
	"dark",
	"ice",
	"void",
	"temporal",
	"star",
	"chaos"
]

const ELEMENT_RELATIONS: Dictionary = {
	"fire": {"strong": "grass", "weak": "water"},
	"water": {"strong": "fire", "weak": "grass"},
	"grass": {"strong": "water", "weak": "fire"},
	"thunder": {"strong": "light", "weak": "light"},
	"light": {"strong": "dark", "weak": "void"},
	"earth": {"strong": "wind", "weak": "fire"},
	"wind": {"strong": "earth", "weak": "water"},
	"dark": {"strong": "light", "weak": "light"},
	"ice": {"strong": "grass", "weak": "fire"},
	"void": {"strong": "dark", "weak": "light"},
	"temporal": {"strong": "dark", "weak": "void"},
	"star": {"strong": "temporal", "weak": "void"},
	"chaos": {"strong": "star", "weak": "light"}
}


static func get_multiplier(attacker_element: String, defender_element: String) -> float:
	var relation: Dictionary = ELEMENT_RELATIONS.get(attacker_element, {})
	if relation.is_empty():
		return NEUTRAL_MULTIPLIER
	# 保留 v0.3 既有裁决：配置同时命中 strong/weak 时，strong 优先。
	if str(relation.get("strong", "")) == defender_element:
		return STRONG_MULTIPLIER
	if str(relation.get("weak", "")) == defender_element:
		return WEAK_MULTIPLIER
	return NEUTRAL_MULTIPLIER


static func is_known_element(element: String) -> bool:
	return ELEMENT_RELATIONS.has(element)
