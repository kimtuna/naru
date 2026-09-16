extends GutTest
## G-013 4단계 — 지형별 자원. spec/03_world/terrain.md · island-generation.md · 04_life/gathering.md
## 숲은 나무 · 산은 돌 · 설산 = 철 · 화산 = 유황 · 약초는 절벽에만 · 지형마다 비율 규칙 · 빈손 시작 보장.

const Terrain := IslandConfig.Terrain
const Deposit := IslandConfig.Deposit
const CLIFF := -1
const LAND_KINDS := [Terrain.GRASS, Terrain.FOREST, Terrain.MOUNTAIN, Terrain.VOLCANO, Terrain.SNOW, Terrain.BEACH]
const ALL_DEPOSITS := [Deposit.TREE, Deposit.STONE, Deposit.IRON, Deposit.SULFUR, Deposit.HERB]
const SEEDS := [777, 2026, -31, 99999]


## 규칙대로 정해진 칸만 센다 (스폰 빈터 · 빈손 시작 덩이 · 광물 보장 칸은 뺀다).
## 돌려주는 값: 지형(절벽 칸은 CLIFF) → {"cells": n, 종류: n}.
func _count(maps: Array) -> Dictionary:
	var out := {}
	for map: IslandMap in maps:
		var gen := map.generator
		var anchors := [gen.mineral_anchor(Deposit.IRON), gen.mineral_anchor(Deposit.SULFUR)]
		for y in map.size:
			for x in map.size:
				var c := Vector2i(x, y)
				if gen.in_spawn_clear(c) or gen.starter_deposit(c) != Deposit.NONE or c in anchors:
					continue
				var key: int = CLIFF if map.is_cliff(c) else map.terrain_at(c)
				if not out.has(key):
					out[key] = {"cells": 0, Deposit.NONE: 0}
					for d in ALL_DEPOSITS:
						out[key][d] = 0
				out[key]["cells"] += 1
				out[key][map.deposit_at(c)] += 1
	return out


## n 개를 센 몫의 허용 오차 — 3 표준편차 + 여유.
func _tolerance(p: float, n: int) -> float:
	return 3.0 * sqrt(p * (1.0 - p) / maxf(n, 1)) + 0.005


func _assert_rules(counts: Dictionary, cfg: IslandConfig) -> void:
	var keys := LAND_KINDS.duplicate()
	keys.append(CLIFF)
	for key in keys:
		var cliff: bool = key == CLIFF
		var rule := cfg.deposit_rule(Terrain.GRASS if cliff else key, cliff)
		var c: Dictionary = counts.get(key, {})
		assert_gt(c.get("cells", 0), 300, "지형 %d 을 셀 만큼 넓다" % key)
		if c.get("cells", 0) == 0:
			continue
		var filled: int = c["cells"] - c[Deposit.NONE]
		var fill: float = float(filled) / c["cells"]
		assert_almost_eq(fill, rule.fill(), _tolerance(rule.fill(), c["cells"]), "지형 %d 채운 몫" % key)
		var allowed := IslandConfig.allowed_deposits(key, cliff)
		var expected := {}
		for share in rule.shares(allowed):
			expected[share[0]] = share[1]
		for d in ALL_DEPOSITS:
			var want: float = expected.get(d, 0.0)
			var got: float = float(c[d]) / maxf(filled, 1)
			if want == 0.0:
				assert_eq(c[d], 0, "지형 %d 에 자원 %d 이 없어야 한다" % [key, d])
			else:
				assert_almost_eq(got, want, _tolerance(want, filled), "지형 %d 자원 %d 의 비" % [key, d])


# --- 지형마다 비율 규칙 ---

func test_each_terrain_counts_near_its_own_rule() -> void:
	var cfg := IslandConfig.load_default()
	var maps := []
	for s in SEEDS:
		maps.append(IslandGenerator.generate(s, cfg))
	_assert_rules(_count(maps), cfg)


func test_rules_follow_changed_config() -> void:
	var cfg := IslandConfig.load_default().copy()
	cfg.forest_deposits = DepositRule.create(70.0, {Deposit.TREE: 1.0, Deposit.STONE: 1.0})
	cfg.mountain_deposits = DepositRule.create(15.0, {Deposit.TREE: 3.0, Deposit.STONE: 1.0})
	cfg.snow_deposits = DepositRule.create(60.0, {Deposit.IRON: 1.0})
	cfg.cliff_deposits = DepositRule.create(80.0, {Deposit.HERB: 1.0})
	# 그 지형에 못 나는 종류는 비를 적어도 안 난다.
	cfg.grass_deposits = DepositRule.create(25.0, {Deposit.TREE: 1.0, Deposit.IRON: 5.0, Deposit.HERB: 5.0})
	cfg.volcano_deposits = DepositRule.create(50.0, {Deposit.SULFUR: 1.0, Deposit.IRON: 1.0, Deposit.HERB: 1.0})
	var maps := [IslandGenerator.generate(31337, cfg), IslandGenerator.generate(4, cfg)]
	_assert_rules(_count(maps), cfg)
	var one := IslandConfig.load_default()
	assert_eq(one.forest_deposits.fill_percent, 45.0, "copy() leaves the default config alone")


