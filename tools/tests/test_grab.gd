extends TestBase

## **칸 사이로 아이템을 옮긴다** (회차 44) — 집어서 놓기의 순수 계산.
##
## 여기가 지키는 것은 하나다: **「칸 + 커서」의 총 개수가 안 변한다.**
## `Inventory` 의 「넘치는 몫이 사라지지 않는다」가 옮기기에서도 같은 말이어야 한다.
## 그래서 거의 모든 검사가 **합을 앞뒤로 재서 맞댄다** — 「옮겨졌다」만 보면
## 꽉 찬 칸에 부은 몫이 어디로 갔는지 아무도 안 묻는다.
##
## 진짜 게임이 이 계산을 정말 부르는지는 `measure_grab.gd`(GRAB)가 잰다:
## 여기가 다 맞아도 `main.gd` 가 클릭을 안 이으면 202개가 전부 초록이다.

const WOOD := &"wood"
const STONE := &"stone"

func _bag(fill: Dictionary = {}) -> Inventory:
	var inv := Inventory.new()
	for i in fill:
		inv.set_slot(int(i), fill[i][0], int(fill[i][1]))
	return inv

func _sum(g: Grab, invs: Array) -> int:
	var n := g.total()
	for inv in invs:
		n += (inv as Inventory).total()
	return n

## ── 칸 하나를 직접 적는 문 ───────────────────────────────────────────

func test_set_slot_은_불변식을_지킨다() -> void:
	var inv := Inventory.new()
	eq(inv.set_slot(0, WOOD, 7), 7, "적은 개수")
	eq(inv.ids[0], WOOD, "0번 칸의 아이디")
	eq(inv.amounts[0], 7, "0번 칸의 개수")
	# 개수가 0 이하면 **아이디도 같이 빈다** — 둘은 늘 같이 참이다.
	eq(inv.set_slot(0, WOOD, 0), 0, "0개를 적으면 적힌 개수")
	eq(inv.ids[0], Inventory.EMPTY, "0개를 적은 칸의 아이디")
	eq(inv.amounts[0], 0, "0개를 적은 칸의 개수")
	# 빈 아이디도 마찬가지다 — 개수를 줘도 빈 칸이 된다.
	inv.set_slot(1, Inventory.EMPTY, 5)
	eq(inv.amounts[1], 0, "빈 아이디를 적은 칸의 개수")
	# 상한을 넘겨 부르면 **잘린다.** 돌려주는 것이 실제로 적힌 개수다.
	eq(inv.set_slot(2, WOOD, Inventory.STACK_MAX + 10), Inventory.STACK_MAX, "상한 너머를 적으면")
	eq(inv.amounts[2], Inventory.STACK_MAX, "잘린 칸의 개수")

func test_없는_칸_번호는_아무_일도_안_한다() -> void:
	var inv := Inventory.new()
	check(not inv.has_slot(-1), "-1번 칸은 없다")
	check(not inv.has_slot(Inventory.SLOTS), "%d번 칸은 없다" % Inventory.SLOTS)
	check(inv.has_slot(0) and inv.has_slot(Inventory.SLOTS - 1), "0 .. 17 은 있다")
	eq(inv.set_slot(-1, WOOD, 5), 0, "없는 칸에 적으면")
	eq(inv.set_slot(99, WOOD, 5), 0, "없는 칸에 적으면")
	eq(inv.total(), 0, "없는 칸에 적어도 가방은 그대로다")

## ── 집는다 ──────────────────────────────────────────────────────────

func test_집으면_칸이_비고_합은_그대로다() -> void:
	var inv := _bag({0: [WOOD, 7]})
	var g := Grab.new()
	var before := _sum(g, [inv])
	check(g.is_empty(), "처음엔 빈 손이다")
	check(g.take(inv, 0), "집힌다")
	eq(g.id, WOOD, "커서의 아이디")
	eq(g.amount, 7, "커서의 개수 — 통째로 온다")
	eq(inv.ids[0], Inventory.EMPTY, "집고 난 칸의 아이디")
	eq(inv.amounts[0], 0, "집고 난 칸의 개수")
	eq(_sum(g, [inv]), before, "합 — 집는다고 개수가 변하면 안 된다")

