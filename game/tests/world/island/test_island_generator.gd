extends GutTest
## G-004 1단계 — 시드로 섬 만들기: 재현 · 스폰 빈터 · 비율 · 광물 지형 · 월드 시드 사용.

const Terrain := IslandConfig.Terrain
const Deposit := IslandConfig.Deposit
## 비율 오차 허용 — 몇만 칸을 세므로 실제 오차는 이보다 훨씬 작다.
const RATIO_TOLERANCE := 0.02


func _count(map: IslandMap, terrain: int) -> Dictionary:
	var counts := {"cells": 0, Deposit.NONE: 0, Deposit.TREE: 0, Deposit.STONE: 0, Deposit.ORE: 0}
	for y in map.size:
		for x in map.size:
			var cell := Vector2i(x, y)
			if terrain >= 0 and map.terrain_at(cell) != terrain:
				continue
			counts["cells"] += 1
			counts[map.deposit_at(cell)] += 1
	return counts


func _share(counts: Dictionary, kind: int, kinds: Array) -> float:
	var total := 0
	for k in kinds:
		total += counts[k]
	return float(counts[kind]) / total


# --- 같은 시드 = 같은 섬 ---

func test_same_seed_gives_same_cells() -> void:
	var a := IslandGenerator.generate(12345)
	var b := IslandGenerator.generate(12345)
	assert_eq(a.size, 256)
	assert_eq(a.terrain_bytes().size(), 256 * 256)
	assert_eq(a.terrain_bytes(), b.terrain_bytes(), "지형이 칸마다 같다")
	assert_eq(a.deposit_bytes(), b.deposit_bytes(), "자원이 칸마다 같다")


func test_different_seed_gives_different_cells() -> void:
	var a := IslandGenerator.generate(1)
	var b := IslandGenerator.generate(2)
	assert_ne(a.deposit_bytes(), b.deposit_bytes())


func test_cell_value_does_not_depend_on_order() -> void:
	var map := IslandGenerator.generate(-987654321)
	var gen := IslandGenerator.new(-987654321)
	# 거꾸로 · 띄엄띄엄 물어도 전체 생성과 같은 값.
	for i in range(200, 0, -1):
		var cell := Vector2i((i * 37) % 256, (i * 91) % 256)
		assert_eq(gen.terrain_at(cell.x, cell.y), map.terrain_at(cell))
		assert_eq(gen.deposit_at(cell.x, cell.y), map.deposit_at(cell))


func test_large_seed_uses_high_bits() -> void:
	var low := IslandGenerator.hash01(5, 3, 4, 0)
	var high := IslandGenerator.hash01(5 + (1 << 40), 3, 4, 0)
	assert_ne(low, high)
	assert_between(high, 0.0, 1.0)


# --- 스폰 7×7 ---

func test_spawn_7x7_is_clear_for_any_seed() -> void:
	var cfg := IslandConfig.load_default()
	cfg = cfg.duplicate()
	cfg.fill_percent = 100.0  # 빈틈 없이 채워도 빈터는 남아야 한다
	for i in 300:
		var seed_value := i * 7919 - 150000 + (i << 33)
		var gen := IslandGenerator.new(seed_value, cfg)
		for dy in range(-3, 4):
			for dx in range(-3, 4):
				var c := cfg.spawn() + Vector2i(dx, dy)
				if gen.deposit_at(c.x, c.y) != Deposit.NONE:
					fail_test("seed %d 스폰 %s 에 장애물" % [seed_value, c])
					return
	pass_test("300개 시드 모두 스폰 7×7 이 비어 있다")


func test_spawn_clear_on_full_map() -> void:
	var map := IslandGenerator.generate(424242)
	assert_eq(map.spawn(), Vector2i(128, 128))
	for dy in range(-3, 4):
		for dx in range(-3, 4):
			assert_false(map.is_blocked(map.spawn() + Vector2i(dx, dy)))
	# 빈터는 7×7 까지만 — 바로 바깥 줄에는 자원이 있다.
	var ring := 0
	for d in range(-4, 5):
		for c in [Vector2i(d, -4), Vector2i(d, 4), Vector2i(-4, d), Vector2i(4, d)]:
			if map.is_blocked(map.spawn() + c):
				ring += 1
	assert_gt(ring, 0)


# --- 비율 ---

func test_ratio_matches_default_config() -> void:
	var cfg := IslandConfig.load_default()
	assert_eq(cfg.fill_percent, 30.0)
	assert_eq([cfg.tree_weight, cfg.stone_weight, cfg.ore_weight], [3.0, 2.0, 1.0])
	for seed_value in [777, 99999, 2026, -31]:
		_assert_ratio(IslandGenerator.generate(seed_value, cfg), cfg)


func test_ratio_follows_changed_config() -> void:
	var cfg: IslandConfig = IslandConfig.load_default().duplicate()
	cfg.fill_percent = 55.0
	cfg.tree_weight = 1.0
	cfg.stone_weight = 4.0
	cfg.ore_weight = 5.0
	cfg.ore_ground_percent = 40.0  # 채울 55% × 광물 몫 1/2 = 27.5% 보다 넓어야 맞출 수 있다
	for seed_value in [31337, 99999, 2026]:
		_assert_ratio(IslandGenerator.generate(seed_value, cfg), cfg)


