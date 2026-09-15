extends TestBase

## 씨앗 월드 위에 얹힌 **바뀐 것**을 잰다 — 없앤 칸 · 바닥에 떨어진 것.
##
## 여기가 지키는 한 문장: **씨앗이 만든 것을 안 고친다.** 없앤 칸의 목록만 들고
## 그 위에 덮어 답한다 — 그래서 저장은 목록 두 개고(P2d), 나무를 다시 자라게 하는 것은
## 목록에서 한 칸을 지우는 것이다 (GDD A-4).
##
## **회차 30 에 시계가 붙었다.** 다시 자라는 것은 여기서부터 「시간」이 필요한 첫 규칙이라
## `now` · `tick()` 이 이 몸에 같이 산다 — 저장이 여전히 하나이기 위해서다.

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

## ── 다시 자란다 (GDD A-4) ────────────────────────────────────────────

## **하루가 지나면 나무가 돌아온다.** 「한 번 캐고 끝나는 자원이 없다」가 이 한 줄이다.
## 하루를 **꽉 채워야** 한다 — 1초 모자라면 아직 그루터기다.
func test_a_cleared_tree_grows_back_after_one_day() -> void:
	var w := WorldState.new(SEED)
	var t := _a_tree(w)
	if t == Vector2i.MAX:
		check(false, "씨앗 %d 에서 나무를 하나도 못 찾았다" % SEED)
		return
	var solid := w.solid()
	w.clear_object(t.x, t.y)
	var day := WorldState.DAY_SEC * WorldObjects.regrow_days(WorldObjects.TREE)
	eq(w.regrow_at(t.x, t.y), day, "다시 자랄 시각")
	eq(w.tick(day - 1.0), 0, "하루가 1초 모자랄 때 자란 칸 수")
	eq(w.object_at(t.x, t.y), WorldObjects.NONE, "1초 모자랄 때 그 칸")
	eq(w.tick(2.0), 1, "하루를 넘겼을 때 자란 칸 수")
	eq(w.object_at(t.x, t.y), WorldObjects.TREE, "다시 자란 칸")
	eq(w.cleared_count(), 0, "없어진 칸의 수 — 목록에서 지워져야 한다")
	# **미리 꽂아 둔 Callable 이 도로 막아야 한다.** 여기가 빠지면 나무를 통과해 걷는다.
	check(solid.call(t.x, t.y), "다시 자란 칸이 안 막는다")

## **자란 칸도 알린다.** 없앨 때와 같은 이유다 — 이 신호가 없으면 색 캐시가 안 버려져서
## 화면에는 그루터기가 그대로 남는다 (main.gd).
func test_regrowing_announces_the_tile() -> void:
	var w := WorldState.new(SEED)
	var t := _a_tree(w)
	if t == Vector2i.MAX:
		check(false, "씨앗 %d 에서 나무를 하나도 못 찾았다" % SEED)
		return
	w.clear_object(t.x, t.y)
	var heard: Array[Vector2i] = []
	w.changed.connect(func(tile: Vector2i) -> void: heard.append(tile))
	w.tick(WorldState.DAY_SEC + 1.0)
	eq(heard.size(), 1, "자란 뒤 들린 신호의 수")
	if heard.size() == 1:
		eq(heard[0], t, "알린 칸")

## **몸이 서 있는 칸은 안 자란다.** 사람 안에서 나무가 자라면 그 자리가 곧
## 「벤 자리에 몸이 낀다」다 — 이 파일이 막으려고 있는 바로 그것이다.
## 비키면 `RETRY_SEC` 안에 자란다.
func test_a_body_on_the_tile_holds_the_regrow() -> void:
	var w := WorldState.new(SEED)
	var t := _a_tree(w)
	if t == Vector2i.MAX:
		check(false, "씨앗 %d 에서 나무를 하나도 못 찾았다" % SEED)
		return
	# **람다는 값을 복사해 간다** (GOTCHAS): `var standing := true` 를 그대로 잡으면
	# 나중에 false 로 바꿔도 람다 안은 영영 true 다 — 배열 한 칸에 담아 참조로 든다.
	var standing := [true]
	w.occupied = func(tile: Vector2i) -> bool: return standing[0] and tile == t
	w.clear_object(t.x, t.y)
	eq(w.tick(WorldState.DAY_SEC + 1.0), 0, "몸이 선 채로 하루가 지났을 때 자란 칸 수")
	eq(w.object_at(t.x, t.y), WorldObjects.NONE, "몸이 선 칸")
	# **영영 미루지 않는다** — 미룬 것은 다시 줄을 서야 한다.
	eq(w.tick(WorldState.RETRY_SEC * 0.5), 0, "비키기 전 자란 칸 수")
	standing[0] = false
	eq(w.tick(WorldState.RETRY_SEC), 1, "비킨 뒤 자란 칸 수")
	eq(w.object_at(t.x, t.y), WorldObjects.TREE, "비킨 뒤 그 칸")

