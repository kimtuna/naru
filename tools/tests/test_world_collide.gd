extends TestBase

## 타일 충돌을 잰다. 값의 출처는 NUMBERS 7절.
##
## 지도는 **손으로 만든다** — 씨앗 월드로 재면 잡음 상수를 건드릴 때마다 검사가 흔들린다.
## `#` 이 막는 칸이고 `.` 이 빈 칸이다. 지도 밖은 비어 있다.
##
## 숫자는 전부 손으로 계산한 값이다: 타일 16 · 상자 반크기 **6 x 4** · 틈 0.01.
## 예) 3번 칸(48px)에 오른쪽으로 부딪히면 몸 중심은 48 - 6 - 0.01 = **41.99**,
## 4번 칸(64px)에 아래로 부딪히면 64 - 4 - 0.01 = **59.99** 다 —
## **상자가 발밑 반 칸이라 세로가 가로보다 2px 더 간다** (회차 16 · 6 - 4).
## **자리는 전부 칸으로 적혀 있다**: 24 = 1.5칸 · 40 = 2.5칸. 타일이 반으로 줄어서
## 회차 16 까지의 값이 그대로 반이 됐다 (48 → 24 · 80 → 40 · 81.99 → 41.99).
##
## **T 를 PlayerMotion.TILE 에서 안 가져온다.** 가져오면 타일을 바꿨을 때 아래 숫자들이
## 소리 없이 틀린 채로 초록이 된다 — 손 계산이 독립된 값이어야 검사가 검사다.
## 대신 둘이 어긋났는지를 test_body_is_narrower_than_a_tile 이 잰다.

const T := 16.0
const TOL := 0.001

# 3번 칸이 세로로 막힌 지도. 「오른쪽이 바다인 해안」이다.
const COAST := ["...#", "...#", "...#", "...#", "...#", "...#"]

# 사방이 막힌 방. 네 방향을 같은 지도로 잰다.
const BOX := ["#####", "#...#", "#...#", "#...#", "#####"]

func _map(rows: Array) -> Callable:
	return func(tx: int, ty: int) -> bool:
		if ty < 0 or ty >= rows.size():
			return false
		var row: String = rows[ty]
		if tx < 0 or tx >= row.length():
			return false
		return row[tx] == "#"

func _open() -> Callable:
	return func(_tx: int, _ty: int) -> bool: return false

func near(actual: float, expected: float, what: String) -> void:
	if absf(actual - expected) > TOL:
		failures.append("%s — 잰 값 %.4f · 기대 %.4f (±%.3f)" % [what, actual, expected, TOL])

func at(actual: Vector2, ex: float, ey: float, what: String) -> void:
	near(actual.x, ex, "%s x" % what)
	near(actual.y, ey, "%s y" % what)

## ── 막는 게 없을 때 ───────────────────────────────────────────────────

func test_open_world_moves_the_whole_motion() -> void:
	# 충돌을 넣었다고 빈 땅에서 느려지면 안 된다 — 속도 게이트가 여기에 기댄다.
	var p := WorldCollide.move(Vector2(24, 24), Vector2(4.0, -3.0), _open())
	at(p, 28.0, 21.0, "빈 월드 이동")

func test_without_a_world_nothing_blocks() -> void:
	# 플레이어 씬만 띄우는 검사(measure_move)는 월드가 없다. 그때도 움직여야 한다.
	var p := WorldCollide.move(Vector2(10, 20), Vector2(240, -240), Callable())
	at(p, 250.0, -220.0, "월드 없이 이동")

func test_zero_motion_stays() -> void:
	var p := WorldCollide.move(Vector2(41.99, 24), Vector2.ZERO, _map(COAST))
	at(p, 41.99, 24.0, "안 움직이면 제자리")

## ── 바다에 못 들어간다 ────────────────────────────────────────────────

func test_stops_in_front_of_the_wall() -> void:
	var p := WorldCollide.move(Vector2(24, 24), Vector2(200, 0), _map(COAST))
	at(p, 41.99, 24.0, "해안에 정면으로 부딪힘")

