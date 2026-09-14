extends SceneTree

## **실측 게이트 — 화면.** 실제 창을 띄워 논리 화면·창 크기·배율·보이는 칸을 잰다.
##
## 왜 단위 검사로 부족한가: `test_project_settings.gd` 는 project.godot 의 **글자**를 읽는다.
## 값이 맞아도 실행 중에 카메라가 줌을 걸거나 코드가 content_scale_factor 를 만지면
## 눈에 보이는 칸 수는 달라진다 — 그런데 단위 검사 18개는 전부 초록으로 남는다.
## (바퀴 3 에서 이동 속도로 똑같은 구멍을 확인했다. NUMBERS 5절)
##
## **헤드리스로 돌리면 안 된다** — headless 드라이버는 창 크기가 (0,0) 이라 배율을 못 잰다.
## check.sh tests 가 `--headless` 없이 부른다.
##
## 이름이 test_ 로 시작하지 않는다 — run_tests.gd 는 이 파일을 안 집는다.

const LOGICAL := Vector2(960.0, 540.0)     # NUMBERS 1절
const WINDOW := Vector2(1920.0, 1080.0)
const SCALE := 2.0
const TILES := Vector2(20.0, 11.25)        # 960/48 · 540/48
const WARMUP := 5                          # 창 크기가 붙을 때까지 기다리는 프레임

var _frames := 0
var _bad := 0

func _initialize() -> void:
	var main: String = ProjectSettings.get_setting("application/run/main_scene")
	root.add_child(load(main).instantiate())

func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < WARMUP:
		return false
	_measure()
	quit(1 if _bad > 0 else 0)
	return true

func _measure() -> void:
	var driver := DisplayServer.get_name()
	if driver == "headless":
		_fail("드라이버", "headless 로는 창을 못 잰다 — --headless 없이 불러라", "macOS/X11")
		_report(driver)
		return

	var vis := root.get_visible_rect().size
	var win := Vector2(DisplayServer.window_get_size())
	_v2("논리 화면", vis, LOGICAL)
	_v2("창", win, WINDOW)

	# 배율은 나눗셈이 아니라 **엔진이 실제로 거는 변환**에서 잰다.
	# content_scale_factor 를 만지면 여기서 잡힌다.
	var fs := root.get_final_transform().get_scale()
	_v2("최종 변환 배율", fs, Vector2(SCALE, SCALE))
	_num("정수 배율", fs.x, roundf(fs.x))       # 소수 배율이면 도트가 뭉갠다

	# 보이는 칸은 **월드 좌표**로 잰다 — 카메라 줌이 걸리면 여기서만 달라진다.
	var cz := root.get_canvas_transform().get_scale()
	var world := Vector2(vis.x / cz.x, vis.y / cz.y)
	var tiles := world / PlayerMotion.TILE
	_v2("보이는 칸", tiles, TILES)

	print("VIEW 논리 %.0fx%.0f · 창 %.0fx%.0f · 배율 %.2fx · 카메라 %.2fx · 타일 %dpx · 보이는 칸 %.2f x %.2f" % [
		vis.x, vis.y, win.x, win.y, fs.x, cz.x, int(PlayerMotion.TILE), tiles.x, tiles.y])
	_report(driver)

func _report(driver: String) -> void:
	print("VIEW %s (드라이버 %s · 프레임 %d)" % [
		"ok" if _bad == 0 else "FAIL %d개" % _bad, driver, _frames])

func _fail(what: String, actual: String, expected: String) -> void:
	_bad += 1
	print("VIEW FAIL %s — 잰 값 %s · 기대 %s" % [what, actual, expected])

func _num(what: String, actual: float, expected: float) -> void:
	if not is_equal_approx(actual, expected):
		_fail(what, "%.4f" % actual, "%.4f" % expected)

func _v2(what: String, actual: Vector2, expected: Vector2) -> void:
	if not (is_equal_approx(actual.x, expected.x) and is_equal_approx(actual.y, expected.y)):
		_fail(what, "%.2f x %.2f" % [actual.x, actual.y], "%.2f x %.2f" % [expected.x, expected.y])
