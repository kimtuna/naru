extends TestBase

## 월드에 놓인 것들(나무·돌·광물)을 잰다. 값의 출처는 NUMBERS 6b절.
##
## **여기는 한 프로세스 안의 순수 계산만 본다.** 「같은 씨앗 = 같은 배치」의 진짜 주장은
## **다른 프로세스에서도** 같다는 것이고, 그건 tools/tests/measure_world.gd 가 잰다 —
## 정적 변수에 시간을 한 번 섞어 두면 이 파일은 전부 초록으로 남는다 (회차 6 과 같은 구멍).

const SEEDS := [1, 42, -20260914, 20260914]
const STEP := 3                    # 표본 격자 간격. 전수 생성은 한 장에 390 ms 다

## ── 어디에 놓이나 ────────────────────────────────────────────────────

## **바다에도 월드 밖에도 안 놓인다.** 물 위에 뜬 나무는 사람 눈에 바로 보인다.
func test_never_on_water_or_outside() -> void:
	for s in SEEDS:
		var wet := 0
		var where := ""
		for y in range(0, WorldGen.SIZE, STEP):
			for x in range(0, WorldGen.SIZE, STEP):
				if WorldGen.tile_at(s, x, y) == WorldGen.WATER \
						and WorldObjects.at(s, x, y) != WorldObjects.NONE:
					wet += 1
					if where == "":
						where = str(Vector2i(x, y))
		eq(wet, 0, "씨앗 %d 바다에 놓인 것 (첫 자리 %s)" % [s, where])
	for p in [Vector2i(-1, 100), Vector2i(100, -1), Vector2i(WorldGen.SIZE, 128),
			Vector2i(128, WorldGen.SIZE), Vector2i(-500, -500)]:
		eq(WorldObjects.at(20260914, p.x, p.y), WorldObjects.NONE, "월드 밖 %s" % p)

## **스폰 둘레 7 x 7 은 반드시 빈터다.** 안 그러면 나무 속에 갇힌 채 시작하는 씨앗이 생긴다 —
## 그건 검사가 아니라 사람이 겪는다.
func test_spawn_clearing_is_empty() -> void:
	var sp := WorldGen.spawn_tile()
	var r := WorldObjects.SPAWN_CLEAR
	for s in SEEDS + [0, 7, 999983, 2147483647]:
		var blocked := 0
		var where := ""
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if WorldObjects.at(s, sp.x + dx, sp.y + dy) != WorldObjects.NONE:
					blocked += 1
					if where == "":
						where = str(Vector2i(dx, dy))
		eq(blocked, 0, "씨앗 %d 스폰 %d칸 안에 놓인 것 (첫 자리 %s)" % [s, r, where])

## 빈터가 **걸어 나갈 수 있는 빈터**인가. 지형(바다)까지 같이 묻는다 —
## 스폰이 땅이어도 세 칸 옆이 바다면 갇힌다.
func test_can_walk_out_of_the_spawn() -> void:
	var sp := WorldGen.spawn_tile()
	for s in SEEDS:
		var solid := WorldCollide.solid_from_seed(s)
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var open := 0
			for i in range(1, WorldObjects.SPAWN_CLEAR + 1):
				if solid.call(sp.x + d.x * i, sp.y + d.y * i):
					break
				open += 1
			eq(open, WorldObjects.SPAWN_CLEAR,
				"씨앗 %d · %s 로 걸어 나간 칸" % [s, d])

## ── 얼마나 놓이나 ────────────────────────────────────────────────────

## 전수 생성 실측 (NUMBERS 6b절): 나무 7.58 ~ 10.67% · 돌 1.93 ~ 2.05% · 광물 0.15 ~ 0.38%.
## 문턱은 넉넉히 둔다 — 값을 못 박는 게 아니라 **「하나도 없다」와 「온 섬이 숲」**을 잡는다.
func test_density_on_land_is_in_range() -> void:
	for s in SEEDS:
		var land := 0
		var k := PackedInt32Array([0, 0, 0, 0])
		for y in range(0, WorldGen.SIZE, STEP):
			for x in range(0, WorldGen.SIZE, STEP):
				if WorldGen.tile_at(s, x, y) != WorldGen.LAND:
					continue
				land += 1
				k[WorldObjects.at(s, x, y)] += 1
		var tree := 100.0 * k[WorldObjects.TREE] / land
		var rock := 100.0 * k[WorldObjects.ROCK] / land
		var ore := 100.0 * k[WorldObjects.ORE] / land
		check(tree > 4.0 and tree < 16.0,
			"씨앗 %d 나무 — 잰 값 %.2f%% · 기대 4%% ~ 16%% (땅 표본 %d)" % [s, tree, land])
		check(rock > 1.0 and rock < 3.5,
			"씨앗 %d 돌 — 잰 값 %.2f%% · 기대 1%% ~ 3.5%%" % [s, rock])
		check(ore > 0.05 and ore < 1.0,
			"씨앗 %d 광물 — 잰 값 %.3f%% · 기대 0.05%% ~ 1%%" % [s, ore])

