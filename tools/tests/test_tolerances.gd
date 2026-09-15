extends TestBase

## **실측 게이트의 허용치가 「잰 흔들림」 위에, 「막으려는 고장」 아래에 있나.** (회차 39)
##
## ── 왜 이 검사가 있나 ──────────────────────────────────────────────
## 같은 실수가 **네 번** 났다. 전부 허용치를 감으로 적은 것이다:
##   회차 11 `FACE`     유휴 프레임으로 물리를 기다림 — 부하 12회 중 1회 터짐
##   회차 26 `USE`      프레임 수로 시간을 끊음
##   회차 34 `REGROW`   0.30초 구간에 허용 0.05 — 0.05 → 0.10 으로 두 번 키웠다
##   회차 35 `COLLIDE`  0.48초 구간에 허용 ±5 인데 물리 한 틱이 ±5.9
## 매번 「터지면 키운다」로 넘어갔고, 키운 허용치가 **고장까지 덮는지**는 아무도 안 봤다.
##
## ── 무엇을 강제하나 ────────────────────────────────────────────────
## 허용치 하나는 **두 수 사이**에 있어야 한다:
##   ① 잡음 위   band·cap: `허용치 ≥ 최대잰값 + 폭`   floor: `허용치 ≤ 최소잰값 − 폭`
##      폭 하나를 더 얹는 이유: N판으로 잰 폭은 **본 것**일 뿐 상한이 아니다.
##   ② 고장 아래 band·cap: `고장 / 허용치 ≥ 3`        floor: `허용치 / 고장 ≥ 3`
##      배수가 3 아래면 그 게이트는 **잡음과 고장을 못 가른다** — 있으나 마나다.
##
## ── 표의 수는 어디서 왔나 ──────────────────────────────────────────
## `최대`·`최소`·`폭` 은 **`tools/loop/jitter.sh 9` 가 잰 것**이다 (2026-09-15 ·
## 같은 기계 · 같은 HEAD · 9판). 게이트가 실제로 견주는 수를 `Tol.obs` 로 흘려 모은다.
## **다시 재려면 `tools/loop/jitter.sh 9` 를 돌리고 이 표를 고쳐라.** 표를 안 고치고
## 허용치만 만지면 여기가 빨개진다 — 그게 이 검사가 하는 일 전부다.
##
## `고장` 은 **그 게이트가 막는 가장 작은 고장**이다. 감이 아니라 출처가 있다:
## 잰 것(회차 33·34 의 대조군)이거나, 상수에서 셈한 것(한 칸 16px 따위)이다.
## 줄마다 `왜` 에 적었다.
##
## **허용치는 여기 안 적는다** — 게이트 파일의 상수를 `get_script_constant_map()` 으로
## 읽는다. 두 군데 적으면 한쪽만 고치는 날이 오고, 그날 이 검사는 아무것도 안 잡는다.

const MIN_MARGIN := 3.0

# 물↔땅 색차. DRAW 가 재는 곳이 해안이라, 화면이 한 칸 미끄러지면 **이만큼** 튄다.
# 상수에서 셈한다 — 색을 고치면 고장 크기도 따라온다.
const COAST_STEP := 0.39        # max|SHOAL − SHORE| 채널 = |0.13 − 0.52|