func test_빈_칸은_집히지_않는다() -> void:
	var inv := Inventory.new()
	var g := Grab.new()
	check(not g.take(inv, 3), "빈 칸을 집으면 아무 일도 안 난다")
	check(g.is_empty(), "손은 여전히 비어 있다")

func test_이미_들었으면_또_집지_않는다() -> void:
	# 또 집으면 먼저 든 것이 **덮여서 사라진다** — 이 한 줄이 그 자리를 막는다.
	var inv := _bag({0: [WOOD, 7], 1: [STONE, 5]})
	var g := Grab.new()
	var before := _sum(g, [inv])
	g.take(inv, 0)
	check(not g.take(inv, 1), "든 채로는 못 집는다")
	eq(g.id, WOOD, "커서의 아이디 — 먼저 든 것 그대로")
	eq(g.amount, 7, "커서의 개수")
	eq(inv.amounts[1], 5, "1번 칸은 그대로다")
	eq(_sum(g, [inv]), before, "합")

func test_없는_칸_번호로는_못_집는다() -> void:
	var inv := _bag({0: [WOOD, 7]})
	var g := Grab.new()
	check(not g.take(inv, -1), "-1번 칸")
	check(not g.take(inv, 999), "999번 칸")
	check(not g.take(null, 0), "가방이 없으면")
	check(g.is_empty(), "손은 비어 있다")

## ── 놓는다 ──────────────────────────────────────────────────────────

func test_빈_칸에_놓으면_통째로_들어간다() -> void:
	var inv := _bag({0: [WOOD, 7]})
	var g := Grab.new()
	var before := _sum(g, [inv])
	g.take(inv, 0)
	check(g.put(inv, 5), "놓인다")
	eq(inv.ids[5], WOOD, "놓인 칸의 아이디")
	eq(inv.amounts[5], 7, "놓인 칸의 개수")
	check(g.is_empty(), "손이 빈다")
	eq(g.amount, 0, "커서의 개수")
	eq(_sum(g, [inv]), before, "합")

func test_같은_것_위에_놓으면_쌓인다() -> void:
	var inv := _bag({0: [WOOD, 7], 1: [WOOD, 3]})
	var g := Grab.new()
	var before := _sum(g, [inv])
	g.take(inv, 0)
	check(g.put(inv, 1), "놓인다")
	eq(inv.amounts[1], 10, "쌓인 칸의 개수 (3 + 7)")
	check(g.is_empty(), "손이 빈다")
	eq(_sum(g, [inv]), before, "합")

func test_꽉_찬_칸에_놓으면_손에_그대로_남는다() -> void:
	# **대조판이다** (BACKLOG): 꽉 찬 칸에 놓았는데 개수가 줄면 증발이다.
	var inv := _bag({0: [WOOD, 5], 1: [WOOD, Inventory.STACK_MAX]})
	var g := Grab.new()
	var before := _sum(g, [inv])
	g.take(inv, 0)
	check(not g.put(inv, 1), "꽉 찬 칸에는 아무것도 안 들어간다")
	eq(inv.amounts[1], Inventory.STACK_MAX, "꽉 찬 칸의 개수 — 한 톨도 안 늘었다")
	eq(g.id, WOOD, "커서의 아이디")
	eq(g.amount, 5, "커서의 개수 — 한 톨도 안 줄었다")
	eq(_sum(g, [inv]), before, "합 — 꽉 찬 칸에 놓아도 총 개수가 안 변한다")

func test_넘치는_몫은_커서에_남는다() -> void:
	# 상한까지만 들어가고 나머지는 손에 남는다 — 「넣었다/못 넣었다」가 아니다.
	var inv := _bag({0: [WOOD, 10], 1: [WOOD, Inventory.STACK_MAX - 4]})
	var g := Grab.new()
	var before := _sum(g, [inv])
	g.take(inv, 0)
	check(g.put(inv, 1), "일부는 들어간다")
	eq(inv.amounts[1], Inventory.STACK_MAX, "받은 칸의 개수 — 상한까지")
	eq(g.amount, 6, "커서에 남은 개수 (10 − 4)")
	eq(g.id, WOOD, "커서의 아이디 — 아직 들고 있다")
	eq(_sum(g, [inv]), before, "합")

