class_name MobSpawner
extends Node
## 몹 부르기 — 코드에서 자리와 마릿수를 정해 몹을 만든다 (원정에서 떼로 부르기 위해, spec/08_combat/mob-ai.md).
## 만든 몹은 mobs 아래에 들어가 근접 공격 · 투사체가 맞힐 수 있고, targets 가 돌려주는 플레이어들을 노린다.
## 언제 · 어디서 저절로 나오는지(스폰 규칙)는 미정이라 여기서 정하지 않는다.

const SCENE := "res://combat/mob_ai/mob.tscn"

signal spawned(mob: Mob)

## 비워 두면 mob_config.tres 를 쓴다.
@export var config: MobConfig

## 몹들의 부모.
var mobs: Node
## 몹이 노릴 대상들을 돌려주는 함수 (Array[Node2D]).
var targets := Callable()


func _ready() -> void:
	if config == null:
		config = MobConfig.load_default()


func setup(mobs_parent: Node, targets_fn: Callable) -> void:
	mobs = mobs_parent
	targets = targets_fn


## at 둘레에 count 마리를 부른다. 첫 마리는 at 에, 나머지는 spawn_spacing 간격으로 둘레에 늘어선다.
func spawn(at: Vector2, count := 1) -> Array[Mob]:
	return spawn_at(positions_around(at, count))


## 주어진 자리마다 한 마리씩 부른다.
func spawn_at(points: Array) -> Array[Mob]:
	var out: Array[Mob] = []
	if mobs == null:
		return out
	for p in points:
		var mob: Mob = (load(SCENE) as PackedScene).instantiate()
		mob.ai = _config()
		mob.targets = targets
		mobs.add_child(mob)
		mob.global_position = p
		out.append(mob)
		spawned.emit(mob)
	return out


## at 둘레에 count 개의 자리 — 겹치지 않게 고리마다 spawn_spacing 간격으로 늘어놓는다.
func positions_around(at: Vector2, count: int) -> Array[Vector2]:
	var out: Array[Vector2] = []
	if count <= 0:
		return out
	out.append(at)
	var gap := _config().spawn_spacing
	var ring := 1
	while out.size() < count:
		var radius := gap * ring
		var slots := maxi(int(floor(TAU * radius / gap)), 1)
		for i in slots:
			if out.size() >= count:
				break
			out.append(at + Vector2.RIGHT.rotated(TAU * i / slots) * radius)
		ring += 1
	return out


## 지금 살아 있는 몹들.
func alive() -> Array[Mob]:
	var out: Array[Mob] = []
	if mobs == null:
		return out
	for child in mobs.get_children():
		var mob := child as Mob
		if mob and not mob.is_dead() and not mob.is_queued_for_deletion():
			out.append(mob)
	return out


func _config() -> MobConfig:
	if config == null:
		config = MobConfig.load_default()
	return config