## **광물이 제일 귀하다** (GDD C-5 광물 본위). 셋이 고르게 깔리면 통화가 안 된다.
func test_ore_is_the_rarest() -> void:
	for s in SEEDS:
		var k := PackedInt32Array([0, 0, 0, 0])
		for y in range(0, WorldGen.SIZE, STEP):
			for x in range(0, WorldGen.SIZE, STEP):
				k[WorldObjects.at(s, x, y)] += 1
		check(k[WorldObjects.ORE] * 2 < k[WorldObjects.ROCK],
			"씨앗 %d 광물 %d 이 돌 %d 의 절반 미만이 아니다" % [s, k[WorldObjects.ORE], k[WorldObjects.ROCK]])
		check(k[WorldObjects.ROCK] * 2 < k[WorldObjects.TREE],
			"씨앗 %d 돌 %d 이 나무 %d 의 절반 미만이 아니다" % [s, k[WorldObjects.ROCK], k[WorldObjects.TREE]])

## 광물이 설 수 있는 **가장 낮은 땅**. 값의 출처는 NUMBERS 6b · GDD C-5 · D-4 다.
##
## **여기에 숫자를 다시 적는 이유**: 전에는 `WorldObjects.ORE_MIN_HEIGHT` 를 읽어서
## 견줬는데, 그러면 **재는 값과 기대값이 같이 움직인다** — 상수를 0.0 으로 내리면
## 기대도 0.0 이 되고, 해수면이 0.30 이라 `h <= 0.0` 인 땅이 아예 없어서 **초록**이다.
## 대조군 ⑤(「광물 높이 문턱을 없앤다」)가 회차 24 부터 그래서 아무것도 안 잡았다.
##
## **한쪽으로만 막는다**: 올리는 회차는 통과하고 내리는 회차만 빨개진다.
const ORE_FLOOR := 0.55

## **광물은 섬 안쪽 높은 땅에만** — 해안에서 주우면 「산에 간다」가 없어진다.
## 두 가지를 따로 묻는다: **상수가 안 내려갔나**(값), **정말 높은 데만 있나**(배치).
## 둘 중 하나만 있으면 빠져나가는 길이 남는다 — 상수를 그대로 두고 `at_height` 의
## `if h > ORE_MIN_HEIGHT` 만 걷어내면 값은 멀쩡하고 배치만 해안까지 내려온다.
func test_ore_only_on_high_ground() -> void:
	check(WorldObjects.ORE_MIN_HEIGHT >= ORE_FLOOR,
		"광물 높이 문턱이 내려갔다 — 잰 값 %.2f · 바닥 %.2f (해수면 %.2f)" % [
			WorldObjects.ORE_MIN_HEIGHT, ORE_FLOOR, WorldGen.SEA_LEVEL])
	for s in SEEDS:
		var low := 0
		var lowest := 9.0
		for y in range(0, WorldGen.SIZE, STEP):
			for x in range(0, WorldGen.SIZE, STEP):
				if WorldObjects.at(s, x, y) != WorldObjects.ORE:
					continue
				var h := WorldGen.height_at(s, x, y)
				lowest = minf(lowest, h)
				if h <= ORE_FLOOR:
					low += 1
		eq(low, 0, "씨앗 %d 바닥 %.2f 아래의 광물 (제일 낮은 것 %.3f)" % [
			s, ORE_FLOOR, lowest])

## **나무는 뭉친다.** 칸마다 독립으로 뽑으면 이 배수가 1 이다 — 온 섬에 고르게 깔린
## 점이 되고 「저 숲으로 가자」가 없어진다. 실측 1.94 ~ 2.59 배 (NUMBERS 6b절).
func test_trees_clump_into_forests() -> void:
	for s in [1, 20260914]:
		var g := WorldObjects.generate(s)
		var land := 0
		var tree := 0
		var near := 0
		var tree_near := 0
		for y in range(1, WorldGen.SIZE - 1):
			for x in range(1, WorldGen.SIZE - 1):
				if WorldGen.tile_at(s, x, y) != WorldGen.LAND:
					continue
				land += 1
				var me := WorldObjects.at_grid(g, x, y)
				if me == WorldObjects.TREE:
					tree += 1
				var nb := false
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					if WorldObjects.at_grid(g, x + d.x, y + d.y) == WorldObjects.TREE:
						nb = true
				if nb:
					near += 1
					if me == WorldObjects.TREE:
						tree_near += 1
		var ratio := (float(tree_near) / near) / (float(tree) / land)
		check(ratio > 1.5, "씨앗 %d 뭉침 배수 — 잰 값 %.2f · 기대 1.5 초과 (흩뿌리면 1.0)" % [s, ratio])

