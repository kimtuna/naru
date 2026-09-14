extends TestBase

## 휘두르는 모션을 잰다 — **순수 계산과 부채꼴의 기하**. 화면에 정말 네모가 나타나고
## 움직이는지는 `measure_window.gd` 의 USE 가 픽셀로 잰다.
##
## **숫자를 글자로 박는다** (회차 19 의 교훈): 0.24초도 90도도 1.5칸도 고른 값이라
## `HandSwing.SWING_SEC` 라는 **이름**으로만 쓰면 0 으로 바꿔도 한 줄이 안 빨개진다.

const WOOD := &"wood"
const STONE := &"stone"
const EPS := 0.001

func test_swing_numbers_are_the_ones_that_were_chosen() -> void:
	# 0.24초 = 60Hz 에서 14프레임 · 초당 4번. 몇 프레임이면 안 보이고 0.5초면 답답하다.
	eq(HandSwing.SWING_SEC, 0.24, "한 번 휘두르는 시간(초)")
	eq(HandSwing.ARC_DEG, 90.0, "휘두르는 부채꼴(도)")
	# 사거리 1.5칸 = 24px. **옆 칸(16px)은 닿고 두 칸 건너(32px)는 못 닿는다.**
	eq(HandSwing.REACH, 24.0, "손이 닿는 거리(px)")
	check(HandSwing.REACH > PlayerMotion.TILE and HandSwing.REACH < PlayerMotion.TILE * 2.0,
		"사거리는 1칸 초과 · 2칸 미만이어야 한다 — 잰 값 %.1f px · 칸 %.0f px" % [
			HandSwing.REACH, PlayerMotion.TILE])
	# 네모는 반 칸이다 — 몸통(16 x 32)보다 작아야 손에 쥔 것으로 보인다.
	eq(HandSwing.SIZE, Vector2(8.0, 8.0), "휘두르는 네모 크기")

func test_a_swing_runs_from_zero_to_one_and_ends() -> void:
	var s := HandSwing.new()
	# **가만히 서 있는 것이 기본 상태다.** 태어나자마자 휘두르고 있으면 안 된다.
	check(not s.is_swinging(), "만들자마자는 안 휘두르는 중이어야 한다")
	eq(s.progress(), 1.0, "안 휘두를 때의 진행도")
	check(s.start(), "좌클릭하면 모션이 시작돼야 한다")
	check(s.is_swinging(), "시작한 뒤에는 휘두르는 중이다")
	eq(s.progress(), 0.0, "막 시작한 진행도")
	s.advance(0.12)
	eq(s.progress(), 0.5, "0.12초 뒤 진행도 (0.24초의 절반)")
	check(s.is_swinging(), "절반에서는 아직 휘두르는 중이다")
	s.advance(0.12)
	eq(s.progress(), 1.0, "0.24초 뒤 진행도")
	check(not s.is_swinging(), "0.24초가 지나면 모션이 끝나야 한다")

func test_a_swing_does_not_restart_on_top_of_itself() -> void:
	# 매 프레임 새로 시작하면 진행도가 0 에 눌러앉아 네모가 한 자리에 붙박인다 —
	# 사람 눈에는 모션이 통째로 사라진다.
	var s := HandSwing.new()
	s.start()
	s.advance(0.1)
	check(not s.start(), "휘두르는 중에 또 누르면 새 모션이 시작되면 안 된다")
	eq(s.progress(), 0.1 / 0.24, "겹쳐 눌러도 진행도가 안 돌아가야 한다")

func test_holding_the_button_swings_again() -> void:
	# **누르고 있으면 계속 휘두른다** (2026-09-14 결정): 나무 한 그루에 수십 번
	# 클릭하게 만들지 않는다. 끝나는 순간이 다음 모션의 시작이다.
	var s := HandSwing.new()
	s.start()
	s.advance(1.0)                      # 한참 지났다
	eq(s.progress(), 1.0, "긴 delta 뒤 진행도가 1 을 넘으면 안 된다")
	check(s.start(), "모션이 끝났으면 다음 모션이 시작돼야 한다")
	eq(s.progress(), 0.0, "다음 모션의 진행도")