const ROWS := [
	{"자리": "MOVE", "파일": "res://tools/tests/measure_move.gd", "상수": "TOL",
	 "꼴": "band", "잰값": 2.326, "폭": 2.313, "고장": 16.0,
	 "왜": "고장 = 한 칸/s (16px). 속도가 칸 단위로 어긋나면 사람이 바로 느낀다"},

	{"자리": "COLLIDE.멈춘자리", "파일": "res://tools/tests/measure_collide.gd", "상수": "TOL_POS",
	 "꼴": "band", "잰값": 0.00001, "폭": 0.0, "고장": 4.0,
	 "왜": "고장 = 물리 한 틱에 가는 거리 240/60 = 4px. 벽을 지나쳤다면 최소 이만큼이다"},

	{"자리": "COLLIDE.세로속력", "파일": "res://tools/tests/measure_collide.gd", "상수": "TOL_RATE",
	 "꼴": "band", "잰값": 2.830, "폭": 1.052, "고장": 169.71,
	 "왜": "고장 = SPEED/√2. 「벽에 닿으면 통째로 멈춘다」면 세로가 0 이 된다 (회차 35)"},

	{"자리": "COLLIDE.걸침", "파일": "res://tools/tests/measure_collide.gd", "상수": "MAX_OVER",
	 "꼴": "cap", "잰값": 1.990, "폭": 0.0, "고장": 8.0,
	 "왜": "고장 = 네모 반폭 8px — 몸이 반 칸 바다에 잠긴 그림"},

	{"자리": "CAMERA.편차", "파일": "res://tools/tests/measure_camera.gd", "상수": "TOL_CENTER",
	 "꼴": "cap", "잰값": 0.0, "폭": 0.0, "고장": 16.0,
	 "왜": "고장 = 한 칸 16px. 카메라가 한 칸 밀리면 화면이 월드에서 미끄러진다"},

	{"자리": "DAY.하늘빛", "파일": "res://tools/tests/measure_day.gd", "상수": "TOL",
	 "꼴": "cap", "잰값": 0.0, "폭": 0.0, "고장": 0.82,
	 "왜": "고장 = 1.0 − 밤 밝기 0.18. main.gd 가 Sky 를 안 물들이면 한밤에 이만큼 틀린다"},

	{"자리": "REGROW.시계", "파일": "res://tools/tests/measure_regrow.gd", "상수": "CLOCK_EPS",
	 "꼴": "cap", "잰값": 0.0, "폭": 0.0, "고장": 0.0337,
	 "왜": "고장 = 회차 34 실측. world.tick(delta*0.9) — 하루가 20분 대신 22분이 된다"},

	{"자리": "FACE.커서각", "파일": "res://tools/tests/measure_facing.gd", "상수": "AIM_TOL_DEG",
	 "꼴": "cap", "잰값": 0.000009, "폭": 0.000009, "고장": 45.0,
	 "왜": "고장 = 구간 사이 가장 좁은 각 45°. 캔버스 변환을 안 타면 수십 도가 어긋난다"},

	{"자리": "VIEW.창자리", "파일": "res://tools/tests/measure_window.gd", "상수": "POS_TOL",
	 "꼴": "cap", "잰값": 0.0, "폭": 0.0, "고장": 33.0,
	 "왜": "고장 = 회차 33 대조군 ⑤ 실측 (창 y 340 → 307)"},

	{"자리": "DRAW.색차", "파일": "res://tools/tests/measure_window.gd", "상수": "TOL",
	 "꼴": "cap", "잰값": 0.003382, "폭": 0.0, "고장": COAST_STEP,
	 "왜": "고장 = 해안의 물↔땅 색차. 화면이 한 칸 미끄러지면 이만큼 튄다"},

	{"자리": "USE.벌어짐", "파일": "res://tools/tests/measure_window.gd", "상수": "USE_MIN_SPAN",
	 "꼴": "floor", "잰값": 19.980, "폭": 0.536, "고장": 0.5,
	 "왜": "고장 = USE_SAME 0.5px — 붙박이 네모는 이보다 덜 움직여 자리 하나로 센다"},

	{"자리": "USE.자리수", "파일": "res://tools/tests/measure_window.gd", "상수": "USE_MIN_SPOTS",
	 "꼴": "floor", "잰값": 17.0, "폭": 1.0, "고장": 1.0,
	 "왜": "고장 = 자리 1개. 네모가 한 자리에 붙박이면 모션이 아니다"},
]

## 허용치는 **게이트 파일의 상수**에서 읽는다. 여기 옮겨 적지 않는다.
func _tol(r: Dictionary) -> float:
	var scr: Script = load(r["파일"])
	if scr == null:
		failures.append("%s — 게이트 파일을 못 읽는다: %s" % [r["자리"], r["파일"]])
		return NAN
	var m: Dictionary = scr.get_script_constant_map()
	if not m.has(r["상수"]):
		failures.append("%s — %s 에 상수 %s 가 없다 (이름이 바뀌었으면 표도 고쳐라)" % [
			r["자리"], r["파일"].get_file(), r["상수"]])
		return NAN
	return float(m[r["상수"]])

