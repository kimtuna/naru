extends TestBase

## `DayCycle` — 시계 하나를 빛 하나로 (GDD G-1b 하루 20분 = 낮 10 + 밤 10).
##
## **여기서 지키는 것이 셋이다**:
##   ① 하루가 **정확히 반반**이다 — 램프가 경계에 걸쳐 있어도 낮 10분 · 밤 10분이다
##   ② 빛이 **튀지 않는다** — 해가 다 뜨는 순간에 밝기가 꺾이면 화면이 한 프레임 깜빡인다
##   ③ **밤빛이 `WorldView` 의 부등식을 안 뒤집는다** — 이게 이 파일의 진짜 이유다.
##      곱하기는 채널 비를 바꾼다: 밤빛이 파랄수록 「땅과 그 위의 것은 b 가 제일 작다」가
##      깨지고 **달빛 아래 바위가 웅덩이로 보인다.** 여유를 실제 월드 칸으로 잰다.

## ③ 을 잴 월드. 실제 섬을 쓴다 — 지어낸 색이 아니라 **화면에 나올 칸**이어야 한다.
const SEED := 20260914
## **해안에 놓는다, 스폰이 아니라.** 스폰 둘레 24×24 는 물이 **한 칸도 없어서**
## (2026-09-15 실측: 땅 576 · 물 0) 물 쪽 부등식이 통째로 공허했다 —
## `measure_window.gd` 가 DRAW 를 해안에 세우는 것과 같은 이유다.
const PATCH := 24          # 해안 칸을 한가운데 두고 이만큼 × 이만큼
const MIN_KIND := 40       # 땅도 물도 이만큼은 있어야 「쟀다」고 한다
## 하루를 이만큼으로 쪼개 전부 본다. 빛은 두 끝(낮·밤) 사이의 볼록 결합이지만,
## 부등식은 곱한 뒤에 보는 것이라 **중간 빛도 같이 확인한다**.
const PHASES := 20

# ── ① 하루가 반반이다 ────────────────────────────────────────────────

func test_day_is_exactly_half_of_the_day() -> void:
	var n := 1200
	var day := 0
	for i in n:
		if DayCycle.is_day(WorldState.DAY_SEC * float(i) / n):
			day += 1
	eq(day, n / 2, "하루 %d 표본 중 낮의 수 (GDD 낮 10분 + 밤 10분)" % n)

func test_noon_is_day_and_midnight_is_night() -> void:
	check(DayCycle.is_day(0.0), "판이 시작하는 순간은 낮이다 (시작 위상 %.2f)" % DayCycle.START_PHASE)
	check(not DayCycle.is_day(WorldState.DAY_SEC * 0.5), "반 바퀴 뒤는 밤이다")
	check(DayCycle.is_day(WorldState.DAY_SEC), "한 바퀴 뒤는 다시 낮이다")

func test_start_is_full_daylight() -> void:
	eq(DayCycle.daylight(0.0), 1.0, "판이 시작하는 순간의 밝기 (한낮이라 곱이 1 이다)")
	eq(DayCycle.light_at(0.0), DayCycle.DAY_LIGHT, "판이 시작하는 순간의 하늘빛")

func test_midnight_is_full_night() -> void:
	eq(DayCycle.daylight(WorldState.DAY_SEC * 0.5), 0.0, "한밤의 밝기")
	eq(DayCycle.light_at(WorldState.DAY_SEC * 0.5), DayCycle.NIGHT_LIGHT, "한밤의 하늘빛")

## 해가 뜨고 지는 **한가운데는 정확히 반**이다. 램프를 경계에 가운데 맞췄다는 뜻이고,
## 한쪽 끝에 붙이면 낮 10분 · 밤 10분이 깨진다.
func test_sunrise_and_sunset_are_exactly_half_lit() -> void:
	eq(DayCycle.daylight_of_phase(0.0), 0.5, "해 뜨는 한가운데(위상 0.0)의 밝기")
	eq(DayCycle.daylight_of_phase(0.5), 0.5, "해 지는 한가운데(위상 0.5)의 밝기")

func test_a_day_repeats() -> void:
	for i in 7:
		var t := WorldState.DAY_SEC * float(i) / 7.0
		eq(DayCycle.light_at(t), DayCycle.light_at(t + WorldState.DAY_SEC * 3.0),
			"%.0f초와 사흘 뒤의 하늘빛" % t)

