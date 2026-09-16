extends GutTest
## G-013 4단계 — 빈손 시작 보장: 첫 도구 · 첫 제작대 재료(맨손 레시피)가 시작 섬에서 반드시 나온다.
## spec/04_life/gathering.md · 03_world/island-generation.md

const Deposit := IslandConfig.Deposit
const Terrain := IslandConfig.Terrain
const HAND := HarvestConfig.HAND
## 스폰에서 이 칸 수 안만 걸어 본다 — 시작 자리에서 바로 닿는 곳.
const REACH := 12
const RAW := {"wood": Deposit.TREE, "stone": Deposit.STONE}


## 원자재 → 첫 도구 하나(맨손 레시피 가운데 제일 비싼 것) + 첫 제작대에 드는 수.
func _need() -> Dictionary:
	var book := RecipeBook.load_default()
	var bench := book.get_recipe("workbench")
	assert_eq(bench.station, RecipeBook.HAND, "첫 제작대는 맨손으로 만든다")
	var need := {}
	for id in RAW:
		var tool_most := 0
		for r in book.recipes_at(RecipeBook.HAND):
			if r.id == "workbench":
				continue
			for it in r.inputs:
				assert_true(it.id in RAW, "맨손 레시피 %s 는 나무 · 돌만 쓴다" % r.id)
				if it.id == id:
					tool_most = maxi(tool_most, it.count)
		var bench_count := 0
		for it in bench.inputs:
			if it.id == id:
				bench_count = it.count
		need[id] = tool_most + bench_count
	assert_gt(need["wood"], 0)
	assert_gt(need["stone"], 0)
	return need


func test_bare_hands_can_gather_the_first_materials() -> void:
	for id in RAW:
		assert_true(HarvestConfig.can_harvest(HAND, RAW[id]), "맨손으로 %s 을 얻는다" % id)
		assert_eq(HarvestConfig.DROPS[RAW[id]], id)


func test_starter_patches_alone_cover_first_tool_and_bench() -> void:
	var need := _need()
	var drop := HarvestConfig.load_default().drop_count
	for i in 50:
		var gen := IslandGenerator.new(i * 7919 - 20000)
		var got := {Deposit.TREE: 0, Deposit.STONE: 0}
		var s := gen.config.spawn()
		for y in range(s.y - REACH, s.y + REACH + 1):
			for x in range(s.x - REACH, s.x + REACH + 1):
				var d := gen.starter_deposit(Vector2i(x, y))
				if d != Deposit.NONE:
					assert_eq(gen.deposit_at(x, y), d, "덩이 칸은 반드시 그 자원")
					assert_eq(gen.terrain_at(x, y), Terrain.GRASS, "덩이는 스폰 둘레 평지에")
					assert_false(gen.cliff_at(x, y))
					got[d] += 1
		assert_gte(got[Deposit.TREE] * drop, need["wood"], "seed %d 나무 덩이" % gen.world_seed)
		assert_gte(got[Deposit.STONE] * drop, need["stone"], "seed %d 돌 덩이" % gen.world_seed)


## 스폰에서 맨손으로 걸어가며(나무 · 돌은 캐서 지나간다) 닿는 나무 · 돌이 넉넉하다.
func test_first_materials_are_reachable_from_spawn_for_any_seed() -> void:
	var need := _need()
	var drop := HarvestConfig.load_default().drop_count
	for i in 200:
		var seed_value := i * 104729 - 777 + (i << 34)
		var gen := IslandGenerator.new(seed_value)
		var got := _reachable(gen)
		if got[Deposit.TREE] * drop < need["wood"] or got[Deposit.STONE] * drop < need["stone"]:
			fail_test("seed %d 시작 재료가 모자란다 %s" % [seed_value, got])
			return
	pass_test("200개 시드 모두 맨손으로 첫 도구 · 첫 제작대 재료에 닿는다")


func _reachable(gen: IslandGenerator) -> Dictionary:
	var s := gen.config.spawn()
	var got := {Deposit.TREE: 0, Deposit.STONE: 0}
	var seen := {s: true}
	var queue: Array[Vector2i] = [s]
	var k := 0
	while k < queue.size():
		var c := queue[k]
		k += 1
		for d in IslandField.NEIGHBORS_4:
			var n: Vector2i = c + d
			if seen.has(n) or maxi(absi(n.x - s.x), absi(n.y - s.y)) > REACH:
				continue
			seen[n] = true
			if gen.terrain_at(n.x, n.y) == Terrain.SEA or gen.cliff_at(n.x, n.y):
				continue
			var dep := gen.deposit_at(n.x, n.y)
			if dep != Deposit.NONE and not HarvestConfig.can_harvest(HAND, dep):
				continue
			if got.has(dep):
				got[dep] += 1
			queue.append(n)
	return got
