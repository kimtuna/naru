extends GutTest
## G-013 2단계 — 절벽: 높이 경계의 일부만 절벽 · 꼭대기까지 절벽 없는 길 · 절벽과 바다는 못 들어간다.

const Terrain := IslandConfig.Terrain
const SEEDS := [20260916, 1, -42, 123456789, 7 + (1 << 40)]
const ELEVATED := [Terrain.MOUNTAIN, Terrain.VOLCANO, Terrain.SNOW]
const NEIGHBORS_4 := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const NEIGHBORS_8 := [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1),
]
const SEED := 20260916

func _custom_config() -> IslandConfig:
	var cfg: IslandConfig = IslandConfig.load_default().duplicate()
	cfg.terrain_block = 3
	cfg.elevated_percent = 35.0
	cfg.max_height = 5
	cfg.cliff_percent = 80.0
	return cfg


func _maps() -> Array[IslandMap]:
	var maps: Array[IslandMap] = []
	for seed_value in SEEDS:
		maps.append(IslandGenerator.generate(seed_value))
	maps.append(IslandGenerator.generate(99, _custom_config()))
	return maps


## 8방향 이웃에 더 낮은 칸이 있는 솟은 칸 — 높이 경계.
func _is_boundary(map: IslandMap, c: Vector2i) -> bool:
	if not IslandConfig.is_elevated(map.terrain_at(c)):
		return false
	for d in NEIGHBORS_8:
		if map.has_cell(c + d) and map.height_at(c + d) < map.height_at(c):
			return true
	return false


# --- 높이 경계의 일부가 절벽, 나머지는 경사 ---

func test_cliffs_are_part_of_height_boundaries() -> void:
	for map in _maps():
		var by_kind := {}
		for kind in ELEVATED:
			by_kind[kind] = [0, 0]  # [절벽, 경사]
		for y in map.size:
			for x in map.size:
				var c := Vector2i(x, y)
				var boundary := _is_boundary(map, c)
				if map.is_cliff(c) and not boundary:
					fail_test("seed %d %s 절벽이 높이 경계가 아니다" % [map.world_seed, c])
					return
				if boundary:
					by_kind[map.terrain_at(c)][0 if map.is_cliff(c) else 1] += 1
		for kind in ELEVATED:
			var label := "seed %d 지형 %d" % [map.world_seed, kind]
			var cliff: int = by_kind[kind][0]
			var slope: int = by_kind[kind][1]
			assert_gt(cliff, 0, label + " 에 절벽이 있다")
			assert_gt(slope, 0, label + " 에 경사가 있다")
		var total := 0
		var cliffs := 0
		for kind in ELEVATED:
			cliffs += by_kind[kind][0]
			total += by_kind[kind][0] + by_kind[kind][1]
		var share := float(cliffs) / total
		assert_between(share, 0.15, 0.85, "seed %d 경계의 일부만 절벽 (%.2f)" % [map.world_seed, share])


func test_cliff_share_follows_config() -> void:
	var shares := []
	for pct in [20.0, 80.0]:
		var cfg: IslandConfig = IslandConfig.load_default().duplicate()
		cfg.cliff_percent = pct
		var map := IslandGenerator.generate(SEED, cfg)
		var cliffs := 0
		var boundary := 0
		for y in map.size:
			for x in map.size:
				if _is_boundary(map, Vector2i(x, y)):
					boundary += 1
					cliffs += 1 if map.is_cliff(Vector2i(x, y)) else 0
		shares.append(float(cliffs) / boundary)
	assert_lt(shares[0] + 0.2, shares[1], "절벽 %% 를 올리면 절벽이 는다 %s" % [shares])


func test_every_guaranteed_peak_has_cliffs() -> void:
	for i in 40:
		var seed_value := i * 7919 - 31337 + (i << 33)
		var map := IslandGenerator.generate(seed_value)
		for kind in ELEVATED:
			var blob := _blob(map, map.generator.peak(kind))
			var cliffs := 0
			for c in blob:
				if map.is_cliff(c):
					cliffs += 1
			if cliffs == 0:
				fail_test("seed %d 보장 지형 %d 에 절벽이 없다" % [seed_value, kind])
				return
	pass_test("40개 시드 모두 보장 산 · 화산 · 설산에 절벽이 있다")


func test_cliffs_are_same_for_same_seed() -> void:
	var a := IslandGenerator.generate(SEEDS[2])
	var b := IslandMap.new(IslandGenerator.new(SEEDS[2]), true)
	for i in range(300, 0, -1):
		var c := Vector2i((i * 71) % 256, (i * 37) % 256)
		assert_eq(b.is_cliff(c), a.is_cliff(c))
	assert_eq(a.cliff_bytes(), b.cliff_bytes())
	assert_ne(a.cliff_bytes(), IslandGenerator.generate(SEEDS[0]).cliff_bytes())


# --- 꼭대기까지 절벽 없는 길 (임시 보장) ---

## c 와 같은 지형으로 4방향 이어진 칸들.
func _blob(map: IslandMap, start: Vector2i) -> Array[Vector2i]:
	var kind := map.terrain_at(start)
	var seen := {start: true}
	var out: Array[Vector2i] = [start]
	var k := 0
	while k < out.size():
		var c := out[k]
		k += 1
		for d in NEIGHBORS_4:
			var e: Vector2i = c + d
			if map.has_cell(e) and not seen.has(e) and map.terrain_at(e) == kind:
				seen[e] = true
				out.append(e)
	return out


