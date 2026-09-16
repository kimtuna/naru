class_name SwingTarget
extends RefCounted
## 휘두르기에 맞을 수 있는 것 하나 — 자원 칸, 나중에는 몹 (G-009).
## 대상을 가진 쪽(Harvester · 몹 목록)이 만들어 Swinger 에 넘기고, 고르는 규칙은 SwingAim 하나다.

## 대상 한가운데 (월드 좌표).
var position: Vector2
## 대상의 반지름 (픽셀) — 휘두른 선이 이만큼 안을 지나면 선 위에 있다고 본다.
var radius: float
## 맞았을 때 부른다: func(item: Variant) -> bool. item 은 손에 든 것(빈손이면 null). 무언가 일어났으면 true.
var on_hit: Callable
## 무엇인지 — 자원이면 칸(Vector2i), 몹이면 노드.
var what: Variant


static func create(pos: Vector2, r: float, hit: Callable, thing: Variant) -> SwingTarget:
	var t := SwingTarget.new()
	t.position = pos
	t.radius = r
	t.on_hit = hit
	t.what = thing
	return t


func hit(item: Variant) -> bool:
	return on_hit.is_valid() and bool(on_hit.call(item))
