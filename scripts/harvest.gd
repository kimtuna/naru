class_name Harvest
extends RefCounted

## **손에 든 것으로 월드의 것을 거둔다** — 첫 항목이 벌목이다 (BACKLOG P2).
## 순수 규칙이다: 무엇으로 무엇을 벨 수 있나 · 어느 칸을 치나 · 무엇이 떨어지나.
## 노드도 엔진도 안 본다 — **단위 검사가 게임과 글자 그대로 같은 함수로 묻는다.**
##
## **모션 위에 얹히는 한 겹이다** (HandSwing 머리말): 대상이 없어도 손은 휘둘러진다.
## 그래서 여기가 빨개져도 클릭 자체는 죽지 않는다 — 사람은 「안 맞았다」를 본다.
##
## ── 판정은 **모션이 시작되는 프레임에 한 번** ────────────────────────
## 휘두르는 중간(네모가 대상에 겹치는 순간)에 재지 않는다. 이유는 둘이다:
##   - 0.24초 뒤에 결과가 나오면 사람은 클릭이 씹혔다고 느낀다. 마인크래프트·코어
##     키퍼도 누르는 순간 판정한다
##   - 한 모션이 프레임마다 여러 번 겹칠 수 있어서, 「한 번 휘두르면 한 번 맞는다」를
##     따로 지켜 줘야 한다. 시작에 묶으면 `HandSwing.start()` 가 이미 그걸 한다
##
## ── **치는 칸 = 겨눈 쪽으로 한 칸** ─────────────────────────────────
## 커서가 가리키는 칸을 그대로 쓰지 않는다. 방향은 이미 커서가 정하고(4방향 ·
## `PlayerFacing`), **휘두르는 네모가 실제로 쓸고 가는 자리**가 그 한 칸이다 —
## 화면에 보이는 것과 맞은 것이 어긋나면 사람이 조준을 배울 수가 없다.
## 사거리가 그 한 칸과 맞아떨어진다: `HandSwing.REACH` 24px = 8 + 16 이라
## **옆 칸의 먼 모서리에 딱 닿고 두 칸 건너는 못 닿는다** (`test_harvest.gd` 가 지킨다).

## ── 도구와 산출 ──────────────────────────────────────────────────────
## **아이디는 글자다** — `Inventory` 도 `HotbarView` 도 아이디로만 안다.
## 도구를 진짜로 만드는 것은 P3 다 (BACKLOG 「도구 3종을 실제로 제작한다」).
const AXE := &"axe"
const WOOD := &"wood"

## 무엇으로 베나. **없는 종류는 아직 아무 도구도 안 듣는다** — 돌·광물은 채광이 온다.
## 맨손은 여기 없다: 맨손 채집(GDD D-2c)은 풀·열매의 것이고, 나무는 도끼다.
const TOOL_FOR := {
	WorldObjects.TREE: AXE,
}

## 무엇이 몇 개 떨어지나. **개수는 아직 자리표시자다** — 균형은 제작이 값을 요구할 때
## (P3) 정한다. 3 은 「한 번 휘둘러 한 그루」와 짝이다: 숲 한 칸이 곧 목재 3개다.
const DROP_FOR := {
	WorldObjects.TREE: WOOD,
}
const DROP_AMOUNT := {
	WorldObjects.TREE: 3,
}

## ── 규칙 묻기 ────────────────────────────────────────────────────────

## 이 종류를 베는 도구의 아이디. 아직 없으면 `EMPTY` 다.
static func tool_for(kind: int) -> StringName:
	return TOOL_FOR.get(kind, Inventory.EMPTY)

static func drop_for(kind: int) -> StringName:
	return DROP_FOR.get(kind, Inventory.EMPTY)

static func drop_amount(kind: int) -> int:
	return DROP_AMOUNT.get(kind, 0)

## 지금 든 것으로 이 종류를 벨 수 있나.
## **맨손(EMPTY)은 언제나 false 다** — 빈 손이 「아무 도구나」가 되면 도구가 의미를 잃는다.
static func can_harvest(held_id: StringName, kind: int) -> bool:
	if held_id == Inventory.EMPTY or kind == WorldObjects.NONE:
		return false
	return tool_for(kind) == held_id

## 서 있는 칸에서 겨눈 쪽으로 한 칸. **축에 못을 박는다** — 방향이 대각선으로 들어와도
## (검사가 손으로 넣을 수 있다) 칸은 반드시 상하좌우 하나다.
static func target_tile(pos: Vector2, facing: Vector2) -> Vector2i:
	var d := PlayerFacing.nearest(facing if not facing.is_zero_approx() else Vector2.RIGHT)
	return standing_tile(pos) + Vector2i(roundi(d.x), roundi(d.y))

## 지금 서 있는 칸. `position` 이 발밑(충돌 상자 한가운데)이라 그대로 칸이 된다 (Player 머리말).
static func standing_tile(pos: Vector2) -> Vector2i:
	return Vector2i(WorldCollide.tile_of(pos.x), WorldCollide.tile_of(pos.y))

## ── 한 번 휘두른 것을 월드에 먹인다 ──────────────────────────────────

## 돌려주는 것은 **거둔 종류**다 — NONE 이면 아무 일도 안 일어났다(빈 칸 · 틀린 도구).
## 거뒀으면 그 칸이 비고 **떨어질 것이 그 칸 한가운데 놓인다.**
##
## **가방에 안 넣는다.** 바닥에 떨어뜨리고 걸어가서 줍는 것이 이 게임의 순서다
## (BACKLOG P2 「바닥 드롭 + 걸어가서 줍기」) — 베자마자 가방에 꽂으면
## 「가방이 꽉 찼을 때」가 판정 한가운데로 들어와서, 벌목이 인벤토리 규칙을 떠안는다.
static func hit(world: WorldState, held_id: StringName, pos: Vector2, facing: Vector2) -> int:
	var tile := target_tile(pos, facing)
	var kind := world.object_at(tile.x, tile.y)
	if not can_harvest(held_id, kind):
		return WorldObjects.NONE
	if world.clear_object(tile.x, tile.y) == WorldObjects.NONE:
		return WorldObjects.NONE
	world.add_drop(drop_for(kind), drop_amount(kind),
		PlayerMotion.tile_center(tile.x, tile.y))
	return kind
