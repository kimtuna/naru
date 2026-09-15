extends TestBase

## **띠 계산은 순수 함수다** — 화면 없이 잰다.
## 실제 화면에서 엔진이 같은 배율을 거는지는 `measure_window.gd` 의 VIEW 가 본다.
## 둘이 짝이다: 여기가 식을, 저기가 **이 기계의 값**을 맡는다.

const LOGICAL := Vector2i(960, 540)

func test_exact_multiple_leaves_no_bar() -> void:
	# 1080p·4K 는 딱 떨어진다. 여기 띠가 생기면 식이 틀린 것이다.
	eq(Display.max_scale(Vector2i(1920, 1080), LOGICAL), 2, "1920x1080 배율")
	eq(Display.bars(Vector2i(1920, 1080), LOGICAL), Vector2i.ZERO, "1920x1080 띠")
	eq(Display.max_scale(Vector2i(3840, 2160), LOGICAL), 4, "4K 배율")
	eq(Display.bars(Vector2i(3840, 2160), LOGICAL), Vector2i.ZERO, "4K 띠")

func test_floors_never_rounds() -> void:
	# **내림이지 반올림이 아니다.** 3.59 를 4 로 올리면 화면 밖으로 잘려 나가고,
	# 잘린 만큼은 **남이 보는 것을 내가 못 보는 것**이라 ⓒ 가 깨진다.
	eq(Display.max_scale(Vector2i(3448, 2174), LOGICAL), 3, "3.59배는 3")
	eq(Display.max_scale(Vector2i(1919, 1079), LOGICAL), 1, "1.999배는 1")

func test_short_axis_decides() -> void:
	# 가로는 4배가 들어가도 세로가 2배뿐이면 2배다 — `aspect=keep` 이라 한 배율이다.
	eq(Display.max_scale(Vector2i(3840, 1080), LOGICAL), 2, "짧은 축이 정한다")
	eq(Display.max_scale(Vector2i(1920, 2160), LOGICAL), 2, "반대로도 짧은 축")

func test_bar_is_smaller_than_logical() -> void:
	# **이 회차가 지키려는 부등식**이다. 처음에 「두 축 다」로 적었다가 빨개졌다 —
	# `aspect=keep` 은 배율이 하나라서 **묶는 축 하나만** 띠가 작다. 반대쪽은 화면
	# 비율이 16:9 에서 먼 만큼 통째로 남는다 (3456x2168 은 가로가 묶고 세로가 548 남는다).
	# 그래서 「한 단계 더 올릴 수 있었다」는 **두 축이 다** 논리만큼 남았을 때뿐이다.
	for w in [1920, 2560, 3000, 3456, 3840, 5120]:
		for h in [1080, 1440, 1600, 2168, 2234, 2880]:
			var av := Vector2i(w, h)
			var b := Display.bars(av, LOGICAL)
			check(b.x >= 0 and b.y >= 0, "%s — 띠가 음수다: %s" % [str(av), str(b)])
			check(b.x < LOGICAL.x or b.y < LOGICAL.y,
				"%s — 띠 %s 가 두 축 다 논리 %s 만큼 남았다. 배율을 더 올릴 수 있었다" % [str(av), str(b), str(LOGICAL)])

func test_binding_axis_is_the_tight_one() -> void:
	# 묶는 축이 어느 쪽인지 **이름으로** 낸다 — 「세로 띠가 크다」를 보고 배율을 올리려는
	# 다음 회차가 여기서 멈춘다. 가로가 묶으면 세로를 아무리 늘려도 배율이 안 오른다.
	eq(Display.binding_axis(Vector2i(3456, 2168), LOGICAL), "가로", "3456x2168 은 가로가 묶는다")
	eq(Display.binding_axis(Vector2i(5120, 2168), LOGICAL), "세로", "5120x2168 은 세로가 묶는다")
	eq(Display.binding_axis(Vector2i(1920, 1080), LOGICAL), "둘 다", "딱 떨어지면 둘 다")

func test_drawn_is_logical_times_integer() -> void:
	# 그려진 크기는 **언제나** 논리 × 정수다. 여기가 깨지면 도트가 뭉갠다.
	for av in [Vector2i(3456, 2168), Vector2i(2560, 1440), Vector2i(1366, 768)]:
		var s := Display.max_scale(av, LOGICAL)
		eq(Display.drawn(av, LOGICAL), LOGICAL * s, "%s 그려진 크기" % str(av))

func test_never_below_one() -> void:
	# 화면이 논리보다 작아도 0배는 없다. 0배는 띠가 아니라 **아무것도 안 그리는 것**이다.
	eq(Display.max_scale(Vector2i(800, 600), LOGICAL), 1, "작은 화면")
	eq(Display.max_scale(Vector2i.ZERO, LOGICAL), 1, "화면 크기를 못 읽었을 때(헤드리스)")
	eq(Display.max_scale(Vector2i(1920, 1080), Vector2i.ZERO), 1, "논리가 0일 때")

func test_logical_comes_from_project_settings() -> void:
	# **여기 960x540 을 다시 적지 않는다** — project.godot 의 글자가 유일한 출처다.
	# 논리 화면을 바꾸면 `test_project_settings.gd` 가 잡고, 이 줄은 따라간다.
	eq(Display.logical(), Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height")), "논리 화면의 출처")