## **되감은 시계도 답이 있다.** 저장을 불러오는 자리가 `now` 를 뒤로 놓을 수 있다 —
## `fposmod` 가 아니라 `fmod` 면 여기서 음수 위상이 나와 빛이 뒤집힌다.
func test_negative_time_has_an_answer() -> void:
	for i in 5:
		var t := -WorldState.DAY_SEC * (0.3 + i)
		var p := DayCycle.phase(t)
		check(p >= 0.0 and p < 1.0, "%.0f초의 위상 — 잰 값 %.4f · 기대 [0, 1)" % [t, p])
		eq(DayCycle.light_at(t), DayCycle.light_at(t + WorldState.DAY_SEC * 5.0),
			"%.0f초와 닷새 뒤의 하늘빛" % t)

# ── ② 빛이 튀지 않는다 ───────────────────────────────────────────────

## 하루를 잘게 쪼개 걸으며 **한 걸음의 밝기 변화**를 본다. 램프를 `smoothstep` 없이
## 잇거나 낮밤을 딱 끊으면 여기서 큰 계단이 잡힌다 — 화면이 한 프레임 깜빡이는 그것이다.
func test_light_never_jumps() -> void:
	var n := 2000
	var worst := 0.0
	var at := 0.0
	var prev := DayCycle.daylight_of_phase(0.0)
	for i in range(1, n + 1):
		var p := float(i) / n
		var cur := DayCycle.daylight_of_phase(p)
		var d := absf(cur - prev)
		if d > worst:
			worst = d
			at = p
		prev = cur
	# 한 걸음이 하루의 1/2000 = 0.6초다. 여명 96초에 0.7 이 변하므로 한 걸음은 0.005 쯤이다.
	check(worst < 0.02, "하루 %d걸음 중 가장 큰 밝기 계단 — 잰 값 %.4f (위상 %.3f) · 기대 0.02 미만" % [
		n, worst, at])

## 해 지는 동안 **줄곧 어두워진다**. 어느 구간에서 되밝아지면 그건 주기가 아니라 잡음이다.
func test_dusk_only_darkens_and_dawn_only_brightens() -> void:
	var half := DayCycle.TWILIGHT * 0.5
	var n := 50
	var prev := 2.0
	for i in range(n + 1):
		var p: float = 0.5 - half + DayCycle.TWILIGHT * float(i) / n
		var cur := DayCycle.daylight_of_phase(p)
		check(cur <= prev + 1e-6, "해 질 녘 위상 %.4f 에서 되밝아졌다 — %.4f → %.4f" % [p, prev, cur])
		prev = cur
	prev = -1.0
	for i in range(n + 1):
		var p: float = fposmod(1.0 - half + DayCycle.TWILIGHT * float(i) / n, 1.0)
		var cur := DayCycle.daylight_of_phase(p)
		check(cur >= prev - 1e-6, "해 뜰 녘 위상 %.4f 에서 되어두워졌다 — %.4f → %.4f" % [p, prev, cur])
		prev = cur

## 여명은 하루의 **한 조각**이어야 한다. `TWILIGHT` 가 0.5 를 넘으면 평지가 사라져
## 「한낮」도 「한밤」도 없는 밍밍한 하루가 되고, 위의 반반 계산도 무너진다.
func test_twilight_leaves_a_plateau() -> void:
	check(DayCycle.TWILIGHT > 0.0 and DayCycle.TWILIGHT < 0.5,
		"여명의 몫 — 잰 값 %.3f · 기대 (0, 0.5)" % DayCycle.TWILIGHT)
	# 평지가 실제로 있다: 램프 바로 바깥은 완전한 낮/밤이다.
	var out := DayCycle.TWILIGHT * 0.5 + 0.001
	eq(DayCycle.daylight_of_phase(0.25), 1.0, "한낮(위상 0.25)의 밝기")
	eq(DayCycle.daylight_of_phase(out), 1.0, "해가 다 뜬 직후(위상 %.4f)의 밝기" % out)
	eq(DayCycle.daylight_of_phase(0.5 + out), 0.0, "해가 다 진 직후의 밝기")

func test_night_is_much_darker_than_day() -> void:
	var day := (DayCycle.DAY_LIGHT.r + DayCycle.DAY_LIGHT.g + DayCycle.DAY_LIGHT.b) / 3.0
	var night := (DayCycle.NIGHT_LIGHT.r + DayCycle.NIGHT_LIGHT.g + DayCycle.NIGHT_LIGHT.b) / 3.0
	check(night < day * 0.5, "한밤의 밝기 — 잰 값 %.3f · 기대 한낮(%.3f)의 절반 미만" % [night, day])
	check(night > 0.1, "한밤의 밝기 — 잰 값 %.3f · 기대 0.1 초과 (아무것도 안 보이면 밤이 아니라 암전이다)" % night)

