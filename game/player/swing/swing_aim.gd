class_name SwingAim
extends RefCounted
## 휘두르면 무엇이 맞나 — 바라보는 방향 앞, 손이 닿는 범위의 부채꼴 안에서 하나를 고른다.
## 커서가 대상 위에 정확히 있을 필요는 없다. 자원이든 몹이든 같은 규칙이다.
## 1. 바라보는 선이 지나가는 대상이 있으면 그중 가장 가까운 것 (앞의 것이 뒤의 것을 가린다)
## 2. 없으면 바라보는 방향과 각이 가장 작은 것, 같으면 가까운 것


static func in_front(origin: Vector2, facing: Vector2, reach: float, half_arc: float, pos: Vector2) -> bool:
	var to := pos - origin
	if to.length() > reach:
		return false
	return to.is_zero_approx() or absf(facing.angle_to(to)) <= half_arc + 0.0001


static func pick(origin: Vector2, facing: Vector2, reach: float, half_arc: float,
		targets: Array) -> SwingTarget:
	var best: SwingTarget = null
	var best_key := []
	for t: SwingTarget in targets:
		if not in_front(origin, facing, reach, half_arc, t.position):
			continue
		var key := _key(origin, facing, t)
		if best == null or _less(key, best_key):
			best = t
			best_key = key
	return best


## [선 위가 아니면 1, 각, 거리] — 작을수록 먼저.
static func _key(origin: Vector2, facing: Vector2, t: SwingTarget) -> Array:
	var to := t.position - origin
	var along := to.dot(facing)
	var off_line := absf(to.cross(facing))
	var on_line := along >= 0.0 and off_line <= t.radius
	var angle := 0.0 if on_line or to.is_zero_approx() else absf(facing.angle_to(to))
	return [0 if on_line else 1, angle, to.length()]


static func _less(a: Array, b: Array) -> bool:
	for i in a.size():
		if not is_equal_approx(a[i], b[i]):
			return a[i] < b[i]
	return false