func test_fill_zero_leaves_island_empty() -> void:
	var cfg: IslandConfig = IslandConfig.load_default().duplicate()
	cfg.fill_percent = 0.0
	cfg.ore_patch_radius = 0
	var gen := IslandGenerator.new(5, cfg)
	for i in 500:
		var c := Vector2i((i * 53) % 256, (i * 17) % 256)
		if c != gen.ore_anchor():
			assert_eq(gen.deposit_at(c.x, c.y), Deposit.NONE)


func test_ore_ground_area_is_same_share_for_every_seed() -> void:
	var cfg := IslandConfig.load_default()
	for i in 50:
		var gen := IslandGenerator.new(i * 65537 - 1234567, cfg)
		# 얼룩 20% (표본 4096칸이라 819/4096) + 보장 원 (반지름 8 ≈ 0.3%, 얼룩과 겹칠 수 있다).
		assert_between(gen.ore_ground_share(), 819.0 / 4096.0, 0.21)
		assert_true(gen.ratio_reachable())


func test_too_narrow_ore_ground_is_reported() -> void:
	var cfg: IslandConfig = IslandConfig.load_default().duplicate()
	cfg.fill_percent = 55.0
	cfg.tree_weight = 1.0
	cfg.stone_weight = 4.0
	cfg.ore_weight = 5.0
	cfg.ore_ground_percent = 10.0
	assert_false(IslandGenerator.new(1, cfg).ratio_reachable(), "10% 땅에 27.5% 광물은 못 넣는다")
	cfg.ore_ground_percent = 30.0
	assert_true(IslandGenerator.new(1, cfg).ratio_reachable())


## 섬 전체: 채운 % 와 나무:돌:광물 비 (설정 비 그대로). 광물 지형 밖 광물은 0.
func _assert_ratio(map: IslandMap, cfg: IslandConfig) -> void:
	var all := _count(map, -1)
	assert_eq(all["cells"], cfg.size * cfg.size, "섬 전체를 센다")
	var filled: int = all[Deposit.TREE] + all[Deposit.STONE] + all[Deposit.ORE]
	assert_almost_eq(float(filled) / all["cells"], cfg.fill_percent / 100.0, RATIO_TOLERANCE,
		"seed %d 채운 %%" % map.world_seed)
	var tso := [Deposit.TREE, Deposit.STONE, Deposit.ORE]
	var total := cfg.tree_weight + cfg.stone_weight + cfg.ore_weight
	for kind in [[Deposit.TREE, cfg.tree_weight], [Deposit.STONE, cfg.stone_weight], [Deposit.ORE, cfg.ore_weight]]:
		assert_almost_eq(_share(all, kind[0], tso), kind[1] / total, RATIO_TOLERANCE,
			"seed %d 섬 전체의 비 (종류 %d)" % [map.world_seed, kind[0]])

	var ore_ground := _count(map, Terrain.ORE_GROUND)
	assert_gt(ore_ground["cells"], 2000, "광물 지형을 셀 만큼 넓다")
	assert_eq(ore_ground[Deposit.ORE], all[Deposit.ORE], "seed %d 광물은 모두 광물 지형에" % map.world_seed)


# --- 광물 지형 ---

func test_ore_only_on_ore_ground() -> void:
	for seed_value in [1, 99, 123456789, -42]:
		var map := IslandGenerator.generate(seed_value)
		var ore := 0
		for y in map.size:
			for x in map.size:
				var c := Vector2i(x, y)
				if map.deposit_at(c) == Deposit.ORE:
					ore += 1
					if map.terrain_at(c) != Terrain.ORE_GROUND:
						fail_test("seed %d %s 광물 지형 밖 광물" % [seed_value, c])
						return
		assert_gt(ore, 0, "seed %d 에 광물이 있다" % seed_value)


func test_every_island_has_ore_ground_with_ore() -> void:
	var cfg: IslandConfig = IslandConfig.load_default().duplicate()
	cfg.ore_ground_percent = 0.0  # 얼룩이 하나도 안 생겨도 보장은 남는다
	for i in 300:
		var seed_value := i * 104729 - 5000
		var gen := IslandGenerator.new(seed_value, cfg)
		var a := gen.ore_anchor()
		var inside := a.x >= 0 and a.y >= 0 and a.x < cfg.size and a.y < cfg.size
		if not inside or gen.terrain_at(a.x, a.y) != Terrain.ORE_GROUND or gen.deposit_at(a.x, a.y) != Deposit.ORE:
			fail_test("seed %d 에 광물 지형 · 광물이 없다 (%s)" % [seed_value, a])
			return
		if gen.in_spawn_clear(a):
			fail_test("seed %d 보장 광물이 스폰 빈터에 있다" % seed_value)
			return
	pass_test("300개 시드 모두 광물 지형과 광물이 있다")


func test_ore_ground_exists_on_full_map_without_noise() -> void:
	var cfg: IslandConfig = IslandConfig.load_default().duplicate()
	cfg.ore_ground_percent = 0.0
	var map := IslandGenerator.generate(2026, cfg)
	var counts := _count(map, Terrain.ORE_GROUND)
	assert_gt(counts["cells"], 100)
	assert_gt(counts[Deposit.ORE], 0)
	assert_eq(_count(map, Terrain.GRASS)[Deposit.ORE], 0)