func test_다른_것_위에_놓으면_맞바꾼다() -> void:
	var inv := _bag({0: [WOOD, 7], 1: [STONE, 5]})
	var g := Grab.new()
	var before := _sum(g, [inv])
	g.take(inv, 0)
	check(g.put(inv, 1), "맞바뀐다")
	eq(inv.ids[1], WOOD, "칸의 아이디 — 들고 있던 것")
	eq(inv.amounts[1], 7, "칸의 개수")
	eq(g.id, STONE, "커서의 아이디 — 칸에 있던 것")
	eq(g.amount, 5, "커서의 개수")
	eq(_sum(g, [inv]), before, "합 — 맞바꿔도 총 개수가 안 변한다")

func test_빈_손으로는_못_놓는다() -> void:
	var inv := Inventory.new()
	var g := Grab.new()
	check(not g.put(inv, 0), "빈 손으로 놓으면 아무 일도 안 난다")
	eq(inv.total(), 0, "가방")

func test_없는_칸_번호에는_못_놓는다() -> void:
	var inv := _bag({0: [WOOD, 7]})
	var g := Grab.new()
	g.take(inv, 0)
	check(not g.put(inv, -1), "-1번 칸")
	check(not g.put(inv, 999), "999번 칸")
	check(not g.put(null, 0), "가방이 없으면")
	eq(g.amount, 7, "커서의 개수 — 그대로다")

## ── 좌클릭 한 번 (`click`) ──────────────────────────────────────────

func test_좌클릭은_빈_손이면_집고_들었으면_놓는다() -> void:
	# **버튼이 하나다** (GDD D-2c). 부르는 쪽이 「지금 집는 차례인가」를 따로 세면
	# 그 판단이 두 곳이 되고 언젠가 갈라진다.
	var bag := _bag({0: [WOOD, 7]})
	var hot := Inventory.new(Hotbar.SLOTS)
	var g := Grab.new()
	var before := _sum(g, [bag, hot])
	check(g.click(bag, 0), "① 집는다")
	eq(g.amount, 7, "집은 뒤 커서의 개수")
	check(g.click(hot, 8), "② 놓는다 — 핫바 9번 칸")
	eq(hot.ids[8], WOOD, "핫바 9번 칸의 아이디")
	eq(hot.amounts[8], 7, "핫바 9번 칸의 개수")
	check(g.is_empty(), "손이 빈다")
	eq(bag.total(), 0, "가방은 비었다")
	eq(_sum(g, [bag, hot]), before, "합 — 가방 ↔ 핫바를 오가도 총 개수가 안 변한다")

func test_빈_칸을_빈_손으로_누르면_아무_일도_안_난다() -> void:
	var inv := Inventory.new()
	var g := Grab.new()
	check(not g.click(inv, 4), "바뀐 것이 없다")
	check(g.is_empty(), "손은 비어 있다")

## ── 우클릭 — 반을 집고 한 개씩 놓는다 (회차 46) ────────────────────

func test_반을_집으면_큰_쪽이_커서로_온다() -> void:
	# **홀수가 이 검사의 전부다** (BACKLOG 대조판 ①). 짝수만 시험하면 반올림을
	# 어느 쪽으로 하든 초록이라 「999 → 499 + 499」로 한 톨이 새도 아무도 안 묻는다.
	var inv := _bag({0: [WOOD, 9]})
	var g := Grab.new()
	var before := _sum(g, [inv])
	check(g.take_half(inv, 0), "반이 집힌다")
	eq(g.amount, 5, "커서의 개수 — 큰 쪽 (9 → 5 + 4)")
	eq(inv.amounts[0], 4, "칸에 남은 개수 — 작은 쪽")
	eq(inv.ids[0], WOOD, "칸의 아이디 — 아직 남아 있다")
	eq(_sum(g, [inv]), before, "합 — 반을 집는다고 개수가 변하면 안 된다")

