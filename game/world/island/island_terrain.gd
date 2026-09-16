class_name IslandTerrain
extends RefCounted
## 섬 지형 — 블록(terrain_block × terrain_block 칸)마다 지형 종류와 높이. spec/03_world/terrain.md.
## 블록 단위라 어느 칸이든 같은 블록의 이웃 3칸이 같은 지형이다 — 한 칸짜리 고립 지형이 생기지 않는다.
## 바다 이어짐 · 높이처럼 섬 전체를 봐야 하는 값은 만들 때 한 번에 정한다.
## 그래도 칸 값은 (시드, 좌표)로만 정해진다 — 어느 칸을 어느 순서로 물어도 같다.

const Terrain := IslandConfig.Terrain

const SALT_SHAPE := 0x5BD1E995
const SALT_DETAIL := 0x27D4EB2F
const SALT_RELIEF := 0x165667B1
const SALT_FOREST := 0x1B03738B
const SALT_KIND := 0x85EBCA6B
const SALT_PEAK := 0x2545F491
## 12방향 (cos, sin) × 1000 — 정수만 써서 기계마다 같은 자리에 봉우리를 둔다.
const DIRS_12 := [
	Vector2i(1000, 0), Vector2i(866, 500), Vector2i(500, 866), Vector2i(0, 1000),
	Vector2i(-500, 866), Vector2i(-866, 500), Vector2i(-1000, 0), Vector2i(-866, -500),
	Vector2i(-500, -866), Vector2i(0, -1000), Vector2i(500, -866), Vector2i(866, -500),
]
## 보장 봉우리를 놓는 차례 — 겹치면 뒤가 이긴다. 산이 마지막이라 광물 보장 칸(ore_anchor)은 늘 산이다.
const PEAK_KINDS := [Terrain.VOLCANO, Terrain.SNOW, Terrain.MOUNTAIN]
const ELEVATED_KINDS := [Terrain.MOUNTAIN, Terrain.VOLCANO, Terrain.SNOW]
const NEIGHBORS_4 := IslandField.NEIGHBORS_4
const NEIGHBORS_8 := IslandField.NEIGHBORS_8

var world_seed: int
var config: IslandConfig
## 블록 한 변의 칸 수 · 섬 한 변의 블록 수.
var block: int
var blocks: int
## 땅(바다 아닌 곳) · 솟은 지형의 칸 수.
var land_cells := 0
var elevated_cells := 0
var _kind := PackedByteArray()
var _height := PackedByteArray()
## 보장 봉우리 한가운데 칸 — Terrain → Vector2i.
var _peaks := {}
## 블록마다 무엇으로 정해졌나 — 섬 모양 · 솟음 · 숲 후보에서 뺄 곳.
var _forced := PackedByteArray()

const FORCE_NONE := 0
const FORCE_FLAT := 1  # 스폰 둘레 — 풀밭
const FORCE_LAND := 2  # 봉우리 둘레 — 땅이지만 솟음 · 숲은 따로 정한다
const FORCE_PEAK := 3  # 봉우리 — 솟은 지형


func _init(seed_value: int, cfg: IslandConfig) -> void:
	world_seed = seed_value
	config = cfg
	block = maxi(cfg.terrain_block, 1)
	blocks = ceili(float(cfg.size) / block)
	var n := blocks * blocks
	_kind.resize(n)
	_height.resize(n)
	_forced.resize(n)
	_place_peaks()
	var sea := _shape_sea()
	_mark_coast(sea)
	_raise()
	_grow_forest()
	_measure_heights()


func terrain_at(x: int, y: int) -> Terrain:
	if x < 0 or y < 0 or x >= config.size or y >= config.size:
		return Terrain.SEA
	return _kind[(y / block) * blocks + x / block] as Terrain


func height_at(x: int, y: int) -> int:
	if x < 0 or y < 0 or x >= config.size or y >= config.size:
		return 0
	return _height[(y / block) * blocks + x / block]


## 보장 봉우리 한가운데 칸 (산 · 화산 · 설산).
func peak(kind: Terrain) -> Vector2i:
	return _peaks[kind]


func _center(bx: int, by: int) -> Vector2:
	return Vector2(bx * block + block * 0.5, by * block + block * 0.5)


