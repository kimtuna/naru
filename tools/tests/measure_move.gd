extends MeasurePhase

## **실측 게이트.** 실제 씬을 물리로 돌려 초당 몇 px 움직이는지 잰다.
##
## 왜 단위 검사로 부족한가: PlayerMotion 이 아무리 맞아도 노드가 그걸 안 쓰면
## 게임은 안 움직인다. 여기가 그 구멍을 막는다 — 입력을 실제로 눌러서 위치를 잰다.
##
## **홀로 도는 프로세스가 아니다** (회차 27): `measure_headless.gd` 가 헤드리스 구간
## 넷 중 첫째로 돌린다. `_initialize`/`_process` 가 `begin`/`step` 이 된 것이 전부고,
## 재는 것과 기대값은 그대로다.
##
## **맨 앞에서 돈다**: 유휴 프레임의 delta 로 px/s 를 재므로 앞에 무엇이 돌았느냐가
## 값에 섞일 여지를 안 남긴다.
##
## 이름이 test_ 로 시작하지 않는다 — run_tests.gd 는 이 파일을 안 집는다.

const DURATION := 1.0            # 한 구간을 몇 초 돌리나
const EXPECT := 240.0            # NUMBERS 1절
const TOL := 5.0                 # 물리 틱 경계 때문에 ±1틱(4px) 이 남는다

var _player: CharacterBody2D
var _phases := [
	{"name": "가로", "keys": ["move_right"]},
	{"name": "대각", "keys": ["move_right", "move_down"]},
]
var _i := 0
var _t := 0.0
var _from := Vector2.ZERO

func tag() -> String:
	return "MOVE"

func begin(t: SceneTree) -> void:
	super(t)
	_player = load("res://scenes/player.tscn").instantiate()
	tree.root.add_child(_player)
	_start_phase()

func cleanup() -> void:
	super()
	drop(_player)
	_player = null

func _start_phase() -> void:
	_t = 0.0
	_player.position = Vector2.ZERO
	_player.velocity = Vector2.ZERO
	_from = _player.position
	for k in _phases[_i]["keys"]:
		Input.action_press(k)

func step(delta: float) -> bool:
	_t += delta
	if _t < DURATION:
		return false
	for k in _phases[_i]["keys"]:
		Input.action_release(k)
	var moved := _player.position - _from
	var per_sec := moved.length() / _t
	var ok := absf(per_sec - EXPECT) <= TOL
	Tol.obs("MOVE.%s" % _phases[_i]["name"], "band", absf(per_sec - EXPECT), TOL)
	if not ok:
		bad += 1
	print("MOVE %s  %.2f px/s · %.3f 칸/s  (%.2f px in %.4f s, 방향 %s)  %s" % [
		_phases[_i]["name"], per_sec, per_sec / PlayerMotion.TILE, moved.length(), _t,
		moved.normalized(), "ok" if ok else "FAIL 기대 %.0f ±%.0f px/s" % [EXPECT, TOL]])
	_i += 1
	if _i < _phases.size():
		_start_phase()
		return false
	print("MOVE %s (구간 %d · 기대 %.0f px/s ±%.0f · 물리 %d Hz)" % [
		"ok" if bad == 0 else "FAIL %d개" % bad, _phases.size(), EXPECT, TOL,
		Engine.physics_ticks_per_second])
	return true