func test_상한에서_반을_집으면_500_과_499_다() -> void:
	# 사람이 적어 준 값 그대로다 (BACKLOG): 999 → 커서 500 · 칸 499.
	var inv := _bag({0: [WOOD, Inventory.STACK_MAX]})
	var g := Grab.new()
	var before := _sum(g, [inv])
	check(g.take_half(inv, 0), "반이 집힌다")
	eq(g.amount, 500, "커서의 개수")
	eq(inv.amounts[0], 499, "칸에 남은 개수")
	eq(_sum(g, [inv]), before, "합")

func test_한_개짜리_칸에서_반을_집으면_그_한_개가_온다() -> void:
	# **대조판이다** (BACKLOG ④): 내림하면 0개를 들고 칸은 그대로라 「우클릭했는데
	# 아무 일도 안 난다」가 된다 — 사람 눈에는 버튼이 고장난 것으로 보인다.
	var inv := _bag({0: [WOOD, 1]})
	var g := Grab.new()
	var before := _sum(g, [inv])
	check(g.take_half(inv, 0), "집힌다")
	eq(g.amount, 1, "커서의 개수 — 0 이면 안 된다")
	eq(g.id, WOOD, "커서의 아이디")
	eq(inv.amounts[0], 0, "칸에 남은 개수")
	eq(inv.ids[0], Inventory.EMPTY, "빈 칸이 된 칸의 아이디")
	eq(_sum(g, [inv]), before, "합")

func test_반_집기의_두_쪽을_더하면_늘_원래_개수다() -> void:
	# 손으로 고른 수 몇 개로는 반올림의 경계를 다 못 짚는다 — 1 부터 상한까지 훑는다.
	for n in [1, 2, 3, 4, 5, 998, 999]:
		var inv := _bag({0: [WOOD, n]})
		var g := Grab.new()
		g.take_half(inv, 0)
		eq(g.amount + inv.amounts[0], n, "%d개를 반으로 가른 두 쪽의 합" % n)
		check(g.amount >= inv.amounts[0], "%d개일 때 커서가 큰 쪽이어야 한다" % n)

func test_빈_칸과_없는_칸에서는_반이_안_집힌다() -> void:
	var inv := _bag({0: [WOOD, 7]})
	var g := Grab.new()
	check(not g.take_half(inv, 3), "빈 칸")
	check(not g.take_half(inv, -1), "-1번 칸")
	check(not g.take_half(inv, 999), "999번 칸")
	check(not g.take_half(null, 0), "가방이 없으면")
	check(g.is_empty(), "손은 비어 있다")
	eq(inv.amounts[0], 7, "가방은 그대로다")

func test_이미_들었으면_반도_안_집는다() -> void:
	# `take` 와 같은 자리다 — 또 집으면 먼저 든 것이 덮여서 사라진다.
	var inv := _bag({0: [WOOD, 9], 1: [STONE, 8]})
	var g := Grab.new()
	var before := _sum(g, [inv])
	g.take_half(inv, 0)
	check(not g.take_half(inv, 1), "든 채로는 못 집는다")
	eq(g.amount, 5, "커서의 개수 — 먼저 든 것 그대로")
	eq(inv.amounts[1], 8, "1번 칸은 그대로다")
	eq(_sum(g, [inv]), before, "합")

func test_한_개씩_놓으면_한_번에_하나만_간다() -> void:
	var inv := _bag({0: [WOOD, 9]})
	var g := Grab.new()
	var before := _sum(g, [inv])
	g.take(inv, 0)
	check(g.put_one(inv, 5), "① 빈 칸에 한 개")
	eq(inv.amounts[5], 1, "빈 칸에 놓인 개수")
	eq(inv.ids[5], WOOD, "그 칸의 아이디")
	eq(g.amount, 8, "커서에 남은 개수")
	check(g.put_one(inv, 5), "② 같은 것 위에 한 개")
	eq(inv.amounts[5], 2, "쌓인 칸의 개수")
	eq(g.amount, 7, "커서에 남은 개수")
	eq(_sum(g, [inv]), before, "합")

