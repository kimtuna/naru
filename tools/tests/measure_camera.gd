extends SceneTree

## **실측 게이트 — 카메라.** 메인 씬을 통째로 돌려 **네 방향으로 걸어 다니면서**
## 매 프레임 「플레이어가 화면 한가운데에 있나 · 보이는 월드가 안 늘었나」를 잰다.
##
## 왜 단위 검사로 부족한가: 씬에 `zoom = Vector2(1, 1)` 이 박혀 있어도
## **실행 중에 코드가 줌을 만지거나 카메라를 꺼 버리면** 단위 검사는 전부 초록으로 남는다.
## (회차 3 속도 · 4 화면 · 5 방향 · 6 월드 · 7 충돌과 **같은 모양의 구멍**이다. NUMBERS 5절)
##
## **안 움직이면 「늘 한가운데」는 공짜다** — 그래서 걸은 거리도 같이 잰다.
## 카메라가 아예 없어도 플레이어가 화면 밖으로 나가는 데는 시간이 걸리므로,
## 판정은 「화면 안에 있나」가 아니라 **「중심에서 몇 px 벗어났나」**다.
##
## 헤드리스로 된다 — 캔버스 변환은 창 없이도 돈다. 창·배율은 measure_window.gd 가 잰다.
##
## 이름이 test_ 로 시작하지 않는다 — run_tests.gd 는 이 파일을 안 집는다.

const LOGICAL := Vector2(960.0, 540.0)     # NUMBERS 1절
const TILES := Vector2(60.0, 33.75)        # 960/16 · 540/16 — 줌이 1 일 때만 이 값이다
const SEC := 0.5                           # 한 방향으로 걷는 시간. 240px/s → 120px = 7.5칸
const TOL_CENTER := 0.5                    # px. 카메라는 계산이라 틱 경계가 안 섞인다
const MIN_PATH := 200.0                    # 전 구간 합. 안 걸으면 판정이 공허하다
const WARMUP := 3                          # 씬의 _ready(월드 배선)는 첫 프레임 뒤에 돈다

## 스폰(섬 한가운데)에서 네 방향. 한둘이 해안에 막혀도 걸은 거리는 남는다.
var _dirs := [["move_right"], ["move_down"], ["move_left"], ["move_up"]]

var _main: Node
var _player: Node2D
var _i := 0
var _t := 0.0
var _last := Vector2.ZERO
var _path := 0.0
var _max_dev := 0.0
var _said_center := false
var _said_zoom := false
var _bad := 0
var _frames := 0
var _samples := 0

func _initialize() -> void:
	var scene: String = ProjectSettings.get_setting("application/run/main_scene")
	_main = load(scene).instantiate()
	root.add_child(_main)

func _process(delta: float) -> bool:
	_frames += 1
	if _frames < WARMUP:
		return false
	if _frames == WARMUP:
		return _setup()
	_sample()
	_t += delta
	if _t < SEC:
		return false
	for k in _dirs[_i]:
		Input.action_release(k)
	_i += 1
	_t = 0.0
	if _i < _dirs.size():
		for k in _dirs[_i]:
			Input.action_press(k)
		return false
	return _finish()

## 배선은 씬의 _ready 가 한다 — **_initialize 에서 보면 아직 비어 있다.**
func _setup() -> bool:
	_player = _main.get_node_or_null("Player") as Node2D
	if _player == null:
		_fail("플레이어", "Main/Player 가 없다", "메인 씬에 플레이어")
		return _finish()
	_last = _player.global_position
	# 걷기 전에 한 번. 「카메라가 원점을 비춘다」는 여기서 이미 잡힌다 —
	# 스폰은 월드 한가운데(6168, 6168)라 화면 밖으로 128칸 떨어져 있다.
	_sample()
	print("CAMERA 스폰 월드 %s · 화면 %s · 보이는 월드 %s" % [
		_player.global_position, _screen_of_player(), _main.visible_world_rect()])
	for k in _dirs[_i]:
		Input.action_press(k)
	return false

## 플레이어의 월드 좌표가 화면 어디로 찍히나. **카메라가 하는 일 전부가 이 변환이다.**
func _screen_of_player() -> Vector2:
	return root.get_canvas_transform() * _player.global_position

func _sample() -> void:
	_samples += 1
	var pos := _player.global_position
	_path += pos.distance_to(_last)
	_last = pos

	var dev := _screen_of_player().distance_to(LOGICAL * 0.5)
	if dev > _max_dev:
		_max_dev = dev
	if dev > TOL_CENTER and not _said_center:
		_said_center = true
		_fail("화면 중심에서 벗어났다", "%.2f px (화면 %s)" % [dev, _screen_of_player()],
			"%.2f px 이내 (중심 %s)" % [TOL_CENTER, LOGICAL * 0.5])

	# 줌 = 시야. 씬의 글자가 아니라 **엔진이 실제로 거는 캔버스 변환**에서 잰다.
	var cz := root.get_canvas_transform().get_scale()
	if not (is_equal_approx(cz.x, 1.0) and is_equal_approx(cz.y, 1.0)) and not _said_zoom:
		_said_zoom = true
		var tiles := Vector2(LOGICAL.x / cz.x, LOGICAL.y / cz.y) / PlayerMotion.TILE
		_fail("줌", "%.2f x %.2f (보이는 칸 %.2f x %.2f)" % [cz.x, cz.y, tiles.x, tiles.y],
			"1.00 x 1.00 (보이는 칸 %.2f x %.2f)" % [TILES.x, TILES.y])

func _finish() -> bool:
	for d in _dirs:
		for k in d:
			Input.action_release(k)
	if _path < MIN_PATH:
		_fail("걸은 거리", "%.2f px" % _path,
			"%.0f px 이상 (안 움직이면 「늘 한가운데」는 공짜다)" % MIN_PATH)
	var cz := root.get_canvas_transform().get_scale()
	var tiles := Vector2(LOGICAL.x / cz.x, LOGICAL.y / cz.y) / PlayerMotion.TILE
	print("CAMERA 최대 편차 %.4f px · 걸은 거리 %.2f px · 줌 %.2fx · 보이는 칸 %.2f x %.2f · 표본 %d" % [
		_max_dev, _path, cz.x, tiles.x, tiles.y, _samples])
	print("CAMERA %s (구간 %d × %.1f s · 허용 편차 %.2f px · 물리 %d Hz)" % [
		"ok" if _bad == 0 else "FAIL %d개" % _bad, _dirs.size(), SEC, TOL_CENTER,
		Engine.physics_ticks_per_second])
	quit(1 if _bad > 0 else 0)
	return true

func _fail(what: String, actual: String, expected: String) -> void:
	_bad += 1
	print("CAMERA FAIL %s — 잰 값 %s · 기대 %s" % [what, actual, expected])
