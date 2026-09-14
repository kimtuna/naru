extends SceneTree

## **실측 게이트 — 바라보는 방향.** 실제 창에 **진짜 커서를 옮겨** 넣고
## 플레이어가 어디를 보는지, 코 네모가 어디로 갔는지 잰다.
##
## 왜 단위 검사로 부족한가: PlayerFacing 이 아무리 맞아도 노드가 커서를 안 읽으면
## 게임은 앞만 본다 — 그런데 단위 검사는 전부 초록으로 남는다.
## (바퀴 3 의 속도, 바퀴 4 의 화면과 같은 모양의 구멍이다. NUMBERS 5절)
##
## **헤드리스로 돌리면 안 된다** — headless 드라이버는 창이 없어 커서를 못 옮긴다.
## check.sh tests 가 `--headless` 없이 부른다.
##
## **사람의 커서를 잠깐 뺏는다.** 끝나면 처음 자리로 되돌린다.
##
## 이름이 test_ 로 시작하지 않는다 — run_tests.gd 는 이 파일을 안 집는다.

const DIST := 200.0          # 겨눔 거리. 데드존(8px) 한참 밖이면 거리는 결과를 안 바꾼다
const SETTLE := 4            # warp 가 창에 붙고 물리가 한 번 도는 데 드는 프레임
const WARMUP := 5

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

var _player: Node
var _scale := 1.0
var _home := Vector2.ZERO
var _i := 0
var _frames := 0
var _wait := 0
var _bad := 0

func _initialize() -> void:
	var main: String = ProjectSettings.get_setting("application/run/main_scene")
	root.add_child(load(main).instantiate())

func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < WARMUP:
		return false
	if _frames == WARMUP:
		return _setup()
	if _wait > 0:
		_wait -= 1
		return false
	_check_phase()
	_i += 1
	if _i < _phases.size():
		_aim(_phases[_i]["deg"])
		return false
	return _finish()

func _setup() -> bool:
	if DisplayServer.get_name() == "headless":
		_fail("드라이버", "headless 로는 커서를 못 옮긴다 — --headless 없이 불러라", "macOS/X11")
		return _finish()
	_player = root.get_node_or_null("Main/Player")
	if _player == null:
		_fail("플레이어", "Main/Player 가 없다", "메인 씬에 플레이어")
		return _finish()
	# 창 좌표 = 화면 좌표 × 최종 배율. warp_mouse 는 창 좌표를 받는다.
	_scale = root.get_final_transform().get_scale().x
	_home = root.get_mouse_position() * _scale
	_aim(_phases[0]["deg"])
	return false

## 플레이어 중심에서 deg 방향 DIST px 떨어진 **월드** 점으로 진짜 커서를 옮긴다.
## **카메라가 생겨서(P1-6) 월드 좌표 ≠ 창 좌표다** — 캔버스 변환으로 화면에 찍고,
## 화면을 창 배율로 늘린다. 플레이어는 화면 한가운데라 DIST 200 은 창 안에 떨어진다.
func _aim(deg: float) -> void:
	var target: Vector2 = _player.global_position + Vector2.RIGHT.rotated(deg_to_rad(deg)) * DIST
	var screen: Vector2 = root.get_canvas_transform() * target
	Input.warp_mouse(screen * _scale)
	_wait = SETTLE

func _check_phase() -> void:
	var p: Dictionary = _phases[_i]
	var got: Vector2 = _player.facing
	var want: Vector2 = p["expect"]
	# 커서가 정말 그 자리에 갔나 — 아니면 밑의 판정은 의미가 없다.
	var aim: Vector2 = _player.get_global_mouse_position() - _player.global_position
	var aim_deg: float = rad_to_deg(Vector2.RIGHT.angle_to(aim))
	if absf(angle_difference(deg_to_rad(p["deg"]), deg_to_rad(aim_deg))) > deg_to_rad(1.0):
		_fail("커서 각 %s" % p["name"], "%.2f°" % aim_deg, "%.2f°" % p["deg"])
	# 코 네모가 방향을 따라갔나 — facing 만 맞고 그림이 안 돌면 사람 눈엔 안 보인다.
	var nose: Node = _player.get_node_or_null("Nose")
	var nose_c: Vector2 = nose.position + nose.size * 0.5 if nose != null else Vector2.INF
	var nose_want: Vector2 = want * _player.NOSE_DIST
	var ok := got == want and nose_c.is_equal_approx(nose_want)
	if not ok:
		_bad += 1
	print("FACE %-16s 커서 %6.1f° · 방향 %s · 코 %s  %s" % [
		p["name"], aim_deg, got, nose_c,
		"ok" if ok else "FAIL 기대 방향 %s · 코 %s" % [want, nose_want]])

func _finish() -> bool:
	if _player != null:
		Input.warp_mouse(_home)
	print("FACE %s (구간 %d · 거리 %.0f px · 스냅 %.0f° · 히스테리시스 %.0f°)" % [
		"ok" if _bad == 0 else "FAIL %d개" % _bad, _phases.size(),
		DIST, PlayerFacing.SNAP_DEG, PlayerFacing.HYSTERESIS_DEG])
	quit(1 if _bad > 0 else 0)
	return true

func _fail(what: String, actual: String, expected: String) -> void:
	_bad += 1
	print("FACE FAIL %s — 잰 값 %s · 기대 %s" % [what, actual, expected])