func test_마지막_한_개를_놓으면_손이_빈다() -> void:
	var inv := _bag({0: [WOOD, 1]})
	var g := Grab.new()
	var before := _sum(g, [inv])
	g.take(inv, 0)
	check(g.put_one(inv, 4), "놓인다")
	check(g.is_empty(), "손이 빈다")
	eq(g.amount, 0, "커서의 개수")
	eq(g.id, Inventory.EMPTY, "커서의 아이디 — 개수가 0 이면 아이디도 빈다")
	eq(_sum(g, [inv]), before, "합")

func test_꽉_찬_칸에_한_개씩_놓으면_손에_그대로_남는다() -> void:
	# **대조판이다** (BACKLOG ②): 안 들어간 개수가 커서에 남아야 한다.
	var inv := _bag({0: [WOOD, 5], 1: [WOOD, Inventory.STACK_MAX]})
	var g := Grab.new()
	var before := _sum(g, [inv])
	g.take(inv, 0)
	check(not g.put_one(inv, 1), "꽉 찬 칸에는 한 톨도 안 들어간다")
	eq(inv.amounts[1], Inventory.STACK_MAX, "꽉 찬 칸의 개수 — 그대로")
	eq(g.amount, 5, "커서의 개수 — 한 톨도 안 줄었다")
	eq(_sum(g, [inv]), before, "합")

func test_다른_것_위에는_한_개도_안_놓인다() -> void:
	# **좌클릭과 갈리는 유일한 갈래다.** 우클릭은 개수를 고르는 조작인데 맞바꾸면
	# 무더기가 통째로 움직여서 「한 개씩」이 그 한 번만 거짓이 된다.
	var inv := _bag({0: [WOOD, 9], 1: [STONE, 5]})
	var g := Grab.new()
	var before := _sum(g, [inv])
	g.take(inv, 0)
	check(not g.put_one(inv, 1), "다른 것 위에는 아무 일도 안 난다")
	eq(inv.ids[1], STONE, "그 칸의 아이디 — 그대로")
	eq(inv.amounts[1], 5, "그 칸의 개수")
	eq(g.id, WOOD, "커서의 아이디 — 그대로 들고 있다")
	eq(g.amount, 9, "커서의 개수")
	eq(_sum(g, [inv]), before, "합")
	# 견주어 둔다: **같은 자리를 좌클릭하면 맞바뀐다.**
	check(g.put(inv, 1), "좌클릭은 맞바꾼다")
	eq(g.id, STONE, "맞바꾼 뒤 커서의 아이디")

func test_빈_손과_없는_칸에는_한_개도_못_놓는다() -> void:
	var inv := _bag({0: [WOOD, 7]})
	var g := Grab.new()
	check(not g.put_one(inv, 0), "빈 손으로는 못 놓는다")
	g.take(inv, 0)
	check(not g.put_one(inv, -1), "-1번 칸")
	check(not g.put_one(inv, 999), "999번 칸")
	check(not g.put_one(null, 0), "가방이 없으면")
	eq(g.amount, 7, "커서의 개수 — 그대로다")

func test_우클릭은_빈_손이면_반을_집고_들었으면_한_개를_놓는다() -> void:
	# 버튼 하나에 문 하나다 (`click` 과 같은 자리) — 부르는 쪽이 갈래를 세면
	# 그 판단이 두 곳이 되고 언젠가 갈라진다.
	var bag := _bag({0: [WOOD, 9]})
	var hot := Inventory.new(Hotbar.SLOTS)
	var g := Grab.new()
	var before := _sum(g, [bag, hot])
	check(g.click_alt(bag, 0), "① 반을 집는다")
	eq(g.amount, 5, "집은 개수")
	eq(bag.amounts[0], 4, "칸에 남은 개수")
	check(g.click_alt(hot, 8), "② 핫바 9번 칸에 한 개")
	eq(hot.amounts[8], 1, "핫바 9번 칸의 개수")
	eq(g.amount, 4, "커서에 남은 개수")
	check(g.click_alt(hot, 8), "③ 또 눌러도 한 개씩 간다")
	eq(hot.amounts[8], 2, "두 번 누른 핫바 칸의 개수")
	eq(_sum(g, [bag, hot]), before, "합 — 가방 ↔ 핫바를 오가도 총 개수가 안 변한다")

