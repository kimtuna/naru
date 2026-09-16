class_name IslandChunk
extends Node2D
## 섬 덩어리 하나 — 칸을 색 네모로 그리고, 자원 칸마다 막는 충돌을 둔다.
## 한 줄에서 이어진 자원 칸은 네모 하나로 합쳐 충돌 모양 수를 줄인다.

## 색은 임시다 — 아트는 사람이 나중에 넣는다.
const TERRAIN_COLORS := {
	IslandConfig.Terrain.GRASS: Color(0.33, 0.55, 0.3),
	IslandConfig.Terrain.ORE_GROUND: Color(0.5, 0.42, 0.36),
}
const DEPOSIT_COLORS := {
	IslandConfig.Deposit.TREE: Color(0.1, 0.35, 0.12),
	IslandConfig.Deposit.STONE: Color(0.55, 0.55, 0.58),
	IslandConfig.Deposit.ORE: Color(0.75, 0.55, 0.15),
}

var map: IslandMap
var chunk: Vector2i
var tile_px: int
var _rect: Rect2i
var _body: StaticBody2D


func setup(island: IslandMap, chunk_pos: Vector2i, tile: int) -> void:
	map = island
	chunk = chunk_pos
	tile_px = tile
	map.ensure_chunk(chunk)
	_rect = map.chunk_rect(chunk)
	name = "Chunk_%d_%d" % [chunk.x, chunk.y]
	position = Vector2(_rect.position * tile_px)
	_build_body()
	queue_redraw()


func body() -> StaticBody2D:
	return _body


func _build_body() -> void:
	_body = StaticBody2D.new()
	_body.name = "Body"
	add_child(_body)
	for y in range(_rect.position.y, _rect.end.y):
		var run_start := -1
		for x in range(_rect.position.x, _rect.end.x + 1):
			var blocked := x < _rect.end.x and map.is_blocked(Vector2i(x, y))
			if blocked and run_start < 0:
				run_start = x
			elif not blocked and run_start >= 0:
				_add_box(Vector2i(run_start, y), x - run_start)
				run_start = -1


func _add_box(cell: Vector2i, length: int) -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(length * tile_px, tile_px)
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2((cell - _rect.position) * tile_px) + shape.size / 2.0
	_body.add_child(col)


func _draw() -> void:
	var t := Vector2(tile_px, tile_px)
	for y in range(_rect.position.y, _rect.end.y):
		for x in range(_rect.position.x, _rect.end.x):
			var cell := Vector2i(x, y)
			var at := Vector2(cell - _rect.position) * float(tile_px)
			draw_rect(Rect2(at, t), TERRAIN_COLORS[map.terrain_at(cell)])
			var deposit := map.deposit_at(cell)
			if deposit != IslandConfig.Deposit.NONE:
				draw_rect(Rect2(at + Vector2.ONE, t - Vector2.ONE * 2.0), DEPOSIT_COLORS[deposit])
