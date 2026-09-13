extends SceneTree

## **실측 게이트.** 실제 씬을 물리로 돌려 초당 몇 px 움직이는지 잰다.
##
## 왜 단위 검사로 부족한가: PlayerMotion 이 아무리 맞아도 노드가 그걸 안 쓰면
## 게임은 안 움직인다. 여기가 그 구멍을 막는다 — 입력을 실제로 눌러서 위치를 잰다.
##
## 이름이 test_ 로 시작하지 않는다 — run_tests.gd 는 이 파일을 안 집는다.
## check.sh tests 가 따로 부른다.

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
var _bad := 0

func _initialize() -> void:
	_player = load("res://scenes/player.tscn").instantiate()
	root.add_child(_player)
	_start_phase()

func _start_phase() -> void:
	_t = 0.0
	_player.position = Vector2.ZERO
	_player.velocity = Vector2.ZERO
	_from = _player.position
	for k in _phases[_i]["keys"]:
		Input.action_press(k)

func _process(delta: float) -> bool:
	_t += delta
	if _t < DURATION:
		return false
	for k in _phases[_i]["keys"]:
		Input.action_release(k)
	var moved := _player.position - _from
	var per_sec := moved.length() / _t
	var ok := absf(per_sec - EXPECT) <= TOL
	if not ok:
		_bad += 1
	print("MOVE %s  %.2f px/s · %.3f 칸/s  (%.2f px in %.4f s, 방향 %s)  %s" % [
		_phases[_i]["name"], per_sec, per_sec / 48.0, moved.length(), _t,
		moved.normalized(), "ok" if ok else "FAIL 기대 %.0f ±%.0f px/s" % [EXPECT, TOL]])
	_i += 1
	if _i < _phases.size():
		_start_phase()
		return false
	print("MOVE %s (구간 %d · 기대 %.0f px/s ±%.0f · 물리 %d Hz)" % [
		"ok" if _bad == 0 else "FAIL %d개" % _bad, _phases.size(), EXPECT, TOL,
		Engine.physics_ticks_per_second])
	quit(1 if _bad > 0 else 0)
	return true
