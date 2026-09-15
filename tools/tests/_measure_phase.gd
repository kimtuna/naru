class_name MeasurePhase
extends RefCounted

## **실측 게이트 한 구간의 바닥.** 헤드리스 구간을 한 프로세스에서 이어 재기 위한 것이다
## (회차 27). `measure_headless.gd` 가 이 구간들을 차례로 돌린다.
##
## **왜 `extends SceneTree` 를 버렸나**: 구간마다 엔진을 한 번씩 띄우면 `check.sh tests` 가
## Godot 을 여덟 번 부른다 — 부팅이 재는 시간보다 길다. 회차 14 가 창 띄우는 둘을
## 합친 것과 같은 방법이다.
##
## **합치면 「반쪽만 돌고 죽어도 초록」이 열린다** (회차 14 가 `WINGATE` 로 막은 것과 같은
## 구멍이다): 앞 구간이 조용히 죽으면 뒤 구간은 아예 안 돌고, 프로세스는 exit 0 으로
## 끝난다. 그래서 `measure_headless.gd` 가 **「넷 다 돌았다」를 찍는 줄**을 내고
## `check.sh` 가 구간 줄 넷 + 그 줄을 **전부** 본다.
##
## 한 구간이 지켜야 하는 것:
##   `tag()`      찍는 줄의 머리말. `check.sh` 가 이 글자로 grep 한다
##   `begin(t)`   노드를 세운다. **`step` 은 다음 프레임부터 불린다** —
##                홀로 돌던 때의 `_initialize` 와 같은 자리다
##   `step(d)`    한 유휴 프레임. 끝났으면 true. 끝내기 전에 **제 요약 줄을 찍는다**
##   `cleanup()`  세운 것을 걷는다. **다음 구간이 앞 구간의 노드를 보면 안 된다**
##   `bad`        잡은 어긋남의 수. 드라이버가 더해서 종료 코드를 낸다

## 눌렸을 수 있는 이동 키. 구간이 제 뒷정리를 빠뜨려도 다음 구간이 눌린 키를 물려받지
## 않게 한다 — 그러면 「가만히 서서 240 px/s」 같은 값이 나온다.
const MOVE_KEYS := ["move_right", "move_left", "move_up", "move_down"]

var bad := 0
var tree: SceneTree

func tag() -> String:
	return "PHASE"

func begin(t: SceneTree) -> void:
	tree = t

func step(_delta: float) -> bool:
	return true

func cleanup() -> void:
	for k in MOVE_KEYS:
		Input.action_release(k)

func fail(what: String, actual: String, expected: String) -> void:
	bad += 1
	print("%s FAIL %s — 잰 값 %s · 기대 %s" % [tag(), what, actual, expected])

## 구간이 세운 노드를 트리에서 **즉시** 떼고 지운다. `queue_free` 만 하면 그 프레임
## 끝까지 `_process` 가 계속 돌아서, 다음 구간이 서는 동안 앞 구간의 씬이 같이 움직인다.
func drop(n: Node) -> void:
	if n == null:
		return
	if n.get_parent() != null:
		n.get_parent().remove_child(n)
	n.queue_free()
