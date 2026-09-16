class_name FoodConfig
extends Resource
## 버프 음식 수치 — 한 곳에 모은다 (값은 expedition/supply/food_config.tres).
## spec/09_expedition/common.md · spec/04_life/farming.md: 작물로 만든 버프 음식이 원정 보급이 된다.
## 음식 종류 · 버프 시간 · 효과 크기는 spec 에 없다 — 전부 임시 값이다. 사람이 플레이해 보고 바꾼다.

const DEFAULT_PATH := "res://expedition/supply/food_config.tres"

## 음식 id → {"buff": 버프 id, "seconds": 버프가 걸려 있는 초}. 들고 우클릭하면 하나를 먹는다.
@export var foods := {}
## 버프 id → 효과. "move_speed" 는 이동 속력에 곱하는 배수다.
@export var buffs := {}


static func load_default() -> FoodConfig:
	return load(DEFAULT_PATH) as FoodConfig


func is_food(item_id: String) -> bool:
	return foods.has(item_id)


func food(item_id: String) -> Dictionary:
	return foods.get(item_id, {})


## 이 버프의 효과 하나 (없으면 기본값).
func effect(buff_id: String, key: String, default: float) -> float:
	return float(buffs.get(buff_id, {}).get(key, default))
