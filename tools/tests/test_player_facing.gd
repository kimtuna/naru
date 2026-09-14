extends TestBase

## 바라보는 방향을 잰다. 마우스가 정하고, 이동 방향과 별개다 (GDD D-2c).
##
## **여기는 순수 계산만 본다.** 노드가 커서를 실제로 읽는지는 씬을 돌려서 재는
## tools/tests/measure_facing.gd 가 본다 — 둘 다 있어야 게이트가 닫힌다.

const FAR := 100.0   # 데드존(8px) 밖이면 거리는 결과를 바꾸지 않는다

## 화면 좌표(y 아래로 증가)에서 각도 deg 를 향하는, 데드존 밖의 겨눔 벡터.
func aim(deg: float, dist: float = FAR) -> Vector2:
	return Vector2.RIGHT.rotated(deg_to_rad(deg)) * dist

func test_constants() -> void:
	eq(PlayerFacing.SNAP_DEG, 45.0, "스냅 반각")
	eq(PlayerFacing.HYSTERESIS_DEG, 10.0, "히스테리시스")
	eq(PlayerFacing.DEAD_ZONE, 8.0, "데드존 px")
	eq(PlayerFacing.AXES.size(), 4, "축 개수")

func test_snaps_to_the_axis_you_point_at() -> void:
	for spec in [[0.0, Vector2.RIGHT], [90.0, Vector2.DOWN], [180.0, Vector2.LEFT], [-90.0, Vector2.UP]]:
		var got: Vector2 = PlayerFacing.nearest(aim(spec[0]))
		eq(got, spec[1], "%.0f° 스냅" % spec[0])

func test_never_returns_a_diagonal() -> void:
	# 360° 를 1° 씩 돈다. 축 아닌 값이 하나라도 나오면 스프라이트가 없다.
	var facing := Vector2.RIGHT
	var bad := 0
	for d in 360:
		facing = PlayerFacing.resolve(aim(float(d)), facing)
		if not PlayerFacing.AXES.has(facing):
			bad += 1
	check(bad == 0, "360° 중 축 아닌 방향 — 잰 값 %d개 · 기대 0개" % bad)

func test_hysteresis_holds_past_the_boundary() -> void:
	# 45° 를 넘어도 55° 까지는 놓지 않는다. 이게 없으면 경계에서 매 프레임 뒤집힌다.
	var f := PlayerFacing.resolve(aim(0.0), Vector2.RIGHT)
	eq(f, Vector2.RIGHT, "0° 에서 오른쪽")
	f = PlayerFacing.resolve(aim(46.0), f)
	eq(f, Vector2.RIGHT, "46° — 경계를 넘었지만 아직 붙잡는다")
	f = PlayerFacing.resolve(aim(54.9), f)
	eq(f, Vector2.RIGHT, "54.9° — 놓는 각 직전")
	f = PlayerFacing.resolve(aim(55.1), f)
	eq(f, Vector2.DOWN, "55.1° — 여기서 놓는다")

func test_hysteresis_is_symmetric() -> void:
	# 반대로 올라올 때도 같은 폭이어야 한다. 아니면 한쪽으로 끌린다.
	var f := PlayerFacing.resolve(aim(90.0), Vector2.DOWN)
	f = PlayerFacing.resolve(aim(44.0), f)
	eq(f, Vector2.DOWN, "44° — 경계를 넘었지만 아직 아래를 본다")
	f = PlayerFacing.resolve(aim(35.1), f)
	eq(f, Vector2.DOWN, "35.1° — 놓는 각 직전")
	f = PlayerFacing.resolve(aim(34.9), f)
	eq(f, Vector2.RIGHT, "34.9° — 여기서 놓는다")

func test_jitter_on_the_boundary_does_not_flicker() -> void:
	# 커서가 45° 경계에서 ±3° 떨린다. 히스테리시스가 없으면 60번 다 뒤집힌다.
	var f := PlayerFacing.resolve(aim(0.0), Vector2.RIGHT)
	var flips := 0
	for i in 60:
		var wobble: float = 45.0 + (3.0 if i % 2 == 0 else -3.0)
		var next: Vector2 = PlayerFacing.resolve(aim(wobble), f)
		if next != f:
			flips += 1
		f = next
	check(flips == 0, "경계 ±3° 흔들림 60프레임의 뒤집힘 — 잰 값 %d회 · 기대 0회" % flips)

func test_dead_zone_keeps_the_last_facing() -> void:
	# 커서가 몸 위에 올라오면 각이 잡음이다. 마지막 방향을 지킨다.
	var f: Vector2 = PlayerFacing.resolve(aim(90.0, 7.9), Vector2.LEFT)
	eq(f, Vector2.LEFT, "데드존 안(7.9px)")
	eq(PlayerFacing.resolve(Vector2.ZERO, Vector2.UP), Vector2.UP, "커서가 정확히 몸 중심")
	f = PlayerFacing.resolve(aim(90.0, 8.1), Vector2.LEFT)
	eq(f, Vector2.DOWN, "데드존 밖(8.1px) — 다시 돈다")

func test_facing_is_independent_of_movement() -> void:
	# 왼쪽으로 걸으면서 오른쪽을 겨눈다 (게걸음). 두 계산이 서로를 안 본다.
	var vel: Vector2 = PlayerMotion.velocity(Vector2.LEFT)
	var f: Vector2 = PlayerFacing.resolve(aim(0.0), Vector2.LEFT)
	eq(vel, Vector2.LEFT * 240.0, "왼쪽 이동 속도")
	eq(f, Vector2.RIGHT, "같은 프레임에 오른쪽을 본다")
