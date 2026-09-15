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
## **몇 개를 옮길지는 버튼이 정한다** (회차 46): 좌클릭은 통째로, **우클릭은 반을 집고
## 한 개씩 놓는다** (마인크래프트 · 테라리아). 상한이 999 라 통째로만 옮기면 제작에
## 10개를 빼는 일조차 못 한다. **개수 인자를 안 붙였다**: 붙이면 부르는 쪽이 「지금
## 몇 개인가」를 세게 되고 그 계산이 두 곳이 된다 — 여기서는 **버튼마다 문이 하나**다
## (`click` · `click_alt`). 총 개수가 안 변한다는 규칙은 네 갈래 전부에 같이 걸린다.
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

## 우클릭 한 번. **빈 손이면 반을 집고, 들었으면 한 개만 놓는다.**
## 좌클릭과 **같은 모양의 문 하나**다 — 갈래를 부르는 쪽에서 세면 언젠가 둘이 갈라진다.
func click_alt(inv: Inventory, index: int) -> bool:
	return put_one(inv, index) if not is_empty() else take_half(inv, index)

## 반이 몇 개인가. **홀수면 큰 쪽이 커서로 온다** (999 → 커서 500 · 칸 499).
##
## **내림하면 안 된다**: 1개짜리 칸에서 0개를 들고 칸은 그대로라 「우클릭했는데
## 아무 일도 안 난다」가 된다 — 사람 눈에는 버튼이 고장난 것으로 보인다.
## 마인크래프트도 1개짜리는 통째로 손에 온다.
static func half_of(n: int) -> int:
	return (n + 1) / 2 if n > 0 else 0

## 반을 집는다. **칸에 남는 것이 작은 쪽**이고, 둘을 더하면 원래 개수다 —
## 여기서 한 톨이 새면 `take` 가 지키는 규칙이 우클릭에서만 깨진다.
func take_half(inv: Inventory, index: int) -> bool:
	if not is_empty() or inv == null or not inv.has_slot(index):
		return false
	if inv.ids[index] == EMPTY:
		return false
	var here: StringName = inv.ids[index]
	var n := half_of(inv.amounts[index])
	# 남는 몫을 **먼저 셈해 둔다** — 칸을 먼저 쓰면 뺄 원본이 사라진다.
	var left: int = inv.amounts[index] - n
	id = here
	amount = n
	inv.set_slot(index, here, left)   # 0 이면 `set_slot` 이 아이디까지 비운다
	return true

## 한 개만 놓는다. 갈래는 `put` 과 같은 모양인데 **개수만 하나다**:
##   빈 칸    한 개가 들어간다
##   같은 것  한 개 얹는다 — **꽉 찼으면 한 톨도 안 준다** (손에 그대로 남는다)
##   다른 것  **아무 일도 안 난다**
##
## 마지막 갈래가 `put` 과 갈린다. 우클릭은 **개수를 고르는 조작**인데 맞바꾸면 무더기가
## 통째로 움직여서 「한 개씩」이라는 말이 그 한 번만 거짓이 된다 — 맞바꾸기는 좌클릭의
## 몫이다. 어느 쪽이든 총 개수는 안 변한다.
func put_one(inv: Inventory, index: int) -> bool:
	if is_empty() or inv == null or not inv.has_slot(index):
		return false
	var there: StringName = inv.ids[index]
	if there != EMPTY and there != id:
		return false
	if inv.amounts[index] >= Inventory.STACK_MAX:
		return false          # **꽉 찼다** — 손에 든 것은 그대로다
	inv.set_slot(index, id, inv.amounts[index] + 1)
	_drop_from_hand(1)
	return true

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