## **설치물이 선 칸에는 안 자란다 — 그리고 옆 칸은 자란다** (GDD A-4 · 회차 32).
## 몸과 다른 점은 **안 움직인다**는 것뿐이라 규칙은 하나면 되는데, 「하나면 된다」를
## 안 재 두면 다음 회차가 설치물용 if 를 여기 하나 더 쌓는다.
##
## **옆 칸이 이 검사의 절반이다**: 설치물 하나가 온 섬의 재생을 멈춰도 「안 자란다」는
## 초록이다 — 자라야 하는 칸이 실제로 자라는 것을 같이 봐야 임자를 보고 미룬 것이다.
## 진짜 설치물은 아직 없으므로 **가짜 한 칸**을 `Claim` 에 꽂는다.
func test_an_installation_on_the_tile_holds_only_that_tile() -> void:
	var w := WorldState.new(SEED)
	var ts := _two_trees(w)
	if ts.is_empty():
		check(false, "씨앗 %d 에서 나무 두 그루를 못 찾았다" % SEED)
		return
	var under: Vector2i = ts[0]      # 설치물 아래
	var free: Vector2i = ts[1]       # 아무도 안 차지한 칸
	# **람다는 값을 복사해 간다** (GOTCHAS) — 허무는 것을 배열 한 칸에 담아 참조로 든다.
	var standing := [true]
	var claim := Claim.new()
	claim.add(&"가짜 설치물", func(tile: Vector2i) -> bool: return standing[0] and tile == under)
	w.occupied = claim.covers
	w.clear_object(under.x, under.y)
	w.clear_object(free.x, free.y)
	eq(w.tick(WorldState.DAY_SEC + 1.0), 1, "하루 뒤 자란 칸 수 (설치물 아래만 빼고)")
	eq(w.object_at(under.x, under.y), WorldObjects.NONE, "설치물이 선 칸")
	eq(w.object_at(free.x, free.y), WorldObjects.TREE, "아무도 안 차지한 옆 칸")
	eq(claim.holder(under), &"가짜 설치물", "설치물이 선 칸의 임자")
	# **허물면 자란다.** 영영 안 자라는 칸으로 적어 두면 되돌릴 자리가 없어진다.
	standing[0] = false
	eq(w.tick(WorldState.RETRY_SEC), 1, "허문 뒤 자란 칸 수")
	eq(w.object_at(under.x, under.y), WorldObjects.TREE, "허문 자리")

## **몸이든 설치물이든 월드는 똑같이 미룬다.** 물음은 하나뿐이고 목록은 `Claim` 의
## 것이라, 둘을 같이 꽂아도 `WorldState` 에는 고칠 줄이 없다.
func test_a_body_and_an_installation_share_one_question() -> void:
	var w := WorldState.new(SEED)
	var ts := _two_trees(w)
	if ts.is_empty():
		check(false, "씨앗 %d 에서 나무 두 그루를 못 찾았다" % SEED)
		return
	var claim := Claim.new()
	claim.add(Claim.BODY, func(tile: Vector2i) -> bool: return tile == ts[0])
	claim.add(&"가짜 설치물", func(tile: Vector2i) -> bool: return tile == ts[1])
	w.occupied = claim.covers
	w.clear_object(ts[0].x, ts[0].y)
	w.clear_object(ts[1].x, ts[1].y)
	eq(w.tick(WorldState.DAY_SEC + 1.0), 0, "둘 다 임자가 있을 때 자란 칸 수")
	eq(w.cleared_count(), 2, "없어진 채로 남은 칸의 수")
	eq(claim.holder(ts[0]), Claim.BODY, "첫 칸의 임자")
	eq(claim.holder(ts[1]), &"가짜 설치물", "둘째 칸의 임자")