func test_빈_칸을_빈_손으로_우클릭하면_아무_일도_안_난다() -> void:
	var inv := Inventory.new()
	var g := Grab.new()
	check(not g.click_alt(inv, 4), "바뀐 것이 없다")
	check(g.is_empty(), "손은 비어 있다")

func test_반씩_집어_나가도_합이_안_변한다() -> void:
	# **이것이 이 항목의 전부다.** 반을 집고 한 개씩 놓기를 섞어 400번 누른다 —
	# 좌클릭까지 섞어야 「좌클릭으로 맞바꾼 뒤 우클릭」 같은 짝이 걸린다.
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260917
	var bag := Inventory.new()
	var hot := Inventory.new(Hotbar.SLOTS)
	bag.set_slot(0, WOOD, Inventory.STACK_MAX)
	bag.set_slot(1, WOOD, 3)
	bag.set_slot(2, STONE, Inventory.STACK_MAX - 2)
	bag.set_slot(3, STONE, 41)
	hot.set_slot(0, WOOD, Inventory.STACK_MAX)
	hot.set_slot(1, STONE, 1)
	var g := Grab.new()
	var before := _sum(g, [bag, hot])
	check(before > 0, "처음에 물건이 있어야 한다 — 0 은 어떤 버그도 안 잡는다")
	for step in 400:
		var inv: Inventory = hot if rng.randi_range(0, 1) == 1 else bag
		var i := rng.randi_range(0, inv.slot_count() - 1)
		if rng.randi_range(0, 1) == 1:
			g.click_alt(inv, i)
		else:
			g.click(inv, i)
		var now := _sum(g, [bag, hot])
		if now != before:
			failures.append("%d번째 클릭에서 합이 %d → %d 로 변했다" % [step, before, now])
			return
		# **칸의 불변식도 같이 본다** — 한 개씩 덜다 0 이 된 칸에 아이디가 남으면
		# 그 칸은 「빈 것처럼 보이는데 아이디가 있는」 칸이 된다.
		for k in inv.slot_count():
			if (inv.ids[k] == Inventory.EMPTY) != (inv.amounts[k] == 0):
				failures.append("%d번째 클릭 뒤 %d번 칸의 불변식이 깨졌다 — %s · %d개" % [
					step, k + 1, inv.ids[k], inv.amounts[k]])
				return
	eq(g.stow([bag, hot]), 0, "못 돌려놓은 개수")
	eq(_sum(g, [bag, hot]), before, "400번 누르고 닫은 뒤의 합")

## ── 창을 닫는다 (`stow`) ────────────────────────────────────────────

func test_집은_채로_닫으면_돌려놓는다() -> void:
	# **대조판이다** (BACKLOG): 집은 채로 가방을 닫아서 잃어버리면 안 된다.
	var bag := _bag({0: [WOOD, 7]})
	var hot := Inventory.new(Hotbar.SLOTS)
	var g := Grab.new()
	var before := _sum(g, [bag, hot])
	g.take(bag, 0)
	eq(g.stow([bag, hot]), 0, "못 돌려놓은 개수")
	check(g.is_empty(), "손이 빈다")
	eq(bag.count(WOOD), 7, "가방에 돌아온 개수")
	eq(_sum(g, [bag, hot]), before, "합 — 닫는다고 개수가 변하면 안 된다")

func test_가방이_꽉_찼으면_핫바가_받는다() -> void:
	# 받을 곳이 목록인 이유다. 순서가 곧 「가방 먼저」다.
	var bag := Inventory.new()
	for i in Inventory.SLOTS:
		bag.set_slot(i, STONE, Inventory.STACK_MAX)
	var hot := Inventory.new(Hotbar.SLOTS)
	var g := Grab.new()
	g.id = WOOD
	g.amount = 7
	var before := _sum(g, [bag, hot])
	eq(g.stow([bag, hot]), 0, "못 돌려놓은 개수")
	eq(hot.count(WOOD), 7, "핫바가 받은 개수")
	eq(_sum(g, [bag, hot]), before, "합")

