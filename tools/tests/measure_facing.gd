extends SceneTree

## **실측 게이트 — 바라보는 방향.** 메인 씬을 **제 SubViewport 안에** 띄우고
## 합성 마우스 이벤트를 밀어 넣어, 플레이어가 어디를 보는지 · 코 네모가 어디로
## 갔는지 잰다.
##
## 왜 단위 검사로 부족한가: PlayerFacing 이 아무리 맞아도 노드가 커서를 안 읽으면
## 게임은 앞만 본다 — 그런데 단위 검사는 전부 초록으로 남는다.
## (회차 3 의 속도, 회차 4 의 화면과 같은 모양의 구멍이다. NUMBERS 5절)
##
## **사람의 커서를 안 뺏는다** (회차 11). 예전에는 `Input.warp_mouse` 로 진짜 커서를
## 옮겼는데, **루트 뷰포트의 `get_mouse_position()` 은 매번 OS 커서를 되묻는다** —
## 그래서 사람이 마우스를 1px 만 건드려도 게이트가 튀었다 (회차 8·9·10 · 사람 세션,
## 네 번). SubViewport 는 다르다: `get_mouse_position()` 이 **밀어 넣은 이벤트만**
## 보고 OS 커서는 안 본다 — `warp_mouse` 를 해도 안 흔들린다 (NUMBERS 10절 실측).
##
## **구멍은 그대로 막는다**: 플레이어는 여전히 `get_global_mouse_position()` 을
## 거치고, 카메라가 SubViewport 안에 있으니 **캔버스 변환도 그대로 탄다** —
## 스폰 칸(128,128)이라 변환의 평행이동이 6000 px 대다. 그 줄을 빼먹으면 안 맞는다.
##
## 창이 필요 없어져서 **헤드리스로 돈다.** (창을 띄워도 통과한다 — 둘 다 쟀다.)
##
## 이름이 test_ 로 시작하지 않는다 — run_tests.gd 는 이 파일을 안 집는다.

const DIST := 200.0          # 겨눔 거리. 데드존(8px) 한참 밖이면 거리는 결과를 안 바꾼다

## **물리 틱으로 센다 — 유휴 프레임이 아니다.** `facing` 은 `_physics_process` 가 정하는데
## 유휴 프레임은 물리와 속도가 다르다: 부하가 걸리면 유휴 4프레임이 물리 한 틱도
## 못 품는다. 그러면 겨눔은 맞는데(커서 0.0°) 방향만 한 틱 뒤처져 빨개진다 —
## **부하만 준 12회 중 1회** 첫 구간이 그렇게 터졌다 (회차 11 실측).
## 하필 첫 구간인 이유: 밀어 넣기 전 SubViewport 의 커서 기본값이 (0,0) 이라
## 플레이어(화면 한가운데) 기준 왼쪽 위 −151° 다 — 플레이어가 먼저 LEFT 를 잡는다.
const SETTLE_TICKS := 2      # 겨눔이 물리에 붙는 데 드는 물리 틱 (1 + 여유 1)
const WARMUP_TICKS := 3      # 씬이 서고 물리가 돌기 시작하는 데 드는 물리 틱

## 커서를 이 각도들로 차례로 옮긴다. 5·6 번은 히스테리시스다 —
## 46° 는 경계(45°)를 넘었지만 **아직 오른쪽**이어야 하고, 60° 에서 비로소 놓는다.
var _phases := [
	{"name": "오른쪽", "deg": 0.0, "expect": Vector2.RIGHT},
	{"name": "아래", "deg": 90.0, "expect": Vector2.DOWN},
	{"name": "왼쪽", "deg": 180.0, "expect": Vector2.LEFT},
	{"name": "위", "deg": -90.0, "expect": Vector2.UP},
	{"name": "오른쪽(재설정)", "deg": 0.0, "expect": Vector2.RIGHT},
	{"name": "46°-붙잡음", "deg": 46.0, "expect": Vector2.RIGHT},
	{"name": "60°-놓음", "deg": 60.0, "expect": Vector2.DOWN},
]

var _view: SubViewport
var _player: Node
var _i := 0
var _until := 0              # 이 물리 틱이 될 때까지 기다린다
var _ready := false
var _bad := 0