func test_four_directions_stop_at_the_box_edge() -> void:
	# 방 한가운데(40,40)에서 네 방향으로 500px 씩 — 옆은 벽 앞 6.01px, 위아래는 4.01px 다.
	# **대칭이 아닌 것이 이 회차의 요점이다**: 상자가 네모가 아니라 발밑 직사각형이다.
	var m := _map(BOX)
	var want := {
		"오른쪽": [Vector2(500, 0), Vector2(57.99, 40)],
		"왼쪽": [Vector2(-500, 0), Vector2(22.01, 40)],
		"아래": [Vector2(0, 500), Vector2(40, 59.99)],
		"위": [Vector2(0, -500), Vector2(40, 20.01)],
	}
	for name in want:
		var p := WorldCollide.move(Vector2(40, 40), want[name][0], m)
		at(p, want[name][1].x, want[name][1].y, "%s 벽" % name)

func test_one_tick_does_not_tunnel() -> void:
	# 한 틱에 100칸을 가도 벽을 뚫으면 안 된다 — 지나가는 칸을 전부 본다.
	var p := WorldCollide.move(Vector2(24, 24), Vector2(5000, 0), _map(COAST))
	at(p, 41.99, 24.0, "한 틱 5000px")

func test_resting_on_the_wall_does_not_drift() -> void:
	# 벽에 붙은 자리에서 계속 밀면 값이 흔들리면 안 된다 (몸이 떨린다).
	var p := Vector2(41.99, 24)
	for i in 10:
		p = WorldCollide.move(p, Vector2(4, 0), _map(COAST))
	at(p, 41.99, 24.0, "벽에 10틱 밀기")

## ── 미끄러진다 ────────────────────────────────────────────────────────

func test_diagonal_into_the_coast_slides() -> void:
	# **이 회차의 핵심 주장.** 막힌 축만 죽고 나머지 축은 통째로 살아 있다.
	var p := WorldCollide.move(Vector2(24, 24), Vector2(200, 200), _map(COAST))
	at(p, 41.99, 224.0, "대각으로 해안에 붙음")

func test_slide_keeps_the_full_axis_speed() -> void:
	# 1초치 대각 이동(240 정규화 → 한 축 169.7056)을 그대로 넣는다.
	# 벽을 타는 동안 세로 속력이 줄면 「벽에 끌린다」는 느낌이 된다.
	var step := PlayerMotion.step(Vector2(1, 1), 1.0)
	near(step.x, 169.7056, "대각 1초의 한 축")
	var p := WorldCollide.move(Vector2(24, 24), step, _map(COAST))
	at(p, 41.99, 24.0 + 169.7056, "해안을 타고 내려간 거리")

func test_concave_corner_blocks_both_axes() -> void:
	var m := _map(["...#", "...#", "####"])
	var p := WorldCollide.move(Vector2(40, 24), Vector2(200, 200), m)
	at(p, 41.99, 27.99, "오목한 구석")

## ── 끼지 않는다 ───────────────────────────────────────────────────────

func test_body_is_narrower_than_a_tile() -> void:
	# 이 파일의 값은 전부 T 로 손 계산한 것이다. 고정값이 바뀌면 **여기가 먼저** 빨개진다 —
	# 위쪽 스무 남짓한 기대값이 소리 없이 틀린 채 초록으로 남는 것을 막는다.
	# (**검사를 하나 더 만들지 않고 여기 붙였다**: `mintests` 바닥은 무장된 상태 검사 안의
	#  숫자라 세션이 못 올린다. 개수를 늘리면 「검사를 지우면 바닥이 잡는다」 대조군이
	#  딱 하나만큼 헐거워진다 — 회차 15 에 실제로 놓쳤다.)
	eq(PlayerMotion.TILE, T, "손 계산이 깔고 있는 타일 크기")
	eq(WorldCollide.HALF, Vector2(T * 0.5 - 2.0, T * 0.25), "손 계산이 깔고 있는 상자 반크기")
	# 같으면 16px 통로에서 부동소수 한 톨에 걸려 낀다. 이 부등식이 아래 검사의 근거다.
	check(WorldCollide.HALF.x < T * 0.5,
		"상자 반폭 — 잰 값 %.2f · 기대 타일 반 %.2f 미만" % [WorldCollide.HALF.x, T * 0.5])
	# **발밑 반 칸**: 상자가 몸통 키(2칸)를 따라가면 벽 앞 두 칸에 멈춰 서서
	# 「보이는 땅에 못 가는」 그림이 된다 (BACKLOG P2 · 코어 키퍼 관례).
	check(WorldCollide.HALF.y < WorldCollide.HALF.x,
		"상자 반높이 — 잰 값 %.2f · 기대 반폭 %.2f 미만 (발밑 상자다)" % [
			WorldCollide.HALF.y, WorldCollide.HALF.x])

