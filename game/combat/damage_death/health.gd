class_name Health
extends RefCounted
## 체력 — 캐릭터와 몹이 같이 쓴다. 피해를 받아 0 이 되면 한 번 죽는다 (spec/08_combat/damage-death.md).
## 죽은 뒤에는 피해를 더 받지 않는다. reset() 으로 다시 가득 채운다.

signal changed(current: float)
signal died

var max_health := 1.0
var current := 1.0


func _init(max_value := 1.0) -> void:
	max_health = maxf(max_value, 0.0)
	current = max_health


func is_dead() -> bool:
	return current <= 0.0


## 피해를 준다. 0 보다 작은 값은 무시한다. 이번 피해로 죽었으면 true.
func damage(amount: float) -> bool:
	if amount <= 0.0 or is_dead():
		return false
	current = maxf(current - amount, 0.0)
	changed.emit(current)
	if is_dead():
		died.emit()
		return true
	return false


## 살아 있으면 체력을 채운다 (최대를 넘지 않는다).
func heal(amount: float) -> void:
	if amount <= 0.0 or is_dead():
		return
	current = minf(current + amount, max_health)
	changed.emit(current)


## 가득 채운다 — 다시 시작할 때.
func reset() -> void:
	current = max_health
	changed.emit(current)
