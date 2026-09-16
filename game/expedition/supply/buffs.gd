class_name Buffs
extends RefCounted
## 캐릭터에 걸린 버프들 — 버프마다 남은 초를 세고, 0 이 되면 풀린다.
## 같은 버프를 다시 받으면 겹치지 않고 남은 시간만 더 긴 쪽으로 새로 맞춘다.
## 효과는 FoodConfig.buffs 에서 읽는다 — 지금은 이동 속력 배수 하나.

signal applied(buff_id: String)
signal expired(buff_id: String)

var config: FoodConfig
## 버프 id → 남은 초.
var _left := {}


func _init(cfg: FoodConfig = null) -> void:
	config = cfg if cfg else FoodConfig.load_default()


func apply(buff_id: String, seconds: float) -> void:
	if buff_id.is_empty() or seconds <= 0.0:
		return
	_left[buff_id] = maxf(time_left(buff_id), seconds)
	applied.emit(buff_id)


func has(buff_id: String) -> bool:
	return _left.has(buff_id)


func time_left(buff_id: String) -> float:
	return float(_left.get(buff_id, 0.0))


func active() -> Array:
	return _left.keys()


## 시간을 delta 초 흘린다. 다 된 버프는 풀린다.
func tick(delta: float) -> void:
	for id in _left.keys():
		_left[id] -= delta
		if _left[id] <= 0.0:
			_left.erase(id)
			expired.emit(id)


## 걸린 버프들의 이동 속력 배수를 곱한 값 (버프가 없으면 1).
func move_speed_multiplier() -> float:
	var m := 1.0
	for id in _left:
		m *= config.effect(id, "move_speed", 1.0)
	return m