## **돌·광물도 자란다 — 나무보다 느리게** (회차 37 · GDD A-4).
## 안 자라게 두면 초반에 야생 철을 다 캔 판이 광산 방을 지을 재료도 없이 막힌다.
## **캔 것이 도로 나온다**: 자란 칸은 빈 땅이 아니라 **씨앗이 놓았던 그 종류**라야 한다 —
## 돌 자리에 나무가 서면 「다시 자란다」가 「지형이 바뀐다」가 된다.
func test_stone_and_ore_grow_back_slower_than_trees() -> void:
	for kind in [WorldObjects.ROCK, WorldObjects.ORE]:
		var w := WorldState.new(SEED)
		var t := _an_object(w, kind)
		if t == Vector2i.MAX:
			check(false, "씨앗 %d 에서 종류 %d 를 하나도 못 찾았다" % [SEED, kind])
			continue
		var solid := w.solid()
		var wait := WorldState.DAY_SEC * WorldObjects.regrow_days(kind)
		eq(w.clear_object(t.x, t.y), kind, "없앤 종류")
		eq(w.regrow_at(t.x, t.y), wait, "종류 %d 가 다시 자랄 시각" % kind)
		# **나무 하루로는 안 자란다.** 셋이 같은 속도면 광물이 흔해져서 통화(C-5)가 흔들린다.
		eq(w.tick(WorldState.DAY_SEC + 1.0), 0, "종류 %d — 하루 뒤 자란 칸 수" % kind)
		eq(w.object_at(t.x, t.y), WorldObjects.NONE, "종류 %d — 하루 뒤 캔 자리" % kind)
		eq(w.tick(wait - w.now - 1.0), 0, "종류 %d — 1초 모자랄 때 자란 칸 수" % kind)
		eq(w.tick(2.0), 1, "종류 %d — 제 날을 넘겼을 때 자란 칸 수" % kind)
		eq(w.object_at(t.x, t.y), kind, "종류 %d — 자란 칸에 돌아온 것" % kind)
		eq(w.cleared_count(), 0, "종류 %d — 없어진 칸의 수" % kind)
		check(solid.call(t.x, t.y), "종류 %d 가 자랐는데 안 막는다" % kind)

## **줄은 「없앤 순서」가 아니라 「자랄 시각」 순이다** (회차 37).
## 종류마다 날 수가 달라진 순간부터 **넣는 순서가 곧 시각 순이 아니다** — 광물(7일)을
## 먼저 캐고 나무(1일)를 나중에 베면, 줄 맨 뒤에 붙는 큐에서는 나무가 광물 뒤에 선다.
## `tick` 은 맨 앞만 보므로 **엿새 동안 아무것도 안 자란다** — 그런데 한 종류만 캐 보는
## 검사는 전부 초록이다. `_schedule` 의 이진 삽입이 여기서 처음으로 일을 한다.
func test_the_queue_runs_in_time_order_not_in_clearing_order() -> void:
	var w := WorldState.new(SEED)
	var tree := _an_object(w, WorldObjects.TREE)
	var rock := _an_object(w, WorldObjects.ROCK)
	var ore := _an_object(w, WorldObjects.ORE)
	if tree == Vector2i.MAX or rock == Vector2i.MAX or ore == Vector2i.MAX:
		check(false, "씨앗 %d 에서 나무·돌·광물을 다 못 찾았다" % SEED)
		return
	# **느린 것부터 캔다** — 자랄 시각의 역순이다.
	w.clear_object(ore.x, ore.y)
	w.clear_object(rock.x, rock.y)
	w.clear_object(tree.x, tree.y)
	eq(w.cleared_count(), 3, "캔 칸의 수")
	eq(w.tick(WorldState.DAY_SEC + 1.0), 1, "하루 뒤 자란 칸 수")
	eq(w.object_at(tree.x, tree.y), WorldObjects.TREE, "하루 뒤 나무 자리")
	eq(w.object_at(rock.x, rock.y), WorldObjects.NONE, "하루 뒤 돌 자리")
	eq(w.object_at(ore.x, ore.y), WorldObjects.NONE, "하루 뒤 광물 자리")
	eq(w.tick(WorldState.DAY_SEC * 2.0), 1, "사흘 뒤 자란 칸 수")
	eq(w.object_at(rock.x, rock.y), WorldObjects.ROCK, "사흘 뒤 돌 자리")
	eq(w.object_at(ore.x, ore.y), WorldObjects.NONE, "사흘 뒤 광물 자리")
	eq(w.tick(WorldState.DAY_SEC * 4.0), 1, "이레 뒤 자란 칸 수")
	eq(w.object_at(ore.x, ore.y), WorldObjects.ORE, "이레 뒤 광물 자리")
	eq(w.cleared_count(), 0, "이레 뒤 없어진 칸의 수")