## ① **허용치가 잰 잡음 위에 있나.** 아래에 있으면 언제든 터지는 게이트다 —
##    회차 34·35 가 그렇게 각각 한 회차씩 잡아먹었다.
func test_허용치는_잰_잡음_위에_있다() -> void:
	for r in ROWS:
		var tol := _tol(r)
		if is_nan(tol):
			continue
		var need: float = r["잰값"] + r["폭"] if r["꼴"] != "floor" else r["잰값"] - r["폭"]
		if r["꼴"] == "floor":
			check(tol <= need, "%s — 허용치 %.6f 가 잰 값에 너무 붙었다 · 최소 %.6f − 폭 %.6f = %.6f 이하라야 한다 (jitter.sh 9)" % [
				r["자리"], tol, r["잰값"], r["폭"], need])
		else:
			check(tol >= need, "%s — 허용치 %.6f 가 잡음보다 좁다 · 최대 %.6f + 폭 %.6f = %.6f 이상이라야 한다 (jitter.sh 9)" % [
				r["자리"], tol, r["잰값"], r["폭"], need])

## ② **허용치와 고장 사이에 3배 여유가 있나.** 없으면 잡음을 덮는 김에 고장도 덮은
##    것이라 그 게이트는 아무것도 안 잡는다. 허용치를 키울 때 반드시 같이 봐야 하는 쪽이다.
func test_허용치와_고장_사이에_세_배_여유가_있다() -> void:
	for r in ROWS:
		var tol := _tol(r)
		if is_nan(tol) or tol == 0.0:
			continue
		var margin: float = (tol / r["고장"]) if r["꼴"] == "floor" else (r["고장"] / tol)
		check(margin >= MIN_MARGIN, "%s — 여유 %.2f배 · %.1f배 이상이라야 한다 (허용치 %.6f · 고장 %.6f — %s)" % [
			r["자리"], margin, MIN_MARGIN, tol, r["고장"], r["왜"]])

## ③ **표가 게이트를 다 덮나.** 게이트에 허용치를 새로 만들면서 표에 안 적으면
##    회차 39 가 한 일이 통째로 새는 자리다 — 「덮이지 않은 허용치」를 여기서 센다.
func test_표가_실측_게이트의_허용치를_다_덮는다() -> void:
	var covered := {}
	for r in ROWS:
		covered["%s::%s" % [r["파일"], r["상수"]]] = true
	# 게이트 파일에서 `Tol.obs(..., TOL이름)` 로 흘리는 상수만 센다.
	# 흘리지 않는 상수는 폭을 잴 길이 없으니 표에 넣을 수도 없다.
	for path in ["res://tools/tests/measure_move.gd", "res://tools/tests/measure_collide.gd",
			"res://tools/tests/measure_camera.gd", "res://tools/tests/measure_day.gd",
			"res://tools/tests/measure_regrow.gd", "res://tools/tests/measure_facing.gd",
			"res://tools/tests/measure_window.gd"]:
		var f := FileAccess.open(path, FileAccess.READ)
		check(f != null, "게이트 파일을 못 연다: %s" % path)
		if f == null:
			continue
		var src := f.get_as_text()
		var n := 0
		for line in src.split("\n"):
			if not line.strip_edges().begins_with("Tol.obs("):
				continue
			n += 1
			# 마지막 인자가 허용치 상수 이름이다.
			# 마지막 인자에서 `float(` 과 `)` 를 벗기면 허용치 상수 이름만 남는다.
			var arg := line.substr(line.rfind(",") + 1).replace("float(", "").replace(")", "").strip_edges()
			check(arg.is_valid_identifier(),
				"%s — Tol.obs 의 허용치 자리가 상수 이름이 아니다: %s" % [path.get_file(), arg])
			if not arg.is_valid_identifier():
				continue
			check(covered.has("%s::%s" % [path, arg]),
				"%s 의 %s 가 표에 없다 — jitter.sh 로 폭을 재고 ROWS 에 한 줄 적어라" % [path.get_file(), arg])
		check(n > 0, "%s 가 Tol.obs 를 하나도 안 부른다 — 폭을 잴 길이 없다" % path.get_file())