func test_아무_데도_못_넣으면_손에_남는다() -> void:
	# **여기서 지우는 것이 곧 증발이다.** 부르는 쪽이 바닥에 떨구고 나서 비운다.
	var bag := Inventory.new()
	var hot := Inventory.new(Hotbar.SLOTS)
	for i in Inventory.SLOTS:
		bag.set_slot(i, STONE, Inventory.STACK_MAX)
	for i in Hotbar.SLOTS:
		hot.set_slot(i, STONE, Inventory.STACK_MAX)
	var g := Grab.new()
	g.id = WOOD
	g.amount = 7
	var before := _sum(g, [bag, hot])
	eq(g.stow([bag, hot]), 7, "못 돌려놓은 개수")
	eq(g.id, WOOD, "커서의 아이디 — 그대로 들고 있다")
	eq(g.amount, 7, "커서의 개수")
	eq(_sum(g, [bag, hot]), before, "합")

func test_빈_손으로_닫으면_아무_일도_안_난다() -> void:
	var bag := _bag({0: [WOOD, 7]})
	var g := Grab.new()
	eq(g.stow([bag]), 0, "못 돌려놓은 개수")
	eq(bag.amounts[0], 7, "가방은 그대로다")

## ── 합이 안 변한다 — 무작위로 눌러 본다 ─────────────────────────────

func test_아무_칸이나_눌러도_합이_안_변한다() -> void:
	# **이것이 이 클래스의 전부다.** 갈래를 손으로 하나씩 적는 검사는 「내가 생각한
	# 경우」만 본다 — 씨앗을 박은 무작위 클릭은 생각 못 한 짝을 친다.
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260916
	var bag := Inventory.new()
	var hot := Inventory.new(Hotbar.SLOTS)
	bag.set_slot(0, WOOD, Inventory.STACK_MAX)
	bag.set_slot(1, WOOD, 3)
	bag.set_slot(2, STONE, Inventory.STACK_MAX - 2)
	bag.set_slot(3, STONE, 40)
	hot.set_slot(0, WOOD, Inventory.STACK_MAX)
	hot.set_slot(1, STONE, 1)
	var g := Grab.new()
	var before := _sum(g, [bag, hot])
	check(before > 0, "처음에 물건이 있어야 한다 — 0 은 어떤 버그도 안 잡는다")
	for step in 400:
		var to_hot := rng.randi_range(0, 1) == 1
		var inv: Inventory = hot if to_hot else bag
		g.click(inv, rng.randi_range(0, inv.slot_count() - 1))
		var now := _sum(g, [bag, hot])
		if now != before:
			failures.append("%d번째 클릭에서 합이 %d → %d 로 변했다" % [step, before, now])
			return
	# 마지막엔 돌려놓는다 — 손에 남은 채로 끝나면 「닫으면 사라진다」가 여기서도 산다.
	eq(g.stow([bag, hot]), 0, "못 돌려놓은 개수")
	eq(_sum(g, [bag, hot]), before, "400번 누르고 닫은 뒤의 합")

## ── 칸의 불변식이 옮기기 뒤에도 참인가 ──────────────────────────────

func test_옮긴_뒤에도_빈_칸은_개수가_0_이다() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 44
	var bag := _bag({0: [WOOD, 9], 1: [STONE, 2], 2: [WOOD, Inventory.STACK_MAX]})
	var g := Grab.new()
	for _i in 200:
		g.click(bag, rng.randi_range(0, bag.slot_count() - 1))
		for k in bag.slot_count():
			if (bag.ids[k] == Inventory.EMPTY) != (bag.amounts[k] == 0):
				failures.append("%d번 칸의 불변식이 깨졌다 — 아이디 %s · 개수 %d" % [
					k + 1, bag.ids[k], bag.amounts[k]])
				return
		if g.is_empty() != (g.amount == 0):
			failures.append("커서의 불변식이 깨졌다 — 아이디 %s · 개수 %d" % [g.id, g.amount])
			return