## **다시 벤 나무는 그때부터 다시 하루다.** 앞서 적힌 시각이 살아 있으면 두 번째 그루가
## 심자마자 자란다 — 큐에 남은 철 지난 기록이 그 구멍이다.
func test_chopping_again_restarts_the_clock() -> void:
	var w := WorldState.new(SEED)
	var t := _a_tree(w)
	if t == Vector2i.MAX:
		check(false, "씨앗 %d 에서 나무를 하나도 못 찾았다" % SEED)
		return
	w.clear_object(t.x, t.y)
	w.tick(WorldState.DAY_SEC + 1.0)
	eq(w.object_at(t.x, t.y), WorldObjects.TREE, "한 번 자란 칸")
	w.clear_object(t.x, t.y)
	eq(w.regrow_at(t.x, t.y), w.now + WorldState.DAY_SEC, "두 번째로 벤 칸의 시각")
	eq(w.tick(WorldState.DAY_SEC - 1.0), 0, "두 번째 하루가 1초 모자랄 때 자란 칸 수")
	eq(w.tick(2.0), 1, "두 번째 하루를 넘겼을 때 자란 칸 수")

## **바닥에 떨어진 것은 안 건드린다.** 자라면서 목재를 거둬 가면 자리를 비운 사이에
## 수확이 증발한다 — 「한 번 캐고 끝나는 자원이 없다」가 「캐도 안 남는다」가 된다.
func test_regrowing_leaves_the_drops_alone() -> void:
	var w := WorldState.new(SEED)
	var t := _a_tree(w)
	if t == Vector2i.MAX:
		check(false, "씨앗 %d 에서 나무를 하나도 못 찾았다" % SEED)
		return
	Harvest.hit(w, Harvest.AXE, PlayerMotion.tile_center(t.x - 1, t.y), Vector2.RIGHT)
	var before := w.dropped_total(Harvest.WOOD)
	check(before > 0, "먼저 목재가 떨어져 있어야 한다 (잰 값 %d)" % before)
	w.tick(WorldState.DAY_SEC + 1.0)
	eq(w.object_at(t.x, t.y), WorldObjects.TREE, "다시 자란 칸")
	eq(w.dropped_total(Harvest.WOOD), before, "자란 뒤 바닥의 목재")

## **시간은 뒤로 안 간다.** 음수 delta 한 번이면 온 섬의 시각이 미래로 밀려
## 벤 것이 영영 안 자란다.
func test_the_clock_never_runs_backwards() -> void:
	var w := WorldState.new(SEED)
	w.tick(10.0)
	eq(w.tick(-100.0), 0, "음수 delta 로 자란 칸 수")
	eq(w.now, 10.0, "음수 delta 뒤의 시계")

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

## 스폰에서 가까운 나무 하나. 못 찾으면 `Vector2i.MAX`.
func _a_tree(w: WorldState) -> Vector2i:
	return _an_object(w, WorldObjects.TREE)

## 스폰에서 가까운 **서로 다른 나무 두 그루**. 「차지한 칸만 안 자란다」를 재려면
## 자라야 하는 칸이 같이 있어야 한다 — 한 그루로는 「전부 멈췄다」와 구별이 안 된다.
func _two_trees(w: WorldState) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var sp := WorldGen.spawn_tile()
	for r in range(WorldObjects.SPAWN_CLEAR + 1, 80):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var t := Vector2i(sp.x + dx, sp.y + dy)
				if w.object_at(t.x, t.y) == WorldObjects.TREE:
					out.append(t)
					if out.size() == 2:
						return out
	return []

## 스폰에서 가까운 그 종류 하나. 돌은 나무보다 드물어서(2.0% 대 숲 42%) 더 멀리 본다.
func _an_object(w: WorldState, kind: int) -> Vector2i:
	var sp := WorldGen.spawn_tile()
	for r in range(WorldObjects.SPAWN_CLEAR + 1, 80):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var t := Vector2i(sp.x + dx, sp.y + dy)
				if w.object_at(t.x, t.y) == kind:
					return t
	return Vector2i.MAX

func _some_water() -> Vector2i:
	for x in range(0, WorldGen.SIZE, 7):
		if WorldGen.tile_at(SEED, x, 0) == WorldGen.WATER:
			return Vector2i(x, 0)
	return Vector2i.MAX
