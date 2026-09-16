class_name IslandMap
extends RefCounted
## 만들어 둔 섬 — 칸마다 지형과 자원. 값은 IslandGenerator 의 해시에서 온다.

var world_seed: int
var size: int
var generator: IslandGenerator
var _terrain := PackedByteArray()
var _deposit := PackedByteArray()


func _init(gen: IslandGenerator) -> void:
	generator = gen
	world_seed = gen.world_seed
	size = gen.config.size
	_terrain.resize(size * size)
	_deposit.resize(size * size)
	for y in size:
		for x in size:
			var t := gen.terrain_at(x, y)
			_terrain[y * size + x] = t
			_deposit[y * size + x] = gen.deposit_on(x, y, t)


func spawn() -> Vector2i:
	return generator.config.spawn()


func has_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size and cell.y < size


func terrain_at(cell: Vector2i) -> IslandConfig.Terrain:
	return _terrain[cell.y * size + cell.x] as IslandConfig.Terrain


func deposit_at(cell: Vector2i) -> IslandConfig.Deposit:
	return _deposit[cell.y * size + cell.x] as IslandConfig.Deposit


## 장애물(자원)이 있나. 섬 밖도 막힌 것으로 본다.
func is_blocked(cell: Vector2i) -> bool:
	return not has_cell(cell) or deposit_at(cell) != IslandConfig.Deposit.NONE


## 칸 값을 통째로 — 두 섬이 같은지 비교할 때.
func terrain_bytes() -> PackedByteArray:
	return _terrain


func deposit_bytes() -> PackedByteArray:
	return _deposit
