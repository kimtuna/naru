class_name Mob
extends CharacterBody2D
## 시험용 몹 — 체력이 0 이 되면 죽어서 사라진다 (spec/08_combat/damage-death.md).
## 기본 AI (spec/08_combat/mob-ai.md): 가만히 있다가 발견 거리 안에 플레이어가 들어오면 쫓아가고,
## 공격 거리 안이면 멈춰서 공격 간격마다 때린다. 놓침 거리 밖으로 멀어지면 다시 가만히 있는다.
## 길찾기는 없다 — 곧장 다가가고 막히면 미끄러진다.

signal died(mob: Mob)
## 대상을 한 번 때렸다.
signal attacked(target: Node2D, damage: float)

enum State { IDLE, CHASE, ATTACK }

var config := DamageConfig.load_default()
## 만들 때부터 있다 — 트리에 넣기 전에도 피해를 받는다.
var health := Health.new(config.mob_max_health)
var ai := MobConfig.load_default()
## 노릴 수 있는 대상들(플레이어들)을 돌려주는 함수. 대상은 global_position 과 take_damage(amount) 가 있다.
## MobSpawner 가 채운다. 비어 있으면 아무도 노리지 않는다.
var targets := Callable()
var state := State.IDLE
## 지금 쫓는 대상. 없으면 null.
var target: Node2D
## 다음 공격까지 남은 초.
var cooldown := 0.0


func _init() -> void:
	health.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	think(delta)
	move_and_slide()


## 한 걸음 판단 — 대상을 고르고 velocity 를 정하고, 닿아 있으면 때린다.
func think(delta: float) -> void:
	cooldown = maxf(cooldown - delta, 0.0)
	velocity = Vector2.ZERO
	if is_dead():
		return
	_update_target()
	if target == null:
		state = State.IDLE
		return
	var to := target.global_position - global_position
	if to.length() > ai.attack_range:
		state = State.CHASE
		velocity = to.normalized() * ai.move_speed
		return
	state = State.ATTACK
	if cooldown <= 0.0:
		attack()


## 대상을 한 번 때린다.
func attack() -> void:
	if target == null or not target.has_method("take_damage"):
		return
	cooldown = ai.attack_interval
	target.take_damage(ai.attack_damage)
	attacked.emit(target, ai.attack_damage)


func _update_target() -> void:
	if target and (not _is_alive(target) or _dist(target) > ai.lose_radius):
		target = null
	if target:
		return
	var best: Node2D = null
	for t in _candidates():
		if _is_alive(t) and _dist(t) <= ai.sight_radius and (best == null or _dist(t) < _dist(best)):
			best = t
	target = best


func _candidates() -> Array:
	if not targets.is_valid():
		return []
	return targets.call()


func _is_alive(t: Node2D) -> bool:
	if not is_instance_valid(t) or t.is_queued_for_deletion() or not t.is_inside_tree():
		return false
	return not ("health" in t and t.health is Health and t.health.is_dead())


func _dist(t: Node2D) -> float:
	return global_position.distance_to(t.global_position)


func take_damage(amount: float) -> bool:
	return health.damage(amount)


func is_dead() -> bool:
	return health.is_dead()


func _on_died() -> void:
	died.emit(self)
	queue_free()
