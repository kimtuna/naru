extends TestBase

## 씨앗 월드 위에 얹힌 **바뀐 것**을 잰다 — 없앤 칸 · 바닥에 떨어진 것.
##
## 여기가 지키는 한 문장: **씨앗이 만든 것을 안 고친다.** 없앤 칸의 목록만 들고
## 그 위에 덮어 답한다 — 그래서 저장은 목록 두 개고(P2d), 나무를 다시 자라게 하는 것은
## 목록에서 한 칸을 지우는 것이다 (GDD A-4).

const SEED := 20260914

## ── 안 건드리면 씨앗 그대로다 ────────────────────────────────────────

## **바꾸기 전에는 `WorldObjects` 와 글자 하나까지 같다.** 상태를 얹었다고 배치가
## 달라지면, 같은 씨앗이 같은 섬을 준다는 전제(GDD D-1)가 여기서 깨진다.
func test_an_untouched_state_is_the_seed_world() -> void:
	var w := WorldState.new(SEED)
	var diff := 0
	var where := ""
	for y in range(100, 160, 3):
		for x in range(100, 160, 3):
			if w.object_at(x, y) != WorldObjects.at(SEED, x, y):
				diff += 1
				if where == "":
					where = str(Vector2i(x, y))
	eq(diff, 0, "안 건드린 상태와 배치가 다른 칸 (첫 자리 %s)" % where)
	eq(w.cleared_count(), 0, "없어진 칸의 수")
	eq(w.drop_count(), 0, "바닥에 떨어진 것의 수")

## ── 없애기 ───────────────────────────────────────────────────────────

func test_clearing_a_tile_removes_only_that_tile() -> void:
	var w := WorldState.new(SEED)
	var t := _a_tree(w)
	if t == Vector2i.MAX:
		check(false, "씨앗 %d 에서 나무를 하나도 못 찾았다" % SEED)
		return
	eq(w.clear_object(t.x, t.y), WorldObjects.TREE, "없앤 종류")
	eq(w.object_at(t.x, t.y), WorldObjects.NONE, "없앤 칸에 남은 것")
	check(w.is_cleared(t.x, t.y), "없앤 칸으로 적혀야 한다")
	eq(w.cleared_count(), 1, "없어진 칸의 수")
	# **옆 칸은 그대로다.** 「한 칸」이 「그 둘레」로 번지면 숲이 클릭 한 번에 사라진다.
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		eq(w.object_at(t.x + d.x, t.y + d.y), WorldObjects.at(SEED, t.x + d.x, t.y + d.y),
			"옆 칸 %s" % d)

## **원래 무엇이 있었는지는 안 잃는다** — 다시 자라게 하려면 그 답이 필요하다 (GDD A-4).
func test_the_original_placement_survives_clearing() -> void:
	var w := WorldState.new(SEED)
	var t := _a_tree(w)
	if t == Vector2i.MAX:
		check(false, "씨앗 %d 에서 나무를 하나도 못 찾았다" % SEED)
		return
	w.clear_object(t.x, t.y)
	eq(w.original_at(t.x, t.y), WorldObjects.TREE, "없앤 뒤 원래 있던 것")

## **빈 칸을 없앴다고 적지 않는다.** 목록이 「바꾼 것」이 아니라 「클릭한 자리」가 되면
## 저장이 걸어 다닌 만큼 커지고, 되돌릴 것도 흐려진다.
func test_clearing_an_empty_tile_records_nothing() -> void:
	var w := WorldState.new(SEED)
	var sp := WorldGen.spawn_tile()          # 스폰 7x7 은 반드시 빈터다 (WorldObjects)
	eq(w.clear_object(sp.x, sp.y), WorldObjects.NONE, "빈 칸을 없앤 결과")
	eq(w.cleared_count(), 0, "없어진 칸의 수")
	check(not w.is_cleared(sp.x, sp.y), "빈 칸은 없앤 칸으로 적히면 안 된다")

