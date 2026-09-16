class_name IslandMap
extends RefCounted
## 섬 — 칸마다 지형 · 높이 · 자원. 값은 IslandGenerator 의 해시에서 온다.
## 덩어리(chunk_size × chunk_size) 단위로 처음 읽을 때 만든다 — 게임은 보이는 곳만 만들어 빨리 들어간다.
## 어느 순서로 만들어도 값이 같다 (칸 값이 좌표의 해시라서).
## 채취로 없앤 칸은 표시(removed)로 남긴다 — 저장은 이 표시만 한다. 재생은 표시를 지우는 것이다.

## 칸의 자원이 바뀌었다 (그리기 · 충돌을 다시 만들 때).
signal cell_changed(cell: Vector2i)

var world_seed: int
var size: int
var chunk_size: int
var generator: IslandGenerator
var _terrain := PackedByteArray()
var _deposit := PackedByteArray()
var _height := PackedByteArray()
var _cliff := PackedByteArray()
var _chunk_count := 0
var _built := PackedByteArray()
var _built_total := 0
## 없앤 칸 표시 — Vector2i → true. WorldData.removed_cells 와 같은 사전을 나눠 쓴다.
var removed: Dictionary
## 없앤 시각 — Vector2i → 월드 시간(초). WorldData.removed_at 과 나눠 쓴다. 없으면 0 에 없앤 것으로 본다.
var removed_at: Dictionary
## 월드 시간 (게임 초) — 시계(WorldClock)가 흘린다. 저장은 WorldData.world_time.
var time := 0.0


## lazy 가 아니면 섬 전체를 바로 만든다. removed_cells · removed_times 는 저장에서 온 없앤 칸 표시와 시각
## (그대로 나눠 쓴다).
func _init(gen: IslandGenerator, lazy := false, removed_cells: Variant = null,
		removed_times: Variant = null) -> void:
	generator = gen
	removed = removed_cells if removed_cells is Dictionary else {}
	removed_at = removed_times if removed_times is Dictionary else {}
	world_seed = gen.world_seed
	size = gen.config.size
	chunk_size = maxi(gen.config.chunk_size, 1)
	_terrain.resize(size * size)
	_deposit.resize(size * size)
	_height.resize(size * size)
	_cliff.resize(size * size)
	_chunk_count = ceili(float(size) / chunk_size)
	_built.resize(_chunk_count * _chunk_count)
	if not lazy:
		build_all()


func spawn() -> Vector2i:
	return generator.config.spawn()


func has_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size and cell.y < size


func chunk_of(cell: Vector2i) -> Vector2i:
	return Vector2i(floori(float(cell.x) / chunk_size), floori(float(cell.y) / chunk_size))


func has_chunk(chunk: Vector2i) -> bool:
	return chunk.x >= 0 and chunk.y >= 0 and chunk.x < _chunk_count and chunk.y < _chunk_count


## 덩어리가 덮는 칸 (섬 끝에서는 잘린다).
func chunk_rect(chunk: Vector2i) -> Rect2i:
	var origin := chunk * chunk_size
	var end := (origin + Vector2i(chunk_size, chunk_size)).min(Vector2i(size, size))
	return Rect2i(origin, end - origin)


func is_chunk_built(chunk: Vector2i) -> bool:
	return has_chunk(chunk) and _built[chunk.y * _chunk_count + chunk.x] != 0


## 만든 덩어리 수 / 전체 덩어리 수.
func built_chunks() -> int:
	return _built_total


func total_chunks() -> int:
	return _chunk_count * _chunk_count


func ensure_chunk(chunk: Vector2i) -> void:
	if not has_chunk(chunk) or is_chunk_built(chunk):
		return
	var rect := chunk_rect(chunk)
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var t := generator.terrain_at(x, y)
			_terrain[y * size + x] = t
			_height[y * size + x] = generator.height_at(x, y)
			_cliff[y * size + x] = 1 if generator.cliff_at(x, y) else 0
			var d := generator.deposit_on(x, y, t)
			if removed.has(Vector2i(x, y)):
				d = IslandConfig.Deposit.NONE
			_deposit[y * size + x] = d
	_built[chunk.y * _chunk_count + chunk.x] = 1
	_built_total += 1


func build_all() -> void:
	for cy in _chunk_count:
		for cx in _chunk_count:
			ensure_chunk(Vector2i(cx, cy))


func terrain_at(cell: Vector2i) -> IslandConfig.Terrain:
	ensure_chunk(chunk_of(cell))
	return _terrain[cell.y * size + cell.x] as IslandConfig.Terrain


## 높이 단 (0 = 평지 높이). 이웃 칸끼리 1 넘게 다르지 않다.
func height_at(cell: Vector2i) -> int:
	ensure_chunk(chunk_of(cell))
	return _height[cell.y * size + cell.x]


## 절벽 칸 — 등반 장비 없이는 못 들어간다.
func is_cliff(cell: Vector2i) -> bool:
	ensure_chunk(chunk_of(cell))
	return _cliff[cell.y * size + cell.x] == 1


func deposit_at(cell: Vector2i) -> IslandConfig.Deposit:
	ensure_chunk(chunk_of(cell))
	return _deposit[cell.y * size + cell.x] as IslandConfig.Deposit


## 칸의 자원을 없애고 표시를 남긴다. 없앨 자원이 없으면 false.
func remove_deposit(cell: Vector2i) -> bool:
	if not has_cell(cell) or deposit_at(cell) == IslandConfig.Deposit.NONE:
		return false
	_deposit[cell.y * size + cell.x] = IslandConfig.Deposit.NONE
	removed[cell] = true
	removed_at[cell] = time
	cell_changed.emit(cell)
	return true


func is_removed(cell: Vector2i) -> bool:
	return removed.has(cell)


func removed_time(cell: Vector2i) -> float:
	return float(removed_at.get(cell, 0.0))


## 시드가 이 칸에 처음 만든 자원 (없앤 표시와 상관없이).
func original_deposit(cell: Vector2i) -> IslandConfig.Deposit:
	return generator.deposit_at(cell.x, cell.y)


## 재생 — 없앤 표시를 지워 칸을 시드의 원래 값으로 돌린다. 표시가 없던 칸이면 false.
## 원래 비어 있던 칸은 표시만 지워지고 빈 채로 남는다.
func regrow(cell: Vector2i) -> bool:
	if not removed.has(cell):
		return false
	removed.erase(cell)
	removed_at.erase(cell)
	if is_chunk_built(chunk_of(cell)):
		_deposit[cell.y * size + cell.x] = original_deposit(cell)
	cell_changed.emit(cell)
	return true


## 걸어서 못 들어가나 — 섬 밖 · 바다 · 절벽 · 자원(장애물). 등반 장비는 아직 없다 (04_life/climbing.md).
func is_blocked(cell: Vector2i) -> bool:
	return not has_cell(cell) or terrain_at(cell) == IslandConfig.Terrain.SEA or is_cliff(cell) \
		or deposit_at(cell) != IslandConfig.Deposit.NONE


## 칸 값을 통째로 — 두 섬이 같은지 비교할 때. 아직 안 만든 곳까지 만든다.
func terrain_bytes() -> PackedByteArray:
	build_all()
	return _terrain


func height_bytes() -> PackedByteArray:
	build_all()
	return _height


func cliff_bytes() -> PackedByteArray:
	build_all()
	return _cliff


func deposit_bytes() -> PackedByteArray:
	build_all()
	return _deposit
