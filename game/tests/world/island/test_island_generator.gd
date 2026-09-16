extends GutTest
## G-004 1단계 — 시드로 섬 만들기: 재현 · 스폰 빈터.
## 지형별 자원 비율 · 광물 지형 · 약초 · 빈손 시작 보장은 test_island_deposits.gd (G-013 4단계).

const Deposit := IslandConfig.Deposit

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
	var cfg := IslandConfig.load_default().copy()
	for kind in IslandConfig.ALLOWED_DEPOSITS:
		cfg.deposit_rule(kind).fill_percent = 100.0  # 빈틈 없이 채워도 빈터는 남아야 한다
	cfg.cliff_deposits.fill_percent = 100.0
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
