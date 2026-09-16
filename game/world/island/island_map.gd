class_name IslandMap
extends RefCounted
## 섬 — 칸마다 지형과 자원. 값은 IslandGenerator 의 해시에서 온다.
## 덩어리(chunk_size × chunk_size) 단위로 처음 읽을 때 만든다 — 게임은 보이는 곳만 만들어 빨리 들어간다.
## 어느 순서로 만들어도 값이 같다 (칸 값이 좌표의 해시라서).

var world_seed: int
var size: int
var chunk_size: int
var generator: IslandGenerator
var _terrain := PackedByteArray()
var _deposit := PackedByteArray()
var _chunk_count := 0
var _built := PackedByteArray()
var _built_total := 0


## lazy 가 아니면 섬 전체를 바로 만든다.
func _init(gen: IslandGenerator, lazy := false) -> void:
	generator = gen
	world_seed = gen.world_seed
	size = gen.config.size
	chunk_size = maxi(gen.config.chunk_size, 1)
	_terrain.resize(size * size)
	_deposit.resize(size * size)
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
			_deposit[y * size + x] = generator.deposit_on(x, y, t)
	_built[chunk.y * _chunk_count + chunk.x] = 1
	_built_total += 1


func build_all() -> void:
	for cy in _chunk_count:
		for cx in _chunk_count:
			ensure_chunk(Vector2i(cx, cy))


func terrain_at(cell: Vector2i) -> IslandConfig.Terrain:
	ensure_chunk(chunk_of(cell))
	return _terrain[cell.y * size + cell.x] as IslandConfig.Terrain


func deposit_at(cell: Vector2i) -> IslandConfig.Deposit:
	ensure_chunk(chunk_of(cell))
	return _deposit[cell.y * size + cell.x] as IslandConfig.Deposit


## 장애물(자원)이 있나. 섬 밖도 막힌 것으로 본다.
func is_blocked(cell: Vector2i) -> bool:
	return not has_cell(cell) or deposit_at(cell) != IslandConfig.Deposit.NONE


## 칸 값을 통째로 — 두 섬이 같은지 비교할 때. 아직 안 만든 곳까지 만든다.
func terrain_bytes() -> PackedByteArray:
	build_all()
	return _terrain


func deposit_bytes() -> PackedByteArray:
	build_all()
	return _deposit
