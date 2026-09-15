class_name WorldState
extends RefCounted

## 씨앗이 만든 월드 위에 얹히는 **사람이 바꾼 것**. 지금은 둘이다:
## **없어진 칸**(벤 나무)과 **바닥에 떨어진 것**(목재).
##
## **회차 24 가 남긴 물음의 답이다** — 「벤 자리를 어디에 적나」.
## 배치(`WorldObjects`)는 좌표를 넣으면 답이 나오는 순수 해시라 상태가 없다:
## 「이 칸의 나무는 없어졌다」를 적을 자리가 코드 어디에도 없었다.
##
## **씨앗 월드를 고치지 않는다.** 없앤 칸의 **목록**만 들고, 물으면 그 위에 덮어서
## 답한다. 두 가지가 여기서 나온다:
##   - 월드 저장(BACKLOG P2d)은 이 두 개만 적으면 된다 — 지형과 배치는 씨앗 하나로
##     글자까지 같게 다시 나온다 (GDD D-1). 65536칸을 적는 저장이 아니다
##   - **나무가 다시 자라는 것**(GDD A-4 「한 번 캐고 끝나는 자원이 없다」)이
##     목록에서 한 칸을 지우는 것으로 끝난다 — 원래 무엇이 있었는지는 안 잃는다
##
## **막는 칸도 여기서 나온다.** 벤 나무가 계속 몸을 막으면 「베었다」가 거짓말이 된다 —
## 그래서 `solid()` 이 없어진 칸을 같이 본다. 규칙 자체는 `WorldCollide` 에 한 벌만 있다.

## 어느 칸이 어떻게 바뀌었는지 알린다. **화면을 다시 칠하는 쪽이 이걸 듣는다** —
## main.gd 의 색 캐시는 「보이는 범위가 바뀔 때만」 다시 채우므로, 제자리에 선 채로
## 나무를 베면 **캐시가 상한 줄 모른다.**
signal changed(tile: Vector2i)

var world_seed: int

## 없어진 칸. `Vector2i` → true. **없는 칸이 곧 안 바뀐 칸**이라 빈 사전이 기본이다.
var cleared := {}

## 바닥에 떨어진 것. `{id, amount, pos}` 의 목록 — **순서가 곧 떨어진 순서**다.
## 줍기(BACKLOG P2)가 이 목록을 먹는다. 여기서는 쌓거나 합치지 않는다:
## 합치는 규칙은 가방의 것이고(`Inventory`), 바닥은 그냥 놓인 자리다.
var drops: Array[Dictionary] = []

func _init(seed_value: int) -> void:
	world_seed = seed_value

## ── 무엇이 놓여 있나 ─────────────────────────────────────────────────

## 이 칸에 지금 서 있는 것. **없앤 칸은 NONE 이다.**
func object_at(x: int, y: int) -> int:
	if cleared.has(Vector2i(x, y)):
		return WorldObjects.NONE
	return WorldObjects.at(world_seed, x, y)

## 씨앗이 **원래** 놓았던 것. 없앤 뒤에도 답이 남는다 — 다시 자라게 할 때 읽는다.
func original_at(x: int, y: int) -> int:
	return WorldObjects.at(world_seed, x, y)

func is_cleared(x: int, y: int) -> bool:
	return cleared.has(Vector2i(x, y))

func cleared_count() -> int:
	return cleared.size()

## ── 바꾸기 ───────────────────────────────────────────────────────────

## 이 칸의 것을 없앤다. 돌려주는 것은 **없앤 종류**다 — NONE 이면 아무 일도 안 했다.
## **빈 칸을 지웠다고 적지 않는다**: 목록이 「바꾼 것」이 아니라 「클릭한 자리」가 되면
## 저장이 자꾸 커지고, 다시 자라게 할 때 무엇을 되돌릴지도 흐려진다.
func clear_object(x: int, y: int) -> int:
	var kind := object_at(x, y)
	if kind == WorldObjects.NONE:
		return WorldObjects.NONE
	cleared[Vector2i(x, y)] = true
	changed.emit(Vector2i(x, y))
	return kind

## 바닥에 떨군다. **개수가 0 이하면 아무것도 안 놓는다** — 빈 더미가 바닥에 남으면
## 줍는 쪽이 「주웠는데 아무것도 안 들어왔다」를 보게 된다.
func add_drop(id: StringName, amount: int, pos: Vector2) -> bool:
	if id == Inventory.EMPTY or amount <= 0:
		return false
	drops.append({"id": id, "amount": amount, "pos": pos})
	return true

func drop_count() -> int:
	return drops.size()

## 바닥에 있는 그 아이디의 총 개수. 검사가 「삼키지 않았나」를 묻는 자리다.
func dropped_total(id: StringName) -> int:
	var n := 0
	for d in drops:
		if d["id"] == id:
			n += int(d["amount"])
	return n

## ── 몸이 지나갈 수 없는 칸 ───────────────────────────────────────────

## 「이 칸이 막나」. **없앤 칸은 안 막는다.**
## 규칙은 `WorldCollide` 에 한 벌뿐이다 — 여기서 바다·오브젝트를 다시 적으면
## 언젠가 한쪽만 고쳐져서 **벤 자리에 몸이 낀다.**
## `cleared` 를 **그대로** 넘긴다(사전은 참조다): 벨 때마다 Callable 을 다시 만들면
## 이미 꽂아 둔 플레이어가 옛 목록을 계속 본다.
func solid() -> Callable:
	return WorldCollide.solid_from_seed(world_seed, cleared)
