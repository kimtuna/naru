extends TestBase

## 가방을 잰다. **여기는 순수 계산만 본다** — 화면과 손에 드는 것은 다음 항목(핫바)이다.
##
## 이 파일이 지키는 문장은 하나다: **넘치는 몫이 사라지지 않는다.**
## 그래서 거의 모든 검사가 「들어간 것 + 돌려받은 것 == 넣으라고 한 것」을 다시 센다 —
## 반환값만 보면 가방이 조용히 먹은 것을 못 잡고, 총합만 보면 반환값이 거짓말한 것을 못 잡는다.

const WOOD := &"wood"
const STONE := &"stone"
const ORE := &"ore"

const MAX := Inventory.STACK_MAX

## 칸의 불변식. 검사가 아니라 **검사마다 부르는 자**다 (이름이 test_ 로 시작하지 않는다).
func _sane(inv: Inventory, where: String) -> void:
	for i in inv.slot_count():
		var empty_id: bool = inv.ids[i] == Inventory.EMPTY
		var empty_n: bool = inv.amounts[i] == 0
		check(empty_id == empty_n,
			"%s · 칸 %d 이 반만 비었다 — 잰 값 id %s · 개수 %d" % [where, i, inv.ids[i], inv.amounts[i]])
		check(inv.amounts[i] >= 0 and inv.amounts[i] <= MAX,
			"%s · 칸 %d 개수가 범위 밖 — 잰 값 %d · 기대 0..%d" % [where, i, inv.amounts[i], MAX])

## 가방을 정확히 꽉 채운다 — 18칸 전부 다른 것으로 가득. `add` 로 채워서
## 「채우는 길」과 「검사하는 길」이 같은 코드를 타게 한다.
func _packed() -> Inventory:
	var inv := Inventory.new()
	for i in Inventory.SLOTS:
		var left := inv.add(StringName("item_%d" % i), MAX)
		check(left == 0, "가방을 채우는 중 %d 번째가 안 들어갔다 — 남은 %d" % [i, left])
	return inv

func test_default_is_eighteen_slots() -> void:
	eq(Inventory.SLOTS, 18, "일반 칸 수")
	var inv := Inventory.new()
	eq(inv.slot_count(), 18, "새 가방의 칸 수")
	eq(inv.total(), 0, "새 가방의 총 개수")
	eq(inv.free_slots(), 18, "새 가방의 빈 칸")
	eq(inv.is_full(), false, "새 가방은 안 찼다")
	eq(inv.count(WOOD), 0, "없는 것의 개수")
	_sane(inv, "새 가방")

func test_first_add_opens_one_slot() -> void:
	var inv := Inventory.new()
	eq(inv.add(WOOD, 5), 0, "5개는 전부 들어간다")
	eq(inv.total(), 5, "총 개수")
	eq(inv.count(WOOD), 5, "나무 개수")
	eq(inv.free_slots(), 17, "빈 칸")
	eq(inv.ids[0], WOOD, "첫 칸의 것")
	eq(inv.amounts[0], 5, "첫 칸의 개수")
	_sane(inv, "한 번 넣은 뒤")

func test_same_item_fills_the_partial_stack_first() -> void:
	# 안 그러면 칸은 남는데 「자리가 없다」가 된다 — 나무 5개가 칸 셋을 먹는다.
	var inv := Inventory.new()
	inv.add(WOOD, 5)
	inv.add(STONE, 2)
	eq(inv.add(WOOD, 3), 0, "덧붙인 3개")
	eq(inv.free_slots(), 16, "칸을 더 열지 않았다")
	eq(inv.amounts[0], 8, "나무 칸이 쌓였다")
	eq(inv.ids[1], STONE, "돌은 제 칸에 그대로")
	eq(inv.count(WOOD), 8, "나무 총합")
	_sane(inv, "쌓은 뒤")

func test_one_stack_overflows_into_the_next_slot() -> void:
	var inv := Inventory.new()
	eq(inv.add(WOOD, MAX + 1), 0, "한 칸을 넘겨도 가방 안에서는 안 남는다")
	eq(inv.amounts[0], MAX, "첫 칸은 꽉")
	eq(inv.ids[1], WOOD, "둘째 칸도 나무")
	eq(inv.amounts[1], 1, "넘친 1개")
	eq(inv.total(), MAX + 1, "총 개수")
	eq(inv.free_slots(), 16, "칸 둘을 썼다")
	_sane(inv, "넘쳐서 두 칸")

func test_full_bag_gives_the_whole_amount_back() -> void:
	# **이 항목의 문장이다.** 꽉 찬 가방에 넣으면 넣으라고 한 만큼 그대로 돌아온다.
	var inv := _packed()
	eq(inv.is_full(), true, "18칸이 전부 찼다")
	eq(inv.total(), Inventory.SLOTS * MAX, "꽉 찬 총 개수")
	var before := inv.total()
	eq(inv.add(WOOD, 7), 7, "새 것 7개가 통째로 돌아온다")
	eq(inv.add(&"item_0", 7), 7, "이미 있지만 꽉 찬 것도 통째로 돌아온다")
	eq(inv.total(), before, "가방은 한 개도 안 늘고 안 줄었다")
	_sane(inv, "꽉 찬 가방")

