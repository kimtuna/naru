extends GutTest
## G-013 1단계 — 높이와 지형 종류: 재현 · 덩어리 · 높이 차 · 보장 · 바다와 해안. 화면 색은 test_island_terrain_view.gd.

const Terrain := IslandConfig.Terrain
const SEEDS := [20260916, 1, -42, 123456789, 7 + (1 << 40)]
## 「한 칸짜리 고립 지형이 없다」 — 모든 칸이 8방향 이웃 가운데 같은 지형을 이만큼 가진다.
const MIN_SAME_NEIGHBORS := 3
const NEIGHBORS_8 := [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1),
]


func _custom_config() -> IslandConfig:
	var cfg: IslandConfig = IslandConfig.load_default().duplicate()
	cfg.terrain_block = 3
	cfg.land_percent = 45.0
	cfg.elevated_percent = 35.0
	cfg.forest_percent = 15.0
	cfg.max_height = 5
	return cfg


func _counts(map: IslandMap) -> Dictionary:
	var counts := {}
	for t in Terrain.values():
		counts[t] = 0
	for y in map.size:
		for x in map.size:
			counts[map.terrain_at(Vector2i(x, y))] += 1
	return counts


# --- 같은 시드 = 같은 지형 · 높이 ---

func test_same_seed_gives_same_terrain_and_height() -> void:
	for seed_value in SEEDS:
		var a := IslandGenerator.generate(seed_value)
		var b := IslandGenerator.generate(seed_value)
		assert_eq(a.terrain_bytes(), b.terrain_bytes(), "seed %d 지형" % seed_value)
		assert_eq(a.height_bytes(), b.height_bytes(), "seed %d 높이" % seed_value)
	var c := IslandGenerator.generate(SEEDS[0])
	var d := IslandGenerator.generate(SEEDS[1])
	assert_ne(c.terrain_bytes(), d.terrain_bytes(), "다른 시드는 다른 지형")
	assert_ne(c.height_bytes(), d.height_bytes(), "다른 시드는 다른 높이")


func test_lazy_height_equals_full_height_in_any_order() -> void:
	var full := IslandGenerator.generate(SEEDS[0])
	var lazy := IslandMap.new(IslandGenerator.new(SEEDS[0]), true)
	for i in range(400, 0, -1):
		var c := Vector2i((i * 53) % 256, (i * 29) % 256)
		assert_eq(lazy.height_at(c), full.height_at(c))
		assert_eq(lazy.terrain_at(c), full.terrain_at(c))
	assert_eq(lazy.height_bytes(), full.height_bytes())


# --- 덩어리 ---

func test_every_cell_has_same_terrain_neighbors() -> void:
	var cases := []
	for seed_value in SEEDS:
		cases.append(IslandGenerator.generate(seed_value))
	cases.append(IslandGenerator.generate(99, _custom_config()))
	for map: IslandMap in cases:
		var bytes := map.terrain_bytes()
		var n: int = map.size
		for y in n:
			for x in n:
				var t: int = bytes[y * n + x]
				var same := 0
				for d in NEIGHBORS_8:
					var nx: int = x + d.x
					var ny: int = y + d.y
					if nx >= 0 and ny >= 0 and nx < n and ny < n and bytes[ny * n + nx] == t:
						same += 1
				if same < MIN_SAME_NEIGHBORS:
					fail_test("seed %d (%d, %d) 지형 %d 의 같은 이웃이 %d칸" % [map.world_seed, x, y, t, same])
					return
	pass_test("모든 칸이 같은 지형 이웃을 %d칸 이상 가진다" % MIN_SAME_NEIGHBORS)


func test_terrain_forms_few_large_blobs() -> void:
	# 칸마다 흩뿌리지 않는다 — 지형이 바뀌는 이웃 쌍이 전체의 작은 몫이다.
	var map := IslandGenerator.generate(SEEDS[0])
	var bytes := map.terrain_bytes()
	var changes := 0
	for y in map.size:
		for x in map.size - 1:
			if bytes[y * map.size + x] != bytes[y * map.size + x + 1]:
				changes += 1
	assert_lt(float(changes) / (map.size * (map.size - 1)), 0.1)


# --- 높이 ---

func _assert_heights(map: IslandMap, top: int) -> int:
	var n: int = map.size
	var heights := map.height_bytes()
	var terrain := map.terrain_bytes()
	var highest := 0
	for y in n:
		for x in n:
			var h := heights[y * n + x]
			highest = maxi(highest, h)
			var raised := IslandConfig.is_elevated(terrain[y * n + x])
			if raised != (h > 0) or h > top:
				fail_test("seed %d (%d, %d) 지형 %d 높이 %d" % [map.world_seed, x, y, terrain[y * n + x], h])
				return -1
			for d in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(-1, 1)]:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx >= 0 and ny >= 0 and nx < n and ny < n and absi(heights[ny * n + nx] - h) > 1:
					fail_test("seed %d (%d, %d) 와 (%d, %d) 높이 차가 1 넘는다" % [map.world_seed, x, y, nx, ny])
					return -1
	return highest


func test_neighbor_heights_differ_by_at_most_one() -> void:
	var cfg := IslandConfig.load_default()
	for seed_value in SEEDS:
		var highest := _assert_heights(IslandGenerator.generate(seed_value, cfg), cfg.max_height)
		assert_eq(highest, cfg.max_height, "seed %d 산이 max_height 까지 솟는다" % seed_value)


