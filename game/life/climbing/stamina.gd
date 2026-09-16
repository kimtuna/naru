class_name Stamina
extends RefCounted
## 등반 기력 — 절벽에서 움직이는 동안 줄고, 절벽 밖에서 차오른다. 멈춰 있으면 그대로다 (spec/04_life/climbing.md).
## 앵커가 달린 칸에서는 절벽이어도 (움직여도) 차오른다.
## 0 이 된 뒤에도 config.grace 만큼은 더 움직일 수 있다(빨강 여유). 그 여유를 넘기면 떨어져야 한다.

enum Zone { GREEN, ORANGE, RED }

var config: ClimbingConfig
var current := 0.0
## 기력이 0 인 채로 더 쓴 양 — grace 를 넘기면 떨어진다.
var overdraw := 0.0


func _init(cfg: ClimbingConfig = null) -> void:
	config = cfg if cfg else ClimbingConfig.load_default()
	current = config.max_stamina


## delta 초 흘린다. anchored 는 앵커가 달린 칸에 있나. 여유까지 다 써서 떨어져야 하면 true.
func tick(delta: float, on_cliff: bool, moving: bool, anchored := false) -> bool:
	if anchored:
		_regen(config.anchor_regen_per_second * delta)
		return false
	if not on_cliff:
		_regen(config.regen_per_second * delta)
		return false
	if not moving:
		return false
	var use := config.drain_per_second * delta
	var from_current := minf(use, current)
	current -= from_current
	overdraw += use - from_current
	return overdraw > config.grace


func _regen(amount: float) -> void:
	overdraw = 0.0
	current = minf(current + amount, config.max_stamina)


func fraction() -> float:
	return current / config.max_stamina if config.max_stamina > 0.0 else 0.0


func is_full() -> bool:
	return current >= config.max_stamina


func zone() -> Zone:
	var f := fraction()
	if f < config.red_below:
		return Zone.RED
	if f < config.orange_below:
		return Zone.ORANGE
	return Zone.GREEN


## 떨어진 뒤 — 여유를 비운다. 기력은 절벽 밖에서 다시 차오른다.
func clear_overdraw() -> void:
	overdraw = 0.0


func refill() -> void:
	current = config.max_stamina
	overdraw = 0.0
