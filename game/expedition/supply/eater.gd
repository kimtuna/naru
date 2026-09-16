class_name Eater
extends Node
## 버프 음식 먹기 — 음식을 들고 우클릭하면 하나를 먹고 버프가 걸린다 (spec/09_expedition/common.md 보급).
## 입력은 Interactor 가 받아 여기로 묻는다 (register). 겨눈 칸과 상관없이 먹는다 —
## 다만 겨눈 곳에 제작대 같은 오브젝트가 있으면 그쪽이 먼저다 (Interactor 순서).

signal eaten(item_id: String)

## 비워 두면 food_config.tres 를 쓴다.
@export var config: FoodConfig

var player: Player


func _ready() -> void:
	if config == null:
		config = FoodConfig.load_default()


func setup(who: Player) -> void:
	player = who


func register(interactor: Interactor) -> void:
	for id in config.foods:
		interactor.set_item_action(str(id), func(_item: Dictionary, _cell: Vector2i) -> bool: return eat())


## 손에 든 음식을 하나 먹는다. 음식이 아니면 아무것도 하지 않고 false.
func eat() -> bool:
	var held = player.held_item() if player else null
	if not (held is Dictionary) or not config.is_food(str(held.get("id", ""))):
		return false
	var food := config.food(str(held.id))
	player.buffs.apply(str(food.get("buff", "")), float(food.get("seconds", 0.0)))
	var left := int(held.get("count", 1)) - 1
	player.hotbar.set_item(player.hotbar.selected(), {"id": held.id, "count": left} if left > 0 else null)
	eaten.emit(str(held.id))
	return true