# ── ③ 밤빛이 부등식을 안 뒤집는다 ────────────────────────────────────

## **이 파일의 진짜 이유.** `WorldView` 머리말의 부등식 — 물은 b > g > r ·
## 땅과 그 위의 것은 b 가 제일 작다 — 이 「땅이 물처럼 보이는 일이 없다」를 떠받친다.
## 하늘빛은 그 색을 **채널마다 다른 값으로 곱하므로** 비를 바꿀 수 있다.
## 실제 섬의 칸을 하루 내내 곱해 보고, 뒤집히면 여기서 빨개진다.
func test_inequalities_survive_every_hour() -> void:
	var sp := _coast_tile()
	var worst_land := 999.0          # 땅에서 r 이 b 보다 앞선 여유 중 제일 좁은 것
	var worst_water := 999.0         # 물에서 b 가 g 보다 앞선 여유 중 제일 좁은 것
	var bad_at := ""
	var n_land := 0
	var n_water := 0
	for i in PHASES:
		var light := DayCycle.light_of_phase(float(i) / PHASES)
		for dy in PATCH:
			for dx in PATCH:
				var x := sp.x - PATCH / 2 + dx
				var y := sp.y - PATCH / 2 + dy
				var c := WorldView.color_at(SEED, x, y)
				var lit := Color(c.r * light.r, c.g * light.g, c.b * light.b)
				if WorldGen.tile_at(SEED, x, y) == WorldGen.WATER:
					if i == 0:
						n_water += 1
					var m: float = minf(lit.b - lit.g, lit.g - lit.r)
					if m < worst_water:
						worst_water = m
						if m <= 0.0:
							bad_at = "물 (%d,%d) 위상 %.2f · %s" % [x, y, float(i) / PHASES, lit.to_html(false)]
				else:
					if i == 0:
						n_land += 1
					var m2: float = minf(lit.r - lit.b, lit.g - lit.b)
					if m2 < worst_land:
						worst_land = m2
						if m2 <= 0.0:
							bad_at = "땅 (%d,%d) 위상 %.2f · %s" % [x, y, float(i) / PHASES, lit.to_html(false)]
	# **공허한 초록을 막는다.** 물이 한 칸도 없는 자리를 골랐으면 물 쪽 부등식은
	# 아무것도 안 묻고 통과한다 — 그게 이 검사가 해안으로 옮겨 온 이유다.
	check(n_land >= MIN_KIND, "잰 땅 칸 — 잰 값 %d · 기대 %d 이상 (해안 %s)" % [n_land, MIN_KIND, sp])
	check(n_water >= MIN_KIND, "잰 물 칸 — 잰 값 %d · 기대 %d 이상 (해안 %s)" % [n_water, MIN_KIND, sp])
	check(worst_water > 0.0, "하늘빛 아래 물의 b > g > r — 여유 %.5f · %s" % [worst_water, bad_at])
	check(worst_land > 0.0, "하늘빛 아래 땅의 b 가 제일 작다 — 여유 %.5f · %s" % [worst_land, bad_at])

## 스폰에서 +x 로 걸어 처음 만나는 바다. `measure_window.gd` 의 DRAW 와 **같은 자리**라
## 화면 게이트가 재는 칸들이 곧 여기서 부등식을 묻는 칸들이다.
func _coast_tile() -> Vector2i:
	var t := WorldGen.spawn_tile()
	while t.x < WorldGen.SIZE and WorldGen.tile_at(SEED, t.x, t.y) == WorldGen.LAND:
		t.x += 1
	return t

## 위의 검사가 **왜 빡빡한지**를 숫자로 못 박는다. 밤빛의 b/r 이 이 값을 넘으면
## 땅의 여유가 음수가 된다 — 돌 색(0.58, 0.57, 0.54)이 가장 좁은 자리다.
## 이 줄이 「더 파랗게 하고 싶다」는 다음 회차에게 보내는 쪽지다.
func test_night_light_is_barely_tinted() -> void:
	var n := DayCycle.NIGHT_LIGHT
	check(n.b >= n.r, "밤빛은 따뜻한 쪽이 아니다 — r %.3f · b %.3f" % [n.r, n.b])
	check(n.b / n.r < 1.09,
		"밤빛의 b/r — 잰 값 %.4f · 기대 1.09 미만 (돌의 r 과 b 는 9%% 밖에 안 벌어져 있다)" % (n.b / n.r))
	check(n.g >= n.r and n.g <= n.b, "밤빛의 g 는 r 과 b 사이다 — %s" % n.to_html(false))