func test_forest_is_mostly_trees_and_mountain_mostly_stone() -> void:
	var counts := _count([IslandGenerator.generate(2026), IslandGenerator.generate(5)])
	var density := func(key: int, d: Deposit) -> float:
		return float(counts[key][d]) / counts[key]["cells"]
	for key in LAND_KINDS:
		if key != Terrain.FOREST:
			assert_gt(density.call(Terrain.FOREST, Deposit.TREE), density.call(key, Deposit.TREE),
				"숲이 지형 %d 보다 나무가 빽빽하다" % key)
		if key != Terrain.MOUNTAIN:
			assert_gt(density.call(Terrain.MOUNTAIN, Deposit.STONE), density.call(key, Deposit.STONE),
				"산이 지형 %d 보다 돌이 빽빽하다" % key)
	assert_gt(counts[Terrain.FOREST][Deposit.TREE], counts[Terrain.FOREST][Deposit.STONE] * 3)
	assert_gt(counts[Terrain.MOUNTAIN][Deposit.STONE], counts[Terrain.MOUNTAIN][Deposit.TREE] * 3)


# --- 광물 · 약초는 제 자리에만 ---

func test_minerals_only_on_their_terrain_and_herbs_only_on_cliffs() -> void:
	for s in [1, 99, 123456789, -42]:
		var map := IslandGenerator.generate(s)
		var seen := {Deposit.IRON: 0, Deposit.SULFUR: 0, Deposit.HERB: 0}
		var bad := []
		for y in map.size:
			for x in map.size:
				var c := Vector2i(x, y)
				var d := map.deposit_at(c)
				if not seen.has(d):
					continue
				seen[d] += 1
				var t := map.terrain_at(c)
				var ok := false
				match d:
					Deposit.IRON:
						ok = t == Terrain.SNOW and not map.is_cliff(c)
					Deposit.SULFUR:
						ok = t == Terrain.VOLCANO and not map.is_cliff(c)
					Deposit.HERB:
						ok = map.is_cliff(c)
				if not ok and bad.size() < 5:
					bad.append([c, d, t])
		assert_eq(bad, [], "seed %d 제 자리 밖 광물 · 약초" % s)
		for d in seen:
			assert_gt(seen[d], 0, "seed %d 에 자원 %d 이 있다" % [s, d])


func test_cliffs_hold_nothing_but_herbs() -> void:
	var counts := _count([IslandGenerator.generate(2026)])
	var cliff: Dictionary = counts[CLIFF]
	assert_gt(cliff[Deposit.HERB], 0)
	assert_eq(cliff[Deposit.HERB] + cliff[Deposit.NONE], cliff["cells"], "절벽에는 약초만")


func test_every_island_has_iron_and_sulfur() -> void:
	var cfg := IslandConfig.load_default().copy()
	cfg.elevated_percent = 0.0  # 얼룩이 하나도 안 솟아도 보장은 남는다
	cfg.snow_deposits.fill_percent = 0.0
	cfg.volcano_deposits.fill_percent = 0.0
	for i in 300:
		var seed_value := i * 104729 - 5000
		var gen := IslandGenerator.new(seed_value, cfg)
		for pair in [[Deposit.IRON, Terrain.SNOW], [Deposit.SULFUR, Terrain.VOLCANO]]:
			var a := gen.mineral_anchor(pair[0])
			if not Rect2i(0, 0, cfg.size, cfg.size).has_point(a) or gen.terrain_at(a.x, a.y) != pair[1] \
					or gen.cliff_at(a.x, a.y) or gen.deposit_at(a.x, a.y) != pair[0] or gen.in_spawn_clear(a):
				fail_test("seed %d 에 광물 %d 보장이 없다 (%s)" % [seed_value, pair[0], a])
				return
	pass_test("300개 시드 모두 철 · 유황이 있다")


# --- 약초는 재배 불가 ---

func test_herbs_cannot_be_farmed() -> void:
	var farm := FarmConfig.new()
	assert_false("herb" in farm.seed_id or "herb" in farm.crop_id, "밭 작물이 약초가 아니다")
	var book := RecipeBook.load_default()
	assert_true(book.is_raw("herb"), "약초는 원자재 — 채집으로만 얻는다")
	for r in book.recipes:
		assert_false("herb" in str(r.output.id), "레시피 %s 가 약초 · 약초 씨앗을 만들지 않는다" % r.id)
	assert_eq(HarvestConfig.DROPS[Deposit.HERB], "herb")
