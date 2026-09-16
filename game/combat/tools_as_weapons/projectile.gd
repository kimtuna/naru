class_name Projectile
extends Node2D
## 총알 — 곧게 날아가다 몹에 맞으면 피해를 주고 사라진다. 사거리를 다 가도 사라진다.
## 물리 충돌 대신 걸음마다 지나간 선분과 몹 사이 거리를 본다 — 빨라도 몹을 건너뛰지 않는다.

signal hit_mob(mob: Mob, damage: float)

const SIZE := 3.0

var direction := Vector2.RIGHT
var speed := 0.0
var damage := 0.0
var max_distance := 0.0
var hit_radius := 0.0
## 몹들의 부모.
var mobs: Node
var traveled := 0.0


## 트리에 넣은 뒤 global_position 을 쏜 자리로 맞춘다.
static func create(dir: Vector2, gun: Variant, cfg: GunConfig, mobs_parent: Node) -> Projectile:
	var p := Projectile.new()
	p.direction = dir.normalized()
	p.speed = cfg.stat(gun, "speed")
	p.damage = cfg.stat(gun, "damage")
	p.max_distance = cfg.stat(gun, "range")
	p.hit_radius = cfg.hit_radius
	p.mobs = mobs_parent
	var body := ColorRect.new()
	body.size = Vector2(SIZE, SIZE)
	body.position = -body.size / 2.0
	body.color = Color(1.0, 0.9, 0.3)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(body)
	return p


func _physics_process(delta: float) -> void:
	advance(speed * delta)


## step 픽셀만큼 날아간다. 그 사이 몹에 맞았으면 그 몹 (맞으면 사라진다).
func advance(step: float) -> Mob:
	if is_queued_for_deletion():
		return null
	step = minf(step, max_distance - traveled)
	var from := global_position
	var to := from + direction * step
	var mob := _first_mob(from, to)
	if mob:
		mob.take_damage(damage)
		hit_mob.emit(mob, damage)
		queue_free()
		return mob
	global_position = to
	traveled += step
	if traveled >= max_distance:
		queue_free()
	return null


## from → to 선분 위에서 가장 먼저 닿는 살아 있는 몹.
func _first_mob(from: Vector2, to: Vector2) -> Mob:
	if mobs == null:
		return null
	var best: Mob = null
	var best_t := INF
	for child in mobs.get_children():
		var mob := child as Mob
		if mob == null or mob.is_dead() or mob.is_queued_for_deletion():
			continue
		var at := mob.global_position
		var closest := Geometry2D.get_closest_point_to_segment(at, from, to)
		if closest.distance_to(at) > hit_radius:
			continue
		var t := from.distance_to(closest)
		if t < best_t:
			best_t = t
			best = mob
	return best
