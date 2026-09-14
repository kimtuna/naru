class_name Inventory
extends RefCounted

## 가방의 **순수 계산**. 노드도 엔진 상태도 안 본다 — 그래서 헤드리스로 잴 수 있다.
##
## **규칙 하나가 이 클래스의 전부다: 넘치는 몫이 사라지지 않는다.**
## `add()` 는 「넣었다/못 넣었다」가 아니라 **못 넣고 남은 개수**를 돌려준다.
## 부르는 쪽은 그 숫자를 반드시 받아야 한다 — 바닥에 떨구든, 제작대 버퍼에 남기든
## (BACKLOG P2 「바닥 드롭」 · P3 「수령 시 모자라면 버퍼에 남는다」).
## bool 을 돌려주면 「꽉 찼는데 조용히 증발」이 **한 글자도 안 틀리고** 짜여진다.
##
## 칸 하나의 불변식: `ids[i] == EMPTY` 와 `amounts[i] == 0` 은 **항상 같이** 참이다.

const SLOTS := 18       # 일반 칸. 핫바 9칸은 따로 얹는다 (GDD D-2c)
const STACK_MAX := 99   # [ASK] 임시값 — 사람이 정할 것. 도구처럼 1개만 쌓이는 것은 아직 없다
const EMPTY := &""

var ids: Array[StringName] = []
var amounts: Array[int] = []

## 상자·제작대 버퍼도 같은 계산을 쓰므로 칸 수를 받는다. 기본은 가방의 18칸이다.
func _init(slot_count: int = SLOTS) -> void:
	var n := maxi(slot_count, 0)
	ids.resize(n)
	ids.fill(EMPTY)
	amounts.resize(n)
	amounts.fill(0)

func slot_count() -> int:
	return ids.size()

func count(id: StringName) -> int:
	var n := 0
	for i in ids.size():
		if ids[i] == id:
			n += amounts[i]
	return n

func total() -> int:
	var n := 0
	for a in amounts:
		n += a
	return n

func free_slots() -> int:
	var n := 0
	for id in ids:
		if id == EMPTY:
			n += 1
	return n

## **「더 못 받는다」가 아니다** — 빈 칸이 없어도 이미 쌓인 것은 더 들어간다.
func is_full() -> bool:
	return free_slots() == 0

## 그 아이디가 더 들어갈 수 있는 개수. **`add()` 가 실제로 받는 수와 항상 같다.**
func space_for(id: StringName) -> int:
	if id == EMPTY:
		return 0
	var room := 0
	for i in ids.size():
		if ids[i] == id:
			room += STACK_MAX - amounts[i]
		elif ids[i] == EMPTY:
			room += STACK_MAX
	return room

## 넣는다. **돌려주는 것은 못 넣고 남은 개수다** — 0 이면 전부 들어갔다.
func add(id: StringName, amount: int) -> int:
	var left := maxi(amount, 0)
	if id == EMPTY:
		return left          # 받을 수 없는 것도 **삼키지는 않는다**
	# ① 이미 쌓여 있는 칸부터 채운다. 안 그러면 같은 것이 가방에 흩어져
	#    칸은 남는데 「자리가 없다」가 된다.
	for i in ids.size():
		if left <= 0:
			break
		if ids[i] == id and amounts[i] < STACK_MAX:
			var put := mini(left, STACK_MAX - amounts[i])
			amounts[i] += put
			left -= put
	# ② 그래도 남으면 빈 칸을 연다.
	for i in ids.size():
		if left <= 0:
			break
		if ids[i] == EMPTY:
			var put := mini(left, STACK_MAX)
			ids[i] = id
			amounts[i] = put
			left -= put
	return left

## 뺀다. 돌려주는 것은 **실제로 뺀 개수** — 모자라면 있는 만큼만 나간다.
##
## **뒤 칸부터 뺀다**: 앞에 꽉 찬 칸을 남기고 짜투리를 먼저 없애야
## 칸이 조금씩 갉아먹힌 채로 늘어나지 않는다.
func remove(id: StringName, amount: int) -> int:
	if id == EMPTY:
		return 0
	var want := maxi(amount, 0)
	var took := 0
	for i in range(ids.size() - 1, -1, -1):
		if took >= want:
			break
		if ids[i] != id:
			continue
		var take := mini(want - took, amounts[i])
		amounts[i] -= take
		took += take
		if amounts[i] == 0:
			ids[i] = EMPTY
	return took