## 봉우리 셋을 스폰 둘레 120° 간격으로 둔다. 회전은 시드가 정한다.
func _place_peaks() -> void:
	var spawn := config.spawn()
	var d := config.peak_patch_distance
	var start := int(IslandGenerator.hash01(world_seed, 0, 0, SALT_PEAK) * 12.0) % 12
	for k in PEAK_KINDS.size():
		var dir: Vector2i = DIRS_12[(start + k * 4) % 12]
		_peaks[PEAK_KINDS[k]] = spawn + dir * d / 1000
	# 스폰 · 봉우리 둘레는 땅으로 둔다 — 해안까지 들어갈 만큼 넉넉하게.
	var coast := float((config.beach_width + 1) * block + block)
	var r_peak := float(maxi(config.peak_patch_radius, block))
	var r_flat := float(config.spawn_flat_radius)
	for by in blocks:
		for bx in blocks:
			var c := _center(bx, by)
			var i := by * blocks + bx
			if c.distance_to(Vector2(spawn)) <= r_flat + coast:
				_forced[i] = FORCE_FLAT if c.distance_to(Vector2(spawn)) <= r_flat + block else FORCE_LAND
			for kind in PEAK_KINDS:
				var dist := c.distance_to(Vector2(_peaks[kind]))
				if dist <= r_peak:
					_forced[i] = FORCE_PEAK
					_kind[i] = kind
				elif dist <= r_peak + coast and _forced[i] == FORCE_NONE:
					_forced[i] = FORCE_LAND


## 섬 모양 얼룩에서 land_percent 만큼 땅을 고르고, 가장자리와 이어진 물만 바다로 둔다.
## 스폰과 이어지지 않은 땅(먼 작은 섬)은 바다, 땅에 갇힌 물(호수)은 땅이 된다. 돌려주는 값: 블록마다 바다면 1.
func _shape_sea() -> PackedByteArray:
	var n := blocks * blocks
	var big := IslandField.lattice(world_seed, config.size, config.shape_noise_cell, SALT_SHAPE)
	var small := IslandField.lattice(world_seed, config.size, config.shape_detail_cell, SALT_DETAIL)
	var half := config.size / 2.0
	var reach := maxf(half - config.sea_margin, 1.0)
	var detail := clampf(config.shape_detail, 0.0, 1.0)
	var values := PackedFloat64Array()
	values.resize(n)
	for by in blocks:
		for bx in blocks:
			var i := by * blocks + bx
			var c := _center(bx, by)
			var lo := c - Vector2.ONE * (block * 0.5)
			var hi := c + Vector2.ONE * (block * 0.5)
			if lo.x < config.sea_margin or lo.y < config.sea_margin \
					or hi.x > config.size - config.sea_margin or hi.y > config.size - config.sea_margin:
				values[i] = -1e9
			elif _forced[i] != FORCE_NONE:
				values[i] = 1e9
			else:
				var r := (c - Vector2(half, half)).length() / reach
				var shape := IslandField.noise(big, config.size, config.shape_noise_cell, c) * (1.0 - detail) \
					+ IslandField.noise(small, config.size, config.shape_detail_cell, c) * detail
				values[i] = shape - r * r * config.shape_falloff
	var land := PackedByteArray()
	land.resize(n)
	var thr := IslandField.top_threshold(values, roundi(n * clampf(config.land_percent / 100.0, 0.0, 1.0)))
	for i in n:
		var inside := values[i] > -1e9
		land[i] = 1 if inside and (values[i] >= thr or _forced[i] != FORCE_NONE) else 0
	# 스폰과 이어진 땅만 남기고, 가장자리에서 그 밖으로 번진 물이 바다다.
	var spawn := config.spawn() / block
	var main := IslandField.flood(blocks, [spawn.y * blocks + spawn.x], land, 1)
	var starts := PackedInt32Array()
	for b in blocks:
		for i in [b, (blocks - 1) * blocks + b, b * blocks, b * blocks + blocks - 1]:
			if main[i] == 0:
				starts.append(i)
	var outside := PackedByteArray()
	outside.resize(n)
	for i in n:
		outside[i] = 1 - main[i]
	return IslandField.flood(blocks, starts, outside, 1)


## 바다 · 해안 · 나머지 땅(일단 풀밭)을 적고 땅 칸 수를 센다.
func _mark_coast(sea: PackedByteArray) -> void:
	var w := config.beach_width
	var land_blocks := 0
	for by in blocks:
		for bx in blocks:
			var i := by * blocks + bx
			if sea[i] == 1:
				_kind[i] = Terrain.SEA
				_forced[i] = FORCE_NONE
				continue
			land_blocks += 1
			if _forced[i] == FORCE_PEAK:
				continue
			_kind[i] = Terrain.GRASS
			for dy in range(-w, w + 1):
				for dx in range(-w, w + 1):
					var nx := bx + dx
					var ny := by + dy
					if nx >= 0 and ny >= 0 and nx < blocks and ny < blocks and sea[ny * blocks + nx] == 1:
						_kind[i] = Terrain.BEACH
	land_cells = land_blocks * block * block


func _is_open(i: int) -> bool:
	return _kind[i] == Terrain.GRASS and (_forced[i] == FORCE_NONE or _forced[i] == FORCE_LAND)


