extends TestBase

## 이동 계산을 잰다. 값의 출처는 NUMBERS 1절 (타일 48 · 속도 240).
##
## **여기는 순수 계산만 본다.** 노드가 이걸 실제로 쓰는지는 헤드리스로 씬을 돌려서
## 재는 tools/tests/measure_move.gd 가 본다 — 둘 다 있어야 게이트가 닫힌다.

const AXES := {
	"오른쪽": Vector2(1, 0),
	"왼쪽": Vector2(-1, 0),
	"위": Vector2(0, -1),
	"아래": Vector2(0, 1),
}

func test_constants() -> void:
	eq(PlayerMotion.TILE, 48.0, "타일 크기")
	eq(PlayerMotion.SPEED, 240.0, "이동 속도")
	eq(PlayerMotion.SPEED / PlayerMotion.TILE, 5.0, "초당 타일 칸")

func test_four_axes_are_exact() -> void:
	for name in AXES:
		var v: Vector2 = PlayerMotion.velocity(AXES[name])
		eq(v, AXES[name] * 240.0, "%s 속도" % name)

func test_diagonal_is_not_faster() -> void:
	# 정규화를 빼먹으면 339.41 이 나온다 — 대각선으로만 걷는 게임이 된다.
	for d in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
		var got: float = PlayerMotion.velocity(d).length()
		check(is_equal_approx(got, 240.0), "대각선 %s 속력 — 잰 값 %.2f · 기대 240.00" % [d, got])

func test_no_input_is_no_motion() -> void:
	eq(PlayerMotion.velocity(Vector2.ZERO), Vector2.ZERO, "입력 없음")
	# 반대 키를 같이 누르면 서로 지워진다 (get_vector 가 합을 준다).
	eq(PlayerMotion.velocity(Vector2(1, 0) + Vector2(-1, 0)), Vector2.ZERO, "좌우 동시")

func test_one_second_is_five_tiles() -> void:
	# 60프레임을 실제로 적분한다. delta 를 빼먹은 구현은 여기서 터진다.
	var pos := Vector2.ZERO
	for i in 60:
		pos += PlayerMotion.step(Vector2(1, 0), 1.0 / 60.0)
	check(is_equal_approx(pos.x, 240.0), "1초 이동 거리 — 잰 값 %.4f px · 기대 240.0000" % pos.x)
	check(is_equal_approx(pos.x / PlayerMotion.TILE, 5.0),
		"1초 이동 칸 — 잰 값 %.4f 칸 · 기대 5.0000" % (pos.x / PlayerMotion.TILE))
	eq(pos.y, 0.0, "가로 이동 중 세로 흔들림")

func test_tile_center() -> void:
	eq(PlayerMotion.tile_center(0, 0), Vector2(24, 24), "타일 (0,0) 중심")
	eq(PlayerMotion.tile_center(10, 5), Vector2(504, 264), "타일 (10,5) 중심")