func test_one_tile_corridor_is_passable() -> void:
	var m := _map(["#.#", "#.#", "#.#", "#.#"])
	var p := WorldCollide.move(Vector2(24, 8), Vector2(0, 500), m)
	at(p, 24.0, 508.0, "폭 1칸 통로 통과")

func test_leaves_a_wall_it_already_overlaps() -> void:
	# 몸이 이미 막는 칸에 걸쳐 있어도 **나오는 쪽은 자유다** —
	# 아니면 월드가 바뀌었을 때 몸이 영영 못 나온다.
	var p := WorldCollide.move(Vector2(45, 24), Vector2(-25, 0), _map(COAST))
	at(p, 20.0, 24.0, "겹친 채 벽에서 나오기")

func test_overlapping_start_is_not_pushed_back() -> void:
	# 겹친 채 벽 쪽으로 밀면 **되밀지 않는다**. 밀어내면 한 틱에 순간이동으로 보인다.
	var p := WorldCollide.move(Vector2(45, 24), Vector2(0.5, 0), _map(COAST))
	check(p.x >= 45.0, "겹친 채 벽 쪽 — 잰 값 %.4f · 기대 45 이상" % p.x)

## ── 씨앗 월드와 붙는 자리 ─────────────────────────────────────────────

func test_seed_world_blocks_water_only() -> void:
	var solid := WorldCollide.solid_from_seed(1)
	var sp := WorldGen.spawn_tile()
	check(not solid.call(sp.x, sp.y), "스폰 칸이 막히면 안 된다 %s" % sp)
	check(solid.call(0, 0), "테두리 칸(0,0)은 막아야 한다")
	check(solid.call(-5, 999), "월드 밖은 막아야 한다")
	var bad := 0
	for y in range(0, WorldGen.SIZE, 11):
		for x in range(0, WorldGen.SIZE, 13):
			if solid.call(x, y) != (WorldGen.tile_at(1, x, y) == WorldGen.WATER):
				bad += 1
	eq(bad, 0, "막는 칸과 바다가 어긋난 칸 수")

func test_overlaps_sees_the_body_corners() -> void:
	var m := _map(COAST)
	check(not WorldCollide.overlaps(Vector2(24, 24), m), "빈 칸 한가운데는 안 겹친다")
	check(WorldCollide.overlaps(Vector2(56, 24), m), "막는 칸 한가운데는 겹친다")
	check(WorldCollide.overlaps(Vector2(44, 24), m), "모서리만 걸쳐도 겹친다")
	check(not WorldCollide.overlaps(Vector2(41.99, 24), m), "벽에 붙어 선 자리는 안 겹친다")
	check(not WorldCollide.overlaps(Vector2(56, 24), Callable()), "월드가 없으면 안 겹친다")

func test_tile_of_works_left_of_the_origin() -> void:
	# 나눗셈의 0 방향 절삭을 쓰면 -1 칸이 0 칸이 되어 경계가 한 칸 밀린다.
	eq(WorldCollide.tile_of(0.0), 0, "0px")
	eq(WorldCollide.tile_of(15.99), 0, "15.99px")
	eq(WorldCollide.tile_of(16.0), 1, "16px")
	eq(WorldCollide.tile_of(-0.01), -1, "-0.01px")
	eq(WorldCollide.tile_of(-16.0), -1, "-16px")