func test_the_motion_sweeps_an_arc_around_where_you_aim() -> void:
	# 겨눈 쪽을 한가운데 두고 -45 → +45 로 쓸고 간다. 한가운데(t=0.5)가 정확히 겨눈 쪽이다.
	eq(HandSwing.arc_deg_at(0.0), -45.0, "모션 시작 각(도)")
	eq(HandSwing.arc_deg_at(0.5), 0.0, "모션 한가운데 각(도)")
	eq(HandSwing.arc_deg_at(1.0), 45.0, "모션 끝 각(도)")
	for facing in PlayerFacing.AXES:
		var mid := HandSwing.offset(facing, 0.5)
		check(mid.distance_to(facing * HandSwing.REACH) < EPS,
			"%s 을 볼 때 한가운데는 겨눈 쪽이어야 한다 — 잰 값 %s · 기대 %s" % [
				facing, mid, facing * HandSwing.REACH])
		var prev := -99.0
		for i in 11:
			var t := i / 10.0
			var off := HandSwing.offset(facing, t)
			# **거리는 안 변한다** — 부채꼴이지 찌르기가 아니다.
			check(absf(off.length() - HandSwing.REACH) < EPS,
				"%s · t=%.1f 에서 사거리 — 잰 값 %.4f · 기대 %.1f" % [facing, t, off.length(), HandSwing.REACH])
			# **부채꼴을 안 벗어난다.** 등 뒤를 치면 겨눈 곳과 맞은 곳이 달라진다.
			var deg := rad_to_deg(absf(off.angle_to(facing)))
			check(deg <= HandSwing.ARC_DEG * 0.5 + EPS,
				"%s · t=%.1f 에서 겨눈 쪽과 벌어진 각 — 잰 값 %.2f · 기대 %.1f 이하" % [
					facing, t, deg, HandSwing.ARC_DEG * 0.5])
			# **한 방향으로만 돈다** — 왕복하면 같은 모션을 두 번 보여 주는 것이다.
			var signed := rad_to_deg(facing.angle_to(off))
			check(signed > prev, "%s · t=%.1f 에서 각이 안 늘었다 — 잰 값 %.2f · 직전 %.2f" % [
				facing, t, signed, prev])
			prev = signed

func test_the_motion_moves_across_the_swing() -> void:
	# **모션은 「네모가 뜬다」가 아니라 「네모가 움직인다」다.** 진행도가 달라지면
	# 자리가 달라져야 한다 — 부채꼴이 0 도가 되면 여기가 빨개진다.
	var a := HandSwing.offset(Vector2.RIGHT, 0.0)
	var b := HandSwing.offset(Vector2.RIGHT, 1.0)
	# 24px 반지름 · 90도 부채꼴의 현: 2 * 24 * sin(45) = 33.94 px
	check(absf(a.distance_to(b) - 33.941) < 0.01,
		"모션의 처음과 끝 사이 거리 — 잰 값 %.3f px · 기대 33.941 px" % a.distance_to(b))
	check(HandSwing.offset(Vector2.RIGHT, 0.0).distance_to(HandSwing.offset(Vector2.RIGHT, 0.1)) > 1.0,
		"10%% 만 지나도 네모가 1px 넘게 움직여야 한다")
	# 범위 밖 t 는 잘린다 — 모션이 끝난 뒤 네모가 부채꼴 밖으로 날아가면 안 된다.
	eq(HandSwing.offset(Vector2.RIGHT, 2.0), HandSwing.offset(Vector2.RIGHT, 1.0), "t > 1 은 끝자리")
	eq(HandSwing.offset(Vector2.RIGHT, -1.0), HandSwing.offset(Vector2.RIGHT, 0.0), "t < 0 은 첫자리")

func test_the_swing_is_colored_by_what_is_in_the_hand() -> void:
	# 「손에 든 것의 동작」이다 (GDD D-2c). 색이 늘 같으면 무엇을 휘두르는지 안 보인다.
	eq(HandSwing.color_for(Inventory.EMPTY), HandSwing.BARE, "맨손의 색")
	eq(HandSwing.color_for(WOOD), HotbarView.item_color(WOOD), "목재를 들었을 때의 색")
	check(HandSwing.color_for(WOOD) != HandSwing.color_for(STONE),
		"다른 것을 들면 다른 색이어야 한다")
	check(HandSwing.color_for(WOOD) != HandSwing.BARE,
		"물건을 든 손이 맨손과 같은 색이면 안 된다")
	# **맨손 색은 코와 같다** — 빈 칸을 들면 손 자체를 휘두르는 그림이다.
	eq(HandSwing.BARE, HotbarView.EDGE_HELD, "맨손 색 = 손에 든 칸의 테두리 색")