func test_height_levels_come_from_config() -> void:
	var cfg := IslandConfig.load_default()
	assert_between(cfg.max_height, 1, 4, "개인 섬 산은 낮다")
	var low: IslandConfig = cfg.duplicate()
	low.max_height = 1
	assert_eq(_assert_heights(IslandGenerator.generate(5, low), 1), 1)
	var custom := _custom_config()
	assert_eq(_assert_heights(IslandGenerator.generate(5, custom), 5), 5)


func test_area_shares_come_from_config() -> void:
	for cfg: IslandConfig in [IslandConfig.load_default(), _custom_config()]:
		for seed_value in [3, 2026]:
			var map := IslandGenerator.generate(seed_value, cfg)
			var counts := _counts(map)
			var total := float(map.size * map.size)
			var land: float = total - counts[Terrain.SEA]
			var raised: int = counts[Terrain.MOUNTAIN] + counts[Terrain.VOLCANO] + counts[Terrain.SNOW]
			var label := "seed %d block %d" % [seed_value, cfg.terrain_block]
			assert_almost_eq(land / total, cfg.land_percent / 100.0, 0.03, label + " 땅 넓이")
			assert_almost_eq(raised / land, cfg.elevated_percent / 100.0, 0.01, label + " 솟은 지형 넓이")
			assert_almost_eq(counts[Terrain.FOREST] / land, cfg.forest_percent / 100.0, 0.01, label + " 숲 넓이")
			assert_gt(counts[Terrain.GRASS], 0, label + " 평지")


# --- 시작 섬 보장 ---

func test_every_seed_has_mountain_volcano_snow_sea_and_flat_spawn() -> void:
	var cfg := IslandConfig.load_default()
	var half := cfg.spawn_clear / 2
	for i in 120:
		var seed_value := i * 104729 - 777777 + (i << 35)
		var gen := IslandGenerator.new(seed_value, cfg)
		for kind in [Terrain.MOUNTAIN, Terrain.VOLCANO, Terrain.SNOW]:
			var p := gen.peak(kind)
			if gen.terrain_at(p.x, p.y) != kind:
				fail_test("seed %d 에 지형 %d 가 없다 (%s)" % [seed_value, kind, p])
				return
		if gen.terrain_at(0, 0) != Terrain.SEA:
			fail_test("seed %d 에 바다가 없다" % seed_value)
			return
		for dy in range(-half, half + 1):
			for dx in range(-half, half + 1):
				var c := cfg.spawn() + Vector2i(dx, dy)
				if gen.terrain_at(c.x, c.y) != Terrain.GRASS or gen.height_at(c.x, c.y) != 0:
					fail_test("seed %d 스폰 %s 가 평지가 아니다" % [seed_value, c])
					return
				if gen.deposit_at(c.x, c.y) != IslandConfig.Deposit.NONE:
					fail_test("seed %d 스폰 %s 에 장애물" % [seed_value, c])
					return
	pass_test("120개 시드 모두 산 · 화산 · 설산 · 바다가 있고 스폰 7×7 이 빈 평지다")


func test_guarantee_holds_even_without_noise_terrain() -> void:
	var cfg: IslandConfig = IslandConfig.load_default().duplicate()
	cfg.elevated_percent = 0.0
	cfg.forest_percent = 0.0
	var counts := _counts(IslandGenerator.generate(11, cfg))
	for kind in [Terrain.MOUNTAIN, Terrain.VOLCANO, Terrain.SNOW, Terrain.SEA, Terrain.BEACH]:
		assert_gt(counts[kind], 20, "지형 %d" % kind)
	assert_eq(counts[Terrain.FOREST], 0)


# --- 바다와 해안 ---

func test_sea_surrounds_island_with_beach_between() -> void:
	for seed_value in SEEDS:
		var map := IslandGenerator.generate(seed_value)
		var n: int = map.size
		var t: PackedByteArray = map.terrain_bytes()
		for i in n:
			for c in [Vector2i(i, 0), Vector2i(i, n - 1), Vector2i(0, i), Vector2i(n - 1, i)]:
				assert_eq(t[c.y * n + c.x], Terrain.SEA, "seed %d 가장자리 %s" % [seed_value, c])
		# 바다는 모두 가장자리와 이어진다 (갇힌 물이 없다).
		var seen := {}
		var stack: Array[Vector2i] = [Vector2i.ZERO]
		seen[Vector2i.ZERO] = true
		while not stack.is_empty():
			var c: Vector2i = stack.pop_back()
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var e: Vector2i = c + d
				if map.has_cell(e) and not seen.has(e) and t[e.y * n + e.x] == Terrain.SEA:
					seen[e] = true
					stack.append(e)
		var beach := 0
		for y in n:
			for x in n:
				var k := t[y * n + x]
				if k == Terrain.BEACH:
					beach += 1
				if k == Terrain.SEA:
					if not seen.has(Vector2i(x, y)):
						fail_test("seed %d (%d, %d) 바다가 가장자리와 이어지지 않는다" % [seed_value, x, y])
						return
					continue
				for d in NEIGHBORS_8:
					var e: Vector2i = Vector2i(x, y) + d
					if k != Terrain.BEACH and map.has_cell(e) and t[e.y * n + e.x] == Terrain.SEA:
						fail_test("seed %d (%d, %d) 지형 %d 가 해안 없이 바다에 닿는다" % [seed_value, x, y, k])
						return
		assert_gt(beach, 500, "seed %d 해안이 있다" % seed_value)
