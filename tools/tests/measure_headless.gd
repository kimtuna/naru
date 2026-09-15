extends SceneTree

## **실측 게이트 — 창이 필요 없는 구간을 한 프로세스에서.** MOVE · WORLD · COLLIDE ·
## CAMERA · CHOP · REGROW 를 차례로 잰다 (회차 27 에 넷, 29 에 벌목, 30 에 다시 자라기).
##
## **왜 합쳤나**: 넷 다 창이 필요 없는데 따로 돌리면 `check.sh tests` 가 Godot 을
## 여덟 번 띄운다 — 부팅이 재는 시간보다 길다. 회차 14 가 창 띄우는 둘(VIEW·DRAW)을
## `measure_window.gd` 로 합친 것과 같은 방법이다.
##
## **회차 14 가 그때 배운 것을 같이 지킨다 — 합치면 「반쪽만 돌고 죽어도 초록」이 열린다.**
## 앞 구간이 조용히 죽으면 뒤 구간은 아예 안 돌고 프로세스는 exit 0 으로 끝난다.
## 그래서 끝에 **`HEADGATE` 줄**을 찍는다: 어느 구간이 몇 개를 잡았는지와 **몇 구간을
## 돌았는지(6/6)**를 같이 적는다. `check.sh` 는 구간 줄 여섯과 이 줄을 **전부** 본다 —
## 하나라도 없으면 빨갛다.
##
## **`FACE` 는 여기 없다.** `measure_facing.gd` 는 제 `SubViewport` 를 세우고
## `root.gui_disable_input` 을 끄는 유일한 게이트고, 흔들림으로 회차 8·9·10·11 을
## 잡아먹은 자리다 — 섞으면 빨강이 어느 구간 탓인지 흐려진다. 따로 돈다.
##
## 구간 고르기: `--script res://tools/tests/measure_headless.gd -- world`
## (`check.sh` 가 WORLD 를 **다른 프로세스에서 한 번 더** 재려고 쓴다 — 두 프로세스가
## 같은 월드를 주는지가 그 게이트의 전부라서 한 프로세스로는 못 합친다.)
##
## 이름이 test_ 로 시작하지 않는다 — run_tests.gd 는 이 파일을 안 집는다.

## **순서가 곧 격리 비용이다.** 노드를 안 세우는 WORLD 가 가장 싸고, MOVE 는
## 플레이어 씬만, COLLIDE·CAMERA 는 메인 씬을 통째로 세운다. MOVE 를 맨 앞에 두는 것은
## 홀로 돌던 때와 같은 자리에서 재기 위해서다 — 유휴 프레임의 delta 로 px/s 를 재므로
## 앞에 무엇이 도느냐가 값에 섞일 여지를 남기지 않는다.
##
## **월드를 바꾸는 구간이 맨 뒤다** (회차 29·30): CHOP 은 나무를 베고 바닥에 목재를
## 떨구고, REGROW 는 시계를 하루 넘게 감는다. 앞에 두면 뒤 구간이 「나무가 있는 칸」을
## 고를 때 이미 벤 자리를 집을 수 있다. 씬은 구간마다 새로 세우므로 실제로 새지는
## 않지만, **순서로 못을 박는다.** 둘 중에서는 **베는 것이 먼저다** — 자라는 것은
## 벤 것의 뒷이야기라 읽는 순서가 곧 규칙의 순서다.
const ORDER := ["move", "world", "collide", "camera", "chop", "regrow"]
const PHASE_PATH := {
	"move": "res://tools/tests/measure_move.gd",
	"world": "res://tools/tests/measure_world.gd",
	"collide": "res://tools/tests/measure_collide.gd",
	"camera": "res://tools/tests/measure_camera.gd",
	"chop": "res://tools/tests/measure_chop.gd",
	"regrow": "res://tools/tests/measure_regrow.gd",
}

## 구간 사이에 비우는 프레임. `queue_free` 는 프레임 끝에 돈다 — 앞 구간의 씬이
## 아직 트리에 있는 채로 다음 구간이 서면 카메라가 둘이 된다.
const GAP := 2

var _want: Array = []
var _i := -1
var _cur: MeasurePhase = null
var _gap := 0
var _done: PackedStringArray = []   # 돈 구간의 "MOVE 0" 같은 기록
var _bad := 0
var _abort := ""

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	for key in ORDER:
		if args.is_empty() or args.has(key):
			_want.append(key)
	if _want.is_empty():
		_abort = "고른 구간이 없다 — 잰 값 %s · 기대 %s 중 하나" % [str(args), str(ORDER)]

func _process(delta: float) -> bool:
	if _abort != "":
		print("HEADGATE FAIL %s" % _abort)
		quit(1)
		return true
	if _cur != null:
		if not _cur.step(delta):
			return false
		_end_phase()
		return false
	if _gap > 0:
		_gap -= 1
		return false
	_i += 1
	if _i >= _want.size():
		return _report()
	var scr: Script = load(PHASE_PATH[_want[_i]])
	_cur = scr.new()
	_cur.begin(self)
	return false

func _end_phase() -> void:
	_bad += _cur.bad
	_done.append("%s %d" % [_cur.tag(), _cur.bad])
	_cur.cleanup()
	_cur = null
	_gap = GAP

## **이 줄 하나가 「반쪽만 돌고 죽어도 초록」을 막는다.** 구간이 죽으면 여기까지
## 못 오므로 줄이 아예 안 나오고, 구간을 조용히 뺐으면 `구간 6/6` 이 `5/5` 로 바뀐다.
## **세는 값을 `check.sh` 와 나눠 가진다**: 여기는 「몇 구간을 돌았나」만 찍고,
## 「여섯이어야 한다」는 `check.sh` 가 안다 — 한 파일만 고쳐서는 초록이 안 된다.
func _report() -> bool:
	print("HEADGATE %s (%s · 구간 %d/%d · 프로세스 한 번)" % [
		"ok" if _bad == 0 else "FAIL %d개" % _bad,
		" · ".join(_done), _done.size(), _want.size()])
	quit(1 if _bad > 0 else 0)
	return true