## **바뀐 칸을 알린다.** 이 신호가 없으면 화면이 안 다시 칠해져서, 제자리에 선 채
## 벤 나무가 화면에 그대로 남는다 (main.gd 의 색 캐시).
func test_clearing_announces_the_tile() -> void:
	var w := WorldState.new(SEED)
	var t := _a_tree(w)
	if t == Vector2i.MAX:
		check(false, "씨앗 %d 에서 나무를 하나도 못 찾았다" % SEED)
		return
	var heard: Array[Vector2i] = []
	w.changed.connect(func(tile: Vector2i) -> void: heard.append(tile))
	w.clear_object(t.x, t.y)
	eq(heard.size(), 1, "들린 신호의 수")
	if heard.size() == 1:
		eq(heard[0], t, "알린 칸")
	# 빈 칸을 치면 아무 일도 안 일어났으므로 알릴 것도 없다.
	var sp := WorldGen.spawn_tile()
	w.clear_object(sp.x, sp.y)
	eq(heard.size(), 1, "빈 칸을 친 뒤 들린 신호의 수")

## ── 막는 칸 ──────────────────────────────────────────────────────────

## **벤 칸은 안 막고, 바다는 여전히 막는다.** 없앤 칸 목록이 바다까지 뚫어 주면
## 나무를 베서 바다 위를 걷게 된다.
func test_cleared_tiles_stop_blocking_but_water_does_not() -> void:
	var w := WorldState.new(SEED)
	var solid := w.solid()
	var t := _a_tree(w)
	if t == Vector2i.MAX:
		check(false, "씨앗 %d 에서 나무를 하나도 못 찾았다" % SEED)
		return
	check(solid.call(t.x, t.y), "나무가 선 칸은 막아야 한다")
	w.clear_object(t.x, t.y)
	# **벨 때마다 Callable 을 다시 안 만든다** — 미리 꽂아 둔 이 Callable 이 봐야 한다.
	check(not solid.call(t.x, t.y), "벤 칸이 아직도 막는다 (미리 꽂아 둔 Callable)")
	var sea := _some_water()
	if sea == Vector2i.MAX:
		check(false, "씨앗 %d 에서 바다를 못 찾았다" % SEED)
		return
	check(solid.call(sea.x, sea.y), "바다는 그대로 막아야 한다")
	w.clear_object(sea.x, sea.y)
	check(solid.call(sea.x, sea.y), "바다를 「베어서」 뚫으면 안 된다")

## ── 바닥에 떨어진 것 ─────────────────────────────────────────────────

func test_drops_pile_up_in_order() -> void:
	var w := WorldState.new(SEED)
	check(w.add_drop(&"wood", 3, Vector2(10, 20)), "목재를 떨궈야 한다")
	check(w.add_drop(&"wood", 2, Vector2(30, 40)), "두 번째 더미도 떨궈야 한다")
	eq(w.drop_count(), 2, "더미의 수")
	eq(w.dropped_total(&"wood"), 5, "바닥의 목재 총합")
	eq(w.dropped_total(&"stone"), 0, "바닥의 돌 총합")
	eq(w.drops[0]["pos"], Vector2(10, 20), "첫 더미의 자리")
	# **합치지 않는다** — 합치는 규칙은 가방의 것이고(Inventory), 바닥은 놓인 자리다.
	eq(w.drops[1]["amount"], 2, "둘째 더미의 개수")

## **빈 더미는 안 놓는다.** 0개짜리가 바닥에 남으면 주운 사람이
## 「주웠는데 아무것도 안 들어왔다」를 본다.
func test_an_empty_drop_is_not_placed() -> void:
	var w := WorldState.new(SEED)
	check(not w.add_drop(&"wood", 0, Vector2.ZERO), "0개는 안 놓아야 한다")
	check(not w.add_drop(&"wood", -5, Vector2.ZERO), "음수는 안 놓아야 한다")
	check(not w.add_drop(Inventory.EMPTY, 3, Vector2.ZERO), "빈 아이디는 안 놓아야 한다")
	eq(w.drop_count(), 0, "바닥에 떨어진 것의 수")

## 왼쪽 칸이 비어 있는 나무 하나. 못 찾으면 `Vector2i.MAX`.
func _a_tree(w: WorldState) -> Vector2i:
	var sp := WorldGen.spawn_tile()
	for r in range(WorldObjects.SPAWN_CLEAR + 1, 40):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var t := Vector2i(sp.x + dx, sp.y + dy)
				if w.object_at(t.x, t.y) == WorldObjects.TREE:
					return t
	return Vector2i.MAX

func _some_water() -> Vector2i:
	for x in range(0, WorldGen.SIZE, 7):
		if WorldGen.tile_at(SEED, x, 0) == WorldGen.WATER:
			return Vector2i(x, 0)
	return Vector2i.MAX
