class_name Grab
extends RefCounted

## **커서가 든 것** — 칸에서 집어 올린 한 무더기다. 노드도 엔진도 안 본다.
##
## **규칙 하나가 이 클래스의 전부다: 「칸 + 커서」의 총 개수가 안 변한다.**
## `Inventory` 의 「넘치는 몫이 사라지지 않는다」가 옮기기에서도 같은 말이어야 한다 —
## 꽉 찬 칸에 부으면 **안 들어간 몫이 커서에 남고**, 다른 것이 들어 있으면 **맞바꾼다.**
## 어느 쪽도 「조용히 증발」이 아니다.
##
## **좌클릭 하나로 집고 놓는다** (GDD D-2c 는 버튼 하나로 간다): 빈 손이면 집고,
## 들었으면 놓는다. 그래서 밖에서 부르는 문은 `click()` 하나다 — 부르는 쪽이
## 「지금 집는 차례인가」를 따로 세면 그 판단이 두 곳이 되고 언젠가 갈라진다.
##
## **몇 개를 옮길지는 여기 없다.** 우클릭으로 반 집기 · 한 개씩 놓기는 **다음 항목**이고
## (BACKLOG), 그때 `take`/`put` 에 개수 인자가 붙는다. 지금은 통째로만 간다.
##
## **칸 번호를 믿지 않는다.** 번호는 화면 좌표에서 오므로(`BagView.slot_at`)
## 범위 밖이 들어올 길이 열려 있다 — `Inventory.has_slot` 이 그 문이다.

const EMPTY := Inventory.EMPTY

## 지금 커서에 있는 것. **둘은 늘 같이 참이다**: `id == EMPTY` ⟺ `amount == 0`.
var id: StringName = EMPTY
var amount := 0

func is_empty() -> bool:
	return id == EMPTY or amount <= 0

## 커서에 있는 개수. **검사가 「합이 그대로인가」를 물을 때 쓰는 쪽**이다.
func total() -> int:
	return 0 if is_empty() else amount

## 좌클릭 한 번. **빈 손이면 집고, 들었으면 놓는다.**
## 돌려주는 것은 **무엇인가 바뀌었나**다 — 빈 칸을 빈 손으로 누르면 false 다.
func click(inv: Inventory, index: int) -> bool:
	return put(inv, index) if not is_empty() else take(inv, index)

## 집는다 — 칸을 **통째로** 커서에 올린다. 이미 들고 있으면 아무 일도 안 한다.
func take(inv: Inventory, index: int) -> bool:
	if not is_empty() or inv == null or not inv.has_slot(index):
		return false
	if inv.ids[index] == EMPTY:
		return false
	id = inv.ids[index]
	amount = inv.amounts[index]
	inv.set_slot(index, EMPTY, 0)
	return true

## 놓는다. 세 갈래고, **어느 쪽도 개수를 안 줄인다**:
##   빈 칸    통째로 들어간다
##   같은 것  상한까지 붓고 **남은 몫은 커서에 남는다** — 꽉 찬 칸이면 한 톨도 안 준다
##   다른 것  **맞바꾼다** (마인크래프트 · 테라리아). 그 칸의 것이 커서로 온다
func put(inv: Inventory, index: int) -> bool:
	if is_empty() or inv == null or not inv.has_slot(index):
		return false
	var there: StringName = inv.ids[index]
	if there != EMPTY and there != id:
		var swap_id := there
		var swap_n: int = inv.amounts[index]
		inv.set_slot(index, id, amount)
		id = swap_id
		amount = swap_n
		return true
	var room: int = Inventory.STACK_MAX - inv.amounts[index]
	var put_n := mini(amount, room)
	if put_n <= 0:
		return false          # **꽉 찼다** — 손에 든 것은 그대로다
	inv.set_slot(index, id, inv.amounts[index] + put_n)
	_drop_from_hand(put_n)
	return true

## **창을 닫는다 — 든 것을 돌려놓는다.** 돌려주는 것은 **못 돌려놓은 개수**다.
##
## 「집은 채로 가방을 닫으면 사라진다」는 이 한 함수가 없으면 한 글자도 안 틀리고
## 짜여진다 — 커서는 화면의 것이라 창이 닫히면 그릴 자리가 없어진다.
## **못 넣은 몫은 커서에 그대로 남긴다**: 여기서 지우면 그게 곧 증발이다.
## 부르는 쪽이 바닥에 떨구고 나서 `clear()` 한다 (`main.gd`).
##
## 받는 것이 목록인 이유: 가방이 꽉 찼으면 핫바가 받는다. 상자·제작대가 생기면
## 그 줄에 끼워 넣는다.
func stow(bags: Array) -> int:
	if is_empty():
		return 0
	var left := amount
	for inv in bags:
		if left <= 0:
			break
		if inv is Inventory:
			left = (inv as Inventory).add(id, left)
	_drop_from_hand(amount - left)
	return left

## 커서를 비운다. **바닥에 떨군 뒤에만 부른다** — 그냥 부르면 증발이다.
func clear() -> void:
	id = EMPTY
	amount = 0

## 커서에서 n 개를 덜어낸다. 0 이 되면 아이디도 같이 비운다 —
## `id == EMPTY` ⟺ `amount == 0` 을 한 곳에서만 지킨다.
func _drop_from_hand(n: int) -> void:
	amount -= maxi(n, 0)
	if amount <= 0:
		id = EMPTY
		amount = 0