## ── 순서가 없다 · 같은 씨앗은 같은 배치 ──────────────────────────────

## **한 칸만 물어도 한 장을 통째로 구워도 같은 답이다.** RandomNumberGenerator 로 짰다면
## 여기서 터진다 — 몇 번째로 뽑았느냐가 값을 정하기 때문이다.
func test_tile_query_matches_the_whole_map() -> void:
	var s := 42
	var g := WorldObjects.generate(s)
	var bad := 0
	var first := ""
	for y in range(0, WorldGen.SIZE, 7):
		for x in range(0, WorldGen.SIZE, 5):
			var one := WorldObjects.at(s, x, y)
			var whole := WorldObjects.at_grid(g, x, y)
			if one != whole:
				bad += 1
				if first == "":
					first = "(%d,%d) 한 칸 %d · 한 장 %d" % [x, y, one, whole]
	eq(bad, 0, "한 칸 질의와 한 장이 다른 칸 (첫 자리 %s)" % first)

func test_same_seed_is_same_placement() -> void:
	var diff := 0
	for y in range(0, WorldGen.SIZE, STEP):
		for x in range(0, WorldGen.SIZE, STEP):
			if WorldObjects.at(7, x, y) != WorldObjects.at(7, x, y):
				diff += 1
	eq(diff, 0, "같은 씨앗·같은 칸인데 다른 것이 놓였다")

## 씨앗이 다르면 **배치도 다르다.** 지형만 바뀌고 나무 자리가 같으면 소금이 죽은 것이다.
func test_different_seed_is_different_placement() -> void:
	for pair in [[1, 2], [42, 43], [-7, 7]]:
		var diff := 0
		var n := 0
		for y in range(0, WorldGen.SIZE, STEP):
			for x in range(0, WorldGen.SIZE, STEP):
				n += 1
				if WorldObjects.at(pair[0], x, y) != WorldObjects.at(pair[1], x, y):
					diff += 1
		var pct := 100.0 * diff / n
		check(pct > 1.0, "씨앗 %d 과 %d 의 배치 차이 — 잰 값 %.2f%% · 기대 1%% 초과" % [
			pair[0], pair[1], pct])

## ── 막는다 ───────────────────────────────────────────────────────────

## **셋 다 막는다.** 나무를 통과해 걸으면 도끼를 들 이유가 없다.
func test_everything_placed_blocks_and_empty_land_does_not() -> void:
	var s := 20260914
	var solid := WorldCollide.solid_from_seed(s)
	var bad_block := 0
	var bad_open := 0
	var seen := PackedInt32Array([0, 0, 0, 0])
	for y in range(0, WorldGen.SIZE, STEP):
		for x in range(0, WorldGen.SIZE, STEP):
			if WorldGen.tile_at(s, x, y) != WorldGen.LAND:
				continue
			var k := WorldObjects.at(s, x, y)
			seen[k] += 1
			if k == WorldObjects.NONE:
				if solid.call(x, y):
					bad_open += 1
			elif not solid.call(x, y):
				bad_block += 1
	eq(bad_block, 0, "놓였는데 안 막는 칸")
	eq(bad_open, 0, "빈 땅인데 막는 칸")
	for k in [WorldObjects.TREE, WorldObjects.ROCK, WorldObjects.ORE]:
		check(seen[k] > 0, "종류 %d 가 표본에 한 칸도 없다 — 판정이 공허하다" % k)

func test_blocks_matches_at() -> void:
	var s := 1
	var bad := 0
	for y in range(0, WorldGen.SIZE, 11):
		for x in range(0, WorldGen.SIZE, 13):
			if WorldObjects.blocks(s, x, y) != (WorldObjects.at(s, x, y) != WorldObjects.NONE):
				bad += 1
	eq(bad, 0, "blocks 와 at 이 다른 칸")

## ── 다시 자란다 (GDD A-4) ────────────────────────────────────────────

## **나무만 자란다, 그것도 「하루」로 적힌다.** 초로 적으면 하루 길이를 고치는 회차가
## 이 파일까지 열어야 하고, 둘이 어긋나면 균형이 조용히 달라진다 (WorldState.DAY_SEC).
func test_only_trees_grow_back_and_the_unit_is_days() -> void:
	eq(WorldObjects.regrow_days(WorldObjects.TREE), 1.0, "나무가 자라는 날 수")
	# **돌·광물은 0 이다** — 캔 자리에 도로 생기면 광산·자동화가 의미를 잃는다.
	eq(WorldObjects.regrow_days(WorldObjects.ROCK), 0.0, "돌이 자라는 날 수")
	eq(WorldObjects.regrow_days(WorldObjects.ORE), 0.0, "광물이 자라는 날 수")
	eq(WorldObjects.regrow_days(WorldObjects.NONE), 0.0, "빈 칸이 자라는 날 수")