## 메인 씬을 루트가 아니라 **SubViewport 안에** 세운다. 논리 화면과 같은 크기라
## 카메라가 비추는 범위가 게임과 같다.
func _initialize() -> void:
	_view = SubViewport.new()
	_view.size = Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"))
	_view.handle_input_locally = true
	var main: String = ProjectSettings.get_setting("application/run/main_scene")
	_view.add_child(load(main).instantiate())
	root.add_child(_view)
	# **루트의 입력 처리를 끈다 — 방어용이다.** 창을 띄운 채로 돌리면 루트 Window 가
	# 진짜 마우스 이벤트를 받는다. 그게 자식 SubViewport 로 새는 것은 **못 봤다**
	# (커서를 옮겨도 SubViewport 는 안 움직였다 — NUMBERS 10절). 그래도 꺼 두는 건
	# 「재는 씬에 진짜 입력이 닿을 길」을 통째로 없애는 값이 한 줄이라서다.
	# 우리는 `_view.push_input` 으로 직접 밀어 넣으므로 합성 입력은 그대로 간다.
	root.gui_disable_input = true
	_until = WARMUP_TICKS

func _process(_delta: float) -> bool:
	if Engine.get_physics_frames() < _until:
		return false
	if not _ready:
		_ready = true
		return _setup()
	_check_phase()
	_i += 1
	if _i < _phases.size():
		_aim(_phases[_i]["deg"])
		return false
	return _finish()

func _setup() -> bool:
	_player = _view.get_node_or_null("Main/Player")
	if _player == null:
		_fail("플레이어", "Main/Player 가 없다", "메인 씬에 플레이어")
		return _finish()
	_aim(_phases[0]["deg"])
	return false

## 플레이어 중심에서 deg 방향 DIST px 떨어진 **월드** 점을 겨눈다.
## 캔버스 변환으로 SubViewport 좌표에 찍어 **합성 이벤트로 밀어 넣는다** —
## OS 커서는 안 건드린다. 플레이어는 화면 한가운데라 DIST 200 은 뷰포트 안에 떨어진다.
func _aim(deg: float) -> void:
	var target: Vector2 = _player.global_position + Vector2.RIGHT.rotated(deg_to_rad(deg)) * DIST
	var local: Vector2 = _view.get_canvas_transform() * target
	var ev := InputEventMouseMotion.new()
	ev.position = local
	ev.global_position = local
	_view.push_input(ev)
	_until = Engine.get_physics_frames() + SETTLE_TICKS

func _check_phase() -> void:
	var p: Dictionary = _phases[_i]
	var got: Vector2 = _player.facing
	var want: Vector2 = p["expect"]
	# 겨눔이 정말 그 자리에 갔나 — 아니면 밑의 판정은 의미가 없다.
	var aim: Vector2 = _player.get_global_mouse_position() - _player.global_position
	var aim_deg: float = rad_to_deg(Vector2.RIGHT.angle_to(aim))
	if absf(angle_difference(deg_to_rad(p["deg"]), deg_to_rad(aim_deg))) > deg_to_rad(1.0):
		_fail("커서 각 %s" % p["name"], "%.2f°" % aim_deg, "%.2f°" % p["deg"])
	# 코 네모가 방향을 따라갔나 — facing 만 맞고 그림이 안 돌면 사람 눈엔 안 보인다.
	# **몸통 한가운데를 돈다** (회차 16): 원점이 발밑으로 내려가서 몸 중심은 그 위에 있고,
	# 몸통이 정사각형이 아니라 축마다 반지름이 다르다 (옆 16 · 위아래 24).
	# 기대값을 **씬의 네모에서 다시 세운다** — 코가 상수 하나에 매달려 있지 않다.
	var nose: Node = _player.get_node_or_null("Nose")
	var body: Control = _player.get_node_or_null("Body")
	var nose_c: Vector2 = nose.position + nose.size * 0.5 if nose != null else Vector2.INF
	var nose_want := Vector2.INF
	if body != null:
		var half: Vector2 = body.size * 0.5
		nose_want = body.position + half + want * half.dot(want.abs())
	var ok := got == want and nose_c.is_equal_approx(nose_want)
	if not ok:
		_bad += 1
	print("FACE %-16s 커서 %6.1f° · 방향 %s · 코 %s  %s" % [
		p["name"], aim_deg, got, nose_c,
		"ok" if ok else "FAIL 기대 방향 %s · 코 %s" % [want, nose_want]])

func _finish() -> bool:
	print("FACE %s (구간 %d · 거리 %.0f px · 스냅 %.0f° · 히스테리시스 %.0f° · 합성 입력 · 물리 %d틱 대기)" % [
		"ok" if _bad == 0 else "FAIL %d개" % _bad, _phases.size(),
		DIST, PlayerFacing.SNAP_DEG, PlayerFacing.HYSTERESIS_DEG, SETTLE_TICKS])
	quit(1 if _bad > 0 else 0)
	return true

func _fail(what: String, actual: String, expected: String) -> void:
	_bad += 1
	print("FACE FAIL %s — 잰 값 %s · 기대 %s" % [what, actual, expected])
