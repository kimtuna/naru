class_name Melee
extends Node
## 근접 공격 — 좌클릭 평타(Swinger)에 맞은 몹에 손에 든 것의 공격 수치만큼 피해를 준다.
## 몹 둘레를 SwingTarget 으로 내놓는다 (targets_near) — 채취와 같은 판정 경로(SwingAim)로 무엇이 맞을지 고른다.

signal mob_hit(mob: Mob, damage: float)

## 비워 두면 weapon_config.tres 를 쓴다.
@export var config: WeaponConfig

## 몹들의 부모.
var mobs: Node


func _ready() -> void:
	if config == null:
		config = WeaponConfig.load_default()


func setup(mobs_parent: Node) -> void:
	mobs = mobs_parent


## 이 아이템으로 이 몹을 한 번 친다. 살아 있는 몹이 아니면 false.
func hit(mob: Mob, item: Variant) -> bool:
	if not is_instance_valid(mob) or mob.is_dead():
		return false
	var damage := config.attack_of(item)
	mob.take_damage(damage)
	mob_hit.emit(mob, damage)
	return true


## origin 둘레 reach 안의 살아 있는 몹들 — 평타가 맞을 수 있는 대상.
func targets_near(origin: Vector2, reach: float) -> Array:
	var out := []
	if mobs == null:
		return out
	for child in mobs.get_children():
		var mob := child as Mob
		if mob == null or mob.is_dead() or mob.is_queued_for_deletion():
			continue
		if origin.distance_to(mob.global_position) > reach:
			continue
		out.append(SwingTarget.create(mob.global_position, config.mob_radius,
			func(item: Variant) -> bool: return hit(mob, item), mob))
	return out