## 스폰에서 바다 · 절벽이 아닌 칸으로 4방향 걸어 닿는 칸. 자원은 캐면 치워지니 길로 본다.
func _walkable_from_spawn(map: IslandMap) -> PackedByteArray:
	var n := map.size
	var terrain := map.terrain_bytes()
	var cliff := map.cliff_bytes()
	var seen := PackedByteArray()
	seen.resize(n * n)
	var s := map.spawn()
	seen[s.y * n + s.x] = 1
	var stack: Array[Vector2i] = [s]
	while not stack.is_empty():
		var c: Vector2i = stack.pop_back()
		for d in NEIGHBORS_4:
			var e: Vector2i = c + d
			var j := e.y * n + e.x
			if map.has_cell(e) and seen[j] == 0 and terrain[j] != Terrain.SEA and cliff[j] == 0:
				seen[j] = 1
				stack.append(e)
	return seen


func test_every_elevated_blob_has_walkable_path_to_its_top() -> void:
	for map in _maps():
		var n := map.size
		var reach := _walkable_from_spawn(map)
		var done := {}
		var blobs := 0
		for y in n:
			for x in n:
				var c := Vector2i(x, y)
				if done.has(c) or not IslandConfig.is_elevated(map.terrain_at(c)):
					continue
				var blob := _blob(map, c)
				blobs += 1
				var top := 0
				for e in blob:
					done[e] = true
					top = maxi(top, map.height_at(e))
				var reached := false
				for e in blob:
					if map.height_at(e) == top and reach[e.y * n + e.x] == 1:
						reached = true
						break
				if not reached:
					fail_test("seed %d %s 덩어리(높이 %d) 꼭대기에 절벽 없이 못 간다" % [map.world_seed, c, top])
					return
		assert_gt(blobs, 3, "seed %d 솟은 덩어리" % map.world_seed)


func test_path_to_top_holds_across_many_seeds() -> void:
	for i in 30:
		var seed_value := i * 104729 + 5 - (i << 36)
		var map := IslandGenerator.generate(seed_value)
		var reach := _walkable_from_spawn(map)
		for kind in ELEVATED:
			var blob := _blob(map, map.generator.peak(kind))
			var top := 0
			for e in blob:
				top = maxi(top, map.height_at(e))
			var ok := false
			for e in blob:
				if map.height_at(e) == top and reach[e.y * map.size + e.x] == 1:
					ok = true
			if not ok:
				fail_test("seed %d 보장 지형 %d 꼭대기 길이 없다" % [seed_value, kind])
				return
	pass_test("30개 시드 모두 보장 봉우리 꼭대기까지 걸어 오른다")


# --- 절벽 · 바다는 못 들어간다 ---

func test_cliff_and_sea_cells_are_blocked() -> void:
	var map := IslandGenerator.generate(SEED)
	var cliffs := 0
	for y in map.size:
		for x in map.size:
			var c := Vector2i(x, y)
			if map.is_cliff(c) or map.terrain_at(c) == Terrain.SEA:
				cliffs += 1 if map.is_cliff(c) else 0
				if not map.is_blocked(c):
					fail_test("%s 절벽/바다인데 막히지 않았다" % c)
					return
	assert_gt(cliffs, 50)
	assert_false(map.is_blocked(map.spawn()))


func test_chunk_collision_covers_cliff_and_sea() -> void:
	var map := IslandGenerator.generate(SEED)
	var cell := approach(map, Vector2i(1, 0), true)
	assert_ne(cell, Vector2i(-1, -1))
	var chunk := IslandChunk.new()
	chunk.setup(map, map.chunk_of(cell), 16)
	var blocked := 0
	var rect := map.chunk_rect(chunk.chunk)
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if map.is_blocked(Vector2i(x, y)):
				blocked += 1
	var area := 0.0
	for col in chunk.collision_shapes():
		area += col.shape.size.x * col.shape.size.y
	assert_almost_eq(area / 256.0, float(blocked), 0.001)
	chunk.free()


## 절벽(cliff) 또는 바다 칸 c 와, 그 앞 두 칸(c - d, c - 2d)이 걸을 수 있는 곳. 스폰에서 가까운 순.
static func approach(map: IslandMap, d: Vector2i, want_cliff: bool) -> Vector2i:
	var s := map.spawn()
	for r in range(4, 120):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var c := s + Vector2i(dx, dy)
				if not map.has_cell(c) or not map.has_cell(c - d * 2):
					continue
				var hit := map.is_cliff(c) if want_cliff else map.terrain_at(c) == Terrain.SEA
				if hit and not map.is_blocked(c - d) and not map.is_blocked(c - d * 2) \
						and not map.is_blocked(c - d * 2 + Vector2i(d.y, d.x)) \
						and not map.is_blocked(c - d * 2 - Vector2i(d.y, d.x)) \
						and not map.is_blocked(c - d + Vector2i(d.y, d.x)) \
						and not map.is_blocked(c - d - Vector2i(d.y, d.x)):
					return c
	return Vector2i(-1, -1)