## 솟은 지형 — 땅의 elevated_percent 가 되게 얼룩이 높은 블록을 고르고, 이어진 덩어리마다 종류를 정한다.
func _raise() -> void:
	var cells := PackedInt32Array()
	var values := PackedFloat64Array()
	var lat := IslandField.lattice(world_seed, config.size, config.relief_noise_cell, SALT_RELIEF)
	var have := 0
	for i in blocks * blocks:
		if _forced[i] == FORCE_PEAK:
			have += 1
		elif _is_open(i):
			cells.append(i)
			values.append(IslandField.noise(lat, config.size, config.relief_noise_cell, _center(i % blocks, i / blocks)))
	var want := roundi(land_cells / float(block * block) * clampf(config.elevated_percent / 100.0, 0.0, 1.0))
	var thr := IslandField.top_threshold(values, want - have)
	var raised := PackedByteArray()
	raised.resize(blocks * blocks)
	for k in cells.size():
		if values[k] >= thr:
			raised[cells[k]] = 1
	# 덩어리마다 하나의 종류 — 덩어리의 첫 블록(줄 순서)을 해시해 비대로 고른다.
	var weights := config.elevated_weights()
	var total := weights[0] + weights[1] + weights[2]
	for i in blocks * blocks:
		if raised[i] != 1:
			continue
		var r := IslandGenerator.hash01(world_seed, i % blocks, i / blocks, SALT_KIND) * total
		var kind: Terrain = ELEVATED_KINDS[0]
		for k in 3:
			kind = ELEVATED_KINDS[k]
			r -= weights[k]
			if r < 0.0:
				break
		_fill_blob(i, raised, kind)


## raised == 1 로 4방향 이어진 덩어리를 kind 로 칠하고 2 로 표시한다.
func _fill_blob(start: int, raised: PackedByteArray, kind: Terrain) -> void:
	raised[start] = 2
	var stack := PackedInt32Array([start])
	while not stack.is_empty():
		var i := stack[stack.size() - 1]
		stack.resize(stack.size() - 1)
		_kind[i] = kind
		for d in NEIGHBORS_4:
			var nx: int = i % blocks + d.x
			var ny: int = i / blocks + d.y
			if nx >= 0 and ny >= 0 and nx < blocks and ny < blocks and raised[ny * blocks + nx] == 1:
				raised[ny * blocks + nx] = 2
				stack.append(ny * blocks + nx)


## 숲 — 솟지 않은 안쪽 땅에서, 땅의 forest_percent 가 되게 얼룩이 높은 블록.
func _grow_forest() -> void:
	var cells := PackedInt32Array()
	var values := PackedFloat64Array()
	var lat := IslandField.lattice(world_seed, config.size, config.forest_noise_cell, SALT_FOREST)
	for i in blocks * blocks:
		if _is_open(i):
			cells.append(i)
			values.append(IslandField.noise(lat, config.size, config.forest_noise_cell, _center(i % blocks, i / blocks)))
	var want := roundi(land_cells / float(block * block) * clampf(config.forest_percent / 100.0, 0.0, 1.0))
	var thr := IslandField.top_threshold(values, want)
	for k in cells.size():
		if values[k] >= thr:
			_kind[cells[k]] = Terrain.FOREST


## 높이 — 솟은 블록에서 솟지 않은 블록까지의 거리(8방향 걸음)를 max_height 에서 자른다.
## 이웃 블록끼리 거리는 1 넘게 다르지 않으니 이웃 칸 높이 차는 1 이하다.
func _measure_heights() -> void:
	var top := maxi(config.max_height, 1)
	var frontier := PackedInt32Array()
	elevated_cells = 0
	for i in blocks * blocks:
		if not IslandConfig.is_elevated(_kind[i]):
			continue
		elevated_cells += block * block
		for d in NEIGHBORS_8:
			var nx: int = i % blocks + d.x
			var ny: int = i / blocks + d.y
			var inside := nx >= 0 and ny >= 0 and nx < blocks and ny < blocks
			if not inside or not IslandConfig.is_elevated(_kind[ny * blocks + nx]):
				_height[i] = 1
				frontier.append(i)
				break
	for level in range(2, top + 1):
		var next := PackedInt32Array()
		for i in frontier:
			for d in NEIGHBORS_8:
				var nx: int = i % blocks + d.x
				var ny: int = i / blocks + d.y
				if nx < 0 or ny < 0 or nx >= blocks or ny >= blocks:
					continue
				var j := ny * blocks + nx
				if _height[j] == 0 and IslandConfig.is_elevated(_kind[j]):
					_height[j] = level
					next.append(j)
		frontier = next
	for i in blocks * blocks:
		if _height[i] == 0 and IslandConfig.is_elevated(_kind[i]):
			_height[i] = top
