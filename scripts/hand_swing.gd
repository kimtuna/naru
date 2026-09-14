class_name HandSwing
extends RefCounted

## 손을 **한 번 휘두르는 모션**의 순수 계산. 노드도 엔진도 시계도 안 본다 —
## 시간은 `advance(delta)` 로 밖에서 들어온다. 그래서 헤드리스로 잴 수 있다.
##
## **대상이 없어도 모션이 나온다** (BACKLOG P2). 이것이 이 클래스가 있는 이유다:
## 「무엇을 맞혔나」를 모션이 정하면, 맞힐 것이 없는 곳을 치면 **아무 일도 안 일어난다.**
## 좌클릭 하나로 모든 도구를 쓰는 조작(GDD D-2c)에서 그건 치명적이다 — 사람은
## 「안 맞았다」와 「클릭이 안 먹었다」를 구별할 방법이 없고, 그러면 클릭을 믿지 못한다.
## **모션이 먼저 나오고 판정은 그 위에 얹힌다.** 판정(벌목·채광)은 월드 오브젝트가
## 생기는 다음 항목들에서 온다 — 지금 여기에는 **판정이 한 줄도 없다.**
##
## **누르고 있으면 계속 휘두른다** (2026-09-14 결정): 나무 한 그루에 수십 번 클릭하게
## 만들면 손목이 남아나지 않는다 (마인크래프트 · 코어 키퍼도 누르고 있는다).
## 그래서 「눌린 순간」을 따로 잡지 않는다 — **한 모션이 끝나는 순간이 다음 모션의
## 시작**이고, 그 판단은 `start()` 가 혼자 한다.

## 한 번 휘두르는 데 걸리는 시간(초). 60Hz 에서 **14프레임**이다.
## 몇 프레임이면 눈에 안 보이고, 0.5초면 연타가 답답하다 — 초당 4번이다.
const SWING_SEC := 0.24

## 휘두르는 부채꼴(도). 겨눈 쪽을 한가운데 두고 **한쪽에서 다른 쪽으로 쓸고 간다.**
## 왕복하지 않는다: 되돌아오는 동작은 같은 모션을 두 번 보여 주면서 길이만 늘린다.
const ARC_DEG := 90.0

## 손이 닿는 거리 — 몸통 한가운데에서 도구 네모의 **중심**까지. **1.5칸**이다.
## 옆 칸(1칸 = 16px)은 확실히 닿고 두 칸 건너(32px)는 못 닿는다.
## 벌목·채광이 「어느 칸을 쳤나」를 물을 때 이 값이 그 사거리가 된다.
const REACH := PlayerMotion.TILE * 1.5

## 휘두르는 네모의 크기. 반 칸이다 — 몸통(1칸 × 2칸)보다 작아야 손에 쥔 것으로 보인다.
const SIZE := Vector2(PlayerMotion.TILE * 0.5, PlayerMotion.TILE * 0.5)

## 맨손의 색. **플레이어의 코와 같은 색이다** — 빈 칸을 들면 손 자체를 휘두른다.
const BARE := Color(0.99, 0.93, 0.78)

## 모션이 시작된 뒤 흐른 시간. **SWING_SEC 면 안 휘두르는 중이다** —
## 처음부터 그 값이라 「가만히 서 있는 상태」와 「막 끝난 상태」가 같은 하나다.
var elapsed := SWING_SEC

func is_swinging() -> bool:
	return elapsed < SWING_SEC

## 0(시작) .. 1(끝). 안 휘두르는 중이면 1 이다.
func progress() -> float:
	return clampf(elapsed / SWING_SEC, 0.0, 1.0)

## 휘두르기 시작한다. 돌려주는 것은 **이번에 시작했는가**다.
##
## **휘두르는 중이면 안 겹친다.** 매 프레임 새로 시작하면 진행도가 0 에 눌러앉아
## 네모가 한 자리에 붙박이고, 사람 눈에는 모션이 통째로 사라진다.
func start() -> bool:
	if is_swinging():
		return false
	elapsed = 0.0
	return true

func advance(delta: float) -> void:
	if is_swinging():
		elapsed = minf(elapsed + delta, SWING_SEC)

## 몸통 한가운데에서 본 도구 네모의 **중심 자리**. t 는 0..1 의 진행도다.
## 겨눈 방향을 한가운데 두고 -ARC/2 → +ARC/2 로 돈다.
static func offset(facing: Vector2, t: float) -> Vector2:
	return facing.normalized().rotated(deg_to_rad(arc_deg_at(t))) * REACH

## 진행도 t 에서 겨눈 방향과 벌어진 각(도). 시작이 -45 · 끝이 +45 다.
static func arc_deg_at(t: float) -> float:
	return lerpf(-ARC_DEG * 0.5, ARC_DEG * 0.5, clampf(t, 0.0, 1.0))

## **손에 든 것의 색.** 핫바 칸과 휘두르는 네모가 다른 색이면 「손에 든 것의 동작」이
## 아니라 그냥 아무 네모다 — 그래서 색의 출처를 하나로 둔다 (`HotbarView.item_color`).
## 빈 칸은 맨손이다. **맨손도 휘두른다** — 맨손 채집이 있다 (GDD D-2c).
static func color_for(held_id: StringName) -> Color:
	return BARE if held_id == Inventory.EMPTY else HotbarView.item_color(held_id)