func test_nothing_vanishes_when_space_runs_out() -> void:
	# 자리가 **모자라게** 남은 경우 — 「전부 들어감/전부 돌아옴」 사이가 진짜 구멍이다.
	for want: int in [1, 9, 10, 40, 1000]:
		var inv := _packed()
		inv.remove(&"item_0", 9)              # 꽉 찬 칸 하나에 9개 자리만 낸다 (빈 칸은 없다)
		eq(inv.is_full(), true, "빈 칸은 여전히 없다")
		var before := inv.total()
		var left := inv.add(&"item_0", want)
		var put := inv.total() - before
		eq(put + left, want, "%d개를 넣었을 때 보존" % want)
		eq(put, mini(want, 9), "%d개 중 실제로 들어간 수" % want)
		_sane(inv, "%d개 넣은 뒤" % want)

func test_space_for_matches_what_add_takes() -> void:
	# 「바닥에 남는다」를 부르는 쪽은 이 값을 미리 본다. 어긋나면 그쪽이 조용히 틀린다.
	var cases: Array[Inventory] = [Inventory.new(), _packed(), _packed(), Inventory.new(1)]
	cases[1].remove(&"item_3", MAX)            # 빈 칸 하나
	cases[2].remove(&"item_3", 40)             # 짜투리 자리만
	cases[3].add(WOOD, 5)                      # 칸이 하나뿐인 가방
	var ids: Array[StringName] = [ORE, ORE, &"item_3", WOOD]
	for i in cases.size():
		var inv: Inventory = cases[i]
		var room: int = inv.space_for(ids[i])
		var before: int = inv.total()
		var left: int = inv.add(ids[i], room + 5)
		eq(inv.total() - before, room, "%d번 가방 — 말한 자리만큼 들어갔다" % i)
		eq(left, 5, "%d번 가방 — 자리를 넘긴 5개가 돌아온다" % i)
		eq(inv.space_for(ids[i]), 0, "%d번 가방 — 이제 자리가 없다" % i)
		_sane(inv, "%d번 가방" % i)

func test_remove_gives_back_only_what_is_there() -> void:
	var inv := Inventory.new()
	inv.add(WOOD, 2 * MAX + 52)
	eq(inv.free_slots(), 15, "세 칸을 썼다")
	eq(inv.remove(WOOD, 60), 60, "뺀 개수")
	eq(inv.total(), 2 * MAX - 8, "남은 총 개수")
	eq(inv.free_slots(), 16, "빈 칸이 하나 돌아왔다")
	eq(inv.amounts[0], MAX, "앞 칸은 꽉 찬 채로 남는다")
	eq(inv.remove(STONE, 5), 0, "없는 것은 0개 나온다")
	# **있는 것보다 많이** 달라고 해야 이 줄이 뜻을 갖는다. 1000 이라고 적었더니
	# 상한이 999 가 된 순간 1990 개가 든 가방에 1000 을 부르는 — 그냥 성공하는 줄이 됐다.
	eq(inv.remove(WOOD, 10 * MAX), 2 * MAX - 8, "모자라면 있는 만큼만")
	eq(inv.total(), 0, "빈 가방")
	eq(inv.free_slots(), 18, "칸이 전부 돌아왔다")
	_sane(inv, "다 뺀 뒤")

func test_bad_input_never_eats_items() -> void:
	var inv := Inventory.new()
	eq(inv.add(Inventory.EMPTY, 5), 5, "이름 없는 것도 삼키지 않는다")
	eq(inv.add(WOOD, 0), 0, "0개")
	eq(inv.add(WOOD, -3), 0, "음수는 아무 일도 아니다")
	eq(inv.total(), 0, "가방은 그대로 비어 있다")
	eq(inv.free_slots(), 18, "칸도 안 열렸다")
	eq(inv.remove(WOOD, -3), 0, "음수만큼 빼면 0개")
	eq(inv.space_for(Inventory.EMPTY), 0, "이름 없는 것의 자리는 없다")
	inv.add(WOOD, 4)
	eq(inv.remove(WOOD, 0), 0, "0개 빼기")
	eq(inv.count(WOOD), 4, "0개 빼도 그대로")
	_sane(inv, "이상한 입력 뒤")

## **정해진 숫자를 글자로 박는다.** 위의 검사들은 전부 `MAX` 라는 이름으로만 쓰므로
## 상수가 조용히 움직여도 한 줄도 안 빨개진다 — 「꽉 찬 가방」이 그냥 다른 상황이 될 뿐이다.
## 바퀴 17 의 스폰 좌표와 같은 자리다: **사람이 고른 값은 이름이 아니라 숫자로 묶어야 한다.**
## 그래서 상수만 보지 않고 **실제로 채워서** 한 칸이 999 를 받는지까지 다시 센다.
func test_stack_cap_is_the_number_the_human_chose() -> void:
	eq(Inventory.STACK_MAX, 999, "한 칸 스택 상한 (2026-09-14 사람이 정했다)")
	var inv := Inventory.new()
	eq(inv.add(WOOD, 999), 0, "999개가 한 번에 들어간다")
	eq(inv.free_slots(), 17, "999개는 칸 하나만 쓴다")
	eq(inv.amounts[0], 999, "한 칸이 실제로 999개를 담았다")
	eq(inv.add(WOOD, 1), 0, "1000번째는 들어가되")
	eq(inv.free_slots(), 16, "둘째 칸을 연다")
	eq(inv.amounts[1], 1, "넘친 1개")
	_sane(inv, "999 를 채운 뒤")
	# 가방 한 개의 용량 — 18칸 × 999. 「꽉 찼다」를 재는 모든 검사가 딛는 바닥이다.
	eq(_packed().total(), 17982, "가방 한 개 용량 18칸 × 999")
