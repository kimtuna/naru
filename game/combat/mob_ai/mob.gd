class_name Mob
extends CharacterBody2D
## 몹 — 지금은 체력만 있다. 체력이 0 이 되면 죽어서 사라진다 (spec/08_combat/damage-death.md).
## 움직임 · 공격은 몹 AI 단계(spec/08_combat/mob-ai.md)가 채운다.

signal died(mob: Mob)

var config := DamageConfig.load_default()
## 만들 때부터 있다 — 트리에 넣기 전에도 피해를 받는다.
var health := Health.new(config.mob_max_health)


func _init() -> void:
	health.died.connect(_on_died)


func take_damage(amount: float) -> bool:
	return health.damage(amount)


func is_dead() -> bool:
	return health.is_dead()


func _on_died() -> void:
	died.emit(self)
	queue_free()
